# TESTS DE VÉRIFICATION - Blue Team SOC

**Objectif** : Valider que chaque règle de détection fonctionne correctement  
**Durée estimée** : 2-3h (30-40 min par test)  
**Prérequis** : Wazuh Manager + Agents en place, accès à l'interface Web

---

## AVANT DE COMMENCER

### Préparation

```bash
# 1. Accéder à l'interface Wazuh
# URL: https://<IP_SOC>:443
# Identifiant: admin / [votre_password]

# 2. Ouvrir deux terminaux SSH:
#    - Terminal 1 : VM1 (Serveur Web) pour générer des attaques
#    - Terminal 2 : VM3 (Monitoring) pour tests supplémentaires

# 3. Avant chaque test, vider le filtre d'alertes Wazuh
# Cliquer sur Alerts > Refresh ou ajouter un filtre temporaire sur l'heure
```

### Points de contrôle globaux

Avant de tester, vérifier :

```bash
# Sur VM SOC (Manager) :
sudo systemctl status wazuh-manager          # Doit être "active (running)"
sudo /var/ossec/bin/manage_agents -l         # Agents doivent être connectés

# Sur VM1 et VM3 (Agents) :
sudo systemctl status wazuh-agent            # Doit être "active (running)"
sudo /var/ossec/bin/wazuh-control status     # Doit indiquer "running"
```

---

## TEST 1 : Brute Force SSH

**Règle testée** : ID 100001  
**Sévérité attendue** : 10 (Haute)  
**Temps estimé** : 30 min

### 1.1 Objectif du test

Générer 6+ tentatives de connexion SSH échouées en moins de 60 secondes pour déclencher l'alerte brute force.

### 1.2 Configuration préalable

Sur la **VM source d'attaque** (machine externe ou VM Kali) :

```bash
# Installer sshpass si nécessaire
sudo apt install -y sshpass

# Créer un script de tentatives SSH
cat > /tmp/brute_force_ssh.sh << 'EOF'
#!/bin/bash

TARGET="admin@192.168.1.50"  # Remplacer IP_VM1
PORT="2222"                   # Port SSH non-standard de VM1

# 6 tentatives avec mots de passe différents (tous faux)
for i in {1..6}; do
  echo "[Tentative $i/6]"
  sshpass -p "password_wrong_$i" ssh -o StrictHostKeyChecking=no \
    -o ConnectTimeout=3 -p $PORT $TARGET "whoami" 2>/dev/null
  sleep 1
done

echo "Script terminé"
EOF

chmod +x /tmp/brute_force_ssh.sh
```

### 1.3 Étapes du test

**Étape 1 : Lancer le script d'attaque**

```bash
# Terminal 1 - Machine attaquante
/tmp/brute_force_ssh.sh

# Résultat attendu :
# Connexions refusées (Permission denied)
```

**Étape 2 : Observer les logs SSH sur VM1**

```bash
# Terminal 2 - VM1
sudo tail -f /var/log/secure | grep "sshd.*Failed"

# Résultat attendu :
# Jan 15 14:23:45 vm1 sshd[1234]: Failed password for invalid user admin from 192.168.1.100 port 54321
# Jan 15 14:23:46 vm1 sshd[1235]: Failed password for invalid user admin from 192.168.1.100 port 54322
# ... (6 fois minimum)
```

**Étape 3 : Vérifier l'alerte Wazuh**

```bash
# Interface Web Wazuh :
# 1. Aller à Alerts (menu gauche)
# 2. Filtrer par Rule ID: 100001
# 3. Chercher l'alerte avec :
#    - Level: 10
#    - Description: "Brute force SSH détecté..."
#    - Source IP: [IP attaquante]
```

### 1.4 Résultat attendu

```
✓ Alerte déclenchée dans les 5-10 secondes après la 6ème tentative
✓ Règle ID : 100001
✓ Level : 10
✓ Source IP visible et correcte
✓ Timestamp précis
```

### 1.5 Diagnostic en cas d'échec

```bash
# Les logs SSH n'arrivent pas à Wazuh
# → Vérifier que l'agent envoie bien les logs /var/log/secure
# → Commande : sudo tail -100 /var/ossec/logs/ossec.log | grep secure

# L'alerte ne se déclenche pas
# → Vérifier la syntaxe de la règle
sudo /var/ossec/bin/wazuh-control verify-config
# → Vérifier le nombre exact de tentatives (doit être 6+)
# → Vérifier la durée (< 60 secondes)
```

### 1.6 Capture du résultat

**Screenshot attendu** : Interface Wazuh avec l'alerte visuelle

```
┌─────────────────────────────────────────────┐
│ Wazuh Dashboard                             │
├─────────────────────────────────────────────┤
│ Alert Details                               │
│ ─────────────────────────────────────────── │
│ Rule ID: 100001                             │
│ Level: 10 (Haute)                           │
│ Timestamp: 2024-01-15 14:23:50              │
│ Description: Brute force SSH...             │
│ Source IP: 192.168.1.100                    │
│ Count: 6 matches in 60s                     │
│ Status: [ALERT] Red indicator               │
└─────────────────────────────────────────────┘
```

**Fichier de log à conserver** :

```bash
# Exporter l'alerte depuis Wazuh
# Bouton Export > JSON ou CSV
# Sauvegarder comme : 01_brute_force_ssh_alert.json
```

---

## TEST 2 : Upload Malveillant

**Règle testée** : ID 100002  
**Sévérité attendue** : 8 (Moyenne)  
**Temps estimé** : 20 min

### 2.1 Objectif du test

Uploader un fichier avec extension suspecte (.sh, .php, .exe) sur le serveur Web pour déclencher l'alerte.

### 2.2 Configuration préalable

Sur **VM1 (Serveur Web)** :

```bash
# Vérifier le dossier d'upload (créé lors de la config du Web)
ls -la /var/www/html/uploads/
# Doit être writable par l'utilisateur www-data

# Si le dossier n'existe pas :
sudo mkdir -p /var/www/html/uploads
sudo chown www-data:www-data /var/www/html/uploads
sudo chmod 755 /var/www/html/uploads
```

### 2.3 Étapes du test

**Étape 1 : Créer un fichier malveillant**

```bash
# Machine attaquante (ou VM externe)
# Créer un simple script shell "malveillant" (inoffensif)
cat > /tmp/shell.sh << 'EOF'
#!/bin/bash
echo "This is a test shell script"
EOF

cat > /tmp/payload.php << 'EOF'
<?php
echo "PHP Payload Test";
phpinfo();
?>
EOF

cat > /tmp/malware.exe << 'EOF'
Binary file placeholder for testing
EOF
```

**Étape 2 : Uploader via HTTP POST**

```bash
# Utiliser curl pour uploader le fichier
curl -X POST -F "file=@/tmp/shell.sh" \
  http://192.168.1.50/upload.php

curl -X POST -F "file=@/tmp/payload.php" \
  http://192.168.1.50/upload.php

# Ou utiliser wget
wget --post-file=/tmp/malware.exe \
  http://192.168.1.50/upload

# Résultat attendu :
# Réponse HTTP (200 OK ou 400 Bad Request, peu importe)
```

**Étape 3 : Vérifier les logs Nginx sur VM1**

```bash
sudo tail -f /var/log/nginx/access.log

# Résultat attendu :
# 192.168.1.100 - - [15/Jan/2024:14:25:10 +0100] "POST /upload.php HTTP/1.1" 
# ... POST request avec fichier .sh, .php, ou .exe
```

**Étape 4 : Vérifier l'alerte Wazuh**

```bash
# Interface Web Wazuh :
# 1. Alerts > Filter
# 2. Règle : 100002
# 3. Chercher alerte "Upload de fichier potentiellement malveillant"
# 4. Vérifier le nom du fichier dans les détails
```

### 2.4 Résultat attendu

```
✓ Alerte déclenchée pour chaque fichier malveillant uploadé
✓ Règle ID : 100002
✓ Level : 8
✓ Détail de fichier visible (shell.sh, payload.php, malware.exe)
✓ HTTP method : POST
```

### 2.5 Diagnostic en cas d'échec

```bash
# Les logs Nginx n'apparaissent pas dans Wazuh
# → Vérifier que /var/log/nginx/access.log est collecté
grep "nginx.*access.log" /var/ossec/etc/ossec.conf

# L'alerte ne détecte pas les extensions
# → Vérifier la regex dans la règle 100002
# → Ajouter d'autres extensions si besoin : \.(sh|php|exe|dll|bat)$
```

### 2.6 Capture du résultat

**Screenshot** : Alerte Wazuh avec détail du fichier

```
Rule ID: 100002
Level: 8
Description: Upload de fichier potentiellement malveillant
File: shell.sh
User Agent: curl/7.x
Source IP: 192.168.1.100
HTTP Status: 200
```

---

## TEST 3 : Escalade Privilèges (sudo non-autorisé)

**Règle testée** : ID 100003  
**Sévérité attendue** : 10 (Haute)  
**Temps estimé** : 25 min

### 3.1 Objectif du test

Exécuter une commande `sudo` avec un utilisateur non-root/admin pour déclencher l'alerte d'escalade de privilèges.

### 3.2 Configuration préalable

Sur **VM1** :

```bash
# S'assurer que auditd surveille les commandes sudo
# Vérifier le fichier de règles audit
sudo grep -n "sudo" /etc/audit/rules.d/audit.rules

# Si absent, ajouter :
sudo echo "-a always,exit -F arch=b64 -S execve -k sudo_exec" >> /etc/audit/rules.d/audit.rules
sudo auditctl -R /etc/audit/rules.d/audit.rules
sudo auditctl -l  # Vérifier que la règle est chargée
```

### 3.3 Étapes du test

**Étape 1 : Créer un utilisateur standard (non-admin)**

```bash
# Sur VM1, en tant que root
sudo useradd -m -d /home/attacker attacker
sudo passwd attacker  # Définir un mot de passe

# Vérifier que l'utilisateur n'a PAS de droits sudo
sudo grep attacker /etc/sudoers  # Doit être vide
```

**Étape 2 : Tenter une commande sudo non-autorisée**

```bash
# Se connecter en tant que 'attacker'
su - attacker

# Tenter plusieurs commandes sudo interdites
sudo cat /etc/shadow
sudo passwd root
sudo userdel admin
sudo id
sudo whoami

# Résultat attendu :
# "sudo: attacker is not in the sudoers file. This incident will be reported"
```

**Étape 3 : Vérifier les logs auditd sur VM1**

```bash
sudo tail -f /var/log/audit/audit.log | grep -i sudo

# Résultat attendu :
# type=EXECVE msg=audit(...): argc=3 a0="sudo" a1="cat" a2="/etc/shadow"
# type=USER_END msg=audit(...): user pid=1234 uid=1000 auid=1000 ... res=failure
```

**Étape 4 : Vérifier l'alerte Wazuh**

```bash
# Interface Web Wazuh :
# 1. Alerts > Filter
# 2. Règle : 100003
# 3. Chercher alerte "Tentative sudo par utilisateur non-autorisé"
# 4. Vérifier l'utilisateur (attacker) dans les détails
```

### 3.4 Résultat attendu

```
✓ Alerte déclenchée pour chaque tentative sudo de l'utilisateur attacker
✓ Règle ID : 100003
✓ Level : 10
✓ User : attacker
✓ Command : cat /etc/shadow (ou autre)
✓ Result : DENIED ou FAILURE
```

### 3.5 Diagnostic en cas d'échec

```bash
# Les logs auditd n'arrivent pas à Wazuh
# → Vérifier qu'auditd envoie ses logs
sudo auditctl -l | grep execve

# Les événements sudo ne sont pas dans les logs
# → Relancer auditd
sudo systemctl restart auditd
sudo auditctl -R /etc/audit/rules.d/audit.rules

# L'alerte n'est pas filtrée correctement
# → Vérifier la regex du user dans la règle 100003
# → Ajuster si besoin : ^(?!admin|root).*$
```

### 3.6 Capture du résultat

**Screenshot** : Alerte Wazuh avec user et commande

```
Rule ID: 100003
Level: 10
Description: Tentative sudo par utilisateur non-autorisé
User: attacker
Command: sudo cat /etc/shadow
Audit ID: 123456
Result: DENIED
```

---

## TEST 4 : Scan Réseau Massif (Nmap)

**Règle testée** : ID 100004  
**Sévérité attendue** : 7 (Moyenne)  
**Temps estimé** : 30 min

### 4.1 Objectif du test

Exécuter un scan Nmap depuis une machine externe pour déclencher l'alerte de scan réseau.

### 4.2 Configuration préalable

Sur **VM source d'attaque** :

```bash
# Installer Nmap si absent
sudo apt install -y nmap

# Vérifier la version
nmap --version
```

Sur **VM1** :

```bash
# S'assurer que firewalld est actif et enregistre les tentatives de connexion
sudo systemctl status firewalld

# Vérifier les règles de logging
sudo firewall-cmd --list-all

# Si absent, ajouter du logging
sudo firewall-cmd --set-log-denied=all --permanent
sudo firewall-cmd --reload
```

### 4.3 Étapes du test

**Étape 1 : Effectuer un scan Nmap complet**

```bash
# Machine attaquante
# Scan classique (avec réponses)
nmap -sV -p- 192.168.1.50

# Scan SYN (plus agressif)
sudo nmap -sS -p 22,80,443,3000-4000 192.168.1.50

# Scan avec timing agressif (pour augmenter rapidement les connexions)
sudo nmap -sS --timing=insane -p 1-65535 192.168.1.50

# Résultat attendu :
# Scan report visible, liste des ports ouverts/fermés
```

**Étape 2 : Vérifier les logs du firewall sur VM1**

```bash
# Sur VM1
sudo tail -f /var/log/firewalld

# Résultat attendu :
# Nombreuses tentatives de connexion sur différents ports
# Exemple :
# WARNING: IN=eth0 OUT= ... SRC=192.168.1.100 DST=192.168.1.50 DPT=22,23,24,25,...
```

**Étape 3 : Vérifier les alertes Wazuh**

```bash
# Interface Web Wazuh :
# 1. Alerts > Filter
# 2. Règle : 100004
# 3. Chercher alerte "Activité de scan réseau détectée"
# 4. Vérifier l'IP source et les ports détectés
```

### 4.4 Résultat attendu

```
✓ Alerte déclenchée après X tentatives de connexion sur différents ports
✓ Règle ID : 100004
✓ Level : 7
✓ Source IP : [IP attaquante]
✓ Ports détectés : 22, 80, 443, 3000-4000, etc.
✓ Pattern : "scan", "syn", ou "nmap" visible
```

### 4.5 Diagnostic en cas d'échec

```bash
# Le firewall ne log pas les tentatives
# → Vérifier les règles
sudo firewall-cmd --list-all
# → Vérifier le niveau de logging
sudo grep "LogDenied" /etc/firewalld/firewalld.conf

# Les logs n'arrivent pas à Wazuh
# → Vérifier que /var/log/firewalld est collecté
grep "firewalld" /var/ossec/etc/ossec.conf

# L'alerte n'est pas déclenchée
# → La règle détecte les "connexions rapides" (frequency)
# → Vérifier que le scan s'est bien exécuté à vitesse rapide
# → Augmenter le nombre de ports si nécessaire (20+)
```

### 4.6 Capture du résultat

**Screenshot** : Alerte Wazuh avec ports scannés

```
Rule ID: 100004
Level: 7
Description: Activité de scan réseau détectée
Source IP: 192.168.1.100
Ports: 22, 80, 443, 3306, 5432, 8000, 8080...
Count: 25 connexions en 60s
Pattern detected: Port scanning
```

---

## TEST 5 : Connexion Hors Horaires

**Règle testée** : ID 100005  
**Sévérité attendue** : 5 (Basse/Info)  
**Temps estimé** : 20 min

### 5.1 Objectif du test

Effectuer une connexion SSH en dehors de la plage horaire autorisée (22h-7h) pour déclencher l'alerte.

### 5.2 Configuration préalable

Sur **VM SOC** :

```bash
# Modifier l'horloge système pour simuler l'heure
# ATTENTION : A faire SEULEMENT en test, dans une VM dédiée !

# Vérifier l'heure actuelle
date

# Changer l'heure à 23:00 (hors horaires)
sudo date -s "15 Jan 2024 23:00:00"

# Vérifier
date

# Note : Les autres VMs doivent être synchronisées
# Utiliser NTP si disponible : timedatectl
```

### 5.3 Étapes du test

**Étape 1 : Configurer l'heure système**

```bash
# Sur VM1
sudo date -s "15 Jan 2024 23:30:00"  # 23h30 (hors horaires)
date

# Vérifier que l'heure est bien appliquée
hwclock --show
```

**Étape 2 : Effectuer une connexion SSH**

```bash
# Depuis une machine externe (ou autre VM)
ssh -p 2222 admin@192.168.1.50

# Connexion réussie mais génère un log

# Résultat attendu :
# Connexion SSH établie normalement
# Log dans /var/log/secure avec timestamp 23:30
```

**Étape 3 : Vérifier le log SSH sur VM1**

```bash
sudo tail -f /var/log/secure | grep "Accepted"

# Résultat attendu :
# Jan 15 23:30:45 vm1 sshd[5678]: Accepted publickey for admin from 192.168.1.xx port 54321
```

**Étape 4 : Vérifier l'alerte Wazuh**

```bash
# Interface Web Wazuh :
# 1. Alerts > Filter
# 2. Règle : 100005
# 3. Chercher alerte "Connexion en dehors des horaires normaux"
# 4. Vérifier l'heure dans l'alerte (23:30)
```

### 5.4 Résultat attendu

```
✓ Alerte déclenchée pour la connexion SSH hors horaires
✓ Règle ID : 100005
✓ Level : 5 (Info)
✓ User : admin
✓ Timestamp : 23:30 (hors plage 07:00-22:00)
✓ Source IP : visible
```

### 5.5 Diagnostic en cas d'échec

```bash
# L'alerte n'est pas déclenchée
# → Vérifier que l'heure système est bien en dehors de 07:00-22:00
date

# → Vérifier la condition "time" dans la règle 100005
# → Si la durée du test est < 5 min, augmenter le timeframe

# Réinitialiser l'heure après le test
# IMPORTANT : Resynchroniser avec NTP
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd
```

### 5.6 Capture du résultat

**Screenshot** : Alerte Wazuh avec timestamp hors horaires

```
Rule ID: 100005
Level: 5
Description: Connexion en dehors des horaires normaux
User: admin
Time: 23:30 (hors plage 07:00-22:00)
Source IP: 192.168.1.45
Action: Accepted publickey
```

---

## TEST 6 : Commande Système Suspecte

**Règle testée** : ID 100006  
**Sévérité attendue** : 6 (Moyenne)  
**Temps estimé** : 20 min

### 6.1 Objectif du test

Exécuter des commandes système suspectes pour déclencher l'alerte.

### 6.2 Configuration préalable

Sur **VM1** :

```bash
# S'assurer qu'auditd surveille bien les EXECVE
sudo grep "execve" /etc/audit/rules.d/audit.rules

# Si absent, ajouter :
sudo echo "-a always,exit -F arch=b64 -S execve -k exec" >> /etc/audit/rules.d/audit.rules
sudo auditctl -R /etc/audit/rules.d/audit.rules

# Vérifier
sudo auditctl -l | grep execve
```

### 6.3 Étapes du test

**Étape 1 : Exécuter les commandes suspectes**

```bash
# Se connecter en tant qu'admin (ou avec accès sudo)
ssh -p 2222 admin@192.168.1.50

# Exécuter les commandes une par une
cat /etc/shadow        # Lire les hash de mots de passe
sudo cat /etc/shadow

passwd -l admin        # Verrouiller un compte

sudo userdel attacker  # Supprimer un utilisateur

id                     # Vérifier l'ID (peut sembler anodin mais configuré comme suspect)

# Résultat attendu :
# Commandes exécutées (certaines échouent si pas root)
```

**Étape 2 : Vérifier les logs auditd sur VM1**

```bash
sudo tail -f /var/log/audit/audit.log | grep -E "cat.*shadow|passwd.*-l|userdel|id"

# Résultat attendu :
# type=EXECVE msg=audit(...): argc=2 a0="cat" a1="/etc/shadow"
# type=EXECVE msg=audit(...): argc=3 a0="sudo" a1="cat" a2="/etc/shadow"
# type=EXECVE msg=audit(...): argc=3 a0="passwd" a1="-l" a2="admin"
```

**Étape 3 : Vérifier l'alerte Wazuh**

```bash
# Interface Web Wazuh :
# 1. Alerts > Filter
# 2. Règle : 100006
# 3. Chercher alerte "Commande système suspecte détectée"
# 4. Vérifier la commande dans les détails
```

### 6.4 Résultat attendu

```
✓ Alerte déclenchée pour chaque commande suspecte exécutée
✓ Règle ID : 100006
✓ Level : 6
✓ Command visible : cat /etc/shadow, passwd -l, userdel, id
✓ User : admin
✓ Audit ID : visible
```

### 6.5 Diagnostic en cas d'échec

```bash
# Les logs auditd n'arrivent pas
# → Vérifier que auditd envoie ses logs
sudo tail -100 /var/ossec/logs/ossec.log | grep auditd

# Les commandes ne sont pas détectées
# → Vérifier que les commandes ont effectivement été exécutées
sudo aureport | grep cat
sudo aureport | grep userdel

# L'alerte n'est pas créée
# → Ajouter plus de commandes suspectes à la regex si besoin
# → Vérifier que la regex dans 100006 contient : cat /etc/shadow|passwd -l|userdel|id
```

### 6.6 Capture du résultat

**Screenshot** : Alerte Wazuh avec commande suspecte

```
Rule ID: 100006
Level: 6
Description: Commande système suspecte détectée
User: admin
Command: cat /etc/shadow
Result: Exécutée
Audit ID: 123456
```

---

## RÉCAPITULATIF DES TESTS

| Test # | Nom | Règle | Sévérité | État | Screenshot | Notes |
|--------|-----|-------|----------|------|-----------|-------|
| 1 | Brute Force SSH | 100001 | 10 | [ ] | [ ] | 6+ tentatives en 60s |
| 2 | Upload Malveillant | 100002 | 8 | [ ] | [ ] | .sh, .php, .exe |
| 3 | Escalade Privilèges | 100003 | 10 | [ ] | [ ] | sudo non-autorisé |
| 4 | Scan Réseau (Nmap) | 100004 | 7 | [ ] | [ ] | 20+ ports en 60s |
| 5 | Connexion Hors Horaires | 100005 | 5 | [ ] | [ ] | Entre 22h-7h |
| 6 | Commande Système Suspecte | 100006 | 6 | [ ] | [ ] | cat /etc/shadow, etc. |

---

## COMMANDES UTILES LORS DES TESTS

### Sur la machine attaquante

```bash
# Générer du trafic rapidement
watch -n 1 'nmap -sS -p 22,80,443 192.168.1.50'

# Boucle de tentatives SSH
for i in {1..10}; do 
  ssh -o ConnectTimeout=1 user@host 2>/dev/null &
done

# Downloader des outils rapidement
curl http://192.168.1.50/test.sh | bash
wget http://192.168.1.50/malware.exe
```

### Sur VM1 (Cible)

```bash
# Voir les logs en direct
sudo tail -f /var/log/secure /var/log/nginx/access.log /var/log/audit/audit.log

# Compter les entrées spécifiques
sudo grep "Failed password" /var/log/secure | wc -l
sudo grep "POST" /var/log/nginx/access.log | wc -l

# Rechercher les commandes dans auditd
sudo aureport -c | head -20
```

### Sur VM SOC (Manager Wazuh)

```bash
# Voir les alertes en temps réel
sudo tail -f /var/ossec/logs/alerts.json | jq '.rule | {id, level, description}'

# Compter les alertes par règle
sudo find /var/ossec/logs/alerts -name "*.json" | xargs grep -o '"rule_id":"[0-9]*"' | sort | uniq -c

# Vérifier les erreurs
sudo grep ERROR /var/ossec/logs/ossec.log
```

---

## NETTOYAGE APRÈS LES TESTS

### Restaurer les paramètres

```bash
# Réinitialiser l'horloge
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd

# Supprimer l'utilisateur attacker
sudo userdel -r attacker

# Supprimer les fichiers d'upload
sudo rm -f /var/www/html/uploads/*.sh
sudo rm -f /var/www/html/uploads/*.php
sudo rm -f /var/www/html/uploads/*.exe

# Vider les anciennes alertes (optionnel)
# Dans Wazuh : Stack Management > Indices > Supprimer les anciens indices
```

### Archiver les preuves

```bash
# Créer un dossier de rapport
mkdir -p ~/rapport_tests/screenshots
mkdir -p ~/rapport_tests/logs

# Exporter les alertes Wazuh
# Depuis l'interface : Alerts > Export > JSON

# Copier les logs importants
sudo cp /var/log/secure ~/rapport_tests/logs/
sudo cp /var/log/nginx/access.log ~/rapport_tests/logs/
sudo cp /var/log/audit/audit.log ~/rapport_tests/logs/

# Créer un résumé
cat > ~/rapport_tests/RESUME.md << 'EOF'
# Résumé des Tests - Blue Team SOC

## Statistiques
- Tests exécutés : 6/6
- Tests réussis : ✓/✓
- Règles validées : ✓/6
- Alertes générées : ✓ alertes

## Détails par test
[À remplir]

## Conclusion
Tous les scénarios de détection ont été validés avec succès.
EOF
```

---

## POINTS IMPORTANTS

### ⚠️ Sécurité

- **Ne jamais** exécuter les tests sur une infrastructure de production
- **Prévenir** les administrateurs système si vous testez sur un réseau partagé
- **Nettoyer** après les tests pour éviter les alertes permanentes

### ⏱️ Timing

- Les logs mettent **5-10 secondes** à arriver dans Wazuh
- Les règles sont évaluées **toutes les 1-2 secondes**
- Attendre **au moins 2-3 minutes** après chaque test pour observer l'alerte

### 🔍 Observation

- Ouvrir l'interface Wazuh **avant** de lancer chaque test
- **Rafraîchir** la page d'alertes régulièrement (F5 ou bouton Refresh)
- Utiliser les **filtres** pour isoler chaque alerte

### 📊 Documentation

- **Capturer** chaque alerte avec un screenshot
- **Noter** les timestamps exacts pour la cohérence
- **Exporter** les alertes en JSON pour le rapport final

---

## SIGNATURE DU TEST

| Test | Date | Validé | Anomalies |
|------|------|--------|-----------|
| 1 - Brute Force SSH | [ ] | [ ] | |
| 2 - Upload Malveillant | [ ] | [ ] | |
| 3 - Escalade Privilèges | [ ] | [ ] | |
| 4 - Scan Réseau | [ ] | [ ] | |
| 5 - Connexion Hors Horaires | [ ] | [ ] | |
| 6 - Commande Système | [ ] | [ ] | |

**Équipe SOC** : ________________  
**Date de fin** : ________________  
**Responsable tests** : ________________

