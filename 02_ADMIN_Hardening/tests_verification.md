# 🧪 Tests de Vérification – Rôle 1 : Admin Système & Hardening

**Objectif :** Vérifier que chaque étape du hardening est correctement appliquée.

**Comment utiliser ce document :**
1. Exécuter chaque commande de test
2. Vérifier que le résultat correspond à l'attendu
3. Noter ✓ ou ✗ dans la colonne "Status"
4. Conserver les logs de test

---

## 🔧 Test 1 : Installation & Partitionnement

### Test 1.1 : Vérifier version Rocky Linux

```bash
# Commande
cat /etc/os-release | grep "PRETTY_NAME"
```

**Résultat attendu :**
```
PRETTY_NAME="Rocky Linux 8.x" (ou 9.x)
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 1.2 : Vérifier partitionnement

```bash
# Commande
lsblk
```

**Résultat attendu :**
```
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda           8:0    0  100G  0 disk
├─sda1        8:1    0    1G  0 part /boot
├─sda2        8:2    0   30G  0 part /
├─sda3        8:3    0   10G  0 part /var
├─sda4        8:4    0   10G  0 part /home
└─sda5        8:5    0    2G  0 part [SWAP]
```

**Vérification :**
- ✓ Partition `/` présente (min 30GB)
- ✓ Partition `/var` présente (min 10GB)
- ✓ Partition `/home` présente (min 10GB)
- ✓ Swap présent (min 2GB)

**Status :** ☐ ✓ | ☐ ✗

---

### Test 1.3 : Vérifier espace disque utilisé

```bash
# Commande
df -h
```

**Résultat attendu :**
```
Filesystem     Size  Used Avail Use% Mounted on
/dev/sda2       30G  2.5G   27G   9% /
/dev/sda3       10G  500M  9.5G   5% /var
/dev/sda4       10G  100M  9.9G   1% /home
/dev/sda1        1G  200M  800M  20% /boot
```

**Vérification :**
- ✓ Aucune partition > 80% utilisée

**Status :** ☐ ✓ | ☐ ✗

---

## 🌍 Test 2 : Configuration Réseau

### Test 2.1 : Vérifier hostname

```bash
# Commande
hostname
```

**Résultat attendu :**
```
web-server
```
(ou `soc` ou `monitoring` selon la VM)

**Status :** ☐ ✓ | ☐ ✗

---

### Test 2.2 : Vérifier IP statique

```bash
# Commande
ip addr show
```

**Résultat attendu :**
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    link/ether 08:00:27:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 192.168.X.Y/24 brd 192.168.X.255 scope global noprefixroute eth0
```

**Vérification :**
- ✓ Adresse IP statique (pas DHCP)
- ✓ IP cohérente avec schéma réseau

**Status :** ☐ ✓ | ☐ ✗

---

### Test 2.3 : Vérifier DNS

```bash
# Commande
cat /etc/resolv.conf
```

**Résultat attendu :**
```
nameserver 8.8.8.8
nameserver 8.8.4.4
```
(ou votre DNS configuré)

**Status :** ☐ ✓ | ☐ ✗

---

### Test 2.4 : Vérifier mise à jour système

```bash
# Commande
dnf check-update
```

**Résultat attendu :**
```
No packages to update
```

**Status :** ☐ ✓ | ☐ ✗

---

## 👤 Test 3 : Gestion des Comptes & Accès

### Test 3.1 : Vérifier compte admin créé

```bash
# Commande
id admin
```

**Résultat attendu :**
```
uid=1000(admin) gid=1000(admin) groups=1000(admin),10(wheel),4(adm)
```

**Vérification :**
- ✓ Utilisateur `admin` existe
- ✓ UID = 1000 (premier utilisateur)
- ✓ Groupe `wheel` présent (pour sudo)

**Status :** ☐ ✓ | ☐ ✗

---

### Test 3.2 : Vérifier sudo configuré pour admin

```bash
# Commande
sudo -l
```

**Résultat attendu :**
```
User admin may run the following commands on web-server:
    (ALL) ALL
```

**Vérification :**
- ✓ Admin a accès sudo
- ✓ (ALL) ALL = privilèges complets

**Status :** ☐ ✓ | ☐ ✗

---

### Test 3.3 : Vérifier root ne peut pas se connecter directement

```bash
# Commande (sur une autre VM/host)
ssh -p 2222 root@192.168.X.Y
```

**Résultat attendu :**
```
Permission denied (publickey).
```

**Vérification :**
- ✓ Root ne peut pas se connecter par SSH
- ✓ Authentification par clé obligatoire

**Status :** ☐ ✓ | ☐ ✗

---

### Test 3.4 : Vérifier utilisateurs système désactivés

```bash
# Commande
cat /etc/passwd | grep -E "^(sync|shutdown|halt|nologin)"
```

**Résultat attendu :**
```
sync:x:5:0:sync:/sbin:/usr/sbin/nologin
shutdown:x:6:0:shutdown:/sbin:/usr/sbin/nologin
halt:x:7:0:halt:/sbin:/usr/sbin/halt
```

**Vérification :**
- ✓ Tous ont `nologin` ou `halt` comme shell
- ✓ Pas de shell interactif

**Status :** ☐ ✓ | ☐ ✗

---

## 🔐 Test 4 : Hardening SSH

### Test 4.1 : Vérifier SSH sur port standard BLOQUÉ

```bash
# Commande (depuis machine externe)
ssh -p 22 admin@192.168.X.Y
```

**Résultat attendu :**
```
ssh: connect to host 192.168.X.Y port 22: Connection refused
```

**Vérification :**
- ✓ Port 22 fermé
- ✓ Connection refused (pas timeout)

**Status :** ☐ ✓ | ☐ ✗

---

### Test 4.2 : Vérifier SSH sur port sécurisé (2222) fonctionne

```bash
# Commande (depuis machine externe)
ssh -p 2222 -i /path/to/private/key admin@192.168.X.Y
```

**Résultat attendu :**
```
[admin@web-server ~]$
```

**Vérification :**
- ✓ Connexion réussie sur port 2222
- ✓ Login en tant qu'admin
- ✓ Prompt shell visible

**Status :** ☐ ✓ | ☐ ✗

---

### Test 4.3 : Vérifier configuration SSH correcte

```bash
# Commande
sudo grep -E "^Port|^PermitRootLogin|^PasswordAuthentication|^PubkeyAuthentication|^MaxAuthTries|^ClientAliveInterval" /etc/ssh/sshd_config
```

**Résultat attendu :**
```
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
```

**Vérification :**
- ✓ Port = 2222
- ✓ Root login = no
- ✓ Password auth = no
- ✓ Pubkey auth = yes
- ✓ Max auth tries = 3
- ✓ Client alive interval = 300s

**Status :** ☐ ✓ | ☐ ✗

---

### Test 4.4 : Vérifier SSH redémarré après config

```bash
# Commande
sudo systemctl status sshd
```

**Résultat attendu :**
```
● sshd.service - OpenSSH server daemon
     Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; vendor preset: enabled)
     Active: active (running) since [date/time]
```

**Vérification :**
- ✓ Service `sshd` actif (Active: active)
- ✓ Service enabled (démarre au boot)

**Status :** ☐ ✓ | ☐ ✗

---

### Test 4.5 : Vérifier clé SSH fonctionne

```bash
# Commande
ssh -p 2222 -i ~/.ssh/id_rsa admin@192.168.X.Y "whoami"
```

**Résultat attendu :**
```
admin
```

**Vérification :**
- ✓ Authentification par clé réussie
- ✓ Commande exécutée (whoami retourne admin)

**Status :** ☐ ✓ | ☐ ✗

---

## 🔥 Test 5 : Firewall (Firewalld)

### Test 5.1 : Vérifier firewalld actif

```bash
# Commande
sudo firewall-cmd --state
```

**Résultat attendu :**
```
running
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 5.2 : Vérifier firewalld activé au boot

```bash
# Commande
sudo systemctl is-enabled firewalld
```

**Résultat attendu :**
```
enabled
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 5.3 : Vérifier zone actuelle

```bash
# Commande
sudo firewall-cmd --get-active-zones
```

**Résultat attendu :**
```
public
  interfaces: eth0
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 5.4 : Vérifier ports autorisés

```bash
# Commande
sudo firewall-cmd --list-ports
```

**Résultat attendu :**
```
2222/tcp
```
(ou `2222/tcp 80/tcp 443/tcp` si serveur web)

**Vérification :**
- ✓ Port 2222/tcp présent
- ✓ Pas de port 22/tcp
- ✓ Seuls ports nécessaires visibles

**Status :** ☐ ✓ | ☐ ✗

---

### Test 5.5 : Vérifier services autorisés

```bash
# Commande
sudo firewall-cmd --list-services
```

**Résultat attendu :**
```
dhcpv6-client ssh
```

**Vérification :**
- ✓ Services minimaux

**Status :** ☐ ✓ | ☐ ✗

---

### Test 5.6 : Vérifier port 22 BLOQUÉ

```bash
# Commande (depuis machine externe)
nc -zv 192.168.X.Y 22
```

**Résultat attendu :**
```
192.168.X.Y 22 (ssh): *connection refused*
```

**Vérification :**
- ✓ Port 22 fermé
- ✓ Connection refused

**Status :** ☐ ✓ | ☐ ✗

---

### Test 5.7 : Vérifier port 2222 OUVERT

```bash
# Commande (depuis machine externe)
nc -zv 192.168.X.Y 2222
```

**Résultat attendu :**
```
192.168.X.Y 2222 (SSH): succeeded!
```

**Vérification :**
- ✓ Port 2222 ouvert
- ✓ Connexion réussie

**Status :** ☐ ✓ | ☐ ✗

---

## 🛡️ Test 6 : SELinux

### Test 6.1 : Vérifier mode SELinux

```bash
# Commande
getenforce
```

**Résultat attendu :**
```
Enforcing
```

**Vérification :**
- ✓ Mode = Enforcing (pas Permissive ou Disabled)

**Status :** ☐ ✓ | ☐ ✗

---

### Test 6.2 : Vérifier configuration SELinux

```bash
# Commande
cat /etc/selinux/config | grep "^SELINUX="
```

**Résultat attendu :**
```
SELINUX=enforcing
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 6.3 : Vérifier statut SELinux détaillé

```bash
# Commande
sudo sestatus -v | head -20
```

**Résultat attendu :**
```
SELinux status:                 enabled
Current mode:                   enforcing
Mode from config file:          enforcing
Policy version:                 33
Policy from config file:        targeted
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 6.4 : Vérifier violations SELinux

```bash
# Commande
sudo grep "denied" /var/log/audit/audit.log | wc -l
```

**Résultat attendu :**
```
0
```
(ou très peu, < 5)

**Vérification :**
- ✓ Pas de violations (ou très peu)
- ✓ Si violations, corrigées avec audit2allow

**Status :** ☐ ✓ | ☐ ✗

---

## ⛔ Test 7 : Protection Brute Force (Fail2ban)

### Test 7.1 : Vérifier fail2ban installé

```bash
# Commande
rpm -qa | grep fail2ban
```

**Résultat attendu :**
```
fail2ban-0.x.x-x.el8.noarch
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 7.2 : Vérifier fail2ban actif

```bash
# Commande
sudo systemctl status fail2ban
```

**Résultat attendu :**
```
● fail2ban.service - Fail2Ban Service
     Loaded: loaded (/usr/lib/systemd/system/fail2ban.service; enabled; vendor preset: disabled)
     Active: active (running) since [date/time]
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 7.3 : Vérifier jails activées

```bash
# Commande
sudo fail2ban-client status
```

**Résultat attendu :**
```
Status
|- Number of jail:  2
`- Jail list: sshd, httpd
```

**Vérification :**
- ✓ Au moins jail `sshd` présente
- ✓ Jail `httpd` si serveur web

**Status :** ☐ ✓ | ☐ ✗

---

### Test 7.4 : Vérifier configuration jail sshd

```bash
# Commande
sudo fail2ban-client status sshd
```

**Résultat attendu :**
```
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed: 0
|  `- File list: /var/log/secure
`- Actions
   |- Currently banned: 0
   |- Total banned: 0
   `- Banned IP list:
```

**Vérification :**
- ✓ Jail sshd active
- ✓ Monitore /var/log/secure

**Status :** ☐ ✓ | ☐ ✗

---

### Test 7.5 : Tester blocage fail2ban (OPTIONNEL - AVEC PRUDENCE)

```bash
# Commande (depuis machine attaquante, simula 6 tentatives SSH échouées)
for i in {1..6}; do ssh -p 2222 admin@192.168.X.Y 2>&1 | head -1; done
```

**Résultat attendu (après 5 tentatives) :**
```
Attempt 1-4: Permission denied (publickey)
Attempt 5: Connection refused (fail2ban bloque)
Attempt 6: Connection refused (IP bannée)
```

**Vérification :**
- ✓ Après 5 tentatives, IP bannée
- ✓ Connection refused

**Note :** Ce test vous bannit ! Utilisez une machine test.

**Status :** ☐ ✓ | ☐ ✗

---

### Test 7.6 : Vérifier configuration fail2ban maxretry et bantime

```bash
# Commande
sudo grep -E "^maxretry|^bantime|^findtime" /etc/fail2ban/jail.local
```

**Résultat attendu :**
```
bantime = 3600
findtime = 600
maxretry = 5
```

**Vérification :**
- ✓ `bantime` = 3600 ou plus (1h minimum)
- ✓ `findtime` = 600 (10 min fenêtre)
- ✓ `maxretry` = 5 ou moins

**Status :** ☐ ✓ | ☐ ✗

---

## 📋 Test 8 : Audit (Auditd)

### Test 8.1 : Vérifier auditd installé

```bash
# Commande
rpm -qa | grep audit
```

**Résultat attendu :**
```
audit-3.x.x-x.el8.x86_64
audit-libs-3.x.x-x.el8.x86_64
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 8.2 : Vérifier auditd actif

```bash
# Commande
sudo systemctl status auditd
```

**Résultat attendu :**
```
● auditd.service - Security Auditing Service
     Loaded: loaded (/usr/lib/systemd/system/auditd.service; enabled; vendor preset: enabled)
     Active: active (running) since [date/time]
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 8.3 : Vérifier règles audit SSH

```bash
# Commande
sudo auditctl -l | grep "ssh"
```

**Résultat attendu :**
```
-a always,exit -F dir=/var/log/secure -F perm=r -F auid>=1000 -F auid!=4294967295 -k ssh_access
```

**Vérification :**
- ✓ Règles SSH configurées
- ✓ Suivi du fichier `/var/log/secure`

**Status :** ☐ ✓ | ☐ ✗

---

### Test 8.4 : Vérifier règles audit sudo

```bash
# Commande
sudo auditctl -l | grep "sudo"
```

**Résultat attendu :**
```
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k sudo_actions
```

**Vérification :**
- ✓ Règles sudo configurées
- ✓ Suivi des exécutions sudo

**Status :** ☐ ✓ | ☐ ✗

---

### Test 8.5 : Vérifier logs audit collectés

```bash
# Commande
sudo tail -20 /var/log/audit/audit.log
```

**Résultat attendu :**
```
type=EXECVE msg=audit(...): argc=X a0=X a1=X...
type=CWD msg=audit(...): cwd="/"
type=PATH msg=audit(...): item=X name="..." inode=X dev=xx,xx mode=0xxx
type=PROCTITLE msg=audit(...): proctitle=...
```

**Vérification :**
- ✓ Logs audit présents
- ✓ Contiennent EXECVE, CWD, PATH, PROCTITLE
- ✓ Timestamp récent

**Status :** ☐ ✓ | ☐ ✗

---

### Test 8.6 : Vérifier audit status

```bash
# Commande
sudo auditctl -l
```

**Résultat attendu :**
```
No rules
```
(ou liste de règles si configurées avec /etc/audit/rules.d/)

**Status :** ☐ ✓ | ☐ ✗

---

## ✨ Test 9 : Validation avec Lynis

### Test 9.1 : Vérifier Lynis installé

```bash
# Commande
which lynis
```

**Résultat attendu :**
```
/usr/bin/lynis
```

**Status :** ☐ ✓ | ☐ ✗

---

### Test 9.2 : Exécuter audit Lynis complet

```bash
# Commande (prend ~2-3 minutes)
sudo lynis audit system
```

**Résultat attendu :**
```
[+] Tests completed
[!] Warnings
[+] Suggestions
[+] Manual remediation suggestions
...
Report details: /var/log/lynis-report-[hostname]-[date].dat
```

**Vérification :**
- ✓ Scan terminé sans erreur
- ✓ Rapport généré

**Status :** ☐ ✓ | ☐ ✗

---

### Test 9.3 : Vérifier score Lynis

```bash
# Commande
sudo grep "^hardening_index=" /var/log/lynis-report-*.dat | tail -1
```

**Résultat attendu :**
```
hardening_index=75
```
(objectif ≥ 70)

**Vérification :**
- ✓ Score ≥ 70/100
- ✓ Idéalement ≥ 80

**Status :** ☐ ✓ | ☐ ✗

---

### Test 9.4 : Afficher warnings Lynis

```bash
# Commande
sudo grep "^warning=" /var/log/lynis-report-*.dat | tail -1
```

**Résultat attendu :**
```
warning=0
```
(ou très peu)

**Vérification :**
- ✓ Zéro warning (idéal)
- ✓ Maximum 3-4 warnings acceptables

**Status :** ☐ ✓ | ☐ ✗

---

### Test 9.5 : Lire rapport Lynis

```bash
# Commande
sudo lynis show report /var/log/lynis-report-$(hostname)-*.dat
```

**Résultat attendu :**
```
Hardening index: 75
System hardened: Good
...
[Warnings and suggestions listed]
```

**Status :** ☐ ✓ | ☐ ✗

---

## 📊 Synthèse des Tests

| Section | Nb tests | ✓ PASS | ✗ FAIL | % Réussite |
|---------|----------|--------|--------|-----------|
| Test 1 : Installation | 3 | ☐ | ☐ | ___% |
| Test 2 : Réseau | 4 | ☐ | ☐ | ___% |
| Test 3 : Comptes & accès | 4 | ☐ | ☐ | ___% |
| Test 4 : SSH Hardening | 5 | ☐ | ☐ | ___% |
| Test 5 : Firewall | 7 | ☐ | ☐ | ___% |
| Test 6 : SELinux | 4 | ☐ | ☐ | ___% |
| Test 7 : Fail2ban | 6 | ☐ | ☐ | ___% |
| Test 8 : Auditd | 6 | ☐ | ☐ | ___% |
| Test 9 : Lynis | 5 | ☐ | ☐ | ___% |
| **TOTAL** | **44** | **☐** | **☐** | **___%** |

---

## 🎯 Résultats Globaux

**Tests réussis :** ___/44  
**Tests échoués :** ___/44  
**Taux de réussite :** ___%

**Critère de validation :** ≥ 42/44 (95% minimum) ou tous tests critiques ✓

**Évaluation finale :**
- ☐ VALIDÉ (tous critiques réussis)
- ☐ À REPRENDRE (corriger les ✗)

---

## 🔍 Logs de Débogage

### En cas d'échec d'un test, collecter les logs :

```bash
# SSH - Vérifier logs
sudo tail -50 /var/log/secure

# Firewall - Vérifier règles
sudo firewall-cmd --list-all
sudo firewall-cmd --list-rich-rules

# SELinux - Vérifier denials
sudo grep "denied" /var/log/audit/audit.log | tail -10

# Fail2ban - Vérifier bannissements
sudo tail -50 /var/log/fail2ban.log

# Auditd - Vérifier configuration
sudo auditctl -l

# Lynis - Vérifier rapport complet
sudo lynis show report /var/log/lynis-report-*.dat
```

---

## 📝 Notes Personnelles

```
Test échoué ? Notons ici :

Test : _________________________________
Résultat : _________________________________
Cause probable : _________________________________
Solution appliquée : _________________________________
Résultat après correction : _________________________________

---

Test : _________________________________
Résultat : _________________________________
Cause probable : _________________________________
Solution appliquée : _________________________________
Résultat après correction : _________________________________
```

---

## ✅ Validation Finale

**Date de fin des tests :** ___/___/___  
**Tous les tests ✓ ?** ☐ Oui | ☐ Non  
**Prêt à passer au Rôle 2 (SOC/Logs) ?** ☐ Oui | ☐ Non  

**Signature responsable :** ________________________

---

**Version :** 1.0  
**Dernière mise à jour :** 06/02/2025  
**Auteur :** Tom (Étudiant 2e année SysAdmin)
