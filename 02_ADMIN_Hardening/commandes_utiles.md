# Commandes utiles - Mémo rapide

> Référence rapide des commandes Linux essentielles pour le projet Mini SOC

---

## 📦 Gestion des paquets (Rocky Linux / RHEL)

### DNF (gestionnaire de paquets)

```bash
# Mettre à jour tous les paquets
sudo dnf update -y

# Installer un paquet
sudo dnf install <paquet> -y

# Chercher un paquet
sudo dnf search <mot-clé>

# Supprimer un paquet
sudo dnf remove <paquet>

# Lister les paquets installés
sudo dnf list installed

# Nettoyer le cache
sudo dnf clean all

# Voir l'historique des installations
sudo dnf history
```

---

## 🌐 Réseau

### Afficher les interfaces réseau

```bash
# Méthode moderne
ip addr show

# Afficher uniquement les IP
ip -br addr show

# Ancienne méthode (si disponible)
ifconfig
```

---

### Configuration IP avec NetworkManager

```bash
# Lister les connexions
nmcli connection show

# Voir les détails d'une connexion
nmcli connection show enp0s3

# Configurer IP fixe
sudo nmcli connection modify enp0s3 ipv4.addresses 192.168.1.10/24
sudo nmcli connection modify enp0s3 ipv4.gateway 192.168.1.1
sudo nmcli connection modify enp0s3 ipv4.dns "8.8.8.8 8.8.4.4"
sudo nmcli connection modify enp0s3 ipv4.method manual

# Redémarrer une interface
sudo nmcli connection down enp0s3
sudo nmcli connection up enp0s3
```

---

### Tests réseau

```bash
# Tester la connectivité
ping -c 4 google.com

# Résolution DNS
nslookup google.com
dig google.com

# Afficher la table de routage
ip route show

# Voir les connexions actives
ss -tuln
netstat -tuln  # Ancienne méthode

# Scanner les ports ouverts (depuis l'extérieur)
nmap -p- 192.168.1.10
```

---

## 🔐 SSH

### Connexion SSH

```bash
# Connexion simple
ssh utilisateur@192.168.1.10

# Connexion avec port personnalisé
ssh -p 2222 utilisateur@192.168.1.10

# Connexion avec clé SSH
ssh -i ~/.ssh/ma_cle utilisateur@192.168.1.10
```

---

### Gestion des clés SSH

```bash
# Générer une paire de clés
ssh-keygen -t ed25519 -C "mon-email@example.com"

# Copier la clé publique sur un serveur
ssh-copy-id utilisateur@192.168.1.10

# Vérifier les permissions des clés
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh
```

---

## 🔥 Firewall (firewalld)

### Commandes de base

```bash
# Vérifier l'état
sudo systemctl status firewalld

# Démarrer/arrêter/redémarrer
sudo systemctl start firewalld
sudo systemctl stop firewalld
sudo systemctl restart firewalld

# Lister les règles actives
sudo firewall-cmd --list-all

# Voir les zones disponibles
sudo firewall-cmd --get-zones

# Voir la zone par défaut
sudo firewall-cmd --get-default-zone
```

---

### Gestion des ports

```bash
# Ouvrir un port (temporaire)
sudo firewall-cmd --add-port=2222/tcp

# Ouvrir un port (permanent)
sudo firewall-cmd --add-port=2222/tcp --permanent
sudo firewall-cmd --reload

# Ouvrir un service (ex: HTTP)
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload

# Fermer un port
sudo firewall-cmd --remove-port=2222/tcp --permanent
sudo firewall-cmd --reload

# Bloquer une IP
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" reject' --permanent
sudo firewall-cmd --reload
```

---

## 👤 Gestion des utilisateurs

### Utilisateurs

```bash
# Créer un utilisateur
sudo useradd -m -s /bin/bash utilisateur

# Définir un mot de passe
sudo passwd utilisateur

# Supprimer un utilisateur
sudo userdel -r utilisateur

# Lister les utilisateurs
cat /etc/passwd | cut -d: -f1

# Changer de mot de passe (soi-même)
passwd
```

---

### Groupes et sudo

```bash
# Ajouter un utilisateur à un groupe
sudo usermod -aG wheel utilisateur  # Groupe wheel = sudo sur Rocky

# Voir les groupes d'un utilisateur
groups utilisateur

# Éditer les permissions sudo
sudo visudo

# Tester sudo
sudo whoami  # Doit afficher "root"
```

---

## 📂 Fichiers et permissions

### Navigation et manipulation

```bash
# Lister fichiers
ls -lah

# Changer de répertoire
cd /etc/ssh

# Créer un dossier
mkdir -p /home/admin/projet

# Copier un fichier
cp fichier.txt /backup/

# Déplacer/renommer
mv fichier.txt nouveau_nom.txt

# Supprimer (attention !)
rm fichier.txt
rm -rf dossier/  # Récursif, prudence !
```

---

### Permissions

```bash
# Changer les permissions (rwx = 7, rw- = 6, r-- = 4)
chmod 600 fichier.txt  # rw------- (propriétaire seulement)
chmod 644 fichier.txt  # rw-r--r--
chmod 755 script.sh    # rwxr-xr-x (exécutable)

# Changer le propriétaire
chown utilisateur:groupe fichier.txt

# Changer récursivement
chown -R utilisateur:groupe /home/utilisateur/

# Voir les permissions
ls -l fichier.txt
```

---

## 📝 Logs

### Consulter les logs

```bash
# Logs SSH
sudo tail -f /var/log/secure

# Logs système
sudo tail -f /var/log/messages

# Logs avec journalctl (systemd)
sudo journalctl -u sshd -f       # SSH en temps réel
sudo journalctl -u nginx -f      # Nginx en temps réel
sudo journalctl --since today    # Logs du jour

# Logs du noyau
dmesg | tail

# Rechercher dans les logs
grep "Failed password" /var/log/secure
```

---

## ⚙️ Services (systemd)

### Gestion des services

```bash
# Voir l'état d'un service
sudo systemctl status sshd

# Démarrer/arrêter/redémarrer
sudo systemctl start sshd
sudo systemctl stop sshd
sudo systemctl restart sshd

# Recharger la configuration (sans redémarrer)
sudo systemctl reload sshd

# Activer au démarrage
sudo systemctl enable sshd

# Désactiver au démarrage
sudo systemctl disable sshd

# Lister tous les services
systemctl list-units --type=service

# Voir les services en échec
systemctl --failed
```

---

## 💾 Disques et partitions

### Afficher l'espace disque

```bash
# Espace disque global
df -h

# Taille d'un dossier
du -sh /var/log/

# Trouver les gros fichiers
sudo du -ah /var | sort -rh | head -n 20
```

---

### Partitions et montage

```bash
# Lister les disques et partitions
lsblk

# Voir les partitions montées
mount | column -t

# Monter une partition
sudo mount /dev/sdb1 /mnt/data

# Démonter une partition
sudo umount /mnt/data
```

---

## 🔍 Processus

### Gestion des processus

```bash
# Lister les processus
ps aux

# Processus en temps réel
top
htop  # Si installé (meilleur)

# Trouver un processus
ps aux | grep nginx

# Tuer un processus
kill <PID>
kill -9 <PID>  # Force kill

# Tuer par nom
pkill nginx
killall nginx
```

---

## 🕒 Système et date

### Informations système

```bash
# Version du système
cat /etc/os-release

# Kernel version
uname -r

# Uptime (temps de fonctionnement)
uptime

# Charge CPU/RAM
free -h
top
```

---

### Date et heure

```bash
# Voir la date
date

# Changer le fuseau horaire
sudo timedatectl set-timezone Europe/Paris

# Voir le fuseau actuel
timedatectl

# Synchroniser l'heure (NTP)
sudo systemctl enable chronyd
sudo systemctl start chronyd
```

---

## 📦 Archives et compression

### Tar (archives)

```bash
# Créer une archive
tar -czvf archive.tar.gz /home/admin/projet/

# Extraire une archive
tar -xzvf archive.tar.gz

# Voir le contenu sans extraire
tar -tzvf archive.tar.gz
```

---

### Zip/Unzip

```bash
# Créer un zip
zip -r archive.zip /home/admin/projet/

# Extraire un zip
unzip archive.zip

# Lister le contenu
unzip -l archive.zip
```

---

## 🔎 Recherche de fichiers

### Find

```bash
# Trouver un fichier par nom
find /etc -name "sshd_config"

# Trouver des fichiers modifiés dans les dernières 24h
find /var/log -mtime -1

# Trouver des fichiers > 100 MB
find /var -size +100M

# Trouver et supprimer (prudence !)
find /tmp -name "*.tmp" -delete
```

---

### Grep (recherche de texte)

```bash
# Chercher dans un fichier
grep "PermitRootLogin" /etc/ssh/sshd_config

# Recherche récursive
grep -r "error" /var/log/

# Ignorer la casse
grep -i "failed" /var/log/secure

# Afficher les numéros de ligne
grep -n "Port" /etc/ssh/sshd_config
```

---

## 🔧 Dépannage rapide

### Réseau ne fonctionne pas

```bash
sudo systemctl restart NetworkManager
sudo nmcli connection up enp0s3
ping 8.8.8.8  # Test sans DNS
ping google.com  # Test avec DNS
```

---

### Service ne démarre pas

```bash
sudo systemctl status <service>
sudo journalctl -u <service> -n 50
```

---

### Disque plein

```bash
df -h
sudo du -sh /var/log/*
sudo journalctl --vacuum-time=7d  # Nettoyer les logs > 7 jours
```

---

## 📚 Ressources

- [Commandes Linux essentielles](https://www.hostinger.com/tutorials/linux-commands)
- [DNF Cheat Sheet](https://docs.rockylinux.org/guides/package_management/)
- [Systemd Cheat Sheet](https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units)

---

**💡 Conseil** : Enregistre cette page dans tes favoris et ouvre-la dans un onglet pendant le projet. Elle te servira de référence rapide !
