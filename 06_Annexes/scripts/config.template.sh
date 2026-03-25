# Fichier de configuration pour les scripts d'automatisation
# Copiez ce fichier en config.sh et adaptez les valeurs

################################################################################
# CONFIGURATION GÉNÉRALE
################################################################################

# Environnement
ENVIRONMENT="production"  # production, staging, development
PROJECT_NAME="mini-soc-rocky"
ADMIN_EMAIL="admin@example.com"

################################################################################
# CONFIGURATION RÉSEAU
################################################################################

# Plages IP autorisées (whitelist)
ALLOWED_IP_RANGES=(
    "192.168.1.0/24"
    "10.0.0.0/8"
    "172.16.0.0/12"
)

# DNS Servers
DNS_SERVERS=(
    "8.8.8.8"
    "8.8.4.4"
)

################################################################################
# CONFIGURATION SSH (harden_system.sh)
################################################################################

# Port SSH personnalisé
SSH_PORT="2222"

# Utilisateur administrateur à créer
ADMIN_USER="sysadmin"

# Paramètres de sécurité SSH
SSH_MAX_AUTH_TRIES="3"
SSH_LOGIN_GRACE_TIME="30"
SSH_CLIENT_ALIVE_INTERVAL="300"
SSH_CLIENT_ALIVE_COUNT_MAX="2"

# Désactiver l'authentification par mot de passe (après config des clés)
SSH_PASSWORD_AUTH="yes"  # Mettre "no" après avoir configuré les clés SSH

################################################################################
# CONFIGURATION FIREWALL
################################################################################

# Ports supplémentaires à ouvrir
CUSTOM_PORTS=(
    # Format: "port/protocole"
    # "8080/tcp"
    # "3306/tcp"
)

# Services à autoriser
FIREWALL_SERVICES=(
    "http"
    "https"
)

################################################################################
# CONFIGURATION FAIL2BAN (harden_system.sh)
################################################################################

FAIL2BAN_MAXRETRY="5"          # Nombre de tentatives avant ban
FAIL2BAN_BANTIME="3600"        # Durée du ban en secondes (1h)
FAIL2BAN_FINDTIME="600"        # Fenêtre de détection (10 min)

# Jails Fail2ban à activer
FAIL2BAN_JAILS=(
    "sshd"
    "nginx-http-auth"
    "nginx-noscript"
)

################################################################################
# CONFIGURATION WAZUH (install_wazuh.sh)
################################################################################

# Version de Wazuh à installer
WAZUH_VERSION="4.7"

# Credentials Wazuh API
WAZUH_API_URL="https://localhost:55000"
WAZUH_API_USER="wazuh"
WAZUH_API_PASS="ChangeThisPassword123!"  # À MODIFIER

# Manager Wazuh
WAZUH_MANAGER_IP="192.168.1.100"  # IP du serveur Wazuh Manager

# Nom de l'agent (automatiquement détecté si vide)
WAZUH_AGENT_NAME=""

################################################################################
# CONFIGURATION DOCKER (install_docker.sh)
################################################################################

# Utilisateur à ajouter au groupe docker
DOCKER_USER="student"

# Options de configuration Docker
DOCKER_STORAGE_DRIVER="overlay2"
DOCKER_LOG_DRIVER="json-file"
DOCKER_LOG_MAX_SIZE="10m"
DOCKER_LOG_MAX_FILE="3"

################################################################################
# CONFIGURATION INCIDENT RESPONSE (response_automate.sh)
################################################################################

# Email pour les notifications
NOTIFICATION_EMAIL="soc@example.com"  # À MODIFIER

# Seuils de détection
SSH_BRUTEFORCE_THRESHOLD=5      # Tentatives SSH avant alerte
SCAN_THRESHOLD=20                # Connexions rejetées avant alerte
PRIVILEGE_ESCALATION_THRESHOLD=3 # Tentatives sudo échouées avant alerte

# Durée de ban automatique (secondes)
AUTO_BAN_DURATION="3600"  # 1 heure

# Whitelist IPs (ne jamais bannir)
WHITELIST_IPS=(
    "192.168.1.1"      # Gateway
    "192.168.1.10"     # Admin workstation
)

# Commandes considérées comme suspectes
SUSPICIOUS_COMMANDS=(
    "rm -rf /"
    "wget http"
    "curl http"
    "/dev/tcp"
    "nc -e"
    "bash -i"
    "python -c"
    "perl -e"
)

################################################################################
# CONFIGURATION MONITORING
################################################################################

# Seuils d'alertes système
CPU_THRESHOLD="80"       # Pourcentage
RAM_THRESHOLD="90"       # Pourcentage
DISK_THRESHOLD="85"      # Pourcentage

# Intervalle de vérification (secondes)
MONITORING_INTERVAL="300"  # 5 minutes

################################################################################
# CONFIGURATION LOGGING
################################################################################

# Répertoires de logs
LOG_DIR="/var/log"
INCIDENT_LOG_DIR="/var/ossec/logs/incidents"
BACKUP_DIR="/root/backups"

# Rétention des logs (jours)
LOG_RETENTION_DAYS="30"

# Niveau de verbosité
# 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG
LOG_LEVEL="2"

################################################################################
# CONFIGURATION BACKUP
################################################################################

# Activer les backups automatiques
ENABLE_AUTO_BACKUP="yes"

# Répertoire de backup
BACKUP_ROOT="/root/backups"

# Fichiers/dossiers à sauvegarder
BACKUP_ITEMS=(
    "/etc/ssh/sshd_config"
    "/etc/fail2ban/"
    "/etc/wazuh/"
    "/var/ossec/etc/"
    "/etc/sysctl.conf"
    "/etc/selinux/config"
)

# Rotation des backups (nombre à conserver)
BACKUP_ROTATION="7"

################################################################################
# CONFIGURATION SELINUX
################################################################################

# Mode SELinux: enforcing, permissive, disabled
SELINUX_MODE="enforcing"

# Contextes SELinux personnalisés (si nécessaire)
# Format: "path:context"
SELINUX_CONTEXTS=(
    # "/var/www/html:httpd_sys_content_t"
)

################################################################################
# CONFIGURATION AUDITING
################################################################################

# Activer l'audit avancé
ENABLE_ADVANCED_AUDIT="yes"

# Règles d'audit supplémentaires
# Voir /etc/audit/rules.d/ pour les règles existantes
AUDIT_RULES=(
    # Audit des modifications de fichiers sensibles
    "-w /etc/passwd -p wa -k identity"
    "-w /etc/shadow -p wa -k identity"
    "-w /etc/sudoers -p wa -k sudoers"
)

################################################################################
# CONFIGURATION TESTS
################################################################################

# Activer le mode test (dry-run par défaut)
TEST_MODE="no"

# IP de test pour les blocages
TEST_IP="198.51.100.1"  # IP de test (RFC 5737)

################################################################################
# CONFIGURATION AVANCÉE
################################################################################

# Timezone
TIMEZONE="Europe/Paris"

# Locale
LOCALE="fr_FR.UTF-8"

# Kernel parameters supplémentaires
SYSCTL_PARAMS=(
    # Format: "param=value"
    # "net.ipv4.ip_forward=0"
    # "net.ipv6.conf.all.disable_ipv6=1"
)

################################################################################
# NOTIFICATIONS
################################################################################

# Types de notifications activées
ENABLE_EMAIL_NOTIFICATIONS="yes"
ENABLE_SYSTEM_NOTIFICATIONS="yes"
ENABLE_WALL_NOTIFICATIONS="yes"

# Webhook pour notifications (Slack, Discord, etc.)
WEBHOOK_URL=""

# Format des notifications
NOTIFICATION_FORMAT="text"  # text, json

################################################################################
# INTÉGRATIONS EXTERNES
################################################################################

# VirusTotal API (pour analyse de malware)
VIRUSTOTAL_API_KEY=""

# AbuseIPDB API (pour réputation IP)
ABUSEIPDB_API_KEY=""

# Slack Webhook
SLACK_WEBHOOK_URL=""

# Discord Webhook
DISCORD_WEBHOOK_URL=""

################################################################################
# NOTES
################################################################################

# Ce fichier contient des valeurs sensibles (mots de passe, API keys)
# NE PAS commiter ce fichier dans Git
# Ajouter config.sh dans .gitignore

# Pour utiliser ce fichier dans vos scripts:
# source /path/to/config.sh

# Pour générer des mots de passe sécurisés:
# openssl rand -base64 32

# Pour générer des clés SSH:
# ssh-keygen -t ed25519 -C "votre_email@example.com"
