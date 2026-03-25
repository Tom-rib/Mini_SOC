# ✅ Tests & Vérification - Supervision & Incident Response

**Objectif** : Valider que tous les livrables du Rôle 3 fonctionnent correctement.

**Prérequis** : 
- VM Monitoring configurée
- Prometheus et Grafana installés
- Node Exporter sur VM1 et VM2
- Ansible configuré
- Accès root sur les VMs

---

## 📋 Checklist des Tests

- [ ] Test 1 : Grafana accessible et configuration validée
- [ ] Test 2 : Métriques Prometheus reçues
- [ ] Test 3 : Alertes déclenchées correctement
- [ ] Test 4 : Playbook Ansible fonctionne
- [ ] Test 5 : Scripts bash exécutables et corrects

---

## 🧪 Test 1 : Grafana Accessible & Configuré

### Objectif
Vérifier que Grafana est en ligne, que la data source Prometheus est correctement configurée, et qu'on peut accéder aux dashboards.

### Étapes

#### 1.1 - Vérifier que le service Grafana s'exécute

```bash
systemctl status grafana-server
```

**Output attendu** :
```
● grafana-server.service - Grafana instance
   Loaded: loaded (/usr/lib/systemd/system/grafana-server.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-01-12 10:30:00 CET; 2h 45min ago
```

**✓ Critère de succès** : `Active: active (running)`

---

#### 1.2 - Vérifier le port d'écoute

```bash
netstat -tlnp | grep 3000
```

**Output attendu** :
```
tcp        0      0 0.0.0.0:3000            0.0.0.0:*               LISTEN      2456/grafana-server
```

**✓ Critère de succès** : Grafana écoute sur le port 3000

---

#### 1.3 - Accéder à l'interface Web

Sur votre machine locale (depuis la machine hôte) :

```bash
curl -s http://<IP_VM_MONITORING>:3000 | head -20
```

**Output attendu** :
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Grafana</title>
    ...
  </head>
  <body>
```

**✓ Critère de succès** : Réponse HTTP 200, page HTML de Grafana

---

#### 1.4 - Vérifier la data source Prometheus

**Via l'API Grafana** :

```bash
curl -s -u admin:admin http://localhost:3000/api/datasources | jq '.[] | {name, type, url}'
```

**Output attendu** :
```json
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://localhost:9090"
}
```

**✓ Critère de succès** : Data source Prometheus présente et opérationnelle

---

#### 1.5 - Vérifier la présence des dashboards

```bash
curl -s -u admin:admin http://localhost:3000/api/search?query=Mini%20SOC | jq '.[] | {title, uri}'
```

**Output attendu** :
```json
{
  "title": "Système Global - Mini SOC",
  "uri": "db/systeme-global-mini-soc"
},
{
  "title": "VM1 - Serveur Web Rocky Linux",
  "uri": "db/vm1-serveur-web-rocky-linux"
}
```

**✓ Critère de succès** : Au moins 4 dashboards présents

---

#### 1.6 - Vérifier les alertes Grafana

```bash
curl -s -u admin:admin http://localhost:3000/api/alerts | jq '.[] | {id, title, state}' | head -20
```

**Output attendu** :
```json
{
  "id": 1,
  "title": "High CPU Usage",
  "state": "alerting"
},
{
  "id": 2,
  "title": "High Memory Usage",
  "state": "ok"
}
```

**✓ Critère de succès** : Alertes présentes et visibles

---

### ✅ Résultat Test 1

| Étape | Status | Détails |
|-------|--------|---------|
| 1.1 - Service running | ☐ | |
| 1.2 - Port 3000 | ☐ | |
| 1.3 - Web access | ☐ | |
| 1.4 - Data source | ☐ | |
| 1.5 - Dashboards | ☐ | |
| 1.6 - Alertes | ☐ | |
| **TOTAL** | ☐ ☐ ☐ | **PASS / FAIL** |

---

## 📊 Test 2 : Métriques Prometheus Reçues

### Objectif
Valider que Prometheus reçoit les métriques depuis Prometheus lui-même, Node Exporter sur VM1 et VM2.

### Étapes

#### 2.1 - Vérifier que Prometheus est en ligne

```bash
systemctl status prometheus
```

**Output attendu** :
```
● prometheus.service - Prometheus
   Loaded: loaded (/etc/systemd/system/prometheus.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-01-12 10:25:00 CET; 2h 50min ago
```

**✓ Critère de succès** : `Active: active (running)`

---

#### 2.2 - Vérifier le port 9090

```bash
netstat -tlnp | grep 9090
```

**Output attendu** :
```
tcp        0      0 0.0.0.0:9090            0.0.0.0:*               LISTEN      1234/prometheus
```

**✓ Critère de succès** : Prometheus écoute sur le port 9090

---

#### 2.3 - Tester l'API Prometheus

```bash
curl -s http://localhost:9090/api/v1/status/config | jq '.status'
```

**Output attendu** :
```
"success"
```

**✓ Critère de succès** : API répond avec succès

---

#### 2.4 - Lister les targets connectées

```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {labels: .labels.instance, health}'
```

**Output attendu** :
```json
{
  "labels": "localhost:9090",
  "health": "up"
},
{
  "labels": "vm1:9100",
  "health": "up"
},
{
  "labels": "vm2:9100",
  "health": "up"
}
```

**✓ Critère de succès** : Au moins 3 targets UP (Prometheus + VM1 + VM2)

---

#### 2.5 - Vérifier les métriques CPU

```bash
curl -s 'http://localhost:9090/api/v1/query?query=node_cpu_seconds_total{instance="vm1:9100"}' | jq '.data.result | length'
```

**Output attendu** :
```
8
```

(8 = nombre de CPU cores)

**✓ Critère de succès** : Nombre > 0 (métriques reçues de VM1)

---

#### 2.6 - Vérifier les métriques RAM

```bash
curl -s 'http://localhost:9090/api/v1/query?query=node_memory_MemTotal_bytes' | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}'
```

**Output attendu** :
```json
{
  "instance": "vm1:9100",
  "value": "2147483648"
},
{
  "instance": "vm2:9100",
  "value": "4294967296"
}
```

**✓ Critère de succès** : Métriques de RAM pour VM1 et VM2

---

#### 2.7 - Vérifier les métriques Disque

```bash
curl -s 'http://localhost:9090/api/v1/query?query=node_filesystem_size_bytes' | jq '.data.result | length'
```

**Output attendu** :
```
6
```

(Minimum 6 filesystems entre les VMs)

**✓ Critère de succès** : Nombre > 0

---

#### 2.8 - Vérifier les métriques réseau

```bash
curl -s 'http://localhost:9090/api/v1/query?query=node_network_receive_bytes_total' | jq '.data.result | length'
```

**Output attendu** :
```
4
```

(Au moins 4 interfaces réseau)

**✓ Critère de succès** : Nombre > 0

---

### ✅ Résultat Test 2

| Étape | Status | Détails |
|-------|--------|---------|
| 2.1 - Service Prometheus | ☐ | |
| 2.2 - Port 9090 | ☐ | |
| 2.3 - API test | ☐ | |
| 2.4 - Targets UP | ☐ | |
| 2.5 - Métriques CPU | ☐ | |
| 2.6 - Métriques RAM | ☐ | |
| 2.7 - Métriques Disque | ☐ | |
| 2.8 - Métriques Réseau | ☐ | |
| **TOTAL** | ☐ ☐ ☐ | **PASS / FAIL** |

---

## 🚨 Test 3 : Alertes Déclenchées Correctement

### Objectif
Simuler une situation d'alerte (haute charge CPU, haute mémoire, etc.) et vérifier que l'alerte se déclenche.

### Étapes

#### 3.1 - Vérifier les règles d'alerte dans Prometheus

```bash
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | {name: .name, state: .state}'
```

**Output attendu** :
```json
{
  "name": "HighCPUUsage",
  "state": "inactive"
},
{
  "name": "HighMemoryUsage",
  "state": "inactive"
}
```

**✓ Critère de succès** : Règles d'alerte présentes et visibles

---

#### 3.2 - Simuler une haute charge CPU sur VM1

**Sur VM1** :

```bash
# Générer une charge CPU (30 secondes)
stress-ng --cpu 4 --timeout 30s --quiet &
```

Ou alternative sans tool :

```bash
for i in {1..4}; do
  yes > /dev/null &
done
sleep 30
killall yes
```

---

#### 3.3 - Vérifier la métrique CPU augmente

```bash
# À exécuter après le stress
curl -s 'http://localhost:9090/api/v1/query?query=node_load5{instance="vm1:9100"}' | jq '.data.result[0].value[1]'
```

**Output attendu** :
```
"3.5"
```

(Valeur élevée > 2.0)

**✓ Critère de succès** : Load average > 2.0

---

#### 3.4 - Attendre l'alerte (5 minutes)

**Note** : Les règles d'alerte ont un délai (`for: 5m`). Attendre 5-10 minutes pour que l'alerte se déclenche.

Vérifier l'état de l'alerte :

```bash
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="HighCPUUsage") | {state: .state, severity: .labels.severity}'
```

**Output attendu** :
```json
{
  "state": "firing",
  "severity": "warning"
}
```

**✓ Critère de succès** : Alerte en état `firing`

---

#### 3.5 - Vérifier l'alerte dans Grafana

Via l'interface Web Grafana → Alerting → Alert Rules

**Output attendu** : Alerte "HighCPUUsage" en rouge (Firing)

**✓ Critère de succès** : Alerte visible dans l'interface

---

#### 3.6 - Simuler une haute mémoire

**Sur VM1** :

```bash
# Allouer 1GB de RAM (30 secondes)
stress-ng --vm 1 --vm-bytes 1G --timeout 30s --quiet &
```

---

#### 3.7 - Vérifier la métrique mémoire

```bash
curl -s 'http://localhost:9090/api/v1/query?query=(1-(node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))*100{instance="vm1:9100"}' | jq '.data.result[0].value[1]'
```

**Output attendu** :
```
"75.5"
```

(Pourcentage élevé > 50%)

**✓ Critère de succès** : Utilisation mémoire > 80%

---

#### 3.8 - Attendre l'alerte mémoire (2 minutes)

```bash
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="HighMemoryUsage") | {state: .state, severity: .labels.severity}'
```

**Output attendu** :
```json
{
  "state": "firing",
  "severity": "critical"
}
```

**✓ Critère de succès** : Alerte en état `firing`

---

#### 3.9 - Vérifier l'historique des alertes

```bash
curl -s http://localhost:9090/api/v1/alerts/groups | jq '.data[0].alerts | length'
```

**Output attendu** :
```
2
```

(Au moins 2 alertes actives)

**✓ Critère de succès** : Nombre d'alertes > 0

---

### ✅ Résultat Test 3

| Étape | Status | Détails |
|-------|--------|---------|
| 3.1 - Règles présentes | ☐ | |
| 3.2 - Charge CPU créée | ☐ | |
| 3.3 - CPU augmente | ☐ | |
| 3.4 - Alerte CPU firing | ☐ | |
| 3.5 - Alerte dans Grafana | ☐ | |
| 3.6 - Charge RAM créée | ☐ | |
| 3.7 - RAM augmente | ☐ | |
| 3.8 - Alerte RAM firing | ☐ | |
| 3.9 - Historique alertes | ☐ | |
| **TOTAL** | ☐ ☐ ☐ | **PASS / FAIL** |

---

## 🎯 Test 4 : Playbook Ansible Fonctionne

### Objectif
Exécuter les playbooks d'incident response et vérifier qu'ils s'exécutent sans erreur.

### Prérequis

```bash
# Installer Ansible si nécessaire
sudo dnf install -y ansible

# Vérifier la version
ansible --version
```

---

### Étapes

#### 4.1 - Vérifier la configuration Ansible

```bash
cat /etc/ansible/hosts
```

**Output attendu** :
```
[monitoring]
monitoring_vm ansible_host=192.168.x.x

[webserver]
vm1 ansible_host=192.168.x.x

[soc]
vm2 ansible_host=192.168.x.x
```

**✓ Critère de succès** : Fichier hosts bien configuré

---

#### 4.2 - Tester la connectivité Ansible

```bash
ansible all -m ping
```

**Output attendu** :
```
vm1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
vm2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
monitoring_vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**✓ Critère de succès** : Tous les hosts répondent `SUCCESS`

---

#### 4.3 - Exécuter le playbook "Block SSH"

```bash
# Créer le playbook s'il n'existe pas
mkdir -p /opt/ansible/playbooks
cp playbooks/block_ssh_bruteforce.yml /opt/ansible/playbooks/

# Exécuter
ansible-playbook /opt/ansible/playbooks/block_ssh_bruteforce.yml \
  -e "attacker_ip=192.168.1.100" \
  -v
```

**Output attendu** :
```
PLAY [Block SSH Brute Force Attack] ****
TASK [Verify attacker IP provided] ****
ok: [vm1]

TASK [Log incident] ****
changed: [vm1]

TASK [Add firewall rule to drop attacker IP] ****
changed: [vm1]

PLAY RECAP ****
vm1 : ok=4 changed=3 unreachable=0 failed=0
```

**✓ Critère de succès** : `failed=0` et au moins 3 tasks changed

---

#### 4.4 - Vérifier que la règle firewall est ajoutée

**Sur VM1** :

```bash
firewall-cmd --list-all | grep 192.168.1.100
```

**Output attendu** :
```
reject rules:
  rule family="ipv4" source address="192.168.1.100" reject
```

**✓ Critère de succès** : Règle présente dans firewall

---

#### 4.5 - Exécuter le playbook "Kill Process"

```bash
# Simuler un processus malveillant (sleep)
pid=$(sleep 3600 & echo $!)

# Exécuter le playbook
ansible-playbook /opt/ansible/playbooks/kill_process.yml \
  -e "process_pid=${pid}" \
  -v
```

**Output attendu** :
```
TASK [Get process details before killing] ****
ok: [vm1]

TASK [Log action before killing process] ****
changed: [vm1]

TASK [Kill process] ****
changed: [vm1]

TASK [Verify process is killed] ****
ok: [vm1]

PLAY RECAP ****
vm1 : ok=6 changed=3 unreachable=0 failed=0
```

**✓ Critère de succès** : `failed=0`, process tué avec succès

---

#### 4.6 - Exécuter le playbook "Isolate VM"

```bash
# Attention : ce playbook désactive le réseau !
# À faire sur une VM de test ou avec précaution

ansible-playbook /opt/ansible/playbooks/isolate_vm.yml \
  -e "network_interface=eth1" \
  --check  # Mode dry-run pour vérification
```

**Output attendu** :
```
TASK [Disable network interface] ****
CHANGED (dry run)

PLAY RECAP ****
vm1 : ok=3 changed=1 unreachable=0 failed=0
```

**✓ Critère de succès** : Playbook syntaxiquement correct (mode `--check`)

---

#### 4.7 - Vérifier les logs d'exécution Ansible

```bash
tail -50 /var/log/incident_response.log
```

**Output attendu** :
```
[2024-01-12 14:30:25] SSH Brute Force - Blocking IP 192.168.1.100
[2024-01-12 14:30:26] INCIDENT RESPONSE - Killing PID 5432 - 5432 root sleep 3600
[2024-01-12 14:30:27] Process kill result: SUCCESS
```

**✓ Critère de succès** : Logs présents et détaillés

---

### ✅ Résultat Test 4

| Étape | Status | Détails |
|-------|--------|---------|
| 4.1 - Config Ansible | ☐ | |
| 4.2 - Ping Ansible | ☐ | |
| 4.3 - Playbook Block SSH | ☐ | |
| 4.4 - Firewall rule OK | ☐ | |
| 4.5 - Playbook Kill Process | ☐ | |
| 4.6 - Playbook Isolate VM | ☐ | |
| 4.7 - Logs OK | ☐ | |
| **TOTAL** | ☐ ☐ ☐ | **PASS / FAIL** |

---

## 🔧 Test 5 : Scripts Bash Exécutables & Fonctionnels

### Objectif
Vérifier que les scripts bash sont exécutables et s'exécutent sans erreur.

### Étapes

#### 5.1 - Vérifier que les scripts existent

```bash
ls -la /opt/scripts/
```

**Output attendu** :
```
-rwxr-xr-x. root root monitor_services.sh
-rwxr-xr-x. root root auto_response_ssh.sh
-rwxr-xr-x. root root generate_incident_report.sh
```

**✓ Critère de succès** : Au moins 3 scripts avec permissions `x` (exécutable)

---

#### 5.2 - Vérifier la syntaxe bash des scripts

```bash
for script in /opt/scripts/*.sh; do
    bash -n "$script" && echo "✓ $script: OK" || echo "✗ $script: ERROR"
done
```

**Output attendu** :
```
✓ /opt/scripts/monitor_services.sh: OK
✓ /opt/scripts/auto_response_ssh.sh: OK
✓ /opt/scripts/generate_incident_report.sh: OK
```

**✓ Critère de succès** : Tous les scripts valides syntaxiquement

---

#### 5.3 - Exécuter le script "Monitor Services"

```bash
/opt/scripts/monitor_services.sh
```

**Output attendu** :
```
==========================================
Service Monitoring Report - 2024-01-12 14:45:32
==========================================

✓ sshd: RUNNING
✓ nginx: RUNNING
✓ wazuh-agent: RUNNING
✓ prometheus: RUNNING
✓ grafana-server: RUNNING

==========================================
Port Listening Checks
==========================================

✓ SSH (Port 22): LISTENING
✓ HTTP (Port 80): LISTENING
✓ HTTPS (Port 443): LISTENING
✓ Node Exporter (Port 9100): LISTENING
✓ Prometheus (Port 9090): LISTENING
✓ Grafana (Port 3000): LISTENING

==========================================
✓ All services OK
```

**✓ Critère de succès** : Script exécuté, tous les services listés

---

#### 5.4 - Vérifier le fichier de log créé

```bash
ls -la /var/log/monitor_services.log
cat /var/log/monitor_services.log | tail -10
```

**Output attendu** :
```
-rw-r--r--. root root 2048 Jan 12 14:45 /var/log/monitor_services.log

[2024-01-12 14:45:32] ✓ sshd: RUNNING
[2024-01-12 14:45:32] ✓ nginx: RUNNING
...
```

**✓ Critère de succès** : Fichier log créé et rempli

---

#### 5.5 - Exécuter le script "Auto Response SSH"

```bash
# Activer fail2ban SSH jail d'abord
sudo fail2ban-client status sshd

# Exécuter le script
/opt/scripts/auto_response_ssh.sh
```

**Output attendu** :
```
[2024-01-12 14:46:00] Starting SSH Brute Force Auto Response
[2024-01-12 14:46:00] Found 0 IPs blocked by fail2ban
[2024-01-12 14:46:00] No blocked IPs detected
```

Ou si des IPs sont bloquées :

```
[2024-01-12 14:46:00] Found 2 IPs blocked by fail2ban
[2024-01-12 14:46:00] Processing blocked IP: 192.168.1.50
[2024-01-12 14:46:01] Blocking IP: 192.168.1.50
[2024-01-12 14:46:02] Auto response completed - 2 IPs processed
```

**✓ Critère de succès** : Script exécuté, log généré

---

#### 5.6 - Exécuter le script "Generate Incident Report"

```bash
/opt/scripts/generate_incident_report.sh
```

**Output attendu** :
```
✓ Incident report generated: /var/incidents/INC-20240112-144630_report.md
# Incident Response Report

**Incident ID**: INC-20240112-144630
**Generated**: Fri Jan 12 14:46:30 CET 2024

...
```

**✓ Critère de succès** : Rapport généré et affiché

---

#### 5.7 - Vérifier le fichier rapport généré

```bash
ls -la /var/incidents/
cat /var/incidents/INC-*/INC-*_report.md | head -30
```

**Output attendu** :
```
-rw-r--r--. root root 3245 Jan 12 14:46 INC-20240112-144630_report.md

# Incident Response Report

**Incident ID**: INC-20240112-144630
**Generated**: Fri Jan 12 14:46:30 CET 2024

---

## 🔴 Incident Summary

Automatic incident response triggered.

---

## 📊 System Status at Time of Incident
...
```

**✓ Critère de succès** : Rapport en Markdown bien formé

---

#### 5.8 - Ajouter les scripts à crontab (optionnel)

```bash
# Vérifier qu'on peut ajouter à crontab
crontab -l 2>/dev/null || echo "No crontab yet"

# Ajouter pour exécution périodique (toutes les 5 min)
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/scripts/monitor_services.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * * /opt/scripts/auto_response_ssh.sh") | crontab -

# Vérifier
crontab -l
```

**Output attendu** :
```
*/5 * * * * /opt/scripts/monitor_services.sh
*/10 * * * * /opt/scripts/auto_response_ssh.sh
```

**✓ Critère de succès** : Crontab configurée

---

### ✅ Résultat Test 5

| Étape | Status | Détails |
|-------|--------|---------|
| 5.1 - Scripts existent | ☐ | |
| 5.2 - Syntaxe bash OK | ☐ | |
| 5.3 - Monitor Services | ☐ | |
| 5.4 - Log monitoring | ☐ | |
| 5.5 - Auto Response | ☐ | |
| 5.6 - Generate Report | ☐ | |
| 5.7 - Rapport généré | ☐ | |
| 5.8 - Crontab OK | ☐ | |
| **TOTAL** | ☐ ☐ ☐ | **PASS / FAIL** |

---

## 📋 Résumé Global des Tests

| Test | Objectif | Status |
|------|----------|--------|
| **Test 1** | Grafana & Configuration | ☐ PASS ☐ FAIL |
| **Test 2** | Métriques Prometheus | ☐ PASS ☐ FAIL |
| **Test 3** | Alertes Déclenchées | ☐ PASS ☐ FAIL |
| **Test 4** | Playbooks Ansible | ☐ PASS ☐ FAIL |
| **Test 5** | Scripts Bash | ☐ PASS ☐ FAIL |

---

## 🎯 Validation Globale

**Score** : ___ / 5 tests réussis

- **5/5** : 🏆 Excellent - Tous les livrables fonctionnent
- **4/5** : ✅ Bon - Un seul test à corriger
- **3/5** : ⚠️ Acceptable - 2 tests à corriger
- **< 3/5** : ❌ À refaire - Plus de 2 tests échoués

---

## 🔧 Dépannage Rapide

### Si Test 1 échoue

```bash
# Redémarrer Grafana
systemctl restart grafana-server

# Vérifier les logs
journalctl -u grafana-server -n 20 -f
```

### Si Test 2 échoue

```bash
# Redémarrer Prometheus
systemctl restart prometheus

# Vérifier la configuration
promtool check config /etc/prometheus/prometheus.yml
```

### Si Test 3 échoue

```bash
# Recharger les règles
curl -X POST http://localhost:9090/-/reload

# Vérifier les alertes
curl -s http://localhost:9090/api/v1/rules
```

### Si Test 4 échoue

```bash
# Tester Ansible
ansible all -m ping

# Vérifier SSH keys
ssh-keyscan -H vm1 vm2 >> ~/.ssh/known_hosts
```

### Si Test 5 échoue

```bash
# Vérifier les permissions
chmod +x /opt/scripts/*.sh

# Tester la syntaxe
bash -n /opt/scripts/monitor_services.sh
```

---

## 📌 Points de Contrôle Importants

✓ Grafana accessible et fonctionnel  
✓ Prometheus reçoit les métriques  
✓ Alertes se déclenchent correctement  
✓ Playbooks Ansible exécutables  
✓ Scripts bash fonctionnels et logués  
✓ Documentation complète et à jour  

---

**Date de test** : _________________  
**Testeur** : _________________  
**Observations** : _________________  
_________________________________________________
