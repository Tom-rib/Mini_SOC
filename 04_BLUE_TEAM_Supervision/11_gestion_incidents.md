# 11. Gestion et documentation des incidents

**Objectif** : Mettre en place un système simple de ticketing et de suivi des incidents.

**Durée estimée** : 45 min  
**Niveau** : Intermédiaire  
**Prérequis** : Notions de suivi d'incidents

---

## 1. Workflow d'un incident

### Phase d'un incident

```
DÉTECTION → TRIAGE → ANALYSE → CONTENTION → REMÉDIATION → CLÔTURE
  (alerte)  (urgent?) (C'est quoi?) (Arrêter) (Nettoyer) (Apprendre)
```

### Rôles impliqués

| Phase | Rôle | Durée |
|-------|------|-------|
| Détection | SOC Analyst | 1-2 min |
| Triage | Incident Commander | 2-5 min |
| Analyse | SOC Team | 5-15 min |
| Contention | Sysadmin | 5-10 min |
| Remédiation | Sysadmin | 10-30 min |
| Clôture | Manager | 5-10 min |

---

## 2. Système simple de ticketing (basé sur fichiers)

### 2.1 Structure de dossier

```
/var/incident_tickets/
├── OPEN/
│   ├── INC_20250206_001.md
│   ├── INC_20250206_002.md
├── IN_PROGRESS/
│   ├── INC_20250205_015.md
├── RESOLVED/
│   ├── INC_20250204_010.md
└── CLOSED/
    ├── INC_20250203_005.md
```

**Format** : `INC_YYYYMMDD_NNNN.md` (YYYY=année, MM=mois, DD=jour, NNNN=numéro du jour)

### 2.2 Créer le système de dossier

```bash
sudo mkdir -p /var/incident_tickets/{OPEN,IN_PROGRESS,RESOLVED,CLOSED}
sudo chmod 770 /var/incident_tickets*
```

---

## 3. Template d'un ticket d'incident

### 3.1 Créer un template

Créer `/var/incident_tickets/TEMPLATE.md` :

```markdown
# Incident INC_YYYYMMDD_NNNN

**Status** : OPEN  
**Severity** : [CRITICAL / HIGH / MEDIUM / LOW]  
**Type** : [brute_force / malware / scan / escalade / autre]  
**Created** : YYYY-MM-DD HH:MM:SS  
**Updated** : YYYY-MM-DD HH:MM:SS  
**Assigned To** : [Nom de l'analyste]  

---

## DÉTECTION

**Alert Type** : [Nom de l'alerte Wazuh/Grafana]  
**Source** : [URL du dashboard ou ID de l'alerte]  
**Symptômes observés** :
- Symptôme 1
- Symptôme 2
- Symptôme 3

**Log snippet** :
```
[Coller les logs pertinents]
```

---

## ANALYSE

### Vérifications effectuées

- [ ] Logs SSH vérifiés
- [ ] Processus actifs analysés
- [ ] Connexions réseau examinées
- [ ] Wazuh logs consultés
- [ ] Fichiers modifiés cherchés

### Findings

- **IP source** : 192.168.1.50
- **Services affectés** : SSH, Nginx
- **Fichiers modifiés** : Aucun
- **Tentatives réussies** : Non
- **Compromission** : NON confirmée

### Assessment

**Verdict** : Attaque détectée mais BLOQUÉE  
**Risk Level** : MEDIUM (attaquant était préparé)  
**Next Steps** : Contention + remédiation

---

## CONTENTION (Actions prises)

| Time | Action | Responsible | Status |
|------|--------|-------------|--------|
| 14:35 | Bloquer IP 192.168.1.50 | Ansible | ✓ Done |
| 14:36 | Vérifier les logs | SOC1 | ✓ Done |
| 14:40 | Notification email | Script | ✓ Done |

**Command executed** :
```bash
/usr/local/bin/ir_block_ip.sh 192.168.1.50 3600
```

**Result** : IP bloquée au firewall pendant 1h

---

## REMÉDIATION

### Système affecté

- **Serveur** : web01 (192.168.1.100)
- **Service** : SSH
- **Config** : /etc/ssh/sshd_config

### Actions de nettoyage

| Action | Status | Evidence |
|--------|--------|----------|
| Changer SSH port | ✓ | Port changé de 22 à 2222 |
| Update SSH config | ✓ | PermitRootLogin = no |
| Redémarrer SSH | ✓ | Service restarted |
| Vérifier logs | ✓ | Pas de connexion réussie |
| Générer rapport | ✓ | /var/incident_evidence/... |

### Justification des changements

- Port SSH non-standard = réduire attaques automatiques
- PermitRootLogin = impossible d'utiliser root directement
- Audit log = tracer toute tentative future

---

## POST-INCIDENT

### Leçons apprises

1. **Quoi s'est passé ?**
   - Attaque SSH brute force depuis IP externe

2. **Comment a-t-on détecté ?**
   - Wazuh a alerté sur >5 failed password attempts

3. **Qu'a-t-on bien fait ?**
   - ✓ Fail2ban a bloqué automatiquement
   - ✓ Logs centralisés dans Wazuh

4. **Qu'on aurait pu mieux faire ?**
   - Clé SSH seulement (pas de mot de passe)
   - Rate limiting au firewall
   - NIDS (Snort/Suricata) pour les patterns

### Recommandations futures

- [x] Mettre en place l'authentification par clé seulement
- [x] Ajouter rate limiting au firewall (iptables limit)
- [ ] Installer Snort pour détection d'intrusion réseau
- [ ] Tester la procédure IR en simulation

---

## CLÔTURE

**Incident resolved** : YYYY-MM-DD HH:MM:SS  
**Closed By** : [Nom du manager]  
**Total Duration** : 35 minutes  
**Evidence Archive** : /var/incident_evidence/INC_YYYYMMDD_NNNN.tar.gz  

**Sign-off** :
```
Incident clôturé. Aucune compromission détectée.
Système sécurisé et durcis. A+
- SOC Manager
```

---
```

---

## 4. Script de création de ticket

### 4.1 Créer un générateur de tickets

Créer `/usr/local/bin/create_incident_ticket.sh` :

```bash
#!/bin/bash

################################################################################
# Script : Créer automatiquement un ticket d'incident
# Usage : ./create_incident_ticket.sh [TYPE] [SEVERITY]
################################################################################

TICKET_DIR="/var/incident_tickets/OPEN"
TODAY=$(date +%Y%m%d)
SEVERITY="${1:-MEDIUM}"
INCIDENT_TYPE="${2:-unknown}"

# === Trouver le prochain numéro ===
LAST_NUM=$(ls $TICKET_DIR/INC_${TODAY}_*.md 2>/dev/null | tail -1 | grep -oE '[0-9]{4}' | tail -1)
NEXT_NUM=$((${LAST_NUM:-0} + 1))
INCIDENT_ID=$(printf "INC_%s_%04d" "$TODAY" "$NEXT_NUM")

# === Créer le ticket ===
TICKET_FILE="${TICKET_DIR}/${INCIDENT_ID}.md"

cat > "$TICKET_FILE" <<EOF
# Incident ${INCIDENT_ID}

**Status** : OPEN
**Severity** : ${SEVERITY}
**Type** : ${INCIDENT_TYPE}
**Created** : $(date '+%Y-%m-%d %H:%M:%S')
**Updated** : $(date '+%Y-%m-%d %H:%M:%S')
**Assigned To** : [À assigner]

---

## DÉTECTION

**Alert Type** : [À remplir]
**Source** : [À remplir]
**Symptoms** :
- 

**Log snippet** :
\`\`\`
[À remplir]
\`\`\`

---

## ANALYSE

[À compléter par l'analyste]

---

## CONTENTION

[À compléter par le sysadmin]

---

## REMÉDIATION

[À compléter par le sysadmin]

---

## POST-INCIDENT

[À compléter par le manager]

---
EOF

echo "✓ Ticket créé : ${INCIDENT_ID}"
echo "  Fichier : ${TICKET_FILE}"
echo "  Severity : ${SEVERITY}"
echo "  Type : ${INCIDENT_TYPE}"

exit 0
```

### 4.2 Utilisation

```bash
# Créer un ticket brute force HIGH severity
sudo /usr/local/bin/create_incident_ticket.sh brute_force HIGH

# Résultat :
# ✓ Ticket créé : INC_20250206_0042
#   Fichier : /var/incident_tickets/OPEN/INC_20250206_0042.md
#   Severity : HIGH
#   Type : brute_force
```

---

## 5. Gestion du cycle de vie du ticket

### 5.1 Déplacer un ticket (workflow)

```bash
# L'analyste commence l'analyse
mv /var/incident_tickets/OPEN/INC_20250206_0042.md \
   /var/incident_tickets/IN_PROGRESS/INC_20250206_0042.md

# Quand c'est résolu
mv /var/incident_tickets/IN_PROGRESS/INC_20250206_0042.md \
   /var/incident_tickets/RESOLVED/INC_20250206_0042.md

# Après validation par le manager
mv /var/incident_tickets/RESOLVED/INC_20250206_0042.md \
   /var/incident_tickets/CLOSED/INC_20250206_0042.md
```

### 5.2 Script de transition

Créer `/usr/local/bin/move_incident.sh` :

```bash
#!/bin/bash

INCIDENT_ID="$1"
NEW_STATUS="$2"  # OPEN, IN_PROGRESS, RESOLVED, CLOSED

TICKET_DIR="/var/incident_tickets"
OLD_FILE=$(find "$TICKET_DIR" -name "${INCIDENT_ID}.md" 2>/dev/null)

if [ -z "$OLD_FILE" ]; then
    echo "[ERROR] Ticket ${INCIDENT_ID} non trouvé"
    exit 1
fi

# Déterminer l'ancien status
OLD_STATUS=$(dirname "$OLD_FILE" | xargs basename)

# Déplacer
NEW_FILE="${TICKET_DIR}/${NEW_STATUS}/${INCIDENT_ID}.md"
mv "$OLD_FILE" "$NEW_FILE"

echo "✓ ${INCIDENT_ID} : ${OLD_STATUS} → ${NEW_STATUS}"

exit 0
```

**Utilisation** :

```bash
sudo /usr/local/bin/move_incident.sh INC_20250206_0042 IN_PROGRESS
sudo /usr/local/bin/move_incident.sh INC_20250206_0042 RESOLVED
sudo /usr/local/bin/move_incident.sh INC_20250206_0042 CLOSED
```

---

## 6. Dashboard simple (Vue d'ensemble)

### 6.1 Script de rapport

Créer `/usr/local/bin/incident_dashboard.sh` :

```bash
#!/bin/bash

TICKET_DIR="/var/incident_tickets"

echo "╔════════════════════════════════════════════════════╗"
echo "║        INCIDENT MANAGEMENT DASHBOARD               ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

echo "📋 OPEN (À traiter)"
echo "─────────────────"
OPEN=$(ls $TICKET_DIR/OPEN/*.md 2>/dev/null | wc -l)
echo "Nombre : $OPEN"
ls -1 $TICKET_DIR/OPEN/*.md 2>/dev/null | xargs -I {} basename {}
echo ""

echo "🔧 IN PROGRESS (En cours)"
echo "─────────────────────────"
INPROG=$(ls $TICKET_DIR/IN_PROGRESS/*.md 2>/dev/null | wc -l)
echo "Nombre : $INPROG"
ls -1 $TICKET_DIR/IN_PROGRESS/*.md 2>/dev/null | xargs -I {} basename {}
echo ""

echo "✅ RESOLVED (Résolu)"
echo "───────────────────"
RESOLVED=$(ls $TICKET_DIR/RESOLVED/*.md 2>/dev/null | wc -l)
echo "Nombre : $RESOLVED"
ls -1 $TICKET_DIR/RESOLVED/*.md 2>/dev/null | xargs -I {} basename {}
echo ""

echo "🔒 CLOSED (Clôturé)"
echo "──────────────────"
CLOSED=$(ls $TICKET_DIR/CLOSED/*.md 2>/dev/null | wc -l)
echo "Nombre : $CLOSED"
ls -1 $TICKET_DIR/CLOSED/*.md 2>/dev/null | head -5 | xargs -I {} basename {}
echo ""

echo "📊 STATISTIQUES"
echo "───────────────"
TOTAL=$((OPEN + INPROG + RESOLVED + CLOSED))
echo "Total incidents : $TOTAL"
echo "MTTR (Mean Time To Resolve) : [À calculer]"
echo "MTTA (Mean Time To Acknowledge) : [À calculer]"

exit 0
```

**Résultat** :

```
╔════════════════════════════════════════════════════╗
║        INCIDENT MANAGEMENT DASHBOARD               ║
╚════════════════════════════════════════════════════╝

📋 OPEN (À traiter)
─────────────────
Nombre : 3
INC_20250206_0040.md
INC_20250206_0041.md
INC_20250206_0042.md

🔧 IN PROGRESS (En cours)
─────────────────────────
Nombre : 1
INC_20250206_0039.md

✅ RESOLVED (Résolu)
───────────────────
Nombre : 5
INC_20250205_0038.md
...

🔒 CLOSED (Clôturé)
──────────────────
Nombre : 47
INC_20250204_0035.md
...

📊 STATISTIQUES
───────────────
Total incidents : 56
MTTR (Mean Time To Resolve) : [À calculer]
MTTA (Mean Time To Acknowledge) : [À calculer]
```

---

## 7. SLA (Service Level Agreement) et KPI

### Métriques à tracker

| Métrique | Target | Bon | Mauvais |
|----------|--------|-----|---------|
| MTTA (Time to Acknowledge) | < 5 min | < 5m | > 15m |
| MTTR (Time to Resolve) | < 1h | < 30m | > 2h |
| Severity HIGH % resolved < 1h | > 80% | > 80% | < 50% |
| Tickets closed / week | > 10 | > 15 | < 5 |

### Script de calcul des KPI

```bash
#!/bin/bash

TICKET_DIR="/var/incident_tickets"
TODAY=$(date +%Y%m%d)
THIS_WEEK=$(date -d "7 days ago" +%Y%m%d)

echo "=== KPI REPORT ==="
echo ""

# Incidents cette semaine
WEEKLY_TOTAL=$(find $TICKET_DIR -name "INC_*.md" | wc -l)
echo "Incidents cette semaine : $WEEKLY_TOTAL"

# Fermés cette semaine
CLOSED_WEEKLY=$(ls $TICKET_DIR/CLOSED/INC_20250206*.md 2>/dev/null | wc -l)
echo "Incidents fermés : $CLOSED_WEEKLY"

# HIGH severity non fermés
HIGH_OPEN=$(grep -l "HIGH" $TICKET_DIR/OPEN/*.md 2>/dev/null | wc -l)
echo "HIGH severity OPEN : $HIGH_OPEN"

if [ $HIGH_OPEN -gt 0 ]; then
    echo "⚠️ Action requise : HIGH severity à traiter !"
fi

exit 0
```

---

## 8. Intégration avec les systèmes

### Création automatique via Wazuh

Ajouter à `/var/ossec/etc/ossec.conf` :

```xml
<command>
    <n>create_ticket</n>
    <executable>create_ticket.sh</executable>
    <expect>rule_id</expect>
    <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
    <command>create_ticket</command>
    <location>local</location>
    <rules_id>5712</rules_id>  <!-- Brute force rule -->
</active-response>
```

Script `/var/ossec/active-response/bin/create_ticket.sh` :

```bash
#!/bin/bash
SEVERITY=$1
RULE_ID=$2

/usr/local/bin/create_incident_ticket.sh "auto_detected" "$SEVERITY"

exit 0
```

---

## 9. Archivage et conformité

### Archiver les incidents clôturés

```bash
#!/bin/bash

# Archiver les incidents clôturés du mois dernier
ARCHIVE_DIR="/var/incident_archives"
mkdir -p "$ARCHIVE_DIR"

# Compresser
tar -czf "$ARCHIVE_DIR/incidents_202501.tar.gz" \
    /var/incident_tickets/CLOSED/INC_202501*.md

# Supprimer les originaux (gardé dans l'archive)
rm /var/incident_tickets/CLOSED/INC_202501*.md

echo "✓ Incidents archivés"
```

---

## 10. Checklist de gestion d'incidents

- [ ] Structure de dossier créée
- [ ] Template de ticket créé
- [ ] Script create_incident_ticket.sh testé
- [ ] Script move_incident.sh testé
- [ ] Script incident_dashboard.sh testé
- [ ] KPI calculés
- [ ] Wazuh intégré pour création auto
- [ ] Archivage en place
- [ ] SLA définis
- [ ] Équipe formée aux procédures

---

## 11. Résumé du workflow complet

```
Alerte Wazuh
    ↓
Ticket créé auto (INC_YYYYMMDD_NNNN)
    ↓
Status : OPEN
    ↓
Analyste assigné → Status : IN_PROGRESS
    ↓
Actions prises (contention + remédiation)
    ↓
Ticket complété → Status : RESOLVED
    ↓
Manager valide → Status : CLOSED
    ↓
Archivé pour conformité
```

Une bonne gestion d'incidents = traçabilité + apprentissage + compliance !
