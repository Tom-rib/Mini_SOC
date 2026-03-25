# 03 - Métriques de surveillance et requêtes PromQL

**Objectif** : Apprendre à récupérer et interpréter les métriques Prometheus  
**Durée estimée** : 1-1.5 heures  
**Rôle** : Administrateur supervision (Rôle 3)

---

## Concepts clés

### Qu'est-ce qu'une métrique ?

Une métrique est une mesure d'un système à un instant T.

```
Métrique = Nom + Labels + Valeur + Timestamp

Exemple:
node_memory_MemFree_bytes{job="vm1-web", instance="10.0.0.5:9100"} 2048000000 1704067200
│                        │
│                        └─ Labels (contexte)
└─────────────────────── Nom de la métrique
```

### Types de métriques

1. **Counter** : augmente toujours (cumul)
   - Exemple : `http_requests_total` (nombre de requêtes depuis démarrage)

2. **Gauge** : monte et descend
   - Exemple : `node_memory_MemFree_bytes` (RAM libre maintenant)

3. **Histogram** : distribution de valeurs
   - Exemple : `http_request_duration_seconds`

4. **Summary** : résumé statique
   - Exemple : quantiles de latence

---

## 1. Métriques système (Node Exporter)

### 1.1 - CPU

**Métrique** : `node_cpu_seconds_total`

```promql
# CPU total utilisé depuis le démarrage (en secondes)
node_cpu_seconds_total

# CPU utilisé par mode (user, system, idle, etc.)
node_cpu_seconds_total{mode="user"}
node_cpu_seconds_total{mode="system"}
node_cpu_seconds_total{mode="idle"}

# Utilisation CPU en % (5 dernières minutes)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100)
```

**Interprétation**
- `mode="user"` : temps CPU en user space (applications)
- `mode="system"` : temps CPU en kernel space
- `mode="idle"` : CPU libre (plus élevé = mieux)
- `mode="iowait"` : CPU attend I/O disque (signe de lenteur)

**Dashboard** : Afficher en **Gauge** 0-100%

---

### 1.2 - RAM / Mémoire

**Métriques principales**

```promql
# RAM libre (en bytes)
node_memory_MemFree_bytes

# RAM utilisée
node_memory_MemTotal_bytes - node_memory_MemFree_bytes

# % RAM utilisée
(1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes)) * 100

# Buffer + Cache (libérable si besoin)
node_memory_Buffers_bytes + node_memory_Cached_bytes

# RAM disponible (vraiment utilisable)
node_memory_MemAvailable_bytes
```

**Labels d'intérêt**
```
node_memory_MemFree_bytes{instance="10.0.0.5:9100", job="vm1-web"}
```

**Interprétation**
- RAM libre ↓ : Le serveur utilise bcp de mémoire
- Buffers/Cache ↑ : Normal, Linux cache les accès disque
- MemAvailable ↓ : Attention, manque de RAM réelle

**Dashboard** : Afficher en **Graph** ou **Stat** 0-100%

---

### 1.3 - Disque

**Métrique** : `node_filesystem_avail_bytes` et `node_filesystem_size_bytes`

```promql
# Espace disque libre (en GB)
node_filesystem_avail_bytes{mountpoint="/"} / 1024^3

# % disque utilisé
(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100

# Toutes les partitions
node_filesystem_avail_bytes / node_filesystem_size_bytes

# Croissance du disque (rate = vitesse de remplissage)
rate(node_filesystem_size_bytes[1h])
```

**Filtres importants**
```
mountpoint="/"      # Root
mountpoint="/var"   # Logs
mountpoint="/home"  # User data
fstype="ext4"       # Ignore tmpfs, sysfs, etc.
```

**Interprétation**
- Disque > 90% : ⚠️ Critique
- Disque > 75% : ⚠️ Attention
- Croissance rapide : Log qui explose ? Dump non compressé ?

**Dashboard** : **Pie chart** % utilisé, ou **Graph** tendance

---

### 1.4 - Charge système

**Métrique** : `node_load1`, `node_load5`, `node_load15`

```promql
# Charge moyenne sur 1 minute
node_load1

# Charge moyenne sur 5 minutes
node_load5

# Charge moyenne sur 15 minutes
node_load15

# Charge en % du nombre de cores
node_load1 / on(instance) group_left count by (instance) (node_cpu_seconds_total{mode="idle"})
```

**Interprétation**
- load < CPU cores : OK
- load > CPU cores : Serveur saturé
- load1 > load5 > load15 : Pics transitoires
- load1 < load5 < load15 : Charge croissante (alerte)

**Dashboard** : **Graph** 3 courbes (1m, 5m, 15m)

---

### 1.5 - Temps système

**Métrique** : `node_time_seconds`

```promql
# Heure système (utilité : vérifier skew NTP)
node_time_seconds

# Offset NTP (secondes)
node_ntp_offset_seconds
```

**Utilité** : Détecter dérive horloge (important pour logs, certificats)

---

## 2. Métriques services

### 2.1 - Service running (ping)

**Métrique** : `up`

```promql
# Tous les targets UP
up

# Target spécifique
up{job="vm1-web"}

# VM1 en tant que nombre (1=up, 0=down)
up{instance="10.0.0.5:9100"}

# Alerter si DOWN
up{job="vm1-web"} == 0
```

**Utilité** : Savoir si scrape réussit (Node Exporter tourne ?)

**Dashboard** : **Table** ou **Stat** vert/rouge

---

### 2.2 - SSH

Nécessite `textfile collector` sur Node Exporter.

Créer script `/usr/local/bin/ssh_check.sh` :

```bash
#!/bin/bash
# Vérifier SSH accessible

PORT=2222  # Port SSH custom
TIMEOUT=2

if timeout $TIMEOUT bash -c "echo > /dev/tcp/localhost/$PORT" 2>/dev/null; then
  echo "node_ssh_running 1"
else
  echo "node_ssh_running 0"
fi
```

```promql
# SSH running
node_ssh_running{job="vm1-web"}
```

---

### 2.3 - Nginx (si Web server)

**Metric**: `nginx_up`

```promql
# Nginx accessible
up{job="nginx"}

# Requêtes Nginx (voir metrics nginx exporter)
rate(nginx_requests_total[5m])
```

---

## 3. Métriques réseau

**Metric** : `node_network_receive_bytes_total`, `node_network_transmit_bytes_total`

```promql
# Bande passante reçue (Mbps)
rate(node_network_receive_bytes_total{device="eth0"}[5m]) * 8 / 1000000

# Bande passante émise (Mbps)
rate(node_network_transmit_bytes_total{device="eth0"}[5m]) * 8 / 1000000

# Erreurs réseau
rate(node_network_transmit_errs_total{device="eth0"}[5m])
```

**Interprétation**
- Spike de trafic : Attaque DDoS ? Backup ?
- Erreurs ↑ : Problème physique réseau ?

**Dashboard** : **Graph** 2 courbes (RX, TX)

---

## 4. Métriques sécurité (intégration Wazuh)

Si vous intégrez Wazuh exporter :

```promql
# Alertes Wazuh par niveau
wazuh_alerts_total{level="critical"}
wazuh_alerts_total{level="high"}

# Agents Wazuh actifs
wazuh_agents_active

# Dernière connexion agent
wazuh_agent_last_seen_seconds
```

---

## 5. Metriques métier du SOC

### 5.1 - Tentatives de connexion (brute force)

Depuis logs centralisés, créer métrique personnalisée :

```bash
# Via Prometheus textfile collector
cat > /var/lib/node_exporter/ssh_failed_logins.prom << EOF
# HELP ssh_failed_logins_total Nombre de tentatives SSH échouées
# TYPE ssh_failed_logins_total counter
ssh_failed_logins_total 42
EOF
```

### 5.2 - Incidents détectés

Via Wazuh API, exposer nombre d'alertes :

```promql
rate(wazuh_alert_events_total[5m])
```

---

## 6. Requêtes PromQL avancées pour Blue Team

### 6.1 - Détection anormales

```promql
# CPU > 80% pendant 5min
node_cpu_usage_percent > 80

# RAM > 90%
(1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes)) > 0.90

# Disque > 85%
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) > 0.85

# Load > nombre de CPUs
node_load1 > on(instance) group_left count(node_cpu_seconds_total{mode="idle"})
```

### 6.2 - Tendances

```promql
# Augmentation RAM sur 1h
delta(node_memory_MemFree_bytes[1h]) < -500000000  # -500MB

# Disque qui remplit vite
rate(node_filesystem_size_bytes[30m]) > 100000000   # > 100MB/min

# Trafic réseau anormal
rate(node_network_receive_bytes_total[5m]) > 1000000000  # > 1GB/s
```

### 6.3 - Comparaisons entre hosts

```promql
# Comparer CPU VM1 vs VM2
{job=~"vm1|vm2"} and node_cpu_usage_percent

# Qui consomme le plus de RAM ?
topk(3, node_memory_MemFree_bytes)

# Quel disque remplit le plus vite ?
topk(3, rate(node_filesystem_size_bytes[1h]))
```

---

## 7. Interface Prometheus

### 7.1 - Tester les requêtes

Aller à : http://<IP_VM3>:9090/graph

```
1. Écrire requête dans "Enter Expression"
2. Cliquer "Execute"
3. Voir résultat en Table ou Graph
```

### 7.2 - Format des résultats

**Table** : valeurs instantanées
```
instance          | value
10.0.0.5:9100    | 2048000000
10.0.0.6:9100    | 3072000000
```

**Graph** : évolution dans le temps
```
(affiche courbe)
```

---

## 8. Cheatsheet des requêtes clés

```promql
# ========== CPU ==========
# Utilisation CPU en %
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# ========== RAM ==========
# % RAM utilisée
(1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes)) * 100

# ========== DISQUE ==========
# % disque utilisé
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100

# ========== LOAD ==========
# Charge système
node_load5

# ========== RÉSEAU ==========
# Bande passante reçue (Mbps)
rate(node_network_receive_bytes_total[5m]) * 8 / 1000000

# ========== STATUS ==========
# Service running
up{job="vm1-web"}

# ========== ALERTES ==========
# Conditions à surveiller
node_memory_MemFree_bytes < 536870912  # < 500MB
node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15  # < 15% libre
```

---

## 9. Exercices pratiques

### Exercice 1 : CPU
```
[ ] Écrire requête : % CPU utilisé
[ ] Identifier pics de charge
[ ] Ajouter requête au dashboard
```

### Exercice 2 : RAM
```
[ ] Écrire requête : % RAM utilisée
[ ] Vérifier si MemAvailable > 10%
[ ] Comparer VM1 vs VM2
```

### Exercice 3 : Disque
```
[ ] Écrire requête : espace libre /
[ ] Repérer partition qui remplit vite
[ ] Écrire alerte : disque > 80%
```

### Exercice 4 : Détection anormale
```
[ ] Créer requête : charge > CPU cores
[ ] Créer requête : pics réseau > 500Mbps
[ ] Créer requête : down time agent
```

---

## Prochaines étapes

👉 **Passer au fichier `04_dashboards.md`**

Pour créer les dashboards Grafana avec ces métriques.

---

## Ressources

**Documentation officielle**
- PromQL : https://prometheus.io/docs/prometheus/latest/querying/basics/
- Node Exporter : https://github.com/prometheus/node_exporter
- Grafana : https://grafana.com/docs/

**Métriques disponibles**
```bash
# Lister toutes les métriques disponibles
curl http://<IP_VM3>:9090/api/v1/label/__name__/values

# Voir labels d'une métrique
curl 'http://<IP_VM3>:9090/api/v1/label/instance/values'
```

---

**Résumé**
- Node Exporter expose 100+ métriques système
- PromQL permet requêtes complexes
- Les 10 requêtes clés : CPU, RAM, Disque, Load, Réseau, Up, SSH, Services
- Pratiquer les requêtes avant de faire les dashboards
