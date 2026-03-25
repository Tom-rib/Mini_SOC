# 👥 3. Les Rôles et Organisation de l'Équipe

**Durée de lecture estimée** : 20 minutes  
**Concepts clés** : Responsabilités, livrables, communication inter-rôles  
**Prérequis** : Avoir lu [`01_contexte_objectifs.md`](01_contexte_objectifs.md) et [`02_architecture_schema.md`](02_architecture_schema.md)

---

## 🎬 Vue d'Ensemble des Rôles

```
┌────────────────────────────────────────────────────────────────┐
│                   ÉQUIPE SOC (3 PERSONNES)                     │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│ RÔLE 1 (Admin)     │  RÔLE 2 (SOC)      │  RÔLE 3 (IR)       │
│ └─ Hardening       │  └─ Détection      │  └─ Réaction       │
│                    │                    │                    │
│ Travaille          │ Travaille          │ Travaille          │
│ AVANT l'attaque    │ PENDANT l'attaque  │ APRÈS l'attaque    │
│                    │                    │                    │
│ Prévention         │ Détection          │ Correction         │
│ (Prevention)       │ (Detection)        │ (Response)         │
│                    │                    │                    │
└────────────────────────────────────────────────────────────────┘
```

---

# 🔒 RÔLE 1 : Administrateur Système & Hardening

**Personnes** : 1 personne  
**Machine** : VM 1 (Serveur Web)  
**Timeframe** : AVANT les attaques  

## 📍 Localisation dans l'Architecture

```
┌──────────────────────────────────────────┐
│         RÔLE 1 : Ici (VM 1)              │
├──────────────────────────────────────────┤
│                                          │
│  Installation Rocky Linux                │
│  ├─ Partitionnement sécurisé            │
│  ├─ Minimal (pas de GUI)                │
│  └─ Mises à jour de sécurité            │
│                                          │
│  Hardening Système                      │
│  ├─ SSH sécurisé (clés, port custom)   │
│  ├─ Firewall restrictif                │
│  ├─ SELinux enforcing                  │
│  ├─ Fail2ban (brute force)             │
│  └─ Auditd (surveillance actions)      │
│                                          │
│  Services Web                           │
│  ├─ Nginx (ou Apache)                  │
│  └─ Configuration sécurisée            │
│                                          │
│  Configuration Wazuh Agent              │
│  └─ Envoie logs vers VM 2              │
│                                          │
│  🔓 RÉSULTAT : Système difficile à     │
│     compromettre                        │
│                                          │
└──────────────────────────────────────────┘
```

## 🎯 Objectifs Détaillés

### Phase 1 : Installation (Semaine 1)

#### Installation de Rocky Linux
```bash
# Ce que tu fais :

# 1. Télécharger l'ISO
   Rocky Linux 9.x Minimal ISO

# 2. Créer la VM
   RAM : 4 GB
   CPU : 2 cores
   Disque : 30 GB
   Boot : UEFI recommandé

# 3. Installation avec partitionnement personnalisé
   /        (root)     → 10 GB  (ext4)
   /var              → 10 GB  (ext4) ← Logs importants
   /home             → 5 GB   (ext4)
   swap              → 4 GB   (swap) ← Pour cache/emergency
   /boot             → 1 GB   (ext4)

# Pourquoi cette séparation ?
# - Si /var explose avec les logs → Ne bloque pas le root
# - Si /home est attachée → Utilisateurs ne crashent pas le sys
# - Si swap → Évite freeze quand RAM > limite

# 4. Après install
   dnf update -y  # Toutes les patchs de sécurité
```

#### Création Compte Administrateur
```bash
# NE PAS utiliser root pour admin quotidien

# Créer un compte nominatif
useradd -m -s /bin/bash -G wheel admin_alice

# Configurer sudo (sans mot de passe pour groupes wheel)
# Éditer /etc/sudoers avec visudo
%wheel ALL=(ALL:ALL) NOPASSWD:ALL

# Vérifier
sudo whoami  # → Affiche "root" si bien configuré
```

### Phase 2 : Sécurisation SSH (Semaine 1-2)

#### Configuration SSH Hardened
```bash
# Fichier : /etc/ssh/sshd_config

# AVANT (dangereux)
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication no
UsePAM yes
X11Forwarding yes
Compression yes

# APRÈS (sécurisé)
# ─────────────────────────────────────

# Port custom (obscurity + reduction attack surface)
Port 2222

# Authentification
PermitRootLogin no               # Root ne peut pas se connecter
PubkeyAuthentication yes         # Clés publiques SEULEMENT
PasswordAuthentication no        # Pas de mots de passe
AuthorizedKeysFile ~/.ssh/authorized_keys

# Sessions
MaxAuthTries 3                   # Max 3 tentatives
MaxSessions 5                    # Max 5 sessions simultanées
ClientAliveInterval 300          # Timeout 5 min
ClientAliveCountMax 2            # Ferme après 2 timeouts

# Déplacements
AllowUsers alice bob             # Seulement ces users
AllowTcpForwarding no           # Port forwarding interdit
X11Forwarding no                # X11 interdit (GUI)
Compression no                  # Compression interdit
UsePAM yes                      # PAM pour logs complets

# Chiffrement fort
Ciphers chacha20-poly1305@openssh.com,aes-256-gcm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Redémarrer
systemctl restart sshd

# Tester
ssh -p 2222 -i ~/.ssh/id_rsa alice@192.168.1.10
```

#### Génération & Distribution Clés SSH
```bash
# Sur ta machine (pas sur le serveur)
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_admin -C "admin@web-server"
# → Génère id_rsa_admin (PRIVÉE = à garder secret)
#              id_rsa_admin.pub (PUBLIQUE = envoyer au serveur)

# Ajouter la clé publique au serveur
ssh-copy-id -i ~/.ssh/id_rsa_admin.pub -p 2222 alice@192.168.1.10

# À partir de maintenant :
ssh -p 2222 -i ~/.ssh/id_rsa_admin alice@192.168.1.10
# → Aucun mot de passe demandé ✅

# IMPORTANT : SAUVEGARDER id_rsa_admin en sécurité
# → Backup crypté, cloud sécurisé, ou coffrefort
# → Si tu la perds = plus d'accès au serveur !
```

### Phase 3 : Firewall & Fail2ban (Semaine 2)

#### Configuration Firewall (firewalld)
```bash
# Zones de sécurité

# 1. Déterminer la zone
sudo firewall-cmd --get-default-zone  # Public par défaut

# 2. Créer zone custom
sudo firewall-cmd --permanent --new-zone=web-server
sudo firewall-cmd --permanent --zone=web-server --set-description="Web Server DMZ"

# 3. Ajouter règles PERMISSIVES (whitelist)
sudo firewall-cmd --permanent --zone=web-server --add-service=http
sudo firewall-cmd --permanent --zone=web-server --add-service=https
sudo firewall-cmd --permanent --zone=web-server --add-port=2222/tcp  # SSH custom
sudo firewall-cmd --permanent --zone=web-server --add-port=1514/udp  # Wazuh

# 4. Bloquer TOUT le reste (blacklist)
sudo firewall-cmd --permanent --zone=web-server --set-target=DROP

# 5. Source (qui a accès)
sudo firewall-cmd --permanent --zone=web-server --add-source=0.0.0.0/0  # Internet
sudo firewall-cmd --permanent --zone=web-server --add-source=192.168.1.20  # VM SOC (logs)
sudo firewall-cmd --permanent --zone=web-server --add-source=192.168.1.30  # VM Monitor

# 6. Recharger
sudo firewall-cmd --reload

# 7. Vérifier
sudo firewall-cmd --zone=web-server --list-all
```

#### Installation & Config Fail2ban
```bash
# Installation
sudo dnf install -y fail2ban

# Configuration : /etc/fail2ban/jail.d/00-sshd.conf
[sshd]
enabled = true
port = 2222
logpath = /var/log/secure
maxretry = 3
findtime = 600         # Fenêtre 10 min
bantime = 3600         # Ban 1 heure
destemail = admin@example.com
sendername = Fail2ban
mta = sendmail

# Redémarrer
sudo systemctl restart fail2ban

# Tester
sudo fail2ban-client status sshd

# Vérifier banishment
sudo fail2ban-client set sshd unbanip 203.0.113.50
```

**Résultat Fail2ban**
```
Après 3 tentatives SSH échouées en 10 min :
  1. IP est bloquée au firewall
  2. Log dans /var/log/fail2ban.log
  3. Alerte envoyée à SOC (Rôle 2)
  4. Réaction automatique (Rôle 3)
```

### Phase 4 : SELinux & Auditd (Semaine 2-3)

#### SELinux (Mandatory Access Control)
```bash
# Vérifier l'état
getenforce  # → Affiche "permissive", "enforcing", ou "disabled"

# Passer en mode enforcing (production)
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html(/.*)?"
sudo setsebool -P httpd_can_network_connect on
sudo semanage boolean -m --on httpd_can_network_connect

# Éditer /etc/selinux/config
SELINUX=enforcing
SELINUXTYPE=targeted

# Redémarrer pour activer
sudo reboot

# Vérifier les violations SELinux
sudo ausearch -k selinux
```

#### Auditd (Audit Logs)
```bash
# Installation
sudo dnf install -y audit

# Configuration : /etc/audit/rules.d/audit.rules

# 1. Auditer les CHANGEMENTS FICHIERS critiques
-w /etc/ssh/ -p wa -k ssh_config_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes

# 2. Auditer les APPELS SYSTÈME dangereux
-a always,exit -F arch=b64 -S execve -F uid>=1000 -F auid>=1000 -k suspicious_commands
-a always,exit -F arch=b64 -S open -S openat -F exit=-EACCES -F auid>=1000 -k access_denied

# 3. Auditer les CONNEXIONS
-a always,exit -F arch=b64 -S connect -F ip_proto=tcp -F key=network_connections

# 4. Auditer sudo
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -k sudo_usage

# Recharger
sudo service auditd restart

# Vérifier les logs
sudo ausearch -k ssh_config_changes
sudo ausearch -k sudoers_changes
```

### Phase 5 : Configuration Web & Logs (Semaine 3)

#### Installation Nginx
```bash
# Installation
sudo dnf install -y nginx

# Configuration : /etc/nginx/nginx.conf
# Ajouter un bloc server custom

server {
    listen 80;
    listen [::]:80;
    server_name web-server.local;

    root /var/www/html;
    index index.html;

    # LOGS (très importants pour Rôle 2)
    access_log /var/log/nginx/access.log combined;
    error_log /var/log/nginx/error.log warn;

    # Sécurité
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";

    location / {
        try_files $uri $uri/ =404;
    }

    # Interdire les fichiers sensibles
    location ~ /\. {
        deny all;
    }
}

# Redémarrer
sudo systemctl restart nginx
sudo systemctl enable nginx
```

#### Configuration rsyslog (Envoi des Logs)
```bash
# Fichier : /etc/rsyslog.d/01-web-server.conf

# 1. Redirection des logs système vers VM SOC
*.* @@192.168.1.20:514

# 2. Format standard
$ActionFileDefaultTemplate RSYSLOG_FileFormat
$ActionForwardDefaultTemplate RSYSLOG_ForwardFormat

# 3. Logs Nginx
:programname, isequal, "nginx" @@192.168.1.20:514

# 4. Logs SSH
:programname, isequal, "sshd" @@192.168.1.20:514

# 5. Logs Auditd
:programname, isequal, "audispd" @@192.168.1.20:514

# Redémarrer
sudo systemctl restart rsyslog
```

### Phase 6 : Wazuh Agent (Semaine 3)

#### Installation Agent Wazuh
```bash
# Télécharger
WAZUH_MANAGER=192.168.1.20
WAZUH_AGENT_NAME=web-server
WAZUH_AGENT_GROUP=web-servers

# Installation (sur Rocky)
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | rpm --import -
rpm -i https://packages.wazuh.com/4.x/yum/wazuh-agent-4.7.0-1.x86_64.rpm

# Configuration : /var/ossec/etc/ossec.conf
<client>
  <server-ip>192.168.1.20</server-ip>
  <server-port>1514</server-port>
  <protocol>tcp</protocol>
  <network-interface>eth0</network-interface>
</client>

# Monitorer les fichiers de log
<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/nginx/access.log</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/secure</location>
  </localfile>
  <localfile>
    <log_format>audit</log_format>
    <location>/var/log/audit/audit.log</location>
  </localfile>
</ossec_config>

# Démarrer l'agent
sudo systemctl start wazuh-agent
sudo systemctl enable wazuh-agent

# Vérifier
sudo /var/ossec/bin/wazuh-control status
```

---

## 📋 Livrables du Rôle 1

À la fin, tu dois avoir :

### 1. Rapport Installation
```markdown
# Rapport Installation Rocky Linux
- [ ] Installation minimal complétée
- [ ] Partitions créées (/, /var, /home, swap)
- [ ] Mises à jour appliquées
- [ ] Compte admin créé
- [ ] SSH accès vérifié
```

### 2. Checklist Hardening
```markdown
# Hardening Checklist
- [ ] SSH : Port 2222, pas de root, clés seulement
- [ ] Firewall : 80/443/2222 ouverts, reste fermé
- [ ] Fail2ban : SSH + Web protected, bans en action
- [ ] SELinux : Mode enforcing activé
- [ ] Auditd : Règles SSH + sudo + fichiers critiques
- [ ] Nginx : Installé, logs importants
- [ ] rsyslog : Envoie vers 192.168.1.20:514
- [ ] Wazuh Agent : Connecté et reporte
```

### 3. Rapport Lynis
```bash
# Lynis = outil d'audit de sécurité Linux

sudo dnf install -y lynis

# Lancer l'audit
sudo lynis audit system

# Générer rapport
sudo lynis audit system --quiet > /tmp/lynis-report.txt

# Livrable : Ce rapport + actions correctives
```

**Résultat attendu** : Score Lynis > 80/100

### 4. Schéma de Sécurité (Diagramme)
```
Créer un diagramme montrant :
  - Flux SSH (2222 → clé → user → sudo)
  - Firewall rules (ports ouverts/fermés)
  - Auditd routes (fichiers → logs)
  - rsyslog envoi (vers VM 2)
```

---

---

# 🔍 RÔLE 2 : SOC / Logs / Détection d'Intrusion

**Personnes** : 1 personne  
**Machine** : VM 2 (SOC Manager)  
**Timeframe** : PENDANT les attaques  

## 📍 Localisation dans l'Architecture

```
┌──────────────────────────────────────────┐
│  RÔLE 2 : Ici (VM 2) - CŒUR DU SOC      │
├──────────────────────────────────────────┤
│                                          │
│  Réception des Logs                     │
│  ├─ rsyslog (port 514)                 │
│  │  ← VM 1, VM 3                       │
│  │                                      │
│  └─ Wazuh Manager (port 1514)          │
│     ← Wazuh Agents sur VM 1 & VM 3     │
│                                          │
│  Analyse en Temps Réel                  │
│  ├─ Wazuh Manager                      │
│  │  ├─ Applique règles                │
│  │  ├─ Détecte anomalies              │
│  │  └─ Crée alertes                   │
│  │                                      │
│  ├─ Elasticsearch                      │
│  │  └─ Indexe + stocke                │
│  │                                      │
│  └─ Kibana (Web UI)                    │
│     └─ Visualise + recherche           │
│                                          │
│  Génération Alertes                     │
│  └─ Brute force, scans, malveillance   │
│                                          │
│  🔍 RÉSULTAT : Voit tout ce qui se     │
│     passe, détecte menaces             │
│                                          │
└──────────────────────────────────────────┘
```

## 🎯 Objectifs Détaillés

### Phase 1 : Installation Wazuh Manager (Semaine 3-4)

#### Installation et Configuration
```bash
# Installation Wazuh Manager + Elasticsearch + Kibana
# (Peut se faire manuellement ou via docker-compose)

# Méthode simple : Docker Compose
# Fichier : docker-compose.yml

version: '3.7'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data

  wazuh:
    image: wazuh/wazuh:4.7.0
    depends_on:
      - elasticsearch
    ports:
      - "1514:1514/udp"  # Wazuh agent port
      - "1514:1514/tcp"
      - "1515:1515/tcp"  # Cluster communication
      - "514:514/udp"    # Syslog
      - "514:514/tcp"
    environment:
      - INDEXER_URL=https://elasticsearch:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=admin123
      - FILEBEAT_SSL_VERIFICATION_MODE=full
      - SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/certs/ca.crt
      - SSL_CERTIFICATE=/etc/ssl/certs/wazuh.crt
      - SSL_KEY=/etc/ssl/certs/wazuh.key

  kibana:
    image: docker.elastic.co/kibana/kibana:8.5.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  elasticsearch-data:

# Lancer
docker-compose up -d

# Accès
# URL : http://192.168.1.20:5601
# Login : admin / admin123
```

### Phase 2 : Enregistrer Agents Wazuh (Semaine 4)

#### Enregistrement des Agents
```bash
# VM 2 (Wazuh Manager)
# Générer clé d'authentification pour agent sur VM 1

docker exec wazuh-wazuh-1 /var/ossec/bin/manage_agents -a -n web-server -G web-servers

# → Affiche un ID agent (ex: 001)

# Sur VM 1 (Wazuh Agent)
# Éditer /var/ossec/etc/ossec.conf

<client>
  <server-ip>192.168.1.20</server-ip>
  <server-port>1514</server-port>
  <client_buffer>
    <queue_size>5000</queue_size>
  </client_buffer>
</client>

# Redémarrer l'agent
sudo systemctl restart wazuh-agent
```

### Phase 3 : Créer Règles de Détection Personnalisées (Semaine 4-5)

#### Règles Wazuh (XML)

Fichier : `/var/ossec/etc/rules/local_rules.xml`

```xml
<!-- Règle 1 : Détecter Brute Force SSH -->
<rule id="100001" level="10">
  <if_sid>5710</if_sid>
  <frequency>5</frequency>
  <timeframe>600</timeframe>
  <same_source_ip />
  <description>Brute force SSH détecté - 5 tentatives échouées</description>
  <group>authentication_failures,pci_dss_10.2.4,pci_dss_10.2.5</group>
  <threshold frequency="5" timeframe="600">
    <alert_frequency>30</alert_frequency>
  </threshold>
</rule>

<!-- Règle 2 : Scan de Ports (Nmap) -->
<rule id="100002" level="12">
  <if_sid>5714</if_sid>
  <match>^Received disconnect from</match>
  <frequency>20</frequency>
  <timeframe>60</timeframe>
  <same_source_ip />
  <description>Port scan détecté - multiple SSH connections fermées</description>
  <group>network_scan,pci_dss_11.4.6</group>
</rule>

<!-- Règle 3 : Commande Sudo Suspecte -->
<rule id="100003" level="11">
  <if_sid>5402</if_sid>
  <match>^sudo:.*COMMAND=.*/bin/sh|^sudo:.*COMMAND=.*/bin/bash</match>
  <description>Sudo utilisé pour lancer shell - potentiellement malveillant</description>
  <group>privilege_escalation,pci_dss_10.2.5</group>
</rule>

<!-- Règle 4 : Upload Fichier dans /var/www -->
<rule id="100004" level="10">
  <if_sid>600</if_sid>
  <match>\.sh$|\.php$|\.py$|\.jsp$</match>
  <action type="monitor">/var/www/html</action>
  <description>Fichier script créé/modifié dans répertoire web - possible malveillance</description>
  <group>malware_activity</group>
</rule>

<!-- Règle 5 : Accès SSH Hors Horaires -->
<rule id="100005" level="8">
  <if_sid>5715</if_sid>
  <time>!6:00-22:00</time>
  <description>SSH login hors horaires de travail - possible intrusion</description>
  <group>anomalies</group>
</rule>

<!-- Règle 6 : Tentative Root SSH (doit être bloquée avant) -->
<rule id="100006" level="12">
  <if_sid>5710</if_sid>
  <match>^Failed password for root|^Invalid user root</match>
  <description>Tentative connexion ROOT SSH - attaque directe détectée</description>
  <group>authentication_failures,pci_dss_10.2.4</group>
</rule>
```

#### Tester les Règles
```bash
# Générer un événement de test
# Sur VM 1 : Tentatives SSH échouées

for i in {1..10}; do
  ssh -p 2222 -i /tmp/fake_key user@192.168.1.10 2>/dev/null
done

# Attendre 1-2 minutes
# Aller sur Kibana (192.168.1.20:5601)
# Chercher l'alerte dans Discover → brute force
```

### Phase 4 : Dashboards Kibana (Semaine 5)

#### Créer des Visualisations

**Dashboard 1 : Vue d'Ensemble Sécurité**
```
- Timeline des alertes par sévérité
- Top sources IP des attaques
- Top règles déclenchées
- Ratio authentifications réussies/échouées
```

**Dashboard 2 : Détection Attaques**
```
- Brute force SSH (alertes en temps réel)
- Scans de ports (connexions rapides)
- Uploads fichiers suspects
- Tentatives élévation privilèges
```

**Dashboard 3 : Analyse Post-Incident**
```
- Timeline complète d'une attaque
- Logs corrélés (SSH + Firewall + Auditd)
- Actions prises par IR
- Temps de détection et réaction
```

### Phase 5 : Tests & Validation (Semaine 5-6)

#### Tester Chaque Scénario d'Attaque

```bash
# Test 1 : Brute Force SSH
ssh -p 2222 wronguser@192.168.1.10
ssh -p 2222 wronguser@192.168.1.10
ssh -p 2222 wronguser@192.168.1.10
... (répéter 5x)
→ Alerte Wazuh générée ✅

# Test 2 : Scan Nmap
nmap -sS -p 1-1000 192.168.1.10
→ Multiples connexions rapides → Détection ✅

# Test 3 : Upload Fichier
curl -X POST -F "file=@test.sh" http://192.168.1.10/upload.php
→ Fichier .sh en /var/www → Alerte malveillance ✅

# Test 4 : Commande Sudo
sudo cat /etc/shadow
→ Command audit → Alerte suspeicte ✅

# Test 5 : Accès Hors Horaires (à 3h du matin)
ssh -p 2222 user@192.168.1.10
→ Alerte "SSH hors horaires" ✅
```

---

## 📋 Livrables du Rôle 2

### 1. Rapport Sources de Logs
```markdown
# Sources Logs Collectées

## VM 1 (Serveur Web)
- SSH : /var/log/secure
- Nginx : /var/log/nginx/access.log, error.log
- Auditd : /var/log/audit/audit.log
- Fail2ban : /var/log/fail2ban.log
- Système : /var/log/messages

## Transport
- rsyslog → 192.168.1.20:514
- Wazuh Agent → 192.168.1.20:1514

## Stockage VM 2
- Elasticsearch : Indexe tous les logs
- Retention : 90 jours minimum
```

### 2. Règles Wazuh Personnalisées
```bash
Livrable : Fichier /var/ossec/etc/rules/local_rules.xml
  - 5+ règles créées
  - Brute force SSH
  - Scan ports
  - Malveillance fichiers
  - Sudoers abuse
  - Anomalies timing
```

### 3. Screenshots Alertes en Action
```
Captures d'écran montrant :
- Kibana Discovery : logs bruts
- Kibana Dashboard : timeline alertes
- Wazuh Console : alertes détaillées (sévérité, rule_id)
- Chaque alert avec contexte (IP source, target, timestamp)
```

### 4. Analyses Détaillées 3+ Attaques

Pour chaque attaque simulée :
```markdown
# Analyse Brute Force SSH

## Timeline
T+0:00 → Attaque lancée (10 tentatives en 30s)
T+0:05 → Logs reçus par rsyslog
T+0:10 → Wazuh Manager évalue règle (brute force)
T+1:00 → Alert generée, dashboards mis à jour

## Indices Présents
- /var/log/secure : Failed password (répétée 10x)
- Elasticsearch : Event indexed avec source IP
- Wazuh : Alert avec severity=10, rule_id=100001

## Règle Déclenchée
Brute Force SSH (ID 100001)
  - Condition : 5+ failed attempts in 600s
  - Source : 203.0.113.50
  - Cible : 192.168.1.10:2222
  - Timestamp : 2026-02-05 14:32:00

## Contexte
- IP attaquante : Aucun accès précédent
- Pattern : 10 users différents testés
- Fail2ban action : IP bloquée après 3 tentatives
- Firewall : Connexion ultérieure refusée

## Action IR
Voir Rôle 3 (Monitoring IR)
```

---

---

# 📊 RÔLE 3 : Supervision & Incident Response

**Personnes** : 1 personne  
**Machine** : VM 3 (Monitoring)  
**Timeframe** : APRÈS la détection (réaction/correction)  

## 📍 Localisation dans l'Architecture

```
┌──────────────────────────────────────────┐
│  RÔLE 3 : Ici (VM 3) - INCIDENT RESPONSE│
├──────────────────────────────────────────┤
│                                          │
│  Monitoring Infrastructure               │
│  ├─ Zabbix / Prometheus                 │
│  ├─ Agents envoient métriques            │
│  └─ Grafana pour visualisation           │
│                                          │
│  Détection Anomalies                     │
│  ├─ Alertmanager                        │
│  ├─ Règles thresholds                   │
│  └─ Notifications                       │
│                                          │
│  Incident Response                       │
│  ├─ Playbooks IR                        │
│  ├─ Scripts automatisés                 │
│  └─ Actions correctives                 │
│                                          │
│  Forensics & Rapports                    │
│  ├─ Analyse post-incident               │
│  ├─ Timeline complète                   │
│  └─ Recommandations                     │
│                                          │
│  🚨 RÉSULTAT : Réagit aux incidents,    │
│     bloque/isole/récupère               │
│                                          │
└──────────────────────────────────────────┘
```

## 🎯 Objectifs Détaillés

### Phase 1 : Installation Monitoring (Semaine 4-5)

#### Option A : Zabbix (Plus complet)
```bash
# Zabbix est un outil pro, très utilisé en entreprise

# Installation (sur VM 3)
sudo dnf install -y mariadb-server
sudo dnf install -y zabbix-server-mysql zabbix-web-mysql
sudo dnf install -y zabbix-agent

# Base de données
sudo systemctl start mariadb
mysql -e "CREATE DATABASE zabbix; CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix123'; GRANT ALL ON zabbix.* TO 'zabbix'@'localhost'; FLUSH PRIVILEGES;"

# Initialiser DB
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbix -p zabbix

# Config : /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix123

# Démarrer
sudo systemctl start zabbix-server
sudo systemctl start zabbix-agent
sudo systemctl enable zabbix-server zabbix-agent

# Web UI
http://192.168.1.30/zabbix
```

#### Option B : Prometheus + Grafana (Plus léger)
```bash
# Prometheus
sudo dnf install -y prometheus
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Configuration : /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'linux'
    static_configs:
      - targets: ['192.168.1.10:9100']
      - targets: ['192.168.1.20:9100']
      - targets: ['192.168.1.30:9100']

# Grafana
sudo dnf install -y grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Web UI
http://192.168.1.30:3000
Login : admin / admin
```

### Phase 2 : Créer Dashboards (Semaine 5)

#### Dashboard Zabbix/Grafana : Ressources

```
┌─────────────────────────────────────────┐
│      RESSOURCES SYSTÈME (temps réel)   │
├─────────────────────────────────────────┤
│                                         │
│ CPU Usage     │ ████████░░  82%        │
│ RAM Usage     │ ██████░░░░  60%        │
│ Disque /      │ ███████░░░  70%        │
│ Disque /var   │ ██░░░░░░░░  15%        │
│                                         │
│ Network IN    │ ████░░░░░░  45 Mbps   │
│ Network OUT   │ █░░░░░░░░░  8 Mbps    │
│                                         │
└─────────────────────────────────────────┘
```

#### Dashboard Zabbix/Grafana : Services

```
┌─────────────────────────────────────────┐
│          SERVICES STATUS                │
├─────────────────────────────────────────┤
│                                         │
│ SSH         ● Actif   (port 2222)       │
│ Nginx       ● Actif   (port 80/443)    │
│ Wazuh Agent ● Actif   (connected)      │
│ Firewall    ● Actif   (20 rules)       │
│ Auditd      ● Actif   (logging)        │
│                                         │
└─────────────────────────────────────────┘
```

#### Dashboard Zabbix/Grafana : Incident Response

```
┌──────────────────────────────────────────┐
│     INCIDENT RESPONSE TIMELINE          │
├──────────────────────────────────────────┤
│                                          │
│ 14:30:00  🔴 Alert : Brute force SSH   │
│           Source: 203.0.113.50          │
│           Target: 192.168.1.10:2222     │
│           Attempts: 10                  │
│                                          │
│ 14:30:30  🟠 CPU spike detected        │
│           Peak: 95% (analyzing logs)    │
│                                          │
│ 14:31:00  🟡 Playbook launched        │
│           Status: Block IP @ firewall   │
│                                          │
│ 14:31:15  ✅ IP blocked successfully   │
│           Fail2ban + firewall-cmd       │
│                                          │
│ 14:32:00  ✅ Forensics captured        │
│           Snapshots: logs, processes    │
│                                          │
│ 14:35:00  ✅ Report generated         │
│           Timeline, logs, remediation   │
│                                          │
└──────────────────────────────────────────┘
```

### Phase 3 : Playbooks Incident Response (Semaine 5-6)

#### Playbook 1 : Bloquer Brute Force SSH

Fichier : `/home/ir-team/playbooks/block_bruteforce_ssh.sh`

```bash
#!/bin/bash

# Playbook : Bloquer Brute Force SSH
# Déclenché par : Wazuh Alert 100001
# Entrées : IP source attaquante

IP_ATTAQUANT=$1
ALERT_ID=$2
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)

# 1. Bloquer l'IP au firewall
echo "[${TIMESTAMP}] Blocage IP ${IP_ATTAQUANT} au firewall..."
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${IP_ATTAQUANT}' reject"
sudo firewall-cmd --reload

# 2. Vérifier dans Fail2ban
echo "[${TIMESTAMP}] Vérification Fail2ban..."
sudo fail2ban-client set sshd banip ${IP_ATTAQUANT}
sudo fail2ban-client status sshd | grep ${IP_ATTAQUANT}

# 3. Créer snapshot forensique
echo "[${TIMESTAMP}] Capture forensique..."
mkdir -p /var/forensics/${ALERT_ID}
cp /var/log/secure /var/forensics/${ALERT_ID}/secure.log
cp /var/log/audit/audit.log /var/forensics/${ALERT_ID}/audit.log
netstat -an > /var/forensics/${ALERT_ID}/netstat.txt
ps auxwww > /var/forensics/${ALERT_ID}/processes.txt

# 4. Envoyer notification
echo "[${TIMESTAMP}] Notification..."
curl -X POST https://hooks.slack.com/... \
  -H 'Content-type: application/json' \
  -d "{ \
    'text': '🚨 Incident Response Actif', \
    'blocks': [ \
      {'type': 'section', 'text': {'type': 'mrkdwn', 'text': '*Type:* Brute Force SSH'}}, \
      {'type': 'section', 'text': {'type': 'mrkdwn', 'text': '*IP Source:* ${IP_ATTAQUANT}'}}, \
      {'type': 'section', 'text': {'type': 'mrkdwn', 'text': '*Action:* Bloquée au firewall'}}, \
      {'type': 'section', 'text': {'type': 'mrkdwn', 'text': '*Timestamp:* ${TIMESTAMP}'}} \
    ] \
  }"

echo "[${TIMESTAMP}] Playbook completed ✅"
```

**Déclencher le playbook** : Automé via webhook Wazuh → Alertmanager → Script

#### Playbook 2 : Isoler Fichier Malveillant

Fichier : `/home/ir-team/playbooks/quarantine_malfile.sh`

```bash
#!/bin/bash

# Playbook : Isoler fichier malveillant
# Déclenché par : Wazuh Alert 100004 (upload fichier .sh/.php)

FILE_PATH=$1
ALERT_ID=$2
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)

# 1. Créer quarantine directory
mkdir -p /var/quarantine/${ALERT_ID}

# 2. Copier le fichier (avant de le supprimer)
cp "${FILE_PATH}" /var/quarantine/${ALERT_ID}/
chmod 000 "${FILE_PATH}"

# 3. Scanner antivirus (si disponible)
if command -v clamscan &> /dev/null; then
  clamscan -r "${FILE_PATH}" > /var/quarantine/${ALERT_ID}/av_scan.txt
fi

# 4. Isoler le répertoire web
sudo chmod 555 /var/www/html
sudo chown root:root /var/www/html

# 5. Redémarrer Nginx
sudo systemctl restart nginx

# 6. Alerte SRE + Sécurité
echo "[${TIMESTAMP}] Fichier malveillant isolé : ${FILE_PATH}" | \
  mail -s "🚨 INCIDENT : Malveillance détectée" security-team@company.com

echo "[${TIMESTAMP}] Playbook completed ✅"
```

### Phase 4 : Scripts Automatisés (Semaine 6)

#### Script 1 : Snapshot Forensique Automatique

```bash
#!/bin/bash

# Script : Créer snapshot forensique après alerte

ALERT_ID=$1
SEVERITY=$2
RULE_NAME=$3

# Directory
SNAP_DIR="/var/forensics/${ALERT_ID}"
mkdir -p ${SNAP_DIR}

# 1. Logs
cp /var/log/secure ${SNAP_DIR}/secure.log
cp /var/log/audit/audit.log ${SNAP_DIR}/audit.log
cp /var/log/nginx/* ${SNAP_DIR}/

# 2. Processes & Network
ps auxwww > ${SNAP_DIR}/ps.txt
netstat -antp > ${SNAP_DIR}/netstat.txt
ss -tulnp > ${SNAP_DIR}/sockets.txt

# 3. File integrity
find /var/www -type f -exec ls -la {} \; > ${SNAP_DIR}/files.txt

# 4. SELinux context
getenforce > ${SNAP_DIR}/selinux_status.txt
sesearch -A > ${SNAP_DIR}/selinux_rules.txt 2>/dev/null

# 5. Tarball pour archivage
tar -czf ${SNAP_DIR}.tar.gz ${SNAP_DIR}

echo "✅ Snapshot forensique créé : ${SNAP_DIR}.tar.gz"
```

#### Script 2 : Générer Rapport Post-Incident

```bash
#!/bin/bash

# Script : Rapport post-incident en Markdown

ALERT_ID=$1
SNAP_DIR="/var/forensics/${ALERT_ID}"

cat > ${SNAP_DIR}/RAPPORT.md << EOF
# Rapport Post-Incident #${ALERT_ID}

## Résumé Exécutif
- **Type** : Brute Force SSH
- **Détecté par** : Wazuh Rule 100001
- **IP Source** : 203.0.113.50
- **Cible** : 192.168.1.10:2222
- **Durée** : 2 minutes
- **Statut** : CONTENU ✅

## Timeline Complète
\`\`\`
14:30:00 - Première tentative SSH
14:30:30 - 10 tentatives en 30s détectées
14:31:00 - Wazuh genère alerte sévérité 10
14:31:15 - Playbook lancé automatiquement
14:31:30 - IP bloquée au firewall
14:32:00 - Forensics captured
\`\`\`

## Artefacts Collectés
- Logs SSH : ${SNAP_DIR}/secure.log
- Audit logs : ${SNAP_DIR}/audit.log
- Processes : ${SNAP_DIR}/ps.txt
- Network sockets : ${SNAP_DIR}/sockets.txt

## Actions Correctives
- ✅ SSH Port changé de 22 à 2222
- ✅ Fail2ban configuré (3 tentatives max)
- ✅ Firewall whitelist appliquée
- ✅ IP source ajoutée à blacklist permanente

## Recommandations
1. Implémenter VPN pour SSH external
2. Activer 2FA pour comptes admin
3. Monitoring SSH activity (toutes les 24h)

---
Rapport généré : $(date)
Enquêteur : IR Team
EOF

cat ${SNAP_DIR}/RAPPORT.md
```

---

## 📋 Livrables du Rôle 3

### 1. Dashboards Monitoring
```
Zabbix / Grafana dashboards:
  - ✅ Resources (CPU/RAM/Disque)
  - ✅ Services (SSH/Nginx/Wazuh)
  - ✅ Incident Response (timeline)
  - ✅ Post-Incident (forensics)

Screenshots exportés en PDF
```

### 2. Playbooks IR (Markdown + Scripts Bash)
```
Playbooks créés :
  - ✅ Block Brute Force SSH
  - ✅ Isoler Fichier Malveillant
  - ✅ Snapshot Forensique
  - ✅ Générer Rapport Post-Incident

Chaque playbook : description + script executable
```

### 3. Scripts Réaction (Bash/Ansible)
```
Scripts :
  - firewall-block-ip.sh
  - quarantine-malfile.sh
  - forensics-snapshot.sh
  - generate-report.sh

Testés et documentés
```

### 4. Rapports Post-Incident
```
Pour chaque attaque simulée :
  - Timeline complète
  - Artefacts forensiques
  - Actions correctives prises
  - Recommandations futures
```

---

---

## 👥 Communication Inter-Rôles

### Workflow de Collaboration

```
RÔLE 1 (Admin)          RÔLE 2 (SOC)          RÔLE 3 (IR)
     │                      │                      │
     │                      │                      │
     ├─→ Logs centralisés ─→│                      │
     │   (rsyslog + Wazuh)  │                      │
     │                      │                      │
     │                      ├─→ Alerte générée ──→│
     │                      │   (Email/Slack)     │
     │                      │                      │
     │                      │                  (Analyse)
     │                      │                  (Décision)
     │                      │                      │
     │                   ← ─ ─ ─ ─ ─ ─ ─ ─ ←─┤    │
     │                   (Webhook feedback)    (Playbook)
     │                      │                      │
     ├─ Règles appliquées ─│                      │
     │  Firewall updates    │                      │
     │                      │                      │
     ├─ Logs du blocage ───→│ ─ ─ ─ ─ ─ ─ ─ ─ →│
     │                      └──→ Rapport Post-incident
     │
```

### Réunions d'Équipe

```
Fréquence : 2x par semaine (30 min)

LUNDI (Briefing)
  Rôle 1 : Nouveaux hardening à tester
  Rôle 2 : Nouvelles règles actives ?
  Rôle 3 : Playbooks opérationnels ?

JEUDI (Debrief + Tests)
  Tous : Résultats tests attaques cette semaine
  Rôle 2 : Alertes déclenchées correctement ?
  Rôle 3 : Réponses automatisées ok ?
  Rôle 1 : Corrections à appliquer ?
```

### Checklist Communication

- [ ] Rôle 1 envoie config SSH chaque update → Rôle 2 (pour logs)
- [ ] Rôle 2 envoie règles Wazuh finalisées → Rôle 3 (pour playbooks)
- [ ] Rôle 3 envoie rapports IR → Rôle 1 (pour ajustements sécurité)
- [ ] Tous les 3 jours : réunion 15 min sync
- [ ] Wiki partagé pour documentations
- [ ] Slack canal #incident-response pour updates temps réel

---

## 📚 Prochaines Étapes

1. **Vérifier** → [`04_prerequis.md`](04_prerequis.md)  
   As-tu assez de matériel ?

2. **Planifier** → [`05_timeline.md`](05_timeline.md)  
   Comment organiser les 6 semaines

---

**Version** : 1.0  
**Dernière mise à jour** : Février 2026
