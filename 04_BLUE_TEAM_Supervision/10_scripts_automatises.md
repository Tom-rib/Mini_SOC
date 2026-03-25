# 10. Scripts Bash automatisés pour Incident Response

**Objectif** : Créer des scripts Bash qui réagissent automatiquement aux incidents.

**Durée estimée** : 1h30  
**Niveau** : Avancé  
**Prérequis** : Wazuh configuré, firewalld, Bash

---

## 1. Concept : Automatisation vs Manuel

### Timeline d'une attaque

```
T+0s  : Attaque démarre
T+30s : Wazuh détecte
T+35s : Analyste regarde l'alerte
T+2m  : Analyste tape les commandes
T+2m30s : Attaquant a le temps de faire des dégâts

VS

T+0s  : Attaque démarre
T+30s : Wazuh détecte
T+31s : Script automatique exécute les actions
T+32s : Attaquant est bloqué
```

**Gain** : 120 secondes sauvées = dégâts évités.

---

## 2. Script #1 : Bloquer une IP et notifier

### 2.1 Création du script

Créer `/usr/local/bin/ir_block_ip.sh` :

```bash
#!/bin/bash

################################################################################
# Script : Bloquer une IP attaquante et notifier
# Usage : ./ir_block_ip.sh <IP> [DURÉE_SECONDES]
# Exemple : ./ir_block_ip.sh 192.168.1.50 3600
################################################################################

set -e  # Arrêter si une commande échoue

# === Configuration ===
ATTACKER_IP="${1:-unknown}"
BLOCK_DURATION="${2:-3600}"  # 1 heure par défaut
NOTIFY_EMAIL="soc-team@monentreprise.fr"
LOG_FILE="/var/log/ir_incidents.log"
LOCK_FILE="/tmp/ir_block_${ATTACKER_IP}.lock"

# Vérifier les arguments
if [ "$ATTACKER_IP" == "" ] || [ "$ATTACKER_IP" == "unknown" ]; then
    echo "[ERROR] Usage: $0 <IP> [DURÉE]"
    exit 1
fi

# === Fonctions ===

log_action() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" | tee -a "$LOG_FILE"
}

notify_slack() {
    local message="$1"
    local webhook_url="https://hooks.slack.com/services/YOUR_WEBHOOK_URL"
    
    # Envoyer à Slack (si configuré)
    if [ ! -z "$webhook_url" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\": \"🚨 IR Alert: ${message}\"}" \
            "$webhook_url" 2>/dev/null || true
    fi
}

send_email() {
    local subject="$1"
    local body="$2"
    
    # Envoyer un email
    echo "$body" | mail -s "$subject" "$NOTIFY_EMAIL" 2>/dev/null || true
}

check_already_blocked() {
    # Vérifier si l'IP est déjà bloquée
    firewall-cmd --zone=drop --list-sources 2>/dev/null | grep -q "$ATTACKER_IP"
    return $?  # 0 = déjà bloquée, 1 = pas bloquée
}

# === MAIN ===

log_action "[START] Blocage IP ${ATTACKER_IP} demandé"

# Vérifier si la commande est lancée par root
if [ "$EUID" -ne 0 ]; then 
    log_action "[ERROR] Ce script doit être lancé en root"
    exit 1
fi

# Vérifier si l'IP est valide
if ! [[ $ATTACKER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    log_action "[ERROR] IP invalide: ${ATTACKER_IP}"
    exit 1
fi

# Vérifier si déjà bloquée
if check_already_blocked; then
    log_action "[INFO] IP ${ATTACKER_IP} déjà bloquée"
    exit 0
fi

# === Étape 1 : Bloquer au firewall ===
log_action "[ACTION] Ajout de ${ATTACKER_IP} à la zone drop"

firewall-cmd --permanent --zone=drop --add-source="${ATTACKER_IP}/32"
if [ $? -eq 0 ]; then
    firewall-cmd --reload
    log_action "[SUCCESS] IP ${ATTACKER_IP} bloquée via firewalld"
else
    log_action "[ERROR] Échec du blocage firewall"
    exit 1
fi

# === Étape 2 : Bloquer via IPTables (backup) ===
log_action "[ACTION] Blocage IPTables pour ${ATTACKER_IP}"

iptables -A INPUT -s "${ATTACKER_IP}" -j DROP
iptables-save | tee /etc/iptables/rules.v4 > /dev/null 2>&1 || true

# === Étape 3 : Collecter les logs de l'attaquant ===
log_action "[ACTION] Collecte des logs relatifs à ${ATTACKER_IP}"

EVIDENCE_DIR="/var/incident_evidence/$(date +%s)_${ATTACKER_IP}"
mkdir -p "$EVIDENCE_DIR"

# Grep les logs contenant cette IP
grep "$ATTACKER_IP" /var/log/secure > "$EVIDENCE_DIR/auth_logs.txt" 2>/dev/null || true
grep "$ATTACKER_IP" /var/log/audit/audit.log > "$EVIDENCE_DIR/audit_logs.txt" 2>/dev/null || true

# Logs Wazuh (si disponible)
if [ -d "/var/ossec/logs/alerts" ]; then
    grep "$ATTACKER_IP" /var/ossec/logs/alerts/alerts.log > "$EVIDENCE_DIR/wazuh_alerts.txt" 2>/dev/null || true
fi

log_action "[SUCCESS] Logs collectés dans ${EVIDENCE_DIR}"

# === Étape 4 : Notifications ===
log_action "[ACTION] Envoi des notifications"

notify_slack "IP ${ATTACKER_IP} bloquée pour ${BLOCK_DURATION}s"

send_email \
    "ALERT: IP ${ATTACKER_IP} bloquée" \
    "L'IP ${ATTACKER_IP} a été bloquée automatiquement.
    
Durée : ${BLOCK_DURATION} secondes
Logs : ${EVIDENCE_DIR}

Cette notification a été générée automatiquement par le script IR."

# === Étape 5 : Planifier le déblocage (optionnel) ===
if [ "$BLOCK_DURATION" -gt 0 ]; then
    log_action "[ACTION] Planification du déblocage dans ${BLOCK_DURATION}s"
    
    # Créer une tâche at (si disponible)
    if command -v at &> /dev/null; then
        echo "firewall-cmd --permanent --zone=drop --remove-source='${ATTACKER_IP}/32' && firewall-cmd --reload" | \
            at "now + ${BLOCK_DURATION} seconds" 2>/dev/null || true
    fi
fi

# === Résumé ===
log_action "[DONE] IP ${ATTACKER_IP} bloquée avec succès"
log_action "======================================="

echo "✓ Blocage terminé : ${ATTACKER_IP}"
echo "  - Firewall : Bloqué"
echo "  - Durée : ${BLOCK_DURATION}s"
echo "  - Logs : ${EVIDENCE_DIR}"

exit 0
```

### 2.2 Rendre exécutable

```bash
sudo chmod +x /usr/local/bin/ir_block_ip.sh
```

### 2.3 Tester le script

```bash
# Test (pas d'admin, avec sudo)
sudo /usr/local/bin/ir_block_ip.sh 192.168.1.50 3600

# Résultat attendu :
# ✓ Blocage terminé : 192.168.1.50
#   - Firewall : Bloqué
#   - Durée : 3600s
#   - Logs : /var/incident_evidence/1707201234_192.168.1.50
```

---

## 3. Script #2 : Tuer un processus malveillant

### 3.1 Création du script

Créer `/usr/local/bin/ir_kill_process.sh` :

```bash
#!/bin/bash

################################################################################
# Script : Tuer un processus suspect
# Usage : ./ir_kill_process.sh <PROCESS_NAME> [SIGNAL]
# Exemple : ./ir_kill_process.sh nginx 9
################################################################################

set -e

PROCESS_NAME="${1:-}"
SIGNAL="${2:-15}"  # SIGTERM par défaut
LOG_FILE="/var/log/ir_incidents.log"

# === Validation ===
if [ -z "$PROCESS_NAME" ]; then
    echo "[ERROR] Usage: $0 <PROCESS_NAME> [SIGNAL]"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ce script doit être lancé en root"
    exit 1
fi

# === Fonctions ===
log_action() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1" | tee -a "$LOG_FILE"
}

# === Main ===
log_action "[START] Terminaison du processus ${PROCESS_NAME}"

# Trouver les PIDs du processus
PIDS=$(pgrep -f "$PROCESS_NAME" 2>/dev/null || echo "")

if [ -z "$PIDS" ]; then
    log_action "[INFO] Aucun processus trouvé pour ${PROCESS_NAME}"
    exit 0
fi

log_action "[INFO] PIDs trouvés : $(echo $PIDS | tr '\n' ' ')"

# Tuer les processus
for PID in $PIDS; do
    log_action "[ACTION] Envoi du signal ${SIGNAL} au PID ${PID}"
    
    if kill -"${SIGNAL}" "$PID" 2>/dev/null; then
        log_action "[SUCCESS] PID ${PID} tué"
    else
        log_action "[ERROR] Impossible de tuer le PID ${PID}"
    fi
done

# Vérifier que les processus sont morts
sleep 1

REMAINING=$(pgrep -f "$PROCESS_NAME" 2>/dev/null || echo "")

if [ -z "$REMAINING" ]; then
    log_action "[SUCCESS] Tous les processus ${PROCESS_NAME} ont été terminés"
    exit 0
else
    log_action "[WARNING] Certains processus ${PROCESS_NAME} sont toujours actifs"
    log_action "[ACTION] Utilisation du signal KILL (-9)"
    
    for PID in $REMAINING; do
        kill -9 "$PID" 2>/dev/null || true
    done
    
    log_action "[DONE] Force kill appliquée"
    exit 0
fi
```

### 3.2 Utilisation

```bash
# Tuer nginx proprement
sudo /usr/local/bin/ir_kill_process.sh nginx 15

# Forcer l'arrêt d'un processus suspect
sudo /usr/local/bin/ir_kill_process.sh malware 9
```

---

## 4. Script #3 : Générer un rapport d'incident

### 4.1 Création du script

Créer `/usr/local/bin/ir_generate_report.sh` :

```bash
#!/bin/bash

################################################################################
# Script : Générer un rapport d'incident complet
# Usage : ./ir_generate_report.sh <INCIDENT_ID> [TYPE_INCIDENT]
# Exemple : ./ir_generate_report.sh 20250206_001 brute_force
################################################################################

INCIDENT_ID="${1:-INCIDENT_$(date +%s)}"
INCIDENT_TYPE="${2:-UNKNOWN}"
REPORT_DIR="/var/incident_reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# === Créer le répertoire ===
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/${INCIDENT_ID}_report.md"

# === Générer le rapport Markdown ===
cat > "$REPORT_FILE" <<EOF
# Rapport d'Incident

**ID Incident** : ${INCIDENT_ID}  
**Type** : ${INCIDENT_TYPE}  
**Date/Heure** : ${TIMESTAMP}  
**Rapport généré par** : ir_generate_report.sh  

---

## 1. RÉSUMÉ EXÉCUTIF

Incident de type **${INCIDENT_TYPE}** détecté et traité automatiquement.

---

## 2. TIMELINE

\`\`\`
$(date '+%H:%M:%S') - Incident détecté
$(date '+%H:%M:%S') - Actions automatiques exécutées
$(date '+%H:%M:%S') - Rapport généré
\`\`\`

---

## 3. SYSTÈME AFFECTÉ

**Hostname** : $(hostname)  
**IP** : $(hostname -I)  
**OS** : $(cat /etc/os-release | grep "PRETTY_NAME")  
**Kernel** : $(uname -r)  
**Uptime** : $(uptime)  

---

## 4. INDICATEURS DE COMPROMISSION

### Processus actifs suspects
\`\`\`
$(ps auxf | head -20)
\`\`\`

### Connexions réseau actives
\`\`\`
$(ss -tuln | head -15)
\`\`\`

### Utilisateurs connectés
\`\`\`
$(w)
\`\`\`

### Modifications récentes de fichiers
\`\`\`
$(find / -type f -mtime -1 2>/dev/null | head -20)
\`\`\`

---

## 5. LOGS PERTINENTS

### SSH logs
\`\`\`
$(tail -20 /var/log/secure 2>/dev/null || echo "N/A")
\`\`\`

### Audit logs
\`\`\`
$(tail -20 /var/log/audit/audit.log 2>/dev/null || echo "N/A")
\`\`\`

### Wazuh alerts
\`\`\`
$(tail -20 /var/ossec/logs/alerts/alerts.log 2>/dev/null || echo "N/A")
\`\`\`

---

## 6. ACTIONS PRISES

- [x] Incident détecté
- [x] Actions automatiques lancées
- [ ] Communication à la direction
- [ ] Analyse approfondie
- [ ] Remédiation supplémentaire
- [ ] Leçons apprises documentées

---

## 7. PROCHAINES ÉTAPES

1. Analyste SOC à vérifier le rapport
2. Incident Commander à évaluer la sévérité
3. Sysadmin à appliquer les remèdes
4. Manager à documenter dans le journal

---

## 8. CONTACTS

- **SOC Team** : soc-team@monentreprise.fr
- **Incident Commander** : ic@monentreprise.fr
- **Sysadmin** : sysadmin@monentreprise.fr

---

**Rapport généré le** : ${TIMESTAMP}  
**Fichier** : ${REPORT_FILE}

EOF

# === Afficher le chemin du rapport ===
echo "✓ Rapport généré : ${REPORT_FILE}"

# === Envoyer par email (optionnel) ===
if command -v mail &> /dev/null; then
    mail -s "Incident Report: ${INCIDENT_ID}" soc-team@monentreprise.fr < "$REPORT_FILE"
    echo "✓ Rapport envoyé par email"
fi

# === Archiver les preuves ===
EVIDENCE_DIR="/var/incident_evidence/${INCIDENT_ID}"
if [ -d "$EVIDENCE_DIR" ]; then
    tar -czf "${REPORT_DIR}/${INCIDENT_ID}_evidence.tar.gz" "$EVIDENCE_DIR"
    echo "✓ Preuves archivées : ${REPORT_DIR}/${INCIDENT_ID}_evidence.tar.gz"
fi

exit 0
```

### 4.2 Utilisation

```bash
sudo /usr/local/bin/ir_generate_report.sh 20250206_brute_force brute_force

# Résultat :
# ✓ Rapport généré : /var/incident_reports/20250206_brute_force_report.md
# ✓ Rapport envoyé par email
# ✓ Preuves archivées : /var/incident_reports/20250206_brute_force_evidence.tar.gz
```

---

## 5. Intégrer avec Wazuh

### Créer un script Wazuh d'alerte personnalisée

Éditer `/var/ossec/etc/ossec.conf` :

```xml
<!-- Ajouter après </alerts> -->
<command>
    <name>ir_auto_block</name>
    <executable>ir_auto_block.sh</executable>
    <expect>srcip</expect>
    <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
    <command>ir_auto_block</command>
    <location>local</location>
    <rules_id>5712,31101</rules_id>  # IDs des règles de brute force
</active-response>
```

Créer `/var/ossec/active-response/bin/ir_auto_block.sh` :

```bash
#!/bin/bash
# Ce script est appelé par Wazuh automatiquement lors d'une alerte

ATTACKER_IP="$1"
LOG_FILE="/var/log/ir_wazuh.log"

echo "[$(date)] Auto-blocking IP: ${ATTACKER_IP}" >> "$LOG_FILE"

# Appeler notre script de blocage
/usr/local/bin/ir_block_ip.sh "$ATTACKER_IP" 7200

exit 0
```

---

## 6. Chaîner les scripts (orchestration)

Créer `/usr/local/bin/ir_full_response.sh` :

```bash
#!/bin/bash

ATTACKER_IP="$1"
INCIDENT_TYPE="$2"

echo "🚨 Réponse complète à l'incident"

echo "1️⃣ Blocage de l'IP..."
/usr/local/bin/ir_block_ip.sh "$ATTACKER_IP" 3600

echo "2️⃣ Arrêt des services menacés..."
if [ "$INCIDENT_TYPE" == "upload" ]; then
    /usr/local/bin/ir_kill_process.sh nginx 15
fi

echo "3️⃣ Génération du rapport..."
/usr/local/bin/ir_generate_report.sh "$(date +%s)_${ATTACKER_IP}" "$INCIDENT_TYPE"

echo "✅ Réponse complétée"
```

**Utilisation** :

```bash
sudo /usr/local/bin/ir_full_response.sh 192.168.1.50 brute_force
```

---

## 7. Automatiser les scripts (cron + Wazuh)

### 7.1 Exécution via Wazuh alerts

Wazuh peut exécuter automatiquement les scripts lors d'une alerte.

### 7.2 Exécution programmée

```bash
# Nettoyer les logs tous les jours à minuit
0 0 * * * /usr/local/bin/ir_cleanup_logs.sh

# Générer un rapport hebdomadaire
0 2 * * 0 /usr/local/bin/ir_weekly_report.sh
```

---

## 8. Checklist scripts

- [ ] Script block_ip.sh créé et testé
- [ ] Script kill_process.sh créé et testé
- [ ] Script generate_report.sh créé et testé
- [ ] Scripts rendus exécutables
- [ ] Wazuh configuré pour appeler les scripts
- [ ] Logs d'exécution dans /var/log/ir_incidents.log
- [ ] Email/Slack notifications fonctionnels
- [ ] Orchestration (full_response) testée

---

## 9. Résumé des scripts

```
incident → Wazuh → Script IR → Actions auto
                   ├─ block_ip.sh
                   ├─ kill_process.sh
                   ├─ generate_report.sh
                   └─ notifications
```

Les scripts = réactivité automatique sans intervention humaine !
