# Détection Commandes Sudo Suspectes

**Durée estimée : 1 heure**  
**Niveau : Intermédiaire+**  
**Objectif** : Détecter les commandes sudo anormales et l'escalade de privilèges

---

## 📌 Objectifs

À la fin de cette fiche, tu pourras :
- Créer des règles avec **regex** (pas juste match)
- Détecter sudo non autorisé
- Différencier sudo **réussi** vs **échoué**
- Alerter sur les commandes dangereuses

---

## 1. Contexte : Escalade de privilèges

### Qu'est-ce qu'on cherche ?

Un utilisateur normal essaie de devenir **root** ou d'exécuter une commande dangereuse.

```
user1$ sudo cat /etc/shadow
[sudo] password for user1: 
user1 is not in the sudoers file. This incident will be reported.
                        ↓
            → Alerte : Tentative de sudo non autorisée
```

### Deux scénarios différents

1. **Sudo refusé** (bon pour la sécurité, mais on veut le savoir)
   ```
   jan 15 14:32:01 rockysrv sudo: user1 : user NOT in sudoers ; TTY=pts/1
   ```

2. **Sudo réussi** (on regarde QUI a utilisé sudo et QUAND)
   ```
   Jan 15 14:32:01 rockysrv sudo: user1 : TTY=pts/1 ; PWD=/home/user1 ; USER=root ; COMMAND=/bin/cat /etc/passwd
   ```

---

## 2. Où sont les logs sudo ?

### Serveur Rocky
```bash
sudo tail -f /var/log/secure | grep "sudo"
```

Exemple de sortie :
```
Jan 15 14:32:01 rockysrv sudo: user1 : TTY=pts/1 ; PWD=/home/user1 ; USER=root ; COMMAND=/bin/bash
Jan 15 14:32:05 rockysrv sudo: user1 : user NOT in sudoers ; TTY=pts/1 ; PWD=/home/user1
Jan 15 14:32:10 rockysrv sudo: root : TTY=pts/0 ; PWD=/ ; USER=root ; COMMAND=/bin/vim /etc/shadow
```

---

## 3. Les règles à créer

Nous allons créer **4 règles** :

| ID | Objectif | Level | Condition |
|----|----------|-------|-----------|
| 100010 | Sudo non autorisé (NOT in sudoers) | 6 | Match "user NOT in sudoers" |
| 100011 | Sudo réussi (toute commande) | 3 | Match "COMMAND=" |
| 100012 | Commandes dangereuses sudo | 8 | Regex (cat /etc/shadow, rm -rf, etc) |
| 100013 | Sudo très fréquent (possible BF) | 7 | Frequency 10 en 300s |

---

## 4. Fichier à éditer

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

Ajoute ces règles dans la section `<group name="local_rules,">` :

---

## 5. Règles complètes (SUDO)

```xml
<!-- ============================================
     RÈGLES SUDO - Escalade de privilèges
     ============================================ -->

<group name="sudo_monitoring,">

  <!-- RÈGLE 1 : Sudo refusé (NOT in sudoers) -->
  <rule id="100010" level="6">
    <match>user NOT in sudoers</match>
    <description>Sudo: User NOT in sudoers file (unauthorized escalation attempt)</description>
    <group>privileged_escalation,authentication_failure,</group>
    <mitre>
      <id>T1548.003</id>  <!-- MITRE: Abuse Elevation Control Mechanism / Sudo -->
    </mitre>
  </rule>

  <!-- RÈGLE 2 : Sudo réussi (baseline - faible priorité) -->
  <rule id="100011" level="3">
    <if_sid>5402</if_sid>  <!-- Wazuh rule for sudo -->
    <match>COMMAND=</match>
    <description>Sudo: Command executed successfully</description>
    <group>sudo_execution,</group>
  </rule>

  <!-- RÈGLE 3 : Commandes dangereuses avec sudo -->
  <rule id="100012" level="8">
    <if_sid>100011</if_sid>
    <regex>COMMAND=(.*\bcat\s+/etc/(shadow|passwd|sudoers)|.*\brm\s+-rf|.*\bchmod\s+777|.*\bchown|.*\bnc\s+-l|.*\bnetcat|.*\bbash.*-i)</regex>
    <description>Sudo: Dangerous command executed (file access, deletion, reverse shell)</description>
    <group>privileged_escalation,dangerous_command,</group>
    <mitre>
      <id>T1548</id>  <!-- MITRE: Abuse Elevation Control Mechanism -->
    </mitre>
  </rule>

  <!-- RÈGLE 4 : Sudo brute force (trop de tentatives) -->
  <rule id="100013" level="7">
    <if_sid>100010</if_sid>
    <frequency>10</frequency>
    <timeframe>300</timeframe>
    <same_source_ip />
    <description>Sudo: Possible escalation brute force (10+ unauthorized attempts in 5 minutes)</description>
    <group>privileged_escalation,attack,</group>
  </rule>

</group>
```

---

## 6. Explication détaillée de chaque règle

### Règle 100010 : Sudo NOT in sudoers (Non autorisé)

```xml
<rule id="100010" level="6">
  <match>user NOT in sudoers</match>
  <description>Sudo: User NOT in sudoers file (unauthorized escalation attempt)</description>
  <group>privileged_escalation,authentication_failure,</group>
</rule>
```

**Quand ça trigger** :
```
Jan 15 14:32:05 rockysrv sudo: user1 : user NOT in sudoers ; TTY=pts/1
                                        ^^^^^^^^^^^^^^^^^^^^^^
```

**Level 6** = Error (escalade non autorisée, c'est grave)

**Cas d'usage** : Quelqu'un d'autre a accès au compte et essaie de devenir root

---

### Règle 100011 : Sudo réussi (baseline)

```xml
<rule id="100011" level="3">
  <if_sid>5402</if_sid>
  <match>COMMAND=</match>
  <description>Sudo: Command executed successfully</description>
  <group>sudo_execution,</group>
</rule>
```

**Quand ça trigger** :
```
Jan 15 14:32:01 rockysrv sudo: user1 : TTY=pts/1 ; PWD=/home/user1 ; USER=root ; COMMAND=/bin/ls -la
                                                                                   ^^^^^^^^^
```

**Level 3** = Faible (c'est normal qu'on utilise sudo)  
**if_sid=5402** = Règle Wazuh interne "sudo executed"

**Utilité** : Baseline pour la détection (règle parente pour 100012)

---

### Règle 100012 : Commandes dangereuses

```xml
<rule id="100012" level="8">
  <if_sid>100011</if_sid>
  <regex>COMMAND=(.*\bcat\s+/etc/(shadow|passwd|sudoers)|.*\brm\s+-rf|.*\bchmod\s+777|.*\bchown|.*\bnc\s+-l|.*\bnetcat|.*\bbash.*-i)</regex>
  <description>Sudo: Dangerous command executed</description>
  <group>privileged_escalation,dangerous_command,</group>
</rule>
```

**Décortiquons la regex** :

```regex
COMMAND=(.*\bcat\s+/etc/(shadow|passwd|sudoers)|...)
         ↓     ↓     ↓                         ↓
         début mots-clé espaces             fin alternatives
```

**Cherche** :
- `cat /etc/shadow` → Lire les hash de mots de passe ⚠️
- `cat /etc/passwd` → Lire la liste des utilisateurs ⚠️
- `cat /etc/sudoers` → Lire qui a les droits sudoers ⚠️
- `rm -rf` → Suppression récursive ⚠️
- `chmod 777` → Donner tous les droits ⚠️
- `chown` → Changer le propriétaire ⚠️
- `nc -l` ou `netcat` → Reverse shell ⚠️
- `bash -i` → Bash interactif ⚠️

**Level 8** = Alert (commande vraiment dangereuse)

---

### Règle 100013 : Sudo brute force

```xml
<rule id="100013" level="7">
  <if_sid>100010</if_sid>
  <frequency>10</frequency>
  <timeframe>300</timeframe>
  <same_source_ip />
  <description>Sudo: Possible escalation brute force</description>
</rule>
```

**Quand ça trigger** :
- 10 tentatives sudo refusées
- Dans 300 secondes (5 minutes)
- Du même user/IP

**Level 7** = Error (tentative d'escalade répétée = attaque)

---

## 7. Tester les règles

### 1️⃣ Test syntaxe

```bash
sudo /var/ossec/bin/wazuh-logtest
# Résultat : INFO: Rule test: OK
```

### 2️⃣ Recharger Wazuh

```bash
sudo systemctl restart wazuh-manager
sudo systemctl status wazuh-manager
```

### 3️⃣ Test : Sudo refusé (100010)

Sur le serveur Rocky, user normal :

```bash
# User normal (pas en sudoers)
user1$ sudo cat /etc/shadow
[sudo] password for user1:
user1 is not in the sudoers file. This incident will be reported.

# Vérifier la ligne de log
sudo grep "NOT in sudoers" /var/log/secure
```

Vérifier l'alerte Wazuh :

```bash
# Sur VM SOC
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100010")'
```

Résultat attendu :
```json
{
  "rule": {
    "id": "100010",
    "level": 6,
    "description": "Sudo: User NOT in sudoers file"
  },
  "data": {
    "srcip": "127.0.0.1"
  }
}
```

---

### 4️⃣ Test : Commande dangereuse (100012)

User autorisé en sudoers :

```bash
# Ajouter user à sudoers (une seule fois)
sudo visudo
# Ajouter : user1 ALL=(ALL) ALL

# Maintenant, user1 peut faire sudo
user1$ sudo cat /etc/shadow
root:!:...
```

Vérifier l'alerte :

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100012")'
```

Résultat :
```json
{
  "rule": {
    "id": "100012",
    "level": 8,
    "description": "Sudo: Dangerous command executed"
  },
  "data": {
    "command": "cat /etc/shadow"
  }
}
```

---

### 5️⃣ Test : Sudo brute force (100013)

Simuler 10 tentatives refusées rapidement :

```bash
# Script pour générer 10 tentatives échouées
for i in {1..10}; do
  sudo cat /etc/shadow 2>&1 >/dev/null
  sleep 1
done
```

Ou avec `watch` :

```bash
watch -n 1 'sudo ls' 2>&1 | head -10
```

Alerte dans Wazuh :
```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100013")'
```

---

## 8. Améliorer la détection

### Ajouter des commandes dangereuses

Édite la regex de la règle 100012 :

```xml
<!-- Ajouter ces commandes -->
<regex>COMMAND=(.*\bcat\s+/etc/(shadow|passwd|sudoers|group)|.*\brm\s+-rf|.*\bchmod\s+777|.*\bawk.*BEGIN|.*\bperl.*-e|.*\bpython.*-c|.*\breversh\.exe)</regex>
```

**Nouvelles cibles** :
- `/etc/group` → Liste des groupes
- `awk/perl/python` → Scripts exécutés comme root
- `reversesh.exe` → Windows reverse shell

---

### Différencier par user

Si tu veux alerter **uniquement** sur root utilisant sudo (rare) :

```xml
<rule id="100012_root_only" level="9">
  <if_sid>100011</if_sid>
  <regex>sudo: root.*COMMAND=</regex>
  <description>Sudo: Root user executing commands (double privilege)</description>
  <group>critical,</group>
</rule>
```

**Cas d'usage** : Les vrais administrateurs ne utilisent **jamais** `sudo` en tant que root

---

## 9. Exemple : Simulation d'attaque

Scénario : Attaquant compromet user1, tente sudo pour escalader

### Étape 1 : Configuration

```bash
# Ajouter user1 en sudoers
echo "user1 ALL=(ALL) ALL" | sudo tee -a /etc/sudoers

# Créer un script malveillant
cat > /tmp/malware.sh << 'EOF'
#!/bin/bash
cat /etc/shadow > /tmp/stolen_passwords.txt
rm -rf /var/www/html
EOF

chmod +x /tmp/malware.sh
```

### Étape 2 : Simulation d'attaque

```bash
# Se faire passer pour user1
user1$ sudo /tmp/malware.sh

# Vu depuis les logs :
# sudo: user1 : TTY=pts/1 ; ... ; COMMAND=/tmp/malware.sh
# → Avec regex : cat /etc/shadow + rm -rf
```

### Étape 3 : Alertes Wazuh

```bash
sudo tail -50 /var/ossec/logs/alerts/alerts.json | jq '.rule | select(.id | inside(["100011", "100012"]))'
```

Résultat :
- Alerte 100011 : Sudo command executed (level 3)
- Alerte 100012 : Dangerous command detected (level 8) ← VRAI PROBLÈME

---

## 10. Intégration avec Playbooks IR

Si tu veux automatiser la réaction :

```xml
<rule id="100012" level="8">
  <if_sid>100011</if_sid>
  <regex>COMMAND=(...)</regex>
  <description>Sudo: Dangerous command</description>
  <group>dangerous_command,</group>
  
  <!-- Déclencher script incident response -->
  <active-response>
    <command>custom-response</command>
    <location>local</location>
    <timeout>300</timeout>  <!-- 5 minutes -->
  </active-response>
</rule>
```

---

## 11. Vérification complète

### Checklist

- [ ] Règles 100010-100013 dans `local_rules.xml`
- [ ] Syntaxe valide (`wazuh-logtest`)
- [ ] Wazuh redémarré
- [ ] Test 100010 (sudo NOT in sudoers)
- [ ] Test 100011 (sudo réussi s'affiche)
- [ ] Test 100012 (commande dangereuse alerte)
- [ ] Test 100013 (brute force sudo)
- [ ] Dashboard Wazuh montre les 4 alertes

### Logs à surveiller

```bash
# Serveur web
sudo grep "sudo" /var/log/secure | tail -20

# VM SOC
sudo tail -f /var/ossec/logs/alerts/alerts.json | grep "100010\|100011\|100012\|100013"
```

---

## 12. Bonnes pratiques

### ✅ À faire

```xml
<regex>COMMAND=(\.\*/bin/(cat|vim|less)\s+/etc/(shadow|passwd))</regex>  <!-- Spécifique -->
<frequency>5</frequency>    <!-- Raisonnable -->
<level>8</level>            <!-- Cohérent -->
```

### ❌ À éviter

```xml
<match>sudo</match>         <!-- ❌ Trop vague, va matcher tout -->
<frequency>1000</frequency> <!-- ❌ Ne va jamais déclencher -->
<level>15</level>           <!-- ❌ Trop dramatique pour une baseline -->
```

---

## 📚 Ressources

```bash
# Regex tester online
# https://regex101.com/

# Voir logs sudo bruts
sudo tail -100 /var/log/secure | grep "sudo"

# Voir alertes Wazuh
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.rule'

# Test regex localement
grep -P "cat.*shadow" <<< "COMMAND=cat /etc/shadow"
```

---

**Durée réelle** : 1 heure (30 min règles + 30 min tests)  
**Compétences** : Regex, détection escalade, baseline monitoring  
**Prochaine étape** : Détection Nmap/Port scanning
