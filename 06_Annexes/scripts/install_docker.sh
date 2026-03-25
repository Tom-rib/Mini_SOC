#!/bin/bash

################################################################################
# Script d'installation de Docker sur Rocky Linux
# Compatible avec Rocky Linux 8.x et 9.x
#
# Usage: sudo ./install_docker.sh [username]
# Exemple: sudo ./install_docker.sh student
#
# Ce script installe Docker Engine et Docker Compose, puis ajoute un utilisateur
# au groupe docker pour permettre l'utilisation sans sudo.
################################################################################

set -euo pipefail  # Arrêter le script en cas d'erreur

# Configuration
LOGFILE="/var/log/install_docker_$(date +%Y%m%d_%H%M%S).log"
USERNAME="${1:-$USER}"  # Utiliser le premier argument ou l'utilisateur courant

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Fonction de logging
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

################################################################################
# Fonction de gestion des erreurs
################################################################################
error_exit() {
    log_error "$1"
    log_error "Installation échouée. Consultez le log: $LOGFILE"
    exit 1
}

################################################################################
# Fonction de rollback
################################################################################
rollback() {
    log_warn "Rollback en cours..."
    
    # Arrêter Docker si actif
    systemctl stop docker 2>/dev/null || true
    
    # Désinstaller les paquets Docker
    dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || true
    
    # Supprimer le repository
    rm -f /etc/yum.repos.d/docker-ce.repo
    
    log_info "Rollback terminé"
}

# Capturer les erreurs et faire un rollback
trap 'rollback' ERR

################################################################################
# Vérification des prérequis
################################################################################
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier si l'utilisateur est root
    if [[ $EUID -ne 0 ]]; then
        error_exit "Ce script doit être exécuté en tant que root (sudo)"
    fi
    
    # Vérifier la version de Rocky Linux
    if [[ ! -f /etc/rocky-release ]]; then
        error_exit "Ce script est conçu pour Rocky Linux uniquement"
    fi
    
    local version=$(cat /etc/rocky-release | grep -oP '\d+' | head -1)
    log_info "Rocky Linux version détectée: $version"
    
    if [[ "$version" -lt 8 ]]; then
        error_exit "Rocky Linux 8.x ou supérieur requis"
    fi
    
    # Vérifier si Docker est déjà installé
    if command -v docker &> /dev/null; then
        log_warn "Docker est déjà installé: $(docker --version)"
        read -p "Voulez-vous réinstaller Docker? (o/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Oo]$ ]]; then
            log_info "Installation annulée"
            exit 0
        fi
    fi
    
    log_info "Prérequis vérifiés avec succès"
}

################################################################################
# Désinstallation des anciennes versions
################################################################################
remove_old_versions() {
    log_info "Suppression des anciennes versions de Docker (si présentes)..."
    
    dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc 2>/dev/null || true
    
    log_info "Anciennes versions supprimées"
}

################################################################################
# Installation des dépendances
################################################################################
install_dependencies() {
    log_info "Installation des dépendances..."
    
    dnf install -y dnf-plugins-core || error_exit "Échec de l'installation de dnf-plugins-core"
    
    log_info "Dépendances installées"
}

################################################################################
# Ajout du repository Docker
################################################################################
add_docker_repository() {
    log_info "Ajout du repository Docker officiel..."
    
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || \
        error_exit "Échec de l'ajout du repository Docker"
    
    log_info "Repository Docker ajouté"
}

################################################################################
# Installation de Docker
################################################################################
install_docker() {
    log_info "Installation de Docker Engine..."
    
    dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || \
        error_exit "Échec de l'installation de Docker"
    
    log_info "Docker Engine installé avec succès"
}

################################################################################
# Configuration et démarrage de Docker
################################################################################
start_docker() {
    log_info "Démarrage et activation de Docker..."
    
    # Démarrer Docker
    systemctl start docker || error_exit "Échec du démarrage de Docker"
    
    # Activer Docker au démarrage
    systemctl enable docker || error_exit "Échec de l'activation de Docker au démarrage"
    
    log_info "Docker démarré et activé"
}

################################################################################
# Ajout de l'utilisateur au groupe docker
################################################################################
add_user_to_docker_group() {
    log_info "Ajout de l'utilisateur '$USERNAME' au groupe docker..."
    
    # Vérifier si l'utilisateur existe
    if ! id "$USERNAME" &>/dev/null; then
        log_warn "L'utilisateur '$USERNAME' n'existe pas"
        return
    fi
    
    # Ajouter l'utilisateur au groupe docker
    usermod -aG docker "$USERNAME" || log_warn "Échec de l'ajout au groupe docker"
    
    log_info "Utilisateur '$USERNAME' ajouté au groupe docker"
    log_warn "L'utilisateur doit se déconnecter et se reconnecter pour que les changements prennent effet"
}

################################################################################
# Vérification de l'installation
################################################################################
verify_installation() {
    log_info "Vérification de l'installation..."
    
    # Vérifier la version de Docker
    local docker_version=$(docker --version)
    log_info "Docker installé: $docker_version"
    
    # Vérifier la version de Docker Compose
    local compose_version=$(docker compose version)
    log_info "Docker Compose installé: $compose_version"
    
    # Vérifier le statut du service
    if systemctl is-active --quiet docker; then
        log_info "Service Docker: ACTIF"
    else
        error_exit "Service Docker: INACTIF"
    fi
    
    # Test avec hello-world
    log_info "Test avec l'image hello-world..."
    if docker run --rm hello-world &>> "$LOGFILE"; then
        log_info "Test réussi: Docker fonctionne correctement"
    else
        log_warn "Le test hello-world a échoué, mais Docker est installé"
    fi
}

################################################################################
# Affichage des informations post-installation
################################################################################
display_info() {
    echo ""
    echo "=========================================="
    echo "  Installation de Docker terminée"
    echo "=========================================="
    echo ""
    echo "Versions installées:"
    docker --version
    docker compose version
    echo ""
    echo "Commandes utiles:"
    echo "  - docker ps                 # Liste des conteneurs actifs"
    echo "  - docker images             # Liste des images"
    echo "  - docker compose up -d      # Démarrer une stack"
    echo "  - systemctl status docker   # Statut du service"
    echo ""
    echo "Documentation:"
    echo "  - https://docs.docker.com/"
    echo ""
    echo "Note: L'utilisateur '$USERNAME' doit se déconnecter"
    echo "      et se reconnecter pour utiliser Docker sans sudo."
    echo ""
    echo "Log d'installation: $LOGFILE"
    echo "=========================================="
}

################################################################################
# Fonction principale
################################################################################
main() {
    log_info "=== Début de l'installation de Docker sur Rocky Linux ==="
    log_info "Log file: $LOGFILE"
    
    check_prerequisites
    remove_old_versions
    install_dependencies
    add_docker_repository
    install_docker
    start_docker
    add_user_to_docker_group
    verify_installation
    
    log_info "=== Installation terminée avec succès ==="
    
    # Désactiver le trap de rollback car l'installation a réussi
    trap - ERR
    
    display_info
}

# Exécution du script
main
