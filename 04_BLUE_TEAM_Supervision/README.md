# 04 - BLUE TEAM : Supervision & Monitoring

**Objectif global** : Mettre en place une supervision complète de l'infrastructure pour détecter les anomalies et incidents  
**Rôle responsable** : Administrateur supervision (Rôle 3)  
**Durée totale estimée** : 5-6 heures  

---

## 📋 Contexte du rôle Supervision

Vous êtes en charge de **l'availability** et **l'incident response** de l'infrastructure SOC.

**Responsabilités**
- Surveiller l'infrastructure 24/7
- Détecter les anomalies (pics ressources, services down)
- Réagir rapidement aux incidents
- Maintenir dashboards à jour
- Documenter les incident response playbooks

**Défis**
- Avoir une visibilité complète en temps réel
- Éviter les faux positifs (alertes inutiles)
- Réagir vite en cas de problème
- Centraliser les informations

---

## 🗂️ Structure des fichiers

```
04_BLUE_TEAM_SUPERVISION/
├── README.md                          ← Vous êtes ici
├── 01_choix_outil.md                  ← Zabbix vs Prometheus ?
├── 02_install_monitoring.md           ← Installation pratique
├── 03_metriques_surveillance.md       ← PromQL & requêtes
├── 04_dashboards.md                   ← Grafana setup
└── scripts/
    ├── install_prometheus.sh          ← Automatiser installation
    ├── node_exporter_install.sh       ← Node Exporter sur VM
    ├── prometheus.yml                 ← Config Prometheus
    └── grafana_dashboards.json        ← Dashboards pré-configurés
```

---

## 📚 Progression recommended

### Semaine 1

**Jour 1 : Décision & Installation** (1.5h)
```
1. Lire 01_choix_outil.md (30 min)
   → Comprendre Zabbix vs Prometheus
   → Choisir approche
   
2. Lancer 02_install_monitoring.md Phase 1-2 (1h)
   → Installation Prometheus sur VM3
```

**Jour 2 : Prometheus complet** (1.5h)
```
1. Continuer 02_install_monitoring.md Phase 3-5 (1.5h)
   → Installation Grafana
   → Installation Node Exporter (VM1, VM2)
   → Tests d'intégration
```

**Jour 3 : Apprentissage PromQL** (1.5h)
```
1. Lire 03_metriques_surveillance.md (1.5h)
   → Apprendre requêtes PromQL
   → Pratiquer 10 requêtes clés
   → Tester dans interface Prometheus
```

**Jour 4 : Dashboards** (2h)
```
1. Suivre 04_dashboards.md (2h)
   → Créer dashboard SOC Overview
   → Créer dashboard VM1 Deep Dive
   → Configurer alertes
   → Exporter dashboards en JSON
```

### Semaine 2

**Jour 1 : Playbooks incident response**
```
Créer procédures écrites pour :
- High CPU → Actions
- Out of memory → Actions
- Disk full → Actions
- Service down → Actions
```

**Jour 2 : Scripts d'auto-réaction** (optionnel)
```
Scripts bash :
- Auto-restart services
- Block suspicious IPs
- Email alertes
```

**Jour 3 : Intégration Wazuh**
```
Connecter Wazuh → Prometheus → Grafana
Alertes SOC → Grafana
Incidents détectés → Dashboard
```

**Jour 4 : Documentation & tests**
```
- Documenter architecture
- Tester en conditions réelles
- Évaluer performance
```

---

## 🎯 Objectifs d'apprentissage

À la fin de cette section, vous maîtriserez :

```
✅ Monitoring
   - Comprendre différents outils (Zabbix, Prometheus, Grafana)
   - Installer et configurer monitoring production-grade
   - Interpréter métriques systèmes
   
✅ PromQL
   - Écrire requêtes avancées
   - Créer alertes personnalisées
   - Analyser tendances
   
✅ Grafana
   - Créer dashboards professionnels
   - Visualiser données complexes
   - Configurer alertes
   
✅ Incident Response
   - Détecter anomalies
   - Escalader incidents
   - Rédiger playbooks IR
   
✅ Architecture SOC
   - Intégrer monitoring + SOC
   - Centraliser alertes
   - Coordonner équipes
```

---

## 📊 Architecture globale mise en place

```
┌──────────────────────────────────────────────────────┐
│                    Internet                           │
└────────────────┬─────────────────────────────────────┘
                 │
         ┌───────┴────────┐
         │                │
    ┌────▼─────┐    ┌────▼─────┐
    │  VM1     │    │  VM2     │
    │  (Web)   │    │  (SOC)   │
    │          │    │          │
    │ Port2222 │    │ Port22   │
    │ Nginx    │    │ Wazuh    │
    │          │    │ ELK      │
    └────┬─────┘    └────┬─────┘
         │                │
    ┌────▼──────┬────────▼───────┐
    │            │                │
    │     Node Exporter (9100) × 2
    │            │                │
    │       ┌────▼─────────────┐  │
    │       │   PROMETHEUS     │◄─┘
    │       │   (VM3: 9090)    │
    │       └────┬─────────────┘
    │            │
    │       ┌────▼─────────────┐
    │       │    GRAFANA       │
    │       │   (VM3: 3000)    │
    │       ├──────────────────┤
    │       │ Dashboard SOC    │
    │       │ Dashboard VM1    │
    │       │ Dashboard Alerts │
    │       └────────┬─────────┘
    │                │
    │        ┌───────▼────────┐
    │        │ Admin Panel    │
    │        │ (you, viewing) │
    │        └────────────────┘
    │
    └──→ TimeSeries DB
         /var/lib/prometheus
         (stockage 15+ jours)
```

---

## 🔧 Configuration résumée

### Accès des services

| Service | URL | Rôle |
|---------|-----|------|
| **Prometheus** | http://<IP_VM3>:9090 | Collecte + stockage |
| **Grafana** | http://<IP_VM3>:3000 | Visualisation |
| **Node Exporter VM1** | http://<IP_VM1>:9100/metrics | Source métriques |
| **Node Exporter VM2** | http://<IP_VM2>:9100/metrics | Source métriques |

### Ports ouverts (firewall)

Sur **VM3** :
```bash
sudo firewall-cmd --permanent --add-port=9090/tcp  # Prometheus
sudo firewall-cmd --permanent --add-port=3000/tcp  # Grafana
sudo firewall-cmd --reload
```

Sur **VM1 & VM2** :
```bash
sudo firewall-cmd --permanent --add-port=9100/tcp  # Node Exporter
sudo firewall-cmd --reload
```

---

## 🚀 Commandes essentielles (cheatsheet)

```bash
# ============ PROMETHEUS ============
# Démarrer
sudo systemctl start prometheus

# Statut
sudo systemctl status prometheus

# Logs temps réel
sudo journalctl -u prometheus -f

# Vérifier config
prometheus --config.file=/etc/prometheus/prometheus.yml --dry-run

# Redémarrer après modif config
sudo systemctl reload prometheus

# ============ GRAFANA ============
# Démarrer
sudo systemctl start grafana-server

# Statut
sudo systemctl status grafana-server

# Logs
sudo journalctl -u grafana-server -f

# ============ NODE EXPORTER ============
# Démarrer
sudo systemctl start node_exporter

# Test métrique
curl http://localhost:9100/metrics | head -20

# ============ TESTS ============
# Tester Prometheus
curl http://localhost:9090

# Tester Grafana
curl http://localhost:3000

# Requête PromQL simple
curl 'http://localhost:9090/api/v1/query?query=up'
```

---

## ❓ FAQ - Questions fréquentes

### Q1 : Prometheus vs Zabbix, lequel choisir ?

**Réponse** : Ce projet utilise **Prometheus** car :
- Léger (important en labo)
- Modulaire (facile à étendre)
- Moderne (industrie standard)
- Grafana est excellente

Zabbix serait plus simple mais plus lourd.

---

### Q2 : Où sont stockées les données Prometheus ?

**Réponse** : 
```
/var/lib/prometheus/

Stockage par défaut : 15 jours
Données compressées et optimisées pour TimeSeries
```

---

### Q3 : Comment ajouter une nouvelle VM à monitorer ?

**Réponse** :
```
1. Installer Node Exporter sur la VM
   sudo systemctl start node_exporter
   
2. Ajouter à /etc/prometheus/prometheus.yml :
   - job_name: 'my-vm'
     static_configs:
       - targets: ['<IP>:9100']
       
3. Redémarrer Prometheus
   sudo systemctl reload prometheus
```

---

### Q4 : Comment alerter sur anomalies ?

**Réponse** :
```
Option 1 : Grafana alerts
  Panel → Alert → Condition → Notification channel
  
Option 2 : Prometheus + AlertManager (avancé)
  Créer alert rules dans prometheus.yml
  Lancer AlertManager
  Configurer routes notification
```

---

### Q5 : J'ai oublié le mot de passe Grafana admin

**Réponse** :
```bash
# Réinitialiser dans base de données
sudo grafana-cli admin reset-admin-password <new_password>
```

---

## ✅ Checklist de validation

Avant de considérer cette phase complète :

```
INSTALLATION
[ ] Prometheus démarre sans erreur
[ ] Grafana démarre sans erreur
[ ] Node Exporter actif sur VM1 et VM2
[ ] Prometheus scrape avec succès les 3 targets

DASHBOARDS
[ ] Dashboard SOC Overview existe
[ ] 6 panels affichent des données
[ ] Dashboard VM1 Deep Dive existe
[ ] Dashboard Alerts & Anomalies existe

PromQL
[ ] Requête CPU fonctionne
[ ] Requête RAM fonctionne
[ ] Requête Disque fonctionne
[ ] Requête Load fonctionne
[ ] Requête Réseau fonctionne

ALERTES
[ ] Au moins 3 alertes configurées
[ ] Au moins 1 notification channel (email/webhook)
[ ] Test d'alerte fonctionne

DOCUMENTATION
[ ] Architecture documentée
[ ] Commandes essentielles notées
[ ] Playbooks incidents écrits
```

---

## 📖 Ressources supplémentaires

### Documentation officielle
- **Prometheus** : https://prometheus.io/docs/
- **Grafana** : https://grafana.com/docs/grafana/
- **Node Exporter** : https://github.com/prometheus/node_exporter
- **PromQL** : https://prometheus.io/docs/prometheus/latest/querying/

### Tutoriels
- **Prometheus basics** : https://prometheus.io/docs/prometheus/latest/getting_started/
- **Grafana dashboards** : https://grafana.com/docs/grafana/latest/features/dashboards/
- **PromQL tutorial** : https://prometheus.io/docs/prometheus/latest/querying/basics/

### Communauté
- **Prometheus forum** : https://discuss.prometheus.io/
- **Grafana community** : https://community.grafana.com/
- **Reddit** : r/prometheus, r/grafana

---

## 🔗 Liens entre fichiers

```
01_choix_outil.md
    ↓ (après avoir compris)
02_install_monitoring.md
    ↓ (après installation réussie)
03_metriques_surveillance.md
    ↓ (après avoir appris PromQL)
04_dashboards.md
    ↓ (dashboards opérationnels)
Playbooks Incident Response (dans section suivante)
```

---

## 🎓 Compétences validées à la fin

```
✅ Linux System Administration
   - Installation services système
   - Gestion firewall
   - Gestion systemd services
   - Configuration TCP/IP
   
✅ Monitoring & Observability
   - Prometheus architecture
   - Collecte de métriques
   - TimeSeries databases
   
✅ PromQL
   - Requêtes basiques et avancées
   - Alertes sur seuils
   - Tendance analysis
   
✅ Data Visualization
   - Grafana dashboards
   - Panels et visualisations
   - Alerting
   
✅ Incident Response
   - Détection d'anomalies
   - Escalade d'incidents
   - Procédures documentées
```

---

## ⏱️ Temps total

| Phase | Durée |
|-------|-------|
| Choix outil | 30 min |
| Installation (Prometheus + Grafana + Node Exporter) | 2h |
| Apprentissage PromQL | 1h 30 min |
| Création dashboards | 2h |
| Alertes & customization | 30 min |
| **TOTAL** | **~6.5 heures** |

---

## 🎯 Prochaines étapes après cette section

1. **Incident Response Playbooks** (Rôle 3)
   - Documenter procédures
   - Tester en conditions réelles
   
2. **Intégration Wazuh** (Rôle 2 + 3)
   - Envoyer alertes Wazuh vers Grafana
   - Corréler logs + métriques
   
3. **Tests de charge** (Tous rôles)
   - Déclencher attaques simulées
   - Valider détection
   - Valider réaction

---

**Bonne chance ! 🚀**

Pour questions ou blocages, consulter les fichiers correspondants ou documentation officielle.

À bientôt en Incident Response !
