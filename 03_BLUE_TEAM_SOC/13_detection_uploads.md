# Détection Uploads de Fichiers Suspects

**Durée estimée : 1 heure**  
**Niveau : Intermédiaire**  
**Objectif** : Détecter les uploads de fichiers malveillants et les modifications de répertoires critiques

---

## 📌 Objectifs

À la fin de cette fiche, tu pourras :
- Configurer File Integrity Monitoring (FIM) avec Wazuh
- Détecter les uploads dans `/var/www/html`
- Alerter sur les extensions suspectes (.php, .sh, .exe)
- Monitorer les répertoires sensibles

---

## 1. Contexte : Qu'est-ce qu'un upload malveillant ?

### Scénario classique

Un attaquant upload un **webshell** (fichier PHP malveillant) :

```bash
# Attaquant
$ curl -F "file=@shell.php" http://192.168.1.10/upload.php

# Serveur Rocky crée le fichier
/var/www/html/uploads/shell.php

# Attaquant peut maintenant exécuter des commandes
$ curl http://192.168.1.10/uploads/shell.php?cmd=ls
```

### Types de fichiers suspects

| Extension | Type | Danger | Action |
|-----------|------|--------|--------|
| `.php` | Webshell | 🔴 CRITIQUE | Alerte level 9 |
| `.sh` | Script bash | 🔴 CRITIQUE | Alerte level 9 |
| `.exe` | Windows executable | 🔴 CRITIQUE | Alerte level 9 |
| `.jsp` | Java webshell | 🔴 CRITIQUE | Alerte level 8 |
| `.asp` | ASP webshell | 🔴 CRITIQUE | Alerte level 8 |
| `.zip` | Archive | 🟠 MOYEN | Alerte level 5 |
| `.tar.gz` | Archive | 🟠 MOYEN | Alerte level 5 |
| `.pdf` | Document | 🟢 NORMAL | Log info |

---

## 2. Configurer File Integrity Monitoring (FIM)

### Qu'est-ce que le FIM ?

Wazuh peut **surveiller les fichiers** et alerter quand :
- Nouveau fichier créé
- Fichier modifié
- Fichier supprimé
- Permissions changées

---

## 3. Configuration Wazuh pour FIM

### Fichier à éditer

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Ajoute cette section dans `<agent>` :

```xml
<!-- ============================================
     FILE INTEGRITY MONITORING
     ============================================ -->

<!-- Monitorer uploads -->
<syscheck>
  <!-- Vérifier chaque 10 minutes -->
  <frequency>600</frequency>
  
  <!-- Répertoire uploads (alert sur création) -->
  <directories check_all="yes" realtime="yes">/var/www/html/uploads</directories>
  
  <!-- Répertoire web complet (plus prudent) -->
  <directories check_all="yes" realtime="yes">/var/www/html</directories>
  
  <!-- Répertoires sensibles du système -->
  <directories check_all="yes" realtime="yes">/etc</directories>
  <directories check_all="yes" realtime="yes">/bin</directories>
  <directories check_all="yes" realtime="yes">/usr/bin</directories>
  
  <!-- Ignorer certains fichiers pour éviter trop d'alertes -->
  <ignore>/var/www/html/logs</ignore>
  <ignore>/var/www/html/cache</ignore>
  <ignore>/var/www/html/temp</ignore>
</syscheck>
```

### Expliquons les paramètres

| Paramètre | Valeur | Signification |
|-----------|--------|---------------|
| `frequency` | 600 | Vérifier tous les 10 min (600 secondes) |
| `realtime="yes"` | activé | Alerte immédiate si changement |
| `check_all="yes"` | activé | Vérifier hash, owner, permissions |
| `<ignore>` | path | Ignorer certains chemins |

---

## 4. Redémarrer Wazuh après modif

```bash
sudo systemctl restart wazuh-agent
sudo systemctl status wazuh-agent

# Vérifier que FIM est actif
sudo grep -i "syscheck" /var/ossec/logs/ossec.log | head -5
```

---

## 5. Règles pour détecter uploads

### Fichier à éditer

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

Ajoute ces règles :

```xml
<!-- ============================================
     FILE INTEGRITY MONITORING - Uploads
     ============================================ -->

<group name="file_monitoring,">

  <!-- RÈGLE 1 : Fichier créé dans uploads (baseline) -->
  <rule id="100030" level="3">
    <if_sid>550</if_sid>  <!-- Wazuh FIM rule -->
    <match>/var/www/html/uploads</match>
    <description>FIM: New file created in uploads directory</description>
    <group>file_creation,</group>
  </rule>

  <!-- RÈGLE 2 : Extension suspecte détectée -->
  <rule id="100031" level="9">
    <if_sid>100030</if_sid>
    <regex>\.php$|\.php[0-9]+$|\.phtml$|\.sh$|\.exe$|\.bat$|\.jsp$|\.asp$|\.aspx$|\.cgi$</regex>
    <description>FIM: Suspicious file uploaded (dangerous extension detected)</description>
    <group>malware,file_upload_attack,</group>
    <mitre>
      <id>T1190</id>  <!-- MITRE: Exploit Public-Facing Application -->
    </mitre>
  </rule>

  <!-- RÈGLE 3 : Archive suspecte (.zip/.tar) -->
  <rule id="100032" level="5">
    <if_sid>100030</if_sid>
    <regex>\.zip$|\.tar$|\.tar\.gz$|\.rar$|\.7z$</regex>
    <description>FIM: Archive file uploaded (possible packed malware)</description>
    <group>file_upload_attack,suspicious_file,</group>
  </rule>

  <!-- RÈGLE 4 : Modification de fichiers système (critique) -->
  <rule id="100033" level="8">
    <if_sid>553</if_sid>  <!-- Wazuh file modified -->
    <match>/bin|/usr/bin|/etc|/var/www/html</match>
    <description>FIM: System or web file modified</description>
    <group>system_modification,attack,</group>
  </rule>

  <!-- RÈGLE 5 : Suppression fichier sensible -->
  <rule id="100034" level="7">
    <if_sid>554</if_sid>  <!-- Wazuh file deleted -->
    <match>/var/www/html|/etc</match>
    <description>FIM: Important file deleted</description>
    <group>file_deletion,attack,</group>
  </rule>

  <!-- RÈGLE 6 : Multiple uploads en peu de temps (possible brute upload) -->
  <rule id="100035" level="6">
    <if_sid>100030</if_sid>
    <frequency>10</frequency>
    <timeframe>60</timeframe>
    <description>FIM: Multiple files uploaded quickly (10+ files in 60 seconds)</description>
    <group>file_upload_attack,</group>
  </rule>

</group>
```

---

## 6. Explication détaillée des règles

### Règle 100030 : Baseline (fichier créé)

```xml
<rule id="100030" level="3">
  <if_sid>550</if_sid>
  <match>/var/www/html/uploads</match>
  <description>FIM: New file created in uploads directory</description>
</rule>
```

**Quand ça trigger** :
```
Wazuh détecte un nouveau fichier dans /var/www/html/uploads
```

**Level 3** = Info (uploads sont normaux)

**if_sid=550** = Wazuh rule interne pour "new file"

---

### Règle 100031 : Extension suspecte ⚠️ CRITICAL

```xml
<rule id="100031" level="9">
  <if_sid>100030</if_sid>
  <regex>\.php$|\.php[0-9]+$|\.phtml$|\.sh$|\.exe$|\.bat$|\.jsp$|\.asp$|\.aspx$|\.cgi$</regex>
  <description>FIM: Suspicious file uploaded (dangerous extension detected)</description>
  <group>malware,file_upload_attack,</group>
</rule>
```

**Décortiquons la regex** :

```regex
\.php$              = se termine par .php
|\.php[0-9]+$       = se termine par .php2, .php3, etc (contourner filter)
|\.phtml$           = PHP HTML variant
|\.sh$              = script bash
|\.exe$|\.bat$      = Windows executables
|\.jsp$|\.asp$      = Webshells Java/ASP
|\.cgi$             = CGI scripts
```

**Pourquoi ces extensions** :
- **PHP** : Lance du code serveur (accès complet)
- **SH** : Exécute des commandes bash
- **EXE/BAT** : Executables Windows
- **JSP/ASP** : Autres webshells

**Level 9** = Alert (mailveillance probable)

---

### Règle 100032 : Archives suspectes

```xml
<rule id="100032" level="5">
  <if_sid>100030</if_sid>
  <regex>\.zip$|\.tar$|\.tar\.gz$|\.rar$|\.7z$</regex>
  <description>FIM: Archive file uploaded</description>
</rule>
```

**Cas d'usage** :
- Attaquant upload `.zip` pour contourner détection
- Puis décompresse sur serveur

**Level 5** = Warning (suspect mais pas confirmé malveillant)

---

### Règle 100033 : Modification fichiers système

```xml
<rule id="100033" level="8">
  <if_sid>553</if_sid>  <!-- Wazuh "file modified" -->
  <match>/bin|/usr/bin|/etc|/var/www/html</match>
  <description>FIM: System or web file modified</description>
</rule>
```

**Quand ça trigger** :
```
Fichier dans /bin, /etc ou /var/www modifié
= attaquant a écrit sur disque après compromission
```

**Level 8** = Alert (incident en cours)

---

### Règle 100035 : Upload brute force

```xml
<rule id="100035" level="6">
  <if_sid>100030</if_sid>
  <frequency>10</frequency>
  <timeframe>60</timeframe>
  <description>Multiple files uploaded quickly</description>
</rule>
```

**Logique** :
- 10 fichiers uploadés
- En 60 secondes
- = comportement suspect (shell upload)

---

## 7. Test pratique

### Étape 1 : Vérifier configuration

```bash
# Vérifier que Wazuh monitore les uploads
sudo grep -A5 "syscheck" /var/ossec/etc/ossec.conf | grep uploads

# Redémarrer pour charger la config
sudo systemctl restart wazuh-agent
sudo systemctl restart wazuh-manager
```

### Étape 2 : Créer un fichier test (non malveillant)

```bash
# Sur serveur Rocky
sudo mkdir -p /var/www/html/uploads

# Créer un fichier benin (PDF)
echo "Test PDF" | sudo tee /var/www/html/uploads/test.pdf

# Attendre 10 secondes
sleep 10

# Vérifier l'alerte
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100030")'
```

Résultat attendu :
```json
{
  "rule": {
    "id": "100030",
    "level": 3,
    "description": "FIM: New file created in uploads directory"
  },
  "file": {
    "name": "/var/www/html/uploads/test.pdf",
    "change": "new_file"
  }
}
```

### Étape 3 : Créer un fichier suspect (.php)

```bash
# Créer un webshell basique (TRÈS DANGEREUX - lab seulement)
sudo bash -c 'echo "<?php system(\$_GET[\"cmd\"]); ?>" > /var/www/html/uploads/shell.php'

# Wazuh va immédiatement alerter
```

Alerte attendue :
```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100031")'
```

Résultat :
```json
{
  "rule": {
    "id": "100031",
    "level": 9,
    "description": "Suspicious file uploaded (dangerous extension detected)"
  },
  "file": {
    "name": "/var/www/html/uploads/shell.php",
    "extension": ".php"
  }
}
```

### Étape 4 : Multiple uploads rapides

```bash
# Créer 10 fichiers rapidement
for i in {1..10}; do
  sudo bash -c "echo 'test$i' > /var/www/html/uploads/file$i.txt"
  sleep 0.5
done

# Alerte 100035 devrait déclencher
```

---

## 8. Intégration avec réaction automatique

### Bloquer les extensions dangereuses automatiquement

```xml
<rule id="100031" level="9">
  <if_sid>100030</if_sid>
  <regex>\.php$|\.sh$|\.exe$</regex>
  <description>FIM: Suspicious file uploaded</description>
  <group>malware,file_upload_attack,</group>
  
  <!-- Supprimer le fichier malveillant -->
  <active-response>
    <command>custom-delete-file</command>
    <location>local</location>
    <timeout>0</timeout>  <!-- Immédiat -->
  </active-response>
  
  <!-- Alerter l'admin -->
  <alert>email</alert>
</rule>
```

**Note** : Nécessite un script personnalisé `custom-delete-file`

---

## 9. Optimiser FIM pour éviter surcharge

### Ignorer certains chemins

```xml
<syscheck>
  <frequency>600</frequency>
  
  <!-- Monitorer uploads -->
  <directories check_all="yes" realtime="yes">/var/www/html/uploads</directories>
  
  <!-- Ignorer cache/logs pour moins d'alertes -->
  <ignore>/var/www/html/cache</ignore>
  <ignore>/var/www/html/logs</ignore>
  <ignore>/var/www/html/tmp</ignore>
  <ignore>/var/log/apache2</ignore>
</syscheck>
```

### Ignorer extensions bénignes

```xml
<!-- Ignorer les fichiers logs -->
<ignore type="sregex">/var/www/html/.*\.log$</ignore>

<!-- Ignorer les fichiers temporaires -->
<ignore type="sregex">/var/www/html/.*\.tmp$</ignore>
```

---

## 10. Cas d'usage : Scénario complet

### Attaque Web Upload

1. **Attaquant** upload un webshell via formulaire :
   ```bash
   curl -F "file=@shell.php" http://192.168.1.10/upload.php
   ```

2. **Serveur Rocky** crée le fichier :
   ```
   /var/www/html/uploads/shell.php
   ```

3. **Wazuh** détecte :
   - Alerte 100030 (niveau 3) : Fichier créé
   - Alerte 100031 (niveau 9) ⚠️ : Extension .php detectée

4. **SOC Alert** :
   ```json
   {
     "rule": {"id": "100031", "level": 9},
     "file": {"name": "shell.php", "change": "new_file"}
   }
   ```

5. **Incident Response** :
   - Isoler le serveur
   - Supprimer le fichier
   - Examiner les logs d'accès web
   - Rebooter le serveur

---

## 11. Vérifier la configuration complète

### Checklist

- [ ] FIM configuré dans `/var/ossec/etc/ossec.conf`
- [ ] Répertoires `/var/www/html/uploads` listés
- [ ] Règles 100030-100035 dans `local_rules.xml`
- [ ] Syntaxe valide (`wazuh-logtest`)
- [ ] Wazuh agents/managers redémarrés
- [ ] Test : créer fichier .pdf → alerte 100030
- [ ] Test : créer fichier .php → alerte 100031
- [ ] Test : créer 10 fichiers → alerte 100035

### Logs à surveiller

```bash
# Serveur Rocky
sudo ls -la /var/www/html/uploads

# VM SOC - alertes FIM
sudo tail -f /var/ossec/logs/alerts/alerts.json | grep -E "100030|100031|100032|100033|100034|100035"
```

---

## 12. Exemple : Configuration serveur web sécurisé

```bash
# Sur serveur Rocky - sécuriser les uploads

# 1. Répertoire uploads non exécutable
sudo chmod 755 /var/www/html/uploads

# 2. Empêcher l'exécution de PHP dans uploads (nginx)
# Dans /etc/nginx/sites-available/default :
location /uploads/ {
    location ~ \.php$ {
        deny all;  # Bloquer toutes requêtes PHP
    }
}

# 3. Supprimer les permissions exécutables
sudo chmod 644 /var/www/html/uploads/*
```

---

## 13. Troubleshooting

### FIM ne génère pas d'alertes

```bash
# Vérifier que syscheck est actif
sudo ps aux | grep -i wazuh

# Vérifier les logs Wazuh
sudo tail -100 /var/ossec/logs/ossec.log | grep -i syscheck

# Reconfigurer manuellement
sudo systemctl stop wazuh-agent
sudo /var/ossec/bin/wazuh-control start
```

### Trop d'alertes

```bash
# Réduire la fréquence
<frequency>1800</frequency>  <!-- 30 minutes au lieu de 10 -->

# Désactiver realtime
<directories check_all="yes" realtime="no">/var/www/html/uploads</directories>

# Ajouter plus d'ignores
<ignore>/var/www/html/cache</ignore>
<ignore>/var/www/html/sessions</ignore>
```

---

## 📚 Fichiers importants

```
/var/ossec/etc/ossec.conf                   ← FIM config
/var/ossec/etc/rules/local_rules.xml        ← Tes règles
/var/www/html/uploads                       ← Répertoire à surveiller
/var/ossec/logs/alerts/alerts.json          ← Alertes Wazuh
```

---

## 🔗 Ressources utiles

```bash
# Tester une regex sur le contenu d'un fichier
cat /var/www/html/uploads/shell.php | grep -E "\.php$"

# Voir tous les fichiers dans uploads
ls -lah /var/www/html/uploads

# Hash un fichier (pour détection tampering)
sha256sum /var/www/html/uploads/shell.php
```

---

**Durée réelle** : 1 heure (40 min config + 20 min tests)  
**Compétences** : FIM, file monitoring, webshell detection  
**Prochaine étape** : Détection accès hors horaires
