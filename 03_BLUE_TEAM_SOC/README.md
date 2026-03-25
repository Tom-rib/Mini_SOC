# 🔵 Wazuh - Blue Team / SOC (Section 3)

**Rôle :** SOC Analyst & Détection d'intrusions

**Objectif global :** Mettre en place un système de détection des menaces et d'analyse centralisée des logs

**Durée totale :** ~7 heures

---

## 📚 Structure de cette section

Cette section couvre l'installation et la configuration de **Wazuh**, le cœur du SOC.

### Fichiers du cours

| # | Fichier | Durée | Contenu |
|---|---------|-------|---------|
| 1 | **04_wazuh_architecture.md** | 30 min | Concepts, architecture, flux de données |
| 2 | **05_wazuh_manager_install.md** | 2h | Installation du serveur Wazuh sur VM2 |
| 3 | **06_wazuh_agents_install.md** | 1h par agent | Installation des agents sur autres VMs |
| 4 | **07_wazuh_integration.md** | 1h | Configuration des sources de logs |
| 5 | **08_wazuh_interface.md** | 1-2h | Navigation et utilisation du Dashboard |

**Total recommandé :** Environ 7 heures (étaler sur 2-3 jours)

---

## 🚀 Par où commencer ?

### Jour 1 : Concepts et Manager

**Matin :**
1. Lire **04_wazuh_architecture.md** (30 min)
   - Comprendre agent/manager
   - Lire les schémas
   - Retenir les ports (1514, 443)

2. Suivre **05_wazuh_manager_install.md** (2h)
   - Installer Wazuh Manager sur VM2
   - Tester l'accès au Dashboard
   - Faire la checklist finale

**Pause déjeuner**

**Après-midi :**
3. Commencer **06_wazuh_agents_install.md**
   - Enregistrer le premier agent (VM1)
   - Installer le package agent
   - Vérifier la connexion

### Jour 2 : Agents et Logs

**Matin :**
1. Finir **06_wazuh_agents_install.md**
   - Installer agents sur VM3 et autres VMs
   - Vérifier que tous les agents sont "Active"

2. Suivre **07_wazuh_integration.md** (1h)
   - Ajouter les sources de logs (SSH, Web, Audit, Sys)
   - Redémarrer les agents
   - Vérifier que les logs arrivent

**Après-midi :**
3. Suivre **08_wazuh_interface.md** (1-2h)
   - Explorer le Dashboard
   - Tester les recherches
   - Créer un dashboard perso

---

## ✅ Checklist d'installation complète

Avant de dire "c'est fini", confirme chaque point :

### Wazuh Manager (VM2)

- ✅ Service wazuh-manager en "running"
- ✅ Service wazuh-dashboard en "running"
- ✅ Accès Dashboard sans erreur SSL
- ✅ Ports 1514 (TCP/UDP) et 443 (HTTPS) ouverts
- ✅ `/var/ossec/logs/ossec.log` sans erreurs graves

### Agents (VM1, VM3, ...)

Par agent :
- ✅ Package wazuh-agent installé
- ✅ Service wazuh-agent en "running"
- ✅ Apparaît "Active" dans `manage_agents`
- ✅ Fichier `/var/ossec/etc/ossec.conf` configuré
- ✅ Can connect to Manager (127.0.0.1:1514 depuis Manager)

### Sources de logs

Par agent :
- ✅ Blocs `<localfile>` ajoutés à ossec.conf
- ✅ Fichiers logs accessibles par l'utilisateur wazuh
- ✅ Configuration validée (`verify-agent-conf`)
- ✅ Logs arrivent sur le Manager (visible dans Dashboard)

### Dashboard

- ✅ Login possible (admin)
- ✅ Tous les agents visibles → "Connected"
- ✅ Logs visibles dans le menu "Logs"
- ✅ Au moins 1 alerte visible

---

## 🎯 Objectifs pédagogiques

À la fin de cette section, tu dois comprendre/savoir :

### Conceptuels
- ✅ Différence entre un **agent** (client) et un **manager** (serveur)
- ✅ Flux : Logs locaux → Agent → Manager → Analyse → Alerte
- ✅ Concept de **règles** (conditions pour déclencher une alerte)
- ✅ Concept de **décodeurs** (parseurs pour extraire champs)
- ✅ Niveaux d'alerte (0-15) et leur signification

### Pratiques
- ✅ Installer un manager Wazuh
- ✅ Enregistrer et installer un agent
- ✅ Configurer des sources de logs dans ossec.conf
- ✅ Naviguer dans le Dashboard
- ✅ Chercher des logs avec des filtres
- ✅ Interpréter une alerte
- ✅ Dépanner des problèmes courants (agent déconnecté, logs manquants)

---

## 🔧 Architecture déployée après cette section

```
                    Internet / Attaquant
                            |
                    (simulation d'attaques)
                            |
                    ┌──────────────────┐
                    │  Firewall Rocky  │
                    │   (ouvert à test)│
                    └────────┬─────────┘
                             |
        ┌────────────────────┼────────────────────┐
        |                    |                    |
        v                    v                    v
   ┌─────────────┐      ┌─────────────┐     ┌──────────────┐
   │ VM1: Web    │      │ VM2: SOC    │     │ VM3:Monitor  │
   │ ----------- │      │ ----------- │     │ ------------ │
   │ OS: Rocky   │      │ OS: Rocky   │     │ OS: Rocky    │
   │ Services:   │      │ Services:   │     │ Services:    │
   │ • SSH       │      │ • Wazuh Mgr │     │ • SSH        │
   │ • Nginx     │      │ • Dashboard │     │ • Zabbix     │
   │ • Auditd    │      │ • Elastic*  │     │ • Grafana    │
   │ • Firewall  │      │ • Firewall  │     │ • Firewall   │
   │             │      │             │     │              │
   │ Agent 001 ◄─┼──┐   │ Manager     │     │ Agent 002 ◄──┼───┐
   │ (logs)      │  │   │ (reçoit,    │     │ (logs)       │   │
   │             │  │   │  analyse)   │     │              │   │
   └─────────────┘  │   │             │     └──────────────┘   │
                    │   │             │                         │
                    └──→ Port 1514 ◄──┴─────────────────────────┘
                        (TCP/UDP)
                        
                    ┌──────────────────┐
                    │  VOUS (SOC)      │
                    │  ----------      │
                    │  Navigateur Web  │
                    │  Port 443 HTTPS  │
                    └────────┬─────────┘
                             |
                    ┌────────▼─────────┐
                    │ Dashboard Wazuh  │
                    │ (Visualisation)  │
                    └──────────────────┘
```

**Flux :**
1. Services génèrent des logs
2. Agents Wazuh envoient les logs au Manager (port 1514)
3. Manager analyse les logs avec des règles
4. Dashboard affiche les alertes
5. SOC Analyst consulte via HTTPS (port 443)

---

## 📖 Prochaines sections du projet

Après Wazuh, tu apprendras :

### Section 4 : Hardening & Sécurité système
- Sécuriser Rocky Linux
- Firewall avancé
- SELinux, Fail2ban, Lynis
- Audit système

### Section 5 : Règles Wazuh avancées
- Créer des règles personnalisées
- Décodeurs custom
- Corrélation d'événements
- Automatisation des réponses (playbooks)

### Section 6 : Monitoring & Incident Response
- Zabbix / Prometheus + Grafana
- Dashboards de supervision
- Procédures IR (Incident Response)
- Post-mortems

---

## 💡 Conseils pour réussir

### 1. Prendre son temps
Ne pas se presser. L'installation peut avoir des petits pépins. Prendre du temps pour vérifier à chaque étape.

### 2. Documenter ses actions
Noter :
- L'IP du Manager (ex: 192.168.1.50)
- L'IP de chaque agent (ex: 192.168.1.10, 192.168.1.30)
- Les mots de passe générés

### 3. Savoir lire les logs
Les erreurs les plus utiles se trouvent dans :
```bash
sudo tail -f /var/ossec/logs/ossec.log
sudo journalctl -u wazuh-manager -f
```

### 4. Utiliser `manage_agents` comme référence
```bash
sudo /var/ossec/bin/manage_agents
```

C'est ton outil de debug central pour les agents.

### 5. Tester incremental
Ne pas installer tous les agents d'un coup. Faire :
1. Manager seul
2. Manager + Agent 1
3. Manager + Agent 1 + Agent 2
etc.

---

## 🐛 Erreurs courantes et solutions rapides

| Erreur | Cause | Solution |
|--------|-------|----------|
| Agent "Disconnected" | Config IP Manager fausse | Vérifier `/var/ossec/etc/ossec.conf` |
| "Permission denied" logs | User wazuh n'a pas accès | `chmod g+r /var/log/secure` |
| Dashboard blank | Elasticsearch down | Redémarrer services |
| "Client key already in use" | Clé dupliquée | Réenregistrer l'agent |
| Port 1514 not open | Firewall bloque | Ouvrir port via firewall-cmd |

---

## 📚 Ressources supplémentaires

### Docs officielles Wazuh
- https://documentation.wazuh.com/
- https://github.com/wazuh/wazuh

### Commandes utiles à mémoriser

```bash
# Manager
sudo /var/ossec/bin/wazuh-control status          # État services
sudo /var/ossec/bin/manage_agents                  # Gérer agents
sudo tail -f /var/ossec/logs/ossec.log            # Logs temps réel

# Agent
sudo systemctl status wazuh-agent                  # État agent
sudo /var/ossec/bin/verify-agent-conf             # Valider config
sudo tail -f /var/ossec/logs/ossec.log            # Logs agent

# Réseau
sudo ss -tuln | grep 1514                         # Vérifier ports
telnet IP_MANAGER 1514                            # Tester connectivité
sudo curl http://localhost:9200/                  # Tester Elasticsearch
```

---

## 🎓 Livrables attendus pour ce projet

À la fin de la section Wazuh, tu dois avoir :

1. ✅ **Manager opérationnel** sur VM2
   - Dashboard accessible
   - Chiffres à recopier : URL, login

2. ✅ **Tous les agents connectés**
   - Liste : Agent 001 = server-web, Agent 002 = vm3-monitoring, etc.
   - Status : "Active" pour chacun

3. ✅ **Sources de logs configurées**
   - Tableau : Quel log sur quelle VM
   - Exemple : VM1 envoie SSH + Nginx + Audit

4. ✅ **Premières alertes visibles**
   - Screenshot du Dashboard
   - Exemple : SSH Brute Force detected
   - Nombre d'alertes par type

5. ✅ **Documentation personnelle**
   - Où tu recopes ce cours dans tes mots
   - Diagramme de ton architecture spécifique
   - Troubleshooting que tu as rencontré

---

## 🚀 Chronométrage réaliste

- **Lecture cours :** 1h
- **Installation Manager :** 1-1.5h
- **Installation agents (2 agents) :** 1h
- **Configuration logs :** 0.5h
- **Tests et troubleshooting :** 1-2h
- **Exploration Dashboard :** 1h

**Total :** 6-7h (peut varié selon les problèmes)

---

**Fin de l'index - Wazuh**

👉 **Prêt à commencer ? Ouvre `04_wazuh_architecture.md`**

---

## Questions fréquentes

**Q: Dois-je installer Elasticsearch ?**
A: Non pour ce projet intro. Facultatif pour production.

**Q: Combien d'agents max ?**
A: Manager All-in-One supporte ~10,000 agents théoriquement. Pour ce projet 3-5 = parfait.

**Q: Puis-je utiliser Ubuntu au lieu de Rocky ?**
A: Oui, la majorité du code fonctionne. Remplace `dnf` par `apt` (Debian/Ubuntu).

**Q: Comment obtenir des alertes réelles ?**
A: Il faut simuler des attaques. Voir **Section 6** pour cela.

**Q: Mon Dashboard est vide, pourquoi ?**
A: 1) Vérifie que des logs arrivent. 2) Attends 5min. 3) Redémarre Elasticsearch.
