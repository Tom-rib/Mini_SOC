#!/bin/bash

################################################################################
# Script d'installation de Wazuh Manager ou Agent sur Rocky Linux
#
# Usage: 
#   sudo ./install_wazuh.sh manager [manager_password]
#   sudo ./install_wazuh.sh agent <manager_ip> [agent_name]
#
# Exemples:
#   sudo ./install_wazuh.sh manager MySecureP@ss123
#   sudo ./install_wazuh.sh agent 192.168.1.100 web-server-01
#
# Ce script installe:
#   - Wazuh Manager (avec Indexer et Dashboard)
#   - Wazuh Agent
################################################################################

set -euo pipefail

# Configuration
LOGFILE="/var/log/install_wazuh_$(date +%Y%m%d_%H%M%S).log"
WAZUH_VERSION="4.7"
INSTALL_TYPE="${1:-}"
MANAGER_IP="${2:-}"
AGENT_NAME="${3:-$(hostname)}"
MANAGER_PASSWORD="${2:-Admin123!}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

error_exit() {
    log_error "$1"
    log_error "Installation échouée. Consultez: $LOGFILE"
    exit 1
}

################################################################################
# Fonction d'affichage de l'aide
################################################################################
show_usage() {
    cat << EOF
Usage: $0 <type> [options]

Types d'installation:
  manager [password]              Installer Wazuh Manager complet
  agent <manager_ip> [name]       Installer Wazuh Agent

Exemples:
  $0 manager MySecureP@ss123
  $0 agent 192.168.1.100 web-server-01

Options:
  -h, --help                      Afficher cette aide

Documentation:
  https://documentation.wazuh.com/

EOF
    exit 0
}

################################################################################
# Vérification des prérequis
################################################################################
check_prerequisites() {
    log_step "Vérification des prérequis..."
    
    # Root check
    if [[ $EUID -ne 0 ]]; then
        error_exit "Ce script doit être exécuté en tant que root (sudo)"
    fi
    
    # Rocky Linux check
    if [[ ! -f /etc/rocky-release ]]; then
        error_exit "Ce script est conçu pour Rocky Linux"
    fi
    
    # Arguments check
    if [[ -z "$INSTALL_TYPE" ]]; then
        show_usage
    fi
    
    if [[ "$INSTALL_TYPE" != "manager" && "$INSTALL_TYPE" != "agent" ]]; then
        error_exit "Type d'installation invalide: $INSTALL_TYPE (utilisez 'manager' ou 'agent')"
    fi
    
    if [[ "$INSTALL_TYPE" == "agent" && -z "$MANAGER_IP" ]]; then
        error_exit "L'IP du manager est requise pour installer un agent"
    fi
    
    # Ressources système
    local total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [[ "$INSTALL_TYPE" == "manager" && "$total_mem" -lt 4 ]]; then
        log_warn "Mémoire insuffisante: ${total_mem}GB (4GB recommandés pour le manager)"
    fi
    
    log_info "Prérequis vérifiés"
}

################################################################################
# Rollback function
################################################################################
rollback() {
    log_warn "Rollback en cours..."
    
    if [[ "$INSTALL_TYPE" == "manager" ]]; then
        systemctl stop wazuh-manager 2>/dev/null || true
        systemctl stop wazuh-indexer 2>/dev/null || true
        systemctl stop wazuh-dashboard 2>/dev/null || true
        
        dnf remove -y wazuh-manager wazuh-indexer wazuh-dashboard 2>/dev/null || true
    else
        systemctl stop wazuh-agent 2>/dev/null || true
        dnf remove -y wazuh-agent 2>/dev/null || true
    fi
    
    rm -f /etc/yum.repos.d/wazuh.repo
    
    log_info "Rollback terminé"
}

trap 'rollback' ERR

################################################################################
# Installation des dépendances
################################################################################
install_dependencies() {
    log_step "Installation des dépendances..."
    
    dnf install -y curl tar gnupg2 || error_exit "Échec de l'installation des dépendances"
    
    log_info "Dépendances installées"
}

################################################################################
# Ajout du repository Wazuh
################################################################################
add_wazuh_repository() {
    log_step "Ajout du repository Wazuh..."
    
    # Importer la clé GPG
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH || \
        error_exit "Échec de l'import de la clé GPG Wazuh"
    
    # Créer le fichier de repository
    cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
    
    log_info "Repository Wazuh ajouté"
}

################################################################################
# Installation de Wazuh Manager (all-in-one)
################################################################################
install_wazuh_manager() {
    log_step "Installation de Wazuh Manager (mode all-in-one)..."
    
    # Télécharger le script d'installation
    log_info "Téléchargement du script d'installation..."
    curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh || \
        error_exit "Échec du téléchargement du script"
    
    # Rendre le script exécutable
    chmod +x wazuh-install.sh
    
    # Installer Wazuh (Manager + Indexer + Dashboard)
    log_info "Installation en cours (cela peut prendre plusieurs minutes)..."
    
    # Générer les certificats et installer
    if ! bash wazuh-install.sh -a; then
        error_exit "Échec de l'installation de Wazuh Manager"
    fi
    
    # Sauvegarder le fichier de credentials
    if [[ -f wazuh-install-files.tar ]]; then
        tar -xvf wazuh-install-files.tar -C /root/
        log_info "Credentials sauvegardés dans /root/wazuh-install-files/"
    fi
    
    log_info "Wazuh Manager installé"
}

################################################################################
# Configuration de Wazuh Manager
################################################################################
configure_wazuh_manager() {
    log_step "Configuration de Wazuh Manager..."
    
    # Démarrer les services
    systemctl daemon-reload
    systemctl enable wazuh-manager
    systemctl enable wazuh-indexer
    systemctl enable wazuh-dashboard
    systemctl start wazuh-manager
    systemctl start wazuh-indexer
    systemctl start wazuh-dashboard
    
    # Attendre que les services démarrent
    log_info "Attente du démarrage des services (30 secondes)..."
    sleep 30
    
    # Vérifier l'état
    if ! systemctl is-active --quiet wazuh-manager; then
        error_exit "Le service wazuh-manager ne s'est pas démarré correctement"
    fi
    
    log_info "Services Wazuh démarrés et activés"
}

################################################################################
# Installation de Wazuh Agent
################################################################################
install_wazuh_agent() {
    log_step "Installation de Wazuh Agent..."
    
    # Installer le paquet
    dnf install -y wazuh-agent || error_exit "Échec de l'installation de l'agent"
    
    log_info "Wazuh Agent installé"
}

################################################################################
# Configuration de Wazuh Agent
################################################################################
configure_wazuh_agent() {
    log_step "Configuration de Wazuh Agent..."
    
    # Configurer l'adresse du manager
    log_info "Configuration du manager: $MANAGER_IP"
    
    # Éditer le fichier de configuration
    sed -i "s/<address>MANAGER_IP<\/address>/<address>$MANAGER_IP<\/address>/" \
        /var/ossec/etc/ossec.conf
    
    # Définir le nom de l'agent
    echo "$AGENT_NAME" > /var/ossec/etc/client.keys
    
    # Démarrer et activer le service
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
    
    if ! systemctl is-active --quiet wazuh-agent; then
        error_exit "Le service wazuh-agent ne s'est pas démarré"
    fi
    
    log_info "Agent configuré et démarré"
}

################################################################################
# Vérification de l'installation Manager
################################################################################
verify_manager_installation() {
    log_step "Vérification de l'installation du Manager..."
    
    # Vérifier les services
    local services=("wazuh-manager" "wazuh-indexer" "wazuh-dashboard")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_info "$service: ACTIF ✓"
        else
            log_error "$service: INACTIF ✗"
        fi
    done
    
    # Vérifier les ports
    if ss -tlnp | grep -q ":55000"; then
        log_info "Port API (55000): OUVERT ✓"
    fi
    
    if ss -tlnp | grep -q ":443"; then
        log_info "Port Dashboard (443): OUVERT ✓"
    fi
    
    # Afficher les informations de connexion
    log_info "Récupération des credentials..."
    
    if [[ -f /root/wazuh-install-files/wazuh-passwords.txt ]]; then
        local admin_password=$(grep "admin" /root/wazuh-install-files/wazuh-passwords.txt | awk '{print $4}')
        
        echo ""
        echo "=========================================="
        echo "  Informations de connexion Wazuh"
        echo "=========================================="
        echo ""
        echo "URL Dashboard: https://$(hostname -I | awk '{print $1}')"
        echo "Username: admin"
        echo "Password: $admin_password"
        echo ""
        echo "Fichier complet: /root/wazuh-install-files/wazuh-passwords.txt"
        echo "=========================================="
        echo ""
    fi
}

################################################################################
# Vérification de l'installation Agent
################################################################################
verify_agent_installation() {
    log_step "Vérification de l'installation de l'Agent..."
    
    if systemctl is-active --quiet wazuh-agent; then
        log_info "Service wazuh-agent: ACTIF ✓"
    else
        log_error "Service wazuh-agent: INACTIF ✗"
    fi
    
    # Vérifier la connexion au manager
    log_info "Vérification de la connexion au manager..."
    sleep 5
    
    if grep -q "Connected to the server" /var/ossec/logs/ossec.log 2>/dev/null; then
        log_info "Connexion au manager: OK ✓"
    else
        log_warn "Connexion au manager: vérification en cours..."
        log_warn "Consultez les logs: /var/ossec/logs/ossec.log"
    fi
}

################################################################################
# Configuration du firewall
################################################################################
configure_firewall() {
    log_step "Configuration du firewall..."
    
    if ! command -v firewall-cmd &> /dev/null; then
        log_warn "firewalld n'est pas installé"
        return
    fi
    
    if [[ "$INSTALL_TYPE" == "manager" ]]; then
        # Ports pour le manager
        firewall-cmd --permanent --add-port=1514/tcp  # Agent registration
        firewall-cmd --permanent --add-port=1515/tcp  # Agent communication
        firewall-cmd --permanent --add-port=55000/tcp # API
        firewall-cmd --permanent --add-port=9200/tcp  # Indexer
        firewall-cmd --permanent --add-port=443/tcp   # Dashboard
        
        firewall-cmd --reload
        log_info "Ports ouverts: 1514, 1515, 55000, 9200, 443"
    fi
    
    log_info "Firewall configuré"
}

################################################################################
# Affichage des informations post-installation
################################################################################
display_manager_info() {
    local server_ip=$(hostname -I | awk '{print $1}')
    
    cat << EOF

========================================
  Installation de Wazuh Manager réussie
========================================

Services installés:
  - Wazuh Manager
  - Wazuh Indexer
  - Wazuh Dashboard

URLs d'accès:
  Dashboard: https://$server_ip
  API:       https://$server_ip:55000

Credentials:
  Voir: /root/wazuh-install-files/wazuh-passwords.txt

Commandes utiles:
  systemctl status wazuh-manager
  systemctl status wazuh-indexer
  systemctl status wazuh-dashboard
  
  /var/ossec/bin/manage_agents     # Gérer les agents
  /var/ossec/bin/wazuh-control     # Contrôler Wazuh
  
  tail -f /var/ossec/logs/ossec.log

Prochaines étapes:
  1. Se connecter au Dashboard
  2. Ajouter des agents
  3. Créer des règles personnalisées

Documentation:
  https://documentation.wazuh.com/

Log: $LOGFILE
========================================

EOF
}

display_agent_info() {
    cat << EOF

========================================
  Installation de Wazuh Agent réussie
========================================

Configuration:
  Manager IP:  $MANAGER_IP
  Agent Name:  $AGENT_NAME

Commandes utiles:
  systemctl status wazuh-agent
  tail -f /var/ossec/logs/ossec.log
  
  /var/ossec/bin/wazuh-control status

Prochaines étapes:
  1. Enregistrer l'agent sur le manager
  2. Vérifier la connexion
  3. Configurer les règles de détection

Sur le Manager, exécuter:
  /var/ossec/bin/manage_agents
  
Log: $LOGFILE
========================================

EOF
}

################################################################################
# Fonction principale
################################################################################
main() {
    log_info "=== Début de l'installation de Wazuh ($INSTALL_TYPE) ==="
    log_info "Log file: $LOGFILE"
    
    check_prerequisites
    install_dependencies
    add_wazuh_repository
    
    if [[ "$INSTALL_TYPE" == "manager" ]]; then
        install_wazuh_manager
        configure_wazuh_manager
        configure_firewall
        verify_manager_installation
        
        trap - ERR
        display_manager_info
    else
        install_wazuh_agent
        configure_wazuh_agent
        verify_agent_installation
        
        trap - ERR
        display_agent_info
    fi
    
    log_info "=== Installation terminée avec succès ==="
}

# Gestion des arguments
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_usage
fi

# Exécution
main
