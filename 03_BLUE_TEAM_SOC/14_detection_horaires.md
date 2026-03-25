# Détection Accès Hors Horaires

**Durée estimée : 1 heure**  
**Niveau : Avancé**  
**Objectif** : Détecter les connexions SSH en dehors des heures normales de travail

---

## 📌 Objectifs

À la fin de cette fiche, tu pourras :
- Créer des règles avec contraintes de **temps** (time_window)
- Détecter connexions anormales (minuit, weekend, vacances)
- Différencier accès légitimes vs suspects
- Alerter sur comportement en dehors horaires

---

## 1. Contexte : Détection comportementale

### Qu'est-ce qu'un accès hors horaires ?

**En entreprise normale** :
- Les utilisateurs travaillent **8h - 18h**
- Lundi à vendredi
- Pas de connexion SSH à 3h du matin

**Accès suspects** :
```
Jan 15 03:15:42 rockysrv sshd: Accepted publickey for user1 from 192.168.1.50
                 ↓ 3h15 du matin = TRÈS SUSPECT
```

### Significations possibles

1. **Attaquant a compromis le compte** → SSH depuis IP étrangère à 3h
2. **Admin urgence** → Connexion admin vendredi 22h (acceptable mais à surveiller)
3. **Teletravail** → Connexion depuis home office à 19h (normal, à whitelist)

---

## 2. Horaires de travail à définir

### Par défaut (entreprise standard)

```
Jours travail   : Lundi-Vendredi
Heures travail  : 08:00 - 18:00

Hors horaires suspects :
- Avant 08:00  (nuit/tôt matin)
- Après 18:00  (soir/nuit)
- Weekend (samedi/dimanche)
- Vacances (à définir)
```

### Cas d'usage en projet cybersec

```
Scenario 1 : Dev normal
- 9h-17h, lundi-vendredi
- OU le soir pour maintenance (22h-23h) = acceptable

Scenario 2 : Attaquant
- 2h du matin, mardi
- IP différente de d'habitude
- Multiples connexions échouées avant réussite
```

---

## 3. Problème : Wazuh ne supporte pas nativement les jours

**Limitation** : Wazuh n'a pas de "day of week" natif en règles XML.

**Solution** : 
1. Créer plusieurs règles (une par scénario)
2. Utiliser `<time_window>` pour heure (0-24)
3. Documenter les jours en regex (moins précis)

---

## 4. Stratégie de détection

Nous allons créer **4 règles** :

| ID | Scénario | Level | Condition |
|----|----------|-------|-----------|
| 100040 | SSH réussi (baseline) | 2 | `Accepted` |
| 100041 | SSH hors horaires (night) | 6 | Accepted + 00:00-07:59 |
| 100042 | SSH week-end (samedi/dimanche pattern) | 6 | Accepted + pattern "sunday\|saturday" |
| 100043 | SSH + failed précédent | 8 | Accepted après 5+ failed |

**Limitation** : Sans jour de la semaine natif, on va utiliser:
- **Time window** pour les heures (précis)
- **Regex** pour essayer de détecter jour (moins fiable)

---

## 5. Approche alternative : Anomaly Detection

Wazuh peut aussi **apprendre** les patterns normaux et alerter sur déviation.

```
Jours 1-5 : SSH 9h-17h depuis IP 192.168.1.100
Jour 6     : SSH 2h du matin depuis IP 192.168.1.200
             ↓ = Déviation normale = ALERTE
```

Cette approche est plus flexible mais plus complexe.

---

## 6. Règles XML (approche simplifiée)

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

```xml
<!-- ============================================
     DÉTECTION HORS HORAIRES
     ============================================ -->

<group name="time_based_detection,">

  <!-- RÈGLE 1 : SSH réussi (baseline) -->
  <rule id="100040" level="2">
    <if_sid>5715</if_sid>  <!-- Wazuh SSH accepted -->
    <match>Accepted</match>
    <description>SSH: Successful login</description>
    <group>ssh_authentication,</group>
  </rule>

  <!-- RÈGLE 2 : SSH hors horaires (00:00 - 07:59) -->
  <rule id="100041" level="6">
    <if_sid>100040</if_sid>
    <time_window>00:00 - 07:59</time_window>
    <description>SSH: Login outside working hours (night time 00:00-07:59)</description>
    <group>time_based_attack,suspicious_access,</group>
    <mitre>
      <id>T1021</id>  <!-- MITRE: Remote Services -->
    </mitre>
  </rule>

  <!-- RÈGLE 3 : SSH très tôt matin (04:00-06:00) -->
  <rule id="100042" level="7">
    <if_sid>100040</if_sid>
    <time_window>04:00 - 06:00</time_window>
    <description>SSH: Login at unusual time (4AM-6AM - very suspicious)</description>
    <group>time_based_attack,suspicious_access,</group>
  </rule>

  <!-- RÈGLE 4 : SSH late evening (21:00 - 23:59) -->
  <rule id="100043" level="5">
    <if_sid>100040</if_sid>
    <time_window>21:00 - 23:59</time_window>
    <description>SSH: Login during late evening (21:00-23:59)</description>
    <group>time_based_access,</group>
  </rule>

  <!-- RÈGLE 5 : SSH après failed attempts (brute force) -->
  <rule id="100044" level="8">
    <if_sid>100040</if_sid>
    <if_matched_group>authentication_failure</if_matched_group>
    <timeframe>300</timeframe>  <!-- Dans les 5 minutes -->
    <description>SSH: Successful login after multiple failed attempts (brute force success)</description>
    <group>brute_force,successful_attack,</group>
  </rule>

  <!-- RÈGLE 6 : Multiple SSH à different hours (anomaly) -->
  <rule id="100045" level="6">
    <if_sid>100040</if_sid>
    <frequency>3</frequency>
    <timeframe>300</timeframe>
    <same_user />
    <description>SSH: Multiple logins by same user in short time (possible account hijacking)</description>
    <group>account_hijacking,</group>
  </rule>

</group>
```

---

## 7. Explication détaillée

### Règle 100040 : Baseline

```xml
<rule id="100040" level="2">
  <if_sid>5715</if_sid>
  <match>Accepted</match>
  <description>SSH: Successful login</description>
</rule>
```

**Quand ça trigger** :
```
Jan 15 14:32:01 rockysrv sshd: Accepted publickey for user1 from 192.168.1.50 port 52341
                 ↓ Accepté = connexion réussie
```

**Level 2** = Info (connexion SSH normale)

---

### Règle 100041 : Hors horaires (00:00-07:59)

```xml
<rule id="100041" level="6">
  <if_sid>100040</if_sid>
  <time_window>00:00 - 07:59</time_window>
  <description>SSH: Login outside working hours</description>
  <group>time_based_attack,suspicious_access,</group>
</rule>
```

**Quand ça trigger** :
```
Heure locale : 3h30 du matin
SSH accepté : user1 from 192.168.1.50
→ ALERTE level 6 = Error
```

**time_window** :
- Format : `HH:MM - HH:MM`
- Toutes les heures entre 00:00 et 07:59
- Fuseau horaire du serveur

**Level 6** = Error (connexion en dehors heures = anormal)

---

### Règle 100042 : Très tôt matin (04:00-06:00)

```xml
<rule id="100042" level="7">
  <if_sid>100040</if_sid>
  <time_window>04:00 - 06:00</time_window>
  <description>SSH: Very unusual time (4AM-6AM)</description>
</rule>
```

**Cas d'usage** :
- 4h-6h du matin = **jamais normal**
- Si connexion SSH à cette heure = très suspect
- Level 7 (plus grave que 100041)

---

### Règle 100043 : Soirée tardive (21:00-23:59)

```xml
<rule id="100043" level="5">
  <if_sid>100040</if_sid>
  <time_window>21:00 - 23:59</time_window>
  <description>SSH: Late evening (9PM-11:59PM)</description>
</rule>
```

**Logique** :
- 21h-23h = peut être admin en urgence
- Less grave than night (niveau 5 vs 6)
- À adapter selon culture d'entreprise

---

### Règle 100044 : Succès après failed (brute force réussi)

```xml
<rule id="100044" level="8">
  <if_sid>100040</if_sid>
  <if_matched_group>authentication_failure</if_matched_group>
  <timeframe>300</timeframe>
  <description>Successful login after multiple failed attempts</description>
</rule>
```

**Quand ça trigger** :
```
Chronologie :
14:32:01 - Accepted publickey for user1
14:32:02 - Failed password (règle 5701) ← authentication_failure
14:32:03 - Failed password
...
14:32:10 - Accepted ← ALERTE 100044 déclenche
```

**if_matched_group** :
- "Si groupe authentication_failure a déclenché dans les X secondes"
- Très utile pour chaîner des événements

**Level 8** = Alert (brute force réussi = compromission probable)

---

### Règle 100045 : Multiples connexions rapides (hijacking)

```xml
<rule id="100045" level="6">
  <if_sid>100040</if_sid>
  <frequency>3</frequency>
  <timeframe>300</timeframe>
  <same_user />
  <description>Multiple logins by same user in short time</description>
</rule>
```

**Quand ça trigger** :
```
Même utilisateur se connecte 3 fois en 5 minutes
= Possible attaquant essayant différentes sessions
```

**same_user** : Compte les occurrences du **même user** (pas IP)

---

## 8. Tester les règles

### Étape 1 : Vérifier syntax

```bash
sudo /var/ossec/bin/wazuh-logtest
# Doit afficher : INFO: Rule test: OK
```

### Étape 2 : Recharger Wazuh

```bash
sudo systemctl restart wazuh-manager
sudo systemctl status wazuh-manager
```

### Étape 3 : Test de nuit (00:00-07:59)

On ne peut pas vraiment changer l'heure système, donc on va tester autrement.

**Option 1 : Éditer les logs manuellement**

```bash
# Créer une entrée SSH avec heure modifiée
cat >> /var/log/secure << 'EOF'
Jan 15 03:15:42 rockysrv sshd[1234]: Accepted publickey for testuser from 192.168.1.100 port 52341 ssh2
EOF

# Wazuh devrait alerter (alerte 100041 ou 100042)
```

**Option 2 : Utiliser wazuh-logtest interactif**

```bash
sudo /var/ossec/bin/wazuh-logtest

# Copier-coller une ligne de log SSH
Jan 15 03:15:42 rockysrv sshd[1234]: Accepted publickey for testuser from 192.168.1.100 port 52341

# Appuyer sur Enter
# Wazuh analyse en se basant sur l'heure du log
```

### Étape 4 : Vérifier les alertes

```bash
# Sur VM SOC
sudo tail -f /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100041" or .rule.id=="100042" or .rule.id=="100043")'
```

---

## 9. Cas d'usage : Attaquant compromet un compte

### Scénario

Attaquant a obtenu les credentials de user1. Il essaie une connexion tard le soir (risqué).

### Événements

```
Jan 15 22:45:10 rockysrv sshd[1234]: Accepted publickey for user1 from 192.168.1.150
                                      ↓
                          Alerte 100043 (level 5) : Late evening
                          + Alerte 100040 (level 2) : Normal SSH

Jan 15 22:45:15 rockysrv sshd[1235]: Accepted publickey for user1 from 192.168.1.150
                                      ↓
                          Alerte 100045 (level 6) : Multiple logins (même user 2x en 5s)
```

### Incident Response

```
1. Vérifier source IP 192.168.1.150
2. Vérifier avec user1 : "As-tu accédé SSH à 22:45 ?"
3. Si NON → Compte compromis
4. Actions :
   - Réinitialiser mot de passe user1
   - Forcer déconnexion des sessions SSH
   - Auditer les commandes exécutées
```

---

## 10. Adapter les horaires

### Pour télétravail (horaires flexibles)

```xml
<!-- Élargir la fenêtre d'horaires normaux -->
<rule id="100041" level="5">  <!-- Level moins grave -->
  <if_sid>100040</if_sid>
  <time_window>22:00 - 06:00</time_window>  <!-- 22h - 6h = travail accepté -->
  <description>SSH: Unusual time for normal work</description>
</rule>
```

### Pour équipe 24/7 (ops, support)

```xml
<!-- Enlever les règles de temps ou les adapter -->
<rule id="100041" level="2">  <!-- Pas d'alerte -->
  <if_sid>100040</if_sid>
  <time_window>00:00 - 23:59</time_window>  <!-- Tout est normal -->
  <description>SSH: Any time ok for operations team</description>
</rule>
```

### Pour période de vacances

```xml
<!-- Désactiver temporairement les alertes hors horaires -->
<!-- Ou créer une règle spéciale avec whitelist -->
```

---

## 11. Intégration avec localisation IP

**Combinaison puissante** :

```xml
<rule id="100046" level="8">
  <if_sid>100040</if_sid>
  <time_window>00:00 - 07:59</time_window>
  <description>SSH: Night time login from unusual IP</description>
  <!-- Si tu as une base IP -> pays -->
</rule>
```

**Détection avancée** :
- SSH à 3h du matin
- **ET** de pays différent (VPN leak?)
- = Probable compromission

---

## 12. Monitoring du comportement

### Créer des statistiques

```bash
# Voir toutes les connexions SSH
sudo tail -1000 /var/ossec/logs/alerts/alerts.json | jq '.data | select(.rule.id=="100040")' | jq '.srcip' | sort | uniq -c | sort -rn
```

Résultat :
```
5 192.168.1.100   ← IP normale, 5 connexions
2 192.168.1.150   ← IP nouvelle, 2 connexions
1 192.168.1.200   ← IP rare, 1 connexion
```

### Baseline learning

Pour éviter faux positifs, noter les patterns normaux :

```
user1  : SSH à 9h-17h, IP 192.168.1.100
user2  : SSH à 10h-18h, IP 192.168.1.101
admin  : SSH 24/7, IPs multiples
```

---

## 13. Règle bonus : Détection par jour de semaine

**Limitation Wazuh** : Pas de `<day_of_week>` natif.

**Workaround** : Utiliser regex sur les logs timestamps :

```xml
<rule id="100047" level="4">
  <if_sid>100040</if_sid>
  <match>^Mon|^Tue|^Wed|^Thu|^Fri</match>  <!-- Workdays -->
  <description>SSH: Weekday login (normal)</description>
  <group>normal_access,</group>
</rule>

<rule id="100048" level="6">
  <if_sid>100040</if_sid>
  <match>^Sat|^Sun</match>  <!-- Weekend -->
  <time_window>00:00 - 23:59</time_window>
  <description>SSH: Weekend login (suspicious)</description>
  <group>time_based_attack,</group>
</rule>
```

**Note** : Dépend du format du log (pas fiable)

---

## 14. Checklist validation

- [ ] Règles 100040-100048 dans `local_rules.xml`
- [ ] Syntaxe valide (`wazuh-logtest`)
- [ ] Wazuh redémarré
- [ ] Test heure normale (8h-18h) → alerte 100040 (level 2)
- [ ] Test heure tardive (21h) → alerte 100043 (level 5)
- [ ] Test heure nuit (3h) → alerte 100041 ou 100042 (level 6-7)
- [ ] Test multiple connexions → alerte 100045 (level 6)
- [ ] Test après brute force → alerte 100044 (level 8)

---

## 15. Troubleshooting

### Time window ne marche pas

```bash
# Vérifier le fuseau horaire du serveur
timedatectl
# Doit afficher le bon timezone

# Si incorrect :
sudo timedatectl set-timezone Europe/Paris
```

### Alerte ne déclenche pas à l'heure exacte

```bash
# time_window utilise l'heure du LOG
# Pas l'heure actuelle

# Si log a timestamp antérieur, Wazuh utilise ça
# Solution : vérifier que les logs ont timestamp correct
```

### Trop d'alertes (faux positifs)

```bash
# Ajuster les niveaux
<rule id="100041" level="4">  <!-- Moins grave -->
  <if_sid>100040</if_sid>
  <time_window>00:00 - 07:59</time_window>
  <description>SSH: Night time (info only)</description>
</rule>

# OU augmenter timeframe pour agrégation
<frequency>5</frequency>
<timeframe>3600</timeframe>  <!-- Alerte seulement après 5 en 1h -->
```

---

## 📚 Fichiers importants

```
/var/ossec/etc/ossec.conf                   ← Config Wazuh (timezone)
/var/ossec/etc/rules/local_rules.xml        ← Tes règles
/var/log/secure                             ← Logs SSH
/var/ossec/logs/alerts/alerts.json          ← Alertes
```

---

## 🎯 Résumé des règles

| ID | Événement | Level | Action |
|----|-----------|-------|--------|
| 100040 | SSH accepté | 2 | Log (baseline) |
| 100041 | 00:00-07:59 | 6 | Alert |
| 100042 | 04:00-06:00 | 7 | Alert |
| 100043 | 21:00-23:59 | 5 | Alert |
| 100044 | Après failed | 8 | Alert |
| 100045 | 3x en 5min | 6 | Alert |

---

**Durée réelle** : 1 heure (40 min règles + 20 min tests)  
**Compétences** : Time-based detection, anomaly detection, behavioral monitoring  
**Prochaine étape** : Intégration incident response
