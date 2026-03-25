# ⏱️ 5. Timeline et Planning (6 Semaines)

**Durée de lecture estimée** : 10 minutes  
**Objectif** : Organiser le travail sur 6 semaines  
**Prérequis** : Avoir vérifié prérequis (voir [`04_prerequis.md`](04_prerequis.md))

---

## 📊 Vue d'Ensemble (Gantt Simplifié)

```
SEMAINE 1 : Préparation & Infrastructure
├─ Rôle 1 : VM 1 installation
├─ Rôle 2 : VM 2 installation
└─ Rôle 3 : VM 3 installation

SEMAINE 2 : Hardening & Bases
├─ Rôle 1 : SSH sécurisé + Firewall
├─ Rôle 2 : rsyslog centralisé
└─ Rôle 3 : Zabbix basics

SEMAINE 3 : Cœur du SOC
├─ Rôle 1 : SELinux + Auditd
├─ Rôle 2 : Wazuh Manager installation
└─ Rôle 3 : Grafana dashboards

SEMAINE 4 : Détection & Monitoring
├─ Rôle 1 : Wazuh Agent + Logs
├─ Rôle 2 : Règles Wazuh personnalisées
└─ Rôle 3 : Alertes automatisées

SEMAINE 5 : Tests & Incident Response
├─ Rôle 1 : Vérification hardening
├─ Rôle 2 : Validation règles + Dashboard Kibana
└─ Rôle 3 : Playbooks IR écrits

SEMAINE 6 : Attaques & Rapports
├─ Tous : Simuler 5 attaques
├─ Rôle 2 : Analyser détections
├─ Rôle 3 : Tester réactions
└─ Tous : Documenter & rapports finals
```

---

## 📅 SEMAINE 1 : Préparation & Infrastructure (20 heures)

### 🎯 Objectifs

- [ ] 3 VM créées et bootables
- [ ] Réseau configuré entre VMs
- [ ] Noms d'hôtes et adresses IP fixes
- [ ] SSH accessible (avec password temporaire)

### 📋 Détail par Rôle

#### Rôle 1 (Admin Hardening) : 7 heures

**Jour 1-2 : Créer et installer VM 1**
```
Étape 1 : Créer VM dans VirtualBox
  - Nom : web-server
  - RAM : 4 GB
  - CPU : 2 cores
  - Disque : 30 GB
  - Boot : Rocky Linux ISO minimal
  Durée : 30 min

Étape 2 : Installer Rocky Linux
  - Choix : Minimal (pas de GUI)
  - Partitionnement custom : /, /var, /home, swap
  - Créer compte admin (pas root)
  - Set hostname : web-server.local
  Durée : 1.5 heures

Étape 3 : Configuration réseau basique
  - IP fixe : 192.168.1.10/24
  - Gateway : 192.168.1.1
  - DNS : 1.1.1.1 + 8.8.8.8
  - Test ping : ping 8.8.8.8
  Durée : 30 min

Étape 4 : Mises à jour
  - dnf update -y
  - Reboot
  Durée : 1 heure (incl. téléchargement)

Étape 5 : SSH temporaire
  - systemctl enable sshd
  - Permettre connexions (password)
  - Tester : ssh admin@192.168.1.10
  Durée : 15 min
```

**Livrable fin semaine 1** : VM web-server prête, accessible en SSH

#### Rôle 2 (SOC) : 7 heures

**Jour 1-2 : Créer et installer VM 2**
```
Étape 1 : Créer VM dans VirtualBox
  - Nom : soc-manager
  - RAM : 6 GB (Important ! Elasticsearch gourmand)
  - CPU : 4 cores
  - Disque : 50 GB
  - Boot : Rocky Linux ISO minimal
  Durée : 30 min

Étape 2 : Installer Rocky Linux (identique à VM 1)
  - Minimal
  - Partitionnement custom
  - Hostname : soc-manager.local
  - Compte admin
  Durée : 1.5 heures

Étape 3 : Réseau VM 2
  - IP fixe : 192.168.1.20/24
  - Gateway : 192.168.1.1
  - DNS : 1.1.1.1 + 8.8.8.8
  - Port 514/UDP ouvert (rsyslog)
  - Port 1514/TCP ouvert (Wazuh)
  Durée : 30 min

Étape 4 : Mises à jour + SSH
  - dnf update -y
  - Reboot
  - SSH temporaire activé
  Durée : 1.5 heures

Étape 5 : Test connectivité inter-VM
  - De VM 1 : ping 192.168.1.20
  - De VM 2 : ping 192.168.1.10
  Durée : 15 min
```

**Livrable fin semaine 1** : VM soc-manager prête, réseau fonctionnel

#### Rôle 3 (Monitoring) : 6 heures

**Jour 1-2 : Créer et installer VM 3**
```
Étape 1 : Créer VM dans VirtualBox
  - Nom : monitoring
  - RAM : 4 GB
  - CPU : 2 cores
  - Disque : 30 GB
  - Boot : Rocky Linux ISO minimal
  Durée : 30 min

Étape 2 : Installer Rocky Linux
  - Minimal
  - Partitionnement : /, /var, /home, swap
  - Hostname : monitoring.local
  - Compte admin
  Durée : 1.5 heures

Étape 3 : Réseau VM 3
  - IP fixe : 192.168.1.30/24
  - Gateway : 192.168.1.1
  - DNS : 1.1.1.1 + 8.8.8.8
  - Port 10051/TCP (Zabbix) accessible
  Durée : 30 min

Étape 4 : Mises à jour + SSH
  - dnf update -y + reboot
  - SSH temporaire
  Durée : 1.5 heures

Étape 5 : Vérifier connectivité triple
  - VM 1 ↔ VM 2 ↔ VM 3
  - Tableau adresses IP noté
  Durée : 15 min
```

**Livrable fin semaine 1** : 3 VMs opérationnelles, réseau OK

### 📌 Checklist Semaine 1

- [ ] VM 1 (web-server, 192.168.1.10) installée ✅
- [ ] VM 2 (soc-manager, 192.168.1.20) installée ✅
- [ ] VM 3 (monitoring, 192.168.1.30) installée ✅
- [ ] Ping entre VMs fonctionne ✅
- [ ] SSH accessible temporairement ✅
- [ ] Snapshots VirtualBox créés (backup sécurité) ✅

### 💾 Sauvegarde Semaine 1

```bash
# Créer snapshot avant hardening
# (au cas où on casse quelque chose)

# VirtualBox CLI
VBoxManage snapshot "web-server" take "S1-Clean-Install"
VBoxManage snapshot "soc-manager" take "S1-Clean-Install"
VBoxManage snapshot "monitoring" take "S1-Clean-Install"

# Ou via GUI : Machine → Snapshots → Take Snapshot
```

---

## 📅 SEMAINE 2 : Hardening & Configuration Bases (20 heures)

### 🎯 Objectifs

- [ ] SSH sécurisé (clés, port custom, pas root)
- [ ] Firewall configuré (ports spécifiques ouverts)
- [ ] Fail2ban actif (protection brute force)
- [ ] rsyslog centralisé (vers VM 2)

### 📋 Détail par Rôle

#### Rôle 1 : Hardening Avancé (8 heures)

**Jour 1 : SSH Sécurisé**
```
Étape 1 : Générer clés SSH (sur ta machine, pas la VM)
  ssh-keygen -t ed25519 -f ~/.ssh/web_server_key
  Durée : 5 min

Étape 2 : Copier clé publique sur VM 1
  ssh-copy-id -i ~/.ssh/web_server_key.pub admin@192.168.1.10
  Durée : 5 min (demande password temporaire)

Étape 3 : Configurer sshd_config
  Éditer : /etc/ssh/sshd_config
  - Port 2222
  - PermitRootLogin no
  - PubkeyAuthentication yes
  - PasswordAuthentication no
  - MaxAuthTries 3
  Durée : 30 min

Étape 4 : Redémarrer SSH et tester
  systemctl restart sshd
  ssh -p 2222 -i ~/.ssh/web_server_key admin@192.168.1.10
  Durée : 15 min

Total Jour 1 : 1 heure
```

**Jour 2 : Firewall + Fail2ban**
```
Étape 1 : Installer et configurer firewalld
  systemctl enable firewalld
  Créer zone 'web-server'
  Ajouter ports : 80, 443, 2222, 1514
  Bloquer TOUT le reste
  Durée : 1.5 heures

Étape 2 : Installer fail2ban
  dnf install -y fail2ban
  Configuration : /etc/fail2ban/jail.d/00-sshd.conf
  - maxretry = 3
  - findtime = 600 (10 min)
  - bantime = 3600 (1 heure)
  Durée : 45 min

Étape 3 : Test
  Tenter 5 connexions SSH échouées
  Vérifier blocage
  Durée : 30 min

Total Jour 2 : 2.75 heures
```

**Jour 3 : Documentation Hardening**
```
Rédiger sur GitHub :
  - Fichier : /02_INSTALLATION/01_hardening_vm1.md
  - Étapes SSH/Firewall/Fail2ban
  - Screenshots configuration
  - Tests de validation
  Durée : 1.5 heures
```

**Livrable Rôle 1 Semaine 2** :
- VM 1 SSH sécurisé
- Firewall restrictif
- Fail2ban actif
- Documentation GitHub

#### Rôle 2 : rsyslog Centralisé (6 heures)

**Jour 2-3 : Configuration Logs**
```
Étape 1 : Installer rsyslog sur VM 2 (receiver)
  dnf install -y rsyslog
  Éditer : /etc/rsyslog.conf
  - Ajouter listener :514/UDP
  - Créer dossier /var/log/remote/
  - Permissions correctes
  Durée : 1 heure

Étape 2 : Configurer rsyslog VM 1 (sender)
  Éditer : /etc/rsyslog.d/01-remote.conf
  - Destination : @@192.168.1.20:514
  - Format : RSYSLOG_FileFormat
  systemctl restart rsyslog
  Durée : 1 heure

Étape 3 : Tester l'envoi
  VM 1 : logger "Test message depuis VM 1"
  VM 2 : tail -f /var/log/remote/web-server.log
  Vérifier apparition du message
  Durée : 30 min

Étape 4 : Configurer fichiers logs
  /var/log/nginx/ → /var/log/remote/nginx/
  /var/log/secure → /var/log/remote/secure/
  /var/log/fail2ban.log → /var/log/remote/fail2ban/
  Durée : 1.5 heures

Étape 5 : Documentation
  GitHub : Schéma rsyslog, test validation
  Durée : 1 heure
```

**Livrable Rôle 2 Semaine 2** :
- rsyslog receiver actif sur VM 2
- Logs de VM 1 centralisés
- Structure /var/log/remote/ propre
- Documentation

#### Rôle 3 : Zabbix Installation Basique (6 heures)

**Jour 3 : Zabbix Server**
```
Étape 1 : Installer Zabbix Server + MySQL
  dnf install -y mariadb-server
  dnf install -y zabbix-server-mysql
  Durée : 1.5 heures

Étape 2 : Créer base données
  mysql
  CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
  CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix123';
  GRANT ALL ON zabbix.* TO 'zabbix'@'localhost';
  FLUSH PRIVILEGES;
  Durée : 30 min

Étape 3 : Initialiser schéma
  mysql -u zabbix -p zabbix < /path/to/zabbix.sql
  Durée : 30 min

Étape 4 : Configurer Zabbix
  Éditer : /etc/zabbix/zabbix_server.conf
  - DBHost=localhost
  - DBName=zabbix
  - DBUser=zabbix
  - DBPassword=zabbix123
  Durée : 30 min

Étape 5 : Démarrer services
  systemctl start mariadb zabbix-server
  systemctl enable mariadb zabbix-server
  Vérifier : systemctl status zabbix-server
  Durée : 30 min

Étape 6 : Installer Zabbix Web UI
  dnf install -y zabbix-web-mysql zabbix-web
  Accéder : http://192.168.1.30/zabbix
  Admin / zabbix
  Durée : 1 heure
```

**Livrable Rôle 3 Semaine 2** :
- Zabbix Server installé
- MySQL accessible
- Web UI opérationnelle
- Connexion admin vérifiée

### 📌 Checklist Semaine 2

- [ ] VM 1 : SSH port 2222, clés RSA, pas de root ✅
- [ ] VM 1 : Firewall restrictif ✅
- [ ] VM 1 : Fail2ban actif ✅
- [ ] VM 2 : rsyslog receiver ✅
- [ ] VM 1 : Logs centralisés vers VM 2 ✅
- [ ] VM 3 : Zabbix Server + MySQL ✅
- [ ] GitHub mis à jour ✅

---

## 📅 SEMAINE 3 : Cœur du SOC (22 heures)

### 🎯 Objectifs

- [ ] SELinux en mode enforcing (VM 1)
- [ ] Auditd actif avec règles (VM 1)
- [ ] Wazuh Manager installé (VM 2)
- [ ] Elasticsearch + Kibana opérationnels (VM 2)

### 📋 Détail par Rôle

#### Rôle 1 : SELinux & Auditd (6 heures)

**Jour 1-2 : SELinux**
```
Étape 1 : Vérifier état SELinux
  getenforce  # → Affiche "permissive"
  Durée : 5 min

Étape 2 : Configurer mode enforcing
  Éditer : /etc/selinux/config
  SELINUX=enforcing
  SELINUXTYPE=targeted
  Reboot
  Durée : 1.5 heures

Étape 3 : Permettre services web + ssh
  semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html(/.*)?"
  setsebool -P httpd_can_network_connect on
  setsebool -P ssh_keysign on
  Durée : 1 heure

Étape 4 : Tester (après reboot)
  getenforce  # → Affiche "enforcing"
  ausearch -ts recent -m AVC | head -20
  (Chercher violations)
  Durée : 30 min
```

**Jour 2 : Auditd**
```
Étape 1 : Installer auditd
  dnf install -y audit
  systemctl start auditd
  systemctl enable auditd
  Durée : 30 min

Étape 2 : Créer règles audit
  Éditer : /etc/audit/rules.d/custom.rules
  - Fichiers critiques : /etc/ssh/, /etc/sudoers, /etc/passwd
  - Système : execve, open/openat, connect
  - Sudo : tous les appels /usr/bin/sudo
  Durée : 1.5 heures

Étape 3 : Charger règles
  augenrules --load
  systemctl restart auditd
  Durée : 30 min

Étape 4 : Tester audit
  sudo whoami
  ausearch -k sudo_usage
  Vérifier log
  Durée : 30 min
```

**Livrable Rôle 1 Semaine 3** :
- SELinux enforcing
- Auditd logs visibles
- Règles audit documentées

#### Rôle 2 : Wazuh Manager (10 heures)

**Jour 1-3 : Installation Wazuh**
```
Étape 1 : Prérequis (1 heure)
  dnf install -y curl gnupg2
  Ajouter clé Wazuh GPG
  Ajouter repo Wazuh

Étape 2 : Installer Elasticsearch (3 heures)
  dnf install -y elasticsearch
  Créer dossier data
  Configuréer JVM (-Xms512m -Xmx512m important!)
  systemctl start elasticsearch
  Attendre démarrage (peut prendre 2 min)
  Tester : curl http://localhost:9200

Étape 3 : Installer Kibana (2 heures)
  dnf install -y kibana
  Éditer config pour Elasticsearch
  systemctl start kibana
  Accéder : http://192.168.1.20:5601

Étape 4 : Installer Wazuh Manager (3 heures)
  dnf install -y wazuh-manager
  systemctl start wazuh-manager
  Tester : /var/ossec/bin/wazuh-control status
  Admin UI devrait être accéssible

Étape 5 : Configuration initiale (1 heure)
  Ajouter les 3 VMs comme agents
  Importer règles de base
  Créer premiers dashboards
```

**Livrable Rôle 2 Semaine 3** :
- Wazuh Manager opérationnel
- Elasticsearch indexe les logs
- Kibana accessible (premier login)
- 3 VMs prêtes à recevoir agents

#### Rôle 3 : Grafana Dashboards Basique (6 heures)

**Jour 2-3 : Grafana Setup**
```
Étape 1 : Installer Grafana (1 heure)
  dnf install -y grafana-server
  systemctl start grafana-server
  systemctl enable grafana-server
  Accéder : http://192.168.1.30:3000
  Admin / admin (changer le mot de passe!)

Étape 2 : Ajouter Prometheus comme data source (1 heure)
  Configuration → Data Sources
  Type : Prometheus
  URL : http://192.168.1.30:9090
  Save & Test

Étape 3 : Créer premier dashboard (2 heures)
  Ajouter panel : CPU Usage (Prometheus metric)
  Ajouter panel : RAM Usage
  Ajouter panel : Disk Usage
  Save dashboard

Étape 4 : Installer Node Exporter (1 heure)
  Sur VM 1 : dnf install -y node_exporter
  systemctl start node_exporter
  Accéder : http://192.168.1.10:9100/metrics
  Ajouter dans Prometheus

Étape 5 : Tester graphiques (1 heure)
  Attendre 2-3 min de scrape
  Vérifier données dans Grafana
  Ajuster thresholds
```

**Livrable Rôle 3 Semaine 3** :
- Grafana opérationnel
- Prometheus scrape VM 1
- Dashboard CPU/RAM/Disque visible
- Métriques temps réel

### 📌 Checklist Semaine 3

- [ ] Rôle 1 : SELinux enforcing + Auditd ✅
- [ ] Rôle 2 : Wazuh + Elasticsearch + Kibana ✅
- [ ] Rôle 3 : Grafana + Prometheus ✅
- [ ] Tous : GitHub docs à jour ✅
- [ ] Snapshot VirtualBox (backup sécurité) ✅

---

## 📅 SEMAINE 4 : Intégration & Règles (18 heures)

### 🎯 Objectifs

- [ ] Wazuh Agents installés sur 3 VMs
- [ ] Logs collectés dans Wazuh
- [ ] 5+ règles personnalisées créées
- [ ] Tests d'attaques simulées

### 📋 Vue Simplifié

#### Rôle 1 : Wazuh Agent Installation (4 heures)

```
Étape 1 : Installer agent sur VM 1 (1 heure)
Étape 2 : Configurer ossec.conf (1 heure)
Étape 3 : Redémarrer et vérifier (1 heure)
Étape 4 : Enregistrer dans Wazuh Manager (1 heure)
```

#### Rôle 2 : Règles Wazuh Personnalisées (10 heures)

```
Jour 1 : Créer 5+ règles XML (6 heures)
  - Brute force SSH
  - Scan de ports
  - Upload fichier malveillant
  - Commande sudo anormale
  - Accès hors horaires

Jour 2 : Tester chaque règle (4 heures)
  - Générer logs de test
  - Vérifier alertes Wazuh
  - Ajuster sévérité
```

#### Rôle 3 : Alertes Grafana (4 heures)

```
Créer alertes pour :
  - CPU > 80% pendant 5 min
  - RAM > 70%
  - Service SSH down
  - Disque > 85%
Intégrer notifications (Slack/Email)
```

### 📌 Checklist Semaine 4

- [ ] Wazuh Agents sur les 3 VMs ✅
- [ ] Logs de VM 1 dans Wazuh ✅
- [ ] 5+ règles personnalisées ✅
- [ ] Première alerte déclenchée avec succès ✅
- [ ] Dashboard Kibana montre des données ✅

---

## 📅 SEMAINE 5 : Tests & Incidents (16 heures)

### 🎯 Objectifs

- [ ] Playbooks Incident Response écrits
- [ ] Scripts bash testés
- [ ] Tous les composants communiquent
- [ ] Prêt pour attaques

### 📋 Vue Simplifié

#### Rôle 1 : Validation (3 heures)
- Tester SSH restrictions
- Vérifier firewall bloque attaques
- Audit logs visible

#### Rôle 2 : Dashboard Kibana (5 heures)
- Dashboard brute force SSH
- Dashboard scans réseau
- Dashboard fichiers suspects
- Dashboard anomalies timing

#### Rôle 3 : Playbooks IR (8 heures)
- Écrire 4 playbooks bash
- Tester chaque playbook
- Intégrer webhooks Wazuh
- Documenter procédures

### 📌 Checklist Semaine 5

- [ ] Playbooks IR opérationnels ✅
- [ ] Dashboard Kibana prêts ✅
- [ ] Workflows de réaction testés ✅
- [ ] Équipe synchronisée ✅

---

## 📅 SEMAINE 6 : Attaques & Rapports Finals (20 heures)

### 🎯 Objectifs

- [ ] 5+ attaques simulées
- [ ] Chaque attaque = log + alerte + réaction
- [ ] Rapports post-incident
- [ ] Documentation complète

### 📋 Attaques à Simuler

**Jour 1-2 : Attaques Attaques**

1. **Nmap Scan** (Port scan)
2. **Brute Force SSH** (5+ tentatives)
3. **Upload Fichier** (Malveillant .sh ou .php)
4. **Commande Sudo** (Tentative élévation)
5. **Accès Anormal** (Hors horaires)

**Pour chaque** :
```
1. Rôle 1 : Confirme logs générés
2. Rôle 2 : Vérifie alerte Wazuh déclenchée
3. Rôle 3 : Exécute playbook IR + rapport
Durée par attaque : 2-3 heures
```

**Jour 3 : Tests complémentaires**

6. **Modification fichier sensible** (/etc/passwd)
7. **Processus suspect** (backdoor simulation)
8. **Fuite réseau** (exfiltration simulation)

**Jour 4 : Rapports**

```
Chaque rôle produit :
  - Rapport technique détaillé
  - Screenshots + graphiques
  - Analyse post-mortem
  - Recommandations futures
```

### 📌 Checklist Semaine 6

- [ ] Attaque 1 : Nmap détectée + bloquée ✅
- [ ] Attaque 2 : Brute force SSH → Fail2ban ✅
- [ ] Attaque 3 : Upload malveillant → Alerte ✅
- [ ] Attaque 4 : Sudo anomalie → Audit ✅
- [ ] Attaque 5 : Accès anormal → Détecté ✅
- [ ] Rapports finals rédigés ✅
- [ ] GitHub finalisé + README complet ✅

---

## 📊 Heures Totales par Rôle

| Rôle | S1 | S2 | S3 | S4 | S5 | S6 | Total |
|---|---|---|---|---|---|---|---|
| **Rôle 1** | 7 | 8 | 6 | 4 | 3 | 6 | **34h** |
| **Rôle 2** | 7 | 6 | 10 | 10 | 5 | 8 | **46h** |
| **Rôle 3** | 6 | 6 | 6 | 4 | 8 | 6 | **36h** |
| **Équipe** | 20 | 20 | 22 | 18 | 16 | 20 | **116h** |

**Par personne** : 34-46 heures sur 6 semaines = **6-8h/semaine**

---

## 🗓️ Calendrier Recommandé

### Option 1 : Parallèle (Recommandé)

```
Chaque rôle travaille indépendamment
S1 : Chacun sa VM (en parallèle)
S2 : Chacun sa config
...
Réunions 2x/semaine pour sync
Durée totale : 6 semaines
```

### Option 2 : Séquentiel (Plus lent)

```
S1-2 : Rôle 1 seul
S2-3 : Rôle 1 + Rôle 2
S3-4 : Tous les 3
Avantage : Pédagogique, moins de chaos
Durée totale : 8-10 semaines
```

### Option 3 : Équipe Seule (Pas de groupe)

```
Une seule personne = 3x plus long
Peut combiner rôles, moins efficient
Durée totale : 9-12 semaines
```

---

## 📋 Format Réunions d'Équipe

### Lundi (30 min) : Briefing

```
Ordre du jour :
1. État semaine précédente (5 min)
2. Blocages ou problèmes (10 min)
3. Objectifs cette semaine (10 min)
4. Dépendances inter-rôles (5 min)
```

### Jeudi (30 min) : Debrief + Tests

```
Ordre du jour :
1. Avancée travail (10 min)
2. Tests d'intégration (15 min)
3. Documentations à jour ? (5 min)
```

---

## 📌 Points de Synchronisation Critiques

### Entre Rôle 1 et Rôle 2

```
Rôle 1 DOIT terminer avant Rôle 2 installe :
  ✅ rsyslog config (logs + SSH)
  ✅ Auditd rules
  ✅ Firewall ports 514/1514
```

### Entre Rôle 2 et Rôle 3

```
Rôle 2 DOIT créer avant Rôle 3 réagit :
  ✅ Webhooks Wazuh configurés
  ✅ Alertes avec IDs uniques
  ✅ Format JSON standardisé
```

### Avant Semaine 6 (Attaques)

```
TOUS les 3 DOIVENT avoir :
  ✅ VMs stables et snapshots
  ✅ Logs centralisés OK
  ✅ Alertes déclenchées 1x OK
  ✅ Playbooks IR testés
```

---

## 🚀 Optimisations Possibles

### Pour Accélérer

- Utiliser **Ansible** pour déployer configs identiques
- **Docker Compose** pour Wazuh au lieu de installation manuelle
- **Templates** VirtualBox pour cloner VMs rapidement

### Pour Approfondir

- Ajouter **Splunk** (SIEM payant, très utilisé)
- Intégrer **Threat Intelligence** (banques IP malveillantes)
- Mettre en place **Backup + Recovery** (DR)
- Tester **Load balancing** (Nginx reverse proxy)

---

## 📚 Livrables Finaux à Produire

### Par Rôle

**Rôle 1**
- [ ] Documentation hardening (Markdown)
- [ ] Checklist sécurité
- [ ] Rapport Lynis

**Rôle 2**
- [ ] Règles Wazuh (XML)
- [ ] Dashboard Kibana (export JSON)
- [ ] Analyses 3 attaques

**Rôle 3**
- [ ] Playbooks IR (scripts bash)
- [ ] Dashboard Grafana (screenshots)
- [ ] Rapports post-incident

### Commun

**GitHub Repo**
- [ ] README complet avec architecture
- [ ] 01_PREPARATION/ (ce qui tu lis)
- [ ] 02_INSTALLATION/ (étapes par rôle)
- [ ] 03_CONFIGURATION/ (configs spécifiques)
- [ ] 04_TESTS/ (scénarios d'attaques)
- [ ] 05_RAPPORTS/ (documents finaux)

**PDF Rapport**
- [ ] Résumé exécutif (1 page)
- [ ] Architecture détaillée (3 pages)
- [ ] Résultats tests (5 pages)
- [ ] Conclusions + recommandations (2 pages)

---

## 🎯 Métriques de Succès

À la fin du projet, tu DOIS pouvoir :

- ✅ Simuler une attaque brute force SSH
- ✅ Voir l'alerte dans Wazuh < 1 min après attaque
- ✅ Bloquer l'IP automatiquement via playbook
- ✅ Générer rapport post-incident
- ✅ Expliquer chaque composant du SOC
- ✅ Reproduire le projet de zéro en 3 jours
- ✅ Ajouter nouvelles règles sans aide

---

## 📞 Support & Ressources

### Si tu bloques

1. Relire la documentation du composant
2. Chercher dans les logs (`tail -f /var/log/...`)
3. Demander à un pair ou formateur
4. Consulter forums officiels (Wazuh, Zabbix, Prometheus)

### Ressources Utiles

- Wazuh Docs : https://documentation.wazuh.com/
- Rocky Docs : https://docs.rockylinux.org/
- Prometheus Docs : https://prometheus.io/docs/
- Grafana Docs : https://grafana.com/docs/

---

## ✨ Bravo !

Tu as un plan complet pour 6 semaines. Le projet est **faisable**,  **pédagogique**, et te donnera de vraies compétences en:

- Administration système (Linux hardening)
- Cybersécurité (SIEM, IDS, logs)
- Incident response (réaction, playbooks)
- Travail en équipe

**Bon courage ! 🚀**

---

**Version** : 1.0  
**Dernière mise à jour** : Février 2026  
**Estimé pour 3 personnes travaillant en parallèle**
