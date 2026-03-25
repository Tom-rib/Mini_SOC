# Règles Wazuh : Syntaxe et Structure

**Durée d'étude : 45 minutes**  
**Objectif** : Comprendre comment fonctionnent les règles Wazuh et où les placer

---

## 📌 Objectifs clés

À la fin de cette fiche, tu pourras :
- Lire une règle XML Wazuh
- Comprendre chaque paramètre (match, regex, level, frequency)
- Savoir où placer tes règles personnalisées
- Créer une simple règle de détection

---

## 1. Qu'est-ce qu'une règle Wazuh ?

Une **règle** est un pattern (motif) qui dit à Wazuh : "Si tu vois **ceci** dans les logs, **alerter** avec cette priorité".

**Exemple simple** :
```
Si tu vois "Failed password for" dans /var/log/secure
→ C'est une tentative de connexion échouée
→ Crée une alerte "niveau 3"
```

---

## 2. Structure complète d'une règle XML

Voici la structure générale :

```xml
<rule id="100500" level="5">
  <if_sid>Some_ID</if_sid>
  <match>^Failed password</match>
  <description>Échec de connexion SSH</description>
  <group>ssh_authentication,</group>
</rule>
```

### Expliquons chaque élément :

| Élément | Exemple | Signification |
|---------|---------|---------------|
| `id` | `id="100500"` | Numéro unique de la règle (doit être >100000 pour custom) |
| `level` | `level="5"` | Sévérité de 0 à 15 (voir tableau ci-dessous) |
| `if_sid` | `if_sid="5701"` | ID de la règle parente (optionnel, pour les sous-règles) |
| `match` | `match="Failed password"` | Texte exact à rechercher |
| `regex` | `regex="^sudo:.*COMMAND="` | Expression régulière plus flexible |
| `description` | `description="Échec SSH"` | Texte de l'alerte dans Wazuh |
| `group` | `group="ssh_authentication,"` | Catégorie de la règle (finit par virgule) |
| `frequency` | `frequency="5"` | Nombre d'occurrences avant alerte |
| `timeframe` | `timeframe="60"` | Durée en secondes pour frequency |

---

## 3. Niveaux d'alerte (severity levels)

```
Level 0-2    = Debug/Info         (ne pas alerter)
Level 3      = Attention          (faible sévérité)
Level 4-5    = Warning            (à surveiller)
Level 6-7    = Error              (problème détecté)
Level 8-9    = Alert              (action requise)
Level 10-11  = Critical           (incident sérieux)
Level 12-15  = Emergency          (incident critique)
```

**Pour ton projet Blue Team** :
- Brute force SSH → **Level 7** (Error)
- Commandes sudo anormales → **Level 8** (Alert)
- Nmap/Port scan → **Level 6** (Error)
- Upload fichier suspect → **Level 9** (Alert)
- Accès hors horaires → **Level 5** (Warning)

---

## 4. Match vs Regex

### Match (simple)
Cherche du texte **exact** :
```xml
<match>Failed password</match>
```
✅ Rapide et simple  
❌ Pas flexible

### Regex (puissant)
Cherche un **motif** (expression régulière) :
```xml
<regex>^Failed password for \w+ from (\d+\.\d+\.\d+\.\d+)</regex>
```
✅ Super flexible  
❌ Plus lent

**Exemples regex utiles** :

```regex
^Failed password        = commence par "Failed password"
.*command.*             = contient "command" n'importe où
COMMAND=\S+             = capture le contenu après COMMAND=
(\d+\.\d+\.\d+\.\d+)    = capture une adresse IP
sudo: \w+               = sudo suivi d'un mot
```

---

## 5. Frequency et Timeframe

Pour détecter les **attaques par brute force** ou **comportements répétitifs**.

```xml
<frequency>5</frequency>      <!-- Alerte après 5 occurrences -->
<timeframe>60</timeframe>      <!-- dans une fenêtre de 60 secondes -->
```

**Exemple concret** :
```xml
<frequency>5</frequency>
<timeframe>60</timeframe>
```
= "Si tu vois 5 fois 'Failed password' en 60 secondes → alerte"

---

## 6. Où placer tes règles ?

Les règles **personnalisées** doivent aller dans :

```
/var/ossec/etc/rules/local_rules.xml
```

**Structure du fichier** :

```xml
<!-- Fichier: /var/ossec/etc/rules/local_rules.xml -->

<group name="local_rules,">
  <group name="ssh_hardening,">
    <rule id="100500" level="5">
      <match>Failed password</match>
      <description>SSH login failed</description>
    </rule>
  </group>

  <group name="sudo_monitoring,">
    <rule id="100510" level="8">
      <regex>sudo: \w+</regex>
      <description>Sudo command executed</description>
    </rule>
  </group>
</group>
```

---

## 7. Exemple complet : Règle brute force SSH

Voici une **vraie règle** que tu vas utiliser :

```xml
<rule id="100500" level="7">
  <if_sid>5701</if_sid>
  <match>Failed password</match>
  <frequency>5</frequency>
  <timeframe>60</timeframe>
  <description>SSH: Probable brute force attack detected</description>
  <group>ssh_attack,authentication_failure,</group>
</rule>
```

**Décodage** :
- `if_sid="5701"` → Ne déclencher QUE si c'est un échec SSH (règle parente)
- `match="Failed password"` → Chercher cet exact texte
- `frequency="5" timeframe="60"` → 5 fois en 60 secondes = attaque
- `level="7"` → Sévérité "Error" (assez grave)
- `group="ssh_attack,..."` → Pour filtrer dans Wazuh

---

## 8. Ajouter des métadonnées avancées

Optionnel mais utile :

```xml
<rule id="100500" level="7">
  <if_sid>5701</if_sid>
  <match>Failed password</match>
  <frequency>5</frequency>
  <timeframe>60</timeframe>
  
  <!-- Infos supplémentaires -->
  <description>SSH: Brute force attack</description>
  <mitre>
    <id>T1110</id>      <!-- MITRE ATT&CK : Brute Force -->
  </mitre>
  <cis>
    <cis_level>1</cis_level>
  </cis>
  <group>ssh_attack,authentication_failure,</group>
</rule>
```

---

## 9. Bonnes pratiques

### ✅ À faire

```xml
<!-- Règle bien structurée -->
<rule id="100555" level="8">
  <if_sid>5701</if_sid>
  <match>Failed password</match>
  <frequency>5</frequency>
  <timeframe>60</timeframe>
  <description>SSH: Multiple failed login attempts</description>
  <group>ssh_authentication,attack,</group>
</rule>
```

### ❌ À éviter

```xml
<!-- IDs non unique ou trop bas -->
<rule id="1000">    <!-- ❌ < 100000 -->

<!-- Match trop vague -->
<rule id="100500">
  <match>failed</match>    <!-- ❌ Trop général, va matcher partout -->

<!-- Level incohérent -->
<rule id="100500" level="15">   <!-- ❌ Trop grave pour juste un SSH failed -->
```

---

## 10. Vérification : Syntaxe de ta première règle

### ✅ Checklist avant de mettre en production

- [ ] ID unique (> 100000)
- [ ] Level entre 0-15
- [ ] Match ou regex valide
- [ ] Description claire
- [ ] Group avec virgule finale
- [ ] Frequency + timeframe cohérents
- [ ] if_sid correct (si utilisé)

### Test syntaxe

```bash
# Vérifier que Wazuh accepte ta règle
sudo /var/ossec/bin/wazuh-logtest

# Tu devrais voir :
# INFO: Reading local rules file.
# INFO: Rule test: OK
```

---

## 11. Résumé des fichiers à modifier

| Fichier | Action | Quand |
|---------|--------|-------|
| `/var/ossec/etc/rules/local_rules.xml` | Ajouter tes règles | À chaque nouvelle règle |
| `/var/ossec/etc/ossec.conf` | Activer logging | Une fois au départ |
| Logs serveur web | Envoyer à Wazuh | Configuration rsyslog |

---

## 12. Prochaines étapes

Maintenant que tu comprends la syntaxe, tu vas créer :

1. **10_detection_bruteforce_ssh.md** → Règle brute force SSH (frequency)
2. **11_detection_sudo.md** → Règle sudo avec regex
3. **12_detection_nmap.md** → Règle nmap/port scan
4. **13_detection_uploads.md** → Règle file integrity monitoring
5. **14_detection_horaires.md** → Règle horaires anormaux

Chacune sera plus spécialisée et testera un aspect différent.

---

## 📚 Ressources utiles

```bash
# Voir toutes les règles existantes
ls -la /var/ossec/etc/rules/

# Tester ton regex
echo "Failed password for user from 192.168.1.100" | grep -E "Failed password for \w+"

# Recharger les règles Wazuh
sudo systemctl restart wazuh-manager
```

---

**Durée réelle** : 45 minutes (lecture + tests)  
**Compétences acquises** : Syntaxe Wazuh, création règles basiques, niveaux d'alerte
