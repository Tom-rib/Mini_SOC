# 05. Configuration des alertes Grafana

**Objectif** : Configurer des alertes automatiques pour détecter les anomalies système (CPU, disque, services).

**Durée estimée** : 1h  
**Niveau** : Intermédiaire  
**Prérequis** : Grafana installé et connecté à Prometheus

---

## 1. Concept des alertes

### Qu'est-ce qu'une alerte ?

Une alerte Grafana est un mécanisme qui :
1. Évalue une métrique à intervalle régulier
2. Compare le résultat à un seuil
3. Déclenche une action si le seuil est dépassé (email, Slack, webhook...)

**Exemple concret** : Si CPU > 80%, envoyer un email à l'équipe SOC.

### Cycle d'une alerte

```
Prometheus collecte → Grafana évalue → Seuil dépassé ? → Action (notif)
   (toutes les 15s)   (toutes les 1min)      OUI        → email/Slack
```

---

## 2. Types d'alertes à configurer

### 2.1 Alerte CPU élevé

**Quand l'activer** : CPU > 80% pendant 2 minutes  
**Impact** : Risque de ralentissement ou attaque DoS  
**Action** : Email + Slack

**Métrique Prometheus** :
```
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Cette formule calcule le pourcentage de CPU utilisé en soustrayant le temps "idle" (inactif).

### 2.2 Alerte disque plein

**Quand l'activer** : Disque > 85% utilisé  
**Impact** : Logs qui ne s'écrivent plus, problème grave  
**Action** : Email critique

**Métrique Prometheus** :
```
(node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes) * 100 < 15
```

### 2.3 Alerte service down

**Quand l'activer** : Service ne répond plus (ping échoue)  
**Impact** : Perte de fonctionnalité, incident critique  
**Action** : Email immédiat + Slack

**Métrique Prometheus** :
```
up{job="SSH"} == 0
up{job="Nginx"} == 0
up{job="Wazuh"} == 0
```

### 2.4 Alerte mémoire élevée

**Quand l'activer** : RAM > 90%  
**Impact** : Risque de swap, ralentissement  
**Action** : Email d'avertissement

**Métrique Prometheus** :
```
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
```

---

## 3. Configuration des alertes dans Grafana

### 3.1 Créer un channel de notification (email)

1. Aller dans **Alerting → Notification channels**
2. Cliquer sur **New channel**
3. Remplir les champs :
   - **Name** : `Email SOC Team`
   - **Type** : `Email`
   - **Email address** : `soc-team@monentreprise.fr`
   - Cocher `Send on all alerts`

4. Cliquer **Save**

### 3.2 Créer un channel Slack (optionnel mais recommandé)

1. Créer un webhook Slack :
   - Aller dans Slack App Directory
   - Installer "Incoming Webhooks"
   - Copier l'URL (ex: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX`)

2. Dans Grafana, créer un nouveau channel :
   - **Name** : `Slack SOC`
   - **Type** : `Slack`
   - **Webhook URL** : `[coller l'URL Slack]`
   - **Channel** : `#soc-alerts`
   - Cocher `Send on all alerts`

---

## 4. Créer les règles d'alerte

### 4.1 Alerte CPU > 80%

**Étape 1** : Créer ou ouvrir un dashboard  
**Étape 2** : Ajouter ou éditer un graphique CPU

**Dans le panneau du graphique** :

```
Aller à l'onglet "Alert"
↓
Cliquer "Create Alert"
↓
Remplir la condition :
  - Query : A (votre métrique CPU)
  - Condition : is above 80
  - For : 2m (déclencher si dépassé pendant 2 min)
↓
Ajouter message :
  Alert name : "CPU Élevé (>80%)"
  Message : "Alerte CPU élevée détectée sur {{$labels.instance}}"
  Notification channel : "Email SOC Team"
↓
Cliquer "Save Alert"
```

**Exemple de configuration JSON** (pour export) :
```json
{
  "alert": "CPU Élevé",
  "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80",
  "for": "2m",
  "annotations": {
    "summary": "CPU élevée sur {{ $labels.instance }}",
    "description": "CPU > 80% pendant 2 minutes"
  }
}
```

---

### 4.2 Alerte disque > 85%

Même processus, mais avec la métrique disque :

```
Query : node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes < 0.15
Condition : is below 0.15 (= 15% libre = 85% utilisé)
For : 5m (attendre 5 min avant alerte, car ça peut fluctuer)
Message : "Disque faible sur {{$labels.device}} : {{$value | humanizePercentage}} libre"
```

---

### 4.3 Alerte service SSH down

```
Query : up{job="SSH"} == 0
Condition : is equal to 0
For : 1m (réaction rapide)
Message : "Service SSH down sur {{$labels.instance}}"
Notification : "Email SOC Team" + "Slack SOC"
```

Répéter pour Nginx et Wazuh.

---

### 4.4 Alerte mémoire > 90%

```
Query : (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
Condition : is above 90
For : 3m
Message : "RAM élevée : {{$value | humanize}}% utilisée"
```

---

## 5. Format des messages d'alerte

### Inclure les bonnes infos

**Mauvais message** :
```
Alerte !
```

**Bon message** :
```
🚨 ALERTE CPU ÉLEVÉE 🚨

Serveur : {{$labels.instance}}
Valeur : {{$value}}%
Seuil : 80%
Durée : 2 minutes
Timestamp : {{$timestamp}}

Action recommandée :
- Vérifier les processus consommant du CPU : top -b -n 1
- Analyser les logs Wazuh
- Contacter l'admin système si nécessaire
```

---

## 6. Tester les alertes

### 6.1 Déclencher une fausse alerte (test)

**Pour tester l'alerte CPU** :

```bash
# Sur le serveur monitoré, lancer une charge CPU
stress --cpu 2 --timeout 5m
```

Après 2 minutes, Grafana doit envoyer une alerte.

**Vérifier dans Grafana** :
- Alerting → Alert Rules
- Vérifier le statut de l'alerte : `ALERTING` (rouge)

### 6.2 Vérifier la notification email

1. Vérifier la boîte mail
2. Ou vérifier les logs Grafana :

```bash
sudo journalctl -u grafana-server | grep -i alert
```

### 6.3 Vérifier la notification Slack

Le message doit apparaître dans le channel `#soc-alerts` de Slack.

---

## 7. Gestion des faux positifs

### Problème : Trop d'alertes !

**Cause** : Seuils trop bas ou durée "For" trop courte.

**Solution** :

| Problème | Cause | Solution |
|----------|-------|----------|
| CPU alerte constamment | Seuil trop bas | Augmenter à 85% ou 90% |
| Disque alerte souvent | Logs qui grandir vite | Augmenter la durée "For" à 10m |
| Fausses alertes pics | Pics momentanés | Augmenter "For" de 2m à 5m |

### Recommandations

```
CPU > 80%        → For 2-3m
Disque > 85%     → For 5-10m (ces systèmes fluctuent moins)
Service down     → For 1m (critique, réaction rapide)
Mémoire > 90%    → For 3m
```

---

## 8. Vérification et validation

### Checklist

- [ ] Channel email créé et testé
- [ ] Channel Slack créé (optionnel)
- [ ] Alerte CPU configurée (>80%, For 2m)
- [ ] Alerte Disque configurée (>85%, For 5m)
- [ ] Alerte Services down configurée (SSH, Nginx, Wazuh)
- [ ] Alerte Mémoire configurée (>90%, For 3m)
- [ ] Test alerte CPU avec `stress` ✓
- [ ] Test notification email ✓
- [ ] Test notification Slack ✓
- [ ] Messages d'alerte clairs et actionnables

### Livrable

Créer un fichier `alertes_configuration.txt` avec :
```
ALERTES CONFIGURÉES
===================

1. CPU > 80%
   - Channel : Email SOC Team
   - Durée : 2m
   - Message : [copier du Grafana]

2. Disque > 85%
   - Channel : Email SOC Team
   - Durée : 5m
   - Message : [copier du Grafana]

3. Services down
   - SSH, Nginx, Wazuh
   - Channel : Email + Slack
   - Durée : 1m

4. Mémoire > 90%
   - Channel : Email SOC Team
   - Durée : 3m

TESTS EFFECTUÉS
===============
- Test alerte CPU : OK le 2025-02-06
- Test email : OK
- Test Slack : OK
```

---

## 9. Résumé en 5 points

1. **Channel** = destination (email, Slack, webhook)
2. **Query** = métrique Prometheus
3. **Condition** = seuil (> 80, < 15, == 0)
4. **For** = durée avant alerte (2m, 5m, 1m)
5. **Message** = infos pour l'équipe (serveur, valeur, action)

Une alerte bien configurée = rapide à identifier + facile à corriger.

---

## Pour aller plus loin

- Créer des groupes d'alertes (critiques vs warnings)
- Ajouter des webhooks personnalisés
- Automatiser les réponses avec Ansible
- Ajouter des dépendances d'alertes (ex: alerte A masque alerte B)
