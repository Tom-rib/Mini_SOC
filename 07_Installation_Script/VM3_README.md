# 📊 VM3 - MONITORING & INCIDENT RESPONSE INSTALLATION GUIDE

## 📖 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Prérequis](#prérequis)
3. [Contenu du script](#contenu-du-script)
4. [Installation](#installation)
5. [Configuration Grafana](#configuration-grafana)
6. [Incident Response](#incident-response)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Vue d'ensemble

**VM3** est le **centre de supervision et de réaction** du projet Mini SOC. C'est le point central pour :
- Monitorer la santé des systèmes
- Créer des dashboards et alertes
- Automatiser les réactions aux incidents
- Analyser les tendances

### Rôle
- **Prometheus:** Collecte les métriques (CPU, RAM, Disk, etc.)
- **Grafana:** Visualisation et dashboards
- **Ansible:** Automatisation des réactions
- **IR Scripts:** Blocage IP, isolation, etc.

### Caractéristiques
- **OS:** Rocky Linux 9
- **IP:** 192.168.1.210
- **Services:** Prometheus, Grafana, Node Exporter
- **RAM:** 4 GB

---

## ⚙️ Prérequis

### Machine virtuelle
- **CPU:** 2 cores
- **RAM:** 4 GB
- **Disk:** 60 GB
- **Network:** Bridged/NAT

### Accès réseau
```
VM3 → VM1 (192.168.1.100:9100) [collecte métriques]
VM3 → VM2 (192.168.1.200:9100) [collecte métriques]
VM3 → VM3 (localhost:9100)      [propres métriques]
```

---

## 📝 Contenu du script

Le script `vm3_install.sh` installe **7 étapes principales** :

### Étape 1: System Updates
```bash
dnf update -y
dnf install -y wget curl vim nano git
```

### Étape 2: Hostname
```bash
hostnamectl set-hostname vm3-monitoring
```

### Étape 3: Firewall Configuration
```
Ports ouverts:
- 9090/tcp   (Prometheus)
- 3000/tcp   (Grafana)
- 9100/tcp   (Node Exporter)
- 1514/tcp   (Wazuh agent)
- 1514/udp   (Wazuh agent)
```

### Étape 4: Prometheus Installation ⭐

#### Qu'est-ce que Prometheus ?
- **Time Series Database** pour les métriques
- Scrape les exporters (Node Exporter)
- Stocke les données avec timestamp
- Permet les alertes basées sur seuils
- Historique 15 jours par défaut

#### Installation
```bash
# Créer utilisateur
useradd --no-create-home --shell /bin/false prometheus

# Télécharger et installer
wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz
cp prometheus /usr/local/bin/
```

#### Configuration
```yaml
# /etc/prometheus/prometheus.yml

global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'vm1_web'
    static_configs:
      - targets: ['192.168.1.100:9100']
  
  - job_name: 'vm2_soc'
    static_configs:
      - targets: ['192.168.1.200:9100']
  
  - job_name: 'vm3_monitoring'
    static_configs:
      - targets: ['localhost:9100']
```

#### Métriques collectées
```
CPU:
  - node_cpu_seconds_total
  - node_load1, node_load5, node_load15
  
Mémoire:
  - node_memory_MemAvailable_bytes
  - node_memory_MemFree_bytes
  - node_memory_MemTotal_bytes
  
Disque:
  - node_filesystem_avail_bytes
  - node_filesystem_size_bytes
  - node_filesystem_readonly
  
Réseau:
  - node_network_receive_bytes_total
  - node_network_transmit_bytes_total
```

### Étape 5: Grafana Installation ⭐

#### Qu'est-ce que Grafana ?
- Interface web pour visualiser les métriques
- Dashboards personnalisés
- Alertes avec notifications
- Multiple sources de données
- Historique complet

#### Installation
```bash
dnf install -y https://dl.grafana.com/oss/release/grafana-10.2.0-1.x86_64.rpm
systemctl start grafana-server
```

#### Interface
```
http://VM3_IP:3000

Accueil:
├─ Dashboards (créer/importer)
├─ Explore (rechercher métriques)
├─ Alerting (configurer alertes)
├─ Configuration (datasources, users)
└─ Settings (admin)
```

#### Datasources
```
Qu'est-ce qu'un datasource ?
= Connection vers Prometheus
Permet à Grafana de lire les métriques

Configuration:
1. Go to Settings → Data Sources
2. Add Prometheus
3. URL: http://localhost:9090
4. Click Save & Test
```

### Étape 6: Node Exporter Installation

#### Qu'est-ce que Node Exporter ?
- Exporte les métriques du système
- Lightweight (5MB)
- Port 9100
- Format Prometheus

#### Métriques exportées
- CPU, RAM, Disk
- Processus
- File descriptors
- Network interfaces
- etc.

#### Chaque VM a son exporter
```
VM1: Node Exporter sur port 9100
     Prometheus scrape 192.168.1.100:9100
     
VM2: Node Exporter sur port 9100
     Prometheus scrape 192.168.1.200:9100
     
VM3: Node Exporter sur localhost:9100
     Prometheus scrape localhost:9100
```

### Étape 7: Wazuh Agent + Ansible + IR Scripts

#### Wazuh Agent
```bash
# Envoie les logs vers VM2 Manager
# Configuration après pour connecter à 192.168.1.200
```

#### Ansible
```bash
# Automation framework
# Permet lancer des actions sur plusieurs VMs
# Crée des playbooks pour réaction incidents
```

#### IR Scripts
```bash
# Scripts Bash pour Incident Response
# Exemple: /opt/ir-scripts/block_ip.sh
# Usage: ./block_ip.sh 192.168.1.50
# Effet: Bloque IP au firewall
```

---

## 🚀 Installation

### 1. Préparer VM3
```bash
scp vm3_install.sh admin@192.168.1.210:~/
```

### 2. Lancer le script
```bash
sudo bash vm3_install.sh
```

**Output attendu:**
```
╔════════════════════════════════════════════╗
║   VM3 - MONITORING & IR INSTALLATION       ║
║   Prometheus + Grafana                     ║
╚════════════════════════════════════════════╝

[INFO] Step 1/7 - Updating system...
[✓] System updated
...
[✓] VM3 INSTALLATION COMPLETED SUCCESSFULLY!

🌐 WEB ACCESS:
  • Prometheus: http://192.168.1.210:9090
  • Grafana: http://192.168.1.210:3000
```

### 3. Durée
```
⏱️ Temps total: 10-15 minutes
```

---

## ✅ Vérification

Après installation :

### Prometheus
```bash
curl http://localhost:9090

# Accédez à http://192.168.1.210:9090
# - Status → Targets
# Vérifier les 3 jobs "UP"
```

### Node Exporter
```bash
curl http://localhost:9100/metrics

# Attendu: Métriques en format Prometheus
# node_cpu_seconds_total{...} ...
```

### Grafana
```bash
curl http://localhost:3000

# Accédez à http://192.168.1.210:3000
# Login: admin / admin
```

### Firewall
```bash
sudo firewall-cmd --list-all

# Vérifier ports:
# 9090, 3000, 9100, 1514
```

---

## ⚙️ Configuration Grafana

### 1. Changer le mot de passe

```
1. Accédez à http://192.168.1.210:3000
2. Cliquez sur votre profil (coin bas-gauche)
3. Change password
4. Entrez nouveau mot de passe
```

### 2. Ajouter Prometheus datasource

```
1. Settings (roue) → Data Sources
2. Add data source
3. Sélectionner Prometheus
4. URL: http://localhost:9090
5. Click "Save & Test"
6. "Data source is working" = OK
```

### 3. Créer un dashboard

#### Dashboard exemple: Système Overview

```
1. Create → Dashboard
2. Add panel
   Titre: CPU Usage
   Metric: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   
3. Add panel
   Titre: Memory Usage
   Metric: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
   
4. Add panel
   Titre: Disk Usage
   Metric: (node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100
```

#### Visualisations
```
- Graph: Courbes dans le temps
- Gauge: Affichage circulaire
- Stat: Grand nombre
- Table: Données tabulaires
- Pie chart: Proportions
```

### 4. Configurer les alertes

```
1. Alerting → Alert rules
2. Create alert
   Condition: CPU > 80%
   Notification: Email / Slack
3. Set up notification channels
4. Test
```

---

## 🚨 Incident Response

### Automation avec Ansible

#### Créer un playbook pour bloquer IP

```bash
# /opt/ansible/playbooks/block_ip.yml
---
- hosts: all
  tasks:
    - name: Block IP in firewall
      command: |
        sudo firewall-cmd --permanent \
        --add-rich-rule="rule family='ipv4' source address='{{ attacker_ip }}' reject"
      vars:
        attacker_ip: "192.168.1.50"
```

#### Exécuter le playbook

```bash
ansible-playbook /opt/ansible/playbooks/block_ip.yml
```

### Scripts IR manuels

#### Block IP manuellement

```bash
# Sur VM3 ou VM1:
/opt/ir-scripts/block_ip.sh 192.168.1.50

# Effet immédiat:
# IP 192.168.1.50 bloquée au firewall
```

### Trigger automatique

#### Depuis Grafana alert

```
Quand CPU > 90%:
  → Envoyer notification
  → Optionnel: Exécuter webhook
  → Webhook appelle script IR
  → Script lance Ansible
  → Isolation automatique
```

---

## 📊 Métriques importantes

### Santé système

| Métrique | Seuil normal | Alerte |
|----------|-------------|--------|
| CPU | < 50% | > 80% |
| RAM | < 75% | > 85% |
| Disk | < 80% | > 90% |
| Load Average | < 2 | > 4 |
| Network I/O | Variable | Pic suspect |

### Détection anomalies

```
Baseline = moyenne sur 7 jours

Alerte si:
  Métrique > Baseline + 2x StdDev

Exemple:
  RAM normal = 2 GB
  Soudain = 3.8 GB
  → Processus malveillant potentiel
```

---

## ❌ Troubleshooting

### Problème: Prometheus ne scrape pas

**Solutions:**
```bash
# Vérifier config:
sudo nano /etc/prometheus/prometheus.yml

# Redémarrer Prometheus:
sudo systemctl restart prometheus

# Vérifier logs:
sudo journalctl -u prometheus -n 50
```

### Problème: Grafana ne voit pas Prometheus

**Solutions:**
```bash
# Vérifier Prometheus accessible:
curl http://localhost:9090

# Tester datasource depuis Grafana:
Settings → Data Sources → Prometheus → Test

# Vérifier firewall:
sudo firewall-cmd --list-all
```

### Problème: Node Exporter no data

**Solutions:**
```bash
# Vérifier service:
sudo systemctl status node_exporter

# Vérifier port:
sudo ss -tlnp | grep 9100

# Test sur chaque VM:
curl http://VM_IP:9100/metrics
```

### Problème: Grafana mémoire insuffisante

**Solutions:**
```bash
# Réduire heap:
sudo nano /etc/sysconfig/grafana-server

# Ajouter:
GF_SERVER_MAX_COOKIE_AGE=3600

# Redémarrer:
sudo systemctl restart grafana-server
```

---

## 📈 Performance

### Ressources typiques

| Composant | CPU | RAM | Disk |
|-----------|-----|-----|------|
| Prometheus | 5-10% | 200-500 MB | 5-10 GB |
| Grafana | 2-5% | 100-300 MB | 1 GB |
| Node Exporter | <1% | 20-50 MB | 0 MB |
| **Total** | **7-15%** | **500 MB-1 GB** | **6-11 GB** |

---

## 🔄 Mise à jour

```bash
# Mise à jour system:
sudo dnf update -y

# Mise à jour Prometheus:
# (télécharger nouvelle version)

# Mise à jour Grafana:
sudo dnf install -y --upgrade grafana

# Redémarrer:
sudo systemctl restart prometheus grafana-server
```

---

## 📝 Notes importantes

⚠️ **À faire après installation:**

1. ✅ Changer Grafana password
2. ✅ Ajouter Prometheus datasource
3. ✅ Vérifier les 3 jobs "UP" dans Prometheus
4. ✅ Créer premier dashboard
5. ✅ Configurer Wazuh Agent
6. ✅ Tester alertes

---

## 🎓 Pour aller plus loin

### Documentation
- [Prometheus Official](https://prometheus.io/)
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- [Ansible Documentation](https://docs.ansible.com/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### Améliorer le monitoring
- Ajouter scrape configs avancés
- Créer alertes complexes
- Intégrer avec Slack/PagerDuty
- Configurer sauvegardes metrics
- Créer playbooks Ansible

---

## 📚 Requêtes PromQL utiles

```promql
# CPU usage (%)
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage (%)
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage (%)
(node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100

# Network bandwidth (MB/s)
rate(node_network_receive_bytes_total[1m]) / 1024 / 1024

# Service up/down
up{job="vm1_web"}
```

---

## ✅ Checklist Finale

```
Avant de connecter les agents:
[ ] Script exécuté sans erreurs
[ ] Prometheus accessible (http://IP:9090)
[ ] Grafana accessible (http://IP:3000)
[ ] Prometheus voit les 3 targets "UP"
[ ] Grafana mot de passe changé
[ ] Prometheus datasource dans Grafana
[ ] Node Exporter running
[ ] Wazuh Agent installé
[ ] Firewall ports ouverts
[ ] IP correcte (192.168.1.210)
```

---

**Version:** 1.0  
**Date:** Février 2026  
**Status:** Production Ready ✅
