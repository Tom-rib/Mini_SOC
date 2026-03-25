# Wazuh Dashboard - Guide d'utilisation de l'interface

**Objectif du chapitre :** Naviguer dans le Dashboard Wazuh et interpréter les alertes

**Durée estimée :** 1-2 heures

**Prérequis :**
- Wazuh Manager opérationnel
- Agents connectés et actifs
- Logs configurés et arrivant
- Accès au Dashboard HTTPS

---

## 1. Accès au Dashboard

### URL d'accès

```
https://IP_MANAGER:443/app/wazuh
```

Remplace `IP_MANAGER` par l'IP de ta VM 2.

**Exemple :**
```
https://192.168.1.50:443/app/wazuh
```

### Identifiants

```
Utilisateur : admin
Mot de passe : [ton mot de passe]
```

### Certificat SSL

À la première visite, tu verras un avertissement SSL (certificat auto-signé).

**Clic :** Advanced → Proceed anyway (ou Accept)

### Page d'accueil

Après login, tu arrives sur le **Dashboard principal**.

---

## 2. Structure générale de l'interface

### Layout global

```
┌──────────────────────────────────────────────────┐
│  WAZUH (logo)          Menu      [Admin ▼]       │  <- Barre supérieure
├──────────────────────────────────────────────────┤
│ ☰ Sidebar                                        │
│ • Dashboard                                      │  <- Menu gauche
│ • Agents                                         │
│ • Logs                                           │
│ • etc.                                           │
├──────────────────────────────────────────────────┤
│                                                  │
│            CONTENU PRINCIPAL                    │
│            (varies selon la page)                │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Menu latéral (Sidebar)

Clique sur le **☰ (hamburger)** en haut à gauche pour ouvrir/fermer.

**Sections principales :**

1. **Dashboard** → Vue générale des alertes
2. **Agents** → État et gestion des agents
3. **Logs** → Recherche dans tous les logs
4. **Modules** → Fonctionnalités spécialisées
5. **Threat intelligence** → Analyses avancées
6. **Administration** → Paramètres et users

---

## 3. Dashboard Principal

### Vue d'ensemble

Le Dashboard affiche un résumé de la sécurité du réseau.

**Éléments clés :**

#### 1. Statistiques globales (haut)

```
Active Agents: 3 / 4      # Agents connectés / total
Alerts (last 24h): 247    # Alertes en 24h
High Priority: 8          # Alertes critiques
Threat Level: Medium      # Niveau de menace
```

#### 2. Timeline des alertes

Graphe montrant les alertes dans le temps (dernières 24h).

Peaks = attaques ou événements masifs.

#### 3. Top Alerts

Tableau des 10 alertes les plus fréquentes.

```
Alert Name                   Count    Severity
SSH Brute Force              45       High
Failed Login Attempts        123      Medium
Port Scan Detected           12       High
Unauthorized Access          3        Critical
```

#### 4. Agents Status

État des agents :
- ✅ Active (connecté, envoie des logs)
- ⚠️ Disconnected (pas de connexion)
- ⛔ Never connected

#### 5. Top Source IPs

Les IPs qui génèrent le plus d'événements.

---

## 4. Menu "Agents"

### Accès

Sidebar → **Agents**

### Liste des agents

Tableau affichant tous les agents enregistrés :

```
ID   Name            IP Address        Status      Last Keep Alive
000  manager         127.0.0.1         Connected   Just now
001  server-web      192.168.1.10      Connected   1 minute ago
002  vm3-monitoring  192.168.1.30      Disconnected 2 hours ago
```

### Détails d'un agent

Clique sur un agent (ex: **001**) pour voir des détails :

- **System info** : OS, version, CPU, RAM
- **Logs** : Tous les logs de cet agent
- **Alerts** : Alertes générées
- **Files** : Intégrité des fichiers surveillés

### Actions

Clic droit ou bouton "..." pour :
- **Restart** : Redémarrer l'agent
- **View alert summary** : Résumé des alertes
- **Manage agent** : Config avancée

---

## 5. Menu "Logs"

### Accès

Sidebar → **Logs**

### Recherche de logs

Interface de recherche complète.

**Barres de filtre :**

```
┌─────────────────────────────────────────────┐
│ Keyword search: [__________]                 │
│ Filter: Agent [select ▼] | Level [select ▼] │
│ Time range: [Last 24 hours ▼]              │
└─────────────────────────────────────────────┘
```

### Recherche par mot-clé

Exemple : Cherche tous les logs contenant "ssh"

```
Keyword search: ssh
[Search]
```

Résultat : Tous les logs SSH

### Filtres disponibles

#### Par Agent

```
Agent: server-web (ID: 001)
```

Affiche uniquement les logs de cet agent.

#### Par Niveau d'alerte

```
Level: 7 (Medium) → 15 (Critical)
```

Affiche les alertes au-dessus d'un certain niveau.

#### Par Plage horaire

```
Time Range: Last 24 hours
             Last 7 days
             Custom range
```

### Exemple de recherche

**Cherche tous les SSH échoués aujourd'hui :**

```
Keyword: Failed password
Agent: server-web
Time Range: Last 24 hours
[Search]
```

Résultat :
```
10 logs found
- Failed password for root from 192.168.1.5
- Failed password for admin from 192.168.1.5
- Failed password for invalid user...
```

---

## 6. Menu "Modules" (Fonctionnalités spécialisées)

### Accès

Sidebar → **Modules** → Sélectionner un module

### Modules courants

#### 1. **Security Events**

Tous les événements de sécurité centralisés.

**Onglets :**
- Overview : Résumé
- Events : Liste complète
- Compliance : Conformité

#### 2. **System Auditing**

Suivi des modifications système, droits d'accès, etc.

#### 3. **Threat Detection**

Détection avancée de menaces.

#### 4. **Integrity Monitoring**

Suivi des modifications de fichiers.

**Exemple :** Alerte si `/etc/passwd` est modifié.

#### 5. **Vulnerability Detection**

Détection de vulnérabilités connues.

---

## 7. Comprendre une alerte

### Exemple d'alerte affichée

Clique sur une alerte pour voir les détails :

```
Title: SSH Brute Force detected
Rule ID: 5503
Level: High (10/10)
Date: 2024-02-06 11:23:45 UTC
Agent: 001 (server-web)

Full Log:
Feb  6 11:23:45 server-web sshd[1234]: Failed password for root from 
  192.168.1.5 port 45678 ssh2

Decoder Output:
{
  "srcip": "192.168.1.5",
  "user": "root",
  "dstport": "22",
  "protocol": "ssh",
  "action": "failure"
}

Rule Details:
  Description: SSH brute force detected - 5+ failed attempts
  CIS: CIS-5.3.2 (Lock account after failed logins)
```

### Champs importants

| Champ | Signification |
|-------|---------------|
| **Rule ID** | Identifiant unique de la règle (5503) |
| **Level** | Sévérité (3=Info, 15=Critical) |
| **Decoder Output** | Champs extraits du log |
| **Source IP** | D'où vient l'attaque |
| **Timestamp** | Quand c'est arrivé |

---

## 8. Créer un Dashboard personnalisé

### Créer un nouveau Dashboard

1. Menu latéral → **Dashboard**
2. Bouton **"+" Create Dashboard**
3. Donne un nom : ex. "My Security Dashboard"
4. Clique "Create"

### Ajouter des widgets

Sur ton nouveau Dashboard :

1. Bouton **"Edit"**
2. Bouton **"+ Add Widget"**
3. Choisir un type :
   - **Visualization** : Graphes, stats
   - **Search** : Résultats de recherche
   - **Metric** : Compteurs

### Exemple : Widget "Alertes SSH"

1. Add Widget → Visualization
2. Nouvelle requête :
   ```
   rule.id: 5503 AND level > 5
   ```
3. Type : Bar chart
4. Titre : "SSH Brute Force Attempts"
5. Ajouter

---

## 9. Recherche avancée avec Wazuh Query Language (WQL)

### Syntaxe WQL

Wazuh utilise une syntaxe de requête puissante.

### Exemples de requêtes

#### Recherche 1 : Tous les SSH échoués

```
rule.id: 5503
```

Affiche toutes les alertes de cette règle.

#### Recherche 2 : SSH + IP source spécifique

```
rule.id: 5503 AND data.srcip: 192.168.1.5
```

Affiche les tentatives depuis cette IP.

#### Recherche 3 : Alertes critiques en 1h

```
level > 8 AND timestamp:[now-1h TO now]
```

Affiche les alertes niveau 9+ de la dernière heure.

#### Recherche 4 : Modifications de `/etc/passwd`

```
rule.group: "syscheck" AND full_log: "/etc/passwd"
```

#### Recherche 5 : Tentatives root

```
data.user: root AND action: failed
```

---

## 10. Alertes en temps réel

### Activer les notifications

1. Menu latéral → **Administration** → **Settings**
2. Section **Notifications**
3. Configurer :
   - Email
   - Slack
   - PagerDuty
   - etc.

### Webhook personnalisé

Envoyer des alertes à un script personnalisé :

```
Configuration JSON:
{
  "webhook_url": "http://192.168.1.60:8080/alert",
  "min_level": 7
}
```

---

## 11. Rapports automatiques

### Générer un rapport

1. Menu latéral → **Reporting**
2. Bouton **"+ New Report"**
3. Sélectionner :
   - Période (dernier jour, semaine, mois)
   - Type (PDF, HTML)
   - Agents à inclure
   - Modules à inclure

### Exemple : Rapport hebdomadaire

```
Report Name: Weekly Security Summary
Period: Last 7 days
Format: PDF
Include:
  ✓ Overview
  ✓ Top Alerts
  ✓ Agent Status
  ✓ Security Events
```

Génère automatiquement → Télécharger

---

## 12. Gestion de la base de données Elasticsearch (optionnel)

### Si Elasticsearch est activé

Sidebar → **Administration** → **Elasticsearch**

**Actions possibles :**
- Voir l'espace disque utilisé
- Archiver/supprimer les vieux logs
- Restaurer depuis une sauvegarde

**Commandes utiles :**

```bash
# Sur le Manager, voir l'état Elasticsearch
sudo curl -s http://localhost:9200/ | json_pp

# Voir les indices (tables)
sudo curl -s http://localhost:9200/_cat/indices | head
```

---

## 13. Administration - Gestion des utilisateurs

### Accès

Sidebar → **Administration** → **Users**

### Créer un nouvel utilisateur

1. Bouton **"+ New User"**
2. Remplir :
   - Username : ex. "soc_analyst"
   - Password : sécurisé
   - Role : SOC Analyst, Admin, etc.
3. Sauvegarder

### Rôles disponibles

| Rôle | Permissions |
|------|------------|
| Admin | Accès total |
| SOC Analyst | Lecture logs, alertes |
| Agent Manager | Gérer agents uniquement |
| Viewer | Lecture seule |

---

## 14. Dépannage : Interface ne répond pas

### Problème 1 : Connexion impossible

**Symptôme :**
```
ERR_CONNECTION_REFUSED
```

**Solution :**
```bash
# Sur Manager, vérifier le service Dashboard
sudo systemctl status wazuh-dashboard

# Redémarrer
sudo systemctl restart wazuh-dashboard

# Vérifier le port 443
sudo ss -tuln | grep 443
```

### Problème 2 : Pas de données affichées

**Symptôme :**
```
No data available
```

**Solutions :**
```bash
# Vérifier que les agents ont envoyé des logs
sudo tail /var/ossec/logs/alerts/alerts.json

# Attendre quelques minutes (Elasticsearch a besoin de temps)

# Vérifier la connexion Elasticsearch
sudo curl -s http://localhost:9200/_health
```

### Problème 3 : Slow performance

**Symptôme :**
```
Interface très lente
```

**Solution :**
```bash
# Réduire la plage horaire (évite de charger trop de données)
# Utiliser des filtres spécifiques
# Archiver les vieux logs

# Redémarrer les services
sudo systemctl restart wazuh-manager wazuh-dashboard
```

---

## 15. Workflow d'investigation d'une alerte

### Étape 1 : Voir l'alerte

Dashboard → Alerte SSH Brute Force

### Étape 2 : Détails de l'alerte

Clique sur l'alerte pour voir :
- Source IP
- Utilisateur cible
- Nombre de tentatives
- Timestamp

### Étape 3 : Chercher les logs associés

Menu Logs → Filtrer par :
- Source IP
- Agent
- Timeframe

### Étape 4 : Analyser les patterns

Y a-t-il d'autres attaques de la même IP ?

```
WQL: data.srcip: 192.168.1.5
```

### Étape 5 : Décider une action

- **Éducation** : Utilisateur a mal rentré son mot de passe
- **Enquête** : Attaque possible
- **Blocage** : Ajouter l'IP au firewall

---

## 📚 Résumé des menus

| Menu | Fonction |
|------|----------|
| Dashboard | Vue générale de la sécurité |
| Agents | État et logs des agents |
| Logs | Recherche dans tous les logs |
| Modules | Fonctionnalités spécialisées |
| Administration | Config, users, system |
| Reporting | Générer rapports |

---

## 💡 Mémo des éléments à surveiller

**Affichage critique :**
- Alertes Level > 8 (High/Critical)
- Agents Disconnected
- IPs en brute force
- Modifications système inattendues

**Recherches utiles à mémoriser :**
```
level > 8                    # Alertes critiques
rule.id: 5503                # SSH brute force
data.srcip: X.X.X.X          # Attaques d'une IP
timestamp:[now-1h TO now]    # Dernière heure
```

---

**Fin du chapitre 5 - Interface Wazuh**

Tu maîtrises maintenant le Dashboard Wazuh. Prochaine étape : **créer des règles personnalisées** pour détecter les spécificités de ton infrastructure.

---

## 🎯 Prochaines étapes recommandées

1. **Créer des règles Wazuh** (voir projet-rules.md)
2. **Configurer des réponses aux incidents** (playbooks)
3. **Intégrer Elasticsearch** pour plus de performance
4. **Configurer les alertes par email/Slack**
5. **Automatiser les dashboards par agent**
