# Détection Brute Force SSH

**Durée estimée : 1 heure**  
**Niveau : Intermédiaire**  
**Objectif** : Détecter 5+ tentatives de connexion SSH échouées en 60 secondes

---

## 📌 Objectifs

À la fin de cette fiche, tu pourras :
- Créer une règle Wazuh pour détecter brute force SSH
- Tester avec l'outil `hydra`
- Voir les alertes en temps réel dans Wazuh
- Comprendre frequency + timeframe

---

## 1. Contexte : Qu'est-ce qu'une attaque brute force SSH ?

### Le problème

Un attaquant tente de **deviner le mot de passe** en testant des centaines de combinaisons rapidement.

```
Attaquant → tente user1:password1 → FAILED
         → tente user1:password2 → FAILED
         → tente user1:password3 → FAILED  ← Détecte ici
         → tente user1:password4 → FAILED
         → tente user1:password5 → FAILED
```

### Comment ça se voit dans les logs ?

Le serveur Rocky génère une ligne **pour chaque tentative échouée** :

```
Jan 15 14:32:01 rockysrv sshd[1234]: Failed password for root from 192.168.1.50 port 52341 ssh2
Jan 15 14:32:02 rockysrv sshd[1235]: Failed password for root from 192.168.1.50 port 52342 ssh2
Jan 15 14:32:03 rockysrv sshd[1236]: Failed password for root from 192.168.1.50 port 52343 ssh2
```

**Wazuh doit dire** : "Hé, 5 échecs en 60 secondes, c'est suspect !"

---

## 2. Les règles à créer

Nous allons créer **2 règles** :
- **Règle 1** : Détecter UN échec SSH (règle parente)
- **Règle 2** : Détecter 5+ échecs en 60s (règle child avec frequency)

### Pourquoi 2 règles ?

- La règle 1 déclenche à chaque log SSH
- La règle 2 agrège la règle 1 avec frequency + timeframe
- C'est plus modularisé et réutilisable

---

## 3. Fichier à éditer

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

**Contenu initial** (s'il est vide) :

```xml
<!-- vim: syntax=xml ts=2 sw=2 expandtab
     filename: local_rules.xml
     This file contains the local custom rules
-->

<group name="local_rules,">

  <!-- RÈGLES SSH -->
  <group name="ssh_authentication,">
    
  </group>

</group>
```

---

## 4. Règles complètes

Copie **exactement** ces 2 règles dans `local_rules.xml` :

```xml
<!-- ============================================
     RÈGLE 1 : Détecter tout échec SSH
     ============================================ -->

<rule id="100001" level="3">
  <if_sid>5701</if_sid>
  <match>Failed password</match>
  <description>SSH: Failed login attempt</description>
  <group>ssh_authentication,</group>
</rule>

<!-- ============================================
     RÈGLE 2 : Brute force SSH (5+ essais/60s)
     ============================================ -->

<rule id="100002" level="7">
  <if_sid>100001</if_sid>
  <frequency>5</frequency>
  <timeframe>60</timeframe>
  <same_source_ip />
  <description>SSH: Brute force attack detected (5+ failed logins in 60 seconds)</description>
  <group>ssh_attack,authentication_failure,</group>
  <mitre>
    <id>T1110</id>  <!-- MITRE: Brute Force -->
  </mitre>
</rule>
```

### Expliquons ligne par ligne

#### Règle 1 (id=100001)

```xml
<rule id="100001" level="3">
```
- `id="100001"` → Numéro unique, > 100000
- `level="3"` → Faible priorité (juste info)

```xml
<if_sid>5701</if_sid>
```
- `5701` = l'ID de la règle Wazuh interne pour "SSH Failed"
- **Très important** : sinon on va matcher TOUS les logs

```xml
<match>Failed password</match>
```
- Cherche ce texte exact dans `/var/log/secure`

```xml
<description>SSH: Failed login attempt</description>
<group>ssh_authentication,</group>
```
- Description de ce qu'on détecte
- Group pour classifier (SSH auth)

#### Règle 2 (id=100002) - LA VRAIE ALERTE

```xml
<rule id="100002" level="7">
  <if_sid>100001</if_sid>
```
- `if_sid="100001"` → Ne déclencher QUE si règle 1 est vraie
- `level="7"` → **Error** = c'est grave (brute force)

```xml
<frequency>5</frequency>
<timeframe>60</timeframe>
```
- **5 occurrences** dans **60 secondes** = alerte
- C'est le cœur de la détection

```xml
<same_source_ip />
```
- **CRUCIAL** : compte les 5 tentatives du **même attaquant**
- Sans ça, 5 échecs de différentes IP = alerte (faux positif)

```xml
<group>ssh_attack,authentication_failure,</group>
```
- Cette alerte est un "ssh_attack" et "authentication_failure"

---

## 5. Vérifier la syntaxe

Avant de recharger Wazuh, teste ta configuration :

```bash
# Vérifier syntaxe XML
sudo /var/ossec/bin/wazuh-logtest
```

Résultat attendu :
```
INFO: Reading local rules file.
INFO: Rule test: OK
wazuh> 
```

Si tu as une erreur de syntaxe, elle s'affichera ici.

---

## 6. Recharger Wazuh

```bash
# Redémarrer le manager Wazuh
sudo systemctl restart wazuh-manager

# Vérifier que c'est OK
sudo systemctl status wazuh-manager

# Voir les logs si problème
sudo tail -f /var/ossec/logs/ossec.log
```

---

## 7. Test pratique : Générer une attaque brute force

Tu vas utiliser **hydra** pour simuler une attaque brute force contre le serveur SSH.

### Avant : Prépare 2 terminaux

**Terminal 1 (Monitoring Wazuh)** :
```bash
# Sur la VM SOC, voir les alertes en temps réel
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.'
```

**Terminal 2 (Hydra attack)** :
```bash
# Sur la machine attaquante (ou ta machine locale)
# Si pas de Kali, installe hydra
sudo apt-get install hydra
```

### Commande hydra

```bash
# Attaque brute force SSH 
# Remplace IP_SERVEUR par l'IP du serveur Rocky web

hydra -l root -P /usr/share/wordlists/rockyou.txt \
  -t 4 \
  -u \
  IP_SERVEUR ssh
```

**Expliquons les paramètres** :

| Param | Signification |
|-------|---------------|
| `-l root` | Essayer avec le user **root** |
| `-P rockyou.txt` | Liste de mots de passe (énorme) |
| `-t 4` | 4 tentatives **simultanées** |
| `-u` | Essayer tous les mots de passe pour chaque user |
| `ssh` | Protocole à attaquer |

### Attaque simplifié pour test rapide

Si rockyou.txt est trop gros, crée ta propre liste :

```bash
# Sur machine attaquante
cat > simple_passwords.txt << 'EOF'
password1
password2
password3
password4
password5
wrongpassword1
wrongpassword2
EOF

# Attaque
hydra -l root -P simple_passwords.txt -t 4 IP_SERVEUR ssh
```

---

## 8. Vérifier les résultats

### Sur le serveur Rocky (VM Web)

**Terminal serveur** :
```bash
# Voir les échecs SSH
sudo tail -100 /var/log/secure | grep "Failed password"

# Exemple de sortie :
# Jan 15 14:32:01 rockysrv sshd[1234]: Failed password for root from 192.168.1.50 port 52341 ssh2
# Jan 15 14:32:02 rockysrv sshd[1235]: Failed password for root from 192.168.1.50 port 52342 ssh2
# ...
```

### Sur la VM SOC (Wazuh Manager)

**Terminal 1 (les alertes)** :
```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100002")'
```

Résultat attendu (alerte brute force) :
```json
{
  "timestamp": "2025-01-15T14:32:15.000+0000",
  "rule": {
    "level": 7,
    "description": "SSH: Brute force attack detected (5+ failed logins in 60 seconds)",
    "id": "100002",
    "groups": ["ssh_attack", "authentication_failure"]
  },
  "agent": {
    "id": "002",
    "name": "rockysrv"
  },
  "data": {
    "srcip": "192.168.1.50"
  }
}
```

### Dashboard Wazuh Web

Accès l'interface Wazuh : `https://IP_SOC:443`

1. Menu → **Threat Detection**
2. Filtre : **Rule ID = 100002**
3. Tu devrais voir : "SSH: Brute force attack detected"

---

## 9. Affiner la détection

Si tu as **trop de faux positifs**, ajuste :

### Augmenter frequency
```xml
<frequency>10</frequency>  <!-- Attendre 10 tentatives -->
<timeframe>60</timeframe>
```

### Diminuer si trop lent à détecter
```xml
<frequency>3</frequency>   <!-- Alerte déjà après 3 -->
<timeframe>30</timeframe>  <!-- En 30 secondes -->
```

**Bon équilibre** :
```xml
<frequency>5</frequency>
<timeframe>60</timeframe>
```
= 5 échecs en 1 minute = probablement une attaque

---

## 10. Ajouter une réaction automatique (Optionnel)

Tu peux faire bloquer l'IP automatiquement. Ajoute à ta règle :

```xml
<rule id="100002" level="7">
  <if_sid>100001</if_sid>
  <frequency>5</frequency>
  <timeframe>60</timeframe>
  <same_source_ip />
  <description>SSH: Brute force attack detected</description>
  <group>ssh_attack,authentication_failure,</group>
  
  <!-- Bloquer l'IP avec fail2ban -->
  <active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <timeout>600</timeout>  <!-- Bloquer 10 min -->
  </active-response>
</rule>
```

---

## 11. Résumé de la détection

| Étape | Action |
|-------|--------|
| 1 | Créer règles dans `/var/ossec/etc/rules/local_rules.xml` |
| 2 | Tester syntaxe : `wazuh-logtest` |
| 3 | Recharger : `systemctl restart wazuh-manager` |
| 4 | Lancer attaque : `hydra -l root -P list.txt IP ssh` |
| 5 | Vérifier logs : `tail -f /var/log/secure` |
| 6 | Vérifier alertes Wazuh : dashboard ou JSON logs |

---

## 12. Checklist de validation

- [ ] Règles XML syntaxiquement correctes
- [ ] `wazuh-logtest` passe sans erreur
- [ ] Wazuh redémarré avec succès
- [ ] Agent Wazuh collecte `/var/log/secure`
- [ ] Hydra génère 5+ tentatives en 60s
- [ ] Alerte id=100002 trigger dans Wazuh
- [ ] Level=7 s'affiche (Error)
- [ ] IP attaquant est visible dans l'alerte

---

## 13. Logs à surveiller

### Logs serveur web (/var/log/secure)
```
Jan 15 14:32:01 rockysrv sshd[1234]: Failed password for root from 192.168.1.50 port 52341 ssh2
```

### Logs Wazuh (/var/ossec/logs/alerts/alerts.json)
```json
{
  "rule": {"id": "100002", "level": 7},
  "data": {"srcip": "192.168.1.50"}
}
```

### Logs SSH sur le serveur
```bash
sudo grep "Failed password" /var/log/secure | wc -l
# Devrait montrer 5+
```

---

## 14. Troubleshooting

### Pas d'alerte malgré l'attaque ?

```bash
# 1. Vérifier que l'agent envoie les logs
sudo grep -c "Failed password" /var/ossec/logs/alerts/alerts.json

# 2. Vérifier que la règle 100001 déclenche
sudo tail -f /var/ossec/logs/alerts/alerts.json | grep "100001"

# 3. Vérifier la connexion agent-manager
sudo /var/ossec/bin/agent_control -l
```

### Logs SSH n'arrive pas à Wazuh ?

```bash
# Vérifier que rsyslog/filebeat envoie vers Wazuh
sudo tail -f /var/ossec/logs/ossec.log | grep "Received from"

# Si rien, reconfigurer :
# Voir fichier 08_centralization_logs.md
```

---

## 📚 Fichiers importants

```
/var/ossec/etc/rules/local_rules.xml     ← Tes règles custom
/var/log/secure                           ← Logs SSH serveur
/var/ossec/logs/alerts/alerts.json        ← Alertes Wazuh
/var/ossec/etc/ossec.conf                 ← Config Wazuh
```

---

**Durée réelle** : 1 heure (45 min comprendre + 15 min test)  
**Compétences** : Frequency, timeframe, aggregation, test attaque  
**Prochaine étape** : Détection sudo avancée
