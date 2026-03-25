# 01 - Choix de l'outil de supervision

**Objectif** : Choisir l'outil de monitoring adapté au projet  
**Durée estimée** : 30 min  
**Rôle** : Administrateur supervision (Rôle 3)

---

## 1. Contexte : pourquoi monitorer ?

Un SOC sans supervision est aveugle. Il faut savoir :
- Si les serveurs sont surcharges
- Si un service tombe
- Si le réseau ralentit
- Si les disques se remplissent

La supervision détecte les **anomalies** avant qu'elles deviennent des incidents graves.

---

## 2. Deux approches principales

### Approche 1 : Zabbix (tout-en-un)

**Philosophie** : Un seul outil pour tout faire.

**Architecture**
```
┌─────────────────────┐
│   Zabbix Server     │  ← Collecte + Alertes + Dashboard
│   (VM3)             │
├─────────────────────┤
│  Zabbix Agent       │  ← Sur chaque VM à monitorer
│  (VM1, VM2)         │
└─────────────────────┘
```

**Avantages**
- Installation unique, intégrée
- Configuration centralisée
- Alertes natives avec escalade
- Support natif pour +200 éléments (services, logs, SNMP, etc.)
- Interface web intuitive
- Parfait pour petit/moyen infrastructure

**Inconvénients**
- Lourd (PostgreSQL/MySQL obligatoire)
- Consommation RAM importante (~500 MB)
- Courbe d'apprentissage moyenne
- Moins modulaire
- Agent Zabbix propriétaire

**Installation** : ~1h  
**Ressources** : RAM 4GB min, CPU 2 cores min

---

### Approche 2 : Prometheus + Grafana (moderne & modulaire)

**Philosophie** : Séparer la collecte (Prometheus) de la visualisation (Grafana).

**Architecture**
```
┌──────────────────────────────────────────────┐
│                 VM3                          │
├──────────────────┬──────────────────────────┤
│  Prometheus      │  Grafana                 │
│  (collecte/stock)│  (dashboards)            │
├──────────────────┴──────────────────────────┤
     ↑                    ↑
┌────┴────┐          ┌────┴────┐
│ Node Ex.│          │ Alertes │
│ (VM1,2) │          │(AlertMgr)│
└─────────┘          └─────────┘
```

**Avantages**
- Léger et rapide (Prometheus en Go)
- Très modulaire (chaque composant indépendant)
- Ecosystem riche (Node Exporter, cAdvisor, etc.)
- Langage de requête puissant (PromQL)
- Dashboards Grafana très personnalisables
- Tendance industrie (Kubernetes, DevOps)
- Consommation ressources basse

**Inconvénients**
- Deux outils à configurer
- Courbe apprentissage PromQL
- Moins de features "natives" (doit assembler les pièces)
- Alertes moins intégrées

**Installation** : ~1.5h  
**Ressources** : RAM 2GB min, CPU 1 core

---

## 3. Tableau comparatif complet

| Critère | Zabbix | Prometheus + Grafana |
|---------|--------|----------------------|
| **Facilité d'installation** | Moyen | Facile |
| **Ressources consommées** | Élevé (~500MB RAM) | Bas (~150MB) |
| **Courbe apprentissage** | Moyen | Moyen-Élevé |
| **Alertes natives** | ✅ Excellentes | ⚠️ Nécessite AlertManager |
| **Dashboards** | ✅ Corrects | ✅✅ Excellents |
| **Modularité** | ❌ Monolithique | ✅ Très modulaire |
| **Scalabilité** | Moyen | Excellente |
| **Écosystème plugins** | Bon | Excellent |
| **Temps de mise en place** | 3-4h | 2-3h |
| **Support enterprise** | ✅ Commercial | ✅ Communauté forte |

---

## 4. Recommandation pour ce projet : Prometheus + Grafana

**Choix** : **Prometheus + Grafana**

**Justifications**

1. **Ressources** : VM de labo avec RAM limitée → Prometheus est plus léger
2. **Apprentissage** : PromQL est utile en cybersecurité (requêtes avancées)
3. **Modularité** : Facile d'ajouter des exporteurs (Wazuh exporter, JMX, etc.)
4. **Industrie** : Prometheus est standard en monitoring modern (DevSecOps)
5. **Dashboards** : Grafana offre plus de flexibilité que Zabbix
6. **Intégration SOC** : Prometheus s'intègre mieux avec Wazuh et ELK

---

## 5. Plan de mise en place

```
Semaine 1
├─ Jour 1 : Installation Prometheus (30 min)
├─ Jour 2 : Installation Grafana + premiers dashboards (1h)
├─ Jour 3 : Configuration Node Exporter (1h)
└─ Jour 4 : Dashboards avancés + alertes (2h)

Total : ~4.5h
```

---

## 6. Composants à installer

### VM3 (Monitoring)
1. **Prometheus** : collecteur + stockage TimeSeries
2. **Grafana** : visualisation dashboards
3. **AlertManager** : gestion des alertes (optionnel pour v1)

### VM1 & VM2 (Moniteurs)
1. **Node Exporter** : exporteur de métriques système
2. (Optional) **Nginx Exporter** : métriques web

---

## 7. Checklist de décision

Avant de continuer, réponds à ces questions :

- [ ] Tu as accès à VM3 avec 2GB RAM min ?
- [ ] Tu préfères une solution **légère et modulaire** (Prometheus) ou **tout-en-un** (Zabbix) ?
- [ ] Tu dois monitorer uniquement **système** ou aussi **applications** ?
- [ ] Connais-tu PromQL ou veux-tu l'apprendre ?

**Si réponses = OUI/Prometheus/système/apprendre** → Prometheus + Grafana  
**Si réponses = NON/Zabbix/applications/non** → Zabbix

---

## 8. Prochaines étapes

👉 **Passer au fichier `02_install_monitoring.md`**

Pour installer Prometheus et Grafana sur VM3.

---

**Notes**
- Dans ce projet, nous utilisons **Prometheus + Grafana**
- Les deux approches sont valables en prod
- Zabbix = plus simple, Prometheus = plus puissant
