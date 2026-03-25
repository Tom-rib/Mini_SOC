# Wazuh Agents - Installation et enregistrement

**Objectif du chapitre :** Installer les agents Wazuh sur VM 1 (Serveur Web) et VM 3 (Monitoring)

**Durée estimée :** 1 heure par agent

**Prérequis :**
- Wazuh Manager opérationnel sur VM 2 (voir chapitre précédent)
- IP du Manager : à noter
- VM cible : Rocky Linux 8/9
- Accès root ou sudo
- Connexion réseau vers Manager (port 1514)

---

## 1. Concepts clés

### Qu'est-ce qu'un agent ?

Un agent Wazuh est un **client léger** qui :
- Lit les fichiers logs locaux
- Les envoie au Manager (port 1514)
- Exécute les réponses aux incidents

### Processus d'enregistrement

Pour qu'un agent puisse se connecter au Manager, il doit d'abord être **enregistré**.

**Étapes :**
1. Générer une clé d'authentification unique
2. La copier sur l'agent
3. L'agent utilise cette clé pour se connecter

### ID et clés d'agents

Chaque agent a :
- **ID unique** : 001, 002, 003, etc.
- **Clé d'authentification** : chaîne chiffrée + secret

Exemple :
```
Agent 001:
  Name: server-web
  ID: 001
  Key: MDAxIHNlcnZlci13ZWIgMTkyLjE2OC4xLjEwMCBhZmMxYTkyYjA2MmYx...
```

---

## 2. Préparation du Manager (enregistrement)

### Étape 1 : Se connecter au Manager

```bash
# Sur VM 2 (Manager)
ssh user@IP_MANAGER
```

### Étape 2 : Générer une clé d'agent

Utilise l'outil `wazuh-authd` pour enregistrer un nouvel agent :

```bash
sudo /var/ossec/bin/agent-auth -m IP_MANAGER -A AGENT_NAME
```

Remplace :
- `IP_MANAGER` : IP de VM 2 (ex: 192.168.1.50)
- `AGENT_NAME` : nom du serveur (ex: server-web, vm3-monitoring)

**Exemple complet :**

Pour VM 1 (Serveur Web) :

```bash
sudo /var/ossec/bin/agent-auth -m 192.168.1.50 -A server-web
```

**Résultat attendu :**
```
Trying to register agent...
Generating agent key ...
Creating agent key file...
Agent key created successfully...
```

### Étape 3 : Voir tous les agents enregistrés

```bash
sudo /var/ossec/bin/manage_agents
```

**Menu interactif :**
```
Wazuh Agent manager
Options:
  a) Add agent
  e) Edit agent
  r) Remove agent
  l) List agents
  q) Quit
Choose an option: l
```

Sélectionne `l` pour lister :

```
ID: 000 Name: manager IP: 127.0.0.1
ID: 001 Name: server-web IP: 192.168.1.10
ID: 002 Name: vm3-monitoring IP: 192.168.1.30
```

---

## 3. Installation de l'agent sur la machine cible

### Étape 1 : Se connecter à la VM cible

Sur VM 1 (Serveur Web) :

```bash
ssh user@192.168.1.10
```

### Étape 2 : Ajouter le dépôt Wazuh

```bash
sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
sudo tee /etc/yum.repos.d/wazuh.repo > /dev/null <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
```

### Étape 3 : Installer le package agent

```bash
sudo dnf install -y wazuh-agent-4.7.0
```

**Résultat attendu :**
```
Installed:
  wazuh-agent-4.7.0-1.x86_64
```

---

## 4. Configuration de l'agent

### Éditer le fichier de configuration

```bash
sudo nano /var/ossec/etc/ossec.conf
```

**Section cruciale `<client>` :**

Cherche cette section et complète l'IP du Manager :

```xml
<client>
  <server>
    <address>192.168.1.50</address>  <!-- IP Manager -->
    <port>1514</port>
    <protocol>tcp</protocol>
  </server>
  <config>
    <auto_restart>yes</auto_restart>
  </config>
</client>
```

**Valeurs à ajuster :**
- `<address>` : IP de ton Manager (VM 2)
- `<port>` : 1514 (standard)
- `<protocol>` : tcp ou udp (tcp recommandé)

**Sauve** : Ctrl+O → Enter → Ctrl+X

### Vérifier les permissions

```bash
sudo chown wazuh:wazuh /var/ossec/etc/ossec.conf
sudo chmod 640 /var/ossec/etc/ossec.conf
```

---

## 5. Démarrage et activation de l'agent

### Activer le démarrage automatique

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
```

### Démarrer l'agent

```bash
sudo systemctl start wazuh-agent
```

### Vérifier que l'agent est actif

```bash
sudo systemctl status wazuh-agent
```

**Résultat attendu :**
```
● wazuh-agent.service - Wazuh Agent
   Loaded: loaded (/usr/lib/systemd/system/wazuh-agent.service; enabled; ...)
   Active: active (running) since Mon 2024-02-06 11:20:00 UTC; 10s ago
```

### Vérifier la connexion au Manager

```bash
sudo ss -tuln | grep -E ':1514|:1515'
```

Résultat : La connexion sort vers le Manager sur port 1514.

---

## 6. Vérification depuis le Manager

### Sur VM 2 (Manager), vérifier que l'agent s'est connecté

```bash
sudo /var/ossec/bin/manage_agents
```

Sélectionne `l` (List) :

```
ID: 001 Name: server-web IP: 192.168.1.10 (Active)
```

**Status doit être "Active"**.

### Voir les connexions actives

```bash
sudo ss -tuln | grep 1514
```

```
tcp        0      0 0.0.0.0:1514            0.0.0.0:*               LISTEN
```

### Vérifier les logs d'enregistrement

```bash
sudo tail -20 /var/ossec/logs/ossec.log | grep 001
```

Résultat :
```
2024-02-06T11:20:15.123456+00:00 manager wazuh: Agent 001 (server-web) is now active.
```

---

## 7. Synchronisation des clés d'authentification

### Si l'agent ne se connecte pas (cas courant)

**Problème :** Les clés ne correspondent pas entre Manager et Agent.

**Solution : Réenregistrer l'agent**

Sur le Manager :

```bash
# Arrêter le service Manager
sudo systemctl stop wazuh-manager

# Supprimer la clé de l'agent
sudo rm /var/ossec/etc/client.keys.org
sudo /var/ossec/bin/agent_control -r 001  # où 001 = ID de l'agent

# Redémarrer
sudo systemctl start wazuh-manager
```

Sur l'Agent (VM cible) :

```bash
# Arrêter l'agent
sudo systemctl stop wazuh-agent

# Supprimer les clés locales
sudo rm /var/ossec/etc/client.keys
sudo rm /var/ossec/etc/client.key
sudo rm -rf /var/ossec/etc/ssl/certs/*

# Redémarrer
sudo systemctl start wazuh-agent
```

---

## 8. Tests de connectivité

### Test 1 : Vérifier les sockets

Sur l'Agent :

```bash
sudo ss -tuln | grep wazuh
```

Doit montrer une connexion ESTABLISHED vers l'IP du Manager.

### Test 2 : Générer un log test

```bash
echo "Test alert from $(hostname)" >> /var/log/messages
```

Puis sur le Manager, vérifier qu'il a reçu le message :

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json | grep -i test
```

### Test 3 : Vérifier les logs locaux de l'agent

```bash
sudo tail -20 /var/ossec/logs/ossec.log
```

Résultat idéal :
```
2024-02-06T11:25:30.456789+00:00 server-web wazuh-agent: info: Connected to the server (192.168.1.50:1514).
```

---

## 9. Répéter pour les autres VMs

Répète les étapes 1 à 8 pour chaque VM supplémentaire (VM 3, etc.)

### Checklist pour chaque nouvel agent :

- ✅ Enregistrement sur le Manager (`manage_agents`)
- ✅ Installation du package (`dnf install wazuh-agent`)
- ✅ Configuration de l'IP du Manager (`/var/ossec/etc/ossec.conf`)
- ✅ Démarrage du service (`systemctl start wazuh-agent`)
- ✅ Vérification du statut Active (`manage_agents` ou Dashboard)

---

## 10. Vue globale dans le Dashboard

Une fois tous les agents connectés :

1. Va sur `https://IP_MANAGER:443/app/wazuh`
2. Menu gauche → **Agents**
3. Tous les agents doivent afficher **"Active"**

```
Agents actifs
  001 - server-web       ✅ Active
  002 - vm3-monitoring   ✅ Active
  000 - manager          ✅ Active
```

---

## 11. Dépannage courant

### Problème 1 : Agent en status "Disconnected"

**Symptôme :**
```
ID: 001 Name: server-web IP: 192.168.1.10 (Disconnected)
```

**Causes possibles :**
1. Firewall bloque port 1514
2. IP du Manager est incorrecte
3. Service wazuh-agent n'est pas démarré

**Solutions :**
```bash
# Sur l'agent :
sudo systemctl restart wazuh-agent

# Vérifier la config
grep -A3 "<client>" /var/ossec/etc/ossec.conf

# Tester la connectivité
telnet 192.168.1.50 1514

# Vérifier le firewall
sudo firewall-cmd --list-all
# Ajouter la règle si besoin :
sudo firewall-cmd --add-port=1514/tcp --permanent
sudo firewall-cmd --reload
```

### Problème 2 : Erreur "Client key already in use"

**Symptôme :**
```
Client key already in use. Exiting.
```

**Solution :**
```bash
# Sur le Manager : supprimer la clé
sudo /var/ossec/bin/manage_agents
# Choisir "Remove agent" (r), puis enregistrer à nouveau
```

### Problème 3 : Permission denied sur les logs

**Symptôme :**
```
ERROR: Unable to open log file
```

**Solution :**
```bash
# Sur l'agent :
sudo chown wazuh:wazuh /var/ossec/logs -R
sudo chmod 750 /var/ossec -R
```

---

## 📚 Résumé des commandes clés

| Commande | Lieu | Rôle |
|----------|------|------|
| `sudo /var/ossec/bin/agent-auth -m IP -A NAME` | Manager | Enregistrer agent |
| `sudo /var/ossec/bin/manage_agents` | Manager | Gérer agents |
| `sudo dnf install wazuh-agent` | Agent | Installer agent |
| `sudo systemctl start wazuh-agent` | Agent | Démarrer agent |
| `sudo systemctl status wazuh-agent` | Agent | Vérifier agent |
| `grep -A3 "<client>" /var/ossec/etc/ossec.conf` | Agent | Vérifier config |

---

## 💡 Mémo d'architecture

```
Manager (VM2) ← Port 1514 ← Agent 001 (VM1)
                          ← Agent 002 (VM3)
                          ← ...
```

Chaque agent envoie ses logs vers le Manager sur le port 1514.

---

**Fin du chapitre 3 - Installation Agents**

Une fois tous les agents "Active" dans le Dashboard, tu es prêt pour configurer les sources de logs.
