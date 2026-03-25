# 🛡️ Mini SOC sécurisé sous Rocky Linux

> Projet pédagogique d'administration système et cybersécurité - Niveau 2e année

---

## 📋 Présentation du projet

Ce dépôt contient une **documentation complète** pour mettre en place un Mini SOC (Security Operations Center) sous Rocky Linux. Le projet simule une infrastructure d'entreprise protégée par une équipe Blue Team et se déroule sur 6 semaines.

**Objectifs pédagogiques :**
- Apprendre à sécuriser un système Linux en conditions réelles
- Déployer un SIEM (Wazuh) et un système de monitoring (Zabbix/Prometheus)
- Détecter et répondre à des attaques simulées
- Travailler en équipe avec des rôles spécialisés

---

## 🏗️ Architecture du projet

Le projet repose sur **3 machines virtuelles Rocky Linux** communiquant en réseau :

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
│                      Attaquant (Kali)                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
                    [Firewall]
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────▼───────┐   ┌─────▼──────┐   ┌─────▼──────┐
   │  VM 1      │   │  VM 2      │   │  VM 3      │
   │  Serveur   │◄──┤  SOC/SIEM  │◄──┤ Monitoring │
   │  Web       │   │  Wazuh     │   │ Grafana    │
   └────────────┘   └────────────┘   └────────────┘
```

**Rôles des machines :**

| VM | Hostname | IP | Rôle | Outils principaux |
|----|----------|-------|------|-------------------|
| VM 1 | soc-web-rocky | 192.168.1.10 | Serveur Web exposé | Nginx, SSH, Fail2ban |
| VM 2 | soc-siem-rocky | 192.168.1.20 | SOC / Logs / SIEM | Wazuh, Elasticsearch |
| VM 3 | soc-monitor-rocky | 192.168.1.30 | Monitoring | Zabbix/Prometheus, Grafana |

---

## 📂 Structure du dépôt

```
mini-soc-rocky/
├── README.md                    ← Tu es ici !
│
├── 01_PREPARATION/              ← Prérequis et architecture
│   ├── 01_prerequis_materiel.md
│   ├── 02_schema_reseau.md
│   └── 03_plan_projet.md
│
├── 02_ADMIN_HARDENING/          ← Installation et sécurisation système
│   ├── 01_installation_base.md     ✅ Fait
│   ├── 02_partitionnement.md       ✅ Fait
│   ├── 03_config_reseau.md         ✅ Fait
│   ├── 04_securisation_ssh.md
│   ├── 05_firewall_firewalld.md
│   ├── 06_selinux.md
│   └── 07_fail2ban.md
│
├── 03_SOC_SIEM/                 ← Détection d'intrusion
│   ├── 01_centralisation_logs.md
│   ├── 02_wazuh_installation.md
│   ├── 03_wazuh_agents.md
│   └── 04_regles_detection.md
│
├── 04_MONITORING/               ← Supervision et dashboards
│   ├── 01_zabbix_prometheus.md
│   ├── 02_grafana_install.md
│   └── 03_dashboards.md
│
├── 05_INCIDENT_RESPONSE/        ← Réponse aux incidents
│   ├── 01_procedures_ir.md
│   ├── 02_scripts_automatisation.md
│   └── 03_playbooks.md
│
├── 06_ATTAQUES_TESTS/           ← Simulation d'attaques
│   ├── 01_brute_force_ssh.md
│   ├── 02_scan_nmap.md
│   ├── 03_upload_malveillant.md
│   └── 04_privilege_escalation.md
│
├── ANNEXES/                     ← Ressources complémentaires
│   ├── commandes_utiles.md
│   ├── troubleshooting.md
│   └── glossaire.md
│
└── scripts/                     ← Scripts et configurations
    ├── hardening/
    ├── monitoring/
    └── incident_response/
```

---

## 🚀 Démarrage rapide

### Prérequis

- **Matériel** : PC avec 16 GB RAM et 200 GB d'espace disque
- **Hyperviseur** : VirtualBox, VMware, KVM ou Proxmox
- **ISO Rocky Linux 9.x** : [Télécharger ici](https://rockylinux.org/download)
- **Niveau** : Connaissance de base de Linux (commandes, SSH, fichiers de configuration)

### Étapes recommandées

1. **Commence par la préparation** : Lis le dossier `01_PREPARATION/` pour comprendre l'architecture
2. **Installe la première VM** : Suis `02_ADMIN_HARDENING/01_installation_base.md`
3. **Sécurise le système** : Continue avec les fichiers 02 à 07 du dossier `02_ADMIN_HARDENING/`
4. **Déploie le SIEM** : Passe au dossier `03_SOC_SIEM/`
5. **Configure le monitoring** : Dossier `04_MONITORING/`
6. **Teste avec des attaques** : Dossier `06_ATTAQUES_TESTS/`

---

## 👥 Organisation en équipe (3 personnes)

Si tu travailles en groupe, voici la répartition des rôles :

| Rôle | Personne | Responsabilité | Dossiers principaux |
|------|----------|----------------|---------------------|
| **Rôle 1** | Admin Système | Installation, hardening, sécurisation | `02_ADMIN_HARDENING/` |
| **Rôle 2** | SOC Analyst | Logs, SIEM, détection d'intrusion | `03_SOC_SIEM/` |
| **Rôle 3** | IR Specialist | Monitoring, réponse aux incidents | `04_MONITORING/` + `05_INCIDENT_RESPONSE/` |

Les trois rôles collaborent sur `06_ATTAQUES_TESTS/`.

---

## 📊 Compétences acquises

À la fin de ce projet, tu seras capable de :

✅ Installer et sécuriser un système Linux entreprise (Rocky/RHEL)  
✅ Configurer un réseau avec IP fixe, firewall, et zones de sécurité  
✅ Déployer un SIEM (Wazuh) et centraliser des logs  
✅ Détecter des attaques (brute force, scans, élévation de privilèges)  
✅ Configurer un système de monitoring (Zabbix/Prometheus + Grafana)  
✅ Écrire des procédures de réponse aux incidents  
✅ Automatiser des réponses avec des scripts Bash/Ansible  
✅ Travailler en équipe structurée (comme en entreprise)

---

## 🎯 Livrables attendus

Pour valider le projet, chaque rôle doit produire :

**Rôle 1 - Admin Système :**
- Checklist de hardening
- Rapport Lynis
- Documentation des configurations

**Rôle 2 - SOC Analyst :**
- Liste des logs collectés
- Règles Wazuh personnalisées
- Analyse de 3 attaques minimum

**Rôle 3 - IR Specialist :**
- Dashboards Grafana
- Playbooks de réponse aux incidents
- Scripts d'automatisation

---

## ⏱️ Planning suggéré (6 semaines)

| Semaine | Objectifs | Livrables |
|---------|-----------|-----------|
| **S1** | Installation des VMs, hardening système | 3 VMs opérationnelles et sécurisées |
| **S2** | Centralisation logs + Wazuh Manager | Wazuh opérationnel avec agents |
| **S3** | Règles de détection personnalisées | Règles Wazuh testées |
| **S4** | Monitoring + Grafana | Dashboards fonctionnels |
| **S5** | Procédures IR + scripts | Playbooks documentés |
| **S6** | Tests d'attaques + finalisation docs | Rapport final complet |

---

## 📚 Ressources complémentaires

### Documentation officielle
- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Zabbix Documentation](https://www.zabbix.com/documentation/current/en/)

### Guides et tutoriels
- [Guide ANSSI - Sécurité Linux](https://www.ssi.gouv.fr/guide/recommandations-de-securite-relatives-a-un-systeme-gnulinux/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

## 🤝 Contribution

Ce projet est conçu comme un support pédagogique évolutif. N'hésite pas à :

- Proposer des améliorations de la documentation
- Ajouter de nouveaux scénarios d'attaque
- Partager tes scripts et configurations
- Signaler des erreurs ou imprécisions

---

## 📝 Licence

Ce projet est fourni à des fins pédagogiques. Tu es libre de l'utiliser, le modifier et le partager dans un contexte éducatif.

---

## 📧 Contact et support

Si tu as des questions ou besoin d'aide :

- Pose tes questions à ton formateur/enseignant
- Consulte la section **ANNEXES/troubleshooting.md**
- Rejoins des communautés Linux/cybersécurité (Discord, forums, etc.)

---

**🎓 Bon apprentissage et bonne chance pour ton projet Mini SOC !**

---

## 🔖 Version

- **Version actuelle** : 1.0
- **Dernière mise à jour** : Février 2026
- **Système cible** : Rocky Linux 9.x
- **Niveau** : Intermédiaire (2e année admin système & réseau)
