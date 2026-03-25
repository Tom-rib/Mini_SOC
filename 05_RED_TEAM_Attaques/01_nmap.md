# Attaque 1 : Nmap - Reconnaissance réseau

**Durée estimée :** 45 minutes  
**Niveau :** Basique  
**Objectif :** Scanner le réseau pour découvrir les hôtes et services actifs

---

## 📋 Objectifs pédagogiques

À l'issue de cette attaque, vous comprendrez :

- Comment un attaquant enumère l'infrastructure
- Quels ports et services sont exposés
- Comment détecter un scan réseau en tant que Blue Team
- L'importance du firewall et des règles d'alerte

---

## 🎯 Scénario réaliste

Un attaquant externe veut cartographier votre réseau pour identifier les cibles potentielles. Il commence par un **scan de découverte**.

---

## 🛠️ Prérequis

**Sur la machine attaquante (Kali ou similaire) :**
- `nmap` installé
- Accès réseau à la VM web (192.168.1.100)
- Terminal/Console

**Informations réseau (adapter à votre lab) :**
- Réseau : 192.168.1.0/24
- VM Web : 192.168.1.100
- VM SOC : 192.168.1.101
- VM Monitoring : 192.168.1.102

---

## ⚙️ Étape 1 : Scan simple de découverte (5 min)

### Objectif
Découvrir les hôtes actifs du réseau.

### Commande

```bash
nmap -sn 192.168.1.0/24
```

**Paramètres :**
- `-sn` = Ping scan (découverte hôtes uniquement, pas de scan ports)

### Output attendu

```
Starting Nmap 7.92 ( https://nmap.org ) at 2024-01-15 10:30 CET
Nmap scan report for 192.168.1.1
Host is up (0.0012s latency).
Nmap scan report for 192.168.1.100
Host is up (0.0045s latency).
Nmap scan report for 192.168.1.101
Host is up (0.0038s latency).
Nmap scan report for 192.168.1.102
Host is up (0.0042s latency).
Nmap done at 2024-01-15 10:31 CET; 1 IP address scanned in 1.05 seconds
```

### Ce qu'on apprend
- Identifier 4 hôtes actifs sur le réseau
- Première reconnaissance

---

## ⚙️ Étape 2 : Scan détaillé de la VM Web (10 min)

### Objectif
Identifier tous les ports ouverts et services sur la VM cible.

### Commande

```bash
nmap -sV -sC 192.168.1.100
```

**Paramètres :**
- `-sV` = Version detection (détermine la version des services)
- `-sC` = Script scan (exécute des scripts de détection)

### Output attendu

```
Starting Nmap 7.92 ( https://nmap.org ) at 2024-01-15 10:32 CET
Nmap scan report for 192.168.1.100
Host is up (0.0032s latency).
Not shown: 997 filtered ports
PORT      STATE    SERVICE     VERSION
22/tcp    open     ssh         OpenSSH 8.2p1 Rocky Linux (protocol 2.0)
80/tcp    open     http        Nginx 1.20.1
443/tcp   open     https       Nginx 1.20.1
9200/tcp  filtered elasticsearch
MAC Address: 52:54:00:12:34:56 (QEMU virtual NIC)

Nmap done at 2024-01-15 10:32 CET; 1 IP address scanned in 5.23 seconds
```

### Ce qu'on apprend
- SSH sur port 22
- Nginx (HTTP/HTTPS) sur ports 80 et 443
- Elasticsearch sur port 9200 (filtré)
- Versions exactes des services

---

## ⚙️ Étape 3 : Scan agressif (OS detection) (15 min)

### Objectif
Obtenir des informations détaillées incluant l'OS et des scripts avancés.

### Commande

```bash
nmap -A -T4 192.168.1.100 -p- 2>/dev/null
```

**Paramètres :**
- `-A` = All (version, OS detection, scripts, traceroute)
- `-T4` = Timing (plus rapide, scan agressif)
- `-p-` = Tous les ports (1-65535)
- `2>/dev/null` = Supprime les messages d'erreur

### Output attendu

```
Starting Nmap 7.92 ( https://nmap.org ) at 2024-01-15 10:33 CET
Nmap scan report for 192.168.1.100
Host is up (0.0031s latency).
Not shown: 65530 filtered ports
PORT      STATE SERVICE    VERSION
22/tcp    open  ssh        OpenSSH 8.2p1 Rocky Linux
| ssh-hostkey:
|   3072 a1:b2:c3:d4:e5:f6:g7:h8 (RSA)
|   256 i9:j0:k1:l2:m3:n4:o5:p6 (ED25519)
|_  256 q7:r8:s9:t0:u1:v2:w3:x4 (ECDSA)
80/tcp    open  http       Nginx 1.20.1
|_http-server-header: nginx/1.20.1
|_http-title: Welcome to Nginx
443/tcp   open  ssl/https  Nginx 1.20.1
9200/tcp  open  elasticsearch
|_elasticsearch-info:
Device type: general purpose
Running: Linux 4.18
OS CPE: cpe:/o:linux:linux_kernel:4.18
OS details: Linux 4.18 on x86_64

Nmap done at 2024-01-15 10:33 CET; 1 IP address scanned in 12.34 seconds
```

### Ce qu'on apprend
- OS : Linux Rocky (noyau 4.18)
- Services détaillés avec versions
- Empreinte SSH
- Configuration du serveur web

---

## ⚙️ Étape 4 : Export des résultats (5 min)

### Objectif
Sauvegarder les résultats pour analyse.

### Commande

```bash
# Scan complet sauvegardé en XML
nmap -sV -sC -A 192.168.1.100 -oX scan_results.xml

# Sauvegarde en texte
nmap -sV -sC -A 192.168.1.100 -oN scan_results.txt

# Afficher le fichier texte
cat scan_results.txt
```

### Output attendu

```
# Nmap 7.92 scan initiated Mon Jan 15 10:34:00 2024 as: nmap -sV -sC -A 192.168.1.100 -oN scan_results.txt
Nmap scan report for 192.168.1.100
Host is up (0.0032s latency).
Not shown: 997 closed ports
PORT      STATE SERVICE    VERSION
22/tcp    open  ssh        OpenSSH 8.2p1 Rocky Linux
80/tcp    open  http       Nginx 1.20.1
443/tcp   open  https      Nginx 1.20.1

# Nmap done at Mon Jan 15 10:34:05 2024; 1 IP address scanned in 5.21 seconds
```

---

## 🔍 Rôle 1 : Administrateur système & hardening

### Ce que tu dois observer

```bash
# Sur la VM Web, vérifier les ports en écoute
sudo ss -tlnp | grep LISTEN

# Sortie attendue :
# LISTEN    0    128         0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=1234,fd=3))
# LISTEN    0    128         0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=5678,fd=10))
# LISTEN    0    128         0.0.0.0:443       0.0.0.0:*    users:(("nginx",pid=5678,fd=11))
```

### Actions à prendre

```bash
# 1. Vérifier firewall
sudo firewall-cmd --list-all

# 2. Vérifier SELinux
getenforce

# 3. Analyser les logs du firewall
sudo journalctl -u firewalld -f

# 4. Configurer des alertes si nécessaire
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" protocol value="icmp" accept'
```

---

## 🛡️ Rôle 2 : SOC / Logs / Détection

### Logs attendus

#### Dans Wazuh, créer une règle de détection

**Fichier de règle Wazuh :** `/var/ossec/etc/rules/local_rules.xml`

```xml
<group name="nmap_detection,">
  <rule id="100200" level="5">
    <description>Possible network scan detected (Nmap)</description>
    <match>nmap</match>
  </rule>

  <rule id="100201" level="7">
    <description>Multiple connections from same source in short time</description>
    <if_sid>5713</if_sid>
    <frequency>5</frequency>
    <timeframe>60</timeframe>
    <ignore>30</ignore>
  </rule>
</group>
```

#### Logs SSH (scan vers port 22)

```
Jan 15 10:33:45 web sshd[2345]: Connection closed by authenticating user root 192.168.1.50 port 54321 [preauth]
Jan 15 10:33:46 web sshd[2346]: Invalid user admin from 192.168.1.50 port 54322
Jan 15 10:33:47 web sshd[2347]: Connection reset by 192.168.1.50 port 54323 [preauth]
```

#### Logs Firewall (pfSense/Firewalld)

```
Jan 15 10:33:45 fw kernel: [UFW BLOCK] IN=eth0 OUT= MAC=52:54:00:ab:cd:ef SRC=192.168.1.50 DST=192.168.1.100 PROTO=TCP SPT=54321 DPT=22 WINDOW=65535 SYN URGP=0
Jan 15 10:33:46 fw kernel: [UFW BLOCK] IN=eth0 OUT= MAC=52:54:00:ab:cd:ef SRC=192.168.1.50 DST=192.168.1.100 PROTO=TCP SPT=54322 DPT=80 WINDOW=65535 SYN URGP=0
```

### Détection Wazuh

**Dans le dashboard Wazuh :**

```
Alert Level: 5 (MEDIUM)
Rule: 100201 - Multiple connections from same source
Source: 192.168.1.50
Destination: 192.168.1.100
Timestamp: 2024-01-15 10:33:45
Count: 5 connections in 60 seconds
Status: TRIGGERED
```

---

## 📊 Rôle 3 : Supervision & Incident Response

### Anomalies à surveiller

#### Indicateurs dans Grafana/Zabbix

```
Metric: Network Connections (incoming)
Value: 1000+ requests/min from single IP
Threshold: Normal < 100 req/min
Status: CRITICAL ALERT

Metric: SSH Connection Attempts
Value: 50+ attempts in 1 min
Threshold: Normal < 5/min
Status: WARNING
```

### Actions de réponse

```bash
# 1. Bloquer l'IP source
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.50" reject'
sudo firewall-cmd --reload

# 2. Générer un rapport d'incident
cat > /var/log/soc/incident_nmap_20240115.txt << 'EOF'
=== INCIDENT REPORT ===
Timestamp: 2024-01-15 10:33:45
Type: Network Reconnaissance (Nmap Scan)
Source IP: 192.168.1.50
Target: 192.168.1.100 (Web Server)
Severity: MEDIUM

Ports Scanned:
- 22/tcp (SSH)
- 80/tcp (HTTP)
- 443/tcp (HTTPS)
- 9200/tcp (Elasticsearch)

Actions Taken:
1. Blocked source IP
2. Enabled enhanced monitoring
3. Alerted SOC team

Status: CONTAINED
EOF

# 3. Vérifier les services
systemctl status nginx ssh
```

---

## ✅ Checklist de validation

Pour valider cette attaque, vérifier les 3 points suivants :

### Point 1 : Attaque exécutée
- [ ] Nmap scan lancé depuis la machine attaquante
- [ ] Au moins 3 scans différents effectués
- [ ] Résultats sauvegardés

### Point 2 : Détection confirmée
- [ ] Alerte Wazuh générée (level ≥ 5)
- [ ] Logs SSH/Firewall capturés
- [ ] Dashboard Wazuh affiche l'incident

### Point 3 : Réaction confirmée
- [ ] IP source bloquée dans le firewall
- [ ] Rapport d'incident généré
- [ ] Services toujours opérationnels

---

## 📝 Commandes utiles - Mémo rapide

```bash
# Scan rapide
nmap -sV 192.168.1.100

# Scan complet
nmap -A -T4 -p- 192.168.1.100

# Scan UDP
nmap -sU 192.168.1.100

# Scan stealth (lent, discret)
nmap -sS -T1 192.168.1.100

# Scanner plusieurs cibles
nmap -sV 192.168.1.100,101,102

# Exporter résultats
nmap -sV 192.168.1.100 -oX output.xml
nmap -sV 192.168.1.100 -oN output.txt
```

---

## 🔗 Références et liens internes

- [02_bruteforce_ssh.md](./02_bruteforce_ssh.md) → Prochaine attaque
- [README.md](../README.md) → Retour au projet
- Documentation Wazuh : `/opt/wazuh/rules/`
- Logs Firewall : `/var/log/firewall.log`

---

## 💡 Points clés à retenir

1. **Nmap est bruyant** → Les IDS/IPS le détectent facilement
2. **Le timing compte** → Trop rapide = alerte immédiate
3. **Les ports fermés/filtrés donnent des infos** → Révèlent un firewall
4. **La détection commence ici** → C'est la première étape d'une attaque réelle

