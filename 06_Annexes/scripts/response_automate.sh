#!/bin/bash

################################################################################
# Script de réponse automatique aux incidents (Incident Response)
# Intégré avec Wazuh SIEM pour la détection et réaction aux attaques
#
# Usage: 
#   ./response_automate.sh --block-ip <IP>
#   ./response_automate.sh --get-attacks
#   ./response_automate.sh --monitor
#
# Ce script peut être appelé automatiquement par Wazuh ou manuellement
################################################################################

set -euo pipefail

# Configuration
LOGFILE="/var/log/incident_response_$(date +%Y%m%d).log"
REPORT_DIR="/var/ossec/logs/incidents"
WAZUH_API_URL="https://localhost:55000"
WAZUH_API_USER="wazuh"
WAZUH_API_PASS=""  # À configurer
NOTIFICATION_EMAIL="soc@example.com"  # À configurer
BANNED_IPS_FILE="/var/log/banned_ips.log"

# Seuils de détection
SSH_BRUTEFORCE_THRESHOLD=5
SCAN_THRESHOLD=20
SUSPICIOUS_COMMANDS=("rm -rf" "wget" "curl" "/dev/tcp" "nc -e")

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

log_alert() {
    echo -e "${MAGENTA}[ALERT]${NC} $@"
    log "ALERT" "$@"
}

log_incident() {
    echo -e "${RED}[INCIDENT]${NC} $@"
    log "INCIDENT" "$@"
}

################################################################################
# Fonction d'aide
################################################################################
show_usage() {
    cat << EOF
Usage: $0 [action] [options]

Actions:
  --block-ip <IP>           Bloquer une IP malveillante
  --unblock-ip <IP>         Débloquer une IP
  --get-attacks             Récupérer les attaques récentes depuis Wazuh
  --monitor                 Mode monitoring continu
  --check-logs              Analyser les logs système
  --generate-report         Générer un rapport d'incident
  --list-banned             Lister les IPs bannies
  --help                    Afficher cette aide

Exemples:
  $0 --block-ip 192.168.1.100
  $0 --get-attacks
  $0 --monitor

Configuration:
  Modifier les variables dans le script:
  - WAZUH_API_URL
  - WAZUH_API_USER
  - WAZUH_API_PASS
  - NOTIFICATION_EMAIL

EOF
    exit 0
}

################################################################################
# Initialisation
################################################################################
initialize() {
    # Créer les répertoires nécessaires
    mkdir -p "$REPORT_DIR"
    
    # Créer le fichier de log s'il n'existe pas
    touch "$LOGFILE"
    touch "$BANNED_IPS_FILE"
    
    # Vérifier les permissions
    if [[ $EUID -ne 0 ]]; then
        log_warn "Ce script devrait être exécuté en tant que root pour bloquer des IPs"
    fi
}

################################################################################
# Bloquer une IP avec firewalld
################################################################################
block_ip() {
    local ip="$1"
    local reason="${2:-Manual block}"
    
    log_alert "Blocage de l'IP: $ip (Raison: $reason)"
    
    # Vérifier si l'IP est déjà bloquée
    if firewall-cmd --list-all | grep -q "$ip"; then
        log_warn "L'IP $ip est déjà bloquée"
        return 0
    fi
    
    # Bloquer avec firewalld
    if firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject"; then
        firewall-cmd --reload
        log_info "IP $ip bloquée avec succès"
        
        # Enregistrer le blocage
        echo "$(date '+%Y-%m-%d %H:%M:%S') | $ip | $reason" >> "$BANNED_IPS_FILE"
        
        # Générer un mini-rapport
        generate_incident_report "$ip" "$reason"
        
        # Envoyer une notification
        send_notification "IP Blocked" "L'IP $ip a été bloquée. Raison: $reason"
        
        return 0
    else
        log_error "Échec du blocage de l'IP $ip"
        return 1
    fi
}

################################################################################
# Débloquer une IP
################################################################################
unblock_ip() {
    local ip="$1"
    
    log_info "Déblocage de l'IP: $ip"
    
    if firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$ip' reject"; then
        firewall-cmd --reload
        log_info "IP $ip débloquée avec succès"
        
        # Retirer du fichier de log
        sed -i "/$ip/d" "$BANNED_IPS_FILE"
        
        return 0
    else
        log_error "Échec du déblocage de l'IP $ip (peut-être pas bloquée)"
        return 1
    fi
}

################################################################################
# Lister les IPs bannies
################################################################################
list_banned_ips() {
    log_info "Liste des IPs bannies:"
    
    if [[ -f "$BANNED_IPS_FILE" && -s "$BANNED_IPS_FILE" ]]; then
        cat "$BANNED_IPS_FILE"
    else
        log_info "Aucune IP bannie"
    fi
    
    echo ""
    log_info "Règles firewall actives:"
    firewall-cmd --list-all | grep "rule family"
}

################################################################################
# Récupérer les alertes depuis Wazuh API
################################################################################
get_wazuh_alerts() {
    log_info "Récupération des alertes Wazuh..."
    
    # Vérifier si l'API est configurée
    if [[ -z "$WAZUH_API_PASS" ]]; then
        log_warn "API Wazuh non configurée (WAZUH_API_PASS vide)"
        log_warn "Analyse des logs locaux à la place..."
        analyze_local_logs
        return
    fi
    
    # Obtenir un token JWT
    local token=$(curl -s -u "$WAZUH_API_USER:$WAZUH_API_PASS" \
                  -k -X GET "$WAZUH_API_URL/security/user/authenticate" \
                  | grep -oP 'token":"?\K[^"]+')
    
    if [[ -z "$token" ]]; then
        log_error "Échec de l'authentification à l'API Wazuh"
        return 1
    fi
    
    # Récupérer les alertes récentes (dernière heure)
    local alerts=$(curl -s -k -X GET \
                   "$WAZUH_API_URL/alerts?limit=100" \
                   -H "Authorization: Bearer $token")
    
    # Analyser les alertes pour détecter des patterns
    echo "$alerts" | jq -r '.data.affected_items[] | 
        "\(.rule.level)|\(.rule.description)|\(.data.srcip // "N/A")"' 2>/dev/null | \
    while IFS='|' read -r level description srcip; do
        if [[ "$level" -ge 10 && "$srcip" != "N/A" ]]; then
            log_alert "Alerte niveau $level: $description (IP: $srcip)"
            
            # Réaction automatique si niveau critique
            if [[ "$level" -ge 12 ]]; then
                log_incident "Niveau critique détecté! Blocage automatique de $srcip"
                block_ip "$srcip" "Wazuh Alert Level $level: $description"
            fi
        fi
    done
}

################################################################################
# Analyser les logs locaux
################################################################################
analyze_local_logs() {
    log_info "Analyse des logs système..."
    
    # Analyser SSH bruteforce
    check_ssh_bruteforce
    
    # Analyser les scans de ports
    check_port_scans
    
    # Analyser les commandes suspectes
    check_suspicious_commands
    
    # Analyser les tentatives d'élévation de privilèges
    check_privilege_escalation
}

################################################################################
# Détecter les attaques SSH bruteforce
################################################################################
check_ssh_bruteforce() {
    log_info "Vérification des attaques SSH bruteforce..."
    
    local failed_attempts=$(grep "Failed password" /var/log/secure 2>/dev/null | \
                           grep "$(date '+%b %d')" | \
                           awk '{print $(NF-3)}' | \
                           sort | uniq -c | sort -rn)
    
    if [[ -n "$failed_attempts" ]]; then
        echo "$failed_attempts" | while read count ip; do
            if [[ "$count" -ge "$SSH_BRUTEFORCE_THRESHOLD" ]]; then
                log_incident "SSH Bruteforce détecté: $ip ($count tentatives)"
                block_ip "$ip" "SSH Bruteforce: $count failed attempts"
            fi
        done
    else
        log_info "Aucune attaque SSH bruteforce détectée"
    fi
}

################################################################################
# Détecter les scans de ports
################################################################################
check_port_scans() {
    log_info "Vérification des scans de ports..."
    
    # Analyser les logs de firewall
    local scanners=$(journalctl -u firewalld --since "1 hour ago" 2>/dev/null | \
                    grep -i "REJECT" | \
                    grep -oP 'SRC=\K[0-9.]+' | \
                    sort | uniq -c | sort -rn)
    
    if [[ -n "$scanners" ]]; then
        echo "$scanners" | while read count ip; do
            if [[ "$count" -ge "$SCAN_THRESHOLD" ]]; then
                log_incident "Scan de ports détecté: $ip ($count connexions rejetées)"
                block_ip "$ip" "Port Scan: $count rejected connections"
            fi
        done
    else
        log_info "Aucun scan de ports détecté"
    fi
}

################################################################################
# Détecter les commandes suspectes
################################################################################
check_suspicious_commands() {
    log_info "Vérification des commandes suspectes..."
    
    if ! command -v ausearch &> /dev/null; then
        log_warn "auditd n'est pas installé"
        return
    fi
    
    # Rechercher les commandes suspectes dans les logs audit
    for cmd in "${SUSPICIOUS_COMMANDS[@]}"; do
        local results=$(ausearch -ts today -m execve 2>/dev/null | grep -i "$cmd" || true)
        
        if [[ -n "$results" ]]; then
            log_alert "Commande suspecte détectée: $cmd"
            echo "$results" | head -5 | while read line; do
                log_warn "  $line"
            done
        fi
    done
}

################################################################################
# Détecter les tentatives d'élévation de privilèges
################################################################################
check_privilege_escalation() {
    log_info "Vérification des élévations de privilèges..."
    
    # Vérifier les tentatives sudo échouées
    local sudo_failures=$(grep "authentication failure" /var/log/secure 2>/dev/null | \
                         grep "$(date '+%b %d')" | \
                         grep "sudo" || true)
    
    if [[ -n "$sudo_failures" ]]; then
        log_alert "Tentatives sudo échouées détectées:"
        echo "$sudo_failures" | while read line; do
            log_warn "  $line"
        done
    fi
    
    # Vérifier les modifications de /etc/sudoers
    if command -v ausearch &> /dev/null; then
        local sudoers_changes=$(ausearch -k sudoers -ts today 2>/dev/null || true)
        
        if [[ -n "$sudoers_changes" ]]; then
            log_alert "Modifications de /etc/sudoers détectées!"
            echo "$sudoers_changes" | head -10
        fi
    fi
}

################################################################################
# Générer un rapport d'incident
################################################################################
generate_incident_report() {
    local ip="${1:-N/A}"
    local reason="${2:-Unknown}"
    local report_file="$REPORT_DIR/incident_${ip}_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Génération du rapport d'incident..."
    
    cat > "$report_file" << EOF
========================================
  RAPPORT D'INCIDENT
========================================
Date: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: $(hostname)
IP attaquante: $ip
Raison: $reason

DÉTAILS DE L'INCIDENT:
----------------------
$(grep "$ip" /var/log/secure 2>/dev/null | tail -20 || echo "Aucun log SSH trouvé")

INFORMATIONS RÉSEAU:
--------------------
Tentatives de connexion:
$(ss -tn | grep "$ip" 2>/dev/null || echo "Aucune connexion active")

GÉOLOCALISATION (approximative):
---------------------------------
$(geoiplookup "$ip" 2>/dev/null || echo "geoiplookup non disponible")

ACTIONS PRISES:
---------------
✓ IP bloquée via firewalld
✓ Alerte générée
✓ Log enregistré

RECOMMANDATIONS:
----------------
1. Vérifier les logs complets: /var/log/secure
2. Analyser les tentatives d'accès: ausearch -k logins
3. Vérifier l'intégrité du système: aide --check
4. Consulter Wazuh Dashboard pour plus de détails

========================================
EOF
    
    log_info "Rapport généré: $report_file"
}

################################################################################
# Générer un rapport complet
################################################################################
generate_full_report() {
    local report_file="$REPORT_DIR/full_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Génération du rapport complet..."
    
    cat > "$report_file" << EOF
========================================
  RAPPORT D'INCIDENTS - $(date '+%Y-%m-%d')
========================================

STATISTIQUES:
-------------
IPs bannies: $(wc -l < "$BANNED_IPS_FILE")
Incidents traités aujourd'hui: $(grep "$(date '+%Y-%m-%d')" "$LOGFILE" | grep -c "INCIDENT")
Alertes émises: $(grep "$(date '+%Y-%m-%d')" "$LOGFILE" | grep -c "ALERT")

IPS BANNIES:
------------
$(cat "$BANNED_IPS_FILE" 2>/dev/null || echo "Aucune")

TOP 10 DES ATTAQUANTS (SSH):
----------------------------
$(grep "Failed password" /var/log/secure 2>/dev/null | \
  awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10 || echo "Aucun")

SERVICES EN ÉCOUTE:
-------------------
$(ss -tlnp | grep LISTEN)

CONNEXIONS ACTIVES SUSPECTES:
------------------------------
$(ss -tn | grep -v "127.0.0.1" | grep ESTAB || echo "Aucune")

DERNIÈRES COMMANDES ROOT:
-------------------------
$(ausearch -k root_commands -ts today 2>/dev/null | tail -20 || echo "auditd non configuré")

ALERTES FAIL2BAN:
-----------------
$(fail2ban-client status sshd 2>/dev/null || echo "fail2ban non installé")

========================================
EOF
    
    log_info "Rapport complet généré: $report_file"
    cat "$report_file"
}

################################################################################
# Envoyer une notification
################################################################################
send_notification() {
    local subject="$1"
    local message="$2"
    
    log_info "Envoi de notification: $subject"
    
    # Notification par email (si configuré)
    if [[ -n "$NOTIFICATION_EMAIL" && "$NOTIFICATION_EMAIL" != "soc@example.com" ]]; then
        echo "$message" | mail -s "[SOC Alert] $subject" "$NOTIFICATION_EMAIL" 2>/dev/null || \
            log_warn "Échec de l'envoi d'email"
    fi
    
    # Notification système
    logger -t "incident_response" -p security.alert "$subject: $message"
    
    # Notification wall (tous les utilisateurs connectés)
    echo "$subject: $message" | wall 2>/dev/null || true
}

################################################################################
# Mode monitoring continu
################################################################################
monitor_mode() {
    log_info "Mode monitoring démarré (Ctrl+C pour arrêter)"
    
    while true; do
        echo ""
        log_info "=== Cycle de monitoring $(date '+%H:%M:%S') ==="
        
        # Vérifier Wazuh
        if [[ -n "$WAZUH_API_PASS" ]]; then
            get_wazuh_alerts
        fi
        
        # Analyser les logs
        analyze_local_logs
        
        # Afficher les stats
        echo ""
        log_info "Stats: $(grep -c INCIDENT "$LOGFILE" 2>/dev/null || echo 0) incidents, $(wc -l < "$BANNED_IPS_FILE") IPs bannies"
        
        # Attendre avant le prochain cycle (5 minutes)
        sleep 300
    done
}

################################################################################
# Fonction principale
################################################################################
main() {
    initialize
    
    log_info "=== Incident Response Automation ==="
    log_info "Log: $LOGFILE"
    
    # Parse arguments
    case "${1:-}" in
        --block-ip)
            if [[ -z "${2:-}" ]]; then
                log_error "IP manquante"
                show_usage
            fi
            block_ip "$2" "${3:-Manual block}"
            ;;
        --unblock-ip)
            if [[ -z "${2:-}" ]]; then
                log_error "IP manquante"
                show_usage
            fi
            unblock_ip "$2"
            ;;
        --get-attacks)
            get_wazuh_alerts
            ;;
        --monitor)
            monitor_mode
            ;;
        --check-logs)
            analyze_local_logs
            ;;
        --generate-report)
            generate_full_report
            ;;
        --list-banned)
            list_banned_ips
            ;;
        --help)
            show_usage
            ;;
        *)
            log_error "Action inconnue: ${1:-none}"
            show_usage
            ;;
    esac
    
    log_info "=== Terminé ==="
}

# Exécution
main "$@"
