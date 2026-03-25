# 🔍 VM2 - SOC / WAZUH MANAGER INSTALLATION GUIDE

## 📖 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Prérequis](#prérequis)
3. [Contenu du script](#contenu-du-script)
4. [Installation](#installation)
5. [Vérification](#vérification)
6. [Configuration agents](#configuration-agents)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Vue d'ensemble

**VM2** est le **cœur du SOC** (Security Operations Center). C'est le serveur central qui :
- Reçoit les logs de toutes les machines
- Détecte les intrusions et attaques
- Génère des alertes en temps réel
- Stocke l'historique complet

### Rôle
- **Wazuh Manager:** Reçoit les logs, crée les alertes
- **Elasticsearch:** Stockage et indexation des logs
- **Kibana:** Visualisation et dashboards

### Caractéristiques
- **OS:** Rocky Linux 9
- **IP:** 192.168.1.200
- **RAM:** 4 GB recommandé
- **Disk:** 60 GB (logs consomment de l'espace)

---

## ⚙️ Prérequis

### Machine virtuelle
- **CPU:** 2 cores
- **RAM:** 4 GB (minimum 2, 8 GB recommandé)
- **Disk:** 60 GB (peut grandir avec les logs)
- **Network:** Bridged/NAT

### Accès réseau
```
VM1 (192.168.1.100) → VM2 (port 1514)  [logs]
VM3 (192.168.1.210) → VM2 (port 1514)  [logs]
```

### Ressources
- Internet pour télécharger Wazuh, Elasticsearch, Kibana
- 20-30 GB d'espace disque libre

---

## 📝 Contenu du script

Le script `vm2_install.sh` installe **8 étapes principales** :

### Étape 1: System Updates
```bash
dnf update -y
dnf install -y wget curl vim nano git gnupg
```
- Met à jour Rocky Linux
- Installe les dépendances

### Étape 2: Hostname
```bash
hostnamectl set-hostname vm2-soc
```

### Étape 3: Firewall Configuration
```
Ports ouverts:
- 514/tcp   (rsyslog - logs entrantes)
- 514/udp   (rsyslog - logs entrantes)
- 1514/tcp  (Wazuh agent registration + communication)
- 1514/udp  (Wazuh agent communication)
- 443/tcp   (Wazuh HTTPS dashboard)
- 9200/tcp  (Elasticsearch API)
- 9100/tcp  (Node Exporter metrics)
```

### Étape 4: Wazuh Manager Installation ⭐

#### Qu'est-ce que Wazuh ?
- **SIEM** = Security Information and Event Management
- **IDS** = Intrusion Detection System
- Analyse les logs et détecte les patterns malveillants
- Génère des alertes en temps réel

#### Installation
```bash
# Add repository
cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

dnf install -y wazuh-manager
systemctl start wazuh-manager
```

#### Composants
- **Manager:** Analyse les logs, génère alertes
- **Agent:** Installé sur VM1/VM3, envoie les logs
- **API:** Port 1514-1515 (communication)
- **Dashboard:** Port 443 (interface web)

### Étape 5: Elasticsearch Installation ⭐

#### Qu'est-ce qu'Elasticsearch ?
- Base de données pour les logs
- Indexation super rapide (millions de logs/sec)
- Recherche en temps réel
- Stockage à long terme

#### Installation
```bash
# Java required
dnf install -y java-17-openjdk java-17-openjdk-devel

# Download and install
dnf install -y elasticsearch-8.11.0

# Configure
sed -i 's/#network.host: .*/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
sed -i 's/#discovery.type:.*/discovery.type: single-node/' /etc/elasticsearch/elasticsearch.yml

systemctl start elasticsearch
```

#### Index Pattern
```
Chaque jour, Elasticsearch crée un nouvel index:
- wazuh-alerts-2026.02.06
- wazuh-alerts-2026.02.07
- etc.

Permet de garder les données organisées.
```

### Étape 6: Kibana Installation ⭐

#### Qu'est-ce que Kibana ?
- Interface web pour visualiser les logs
- Dashboards et graphiques
- Recherche et filtrage avancé
- Analyse en temps réel

#### Installation
```bash
dnf install -y kibana-8.11.0

sed -i 's/#server.host: .*/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
sed -i 's/#elasticsearch.hosts: .*/elasticsearch.hosts: ["http:\/\/localhost:9200"]/' /etc/kibana/kibana.yml

systemctl start kibana
```

#### Accès
- URL: http://VM2_IP:5601
- Visualise tous les logs stockés dans Elasticsearch

### Étape 7: rsyslog Configuration

#### Qu'est-ce que rsyslog ?
- Reçoit les logs entrants (UDP/TCP)
- Peut les rediriger vers files ou autres services
- En écoute sur ports 514

#### Configuration
```bash
$ModLoad imudp
$UDPServerRun 514

$ModLoad imtcp
$InputTCPServerRun 514

# Store logs
:fromhost-ip /var/log/wazuh/agents.log
```

#### Flux logs
```
VM1 (logs) 
    ↓ rsyslog:514
VM2 (rsyslog reception)
    ↓ fichier /var/log/wazuh/agents.log
    ↓ Wazuh Agent sur VM2 les relit
Wazuh Manager
    ↓ analyse + alertes
Elasticsearch (stockage)
    ↓
Kibana (visualisation)
```

### Étape 8: Node Exporter

```bash
# Prometheus exporter for metrics
node_exporter-1.7.0

# Port 9100
# Exporte CPU, RAM, Disk, Network
```

---

## 🚀 Installation

### 1. Préparer VM2
```bash
# Copier script sur VM2
scp vm2_install.sh admin@192.168.1.200:~/
```

### 2. Lancer le script
```bash
sudo bash vm2_install.sh
```

**Output attendu:**
```
╔════════════════════════════════════════════╗
║   VM2 - SOC INSTALLATION                  ║
║   Wazuh Manager - Mini SOC Project        ║
╚════════════════════════════════════════════╝

[INFO] Step 1/8 - Updating system...
[✓] System updated
...
[✓] VM2 INSTALLATION COMPLETED SUCCESSFULLY!

🌐 WEB ACCESS:
  • Wazuh Dashboard: https://192.168.1.200:443
  • Kibana: http://192.168.1.200:5601
```

### 3. Durée
```
⏱️ Temps total: 15-20 minutes
```

---

## ✅ Vérification

Après installation, tester :

### Wazuh Manager Status
```bash
sudo /var/ossec/bin/wazuh-control status

# Attendu:
# wazuh-authd is running
# wazuh-remoted is running
# wazuh-analysisd is running
# etc.
```

### Elasticsearch Status
```bash
curl http://localhost:9200

# Attendu: JSON avec info Elasticsearch
{
  "name" : "node-1",
  "version" : { "number" : "8.11.0" },
  ...
}
```

### Kibana Access
```bash
curl http://localhost:5601

# Attendu: Page HTML Kibana
```

### Firewall Ports
```bash
sudo firewall-cmd --list-all

# Vérifier ports ouverts:
# 514, 1514, 443, 9200, 9100
```

### Wazuh Web UI
```
Accéder à: https://192.168.1.200:443
Credentials: admin / SecretPassword

Interface web Wazuh
- Dashboard
- Agents (0 actuellement)
- Modules (File Integrity, Rootkit Detection, etc.)
```

---

## 🔐 Sécurité

### Changer credentials immédiatement !

```bash
# Sur VM2:
sudo /var/ossec/bin/wazuh-control set-password

# Changer admin password
# Entrer nouveau mot de passe 2x

# Redémarrer Wazuh
sudo systemctl restart wazuh-manager
```

### Backup important

```bash
# Sauvegarder Wazuh database
sudo tar -czf wazuh-backup.tar.gz /var/ossec/

# Sauvegarder Elasticsearch
sudo curl -XGET 'http://localhost:9200/_snapshot/my_backup' > backup.json
```

---

## 📋 Configuration des agents

### Enregistrer Wazuh Agents

Après VM2 installation, register VM1 & VM3 agents:

#### 1. Obtenir la clé d'enregistrement

**Sur VM2:**
```bash
sudo /var/ossec/bin/manage_agents

# Menu:
# a) Add agent
# Entrer:
# - Name: vm1-web (ou vm3-monitoring)
# - IP: 192.168.1.100 (ou 192.168.1.210)
# Obtenir: Agent ID + Key (longue string)
```

#### 2. Configurer l'agent

**Sur VM1 (ou VM3):**
```bash
# Éditer config agent:
sudo nano /var/ossec/etc/ossec.conf

# Modifier:
<manager>
  <ip>192.168.1.200</ip>
  <protocol>tcp</protocol>
</manager>

# Importer la clé reçue:
sudo /var/ossec/bin/manage_agents

# Menu:
# i) Import key
# Coller la clé complète

# Redémarrer agent:
sudo systemctl restart wazuh-agent
```

#### 3. Vérifier la connexion

**Sur VM2:**
```bash
sudo /var/ossec/bin/wazuh-control status

# Attendu: agents connectés

# Ou dans Wazuh UI:
# Agents → Voir agent "vm1-web" en "Active"
```

---

## 📊 Monitoring des logs

### Voir les logs entrants

```bash
# Logs bruts reçus:
sudo tail -f /var/log/wazuh/agents.log

# Logs Wazuh Manager:
sudo tail -f /var/ossec/logs/alerts.log

# Logs Elasticsearch:
sudo tail -f /var/log/elasticsearch/elasticsearch.log
```

### Rechercher un événement

**Dans Kibana:**
1. Aller à http://192.168.1.200:5601
2. Créer index pattern: wazuh-alerts-*
3. Rechercher par:
   - Hostname: vm1-web
   - Rule ID: 5403 (Brute force)
   - Severity: 7+
   - etc.

---

## 🚨 Alertes d'exemple

### Brute Force SSH Detection
```
Rule: Multiple authentication failures (5 fails in 60 sec)
Level: 7 (Warning)
Source: vm1-web
Action: Logged and alerted
```

### Privilege Escalation
```
Rule: sudo command executed
Level: 5-7
Source: vm1-web
Pattern: sudo whoami ou sudo -u root
```

### System File Modification
```
Rule: /etc/passwd modification
Level: 8
Source: any
Pattern: Change detected by auditd
```

---

## ❌ Troubleshooting

### Problème: Agents ne se connectent pas

**Solutions:**
```bash
# Vérifier firewall:
sudo firewall-cmd --list-all
# Port 1514 doit être ouvert

# Vérifier Wazuh Manager:
sudo /var/ossec/bin/wazuh-control status

# Vérifier config agent:
sudo nano /var/ossec/etc/ossec.conf
# Manager IP doit être 192.168.1.200

# Logs agent:
sudo tail -f /var/ossec/logs/ossec.log
```

### Problème: Elasticsearch disk full

**Solutions:**
```bash
# Voir usage:
df -h /var/lib/elasticsearch

# Nettoyer vieux indices:
curl -XDELETE 'http://localhost:9200/wazuh-alerts-2026.01.*'

# Ajouter disque ou archiver données
```

### Problème: Kibana ne répond pas

**Solutions:**
```bash
# Redémarrer Kibana:
sudo systemctl restart kibana

# Vérifier logs:
sudo tail -f /var/log/kibana/kibana.log

# Vérifier Elasticsearch accessible:
curl http://localhost:9200
```

### Problème: Mémoire insuffisante

**Solutions:**
```bash
# Réduire heap Elasticsearch:
sudo nano /etc/elasticsearch/jvm.options

# Modifier (pour 4 GB RAM):
-Xms1g
-Xmx1g

# Redémarrer:
sudo systemctl restart elasticsearch
```

---

## 📈 Performance

### Ressources typiques

| Composant | CPU | RAM | Disk |
|-----------|-----|-----|------|
| Wazuh Manager | 10-15% | 500 MB | 1 GB |
| Elasticsearch | 20-30% | 1-2 GB | 50+ GB |
| Kibana | 5-10% | 300 MB | 100 MB |
| **Total** | **35-55%** | **2-3 GB** | **51+ GB** |

---

## 🔄 Mise à jour

```bash
# Mettre à jour Wazuh:
sudo dnf install -y --upgrade wazuh-manager

# Mettre à jour Elasticsearch:
sudo dnf install -y --upgrade elasticsearch

# Redémarrer:
sudo systemctl restart wazuh-manager
sudo systemctl restart elasticsearch
```

---

## 📝 Notes importantes

⚠️ **À faire après installation:**

1. ✅ Changer credentials admin
2. ✅ Enregistrer agents VM1 & VM3
3. ✅ Vérifier logs arrivent dans Wazuh
4. ✅ Créer dashboards Kibana
5. ✅ Configurer alertes par email (optionnel)
6. ✅ Backup configuration

---

## 🎓 Pour aller plus loin

### Documentation
- [Wazuh Official Docs](https://documentation.wazuh.com/)
- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana User Guide](https://www.elastic.co/guide/en/kibana/current/index.html)

### Améliorer détection
- Ajouter custom rules Wazuh
- Créer playbooks d'automatisation
- Intégrer alertes email/Slack
- Configurer sysmon (advanced logging)

---

## ✅ Checklist Finale

```
Avant de passer aux agents:
[ ] Script exécuté sans erreurs
[ ] Wazuh Manager status: running
[ ] Elasticsearch running
[ ] Kibana accessible (http://IP:5601)
[ ] Firewall ports ouverts
[ ] Admin credentials changés
[ ] Node Exporter running (port 9100)
[ ] No errors in /var/ossec/logs/ossec.log
[ ] IP correcte (192.168.1.200)
```

---

**Version:** 1.0  
**Date:** Février 2026  
**Status:** Production Ready ✅
