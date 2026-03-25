# 🔒 Mini SOC Sécurisé sous Rocky Linux

**Infrastructure d'entreprise simulée avec équipe Blue Team (défense)**

> Un projet complet de cybersécurité pour étudiants en administration systèmes et réseaux  
> Niveau : 2e année | Durée : 6 semaines | Équipe : 3 rôles

---

## 📸 Aperçu Visuel

```
┌─────────────────────────────────────────────────────────────┐
│                  INTERNET / ATTAQUANTS                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                    [FIREWALL]
                         │
            ┌────────────┼────────────┐
            │            │            │
     ┌──────▼────┐ ┌─────▼───┐ ┌────▼──────┐
     │   VM 1    │ │  VM 2   │ │   VM 3    │
     │ Serveur   │ │   SOC   │ │ Monitoring│
     │   Web     │ │ & Logs  │ │    & IR   │
     └──────┬────┘ └─────┬───┘ └────┬──────┘
            │            │           │
            └────────────┼───────────┘
                 (Logs + Alertes)
```

---

## 🎯 Objectifs du Projet

Construire un **mini SOC** (Security Operations Center) fonctionnel pour :

✅ **Sécuriser** les systèmes (hardening, logs, audit)  
✅ **Surveiller** les activités en temps réel  
✅ **Détecter** les attaques automatiquement  
✅ **Réagir** aux incidents rapidement  

---

## 👥 Les 3 Rôles

### 🔒 Rôle 1 : Admin Système & Hardening
**Travaille AVANT les attaques**

- Installation Rocky Linux minimal
- SSH sécurisé (clés, port custom, pas root)
- Firewall restrictif (Firewalld)
- Protection brute force (Fail2ban)
- Audit système (SELinux, Auditd)
- Centralisation logs

**Machine** : VM 1 (Serveur Web, 192.168.1.10)  
**Heures** : 34 heures

---

### 🔍 Rôle 2 : SOC / Logs / Détection
**Travaille PENDANT les attaques**

- Centralisation des logs (rsyslog + Wazuh)
- SIEM (Wazuh Manager + Elasticsearch)
- Dashboards temps réel (Kibana)
- Règles de détection personnalisées
- Alertes automatiques

**Machine** : VM 2 (SOC & Logs, 192.168.1.20)  
**Heures** : 46 heures

---

### 📊 Rôle 3 : Monitoring & Incident Response
**Travaille APRÈS la détection**

- Supervision infrastructure (Zabbix/Prometheus/Grafana)
- Détection d'anomalies
- Playbooks Incident Response (IR)
- Scripts automatisés
- Rapports post-incident

**Machine** : VM 3 (Monitoring, 192.168.1.30)  
**Heures** : 36 heures

---

## 📋 Structure du Dépôt

```
mini-soc-rocky/
│
├── README.md                    ← Tu es ici
│
├── 01_PREPARATION/              ← COMMENCER PAR ICI
│   ├── INDEX.md                 (Table des matières)
│   ├── 01_contexte_objectifs.md (Vue d'ensemble)
│   ├── 02_architecture_schema.md (Architectre réseau)
│   ├── 03_roles_equipes.md      (Rôles détaillés)
│   ├── 04_prerequis.md          (Matériel requis)
│   └── 05_timeline.md           (Planning 6 semaines)
│
├── 02_INSTALLATION/             ← Instructions étape par étape
│   ├── 01_vm1_installation.md
│   ├── 02_vm2_installation.md
│   └── 03_vm3_installation.md
│
├── 03_CONFIGURATION/            ← Fichiers de configuration
│   ├── vm1-sshd-config
│   ├── vm1-firewall-rules.sh
│   ├── vm2-rsyslog-config
│   ├── vm2-wazuh-rules.xml
│   ├── vm3-zabbix-alerts.conf
│   └── scripts/                 (Bash, Ansible)
│
├── 04_TESTS/                    ← Scénarios d'attaques
│   ├── 01_brute_force_ssh.md
│   ├── 02_port_scan_nmap.md
│   ├── 03_upload_malveillant.md
│   ├── 04_sudo_anomaly.md
│   └── 05_time_anomaly.md
│
├── 05_RAPPORTS/                 ← Documents finaux
│   ├── rapport_rôle1_hardening.md
│   ├── rapport_rôle2_detection.md
│   ├── rapport_rôle3_incident_response.md
│   └── rapport_global.pdf
│
└── RESSOURCES/                  ← Fichiers utiles
    ├── diagrammes/
    ├── checklists/
    └── templates/
```

---

## 🚀 Démarrage Rapide

### Étape 0 : Préparation (TRÈS IMPORTANT !)

```bash
# 1. Clone ce dépôt
git clone <url-du-repo> mini-soc-rocky
cd mini-soc-rocky

# 2. Lis la préparation
cd 01_PREPARATION
# Ouvre INDEX.md et lis dans cet ordre :
#   1. 01_contexte_objectifs.md (15 min)
#   2. 02_architecture_schema.md (15 min)
#   3. 04_prerequis.md (10 min) ← IMPORTANT: Vérifier matériel
#   4. 05_timeline.md (10 min)
#   5. 03_roles_equipes.md (20 min)

# 3. Vérifier matériel
# RAM : 16 GB min, 32 GB idéal
# Disque : 150 GB SSD
# CPU : 8 cores
```

### Étape 1 : Installer Hyperviseur

```bash
# macOS
brew install virtualbox

# Linux
sudo dnf install -y VirtualBox    # Fedora/Rocky
sudo apt install -y virtualbox    # Ubuntu/Debian

# Windows
# Télécharger depuis https://www.virtualbox.org/

# Vérifier installation
vboxmanage --version
```

### Étape 2 : Télécharger ISO

```bash
# Rocky Linux (3x pour 3 VMs)
wget https://rockylinux.org/download  # Télécharger Minimal

# Vérifier intégrité
sha256sum Rocky-9.x-Minimal-x86_64-dvd.iso
# Comparer avec fichier .sha256 officiel
```

### Étape 3 : Commencer Installation

```bash
# Lire 02_INSTALLATION/
# Suivre les étapes détaillées pour chaque VM

# Par rôle :
# Rôle 1 : 02_INSTALLATION/01_vm1_installation.md
# Rôle 2 : 02_INSTALLATION/02_vm2_installation.md
# Rôle 3 : 02_INSTALLATION/03_vm3_installation.md
```

---

## 📊 Timeline du Projet

```
S1 : Préparation & Infrastructure (20h)
  Créer 3 VMs, configuration réseau basique

S2 : Hardening & Configuration (20h)
  SSH sécurisé, Firewall, rsyslog, Zabbix basics

S3 : Cœur du SOC (22h)
  SELinux, Auditd, Wazuh, Elasticsearch, Kibana

S4 : Intégration & Règles (18h)
  Wazuh Agents, règles personnalisées, dashboards

S5 : Tests & IR (16h)
  Playbooks Incident Response, scripts bash

S6 : Attaques & Rapports (20h)
  Simuler 5 attaques, analyses, rapports finals

TOTAL : 116 heures = 6 semaines à 6-8h/semaine
```

---

## ✨ Compétences Apprises

### Administration Système
- ✅ Installation et hardening Rocky Linux
- ✅ SSH sécurisé (clés, authentification)
- ✅ Firewall (Firewalld)
- ✅ Audit système (SELinux, Auditd)
- ✅ Logs et centralisation

### Cybersécurité
- ✅ Concepts SIEM (Security Information & Event Management)
- ✅ Détection d'intrusions (IDS/SIEM)
- ✅ Vecteurs d'attaque courants
- ✅ Blue Team (défense)
- ✅ Incident Response

### Outils Professionnels
- ✅ **Wazuh** : SIEM/IDS open source
- ✅ **Elasticsearch** : Base de données logs
- ✅ **Kibana** : Visualisation logs temps réel
- ✅ **Zabbix** ou **Prometheus/Grafana** : Monitoring
- ✅ **Fail2ban** : Protection brute force
- ✅ Bash scripting pour automatisation

### Soft Skills
- ✅ Travail en équipe structurée
- ✅ Documentation technique
- ✅ Communication
- ✅ Résolution de problèmes

---

## 🏆 Valeur du Projet

### Pour ton Portfolio
- ✅ Excellent projet pour CV/LinkedIn
- ✅ Démontre compétences réelles entreprise
- ✅ Code + documentation sur GitHub
- ✅ Reproductible et scalable

### Pour ton Apprentissage
- ✅ Cas réaliste (SOC entreprise)
- ✅ Contexte Blue Team (plus rare que Red Team)
- ✅ Architecture complète (pas juste un service)
- ✅ Prépare à vrais rôles en entreprise

### Niveaux d'Étude
- BTS SIO ⭐⭐⭐⭐⭐
- Licence informatique ⭐⭐⭐⭐
- Master cybersécurité ⭐⭐⭐
- Bootcamp cybersec ⭐⭐⭐⭐⭐

---

## 🎓 Public Cible

- **Étudiants** en administration systèmes et réseaux (2-3e année)
- **Apprentis** en cybersécurité
- **Formateurs** cherchant projet complet
- **Auto-apprenants** en infrastructure sécurisée

**Prérequis minimum** :
- Linux de base (commandes, permissions)
- SSH et SCP
- Concepts réseau (IP, ports, firewalls)
- Admin système (users, services, packages)

---

## 🚨 Attaques à Simuler

Tu vas tester **5+ attaques réalistes** :

1. **Nmap Port Scan** → Détection scan réseau
2. **Brute Force SSH** → Fail2ban + Wazuh
3. **Upload Fichier Malveillant** → Détection malveillance
4. **Sudo Anomaly** → Élévation privilèges
5. **Off-Hours Access** → Timing anormal

**Chaque attaque** doit :
```
1. Générer un log (visible en temps réel)
2. Déclencher une alerte (Wazuh rule)
3. Avoir une réaction (IR playbook)
```

---

## 📚 Documentation

Chaque section a sa propre documentation :

| Section | Contenu | Lecteurs |
|---|---|---|
| **01_PREPARATION** | Contexte + planning | Tous |
| **02_INSTALLATION** | Pas-à-pas installation | Tech leads |
| **03_CONFIGURATION** | Fichiers configs | Chaque rôle |
| **04_TESTS** | Scénarios attaques | QA + IR |
| **05_RAPPORTS** | Résultats + conclusions | Direction |

---

## 🤝 Mode Collaboration

### En Équipe de 3 (Recommandé)

```
Semaine 1
├─ Rôle 1 crée VM 1
├─ Rôle 2 crée VM 2  (parallèle)
├─ Rôle 3 crée VM 3  (parallèle)
└─ Réunion jeudi : vérifier inter-connectivité

Semaine 2-6
├─ Chacun sur son rôle
├─ Points de sync lundi/jeudi
└─ Dépendances managées
```

### Solo (Plus long)

```
Chaque rôle fait tout, mais documente bien la séparation.
Durée : 9-12 semaines (instead of 6)
Avantage : Comprends tout le système
```

---

## ⚙️ Technologies Utilisées

| Composant | Rôle | Pourquoi |
|---|---|---|
| **Rocky Linux** | OS | Équivalent RHEL, professionnel |
| **Firewalld** | Firewall | Native Rocky, simple |
| **SSH** | Accès sécurisé | Standard industrie |
| **SELinux** | MAC | Sécurité obligatoire |
| **Auditd** | Audit système | Compliance, traces |
| **rsyslog** | Logs transport | Centralisation |
| **Wazuh** | SIEM/IDS | Open source, puissant |
| **Elasticsearch** | Index logs | Scalable, pro |
| **Kibana** | Visualisation | Standard ELK |
| **Zabbix** | Monitoring | Alternatif Prometheus |
| **Prometheus** | Metrics | Alternative légère |
| **Grafana** | Dashboards | Visualisation temps réel |
| **Fail2ban** | Brute force | Léger et efficace |

---

## 🔧 Prérequis Matériel

### Minimum (Serré)

| Ressource | Quantité |
|---|---|
| RAM | 16 GB |
| CPU | 8 cores |
| Disque | 150 GB SSD |
| Réseau | 1 Gbps |

### Recommandé (Confortable)

| Ressource | Quantité |
|---|---|
| RAM | 32 GB |
| CPU | 16 cores |
| Disque | 300 GB SSD NVMe |
| Réseau | Filaire Gigabit |

**Distribution RAM par VM** :
```
Host OS      : 4-6 GB
VM 1 (Web)   : 4 GB
VM 2 (SOC)   : 6 GB  ← Important, Elasticsearch
VM 3 (Monitor): 4 GB
───────────────────
TOTAL        : 20-22 GB
```

---

## 📞 Support & Ressources

### Documentation Officielle

| Outil | URL |
|---|---|
| Rocky Linux | https://docs.rockylinux.org/ |
| Wazuh | https://documentation.wazuh.com/ |
| Elasticsearch | https://www.elastic.co/guide/en/elasticsearch/reference/ |
| Prometheus | https://prometheus.io/docs/ |
| Grafana | https://grafana.com/docs/ |
| Zabbix | https://www.zabbix.com/documentation/ |

### Communautés

- r/linuxadministration (Reddit)
- Wazuh Community (forums)
- Stack Overflow (questions tech)
- TryHackMe (labs pratiques)

---

## 📝 Licence & Attribution

Ce projet est créé pour fins éducatives par **La Plateforme**.

Libre d'utilisation pour :
- Éducation
- Formation
- Apprentissage personnel
- Forks publics (avec attribution)

---

## 🎓 Prochaines Étapes

1. **Lire** [`01_PREPARATION/INDEX.md`](01_PREPARATION/INDEX.md)
2. **Vérifier** matériel (document 4)
3. **Créer** équipe (3 personnes idéalement)
4. **Installer** hyperviseur
5. **Commencer** installation S1 (02_INSTALLATION/)

---

## 💡 Conseils Finaux

> **Ce n'est pas un tutoriel à copier-coller.**
> 
> C'est une expérience d'apprentissage.
> 
> Comprends **pourquoi** chaque étape.  
> Les meilleurs apprentissages viennent des **erreurs**.
> 
> **Lire les logs**, c'est 80% du travail d'admin/sécurité.

---

## 📊 Statistiques du Projet

- **Durée totale** : 6 semaines
- **Équipe** : 3 personnes (ou 1 solo)
- **Heures totales** : 116h (19h/semaine équipe)
- **VMs créées** : 3 + 1 optionnel (Kali)
- **Attaques simulées** : 5+
- **Règles Wazuh** : 5+ personnalisées
- **Compétences apprises** : 15+
- **Valeur portfolio** : ⭐⭐⭐⭐⭐

---

**Version** : 1.0  
**Créé** : Février 2026  
**Maintenu par** : Équipe La Plateforme  
**État** : Production ✅

---

**🚀 Prêt ? Commence par [`01_PREPARATION/INDEX.md`](01_PREPARATION/INDEX.md) !**
