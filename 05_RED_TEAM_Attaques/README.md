# 🔴 Red Team Attacks - Mini SOC Rocky Linux

**Durée totale estimée :** 4-5 heures  
**Niveau:** Intermédiaire solide  
**Objectif :** Simuler des attaques réalistes pour valider le système de défense

---

## 📑 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture des attaques](#architecture-des-attaques)
3. [Cycle d'attaque complet](#cycle-dattaque-complet)
4. [Les 5 attaques détaillées](#les-5-attaques-détaillées)
5. [Checklist d'exécution](#checklist-dexécution)
6. [Recommandations de sécurité](#recommandations-de-sécurité)

---

## Vue d'ensemble

### Objectif pédagogique

Cette section simule une **attaque complète** contre l'infrastructure du Mini SOC. Chaque attaque représente une étape réelle du processus d'intrusion :

```
Reconnaissance → Accès → Exécution → Escalade → Persistance
     (01)        (02)      (03)        (04)        (05)
```

### Principe de base

Chaque attaque doit :

✅ **Être exécutée** sur la machine attaquante (Kali/Parrot)  
✅ **Être détectée** par Wazuh en temps réel (rule level ≥ 5)  
✅ **Être bloquée** (si possible) par les défenses (Fail2ban, SELinux)  
✅ **Générer des logs** que les 3 rôles doivent analyser  
✅ **Produire une preuve** documentée (screenshot, rapport)  

---

## Architecture des attaques

### Topologie du lab

```
┌─────────────────────────────────────────────────────────┐
│                    INTERNET / ATTAQUANT                 │
│                   (Kali - 192.168.1.50)                │
└──────────────┬────────────────────────────────────────┘
               │ Attaques multiples
               │
┌──────────────▼────────────────────────────────────────┐
│             NETWORK (192.168.1.0/24)                   │
│                                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │   WEB       │  │     SOC      │  │ MONITORING  │  │
│  │  (.100)     │  │   (.101)     │  │   (.102)    │  │
│  │             │  │              │  │             │  │
│  │ Nginx       │  │ Wazuh Manager│  │ Zabbix      │  │
│  │ PHP         │  │ Elasticsearch│  │ Prometheus  │  │
│  │ auditd      │  │ Kibana       │  │ Grafana     │  │
│  └─────────────┘  └──────────────┘  └─────────────┘  │
│
│  ← Attaques cibles ici →
└──────────────────────────────────────────────────────┘
```

### Flux de défense

```
ATTAQUE
   ↓
[Firewall] → Bloque ports/IPs (Firewalld/UFW)
   ↓
[Fail2ban] → Bloque brute force (SSH, Web)
   ↓
[SELinux] → Empêche exécution non autorisée
   ↓
[auditd] → Enregistre toutes les actions
   ↓
[Logs] → SSH, Nginx, Firewall, Système
   ↓
[Wazuh] → Détecte et corrèle les patterns
   ↓
[Rôle 2 (SOC)] → Analyse l'incident en temps réel
   ↓
[Rôle 3 (IR)] → Exécute le playbook de réaction
   ↓
INCIDENT RESOLVED ✅
```

---

## Cycle d'attaque complet

### Phase 1 : Reconnaissance (Nmap)

**Durée :** 45 min | **Niveau :** Basique  
**Fichier :** `01_nmap.md`

```
Attaquant                   Cible
    │                         │
    ├─ nmap -sn             ──→ Découverte des hôtes
    │                      BROADCAST
    │
    ├─ nmap -sV             ──→ Scan de services
    │                      (Port scanning)
    │
    └─ nmap -A              ──→ Scan complet (OS, scripts)
                           DETAILS
```

**Détection :** Wazuh rule 100200+ / Dashboard monitoring

---

### Phase 2 : Accès (Brute Force SSH)

**Durée :** 1h | **Niveau :** Intermédiaire  
**Fichier :** `02_bruteforce_ssh.md`

```
Attaquant                   Cible
    │                         │
    ├─ hydra -l admin       ──→ Énumère usernames
    │   -P wordlist.txt
    │
    ├─ Tentative 1: admin/password  ──✗
    ├─ Tentative 2: admin/123456    ──✗
    ├─ Tentative 3: admin/admin     ──✓ SUCCESS!
    │
    └─ SSH login as admin   ──→ Accès obtenu!
```

**Défense:** Fail2ban bloque après 5 tentatives  
**Détection:** Wazuh rule 100301 / Logs SSH

---

### Phase 3 : Exécution (Upload Web Shell)

**Durée :** 1h | **Niveau :** Intermédiaire  
**Fichier :** `03_upload_malveillant.md`

```
Attaquant                   Cible
    │                         │
    ├─ curl -F "file=shell.php" ──→ Upload malveillant
    │                        /uploads/
    │
    ├─ GET /uploads/shell.php?cmd=whoami ──→ Exécution commandes
    │                        EXECUTION
    │
    └─ whoami → www-data    ✅ RCE Réussi!
```

**Défense:** SELinux bloque exécution / Nginx config  
**Détection:** Wazuh rule 100400+ / File integrity

---

### Phase 4 : Escalade (Privilege Escalation)

**Durée :** 1h | **Niveau :** Avancé  
**Fichier :** `04_elevation_privileges.md`

```
Attaquant                   Cible
    │                         │
    ├─ sudo -l               ──→ Énumère permissions sudo
    │                      
    ├─ sudo cat /etc/shadow  ──→ Accès hashes passwords
    │                      
    ├─ sudo chmod 4755 /tmp/shell ──→ Active SUID bit
    │                      
    └─ /tmp/shell -p        ──→ uid=0(root)! ✅
```

**Défense:** Sudo config restrictive / auditd  
**Détection:** Wazuh rule 100500+ / Auditd tracking

---

### Phase 5 : Persistance (Anomalie temporelle)

**Durée :** 45 min | **Niveau :** Basique  
**Fichier :** `05_connexion_hors_horaires.md`

```
Attaquant                   Cible
    │                         │
    ├─ SSH 22:35 (hors 8-18h) ──→ Connexion suspecte
    │                       
    ├─ cat /etc/shadow       ──→ Énumération sensible
    ├─ find / -perm -4000    ──→ Recherche SUID
    ├─ chmod 4755 /bin/bash  ──→ Backdoor
    │                       
    └─ Automatisation via cron ──→ Persistance
```

**Détection:** Wazuh rule 100600+ / Time-based anomaly  
**Réaction:** Incident Response playbook

---

## Les 5 attaques détaillées

### 1. 🔍 Nmap Scanning (01_nmap.md)

| Aspect | Détail |
|--------|--------|
| **Durée** | 45 minutes |
| **Attaque** | Scan réseau de découverte |
| **Impact** | Énumération services + OS |
| **Détection** | Firewall logs + IDS |
| **Blocage** | Firewall + règles |
| **Logs générés** | Firewall, Nginx access, auditd |

**Commandes clés :**
```bash
nmap -sn 192.168.1.0/24              # Découverte hôtes
nmap -sV -sC 192.168.1.100           # Service enumeration
nmap -A -T4 -p- 192.168.1.100        # Full scan
```

---

### 2. 🔐 SSH Brute Force (02_bruteforce_ssh.md)

| Aspect | Détail |
|--------|--------|
| **Durée** | 1 heure |
| **Attaque** | Force brute de credentials SSH |
| **Impact** | Accès au système obtenu |
| **Défense** | Fail2ban (bloque après 5 tentatives) |
| **Détection** | Wazuh + Fail2ban logs |
| **Preuve** | Logs SSH + rapport incident |

**Commandes clés :**
```bash
hydra -L users.txt -P pass.txt ssh://192.168.1.100
medusa -h 192.168.1.100 -u admin -P wordlist.txt -M ssh
```

---

### 3. 📤 Web Shell Upload (03_upload_malveillant.md)

| Aspect | Détail |
|--------|--------|
| **Durée** | 1 heure |
| **Attaque** | Upload fichier PHP malveillant |
| **Impact** | Exécution de commandes (RCE) |
| **Défense** | SELinux + Nginx config |
| **Détection** | File monitoring + Web logs |
| **Preuve** | Shell PHP + screenshots |

**Commandes clés :**
```bash
curl -F "file=@shell.php" http://192.168.1.100/upload.php
curl "http://192.168.1.100/uploads/shell.php?cmd=whoami"
```

---

### 4. ⬆️ Privilege Escalation (04_elevation_privileges.md)

| Aspect | Détail |
|--------|--------|
| **Durée** | 1 heure |
| **Attaque** | Escalade vers uid=0 (root) |
| **Impact** | Contrôle complet du système |
| **Défense** | Sudo config + SELinux |
| **Détection** | auditd + Wazuh logs |
| **Preuve** | logs sudo + audit trail |

**Commandes clés :**
```bash
sudo -l                              # Enumération permissions
sudo chmod 4755 /tmp/shell           # Activation SUID
/tmp/shell -p                        # Escalade
```

---

### 5. ⏰ Anomalies Temporelles (05_connexion_hors_horaires.md)

| Aspect | Détail |
|--------|--------|
| **Durée** | 45 minutes |
| **Attaque** | Connexion hors horaires + actions sensibles |
| **Impact** | Indication d'une compromission |
| **Défense** | PAM time restrictions |
| **Détection** | Baseline + anomaly detection |
| **Preuve** | Logs horodatés + incident |

**Commandes clés :**
```bash
ssh student@192.168.1.100 "whoami"   # Connexion 22h35
sudo cat /etc/shadow                 # Action sensible
```

---

## Checklist d'exécution

### Avant de commencer

- [ ] Vérifier que toutes les VMs sont démarrées
- [ ] Ping des 3 cibles depuis la machine attaquante
- [ ] Wazuh agent actif et connecté
- [ ] Dashboard Wazuh accessible
- [ ] Logs en direct du serveur
- [ ] Synchronisation d'horloge (ntpd/chrony)

### Pour chaque attaque

- [ ] Lancer l'attaque selon le script
- [ ] Vérifier les logs générés
- [ ] Confirmer la détection Wazuh
- [ ] Observer la défense (Fail2ban, SELinux, etc.)
- [ ] Documenter les preuves
- [ ] Simuler la réaction d'incident response

### Après chaque attaque

- [ ] Sauvegarder les preuves
- [ ] Nettoyer les fichiers malveillants
- [ ] Réinitialiser les configurations
- [ ] Enregistrer les timings
- [ ] Noter les observations

### À la fin de tous les tests

- [ ] Compiler les rapports
- [ ] Créer une chronologie complète
- [ ] Analyser les gaps de détection
- [ ] Proposer des améliorations
- [ ] Présenter les résultats

---

## Recommandations de sécurité

### Basées sur les attaques observées

```
01. NMAP Scanning
   ✅ Firewall bloque les ports inutiles
   ✅ IDS/IPS déjà en place
   ✅ Réduire les services publics

02. SSH Brute Force
   ✅ Fail2ban actif avec timeouts courts
   ✅ SSH keys authentication only (pas de passwords)
   ✅ Port non-standard
   ✅ Rate limiting

03. Web Shell Upload
   ✅ Valider les uploads côté serveur
   ✅ SELinux enforcing mode
   ✅ Interdire PHP dans /uploads
   ✅ File integrity monitoring

04. Privilege Escalation
   ✅ Sudo sans NOPASSWD
   ✅ Audit des fichiers SUID
   ✅ Restreindre les commandes sudo
   ✅ auditd avec logging complet

05. Anomalies Temporelles
   ✅ Baseline comportementale
   ✅ Règles time-based dans Wazuh
   ✅ Alerte immédiate hors horaires
   ✅ Corrélation d'événements
```

---

## 📊 Tableau récapitulatif

| # | Attaque | Durée | Niveau | Detection | Blocage | Rôle Critique |
|---|---------|-------|--------|-----------|---------|---------------|
| 01 | Nmap | 45m | ⭐ | Firewall | ✓ | Rôle 1 |
| 02 | Brute Force SSH | 1h | ⭐⭐ | Fail2ban | ✓ | Rôle 2 |
| 03 | Web Shell | 1h | ⭐⭐ | SELinux | ✓ | Rôle 1+2 |
| 04 | Escalade Privs | 1h | ⭐⭐⭐ | auditd | ✓ | Rôle 2 |
| 05 | Off-Hours | 45m | ⭐ | Wazuh | ✓ | Rôle 3 |

---

## 🎯 KPIs de succès

Pour chaque attaque, mesurer :

### 1. **Temps de détection** (Target: < 60 secondes)
```
Détection = Timestamp de l'alerte Wazuh - Timestamp de l'attaque
```

### 2. **Taux de blocage** (Target: 100%)
```
Bloquée = Attaque échouée OU Défense a agi
Non bloquée = Attaque complètement réussie
```

### 3. **Logs capturés** (Target: > 95%)
```
Chaque action enregistrée dans au moins 2 sources
(SSH, auditd, Nginx, Firewall, Wazuh, etc.)
```

### 4. **Alerte Wazuh** (Target: Level ≥ 5)
```
Level 5+ = Warning/Minor
Level 7+ = High
Level 9+ = Critical
```

---

## 📋 Ressources supplémentaires

### Documentation complète par attaque
- `01_nmap.md` - Scan réseau complet
- `02_bruteforce_ssh.md` - Attaque par force brute
- `03_upload_malveillant.md` - Shell web et RCE
- `04_elevation_privileges.md` - Escalade de privilèges
- `05_connexion_hors_horaires.md` - Détection d'anomalies

### Outils recommandés
- **Nmap** - Network scanning
- **Hydra** - Brute force
- **Curl/Wget** - HTTP requests
- **SSH** - Remote access
- **Wazuh** - SIEM/IDS
- **Zabbix/Prometheus** - Monitoring

### Lectures complémentaires
- MITRE ATT&CK Framework
- OWASP Top 10
- CIS Controls
- NIST Cybersecurity Framework

---

## 🚀 Prochaines étapes

Une fois les 5 attaques validées :

1. **Documenter les améliorations** → Créer des runbooks
2. **Automatiser les réactions** → Scripts Ansible/Bash
3. **Former l'équipe** → Présentation des résultats
4. **Améliorer le scoring** → Ajouter des métriques
5. **Refaire le cycle** → Boucle continue de test

---

**Dernière mise à jour :** Jan 15, 2024  
**Auteur :** Mini SOC Team  
**Statut :** ✅ Complet et testé  

