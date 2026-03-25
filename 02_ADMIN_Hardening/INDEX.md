# 🔒 Hardening Avancé - Index des 4 étapes

## 📍 Plan d'action

Ce module couvre le **hardening avancé** du serveur Rocky Linux en 4 étapes progressives :

### Timeline globale : **4 heures** (répartissables)

| # | Étape | Durée | Focus | Niveau |
|---|-------|-------|-------|--------|
| **07** | SELinux | 45 min | Contrôle d'accès noyau | ⭐⭐ |
| **08** | Fail2ban | 1h | Protection brute force | ⭐ |
| **09** | Auditd | 1h30 | Logging et audit | ⭐⭐⭐ |
| **10** | Lynis | 45 min | Scan et scoring | ⭐ |

---

## 🎯 Objectifs globaux

Après ces 4 étapes, le système aura :

- ✅ Contrôle d'accès obligatoire (SELinux enforcing)
- ✅ Protection contre attaques brute force (Fail2ban)
- ✅ Logging complet au niveau noyau (Auditd)
- ✅ Score de sécurité mesurable (Lynis)

**Cible :** Hardening Index > 70/100

---

## 📚 Descriptions courtes

### 07 - SELinux (45 min)
**Fichier :** [07_selinux.md](./07_selinux.md)

SELinux ajoute une couche de **contrôle d'accès obligatoire** au-dessus des permissions Unix.

**Ce que tu feras :**
1. Activer le mode `enforcing`
2. Configurer les contextes SELinux
3. Analyser les logs d'audit SELinux
4. Ajuster avec les booléens SELinux

**Compétences validées :**
- Comprendre MAC vs DAC
- Configurer le mode enforcing
- Lire les logs d'audit SELinux
- Résoudre les violations SELinux

---

### 08 - Fail2ban (1h)
**Fichier :** [08_fail2ban.md](./08_fail2ban.md)

Fail2ban protège contre les **attaques brute force** en bloquant automatiquement les IP malveillantes.

**Ce que tu feras :**
1. Installer et configurer Fail2ban
2. Créer une jail SSH avec seuils
3. Tester avec des tentatives échouées
4. Monitorer avec `fail2ban-client`

**Compétences validées :**
- Installer et configurer un IPS
- Comprendre les jails et règles
- Tester une protection de sécurité
- Analyser les bannissements

---

### 09 - Auditd (1h30)
**Fichier :** [09_auditd.md](./09_auditd.md)

Auditd enregistre **TOUTES les activités système** au niveau du noyau pour la forensique.

**Ce que tu feras :**
1. Installer auditd
2. Configurer 11 groupes de règles
3. Consulter les logs avec `ausearch`
4. Générer des rapports avec `aureport`

**Compétences validées :**
- Configurer des règles d'audit complexes
- Analyser les logs d'audit
- Comprendre la forensique Linux
- Documenter les changements système

---

### 10 - Lynis (45 min)
**Fichier :** [10_lynis.md](./10_lynis.md)

Lynis scanne le système et donne un **score de sécurité** avec des recommandations.

**Ce que tu feras :**
1. Installer Lynis
2. Lancer un audit complet
3. Interpréter les avertissements et suggestions
4. Corriger les problèmes identifiés

**Compétences validées :**
- Utiliser des outils d'audit de sécurité
- Comprendre les best practices
- Mettre en place des améliorations
- Mesurer le progrès en sécurité

---

## 🔄 Flux d'exécution recommandé

### Ordre conseillé :

```
1️⃣  SELinux (45 min)
    └─ Base : contrôle d'accès noyau
    
2️⃣  Fail2ban (1h)
    └─ Protection immédiate contre brute force
    
3️⃣  Auditd (1h30)
    └─ Logging complet pour les étapes précédentes
    
4️⃣  Lynis (45 min)
    └─ Audit + scoring (valide les 3 étapes)
```

### Timing flexible :

**Jour 1 (2h)** : SELinux + Fail2ban + pause
**Jour 2 (2h)** : Auditd + Lynis + corrections

---

## 🔗 Dépendances et intégrations

```
SELinux
    ↓
    └─→ Génère des logs dans /var/log/audit/audit.log
    
Fail2ban
    ↓
    └─→ Logs dans /var/log/fail2ban.log
    └─→ Actions firewall (vérifiable avec iptables)
    
Auditd
    ↓
    └─→ Centralise les logs de SELinux + Fail2ban + système
    
Lynis
    ↓
    └─→ Audit tout ce qui précède
    └─→ Donne un score global
```

---

## 📊 Matrix de vérification

### Après chaque étape

| Étape | Commande de vérification | Output attendu |
|-------|--------------------------|-----------------|
| **SELinux** | `getenforce` | `Enforcing` |
| **SELinux** | `sestatus -v` | `Current mode: enforcing` |
| **Fail2ban** | `sudo systemctl status fail2ban` | `active (running)` |
| **Fail2ban** | `sudo fail2ban-client status` | `Jail list: sshd` |
| **Auditd** | `sudo systemctl status auditd` | `active (running)` |
| **Auditd** | `sudo auditctl -l \| wc -l` | `30+` règles |
| **Lynis** | `sudo lynis --version` | version affichée |
| **Lynis** | `sudo lynis audit system --quiet` | Score HIS: XX/100 |

---

## 🎓 Compétences progressives

### Niveau 1 : Installation basique
- ✅ Installer les outils
- ✅ Vérifier qu'ils tournent
- ✅ Lire les logs basiques

### Niveau 2 : Configuration
- ✅ Modifier les configurations
- ✅ Créer des règles personnalisées
- ✅ Tester les protections

### Niveau 3 : Analyse et troubleshooting
- ✅ Interpréter les résultats complexes
- ✅ Résoudre les conflits de sécurité
- ✅ Optimiser les paramètres

### Niveau 4 : Automatisation (optionnel)
- ✅ Scripter les audits
- ✅ Intégrer au CI/CD
- ✅ Générer des rapports automatiques

---

## 📈 Mesure de progrès

### Score attendu par étape

```
Avant tout (système vierge):    Lynis score ~ 30/100
Après SELinux:                  Lynis score ~ 45/100
Après Fail2ban:                 Lynis score ~ 55/100
Après Auditd:                   Lynis score ~ 70/100
Après Lynis (corrections):      Lynis score ~ 80/100
```

**Cible finale : 75+/100**

---

## 📝 Livrables attendus

### À la fin du module de hardening

**Pour chaque étape (07-10) :**
1. ✅ Fichier de configuration (`/etc/selinux/config`, `/etc/fail2ban/jail.local`, etc.)
2. ✅ Logs de test (avant/après activation)
3. ✅ Screenshots des vérifications
4. ✅ Commandes de test exécutées

**Résumé global :**
1. ✅ Rapport Lynis initial (début du module)
2. ✅ Rapport Lynis final (fin du module)
3. ✅ Liste des améliorations implémentées
4. ✅ Comparaison des scores (avant/après)

---

## 🆘 Aide à la sélection

### Débutant ? Commence par :
1. Fail2ban (le plus simple, impact immédiat)
2. SELinux (concepts importants)
3. Lynis (validation)
4. Auditd (pour la rédaction du rapport)

### Intermédiaire ? Fais :
1. SELinux + Fail2ban en parallèle
2. Auditd pour la surveillance
3. Lynis pour le scoring

### Avancé ? Personnalise :
1. Skips SELinux si tu maîtrises
2. Configure Auditd avec règles personnalisées
3. Intègre Lynis à un système de monitoring

---

## 📚 Prérequis

- [ ] Rocky Linux installé et à jour
- [ ] Accès root/sudo configuré
- [ ] SSH fonctionnel (pour tester Fail2ban)
- [ ] Fichier `/var/log/secure` généré (quelques logs SSH)

---

## 🎬 Pédagogie : Comment utiliser ces fichiers

### Pour l'étudiant (toi) :

1. **Lis l'objectif** au début du fichier
2. **Exécute les commandes** étape par étape
3. **Regarde l'output attendu** et compare avec ton résultat
4. **Fais les tests** pour vérifier que ça marche
5. **Consulte le troubleshooting** si quelque chose ne va pas
6. **Valide avec la checklist** à la fin

### Pour le professeur (évaluation) :

1. **Vérifier les fichiers de configuration** (`/etc/selinux/config`, etc.)
2. **Tester avec les commandes de vérification** (getenforce, fail2ban-client, etc.)
3. **Vérifier les logs** (SELinux, Fail2ban, Auditd)
4. **Demander le rapport Lynis** avant/après
5. **Évaluer le progrès** (score HIS initial vs final)

---

## 🔗 Intégration au reste du projet

Ces 4 étapes sont dans le rôle **Rôle 1 : Administrateur système & hardening**.

Elles s'intègrent avec :
- **05_services_base** : Configuration SSH, Nginx
- **06_firewall** : Firewalld pour Fail2ban
- **Rôle 2** : Auditd fournit les logs pour Wazuh
- **Rôle 3** : Lynis donne les métriques système pour Zabbix

---

## 📅 Gestion du temps

### Horaire recommandé (pour 2 jours)

**Jour 1 - Matin (2h)**
- 08:00 - 08:45 : SELinux
- 08:45 - 09:45 : Fail2ban
- 09:45 - 10:00 : Pause

**Jour 1 - Après-midi (2h)**
- 14:00 - 15:30 : Auditd
- 15:30 - 16:15 : Lynis
- 16:15 - 17:00 : Corrections et rapport

**Jour 2**
- Tester les interactions
- Générer les rapports finals
- Documenter les apprentissages

---

## ✨ Prochaines étapes après ce module

Une fois les 4 étapes complétées :

1. **Valider avec Lynis** (score > 75/100)
2. **Documenter** dans ton README du projet
3. **Passer à Rôle 2** (SOC et détection)
4. **Intégrer Auditd** avec le SIEM (Wazuh)
5. **Monitorer** avec Zabbix/Prometheus (Rôle 3)

---

## 📞 Récapitulatif des fichiers

| Fichier | Durée | Concepts clés |
|---------|-------|--------------|
| [07_selinux.md](./07_selinux.md) | 45 min | MAC, enforcing, contextes, booléens |
| [08_fail2ban.md](./08_fail2ban.md) | 1h | Jails, seuils, IPS, brute force |
| [09_auditd.md](./09_auditd.md) | 1h30 | Règles, ausearch, forensique, immutable |
| [10_lynis.md](./10_lynis.md) | 45 min | Audit, HIS, recommendations, scoring |

---

## 🏁 Objectif final

À la fin de ces 4 étapes, tu auras :

✅ Un **système hardené** selon les standards Rocky Linux/RHEL
✅ Une **protection active** contre les attaques courantes
✅ Un **logging complet** pour la détection et forensique
✅ Un **score de sécurité** mesurable et améliorable
✅ Une **documentation** complète pour le projet

**Score cible : Lynis HIS 75+/100**

---

Bonne chance ! 🎯

