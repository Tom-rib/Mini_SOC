# Wazuh - Architecture et concepts

**Objectif du chapitre :** Comprendre comment Wazuh fonctionne et se structure dans notre infrastructure SOC.

**Durée estimée :** 30 minutes (lecture + schémas)

---

## 1. Qu'est-ce que Wazuh ?

Wazuh est une plateforme open-source de **détection des menaces** et de **réponse aux incidents**.

Elle remplit deux rôles essentiels dans une équipe SOC :

1. **IDS (Intrusion Detection System)** → détecte les attaques
2. **SIEM (Security Information & Event Management)** → centralise et analyse les logs

Contrairement aux firewall classiques (qui bloquent), Wazuh **observe et alerte**.

---

## 2. Architecture générale de Wazuh

Notre infrastructure Wazuh comprend deux composants principaux :

### 📍 Composant 1 : Wazuh Manager (serveur central)

**Emplacement :** VM 2 (SOC / Logs / SIEM)

**Rôle :**
- Reçoit les logs de tous les agents
- Analyse les événements selon des règles
- Génère des alertes
- Stocke les données
- Expose une interface Web (Wazuh Dashboard)

**Ressources nécessaires :**
- 4 GB RAM minimum
- 30 GB disque (plus selon la rétention)
- Port 1514/UDP (réception agents)
- Port 443/HTTPS (interface Web)

### 📍 Composant 2 : Wazuh Agents

**Emplacement :** VM 1 (Serveur Web) + autres VM

**Rôle :**
- Collecte les logs locaux
- Envoie les logs au Manager
- Exécute des actions de réponse
- Vérifie l'intégrité des fichiers

**Ressources légères :**
- ~50 MB RAM
- ~200 MB disque
- Connexion réseau vers le Manager (port 1514)

---

## 3. Flux de communication

```
┌─────────────────────────────────────────────────────┐
│         AGENTS (VM1, VM3, etc.)                     │
│  Collectent logs locaux                             │
│  - /var/log/secure (SSH)                            │
│  - /var/log/nginx/access.log (Web)                  │
│  - /var/log/audit/audit.log (Auditd)               │
│  - /var/log/messages (Système)                      │
└──────────────┬──────────────────────────────────────┘
               │
               │ Connexion TCP/UDP port 1514
               │ (chiffrage optionnel)
               │
               ▼
┌─────────────────────────────────────────────────────┐
│      WAZUH MANAGER (VM2)                            │
│  Décodage des logs                                  │
│  Analyse par règles personnalisées                  │
│  Génération d'alertes                               │
│  Stockage Elasticsearch (optionnel)                 │
└──────────────┬──────────────────────────────────────┘
               │
               │ Port 443 HTTPS
               │
               ▼
┌─────────────────────────────────────────────────────┐
│      WAZUH DASHBOARD (Interface Web)                │
│  https://IP_Manager:443/app/wazuh                   │
│  Visualisation des alertes                          │
│  Dashboards de sécurité                             │
│  Gestion des agents                                 │
└─────────────────────────────────────────────────────┘
```

---

## 4. Ports et protocoles

| Port | Protocole | Direction | Rôle |
|------|-----------|-----------|------|
| 1514 | TCP/UDP | Agent → Manager | Envoi des logs |
| 1515 | TCP | Agent → Manager | Enregistrement agent (optionnel) |
| 443 | HTTPS | Utilisateur → Manager | Accès à l'interface Web |
| 514 | Syslog (optionnel) | Sources ext. → Manager | Réception logs externes |

**Important :** Les ports doivent être ouverts dans le firewall entre les machines.

---

## 5. Modes de déploiement

Notre projet utilise le mode **All-in-One** (simplifié) :

```
┌──────────────────────────┐
│   Wazuh Manager (VM2)    │
│  - Wazuh server          │
│  - Elasticsearch*        │
│  - Wazuh Dashboard       │
└──────────────────────────┘
         ▲
         │
    ┌────┴─────────┬─────────────┐
    ▼              ▼              ▼
  ┌────┐        ┌────┐        ┌────┐
  │VM1 │        │VM3 │        │VM? │
  │Agent         │Agent        │Agent
  └────┘        └────┘        └────┘
```

*Elasticsearch est une base de données pour stocker les logs (optionnel pour ce projet).

---

## 6. Cycle de vie d'une alerte

### Étape 1 : Collecte
L'agent lit un fichier log sur VM1 (ex: /var/log/secure)

**Exemple :** Une tentative SSH échouée
```
Failed password for invalid user admin from 192.168.1.5 port 45678 ssh2
```

### Étape 2 : Envoi
L'agent envoie cette ligne au Manager (port 1514)

### Étape 3 : Décodage
Le Manager parsing le log selon des **décodeurs** (format-specific)
```
Champ 'srcip' = 192.168.1.5
Champ 'dstport' = 22
Champ 'status' = Failed
```

### Étape 4 : Analyse
Le Manager compare avec les **règles** :

**Exemple de règle :**
```
Si 5 tentatives Failed en 1 minute
  → Trigger alerte "SSH Brute Force"
```

### Étape 5 : Alerte
L'alerte s'affiche sur le Dashboard

```
🚨 Alert - SSH Brute Force detected
   Source IP: 192.168.1.5
   Tentatives: 5
   Severity: High (7/10)
   Timestamp: 2024-02-06 14:23:45
```

### Étape 6 : Réaction (optionnel)
Un script répond automatiquement :
- Blocage IP au firewall
- Désactivation du compte
- Notification administrateur

---

## 7. Types de règles Wazuh

### Règle 1 : Détection basée sur le contenu

Cherche un pattern dans le log :

```xml
<rule id="5501" level="5">
    <if_sid>5500</if_sid>
    <match>Failed password|failed password</match>
    <description>SSH Failed password attempt</description>
</rule>
```

### Règle 2 : Détection d'anomalies (fréquence)

Compte les occurrences en peu de temps :

```xml
<rule id="5502" level="10">
    <if_sid>5501</if_sid>
    <frequency>5</frequency>
    <timeframe>60</timeframe>
    <same_source_ip/>
    <description>SSH Brute Force - 5 failures in 60s</description>
</rule>
```

### Règle 3 : Corrélation d'événements

Combine plusieurs logs :

```xml
<rule id="5503" level="12">
    <if_sid>5502</if_sid>
    <match>root</match>
    <description>SSH Brute Force on root account</description>
</rule>
```

---

## 8. Niveaux d'alerte

Chaque alerte a un **niveau de sévérité** (0-15) :

| Niveau | Sévérité | Exemple |
|--------|----------|---------|
| 0-3 | Info | Connexion réussie SSH |
| 4-6 | Low | Accès à un service |
| 7-8 | Medium | Tentative échouée |
| 9-11 | High | Brute force, scan port |
| 12-15 | Critical | Compromission suspectée |

**Utilité :** Hiérarchiser ce qui est urgent.

---

## 9. Stockage et rétention

### Sans Elasticsearch (simple)
- Les alertes sont en fichiers JSON
- Localisation : `/var/ossec/logs/alerts/`
- Rétention : à gérer manuellement

### Avec Elasticsearch (recommandé pour production)
- Base de données
- Rétention automatique
- Requêtes avancées
- Dashboards interactifs

**Pour ce projet :** Nous utilisons la version simple sans Elasticsearch d'abord.

---

## 10. Vérifications après cette étape

✅ Comprendre la différence agent/manager  
✅ Savoir où se connecter les agents (port 1514)  
✅ Connaître les ports de l'interface Web (443)  
✅ Comprendre le cycle de vie d'une alerte  

---

## 📚 Prochaines étapes

1. **04_wazuh_manager_install.md** → Installer le Manager sur VM2
2. **05_wazuh_agents_install.md** → Installer agents sur VM1
3. **06_wazuh_integration.md** → Configurer les sources de logs
4. **07_wazuh_interface.md** → Utiliser le Dashboard

---

## 💡 Mémo rapide

| Concept | Définition |
|---------|-----------|
| **Agent** | Client léger qui envoie les logs |
| **Manager** | Serveur qui reçoit, analyse et alerte |
| **Règle** | Condition qui déclenche une alerte |
| **Décodeur** | Parser qui extrait les champs du log |
| **Alerte** | Notification d'un événement détecté |
| **Dashboard** | Interface Web de visualisation |

---

**Fin du chapitre 1 - Architecture**

Prêt pour l'installation ? Continue avec le fichier suivant.
