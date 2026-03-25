# 08 - Fail2ban : Protection contre le brute force

## 🎯 Objectif
Installer et configurer **Fail2ban** pour bloquer automatiquement les tentatives de connexion massives sur SSH.

Fail2ban surveille les logs et applique des règles firewall (iptables/firewalld) quand une attaque est détectée.

**Durée estimée :** 1 heure

---

## 📚 Concepts importants

### Qu'est-ce que Fail2ban ?

Fail2ban fonctionne en 4 étapes :

1. **Monitoring** : Lit les logs (SSH, web, etc.)
2. **Pattern matching** : Détecte les patterns d'attaque (ex: "Failed password" répété)
3. **Threshold** : Déclenche une action après N tentatives en T secondes
4. **Action** : Bloque l'IP (ajoute une règle firewall, ban)

### Exemple simplifié

```
Attaquant 192.168.1.100 essaie SSH 6 fois en 1 minute
    ↓
Fail2ban lit /var/log/secure
    ↓
"Failed password" × 6 en 60s = ALERTE
    ↓
Fail2ban bloque 192.168.1.100 pour 10 minutes
    ↓
Attaquant essaie... connexion refusée (IP bannie)
```

### Jails (Prisons)
Fail2ban gère plusieurs "jails" indépendants :
- **sshd** : Protection SSH
- **httpd** : Protection serveur web
- **recidive** : IP qui reviennent sans arrêt

Chaque jail a sa configuration, seuils et actions.

---

## ⚙️ Étape 1 : Installation

### Installer Fail2ban
```bash
sudo dnf install fail2ban -y
```

**Output attendu :**
```
Last metadata expiration check: 0:00:01 ago on Wed Nov 15 10:45:00 2024.
Dependencies resolved.
================================================================================
 Package                Arch   Version              Repository           Size
================================================================================
Installing:
 fail2ban               x86_64 0.11.4-5.el9         appstream          128 kB
 fail2ban-systemd       x86_64 0.11.4-5.el9         appstream           20 kB

Transaction Summary
================================================================================
Install  2 Packages

Downloading Packages:
[...]
Installed:
  fail2ban-0.11.4-5.el9.x86_64  fail2ban-systemd-0.11.4-5.el9.x86_64
```

### Vérifier l'installation
```bash
fail2ban-client --version
```

**Output attendu :**
```
Fail2Ban v0.11.4
```

---

## ⚙️ Étape 2 : Configuration SSH (Protection contre brute force)

### Créer la configuration locale
```bash
sudo nano /etc/fail2ban/jail.local
```

**Ajoute ce contenu :**

```ini
[DEFAULT]
# Délai avant déblocage automatique (en secondes)
bantime = 600

# Période de surveillance (en secondes)
findtime = 600

# Nombre de tentatives avant bannissement
maxretry = 5

# Email pour alertes (optionnel, laisser vide pour l'instant)
destemail = root@localhost
sendername = Fail2Ban
mta = sendmail

[sshd]
# Activer la jail SSH
enabled = true

# Port non-standard (adapte si tu as changé le port SSH)
port = 22

# Fichier log à surveiller
logpath = /var/log/secure

# Nombre de tentatives échouées avant ban
maxretry = 5

# Durée du bannissement (600s = 10 min)
bantime = 600

# Fenêtre de détection (600s = 10 min)
findtime = 600

# Filtre à utiliser
filter = sshd[mode=aggressive]
```

Sauvegarde : `Ctrl+O`, puis `Ctrl+X`.

### Expliquer les paramètres

| Paramètre | Valeur | Explication |
|-----------|--------|-------------|
| `bantime` | 600 | Durée du ban en secondes (10 min) |
| `findtime` | 600 | Fenêtre de temps à surveiller (10 min) |
| `maxretry` | 5 | Nombre d'erreurs avant ban |
| `port` | 22 | Port SSH surveillé |
| `logpath` | /var/log/secure | Fichier log à analyser |
| `filter` | sshd[mode=aggressive] | Mode strict de détection |

**Exemple :** Avec ces paramètres, 6 tentatives échouées en 10 minutes = IP bannie pour 10 minutes.

---

## ⚙️ Étape 3 : Démarrer et activer Fail2ban

### Démarrer le service
```bash
sudo systemctl start fail2ban
```

### Activer au démarrage
```bash
sudo systemctl enable fail2ban
```

### Vérifier le statut
```bash
sudo systemctl status fail2ban
```

**Output attendu :**
```
● fail2ban.service - Fail2Ban Service
   Loaded: loaded (/usr/lib/systemd/system/fail2ban.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed Nov 15 10:50:00 2024; 5s ago
   Main PID: 5432 (fail2ban-server)
```

---

## ⚙️ Étape 4 : Vérifier la configuration

### Lister les jails activées
```bash
sudo fail2ban-client status
```

**Output attendu :**
```
Status
|- Number of jails:	1
`- Jail list:	sshd
```

### Détails de la jail sshd
```bash
sudo fail2ban-client status sshd
```

**Output attendu :**
```
Status for the jail: sshd
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	0
|  `- Journal matches:	0 attempt in last 10m
|- Action
|  |- Currently banned:	0
|  |- Total banned:	0
|  `- Ban list:	
```

---

## 🧪 Étape 5 : Tester la protection

### Objectif
Déclencher intentionnellement une détection pour vérifier que Fail2ban fonctionne.

### Test 1 : Essayer des connexions SSH échouées

**Depuis une autre machine (ou la même en local) :**

```bash
# Essaie une connexion avec le mauvais mot de passe
for i in {1..6}; do
  ssh -v user@192.168.1.10 -p 22 2>&1 | grep -i "denied\|failed"
  sleep 1
done
```

Ou manuellement :

```bash
ssh mauvais_user@192.168.1.10
# Rentre un mauvais mot de passe 6 fois
```

### Test 2 : Vérifier que l'IP a été bannie

**Sur le serveur :**

```bash
sudo fail2ban-client status sshd
```

**Output attendu (après test) :**
```
Status for the jail: sshd
|- Filter
|  |- Currently failed:	6
|  |- Total failed:	6
|  `- Journal matches:	6 attempts in last 10m
|- Action
|  |- Currently banned:	1
|  |- Total banned:	1
|  `- Ban list:	192.168.1.100
```

### Test 3 : Confirmer que l'IP est bloquée
```bash
sudo iptables -L -n | grep 192.168.1.100
```

**Output attendu :**
```
DROP       all  --  192.168.1.100        0.0.0.0/0
```

Ou avec firewalld :
```bash
sudo firewall-cmd --list-all | grep rich
```

---

## 📊 Monitoring et logs

### Voir les logs de Fail2ban
```bash
sudo tail -50 /var/log/fail2ban.log
```

**Exemple de sortie :**
```
2024-11-15 10:52:15,123 fail2ban.filter [5432]: WARNING [sshd] Found 192.168.1.100 - 2024-11-15 10:52:14
2024-11-15 10:52:25,456 fail2ban.filter [5432]: WARNING [sshd] Found 192.168.1.100 - 2024-11-15 10:52:24
2024-11-15 10:52:35,789 fail2ban.filter [5432]: WARNING [sshd] Found 192.168.1.100 - 2024-11-15 10:52:34
2024-11-15 10:52:45,012 fail2ban.filter [5432]: WARNING [sshd] Found 192.168.1.100 - 2024-11-15 10:52:44
2024-11-15 10:52:55,345 fail2ban.filter [5432]: WARNING [sshd] Found 192.168.1.100 - 2024-11-15 10:52:54
2024-11-15 10:53:01,678 fail2ban.actions [5432]: NOTICE [sshd] Ban 192.168.1.100
```

Interprétation :
- `Found` = tentative échouée détectée
- `Ban` = IP a été ajoutée à la liste noire

### Voir les logs SSH bloqués
```bash
sudo grep "Failed password\|Invalid user" /var/log/secure | tail -20
```

### Voir les bannissements actuels
```bash
sudo fail2ban-client banned
```

Ou pour chaque jail :
```bash
sudo fail2ban-client status sshd | grep "Ban list"
```

---

## 🔧 Débannir une IP manuellement

Si tu as besoin de débannir une IP testée :

```bash
# Vérifier l'IP bannie
sudo fail2ban-client status sshd

# Débannir une IP spécifique
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

**Output attendu :**
```
1
```

Vérifier :
```bash
sudo fail2ban-client status sshd | grep "Ban list"
# Doit être vide maintenant
```

---

## ⚙️ Configuration avancée (optionnel)

### Augmenter la durée de ban
```bash
sudo nano /etc/fail2ban/jail.local
```

Modifie :
```ini
bantime = 3600
# 3600 secondes = 1 heure
```

Redémarre :
```bash
sudo systemctl restart fail2ban
```

### Exclure une IP de la détection
```bash
sudo nano /etc/fail2ban/jail.local
```

Ajoute avant `[sshd]` :
```ini
ignoreip = 127.0.0.1/8 192.168.1.50
```

Redémarre :
```bash
sudo systemctl restart fail2ban
```

### Surveiller aussi le web
```bash
sudo nano /etc/fail2ban/jail.local
```

Ajoute à la fin :
```ini
[httpd-auth]
enabled = true
port = http,https
logpath = /var/log/httpd/error_log
maxretry = 5
bantime = 3600
```

Redémarre :
```bash
sudo systemctl restart fail2ban
```

---

## ✅ Vérification finale

### Checklist

- [ ] Fail2ban est installé et actif (`systemctl status fail2ban`)
- [ ] La jail sshd est activée (`fail2ban-client status`)
- [ ] Configuration /etc/fail2ban/jail.local existe
- [ ] Paramètres corrects : `maxretry=5`, `findtime=600`, `bantime=600`
- [ ] Test de brute force a déclenché un bannissement
- [ ] IP bannie confirmée avec `iptables` ou `firewalld`
- [ ] Logs montrent les détections et bannissements

### Test final complet
```bash
# 1. Vérifier le statut
sudo systemctl status fail2ban | grep Active

# 2. Vérifier la config
sudo fail2ban-client status sshd

# 3. Vérifier les logs
sudo tail -10 /var/log/fail2ban.log

# 4. Vérifier aucune IP bannie au repos
sudo fail2ban-client status sshd | grep "Ban list"
```

**Output attendu :**
```
Active: active (running)
Status for the jail: sshd
[...]
Ban list:	
```

---

## 🆘 Troubleshooting courant

### Problème 1 : Fail2ban ne détecte rien

**Symptôme :** Même après 6 tentatives, `fail2ban-client status sshd` montre `Currently failed: 0`

**Cause probable :** Le format de log change selon la version de SSH.

**Solution :**
```bash
# Vérifier que les logs sont générés
sudo grep "Failed\|Invalid" /var/log/secure | tail -10

# Tester le filtre
sudo fail2ban-regex /var/log/secure /etc/fail2ban/filter.d/sshd.conf
```

### Problème 2 : Fail2ban refuse de démarrer

**Symptôme :**
```
systemctl start fail2ban
Job for fail2ban.service failed
```

**Solution :**
```bash
# Vérifier les erreurs
sudo systemctl status fail2ban -l

# Vérifier la syntaxe du fichier
sudo python3 -m py_compile /etc/fail2ban/jail.local

# Réinitialiser la config
sudo rm /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
```

### Problème 3 : Je ne peux plus me connecter en SSH

**Cause :** Tu as peut-être banni ta propre IP par accident.

**Solution (si accès physique) :**
```bash
# Débannir directement via iptables
sudo iptables -D INPUT -j f2b-sshd
sudo iptables -D f2b-sshd -s 192.168.1.50 -j DROP
```

Ou via fail2ban :
```bash
sudo fail2ban-client set sshd unbanip 192.168.1.50
```

---

## 📋 Résumé des commandes clés

```bash
# Installation
sudo dnf install fail2ban -y

# Service
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sudo systemctl status fail2ban

# Monitoring
sudo fail2ban-client status
sudo fail2ban-client status sshd
sudo tail -50 /var/log/fail2ban.log

# Gestion des bans
sudo fail2ban-client set sshd unbanip 192.168.1.100
sudo iptables -L -n | grep banned

# Configuration
sudo nano /etc/fail2ban/jail.local
```

---

## 🎓 Points clés à retenir

1. **Fail2ban = IPS (Intrusion Prevention System)** : C'est la première défense contre le brute force.
2. **Seuil par défaut : 5 tentatives en 10 minutes** : À adapter selon ta politique.
3. **Les bans sont appliqués via firewall** : Vérifiable avec `iptables` ou `firewalld`.
4. **Logs importants** : `/var/log/fail2ban.log` pour Fail2ban, `/var/log/secure` pour SSH.
5. **À exclure de la détection** : Ta machine d'administration (tes IPs fixes).

---

## 📚 Ressources

- Documentation : `man fail2ban`
- Logs Fail2ban : `/var/log/fail2ban.log`
- Filtres disponibles : `/etc/fail2ban/filter.d/`

