# 🚀 MINI SOC - INSTALLATION GUIDE

## 📦 Fichiers à télécharger

Vous avez **6 fichiers** à utiliser:

### VM1 - Web Server
- **vm1_install.sh** - Script d'installation (400 lignes)
- **VM1_README.md** - Documentation complète (20+ pages)

### VM2 - SOC / Wazuh Manager
- **vm2_install.sh** - Script d'installation (350 lignes)
- **VM2_README.md** - Documentation complète (25+ pages)

### VM3 - Monitoring
- **vm3_install.sh** - Script d'installation (350 lignes)
- **VM3_README.md** - Documentation complète (20+ pages)

---

## 📋 Ordre d'installation

```
1️⃣ Créer 3 VMs Rocky Linux
2️⃣ Configurer le réseau (IPs statiques)
3️⃣ Installer VM1 (15 min)
4️⃣ Installer VM2 (20 min)
5️⃣ Installer VM3 (15 min)
6️⃣ Connecter les agents (10 min)

⏱️ TOTAL: ~70 minutes
```

---

## 🎯 Architecture finale

```
┌─────────────────────────────────────────────────────┐
│ Internet / Attacker                                 │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │    FIREWALL/NAT       │
         │  (VirtualBox Bridge)  │
         └───────────────┬───────┘
                         │
      ┌──────────────────┼──────────────────┐
      ▼                  ▼                  ▼
┌────────────┐    ┌────────────┐    ┌────────────┐
│   VM1      │    │   VM2      │    │   VM3      │
│ Web Server │    │ SOC/SIEM   │    │ Monitoring │
│192.168.1.  │    │192.168.1.  │    │192.168.1.  │
│   100      │    │   200      │    │   210      │
├────────────┤    ├────────────┤    ├────────────┤
│ • Nginx    │    │ • Wazuh    │    │ • Prometheus
│ • SSH:2222 │    │ • Elastic  │    │ • Grafana  │
│ • Fail2ban │    │ • Kibana   │    │ • Ansible  │
│ • Auditd   │    │ • rsyslog  │    │ • IR Tools │
│ • SELinux  │    │ • rsyslog  │    │            │
│ • Metrics  │    │ • Metrics  │    │ • Metrics  │
└────────────┘    └────────────┘    └────────────┘
      │ logs           ▲ logs            │
      └───────────────►┤◄────────────────┘
                       │
                    Alerts
                       │
                       ▼
                  IR Automation
                  (Playbooks/Scripts)
```

---

## 🔍 Réseau

### Configuration IPv4

```
VM1 - Web Server:
  IP: 192.168.1.100
  Gateway: 192.168.1.1
  DNS: 8.8.8.8

VM2 - SOC:
  IP: 192.168.1.200
  Gateway: 192.168.1.1
  DNS: 8.8.8.8

VM3 - Monitoring:
  IP: 192.168.1.210
  Gateway: 192.168.1.1
  DNS: 8.8.8.8
```

### Ports principaux

```
VM1:
  • 22    → FERMÉ (SSH disabled)
  • 2222  → SSH hardened
  • 80    → HTTP
  • 443   → HTTPS
  • 1514  → Wazuh agent
  • 9100  → Metrics

VM2:
  • 514   → rsyslog (logs reception)
  • 1514  → Wazuh agent registration
  • 443   → Wazuh Web UI
  • 9200  → Elasticsearch
  • 5601  → Kibana
  • 9100  → Metrics

VM3:
  • 9090  → Prometheus
  • 3000  → Grafana
  • 1514  → Wazuh agent
  • 9100  → Metrics
```

---

## 📖 Utilisation des fichiers

### Étape 1: Lire les README

**Avant d'exécuter les scripts, lisez COMPLÈTEMENT les fichiers README !**

```
VM1_README.md  → Comprendre ce que fait le hardening
VM2_README.md  → Comprendre Wazuh/Elasticsearch/Kibana
VM3_README.md  → Comprendre Prometheus/Grafana
```

Chaque README explique :
- Qu'est-ce qui est installé ?
- Pourquoi ?
- Comment ça marche ?
- Vérifications après installation
- Troubleshooting

### Étape 2: Copier les scripts

**Sur VM1:**
```bash
scp vm1_install.sh admin@192.168.1.100:~/
```

**Sur VM2:**
```bash
scp vm2_install.sh admin@192.168.1.200:~/
```

**Sur VM3:**
```bash
scp vm3_install.sh admin@192.168.1.210:~/
```

### Étape 3: Exécuter les scripts

**Sur VM1:**
```bash
ssh -p 2222 admin@192.168.1.100
sudo bash vm1_install.sh
# Durée: 15 minutes
```

**Sur VM2:**
```bash
ssh admin@192.168.1.200
sudo bash vm2_install.sh
# Durée: 20 minutes
```

**Sur VM3:**
```bash
ssh admin@192.168.1.210
sudo bash vm3_install.sh
# Durée: 15 minutes
```

---

## ✅ Vérifications post-installation

### VM1 - Web Server
```bash
# SSH port 2222
ssh -p 2222 admin@192.168.1.100

# Firewall
sudo firewall-cmd --list-all

# Services
sudo systemctl status sshd
sudo systemctl status nginx
sudo systemctl status fail2ban
sudo systemctl status auditd
sudo systemctl status node_exporter
```

### VM2 - SOC
```bash
# Services
sudo /var/ossec/bin/wazuh-control status
sudo systemctl status elasticsearch
sudo systemctl status kibana

# Accès
https://192.168.1.200:443  → Wazuh
http://192.168.1.200:5601  → Kibana
http://192.168.1.200:9100  → Metrics
```

### VM3 - Monitoring
```bash
# Services
sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status node_exporter

# Accès
http://192.168.1.210:9090  → Prometheus
http://192.168.1.210:3000  → Grafana
http://192.168.1.210:9100  → Metrics
```

---

## 🔐 Sécurité

### Credentials à changer

```
VM2 - Wazuh:
  Default: admin / SecretPassword
  Change: sudo /var/ossec/bin/wazuh-control set-password

VM3 - Grafana:
  Default: admin / admin
  Change: Settings → Change password
```

### SSH Keys Setup

```bash
# Sur votre workstation:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/mini_soc_key
ssh-copy-id -i ~/.ssh/mini_soc_key.pub -p 2222 admin@192.168.1.100
ssh-copy-id -i ~/.ssh/mini_soc_key.pub admin@192.168.1.200
ssh-copy-id -i ~/.ssh/mini_soc_key.pub admin@192.168.1.210
```

---

## 🔗 Connexion des agents

### Enregistrer Wazuh Agents

#### Sur VM2 (Manager):
```bash
sudo /var/ossec/bin/manage_agents

# Menu: a) Add agent
# Name: vm1-web
# IP: 192.168.1.100
# Obtenir: Agent ID + Key (longue string)

# Répéter pour VM3:
# Name: vm3-monitoring
# IP: 192.168.1.210
```

#### Sur VM1 & VM3 (Agents):
```bash
# Éditer config:
sudo nano /var/ossec/etc/ossec.conf

# Changer:
<manager>
  <ip>192.168.1.200</ip>
  <protocol>tcp</protocol>
</manager>

# Importer clé:
sudo /var/ossec/bin/manage_agents
# Menu: i) Import key
# Coller la clé

# Redémarrer:
sudo systemctl restart wazuh-agent
```

#### Vérifier:
```bash
# Sur VM2:
sudo /var/ossec/bin/wazuh-control status

# Agents connectés ?
# Ou dans Wazuh UI: Agents → Active
```

---

## 📊 Accès aux interfaces

### Après installation complète

| Service | URL | Credentials |
|---------|-----|------------|
| Wazuh | https://192.168.1.200:443 | admin / (changed) |
| Kibana | http://192.168.1.200:5601 | (auto) |
| Grafana | http://192.168.1.210:3000 | admin / (changed) |
| Prometheus | http://192.168.1.210:9090 | (open) |
| Web Server | http://192.168.1.100 | (public) |

---

## 🐛 Troubleshooting rapide

### Les scripts ne fonctionnent pas ?

```bash
# 1. Vérifier que vous êtes root:
whoami  # Doit être "root"

# 2. Vérifier internet:
ping 8.8.8.8

# 3. Vérifier disque:
df -h  # Au moins 20 GB libres

# 4. Vérifier RAM:
free -h  # Au moins 2 GB

# 5. Lire les logs:
journalctl -xe
```

### Services ne démarrent pas ?

```bash
# Vérifier quels services sont down:
systemctl list-units --type=service --state=failed

# Voir les erreurs:
sudo journalctl -u SERVICE_NAME -n 50

# Redémarrer:
sudo systemctl restart SERVICE_NAME
```

### Problèmes réseau ?

```bash
# Ping entre VMs:
ping 192.168.1.100  # VM1
ping 192.168.1.200  # VM2
ping 192.168.1.210  # VM3

# DNS:
nslookup google.com

# Firewall:
sudo firewall-cmd --list-all
```

---

## 📚 Documentation complète

Chaque fichier README contient:
- **Vue d'ensemble:** Rôle et objectifs
- **Prérequis:** Configuration nécessaire
- **Contenu du script:** Étape par étape
- **Vérification:** Tests post-installation
- **Configuration:** Setup des services
- **Troubleshooting:** Solutions aux problèmes
- **Checklist finale:** Avant/après

---

## 🎯 Objectifs atteints après installation

```
✅ Infrastructure Multi-VM (3 VMs)
✅ Sécurité système (Hardening)
✅ Firewall + Fail2ban (Protection brute force)
✅ Centralized Logging (rsyslog)
✅ SIEM (Wazuh + Elasticsearch)
✅ Real-time Monitoring (Prometheus + Grafana)
✅ Incident Response (Scripts + Playbooks)
✅ Audit Logging (Auditd)
✅ Web Server (Nginx)
✅ Metrics Collection (Node Exporter)
```

---

## 📋 Checklist d'installation

```
AVANT DE COMMENCER:
[ ] 3 VMs créées (Rocky Linux minimal)
[ ] Réseau bridgé configuré
[ ] IPs statiques définies
[ ] Internet accessible

VM1:
[ ] Script copié et exécuté
[ ] Services démarrés (SSH, Nginx, etc.)
[ ] Ports ouverts (2222, 80, 443, 1514)
[ ] Test: ssh -p 2222 admin@192.168.1.100

VM2:
[ ] Script copié et exécuté
[ ] Wazuh Manager running
[ ] Elasticsearch running
[ ] Kibana accessible
[ ] Admin password changé
[ ] Agents enregistrés (VM1 + VM3)

VM3:
[ ] Script copié et exécuté
[ ] Prometheus running
[ ] Grafana accessible
[ ] Grafana password changé
[ ] Prometheus datasource ajouté
[ ] Agents connectés

TESTS:
[ ] Logs arrivent dans Wazuh (VM2)
[ ] Métriques dans Prometheus (VM3)
[ ] Dashboards fonctionnent
[ ] Alertes testées
```

---

## 📞 Support

### Besoin d'aide ?

1. **Lire le README pertinent** - La plupart des questions sont couvertes
2. **Vérifier les logs:** `journalctl -u SERVICE_NAME`
3. **Tester la connectivité:** `ping`, `telnet`, `netstat`
4. **Redémarrer le service:** `systemctl restart SERVICE`
5. **Consulter la documentation officielle:**
   - Wazuh: https://documentation.wazuh.com
   - Prometheus: https://prometheus.io/docs
   - Grafana: https://grafana.com/docs
   - Rocky Linux: https://docs.rockylinux.org

---

## 🎓 Prochaines étapes

Après installation réussie:

1. **Tests de sécurité:**
   - Tester brute force SSH
   - Tester uploads malveillants
   - Vérifier détection Wazuh

2. **Tuning:**
   - Ajuster les seuils d'alerte
   - Créer des dashboards personnalisés
   - Configurer notifications email/Slack

3. **Automation:**
   - Créer playbooks Ansible
   - Automatiser les blocages IP
   - Paramétrer l'Incident Response

4. **Hardening avancé:**
   - Ajouter WAF (ModSecurity)
   - Configurer TLS/HTTPS
   - Implémenter 2FA Grafana

---

## 📊 Ressources système

### Utilisation après installation

| Ressource | Usage |
|-----------|-------|
| **VM1** | 1-2 GB RAM, 5-10% CPU |
| **VM2** | 2-3 GB RAM, 10-20% CPU |
| **VM3** | 1-2 GB RAM, 5-15% CPU |
| **Total** | 4-7 GB RAM, 20-45% CPU |
| **Disk** | 30-40 GB utilisés |

---

## ✨ Vous avez maintenant :

- 🛡️ **Infrastructure sécurisée** (3 VMs)
- 🔍 **SIEM complet** (Wazuh)
- 📊 **Monitoring** (Prometheus + Grafana)
- 🚨 **Alertes temps réel**
- 🤖 **Automation IR** (Ansible)
- 📝 **Audit logging** (Auditd)
- 🔐 **SSH hardening**
- 🛡️ **Firewall avancé**
- 📈 **Métriques complètes**
- 🎓 **Environnement d'apprentissage**

**Prêt pour les tests de sécurité et Red Team exercises !**

---

**Version:** 1.0  
**Date:** Février 2026  
**Status:** Production Ready ✅

**Bon déploiement ! 🚀**
