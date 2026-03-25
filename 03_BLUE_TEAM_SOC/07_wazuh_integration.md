# Wazuh - Configuration des sources de logs

**Objectif du chapitre :** Configurer Wazuh pour collecter les logs des serveurs

**Durée estimée :** 1 heure

**Prérequis :**
- Wazuh Manager opérationnel sur VM 2
- Au moins 1 agent connecté et actif
- Accès aux fichiers de configuration

---

## 1. Concept : Localfiles

### Qu'est-ce qu'une source de logs ?

Une **source de logs** est un fichier ou répertoire que Wazuh doit **lire et surveiller**.

**Exemples :**
- `/var/log/secure` → logs SSH
- `/var/log/nginx/access.log` → logs du serveur web
- `/var/log/audit/audit.log` → logs du système d'audit
- `/var/log/messages` → messages système généraux

### Comment ça fonctionne ?

```
┌─────────────────────┐
│ Fichier log local   │
│ /var/log/secure     │
└──────────┬──────────┘
           │ (tail -f, suivi en temps réel)
           │
┌──────────▼──────────┐
│ Agent Wazuh         │
│ lit les nouvelles   │
│ lignes              │
└──────────┬──────────┘
           │ (port 1514)
           │
┌──────────▼──────────┐
│ Wazuh Manager       │
│ analyse les logs    │
│ applique les règles │
└─────────────────────┘
```

### Configuration XML `<localfile>`

Chaque source se configure avec un bloc XML :

```xml
<localfile>
  <log_format>syslog</log_format>              <!-- Format du log -->
  <location>/var/log/secure</location>          <!-- Chemin du fichier -->
  <alias>ssh_logs</alias>                        <!-- Alias (optionnel) -->
</localfile>
```

---

## 2. Emplacements des fichiers de configuration

### Sur l'Agent (VM cible)

```bash
/var/ossec/etc/ossec.conf
```

Sections `<localfile>` à ajouter ici.

### Sur le Manager (pour un monitoring centralisé)

```bash
/var/ossec/etc/ossec.conf
```

On peut aussi configurer depuis le Manager.

---

## 3. Configuration des logs SSH

### Localisation du log SSH

Sur VM 1 (Serveur Web) :

```bash
ls -la /var/log/secure
```

Résultat :
```
-rw------- 1 root root 4892 Feb  6 11:30 /var/log/secure
```

### Ajouter la source SSH dans l'agent

Sur VM 1 (Agent) :

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Cherche la section `<agent>` ou crée une nouvelle section `<localfile>` :

```xml
<!-- Collecte des logs SSH -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/secure</location>
  <alias>ssh_logs</alias>
</localfile>
```

### Détails de la configuration SSH

| Paramètre | Valeur | Explication |
|-----------|--------|-------------|
| `log_format` | `syslog` | Format standard des logs système |
| `location` | `/var/log/secure` | Chemin du fichier SSH |
| `alias` | `ssh_logs` | Nom pour retrouver facilement |

---

## 4. Configuration des logs Web (Nginx/Apache)

### Sur VM 1 (si Nginx est installé)

Localiser le log Nginx :

```bash
ls -la /var/log/nginx/access.log
```

### Ajouter la source dans ossec.conf

```xml
<!-- Collecte des logs Nginx -->
<localfile>
  <log_format>nginx</log_format>
  <location>/var/log/nginx/access.log</location>
  <alias>web_access_logs</alias>
</localfile>

<!-- Collecte des erreurs Nginx -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/nginx/error.log</location>
  <alias>web_error_logs</alias>
</localfile>
```

### Si Apache au lieu de Nginx

```xml
<localfile>
  <log_format>apache</log_format>
  <location>/var/log/httpd/access_log</location>
  <alias>apache_access</alias>
</localfile>
```

---

## 5. Configuration des logs Auditd

### Vérifier que auditd est actif

```bash
sudo systemctl status auditd
```

Si inactif, l'activer :

```bash
sudo systemctl enable auditd
sudo systemctl start auditd
```

### Localiser les logs audit

```bash
ls -la /var/log/audit/
```

Résultat :
```
-rw------- 1 root root 12500 Feb  6 11:35 audit.log
```

### Ajouter la source audit

```xml
<!-- Collecte des logs Audit -->
<localfile>
  <log_format>audit</log_format>
  <location>/var/log/audit/audit.log</location>
  <alias>audit_logs</alias>
</localfile>
```

---

## 6. Configuration des logs système généraux

### Fichier messages

```xml
<!-- Collecte des messages système -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/messages</location>
  <alias>system_logs</alias>
</localfile>
```

### Logs de démarrage

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/boot.log</location>
  <alias>boot_logs</alias>
</localfile>
```

---

## 7. Configuration pour le firewall (Firewalld)

### Localiser les logs firewall

```bash
sudo journalctl -u firewalld | head -20
```

Ou depuis rsyslog :

```bash
grep firewall /var/log/messages
```

### Ajouter la source firewall

```xml
<!-- Collecte des logs Firewall -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/firewall.log</location>
  <alias>firewall_logs</alias>
</localfile>
```

**Note :** Si firewalld n'a pas de fichier dédié, utilise journalctl depuis le Manager.

---

## 8. Configuration pour les services custom

### Exemple : Logs d'une application personnalisée

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/myapp/app.log</location>
  <alias>custom_app_logs</alias>
</localfile>
```

### Avec rotation de logs

Si le fichier est en rotation (log.1, log.2, etc.) :

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/myapp/app.log*</location>  <!-- Wildcard -->
  <alias>custom_app_logs</alias>
</localfile>
```

---

## 9. Configuration complète exemple (Serveur Web VM1)

### Fichier ossec.conf complet pour un agent

Voici un exemple avec toutes les sources configurées :

```xml
<!-- Fichier /var/ossec/etc/ossec.conf sur VM1 -->

<agent>
  <server>
    <address>192.168.1.50</address>  <!-- IP Manager -->
    <port>1514</port>
    <protocol>tcp</protocol>
  </server>
</agent>

<!-- ========== SOURCES DE LOGS ========== -->

<!-- SSH -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/secure</location>
  <alias>ssh_logs</alias>
</localfile>

<!-- Web -->
<localfile>
  <log_format>nginx</log_format>
  <location>/var/log/nginx/access.log</location>
  <alias>web_access_logs</alias>
</localfile>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/nginx/error.log</location>
  <alias>web_error_logs</alias>
</localfile>

<!-- Audit -->
<localfile>
  <log_format>audit</log_format>
  <location>/var/log/audit/audit.log</location>
  <alias>audit_logs</alias>
</localfile>

<!-- Système -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/messages</location>
  <alias>system_logs</alias>
</localfile>

<!-- Firewall -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/firewall.log</location>
  <alias>firewall_logs</alias>
</localfile>
```

---

## 10. Application de la configuration

### Étape 1 : Sauvegarder la config

```bash
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.backup
```

### Étape 2 : Valider la syntaxe XML

```bash
sudo /var/ossec/bin/verify-agent-conf
```

Résultat attendu :
```
Verifying agent config...
Configuration OK.
```

### Étape 3 : Redémarrer l'agent

```bash
sudo systemctl restart wazuh-agent
```

### Étape 4 : Vérifier le statut

```bash
sudo systemctl status wazuh-agent
```

Doit être "active (running)".

---

## 11. Vérification que les logs arrivent

### Méthode 1 : Via le Manager

Sur VM 2 (Manager) :

```bash
sudo tail -f /var/ossec/logs/ossec.log | grep -i "ssh_logs\|web_access"
```

Résultat :
```
2024-02-06T11:40:15.123456+00:00 manager wazuh: Agent 001 (server-web) 
  successfully reading: /var/log/secure
```

### Méthode 2 : Générer un événement test

Sur VM 1 (Agent), génère un événement SSH :

```bash
# Tenter une mauvaise connexion SSH (génère un log)
ssh baduser@localhost 2>&1 | head -1
# Ou directement
echo "Test SSH attempt" >> /var/log/secure
```

Sur le Manager, cherche cet événement :

```bash
sudo grep "Test SSH" /var/ossec/logs/alerts/alerts.json
```

### Méthode 3 : Interface Web

1. Va sur `https://IP_Manager:443/app/wazuh`
2. Menu "Logs"
3. Filtre par agent 001
4. Cherche les événements SSH

---

## 12. Permissions d'accès aux fichiers

### Problème courant : Permission denied

**Symptôme :**
```
ERROR: open file '/var/log/secure' failed (errno 13)
```

**Solution :**

L'utilisateur `wazuh` doit avoir accès aux fichiers log :

```bash
# Vérifier les permissions
ls -la /var/log/secure /var/log/nginx/ /var/log/audit/

# Ajouter wazuh au groupe root ou loggers
sudo usermod -a -G adm,wheel wazuh
sudo usermod -a -G systemd-journal wazuh

# Ou changer les permissions
sudo chmod g+r /var/log/secure
sudo chmod g+r /var/log/nginx/access.log
sudo chmod g+r /var/log/audit/audit.log
```

### Redémarrer l'agent après changement de permissions

```bash
sudo systemctl restart wazuh-agent
```

---

## 13. Formats de logs supportés

Wazuh supporte plusieurs formats natifs :

| Format | Fichiers | Exemple |
|--------|----------|---------|
| `syslog` | /var/log/secure, /var/log/messages | SSH, auditd, système |
| `nginx` | /var/log/nginx/access.log | Logs Nginx |
| `apache` | /var/log/httpd/access_log | Logs Apache |
| `audit` | /var/log/audit/audit.log | Auditd |
| `json` | Logs au format JSON natif | Apps modernes |

---

## 14. Configuration avancée : Alertes sur fichiers

### Surveiller aussi les modifications de fichiers

```xml
<!-- Intégrité des fichiers système -->
<syscheck>
  <frequency>3600</frequency>  <!-- Toutes les heures -->
  <directories check_all="yes" realtime="yes">/etc</directories>
  <directories check_all="yes" realtime="yes">/root/.ssh</directories>
  <directories check_all="yes" realtime="yes">/var/www</directories>
</syscheck>
```

---

## 15. Dépannage courant

### Problème 1 : Les logs n'arrivent pas

**Checklist :**
```bash
# 1. Agent en route ?
sudo systemctl status wazuh-agent

# 2. Config valide ?
sudo /var/ossec/bin/verify-agent-conf

# 3. Fichiers accessibles ?
ls -la /var/log/secure /var/log/nginx/

# 4. Permissions wazuh ?
id wazuh

# 5. Connecté au Manager ?
sudo ss -tuln | grep 1514
```

### Problème 2 : Too many fields / Erreurs de parsing

**Symptôme :**
```
ERROR: Too many fields in decoded
```

**Solution :**
```bash
# Vérifier le format du log
head -1 /var/log/nginx/access.log

# Ajuster le format dans ossec.conf si besoin
<localfile>
  <log_format>json</log_format>  <!-- Tenter json -->
  <location>/var/log/nginx/access.log</location>
</localfile>
```

### Problème 3 : File not found

**Symptôme :**
```
ERROR: Could not find file: /var/log/nginx/access.log
```

**Solution :**
```bash
# Vérifier le chemin exact
find /var/log -name "access.log*"

# Corriger dans ossec.conf
# Redémarrer l'agent
sudo systemctl restart wazuh-agent
```

---

## 📚 Résumé des configurations

### Serveur Web (VM1)

```xml
<!-- SSH -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/secure</location>
</localfile>

<!-- Web (Nginx) -->
<localfile>
  <log_format>nginx</log_format>
  <location>/var/log/nginx/access.log</location>
</localfile>

<!-- Audit -->
<localfile>
  <log_format>audit</log_format>
  <location>/var/log/audit/audit.log</location>
</localfile>

<!-- Système -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/messages</location>
</localfile>
```

### Serveur Monitoring (VM3)

Même structure, ajoute si besoin :

```xml
<!-- Prometheus/Zabbix logs -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/prometheus/prometheus.log</location>
</localfile>
```

---

## 💡 Mémo

**Une source de logs = un bloc `<localfile>`**

Chaque bloc :
1. Définit le format du log
2. Pointe vers le fichier
3. Donne un alias pour la trace

---

**Fin du chapitre 4 - Configuration des logs**

Une fois les logs collectés, tu es prêt à explorer le Dashboard et créer des règles.
