# 📋 Mémo Linux - Cheat Sheet Essentielles

> **Objectif** : Référence rapide des commandes Linux les plus utilisées dans le projet.  
> **Format** : Tableau commande → option → description → exemple

---

## 1️⃣ Navigation & Fichiers

### Navigation

| Commande | Option | Description | Exemple |
|----------|--------|-------------|---------|
| `pwd` | - | Affiche le répertoire courant | `pwd` |
| `cd` | `..` / `/` / `~` | Change de répertoire | `cd /var/log` |
| `ls` | `-la`, `-lh` | Liste les fichiers (détail, humain) | `ls -la /home/` |
| `find` | `-name`, `-type`, `-size` | Recherche fichiers par critères | `find / -name "*.log"` |
| `locate` | - | Recherche rapide (DB indexée) | `locate passwd` |

### Affichage & Édition

| Commande | Option | Description | Exemple |
|----------|--------|-------------|---------|
| `cat` | `-n` | Affiche contenu (avec numéros) | `cat -n /etc/passwd` |
| `less` | `G`, `/` | Pagination (G=fin, /=recherche) | `less /var/log/secure` |
| `tail` | `-f`, `-n 50` | Dernières lignes (suivi actif) | `tail -f /var/log/messages` |
| `head` | `-n 10` | Premières lignes | `head -n 20 /etc/hosts` |
| `nano` | - | Éditeur simple | `nano /etc/hostname` |
| `vi` / `vim` | - | Éditeur avancé | `vim /etc/sshd_config` |
| `cp` | `-r`, `-v` | Copie (récursive, verbeux) | `cp -r /home/user /backup/` |
| `mv` | - | Déplace/renomme | `mv old_name new_name` |
| `rm` | `-r`, `-f` | Supprime (récursif, force) | `rm -rf /tmp/old/` |

### Archivage

| Commande | Description | Exemple |
|----------|-------------|---------|
| `tar -czf` | Crée archive compressée | `tar -czf backup.tar.gz /home/` |
| `tar -xzf` | Extrait archive | `tar -xzf backup.tar.gz` |
| `gzip` | Compresse fichier | `gzip largefichier.log` |
| `gunzip` | Décompresse | `gunzip largefichier.log.gz` |

---

## 2️⃣ Utilisateurs & Permissions

### Gestion Utilisateurs

| Commande | Option | Description | Exemple |
|----------|--------|-------------|---------|
| `useradd` | `-m`, `-s` | Crée utilisateur (home, shell) | `useradd -m -s /bin/bash john` |
| `passwd` | - | Change mot de passe | `passwd john` |
| `usermod` | `-aG`, `-L` | Modifie utilisateur (groupe, lock) | `usermod -aG sudo john` |
| `userdel` | `-r` | Supprime utilisateur (+ home) | `userdel -r john` |
| `id` | - | Affiche UID/GID utilisateur | `id john` |
| `whoami` | - | Utilisateur actuel | `whoami` |
| `su` | `-` | Change utilisateur (login shell) | `su - john` |
| `sudo` | `-u`, `-i` | Exécute en root (autre user) | `sudo -u john cat /root/file` |

### Permissions (Octales)

| Octal | rwx | Sens |
|-------|-----|------|
| 4 | r-- | Lecture |
| 2 | -w- | Écriture |
| 1 | --x | Exécution |
| 7 | rwx | Tous |
| 5 | r-x | Lecture + Exécution |

| Commande | Description | Exemple |
|----------|-------------|---------|
| `chmod` | Change permissions | `chmod 755 script.sh` ou `chmod +x file` |
| `chown` | Change propriétaire/groupe | `chown john:staff /home/john` |

**Récapitulatif rapide :**
- `chmod 644 file` → rw-r--r-- (fichier standard)
- `chmod 755 dir` → rwxr-xr-x (répertoire)
- `chmod 600 key` → rw------- (clé SSH)
- `chmod 700 script` → rwx------ (script sensible)

---

## 3️⃣ Processes & Services

### Processus

| Commande | Option | Description | Exemple |
|----------|--------|-------------|---------|
| `ps` | `-aux`, `-ef` | Liste processus | `ps aux \| grep sshd` |
| `top` | - | Moniteur temps réel | `top` (appuyer `q` pour quitter) |
| `htop` | - | Top amélioré (si installé) | `htop` |
| `kill` | `-9` (SIGKILL) | Tue processus | `kill -9 1234` |
| `pkill` | - | Tue par nom | `pkill -f "python script"` |
| `pgrep` | - | Cherche par nom | `pgrep sshd` |
| `bg` / `fg` | - | Arrière-plan / Avant-plan | `bg`, `fg %1` |

### Services (Systemd)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl start` | Démarre service | `systemctl start sshd` |
| `systemctl stop` | Arrête service | `systemctl stop nginx` |
| `systemctl restart` | Redémarre service | `systemctl restart sshd` |
| `systemctl reload` | Recharge config | `systemctl reload firewalld` |
| `systemctl status` | Affiche état | `systemctl status sshd` |
| `systemctl enable` | Active au démarrage | `systemctl enable sshd` |
| `systemctl disable` | Désactive au démarrage | `systemctl disable sshd` |
| `systemctl is-active` | Vérifie si actif | `systemctl is-active sshd` |

---

## 4️⃣ Logs & Recherche

### Recherche de Texte

| Commande | Option | Description | Exemple |
|----------|--------|-------------|---------|
| `grep` | `-i`, `-v`, `-n`, `-c` | Cherche texte (insensible, inverse, numéro, compte) | `grep "error" /var/log/secure` |
| `grep` | `-E` | Expression régulière | `grep -E "Failed\|Success" log.txt` |
| `awk` | `-F` | Traite colonnes (séparateur) | `awk -F: '{print $1}' /etc/passwd` |
| `sed` | `s///` | Remplace texte (stream editor) | `sed 's/old/new/g' file.txt` |
| `cut` | `-d`, `-f` | Extrait colonnes | `cut -d: -f1 /etc/passwd` |
| `sort` | `-n`, `-r` | Trie (numérique, inverse) | `sort -n file.txt` |
| `uniq` | `-c` | Lignes uniques (compte) | `uniq -c file.txt` |
| `wc` | `-l`, `-w` | Compte (lignes, mots) | `wc -l /var/log/secure` |

**Exemple pipeline :**
```bash
# Compte les IPs qui se connectent
grep "Failed password" /var/log/secure | awk '{print $11}' | sort | uniq -c | sort -rn
```

### Logs Système

| Fichier | Contenu |
|---------|---------|
| `/var/log/messages` | Logs système généraux |
| `/var/log/secure` | SSH, authentification, sudo |
| `/var/log/audit/audit.log` | Auditd (si actif) |
| `/var/log/firewalld` | Firewall logs |
| `journalctl` | Logs systemd (alternative modernes) |

---

## 5️⃣ Réseau & Connectivité

### Connexions Réseau

| Commande | Option | Description | Exemple |
|----------|--------|-------------|---------|
| `ip addr` | - | Affiche interfaces réseau | `ip addr show` |
| `ip route` | - | Affiche routes | `ip route show` |
| `ping` | `-c` | Teste connexion (count) | `ping -c 3 8.8.8.8` |
| `traceroute` | - | Trace chemin vers hôte | `traceroute google.com` |
| `netstat` | `-an`, `-tulpn` | Stats réseau (all, TCP/UDP) | `netstat -tulpn \| grep LISTEN` |
| `ss` | `-an`, `-tulpn` | Stats réseau (moderne) | `ss -tulpn \| grep LISTEN` |
| `nslookup` | - | Requête DNS | `nslookup google.com` |
| `dig` | - | Requête DNS détaillée | `dig google.com` |
| `hostname` | - | Affiche/change hostname | `hostname` |
| `ifconfig` | - | Affiche interfaces (ancien) | `ifconfig` |

### Transfer de Fichiers

| Commande | Description | Exemple |
|----------|-------------|---------|
| `scp` | Copie via SSH | `scp file.txt user@host:/tmp/` |
| `rsync` | Sync intelligent | `rsync -avz /local/ user@host:/remote/` |
| `wget` | Télécharge URL | `wget https://example.com/file.tar.gz` |
| `curl` | Requête HTTP | `curl -I https://example.com` |

---

## 6️⃣ Disques & Espace

| Commande | Option | Description | Exemple |
|----------|--------|-------------|---------|
| `df` | `-h` | Espace disques (humain) | `df -h` |
| `du` | `-sh` | Taille dossier (résumé, humain) | `du -sh /home/` |
| `fdisk` | `-l` | Partitions | `fdisk -l` |
| `mount` / `umount` | - | Monte/démonte | `mount /dev/sdb1 /mnt/backup` |
| `lsblk` | - | Affiche blocs disques | `lsblk` |

---

## 7️⃣ Système & Infos

| Commande | Description | Exemple |
|----------|-------------|---------|
| `uname` | Info système | `uname -a` |
| `cat /etc/os-release` | Distro info | `cat /etc/os-release` |
| `uptime` | Temps depuis démarrage | `uptime` |
| `date` | Date/heure | `date` |
| `timedatectl` | Gestion temps (systemd) | `timedatectl status` |
| `free` | Mémoire (humain) | `free -h` |
| `lscpu` | Info CPU | `lscpu` |
| `lsmem` | Info mémoire | `lsmem` |

---

## 8️⃣ Tips & Tricks Rapides

### Raccourcis Utiles

```bash
# Historique des commandes
history                              # Affiche historique
!50                                  # Réexécute commande 50
!!                                   # Réexécute dernière commande
Ctrl+R                               # Recherche dans historique

# Redirections
command > file                       # Envoie output dans fichier (overwrite)
command >> file                      # Ajoute output à fichier (append)
command 2>&1                         # Envoie erreurs avec output
command 2>/dev/null                  # Supprime erreurs

# Pipes
command1 | command2                  # Output de cmd1 → input de cmd2
ps aux | grep sshd                   # Cherche processus sshd

# Variables
echo $VAR                            # Affiche variable
export VAR=value                     # Crée variable persistante
```

### Commandes Combinées Utiles

```bash
# Vérifie si service tourne
systemctl is-active sshd && echo "Running" || echo "Stopped"

# Affiche 10 derniers logins
lastlog | head -10

# Vérifie qui utilise ressources
ps aux --sort=-%mem | head -5        # Top 5 processus (RAM)
ps aux --sort=-%cpu | head -5        # Top 5 processus (CPU)

# Trouve fichiers modifiés récemment
find / -mtime -1 -type f            # Modifiés depuis 1 jour
find / -mmin -30 -type f            # Modifiés depuis 30 min
```

---

## 9️⃣ À Retenir Absolument

1. **Permissions** : 755 (dossiers), 644 (fichiers), 600 (clés SSH)
2. **Logs** : `/var/log/secure` (SSH), `/var/log/messages` (système)
3. **Services** : `systemctl start/stop/restart/status/enable`
4. **Recherche** : `grep` (texte), `find` (fichiers), `locate` (rapide)
5. **Pipes** : `|` enchaîne commandes, `>` / `>>` redirige output
6. **Sudo** : `sudo -i` (login root), `sudo -u user cmd` (autre user)
7. **Réseau** : `ss -tulpn` ou `netstat -tulpn` (ports écoutants)
8. **Root** : Évite de travailler en root, utilise `sudo` au besoin

---

**Dernière mise à jour** : Documentation projet Mini SOC  
**Niveau** : 2e année admin systèmes & réseaux
