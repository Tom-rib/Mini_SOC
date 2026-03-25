#!/bin/bash

################################################################################
#                                                                              #
#  MINI SOC - VM1 INSTALLATION SCRIPT                                         #
#  Web Server avec Hardening                                                  #
#                                                                              #
#  Usage: sudo bash vm1_install.sh                                            #
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
echo "║   VM1 - WEB SERVER INSTALLATION                               ║"
echo "║   Mini SOC - Hardened Rocky Linux                             ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ===== 1. SYSTEM UPDATES =====
log_info "Step 1/10 - Updating system..."
dnf update -y > /dev/null 2>&1
dnf install -y wget curl vim nano git > /dev/null 2>&1
log_success "System updated"

# ===== 2. HOSTNAME =====
log_info "Step 2/10 - Setting hostname..."
hostnamectl set-hostname vm1-web
log_success "Hostname set to vm1-web"

# ===== 3. SSH HARDENING =====
log_info "Step 3/10 - Hardening SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

cat > /etc/ssh/sshd_config << 'SSHEOF'
Port 2222
AddressFamily inet
ListenAddress 0.0.0.0

Protocol 2
HostKeys /etc/ssh/ssh_host_rsa_key
HostKeys /etc/ssh/ssh_host_ecdsa_key
HostKeys /etc/ssh/ssh_host_ed25519_key

SyslogFacility AUTH
LogLevel VERBOSE

LoginGraceTime 30s
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 2

PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

UsePAM yes

X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitUserEnvironment no

ClientAliveInterval 300
ClientAliveCountMax 2

Subsystem sftp /usr/lib64/openssh/sftp-server
SSHEOF

systemctl restart sshd > /dev/null 2>&1
systemctl enable sshd > /dev/null 2>&1
log_success "SSH hardened (port 2222, key-only auth)"

# ===== 4. FIREWALL =====
log_info "Step 4/10 - Configuring firewall..."
systemctl start firewalld > /dev/null 2>&1
systemctl enable firewalld > /dev/null 2>&1

firewall-cmd --permanent --add-port=2222/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=80/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=443/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=1514/tcp > /dev/null 2>&1
firewall-cmd --permanent --add-port=1514/udp > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1

log_success "Firewall configured (ports: 2222, 80, 443, 1514)"

# ===== 5. FAIL2BAN =====
log_info "Step 5/10 - Installing Fail2ban..."
dnf install -y fail2ban fail2ban-systemd > /dev/null 2>&1

cat > /etc/fail2ban/jail.d/sshd.local << 'F2BEOF'
[sshd]
enabled = true
port = 2222
logpath = /var/log/secure
maxretry = 5
findtime = 600
bantime = 3600
F2BEOF

systemctl start fail2ban > /dev/null 2>&1
systemctl enable fail2ban > /dev/null 2>&1
log_success "Fail2ban installed (blocks after 5 failed SSH attempts)"

# ===== 6. AUDITD =====
log_info "Step 6/10 - Installing auditd..."
dnf install -y audit audit-libs > /dev/null 2>&1

cat >> /etc/audit/rules.d/audit.rules << 'AUDITEOF'

# SSH logs
-w /var/log/secure -p wa -k ssh_logs

# Sudo commands
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes

# System changes
-w /etc/ssh/sshd_config -p wa -k sshd_config_changes
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes

# Root changes
-w /root/ -p wa -k root_changes

AUDITEOF

systemctl restart auditd > /dev/null 2>&1
systemctl enable auditd > /dev/null 2>&1
log_success "Auditd configured (system audit logging)"

# ===== 7. SELINUX =====
log_info "Step 7/10 - Configuring SELinux..."
sed -i 's/SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
log_success "SELinux set to enforcing (reboot for full effect)"

# ===== 8. NGINX =====
log_info "Step 8/10 - Installing Nginx..."
dnf install -y nginx > /dev/null 2>&1

mkdir -p /var/www/html
cat > /var/www/html/index.html << 'WEBEOF'
<!DOCTYPE html>
<html>
<head>
    <title>VM1 - Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 20px; background: #d4edda; border-radius: 5px; }
        .config { padding: 20px; background: #e2e3e5; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🛡️ VM1 - Hardened Web Server</h1>
    <div class="status">
        <h2>Status: ✅ ONLINE</h2>
        <p>Rocky Linux - Mini SOC Project</p>
    </div>
    <div class="config">
        <h2>Security Configuration:</h2>
        <ul>
            <li>SSH Port: 2222 (key-based auth only)</li>
            <li>Firewall: Active (ports 80, 443, 2222)</li>
            <li>Fail2ban: Enabled (DDoS protection)</li>
            <li>Auditd: Enabled (system logging)</li>
            <li>SELinux: Enforcing</li>
        </ul>
    </div>
</body>
</html>
WEBEOF

systemctl start nginx > /dev/null 2>&1
systemctl enable nginx > /dev/null 2>&1
log_success "Nginx installed and running"

# ===== 9. NODE EXPORTER =====
log_info "Step 9/10 - Installing Prometheus Node Exporter..."
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
log_success "Node Exporter installed (metrics on port 9100)"

# ===== 10. WAZUH AGENT =====
log_info "Step 10/10 - Installing Wazuh Agent..."
dnf install -y https://packages.wazuh.com/4.x/yum/wazuh-agent-4.7.0-1.el9.x86_64.rpm > /dev/null 2>&1
log_success "Wazuh Agent installed"

# ===== FINAL SUMMARY =====
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   ✅ VM1 INSTALLATION COMPLETED SUCCESSFULLY!                  ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 INSTALLATION SUMMARY:"
echo "  ✓ System updated"
echo "  ✓ SSH hardened (port 2222, key-only)"
echo "  ✓ Firewall configured"
echo "  ✓ Fail2ban enabled"
echo "  ✓ Auditd logging enabled"
echo "  ✓ SELinux set to enforcing"
echo "  ✓ Nginx web server installed"
echo "  ✓ Node Exporter installed (port 9100)"
echo "  ✓ Wazuh Agent installed"
echo ""

echo "🔐 SECURITY CONFIGURATION:"
echo "  • SSH Port: 2222"
echo "  • Auth Method: SSH keys only"
echo "  • Root Login: DISABLED"
echo "  • Firewall Ports: 2222, 80, 443, 1514"
echo ""

echo "📊 WEB ACCESS:"
WEB_IP=$(hostname -I | awk '{print $1}')
echo "  • HTTP: http://${WEB_IP}:80"
echo "  • HTTPS: https://${WEB_IP}:443"
echo "  • Metrics: http://${WEB_IP}:9100/metrics"
echo ""

echo "⚠️  NEXT STEPS:"
echo "  1. Create SSH keys: ssh-keygen -t rsa -b 4096"
echo "  2. Copy to VM1: ssh-copy-id -p 2222 admin@${WEB_IP}"
echo "  3. Configure Wazuh Agent with Manager IP"
echo "  4. Update rsyslog SOC_IP in /etc/rsyslog.conf"
echo ""

log_success "Installation complete!"
