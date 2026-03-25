# 06. Évaluation des baselines et seuils d'alerte

**Objectif** : Déterminer des seuils d'alerte intelligents basés sur le comportement réel du système.

**Durée estimée** : 1h  
**Niveau** : Intermédiaire  
**Prérequis** : Prometheus collecte les données depuis 7-30 jours

---

## 1. Qu'est-ce qu'une baseline ?

### Définition simple

Une **baseline** = le fonctionnement normal de votre système.

**Exemple** :
- CPU normal = 25% utilisé
- Disque normal = 60% utilisé
- RAM normal = 65% utilisée

### Pourquoi c'est important ?

Sans baseline :
```
Alerte CPU > 80% 
→ Normal pour ce serveur !
→ Faux positif
→ L'équipe ignore les alertes
→ Catastrophe
```

Avec baseline :
```
Baseline CPU = 30%
Alerte CPU > 60% (baseline + 100%)
→ Vraiment anormal
→ Vraiment utile
→ L'équipe réagit
```

---

## 2. Évaluer la baseline CPU

### 2.1 Collect

Pour **30 jours** minimum, Prometheus doit collecter les métriques.

**Vérifier dans Prometheus** (http://localhost:9090) :

1. Aller dans **Graph**
2. Écrire la requête :
```
rate(node_cpu_seconds_total{mode="idle"}[5m])
```
3. Cocher **Range 30d** (30 jours)
4. Vérifier qu'il y a des données

### 2.2 Analyser avec une requête Grafana

**Query pour voir la moyenne CPU sur 30 jours** :

```
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Cette requête calcule le CPU utilisé en moyenne sur la plage sélectionnée.

**Étapes** :
1. Ouvrir Grafana
2. Créer un nouveau dashboard : **+ → Dashboard**
3. Ajouter un panneau : **+ → Add panel**
4. Query : copier la requête ci-dessus
5. Définir la plage : **Last 30 days**
6. Regarder la courbe

**Exemple de résultat** :

```
Jour 1-7   : CPU = 20-30% (heures bureau)
Jour 8-14  : CPU = 22-28% (normal)
Jour 15-21 : CPU = 25-35% (pic mardi, maintenance)
Jour 22-30 : CPU = 20-25% (calme)

MOYENNE GLOBALE = 25%
```

### 2.3 Déterminer le seuil CPU

**Formule simple** :
```
Seuil alerte = Baseline + 30% (ou 50% selon criticalité)
```

**Exemples** :
```
Baseline = 25%  → Seuil = 25 + 30 = 55% (normal)
Baseline = 10%  → Seuil = 10 + 30 = 40% (très sensible)
Baseline = 40%  → Seuil = 40 + 50 = 90% (critique)
```

**Recommandation pour ce projet** :
- Serveur test → Seuil à **70-80%** (moins sensible)
- Serveur production → Seuil à **50-60%** (plus sensible)

---

## 3. Évaluer la baseline RAM

### 3.1 Query Prometheus

```
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

Cette formule donne le pourcentage de RAM utilisée.

### 3.2 Analyser sur 30 jours

1. Dans Grafana, créer un panneau RAM
2. Range : **Last 30 days**
3. Observer les pics et la moyenne

**Exemple** :
```
RAM utilisée (moyenne) = 60%
Maximum observé = 78%
Minimum observé = 52%
```

### 3.3 Déterminer le seuil RAM

**Formule** :
```
Seuil = Max observé + 10-15%
```

**Exemple avec données ci-dessus** :
```
Max observé = 78%
Seuil alerte = 78 + 10 = 88%
```

**Interprétation** :
- Seuil < 85% → Trop sensible (faux positifs)
- Seuil 85-90% → Bon (alerte justifiée)
- Seuil > 95% → Trop tard (OOM risk)

**Recommandation** : **85-90%** pour ce projet

---

## 4. Évaluer la baseline Disque

### 4.1 Query Prometheus

```
(node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_avail_bytes{fstype!="tmpfs"}) / node_filesystem_size_bytes * 100
```

### 4.2 Analyser sur 30 jours

Regarder l'évolution :

```
Jour 1  : 40%
Jour 7  : 45%
Jour 14 : 52%
Jour 21 : 58%
Jour 30 : 62%
```

**Observation** : Croissance de ~1% par jour (logs qui accumulent).

### 4.3 Déterminer le seuil Disque

**Règle** :
```
Seuil = Taux de croissance × Jours avant alerte + actuel + marge
```

**Calcul** :
```
Taux = 1% par jour
Si on veut être alerté 7 jours avant saturation :
  Seuil = 62% (actuel) + (1% × 7 jours) + 5% (marge) = 74%

Arrondir à 75%
```

**Mais attention** : Si disque se remplit trop vite, réduire le seuil.

**Vérifier les gros consommateurs** :

```bash
# Sur le serveur
du -sh /var/log/*
du -sh /var/*
du -sh /home/*
```

Si logs explosent, fixer le seuil plus bas (**70%** ou **75%**).

**Recommandation** : **85%** pour ce projet (disque virtuel a de la marge)

---

## 5. Créer une feuille de baselines

### Template à remplir

Créer un fichier `baselines.md` :

```markdown
# Baselines et seuils du Mini SOC

## 1. CPU

### Metric
node_cpu_seconds_total{mode="idle"}

### Analyse 30 jours
- Minimum observé : 15%
- Moyenne : 25%
- Maximum observé : 65%
- Pic détecté : Maintenance Tuesday 3pm (+40%)

### Seuil choisi
- **Alerte normale** : > 70% (baseline + 45%)
- **Alerte critique** : > 85% (baseline + 60%)
- **Durée avant alerte** : 2 minutes
- **Justification** : Server test, peu sensible

---

## 2. RAM

### Metric
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

### Analyse 30 jours
- Minimum observé : 52%
- Moyenne : 62%
- Maximum observé : 78%

### Seuil choisi
- **Alerte** : > 88% (max + 10%)
- **Durée avant alerte** : 3 minutes
- **Justification** : Éviter OOM, VM test

---

## 3. Disque

### Metric
(size - available) / size * 100

### Analyse 30 jours
- Actuel : 62%
- Croissance : ~1% par jour
- Saturation estimée : 30 jours

### Seuil choisi
- **Alerte** : > 85% (marge avant saturation)
- **Durée avant alerte** : 5 minutes (peut fluctuer)
- **Action** : Archiver logs + alerte admin

---

## Seuils finaux appliqués

| Métrique | Baseline | Seuil | For | Action |
|----------|----------|-------|-----|--------|
| CPU | 25% | 70% | 2m | Email |
| RAM | 62% | 88% | 3m | Email |
| Disque | 62% | 85% | 5m | Email critique |

Date d'évaluation : 2025-02-06
Prochaine révision : 2025-03-06
```

---

## 6. Méthode pratique : Requêtes Grafana

### 6.1 Dashboard de baseline

Créer un dashboard dedié avec ces panneaux :

**Panneau 1 : CPU 30j**
```
Requête : 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
Range : Last 30 days
Format : Gauge (pour voir la moyenne au centre)
```

**Panneau 2 : RAM 30j**
```
Requête : (1 - (avg(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))) * 100
Range : Last 30 days
Format : Gauge
```

**Panneau 3 : Disque 30j**
```
Requête : (avg(node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_avail_bytes) / avg(node_filesystem_size_bytes{fstype!="tmpfs"})) * 100
Range : Last 30 days
Format : Gauge
```

**Panneau 4 : Croissance disque (taux par jour)**
```
Requête : rate(node_filesystem_size_bytes - node_filesystem_avail_bytes[1d])
Range : Last 30 days
Format : Graph (courbe pour voir la tendance)
```

### 6.2 Interpréter un graphique

**Si le graphique montre** :
- Ligne plate → comportement stable, seuil peut être bas
- Pics réguliers → prévoir marges plus grandes
- Tendance ascendante → seuil plus bas pour anticiper

---

## 7. Éviter les faux positifs

### Problème n°1 : Alertes pendant la maintenance

**Solution** :
- Désactiver temporairement l'alerte pendant la maintenance
- Ou augmenter la durée "For" ce jour-là

### Problème n°2 : Pics momentanés

**Exemple** : CPU à 95% pendant 10 secondes, puis normal.

**Solution** :
- Augmenter la durée "For" de 2m à 5m
- Ou augmenter le seuil de 70% à 80%

### Problème n°3 : Mesures inexactes

**Vérifier** :
```bash
# Sur le serveur, comparer avec la réalité
free -h  # vérifier RAM réelle
df -h    # vérifier disque réel
top      # vérifier CPU réel
```

Si Prometheus ≠ réalité, vérifier la config Prometheus.

---

## 8. Réviser les baselines

**Quand réviser** ?
- Après 30 jours → première révision
- Après changement de configuration
- Après chaque incident majeur

**Comment** ?
- Même processus : analyser les 30 derniers jours
- Ajuster les seuils
- Mettre à jour le fichier `baselines.md`

---

## 9. Checklist

- [ ] Prometheus collecte depuis 30 jours minimum
- [ ] Dashboard de baseline créé dans Grafana
- [ ] CPU : baseline identifiée, seuil défini
- [ ] RAM : baseline identifiée, seuil défini
- [ ] Disque : baseline identifiée, seuil défini
- [ ] Fichier `baselines.md` complété
- [ ] Seuils appliqués dans les alertes
- [ ] Test faux positif effectué
- [ ] Pas d'alerte spam depuis 1 semaine

---

## 10. Résumé pratique

```
PROCESSUS SIMPLIFIÉ :
=====================

1. Attendre 30 jours (ou regarder ce qu'on a)
2. Noter la moyenne de chaque métrique
3. Ajouter 30-50% à la moyenne → seuil
4. Configurer l'alerte dans Grafana
5. Tester pendant 1 semaine
6. Ajuster si faux positifs
7. Valider

Exemple :
CPU moyenne = 25% → Seuil = 25 + 30 = 55%
RAM moyenne = 60% → Seuil = 60 + 30 = 90% (mais capper à 88%)
Disque = 62% + croissance → Seuil = 85%
```

Une baseline bien calculée = alertes justes = une équipe confiante !
