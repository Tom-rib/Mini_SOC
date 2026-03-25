# 05 - Durcissement SSH

**Durée estimée :** 1h  
**Rôle concerné :** Administrateur système & hardening

---

## 🎯 Objectif de cette étape

Transformer SSH en forteresse : changer le port, interdire root, forcer l'authentification par clé, limiter les tentatives. SSH est **la porte d'entrée** du serveur, c'est la première chose que les attaquants scannent.

**Pourquoi ?**
- Port 22 = première cible des bots d'attaque
- Authentification par mot de passe = vulnérable au brute force
- Root en SSH = jackpot pour un attaquant

---

## 📋 Ce que vous allez faire

1. Sauvegarder la configuration SSH actuelle
2. Modifier `/etc/ssh/sshd_config` avec les bonnes pratiques
3. Redémarrer le service SSH
4. Tester la nouvelle configuration
5. Vérifier que root ne peut plus se connecter

---

## Étape 1 : Sauvegarde de la configuration

**Toujours faire une sauvegarde avant de modifier un fichier critique !**

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Vérifier que la sauvegarde existe
ls -lh /etc/ssh/sshd_config*
```

**Output attendu :**
```
-rw------- 1 root root 3.3K  6 fév 10:00 /etc/ssh/sshd_config
-rw------- 1 root root 3.3K  6 fév 10:00 /etc/ssh/sshd_config.backup
```

---

## Étape 2 : Configuration sécurisée de SSH

### Éditer le fichier de configuration

```bash
sudo nano /etc/ssh/sshd_config
```

### Paramètres à modifier/ajouter

**Trouvez et modifiez (ou ajoutez si inexistant) :**

```bash
# ========================================
# PORT PERSONNALISÉ (éviter les scans automatiques)
# ========================================
Port 2222

# ========================================
# DÉSACTIVER ROOT
# ========================================
PermitRootLogin no

# ========================================
# AUTHENTIFICATION
# ========================================
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# ========================================
# LIMITER LES TENTATIVES
# ========================================
MaxAuthTries 3
MaxSessions 2

# ========================================
# TIMEOUT DE SESSION
# ========================================
ClientAliveInterval 300
ClientAliveCountMax 2

# ========================================
# PROTOCOLE ET CHIFFREMENT
# ========================================
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# ========================================
# RESTRICTIONS D'ACCÈS
# ========================================
AllowUsers admin
# OU pour autoriser un groupe :
# AllowGroups wheel

# ========================================
# DÉSACTIVER LES FONCTIONS DANGEREUSES
# ========================================
X11Forwarding no
PermitUserEnvironment no
AllowTcpForwarding no
AllowAgentForwarding no
GatewayPorts no
```

**Sauvegarder avec :** `Ctrl + X`, puis `Y`, puis `Entrée`

---

## 📖 Explications des paramètres

| Paramètre | Valeur | Explication |
|-----------|--------|-------------|
| `Port` | 2222 | Change le port par défaut (22). Réduit les scans automatisés |
| `PermitRootLogin` | no | Empêche root de se connecter en SSH. **Critique !** |
| `PubkeyAuthentication` | yes | Active l'authentification par clé publique |
| `PasswordAuthentication` | no | Désactive l'authentification par mot de passe |
| `MaxAuthTries` | 3 | Limite à 3 tentatives d'authentification |
| `ClientAliveInterval` | 300 | Envoie un signal toutes les 5 min pour maintenir la connexion |
| `ClientAliveCountMax` | 2 | Déconnexion après 2 signaux sans réponse (10 min total) |
| `AllowUsers` | admin | Seul le compte "admin" peut se connecter |
| `X11Forwarding` | no | Désactive le forwarding graphique (inutile pour un serveur) |

---

## Étape 3 : Vérifier la syntaxe

**Avant de redémarrer SSH, vérifiez qu'il n'y a pas d'erreur de syntaxe :**

```bash
sudo sshd -t
```

**Output attendu (si OK) :**
```
(aucun message = configuration valide)
```

**Si erreur :**
```
/etc/ssh/sshd_config line 25: Bad configuration option: PortTypo
```
→ Corriger l'erreur avant de continuer !

---

## Étape 4 : Ouvrir le nouveau port dans le firewall

**IMPORTANT : Faire ça AVANT de redémarrer SSH !**

```bash
# Ouvrir le port 2222
sudo firewall-cmd --permanent --add-port=2222/tcp

# Recharger le firewall
sudo firewall-cmd --reload

# Vérifier
sudo firewall-cmd --list-ports
```

**Output attendu :**
```
2222/tcp
```

---

## Étape 5 : Autoriser le port dans SELinux

Rocky Linux utilise SELinux qui contrôle les ports autorisés pour SSH.

```bash
# Vérifier les ports SSH autorisés
sudo semanage port -l | grep ssh

# Ajouter le port 2222
sudo semanage port -a -t ssh_port_t -p tcp 2222

# Vérifier que c'est bien ajouté
sudo semanage port -l | grep ssh
```

**Output attendu :**
```
ssh_port_t    tcp    2222, 22
```

---

## Étape 6 : Redémarrer SSH

```bash
# Redémarrer le service SSH
sudo systemctl restart sshd

# Vérifier le statut
sudo systemctl status sshd
```

**Output attendu :**
```
● sshd.service - OpenSSH server daemon
   Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled)
   Active: active (running) since Wed 2024-02-06 10:30:00 CET
```

**Vérifier que SSH écoute sur le port 2222 :**

```bash
sudo ss -tlnp | grep sshd
```

**Output attendu :**
```
LISTEN  0  128  *:2222  *:*  users:(("sshd",pid=1234,fd=3))
```

---

## Étape 7 : Tests de validation

### Test 1 : Connexion avec le nouveau port

**IMPORTANT : Gardez votre session actuelle ouverte ! Ouvrez un NOUVEAU terminal.**

```bash
# Depuis votre machine locale
ssh -p 2222 admin@IP_DU_SERVEUR
```

**Si ça marche :** ✅ Parfait !  
**Si ça ne marche pas :** ❌ **NE FERMEZ PAS** votre session actuelle, dépannez d'abord.

### Test 2 : Vérifier que root est refusé

```bash
# Essayer de se connecter en root (doit échouer)
ssh -p 2222 root@IP_DU_SERVEUR
```

**Output attendu :**
```
root@IP_DU_SERVEUR: Permission denied (publickey).
```

C'est **normal** et **souhaité** ! Root ne peut plus se connecter.

### Test 3 : Vérifier que le port 22 est fermé

```bash
# Depuis votre machine locale
ssh -p 22 admin@IP_DU_SERVEUR
```

**Output attendu :**
```
ssh: connect to host IP_DU_SERVEUR port 22: Connection refused
```

Parfait ! Le port 22 n'est plus accessible.

---

## Étape 8 : Désactiver définitivement le port 22

Si tout fonctionne sur le port 2222, on peut retirer complètement le port 22 de SELinux.

```bash
# Retirer le port 22 (optionnel, si vous êtes sûr)
sudo semanage port -d -t ssh_port_t -p tcp 22
```

---

## ✅ Checklist de validation

- [ ] Fichier `/etc/ssh/sshd_config` sauvegardé
- [ ] Port personnalisé configuré (2222)
- [ ] `PermitRootLogin no` défini
- [ ] `PasswordAuthentication no` défini
- [ ] Port 2222 ouvert dans le firewall
- [ ] Port 2222 autorisé dans SELinux
- [ ] SSH redémarré sans erreur
- [ ] Connexion sur port 2222 réussie
- [ ] Connexion root refusée
- [ ] Connexion sur port 22 refusée

---

## ❌ Erreurs courantes

### Problème : "Connection refused" sur port 2222

**Causes possibles :**
1. Firewall bloque le port
2. SELinux bloque le port
3. SSH n'écoute pas sur 2222

**Diagnostic :**
```bash
# Vérifier que SSH écoute bien
sudo ss -tlnp | grep sshd

# Vérifier le firewall
sudo firewall-cmd --list-ports

# Vérifier SELinux
sudo semanage port -l | grep ssh

# Voir les logs SSH
sudo journalctl -u sshd -f
```

### Problème : "Permission denied (publickey)"

**Cause :** Authentification par clé mal configurée

**Solution :**
```bash
# Vérifier que votre clé publique est bien dans authorized_keys
cat ~/.ssh/authorized_keys

# Vérifier les permissions
ls -la ~/.ssh/
# Doit afficher :
# drwx------ (700) pour le dossier .ssh
# -rw------- (600) pour authorized_keys
```

### Problème : "Bad configuration option"

**Cause :** Erreur de syntaxe dans sshd_config

**Solution :**
```bash
# Restaurer la sauvegarde
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config

# Refaire les modifications avec attention
sudo nano /etc/ssh/sshd_config
```

### Problème : Bloqué dehors (plus de connexion possible)

**Solution de secours :** Utiliser la console de votre hyperviseur (VirtualBox, VMware) pour accéder directement à la VM et corriger la configuration.

---

## 📝 Notes importantes

1. **Session de secours** : Avant de redémarrer SSH, ouvrez une 2e session. Si ça casse, vous pourrez dépanner.
2. **Port personnalisé** : Notez bien votre port custom quelque part !
3. **Logs SSH** : En cas de problème, regardez toujours `/var/log/secure` ou `journalctl -u sshd`

---

## 🔗 Prochaine étape

→ **06_firewall.md** : Configurer le pare-feu firewalld pour protéger le serveur

---

## 📚 Commandes de référence

```bash
# Gestion du service SSH
sudo systemctl status sshd      # Voir le statut
sudo systemctl restart sshd     # Redémarrer
sudo systemctl reload sshd      # Recharger la config sans couper les connexions
sudo sshd -t                    # Tester la syntaxe de la config

# Ports et connexions
sudo ss -tlnp | grep sshd       # Voir les ports SSH
sudo lsof -i :2222              # Voir ce qui écoute sur le port 2222

# Logs
sudo journalctl -u sshd -f      # Suivre les logs SSH en temps réel
sudo tail -f /var/log/secure    # Logs d'authentification

# SELinux
sudo semanage port -l | grep ssh        # Lister les ports SSH autorisés
sudo semanage port -a -t ssh_port_t -p tcp PORT  # Ajouter un port
sudo semanage port -d -t ssh_port_t -p tcp PORT  # Supprimer un port
```
