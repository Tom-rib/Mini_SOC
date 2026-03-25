#!/bin/bash

# Script d'installation automatisée de Prometheus
# Usage: sudo bash install_prometheus.sh
# Tested on: Rocky Linux 8/9

set -e

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Versions
PROMETHEUS_VERSION="2.48.1"
PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

echo -e "${YELLOW}╔════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Installation Prometheus ${PROMETHEUS_VERSION}           ║${NC}"
echo -e "${YELLOW}║  Rocky Linux - Système supervisé              ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════╝${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être exécuté en root${NC}"
   exit 1
fi

# ============ PHASE 1 : Préparation ============
echo -e "\n${YELLOW}[PHASE 1] Préparation du système...${NC}"

# Update système
dnf update -y > /dev/null 2>&1
dnf install -y wget curl tar gzip vim > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Système à jour"

# ============ PHASE 2 : Créer utilisateurs ============
echo -e "\n${YELLOW}[PHASE 2] Création des utilisateurs...${NC}"

# Créer utilisateur prometheus
if ! id -u prometheus > /dev/null 2>&1; then
    useradd --no-create-home --shell /bin/false prometheus
    echo -e "${GREEN}✓${NC} Utilisateur 'prometheus' créé"
else
    echo -e "${YELLOW}!${NC} Utilisateur 'prometheus' existe déjà"
fi

# ============ PHASE 3 : Télécharger et installer ============
echo -e "\n${YELLOW}[PHASE 3] Téléchargement Prometheus...${NC}"

WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"

echo "  Téléchargement : ${PROMETHEUS_URL}"
wget -q "$PROMETHEUS_URL"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Téléchargement réussi"
else
    echo -e "${RED}✗${NC} Erreur téléchargement"
    exit 1
fi

echo "  Extraction..."
tar xzf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
cd "prometheus-${PROMETHEUS_VERSION}.linux-amd64"

echo -e "${GREEN}✓${NC} Prometheus extrait"

# ============ PHASE 4 : Placement fichiers ============
echo -e "\n${YELLOW}[PHASE 4] Placement des fichiers...${NC}"

# Créer répertoires
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Copier binaires
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/
chmod +x /usr/local/bin/prometheus
chmod +x /usr/local/bin/promtool

echo -e "${GREEN}✓${NC} Binaires installés"

# ============ PHASE 5 : Configuration ============
echo -e "\n${YELLOW}[PHASE 5] Configuration Prometheus...${NC}"

# Créer config par défaut
cat > /etc/prometheus/prometheus.yml << 'EOF'
# Prometheus configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'rocky-soc'

tsdb:
  path: /var/lib/prometheus/

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'vm1-web'
    static_configs:
      - targets: ['10.0.0.5:9100']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'VM1-web'

  - job_name: 'vm2-soc'
    static_configs:
      - targets: ['10.0.0.6:9100']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'VM2-soc'
EOF

echo -e "${GREEN}✓${NC} Configuration par défaut créée"
echo "  ATTENTION : Vérifier et adapter les IPs dans /etc/prometheus/prometheus.yml"

# ============ PHASE 6 : Permissions ============
echo -e "\n${YELLOW}[PHASE 6] Configuration des permissions...${NC}"

chown -R prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /var/lib/prometheus
chmod 755 /var/lib/prometheus

echo -e "${GREEN}✓${NC} Permissions configurées"

# ============ PHASE 7 : Service systemd ============
echo -e "\n${YELLOW}[PHASE 7] Création du service systemd...${NC}"

cat > /etc/systemd/system/prometheus.service << 'EOF'
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

StandardOutput=journal
StandardError=journal
SyslogIdentifier=prometheus

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo -e "${GREEN}✓${NC} Service systemd créé"

# ============ PHASE 8 : Démarrage ============
echo -e "\n${YELLOW}[PHASE 8] Démarrage du service...${NC}"

systemctl start prometheus
sleep 2

if systemctl is-active --quiet prometheus; then
    echo -e "${GREEN}✓${NC} Prometheus démarré avec succès"
else
    echo -e "${RED}✗${NC} Erreur au démarrage"
    journalctl -u prometheus -n 10
    exit 1
fi

systemctl enable prometheus
echo -e "${GREEN}✓${NC} Auto-start configuré au boot"

# ============ PHASE 9 : Firewall ============
echo -e "\n${YELLOW}[PHASE 9] Configuration firewall...${NC}"

firewall-cmd --permanent --add-port=9090/tcp > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Port 9090 ouvert"

# ============ PHASE 10 : Vérification ============
echo -e "\n${YELLOW}[PHASE 10] Vérifications...${NC}"

# Test local
if curl -s http://localhost:9090 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Prometheus répond sur port 9090"
else
    echo -e "${RED}✗${NC} Prometheus ne répond pas"
    exit 1
fi

# Nettoyer temp
cd /
rm -rf "$WORK_DIR"

# ============ RÉSUMÉ ============
echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation réussie !                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}📊 Prometheus${NC}"
echo -e "  Version: ${PROMETHEUS_VERSION}"
echo -e "  Accès: http://<IP_VM3>:9090"
echo -e "  Config: /etc/prometheus/prometheus.yml"
echo -e "  Données: /var/lib/prometheus/"
echo -e "  Logs: ${GREEN}sudo journalctl -u prometheus -f${NC}"
echo -e "  Statut: ${GREEN}sudo systemctl status prometheus${NC}"

echo -e "\n${YELLOW}⚠️  ACTIONS REQUISES${NC}"
echo -e "  1. Adapter /etc/prometheus/prometheus.yml avec bonnes IPs"
echo -e "  2. Installer Node Exporter sur VM1 et VM2"
echo -e "  3. Redémarrer Prometheus:"
echo -e "     ${GREEN}sudo systemctl reload prometheus${NC}"

echo -e "\n${YELLOW}✅ Prochaine étape${NC}"
echo -e "  Installer Grafana:"
echo -e "  ${GREEN}sudo bash install_grafana.sh${NC}"
