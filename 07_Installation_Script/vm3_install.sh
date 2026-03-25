#!/bin/bash

################################################################################
#                                                                              #
#  MINI SOC - VM3 INSTALLATION SCRIPT                                         #
#  Monitoring & Incident Response                                             #
#                                                                              #
#  Usage: sudo bash vm3_install.sh                                            #
#                                                                              #
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (sudo)"
   exit 1
fi

clear

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   VM3 - MONITORING & IR INSTALLATION                           ║"
echo "║   Prometheus + Grafana - Mini SOC Project                      ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ===== 1. SYSTEM UPDATES =====
log_info "Step 1/7 - Updating system..."
dnf update -y > /dev/null 2>&1
dnf install -y wget curl vim nano git > /dev/null 2>&1
log_success "System updated"

# ===== 2. HOSTNAME =====
log_info "Step 2/7 - Setting hostname..."
hostnamectl set-hostname vm3-monitoring
log_success "Hostname set to vm3-monitoring"

# ===== 3. FIREWALL =====
log_info "Step 3/7 - Configuring firewall..."
systemctl start firewalld > /dev/null 2>&1
systemctl enable firewalld > /dev/null 2>&1

firewall-cmd --permanent --add-port=9090/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=3000/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=9100/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=1514/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=1514/udp > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1

log_success "Firewall configured (ports: 9090, 3000, 9100, 1514)"

# ===== 4. INSTALL PROMETHEUS =====
log_info "Step 4/7 - Installing Prometheus..."

useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true

PROM_VERSION="2.48.0"
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz

mkdir -p /etc/prometheus /var/lib/prometheus

cp prometheus-${PROM_VERSION}.linux-amd64/prometheus /usr/local/bin/
cp prometheus-${PROM_VERSION}.linux-amd64/promtool /usr/local/bin/
cp -r prometheus-${PROM_VERSION}.linux-amd64/consoles /etc/prometheus/
cp -r prometheus-${PROM_VERSION}.linux-amd64/console_libraries /etc/prometheus/

rm -rf prometheus-${PROM_VERSION}.linux-amd64*

# Create Prometheus configuration
cat > /etc/prometheus/prometheus.yml << 'PROMEOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'mini-soc'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'vm1_web'
    static_configs:
      - targets: ['192.168.1.100:9100']
        labels:
          server: 'vm1-web'
          role: 'web'

  - job_name: 'vm2_soc'
    static_configs:
      - targets: ['192.168.1.200:9100']
        labels:
          server: 'vm2-soc'
          role: 'soc'

  - job_name: 'vm3_monitoring'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          server: 'vm3-monitoring'
          role: 'monitoring'

PROMEOF

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

cat > /etc/systemd/system/prometheus.service << 'PROMSERVICEEOF'
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
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

Restart=on-failure

[Install]
WantedBy=multi-user.target
PROMSERVICEEOF

systemctl daemon-reload > /dev/null 2>&1
systemctl enable prometheus > /dev/null 2>&1
systemctl start prometheus > /dev/null 2>&1

log_success "Prometheus installed and running (port 9090)"

# ===== 5. INSTALL GRAFANA =====
log_info "Step 5/7 - Installing Grafana..."

dnf install -y https://dl.grafana.com/oss/release/grafana-10.2.0-1.x86_64.rpm > /dev/null 2>&1

systemctl daemon-reload > /dev/null 2>&1
systemctl enable grafana-server > /dev/null 2>&1
systemctl start grafana-server > /dev/null 2>&1

log_success "Grafana installed and running (port 3000)"

# ===== 6. INSTALL NODE EXPORTER =====
log_info "Step 6/7 - Installing Prometheus Node Exporter..."

useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

NODE_VERSION="1.7.0"
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
tar xzf node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_VERSION}.linux-amd64*

cat > /etc/systemd/system/node_exporter.service << 'NODEEOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
NODEEOF

systemctl daemon-reload > /dev/null 2>&1
systemctl start node_exporter > /dev/null 2>&1
systemctl enable node_exporter > /dev/null 2>&1

log_success "Node Exporter installed (port 9100)"

# ===== 7. ADDITIONAL TOOLS =====
log_info "Step 7/7 - Installing Wazuh Agent and Ansible..."

dnf install -y https://packages.wazuh.com/4.x/yum/wazuh-agent-4.7.0-1.el9.x86_64.rpm > /dev/null 2>&1
dnf install -y ansible > /dev/null 2>&1

# Create IR scripts directory
mkdir -p /opt/ir-scripts
chmod 755 /opt/ir-scripts

# Example IR script: Block IP
cat > /opt/ir-scripts/block_ip.sh << 'BLOCKIPEOF'
#!/bin/bash
# Block attacker IP in firewall

IP=$1
if [ -z "$IP" ]; then
    echo "Usage: $0 <IP_ADDRESS>"
    exit 1
fi

echo "[$(date)] Blocking IP: $IP"
sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"$IP\" reject"
sudo firewall-cmd --reload

echo "[$(date)] IP $IP blocked successfully"
BLOCKIPEOF

chmod +x /opt/ir-scripts/block_ip.sh

log_success "Wazuh Agent, Ansible, and IR scripts installed"

# ===== FINAL SUMMARY =====
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   ✅ VM3 INSTALLATION COMPLETED SUCCESSFULLY!                  ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 INSTALLATION SUMMARY:"
echo "  ✓ System updated"
echo "  ✓ Prometheus installed (metrics collection)"
echo "  ✓ Grafana installed (dashboards)"
echo "  ✓ Node Exporter installed"
echo "  ✓ Wazuh Agent installed"
echo "  ✓ Ansible installed"
echo "  ✓ IR scripts directory created"
echo ""

MON_IP=$(hostname -I | awk '{print $1}')

echo "🌐 WEB ACCESS:"
echo "  • Prometheus: http://${MON_IP}:9090"
echo "  • Grafana: http://${MON_IP}:3000"
echo "  • Metrics: http://${MON_IP}:9100/metrics"
echo ""

echo "🔐 DEFAULT CREDENTIALS:"
echo "  • Grafana Username: admin"
echo "  • Grafana Password: admin"
echo ""

echo "📊 METRICS COLLECTION:"
echo "  • VM1 (Web): 192.168.1.100:9100"
echo "  • VM2 (SOC): 192.168.1.200:9100"
echo "  • VM3 (Self): localhost:9100"
echo ""

echo "⚙️ NEXT STEPS:"
echo "  1. ⚠️ CHANGE GRAFANA PASSWORD:"
echo "     Go to http://${MON_IP}:3000 → Settings → Change password"
echo ""
echo "  2. Add Prometheus datasource in Grafana:"
echo "     • Data Sources → Add Prometheus"
echo "     • URL: http://localhost:9090"
echo "     • Click Save"
echo ""
echo "  3. Register Wazuh Agent:"
echo "     • Configure Manager IP: 192.168.1.200"
echo "     • Restart: sudo systemctl restart wazuh-agent"
echo ""
echo "  4. Create dashboards:"
echo "     • Import existing dashboards or create custom ones"
echo "     • Monitor: CPU, RAM, Disk, Network"
echo ""

log_success "Installation complete! Access Grafana at http://${MON_IP}:3000"
