# 09 - Auditd : Système d'audit du noyau

## 🎯 Objectif
Installer et configurer **auditd** pour enregistrer et surveiller les activités sensibles au niveau du noyau.

Auditd est le système de logging le plus bas niveau Linux. Il enregistre TOUT (fichiers modifiés, commandes exécutées, accès réseau, appels système).

**Durée estimée :** 1h30

---

## 📚 Concepts importants

### Auditd vs les logs classiques

| Aspect | Logs classiques | Auditd |
|--------|-----------------|--------|
| **Niveau** | Application | Noyau Linux |
| **Complétude** | Partiel | Exhaustif |
| **Manipulable** | Oui (par root) | Non (même root ne peut pas l'effacer) |
| **Performance** | Normal | Léger surcoût |
| **Forensique** | Moyen | Excellent |

### Cas d'usage d'auditd

1. **Qui a accédé à ce fichier ?** → Auditd le sait
2. **Quelles commandes sudo ont été exécutées ?** → Historique complet
3. **Un attaquant a supprimé les logs SSH** → Auditd enregistre l'effacement
4. **Qui a modifié /etc/passwd ?** → Auditd a la preuve

### Architecture auditd

```
Événement système (ex: accès fichier)
        ↓
Noyau Linux (audit subsystem)
        ↓
Auditd daemon
        ↓
Règles (audit.rules) → Correspond-elle ?
        ↓
Enregistrement dans /var/log/audit/audit.log
```

---

## ⚙️ Étape 1 : Installation

### Installer auditd
```bash
sudo dnf install audit audit-libs -y
```

**Output attendu :**
```
Last metadata expiration check: 0:00:01 ago on Wed Nov 15 11:00:00 2024.
Dependencies resolved.
================================================================================
 Package         Arch          Version           Repository          Size
================================================================================
Installing:
 audit           x86_64        3.0.7-5.el9       baseos           213 kB
 audit-libs      x86_64        3.0.7-5.el9       baseos            68 kB

Installed:
  audit-3.0.7-5.el9.x86_64  audit-libs-3.0.7-5.el9.x86_64
```

### Vérifier l'installation
```bash
auditctl -v
```

**Output attendu :**
```
auditctl v3.0.7
```

---

## ⚙️ Étape 2 : Configurer les règles d'audit

### Localiser le fichier de règles
```bash
ls -la /etc/audit/
```

**Output attendu :**
```
total 64
drwxr-xr-x.  3 root root   4096 Nov 15 10:30 .
drwxr-xr-x. 17 root root   4096 Nov 15 10:00 ..
-rw-------.  1 root root    456 Nov 15 10:30 audit.rules
-rw-------.  1 root root   1223 Jul 10 10:00 rules.d (directory)
```

### Éditer les règles d'audit
```bash
sudo nano /etc/audit/rules.d/audit.rules
```

**Remplace le contenu par :**

```bash
# Effacer toutes les règles existantes
-D

# Buffer Size
-b 8192

# Nombre de défaillances avant arrêt
-f 2

# Supprimer les messages de fin de lecture du disque
-a never,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a never,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change

# === RÈGLES DE SURVEILLANCE ===

# 1. Surveiller les modifications système (/etc, /sbin, /usr/bin)
-w /etc/audit/ -p wa -k audit-config-changes
-w /etc/selinux/ -p wa -k selinux-config-changes
-w /etc/apparmor/ -p wa -k apparmor-config-changes
-w /etc/libaudit.conf -p wa -k audit-config-changes

# 2. Surveiller les changements de permissions et d'ownership
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=-1 -k perm-mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=-1 -k perm-mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=-1 -k perm-mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=-1 -k perm-mod

# 3. Surveiller les tentatives d'accès non autorisé
-a always,exit -F arch=b64 -S open -S openat -F exit=-EACCES -F auid>=1000 -F auid!=-1 -k access
-a always,exit -F arch=b32 -S open -S openat -F exit=-EACCES -F auid>=1000 -F auid!=-1 -k access
-a always,exit -F arch=b64 -S open -S openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -k access
-a always,exit -F arch=b32 -S open -S openat -F exit=-EPERM -F auid>=1000 -F auid!=-1 -k access

# 4. Surveiller les modifications de fichiers de montage
-a always,exit -F arch=b64 -S mount -S umount2 -F auid>=1000 -F auid!=-1 -k mounts
-a always,exit -F arch=b32 -S mount -S umount2 -F auid>=1000 -F auid!=-1 -k mounts

# 5. Surveiller les suppressions de fichiers
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -k delete

# 6. Surveiller les modifications du sudo
-w /etc/sudoers -p wa -k sudo-changes
-w /etc/sudoers.d/ -p wa -k sudo-changes

# 7. Surveiller les appels sudo
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=-1 -k sudo-usage

# 8. Surveiller les modifications des comptes
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# 9. Surveiller les sessions de connexion
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins
-w /var/log/lastlog -p wa -k logins

# 10. Surveiller les changements réseau
-a always,exit -F arch=b64 -S sethostname -S setdomainname -F auid>=1000 -F auid!=-1 -k network_modifications
-a always,exit -F arch=b32 -S sethostname -S setdomainname -F auid>=1000 -F auid!=-1 -k network_modifications

# 11. Surveillance des appels système dangereux (privilege escalation)
-a always,exit -F arch=b64 -S execve -F uid=0 -k exec
-a always,exit -F arch=b32 -S execve -F uid=0 -k exec

# Make configuration immutable
-e 2
```

### Explication des paramètres

```bash
-D              # Effacer les règles précédentes
-b 8192         # Taille du buffer audit (nombre d'événements)
-f 2            # Mode de défaillance (2 = continuer)
-w /chemin      # Surveiller un fichier ou répertoire
-p wa           # Permissions : w=write, a=attribute
-S syscall      # Appel système à surveiller
-F              # Filtre (auid=user ID, arch=architecture)
-k clé          # Clé pour identifier la règle
-e 2            # Rendre immutable (on ne peut pas modifier sans redémarrer)
```

**Exemple décodé :**
```bash
-w /etc/passwd -p wa -k identity
# Surveille (/w) le fichier /etc/passwd pour les modifications (w) et changes d'attributs (a)
# Les logs seront taggés avec la clé "identity"
```

Sauvegarde : `Ctrl+O`, puis `Ctrl+X`.

---

## ⚙️ Étape 3 : Charger les règles et démarrer auditd

### Charger les nouvelles règles
```bash
sudo auditctl -R /etc/audit/rules.d/audit.rules
```

**Output attendu :**
```
Loading rules from /etc/audit/rules.d/audit.rules
```

### Vérifier que les règles sont chargées
```bash
sudo auditctl -l
```

**Output attendu (extrait) :**
```
-D
-b 8192
-f 2
-w /etc/audit/ -p wa -k audit-config-changes
-w /etc/selinux/ -p wa -k selinux-config-changes
-w /etc/apparmor/ -p wa -k apparmor-config-changes
...
-e 2
```

Le nombre de règles dépend de ta configuration (30-50 typiquement).

### Démarrer auditd
```bash
sudo systemctl start auditd
```

### Activer au démarrage
```bash
sudo systemctl enable auditd
```

### Vérifier le statut
```bash
sudo systemctl status auditd
```

**Output attendu :**
```
● auditd.service - Security Auditing Service
   Loaded: loaded (/usr/lib/systemd/system/auditd.service; enabled)
   Active: active (running) since Wed Nov 15 11:15:00 2024; 2s ago
   Main PID: 6543 (auditd)
```

---

## 🔍 Étape 4 : Consulter les logs d'audit

### Fichier de logs
```bash
ls -la /var/log/audit/
```

**Output attendu :**
```
total 512
drwx------.  2 root root   4096 Nov 15 11:20 .
drwxr-xr-x. 13 root root   4096 Nov 15 11:00 ..
-rw-------.  1 root root 450000 Nov 15 11:25 audit.log
```

Les logs sont lisibles seulement par root (sécurisé).

### Voir les logs bruts
```bash
sudo tail -20 /var/log/audit/audit.log
```

**Exemple de sortie :**
```
type=PROCTITLE msg=audit(1699971345.123:456): proctitle=sudo
type=SYSCALL msg=audit(1699971345.123:456): arch=c000003e syscall=59 success=yes exit=0 a0=0 a1=0 a2=0 a3=0 items=2 ppid=1234 pid=5678 auid=1000 uid=0 gid=0 euid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=1 comm="sudo" exe="/usr/bin/sudo" key="sudo-usage"
type=EXECVE msg=audit(1699971345.123:456): argc=3 a0="/usr/bin/sudo" a1="-u" a2="root"
type=CWD msg=audit(1699971345.123:456): cwd="/home/user"
type=PATH msg=audit(1699971345.123:456): item=0 name="/usr/bin/sudo" inode=12345 dev=10:00 mode=0104755 ouid=0 ogid=0 rdev=00:00
```

**C'est dur à lire... utilisons un outil !**

### Voir les logs en format humain
```bash
sudo ausearch -k sudo-usage
```

**Output attendu (plus lisible) :**
```
----
time->Wed Nov 15 11:25:30 2024
type=SYSCALL msg=audit(1699971345.123:456): arch=c000003e syscall=execve success=yes exit=0 a0=7fff70a68e70 a1=7fff70a68550 a2=7fff70a68560 a3=0 items=2 ppid=1234 pid=5678 auid=1000 uid=0 gid=0 euid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=1 comm="sudo" exe="/usr/bin/sudo" subj=unconfined_u:unconfined_r:sudo_t:s0-s0:c0.c1023 key="sudo-usage"
type=EXECVE msg=audit(1699971345.123:456): argc=3 a0="/usr/bin/sudo" a1="-u" a2="root"
```

### Rechercher par clé de règle
```bash
sudo ausearch -k identity
```

**Trouve tous les accès à passwd/shadow/group.**

```bash
sudo ausearch -k delete
```

**Trouve tous les fichiers supprimés.**

```bash
sudo ausearch -k sudo-usage -ts today
```

**Affiche les sudo d'aujourd'hui.**

---

## 🧪 Étape 5 : Tester les règles d'audit

### Test 1 : Modifier /etc/passwd
```bash
# D'abord, regarde l'état actuel
sudo tail -1 /var/log/audit/audit.log

# Maintenant, modifie un fichier surveillé
sudo echo "# test" >> /etc/sudoers.d/test

# Vérifier que c'a été enregistré
sudo ausearch -k sudo-changes
```

**Output attendu :**
```
----
time->Wed Nov 15 11:30:45 2024
type=CONFIG_CHANGE msg=audit(1699971445.456:789): audit_enabled=1 res=success
----
time->Wed Nov 15 11:30:50 2024
type=PATH msg=audit(1699971450.789:123): item=0 name="/etc/sudoers.d/test" inode=99999 dev=10:00 mode=0100644 ouid=0 ogid=0 rdev=00:00 nametype=CREATE
```

### Test 2 : Exécuter sudo
```bash
# Exécute sudo
sudo whoami

# Cherche dans les logs
sudo ausearch -k sudo-usage
```

**Output attendu :**
```
time->Wed Nov 15 11:31:15 2024
type=SYSCALL msg=audit(...): syscall=execve success=yes ... comm="sudo" exe="/usr/bin/sudo" key="sudo-usage"
type=EXECVE msg=audit(...): argc=2 a0="/usr/bin/sudo" a1="whoami"
```

### Test 3 : Supprimer un fichier
```bash
# Crée et supprime un fichier
touch /tmp/test-audit.txt
rm /tmp/test-audit.txt

# Cherche dans les logs
sudo ausearch -k delete | tail -20
```

**Output attendu :**
```
type=SYSCALL msg=audit(...): syscall=unlink success=yes ... key="delete"
type=PATH msg=audit(...): name="/tmp/test-audit.txt" nametype=DELETE
```

---

## 📊 Commandes utiles pour l'analyse

### Voir tous les événements aujourd'hui
```bash
sudo ausearch -ts today
```

### Voir les erreurs d'accès
```bash
sudo ausearch -k access
```

### Voir les changements de permissions
```bash
sudo ausearch -k perm-mod
```

### Voir qui a accédé à /etc/passwd
```bash
sudo ausearch -f /etc/passwd
```

### Voir les événements d'une heure spécifique
```bash
sudo ausearch -ts 11:00:00 -te 12:00:00
```

### Exporter les logs en format CSV
```bash
sudo ausearch -k sudo-usage -format text | ausearch -format csv > /tmp/audit.csv
```

### Générer un rapport d'audit
```bash
sudo aureport
```

**Output attendu :**
```
Summary Report
======================
Range of time in logs: 11/15/2024 11:15:30.123 - 11/15/2024 11:35:45.678
Selected time for report: 11/15/2024 11:15:30 - 11/15/2024 11:35:45
Number of changes in configuration: 5
Number of failed logins: 0
Number of successful logins: 3
Number of failed syscalls: 2
Number of anomalies: 0
Number of responses to anomalies: 0
Number of crypto events: 0
Number of keys: 8
```

---

## ⚙️ Configuration avancée

### Augmenter la taille du buffer (pour plus d'événements)
```bash
sudo nano /etc/audit/rules.d/audit.rules
```

Change :
```bash
-b 8192
```

En :
```bash
-b 16384
```

Puis recharge :
```bash
sudo auditctl -R /etc/audit/rules.d/audit.rules
sudo systemctl restart auditd
```

### Surveiller un répertoire spécifique
```bash
sudo auditctl -w /opt/app/ -p wa -k app-changes
```

Rendre permanent dans `/etc/audit/rules.d/audit.rules`.

### Ajouter une règle d'appel système personnalisée
```bash
# Surveiller les ouvertures de fichiers en écriture
sudo auditctl -a always,exit -F arch=b64 -S open -F flags=O_WRONLY -k file-write-attempts
```

---

## ✅ Vérification finale

### Checklist

- [ ] Auditd est installé (`auditctl -v`)
- [ ] Le service est actif (`systemctl status auditd`)
- [ ] Les règles sont chargées (`auditctl -l` affiche 30+ règles)
- [ ] Le fichier `/var/log/audit/audit.log` existe
- [ ] Les tests génèrent des logs (`ausearch` trouve des événements)
- [ ] La clé `-e 2` rend les règles immutables
- [ ] Les permissions sont restrictives (`-rw-------` pour audit.log)

### Test final complet
```bash
# 1. Vérifier le status
sudo systemctl status auditd | grep Active

# 2. Compter les règles
sudo auditctl -l | wc -l

# 3. Vérifier la taille du log
sudo ls -lh /var/log/audit/audit.log

# 4. Faire un test simple
touch /tmp/test.txt
sudo ausearch -f /tmp/test.txt

# 5. Générer un rapport
sudo aureport -t file-events
```

---

## 🆘 Troubleshooting courant

### Problème 1 : Auditd refuse de démarrer

**Symptôme :**
```
systemctl start auditd
Job for auditd.service failed
```

**Cause probable :** Erreur de syntaxe dans les règles.

**Solution :**
```bash
# Vérifier la syntaxe
sudo auditctl -l 2>&1

# Réinitialiser les règles
sudo auditctl -D
sudo systemctl restart auditd
```

### Problème 2 : Les règles ne se chargent pas au boot

**Cause :** Le fichier `/etc/audit/rules.d/audit.rules` ne doit pas avoir `-e 2` à la fin (sinon immutable).

**Solution :**
```bash
# Vérifier la dernière ligne
sudo tail -1 /etc/audit/rules.d/audit.rules

# Elle doit être : -e 2
```

### Problème 3 : Le fichier audit.log devient énorme

**Cause :** Trop d'événements enregistrés.

**Solution :**
```bash
# Archiver les logs
sudo mv /var/log/audit/audit.log /var/log/audit/audit.log.$(date +%Y%m%d)
sudo systemctl restart auditd

# Ou réduire les règles
sudo nano /etc/audit/rules.d/audit.rules
# Commente les règles moins importantes
```

---

## 📋 Résumé des commandes clés

```bash
# Installation
sudo dnf install audit audit-libs -y

# Configuration
sudo nano /etc/audit/rules.d/audit.rules
sudo auditctl -R /etc/audit/rules.d/audit.rules

# Service
sudo systemctl start auditd
sudo systemctl enable auditd
sudo systemctl restart auditd

# Voir les règles
sudo auditctl -l

# Consulter les logs
sudo tail -20 /var/log/audit/audit.log
sudo ausearch -k clé
sudo ausearch -ts today
sudo aureport

# Gestion des règles
sudo auditctl -w /chemin -p wa -k clé
sudo auditctl -a always,exit -F syscall=open -k clé
```

---

## 🎓 Points clés à retenir

1. **Auditd = logging au niveau noyau** : Pas contournable, même par root.
2. **Immutable avec `-e 2`** : Les règles ne peuvent pas être modifiées sans redémarrage.
3. **Clés importantes** : identity, sudo-usage, delete, perm-mod pour la sécurité.
4. **Recherche avec `ausearch`** : Plus lisible que les logs bruts.
5. **Archive régulièrement** : Le fichier audit.log peut devenir très volumineux.

---

## 📚 Ressources

- Manuel : `man auditctl`, `man ausearch`, `man aureport`
- Configuration : `/etc/audit/audit.rules`, `/etc/audit/rules.d/`
- Logs : `/var/log/audit/audit.log`

