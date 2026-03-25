# 🛡️ Mémo Wazuh - SIEM & Détection d'Intrusions

> **Objectif** : Guide rapide pour installer, configurer et utiliser Wazuh dans le projet SOC.  
> **Contexte** : Centralisation des logs, détection d'attaques, alertes temps réel.  
> **Architecture** : Manager (collecteur) + Agents (sources) + Interface web

---

## 1️⃣ Installation

### Prérequis

```bash
# CPU : 2 cores minimum
# RAM : 4 GB minimum (8 GB recommandé)
# Disque : 20 GB minimum

lscpu
free -h
df -h
```

### Installation du Manager Wazuh (VM SOC)

```bash
# 1. Ajouter repo Wazuh
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | rpm --import -

# 2. Créer fichier repo
cat > /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL \$releasever \$basearch
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

# 3. Installer Wazuh Manager
dnf install -y wazuh-manager

# 4. Générer certificats SSL
/var/ossec/bin/wazuh-certs-tool.sh

# 5. Démarrer service
systemctl start wazuh-manager
systemctl enable wazuh-manager

# 6. Vérifier
systemctl status wazuh-manager
```

### Installation du Agent Wazuh (sur VM à monitorer)

```bash
# Sur chaque VM à protéger (web, monitoring, etc.)

# 1. Ajouter repo Wazuh (même que manager)
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | rpm --import -

cat > /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL \$releasever \$basearch
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

# 2. Installer agent
dnf install -y wazuh-agent

# 3. Configurer manager IP
# Éditer /var/ossec/etc/ossec.conf et ajouter :
# <server>
#   <address>192.168.1.20</address>  ← IP du manager
#   <port>1514</port>
#   <protocol>tcp</protocol>
# </server>

nano /var/ossec/etc/ossec.conf

# 4. Démarrer agent
systemctl start wazuh-agent
systemctl enable wazuh-agent

# 5. Vérifier
systemctl status wazuh-agent
```

---

## 2️⃣ Gestion des Services Wazuh

### Manager (VM SOC)

```bash
# Démarrer
systemctl start wazuh-manager

# Arrêter
systemctl stop wazuh-manager

# Redémarrer
systemctl restart wazuh-manager

# Recharger config
systemctl reload wazuh-manager

# Statut
systemctl status wazuh-manager

# Activer au démarrage
systemctl enable wazuh-manager

# Vérifier version
/var/ossec/bin/wazuh-control info
```

### Agents (VM à protéger)

```bash
# Démarrer
systemctl start wazuh-agent

# Redémarrer
systemctl restart wazuh-agent

# Statut
systemctl status wazuh-agent

# Vérifier connexion au manager
/var/ossec/bin/wazuh-control state

# Activer au démarrage
systemctl enable wazuh-agent
```

---

## 3️⃣ Enregistrement des Agents

### Méthode 1 : Registration CLI (recommandé)

```bash
# Sur le MANAGER, générer clé pour agent
/var/ossec/bin/manage_agents -a -n "agent-web" -i 192.168.1.10 -g web

# Output : ID=001, Key=...

# Sur l'AGENT, importer la clé
/var/ossec/bin/manage_agents -i [KEY_GENEREE]

# Redémarrer agent
systemctl restart wazuh-agent
```

### Vérifier l'enregistrement

```bash
# Sur le MANAGER
/var/ossec/bin/manage_agents -l
# Affiche liste des agents enregistrés

# Voir status agent
/var/ossec/bin/wazuh-control agent_control -l
```

### Supprimer un agent

```bash
# Sur le MANAGER
/var/ossec/bin/manage_agents -r 001
# où 001 = ID de l'agent
```

---

## 4️⃣ Configuration des Sources de Logs

### Configurer Wazuh pour collecter logs

**Éditer `/var/ossec/etc/ossec.conf` sur chaque agent :**

```xml
<!-- SSH logs -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/secure</location>
</localfile>

<!-- Web server logs (Nginx) -->
<localfile>
  <log_format>apache</log_format>
  <location>/var/log/nginx/access.log</location>
</localfile>

<!-- Syslog general -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/messages</location>
</localfile>

<!-- Audit logs (si auditd actif) -->
<localfile>
  <log_format>json</log_format>
  <location>/var/log/audit/audit.log</location>
</localfile>

<!-- Sudo logs -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/secure</location>
</localfile>
```

### Redémarrer agent après modification

```bash
systemctl restart wazuh-agent
```

### Vérifier logs collectés

```bash
# Sur le MANAGER
tail -f /var/ossec/logs/alerts/alerts.json

# Ou via interface web
# https://SOC_IP:443
```

---

## 5️⃣ Interface Web Wazuh

### Accéder au Dashboard

```bash
# URL : https://SOC_IP:443

# Identifiants par défaut (à changer IMMÉDIATEMENT)
# Utilisateur : admin
# Mot de passe : SecretPassword
```

### Sections principales

| Section | Fonction |
|---------|----------|
| **Dashboard** | Vue d'ensemble (agents, alertes) |
| **Agents** | Gestion des agents (voir statut) |
| **Modules** | Fonctionnalités (File Integrity, Syscalls) |
| **Threat Intelligence** | Alertes et patterns d'attaque |
| **Compliance** | Standards (PCI-DSS, GDPR) |
| **Settings** | Configuration (utilisateurs, connexions) |

### Actions courantes

- **Ajouter agent** : Settings → Agents → Register agent
- **Voir alertes** : Threat Intelligence → Alerts
- **Modifier règles** : Settings → Rules
- **Voir événements** : Agents → Sélectionner agent → Events

---

## 6️⃣ Règles Personnalisées (Détection)

### Emplacement des règles

```bash
# Règles Wazuh :
ls /var/ossec/ruleset/rules/

# Fichier de config :
/var/ossec/etc/ossec.conf

# Logique : Events → Match Rules → Generate Alert
```

### Syntaxe d'une règle Wazuh

```xml
<rule id="XXXXX" level="LEVEL" >
  <match>pattern_to_match</match>
  <description>Description de l'alerte</description>
  <group>attack_type</group>
</rule>
```

### Exemples de règles personnalisées

#### Détection Brute Force SSH

```xml
<!-- Dans /var/ossec/etc/rules/local_rules.xml -->

<rule id="100001" level="5">
  <if_sid>5710,5711,5712</if_sid>
  <description>Multiple SSH failed auth attempts</description>
  <group>attack.ssh</group>
</rule>

<!-- Règle agrégée (5 tentatives en 2 min) -->
<rule id="100002" level="10" frequency="5" timeframe="120">
  <if_sid>5710</if_sid>
  <description>Brute force SSH attempt</description>
  <group>attack.ssh</group>
</rule>
```

#### Détection Connexion Root SSH

```xml
<rule id="100003" level="7">
  <if_group>authentication_success</if_group>
  <match>user: root</match>
  <description>ROOT login via SSH</description>
  <group>auth.suspicious</group>
</rule>
```

#### Détection Upload fichier en /tmp

```xml
<rule id="100004" level="6">
  <log_format>syslog</log_format>
  <match>.*Uploaded.*</match>
  <description>Suspicious file upload detected</description>
  <group>attack.execution</group>
</rule>
```

#### Détection Commande Sudo

```xml
<rule id="100005" level="5">
  <if_group>sudo_cmds</if_group>
  <match>cat /root|passwd|shadow</match>
  <description>Suspicious sudo command executed</description>
  <group>attack.privilege_escalation</group>
</rule>
```

### Ajouter règle personnalisée

1. **Éditer `/var/ossec/etc/rules/local_rules.xml`**

```bash
nano /var/ossec/etc/rules/local_rules.xml
```

2. **Ajouter votre règle XML**

3. **Vérifier syntaxe**

```bash
/var/ossec/bin/wazuh-control validate-config
```

4. **Redémarrer Wazuh**

```bash
systemctl restart wazuh-manager
```

### Tester une règle

```bash
# Générer un log qui match
echo "Your test message" >> /var/log/messages

# Vérifier l'alerte dans le manager
tail -f /var/ossec/logs/alerts/alerts.json | grep "Your test"
```

---

## 7️⃣ Alertes et Niveaux de Sévérité

### Niveaux d'alerte Wazuh

| Niveau | Sévérité | Sens |
|--------|----------|------|
| 0-3 | Info | Informatif (pas une menace) |
| 4-5 | Low | Faible (intéressant) |
| 6-7 | Medium | Moyen (à investiguer) |
| 8-10 | High | Élevé (probable incident) |
| 11-15 | Critical | Critique (incident confirmé) |

### Configurer alertes par email

```bash
# Éditer /var/ossec/etc/ossec.conf :
<email_notification>
  <email_to>soc@example.com</email_to>
  <smtp_server>localhost</smtp_server>
  <email_from>wazuh@example.com</email_from>
  <log_alert_level>5</log_alert_level>
</email_notification>

systemctl restart wazuh-manager
```

### Visualiser alertes

```bash
# Via CLI - dernières 20 alertes
tail -20 /var/ossec/logs/alerts/alerts.log

# JSON format
tail -20 /var/ossec/logs/alerts/alerts.json

# Temps réel
tail -f /var/ossec/logs/alerts/alerts.json | grep "Your_Pattern"
```

---

## 8️⃣ Intégration avec Elasticsearch & Kibana

### Architecture

```
Agents → Manager Wazuh → Elasticsearch → Kibana (Visualisation)
         (Collecte)      (Stockage)    (Dashboards)
```

### Installer Elasticsearch & Kibana

```bash
# Généralement fourni avec Wazuh All-in-One
# Sinon, installation manuelle :

dnf install -y elasticsearch kibana

# Démarrer services
systemctl start elasticsearch
systemctl start kibana

# Vérifier
curl -u admin:admin https://localhost:9200/_cluster/health?pretty
```

### Dashboards Kibana

```
URL : https://SOC_IP:5601
Utilisateur : elastic
Mot de passe : (défini lors install)
```

### Créer dashboard personnalisé

1. Allez sur Kibana → Create Index Pattern
2. Sélectionnez `wazuh-alerts-*`
3. Créez visualizations (graphiques)
4. Assemblez en Dashboard

---

## 9️⃣ Logs & Fichiers Importants

### Fichiers de logs Wazuh

| Fichier | Contenu |
|---------|---------|
| `/var/ossec/logs/alerts/alerts.log` | Alertes format texte |
| `/var/ossec/logs/alerts/alerts.json` | Alertes JSON |
| `/var/ossec/logs/ossec.log` | Logs du manager |
| `/var/ossec/var/run/wazuh-control.state` | État du service |

### Afficher alertes en temps réel

```bash
# Format texte
tail -f /var/ossec/logs/alerts/alerts.log

# Format JSON (mieux pour parsing)
tail -f /var/ossec/logs/alerts/alerts.json | jq '.' 

# Filtrer par sévérité
tail -f /var/ossec/logs/alerts/alerts.json | jq 'select(.rule.level >= 7)'

# Filtrer par groupe
tail -f /var/ossec/logs/alerts/alerts.json | jq 'select(.rule.groups[] == "attack.ssh")'
```

### Configuration manager

```bash
cat /var/ossec/etc/ossec.conf
```

---

## 1️⃣0️⃣ Troubleshooting Wazuh

### Agent ne se connecte pas au Manager

```bash
# 1. Vérifier firewall (port 1514)
firewall-cmd --list-ports
# Doit avoir 1514/tcp

# 2. Vérifier config agent
cat /var/ossec/etc/ossec.conf | grep -A5 "<server>"
# IP et port doivent être corrects

# 3. Redémarrer agent
systemctl restart wazuh-agent

# 4. Vérifier connexion
/var/ossec/bin/wazuh-control state

# 5. Logs agent
tail -f /var/ossec/logs/ossec.log
```

### Pas de logs collectés

```bash
# 1. Vérifier que fichiers de logs existent
ls -la /var/log/secure /var/log/messages /var/log/nginx/

# 2. Vérifier permissions (agent peut lire ?)
ls -la /var/log/secure
# Doit être readable par user ossec

# 3. Vérifier fichiers collectés dans config agent
grep -A2 "<localfile>" /var/ossec/etc/ossec.conf

# 4. Redémarrer agent après modification
systemctl restart wazuh-agent

# 5. Vérifier dans manager
/var/ossec/bin/wazuh-control agent_control -l
```

### Manager ne démarre pas

```bash
# 1. Vérifier logs
tail -50 /var/ossec/logs/ossec.log

# 2. Vérifier configuration
/var/ossec/bin/wazuh-control validate-config

# 3. Vérifier ports disponibles
ss -tulpn | grep 1514

# 4. Relancer service
systemctl restart wazuh-manager
systemctl status wazuh-manager
```

### Alertes ne s'affichent pas

```bash
# 1. Vérifier qu'agent est connecté
/var/ossec/bin/wazuh-control agent_control -l

# 2. Générer un événement test
echo "TEST ALERT" >> /var/log/messages

# 3. Attendre quelques secondes et vérifier
tail -20 /var/ossec/logs/alerts/alerts.json

# 4. Vérifier les règles
grep -c "<rule" /var/ossec/ruleset/rules/*.xml

# 5. Redémarrer manager si règles modifiées
systemctl restart wazuh-manager
```

---

## 1️⃣1️⃣ Commandes Essentielles

| Action | Commande |
|--------|----------|
| Status manager | `systemctl status wazuh-manager` |
| Status agent | `systemctl status wazuh-agent` |
| Démarrer manager | `systemctl start wazuh-manager` |
| Lister agents | `/var/ossec/bin/manage_agents -l` |
| Enregistrer agent | `/var/ossec/bin/manage_agents -a -n "name"` |
| Voir alertes | `tail -f /var/ossec/logs/alerts/alerts.json` |
| Valider config | `/var/ossec/bin/wazuh-control validate-config` |
| Agent state | `/var/ossec/bin/wazuh-control agent_control -l` |
| Voir logs manager | `tail -f /var/ossec/logs/ossec.log` |

---

## 1️⃣2️⃣ Checklist Déploiement Projet

- [ ] Manager Wazuh installé et démarré (VM SOC)
- [ ] Agents Wazuh installés sur VM web et monitoring
- [ ] Agents enregistrés et connectés
- [ ] Logs collectés (SSH, syslog, audit)
- [ ] Règles de détection créées
- [ ] Elasticsearch/Kibana en place
- [ ] Dashboards créés
- [ ] Alertes email configurées
- [ ] Test de détection (brute force SSH, etc.)
- [ ] Alertes confirmées dans interface

---

**Dernière mise à jour** : Documentation projet Mini SOC  
**Niveau** : 2e année admin systèmes & réseaux  
**Note** : Wazuh = cœur de la détection, testez bien les règles !
