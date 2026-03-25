# COMMANDES DE DIAGNOSTIC ET MAINTENANCE - Blue Team SOC

**Localisation** : À exécuter sur les VM Wazuh (Manager et Agents)  
**Prérequis** : Accès root/sudo

---

## 1. VÉRIFICATION DE L'ÉTAT DU SYSTÈME

### État général de Wazuh

```bash
# Voir si tous les services Wazuh tournent
sudo systemctl status wazuh-manager    # Sur VM SOC
sudo systemctl status wazuh-agent      # Sur VM1 et VM3

# Redémarrer le Manager en cas de problème
sudo systemctl restart wazuh-manager

# Redémarrer un Agent
sudo systemctl restart wazuh-agent
```

### Agents connectés au Manager

```bash
# Voir tous les agents et leur statut
sudo /var/ossec/bin/manage_agents -l

# Résultat attendu :
# ID Name          IP              Status Last-keepalive
# 001 VM1          192.168.1.50    Active 2024-01-15 14:30:15
# 002 VM3          192.168.1.52    Active 2024-01-15 14:30:10
```

### Santé du Manager

```bash
# Vérifier la syntaxe des règles et configuration
sudo /var/ossec/bin/wazuh-control verify-config

# Résultat attendu : "OK"

# Voir les erreurs de configuration
sudo grep -i error /var/ossec/logs/ossec.log | tail -20

# Compter les alertes générées
sudo find /var/ossec/logs/alerts -name "*.json" | wc -l
```

---

## 2. GESTION DES RÈGLES

### Vérifier les règles personnalisées

```bash
# Voir le contenu du fichier de règles
sudo cat /var/ossec/etc/rules/custom-rules.xml

# Valider la syntaxe XML
xmllint --noout /var/ossec/etc/rules/custom-rules.xml

# Voir les règles chargées en mémoire
sudo grep "custom-rules" /var/ossec/logs/ossec.log

# Compter les règles chargées
sudo grep -c "<rule" /var/ossec/etc/rules/custom-rules.xml
```

### Ajouter une règle

```bash
# Éditer le fichier (ajouter avant la balise </group> finale)
sudo nano /var/ossec/etc/rules/custom-rules.xml

# Valider
sudo /var/ossec/bin/wazuh-control verify-config

# Redémarrer si OK
sudo systemctl restart wazuh-manager

# Attendre ~5 secondes et vérifier
sudo tail -20 /var/ossec/logs/ossec.log
```

### Tester une règle rapidement

```bash
# Générer un événement test et vérifier s'il correspond
echo "Test SSH Failed password" | wazuh-regex -p "Failed password"

# Résultat : 1 = match, 0 = no match
```

---

## 3. GESTION DES LOGS

### Voir les logs en temps réel

```bash
# Logs principaux du Manager
sudo tail -f /var/ossec/logs/ossec.log

# Alertes JSON générées
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.rule | {id, level, description}'

# Logs d'un agent spécifique
sudo tail -f /var/ossec/logs/agent_logs.log | grep "001"
```

### Analyser les logs d'erreur

```bash
# Voir les erreurs récentes
sudo grep ERROR /var/ossec/logs/ossec.log | tail -10

# Erreurs liées aux règles
sudo grep -i "rule\|regex" /var/ossec/logs/ossec.log | grep -i error

# Erreurs de parsing des logs
sudo grep -i "parsing\|error.*decode" /var/ossec/logs/ossec.log
```

### Archiver/nettoyer les logs

```bash
# Voir la taille des logs
du -sh /var/ossec/logs/

# Archiver les logs anciens (>30 jours)
sudo find /var/ossec/logs -name "*.log" -mtime +30 -exec gzip {} \;

# Supprimer les archives très anciennes (>90 jours)
sudo find /var/ossec/logs -name "*.gz" -mtime +90 -delete

# Redémarrer Wazuh après suppression
sudo systemctl restart wazuh-manager
```

---

## 4. GESTION DES AGENTS

### Ajouter un nouvel agent

```bash
# Sur le Manager
sudo /var/ossec/bin/manage_agents -a

# Remplir les informations :
# - Agent name : VM2
# - IP address : 192.168.1.51
# - Valid (y/n) : y

# Voir l'ID assigné
sudo /var/ossec/bin/manage_agents -l
```

### Installer l'agent sur une nouvelle VM

```bash
# 1. Télécharger le package (depuis repo Wazuh)
sudo apt install -y wazuh-agent

# 2. Configurer le Manager IP
sudo nano /var/ossec/etc/ossec.conf
# Modifier la section <client>:
# <manager_ip>192.168.1.52</manager_ip>

# 3. Enregistrer l'agent avec la clé
sudo /var/ossec/bin/wazuh-control -i <KEY_FROM_MANAGER>

# 4. Démarrer l'agent
sudo systemctl start wazuh-agent
sudo systemctl enable wazuh-agent

# 5. Vérifier sur le Manager
sudo /var/ossec/bin/manage_agents -l
```

### Supprimer un agent déconnecté

```bash
# Voir les agents inactifs
sudo /var/ossec/bin/manage_agents -l | grep Disconnected

# Supprimer un agent par ID (ex: 002)
sudo /var/ossec/bin/manage_agents -r 002

# Valider (y)

# Redémarrer Wazuh
sudo systemctl restart wazuh-manager
```

---

## 5. GESTION DES ALERTES

### Voir les alertes récentes

```bash
# Alertes des 5 dernières minutes
sudo jq '.rule.id as $id | select($id > 0) | {timestamp: .timestamp, rule: $id, level: .rule.level, description: .rule.description}' \
  /var/ossec/logs/alerts/alerts.json | tail -20

# Alertes par sévérité
sudo grep -o '"level":[0-9]*' /var/ossec/logs/alerts/alerts.json | sort | uniq -c

# Alertes par règle
sudo grep -o '"id":[0-9]*' /var/ossec/logs/alerts/alerts.json | sort | uniq -c | sort -rn
```

### Filtrer les alertes

```bash
# Toutes les alertes niveau 10 (critique)
sudo jq 'select(.rule.level == 10)' /var/ossec/logs/alerts/alerts.json

# Alertes de la règle 100001 (Brute Force)
sudo jq 'select(.rule.id == 100001)' /var/ossec/logs/alerts/alerts.json

# Alertes des 2 dernières heures
sudo find /var/ossec/logs/alerts -newer /tmp/reference_time.txt -exec cat {} \; | jq .

# Alertes d'une IP source spécifique
sudo grep "192.168.1.100" /var/ossec/logs/alerts/alerts.json | jq .
```

### Exporter les alertes

```bash
# Exporter toutes les alertes en CSV
sudo jq -r '[.timestamp, .rule.id, .rule.level, .rule.description, .agent.id] | @csv' \
  /var/ossec/logs/alerts/alerts.json > alertes_export.csv

# Exporter en JSON formaté
sudo cp /var/ossec/logs/alerts/alerts.json alertes_backup.json
sudo chown $USER alertes_backup.json
jq '.' alertes_backup.json > alertes_formatted.json

# Imprimer un rapport texte
sudo jq -r 'select(.rule.id > 100000) | "\(.timestamp) | Rule: \(.rule.id) | Level: \(.rule.level) | \(.rule.description)"' \
  /var/ossec/logs/alerts/alerts.json > rapport_alertes.txt
```

---

## 6. GESTION DE LA BASE DE DONNÉES (Elasticsearch)

### État du cluster Elasticsearch

```bash
# Vérifier que Elasticsearch tourne
sudo systemctl status elasticsearch

# Vérifier la santé du cluster
curl -s http://localhost:9200/_cluster/health | jq .

# Résultat attendu :
# "status": "green"
# "number_of_nodes": 1
```

### Voir les indices

```bash
# Lister tous les indices
curl -s http://localhost:9200/_cat/indices?v

# Voir la taille des indices
curl -s http://localhost:9200/_cat/indices?v&h=index,store.size

# Exemple :
# wazuh-alerts-4.x-2024.01.15  500MB
# wazuh-alerts-4.x-2024.01.14  480MB
```

### Archiver les anciens indices

```bash
# Supprimer les indices de plus de 30 jours
for index in $(curl -s http://localhost:9200/_cat/indices?h=i | grep 2023); do
  curl -X DELETE "localhost:9200/$index"
done

# Note : À faire avec prudence !
```

---

## 7. GESTION DE FIREWALLD

### État du pare-feu

```bash
# Sur VM1 (Serveur Web)
sudo systemctl status firewalld

# Voir les règles actives
sudo firewall-cmd --list-all

# Voir les ports ouverts
sudo firewall-cmd --list-ports
```

### Activer le logging des connexions refusées

```bash
# Configurer firewalld pour logger toutes les connexions refusées
sudo firewall-cmd --set-log-denied=all --permanent
sudo firewall-cmd --reload

# Vérifier
sudo firewall-cmd --get-log-denied

# Voir les logs
sudo tail -f /var/log/firewalld
```

---

## 8. GESTION D'AUDITD

### État d'auditd

```bash
# Vérifier qu'auditd tourne
sudo systemctl status auditd

# Voir les règles de surveillance actuelles
sudo auditctl -l

# Nombre de règles chargées
sudo auditctl -l | wc -l
```

### Ajouter une règle d'audit

```bash
# Surveiller la commande cat sur /etc/shadow
sudo auditctl -w /etc/shadow -p wa -k shadow_access

# Surveiller les commandes sudo
sudo auditctl -a always,exit -F arch=b64 -S execve -F exe=/usr/bin/sudo -k sudo_exec

# Vérifier
sudo auditctl -l | grep shadow
sudo auditctl -l | grep sudo
```

### Voir les événements audit

```bash
# Voir les 20 derniers événements
sudo ausearch -ts recent | tail -100

# Chercher les événements d'un utilisateur
sudo ausearch -u attacker

# Chercher les commandes exécutées
sudo ausearch -m EXECVE | tail -20

# Générer un rapport
aureport -c --summary
```

---

## 9. COMMANDES RÉSEAU

### Vérifier la connectivité

```bash
# Depuis Machine Attaquante vers VM1
ping -c 3 192.168.1.50

# Tester la connectivité SSH
nc -zv 192.168.1.50 2222

# Scan de port simple
nmap -sV -p 22,80,443 192.168.1.50
```

### Voir les connexions réseau

```bash
# Connexions actives sur VM1
sudo ss -tlnp | grep LISTEN

# Connexions établies
sudo ss -tnp | grep ESTABLISHED

# État de la connexion SSH
sudo ss -tnp | grep sshd
```

### Tester les règles de firewall

```bash
# Depuis une machine externe
telnet 192.168.1.50 22

# Voir les logs de rejet
sudo tail -f /var/log/firewalld | grep REJECT
```

---

## 10. PERFORMANCES ET OPTIMISATION

### Vérifier l'utilisation des ressources

```bash
# RAM et CPU
top -b -n 1 | head -20

# Disque
df -h /var/ossec
du -sh /var/ossec/*

# I/O disque
iostat -x 1 5
```

### Optimiser Wazuh

```bash
# Augmenter la limite d'alertes si trop d'événements
sudo sed -i 's/<alert_format>.*<\/alert_format>/<alert_format>json<\/alert_format>/g' /var/ossec/etc/ossec.conf

# Réduire la fréquence de vérification
sudo sed -i 's/<update_check>.*<\/update_check>/<update_check>no<\/update_check>/g' /var/ossec/etc/ossec.conf

# Augmenter la taille de la queue des alertes
sudo sed -i 's/<queue_size>.*<\/queue_size>/<queue_size>200000<\/queue_size>/g' /var/ossec/etc/ossec.conf

# Redémarrer
sudo systemctl restart wazuh-manager
```

---

## 11. DÉPANNAGE COURANT

### Les alertes ne s'affichent pas dans Wazuh

```bash
# 1. Vérifier que les agents envoient des logs
sudo tail -20 /var/ossec/logs/ossec.log | grep "agent.*connected"

# 2. Vérifier que les logs source existent
sudo ls -la /var/log/secure
sudo ls -la /var/log/audit/audit.log

# 3. Vérifier la configuration de l'agent
sudo grep -A 5 "<localfile>" /var/ossec/etc/ossec.conf | head -20

# 4. Redémarrer l'agent
sudo systemctl restart wazuh-agent
```

### Elasticsearch consomme trop de RAM

```bash
# Réduire la RAM allouée à Elasticsearch
sudo nano /etc/elasticsearch/jvm.options

# Changer (exemple) :
# -Xms512m
# -Xmx512m

# Redémarrer
sudo systemctl restart elasticsearch
```

### Les règles ne se chargent pas

```bash
# 1. Vérifier la syntaxe
sudo /var/ossec/bin/wazuh-control verify-config

# 2. Voir les erreurs
sudo grep -i "error\|rule" /var/ossec/logs/ossec.log | grep -i custom

# 3. Recharger les règles
sudo systemctl restart wazuh-manager

# 4. Attendre le chargement
sleep 5
sudo grep "custom-rules" /var/ossec/logs/ossec.log
```

### Un agent se déconnecte constamment

```bash
# 1. Vérifier la connectivité
ping 192.168.1.50

# 2. Vérifier la configuration de l'agent
sudo cat /var/ossec/etc/ossec.conf | grep -A 2 "<client>"

# 3. Vérifier les logs d'erreur
sudo tail -50 /var/ossec/logs/ossec.log | grep "Agent"

# 4. Réinitialiser la clé de l'agent
sudo /var/ossec/bin/manage_agents -r <AGENT_ID>  # Sur Manager
sudo rm -f /var/ossec/etc/client.keys              # Sur Agent
sudo systemctl restart wazuh-agent                 # Sur Agent
```

---

## 12. SCRIPTS PRATIQUES

### Script de vérification automatique

```bash
#!/bin/bash
# save as: /home/admin/check_soc.sh

echo "=== CHECK BLUE TEAM SOC ==="
echo ""

echo "1. État du Manager"
sudo systemctl is-active wazuh-manager

echo ""
echo "2. Agents connectés"
sudo /var/ossec/bin/manage_agents -l | grep "Active" | wc -l

echo ""
echo "3. Alertes des 5 dernières minutes"
find /var/ossec/logs/alerts -newer /tmp/ref_5min -exec wc -l {} \; | awk '{s+=$1} END {print s}'

echo ""
echo "4. Erreurs dans les logs"
sudo grep ERROR /var/ossec/logs/ossec.log | tail -1

echo ""
echo "5. Utilisation du disque"
du -sh /var/ossec | awk '{print $1}'
```

Utilisation :

```bash
chmod +x /home/admin/check_soc.sh
./check_soc.sh
```

### Script d'export des alertes

```bash
#!/bin/bash
# save as: /home/admin/export_alerts.sh

BACKUP_DIR="/home/admin/backup_alerts"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Export des alertes en cours..."

# Exporter JSON
sudo cp /var/ossec/logs/alerts/alerts.json \
  $BACKUP_DIR/alerts_$TIMESTAMP.json

# Exporter CSV
sudo jq -r '[.timestamp, .rule.id, .rule.level, .rule.description] | @csv' \
  /var/ossec/logs/alerts/alerts.json > \
  $BACKUP_DIR/alerts_$TIMESTAMP.csv

echo "Export terminé : $BACKUP_DIR/alerts_$TIMESTAMP.*"
```

---

## 13. CHECKLIST MAINTENANCE HEBDOMADAIRE

```bash
# Chaque semaine, exécuter :

# 1. Vérifier l'état général
sudo /var/ossec/bin/wazuh-control verify-config

# 2. Nettoyer les logs anciens
sudo find /var/ossec/logs -name "*.log" -mtime +30 -exec gzip {} \;

# 3. Vérifier les disques
df -h | grep -E "var|home"

# 4. Revoir les alertes de la semaine
sudo jq '.rule.level' /var/ossec/logs/alerts/alerts.json | sort -n | uniq -c

# 5. Vérifier les agents inactifs
sudo /var/ossec/bin/manage_agents -l | grep -v Active

# 6. Archiver les alertes
sudo tar -czf /backup/alerts_backup_$(date +%Y%m%d).tar.gz /var/ossec/logs/alerts/
```

---

## 14. CONTACT ET SUPPORT

**Documentation Wazuh officielle** : https://documentation.wazuh.com/  
**Forum communautaire** : https://github.com/wazuh/wazuh/discussions  
**Issues/Bugs** : https://github.com/wazuh/wazuh/issues  

**Pour ce projet** :  
- Équipe SOC : [à remplir]  
- Responsable Technique : [à remplir]  
- Dernier update : 2024-01-15

