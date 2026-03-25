# 🛡️ Mini SOC Sécurisé sous Rocky Linux

> **Infrastructure d'entreprise simulée protégée par une équipe Blue Team | Projet pédagogique complet**

![Version](https://img.shields.io/badge/version-2.0-blue)
![Status](https://img.shields.io/badge/status-Active-green)
![License](https://img.shields.io/badge/license-CC--BY--SA-orange)
![Level](https://img.shields.io/badge/level-Intermédiaire+-red)

---

## 📖 Vue d'ensemble

Ce projet simule une **infrastructure d'entreprise réelle** protégée par une équipe SOC (Security Operations Center). Vous incarnerez une équipe Blue Team chargée de **sécuriser, surveiller, détecter et réagir aux attaques**.

### 🎯 Votre mission
- 🔒 **Sécuriser** les systèmes (hardening, firewall, audit)
- 👀 **Surveiller** les activités en temps réel (logs, SIEM, monitoring)
- 🚨 **Détecter** les attaques automatiquement (règles, IDS)
- ⚡ **Réagir** aux incidents (playbooks, automatisation)

### ⏱️ Durée et niveau
- **Durée** : 6 semaines
- **Niveau** : 2e année admin/réseaux
- **Format** : Travail en équipe (3 rôles spécialisés)

---

## 🏗️ Architecture de l'infrastructure

```
┌─────────────────────────────────────────────────────────┐
│  INTERNET / ATTAQUANTS (Red Team ou tests)              │
└─────────────────────┬───────────────────────────────────┘
                      │
                 [FIREWALL]
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   ┌────▼────┐   ┌────▼────┐   ┌───▼─────┐
   │  VM 1   │   │  VM 2   │   │  VM 3   │
   │ Serveur │   │   SOC   │   │ Monitor │
   │  Web    │◄──┤  Wazuh  │◄──┤ Grafana │
   └────┬────┘   └────┬────┘   └─────────┘
        │             │
        └─────────────┘
     (Logs & Alertes)
```

### 🖥️ Description des machines

| VM | Hostname | IP | Rôle | Outils principaux |
|---|----------|-------|------|-------------------|
| **VM1** | soc-web-rocky | 192.168.1.10 | Serveur Web (cible) | Nginx, SSH, Fail2ban, Auditd |
| **VM2** | soc-siem-rocky | 192.168.1.20 | SOC / Détection | Wazuh Manager, Elasticsearch |
| **VM3** | soc-monitor-rocky | 192.168.1.30 | Monitoring / IR | Prometheus, Grafana, Node Exporter |

---

## 📂 Structure du dépôt

```
Mini_SOC/
├── 📖 01_Preparation/              ← Lire EN PREMIER (contexte & objectifs)
│   ├── 01_contexte_objectifs.md
│   ├── 02_architecture_schema.md
│   ├── 03_roles_equipes.md
│   ├── 04_prerequis.md
│   └── 05_timeline.md
│
├── 🔒 02_ADMIN_Hardening/          ← RÔLE 1 : Sécuriser les systèmes
│   ├── 01_installation_base.md
│   ├── 02_partitionnement.md
│   ├── 03_config_reseau.md
│   ├── 04_comptes_acces.md
│   ├── 05_ssh_hardening.md
│   ├── 06_firewall.md
│   ├── 07_selinux.md
│   ├── 08_fail2ban.md
│   ├── 09_auditd.md
│   └── 10_lynis.md
│
├── 🔵 03_BLUE_TEAM_SOC/            ← RÔLE 2 : Détecter les attaques
│   ├── 04_wazuh_architecture.md
│   ├── 05_wazuh_manager_install.md
│   ├── 06_wazuh_agents_install.md
│   ├── 07_wazuh_integration.md
│   ├── 08_wazuh_interface.md
│   ├── 09_regles_syntax.md
│   ├── 10_detection_bruteforce_ssh.md
│   ├── 11_detection_sudo.md
│   ├── 12_detection_nmap.md
│   ├── 13_detection_uploads.md
│   └── 14_detection_horaires.md
│
├── 📊 04_BLUE_TEAM_Supervision/    ← RÔLE 3 : Surveiller & Réagir
│   ├── 01_choix_outil.md
│   ├── 02_install_monitoring.md
│   ├── 03_metriques_surveillance.md
│   ├── 04_dashboards.md
│   ├── 05_configuration_alertes.md
│   ├── 06_seuils_baselines.md
│   ├── 07_integration_wazuh.md
│   ├── 08_procedures_ir.md
│   ├── 09_playbooks_ir.md
│   ├── 10_scripts_automatises.md
│   └── CHEATSHEET.md
│
├── 🔴 05_RED_TEAM_Attaques/       ← Attaques à détecter
│   ├── 01_nmap.md
│   ├── 02_bruteforce_ssh.md
│   ├── 03_upload_malveillant.md
│   ├── 04_elevation_privileges.md
│   ├── 05_connexion_hors_horaires.md
│   ├── 06_web_shells.md
│   ├── 07_cve.md
│   └── 08_lateral_movement.md
│
├── 📚 06_Annexes/                  ← Ressources & configurations
│   ├── ansible/                    ← Playbooks automatisation
│   ├── configs/                    ← Fichiers de configuration
│   ├── memos/                      ← Mémos rapides Linux/SSH/etc
│   ├── scripts/                    ← Scripts utilitaires
│   └── wazuh_rules/                ← Règles Wazuh personnalisées
│
└── ⚡ 07_Installation_Script/       ← Scripts d'installation automatisée
    ├── INSTALLATION_COMPLETE_GUIDE.md
    ├── vm1_install.sh
    ├── vm2_install.sh
    ├── vm3_install.sh
    ├── VM1_README.md
    ├── VM2_README.md
    └── VM3_README.md
```

---

## 👥 Les 3 rôles et responsabilités

Chaque personne/équipe a une mission bien définie et travaille sur une VM spécifique.

### 👨‍💻 **Rôle 1 : Administrateur Système & Hardening** → [Voir 02_ADMIN_Hardening/](02_ADMIN_Hardening/)
**Mission** : Rendre les serveurs difficiles à compromettre  
**Responsable de** : VM1  
**Phase** : AVANT les attaques (prévention)

✅ Installation Rocky Linux minimal et sécurisé  
✅ Partitionnement + configuration réseau  
✅ SSH hardening (clés, port custom, timeouts)  
✅ Firewall (firewalld) avec zones et règles  
✅ SELinux en mode enforcing  
✅ Fail2ban pour protection brute force  
✅ Auditd pour traçabilité complète  
✅ Checklist Lynis et rapport de sécurité

**Livrables** : VM1 sécurisée, rapport Lynis, documentation

---

### 🔍 **Rôle 2 : SOC / Logs / Détection d'intrusion (Blue Team)**
**Mission** : Voir ce qui se passe et détecter les attaques  
**Quand** : *Pendant* les attaques (détection)

- Centralisation des logs (SSH, Web, système, auditd, firewall)
- Installation Wazuh (SIEM/IDS)
- Configuration agents Wazuh sur serveurs
- Création de **règles personnalisées** :
  - Brute force SSH
  - Élévation privilèges (sudo)
  - Scans réseau (Nmap)
  - Uploads malveillants
  - Connexions hors horaires

**Livrables** : Règles Wazuh (XML), screenshots alertes, analyses d'attaques

---

### 📊 **Rôle 3 : Supervision & Incident Response (Blue Team)**
**Mission** : Assurer la disponibilité et réagir quand ça dérape  
**Quand** : *Après* la détection (réaction)

- Supervision avec Zabbix ou Prometheus + Grafana
- Surveillance : CPU, RAM, disques, services, temps réponse
- Détection d'anomalies (pics CPU, disques pleins, services down)
- **Playbooks IR** (Incident Response) :
  - Procédures écrites pour chaque type d'attaque
  - Scripts Bash/Ansible pour réactions semi-automatiques
  - Blocage IP, désactivation compte, isolation VM

**Livrables** : Dashboards, playbooks IR, scripts de réponse, rapports

---

## 📚 Structure du dépôt

```
📁 mini-soc-rocky/
│
├── README.md                           # ← Vous êtes ici
├── SOMMAIRE.md                         # Sommaire complet avec tous les liens
│
├── 📁 01_PREPARATION/                  # Contexte & Architecture
│   ├── 01_contexte_objectifs.md
│   ├── 02_architecture_schema.md
│   ├── 03_roles_equipes.md
│   ├── 04_prerequis.md
│   └── 05_timeline.md
│
├── 📁 02_ADMIN_HARDENING/              # Rôle 1 : Admin Système
│   ├── 01_installation_base.md
│   ├── 02_partitionnement.md
│   ├── 03_config_reseau.md
│   ├── 04_comptes_acces.md
│   ├── 05_ssh_hardening.md
│   ├── 06_firewall.md
│   ├── 07_selinux.md
│   ├── 08_fail2ban.md
│   ├── 09_auditd.md
│   ├── 10_lynis.md
│   └── 🧪 tests_verification.md
│
├── 📁 03_BLUE_TEAM_SOC/                # Rôle 2 : SOC / Détection
│   ├── 01_sources_logs.md
│   ├── 02_rsyslog_filebeat.md
│   ├── 03_transport_logs.md
│   ├── 04_wazuh_architecture.md
│   ├── 05_wazuh_manager_install.md
│   ├── 06_wazuh_agents_install.md
│   ├── 07_wazuh_integration.md
│   ├── 08_wazuh_interface.md
│   ├── 09_regles_syntax.md
│   ├── 10_detection_bruteforce_ssh.md
│   ├── 11_detection_sudo.md
│   ├── 12_detection_nmap.md
│   ├── 13_detection_uploads.md
│   ├── 14_detection_horaires.md
│   ├── LIVRABLES.md
│   └── 🧪 tests_verification.md
│
├── 📁 04_BLUE_TEAM_SUPERVISION/       # Rôle 3 : Monitoring & IR
│   ├── 01_choix_outil.md
│   ├── 02_install_monitoring.md
│   ├── 03_metriques_surveillance.md
│   ├── 04_dashboards.md
│   ├── 05_configuration_alertes.md
│   ├── 06_seuils_baselines.md
│   ├── 07_integration_wazuh.md
│   ├── 08_procedures_ir.md
│   ├── 09_playbooks_ir.md
│   ├── 10_scripts_automatises.md
│   ├── 11_gestion_incidents.md
│   ├── LIVRABLES.md
│   └── 🧪 tests_verification.md
│
├── 📁 05_RED_TEAM_ATTAQUES/           # Attaques à simuler
│   ├── 01_nmap.md
│   ├── 02_bruteforce_ssh.md
│   ├── 03_upload_malveillant.md
│   ├── 04_elevation_privileges.md
│   ├── 05_connexion_hors_horaires.md
│   ├── 06_web_shells.md
│   ├── 07_cve.md
│   ├── 08_lateral_movement.md
│   └── LIVRABLES.md
│
├── 📁 06_ANNEXES/
│   ├── 📁 memos/
│   │   ├── 01_memo_linux.md
│   │   ├── 02_memo_ssh.md
│   │   ├── 03_memo_firewalld.md
│   │   ├── 04_memo_wazuh.md
│   │   └── 05_depannage.md
│   │
│   ├── 📁 scripts/
│   │   ├── install_docker.sh
│   │   ├── install_wazuh.sh
│   │   ├── harden_system.sh
│   │   └── response_automate.sh
│   │
│   ├── 📁 configs/
│   │   ├── sshd_config
│   │   ├── firewalld_zones.xml
│   │   ├── rsyslog.conf
│   │   └── auditd_rules.conf
│   │
│   ├── 📁 wazuh_rules/
│   │   ├── bruteforce_ssh.xml
│   │   ├── privilege_escalation.xml
│   │   ├── malware_detection.xml
│   │   └── custom_rules.xml
│   │
│   └── 📁 ansible/
│       ├── playbook_hardening.yml
│       ├── playbook_monitoring.yml
│       └── playbook_ir.yml
│
└── 📄 DOCUMENTATION_TECHNIQUE.docx      # Documentation complète (final)
```

---

## ⚡ Démarrage rapide

### 1️⃣ Lire en premier
```bash
# Commencez par comprendre le contexte
01_PREPARATION/01_contexte_objectifs.md
01_PREPARATION/02_architecture_schema.md
01_PREPARATION/03_roles_equipes.md
```

### 2️⃣ Suivre le sommaire
```bash
# Allez sur le sommaire complet
cat SOMMAIRE.md
```

### 3️⃣ Choisir votre rôle et commencer
```bash
# Rôle 1 (Admin) ?
02_ADMIN_HARDENING/01_installation_base.md

# Rôle 2 (SOC) ?
03_BLUE_TEAM_SOC/01_sources_logs.md

# Rôle 3 (Monitoring/IR) ?
04_BLUE_TEAM_SUPERVISION/01_choix_outil.md
```

### 4️⃣ Tester les attaques
```bash
# Une fois les défenses en place
05_RED_TEAM_ATTAQUES/01_nmap.md
```

---

## 🧪 Attaques obligatoires à simuler

Chaque attaque doit générer un log → déclencher une alerte → avoir une réaction.

| Attaque | Rôle 1 | Rôle 2 | Rôle 3 |
|---------|--------|--------|--------|
| **Nmap** (reconnaissance) | Firewall bloque | Wazuh détecte | Dashboards alertent |
| **Brute force SSH** | Fail2ban bloque | Règles alertent | Blocage IP automatique |
| **Upload malveillant** | SELinux/Firewall | Wazuh analyse | Suppression fichier |
| **Élévation privilèges (sudo)** | Auditd enregistre | Règles alertent | Incident ticket |
| **Connexion hors horaires** | Logs disponibles | Règles alertent | Alerte superviseur |

---

## 📋 Prérequis

### Matériel
- PC/Serveur avec **VirtualBox** ou **VMware**
- RAM : **16 GB minimum** (8 par VM)
- Disque : **200 GB** (50-60 GB par VM)
- Réseau : **VM bridge ou nat-network**

### Logiciels
- **VirtualBox 7.0+** ou **VMware 17+**
- **ISO Rocky Linux 8.x ou 9.x**
- **ISO Kali Linux** (optionnel, pour Red Team)
- Outils : SSH client, éditeur texte

### Connaissances préalables
- Notions Linux de base (commandes, fichiers, utilisateurs)
- Réseau : IP, ports, firewall
- Sécurité : concepts basiques (chiffrement, authentification)

---

## 🎓 Compétences validées

À l'issue de ce projet, vous maîtriserez :

✅ **Linux entreprise** : Installation, partitionnement, gestion système sur RHEL/Rocky  
✅ **Sécurité système** : Hardening complet (SSH, firewall, SELinux, audit)  
✅ **SOC / Blue Team** : Détection d'intrusion, règles personnalisées  
✅ **SIEM** : Centralisation logs, Wazuh, alertes temps réel  
✅ **Monitoring** : Zabbix ou Prometheus, dashboards, baselines  
✅ **Incident Response** : Playbooks, scripts automatisés, gestion tickets  
✅ **Automation** : Bash, Ansible, scripting défensif  
✅ **Travail en équipe** : Rôles structurés, communication  

---

## 💡 Conseils d'utilisation

### 📖 Comment lire ce dépôt
- **Chaque fichier `.md` est autonome** : peut être lu seul, comme une fiche de cours
- **Suivez l'ordre du sommaire** pour avoir une progression logique
- **Chaque section a** : objectif, concept, étapes, exemple, vérification

### 🛠️ Comment reproduire le projet
1. **Installez 3 VMs** Rocky Linux (ou 4 avec Kali)
2. **Attribuez les rôles** (1 personne = 1 rôle)
3. **Suivez les étapes** dans l'ordre du sommaire
4. **Testez à chaque étape** : commandes de vérification fournies
5. **Simulez les attaques** à la fin (05_RED_TEAM_ATTAQUES)

### 📚 À la fin du projet
- **Relisez les fiches** comme des mémo pour mémoriser
- **Réutilisez les scripts** pour d'autres projets
- **Créez un rapport de synthèse** en utilisant `DOCUMENTATION_TECHNIQUE.docx`

---

## 📊 Niveau et durée

| Aspect | Détail |
|--------|--------|
| **Niveau** | Intermédiaire solide (Bac+2 minimum) |
| **Durée estimée** | 40-60 heures (groupe de 3 personnes) |
| **Par personne** | ~15-20 heures (si bien réparties) |
| **Public visé** | BTS SIO, Licence, Master cyber, portfolio pro |

---

## 🎯 Résultat attendu

À la fin, vous aurez :

📋 **Documentation**
- Cours complet en Markdown (ce dépôt)
- Mémo et fiches techniques
- Rapport technique `.docx` complet

💻 **Infrastructure**
- 3 VMs Rocky Linux sécurisées et opérationnelles
- SIEM Wazuh avec 20+ règles personnalisées
- Monitoring avec alertes et dashboards
- Playbooks IR et scripts de réaction

🧪 **Preuves de fonctionnement**
- Logs d'attaques simulées
- Captures alertes Wazuh
- Rapports post-incident
- Vidéos de démonstration (optionnel)

---

## 🤝 Contribution & Améliorations

Ce projet est **open source** et pédagogique. Vous pouvez :
- 📝 Proposer des améliorations
- 🐛 Signaler des erreurs/typos
- 💪 Ajouter des attaques avancées
- 🎨 Améliorer la documentation

---

## 📞 Besoin d'aide ?

- 📖 **Relisez le sommaire** : [SOMMAIRE.md](./SOMMAIRE.md)
- 🔍 **Consultez les mémo** : [06_ANNEXES/memos/](./06_ANNEXES/memos/)
- 🧪 **Utilisez les tests** : Fichier `tests_verification.md` de chaque section
- 🔗 **Ressources externes** : Lien dans chaque fichier `.md`

---

## 📜 License & Citation

Ce projet est sous licence **Creative Commons BY-SA** (Vous pouvez l'utiliser, le modifier, le redistribuer à condition de citer l'auteur).

**Citation suggérée** :
```
Mini SOC Sécurisé sous Rocky Linux - Projet pédagogique BTS/Licence
Auteur : [Votre nom / Établissement]
Lien : [URL GitHub]
```

---

## 🚀 Prêt à commencer ?

```bash
# 1. Lisez le contexte
cat 01_PREPARATION/01_contexte_objectifs.md

# 2. Consultez le sommaire complet
cat SOMMAIRE.md

# 3. Choisissez votre rôle et lancez-vous !
# Rôle 1 (Admin) → 02_ADMIN_HARDENING/
# Rôle 2 (SOC)  → 03_BLUE_TEAM_SOC/
# Rôle 3 (IR)   → 04_BLUE_TEAM_SUPERVISION/
```

**Bon courage et amusez-vous bien ! 🛡️🔍⚡**

---

**Dernière mise à jour** : Février 2026  
**Version** : 2.0 | **Status** : Actif & Maintenus
