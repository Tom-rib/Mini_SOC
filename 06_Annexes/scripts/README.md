# Scripts d'automatisation - Mini SOC Rocky Linux

Ce répertoire contient des scripts bash pour automatiser les tâches d'installation, de hardening et de réponse aux incidents.

## 📋 Liste des scripts

### 1. `install_docker.sh`
**Installation de Docker sur Rocky Linux**

Installe Docker Engine, Docker Compose et configure l'accès utilisateur.

**Usage:**
```bash
sudo ./install_docker.sh [username]
```

**Exemple:**
```bash
sudo ./install_docker.sh student
```

**Ce que fait le script:**
- ✅ Vérifie les prérequis système
- ✅ Désinstalle les anciennes versions
- ✅ Ajoute le repository Docker officiel
- ✅ Installe Docker Engine + Docker Compose
- ✅ Démarre et active les services
- ✅ Ajoute l'utilisateur au groupe docker
- ✅ Vérifie l'installation avec hello-world

**Logs:** `/var/log/install_docker_YYYYMMDD_HHMMSS.log`

---

### 2. `install_wazuh.sh`
**Installation de Wazuh Manager ou Agent**

Installe et configure Wazuh SIEM (Manager complet ou Agent uniquement).

**Usage:**

**Pour le Manager (all-in-one):**
```bash
sudo ./install_wazuh.sh manager [password]
```

**Pour un Agent:**
```bash
sudo ./install_wazuh.sh agent <manager_ip> [agent_name]
```

**Exemples:**
```bash
# Installer le Manager
sudo ./install_wazuh.sh manager MySecureP@ss123

# Installer un Agent
sudo ./install_wazuh.sh agent 192.168.1.100 web-server-01
```

**Manager - Ce que fait le script:**
- ✅ Installe Wazuh Manager + Indexer + Dashboard
- ✅ Génère les certificats SSL
- ✅ Configure les services
- ✅ Ouvre les ports firewall (1514, 1515, 55000, 9200, 443)
- ✅ Sauvegarde les credentials dans `/root/wazuh-install-files/`

**Agent - Ce que fait le script:**
- ✅ Installe Wazuh Agent
- ✅ Configure la connexion au Manager
- ✅ Démarre le service

**Accès au Dashboard:**
- URL: `https://<server-ip>`
- Username: `admin`
- Password: voir `/root/wazuh-install-files/wazuh-passwords.txt`

**Logs:** `/var/log/install_wazuh_YYYYMMDD_HHMMSS.log`

---

### 3. `harden_system.sh`
**Hardening automatisé du système**

Configure les mesures de sécurité avancées sur Rocky Linux.

**Usage:**
```bash
# Mode dry-run (voir sans exécuter)
sudo ./harden_system.sh --dry-run

# Exécution réelle
sudo ./harden_system.sh
```

**⚠️ ATTENTION:**
- Ce script modifie des configurations système critiques
- Testez d'abord avec `--dry-run`
- Testez sur une VM avant la production
- Le port SSH sera changé (défaut: 2222)

**Configuration (modifier dans le script):**
```bash
ADMIN_USER="sysadmin"              # Utilisateur admin
SSH_PORT="2222"                     # Port SSH
SSH_MAX_AUTH_TRIES="3"              # Tentatives SSH max
FAIL2BAN_MAXRETRY="5"               # Tentatives avant ban
FAIL2BAN_BANTIME="3600"             # Durée du ban (sec)
```

**Ce que fait le script:**
1. ✅ Crée un utilisateur administrateur
2. ✅ Sécurise SSH (port personnalisé, pas de root, timeouts)
3. ✅ Configure firewalld
4. ✅ Active SELinux en mode enforcing
5. ✅ Installe et configure Fail2ban
6. ✅ Configure auditd avec règles personnalisées
7. ✅ Applique des paramètres kernel sécurisés (sysctl)
8. ✅ Désactive les services inutiles
9. ✅ Lance un audit avec Lynis
10. ✅ Génère un rapport complet

**Fichiers générés:**
- Backup: `/root/hardening_backup_YYYYMMDD_HHMMSS/`
- Log: `/var/log/system_hardening_YYYYMMDD_HHMMSS.log`
- Rapport: `/root/hardening_report_YYYYMMDD_HHMMSS.txt`

**Après l'exécution:**
```bash
# Vérifier les services
systemctl status sshd
systemctl status fail2ban
fail2ban-client status sshd

# Tester SSH sur le nouveau port
ssh -p 2222 sysadmin@<server-ip>

# Vérifier SELinux
getenforce

# Consulter les audits
ausearch -k logins
ausearch -k root_commands
```

**Logs:** `/var/log/system_hardening_*.log`

---

### 4. `response_automate.sh`
**Réponse automatique aux incidents**

Script d'Incident Response intégré avec Wazuh pour détecter et réagir aux attaques.

**Usage:**

**Bloquer une IP:**
```bash
sudo ./response_automate.sh --block-ip 192.168.1.100
sudo ./response_automate.sh --block-ip 10.0.0.50 "SSH Bruteforce detected"
```

**Débloquer une IP:**
```bash
sudo ./response_automate.sh --unblock-ip 192.168.1.100
```

**Récupérer les attaques depuis Wazuh:**
```bash
./response_automate.sh --get-attacks
```

**Mode monitoring continu:**
```bash
sudo ./response_automate.sh --monitor
# Ctrl+C pour arrêter
```

**Analyser les logs:**
```bash
sudo ./response_automate.sh --check-logs
```

**Générer un rapport:**
```bash
./response_automate.sh --generate-report
```

**Lister les IPs bannies:**
```bash
./response_automate.sh --list-banned
```

**Configuration (modifier dans le script):**
```bash
WAZUH_API_URL="https://localhost:55000"
WAZUH_API_USER="wazuh"
WAZUH_API_PASS=""                   # À configurer
NOTIFICATION_EMAIL="soc@example.com"
SSH_BRUTEFORCE_THRESHOLD=5          # Seuil bruteforce
SCAN_THRESHOLD=20                   # Seuil scan ports
```

**Ce que fait le script:**

**Détection automatique:**
- 🔍 Attaques SSH bruteforce
- 🔍 Scans de ports (nmap, etc.)
- 🔍 Commandes suspectes (rm -rf, wget, curl, nc)
- 🔍 Tentatives d'élévation de privilèges
- 🔍 Alertes Wazuh (via API)

**Réponses automatiques:**
- 🛡️ Blocage IP avec firewalld
- 📝 Génération de rapports d'incidents
- 📧 Notifications (email + système)
- 📊 Logging centralisé

**Fichiers générés:**
- Incidents: `/var/ossec/logs/incidents/`
- IPs bannies: `/var/log/banned_ips.log`
- Log principal: `/var/log/incident_response_YYYYMMDD.log`

**Intégration avec Wazuh:**

Pour appeler automatiquement ce script depuis Wazuh, ajoutez dans `/var/ossec/etc/ossec.conf`:

```xml
<command>
  <name>firewall-drop</name>
  <executable>response_automate.sh</executable>
  <expect>srcip</expect>
  <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <level>10</level>
  <timeout>3600</timeout>
</active-response>
```

**Logs:** `/var/log/incident_response_*.log`

---

## 🚀 Ordre d'exécution recommandé

Pour un nouveau serveur, suivez cet ordre:

```bash
# 1. Hardening du système (TOUJOURS EN PREMIER)
sudo ./harden_system.sh --dry-run    # Tester d'abord
sudo ./harden_system.sh               # Exécuter

# 2. Installer Docker (si nécessaire)
sudo ./install_docker.sh student

# 3. Installer Wazuh Manager
sudo ./install_wazuh.sh manager MySecurePassword123

# 4. Sur les autres VM, installer les Agents
sudo ./install_wazuh.sh agent 192.168.1.100 web-server

# 5. Configurer la réponse automatique
# Modifier les variables dans response_automate.sh
sudo ./response_automate.sh --monitor
```

---

## 🔧 Vérifications post-installation

### Après hardening:
```bash
# Vérifier SSH
ssh -p 2222 sysadmin@localhost

# Vérifier Fail2ban
fail2ban-client status

# Vérifier SELinux
getenforce  # Doit afficher: Enforcing

# Vérifier firewall
firewall-cmd --list-all

# Vérifier les audits
ausearch -k logins
```

### Après installation Wazuh:
```bash
# Manager
systemctl status wazuh-manager
systemctl status wazuh-indexer
systemctl status wazuh-dashboard

# Accéder au Dashboard
firefox https://localhost

# Agent
systemctl status wazuh-agent
tail -f /var/ossec/logs/ossec.log
```

### Tester la réponse automatique:
```bash
# Simuler une attaque bruteforce (depuis une autre machine)
for i in {1..10}; do ssh user@<target>; done

# Vérifier les détections
sudo ./response_automate.sh --check-logs

# Vérifier les IPs bannies
sudo ./response_automate.sh --list-banned
```

---

## 📝 Logs et rapports

Tous les scripts génèrent des logs détaillés:

```bash
# Logs d'installation
/var/log/install_docker_*.log
/var/log/install_wazuh_*.log

# Logs de hardening
/var/log/system_hardening_*.log
/root/hardening_report_*.txt

# Logs de réponse aux incidents
/var/log/incident_response_*.log
/var/ossec/logs/incidents/

# Logs système
/var/log/secure      # SSH, sudo
/var/log/audit/      # auditd
/var/log/messages    # Système
```

---

## ⚠️ Avertissements de sécurité

### harden_system.sh:
- ⚠️ Le port SSH sera changé (défaut: 2222)
- ⚠️ Le root login SSH sera désactivé
- ⚠️ Testez la connexion SSH avant de fermer la session!
- ⚠️ Notez le mot de passe de l'utilisateur admin créé

### install_wazuh.sh:
- ⚠️ Sauvegardez les credentials: `/root/wazuh-install-files/`
- ⚠️ Le Manager nécessite au moins 4GB de RAM
- ⚠️ Ports ouverts: 1514, 1515, 55000, 9200, 443

### response_automate.sh:
- ⚠️ Configurez WAZUH_API_PASS pour l'intégration complète
- ⚠️ Testez le blocage IP avec une IP de test d'abord
- ⚠️ Le déblocage automatique n'est pas activé par défaut

---

## 🆘 Dépannage

### SSH inaccessible après hardening:
```bash
# Depuis la console (KVM/iLO/etc.)
sudo firewall-cmd --add-port=2222/tcp
sudo systemctl restart sshd
```

### Wazuh Dashboard inaccessible:
```bash
# Vérifier les services
systemctl status wazuh-indexer
systemctl status wazuh-dashboard

# Vérifier les ports
ss -tlnp | grep 443
ss -tlnp | grep 9200

# Logs
tail -f /var/log/wazuh-indexer/wazuh-cluster.log
```

### Script response_automate.sh ne bloque pas:
```bash
# Vérifier les permissions
sudo chmod +x response_automate.sh

# Vérifier firewalld
systemctl status firewalld

# Tester manuellement
sudo firewall-cmd --add-rich-rule="rule family='ipv4' source address='1.2.3.4' reject"
```

---

## 📚 Ressources

- [Documentation Wazuh](https://documentation.wazuh.com/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [Docker Documentation](https://docs.docker.com/)
- [RHEL Security Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_hardening/)
- [Fail2ban Wiki](https://www.fail2ban.org/)

---

## 🔄 Maintenance

### Mise à jour régulière:
```bash
# Système
sudo dnf update -y

# Wazuh
# Suivre la documentation officielle

# Docker
sudo dnf update docker-ce docker-ce-cli containerd.io
```

### Rotation des logs:
Les scripts utilisent logrotate automatiquement. Vérifier `/etc/logrotate.d/`.

### Backup des configurations:
```bash
# Sauvegarder les configs importantes
tar czf backup_configs_$(date +%Y%m%d).tar.gz \
  /etc/ssh/sshd_config \
  /etc/fail2ban/ \
  /etc/wazuh/ \
  /var/ossec/etc/
```

---

**Auteur:** Mini SOC Project  
**Version:** 1.0  
**Date:** 2026  
**Licence:** MIT
