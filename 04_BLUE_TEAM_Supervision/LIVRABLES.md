# 🎯 Livrables - Rôle 3 : Supervision & Incident Response

**Objectif** : Documenter tous les livrables du rôle 3 (supervision + incident response).

**Date** : [à compléter]  
**Responsable** : [Nom du rôle 3]  
**VM associée** : Monitoring & Supervision

---

## 📋 Checklist des livrables

Cocher ✓ chaque élément au fur et à mesure :

### Installation & Configuration

- [ ] **Prometheus installé** sur VM Monitoring
  - Port 9090 accessible
  - Fichier `/etc/prometheus/prometheus.yml` configuré
  - Service `prometheus` actif et en autostart
  
- [ ] **Grafana installé** sur VM Monitoring
  - Port 3000 accessible
  - Utilisateur admin créé
  - Data source Prometheus configurée
  - Service `grafana-server` actif et en autostart

- [ ] **Node Exporter installé** sur VM1 (Serveur Web)
  - Port 9100 accessible
  - Métriques système remontées
  - Service `node_exporter` actif et en autostart

- [ ] **Node Exporter installé** sur VM2 (SOC/Logs)
  - Port 9100 accessible
  - Métriques système remontées
  - Service `node_exporter` actif et en autostart

- [ ] **Wazuh Agent configuré** sur VM1
  - Connecté au manager Wazuh
  - Logs remontés

- [ ] **Wazuh Agent configuré** sur VM2
  - Connecté au manager Wazuh
  - Logs remontés

### Dashboards Grafana

- [ ] **Dashboard "Système Global"** créé
  - Vue d'ensemble CPU/RAM/Disk de toutes les VMs
  - Export JSON sauvegardé

- [ ] **Dashboard "VM1 - Serveur Web"** créé
  - CPU, RAM, Disk (détail)
  - Trafic réseau
  - Export JSON sauvegardé

- [ ] **Dashboard "VM2 - SOC/Logs"** créé
  - CPU, RAM, Disk (détail)
  - Espace disque pour logs
  - Export JSON sauvegardé

- [ ] **Dashboard "Wazuh Intégration"** créé
  - Alertes temps réel
  - Graphiques attaques détectées
  - Export JSON sauvegardé

### Alertes Prometheus

- [ ] **Alerte "High CPU"** configurée
  - Seuil : > 80% pendant 5 min
  - Action : mail ou webhook

- [ ] **Alerte "High Memory"** configurée
  - Seuil : > 85% pendant 2 min
  - Action : mail ou webhook

- [ ] **Alerte "Service Down"** configurée
  - SSH, Nginx, Wazuh surveiller
  - Action : réaction immédiate

- [ ] **Alerte "Disk Space Critical"** configurée
  - Seuil : < 10% libre
  - Action : notification

### Incident Response

- [ ] **Playbook Ansible "Block SSH Brute Force"** créé
  - Fichier : `playbooks/block_ssh_bruteforce.yml`
  - Ajoute IP à firewall
  - Réinitialise fail2ban

- [ ] **Playbook Ansible "Kill Suspicious Process"** créé
  - Fichier : `playbooks/kill_process.yml`
  - Arrête processus par PID
  - Enregistre l'action

- [ ] **Playbook Ansible "Isolate VM"** créé
  - Fichier : `playbooks/isolate_vm.yml`
  - Arrête network interface
  - Log l'action

- [ ] **Script Bash "Response SSH Brute"** créé
  - Fichier : `scripts/response_ssh_bruteforce.sh`
  - Exécutable et commenté

- [ ] **Script Bash "Monitor Services"** créé
  - Fichier : `scripts/monitor_services.sh`
  - Vérifie SSH, Nginx, Wazuh
  - Envoie alertes

- [ ] **Script Bash "Auto Response"** créé
  - Fichier : `scripts/auto_response.sh`
  - Lance playbooks automatiquement

### Documentation

- [ ] **Procédures IR documentées**
  - Fichier : `IR_procedures.md`
  - Au moins 3 procédures détaillées

- [ ] **Rapport post-incident** créé
  - Fichier : `report_template.md`
  - Template pour futures analyses

---

## 📊 Dashboards Grafana (Exports JSON)

### Dashboard 1: Système Global

```json
{
  "dashboard": {
    "title": "Système Global - Mini SOC",
    "tags": ["system", "overview"],
    "timezone": "UTC",
    "panels": [
      {
        "title": "CPU Usage - All VMs",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Memory Usage - All VMs",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Disk Usage - All VMs",
        "targets": [
          {
            "expr": "100 - (node_filesystem_avail_bytes{fstype!=\"tmpfs\"} / node_filesystem_size_bytes) * 100"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Network Traffic - Inbound",
        "targets": [
          {
            "expr": "rate(node_network_receive_bytes_total[5m])"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

### Dashboard 2: VM1 - Serveur Web (Détail)

```json
{
  "dashboard": {
    "title": "VM1 - Serveur Web Rocky Linux",
    "tags": ["vm1", "webserver"],
    "panels": [
      {
        "title": "CPU Usage (Détail)",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{instance=\"vm1:9100\",mode=\"idle\"}[5m])) * 100)"
          }
        ]
      },
      {
        "title": "Memory Usage (Détail)",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes{instance=\"vm1:9100\"} / node_memory_MemTotal_bytes{instance=\"vm1:9100\"})) * 100"
          }
        ]
      },
      {
        "title": "Nginx Connections",
        "targets": [
          {
            "expr": "nginx_connections_active{instance=\"vm1:9100\"}"
          }
        ]
      },
      {
        "title": "Disk Space",
        "targets": [
          {
            "expr": "100 - (node_filesystem_avail_bytes{instance=\"vm1:9100\",fstype=\"ext4\"} / node_filesystem_size_bytes) * 100"
          }
        ]
      },
      {
        "title": "System Load Average",
        "targets": [
          {
            "expr": "node_load1{instance=\"vm1:9100\"}"
          }
        ]
      }
    ]
  }
}
```

### Dashboard 3: VM2 - SOC/Logs (Détail)

```json
{
  "dashboard": {
    "title": "VM2 - SOC/Logs Rocky Linux",
    "tags": ["vm2", "soc", "logs"],
    "panels": [
      {
        "title": "CPU Usage (Détail)",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{instance=\"vm2:9100\",mode=\"idle\"}[5m])) * 100)"
          }
        ]
      },
      {
        "title": "Memory Usage (Détail)",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes{instance=\"vm2:9100\"} / node_memory_MemTotal_bytes{instance=\"vm2:9100\"})) * 100"
          }
        ]
      },
      {
        "title": "Disk Space - Logs Directory",
        "targets": [
          {
            "expr": "100 - (node_filesystem_avail_bytes{instance=\"vm2:9100\",mountpoint=\"/var\"} / node_filesystem_size_bytes{mountpoint=\"/var\"}) * 100"
          }
        ]
      },
      {
        "title": "Elasticsearch Memory",
        "targets": [
          {
            "expr": "elasticsearch_jvm_memory_used_bytes{instance=\"vm2:9100\"}"
          }
        ]
      },
      {
        "title": "Wazuh Manager Status",
        "targets": [
          {
            "expr": "wazuh_manager_status{instance=\"vm2:9100\"}"
          }
        ]
      }
    ]
  }
}
```

### Dashboard 4: Wazuh Intégration (Alertes & Attaques)

```json
{
  "dashboard": {
    "title": "Wazuh - Détection & Alertes",
    "tags": ["wazuh", "security", "incidents"],
    "panels": [
      {
        "title": "Alertes Temps Réel",
        "targets": [
          {
            "expr": "increase(wazuh_alerts_total[5m])"
          }
        ],
        "type": "stat"
      },
      {
        "title": "Attaques SSH Brute Force Détectées",
        "targets": [
          {
            "expr": "increase(wazuh_rule_sshd_brute_force[1h])"
          }
        ]
      },
      {
        "title": "Tentatives Escalade Privilèges",
        "targets": [
          {
            "expr": "increase(wazuh_rule_privilege_escalation[1h])"
          }
        ]
      },
      {
        "title": "Fichiers Malveillants Détectés",
        "targets": [
          {
            "expr": "increase(wazuh_rule_malware_detected[1h])"
          }
        ]
      },
      {
        "title": "Top 10 IPs Attaquantes",
        "targets": [
          {
            "expr": "topk(10, sum by (src_ip) (increase(wazuh_alerts_total[1h])))"
          }
        ]
      }
    ]
  }
}
```

---

## 🎯 Playbooks Ansible

### Playbook 1: Block SSH Brute Force

**Fichier** : `playbooks/block_ssh_bruteforce.yml`

```yaml
---
# Playbook: Block SSH Brute Force Attack
# Objectif: Bloquer une IP attaquante immédiatement au firewall
# Utilisation: ansible-playbook playbooks/block_ssh_bruteforce.yml -e "attacker_ip=192.168.1.100"

- name: Block SSH Brute Force Attack
  hosts: all
  become: yes
  gather_facts: yes
  
  vars:
    attacker_ip: "{{ attacker_ip | default('0.0.0.0') }}"
    firewall_zone: "drop"
    log_file: "/var/log/incident_response.log"
  
  tasks:
    - name: "Verify attacker IP provided"
      assert:
        that:
          - attacker_ip != '0.0.0.0'
        fail_msg: "attacker_ip must be provided: ansible-playbook ... -e 'attacker_ip=X.X.X.X'"

    - name: "Log incident"
      lineinfile:
        path: "{{ log_file }}"
        line: "[$(date)] SSH Brute Force - Blocking IP {{ attacker_ip }}"
        create: yes

    - name: "Add firewall rule to drop attacker IP"
      firewalld:
        rich_rule: "rule family='ipv4' source address='{{ attacker_ip }}' reject"
        state: enabled
        zone: "{{ firewall_zone }}"
        permanent: yes
      notify: reload firewall

    - name: "Reset fail2ban jail for SSH"
      command: "fail2ban-client set sshd unbanip {{ attacker_ip }}"
      ignore_errors: yes

    - name: "Verify rule added"
      shell: "firewall-cmd --list-all"
      register: firewall_status
      changed_when: false

    - name: "Display firewall status"
      debug:
        msg: "{{ firewall_status.stdout }}"

  handlers:
    - name: reload firewall
      service:
        name: firewalld
        state: reloaded

  post_tasks:
    - name: "Generate alert email"
      debug:
        msg: "ALERT: IP {{ attacker_ip }} has been blocked due to SSH brute force attempt"
```

### Playbook 2: Kill Suspicious Process

**Fichier** : `playbooks/kill_process.yml`

```yaml
---
# Playbook: Kill Suspicious Process
# Objectif: Arrêter un processus malveillant et enregistrer l'action
# Utilisation: ansible-playbook playbooks/kill_process.yml -e "process_pid=1234"

- name: Kill Suspicious Process
  hosts: all
  become: yes
  gather_facts: yes

  vars:
    process_pid: "{{ process_pid | default('0') }}"
    log_file: "/var/log/incident_response.log"
    forensics_dir: "/var/forensics"

  tasks:
    - name: "Verify PID provided"
      assert:
        that:
          - process_pid != '0'
        fail_msg: "process_pid must be provided: ansible-playbook ... -e 'process_pid=XXXX'"

    - name: "Get process details before killing"
      shell: "ps -p {{ process_pid }} -o pid,user,cmd --no-headers"
      register: process_info
      ignore_errors: yes
      changed_when: false

    - name: "Display process details"
      debug:
        msg: "Process info: {{ process_info.stdout }}"

    - name: "Create forensics directory if not exist"
      file:
        path: "{{ forensics_dir }}"
        state: directory
        mode: '0755'

    - name: "Archive process memory dump"
      shell: "gcore -o {{ forensics_dir }}/core_{{ process_pid }} {{ process_pid }} 2>/dev/null || true"
      ignore_errors: yes

    - name: "Log action before killing process"
      lineinfile:
        path: "{{ log_file }}"
        line: "[$(date)] INCIDENT RESPONSE - Killing PID {{ process_pid }} - {{ process_info.stdout }}"
        create: yes

    - name: "Kill process"
      shell: "kill -9 {{ process_pid }}"
      ignore_errors: yes

    - name: "Verify process is killed"
      shell: "ps -p {{ process_pid }} && echo 'FAILED' || echo 'SUCCESS'"
      register: kill_result
      changed_when: false

    - name: "Log result"
      lineinfile:
        path: "{{ log_file }}"
        line: "[$(date)] Process kill result: {{ kill_result.stdout }}"

    - name: "Generate alert"
      debug:
        msg: "ALERT: Process PID {{ process_pid }} has been terminated"
```

### Playbook 3: Isolate VM Network

**Fichier** : `playbooks/isolate_vm.yml`

```yaml
---
# Playbook: Isolate VM Network
# Objectif: Isoler une VM en désactivant son interface réseau
# Utilisation: ansible-playbook playbooks/isolate_vm.yml -e "network_interface=eth0"

- name: Isolate VM Network
  hosts: all
  become: yes
  gather_facts: yes

  vars:
    network_interface: "{{ network_interface | default('eth0') }}"
    log_file: "/var/log/incident_response.log"

  tasks:
    - name: "Get current network configuration"
      shell: "ip addr show {{ network_interface }}"
      register: network_info
      changed_when: false
      ignore_errors: yes

    - name: "Display network info"
      debug:
        msg: "{{ network_info.stdout }}"

    - name: "Log isolation action"
      lineinfile:
        path: "{{ log_file }}"
        line: "[$(date)] ISOLATION - Disabling interface {{ network_interface }}"
        create: yes

    - name: "Disable network interface"
      shell: "ip link set {{ network_interface }} down"
      ignore_errors: yes

    - name: "Verify interface is down"
      shell: "ip link show {{ network_interface }} | grep DOWN"
      register: verify_down
      changed_when: false
      ignore_errors: yes

    - name: "Log isolation result"
      lineinfile:
        path: "{{ log_file }}"
        line: "[$(date)] Interface {{ network_interface }} isolated - {{ verify_down.stdout | default('SUCCESS') }}"

    - name: "Alert - VM Isolated"
      debug:
        msg: "ALERT: VM {{ inventory_hostname }} has been isolated from network"

  post_tasks:
    - name: "Forensics note"
      lineinfile:
        path: "{{ log_file }}"
        line: "[$(date)] NOTE: VM isolated for forensics investigation. Manual action required to restore."
```

---

## 🔧 Scripts Bash

### Script 1: Monitor Services

**Fichier** : `scripts/monitor_services.sh`

```bash
#!/bin/bash
#
# Script: Monitor Critical Services
# Objectif: Vérifier l'état des services critiques et générer des alertes
# Utilisation: ./monitor_services.sh
# Planification: Ajouter à crontab pour exécution périodique
#

set -e

# Configuration
LOG_FILE="/var/log/monitor_services.log"
ALERT_FILE="/var/log/alerts.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonctions
log_message() {
    echo "[${TIMESTAMP}] $1" | tee -a "${LOG_FILE}"
}

alert() {
    echo "[${TIMESTAMP}] ⚠️  ALERT: $1" | tee -a "${ALERT_FILE}"
}

check_service() {
    local service_name=$1
    
    if systemctl is-active --quiet "${service_name}"; then
        echo -e "${GREEN}✓${NC} ${service_name}: RUNNING"
        log_message "✓ ${service_name}: RUNNING"
        return 0
    else
        echo -e "${RED}✗${NC} ${service_name}: STOPPED"
        alert "${service_name} is NOT RUNNING"
        return 1
    fi
}

check_port() {
    local port=$1
    local service_name=$2
    
    if netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
        echo -e "${GREEN}✓${NC} ${service_name} (Port ${port}): LISTENING"
        log_message "✓ ${service_name} listening on port ${port}"
        return 0
    else
        echo -e "${RED}✗${NC} ${service_name} (Port ${port}): NOT LISTENING"
        alert "${service_name} not listening on port ${port}"
        return 1
    fi
}

# Main monitoring
echo "=========================================="
echo "Service Monitoring Report - ${TIMESTAMP}"
echo "=========================================="
echo ""

services=("sshd" "nginx" "wazuh-agent" "prometheus" "grafana-server")
failed_count=0

for service in "${services[@]}"; do
    if ! check_service "${service}"; then
        ((failed_count++))
    fi
done

echo ""
echo "=========================================="
echo "Port Listening Checks"
echo "=========================================="
echo ""

# Check key ports
check_port 22 "SSH"
check_port 80 "HTTP"
check_port 443 "HTTPS"
check_port 9100 "Node Exporter"
check_port 9090 "Prometheus"
check_port 3000 "Grafana"

echo ""
echo "=========================================="

if [ ${failed_count} -gt 0 ]; then
    echo -e "${RED}❌ ${failed_count} service(s) DOWN${NC}"
    exit 1
else
    echo -e "${GREEN}✓ All services OK${NC}"
    exit 0
fi
```

### Script 2: Auto Response to SSH Brute Force

**Fichier** : `scripts/auto_response_ssh.sh`

```bash
#!/bin/bash
#
# Script: Automatic Response to SSH Brute Force
# Objectif: Détecter et réagir automatiquement aux tentatives SSH brute force
# Utilisation: ./auto_response_ssh.sh
# Note: À exécuter en tant que root
#

set -e

# Configuration
LOG_FILE="/var/log/ssh_response.log"
FAIL2BAN_LOG="/var/log/fail2ban.log"
THRESHOLD=5  # Nombre d'IPs à bloquer simultanement avant alerte haute
ANSIBLE_PLAYBOOK="/opt/ansible/playbooks/block_ssh_bruteforce.yml"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log_action() {
    echo "[${TIMESTAMP}] $1" >> "${LOG_FILE}"
}

# Récupérer les IPs bloquées par fail2ban
get_blocked_ips() {
    fail2ban-client status sshd | grep "Banned IP list" | awk '{print $NF}' | tr ',' '\n' | sed 's/^ *//;s/ *$//'
}

# Bloquer une IP via firewall
block_ip() {
    local ip=$1
    
    log_action "Blocking IP: ${ip}"
    
    # Utiliser firewall-cmd pour bloquer
    firewall-cmd --add-rich-rule="rule family='ipv4' source address='${ip}' reject" --permanent
    firewall-cmd --reload
    
    echo "IP ${ip} blocked at $(date)" >> "${LOG_FILE}"
}

# Déclencher Ansible playbook pour riposte avancée
trigger_ansible_response() {
    local ip=$1
    
    if [ -f "${ANSIBLE_PLAYBOOK}" ]; then
        log_action "Triggering Ansible playbook for IP: ${ip}"
        ansible-playbook "${ANSIBLE_PLAYBOOK}" -e "attacker_ip=${ip}" >> "${LOG_FILE}" 2>&1 || true
    fi
}

# Main
echo "[${TIMESTAMP}] Starting SSH Brute Force Auto Response" >> "${LOG_FILE}"

blocked_ips=$(get_blocked_ips)
blocked_count=$(echo "${blocked_ips}" | wc -w)

if [ ${blocked_count} -gt 0 ]; then
    log_action "Found ${blocked_count} IPs blocked by fail2ban"
    
    while IFS= read -r ip; do
        if [ -n "${ip}" ]; then
            log_action "Processing blocked IP: ${ip}"
            block_ip "${ip}"
            
            # Si seuil atteint, trigger riposte avancée
            if [ ${blocked_count} -ge ${THRESHOLD} ]; then
                trigger_ansible_response "${ip}"
            fi
        fi
    done <<< "${blocked_ips}"
    
    log_action "Auto response completed - ${blocked_count} IPs processed"
else
    log_action "No blocked IPs detected"
fi

exit 0
```

### Script 3: Incident Response Report Generator

**Fichier** : `scripts/generate_incident_report.sh`

```bash
#!/bin/bash
#
# Script: Generate Incident Response Report
# Objectif: Générer un rapport détaillé d'incident
# Utilisation: ./generate_incident_report.sh [incident_id]
#

set -e

INCIDENT_ID=${1:-"INC-$(date +%Y%m%d-%H%M%S)"}
REPORT_DIR="/var/incidents"
REPORT_FILE="${REPORT_DIR}/${INCIDENT_ID}_report.md"

mkdir -p "${REPORT_DIR}"

# Récupérer les données
TIMESTAMP=$(date)
BLOCKED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP list" || echo "None")
RECENT_ALERTS=$(tail -20 /var/log/alerts.log 2>/dev/null || echo "No alerts logged")
SYSTEM_STATUS=$(systemctl status sshd nginx wazuh-agent 2>&1 || echo "Status unavailable")
FIREWALL_RULES=$(firewall-cmd --list-all 2>/dev/null || echo "Firewall info unavailable")

# Générer le rapport
cat > "${REPORT_FILE}" << EOF
# Incident Response Report

**Incident ID**: ${INCIDENT_ID}  
**Generated**: ${TIMESTAMP}  
**Reporter**: Auto-generated

---

## 🔴 Incident Summary

Automatic incident response triggered.

---

## 📊 System Status at Time of Incident

\`\`\`
${SYSTEM_STATUS}
\`\`\`

---

## 🚫 Blocked IPs

\`\`\`
${BLOCKED_IPS}
\`\`\`

---

## ⚠️ Recent Alerts (Last 20)

\`\`\`
${RECENT_ALERTS}
\`\`\`

---

## 🛡️ Firewall Rules in Effect

\`\`\`
${FIREWALL_RULES}
\`\`\`

---

## 📝 Response Actions Taken

- [ ] IPs blocked at firewall
- [ ] Playbooks executed
- [ ] Alerts sent
- [ ] Investigation completed

---

## 🔍 Recommendations

1. Analyze attacker patterns
2. Review authentication logs
3. Consider additional hardening
4. Update firewall rules permanently

---

**Report saved to**: ${REPORT_FILE}
EOF

echo "✓ Incident report generated: ${REPORT_FILE}"
cat "${REPORT_FILE}"

exit 0
```

---

## 📖 Fichiers de configuration

### Prometheus Config pour alertes

**Fichier** : `prometheus/alert_rules.yml`

```yaml
groups:
  - name: system_alerts
    interval: 30s
    rules:
      # High CPU Usage
      - alert: HighCPUUsage
        expr: 'node_load5 > 4'
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
          description: "CPU load is {{ $value }} on {{ $labels.instance }}"

      # High Memory Usage
      - alert: HighMemoryUsage
        expr: '(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.85'
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High Memory on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"

      # Disk Space Critical
      - alert: DiskSpaceCritical
        expr: '(node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.1'
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space critical on {{ $labels.instance }}"
          description: "Only {{ $value | humanizePercentage }} disk space remaining"

      # Service Down
      - alert: ServiceDown
        expr: 'up == 0'
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "Service {{ $labels.instance }} has been unreachable for 1 minute"
```

---

## ✅ Résumé des livrables

| Élément | Statut | Fichier |
|---------|--------|---------|
| Prometheus + Grafana | À tester | `/etc/prometheus/` |
| Dashboard System Global | JSON fourni | `dashboards/system_global.json` |
| Dashboard VM1 | JSON fourni | `dashboards/vm1_webserver.json` |
| Dashboard VM2 | JSON fourni | `dashboards/vm2_soc.json` |
| Dashboard Wazuh | JSON fourni | `dashboards/wazuh_integration.json` |
| Playbook Block SSH | YAML fourni | `playbooks/block_ssh_bruteforce.yml` |
| Playbook Kill Process | YAML fourni | `playbooks/kill_process.yml` |
| Playbook Isolate VM | YAML fourni | `playbooks/isolate_vm.yml` |
| Script Monitor | Bash fourni | `scripts/monitor_services.sh` |
| Script Auto Response | Bash fourni | `scripts/auto_response_ssh.sh` |
| Script Incident Report | Bash fourni | `scripts/generate_incident_report.sh` |
| Alert Rules | YAML fourni | `prometheus/alert_rules.yml` |

---

## 📌 Prochaine étape

→ Voir `tests_verification.md` pour valider chaque livrable
