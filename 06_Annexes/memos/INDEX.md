# 📚 Index des Mémos - Guide de Navigation

> **Objectif** : Index centralisé de tous les mémos du projet Mini SOC.  
> **Usage** : Ouvrir ce fichier pour trouver rapidement le mémo dont vous avez besoin.

---

## 📖 Structure des Mémos

Tous les fichiers sont organisés dans `/06_ANNEXES/memos/` :

```
06_ANNEXES/
└── memos/
    ├── INDEX.md                    ← Vous êtes ici
    ├── 01_memo_linux.md           (Cheat sheet Linux)
    ├── 02_memo_ssh.md             (SSH & authentification)
    ├── 03_memo_firewalld.md       (Firewall)
    ├── 04_memo_wazuh.md           (SIEM & détection)
    └── 05_depannage.md            (Troubleshooting FAQ)
```

---

## 🎯 Quel Mémo pour Quel Besoin ?

### 1️⃣ **Je dois naviguer / lister fichiers / éditer fichiers**
→ **[01_memo_linux.md](./01_memo_linux.md)**

**Contenu :**
- Navigation (`cd`, `ls`, `pwd`)
- Affichage fichiers (`cat`, `less`, `tail`)
- Édition (`nano`, `vim`)
- Permissions (`chmod`, `chown`)
- Gestion utilisateurs
- Processes & services
- Logs & recherche (`grep`, `awk`)
- Réseau & connectivité
- Disques & espace

**Exemple de besoin :**
- Comment copier un fichier ?
- Comment voir les permissions ?
- Comment trouver une erreur dans les logs ?
- Comment vérifier qu'un processus tourne ?

---

### 2️⃣ **Je dois configurer SSH ou me connecter aux VMs**
→ **[02_memo_ssh.md](./02_memo_ssh.md)**

**Contenu :**
- Générer clés SSH (RSA, ED25519)
- Copier clés publiques (`ssh-copy-id`)
- Configuration SSH (`~/.ssh/config`)
- Connexion et exécution distante
- SCP (copie fichiers)
- SSH tunneling (port forwarding)
- Troubleshooting permissions
- Multi-clés

**Exemple de besoin :**
- Comment générer une clé SSH ?
- Comment me connecter sans password ?
- Comment copier un fichier vers le serveur ?
- Pourquoi "Permission denied" ?

---

### 3️⃣ **Je dois configurer le firewall (ouvrir ports, ajouter règles)**
→ **[03_memo_firewalld.md](./03_memo_firewalld.md)**

**Contenu :**
- Démarrage/arrêt firewalld
- Gestion des zones (public, internal, dmz)
- Ouverture de ports (TCP/UDP)
- Services prédéfinis
- Règles personnalisées (rich rules)
- NAT & forwarding
- Configuration du projet
- Troubleshooting firewall

**Exemple de besoin :**
- Ouvrir le port 2222 pour SSH ?
- Bloquer une IP spécifique ?
- Limiter les connexions (rate limiting) ?
- Pourquoi SSH ne passe pas ?

---

### 4️⃣ **Je dois installer/configurer Wazuh ou vérifier les alertes**
→ **[04_memo_wazuh.md](./04_memo_wazuh.md)**

**Contenu :**
- Installation Manager Wazuh
- Installation Agents Wazuh
- Enregistrement des agents
- Configuration des sources de logs
- Interface web Wazuh
- Règles personnalisées (détection)
- Alertes et niveaux de sévérité
- Intégration Elasticsearch/Kibana
- Logs et fichiers Wazuh
- Troubleshooting Wazuh

**Exemple de besoin :**
- Comment installer Wazuh ?
- Comment enregistrer un agent ?
- Comment créer une règle de détection ?
- Pourquoi pas de logs collectés ?
- Comment configurer les alertes email ?

---

### 5️⃣ **Quelque chose ne marche pas, je dois résoudre un problème**
→ **[05_depannage.md](./05_depannage.md)**

**Contenu :**
- SSH : Connection refused, Permission denied
- Firewall : Port ouvert mais inaccessible
- Wazuh : Agent déconnecté, pas de logs
- Monitoring : Agent non disponible
- Espace disque plein
- SELinux bloque
- Réseau : VMs ne communiquent pas
- Commandes de debug universelles
- Checklist avant de demander aide
- Escalade d'urgence

**Exemple de besoin :**
- SSH refuses my connection !
- Je ne peux plus me connecter du tout !
- Les logs n'arrivent pas dans Wazuh !
- Le disque est plein !

---

## 🚀 Guide Rapide par Étape du Projet

### **Étape 1 : Installation & Préparation**

```
1. Générer clés SSH          → 02_memo_ssh.md (section 1-2)
2. Se connecter aux VMs      → 02_memo_ssh.md (section 4)
3. Naviguer dans les fichiers → 01_memo_linux.md (section 1)
4. Configurer firewall       → 03_memo_firewalld.md (section 3-7)
```

### **Étape 2 : Installation Wazuh**

```
1. Installer Manager Wazuh   → 04_memo_wazuh.md (section 1)
2. Installer Agents          → 04_memo_wazuh.md (section 1)
3. Enregistrer agents        → 04_memo_wazuh.md (section 3)
4. Configurer sources logs   → 04_memo_wazuh.md (section 4)
```

### **Étape 3 : Créer Règles de Détection**

```
1. Comprendre les règles     → 04_memo_wazuh.md (section 6)
2. Créer règles custom       → 04_memo_wazuh.md (section 6)
3. Tester les règles         → 04_memo_wazuh.md (section 6)
4. Voir les alertes          → 04_memo_wazuh.md (section 7)
```

### **Étape 4 : Tests & Attaques Simulées**

```
1. Générer événement test    → 04_memo_wazuh.md (section 7)
2. Vérifier alertes          → 04_memo_wazuh.md (section 7)
3. Déboguer si problème      → 05_depannage.md (Wazuh section)
```

### **Étape 5 : Troubleshooting**

```
Si SSH ne marche pas         → 05_depannage.md (SSH section)
Si firewall bloque           → 05_depannage.md (Firewall section)
Si Wazuh ne collecte rien    → 05_depannage.md (Wazuh section)
Autre problème               → 05_depannage.md (Checklist)
```

---

## 🔍 Comment Utiliser les Mémos

### Pour Trouver une Commande Spécifique

1. **Ouvrir le mémo approprié**
2. **Ctrl+F** pour rechercher le mot-clé
   - Ex: `ssh-keygen`, `firewall-cmd`, `systemctl`, etc.
3. **Lire la section** avec contexte et explication

### Pour Comprendre un Concept

1. **Aller au mémo du domaine**
2. **Lire la section explicative** (premier paragraphe)
3. **Voir les exemples pratiques**
4. **Adapter à votre situation**

### Pour Déboguer un Problème

1. **Aller dans [05_depannage.md](./05_depannage.md)**
2. **Chercher le symptôme exact**
3. **Suivre les solutions proposées**
4. **Tester avec les commandes fournis**

---

## 📊 Vue d'Ensemble des Mémos

| Mémo | Domaine | Commandes | Niveaux |
|------|---------|-----------|---------|
| 01_memo_linux | Système | 50+ | Navigation, fichiers, users, réseau |
| 02_memo_ssh | Sécurité | 30+ | Clés, tunneling, troubleshooting |
| 03_memo_firewalld | Réseau | 40+ | Ports, zones, rich rules, NAT |
| 04_memo_wazuh | SOC | 25+ | Installation, rules, alertes |
| 05_depannage | Support | Procédures | SSH, firewall, Wazuh, réseau |

---

## 💡 Tips de Productivité

### Bookmark les sections importantes

```bash
# Marquer dans votre éditeur :
# 02_memo_ssh → Section "Configuration SSH"
# 03_memo_firewalld → Section "Configuration du Projet"
# 04_memo_wazuh → Section "Règles Personnalisées"
# 05_depannage → Section "Checklist"
```

### Créer un alias pour accès rapide

```bash
# Dans ~/.bash_profile ou ~/.bashrc :
alias memos='cd ~/mini-soc-rocky/06_ANNEXES/memos && ls -la'
alias memo_linux='less 01_memo_linux.md'
alias memo_ssh='less 02_memo_ssh.md'
alias memo_firewall='less 03_memo_firewalld.md'
alias memo_wazuh='less 04_memo_wazuh.md'
alias memo_debug='less 05_depannage.md'

# Utiliser :
memos              # Voir tous les mémos
memo_ssh           # Ouvrir mémo SSH
```

### Chercher une commande dans tous les mémos

```bash
# Rechercher "systemctl" dans tous les mémos
grep -n "systemctl" *.md

# Chercher "firewall-cmd" avec contexte
grep -B2 -A2 "firewall-cmd" *.md
```

---

## ✅ Checklist : Mémos à Réviser

Avant de commencer le projet :

- [ ] Lire **01_memo_linux** : sections "À retenir absolument"
- [ ] Lire **02_memo_ssh** : sections 1-4 (génération + connexion)
- [ ] Lire **03_memo_firewalld** : sections 1-3 (ports basics)
- [ ] Lire **04_memo_wazuh** : sections 1-3 (installation)
- [ ] Parcourir **05_depannage** : section "Checklist"

Pendant le projet :

- [ ] Garde **05_depannage.md** ouvert en arrière-plan
- [ ] Consulte les memos au fur et à mesure
- [ ] Ajoute tes propres notes/variantes

---

## 🎓 Objectif Pédagogique

Ces mémos visent à :

✅ **Fournir références rapides** pendant le projet  
✅ **Expliquer la "pourquoi"** pas juste le "comment"  
✅ **Servir de révisions** après le projet  
✅ **Être réutilisables** pour d'autres projets  
✅ **Couvrir 90% des cas** rencontrés en année 2  

---

## 📞 Structure de Chaque Mémo

Chaque mémo suit cette structure :

1. **En-tête** : Objectif + contexte
2. **Table des matières** : Sections principales
3. **Sections numérotées** : Chaque concept/commande
4. **Tableaux & listes** : Format rapide
5. **Exemples pratiques** : Avec output attendu
6. **Troubleshooting** : Si applicable
7. **Résumé** : Points clés à retenir

---

## 🔗 Navigation Rapide

```markdown
👉 Commandes Linux générales          → 01_memo_linux.md
👉 SSH & authentification par clé    → 02_memo_ssh.md  
👉 Firewall & ouverture ports        → 03_memo_firewalld.md
👉 Installation/config Wazuh         → 04_memo_wazuh.md
👉 Je suis bloqué / problème         → 05_depannage.md
```

---

## 📈 Versions & Updates

| Version | Date | Changements |
|---------|------|-------------|
| 1.0 | 2025-02 | Création initiale (5 mémos) |
| 1.1 | - | À ajouter : Monitoring, automatisation |

Vous pouvez ajouter vos propres notes / corrections !

---

**Créé pour** : Projet Mini SOC sécurisé sous Rocky Linux  
**Niveau** : 2e année Administration Systèmes & Réseaux  
**Usage** : À garder ouvert pendant tout le projet ! 📖

---

**Besoin d'un mémo supplémentaire ?** Créez-le en suivant le même format ! 🚀
