# 07. Intégration Wazuh dans Prometheus et Grafana

**Objectif** : Centraliser les alertes Wazuh dans Prometheus/Grafana pour avoir une vue unifiée.

**Durée estimée** : 1h  
**Niveau** : Avancé  
**Prérequis** : Wazuh installé, Prometheus configuré, Grafana connecté

---

## 1. Architecture d'intégration

### Flux des données

```
[Serveur Web]
     ↓
[Wazuh Agent]
     ↓
[Wazuh Manager] ← API REST
     ↓
[Prometheus] ← scrape les métriques
     ↓
[Grafana] ← visualise les alertes
```

### Avantages

- Vue unifiée : système ET sécurité au même endroit
- Alertes cross-system : corrélation CPU + attaque
- Historique : garder les données Wazuh 30+ jours
- Automatisation : basé sur Prometheus, utilise AlertManager

---

## 2. Configurer un exporter Wazuh → Prometheus

### 2.1 Installation du wazuh-exporter

L'exporter Wazuh n'existe pas par défaut. Solutions :

**Option A** : Créer un script Python (recommandé)  
**Option B** : Utiliser une API gateway (complexe)  
**Option C** : Exporter les logs via JSON (simple)

On choisit **Option A** : un script Python qui scrape l'API Wazuh.

### 2.2 Créer le script Python d'export

**Étape 1** : SSH sur la VM Prometheus

```bash
ssh admin@prometheus-vm
sudo -i  # devenir root
```

**Étape 2** : Installer les dépendances

```bash
pip install requests prometheus-client
```

**Étape 3** : Créer le script

Créer `/opt/wazuh_exporter.py` :

```python
#!/usr/bin/env python3
"""
Exporter Wazuh vers Prometheus
Scrape l'API Wazuh et expose les métriques au format Prometheus
"""

import requests
import json
import time
from prometheus_client import start_http_server, Gauge, Counter
from urllib3.exceptions import InsecureRequestWarning

# Désactiver les avertissements SSL (Wazuh utilise HTTPS auto-signé)
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Configuration
WAZUH_API_URL = "https://wazuh-manager:55000"  # IP ou hostname du Wazuh Manager
WAZUH_USERNAME = "wazuh"
WAZUH_PASSWORD = "Wazuh1234!"  # Remplacer par le mot de passe réel
PROMETHEUS_PORT = 9100  # Port d'écoute

# Métriques Prometheus
alerts_total = Counter('wazuh_alerts_total', 'Total alerts by severity', ['severity'])
active_agents = Gauge('wazuh_agents_active', 'Number of active agents')
disconnected_agents = Gauge('wazuh_agents_disconnected', 'Number of disconnected agents')
vulnerability_count = Gauge('wazuh_vulnerabilities_count', 'Total vulnerabilities detected')
brute_force_attempts = Counter('wazuh_brute_force_attempts_total', 
                               'Total brute force attempts', 
                               ['source_ip'])
privilege_escalation = Counter('wazuh_privilege_escalation_total',
                               'Total privilege escalation attempts',
                               ['user'])


class WazuhAPI:
    """Client pour l'API Wazuh"""
    
    def __init__(self, url, username, password):
        self.url = url
        self.username = username
        self.password = password
        self.token = None
        self.authenticate()
    
    def authenticate(self):
        """Obtenir un token d'authentification"""
        endpoint = f"{self.url}/security/user/authenticate"
        try:
            response = requests.post(endpoint, 
                                    auth=(self.username, self.password),
                                    verify=False)
            response.raise_for_status()
            self.token = response.json()['data']['token']
            print("[✓] Authentification Wazuh réussie")
        except Exception as e:
            print(f"[✗] Erreur authentification Wazuh : {e}")
            raise
    
    def get_alerts(self, limit=1000, severity_min=3):
        """Récupérer les alertes récentes"""
        endpoint = f"{self.url}/events"
        headers = {"Authorization": f"Bearer {self.token}"}
        
        try:
            response = requests.get(endpoint,
                                   headers=headers,
                                   params={'limit': limit, 'sort': '-timestamp'},
                                   verify=False)
            response.raise_for_status()
            return response.json()['data']['affected_items']
        except Exception as e:
            print(f"[✗] Erreur récupération alertes : {e}")
            return []
    
    def get_agents(self):
        """Récupérer l'état des agents"""
        endpoint = f"{self.url}/agents"
        headers = {"Authorization": f"Bearer {self.token}"}
        
        try:
            response = requests.get(endpoint, 
                                   headers=headers,
                                   verify=False)
            response.raise_for_status()
            return response.json()['data']['affected_items']
        except Exception as e:
            print(f"[✗] Erreur récupération agents : {e}")
            return []


def scrape_wazuh():
    """Scraper les données Wazuh et mettre à jour les métriques"""
    global wazuh_client
    
    while True:
        try:
            # Récupérer les alertes
            alerts = wazuh_client.get_alerts(limit=500)
            
            # Compter par sévérité
            severity_counts = {'critical': 0, 'high': 0, 'medium': 0, 'low': 0}
            
            for alert in alerts:
                # Obtenir la sévérité
                severity = alert.get('rule', {}).get('level', 0)
                
                if severity >= 12:
                    severity_counts['critical'] += 1
                elif severity >= 8:
                    severity_counts['high'] += 1
                elif severity >= 4:
                    severity_counts['medium'] += 1
                else:
                    severity_counts['low'] += 1
                
                # Détecter les attaques spécifiques
                rule_description = alert.get('rule', {}).get('description', '')
                
                # Brute force SSH
                if 'brute' in rule_description.lower() or 'ssh' in rule_description.lower():
                    source_ip = alert.get('data', {}).get('srcip', 'unknown')
                    brute_force_attempts.labels(source_ip=source_ip).inc()
                
                # Escalade de privilèges
                if 'privilege' in rule_description.lower() or 'sudo' in rule_description.lower():
                    user = alert.get('data', {}).get('user', 'unknown')
                    privilege_escalation.labels(user=user).inc()
            
            # Mettre à jour les compteurs de sévérité
            for severity, count in severity_counts.items():
                alerts_total.labels(severity=severity)._value.set(count)
            
            # Récupérer l'état des agents
            agents = wazuh_client.get_agents()
            active = sum(1 for a in agents if a.get('status') == 'active')
            disconnected = sum(1 for a in agents if a.get('status') != 'active')
            
            active_agents.set(active)
            disconnected_agents.set(disconnected)
            
            print(f"[✓] Scrape réussi : {len(alerts)} alertes, "
                  f"{active} agents actifs, {disconnected} déconnectés")
            
        except Exception as e:
            print(f"[✗] Erreur scrape : {e}")
        
        # Attendre avant la prochaine scrape (60 secondes)
        time.sleep(60)


if __name__ == '__main__':
    print("=== Wazuh Exporter pour Prometheus ===")
    
    # Initialiser le client Wazuh
    wazuh_client = WazuhAPI(WAZUH_API_URL, WAZUH_USERNAME, WAZUH_PASSWORD)
    
    # Démarrer le serveur HTTP Prometheus
    start_http_server(PROMETHEUS_PORT)
    print(f"[✓] Exporter démarré sur le port {PROMETHEUS_PORT}")
    
    # Scraper en continu
    scrape_wazuh()
```

**Étape 4** : Rendre exécutable et tester

```bash
chmod +x /opt/wazuh_exporter.py

# Test
python3 /opt/wazuh_exporter.py
```

Vous devriez voir :
```
=== Wazuh Exporter pour Prometheus ===
[✓] Authentification Wazuh réussie
[✓] Exporter démarré sur le port 9100
[✓] Scrape réussi : 15 alertes, 2 agents actifs, 0 déconnectés
```

### 2.3 Créer un service systemd

Créer `/etc/systemd/system/wazuh-exporter.service` :

```ini
[Unit]
Description=Wazuh Prometheus Exporter
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/bin/python3 /opt/wazuh_exporter.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Démarrer le service :

```bash
sudo systemctl enable wazuh-exporter
sudo systemctl start wazuh-exporter
sudo systemctl status wazuh-exporter
```

Vérifier que ça fonctionne :

```bash
curl http://localhost:9100/metrics | grep wazuh
```

---

## 3. Configurer Prometheus pour scraper Wazuh

### 3.1 Éditer prometheus.yml

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Ajouter un nouveau job :

```yaml
global:
  scrape_interval: 60s

scrape_configs:
  # ... autres jobs ...
  
  - job_name: 'wazuh'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 60s
    scrape_timeout: 30s
```

### 3.2 Redémarrer Prometheus

```bash
sudo systemctl restart prometheus
```

Vérifier dans l'interface Prometheus (http://localhost:9090) :
- Aller dans **Status → Targets**
- Voir si `wazuh` est `UP`

---

## 4. Créer des dashboards Grafana pour Wazuh

### 4.1 Dashboard d'alertes Wazuh

Créer un nouveau dashboard dans Grafana :

**Panneau 1 : Alertes par sévérité (gauge)**

```
Metric : wazuh_alerts_total
GroupBy : severity
Display : Pie chart
Colors : critical=red, high=orange, medium=yellow, low=green
```

**Panneau 2 : Agents actifs vs déconnectés**

```
Metric 1 : wazuh_agents_active
Metric 2 : wazuh_agents_disconnected
Display : Stat panel
```

**Panneau 3 : Tentatives brute force (top 5)**

```
Metric : topk(5, wazuh_brute_force_attempts_total)
GroupBy : source_ip
Display : Graph avec label
```

**Panneau 4 : Escalades de privilèges**

```
Metric : wazuh_privilege_escalation_total
GroupBy : user
Display : Table
```

### 4.2 Importer un dashboard Wazuh pré-fait (optionnel)

Grafana a des dashboards Wazuh. Pour en importer un :

1. Aller dans **Dashboards → Import**
2. Entrer l'ID : `12114` (Wazuh Dashboard)
3. Sélectionner Prometheus comme datasource
4. Cliquer **Import**

---

## 5. Créer des alertes croisées (système + sécurité)

### Alerte : "CPU élevé ET brute force SSH"

**Cas d'usage** : Attaque DDoS combinée avec SSH brute force.

Dans Grafana, créer une alerte :

```
Query A : CPU > 70%
Query B : wazuh_brute_force_attempts_total > 10

Condition : A AND B
For : 2m
Message : "Attaque probable ! CPU élevée ET tentatives SSH détectées"
```

### Alerte : "Disque plein ET logs de sécurité augmentent"

```
Query A : node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15
Query B : wazuh_alerts_total > 100

Condition : A AND B
For : 5m
Message : "Espace disque faible mais beaucoup d'alertes Wazuh. Archiver logs !"
```

---

## 6. Requêtes PromQL utiles pour Wazuh

### Alertes critiques des 24h

```
increase(wazuh_alerts_total{severity="critical"}[24h])
```

### Agents souvent déconnectés

```
wazuh_agents_disconnected
```

### Attaques SSH par jour

```
rate(wazuh_brute_force_attempts_total[1d])
```

### Top 5 utilisateurs avec tentatives d'escalade

```
topk(5, wazuh_privilege_escalation_total)
```

---

## 7. Intégration avec AlertManager (optionnel)

Si vous utilisez AlertManager pour Prometheus, ajouter un groupe d'alertes Wazuh :

Créer `/etc/prometheus/alert_wazuh.yml` :

```yaml
groups:
  - name: wazuh_alerts
    interval: 60s
    rules:
      - alert: WazuhCriticalAlert
        expr: wazuh_alerts_total{severity="critical"} > 5
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Trop d'alertes critiques Wazuh"
          description: "{{ $value }} alertes critiques détectées"
      
      - alert: WazuhAgentDown
        expr: wazuh_agents_disconnected > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Agent Wazuh déconnecté"
          description: "{{ $value }} agent(s) déconnecté(s)"
      
      - alert: WazuhBruteForceAttack
        expr: wazuh_brute_force_attempts_total > 20
        for: 1m
        labels:
          severity: high
        annotations:
          summary: "Attaque SSH brute force détectée"
          description: "{{ $value }} tentatives de brute force"
```

Charger cette config dans Prometheus.

---

## 8. Validation et test

### 8.1 Vérifier les métriques Wazuh

```bash
# Sur le serveur Prometheus
curl http://localhost:9100/metrics | grep wazuh_
```

Résultat attendu :
```
wazuh_alerts_total{severity="critical"} 2
wazuh_alerts_total{severity="high"} 5
wazuh_agents_active 2
wazuh_agents_disconnected 0
wazuh_brute_force_attempts_total{source_ip="192.168.1.50"} 12
```

### 8.2 Tester une requête Prometheus

Dans http://localhost:9090 :

```
Query : wazuh_agents_active
→ Doit afficher un nombre > 0
```

### 8.3 Vérifier le dashboard Grafana

Le dashboard doit afficher :
- [ ] Alertes par sévérité
- [ ] Agents status
- [ ] Brute force attempts
- [ ] Privilege escalation

---

## 9. Checklist d'intégration

- [ ] Dépendances Python installées (requests, prometheus-client)
- [ ] Script wazuh_exporter.py créé et testé
- [ ] Service wazuh-exporter.service créé et running
- [ ] prometheus.yml modifié avec job Wazuh
- [ ] Prometheus redémarré
- [ ] Métriques visibles en http://localhost:9100/metrics
- [ ] Prometheus scrape le job Wazuh (Status → Targets → UP)
- [ ] Dashboard Grafana créé
- [ ] Alertes croisées configurées
- [ ] Test : vérifier que les alertes Wazuh apparaissent dans Grafana

---

## 10. Dépannage

| Problème | Cause | Solution |
|----------|-------|----------|
| Erreur auth Wazuh | Mauvais mot de passe | Vérifier les credentials |
| Pas de métriques | Service pas lancé | `systemctl status wazuh-exporter` |
| Metrics vides | API Wazuh non accessible | Vérifier URL, firewall |
| Prometheus ne scrape pas | Job pas configuré | Redémarrer Prometheus |

---

## Résumé

```
Wazuh → [Exporter Python] → :9100/metrics
                              ↓
                         Prometheus scrape
                              ↓
                         Grafana visualise
                              ↓
                         AlertManager → Actions
```

Une intégration réussie = détection + analyse + action au même endroit !
