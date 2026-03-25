# Aide-mémoire Supervision - Commandes essentielles

**Imprimer cette page ou copier dans terminal au besoin**

---

## 🚀 Démarrage rapide (cheatsheet)

### Installation (une seule fois)

```bash
# Sur VM3 (Monitoring)
sudo bash install_prometheus.sh
sudo bash install_grafana.sh

# Sur VM1 et VM2
sudo bash install_node_exporter.sh
```

### Modification configuration

```bash
# Éditer Prometheus config
sudo vim /etc/prometheus/prometheus.yml

# Recharger sans redémarrer
sudo systemctl reload prometheus

# Vérifier syntaxe
promtool check config /etc/prometheus/prometheus.yml
```

---

## 📊 Accès services

```
Prometheus    : http://<IP_VM3>:9090
Grafana       : http://<IP_VM3>:3000
              Login: admin / admin

Node Exporter VM1 : http://<IP_VM1>:9100/metrics
Node Exporter VM2 : http://<IP_VM2>:9100/metrics
```

---

## 🔍 Vérifier statut services

```bash
# Prometheus
sudo systemctl status prometheus
sudo systemctl start prometheus
sudo systemctl stop prometheus
sudo systemctl restart prometheus
sudo systemctl reload prometheus

# Grafana
sudo systemctl status grafana-server
sudo systemctl start grafana-server
sudo systemctl stop grafana-server

# Node Exporter
sudo systemctl status node_exporter
sudo systemctl start node_exporter
sudo systemctl stop node_exporter
```

---

## 📋 Logs en temps réel

```bash
# Prometheus logs
sudo journalctl -u prometheus -f

# Grafana logs
sudo journalctl -u grafana-server -f

# Node Exporter logs
sudo journalctl -u node_exporter -f

# Alternative : fichiers logs
tail -100f /var/log/grafana/grafana.log
```

---

## 🔌 Vérifier connectivité

```bash
# Prometheus est accessible ?
curl http://localhost:9090

# Grafana est accessible ?
curl http://localhost:3000

# Node Exporter répond ?
curl http://localhost:9100/metrics

# Depuis autre machine
curl http://<IP_VM3>:9090
curl http://<IP_VM1>:9100/metrics

# Test connexion avec telnet
telnet <IP_VM1> 9100

# Ports en écoute
sudo ss -tlnp | grep -E "9090|3000|9100"
```

---

## 🌐 Firewall (si besoin)

```bash
# Ajouter port Prometheus
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --reload

# Ajouter port Grafana
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

# Ajouter port Node Exporter
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload

# Vérifier ports ouverts
sudo firewall-cmd --list-all
```

---

## 📈 PromQL : 10 requêtes clés

### Dans http://<IP_VM3>:9090/graph

```promql
# 1. CPU utilisé (%)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 2. RAM utilisée (%)
(1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes)) * 100

# 3. Disque utilisé (%) - partition root
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100

# 4. Load average 1 min
node_load1

# 5. Bande passante reçue (Mbps)
rate(node_network_receive_bytes_total{device="eth0"}[5m]) * 8 / 1000000

# 6. Bande passante émise (Mbps)
rate(node_network_transmit_bytes_total{device="eth0"}[5m]) * 8 / 1000000

# 7. Services UP (1=actif, 0=down)
up{job=~"vm1|vm2"}

# 8. Alertes critiques
count(ALERTS{severity="critical"})

# 9. Taux d'erreurs SSH
rate(node_systemd_unit_state{name="sshd.service", state="failed"}[5m])

# 10. Comparer 2 VMs
{job=~"vm1|vm2"} and node_memory_MemFree_bytes
```

---

## 🎨 Grafana : Créer panel rapidement

### Via interface web (http://<IP_VM3>:3000)

```
1. Dashboards → New Dashboard
2. New Panel
3. Dans "Query" : coller requête PromQL
4. Dans "Visualization" : choisir type (Graph, Gauge, Table, etc.)
5. Configurer : Titre, Unit, Thresholds
6. Save Dashboard
```

**Types visualisation clés**
- **Time Series** : courbes dans le temps
- **Gauge** : aiguille 0-100% (CPU, RAM)
- **Table** : données tabulaires (logs, statuts)
- **Pie Chart** : disque utilisé
- **Stat** : nombre simple (alertes, serveurs down)

---

## 🔧 Configuration Prometheus : Ajouter cible

### Éditer `/etc/prometheus/prometheus.yml`

```yaml
scrape_configs:
  - job_name: 'ma-nouvelle-cible'
    static_configs:
      - targets: ['10.0.0.X:9100']
```

```bash
# Puis recharger
sudo systemctl reload prometheus

# Vérifier dans : http://<IP_VM3>:9090/targets
```

---

## 📧 Alertes : Configuration minimale (Grafana)

### Panel → Alert

```
Condition: 
  node_memory_MemFree_bytes < 536870912    (500MB)
For: 5 minutes
Send to: Email / Webhook

Puis cliquer Save
```

---

## 🛠️ Dépannage rapide

| Symptôme | Cause | Solution |
|----------|-------|----------|
| Prometheus n'écoute pas 9090 | Service arrêté | `sudo systemctl start prometheus` |
| Port 9090 indisponible | Autre service utilise port | `sudo ss -tlnp \| grep 9090` |
| Targets RED | Node Exporter down | `ssh <IP_VM> sudo systemctl restart node_exporter` |
| Grafana vide | Data source pas connectée | Configuration → Data Sources → Test |
| Requête PromQL vide | Métrique n'existe pas | Tester d'abord dans Prometheus web |
| Config refusée au reload | Syntaxe YAML | `promtool check config prometheus.yml` |
| Disque plein | Rétention données | Diminuer `retention.time` ou augmenter stockage |

---

## 📂 Chemins importants

```
/etc/prometheus/prometheus.yml        # Configuration principale
/var/lib/prometheus/                  # Base de données (TimeSeries)
/etc/systemd/system/prometheus.service # Service systemd
/etc/systemd/system/node_exporter.service
/etc/grafana/grafana.ini              # Config Grafana
/var/log/grafana/                     # Logs Grafana
```

---

## 🔐 Réinitialiser Grafana admin

```bash
# Si oublié mot de passe
sudo grafana-cli admin reset-admin-password <NOUVEAU_MOT_DE_PASSE>

# Exemple
sudo grafana-cli admin reset-admin-password MonNouveauMotDePasse123
```

---

## 📊 Requêtes utiles pour Blue Team

### Détection anomalies

```promql
# CPU > 80% (alerte)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80

# RAM < 500MB (critique)
node_memory_MemFree_bytes < 536870912

# Disque > 90% plein (alerte)
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 > 90

# Service DOWN
up == 0

# Charge système > nombre de CPUs
node_load1 > count(node_cpu_seconds_total{mode="idle"})
```

---

## 🚨 Incidents courants

### Prometheus plein disque

```bash
# Vérifier taille
du -sh /var/lib/prometheus/

# Diminuer rétention dans prometheus.yml
retention:
  size: 10GB      # Réduire
  time: 7d        # Réduire à 7 jours

# Recharger
sudo systemctl reload prometheus
```

### Grafana oubli config après restart

```bash
# Vérifier fichier config
sudo ls -la /var/lib/grafana/

# Réinitialiser base de données
sudo systemctl stop grafana-server
sudo rm /var/lib/grafana/grafana.db
sudo systemctl start grafana-server
```

### Node Exporter ne se lance pas

```bash
# Vérifier erreur
sudo journalctl -u node_exporter -n 20

# Problèmes courants:
# - Port 9100 déjà utilisé
# - Permissions fichier
# - Dépendances manquantes

sudo systemctl restart node_exporter
```

---

## 🧪 Tester une métrique rapidement

```bash
# Sur VM1/VM2, afficher métrique directement
curl http://localhost:9100/metrics | grep node_cpu

# Regarder structure JSON (API Prometheus)
curl 'http://localhost:9090/api/v1/query?query=up'

# Voir all labels disponibles
curl http://localhost:9090/api/v1/label/__name__/values
curl http://localhost:9090/api/v1/label/instance/values
```

---

## 📚 Ressources rapides

```
Prometheus docs : https://prometheus.io/docs/
Grafana docs : https://grafana.com/docs/grafana/
PromQL ref : https://prometheus.io/docs/prometheus/latest/querying/basics/
Node Exporter metrics : https://github.com/prometheus/node_exporter#enabled-by-default
```

---

## ✅ Checklist minimaliste

```
[ ] Prometheus démarre sans erreur
[ ] Grafana démarre et accessible
[ ] Node Exporter sur VM1 et VM2 tourne
[ ] Prometheus voit 3 targets en UP
[ ] Créer 1 dashboard basique avec 3 panels
[ ] Tester 5 requêtes PromQL
[ ] Créer 1 alerte simple
[ ] Documenter ports/IPs/accès
```

---

## 🚀 Quick Start (5 min)

```bash
# 1. SSH VM3
ssh admin@<IP_VM3>

# 2. Installation Prometheus
sudo bash install_prometheus.sh

# 3. Installation Grafana (dans un autre terminal)
sudo dnf install -y grafana-enterprise
sudo systemctl start grafana-server

# 4. SSH VM1 & VM2, installer Node Exporter
sudo bash install_node_exporter.sh

# 5. Éditer config Prometheus
sudo vim /etc/prometheus/prometheus.yml
# → Adapter IPs

# 6. Redémarrer
sudo systemctl reload prometheus

# 7. Ouvrir navigateur
# http://<IP_VM3>:9090/targets  ← Voir 3 targets UP
# http://<IP_VM3>:3000          ← Interface Grafana
```

**Durée : ~15 min si tout préparé**

---

**Dernière mise à jour** : Jan 2025  
**Prometheus version** : 2.48.1  
**Grafana version** : 10.2+  
**Node Exporter version** : 1.7.0
