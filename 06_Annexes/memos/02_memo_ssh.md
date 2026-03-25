# 🔐 Mémo SSH - Authentification & Connexion Sécurisée

> **Objectif** : Guide rapide pour générer, configurer et utiliser SSH dans le projet SOC.  
> **Contexte** : Authentification par clé SSH obligatoire, pas de mot de passe SSH.

---

## 1️⃣ Génération de Clés SSH

### Générer une paire de clés (RSA 4096)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
# -t rsa           : Type de clé RSA
# -b 4096          : Taille 4096 bits (sécurisé)
# -f ~/.ssh/id_rsa : Chemin du fichier
# -N ""            : Pas de passphrase (vide)
```

**Output attendu :**
```
Generating public/private rsa key pair.
Your identification has been saved in /home/user/.ssh/id_rsa
Your public key has been saved in /home/user/.ssh/id_rsa.pub
The key fingerprint is: ...
```

### Vérifier les clés générées

```bash
ls -la ~/.ssh/
# id_rsa       (privée - permissions 600)
# id_rsa.pub   (publique - partageable)
```

### Afficher la clé publique

```bash
cat ~/.ssh/id_rsa.pub
# Copier cette sortie pour autoriser l'accès sur le serveur
```

### Alternative : Générer avec ED25519 (plus moderne)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
# Recommandé si supporté, plus performant et sûr
```

---

## 2️⃣ Distribuer la Clé Publique

### Méthode 1 : ssh-copy-id (AUTOMATIQUE - recommandé)

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub user@hostname
# Ou sans spécifier le fichier :
ssh-copy-id user@hostname
```

**Processus :**
- Demande password SSH (dernière fois !)
- Copie clé publique dans `~/.ssh/authorized_keys`
- Ajoute permissions automatiques

### Méthode 2 : Manuel

```bash
# 1. Sur local, lire la clé publique
cat ~/.ssh/id_rsa.pub

# 2. Sur le serveur, ajouter à authorized_keys
mkdir -p ~/.ssh
cat >> ~/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAA...  (coller clé publique)
EOF

# 3. Fixer permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Vérifier que ça marche

```bash
ssh user@hostname
# Devrait se connecter SANS demander de mot de passe
```

---

## 3️⃣ Configuration SSH (~/.ssh/config)

### Créer un fichier de config pour simplifier

```bash
nano ~/.ssh/config
```

### Exemple de config pour le projet

```conf
# Serveur Web (VM 1)
Host web
    HostName 192.168.1.10
    User admin
    IdentityFile ~/.ssh/id_rsa
    Port 2222
    StrictHostKeyChecking accept-new

# SOC / SIEM (VM 2)
Host soc
    HostName 192.168.1.20
    User soc_analyst
    IdentityFile ~/.ssh/id_rsa
    Port 2222
    StrictHostKeyChecking accept-new

# Monitoring (VM 3)
Host monitoring
    HostName 192.168.1.30
    User monitoring
    IdentityFile ~/.ssh/id_rsa
    Port 2222
    StrictHostKeyChecking accept-new
```

### Utiliser le config

```bash
ssh web              # Au lieu de ssh -p 2222 admin@192.168.1.10
ssh soc
ssh monitoring
```

### Permissions du config

```bash
chmod 600 ~/.ssh/config
```

---

## 4️⃣ Connexion SSH Avancée

### Connexion basique

```bash
ssh user@hostname
ssh user@hostname -p 2222           # Port custom
ssh -i ~/.ssh/id_rsa user@hostname  # Clé spécifique
```

### Exécuter commande à distance

```bash
ssh user@hostname "ls -la /home/"
ssh web "systemctl status sshd"
ssh soc "tail -20 /var/log/secure"
```

### Mode interactif distant

```bash
ssh user@hostname
# Vous êtes maintenant sur le serveur distant
exit                                # Revenir local
```

### Options utiles

| Option | Description | Exemple |
|--------|-------------|---------|
| `-p` | Port SSH | `ssh -p 2222 user@host` |
| `-i` | Clé spécifique | `ssh -i ~/.ssh/special_key user@host` |
| `-v` | Verbose (debug) | `ssh -v user@host` |
| `-vv` | Plus de détails | `ssh -vv user@host` |
| `-N` | Pas de commande (tunnel) | `ssh -N -L 3306:localhost:3306` |
| `-f` | Background | `ssh -f -N -L ...` |
| `-X` | Forward X11 (GUI) | `ssh -X user@host` |

---

## 5️⃣ Copie de Fichiers via SSH (SCP)

### SCP : Secure CoPy

```bash
# Copier fichier local → serveur
scp file.txt user@hostname:/path/
scp file.txt web:/tmp/

# Copier serveur → local
scp user@hostname:/path/file.txt ./
scp web:/var/log/secure ~/logs/

# Copier répertoire (récursif)
scp -r /home/user/folder/ web:/backup/

# Avec port custom
scp -P 2222 file.txt user@hostname:/path/
```

### Utiliser avec config SSH

```bash
scp local_file web:/remote/path/
scp soc:/var/log/secure ~/soc_logs/
```

---

## 6️⃣ Tunneling SSH (Port Forwarding)

### Local Port Forwarding (-L)

Accéder à un service distant via local.

```bash
ssh -L local_port:target_host:target_port user@jump_host
ssh -L 3306:localhost:3306 user@web
# Maintenant : localhost:3306 = web:3306
```

**Exemple pratique :**
```bash
# Accéder à MySQL distant sur port local 3306
ssh -L 3306:localhost:3306 admin@web

# Dans autre terminal :
mysql -h localhost -u user -p
```

### Remote Port Forwarding (-R)

Exposer un service local via serveur distant.

```bash
ssh -R remote_port:localhost:local_port user@host
ssh -R 8080:localhost:3000 user@web
# Distant : localhost:8080 = local:3000
```

### Dynamic Forwarding (-D)

Créer un proxy SOCKS.

```bash
ssh -D 1080 user@web
# Configurer navigateur proxy : localhost:1080 (SOCKS5)
```

---

## 7️⃣ Gestion des Clés Publiques

### Ajouter clé supplémentaire

```bash
# Générer nouvelle clé
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_backup

# Ajouter sur serveur (manuellement)
cat ~/.ssh/id_rsa_backup.pub | ssh user@host "cat >> ~/.ssh/authorized_keys"

# Ou editer authorized_keys directement
nano ~/.ssh/authorized_keys
```

### Supprimer une clé

```bash
# Éditer authorized_keys et supprimer la ligne
nano ~/.ssh/authorized_keys

# Ou générer nouvelle clé et supprimer l'ancienne
```

### Lister les clés autorisées

```bash
cat ~/.ssh/authorized_keys
```

---

## 8️⃣ Authentification Multi-Clés

### Déployer clé sur plusieurs serveurs

```bash
#!/bin/bash
# Script pour copier clé sur plusieurs hôtes

hosts=("web" "soc" "monitoring")
for host in "${hosts[@]}"; do
    ssh-copy-id -i ~/.ssh/id_rsa.pub user@$host
    echo "✓ Clé copiée sur $host"
done
```

### Vérifier accès sur tous les serveurs

```bash
for host in web soc monitoring; do
    echo "Testing $host..."
    ssh $host "hostname"
done
```

---

## 9️⃣ Troubleshooting SSH

### Connexion refusée / Timeout

```bash
# 1. Vérifier que SSH tourne
ssh -v user@hostname
# Chercher "Connection refused" ou "Timeout"

# 2. Vérifier port écoute
ssh soc "ss -tulpn | grep sshd"
# Devrait afficher port SSH (22, 2222, etc.)

# 3. Vérifier firewall
ssh soc "firewall-cmd --list-all"
# Voir section "services" et "ports"

# 4. Redémarrer SSH si nécessaire
ssh soc "sudo systemctl restart sshd"
```

### Permission denied (publickey)

```bash
# 1. Vérifier authorized_keys permissions
ssh user@host "ls -la ~/.ssh/"
# Doit être : drwx------ (700) pour .ssh
#             -rw------- (600) pour authorized_keys

# 2. Réparer si nécessaire
ssh user@host "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

# 3. Vérifier contenu authorized_keys
ssh user@host "cat ~/.ssh/authorized_keys"
# Clé doit être sur une seule ligne
```

### Clé ne fonctionne pas

```bash
# 1. Vérifier permissions de clé locale
ls -la ~/.ssh/id_rsa
# Doit être : -rw------- (600)

# 2. Si mauvaises permissions :
chmod 600 ~/.ssh/id_rsa

# 3. Tester connexion avec debug
ssh -vvv user@hostname

# 4. Vérifier empreinte de clé
ssh-keygen -l -f ~/.ssh/id_rsa.pub
```

### SSH trop lent

```bash
# Désactiver DNS (cherche DNS = lent)
ssh -o UseDNS=no user@hostname

# Ajouter au config
echo "UseDNS no" >> ~/.ssh/config

# Désactiver GSSAPI (peut être lent)
ssh -o GSSAPIAuthentication=no user@hostname
```

---

## 🔟 Sécurité SSH : Checklist

### Côté Client (Votre Machine)

- ✅ Clés privées (`id_rsa`) : permissions 600
- ✅ Dossier `.ssh` : permissions 700
- ✅ Clés non-password : `ssh-keygen -N ""`
- ✅ Ne PAS partager clé privée
- ✅ Utiliser ed25519 si possible (plus moderne)

### Côté Serveur (après SSH-keygen)

```bash
# Vérifier config SSH
grep -E "^[^#]" /etc/ssh/sshd_config | head -20

# Points clés :
# - PermitRootLogin no
# - PasswordAuthentication no
# - PubkeyAuthentication yes
# - Port 2222 (custom)
```

### Test rapide d'accès

```bash
# Doit marcher sans password
for host in web soc monitoring; do
    echo "=== $host ==="
    ssh $host "hostname && whoami"
done
```

---

## 1️⃣1️⃣ Commandes SSH à Retenir

| Situation | Commande |
|-----------|----------|
| Générer clés | `ssh-keygen -t rsa -b 4096` |
| Copier clé | `ssh-copy-id user@host` |
| Se connecter | `ssh user@host` ou `ssh web` (avec config) |
| Exécuter commande | `ssh web "ls -la"` |
| Copier fichier | `scp file.txt web:/tmp/` |
| Tunnel local | `ssh -L 3306:localhost:3306 web` |
| Debug connexion | `ssh -vvv user@host` |
| Vérifier clés | `ls -la ~/.ssh/` |
| Vérifier authorized | `ssh host "cat ~/.ssh/authorized_keys"` |

---

**Dernière mise à jour** : Documentation projet Mini SOC  
**Niveau** : 2e année admin systèmes & réseaux  
**Point clé** : SSH par clé, jamais par password !
