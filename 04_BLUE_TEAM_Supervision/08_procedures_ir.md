# 08. Procédures d'Incident Response (IR)

**Objectif** : Définir des procédures claires pour réagir à chaque type d'attaque.

**Durée estimée** : 1h  
**Niveau** : Avancé  
**Prérequis** : Comprendre les 5 attaques du projet

---

## 1. Principes d'une bonne procédure IR

### Structure basique

Une procédure IR doit suivre ce modèle :

```
1. DÉTECTION
   └ Symptômes à observer
   └ Logs à vérifier

2. ANALYSE
   └ Commandes de diagnostic
   └ Questions à se poser

3. CONTENTION
   └ Actions pour arrêter l'attaque
   └ Éviter la propagation

4. REMÉDIATION
   └ Restaurer le système
   └ Prévenir la récurrence

5. POST-INCIDENT
   └ Documentation
   └ Leçons apprises
```

### Rôles dans chaque phase

| Phase | Rôle | Action |
|-------|------|--------|
| Détection | SOC Analyst | Identifier l'alerte |
| Analyse | Incident Commander | Confirmer la compromission |
| Contention | Sysadmin | Bloquer l'attaquant |
| Remédiation | Sysadmin | Nettoyer le système |
| Post | Manager | Documenter |

---

## 2. PROCÉDURE #1 : Brute force SSH

### 2.1 Détection

**Alert Grafana/Wazuh**:
```
⚠️ Tentatives SSH multiples
- Sévérité : HIGH
- Source : IP externe
- Cible : port SSH non-standard
```

**Symptômes** :
- Logs `auth` remplis de "Failed password"
- File `/var/log/secure` grandit rapidement
- Fail2ban bloque des IPs

### 2.2 Vérifier l'attaque

**Étape 1** : Accéder au serveur SSH-hardened

```bash
ssh -p 2222 admin@192.168.1.100  # Port personnalisé !
```

**Étape 2** : Vérifier les logs SSH

```bash
# Voir les tentatives en temps réel
tail -f /var/log/secure | grep "Failed password"

# Compter par IP source
grep "Failed password" /var/log/secure | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
```

**Résultat attendu** :
```
   50 192.168.1.50      ← L'attaquant !
   30 192.168.1.51
    5 192.168.1.100
```

**Étape 3** : Vérifier l'état de Fail2ban

```bash
sudo fail2ban-client status sshd
```

Résultat :
```
Status for the jail sshd:
  Currently failed:  15
  Total banned:      2
  IP list:           192.168.1.50 192.168.1.51
```

### 2.3 Contention (arrêter l'attaque)

**Option 1** : Fail2ban a déjà bloqué (observé mais pas d'action)

```bash
# Vérifier la règle Fail2ban
cat /etc/fail2ban/jail.local | grep -A5 "\[sshd\]"
```

Résultat idéal :
```
[sshd]
enabled = true
maxretry = 5        # Bloquer après 5 essais
findtime = 600      # Dans 10 minutes
bantime = 3600      # Bannir 1 heure
```

**Option 2** : Bloquer manuellement au firewall

```bash
# Voir les IPs actuellement bloquées
sudo firewall-cmd --zone=drop --list-all

# Ajouter une IP à la zone drop (bloquée)
sudo firewall-cmd --permanent --zone=drop --add-source=192.168.1.50/32
sudo firewall-cmd --reload

# Vérifier
sudo firewall-cmd --zone=drop --list-sources
```

### 2.4 Analyse approfondie

**Vérifier s'il y a eu compromise** :

```bash
# Vérifier les connexions réussies
grep "Accepted password" /var/log/secure | tail -20

# Vérifier les derniers logins (w)
w

# Vérifier les logs d'accès sudoers
sudo grep "COMMAND" /var/log/auth.log | tail -20
```

**Si pas de Accepted password** → Attaque échouée, tant mieux.

**Si Accepted password** → CRITIQUE, procéder en 2.5.

### 2.5 Remédiation (nettoyer)

**Si attaque réussie** :

```bash
# 1. Changer tous les mots de passe
passwd admin
# Faire pour chaque compte utilisateur

# 2. Vérifier les clés SSH non autorisées
cat ~/.ssh/authorized_keys

# 3. Vérifier la présence de backdoors

# Cron jobs
crontab -l

# Clés SSH système
ls -la /home/*/.ssh/authorized_keys2

# 4. Vérifier les comptes actifs
cat /etc/passwd | grep "/bin/bash"

# 5. Mettre à jour les règles SSH
sudo nano /etc/ssh/sshd_config
# Vérifier :
# PermitRootLogin no
# PasswordAuthentication no
# MaxAuthTries 3

# 6. Redémarrer SSH
sudo systemctl restart sshd
```

### 2.6 Documentation

Créer un rapport `incident_20250206_brute_force.txt` :

```
INCIDENT REPORT
===============
Date : 2025-02-06
Type : SSH Brute Force
Severity : HIGH
Status : RESOLVED

TIMELINE:
14:30 - Alerte SSH brute force (Grafana)
14:32 - Analyst vérifies les logs
14:35 - 192.168.1.50 identifiée comme attaquant
14:37 - IP bloquée via firewall
14:45 - Logs vérifiés, pas de connexion réussie
15:00 - Incident clôturé

FINDINGS:
- Attaque : 200+ tentatives en 30 minutes
- Source : 192.168.1.50 (Kali Linux sur le réseau de labo)
- Résultat : BLOQUÉE par Fail2ban/Firewall
- Compromission : NON détectée

PREVENTIONS FUTURES:
- Fail2ban actif ✓
- Clé SSH obligatoire ✓
- Port SSH non-standard ✓
- SELinux actif ✓
```

---

## 3. PROCÉDURE #2 : Upload fichier malveillant

### 3.1 Détection

**Alert Grafana/Wazuh** :
```
📄 Fichier suspect uploadé
- Sévérité : CRITICAL
- Type : executable / script
- Chemin : /var/www/uploads/
```

### 3.2 Vérifier l'attaque

**Étape 1** : Lister les fichiers suspects

```bash
# Fichiers récemment modifiés
find /var/www/uploads -type f -mtime -1 -ls

# Fichiers exécutables (danger!)
find /var/www/uploads -type f -executable

# Fichiers archives
find /var/www/uploads -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.gz" \)
```

**Étape 2** : Analyser le fichier

```bash
# Voir le type de fichier
file /var/www/uploads/suspicious_file

# Vérifier le hash (pour le signaler)
sha256sum /var/www/uploads/suspicious_file

# Scanner antivirus (si installé)
clamav /var/www/uploads/suspicious_file
```

### 3.3 Contention

**Étape 1** : Isoler le fichier

```bash
# Déplacer vers une zone de quarantaine
sudo mkdir -p /quarantine
sudo mv /var/www/uploads/suspicious_file /quarantine/
sudo chmod 000 /quarantine/suspicious_file  # Lecture impossible
```

**Étape 2** : Vérifier d'où il vient

```bash
# Logs Nginx/Apache
tail -100 /var/log/nginx/access.log | grep "upload"

# Résultat :
# 192.168.1.50 POST /upload 200 - "Mozilla/5.0 (X11; Linux)"
```

### 3.4 Remédiation

**Étape 1** : Nettoyer le webserver

```bash
# Vérifier que le processus nginx n'a pas exécuté le malware
ps aux | grep -E "nginx|apache|php"

# Si process suspect, le tuer
sudo kill -9 <PID>
sudo systemctl restart nginx
```

**Étape 2** : Renforcer la sécurité upload

Éditer `/etc/nginx/conf.d/upload-security.conf` :

```nginx
# Limiter la taille des uploads
client_max_body_size 10M;

# Accepter seulement certains types
location /upload {
    # Bloquer les fichiers exécutables
    if ($request_filename ~* \.(php|php3|php4|php5|php7|phtml|pl|py|jsp|asp|sh|cgi)$) {
        return 403;
    }
    
    # Limiter les uploads à images
    types {
        image/jpeg jpg jpeg;
        image/png png;
        image/gif gif;
    }
}
```

**Étape 3** : Scanner les fichiers uploads existants

```bash
# Chercher les scripts exécutables
find /var/www/uploads -type f \( -executable -o -name "*.php" -o -name "*.sh" \)

# Chercher les archives
find /var/www/uploads -type f \( -name "*.zip" -o -name "*.tar*" \)
```

### 3.5 Documentation

```
INCIDENT REPORT
===============
Date : 2025-02-06 15:30
Type : Malicious File Upload
Severity : CRITICAL
Status : RESOLVED

FINDINGS:
- Fichier : malware.php (uploaded vers /uploads)
- Source IP : 192.168.1.50
- SHA256 : a1b2c3d4e5f6...
- Contenu : Webshell PHP
- Exécution : NON (bloquée par upload rules)

RESPONSE:
- Fichier mouvé en quarantaine
- Upload rules renforcées
- Nginx restarté
- Logs archivés pour analyse

PREVENTIONS:
- Upload validation ✓
- Type whitelist ✓
- Script execution disabled ✓
```

---

## 4. PROCÉDURE #3 : Scan réseau (Nmap)

### 4.1 Détection

**Alert** :
```
🔍 Scan réseau massif détecté
- Sévérité : HIGH
- Ports scannés : 200+
- Protocole : TCP SYN
```

### 4.2 Vérifier l'attaque

**Étape 1** : Vérifier les logs firewall

```bash
# Rocky Linux utilise firewalld
sudo journalctl -u firewalld | tail -50

# Ou les logs iptables
sudo iptables -L -v -n
```

**Étape 2** : Analyser les connexions réseau

```bash
# Ports avec nombreuses tentatives de connexion
netstat -tuln | grep ESTABLISHED,SYN_RECV

# Ou avec ss (outil moderne)
ss -tuln | grep -E "SYN|ESTABLISHED"

# Connexions non établies (scan!)
ss -tuln | grep SYN_RECV
```

**Étape 3** : Identifier l'attaquant

```bash
# Logs Wazuh/Fail2ban
grep "scan" /var/ossec/logs/alerts/alerts.json

# Ou simpler, vérifier les sources actives
sudo tcpdump -i eth0 "tcp[tcpflags] & tcp-syn != 0" -c 20

# Résultat :
# SYN from 192.168.1.50:12345 to our ports
```

### 4.3 Contention

**Étape 1** : Bloquer l'attaquant

```bash
# Au firewall
sudo firewall-cmd --permanent --zone=drop --add-source=192.168.1.50/32
sudo firewall-cmd --reload

# Ou avec iptables directement
sudo iptables -I INPUT 1 -s 192.168.1.50 -j DROP
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**Étape 2** : Fermer les ports inutiles

```bash
# Lister les ports ouverts
sudo firewall-cmd --list-ports

# Fermer un port
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd --reload

# Limiter SSH à une seule IP
sudo firewall-cmd --permanent --zone=internal --add-source=192.168.1.100/32
sudo firewall-cmd --permanent --zone=internal --add-service=ssh
```

### 4.4 Remédiation

**Étape 1** : Hardening firewall

```bash
# Activer le rate limiting
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 port protocol=tcp port=22 limit value=5/m accept'
sudo firewall-cmd --reload
```

**Étape 2** : Voir les règles appliquées

```bash
sudo firewall-cmd --zone=public --list-all
```

---

## 5. PROCÉDURE #4 : Élévation de privilèges

### 5.1 Détection

**Alert** :
```
⬆️ Tentative d'escalade de privilèges
- Sévérité : CRITICAL
- User : www-data
- Command : sudo /bin/bash
```

### 5.2 Vérifier l'attaque

**Étape 1** : Vérifier les logs sudo

```bash
# Tentatives sudo
sudo journalctl -u sudo -n 100

# Ou directement
sudo grep "sudo" /var/log/secure

# Résultat :
# "www-data : user NOT in sudoers ; TTY=pts/0 ; PWD=/var/www ; USER=root"
```

**Étape 2** : Analyser si l'escalade a réussi

```bash
# Vérifier les comptes actifs
cat /etc/shadow | grep -v ":" | head

# Vérifier les groupes critiques
groups www-data

# Vérifier les sudo rules
sudo visudo -c  # Vérifier la syntaxe
sudo cat /etc/sudoers
sudo ls -la /etc/sudoers.d/
```

**Étape 3** : Vérifier si root a été obtenu

```bash
# Processus lancés par root
ps aux | grep www-data

# Si processus root = CRITIQUE

# Vérifier les cron jobs root
sudo crontab -l

# Vérifier les fichiers modifiés récemment par root
find /root -type f -mtime -1
```

### 5.3 Contention

**Si pas de compromise détectée** :
```bash
# Tout va bien, documenter et continuer
```

**Si compromise détectée** :

```bash
# 1. Arrêter le service compromis
sudo systemctl stop nginx

# 2. Isoler le compte
sudo usermod -L www-data  # Lock le compte
sudo usermod -s /usr/sbin/nologin www-data  # Shell interdit

# 3. Tuer les processus actifs
sudo pkill -u www-data

# 4. Vérifier les fichiers modifiés
find /var/www -type f -mtime -1 -ls
```

### 5.4 Remédiation

**Étape 1** : Renforcer les permissions

```bash
# Vérifier les permissions sensibles
ls -la /etc/sudoers*

# Vérifier que root est en charge
sudo lsattr -d /etc/sudoers

# Mettre en immutable
sudo chattr +i /etc/sudoers
```

**Étape 2** : Audit SELinux

```bash
# Vérifier les violations
sudo ausearch -k pam_unix

# Ou
sudo grep "avc" /var/log/audit/audit.log | tail -20
```

---

## 6. PROCÉDURE #5 : Connexion hors horaires

### 6.1 Détection

**Alert** :
```
🌙 Connexion hors horaires
- Sévérité : MEDIUM
- User : admin
- Time : 02:30 (la nuit!)
- Source : 192.168.1.50
```

### 6.2 Vérifier l'attaque

**Étape 1** : Vérifier les logs de connexion

```bash
# Dernières connexions
lastlog

# Logs SSH
grep "Accepted" /var/log/secure | tail -10

# Filtrer par user
lastlog -u admin
```

**Étape 2** : Analyser le contexte

```bash
# Qui s'est connecté de cette IP ?
grep "192.168.1.50" /var/log/secure

# À quelle heure ?
grep "02:30" /var/log/secure
```

### 6.3 Contention

```bash
# Si c'est un vrai utilisateur (maintenance prévue) :
# → Tout va bien

# Si c'est suspect :
# → Utiliser la procédure SSH brute force (2.5)
```

### 6.4 Remédiation

**Mettre en place des restrictions horaires** :

Éditer `/etc/pam.d/common-auth-pc` :

```
# Restreindre les connexions en dehors des heures de bureau
account required pam_time.so
```

Éditer `/etc/security/time.conf` :

```
# user;tty;rhost;service;ttimes;[nonexistent_user]
admin;*;*;sshd;!Mo0000-Fr2359
# Signifie : admin ne peut se connecter SSH que lundi 00:00 à vendredi 23:59
```

---

## 7. Modèle générique pour toute procédure

```markdown
## PROCÉDURE : [NOM ATTAQUE]

### DÉTECTION
- Alertes à chercher : 
- Logs à vérifier :

### ANALYSE
- Commandes de diagnostic :
- Questions de validation :

### CONTENTION (Arrêter)
- Actions immédiates :
- Durée : 

### REMÉDIATION (Nettoyer)
- Étapes de nettoyage :
- Vérifications :

### POST-INCIDENT
- Rapport :
- Leçons apprises :
```

---

## 8. Checklist générale IR

- [ ] Alertes configurées pour les 5 attaques
- [ ] Procédure #1 (Brute force) testée
- [ ] Procédure #2 (Upload) testée
- [ ] Procédure #3 (Scan) testée
- [ ] Procédure #4 (Escalade) testée
- [ ] Procédure #5 (Hors horaires) testée
- [ ] Équipe formée aux 5 procédures
- [ ] Rapports d'incidents archivés
- [ ] Playbooks Ansible créés (étape 09)
- [ ] Scripts automatisés créés (étape 10)

---

## 9. Résumé des 5 procédures

| Attaque | Détection | Contention | Remédiation |
|---------|-----------|-----------|------------|
| Brute force SSH | Logs "Failed pass" | Fail2ban bloque | Changer mdp |
| Upload malware | Fichier suspect | Quarantine | Upload rules |
| Scan réseau | SYN flood | Bloquer IP | Firewall rules |
| Escalade | Sudo violation | Tuer process | Audit perms |
| Hors horaires | Login nuit | Vérifier | Time restrictions |

Une procédure claire = une réaction rapide et efficace !
