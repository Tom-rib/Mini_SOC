# 🛡️ Mini SOC Sécurisé sous Rocky Linux

[![Rocky Linux](https://img.shields.io/badge/Rocky%20Linux-9-10B981?style=flat&logo=rockylinux)](https://rockylinux.org/)
[![Wazuh](https://img.shields.io/badge/Wazuh-4.7-blue?style=flat)](https://wazuh.com/)
[![Ansible](https://img.shields.io/badge/Ansible-Ready-red?style=flat&logo=ansible)](https://www.ansible.com/)
[![License](https://img.shields.io/badge/License-Educational-yellow)](LICENSE)

> Projet pédagogique de simulation d'infrastructure d'entreprise sécurisée avec Blue Team SOC

## 📚 Vue d'ensemble

Ce projet simule une infrastructure d'entreprise complète protégée par une équipe SOC (Security Operations Center). Il vise à enseigner les compétences de cybersécurité défensive (Blue Team) à travers une approche pratique.

### 🎯 Objectifs pédagogiques

- ✅ Sécuriser des systèmes Linux en environnement professionnel
- ✅ Centraliser et analyser les logs de sécurité (SIEM)
- ✅ Détecter et répondre aux incidents de sécurité
- ✅ Monitorer l'infrastructure et anticiper les problèmes
- ✅ Travailler en équipe avec des rôles spécialisés

### 🏗️ Architecture

```
Internet / Attaquant
        |
   [Firewall]
        |
  [Serveur Web] ─────────┐
        |                 │
   Logs & Alertes        │
        |                 │
  [SOC / SIEM] ──────────┤
        |                 │
   [Monitoring] ──────────┘
```

**3 VMs principales :**
- **VM1** : Serveur web exposé (cible)
- **VM2** : SOC/SIEM avec Wazuh (détection)
- **VM3** : Monitoring avec Prometheus/Grafana (supervision)

## 📁 Structure du projet

```
mini-soc-rocky/
├── README.md                    # Ce fichier
├── 01_PREPARATION/              # Prérequis et planification
├── 02_INSTALLATION/             # Guides d'installation
├── 03_CONFIGURATION/            # Configuration par rôle
├── 04_TESTS_VALIDATION/         # Scénarios de test
├── 05_EXPLOITATION/             # Guides opérationnels
├── 06_ANNEXES/
│   ├── configs/                 # Fichiers de configuration
│   │   ├── sshd_config          # SSH sécurisé
│   │   ├── firewalld_zones.xml  # Zones firewall
│   │   ├── rsyslog.conf         # Forward logs
│   │   └── auditd_rules.conf    # Audit système
│   ├── wazuh_rules/             # Règles SIEM personnalisées
│   │   ├── bruteforce_ssh.xml   # Détection brute force
│   │   ├── privilege_escalation.xml
│   │   ├── malware_detection.xml
│   │   └── custom_rules.xml     # Template de règles
│   └── ansible/                 # Automatisation
│       ├── playbook_hardening.yml
│       ├── playbook_monitoring.yml
│       ├── playbook_ir.yml      # Incident Response
│       └── inventory.ini
└── scripts/                     # Scripts utilitaires
```

## 🚀 Démarrage rapide

### Prérequis

- 3 VMs Rocky Linux 9 (ou équivalent RHEL)
- 4 GB RAM minimum par VM
- 20 GB disque minimum par VM
- Réseau interne 192.168.100.0/24 (ou adapter)
- Hyperviseur : VirtualBox, VMware, Proxmox, etc.

### Installation rapide avec Ansible

```bash
# 1. Cloner le projet
git clone https://github.com/votre-nom/mini-soc-rocky.git
cd mini-soc-rocky

# 2. Adapter l'inventory
nano 06_ANNEXES/ansible/inventory.ini
# Modifier les IPs selon votre environnement

# 3. Hardening automatisé
ansible-playbook -i 06_ANNEXES/ansible/inventory.ini \
                 06_ANNEXES/ansible/playbook_hardening.yml

# 4. Déployer le monitoring
ansible-playbook -i 06_ANNEXES/ansible/inventory.ini \
                 06_ANNEXES/ansible/playbook_monitoring.yml \
                 --limit monitoring_servers

# 5. Tester une réponse automatique
ansible-playbook -i 06_ANNEXES/ansible/inventory.ini \
                 06_ANNEXES/ansible/playbook_ir.yml \
                 --tags="forensics"
```

### Installation manuelle

Consulter les guides dans `02_INSTALLATION/` et `03_CONFIGURATION/` pour une installation pas-à-pas.

## 🔧 Configuration des outils

### SSH Sécurisé

```bash
# Copier la config SSH sécurisée
sudo cp 06_ANNEXES/configs/sshd_config /etc/ssh/sshd_config

# Adapter le port et les utilisateurs autorisés
sudo nano /etc/ssh/sshd_config

# Redémarrer SSH
sudo systemctl restart sshd
```

### Firewalld

```bash
# Utiliser les zones prédéfinies
sudo cp 06_ANNEXES/configs/firewalld_zones.xml /etc/firewalld/zones/

# Activer une zone
sudo firewall-cmd --zone=internal-soc --change-interface=eth0 --permanent
sudo firewall-cmd --reload
```

### Rsyslog (forwarding vers Wazuh)

```bash
# Copier la config rsyslog
sudo cp 06_ANNEXES/configs/rsyslog.conf /etc/rsyslog.d/wazuh-forward.conf

# Adapter l'IP du serveur Wazuh
sudo nano /etc/rsyslog.d/wazuh-forward.conf
# Remplacer 192.168.100.20 par l'IP de votre SOC

# Redémarrer rsyslog
sudo systemctl restart rsyslog
```

### Auditd

```bash
# Copier les règles audit
sudo cp 06_ANNEXES/configs/auditd_rules.conf /etc/audit/rules.d/custom.rules

# Charger les règles
sudo augenrules --load

# Redémarrer auditd
sudo service auditd restart
```

### Wazuh - Règles personnalisées

```bash
# Sur le Wazuh Manager
sudo nano /var/ossec/etc/rules/local_rules.xml

# Copier le contenu des fichiers:
# - 06_ANNEXES/wazuh_rules/bruteforce_ssh.xml
# - 06_ANNEXES/wazuh_rules/privilege_escalation.xml
# - 06_ANNEXES/wazuh_rules/malware_detection.xml

# Redémarrer Wazuh
sudo systemctl restart wazuh-manager
```

## 🧪 Tests et validation

### Tester la détection brute force SSH

```bash
# Depuis une machine externe ou Kali Linux
for i in {1..10}; do 
  ssh root@192.168.100.10 -p 2222
done

# Vérifier dans Wazuh UI:
# Dashboard > Security Events > Filter "brute_force"
```

### Tester la détection d'élévation de privilèges

```bash
# Sur un serveur monitoré
sudo visudo    # Devrait déclencher alerte niveau 12

# Vérifier dans Wazuh
# Dashboard > Security Events > Filter "privilege_escalation"
```

### Tester l'Incident Response automatique

```bash
# Bloquer une IP attaquante
ansible-playbook -i 06_ANNEXES/ansible/inventory.ini \
                 06_ANNEXES/ansible/playbook_ir.yml \
                 --tags="ssh_bruteforce" \
                 -e "attacker_ip=1.2.3.4"

# Vérifier que l'IP est bloquée
sudo firewall-cmd --list-all
```

## 📊 Dashboards et monitoring

### Accès aux interfaces

| Service       | URL                        | Login par défaut  |
|---------------|----------------------------|-------------------|
| Grafana       | http://IP:3000             | admin / admin     |
| Prometheus    | http://IP:9090             | (pas d'auth)      |
| Wazuh UI      | https://IP:443             | admin / admin     |

### Dashboards Grafana recommandés

À importer depuis grafana.com:
- **Node Exporter Full** (ID: 1860) - Métriques Linux complètes
- **Prometheus Stats** (ID: 2) - Stats Prometheus
- **Nginx Metrics** (ID: 11199) - Si serveur web

## 🎓 Organisation en équipe (3 personnes)

### Rôle 1 : Administrateur système & Hardening

**Mission :** Rendre les serveurs difficiles à compromettre

**Tâches :**
- Installation et configuration Rocky Linux
- Hardening système (SSH, Firewall, SELinux)
- Mise en place Fail2ban et auditd
- Génération rapport Lynis

**Livrables :**
- Checklist de hardening
- Rapport Lynis
- Documentation des choix sécurité

### Rôle 2 : SOC Analyst (Blue Team)

**Mission :** Détecter les attaques

**Tâches :**
- Centralisation des logs (rsyslog)
- Configuration Wazuh SIEM
- Création règles de détection personnalisées
- Analyse des alertes

**Livrables :**
- Liste des logs collectés
- Règles Wazuh personnalisées
- Screenshots des alertes
- Analyse de 3+ attaques

### Rôle 3 : Monitoring & Incident Response

**Mission :** Superviser et réagir

**Tâches :**
- Déploiement Prometheus + Grafana
- Configuration dashboards
- Rédaction playbooks IR
- Réponse automatisée aux incidents

**Livrables :**
- Dashboards de monitoring
- Playbooks Ansible IR
- Scripts de réponse
- Rapport post-incident

## 🔥 Scénarios d'attaque à simuler

Obligatoire de tester ces 5 scénarios:

1. **Nmap Scan** - Scan réseau massif
2. **SSH Brute Force** - Tentatives connexion répétées
3. **Upload fichier malveillant** - Web shell .php
4. **Tentative sudo** - Élévation privilèges
5. **Connexion hors horaires** - Accès suspect 2h du matin

Chaque attaque doit:
- ✅ Générer un log
- ✅ Déclencher une alerte Wazuh
- ✅ Avoir une réponse IR

## 📈 Compétences validées

En réalisant ce projet, vous validez:

- ✅ Linux entreprise (RHEL/Rocky)
- ✅ Sécurité système (hardening)
- ✅ SOC / Blue Team
- ✅ SIEM (Wazuh)
- ✅ Détection & réponse aux incidents
- ✅ Monitoring infrastructure
- ✅ Automatisation (Ansible)
- ✅ Travail d'équipe structuré

## 🏆 Niveau et valeur

**Niveau :** Intermédiaire solide (2e année BTS/DUT/Licence)

**Valorisable pour :**
- BTS SIO option SISR
- BUT Réseaux & Télécoms
- Licence Pro Cybersécurité
- Portfolio professionnel
- Candidatures stages/alternances SOC

## 📝 Livrables finaux

Pour compléter le projet, fournir:

1. **Documentation technique complète** (ce repo GitHub)
2. **Rapport de projet** (PDF) avec:
   - Architecture détaillée
   - Choix techniques justifiés
   - Screenshots des alertes
   - Analyse des attaques simulées
3. **Vidéo démo** (5-10 min) montrant:
   - Attaque en direct
   - Détection dans Wazuh
   - Réponse automatisée
4. **Présentation** (slides) pour soutenance

## 🤝 Contribution

Ce projet est éducatif et ouvert aux contributions:

1. Fork le projet
2. Crée une branche (`git checkout -b feature/amelioration`)
3. Commit tes changements (`git commit -m 'Ajout feature X'`)
4. Push vers la branche (`git push origin feature/amelioration`)
5. Ouvre une Pull Request

## 📚 Ressources

### Documentation officielle

- [Rocky Linux Docs](https://docs.rockylinux.org/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Ansible Documentation](https://docs.ansible.com/)

### Guides de sécurité

- [CIS Benchmark Rocky Linux](https://www.cisecurity.org/benchmark/rocky_linux)
- [ANSSI - Recommandations](https://www.ssi.gouv.fr/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Formation complémentaire

- [TryHackMe - Blue Team](https://tryhackme.com/paths)
- [CyberDefenders Labs](https://cyberdefenders.org/)
- [Blue Team Labs Online](https://blueteamlabs.online/)

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👥 Auteurs

- **Ton nom** - *Initial work* - [GitHub](https://github.com/ton-username)

## 🙏 Remerciements

- La communauté Rocky Linux
- L'équipe Wazuh
- Les contributeurs Ansible
- Les formateurs en cybersécurité

## 💬 Support

Pour toute question ou problème:

1. Consulter les [Issues](https://github.com/ton-username/mini-soc-rocky/issues) existantes
2. Ouvrir une nouvelle issue avec le tag approprié
3. Rejoindre notre [Discord](https://discord.gg/xxxxx) (si applicable)

---

⭐ Si ce projet vous a aidé, n'hésitez pas à lui donner une étoile sur GitHub!

📧 Contact : votre.email@example.com
