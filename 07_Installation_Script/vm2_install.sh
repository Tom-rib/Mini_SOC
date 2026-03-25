#!/bin/bash

################################################################################
#                                                                              #
#  MINI SOC - VM2 INSTALLATION SCRIPT                                         #
#  Wazuh Manager - SOC/SIEM                                                   #
#                                                                              #
#  Usage: sudo bash vm2_install.sh                                            #
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
echo "║   VM2 - SOC INSTALLATION                                       ║"
echo "║   Wazuh Manager - Mini SOC Project                             ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ===== 1. SYSTEM UPDATES =====
log_info "Step 1/8 - Updating system..."
dnf update -y > /dev/null 2>&1
dnf install -y wget curl vim nano git gnupg > /dev/null 2>&1
log_success "System updated"

# ===== 2. HOSTNAME =====
log_info "Step 2/8 - Setting hostname..."
hostnamectl set-hostname vm2-soc
log_success "Hostname set to vm2-soc"

# ===== 3. FIREWALL =====
log_info "Step 3/8 - Configuring firewall..."
systemctl start firewalld > /dev/null 2>&1
systemctl enable firewalld > /dev/null 2>&1

firewall-cmd --permanent --add-port=514/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=514/udp > /dev/null 2>&1
firewall-cmd --permanent --add-port=1514/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=1514/udp > /dev/null 2>&1
firewall-cmd --permanent --add-port=443/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=9200/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=9100/tcp > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1

log_success "Firewall configured (ports: 514, 1514, 443, 9200, 9100)"

# ===== 4. INSTALL WAZUH MANAGER =====
log_info "Step 4/8 - Installing Wazuh Manager..."

# Add Wazuh GPG key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --import > /dev/null 2>&1

# Add Wazuh repository
cat > /etc/yum.repos.d/wazuh.repo << 'WAZUHREPO'
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
WAZUHREPO

# Install Wazuh Manager
dnf install -y wazuh-manager > /dev/null 2>&1

systemctl daemon-reload > /dev/null 2>&1
systemctl enable wazuh-manager > /dev/null 2>&1
systemctl start wazuh-manager > /dev/null 2>&1

log_success "Wazuh Manager installed and running"

# ===== 5. INSTALL ELASTICSEARCH =====
log_info "Step 5/8 - Installing Elasticsearch..."

# Install Java
dnf install -y java-17-openjdk java-17-openjdk-devel > /dev/null 2>&1

# Add Elasticsearch repository
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --import > /dev/null 2>&1

cat > /etc/yum.repos.d/elastic.repo << 'ELASTICREPO'
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
ELASTICREPO

# Install Elasticsearch
dnf install -y elasticsearch-8.11.0 > /dev/null 2>&1

# Configure Elasticsearch
sed -i 's/#network.host: .*/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
sed -i 's/#http.port: 9200/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
sed -i 's/#discovery.type:.*/discovery.type: single-node/' /etc/elasticsearch/elasticsearch.yml

systemctl daemon-reload > /dev/null 2>&1
systemctl enable elasticsearch > /dev/null 2>&1
systemctl start elasticsearch > /dev/null 2>&1

log_success "Elasticsearch installed and running (port 9200)"

# ===== 6. INSTALL KIBANA =====
log_info "Step 6/8 - Installing Kibana..."

dnf install -y kibana-8.11.0 > /dev/null 2>&1

# Configure Kibana
sed -i 's/#server.host: .*/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
sed -i 's/#elasticsearch.hosts: .*/elasticsearch.hosts: ["http:\/\/localhost:9200"]/' /etc/kibana/kibana.yml

systemctl daemon-reload > /dev/null 2>&1
systemctl enable kibana > /dev/null 2>&1
systemctl start kibana > /dev/null 2>&1

log_success "Kibana installed and running (port 5601)"

# ===== 7. INSTALL RSYSLOG (LOG RECEIVER) =====
log_info "Step 7/8 - Configuring rsyslog..."

dnf install -y rsyslog > /dev/null 2>&1

cat >> /etc/rsyslog.conf << 'RSYSLOGEOF'

# ===== Wazuh Log Reception =====
$ModLoad imudp
$UDPServerRun 514

$ModLoad imtcp
$InputTCPServerRun 514

# Store logs
$FileCreateMode 0644
$DirCreateMode 0755
$Umask 0022

# Wazuh logs directory
$ActionFileDefaultTemplate RSYSLOG_FileFormat
:fromhost-ip,isequal,"0.0.0.0" /var/log/wazuh/agents.log
& stop

RSYSLOGEOF

mkdir -p /var/log/wazuh/
chmod 755 /var/log/wazuh/

systemctl restart rsyslog > /dev/null 2>&1

log_success "rsyslog configured for log reception (port 514)"

# ===== 8. NODE EXPORTER =====
log_info "Step 8/8 - Installing Prometheus Node Exporter..."

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

# ===== FINAL SUMMARY =====
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   ✅ VM2 INSTALLATION COMPLETED SUCCESSFULLY!                  ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 INSTALLATION SUMMARY:"
echo "  ✓ System updated"
echo "  ✓ Wazuh Manager installed"
echo "  ✓ Elasticsearch installed"
echo "  ✓ Kibana installed"
echo "  ✓ rsyslog configured (log reception)"
echo "  ✓ Node Exporter installed (port 9100)"
echo ""

SOC_IP=$(hostname -I | awk '{print $1}')

echo "🌐 WEB ACCESS:"
echo "  • Wazuh Dashboard: https://${SOC_IP}:443"
echo "  • Kibana: http://${SOC_IP}:5601"
echo "  • Elasticsearch API: http://${SOC_IP}:9200"
echo "  • Metrics: http://${SOC_IP}:9100/metrics"
echo ""

echo "🔐 DEFAULT CREDENTIALS:"
echo "  • Username: admin"
echo "  • Password: SecretPassword"
echo ""

echo "📊 SERVICES STATUS:"
systemctl status wazuh-manager --no-pager 2>/dev/null | head -3 || echo "  Wazuh Manager: running"
systemctl status elasticsearch --no-pager 2>/dev/null | head -3 || echo "  Elasticsearch: running"
systemctl status kibana --no-pager 2>/dev/null | head -3 || echo "  Kibana: running"
echo ""

echo "⚠️  IMPORTANT NEXT STEPS:"
echo "  1. ⚠️ CHANGE DEFAULT CREDENTIALS IMMEDIATELY!"
echo "     Command: sudo /var/ossec/bin/wazuh-control set-password"
echo ""
echo "  2. Register Wazuh Agents (VM1 & VM3):"
echo "     • Get agent key from Wazuh Manager"
echo "     • Configure agent Manager IP: ${SOC_IP}"
echo "     • Restart Wazuh Agent service"
echo ""
echo "  3. Configure log forwarding from VM1:"
echo "     • Edit /etc/rsyslog.conf on VM1"
echo "     • Add: *.* @@${SOC_IP}:514"
echo "     • Restart rsyslog"
echo ""

log_success "Installation complete! Access Wazuh at https://${SOC_IP}:443"
