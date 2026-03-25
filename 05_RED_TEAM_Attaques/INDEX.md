# 📋 RED TEAM ATTAQUES – Index Navigation

**Dossier** : `05_RED_TEAM_ATTAQUES/`  
**Contenu** : Attaques obligatoires et avancées + structure de remise  
**Durée totale** : Phase 4 (1 semaine) + Phase 5 (1 semaine optionnelle)

---

## 🗺️ Vue d'ensemble

```
┌─────────────────────────────────────────────────────┐
│  PHASE 4 – ATTAQUES OBLIGATOIRES (1 semaine)       │
│  └─ Fichier : 05_escalade_privileges.md            │
│     • Nmap scan                                     │
│     • SSH brute force                              │
│     • Upload malveillant                           │
│     • Escalade de privilèges                       │
│     • Accès hors horaires                          │
├─────────────────────────────────────────────────────┤
│  PHASE 5 – ATTAQUES AVANCÉES (optionnel, 1 semaine)│
│  ├─ Fichier : 06_web_shells.md                    │
│  │  └─ Web shells persistants (PHP, JSP)          │
│  ├─ Fichier : 07_cve.md                           │
│  │  └─ Exploitation CVE (enum SSH, path traversal)│
│  └─ Fichier : 08_lateral_movement.md              │
│     └─ Mouvement latéral inter-VMs                │
├─────────────────────────────────────────────────────┤
│  PHASE 6 – DOCUMENTATION FINALE                     │
│  └─ Fichier : LIVRABLES.md (ce dossier)           │
│     • Checklist complète                           │
│     • Structure des preuves                        │
│     • Critères d'évaluation                        │
└─────────────────────────────────────────────────────┘
```

---

## 📄 Fichiers détails

### 1️⃣ **05_escalade_privileges.md** (Obligatoire)
**Durée** : 1 semaine | **Prérequis** : 01-04 complétés

**Contenu** :
- 5 attaques obligatoires à simuler
- Procédures complètes étape par étape
- Commandes exactes et preuves
- Logs générés et alertes Wazuh
- Réactions documentées

**Attaques** :
1. 🔍 **Nmap Scan** (30 min)
   - Scan réseau complet
   - Identification services
   - Logs Firewall
   - Alerte Wazuh
   - Blocage IP

2. 💥 **SSH Brute Force** (30 min)
   - Wordlist attacks
   - Hydra configuration
   - Logs /var/log/secure
   - Alerte SSH brute force
   - Blocage Fail2ban

3. 📤 **Upload Malveillant** (45 min)
   - Vulnérabilité upload
   - Fichier PHP/JSP uploadé
   - Web shell test
   - Logs Nginx
   - Alerte web shell
   - Suppression fichier

4. 📈 **Escalade de Privilèges** (45 min)
   - Vérifier sudo -l
   - Exploiter vulnérabilité
   - Root access obtenu
   - Logs sudo
   - Alerte escalade
   - Remediation

5. 🕰️ **Accès Hors Horaires** (30 min)
   - Connexion SSH à 3h du matin
   - Logs timestamp
   - Alerte heure anormale
   - Blocage horaire

**Durée totale** : ~3 heures execution + 2 heures doc = 5h

---

### 2️⃣ **06_web_shells.md** (Optionnel, Phase 5)
**Durée** : 1h30 | **Niveau** : Intermédiaire-avancé | **Prérequis** : 05

**Concepts** :
- Définition web shell
- Création PHP/JSP
- Upload et exécution
- Obfuscation et evasion
- Détection comportementale
- Réaction et nettoyage

**Étapes** :
1. Créer shell.php simple
2. Créer shell_encoded.php (obfusqué)
3. Créer shell.jsp
4. Upload sur VM1
5. Tester exécution commandes
6. Exfiltrer données
7. Créer reverse shell
8. Détecter via Wazuh
9. Ajouter règles personnalisées
10. Localiser et supprimer shell
11. Audit complet logs

**Preuves requises** :
- [ ] Shells créés et testés
- [ ] Logs HTTP montrant accès shell
- [ ] Alerte Wazuh générée
- [ ] Rules Wazuh personnalisées
- [ ] Screenshots exécution commandes
- [ ] Timeline complète

---

### 3️⃣ **07_cve.md** (Optionnel, Phase 5)
**Durée** : 2h | **Niveau** : Avancé | **Prérequis** : 05

**Concepts** :
- Identification CVE
- Scan vulnerabilités (Nessus, OpenVAS)
- PoC (Proof of Concept)
- Exploitation manuelle ou Metasploit
- Patterns de détection
- Patch et mitigation

**Étapes** :
1. Scanner vulnerabilités (Nmap, Nessus)
2. Identifier version service
3. Rechercher CVE associée
4. Obtenir PoC
5. Adapter exploit
6. Exécuter exploitation
7. Générer logs
8. Créer règles Wazuh
9. Vérifier détection
10. Bloquer attaquant
11. Appliquer patch

**Exemples CVE inclus** :
- CVE-2018-15473 (SSH user enumeration)
- CVE-2021-41773 (Apache path traversal)
- CVE-2021-3156 (Sudo privilege escalation)

**Preuves requises** :
- [ ] CVE identifiée documentée
- [ ] Service vulnérable scanné
- [ ] PoC/Exploit acquisition
- [ ] Exploitation réussie
- [ ] Logs générés
- [ ] Alerte Wazuh triggered
- [ ] Règles Wazuh créées
- [ ] Patch appliqué
- [ ] Vérification patch

---

### 4️⃣ **08_lateral_movement.md** (Optionnel, Phase 5)
**Durée** : 2h | **Niveau** : Avancé | **Prérequis** : 05

**Concepts** :
- Reconnaissance intra-réseau
- Discovery d'autres hosts
- Extraction de credentials
- Exploitation with stolen credentials
- Escalade sur nouvelles machines
- Persistence
- Detection et réaction

**Étapes** :
1. Enumérer réseau (nmap, arp-scan)
2. Découvrir VM2 et VM3
3. Tester connectivité SSH
4. Chercher clés SSH
5. Chercher passwords configs
6. Chercher bash_history
7. Accéder VM2 avec creds
8. Accéder VM3 avec creds
9. Escalade sudo sur VM2
10. Escalade sudo sur VM3
11. Créer règles Wazuh mouvement latéral
12. Détecter et bloquer

**Détection points** :
- SSH login depuis VM1
- Public key authentication
- Sudo escalation
- Multiple failed SSH attempts

**Preuves requises** :
- [ ] Réseau énuméré
- [ ] VMs découvertes
- [ ] Credentials extraits
- [ ] SSH VM2 établi
- [ ] SSH VM3 établi
- [ ] Escalade VM2 réussie
- [ ] Escalade VM3 réussie
- [ ] Logs SSH/sudo complets
- [ ] Alertes Wazuh triggered
- [ ] Firewall rules appliquées

---

### 5️⃣ **LIVRABLES.md** (Obligatoire, Phase 6)

**Contenu** :
- ✅ Checklist complète par phase
- ✅ Checklist par rôle (Rôles 1, 2, 3)
- ✅ Attaques obligatoires détaillées
- ✅ Attaques optionnelles expliquées
- ✅ Structure GitHub recommandée
- ✅ Format de remise
- ✅ Critères d'évaluation
- ✅ Checklist finale avant remise

**Sections principales** :
1. **Livrables Rôle 1** (Hardening)
   - Checklist hardening
   - Rapport Lynis
   - Justifications sécurité
   - Diagramme OS

2. **Livrables Rôle 2** (SOC/Logs)
   - Configuration Wazuh
   - Liste logs collectés
   - Règles personnalisées
   - Analyse 5+ attaques
   - Dashboards

3. **Livrables Rôle 3** (Monitoring/IR)
   - Configuration monitoring
   - Dashboards
   - Playbooks IR
   - Scripts réponse
   - Rapports post-incident

4. **Attaques obligatoires**
   - Nmap scan
   - SSH brute force
   - Upload malveillant
   - Escalade sudo
   - Accès hors horaires

5. **Attaques optionnelles**
   - Web shells (06)
   - CVE exploitation (07)
   - Mouvement latéral (08)

---

## 🎯 Planning Phase 4 & 5

### Phase 4 – Attaques Obligatoires (Semaine 4)

| Jour | Attaque | Durée | Qui |
|-----|---------|-------|-----|
| Lun | Nmap scan | 30 min | Rôle 2+3 |
| Lun | SSH brute force | 30 min | Rôle 2+3 |
| Mar | Upload malveillant | 45 min | Rôle 1+2+3 |
| Mer | Escalade sudo | 45 min | Rôle 1+2+3 |
| Jeu | Accès hors horaires | 30 min | Rôle 2+3 |
| Ven | Documentation attaques | 3h | Tous |

**Total Phase 4** : ~10h

---

### Phase 5 – Attaques Avancées (Semaine 5, OPTIONNEL)

| Jour | Attaque | Durée | Qui |
|-----|---------|-------|-----|
| Lun | Web shells (06) | 1h30 | Rôle 2+3 |
| Mar | CVE exploitation (07) | 2h | Rôle 2+3 |
| Mer-Jeu | Mouvement latéral (08) | 2h | Rôle 2+3 |
| Ven | Documentation avancée | 3h | Tous |

**Total Phase 5** : ~9h30 (optionnel, ajoute valeur)

---

## 📊 Preuves à documenter

### Pour chaque attaque

```markdown
### Attaque X : [Nom]

**Planning** :
- Timing : [date/heure]
- Durée : [X min]
- Exécutée par : [Rôle X]

**Exécution** :
- Commande exacte
- Output complet
- Screenshot écran

**Logs générés** :
- Localisation fichier
- Contenu logs pertinents
- Timeline

**Détection Wazuh** :
- Rule ID déclenché
- Screenshot alerte
- Level de sévérité
- Description

**Réaction** :
- Actions prises
- Commandes exécution
- Vérification réaction

**Preuves photographiques** :
- [screenshot1.png]
- [screenshot2.png]
- [logs_complet.txt]
```

---

## 🔗 Navigation

### Lire en ordre

1. **Commencer** → Ouvrir `LIVRABLES.md`
2. **Attaques obligatoires** → Consulter `05_escalade_privileges.md`
3. **Attaques avancées** → Lire `06_web_shells.md`, `07_cve.md`, `08_lateral_movement.md`
4. **Checklist** → Vérifier les checklists de remise dans `LIVRABLES.md`

### Par rôle

- **Rôle 1 (Hardening)** → Fichiers 01-02 + livrables Rôle 1 dans LIVRABLES.md
- **Rôle 2 (SOC)** → Fichiers 03-04 + attaques obligatoires + livrables Rôle 2 dans LIVRABLES.md
- **Rôle 3 (Monitoring)** → Fichiers 03-04 + attaques obligatoires + livrables Rôle 3 dans LIVRABLES.md

### Par attaque

Chercher le numéro d'attaque :
- **Attaque 1 (Nmap)** → 05_escalade_privileges.md
- **Attaque 2 (SSH)** → 05_escalade_privileges.md
- **Attaque 3 (Upload)** → 05_escalade_privileges.md
- **Attaque 4 (Escalade)** → 05_escalade_privileges.md
- **Attaque 5 (Hors horaires)** → 05_escalade_privileges.md
- **Attaque 6 (Web shells)** → 06_web_shells.md (optionnel)
- **Attaque 7 (CVE)** → 07_cve.md (optionnel)
- **Attaque 8 (Lateral)** → 08_lateral_movement.md (optionnel)

---

## 📦 Structure preuves requises

```
preuves/
├── 01_nmap_scan/
│   ├── 01_nmap_output.txt
│   ├── 02_firewall_logs.png
│   ├── 03_wazuh_alert.png
│   └── 04_wazuh_rule.xml
├── 02_ssh_brute_force/
│   ├── 01_hydra_execution.png
│   ├── 02_secure_logs.txt
│   ├── 03_wazuh_alert.png
│   └── 04_blocage_ip.png
├── 03_upload_malveillant/
│   ├── 01_shell_created.php
│   ├── 02_upload_success.png
│   ├── 03_command_execution.png
│   ├── 04_nginx_logs.txt
│   ├── 05_wazuh_alert.png
│   └── 06_suppression.png
├── 04_escalade_sudo/
│   ├── 01_sudo_l_output.txt
│   ├── 02_escalade_success.png
│   ├── 03_sudo_logs.txt
│   ├── 04_wazuh_alert.png
│   └── 05_audit_logs.txt
├── 05_acces_hors_horaires/
│   ├── 01_ssh_access.png
│   ├── 02_timestamp_logs.txt
│   ├── 03_wazuh_alert.png
│   └── 04_rule_temporelle.xml
├── 06_web_shells/ (optionnel)
│   ├── 01_shell_php.txt
│   ├── 02_upload.png
│   ├── 03_execution.png
│   ├── 04_nginx_logs.txt
│   ├── 05_wazuh_alert.png
│   └── 06_cleanup.png
├── 07_cve/ (optionnel)
│   ├── 01_nmap_vulnscan.txt
│   ├── 02_cve_identified.txt
│   ├── 03_poc_output.txt
│   ├── 04_logs.txt
│   ├── 05_wazuh_alert.png
│   └── 06_patch_applied.txt
└── 08_lateral_movement/ (optionnel)
    ├── 01_network_scan.txt
    ├── 02_credentials_found.txt
    ├── 03_vm2_access.png
    ├── 04_vm3_access.png
    ├── 05_escalade_vm2.png
    ├── 06_escalade_vm3.png
    ├── 07_logs_ssh.txt
    ├── 08_wazuh_alerts.png
    └── 09_firewall_rules.txt
```

---

## ✅ Validation avant remise

Pour chaque attaque :
- [ ] Logs générés et sauvegardés
- [ ] Alerte Wazuh triggered et screenshot
- [ ] Réaction documentée
- [ ] Preuves photographiques complètes
- [ ] Timestamps correctes
- [ ] Règles Wazuh présentes

Pour l'ensemble :
- [ ] Tous les fichiers .md présents
- [ ] Scripts testés et fonctionnels
- [ ] README.md complet
- [ ] Structure GitHub respectée
- [ ] Pas de fichiers volumineux inutiles
- [ ] Tous les rôles couverts

---

## 🚀 Démarrage rapide

1. Lire **LIVRABLES.md** → Vue d'ensemble et checklists
2. Exécuter **05_escalade_privileges.md** → 5 attaques obligatoires
3. (Optionnel) Ajouter **06-08** → Attaques avancées
4. Documenter preuves → Folder `preuves/`
5. Remplir checklists → LIVRABLES.md
6. Pousser sur GitHub → `git push`

---

**Dernière mise à jour** : Février 2026  
**Version** : 1.0 (Production)
