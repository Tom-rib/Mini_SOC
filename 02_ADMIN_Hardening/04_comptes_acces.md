# 04 - Comptes et Accès Sécurisés

**Durée estimée :** 1h  
**Rôle concerné :** Administrateur système & hardening

---

## 🎯 Objectif de cette étape

Créer une structure de comptes sécurisée pour remplacer l'utilisation directe du compte root. En entreprise, on ne se connecte **jamais** directement en root via SSH.

**Pourquoi ?**
- Si root est compromis, l'attaquant a tous les pouvoirs
- Impossible de tracer qui a fait quoi
- Pas de validation des actions sensibles

---

## 📋 Ce que vous allez faire

1. Créer un compte administrateur nominatif
2. Le configurer pour utiliser `sudo`
3. Générer une paire de clés SSH
4. Vérifier que tout fonctionne

---

## Étape 1 : Créer un compte administrateur

### Création du compte

```bash
# Se connecter en root (pour la dernière fois !)
sudo su -

# Créer un nouvel utilisateur (remplacer 'admin' par votre prénom)
useradd -m -s /bin/bash admin

# Définir un mot de passe temporaire
passwd admin
```

**Output attendu :**
```
Nouveau mot de passe : 
Retapez le nouveau mot de passe : 
passwd : le mot de passe a été mis à jour avec succès
```

### Explications

- `-m` : crée le répertoire home `/home/admin`
- `-s /bin/bash` : définit bash comme shell par défaut
- `passwd` : définit un mot de passe (temporaire, on utilisera les clés SSH ensuite)

---

## Étape 2 : Configurer les privilèges sudo

### Ajouter au groupe wheel

Le groupe `wheel` sur Rocky Linux permet d'utiliser sudo.

```bash
# Ajouter l'utilisateur au groupe wheel
usermod -aG wheel admin

# Vérifier les groupes
groups admin
```

**Output attendu :**
```
admin : admin wheel
```

### Configuration avancée de sudoers (optionnel mais recommandé)

```bash
# Éditer le fichier sudoers de manière sécurisée
visudo
```

**Ajouter ces lignes personnalisées :**
```bash
# Timeout de 10 minutes (plus court = plus sûr)
Defaults timestamp_timeout=10

# Toujours demander le mot de passe
Defaults !authenticate

# Journaliser toutes les commandes sudo
Defaults logfile="/var/log/sudo.log"
Defaults log_input, log_output
```

**Important :** N'utilisez JAMAIS un éditeur de texte normal pour éditer `/etc/sudoers`. Toujours utiliser `visudo` qui vérifie la syntaxe avant de sauvegarder.

---

## Étape 3 : Tester sudo

```bash
# Se déconnecter de root
exit

# Se reconnecter avec le nouveau compte
su - admin

# Tester une commande sudo
sudo whoami
```

**Output attendu :**
```
[sudo] Mot de passe de admin : 
root
```

Si vous voyez "root", c'est bon ! Votre compte peut exécuter des commandes avec les privilèges root.

---

## Étape 4 : Générer une paire de clés SSH

### Sur votre machine locale (pas sur le serveur)

```bash
# Générer une paire de clés RSA de 4096 bits
ssh-keygen -t rsa -b 4096 -C "admin@mini-soc-rocky"
```

**Prompts attendus :**
```
Enter file in which to save the key (/home/vous/.ssh/id_rsa): [Entrée]
Enter passphrase (empty for no passphrase): [Tapez une phrase de passe FORTE]
Enter same passphrase again: [Retapez-la]
```

**Résultat :**
- Clé privée : `~/.ssh/id_rsa` (à garder SECRÈTE)
- Clé publique : `~/.ssh/id_rsa.pub` (à copier sur le serveur)

### Copier la clé publique sur le serveur

```bash
# Depuis votre machine locale
ssh-copy-id -p 22 admin@IP_DU_SERVEUR
```

**OU manuellement :**

```bash
# Sur le serveur, en tant qu'admin
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Coller le contenu de votre id_rsa.pub dans authorized_keys
nano ~/.ssh/authorized_keys
# [Coller la clé publique, puis Ctrl+X, Y, Entrée]

chmod 600 ~/.ssh/authorized_keys
```

---

## Étape 5 : Vérifications

### Vérifier les groupes de l'utilisateur

```bash
groups admin
id admin
```

**Output attendu :**
```
admin : admin wheel
uid=1001(admin) gid=1001(admin) groupes=1001(admin),10(wheel)
```

### Vérifier les connexions actives

```bash
who
w
```

**Output attendu :**
```
admin    pts/0        2024-02-06 10:30 (192.168.1.100)
```

### Tester la connexion SSH avec clé

```bash
# Depuis votre machine locale
ssh -p 22 admin@IP_DU_SERVEUR
```

Si ça demande votre **passphrase de clé** (pas le mot de passe du compte), c'est parfait !

---

## ✅ Checklist de validation

- [ ] Compte admin créé avec home directory
- [ ] Groupe wheel attribué
- [ ] sudo fonctionne (teste avec `sudo whoami`)
- [ ] Paire de clés SSH générée
- [ ] Clé publique copiée sur le serveur
- [ ] Connexion SSH par clé fonctionne
- [ ] Fichier `/var/log/sudo.log` créé (si configuré)

---

## ❌ Erreurs courantes

### Problème : "admin is not in the sudoers file"

**Cause :** L'utilisateur n'est pas dans le groupe wheel

**Solution :**
```bash
sudo usermod -aG wheel admin
# Puis se déconnecter/reconnecter
```

### Problème : "Permission denied (publickey)"

**Cause :** Mauvais permissions sur `.ssh/` ou `authorized_keys`

**Solution :**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Problème : "visudo: syntax error"

**Cause :** Erreur de syntaxe dans sudoers

**Solution :** `visudo` vous empêchera de sauvegarder. Relire attentivement les lignes ajoutées.

---

## 📝 Notes importantes

1. **Jamais de root direct en SSH** : Une fois SSH configuré (prochaine étape), root ne pourra plus se connecter
2. **Passphrase de clé ≠ mot de passe du compte** : La passphrase protège votre clé privée locale
3. **Sauvegardez votre clé privée** : Si vous la perdez, vous devrez recréer une nouvelle paire

---

## 🔗 Prochaine étape

→ **05_ssh_hardening.md** : Sécuriser le service SSH (port custom, désactiver root, etc.)

---

## 📚 Commandes de référence

```bash
# Gestion des utilisateurs
useradd -m -s /bin/bash <user>    # Créer un utilisateur
passwd <user>                      # Définir/changer le mot de passe
usermod -aG <groupe> <user>        # Ajouter à un groupe
userdel -r <user>                  # Supprimer un utilisateur et son home

# Vérifications
id <user>                          # Infos complètes sur un utilisateur
groups <user>                      # Lister les groupes d'un utilisateur
who                                # Utilisateurs connectés
w                                  # Détails des sessions actives
last                               # Historique des connexions

# SSH
ssh-keygen -t rsa -b 4096          # Générer une paire de clés
ssh-copy-id user@host              # Copier la clé publique
ssh -i ~/.ssh/cle_privee user@host # Se connecter avec une clé spécifique
```
