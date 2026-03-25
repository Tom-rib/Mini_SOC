# 04 - Dashboards Grafana

**Objectif** : Créer des dashboards de monitoring et d'alerte pour le SOC  
**Durée estimée** : 2-2.5 heures  
**Rôle** : Administrateur supervision (Rôle 3)

---

## Architecture des dashboards

```
┌─────────────────────────────────────┐
│ DASHBOARD PRINCIPAL (SOC Overview)  │
├─────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐         │
│  │ VM Status│  │  Alertes │         │  Panel 1
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │   CPU    │  │    RAM   │         │  Panel 2
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │  Disque  │  │  Réseau  │         │  Panel 3
│  └──────────┘  └──────────┘         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ DASHBOARD DÉTAIL (VM1 Deep Dive)    │
├─────────────────────────────────────┤
│ Graphs CPU, RAM, Disque détaillés   │
│ Logs SSH, tentatives connexion      │
│ Charges réseau par service          │
└─────────────────────────────────────┘
```

---

## Phase 1 : Préparation Grafana

### 1.1 - Se connecter à Grafana

Ouvrir navigateur :
```
http://<IP_VM3>:3000
```

Identifiants :
```
admin
admin
```

**Premier écran** : Grafana demande de changer le mot de passe → **Skip** (ou changer)

### 1.2 - Ajouter Prometheus comme source de données

```
Menu → Configuration → Data Sources
```

**Cliquer** : "Add data source"

**Remplir** :
```
Name: Prometheus
Type: Prometheus
URL: http://localhost:9090
```

**Cliquer** : "Save & test"

**Résultat attendu** : "Data source is working"

---

## Phase 2 : Dashboard principal

### 2.1 - Créer le dashboard

```
Menu gauche → Dashboards → New → New Dashboard
```

### 2.2 - Ajouter les panels

#### Panel 1 : VM Status (Tableau)

**Créer panel**
```
New Panel (ou + Add panel)
```

**Requête**
```promql
up{job=~"vm1|vm2|prometheus"}
```

**Configuration**
```
Visualization: Table
Columns: instance, value (renommer en "Status")
Thresholds:
  - 1 = Green (Up)
  - 0 = Red (Down)
```

**Titre** : "Hosts Status"

**Position** : Top-left, 6x4

---

#### Panel 2 : Alertes actives (Stat)

**Requête**
```promql
count(count by (alertname) (ALERTS{severity="critical"}))
```

Si pas d'alertes Prometheus, mettre : `count(up{job=~".*"})`

**Configuration**
```
Visualization: Stat
Unit: short
Color scheme:
  - > 0 = Red
  - = 0 = Green
```

**Titre** : "Critical Alerts"

**Position** : Top-right, 6x4

---

#### Panel 3 : CPU Usage (Gauge)

**Requête**
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Configuration**
```
Visualization: Gauge
Unit: percent
Min: 0
Max: 100
Thresholds:
  - 0 = Green
  - 60 = Yellow
  - 80 = Red
```

**Titre** : "CPU Usage"

**Position** : 2nd row, left, 4x4

---

#### Panel 4 : RAM Usage (Gauge)

**Requête**
```promql
(1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes)) * 100
```

**Configuration**
```
Visualization: Gauge
Unit: percent
Min: 0
Max: 100
Thresholds:
  - 0 = Green
  - 70 = Yellow
  - 90 = Red
```

**Titre** : "Memory Usage"

**Position** : 2nd row, middle, 4x4

---

#### Panel 5 : Disk Usage (Gauge)

**Requête**
```promql
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
```

**Configuration**
```
Visualization: Pie Chart (ou Gauge)
Unit: percent
Thresholds:
  - 0 = Green
  - 75 = Yellow
  - 90 = Red
```

**Titre** : "Disk Usage /"

**Position** : 2nd row, right, 4x4

---

#### Panel 6 : Network Traffic (Graph)

**Requête 1** (RX)
```promql
rate(node_network_receive_bytes_total{device="eth0"}[5m]) * 8 / 1000000
```

**Requête 2** (TX)
```promql
rate(node_network_transmit_bytes_total{device="eth0"}[5m]) * 8 / 1000000
```

**Configuration**
```
Visualization: Time series / Graph
Unit: Mbps
Legend: table (show)
Stack: false
```

**Titre** : "Network I/O"

**Position** : 3rd row, full width, 12x6

---

### 2.3 - Sauvegarder le dashboard

**Cliquer** : "Save" (en haut)

**Titre** : "SOC Overview"

**Cliquer** : "Save"

---

## Phase 3 : Dashboard détail VM1

### 3.1 - Créer nouveau dashboard

```
Dashboards → New Dashboard
```

### 3.2 - Panels détail pour VM1

#### Panel 1 : CPU détail VM1

**Requête**
```promql
rate(node_cpu_seconds_total{instance="10.0.0.5:9100", mode=~"user|system"}[5m]) * 100
```

**Configuration**
```
Visualization: Time series
Legend: show (by mode)
Stack: true
```

**Titre** : "VM1 CPU (User + System)"

---

#### Panel 2 : RAM détail VM1

**Requête**
```promql
node_memory_MemFree_bytes{instance="10.0.0.5:9100"} / 1024^3
```

**Configuration**
```
Visualization: Graph
Unit: GB
```

**Titre** : "VM1 Memory Free (GB)"

---

#### Panel 3 : Disque détail VM1

**Requête**
```promql
(1 - node_filesystem_avail_bytes{instance="10.0.0.5:9100", mountpoint="/"} / node_filesystem_size_bytes{instance="10.0.0.5:9100", mountpoint="/"}) * 100
```

**Configuration**
```
Visualization: Gauge / Stat
Unit: percent
```

**Titre** : "VM1 Disk Usage"

---

#### Panel 4 : Load Average VM1

**Requête**
```promql
node_load1{instance="10.0.0.5:9100"}
```

**Configuration**
```
Visualization: Time series
```

**Titre** : "VM1 Load Average (1m)"

---

#### Panel 5 : Service Status (Table)

**Requête**
```promql
up{instance=~"10.0.0.5:.*"}
```

**Configuration**
```
Visualization: Table
Columns: job, instance, value
Value mapping: 1 → "Up", 0 → "Down"
```

**Titre** : "VM1 Services"

---

### 3.3 - Sauvegarder

**Titre** : "VM1 - Web Server Deep Dive"

---

## Phase 4 : Dashboard incidents

### 4.1 - Créer dashboard d'alertes

```
New Dashboard
```

### 4.2 - Panel : Anomalies détectées

**Requête** (CPU élevé)
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```

**Configuration**
```
Visualization: Alerts (ou Table)
Color: Red if value > 0
```

**Titre** : "High CPU (>80%)"

---

**Requête** (RAM élevée)
```promql
(1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes)) * 100 > 90
```

**Titre** : "High Memory (>90%)"

---

**Requête** (Disque plein)
```promql
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 > 85
```

**Titre** : "Disk Almost Full (>85%)"

---

### 4.3 - Sauvegarder

**Titre** : "Alerts & Anomalies"

---

## Phase 5 : Variables & Templates

### 5.1 - Rendre dashboards réutilisables avec variables

Aller au dashboard "SOC Overview"

**Éditeur** (crayon en haut)

**Settings** → **Variables** → **New variable**

```
Name: instance
Label: Host
Type: Query
Datasource: Prometheus
Query: label_values(up, instance)
```

**Répéter** pour : `job`, `mountpoint`

### 5.2 - Utiliser variable dans requête

Remplacer IP hardcodée par `$instance`

**Exemple (avant)**
```promql
up{instance="10.0.0.5:9100"}
```

**Exemple (après)**
```promql
up{instance=~"$instance"}
```

---

## Phase 6 : Exporter les dashboards

### 6.1 - Exporter en JSON

Dashboard → **Dashboard settings** (en haut)

```
JSON Model
```

**Copier** le contenu JSON complet.

**Créer fichier** : `grafana_soc_overview.json`

**Utilité** : Réimporter rapidement sur autre instance.

### 6.2 - Réimporter un dashboard

```
Dashboards → Import
Coller le JSON
Sélectionner data source Prometheus
Cliquer Import
```

---

## Phase 7 : Alertes Grafana (optionnel)

### 7.1 - Configurer notification channel

```
Configuration → Notification channels
```

**Créer un channel** :
```
Type: Email / Webhook / Slack
Name: SOC Alerts
```

**Exemple Webhook** (pour incidents)
```
URL: http://<IP_VM3>:8080/alerts
```

### 7.2 - Ajouter alertes aux panels

Panel → Alert → New alert

```
Condition: node_memory_MemFree_bytes < 536870912 (500MB)
For: 5m
Send to: SOC Alerts
```

---

## Phase 8 : Personalisation avancée

### 8.1 - Ajouter annotations

**Dashboard Settings** → **Annotations**

```
Name: Incidents
Data source: Prometheus
Query: ALERTS{severity="critical"}
```

### 8.2 - Auto-refresh

En haut à droite :
```
Refresh Rate: 30s (ou 1m)
```

### 8.3 - Thème sombre

**Profile** → **Preferences**
```
UI Theme: Dark
```

---

## Checklist création dashboards

```
✅ Dashboard SOC Overview
   [ ] Panel VM Status (table)
   [ ] Panel Alerts Count (stat)
   [ ] Panel CPU (gauge)
   [ ] Panel RAM (gauge)
   [ ] Panel Disk (pie/gauge)
   [ ] Panel Network (graph)
   
✅ Dashboard VM1 Deep Dive
   [ ] Panel CPU detail (time series)
   [ ] Panel RAM detail (graph)
   [ ] Panel Disk detail (gauge)
   [ ] Panel Load (graph)
   [ ] Panel Services (table)
   
✅ Dashboard Alerts & Anomalies
   [ ] Panel High CPU alert
   [ ] Panel High Memory alert
   [ ] Panel Disk Full alert
   
✅ Features avancées
   [ ] Variables ($instance, $job)
   [ ] Auto-refresh 30s
   [ ] Thème personnalisé
   [ ] JSON exportés
```

---

## Exercices pratiques

### Exercice 1 : Créer panel personnalisé

```
[ ] Créer un panel "Network Errors"
[ ] Requête : rate(node_network_transmit_errs_total[5m])
[ ] Visualisation : Time series
[ ] Ajouter au dashboard Alerts
```

### Exercice 2 : Créer alerte

```
[ ] Panel : CPU > 80% pendant 5 min
[ ] Ajouter notification email
[ ] Tester : générer charge CPU pour déclencher alerte
```

### Exercice 3 : Dashboard personnalisé

```
[ ] Créer dashboard "Security Monitoring"
[ ] Panels : 
    - SSH failed logins
    - Failed sudo attempts
    - Port scans detected
    - Firewall blocks
```

---

## Troubleshooting dashboards

### Les données ne s'affichent pas

```
1. Vérifier data source Prometheus
   Configuration → Data Sources → Prometheus → Test
   
2. Vérifier requête PromQL
   Aller à http://<IP_VM3>:9090 → tester requête
   
3. Vérifier dates
   Panel → Time range (en haut) → Last 1h
   
4. Logs Grafana
   sudo journalctl -u grafana-server -f
```

### Les panels sont vides

```
1. Data source n'est pas sélectionnée
   Panel → Edit → Data source : "Prometheus"
   
2. Targets DOWN dans Prometheus
   http://<IP_VM3>:9090/targets
   
3. Metrics inexistantes
   Tester manuellement :
   curl http://<IP_VM3>:9090/api/v1/query?query=<REQUETE>
```

---

## Résumé dashboards créés

| Dashboard | Panneaux | Utilité |
|-----------|----------|---------|
| SOC Overview | 6 | Vue globale infrastructure |
| VM1 Deep Dive | 5 | Analyse détail VM1 |
| Alerts & Anomalies | 4 | Détection incidents |

---

## Prochaines étapes

👉 **Retour à la documentation principale**

Les dashboards sont maintenant opérationnels. Passer à :
- Configuration des alertes Wazuh
- Intégration avec SOC (logs centralisés)
- Playbooks d'incident response

---

## Ressources Grafana

**Documentation**
- Grafana dashboards : https://grafana.com/docs/grafana/latest/features/dashboards/
- Panels : https://grafana.com/docs/grafana/latest/panels/
- Alerting : https://grafana.com/docs/grafana/latest/alerting/

**Dashboards publics**
```
Grafana Marketplace : https://grafana.com/grafana/dashboards/
Chercher : "Prometheus" ou "Node Exporter"
Importer et adapter
```

---

## Livrables du Rôle 3 (Supervision)

À cette étape, vous avez complété :

```
✅ Installation Prometheus + Grafana
✅ Configuration Node Exporter (VM1, VM2)
✅ Dashboards monitoring
✅ Alertes anomalies
```

Reste :
```
❌ Playbooks Incident Response
❌ Scripts d'auto-réaction (optionnel)
❌ Intégration Wazuh → Prometheus
```

---

**Temps réel par activité**
- Préparation Grafana : 10 min
- Dashboard principal : 45 min
- Dashboard VM1 : 30 min
- Dashboard Alertes : 20 min
- Variables & templates : 15 min
- Personnalisation : 20 min
- **Total : ~2h20**
