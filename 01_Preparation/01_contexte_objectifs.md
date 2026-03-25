# 📖 1. Contexte et Objectifs du Projet

**Durée de lecture estimée** : 15 minutes  
**Niveau** : 2e année administration systèmes et réseaux  
**Compétences** : Infrastructure Linux, sécurité, détection d'attaques

---

## 🎯 Objectif du Projet

Ce projet simule une **infrastructure d'entreprise réelle** protégée par une équipe Blue Team (défense).

Tu vas construire un mini **SOC** (Security Operations Center) : l'endroit où les experts surveillent, détectent et réagissent aux attaques.

### Le scenario simplifié

```
┌─────────────────────────────────────────────────────────┐
│  SCÉNARIO : Entreprise sous attaque                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  TU ES : L'équipe Blue Team (défense)                   │
│  TA MISSION :                                            │
│    ✅ Sécuriser les serveurs                             │
│    ✅ Surveiller les activités                           │
│    ✅ Détecter les attaques                              │
│    ✅ Réagir aux incidents                               │
│                                                           │
│  L'ENNEMI : Un attaquant (ou groupe d'étudiants)        │
│  SON OBJECTIF :                                          │
│    ❌ Accéder au serveur web                             │
│    ❌ Voler des données                                  │
│    ❌ Paralyser les services                             │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 🏆 Compétences Validées à la Fin

### Administration Système
- ✅ Installation et configuration de **Rocky Linux** (équivalent RHEL)
- ✅ Hardening : sécuriser un OS dès l'installation
- ✅ Gestion des accès, SSH, sudo, pare-feu
- ✅ Audit système avec auditd

### Sécurité
- ✅ Comprendre les vecteurs d'attaque (brute force, scan, malveillance)
- ✅ Identifier les failles et les corriger
- ✅ SELinux : contrôle d'accès obligatoire
- ✅ Fail2ban : protection brute force

### SOC / Blue Team
- ✅ Centralisation des logs (rsyslog, Filebeat)
- ✅ **Wazuh** : IDS/SIEM (détection d'intrusions)
- ✅ Créer des règles de détection personnalisées
- ✅ Interpréter les alertes

### Monitoring & Incident Response
- ✅ **Zabbix** ou **Prometheus + Grafana** : supervision
- ✅ Playbooks d'incident response (IR)
- ✅ Scripts bash/Ansible pour réactions automatisées
- ✅ Forensics et post-mortem d'attaques

### Soft Skills
- ✅ Travail en équipe structurée (3 rôles distincts)
- ✅ Communication entre équipes
- ✅ Documentation technique claire

---

## 👥 Les 3 Rôles de l'Équipe

### 🔒 Rôle 1 : Administrateur Système & Hardening

**Mission** : Rendre les serveurs **difficiles à compromettre**.

Tu travailles **avant les attaques** (prévention).

#### Responsabilités
- Installation minimal et propre de Rocky Linux
- Configuration SSH sécurisée (pas de root, clés seulement, port custom)
- Firewall restrictif (fail2ban, firewalld)
- SELinux en mode enforcing
- Audit système complet (auditd)
- Benchmark de sécurité (Lynis)

#### Exemple : Sécuriser SSH
```bash
# ❌ Avant (dangereux)
→ Root peut se connecter via SSH
→ Les mots de passe sont acceptés
→ Port 22 standard (visible pour les attaquants)

# ✅ Après (sécurisé)
→ Root ne peut pas se connecter SSH
→ Seulement les clés publiques sont acceptées
→ SSH sur le port 2222 (plus discret)
→ Maximum 3 tentatives avant blocage (Fail2ban)
```

#### Livrables
- Checklist de hardening complète ✅
- Rapport Lynis (audit de sécurité)
- Configuration documentée de chaque service
- Diagramme du système sécurisé

---

### 🔍 Rôle 2 : SOC / Logs / Détection d'Intrusion (Blue Team)

**Mission** : **Voir ce qui se passe** et détecter les attaques.

Tu travailles **pendant les attaques** (détection).

#### Responsabilités
- Centraliser les logs de toutes les VM (SSH, Web, Firewall, Auditd)
- Installer et configurer **Wazuh** (SIEM/IDS)
- Créer des règles de détection personnalisées
- Déclencher des alertes en temps réel
- Analyser les logs pour identifier les comportements suspects

#### Exemple : Détecter un Brute Force SSH
```
ÉVÉNEMENT 1 : SSH | Failed password for invalid user admin from 192.168.1.50
ÉVÉNEMENT 2 : SSH | Failed password for invalid user root from 192.168.1.50
ÉVÉNEMENT 3 : SSH | Failed password for invalid user test from 192.168.1.50
...
ÉVÉNEMENT 5 : SSH | Failed password (repeat) from 192.168.1.50

RÈGLE WAZUH DÉCLENCHE :
⚠️ ALERTE : "Brute force SSH détecté - 5 tentatives échouées en 1 minute"
   → IP source : 192.168.1.50
   → Cible : serveur web
   → Sévérité : ÉLEVÉE
```

#### Livrables
- Liste de toutes les sources de logs
- Règles Wazuh personnalisées (XML)
- Screenshots des alertes en action
- Analyses détaillées d'au moins 3 attaques simulées

---

### 📊 Rôle 3 : Supervision & Incident Response

**Mission** : Assurer la **disponibilité** et **réagir** quand ça dérape.

Tu travailles **après la détection** (réaction/correction).

#### Responsabilités
- Installer **Zabbix** ou **Prometheus + Grafana**
- Monitorer CPU, RAM, disques, services, temps de réponse
- Créer des dashboards significatifs
- Détecter les anomalies (pics CPU, remplissage disque)
- Écrire des playbooks d'incident response (IR)
- Créer des scripts automatisés pour isoler/bloquer les attaques

#### Exemple : Réagir à une Attaque
```
DÉTECTION (Rôle 2) :
→ Wazuh décèle "Upload fichier malveillant en /var/www/html"

RÉACTION (Rôle 3) :
→ Script automatisé lance :
   1. Blocage IP source par le firewall
   2. Désactivation compte compromis
   3. Isolation réseau du serveur
   4. Notification administrateur
   5. Démarrage enquête forensique

DASHBOARD :
→ Affiche timeline de l'attaque
→ CPU/RAM/Réseau pendant l'incident
→ État avant/après réaction
```

#### Livrables
- Dashboards Zabbix/Grafana complets
- Playbooks incident response (format Markdown + Ansible)
- Scripts bash/Ansible de réaction
- Rapports post-incident (post-mortem)

---

## 🚀 Attaques à Simuler (Obligatoire)

Chaque attaque doit :

1. **Générer un log** (Rôle 2 le voit dans Wazuh)
2. **Déclencher une alerte** (Wazuh rule correspond)
3. **Avoir une réaction** (Rôle 3 bloque/isole/répond)

### 5 Attaques Essentielles

#### 🔴 Attaque 1 : Scan de Ports (Nmap)
```bash
# Depuis une machine attaquante
nmap -sS -p 1-65535 192.168.1.100

# Ce qui se passe :
Log → Firewall détecte connexions massives
Alert → Wazuh : "Port scan detected"
Reaction → Bloquer l'IP source pendant 1h
```

#### 🔴 Attaque 2 : Brute Force SSH
```bash
# Simulation d'attaque
for i in {1..10}; do
  ssh -p 2222 admin@192.168.1.100 << PASS
  wrongpassword$i
PASS
done

# Ce qui se passe :
Log → SSH log enregistre 10 tentatives échouées
Alert → Wazuh : "5+ failed SSH attempts en 1 min"
Reaction → Fail2ban + firewall bloquent l'IP
```

#### 🔴 Attaque 3 : Upload Fichier Malveillant
```bash
# Vers un formulaire web vulnérable
curl -X POST -F "file=@backdoor.sh" \
  http://192.168.1.100/upload.php

# Ce qui se passe :
Log → Nginx log l'upload + auditd détecte fichier .sh en /var/www
Alert → Wazuh : "Suspicious file upload detected"
Reaction → Isoler le répertoire, scan antivirus, notifier
```

#### 🔴 Attaque 4 : Tentative Élévation de Privilèges (Sudo)
```bash
# L'attaquant essaie de devenir root
sudo -i
sudo whoami
sudo cat /etc/shadow

# Ce qui se passe :
Log → auditd enregistre chaque commande sudo
Alert → Wazuh : "Unauthorized sudo attempt"
Reaction → Désactiver le compte, enquête

```

#### 🔴 Attaque 5 : Accès Hors Horaires
```bash
# Connexion SSH à 3h du matin (horaire anormal)
ssh -p 2222 user@192.168.1.100

# Ce qui se passe :
Log → SSH log la connexion avec timestamp
Alert → Wazuh rule : "SSH access outside business hours"
Reaction → Alerte élevée, investigation manuelle
```

---

## 📋 Vue d'Ensemble Complète

| Aspect | Détails |
|--------|---------|
| **Durée totale** | 6 semaines (30-40 heures) |
| **Équipe** | 3 personnes (1 rôle chacun) |
| **Machines** | 3 VM + 1 attaquante (optionnel) |
| **OS principal** | Rocky Linux 9.x |
| **Outils clés** | Wazuh, Zabbix, Firewalld, SELinux, Fail2ban |
| **Langages** | Bash, XML (Wazuh rules), YAML (Ansible) |
| **Valeur pédagogique** | ⭐⭐⭐⭐⭐ (entreprise réelle) |

---

## ❓ Questions Fréquentes

**Q: Je travaille seul, je fais quoi ?**  
R: Combine les 3 rôles, mais documente bien la séparation. Tu apprendras plus !

**Q: Rocky Linux, pourquoi pas Debian/Ubuntu ?**  
R: Rocky = RHEL (très utilisé en entreprise). Bonne expérience professionnelle.

**Q: Combien de temps par semaine ?**  
R: 6-8 heures minimum pour bien faire. Comptez 2-3 heures par partie.

**Q: Les attaques seront réelles ?**  
R: Non, vous les simulez volontairement. L'objectif est de **prouver que ça marche**.

**Q: Où je documente tout ça ?**  
R: GitHub (ce repo) + Rapports PDF pour l'évaluation.

---

## 📚 Prochaines Étapes

Avant de commencer, tu dois :

1. **Lire** → [`02_architecture_schema.md`](02_architecture_schema.md)  
   Comprendre comment les 3 VM communiquent

2. **Lire** → [`03_roles_equipes.md`](03_roles_equipes.md)  
   Détails précis de chaque rôle

3. **Vérifier** → [`04_prerequis.md`](04_prerequis.md)  
   Tu as le matériel et les logiciels ?

4. **Planifier** → [`05_timeline.md`](05_timeline.md)  
   Organiser le travail sur 6 semaines

---

## 📌 Symboles Utilisés dans la Doc

| Symbole | Signification |
|---------|---|
| ✅ | À faire / Complété |
| ❌ | À éviter / Mauvaise pratique |
| ⚠️ | Attention / Piège courant |
| 🎯 | Objectif important |
| 📚 | Ressource / Documentation |
| 🔒 | Sécurité critiqui |
| 🚀 | Performance / Optimisation |

---

**Version** : 1.0  
**Dernière mise à jour** : Février 2026  
**Auteur** : Équipe de formation La Plateforme
