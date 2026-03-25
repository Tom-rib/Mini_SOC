# 10 - Lynis : Audit de sécurité du système

## 🎯 Objectif
Installer et utiliser **Lynis** pour auditer la sécurité globale du système.

Lynis est un scanner de sécurité qui :
- Vérifie la configuration du système
- Teste les services et protocoles
- Propose des améliorations
- Génère un score de sécurité

**Durée estimée :** 45 minutes

---

## 📚 Concepts importants

### Qu'est-ce que Lynis ?

Lynis est un outil d'**audit de sécurité complet** qui fonctionne en 4 phases :

```
Phase 1: System Information
    ↓ (Récupère des infos générales)
Phase 2: Hardening Index
    ↓ (Teste 150+ aspects de sécurité)
Phase 3: Recommendations
    ↓ (Propose des améliorations)
Phase 4: Warnings
    ↓ (Alerte sur les problèmes critiques)
Score final
```

### Exemple de résultat

```
Security Scan Results
========================
Warnings:      4 (problèmes à traiter)
Suggestions:  28 (améliorations recommandées)
Info items:   42 (informations collectées)
Skipped tests: 8
Passed tests:  93

Hardening Index: 58 / 100
```

### Comparaison avec d'autres outils

| Outil | Niveau | Complexité | Vitesse |
|-------|--------|-----------|---------|
| **Lynis** | Basique | Simple | Très rapide |
| **NIST SAC** | Complet | Complexe | Lent |
| **CIS Benchmarks** | Détaillé | Très complexe | Variable |
| **Nessus** | Complet | Complexe | Moyen |

Lynis est parfait pour une **première vérification rapide**.

---

## ⚙️ Étape 1 : Installation

### Méthode 1 : Depuis le dépôt (recommandé)
```bash
sudo dnf install lynis -y
```

**Output attendu :**
```
Last metadata expiration check: 0:00:01 ago on Wed Nov 15 11:45:00 2024.
Dependencies resolved.
================================================================================
 Package         Arch           Version          Repository         Size
================================================================================
Installing:
 lynis           x86_64         2.5.9-1.el9      epel            512 kB

Installed:
  lynis-2.5.9-1.el9.x86_64
```

### Méthode 2 : Depuis le dépôt officiel (avancé)
```bash
cd /opt
sudo git clone https://github.com/CISOfy/lynis.git
cd lynis
sudo chmod +x lynis
sudo ./lynis --version
```

### Vérifier l'installation
```bash
lynis --version
```

**Output attendu :**
```
Lynis 2.5.9
Audit security tool for Linux, Unix, and Mac OS systems
Git development version
Copyright 2007-2024 CISOfy
License: GPL v3
```

---

## ⚙️ Étape 2 : Lancer un audit complet

### Audit système complet
```bash
sudo lynis audit system
```

Cela va prendre 3-5 minutes. Le processus :

1. **Détecte l'OS et les infos système**
2. **Teste les services (SSH, Firewall, SELinux, etc.)**
3. **Vérifie les configurations critiques**
4. **Propose des recommandations**
5. **Génère un score**

**Output attendu (pendant l'audit) :**
```
[ ] Hardening Index calculation...
    
  Security checks
  ================
  - Checking filesystem configuration
    * Filesystems in /etc/fstab...................... [ DONE ]
    * Checking mount point ACLs...................... [ DONE ]
    * Checking existing ACLs......................... [ DONE ]
    * Checking file attributes....................... [ DONE ]
    * Checking files permissions..................... [ DONE ]
    
  - Checking SSH configuration
    * SSH configuration............................... [ SUGGESTION ]
    * SSH Keys....................................... [ OK ]
    * SSH Allow/Deny................................. [ SUGGESTION ]
    * SSH Banner...................................... [ WARNING ]
    
  [...des centaines de tests...]
  
- Overall tests passed: 93
- Overall tests failed: 4
- Skipped: 8
- Items with warnings: 12
- Items with suggestions: 28
```

---

## 📊 Étape 3 : Interpréter les résultats

### Après l'audit, tu verras un résumé
```bash
=========================
Hardening Index Results:
=========================

  Hardening Index Score (HIS):      58
  Maximum Hardening Index Score:    100
  Percentage of hardened system:    58 %

  Actual Score: 58 / 100

  Improvement actions:
  - Consider implementing some of the Lynis recommendations...
```

### Comprendre les niveaux

| Niveau | Signification | Action |
|--------|---------------|-----------| 
| **OK** | ✅ Tout va bien | Aucune action nécessaire |
| **SUGGESTION** | 💡 Amélioration possible | À considérer |
| **WARNING** | ⚠️ Problème notable | À corriger |
| **UNKNOWN** | ❓ Test inactif | Peut être ignoré (dépend du test) |

### Exemple de suggestions (à la fin du rapport)
```
SUGGESTIONS FOR IMPROVEMENT
=============================

[ * ] SSH
    - Description: Consider hardening SSH configuration
    - File: /etc/ssh/sshd_config
    - Implement stricter SSH settings (e.g., disable password auth)
    
[ * ] Firewall
    - Description: Enable and configure firewall
    - Implement UFW or firewalld
    
[ * ] SELinux
    - Description: Set SELinux to enforcing mode
    - Benefits: Better system hardening
    
[ * ] Fail2ban
    - Description: Install and configure Fail2ban
    - Benefits: Protection against brute-force attacks
```

---

## 📈 Étape 4 : Générer des rapports détaillés

### Rapport texte complet
```bash
sudo lynis audit system > /tmp/lynis_audit_$(date +%Y%m%d_%H%M%S).txt
```

Cela sauvegarde le rapport complet dans un fichier.

### Voir le rapport
```bash
less /tmp/lynis_audit_*.txt
```

**Ou** consulte directement après l'audit :
```bash
sudo lynis audit system --quiet 2>/dev/null | tail -100
```

### Rapport HTML (avancé)
```bash
# Générer un rapport formaté
sudo lynis audit system --view 2>/dev/null | tee /tmp/lynis_report.txt
```

### Exécuter sans affichage en temps réel
```bash
sudo lynis audit system --quiet
```

Affiche seulement le résumé final.

---

## 🔍 Étape 5 : Analyser les avertissements courants

### Avertissement 1 : SSH Banner manquant

**Message :**
```
[ WARNING ] SSH configuration - No banner message set
```

**Pourquoi c'est important :** Le banneau SSH avertit les utilisateurs (conformité légale).

**Solution :**
```bash
sudo nano /etc/ssh/sshd_config
```

Ajoute ou modifie :
```
Banner /etc/ssh/banner.txt
```

Crée le fichier de banneau :
```bash
sudo nano /etc/ssh/banner.txt
```

Ajoute :
```
========================================================
                   SECURITY NOTICE
    Unauthorized access to this system is forbidden and 
    will be prosecuted by law.
========================================================
```

Redémarre SSH :
```bash
sudo systemctl restart sshd
```

### Avertissement 2 : Firewall désactivé

**Message :**
```
[ WARNING ] Firewall is not running
```

**Pourquoi c'est important :** Aucune protection réseau.

**Solution :** (à faire dans l'étape 06_firewall)
```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld
```

### Avertissement 3 : SELinux non en mode Enforcing

**Message :**
```
[ WARNING ] SELinux is not enabled
```

**Pourquoi c'est important :** Pas de contrôle d'accès au niveau noyau.

**Solution :** (déjà couvert dans étape 07_selinux)
```bash
sudo nano /etc/selinux/config
# Mets SELINUX=enforcing
```

### Avertissement 4 : Sudo mal configuré

**Message :**
```
[ SUGGESTION ] Configure sudo to require password confirmation
```

**Pourquoi c'est important :** Sécurité des commandes privilégiées.

**Solution :**
```bash
sudo visudo
```

Ajoute ou vérifie :
```
Defaults    use_pty
Defaults    logfile = "/var/log/sudo.log"
Defaults    log_input, log_output
```

---

## 🧪 Étape 6 : Suivi des améliorations

### Créer une liste de tâches

Après chaque audit Lynis, crée un fichier de suivi :

```bash
sudo lynis audit system > /tmp/lynis_$(date +%Y%m%d).log 2>&1
grep -i "suggestion\|warning" /tmp/lynis_$(date +%Y%m%d).log > /tmp/todo_security.txt
```

### Vérifier les améliorations après corrections

```bash
# Premier audit
sudo lynis audit system --quiet > /tmp/lynis_before.txt

# [Fais les corrections...]

# Deuxième audit
sudo lynis audit system --quiet > /tmp/lynis_after.txt

# Compare les scores
grep "Hardening Index" /tmp/lynis_*.txt
```

**Output attendu :**
```
/tmp/lynis_before.txt:  Hardening Index Score (HIS):      58
/tmp/lynis_after.txt:   Hardening Index Score (HIS):      72
```

Progression visible ! ✨

---

## ⚙️ Options avancées

### Audit spécifique (sans tests inutiles)
```bash
# Audit rapide (5 minutes)
sudo lynis audit system --quick

# Audit sans interactivité (pour scripts)
sudo lynis audit system --quiet --nolog
```

### Sauvegarder les résultats en JSON
```bash
# Requiert la version Pro, mais voici l'alternative
sudo lynis audit system 2>&1 | grep -E "^\[|SUGGESTION|WARNING" > /tmp/lynis_export.txt
```

### Auditer un domaine spécifique
```bash
# Vérifier les tests disponibles
sudo lynis show tests
```

Exemple de sortie :
```
SSH Security Tests:
  - SSH1 (SSH client)
  - SSH2 (SSH banner)
  - SSH3 (SSH configuration)
  
Firewall Tests:
  - FIRE1 (Firewall active)
  - FIRE2 (Rules present)
```

### Désactiver certains tests (optionnel)
```bash
sudo nano /etc/lynis/default.prf
```

Ajoute :
```
# Skip unwanted tests
skip-test=NETW-3012
skip-test=FILE-7524
```

---

## 📋 Checklist d'audit Lynis

### Template de suivi

```markdown
# Audit Lynis - Date: YYYY-MM-DD

## Score avant
- Hardening Index: __/100

## Avertissements à corriger
- [ ] Item 1 - Description
- [ ] Item 2 - Description
- [ ] Item 3 - Description

## Suggestions importantes
- [ ] Item 1 - Description
- [ ] Item 2 - Description

## Actions effectuées
- [x] SSH Banner configuré
- [x] Firewall activé
- [ ] SELinux en enforcing

## Score après
- Hardening Index: __/100

## Évolution
- Avant: __ points
- Après: __ points
- Gain: __ points
```

---

## ✅ Vérification finale

### Checklist de l'audit Lynis

- [ ] Lynis est installé (`lynis --version`)
- [ ] Un audit complet a été exécuté (`sudo lynis audit system`)
- [ ] Le score initial a été noté (ex: 58/100)
- [ ] Les 5 principaux avertissements sont identifiés
- [ ] Au moins 3 suggestions ont été corrigées
- [ ] Un deuxième audit montre une amélioration
- [ ] Les rapports sont sauvegardés pour comparaison

### Test final
```bash
# Lancer un audit rapide
sudo lynis audit system --quick

# Vérifier le score final
echo "========================================"
echo "Audit Lynis terminé avec succès !"
echo "========================================"
```

---

## 🆘 Troubleshooting courant

### Problème 1 : L'audit prend trop longtemps

**Cause :** Tests complexes ou disque lent.

**Solution :**
```bash
# Utiliser le mode rapide
sudo lynis audit system --quick

# Ou arrêter les tests inutiles
sudo nano /etc/lynis/default.prf
# Ajoute : skip-test=TEST_SLOW
```

### Problème 2 : Erreur "Permission denied"

**Symptôme :**
```
Error: No permission to read /etc/shadow
```

**Solution :**
```bash
# Lynis DOIT être lancé avec sudo
sudo lynis audit system
```

### Problème 3 : Certains tests retournent "UNKNOWN"

**Cause :** C'est normal pour certains tests conditionnels.

**Pas d'action nécessaire**, ces tests ne s'appliquent pas à ton système.

---

## 📊 Intégration continue (Avancé)

### Script de monitoring automatique

```bash
#!/bin/bash
# audit_check.sh - À mettre dans /usr/local/bin/

LOG_DIR="/var/log/lynis"
mkdir -p $LOG_DIR

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT="$LOG_DIR/lynis_$TIMESTAMP.log"

sudo lynis audit system --quiet > "$REPORT" 2>&1

# Extraire le score
SCORE=$(grep "Hardening Index Score" "$REPORT" | grep -oE "[0-9]+")

echo "Hardening Index Score: $SCORE/100"

# Alerte si score < 70
if [ "$SCORE" -lt 70 ]; then
    echo "ALERTE: Score de sécurité faible !" >&2
    exit 1
fi

exit 0
```

Rendre exécutable :
```bash
sudo chmod +x /usr/local/bin/audit_check.sh
```

Ajouter au cron (une fois par mois) :
```bash
sudo crontab -e
# Ajoute : 0 0 1 * * /usr/local/bin/audit_check.sh
```

---

## 📋 Résumé des commandes clés

```bash
# Installation
sudo dnf install lynis -y

# Audit complet
sudo lynis audit system

# Audit rapide
sudo lynis audit system --quick

# Audit silencieux (résumé seulement)
sudo lynis audit system --quiet

# Sauvegarder le rapport
sudo lynis audit system > /tmp/lynis_report_$(date +%Y%m%d).txt

# Voir les tests disponibles
sudo lynis show tests

# Version
lynis --version

# Aide
lynis --help
```

---

## 🎓 Points clés à retenir

1. **Lynis = scanner de sécurité généraliste** : Parfait pour une vue d'ensemble.
2. **Score HIS** : Indique le % de durcissement du système (cible: 70+).
3. **Trois niveaux** : OK (vert), SUGGESTION (jaune), WARNING (rouge).
4. **Audit régulier** : À faire après chaque changement majeur.
5. **Pas une solution complète** : À compléter avec CIS Benchmarks pour la production.

---

## 📚 Ressources

- Site officiel : https://cisofy.com/lynis/
- Documentation : `man lynis`
- Tests disponibles : `sudo lynis show tests`
- Configuration : `/etc/lynis/default.prf`

---

## 📝 Prochaines étapes

Après Lynis, tu dois :

1. **Corriger les avertissements** (priorité haute)
2. **Implémenter les suggestions** (priorité moyenne)
3. **Refaire un audit** dans 2 semaines
4. **Comparer les scores** pour valider le progrès
5. **Documenter les changements** dans ton rapport du projet

