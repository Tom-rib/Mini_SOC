#!/bin/bash

################################################################################
# Script de hardening automatisé pour Rocky Linux
# Basé sur les bonnes pratiques de sécurité Linux et CIS Benchmarks
#
# Usage: sudo ./harden_system.sh [--dry-run]
#
# Options:
#   --dry-run    Afficher les actions sans les exécuter
#   --help       Afficher l'aide
#
# ATTENTION: Ce script modifie la configuration système.
#            Testez d'abord sur une VM ou utilisez --dry-run
################################################################################

set -euo pipefail

# Configuration
LOGFILE="/var/log/system_hardening_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/root/hardening_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

# Paramètres configurables
ADMIN_USER="sysadmin"              # Utilisateur administrateur à créer
SSH_PORT="2222"                     # Port SSH personnalisé
SSH_MAX_AUTH_TRIES="3"              # Nombre max de tentatives SSH
SSH_LOGIN_GRACE_TIME="30"           # Délai de connexion SSH
FAIL2BAN_MAXRETRY="5"               # Tentatives avant ban
FAIL2BAN_BANTIME="3600"             # Durée du ban (secondes)

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

################################################################################
# Fonctions de logging
################################################################################
log() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOGFILE"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $@"
    log "INFO" "$@"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $@"
    log "WARN" "$@"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $@"
    log "ERROR" "$@"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $@"
    log "STEP" "$@"
}

log_action() {
    echo -e "${CYAN}[ACTION]${NC} $@"
    log "ACTION" "$@"
}

error_exit() {
    log_error "$1"
    log_error "Hardening échoué. Consultez: $LOGFILE"
    log_error "Backup disponible dans: $BACKUP_DIR"
    exit 1
}

################################################################################
# Fonction d'aide
################################################################################
show_usage() {
    cat << EOF
Usage: $0 [options]

Options:
  --dry-run         Afficher les actions sans les exécuter
  --help            Afficher cette aide

Configuration (modifier dans le script):
  ADMIN_USER        Utilisateur admin à créer (défaut: sysadmin)
  SSH_PORT          Port SSH (défaut: 2222)
  
Ce script effectue:
  ✓ Création d'un utilisateur admin
  ✓ Configuration SSH sécurisée
  ✓ Configuration du firewall
  ✓ Activation de SELinux
  ✓ Installation de Fail2ban
  ✓ Configuration d'auditd
  ✓ Désactivation des services inutiles
  ✓ Paramètres kernel sécurisés

ATTENTION: Ce script modifie la configuration système.
           Testez d'abord en --dry-run ou sur une VM.

EOF
    exit 0
}

################################################################################
# Fonction d'exécution (dry-run aware)
################################################################################
execute() {
    local cmd="$@"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_action "[DRY-RUN] $cmd"
        return 0
    else
        log_action "$cmd"
        eval "$cmd" 2>&1 | tee -a "$LOGFILE"
        return ${PIPESTATUS[0]}
    fi
}

################################################################################
# Backup de configuration
################################################################################
backup_config() {
    log_step "Création du backup de configuration..."
    
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        
        # Fichiers importants à sauvegarder
        local files=(
            "/etc/ssh/sshd_config"
            "/etc/sysctl.conf"
            "/etc/selinux/config"
            "/etc/security/limits.conf"
            "/etc/pam.d/system-auth"
        )
        
        for file in "${files[@]}"; do
            if [[ -f "$file" ]]; then
                cp -a "$file" "$BACKUP_DIR/" || log_warn "Échec backup: $file"
            fi
        done
        
        log_info "Backup créé dans: $BACKUP_DIR"
    else
        log_info "[DRY-RUN] Backup serait créé dans: $BACKUP_DIR"
    fi
}

################################################################################
# Vérification des prérequis
################################################################################
check_prerequisites() {
    log_step "Vérification des prérequis..."
    
    if [[ $EUID -ne 0 ]]; then
        error_exit "Ce script doit être exécuté en tant que root (sudo)"
    fi
    
    if [[ ! -f /etc/rocky-release ]]; then
        log_warn "Ce script est optimisé pour Rocky Linux"
    fi
    
    log_info "Prérequis vérifiés"
}

################################################################################
# 1. Création d'un utilisateur administrateur
################################################################################
create_admin_user() {
    log_step "1. Création de l'utilisateur administrateur..."
    
    if id "$ADMIN_USER" &>/dev/null; then
        log_warn "L'utilisateur $ADMIN_USER existe déjà"
        return
    fi
    
    # Créer l'utilisateur
    execute "useradd -m -s /bin/bash -G wheel $ADMIN_USER"
    
    # Définir un mot de passe temporaire
    if [[ "$DRY_RUN" == false ]]; then
        echo "$ADMIN_USER:TempPass123!" | chpasswd
        chage -d 0 "$ADMIN_USER"  # Forcer le changement de mot de passe
        log_info "Utilisateur créé. Mot de passe temporaire: TempPass123!"
        log_warn "L'utilisateur devra changer le mot de passe à la première connexion"
    fi
    
    log_info "Utilisateur $ADMIN_USER créé avec succès"
}

################################################################################
# 2. Sécurisation SSH
################################################################################
harden_ssh() {
    log_step "2. Configuration SSH sécurisée..."
    
    local sshd_config="/etc/ssh/sshd_config"
    
    if [[ "$DRY_RUN" == false ]]; then
        # Backup du fichier original
        cp "$sshd_config" "${sshd_config}.bak"
        
        # Configurations de sécurité
        cat >> "$sshd_config" << EOF

# === Security Hardening ===
# Port non standard
Port $SSH_PORT

# Désactiver root login
PermitRootLogin no

# Authentification par clé uniquement (décommenter si clés configurées)
# PasswordAuthentication no
# PubkeyAuthentication yes

# Limiter les tentatives
MaxAuthTries $SSH_MAX_AUTH_TRIES
LoginGraceTime $SSH_LOGIN_GRACE_TIME

# Désactiver les options dangereuses
PermitEmptyPasswords no
X11Forwarding no
PermitUserEnvironment no
AllowAgentForwarding no
AllowTcpForwarding no

# Utiliser seulement les protocoles sécurisés
Protocol 2

# Timeout des sessions inactives
ClientAliveInterval 300
ClientAliveCountMax 2

# Limiter les utilisateurs autorisés
AllowUsers $ADMIN_USER

# Logging
LogLevel VERBOSE
EOF
        
        # Tester la configuration
        if sshd -t; then
            log_info "Configuration SSH validée"
        else
            log_error "Configuration SSH invalide"
            cp "${sshd_config}.bak" "$sshd_config"
            error_exit "Restauration de la config SSH"
        fi
        
    else
        log_info "[DRY-RUN] SSH serait configuré avec le port $SSH_PORT"
    fi
    
    log_warn "IMPORTANT: Le port SSH sera changé pour $SSH_PORT"
    log_warn "           Assurez-vous que le firewall autorise ce port!"
}

################################################################################
# 3. Configuration Firewall
################################################################################
configure_firewall() {
    log_step "3. Configuration du firewall (firewalld)..."
    
    # Installer firewalld si nécessaire
    if ! command -v firewall-cmd &> /dev/null; then
        execute "dnf install -y firewalld"
    fi
    
    execute "systemctl enable firewalld"
    execute "systemctl start firewalld"
    
    # Configuration des règles
    execute "firewall-cmd --permanent --remove-service=ssh"
    execute "firewall-cmd --permanent --add-port=${SSH_PORT}/tcp"
    execute "firewall-cmd --permanent --add-service=http"
    execute "firewall-cmd --permanent --add-service=https"
    
    # Protections supplémentaires
    execute "firewall-cmd --permanent --set-default-zone=public"
    execute "firewall-cmd --permanent --zone=public --add-rich-rule='rule family=\"ipv4\" source address=\"0.0.0.0/0\" drop'"
    execute "firewall-cmd --permanent --zone=public --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.0.0/16\" accept'"
    
    execute "firewall-cmd --reload"
    
    log_info "Firewall configuré"
}

################################################################################
# 4. SELinux
################################################################################
configure_selinux() {
    log_step "4. Configuration de SELinux..."
    
    local selinux_config="/etc/selinux/config"
    
    if [[ "$DRY_RUN" == false ]]; then
        # Forcer SELinux en mode enforcing
        sed -i 's/SELINUX=.*/SELINUX=enforcing/' "$selinux_config"
        
        # Si SELinux est en mode disabled, il faudra redémarrer
        if getenforce | grep -qi "Disabled"; then
            log_warn "SELinux est actuellement désactivé"
            log_warn "Le système doit être redémarré pour activer SELinux"
        else
            setenforce 1
            log_info "SELinux activé en mode enforcing"
        fi
    else
        log_info "[DRY-RUN] SELinux serait configuré en mode enforcing"
    fi
}

################################################################################
# 5. Fail2ban
################################################################################
install_fail2ban() {
    log_step "5. Installation et configuration de Fail2ban..."
    
    # Installer Fail2ban et EPEL
    execute "dnf install -y epel-release"
    execute "dnf install -y fail2ban fail2ban-systemd"
    
    if [[ "$DRY_RUN" == false ]]; then
        # Configuration locale
        cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = $FAIL2BAN_BANTIME
findtime = 600
maxretry = $FAIL2BAN_MAXRETRY
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
EOF
        
        log_info "Fail2ban configuré"
    fi
    
    execute "systemctl enable fail2ban"
    execute "systemctl start fail2ban"
}

################################################################################
# 6. Auditd
################################################################################
configure_auditd() {
    log_step "6. Configuration d'auditd..."
    
    execute "dnf install -y audit"
    
    if [[ "$DRY_RUN" == false ]]; then
        # Règles d'audit importantes
        cat >> /etc/audit/rules.d/hardening.rules << EOF
# Audit des connexions
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins

# Audit des modifications de comptes
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity

# Audit des modifications sudo
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# Audit des commandes privilégiées
-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands

# Audit des modifications réseau
-w /etc/sysconfig/network-scripts/ -p wa -k network_modifications
-w /etc/hosts -p wa -k network_modifications
EOF
        
        # Recharger les règles
        augenrules --load
        
        log_info "Auditd configuré"
    fi
    
    execute "systemctl enable auditd"
    execute "systemctl start auditd"
}

################################################################################
# 7. Paramètres kernel (sysctl)
################################################################################
configure_sysctl() {
    log_step "7. Configuration des paramètres kernel..."
    
    if [[ "$DRY_RUN" == false ]]; then
        cat >> /etc/sysctl.d/99-hardening.conf << EOF
# Protection contre les attaques réseau
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Protection IPv6
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Randomisation de l'espace d'adressage
kernel.randomize_va_space = 2

# Restriction d'accès aux logs kernel
kernel.dmesg_restrict = 1

# Protection contre les core dumps
fs.suid_dumpable = 0
EOF
        
        # Appliquer les paramètres
        sysctl -p /etc/sysctl.d/99-hardening.conf
        
        log_info "Paramètres kernel appliqués"
    fi
}

################################################################################
# 8. Désactivation des services inutiles
################################################################################
disable_unused_services() {
    log_step "8. Désactivation des services inutiles..."
    
    local unused_services=(
        "bluetooth"
        "cups"
        "avahi-daemon"
        "postfix"
    )
    
    for service in "${unused_services[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}.service"; then
            execute "systemctl stop $service" || true
            execute "systemctl disable $service" || true
            log_info "Service désactivé: $service"
        fi
    done
}

################################################################################
# 9. Vérification de sécurité avec Lynis
################################################################################
run_security_audit() {
    log_step "9. Audit de sécurité avec Lynis..."
    
    if ! command -v lynis &> /dev/null; then
        log_info "Installation de Lynis..."
        execute "dnf install -y lynis"
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        log_info "Exécution de l'audit (cela peut prendre quelques minutes)..."
        lynis audit system --quick >> "$LOGFILE" 2>&1
        log_info "Rapport Lynis disponible dans: /var/log/lynis.log"
    else
        log_info "[DRY-RUN] Lynis audit serait exécuté"
    fi
}

################################################################################
# 10. Génération du rapport
################################################################################
generate_report() {
    log_step "10. Génération du rapport..."
    
    local report_file="/root/hardening_report_$(date +%Y%m%d_%H%M%S).txt"
    
    if [[ "$DRY_RUN" == false ]]; then
        cat > "$report_file" << EOF
========================================
  Rapport de Hardening Système
========================================
Date: $(date)
Hostname: $(hostname)

Configuration appliquée:
------------------------
✓ Utilisateur admin: $ADMIN_USER (mot de passe: TempPass123!)
✓ SSH Port: $SSH_PORT
✓ Root login SSH: DÉSACTIVÉ
✓ SELinux: ENFORCING
✓ Firewalld: ACTIF
✓ Fail2ban: ACTIF (maxretry: $FAIL2BAN_MAXRETRY, bantime: $FAIL2BAN_BANTIME)
✓ Auditd: ACTIF avec règles personnalisées
✓ Sysctl: Paramètres sécurisés appliqués
✓ Services inutiles: DÉSACTIVÉS

Fichiers de backup:
-------------------
$BACKUP_DIR/

Logs:
-----
$LOGFILE
/var/log/lynis.log

Prochaines étapes:
------------------
1. REDÉMARRER LE SYSTÈME si SELinux était désactivé
2. Configurer les clés SSH pour $ADMIN_USER
3. Désactiver PasswordAuthentication dans /etc/ssh/sshd_config
4. Vérifier les logs d'audit: ausearch -k logins
5. Consulter le rapport Lynis: /var/log/lynis.log
6. Tester la connexion SSH sur le port $SSH_PORT

Commandes utiles:
-----------------
systemctl status sshd
systemctl status fail2ban
fail2ban-client status sshd
ausearch -k root_commands
firewall-cmd --list-all
getenforce

ATTENTION:
----------
- Le mot de passe de $ADMIN_USER doit être changé
- Port SSH modifié: $SSH_PORT
- Testez la connexion SSH avant de fermer la session actuelle!

========================================
EOF
        
        log_info "Rapport généré: $report_file"
        cat "$report_file"
    else
        log_info "[DRY-RUN] Rapport serait généré dans: $report_file"
    fi
}

################################################################################
# Fonction principale
################################################################################
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_warn "Mode DRY-RUN activé - aucune modification ne sera effectuée"
                shift
                ;;
            --help)
                show_usage
                ;;
            *)
                log_error "Option inconnue: $1"
                show_usage
                ;;
        esac
    done
    
    log_info "=== Début du hardening système ==="
    log_info "Log file: $LOGFILE"
    
    if [[ "$DRY_RUN" == false ]]; then
        log_warn "Ce script va modifier la configuration système"
        read -p "Êtes-vous sûr de vouloir continuer? (oui/non): " -r
        if [[ ! $REPLY =~ ^[Oo][Uu][Ii]$ ]]; then
            log_info "Opération annulée"
            exit 0
        fi
    fi
    
    check_prerequisites
    backup_config
    
    create_admin_user
    harden_ssh
    configure_firewall
    configure_selinux
    install_fail2ban
    configure_auditd
    configure_sysctl
    disable_unused_services
    run_security_audit
    
    generate_report
    
    log_info "=== Hardening terminé avec succès ==="
    
    if [[ "$DRY_RUN" == false ]]; then
        log_warn "IMPORTANT: Testez la connexion SSH avant de fermer cette session!"
        log_warn "           Nouveau port SSH: $SSH_PORT"
        log_warn "           Nouvel utilisateur: $ADMIN_USER"
    fi
}

# Exécution
main "$@"
