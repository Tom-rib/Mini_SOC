# Détection Nmap et Scans de Port

**Durée estimée : 1 heure**  
**Niveau : Intermédiaire+**  
**Objectif** : Détecter les scans de port (Nmap) et activités réseau anormales

---

## 📌 Objectifs

À la fin de cette fiche, tu pourras :
- Identifier les signatures Nmap dans les logs firewall
- Créer des règles pour détecter scans de port
- Différencier port scan vs trafic normal
- Alerter sur reconnaissance réseau

---

## 1. Contexte : Qu'est-ce qu'un Nmap scan ?

### Attaque classique

Un attaquant commence par **scanner les ports** pour voir quels services tournent :

```bash
# Attaquant
$ nmap -p- 192.168.1.10

# Resultat
Starting Nmap...
PORT      STATE  SERVICE
22/tcp    open   ssh
80/tcp    open   http
3306/tcp  open   mysql
...
```

### Signature dans les logs

**Logs firewall (firewalld)** :
```
Jan 15 14:32:01 rockysrv kernel: [firewall] IN=eth0 OUT= MAC=...SRC=192.168.1.50 DST=192.168.1.10 PROTO=TCP SPT=52341 DPT=22 SYN
Jan 15 14:32:02 rockysrv kernel: [firewall] IN=eth0 OUT= MAC=...SRC=192.168.1.50 DST=192.168.1.10 PROTO=TCP SPT=52342 DPT=23 SYN
Jan 15 14:32:03 rockysrv kernel: [firewall] IN=eth0 OUT= MAC=...SRC=192.168.1.50 DST=192.168.1.10 PROTO=TCP SPT=52343 DPT=25 SYN
                                                                                     ↓                               ↓
                                                                  Ports différents = scan de port
```

**Ce qui est suspect** :
- Même source IP
- Beaucoup de ports différents
- Peu de temps
- Réponses TCP RST (port fermé)

---

## 2. Sources de logs pour port scan

### 1️⃣ Firewall (logs kernel)
```bash
# Rocky Linux avec firewalld
sudo tail -f /var/log/messages | grep firewall

# Exemple :
# Jan 15 14:32:01 rockysrv kernel: [nf_tables] IN=eth0 SRC=192.168.1.50 DPT=22 SYN
```

### 2️⃣ Wazuh FIM (File Integrity Monitoring)
- Peut détecter modifications de fichiers réseau

### 3️⃣ Suricata / Snort (si installé)
- IDS réseau dédié
- **Pour ce projet** : pas nécessaire, juste firewall + Wazuh

---

## 3. Configuration firewalld pour logger les rejets

### Activer le logging des paquets rejetés

```bash
# Sur serveur Rocky
sudo firewall-cmd --set-log-denied=unicast
sudo firewall-cmd --get-log-denied
```

Vérifier la configuration :

```bash
# Voir les rejets dans les logs
sudo tail -f /var/log/messages | grep "REJECT"
```

### Exemple de log rejeté

```
Jan 15 14:32:01 rockysrv kernel: [nf_tables] REJECT IN=eth0 OUT= MAC=... 
SRC=192.168.1.50 DST=192.168.1.10 PROTO=TCP SPT=52341 DPT=12345 SYN
```

---

## 4. Règles de détection Nmap

Nous allons créer **3 règles** :

| ID | Objectif | Level | Condition |
|----|----------|-------|-----------|
| 100020 | Port rejeté (une tentative) | 2 | Firewall REJECT |
| 100021 | Scan de port (multiple rejets) | 6 | Frequency 20 ports en 60s |
| 100022 | Scan syn (SYN flood) | 7 | Beaucoup de SYN en peu de temps |

---

## 5. Éditer les règles

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

Ajoute ces règles :

```xml
<!-- ============================================
     RÈGLES RÉSEAU - Scans de port / Nmap
     ============================================ -->

<group name="network_scanning,">

  <!-- RÈGLE 1 : Port rejeté par firewall (baseline) -->
  <rule id="100020" level="2">
    <match>REJECT</match>
    <description>Firewall: Incoming connection rejected</description>
    <group>firewall,network,</group>
  </rule>

  <!-- RÈGLE 2 : Port scan (20+ ports rejetés en 60s) -->
  <rule id="100021" level="6">
    <if_sid>100020</if_sid>
    <frequency>20</frequency>
    <timeframe>60</timeframe>
    <same_source_ip />
    <description>Network: Possible port scan detected (20+ rejected connections in 60 seconds)</description>
    <group>network_scanning,attack,</group>
    <mitre>
      <id>T1046</id>  <!-- MITRE: Network Service Scanning -->
    </mitre>
  </rule>

  <!-- RÈGLE 3 : SYN scan rapide (suspect) -->
  <rule id="100022" level="7">
    <if_sid>100020</if_sid>
    <regex>PROTO=TCP.*SYN</regex>
    <frequency>15</frequency>
    <timeframe>30</timeframe>
    <same_source_ip />
    <description>Network: Possible SYN port scan / SYN flood (15+ SYN packets in 30 seconds)</description>
    <group>network_scanning,attack,</group>
  </rule>

  <!-- RÈGLE 4 : Scan d'un port spécifique (bruteforce port) -->
  <rule id="100023" level="5">
    <if_sid>100020</if_sid>
    <regex>DPT=(3389|5900|5901|445|139)</regex>  <!-- RDP, VNC, SMB, NetBIOS -->
    <frequency>5</frequency>
    <timeframe>60</timeframe>
    <description>Network: Suspicious port targeted (RDP/VNC/SMB scan)</description>
    <group>network_scanning,attack,</group>
  </rule>

</group>
```

---

## 6. Explication détaillée

### Règle 100020 : Port rejeté (baseline)

```xml
<rule id="100020" level="2">
  <match>REJECT</match>
  <description>Firewall: Incoming connection rejected</description>
  <group>firewall,network,</group>
</rule>
```

**Quand ça trigger** :
```
Jan 15 14:32:01 rockysrv kernel: [nf_tables] REJECT IN=eth0 ... DPT=12345
```

**Level 2** = Debug/Info (c'est normal, on a un firewall)

**Utilité** : Règle parente pour agrégation

---

### Règle 100021 : Port scan

```xml
<rule id="100021" level="6">
  <if_sid>100020</if_sid>
  <frequency>20</frequency>
  <timeframe>60</timeframe>
  <same_source_ip />
  <description>Possible port scan (20+ rejets en 60s)</description>
  <group>network_scanning,attack,</group>
</rule>
```

**Logique** :
- 20 ports **différents** rejetés
- En 60 secondes
- De la **même IP** (attaquant)

**Level 6** = Error (reconnaissance actuelle)

**Seuil** :
- 20 ports = assez bas pour détecter
- 60 secondes = Nmap standard scan

---

### Règle 100022 : SYN scan rapide

```xml
<rule id="100022" level="7">
  <if_sid>100020</if_sid>
  <regex>PROTO=TCP.*SYN</regex>
  <frequency>15</frequency>
  <timeframe>30</timeframe>
  <same_source_ip />
  <description>Possible SYN port scan</description>
</rule>
```

**Quand ça trigger** :
```
Beaucoup de paquets SYN rejetés rapidement
= SYN scan avec Nmap
```

**Level 7** = Error (plus rapide = plus suspect)

---

### Règle 100023 : Ports à risque

```xml
<rule id="100023" level="5">
  <if_sid>100020</if_sid>
  <regex>DPT=(3389|5900|5901|445|139)</regex>
  <description>Suspicious port targeted</description>
</rule>
```

**Ports cibles** :
- `3389` = RDP (Windows Remote Desktop)
- `5900`, `5901` = VNC (Remote Access)
- `445` = SMB (Windows Shares)
- `139` = NetBIOS

**Logique** : Attaquant cherche spécifiquement ces services = **c'est ciblé**

**Level 5** = Warning (pas aussi grave que le scan complet, mais ciblé)

---

## 7. Vérifier la configuration firewall

### Étape 1 : Activer le logging

```bash
# Sur serveur Rocky
sudo firewall-cmd --set-log-denied=all
sudo firewall-cmd --reload
sudo systemctl restart firewalld
```

### Étape 2 : Vérifier les logs

```bash
sudo tail -f /var/log/messages | grep -E "REJECT|DROP"
```

Résultat attendu :
```
Jan 15 14:32:01 rockysrv kernel: [nf_tables] REJECT IN=eth0 OUT= MAC=...
SRC=192.168.1.50 DST=192.168.1.10 PROTO=TCP SPT=52341 DPT=12345 SYN
```

### Étape 3 : Configurer Wazuh pour collecter

```bash
# Vérifier que /var/log/messages est monitoré par l'agent Wazuh
sudo grep -A5 "/var/log/messages" /var/ossec/etc/ossec.conf

# Doit contenir :
# <location>/var/log/messages</location>
```

---

## 8. Test pratique : Générer un Nmap scan

### Prérequis

```bash
# Sur la machine attaquante (ou locale)
sudo apt-get install nmap
```

### Test 1️⃣ : Scan simple

```bash
# Depuis machine attaquante, scanner l'IP du serveur Rocky
nmap -p 1-1000 192.168.1.10

# Ou si Nmap aggressif :
nmap -A 192.168.1.10
```

### Test 2️⃣ : Port specific

```bash
# Scanner des ports spécifiques (RDP/VNC/SMB)
nmap -p 3389,5900,5901,445,139 192.168.1.10
```

### Test 3️⃣ : SYN scan

```bash
# SYN scan (rapide)
sudo nmap -sS 192.168.1.10
```

---

## 9. Vérifier les résultats

### 1️⃣ Vérifier les logs firewall

```bash
# Sur le serveur Rocky, pendant le scan
sudo tail -f /var/log/messages | grep "REJECT\|DROP"

# Exemple de sortie :
# Jan 15 14:32:01 rockysrv kernel: [nf_tables] REJECT IN=eth0 SRC=192.168.1.50 DPT=1 SYN
# Jan 15 14:32:02 rockysrv kernel: [nf_tables] REJECT IN=eth0 SRC=192.168.1.50 DPT=2 SYN
# Jan 15 14:32:03 rockysrv kernel: [nf_tables] REJECT IN=eth0 SRC=192.168.1.50 DPT=3 SYN
# ...
```

### 2️⃣ Vérifier les alertes Wazuh

```bash
# Sur la VM SOC
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100021" or .rule.id=="100022" or .rule.id=="100023")'
```

Résultat attendu pour `nmap -p 1-1000` :
```json
{
  "rule": {
    "id": "100021",
    "level": 6,
    "description": "Network: Possible port scan detected"
  },
  "data": {
    "srcip": "192.168.1.50",
    "ports_detected": "1,2,3,...,1000"
  }
}
```

### 3️⃣ Dashboard Wazuh

Accès : `https://IP_SOC:443`

1. Menu → **Threat Detection**
2. Filtre : **Rule ID = 100021 OR 100022**
3. Tu devrais voir les scans Nmap

---

## 10. Affiner les règles

### Réduire faux positifs

Si tu as trop de faux positifs (scans légitimes) :

```xml
<!-- Augmenter le threshold -->
<frequency>50</frequency>    <!-- Au lieu de 20 -->
<timeframe>120</timeframe>   <!-- Au lieu de 60 -->
```

### Augmenter sensibilité

Si tu veux être plus sensible :

```xml
<!-- Diminuer le threshold -->
<frequency>10</frequency>     <!-- Au lieu de 20 -->
<timeframe>30</timeframe>     <!-- Au lieu de 60 -->
```

---

## 11. Cas spécial : Nmap avec -sU (UDP scan)

```xml
<!-- Règle pour UDP scan -->
<rule id="100024" level="5">
  <if_sid>100020</if_sid>
  <regex>PROTO=UDP</regex>
  <frequency>30</frequency>
  <timeframe>60</timeframe>
  <same_source_ip />
  <description>Network: Possible UDP port scan</description>
  <group>network_scanning,</group>
</rule>
```

---

## 12. Exemple : Simulation complète

### Scénario

Attaquant lance Nmap pour trouver services exposés avant d'attaquer.

### Étape 1 : Setup

```bash
# Serveur Rocky : Vérifier firewall logging
sudo firewall-cmd --set-log-denied=all
sudo systemctl restart wazuh-agent
```

### Étape 2 : Scanner

```bash
# Machine attaquante
nmap -A -p- 192.168.1.10
# Scan tous les ports, détection OS
```

### Étape 3 : Alertes

```bash
# VM SOC verra :
# 1. Alerte 100020 (chaque port rejeté) - level 2
# 2. Alerte 100021 (agrégation scan complet) - level 6 ⚠️
# 3. Possiblement 100022 (SYN rapide) - level 7 ⚠️
```

### Étape 4 : Documenter

```bash
# Récupérer les alertes pour rapport
sudo tail -100 /var/ossec/logs/alerts/alerts.json | jq '.rule | select(.id | inside(["100021", "100022"]))' > /tmp/nmap_alerts.json

cat /tmp/nmap_alerts.json
```

---

## 13. Intégration avec Incident Response

Ajouter réaction automatique :

```xml
<rule id="100021" level="6">
  <if_sid>100020</if_sid>
  <frequency>20</frequency>
  <timeframe>60</timeframe>
  <same_source_ip />
  <description>Network: Port scan detected</description>
  <group>network_scanning,attack,</group>
  
  <!-- Bloquer l'IP avec firewall -->
  <active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <timeout>1800</timeout>  <!-- Bloquer 30 minutes -->
  </active-response>
</rule>
```

---

## 14. Checklist validation

- [ ] `firewall-cmd --set-log-denied=all` exécuté
- [ ] Logs firewall visibles dans `/var/log/messages`
- [ ] Wazuh collecte `/var/log/messages`
- [ ] Règles 100020-100024 dans `local_rules.xml`
- [ ] Syntaxe validée (`wazuh-logtest`)
- [ ] Wazuh redémarré
- [ ] Test Nmap scan simple
- [ ] Alertes 100021/100022 apparaissent dans Wazuh

---

## 15. Troubleshooting

### Pas de logs firewall

```bash
# Vérifier que le logging est actif
sudo firewall-cmd --get-log-denied
# Doit être : all ou unicast

# Si non, réactiver
sudo firewall-cmd --set-log-denied=all
sudo firewall-cmd --reload
```

### Alertes ne déclenchent pas

```bash
# Vérifier que Wazuh voit les logs
sudo grep "nf_tables\|REJECT" /var/ossec/logs/ossec.log | head -20

# Vérifier la règle parente
sudo /var/ossec/bin/wazuh-logtest
# Entrer une ligne de log firewall
```

### Trop de faux positifs

```bash
# Exclure les IPs de confiance dans la règle
<same_source_exclude>192.168.1.1,192.168.1.2</same_source_exclude>
```

---

## 📚 Fichiers importants

```
/var/ossec/etc/rules/local_rules.xml        ← Tes règles
/var/log/messages                            ← Logs firewall
/var/ossec/logs/alerts/alerts.json           ← Alertes Wazuh
/etc/firewalld/firewalld.conf                ← Config firewall
```

---

**Durée réelle** : 1 heure (30 min règles + 30 min tests Nmap)  
**Compétences** : Firewall logging, frequency aggregation, network detection  
**Prochaine étape** : Détection uploads fichiers suspects
