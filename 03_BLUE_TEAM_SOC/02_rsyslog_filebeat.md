# 02 - Centralisation avec rsyslog et Filebeat

## 🎯 Objectif de cette étape

Configurer l'envoi de tous les logs du serveur web vers la **VM SOC**, pour qu'un attaquant ne puisse pas effacer les preuves en local.

**Durée estimée** : 1 heure 30 minutes

---

## 📋 Concept : Deux approches, un résultat

Il existe deux outils pour centraliser les logs. À toi de choisir selon le niveau souhaité.

### Approche 1 : rsyslog (simple, robuste, préinstallé)

```
Avantages:
+ Léger et préinstallé sur Rocky Linux
+ Configuration simple en quelques lignes
+ Parfait pour apprendre
+ Moins de dépendances

Inconvénients:
- Pas de parsing avancé
- Moins d'options de transport
```

### Approche 2 : Filebeat (moderne, flexible, puissant)

```
Avantages:
+ Intégration native Elasticsearch/Wazuh
+ Parsing et enrichissement des logs
+ Transport sécurisé TLS simple
+ Idéal pour production

Inconvénients:
- Installation supplémentaire
- Plus complexe à déboguer
- Consomme plus de ressources
```

**Choix recommandé pour ce projet** : Commencer avec **rsyslog** (plus simple), puis migrer vers **Filebeat** si tu veux pousser plus loin.

---

## 1. Approche A : rsyslog (Simple)

### 1.1 Vérifier que rsyslog est installé et actif

```bash
# Vérifier l'installation
rpm -qa | grep rsyslog

# Vérifier le service
systemctl status rsyslog
systemctl is-enabled rsyslog
```

**Résultat attendu**
```
rsyslog-8.2102.0-1.el9.x86_64
● rsyslog.service - System Logging Service
   Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled)
   Active: active (running)
```

Si rsyslog n'est pas actif, le démarrer :
```bash
systemctl start rsyslog
systemctl enable rsyslog
```

---

### 1.2 Comprendre la configuration rsyslog

**Fichier principal**
```
/etc/rsyslog.conf
```

**Structure d'une règle rsyslog**
```
selector   action
│          │
facility.priority  /path/to/file
```

Exemples :
```
# Tous les messages de tous les services, niveau info et plus → fichier local
*.info                                    /var/log/messages

# Messages SSH, tous les niveaux → fichier spécifique
auth.*                                    /var/log/secure

# Messages d'erreur critiques → envoyer vers serveur SOC
*.crit                                    @SOC_IP:514
```

**Que signifient les symboles ?**
- `@SOC_IP:514` → envoyer vers le serveur SOC en **UDP** (connexion simple)
- `@@SOC_IP:514` → envoyer vers le serveur SOC en **TCP** (plus fiable)

---

### 1.3 Ajouter la centralisation des logs

**Étape 1 : Sauvegarder la config originale**
```bash
sudo cp /etc/rsyslog.conf /etc/rsyslog.conf.backup
```

**Étape 2 : Éditer le fichier de configuration**

```bash
sudo vi /etc/rsyslog.conf
```

**À ajouter à la fin du fichier** (avant la ligne `$IncludeConfig /etc/rsyslog.d/*.conf` s'il existe) :

```conf
#############################################
# Centralisation vers VM SOC
#############################################

# Envoyer TOUS les logs vers le serveur SOC
# Remplacer SOC_IP par l'IP réelle (ex: 192.168.1.20)
# Remplacer SERVEUR_NAME par le nom de ton serveur (ex: web01)
# Format : @@DEST_IP:PORT (TCP) ou @DEST_IP:PORT (UDP)

# Option 1 : UDP (plus simple, moins sûr)
*.* @192.168.1.20:514

# Option 2 : TCP (plus sûr, légèrement plus lent)
# *.* @@192.168.1.20:514

# Optionnel : marquer les messages avec le nom du serveur
$ActionFileDefaultTemplate RSYSLOG_FileFormat
$Hostname web01
```

**À la place de** :
- `192.168.1.20` → IP réelle de ta VM SOC
- `web01` → nom de ton serveur (pour identifier d'où vient le log)
- `514` → port standard syslog (à ouvrir dans le firewall)

**Exemple complet**
```conf
# ...contenu existant...

# =========================
# Centralisation vers SOC
# =========================
*.* @@192.168.1.20:514
```

**Étape 3 : Vérifier la syntaxe**

```bash
# Valider la configuration
sudo rsyslogd -N1
```

**Résultat attendu**
```
rsyslogd: version 8.2102.0, config validation run (level 0), master config /etc/rsyslog.conf
rsyslogd: End of config validation run. Syntax OK.
```

Si erreur : revoir les modifications et relancer `rsyslogd -N1`.

**Étape 4 : Redémarrer rsyslog**

```bash
sudo systemctl restart rsyslog
sudo systemctl status rsyslog
```

**Résultat attendu** : `Active: active (running)`

---

### 1.4 Vérifier que les logs sortent

**Sur le serveur web, créer un message de test**

```bash
# Envoyer un message test directement dans syslog
sudo logger -t rsyslog-test "Ceci est un message de test depuis le serveur web"

# Vérifier qu'il est bien dans les logs locaux
grep "rsyslog-test" /var/log/messages
```

**Résultat attendu**
```
Jan 15 11:00:00 web01 rsyslog-test: Ceci est un message de test depuis le serveur web
```

---

### 1.5 Tester la centralisation (depuis la VM SOC)

**Sur la VM SOC, écouter le port 514**

```bash
# Installer netcat si nécessaire
sudo yum install ncat

# Écouter sur UDP 514 (temporaire, pour test)
sudo ncat -u -l 514
```

**Retour au serveur web : générer des logs**
```bash
logger -t test-web "Premier message de test"
logger -t test-web "Deuxième message de test"
```

**Sur la VM SOC** (la fenêtre ncat), tu devrais voir :
```
<30>Jan 15 11:05:00 web01 test-web: Premier message de test
<30>Jan 15 11:05:01 web01 test-web: Deuxième message de test
```

Si tu vois ces messages → **Bravo ! Les logs sont centralisés.**

Si rien n'apparaît → voir la section Troubleshooting.

---

## 2. Approche B : Filebeat (Moderne)

### 2.1 Installation de Filebeat

**Télécharger et installer**

```bash
# Télécharger la version compatible Rocky 9
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.10.0-x86_64.rpm

# Installer
sudo rpm -ivh filebeat-8.10.0-x86_64.rpm

# Vérifier
filebeat version
```

**Résultat attendu**
```
filebeat version 8.10.0
```

---

### 2.2 Configurer Filebeat

**Fichier de configuration**
```
/etc/filebeat/filebeat.yml
```

**Sauvegarder l'original**
```bash
sudo cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.backup
```

**Éditer la configuration**

```bash
sudo vi /etc/filebeat/filebeat.yml
```

**Ajouter/modifier la section `filebeat.inputs`** (chercher la ligne existante et modifier) :

```yaml
filebeat.inputs:

# Input 1: SSH logs
- type: log
  enabled: true
  paths:
    - /var/log/secure
  fields:
    log_type: ssh
  
# Input 2: Nginx access logs
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
  fields:
    log_type: nginx_access

# Input 3: Nginx error logs
- type: log
  enabled: true
  paths:
    - /var/log/nginx/error.log
  fields:
    log_type: nginx_error

# Input 4: System logs
- type: log
  enabled: true
  paths:
    - /var/log/messages
  fields:
    log_type: system

# Input 5: Audit logs (optionnel, plus détaillé)
- type: log
  enabled: true
  paths:
    - /var/log/audit/audit.log
  fields:
    log_type: audit
```

**Modifier la section `output.logstash`** ou `output.elasticsearch` (selon ta destination) :

**Option A : Envoyer vers Logstash/Wazuh**
```yaml
output.logstash:
  enabled: true
  hosts: ["192.168.1.20:5000"]
  ssl.enabled: false
  # ou avec TLS:
  # ssl.enabled: true
  # ssl.certificate_authorities: ["/path/to/ca.crt"]
```

**Option B : Envoyer vers Elasticsearch**
```yaml
output.elasticsearch:
  enabled: true
  hosts: ["192.168.1.20:9200"]
  index: "filebeat-logs-%{+yyyy.MM.dd}"
  username: "elastic"
  password: "your_password_here"
```

---

### 2.3 Tester et démarrer Filebeat

**Valider la configuration**

```bash
sudo filebeat test config -c /etc/filebeat/filebeat.yml
```

**Résultat attendu**
```
Config OK
```

**Tester la connexion à la destination**

```bash
sudo filebeat test output -c /etc/filebeat/filebeat.yml
```

**Résultat attendu**
```
logstash: 192.168.1.20:5000...
  connection...
  parse resolv.conf...
    Successfully contacted logstash at 192.168.1.20:5000
```

**Démarrer Filebeat**

```bash
sudo systemctl start filebeat
sudo systemctl enable filebeat
sudo systemctl status filebeat
```

**Vérifier que les logs sont envoyés**

```bash
sudo journalctl -u filebeat -n 50
```

**Résultat attendu** (tu devrais voir des messages comme) :
```
filebeat[1234]: Successfully published 25 events
filebeat[1234]: Metrics (period=30s)...
```

---

## 3. Comparaison : rsyslog vs Filebeat

| Aspect | rsyslog | Filebeat |
|--------|---------|----------|
| **Installation** | Préinstallé ✓ | À installer |
| **Complexité** | Simple (2-3 lignes) | Modérée (YAML) |
| **Transport** | UDP/TCP basique | TCP/TLS avancé |
| **Parsing** | Minimal | Riche (Grok patterns) |
| **Wazuh** | Fonctionne | Natif avec Filebeat |
| **Apprentissage** | Rapide | Plus long |

**Recommandation** : Commence avec rsyslog pour comprendre, bascule vers Filebeat pour aller plus loin.

---

## 4. Vérifications pratiques

### Checklist rsyslog

- [ ] rsyslog est installé et actif (`systemctl status rsyslog`)
- [ ] Config modifiée (`grep "@.*SOC" /etc/rsyslog.conf`)
- [ ] Syntaxe validée (`rsyslogd -N1` retourne OK)
- [ ] Service redémarré
- [ ] Message de test apparaît sur SOC (`logger` + écoute ncat)

### Checklist Filebeat

- [ ] Filebeat installé (`filebeat version`)
- [ ] Config YAML correcte (indentation, syntaxe)
- [ ] Test config réussi (`filebeat test config`)
- [ ] Test output réussi (`filebeat test output`)
- [ ] Service démarré et actif
- [ ] Logs visibles dans la destination (Logstash/Elasticsearch)

---

## 5. Troubleshooting

### Problème : "Connection refused" sur le port 514

**Cause possible** : Le serveur SOC n'écoute pas sur le port 514.

**Solution**
```bash
# Sur la VM SOC, vérifier que quelque chose écoute
sudo netstat -tuln | grep 514
sudo ss -tuln | grep 514

# Si rien, démarrer un listener de test
sudo ncat -u -l 192.168.1.20 514
```

---

### Problème : Les logs s'envoient mais arrivent vides/corrompus

**Cause possible** : Format incompatible ou chemin mal configuré.

**Solution**
```bash
# Vérifier que rsyslog lit bien les fichiers
sudo tail -f /var/log/secure

# Vérifier les permissions
ls -l /var/log/secure
ls -l /var/log/nginx/

# Si permission denied, ajouter l'utilisateur rsyslog au groupe
sudo usermod -a -G adm rsyslog
sudo systemctl restart rsyslog
```

---

### Problème : Filebeat affiche "Failed to start: permission denied"

**Cause possible** : Fichiers log non accessibles par l'utilisateur filebeat.

**Solution**
```bash
# Ajouter l'utilisateur filebeat au groupe adm (pour les logs système)
sudo usermod -a -G adm filebeat

# Vérifier les permissions des fichiers de config
ls -l /etc/filebeat/filebeat.yml
sudo chown root:filebeat /etc/filebeat/filebeat.yml
sudo chmod 640 /etc/filebeat/filebeat.yml

# Redémarrer
sudo systemctl restart filebeat
```

---

### Problème : Les logs arrivent mais mélangés ou hors ordre

**Cause** : Normal avec UDP (non-garanti). Passer à TCP.

**Solution rsyslog**
```conf
# Changer cette ligne
*.* @192.168.1.20:514

# En celle-ci (TCP, plus sûr)
*.* @@192.168.1.20:514
```

**Solution Filebeat** : Utiliser TLS dans la config YAML.

---

## 6. Activité : Générer des logs pour tester

**Scénario 1 : Brute force SSH (5 tentatives échouées)**
```bash
for i in {1..5}; do
  ssh baduser@localhost 2>/dev/null || true
done

# Vérifier sur la SOC
grep "baduser" /var/log/secure
```

**Scénario 2 : Accès web divers**
```bash
curl http://localhost/              # 200 OK
curl http://localhost/admin/        # 403 Forbidden
curl http://localhost/not-found     # 404 Not Found
curl -X POST http://localhost/upload -d "bigdata..." # 413 Payload too large
```

**Scénario 3 : Commande suspecte (audit)**
```bash
# Si auditd est configuré
touch /tmp/.hidden
chmod 755 /tmp/.hidden
```

Tous ces événements devraient apparaître sur la VM SOC.

---

## ✅ Prêt pour l'étape suivante ?

Une fois que tu as validé une approche (rsyslog OU Filebeat), tu es prêt pour :

**Étape suivante (03_transport_logs.md)** : Sécuriser le transport des logs avec TLS/SSL et certificats.

---

## 📚 Ressources rapides

### Commandes de déboggage rsyslog

```bash
# Voir les logs en temps réel
sudo tail -f /var/log/messages

# Afficher la config active
sudo rsyslogd -d -n | head -50

# Tester une règle spécifique
logger -p local0.info "Test message"
```

### Commandes de déboggage Filebeat

```bash
# Voir les logs de démarrage
sudo journalctl -u filebeat -n 100

# Mode de débogage (verbose)
sudo filebeat run -e -d "*"

# Vérifier les fichiers monitorés
sudo filebeat modules list
sudo filebeat export config
```

### Variables d'environnement utiles

```bash
# Pour rsyslog
$HOSTNAME     # nom du serveur
$TIMESTAMP    # timestamp de l'événement
$TAG          # tag du message

# Pour Filebeat (dans filebeat.yml)
# Ajouter des champs personnalisés
fields:
  server_name: web01
  environment: production
  team: blue-team
```
