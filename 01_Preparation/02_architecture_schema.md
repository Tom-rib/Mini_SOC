# 🏗️ 2. Architecture et Schémas

**Durée de lecture estimée** : 15 minutes  
**Concepts clés** : Réseau, flux de données, séparation des services  
**Prérequis** : Avoir lu [`01_contexte_objectifs.md`](01_contexte_objectifs.md)

---

## 🎨 Schéma Global (Vue d'Ensemble)

```
                                ┌─────────────────────────┐
                                │   INTERNET / ATTAQUANT  │
                                │  (Kali Linux optionnel) │
                                └────────────┬────────────┘
                                             │
                                      (Scans, attaques)
                                             │
                        ┌────────────────────┴────────────────────┐
                        │                                         │
                    ┌───▼─────────────┐                    ┌─────▼────────┐
                    │  FIREWALL       │                    │  (Réseau DMZ  │
                    │  Rocky Linux    │                    │   ou Bridge)  │
                    │                 │                    │               │
                    │ Port 22 (SSH)   │                    │               │
                    │ Port 80/443     │                    │               │
                    │ Firewalld       │                    │               │
                    └────────┬────────┘                    └───────────────┘
                             │
                             │ (trafic autorisé)
                             │
                    ┌────────▼──────────────┐
                    │   VM 1 : SERVEUR WEB  │
                    │   Rocky Linux 9       │
                    │  ────────────────────│
                    │  • Nginx (web)        │
                    │  • Logs centralisés   │
                    │  • SSH hardened       │
                    │  • Auditd             │
                    │  • Firewall local     │
                    │  • SELinux enforcing  │
                    │  • Wazuh Agent        │
                    │  IP : 192.168.1.10    │
                    └────────┬──────────────┘
                             │
                      (Logs en temps réel)
                             │
         ┌───────────────────┴───────────────────┐
         │                                       │
    ┌────▼──────────────────┐           ┌──────▼─────────────┐
    │  VM 2 : SOC / LOGS    │           │  VM 3 : MONITORING │
    │  Rocky Linux 9        │           │  Rocky Linux 9     │
    │ ────────────────────│           │ ────────────────── │
    │ • Wazuh Manager     │           │ • Zabbix Server   │
    │ • Elasticsearch     │           │ • Prometheus      │
    │ • Kibana (web UI)   │           │ • Grafana (UI)    │
    │ • rsyslog receiver  │           │ • Alertmanager    │
    │ • Analyseur logs    │           │ • Dashboard IR    │
    │ IP : 192.168.1.20   │           │ IP : 192.168.1.30 │
    │ Port 514 (syslog)   │           │ Port 10051 (Zabbix)│
    │ Port 1514 (Wazuh)   │           │ Port 9090 (Prometh)│
    └────┬─────────────────┘           └────┬──────────────┘
         │                                   │
         └───────────────┬───────────────────┘
                         │
                (Alertes, dashboards)
                         │
                    ┌────▼─────┐
                    │ ÉCRANS   │
                    │ ALERTES  │
                    │ RAPPORTS │
                    └──────────┘
```

---

## 📡 Flux de Données Détaillé

### 1️⃣ Sur le Serveur Web (VM 1)

```
┌──────────────────────────────────────────────────────────────┐
│          VM 1 : SERVEUR WEB (192.168.1.10)                   │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Applications & Services                                     │
│  ├─ Nginx (port 80/443)                                      │
│  ├─ SSH (port 2222)                                          │
│  ├─ Fail2ban                                                 │
│  └─ Auditd                                                   │
│                                                               │
│  Logs Générés                                                │
│  ├─ /var/log/nginx/access.log    (requêtes web)             │
│  ├─ /var/log/nginx/error.log     (erreurs web)              │
│  ├─ /var/log/secure              (SSH, sudo)                │
│  ├─ /var/log/audit/audit.log     (actions système)          │
│  ├─ /var/log/fail2ban.log        (tentatives bloquées)      │
│  └─ /var/log/messages            (système général)          │
│                                                               │
│  Envoi Logs (rsyslog + Wazuh Agent)                          │
│  │                                                            │
│  ├─→ rsyslog envoie vers 192.168.1.20:514 (syslog)         │
│  └─→ Wazuh Agent envoie vers 192.168.1.20:1514 (Wazuh)     │
│                                                               │
│  Wazuh Agent LOCAL                                           │
│  ├─ Monitore les fichiers de log                            │
│  ├─ Scanne les modifications de fichiers                    │
│  ├─ Détecte les anomalies locales                           │
│  └─ Envoie au manager (VM 2)                                │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### 2️⃣ Sur le SOC (VM 2)

```
┌──────────────────────────────────────────────────────────────┐
│          VM 2 : SOC (192.168.1.20)                           │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Réception des Logs                                          │
│  ├─ rsyslog (port 514)  ← VM 1, VM 3                        │
│  │  └─ Centralise TOUT en /var/log/remote/                  │
│  │                                                            │
│  └─ Wazuh Manager (port 1514)  ← Wazuh Agents               │
│     └─ Reçoit événements structurés                         │
│                                                               │
│  Traitement & Analyse                                        │
│  ├─ Wazuh Manager                                            │
│  │  ├─ Applique les règles de détection                    │
│  │  ├─ Évalue la sévérité (1-15)                           │
│  │  ├─ Crée les alertes                                    │
│  │  └─ Envoie vers Elasticsearch                           │
│  │                                                            │
│  ├─ Elasticsearch (base de données)                          │
│  │  └─ Indexe TOUS les logs & alertes                      │
│  │                                                            │
│  └─ Kibana (Web UI, port 5601)                              │
│     ├─ Dashboards en temps réel                            │
│     ├─ Recherche avancée dans les logs                     │
│     └─ Graphiques & statistiques                           │
│                                                               │
│  Alertes Générées                                            │
│  ├─ Brute force SSH                                         │
│  ├─ Scan de ports                                           │
│  ├─ Tentatives élévation privilèges                        │
│  ├─ Accès hors horaires                                    │
│  └─ Upload fichiers suspects                               │
│                                                               │
│  Envoi des Alertes (Webhooks)                               │
│  │                                                            │
│  └─→ Email / Slack → Rôle 3 (Incident Response)             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### 3️⃣ Sur le Monitoring (VM 3)

```
┌──────────────────────────────────────────────────────────────┐
│          VM 3 : MONITORING (192.168.1.30)                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Collection de Métriques                                     │
│  ├─ Zabbix Agent (ou Prometheus exporters)                  │
│  │  ├─ Envoie CPU, RAM, Disque toutes les 30s              │
│  │  ├─ Envoie État des services                            │
│  │  └─ Envoie Temps de réponse réseau                      │
│  │                                                            │
│  └─ Prometheus (port 9090)                                  │
│     ├─ Scrape les métriques toutes les 15s                 │
│     ├─ Stocke les historiques                              │
│     └─ Évalue les règles d'alerte                          │
│                                                               │
│  Analyse & Dashboards                                        │
│  ├─ Grafana (port 3000)                                    │
│  │  ├─ Visualise les métriques en temps réel               │
│  │  ├─ Graphiques CPU, RAM, Disque                        │
│  │  ├─ État des services                                   │
│  │  └─ Tableau de bord Incident Response                  │
│  │                                                            │
│  └─ Alertmanager                                            │
│     ├─ Reçoit les alertes de Prometheus                    │
│     ├─ Group & déduplique les alertes                      │
│     └─ Route vers Slack / Email / Webhook                 │
│                                                               │
│  Actions de Réaction (IR)                                    │
│  ├─ Scripts Bash / Ansible                                 │
│  │  ├─ Bloquer une IP au firewall                         │
│  │  ├─ Désactiver un compte utilisateur                   │
│  │  ├─ Isoler un service                                  │
│  │  └─ Lancer une investigation forensique                │
│  │                                                            │
│  └─ Playbooks Incident Response (manuel ou auto)            │
│     ├─ Brute force SSH → Bloquer l'IP                     │
│     ├─ Fichier malveillant → Isoler + Alerte              │
│     └─ Scan réseau → Enquête + Rapport                    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔄 Cycle Complet d'une Attaque

Exemple : **Brute force SSH détecté**

```
⏱️ T+0 ATTAQUE EN COURS
  └─→ Attaquant : 10 tentatives SSH échouées en 30 secondes
      De l'IP 203.0.113.50 vers 192.168.1.10:2222

⏱️ T+2 DETECTION (VM 2 - SOC)
  Log Reçu via rsyslog & Wazuh Agent :
  ├─ 10 entrées "Failed password" dans /var/log/secure
  ├─ Wazuh Manager applique la règle :
  │  IF (failed_login > 5 IN 1 minute) THEN
  │    ALERT severity=10
  │    Rule_ID=5710
  │    Description="Brute force SSH"
  │
  ├─ Elasticsearch indexe l'alerte
  ├─ Kibana affiche en ROUGE sur le dashboard
  └─ Notification → Slack / Email (Rôle 3)

⏱️ T+3-5 DECISION (Rôle 3 - Monitoring IR)
  Analyse :
  ├─ Vérifier l'IP source (est-ce un test autorisé ?)
  ├─ Voir les tentatives exactes dans Kibana
  ├─ Consulter le dashboard Grafana (état des services)
  └─ Décider : BLOQUER ou ENQUÊTER

⏱️ T+6 RÉACTION (VM 3 - Monitoring IR)
  Playbook lancé automatiquement :
  ├─ Script 1 : firewall-block-ip.sh
  │  → Ajoute rule : firewall-cmd --add-rich-rule='...'
  │  → IP 203.0.113.50 est maintenant BLOQUÉE
  │
  ├─ Script 2 : alert-ir-team.sh
  │  → Envoie rapport slack avec :
  │    - Timeline de l'attaque
  │    - IP bloquée
  │    - Actions prises
  │    - Logs concernés
  │
  └─ Script 3 : forensics-snapshot.sh
     → Sauvegarde /var/log pour enquête

⏱️ T+10 POST-INCIDENT (Rapports)
  Rôle 3 produit :
  ├─ Rapport post-mortem
  ├─ Timeline complète
  ├─ Graphiques Grafana (avant/après)
  ├─ Alertes Wazuh générées
  └─ Actions correctives (ex: changer port SSH)
```

---

## 🌐 Architecture Réseau

### Configuration Réseau Recommandée

```
Host (Ton Ordinateur)
│
├─ VirtualBox / VMware / Proxmox / KVM
│  │
│  └─ Bridge Network (192.168.1.0/24)
│     │
│     ├─ VM 1 (Web Server)    → 192.168.1.10
│     ├─ VM 2 (SOC / Logs)    → 192.168.1.20
│     ├─ VM 3 (Monitoring)    → 192.168.1.30
│     └─ VM 4 (Attacker/Kali) → 192.168.1.50 (optionnel)
│
└─ Firewall Host (NAT)
```

### Configuration Détaillée

| VM | Hostname | IP | RAM | CPU | Disque | Rôle |
|---|---|---|---|---|---|---|
| VM 1 | web-server | 192.168.1.10 | 4 GB | 2 cores | 30 GB | Serveur Web + Hardening |
| VM 2 | soc-manager | 192.168.1.20 | 6 GB | 4 cores | 50 GB | Wazuh Manager + Logs |
| VM 3 | monitoring | 192.168.1.30 | 4 GB | 2 cores | 30 GB | Zabbix + Prometheus |
| VM 4 | attacker | 192.168.1.50 | 2 GB | 1 core | 20 GB | Kali (optionnel) |

**Total minimum** : 16 GB RAM (3 VM) / 22 GB RAM (4 VM)

---

## 🔐 Isolation & Sécurité de l'Architecture

### Zones de Sécurité

```
┌─────────────────────────────────────────────────┐
│           ZONE EXTERNELLE (Internet)            │
├─────────────────────────────────────────────────┤
│  Attaquants, Traffic non contrôlé               │
│  Accès : LIMITÉ via firewall                    │
│                                                  │
│  Port 22 (SSH) → Bloqué                        │
│  Port 80/443 (HTTP/S) → Ouvert vers VM 1      │
│  Port 514 (syslog) → Bloqué                    │
│  Port 1514 (Wazuh) → Bloqué                    │
│  Port 5601 (Kibana) → Bloqué (accès interne)  │
│  Port 3000 (Grafana) → Bloqué (accès interne) │
│                                                  │
└────────────┬─────────────────────────────────────┘
             │
        ┌────▼──────────────┐
        │  Firewall Rocky   │
        │  (VM 1 ou Host)   │
        └────┬──────────────┘
             │
    ┌────────┴──────────┐
    │                   │
┌───▼────────────┐ ┌───▼────────────┐
│  ZONE DMZ      │ │  ZONE INTERNE  │
│ (Production)   │ │  (Gestion)     │
├────────────────┤ ├────────────────┤
│ VM 1 : Web     │ │ VM 2 : SOC     │
│ Accessible de  │ │ Accessible de  │
│ l'extérieur    │ │ VM 1 & VM 3    │
│                │ │                │
│ Logs sortent   │ │ Reçoit logs    │
│ vers VM 2      │ │ Envoie alertes │
│                │ │                │
└────────────────┘ │ VM 3 : Monitor │
                   │ Accessible de  │
                   │ VM 1 & VM 2    │
                   │                │
                   │ Reçoit alertes │
                   │ Envoie actions │
                   └────────────────┘
```

---

## 📊 Matrice de Communication

Qui parle à qui ?

```
            VM 1      VM 2      VM 3      Attacker
           (Web)     (SOC)    (Monitor)  (Kali)
          ────────────────────────────────────────
VM 1      │   X    →→  514   ←→  9090    ←  80/443
          │          1514       3000
          │          (logs)   (dashb)
          │
VM 2      ←← rsyslog X        ←  9090      
          ←← Wazuh           (metrics)
          │          →→ 5601
          │            (alerts)
          │
VM 3      ←  9090    ←  5601   X          
          (metrics) (logs)
          →  9090    → webhooks
          (scripts)
          
Attacker  →→ port 22 →→ port 514  →
          (SSH)   (scan)   (recon)
          →→ port 80/443
             (exploit)
```

**Légende**
- `→→` = Initie la connexion
- `←←` = Reçoit/Écoute
- `←→` = Bidirectionnel
- Numéros = Ports TCP/UDP

---

## 🎯 Pourquoi Cette Architecture ?

| Choix | Raison |
|-------|--------|
| **3 VM séparées** | ✅ Isolation des services, résilience, meilleure sécu |
| **Rocky Linux** | ✅ Équivalent RHEL (entreprise), moins dépassé qu'Ubuntu |
| **Firewall local** | ✅ Chaque VM se défend (défense en profondeur) |
| **Logs centralisés** | ✅ Attaquant ne peut pas tout effacer localement |
| **Wazuh + Elasticsearch** | ✅ Scalable, utilisé en entreprise, détection avancée |
| **Zabbix/Prometheus** | ✅ Monitoring pro, détection anomalies |
| **Incident Response** | ✅ Automatiser les réactions = moins d'incidents |

---

## 📋 Checklist Architecture

Avant de commencer l'installation :

- [ ] Tu as compris le flux des données (logs → SOC → alertes → IR)
- [ ] Tu connais l'adresse IP de chaque VM
- [ ] Tu as assez de RAM et disque (voir tableau)
- [ ] Tu sais pourquoi VM 2 = cœur du SOC
- [ ] Tu sais pourquoi isoler les services
- [ ] Tu as noté les ports importants

---

## 📚 Prochaines Étapes

1. **Lire** → [`03_roles_equipes.md`](03_roles_equipes.md)  
   Détails précis de chaque rôle

2. **Vérifier** → [`04_prerequis.md`](04_prerequis.md)  
   As-tu assez de matériel ?

3. **Planifier** → [`05_timeline.md`](05_timeline.md)  
   Comment organiser les 6 semaines

---

**Version** : 1.0  
**Diagrammes** : ASCII Art / Draw.io  
**Dernière mise à jour** : Février 2026
