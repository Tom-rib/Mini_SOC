# 02 - Installation du monitoring (Prometheus + Grafana)

**Objectif** : Installer et configurer Prometheus et Grafana sur VM3  
**Durée estimée** : 2-3 heures  
**Rôle** : Administrateur supervision (Rôle 3)

---

## Vue d'ensemble de cette étape

```
┌─────────────────────────────────────────────────────┐
│ VM3 (Monitoring)                                    │
│                                                     │
│  Port 9090   ┌──────────────┐                       │
│  Prometheus  │ Scrape VM1   │ → collecte metrics   │
│              │ Scrape VM2   │                       │
│              └──────────────┘                       │
│                     ↓ (stockage)                     │
│              /var/lib/prometheus/                   │
│                                                     │
│  Port 3000   ┌──────────────┐                       │
│  Grafana     │ Query data   │ → visualisation      │
│              │ Dashboards   │                       │
│              └──────────────┘                       │
└─────────────────────────────────────────────────────┘
```

---

## Phase 1 : Préparation VM3

### 1.1 - Vérifications préalables

Se connecter à VM3 :
```bash
# SSH vers VM3
ssh admin@<IP_VM3>

# Vérifier Rocky Linux
cat /etc/os-release

# Vérifier ressources disponibles
free -h        # RAM
df -h /        # Disque
nproc          # CPU cores
```

**Résultat attendu**
```
RAM: 2GB minimum
Disque: 10GB libre
CPU: 1-2 cores
OS: Rocky Linux 8 ou 9
```

### 1.2 - Mise à jour système

```bash
# Mise à jour du système
sudo dnf update -y

# Packages utiles
sudo dnf install -y wget curl tar gzip vim git

# Vérifier version
curl --version
```

### 1.3 - Créer utilisateur Prometheus

```bash
# Créer utilisateur dédié (sans shell)
sudo useradd --no-create-home --shell /bin/false prometheus

# Créer utilisateur dédié pour Node Exporter
sudo useradd --no-create-home --shell /bin/false node_exporter

# Vérifier
grep prometheus /etc/passwd
```

---

## Phase 2 : Installation de Prometheus

### 2.1 - Télécharger et extraire Prometheus

```bash
# Définir version
PROMETHEUS_VERSION="2.48.1"

# Créer répertoire de travail
mkdir -p ~/prometheus-setup
cd ~/prometheus-setup

# Télécharger
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# Extraire
tar xvfz prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# Vérifier extraction
ls prometheus-${PROMETHEUS_VERSION}.linux-amd64/
```

### 2.2 - Déplacer fichiers aux emplacements finaux

```bash
cd ~/prometheus-setup/prometheus-${PROMETHEUS_VERSION}.linux-amd64

# Créer répertoires système
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

# Copier fichiers binaires
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/

# Copier fichiers de configuration (templates)
sudo cp prometheus.yml /etc/prometheus/prometheus.yml.bak

# Vérifier installation
prometheus --version
```

### 2.3 - Configurer Prometheus

Créer le fichier de configuration `/etc/prometheus/prometheus.yml` :

```bash
# Éditer le fichier de configuration
sudo vim /etc/prometheus/prometheus.yml
```

**Contenu du fichier** (remplacer par défaut) :

```yaml
# /etc/prometheus/prometheus.yml
# Configuration Prometheus

global:
  scrape_interval: 15s      # Collecte les métriques tous les 15s
  evaluation_interval: 15s   # Évalue les alertes tous les 15s
  external_labels:
    monitor: 'rocky-soc'

# Options de sauvegardes
tsdb:
  path: /var/lib/prometheus/   # Où stocker les données

# Configuration des cibles à monitorer
scrape_configs:
  # Prometheus lui-même
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # VM1 (Serveur Web) - Node Exporter
  - job_name: 'vm1-web'
    static_configs:
      - targets: ['<IP_VM1>:9100']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'VM1-web'

  # VM2 (SOC) - Node Exporter
  - job_name: 'vm2-soc'
    static_configs:
      - targets: ['<IP_VM2>:9100']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'VM2-soc'

  # Wazuh manager (optionnel)
  # - job_name: 'wazuh'
  #   static_configs:
  #     - targets: ['<IP_VM2>:9100']
```

**⚠️ Important** : Remplacer `<IP_VM1>` et `<IP_VM2>` par les vraies IPs

### 2.4 - Définir les permissions

```bash
# Propriétaire des fichiers
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Permissions
sudo chmod 755 /var/lib/prometheus

# Vérifier
ls -la /etc/prometheus/
```

### 2.5 - Créer service systemd

Créer `/etc/systemd/system/prometheus.service` :

```bash
sudo vim /etc/systemd/system/prometheus.service
```

**Contenu** :

```ini
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

Restart=always
RestartSec=5s

# Logs
StandardOutput=journal
StandardError=journal
SyslogIdentifier=prometheus

[Install]
WantedBy=multi-user.target
```

### 2.6 - Démarrer Prometheus

```bash
# Recharger systemd
sudo systemctl daemon-reload

# Démarrer le service
sudo systemctl start prometheus

# Vérifier statut
sudo systemctl status prometheus

# Démarrage au boot
sudo systemctl enable prometheus

# Vérifier les logs
sudo journalctl -u prometheus -f
```

### 2.7 - Test d'accès Prometheus

```bash
# Depuis VM3
curl http://localhost:9090/

# Depuis ta machine
# Ouvrir navigateur : http://<IP_VM3>:9090
```

**Résultat attendu**
- Page d'accueil Prometheus visible
- Menu "Graph" accessible
- Onglet "Status" → "Targets" montre les cibles configurées

---

## Phase 3 : Installation de Grafana

### 3.1 - Installer Grafana

```bash
# Ajouter repo Grafana
sudo bash -c 'cat > /etc/yum.repos.d/grafana.repo << EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF'

# Installer Grafana
sudo dnf install -y grafana-enterprise

# Alternative sans repo (binaire direct)
# wget https://dl.grafana.com/oss/release/grafana-10.2.3.linux-amd64.tar.gz
```

### 3.2 - Démarrer Grafana

```bash
# Démarrer
sudo systemctl start grafana-server

# Vérifier
sudo systemctl status grafana-server

# Démarrage au boot
sudo systemctl enable grafana-server

# Logs
sudo journalctl -u grafana-server -f
```

### 3.3 - Accès Grafana

```bash
# Vérifier écoute port 3000
sudo ss -tlnp | grep 3000

# Accès web : http://<IP_VM3>:3000
```

**Identifiants par défaut**
```
Utilisateur: admin
Mot de passe: admin
```

⚠️ Grafana demandera de changer le mot de passe au premier accès.

---

## Phase 4 : Installer Node Exporter (VM1 & VM2)

### 4.1 - Sur VM1 (serveur web)

```bash
# Se connecter à VM1
ssh admin@<IP_VM1>

# Créer répertoire
mkdir -p ~/node-exporter
cd ~/node-exporter

# Télécharger Node Exporter
NODE_VERSION="1.7.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz

# Extraire
tar xvfz node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
cd node_exporter-${NODE_VERSION}.linux-amd64

# Déplacer binaire
sudo cp node_exporter /usr/local/bin/

# Vérifier
node_exporter --version
```

### 4.2 - Créer service Node Exporter (VM1)

```bash
# Sur VM1, créer service
sudo vim /etc/systemd/system/node_exporter.service
```

**Contenu** :

```ini
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

Restart=always
RestartSec=5s

StandardOutput=journal
StandardError=journal
SyslogIdentifier=node_exporter

[Install]
WantedBy=multi-user.target
```

```bash
# Démarrer
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Vérifier
sudo systemctl status node_exporter

# Test
curl http://localhost:9100/metrics | head -20
```

### 4.3 - Répéter pour VM2 (serveur SOC)

Mêmes étapes que VM1, se connecter à VM2 :

```bash
ssh admin@<IP_VM2>

# Mêmes commandes que VM1 (4.1 et 4.2)
```

---

## Phase 5 : Vérifier configuration complète

### 5.1 - Depuis VM1

```bash
# Test Node Exporter
curl http://localhost:9100/metrics

# Résultat : métriques de système
# node_cpu_seconds_total
# node_memory_MemFree_bytes
# ...
```

### 5.2 - Depuis VM2

```bash
# Test Node Exporter
curl http://localhost:9100/metrics
```

### 5.3 - Depuis VM3 (Prometheus)

```bash
# Vérifier targets
curl http://localhost:9090/api/v1/targets

# Résultat JSON : tous les targets doivent être "up"

# Test direct PromQL
curl 'http://localhost:9090/api/v1/query?query=node_memory_MemFree_bytes'
```

---

## Checklist de vérification

```
✅ Prometheus démarre sans erreur
   [ ] systemctl status prometheus → active (running)
   
✅ Prometheus accessible sur 9090
   [ ] http://<IP_VM3>:9090 → interface visible
   
✅ Grafana démarre sans erreur
   [ ] systemctl status grafana-server → active (running)
   
✅ Grafana accessible sur 3000
   [ ] http://<IP_VM3>:3000 → page login
   [ ] Connexion admin/admin fonctionne
   
✅ Node Exporter VM1 fonctionne
   [ ] curl http://<IP_VM1>:9100/metrics → métriques reçues
   
✅ Node Exporter VM2 fonctionne
   [ ] curl http://<IP_VM2>:9100/metrics → métriques reçues
   
✅ Prometheus voit les targets
   [ ] http://<IP_VM3>:9090/targets → 3 targets en "UP"
```

---

## Troubleshooting

### Prometheus ne démarre pas

```bash
# Vérifier logs
sudo journalctl -u prometheus -n 50

# Vérifier syntaxe config
prometheus --config.file=/etc/prometheus/prometheus.yml --dry-run

# Problèmes courants
# - Port 9090 déjà utilisé
sudo ss -tlnp | grep 9090

# - Permissions fichiers
sudo chown -R prometheus:prometheus /etc/prometheus
```

### Grafana ne démarre pas

```bash
sudo journalctl -u grafana-server -n 50

# Port 3000 occupé ?
sudo ss -tlnp | grep 3000

# Logs détaillés
sudo tail -100 /var/log/grafana/grafana.log
```

### Node Exporter non visible dans Prometheus

```bash
# Vérifier firewall VM1/VM2
sudo firewall-cmd --list-all

# Ouvrir port 9100
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload

# Depuis VM3, tester connectivity
telnet <IP_VM1> 9100
curl http://<IP_VM1>:9100/metrics
```

### Targets DOWN dans Prometheus

```bash
# Vérifier IPs dans config
sudo cat /etc/prometheus/prometheus.yml

# Vérifier services actifs
sudo systemctl status prometheus
sudo systemctl status grafana-server

# Sur VM1/VM2
sudo systemctl status node_exporter

# Redémarrer Prometheus
sudo systemctl restart prometheus
```

---

## Prochaines étapes

👉 **Passer au fichier `03_metriques_surveillance.md`**

Pour apprendre quelles métriques monitorer et comment les récupérer.

---

## Résumé des ports ouverts

| Service | VM | Port | Accès |
|---------|----|----|--------|
| Prometheus | VM3 | 9090 | Web + API |
| Grafana | VM3 | 3000 | Web |
| Node Exporter | VM1 | 9100 | Prometheus scrape |
| Node Exporter | VM2 | 9100 | Prometheus scrape |

À adapter dans les règles firewall.

---

**Temps estimé réel**
- Installation Prometheus : 30 min
- Installation Grafana : 20 min
- Installation Node Exporter (x2) : 40 min
- Tests & troubleshooting : 30 min
- **Total : ~2h**
