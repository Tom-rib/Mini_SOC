# 01 - Sources de logs : identification et exploration

## 🎯 Objectif de cette étape

Comprendre quels logs sont disponibles sur le serveur et pourquoi ils sont importants. Ces logs sont ta **source d'information** pour détecter les attaques.

**Durée estimée** : 30 minutes

---

## 📋 Concept : Pourquoi centraliser les logs ?

Imagine que tu es un détective : les logs sont tes indices. Si un attaquant compromet un serveur, il peut **effacer les logs locaux** pour couvrir ses traces. En centralisant les logs sur une machine SOC séparée, tu les protèges.

**Schema logique :**
```
[Serveur Web] → logs → [Attaquant efface = preuve perdue]
                ↓
              [SOC sécurisé] → logs conservés = preuve sauvée
```

---

## 1. Types de logs à collecter

### 1.1 Logs SSH : `/var/log/secure`

**Qu'est-ce que c'est ?**

Tous les événements liés à SSH (connexions, tentatives échouées, authentification). C'est une cible privilégiée des attaquants.

**Chemin du fichier**
```
/var/log/secure
```

**Format typique**
```
Jan 15 10:23:45 web01 sshd[1234]: Failed password for invalid user admin from 192.168.1.100 port 54321 ssh2
Jan 15 10:23:47 web01 sshd[1235]: Invalid user testuser from 192.168.1.100 port 54322
Jan 15 10:24:01 web01 sshd[1240]: Accepted publickey for sysadmin from 192.168.1.50 port 22 ssh2
```

**Informations clés à noter**
- Utilisateur : `admin`, `testuser`, `sysadmin`
- Source (IP) : d'où vient la connexion
- Verdict : `Failed password`, `Invalid user`, `Accepted`
- Protocole : `ssh2`

**Exemples d'attaques visibles**
- Brute force : plusieurs `Failed password` en quelques secondes
- User enumeration : `Invalid user testuser` (attaquant teste des comptes)
- Connexion root : `Accepted publickey for root` (dangereux, à alerter)

---

### 1.2 Logs Nginx (Web) : `/var/log/nginx/`

**Qu'est-ce que c'est ?**

Toutes les requêtes HTTP/HTTPS reçues par le serveur web. C'est la "vitrine" de ton application et le point d'attaque le plus commun.

**Chemins des fichiers**
```
/var/log/nginx/access.log     → toutes les requêtes (200, 404, 500, etc.)
/var/log/nginx/error.log      → erreurs serveur, anomalies
```

**Format typique du access.log**
```
192.168.1.100 - - [15/Jan/2025:10:30:45 +0100] "GET / HTTP/1.1" 200 5123 "-" "Mozilla/5.0"
192.168.1.100 - - [15/Jan/2025:10:30:46 +0100] "GET /admin HTTP/1.1" 403 0 "-" "curl/7.68"
192.168.1.100 - - [15/Jan/2025:10:30:47 +0100] "POST /upload HTTP/1.1" 413 0 "-" "curl/7.68"
10.0.0.50 - - [15/Jan/2025:10:31:00 +0100] "GET /shell.php HTTP/1.1" 500 0 "-" "Mozilla/5.0"
```

**Informations clés**
- IP source : `192.168.1.100`, `10.0.0.50`
- Timestamp : quand exactement
- Méthode HTTP : `GET`, `POST`, `HEAD`, etc.
- Chemin : `/`, `/admin`, `/upload`, `/shell.php`
- Code HTTP : `200` (OK), `403` (Forbidden), `404` (Not Found), `413` (Payload Too Large), `500` (Erreur serveur)
- User-Agent : navigateur ou outil (`curl`, `wget`, `sqlmap`)

**Exemples d'attaques visibles**
- Scan de répertoires : plusieurs `404` ou `403` sur `/admin`, `/config`, `/backup`
- Upload malveillant : `POST /upload` avec code `413` (fichier rejeté) ou `500` (erreur serveur)
- Web shell : `GET /shell.php` qui aurait été uploadé
- Scanner réseau : User-Agent suspecte ou pattern de requête automatisé

**Format du error.log**
```
2025/01/15 10:35:22 [error] 1234#0: *567 open() "/var/www/html/config.php" failed (13: Permission denied)
2025/01/15 10:36:45 [crit] 1234#0: *890 socket() failed (24: Too many open files)
```

---

### 1.3 Logs système : `/var/log/messages` ou `journalctl`

**Qu'est-ce que c'est ?**

Événements généraux du système : arrêts de service, redémarrages, erreurs matériel, etc.

**Accès**
```
# Ancienne méthode (fichier)
/var/log/messages

# Méthode moderne (systemd)
journalctl -xe
journalctl --since "1 hour ago"
```

**Exemples pertinents**
```
Jan 15 10:40:00 web01 kernel: Out of memory: Kill process nginx (1234)
Jan 15 10:41:00 web01 systemd: sshd.service: Main process exited, code=killed, status=9/KILL
Jan 15 10:42:00 web01 systemd: Restarted Web Application Service
```

**Informations clés**
- Arrêt/redémarrage de services
- Perte de mémoire ou ressources
- Changements de configuration

---

### 1.4 Logs d'audit : `/var/log/audit/audit.log`

**Qu'est-ce que c'est ?**

Trace détaillée des **commandes système** et des **accès aux fichiers sensibles** via auditd. C'est le plus précis pour enquête post-incident.

**Chemin**
```
/var/log/audit/audit.log
```

**Exemple d'une commande suspecte détectée**
```
type=EXECVE msg=audit(1234567890.123:456): argc=3 a0="/bin/rm" a1="-rf" a2="/var/log/"
type=PATH msg=audit(1234567890.123:457): name="/var/log/" inode=789 dev=10,1 mode=040755
type=PROCTITLE msg=audit(1234567890.123:458): proctitle="/bin/rm" "-rf" "/var/log/"
```

**Informations clés**
- Commande exécutée : `EXECVE` avec arguments
- Fichier accédé : `PATH` avec inode
- Qui a lancé : UID, PID, parent PID (dans les logs complets)

**Exemples d'attaques détectables**
- Attaquant qui essaie d'effacer les logs : `rm -rf /var/log/`
- Création de fichier suspect : `/tmp/.hidden` avec droits 755
- Modifications de fichiers système : `/etc/passwd`, `/etc/shadow`
- Changements de permissions : `chmod 777 /etc/`

**Note** : auditd doit être activé et configuré au préalable (voir module Rôle 1).

---

### 1.5 Logs Firewall : `firewalld`

**Qu'est-ce que c'est ?**

Paquets rejetés ou bloqués par le firewall. Utile pour voir les tentatives de connexion avant qu'elles n'atteignent le serveur.

**Accès**
```
journalctl -u firewalld -n 100
```

ou

```
grep "REJECT" /var/log/messages
```

**Exemple typique**
```
Jan 15 10:50:00 web01 kernel: IN=eth0 OUT= MAC=... SRC=192.168.1.200 DST=192.168.1.10 PROTO=TCP SPT=54321 DPT=22 FLAGS=SYN
```

**Informations clés**
- Interface réseau : `IN=eth0` (entrant)
- IP source et destination : `SRC=...`, `DST=...`
- Port destination : `DPT=22` (SSH), `DPT=80` (HTTP), etc.
- Type d'attaque : scan de port, connexion non autorisée

---

## 2. Exploration manuelle des logs

### Commandes essentielles

**Voir les 20 dernières lignes d'un fichier**
```bash
tail -20 /var/log/secure
tail -20 /var/log/nginx/access.log
tail -20 /var/log/messages
```

**Voir les logs en temps réel (utile pendant une attaque)**
```bash
tail -f /var/log/secure
tail -f /var/log/nginx/access.log
```

**Compter les erreurs SSH**
```bash
grep "Failed password" /var/log/secure | wc -l
```

**Voir toutes les connexions rejetées**
```bash
grep "Failed password\|Invalid user" /var/log/secure
```

**Chercher une IP spécifique**
```bash
grep "192.168.1.100" /var/log/nginx/access.log
grep "192.168.1.100" /var/log/secure
```

**Lister les utilisateurs ayant tenté se connecter**
```bash
grep "Failed password for" /var/log/secure | awk '{print $9}' | sort | uniq -c
```

**Voir les tentatives depuis la dernière heure**
```bash
journalctl --since "1 hour ago" -u sshd
```

---

## 3. Vérification pratique

### Étape 1 : Vérifier que les logs existent

```bash
ls -lh /var/log/secure
ls -lh /var/log/nginx/access.log
ls -lh /var/log/messages
ls -lh /var/log/audit/audit.log
```

**Résultat attendu** : tous les fichiers doivent exister et avoir une taille > 0

---

### Étape 2 : Générer un log de test

**Depuis la machine attaquante (ou un autre terminal)**
```bash
# Test 1 : Tentative SSH échouée
ssh testuser@<IP_SERVEUR>  # entrer un mauvais mot de passe exprès

# Test 2 : Accès web normal
curl http://<IP_SERVEUR>/

# Test 3 : Accès web rejeté
curl http://<IP_SERVEUR>/admin/
```

**Sur le serveur, vérifier les logs**
```bash
# Voir la tentative SSH
tail -5 /var/log/secure | grep "testuser"

# Voir la requête web
tail -5 /var/log/nginx/access.log | grep "curl"
```

---

### Étape 3 : Comptage des événements

```bash
# Nombre total de lignes dans secure
wc -l /var/log/secure

# Nombre de tentatives échouées
grep -c "Failed password" /var/log/secure

# Nombre de requêtes HTTP 200
grep -c " 200 " /var/log/nginx/access.log

# Nombre d'erreurs 404
grep -c " 404 " /var/log/nginx/access.log
```

---

## 4. Checklist de validation

- [ ] `/var/log/secure` contient au moins 100 lignes
- [ ] `/var/log/nginx/access.log` contient au moins 50 lignes
- [ ] `/var/log/messages` contient des événements système
- [ ] `/var/log/audit/audit.log` existe et est alimenté
- [ ] Peux trouver une tentative SSH échouée avec `grep "Failed password"`
- [ ] Peux trouver une requête HTTP avec `grep "GET /"`
- [ ] Peux extraire une IP avec `grep | awk`

---

## 5. Préparation pour l'étape suivante

Maintenant que tu connais les sources, tu vas les **centraliser** sur la VM SOC. 

**Prochaine étape (02_rsyslog_filebeat.md)** : configurer `rsyslog` pour envoyer tous ces logs vers le serveur SOC en temps réel.

---

## 📚 Ressources et mémos

### Commandes rapides de test

```bash
# Créer 10 tentatives SSH échouées (à titre de test)
for i in {1..10}; do 
  ssh testuser@localhost 2>/dev/null || true
done

# Voir le résultat
grep "testuser" /var/log/secure | tail -10
```

### Patterns à chercher lors d'une attaque

| Attaque | Pattern à grep |
|---------|---|
| Brute force SSH | `Failed password` |
| User enumeration | `Invalid user` |
| Scan web | `404\|403` (plusieurs) |
| Upload malveillant | `POST.*413\|500` |
| Web shell | `GET.*\.php` |
| Effacement logs | `rm.*var/log` dans audit |

---

## ✅ Prêt pour la suite ?

Si tu as validé la checklist, tu es prêt à passer à l'étape suivante : **configurer rsyslog pour centraliser ces logs vers la VM SOC**.
