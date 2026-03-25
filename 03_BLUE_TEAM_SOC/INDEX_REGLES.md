# 📑 Index des Règles de Détection Wazuh

**Vue d'ensemble rapide de tous les IDs de règles et leurs usages**

---

## 🎯 Règles par domaine

### SSH & Authentification (100001-100015)

| ID | Nom | Level | Condition | Fichier |
|---|---|---|---|---|
| 100001 | SSH Failed login (baseline) | 3 | if_sid 5701 match "Failed password" | 10 |
| 100002 | **SSH Brute force** | **7** | **frequency 5/60s same_source_ip** | **10** |
| - | - | - | - | - |

### Escalade de Privilèges (100010-100025)

| ID | Nom | Level | Condition | Fichier |
|---|---|---|---|---|
| 100010 | **Sudo NOT in sudoers** | **6** | **match "user NOT in sudoers"** | **11** |
| 100011 | Sudo executed (baseline) | 3 | if_sid 5402 match "COMMAND=" | 11 |
| 100012 | **Sudo dangerous command** | **8** | **regex cat/shadow, rm -rf, etc** | **11** |
| 100013 | **Sudo brute force** | **7** | **frequency 10/300s same_source_ip** | **11** |

### Reconnaissance Réseau (100020-100025)

| ID | Nom | Level | Condition | Fichier |
|---|---|---|---|---|
| 100020 | Firewall REJECT (baseline) | 2 | match "REJECT" | 12 |
| 100021 | **Port scan** | **6** | **frequency 20/60s same_source_ip** | **12** |
| 100022 | **SYN scan rapid** | **7** | **regex SYN frequency 15/30s** | **12** |
| 100023 | Suspicious port targeted | 5 | DPT=(3389, 5900, 5901, 445, 139) | 12 |
| 100024 | UDP port scan | 5 | PROTO=UDP frequency 30/60s | 12 |

### File Integrity Monitoring (100030-100035)

| ID | Nom | Level | Condition | Fichier |
|---|---|---|---|---|
| 100030 | File created (baseline) | 3 | if_sid 550 match "/uploads" | 13 |
| 100031 | **Suspicious extension** | **9** | **regex .php, .sh, .exe, etc** | **13** |
| 100032 | Archive uploaded | 5 | regex .zip, .tar, .rar | 13 |
| 100033 | System file modified | 8 | if_sid 553 match "/bin, /etc" | 13 |
| 100034 | Important file deleted | 7 | if_sid 554 match "/var/www, /etc" | 13 |
| 100035 | **Multiple uploads rapid** | **6** | **frequency 10/60s** | **13** |

### Time-Based Detection (100040-100048)

| ID | Nom | Level | Condition | Fichier |
|---|---|---|---|---|
| 100040 | SSH accepted (baseline) | 2 | if_sid 5715 match "Accepted" | 14 |
| 100041 | **SSH night time** | **6** | **time_window 00:00-07:59** | **14** |
| 100042 | **SSH very early morning** | **7** | **time_window 04:00-06:00** | **14** |
| 100043 | SSH late evening | 5 | time_window 21:00-23:59 | 14 |
| 100044 | **Success after failed** | **8** | **if_matched_group auth_failure** | **14** |
| 100045 | **Multiple logins rapid** | **6** | **frequency 3/300s same_user** | **14** |

---

## 📊 Récapitulatif par fichier

### 09_regles_syntax.md (Théorie)
**Durée** : 45 min  
**Contenu** : Syntaxe XML, niveaux, concepts de base  
**Règles créées** : 0 (fondations seulement)

### 10_detection_bruteforce_ssh.md
**Durée** : 1h  
**Contenu** : Brute force SSH avec frequency/timeframe  
**Règles créées** :
- 100001 (baseline)
- 100002 (brute force)

### 11_detection_sudo.md
**Durée** : 1h  
**Contenu** : Escalade privilèges, regex avancée  
**Règles créées** :
- 100010 (NOT in sudoers)
- 100011 (baseline)
- 100012 (dangerous commands)
- 100013 (brute force)

### 12_detection_nmap.md
**Durée** : 1h  
**Contenu** : Port scanning, firewall logs  
**Règles créées** :
- 100020 (baseline)
- 100021 (port scan)
- 100022 (SYN scan)
- 100023 (suspicious ports)
- 100024 (UDP scan)

### 13_detection_uploads.md
**Durée** : 1h  
**Contenu** : File integrity monitoring, webshells  
**Règles créées** :
- 100030 (baseline)
- 100031 (dangerous extensions)
- 100032 (archives)
- 100033 (system modified)
- 100034 (file deleted)
- 100035 (rapid uploads)

### 14_detection_horaires.md
**Durée** : 1h  
**Contenu** : Time-based detection, anomaly detection  
**Règles créées** :
- 100040 (baseline)
- 100041 (night time)
- 100042 (early morning)
- 100043 (late evening)
- 100044 (success after failed)
- 100045 (multiple logins)

**Total** : 20 règles, 6 heures

---

## 🚨 Règles CRITIQUES (Level 8-9)

Ces règles indiquent une **probable compromission** :

| ID | Raison | Action |
|---|---|---|
| 100002 | Brute force SSH | Bloquer IP 10 min |
| 100012 | Sudo dangerous command | Isoler serveur |
| 100031 | Webshell upload | Supprimer fichier + audit |
| 100044 | Success after failed | Forcer reset pwd |

---

## ⚠️ Règles ATTENTION (Level 5-7)

Anomalies à surveiller mais pas critiques :

| ID | Raison | Action |
|---|---|---|
| 100010 | Sudo unauthorized | Notifier user |
| 100021 | Port scan | Log + analyse |
| 100041 | Night SSH | Vérifier avec user |
| 100043 | Late evening SSH | Acceptable si admin |

---

## 📚 Statistiques

```
Total de règles        : 20
Règles SSH/auth       : 4
Règles escalade       : 4
Règles réseau         : 5
Règles fichiers       : 6
Règles temps          : 6

Par niveau :
- Level 2-3 (info)    : 4 (baseline)
- Level 5-6 (warning) : 8
- Level 7-8 (alert)   : 6
- Level 9 (critical)  : 2
```

---

## 🔗 Dépendances entre règles

```
Brute Force SSH :
100001 (baseline) → 100002 (frequency agg)

Escalade Privileges :
100011 (baseline) → 100012 (dangerous cmd)
100010 (failed)   → 100013 (frequency brute)

Port Scan :
100020 (baseline) → 100021 (frequency agg)
                 → 100022 (SYN rapid)
                 → 100023 (suspicious ports)

File Upload :
100030 (baseline) → 100031 (extensions)
                 → 100032 (archives)
                 → 100035 (frequency)

Time Detection :
100040 (baseline) → 100041-100043 (time windows)
                 → 100044 (after failed)
                 → 100045 (frequency user)
```

---

## 🧪 Matrice de tests

### Attaques à simuler

```
Brute Force SSH
├─ Command : hydra -l root -P list.txt IP ssh
├─ Expected : Rule 100002 (level 7)
└─ Duration : 5 minutes

Escalade Sudo
├─ Command : sudo cat /etc/shadow (non autorisé)
├─ Expected : Rule 100010 (level 6)
└─ Duration : 30 secondes

Port Scan
├─ Command : nmap -p 1-1000 IP
├─ Expected : Rule 100021 (level 6)
└─ Duration : 2 minutes

Upload Webshell
├─ Command : curl -F "file=@shell.php" http://IP/upload.php
├─ Expected : Rule 100031 (level 9)
└─ Duration : Immédiat

Night Login
├─ Command : SSH à 3h du matin
├─ Expected : Rule 100041-100042 (level 6-7)
└─ Duration : Immédiat
```

---

## 📋 Checklist avant production

- [ ] Tous les IDs sont uniques (100001-100048)
- [ ] Tous les if_sid correctement référencés
- [ ] Time windows correctement formatés
- [ ] Regex validées sur regex101.com
- [ ] Levels cohérents (0-15)
- [ ] Descriptions claires
- [ ] Groups cohérents
- [ ] MITRE IDs pertinents
- [ ] Tests passent sur wazuh-logtest
- [ ] Wazuh redémarré après modifs

---

## 🎯 Progression recommandée

### Jour 1 (2h)
1. Lire 09_regles_syntax.md
2. Faire 10_detection_bruteforce_ssh.md (pratique avec hydra)
3. Valider 2 règles (100001-100002)

### Jour 2 (2h)
1. Faire 11_detection_sudo.md (4 règles)
2. Faire 12_detection_nmap.md (5 règles)
3. Valider total 11 règles

### Jour 3 (2h)
1. Faire 13_detection_uploads.md (6 règles)
2. Faire 14_detection_horaires.md (6 règles)
3. Valider total 20 règles

---

## 💡 Tips & Tricks

### Debug une règle qui ne déclenche pas

```bash
# 1. Vérifier syntaxe
sudo /var/ossec/bin/wazuh-logtest

# 2. Tester manuellement
echo "Jan 15 14:32:01 server sshd: Failed password for root from 192.168.1.50" | \
  sudo /var/ossec/bin/wazuh-logtest

# 3. Vérifier if_sid correct
grep "<rule id=\"5701\"" /var/ossec/etc/rules/*.xml

# 4. Recharger et vérifier logs
sudo systemctl restart wazuh-manager
sudo tail -50 /var/ossec/logs/ossec.log | grep -i error
```

### Voir toutes les alertes d'une règle

```bash
sudo grep '"id":"100002"' /var/ossec/logs/alerts/alerts.json | wc -l
```

### Lister les règles par niveau

```bash
grep 'level="9"' /var/ossec/etc/rules/local_rules.xml
grep 'level="8"' /var/ossec/etc/rules/local_rules.xml
```

---

## 🔐 Sécurité des règles

**Important** : Les règles sont stockées en clair, donc :

```bash
# Restreindre l'accès
sudo chmod 640 /var/ossec/etc/rules/local_rules.xml

# Sauvegarder régulièrement
sudo cp /var/ossec/etc/rules/local_rules.xml /backup/local_rules.xml.bak

# Verifier checksum
sudo sha256sum /var/ossec/etc/rules/local_rules.xml
```

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-15  
**Statut** : Complète (20/20 règles)
