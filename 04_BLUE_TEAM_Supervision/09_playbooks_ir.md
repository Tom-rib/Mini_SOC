# 09. Playbooks Ansible pour Incident Response

**Objectif** : Automatiser les réactions aux incidents avec Ansible.

**Durée estimée** : 1h30  
**Niveau** : Avancé  
**Prérequis** : Ansible installé, SSH configuré vers les serveurs

---

## 1. Concept : Pourquoi automatiser avec Ansible ?

### Sans Ansible (manuel)

```
Incident détecté
→ Analyste SSH sur le serveur
→ Tape des commandes à la main
→ 5-10 minutes de délai
→ Risque d'erreur
```

### Avec Ansible (automatisé)

```
Incident détecté
→ Déclenchement du playbook
→ Exécution en parallèle sur tous les serveurs
→ 30 secondes de délai
→ Pas d'erreur
```

**Gain** : Rapidité × Fiabilité × Scalabilité

---

## 2. Installation et configuration d'Ansible

### 2.1 Installer Ansible

```bash
# Sur le serveur monitoring (VM SOC)
sudo apt update
sudo apt install ansible -y

# Vérifier
ansible --version
# Output: ansible 2.9.x
```

### 2.2 Configurer la connexion SSH

**Générer une clé SSH pour Ansible** (si pas déjà fait) :

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""
```

**Copier la clé sur les serveurs** :

```bash
# Serveur web
ssh-copy-id -i ~/.ssh/ansible_key.pub admin@192.168.1.100

# SOC
ssh-copy-id -i ~/.ssh/ansible_key.pub admin@192.168.1.101

# Monitoring
ssh-copy-id -i ~/.ssh/ansible_key.pub admin@192.168.1.102
```

### 2.3 Créer l'inventaire

Créer `/etc/ansible/hosts` :

```ini
[all:vars]
ansible_user = admin
ansible_ssh_private_key_file = ~/.ssh/ansible_key
ansible_python_interpreter = /usr/bin/python3

[web_servers]
web01 ansible_host=192.168.1.100

[soc_servers]
soc01 ansible_host=192.168.1.101

[monitoring_servers]
monitor01 ansible_host=192.168.1.102
```

**Tester la connexion** :

```bash
ansible all -i /etc/ansible/hosts -m ping
```

Résultat attendu :
```
web01 | SUCCESS => {
    "ping": "pong"
}
soc01 | SUCCESS => {
    "ping": "pong"
}
monitor01 | SUCCESS => {
    "ping": "pong"
}
```

---

## 3. Playbook #1 : Bloquer une IP attaquante

### 3.1 Création du playbook

Créer `/home/admin/ir_playbooks/block_ip.yml` :

```yaml
---
# Playbook : Bloquer une IP attaquante au firewall
# Usage : ansible-playbook block_ip.yml -e "attacker_ip=192.168.1.50"

- name: Bloquer IP attaquante au firewall
  hosts: all  # Appliquer à tous les serveurs
  become: yes  # Devenir root
  
  vars:
    # Valeur par défaut, override avec -e "attacker_ip=X"
    attacker_ip: "192.168.1.50"
    block_duration: "3600"  # 1 heure
  
  tasks:
    - name: Afficher l'IP à bloquer
      debug:
        msg: "Blocage de {{ attacker_ip }} pendant {{ block_duration }} secondes"
    
    # === FIREWALLD (Rocky Linux) ===
    - name: Bloquer l'IP avec firewalld (permanent)
      firewalld:
        source: "{{ attacker_ip }}/32"
        zone: drop
        permanent: yes
        state: enabled
      notify: reload_firewalld
      tags:
        - firewall
        - blocking
    
    # === Alternative : IPTables ===
    - name: Bloquer l'IP avec iptables (temporaire)
      iptables:
        chain: INPUT
        source: "{{ attacker_ip }}"
        jump: DROP
        state: present
      tags:
        - iptables
    
    # === Vérification ===
    - name: Vérifier que l'IP est bloquée
      shell: |
        firewall-cmd --zone=drop --list-sources | grep "{{ attacker_ip }}"
      register: verify_block
      failed_when: verify_block.rc != 0
      tags:
        - verify
    
    - name: Confirmer le blocage
      debug:
        msg: "IP {{ attacker_ip }} bloquée avec succès"
      when: verify_block.rc == 0
    
    # === Logging ===
    - name: Logger l'incident
      lineinfile:
        path: /var/log/ir_incidents.log
        line: "[{{ ansible_date_time.iso8601 }}] Blocage IP {{ attacker_ip }} par Ansible"
        create: yes
  
  # === Handlers ===
  handlers:
    - name: reload_firewalld
      service:
        name: firewalld
        state: restarted

```

### 3.2 Utiliser le playbook

**Bloquer une IP spécifique** :

```bash
ansible-playbook /home/admin/ir_playbooks/block_ip.yml \
  -e "attacker_ip=192.168.1.50" \
  -i /etc/ansible/hosts
```

**Résultat** :
```
PLAY [Bloquer IP attaquante au firewall]

TASK [Afficher l'IP à bloquer]
ok: [web01] => msg: "Blocage de 192.168.1.50 pendant 3600 secondes"
ok: [soc01] => msg: "Blocage de 192.168.1.50 pendant 3600 secondes"

TASK [Bloquer l'IP avec firewalld]
changed: [web01]
changed: [soc01]
changed: [monitor01]

TASK [Vérifier que l'IP est bloquée]
ok: [web01]

TASK [Logger l'incident]
changed: [web01]

PLAY RECAP
web01 : ok=5  changed=2  unreachable=0  failed=0
soc01 : ok=5  changed=2  unreachable=0  failed=0
monitor01 : ok=5  changed=2  unreachable=0  failed=0
```

---

## 4. Playbook #2 : Arrêter un service compromis

### 4.1 Création du playbook

Créer `/home/admin/ir_playbooks/stop_service.yml` :

```yaml
---
# Playbook : Arrêter un service suspect
# Usage : ansible-playbook stop_service.yml -e "service_name=nginx"

- name: Arrêter et isoler un service compromis
  hosts: web_servers  # Seulement les serveurs web
  become: yes
  
  vars:
    service_name: "nginx"  # Service à arrêter
    action: "stop"  # stop ou restart
  
  tasks:
    - name: Vérifier que le service existe
      command: systemctl list-unit-files | grep "{{ service_name }}"
      register: service_check
      ignore_errors: yes
    
    - name: Arrêter le service
      systemd:
        name: "{{ service_name }}"
        state: stopped
        enabled: no  # Empêcher le redémarrage automatique
      when: service_check.rc == 0
      register: service_stop
    
    - name: Afficher le statut
      debug:
        msg: "Service {{ service_name }} arrêté. State: {{ service_stop.state }}"
    
    - name: Vérifier les processus associés
      shell: pgrep -f "{{ service_name }}" || echo "Aucun processus"
      register: process_check
    
    - name: Tuer les processus résiduels
      shell: pkill -9 -f "{{ service_name }}"
      when: process_check.stdout != "Aucun processus"
      ignore_errors: yes
    
    # === Collecte de preuves ===
    - name: Dumper les logs du service
      command: "journalctl -u {{ service_name }} --no-pager > /tmp/{{ service_name }}_logs.txt"
      ignore_errors: yes
    
    - name: Collecter les logs en preuves
      fetch:
        src: "/tmp/{{ service_name }}_logs.txt"
        dest: "/home/admin/incident_evidence/"
        flat: yes
      ignore_errors: yes
    
    - name: Logger l'arrêt
      lineinfile:
        path: /var/log/ir_incidents.log
        line: "[{{ ansible_date_time.iso8601 }}] Service {{ service_name }} arrêté par Ansible"
        create: yes

```

### 4.2 Utiliser le playbook

```bash
ansible-playbook /home/admin/ir_playbooks/stop_service.yml \
  -e "service_name=nginx" \
  -i /etc/ansible/hosts
```

---

## 5. Playbook #3 : Collecter les logs d'incident

### 5.1 Création du playbook

Créer `/home/admin/ir_playbooks/collect_logs.yml` :

```yaml
---
# Playbook : Collecter les logs d'incident pour analyse
# Usage : ansible-playbook collect_logs.yml -e "incident_id=20250206_001"

- name: Collecter les logs d'incident
  hosts: all
  
  vars:
    incident_id: "{{ ansible_date_time.date }}_incident"
    evidence_path: "/tmp/incident_evidence"
  
  tasks:
    - name: Créer le dossier de preuves
      file:
        path: "{{ evidence_path }}"
        state: directory
        mode: '0700'
      become: yes
    
    - name: Collecter les logs auth
      copy:
        src: /var/log/secure
        dest: "{{ evidence_path }}/auth_logs.txt"
        remote_src: yes
      become: yes
      ignore_errors: yes
    
    - name: Collecter les logs Wazuh
      copy:
        src: /var/ossec/logs/alerts/alerts.log
        dest: "{{ evidence_path }}/wazuh_alerts.log"
        remote_src: yes
      become: yes
      ignore_errors: yes
    
    - name: Collecter les logs système
      shell: |
        journalctl --no-pager -n 1000 > {{ evidence_path }}/system_logs.txt
      become: yes
      ignore_errors: yes
    
    - name: Collecter les logs firewall
      shell: |
        firewall-cmd --get-log-denied > {{ evidence_path }}/firewall_logs.txt 2>&1
      become: yes
      ignore_errors: yes
    
    - name: Collecter les processus actifs
      shell: |
        ps auxf > {{ evidence_path }}/processes.txt
      become: yes
    
    - name: Collecter les connexions réseau
      shell: |
        ss -tuln > {{ evidence_path }}/connections.txt
        netstat -tulpn >> {{ evidence_path }}/connections.txt 2>/dev/null
      become: yes
    
    - name: Collecter les utilisateurs actifs
      shell: |
        w > {{ evidence_path }}/active_users.txt
        lastlog >> {{ evidence_path }}/active_users.txt
      become: yes
    
    - name: Créer le timestamp
      shell: |
        echo "Collecté le : $(date -Iseconds)" > {{ evidence_path }}/METADATA.txt
        echo "Host : $(hostname)" >> {{ evidence_path }}/METADATA.txt
        echo "Incident ID : {{ incident_id }}" >> {{ evidence_path }}/METADATA.txt
      become: yes
    
    - name: Archiver les preuves
      archive:
        path: "{{ evidence_path }}"
        dest: "/tmp/{{ incident_id }}_evidence.tar.gz"
        format: gz
      become: yes
    
    - name: Récupérer l'archive en local
      fetch:
        src: "/tmp/{{ incident_id }}_evidence.tar.gz"
        dest: "/home/admin/incident_evidence/"
        flat: yes
      become: yes
    
    - name: Afficher le chemin de l'archive
      debug:
        msg: "Preuves archivées dans /home/admin/incident_evidence/{{ incident_id }}_evidence.tar.gz"

```

### 5.2 Utiliser le playbook

```bash
ansible-playbook /home/admin/ir_playbooks/collect_logs.yml \
  -e "incident_id=20250206_brute_force" \
  -i /etc/ansible/hosts
```

**Résultat** : Archive tar.gz avec tous les logs, téléchargée en local.

---

## 6. Playbook #4 : Réinitialiser après incident

Créer `/home/admin/ir_playbooks/incident_recovery.yml` :

```yaml
---
# Playbook : Nettoyer après un incident
# Usage : ansible-playbook incident_recovery.yml -e "target=web01"

- name: Récupération après incident
  hosts: "{{ target }}"
  become: yes
  
  vars:
    target: "web01"
  
  tasks:
    - name: Mettre à jour le système
      yum:
        name: '*'
        state: latest
    
    - name: Changer tous les mots de passe
      user:
        name: "{{ item }}"
        password: "{{ lookup('password', '/dev/null') | password_hash('sha512') }}"
      loop:
        - admin
        - www-data
      ignore_errors: yes
    
    - name: Redémarrer les services clés
      service:
        name: "{{ item }}"
        state: restarted
      loop:
        - sshd
        - nginx
        - auditd
        - fail2ban
      ignore_errors: yes
    
    - name: Nettoyer les logs
      shell: |
        > /var/log/secure
        > /var/log/auth.log
        journalctl --vacuum=1d
    
    - name: Vérifier la sécurité
      shell: |
        lynis audit system --quick
      register: lynis_result
    
    - name: Afficher le rapport Lynis
      debug:
        msg: "{{ lynis_result.stdout }}"

```

---

## 7. Organiser les playbooks

### Structure de dossier

```
/home/admin/ir_playbooks/
├── block_ip.yml
├── stop_service.yml
├── collect_logs.yml
├── incident_recovery.yml
├── variables.yml
├── group_vars/
│   ├── all.yml
│   ├── web_servers.yml
│   └── soc_servers.yml
└── roles/
    ├── incident_response/
    │   └── tasks/main.yml
    └── hardening/
        └── tasks/main.yml
```

### 7.1 Fichier variables central

Créer `/home/admin/ir_playbooks/group_vars/all.yml` :

```yaml
---
# Variables globales

# Contacts d'escalade
incident_escalation_email: "soc-team@monentreprise.fr"
incident_slack_webhook: "https://hooks.slack.com/services/..."

# Délai de réaction par défaut
default_block_duration: 3600  # 1 heure

# Chemins critiques
evidence_path: "/var/incident_evidence"
log_path: "/var/log/ir_incidents.log"

# Services critiques
critical_services:
  - sshd
  - nginx
  - auditd
  - fail2ban
  - wazuh-agent
```

---

## 8. Chaîner les playbooks (orchestration)

Créer `/home/admin/ir_playbooks/full_incident_response.yml` :

```yaml
---
# Playbook : Réponse complète à un incident
# Usage : ansible-playbook full_incident_response.yml \
#         -e "incident_type=brute_force" \
#         -e "attacker_ip=192.168.1.50"

- name: Réponse complète incident
  hosts: localhost
  gather_facts: no
  
  vars:
    incident_type: "unknown"
    attacker_ip: "unknown"
  
  tasks:
    - name: "ÉTAPE 1: Bloquer l'attaquant"
      include_tasks: block_ip.yml
      vars:
        block_ip: "{{ attacker_ip }}"
    
    - name: "ÉTAPE 2: Arrêter les services menacés"
      include_tasks: stop_service.yml
      vars:
        service_name: "nginx"
      when: incident_type == "upload" or incident_type == "web"
    
    - name: "ÉTAPE 3: Collecter les preuves"
      include_tasks: collect_logs.yml
      vars:
        incident_id: "{{ ansible_date_time.date }}_{{ incident_type }}"
    
    - name: "ÉTAPE 4: Envoyer une notification"
      slack:
        token: "{{ slack_token }}"
        channel: "#soc-alerts"
        msg: "🚨 Incident {{ incident_type }} traité. Attaquant {{ attacker_ip }} bloqué."
      ignore_errors: yes

```

**Utiliser** :

```bash
ansible-playbook /home/admin/ir_playbooks/full_incident_response.yml \
  -e "incident_type=brute_force" \
  -e "attacker_ip=192.168.1.50"
```

---

## 9. Tester un playbook

### 9.1 Syntax check

```bash
ansible-playbook block_ip.yml --syntax-check
```

### 9.2 Dry run (test sans exécution)

```bash
ansible-playbook block_ip.yml \
  -e "attacker_ip=192.168.1.50" \
  --check  # N'exécute pas vraiment
```

### 9.3 Verbose mode

```bash
ansible-playbook block_ip.yml -vvv
```

---

## 10. Checklist Ansible IR

- [ ] Ansible installé et configuré
- [ ] Inventaire créé
- [ ] SSH keys distribuées
- [ ] Playbook block_ip.yml créé et testé
- [ ] Playbook stop_service.yml créé et testé
- [ ] Playbook collect_logs.yml créé et testé
- [ ] Playbook incident_recovery.yml créé et testé
- [ ] Variables centralisées
- [ ] Playbook orchestration créé
- [ ] Tous les playbooks testés en dry-run
- [ ] Documentation des playbooks

---

## 11. Résumé des playbooks

| Playbook | But | Temps | Risque |
|----------|-----|-------|--------|
| block_ip | Bloquer attaquant | <1m | Bas |
| stop_service | Arrêter service | <30s | Moyen |
| collect_logs | Collecter preuves | <2m | Nul |
| recovery | Rétablir service | <5m | Haut |

Les playbooks = automation + reproductibilité + rapidité !
