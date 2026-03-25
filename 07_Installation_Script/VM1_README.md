# 🛡️ VM1 - WEB SERVER INSTALLATION GUIDE

## 📖 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Prérequis](#prérequis)
3. [Contenu du script](#contenu-du-script)
4. [Installation](#installation)
5. [Vérification](#vérification)
6. [Sécurité](#sécurité)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Vue d'ensemble

**VM1** est le **serveur web exposé** du projet Mini SOC. Il simule un serveur réaliste en production, durci contre les attaques.

### Rôle
- Serveur HTTP/HTTPS (Nginx)
- Cible d'attaques (red team)
- Envoie les logs au SOC (VM2)
- Envoie les métriques au monitoring (VM3)

### Caractéristiques
- **OS:** Rocky Linux 9 (RHEL-compatible)
- **Services:** Nginx, SSH (port 2222), Firewall, Wazuh Agent
- **Sécurité:** SSH keys, Fail2ban, Auditd, SELinux
- **IP:** 192.168.1.100

---

## ⚙️ Prérequis

### Machine virtuelle
- **CPU:** 2 cores
- **RAM:** 4 GB
- **Disk:** 60 GB
- **Network:** Bridged ou NAT avec accès VM2/VM3

### Logiciels
- Rocky Linux 9 minimal (déjà installé)
- sudo access
- Internet connection

### Réseau
```
IP: 192.168.1.100
Gateway: 192.168.1.1
DNS: 8.8.8.8, 8.8.4.4
```

---

## 📝 Contenu du script

Le script `vm1_install.sh` installe **10 étapes principales** :

### Étape 1: System Updates
```bash
dnf update -y
dnf install -y wget curl vim nano git
```
- Met à jour Rocky Linux
- Installe les outils essentiels

### Étape 2: Hostname Configuration
```bash
hostnamectl set-hostname vm1-web
```
- Identifie la machine dans le réseau

### Étape 3: SSH Hardening ⭐
```bash
# Port personnalisé
Port 2222

# Root login disabled
PermitRootLogin no

# Authentification par clé uniquement
PubkeyAuthentication yes
PasswordAuthentication no

# Sécurité supplémentaire
MaxAuthTries 3
ClientAliveInterval 300
```

**Pourquoi ?**
- Réduit les tentatives de brute force
- Port 2222 peu attaqué (vs 22)
- Clés SSH = authentification forte

### Étape 4: Firewall Configuration
```
Ports ouverts:
- 2222/tcp   (SSH)
- 80/tcp     (HTTP)
- 443/tcp    (HTTPS)
- 1514/tcp   (Wazuh agent)
- 1514/udp   (Wazuh agent)

Tous les autres ports: BLOQUÉS
```

**Approche:** Whitelist (ouvrir ce qui est nécessaire)

### Étape 5: Fail2ban Installation
```bash
dnf install -y fail2ban
# Configuration SSH
[sshd]
maxretry = 5        # Ban après 5 essais
findtime = 600      # En 10 minutes
bantime = 3600      # Pendant 1 heure
```

**Détection:**
- Monitore `/var/log/secure`
- Détecte "Failed password"
- Bloque IP attaquante automatiquement

### Étape 6: Auditd Installation
```bash
# Écoute:
-w /var/log/secure          # Logs SSH
-w /etc/sudoers             # Changements sudo
-w /etc/ssh/sshd_config     # Config SSH
-w /etc/passwd              # Créations comptes
```

**Utilité:**
- Journalisation détaillée
- Trace toutes les actions suspectes
- Utile pour forensics

### Étape 7: SELinux Configuration
```bash
SELINUX=enforcing
```

- **Mandatory Access Control** (MAC)
- Contrôle fin des permissions au niveau système
- Réduit impact d'une compromise

### Étape 8: Nginx Web Server
```bash
dnf install -y nginx
# Crée page d'accueil
# Démarre service
```

- Serveur web pour HTTP/HTTPS
- Page d'accueil indiquant le statut sécurité

### Étape 9: Node Exporter (Prometheus)
```bash
# Télécharge et installe
node_exporter-1.7.0.linux-amd64
# Lance sur port 9100
```

**Métriques exportées:**
- CPU usage
- RAM usage
- Disk usage
- Network I/O
- Processus actifs

### Étape 10: Wazuh Agent
```bash
dnf install -y wazuh-agent-4.7.0
```

- Agent Wazuh pour log collection
- Envoie les logs à VM2 (Manager)
- Port 1514 (communication)

---

## 🚀 Installation

### 1. Préparer VM1
```bash
# Télécharger script sur VM1
scp vm1_install.sh admin@192.168.1.100:~/

# Ou copier directement sur VM1
```

### 2. Lancer le script
```bash
sudo bash vm1_install.sh
```

**Output attendu:**
```
╔════════════════════════════════════════════╗
║   VM1 - WEB SERVER INSTALLATION           ║
║   Mini SOC - Hardened Rocky Linux         ║
╚════════════════════════════════════════════╝

[INFO] Step 1/10 - Updating system...
[✓] System updated
[INFO] Step 2/10 - Setting hostname...
[✓] Hostname set to vm1-web
...
[✓] VM1 INSTALLATION COMPLETED SUCCESSFULLY!
```

### 3. Durée
```
⏱️ Temps total: 10-15 minutes
```

---

## ✅ Vérification

Après installation, vérifier :

### SSH (Port 2222)
```bash
# Depuis votre machine:
ssh -p 2222 admin@192.168.1.100

# Attendu: login réussi (avec clé)
# Erreur "connection refused" si port fermé
```

### Firewall
```bash
ssh -p 2222 admin@192.168.1.100
sudo firewall-cmd --list-all

# Vérifier ports ouverts:
# 2222/tcp, 80/tcp, 443/tcp, 1514
```

### Web Server
```bash
# Depuis VM1:
curl http://localhost

# Depuis votre machine:
curl http://192.168.1.100

# Attendu: Page HTML avec status ✅
```

### Node Exporter
```bash
curl http://192.168.1.100:9100/metrics

# Attendu: Métriques Prometheus
```

### Fail2ban
```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Attendu: "Jail 'sshd' is currently enabled"
```

### Auditd
```bash
sudo tail -f /var/log/audit/audit.log

# Attendu: Logs de système
```

### Wazuh Agent
```bash
sudo systemctl status wazuh-agent

# Attendu: "active (running)"
```

---

## 🔐 Sécurité

### Qu'est-ce qui est protégé ?

| Menace | Protection |
|--------|-----------|
| Brute force SSH | Fail2ban (5 essais → ban 1h) |
| Port scanning | Firewall (whitelist) |
| Root compromise | PermitRootLogin=no |
| Password guessing | Key-only auth (pas de mdp SSH) |
| Elevation privilèges | Auditd (logging) |
| Unauthorized access | SELinux (MAC) |

### Meilleures pratiques

#### 1. SSH Keys Setup
```bash
# Sur votre workstation:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/vm1_key
ssh-copy-id -i ~/.ssh/vm1_key.pub -p 2222 admin@192.168.1.100

# Ajouter à ~/.ssh/config:
Host vm1
    HostName 192.168.1.100
    Port 2222
    User admin
    IdentityFile ~/.ssh/vm1_key

# Utilisation simple:
ssh vm1
```

#### 2. Mettre à jour les logs vers VM2
```bash
# Éditer /etc/rsyslog.conf:
sudo nano /etc/rsyslog.conf

# Ajouter à la fin:
*.* @@192.168.1.200:514

# Redémarrer:
sudo systemctl restart rsyslog
```

#### 3. Configurer Wazuh Agent
```bash
# Sur VM1:
sudo nano /var/ossec/etc/ossec.conf

# Modifier:
<manager>
  <ip>192.168.1.200</ip>
  <protocol>tcp</protocol>
</manager>

# Redémarrer agent:
sudo systemctl restart wazuh-agent
```

#### 4. Monitorer Fail2ban
```bash
# Voir les bans:
sudo fail2ban-client status sshd

# Débannir une IP:
sudo fail2ban-client set sshd unbanip 192.168.1.50
```

---

## 🧪 Tests de sécurité

### Test 1: SSH Port 2222
```bash
# Devrait fonctionner:
ssh -p 2222 admin@192.168.1.100

# Devrait échouer:
ssh admin@192.168.1.100  # Port 22 fermé
```

### Test 2: Fail2ban
```bash
# Faire échouer 6 connexions SSH:
for i in {1..6}; do
    sshpass -p "wrong" ssh -p 2222 admin@192.168.1.100
done

# Vérifier IP bannée:
sudo fail2ban-client status sshd
```

### Test 3: Auditd
```bash
# Modifier un fichier monitoré:
sudo nano /etc/ssh/sshd_config

# Vérifier audit log:
sudo ausearch -k sshd_config_changes
```

### Test 4: Web Server
```bash
# Accédez à http://192.168.1.100
# Devrait voir la page d'accueil avec status ✅
```

---

## ❌ Troubleshooting

### Problème: SSH connection refused

**Causes possibles:**
1. SSH service not running
2. Port incorrect
3. Firewall blocking

**Solutions:**
```bash
# Vérifier SSH service:
sudo systemctl status sshd

# Redémarrer SSH:
sudo systemctl restart sshd

# Vérifier port:
sudo ss -tlnp | grep 2222

# Vérifier firewall:
sudo firewall-cmd --list-all
```

### Problème: Fail2ban ne bloque pas

**Solutions:**
```bash
# Vérifier status:
sudo fail2ban-client status sshd

# Voir les logs:
sudo tail -f /var/log/fail2ban.log

# Redémarrer:
sudo systemctl restart fail2ban
```

### Problème: Node Exporter ne répond pas

**Solutions:**
```bash
# Vérifier service:
sudo systemctl status node_exporter

# Vérifier port:
sudo ss -tlnp | grep 9100

# Redémarrer:
sudo systemctl restart node_exporter
```

### Problème: Wazuh Agent disconnected

**Solutions:**
```bash
# Vérifier config:
sudo nano /var/ossec/etc/ossec.conf
# S'assurer que manager IP = 192.168.1.200

# Redémarrer agent:
sudo systemctl restart wazuh-agent

# Vérifier logs:
sudo tail -f /var/ossec/logs/ossec.log
```

### Problème: Disk full

**Solutions:**
```bash
# Voir l'utilisation:
df -h

# Nettoyer les vieux logs:
sudo journalctl --vacuum=100M

# Nettoyer auditd logs:
sudo auditctl -D  # Attention: efface l'historique!
```

---

## 📊 Ressources système

Après installation, l'utilisation typique:

| Ressource | Usage |
|-----------|-------|
| CPU | 5-10% (idle) |
| RAM | 1-2 GB |
| Disk | 10-15 GB |
| Network | <1 Mbps (idle) |

---

## 🔄 Mise à jour

Pour maintenir la sécurité à jour:

```bash
# Mettre à jour Rocky Linux:
sudo dnf update -y

# Mettre à jour Wazuh Agent:
sudo dnf install -y --upgrade wazuh-agent

# Redémarrer si nécessaire:
sudo reboot
```

---

## 📝 Notes importantes

⚠️ **À faire après installation:**

1. ✅ Créer SSH keys pour authentification
2. ✅ Configurer Wazuh Agent avec Manager IP
3. ✅ Activer rsyslog forwarding vers VM2
4. ✅ Changer le hostname si différent
5. ✅ Vérifier connectivité réseau vers VM2/VM3

---

## 🎓 Pour aller plus loin

### Lire la documentation:
- [Nginx Security](https://nginx.org/en/docs/)
- [Fail2ban Manual](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [Auditd Docs](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_guide/index)
- [SELinux Guide](https://access.redhat.com/articles/3359321)

### Améliores la sécurité:
- Ajouter HTTPS certificate (Let's Encrypt)
- Configurer rate limiting Nginx
- Activer ModSecurity WAF
- Ajouter logging centralisé TLS

---

## ✅ Checklist Finale

```
Avant de passer aux autres VMs:
[ ] Script exécuté sans erreurs
[ ] SSH port 2222 accessible
[ ] Web server répondant (http://IP)
[ ] Node Exporter sur port 9100
[ ] Fail2ban actif
[ ] Auditd logging
[ ] SELinux enforcing
[ ] Wazuh Agent installé
[ ] Firewall configuré
[ ] IP correcte (192.168.1.100)
```

---

**Version:** 1.0  
**Date:** Février 2026  
**Status:** Production Ready ✅
