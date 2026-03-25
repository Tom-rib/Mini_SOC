#!/bin/bash

# Script d'installation automatisée de Node Exporter
# Usage: sudo bash install_node_exporter.sh
# Tested on: Rocky Linux 8/9

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Version
NODE_VERSION="1.7.0"
NODE_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz"

echo -e "${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Installation Node Exporter ${NODE_VERSION}       ║${NC}"
echo -e "${YELLOW}║  Rocky Linux - VM source métriques           ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être exécuté en root${NC}"
   exit 1
fi

# ============ PHASE 1 : Préparation ============
echo -e "\n${YELLOW}[PHASE 1] Préparation...${NC}"

dnf install -y wget tar gzip > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Packages installés"

# ============ PHASE 2 : Utilisateur ============
echo -e "\n${YELLOW}[PHASE 2] Création utilisateur...${NC}"

if ! id -u node_exporter > /dev/null 2>&1; then
    useradd --no-create-home --shell /bin/false node_exporter
    echo -e "${GREEN}✓${NC} Utilisateur 'node_exporter' créé"
else
    echo -e "${YELLOW}!${NC} Utilisateur existe déjà"
fi

# ============ PHASE 3 : Téléchargement ============
echo -e "\n${YELLOW}[PHASE 3] Téléchargement...${NC}"

WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"

wget -q "$NODE_URL"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Téléchargement réussi"
else
    echo -e "${RED}✗${NC} Erreur téléchargement"
    exit 1
fi

# ============ PHASE 4 : Installation ============
echo -e "\n${YELLOW}[PHASE 4] Installation...${NC}"

tar xzf "node_exporter-${NODE_VERSION}.linux-amd64.tar.gz"
cd "node_exporter-${NODE_VERSION}.linux-amd64"

cp node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

echo -e "${GREEN}✓${NC} Node Exporter installé"

# ============ PHASE 5 : Service systemd ============
echo -e "\n${YELLOW}[PHASE 5] Création service systemd...${NC}"

cat > /etc/systemd/system/node_exporter.service << 'EOF'
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
EOF

systemctl daemon-reload
echo -e "${GREEN}✓${NC} Service créé"

# ============ PHASE 6 : Démarrage ============
echo -e "\n${YELLOW}[PHASE 6] Démarrage...${NC}"

systemctl start node_exporter
sleep 2

if systemctl is-active --quiet node_exporter; then
    echo -e "${GREEN}✓${NC} Node Exporter démarré"
else
    echo -e "${RED}✗${NC} Erreur au démarrage"
    journalctl -u node_exporter -n 10
    exit 1
fi

systemctl enable node_exporter
echo -e "${GREEN}✓${NC} Auto-start configuré"

# ============ PHASE 7 : Firewall ============
echo -e "\n${YELLOW}[PHASE 7] Firewall...${NC}"

firewall-cmd --permanent --add-port=9100/tcp > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Port 9100 ouvert"

# ============ PHASE 8 : Vérification ============
echo -e "\n${YELLOW}[PHASE 8] Vérifications...${NC}"

if curl -s http://localhost:9100/metrics | grep -q "node_cpu"; then
    echo -e "${GREEN}✓${NC} Métriques disponibles"
else
    echo -e "${RED}✗${NC} Pas de métriques"
    exit 1
fi

# Nettoyer
cd /
rm -rf "$WORK_DIR"

# ============ RÉSUMÉ ============
echo -e "\n${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation réussie !                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}📊 Node Exporter${NC}"
echo -e "  Version: ${NODE_VERSION}"
echo -e "  Port: 9100"
echo -e "  Métriques: http://localhost:9100/metrics"
echo -e "  Statut: ${GREEN}sudo systemctl status node_exporter${NC}"
echo -e "  Logs: ${GREEN}sudo journalctl -u node_exporter -f${NC}"

echo -e "\n${YELLOW}⚠️  ACTIONS REQUISES${NC}"
echo -e "  1. Sur VM3 (Prometheus), ajouter target :"
echo -e "     - job_name: 'ce-serveur'"
echo -e "       static_configs:"
echo -e "         - targets: ['<IP_CE_SERVEUR>:9100']"
echo -e "\n  2. Redémarrer Prometheus:"
echo -e "     ${GREEN}sudo systemctl reload prometheus${NC}"

echo -e "\n✅ Répéter ce script sur VM1 et VM2"
