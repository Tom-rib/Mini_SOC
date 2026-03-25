# 02 - Partitionnement sécurisé

## 📋 Objectif

Mettre en place un **partitionnement sécurisé** de ton disque avec des partitions séparées pour `/`, `/var`, `/home` et `swap`. Cette séparation limite l'impact en cas de compromission ou de saturation d'une partition.

---

## 🎓 Concepts clés

**Pourquoi séparer les partitions ?**

En environnement professionnel, on ne met jamais tout sur une seule partition (`/`). Voici pourquoi :

1. **Isolation des données** : Si un attaquant remplit `/var/log` avec des logs, il ne pourra pas saturer `/home` ou `/`
2. **Limiter la compromission** : Si `/home` est compromis, les fichiers système critiques dans `/` restent intacts
3. **Faciliter les sauvegardes** : On peut sauvegarder uniquement `/home` sans toucher au système
4. **Performance** : Certaines partitions peuvent être montées avec des options spécifiques (noexec, nosuid)

**Les partitions principales :**

- **`/`** (root) : Système de base, binaires, configurations
- **`/var`** : Logs, fichiers temporaires, base de données
- **`/home`** : Répertoires personnels des utilisateurs
- **`swap`** : Mémoire virtuelle (extension de la RAM)

---

## 🛠️ Prérequis

- Rocky Linux installé (voir [01_installation_base.md](./01_installation_base.md))
- Accès root ou sudo
- Disque de 60 GB minimum

> ⚠️ **Attention** : Si tu as déjà installé Rocky Linux avec partitionnement automatique, cette étape nécessite une réinstallation complète. Sinon, tu peux appliquer ce partitionnement **pendant l'installation**.

---

## 📖 Méthode 1 : Partitionnement pendant l'installation (RECOMMANDÉ)

Si tu n'as pas encore installé Rocky Linux ou si tu recommences, voici comment partitionner **pendant l'installation**.

### Étape 1 : Accéder au partitionnement manuel

1. Lors de l'installation, au moment de **Installation Destination** :
2. Sélectionne ton disque
3. Choisis **"Custom"** (Personnalisé) au lieu de "Automatic"
4. Clique sur **Done**

---

### Étape 2 : Créer les partitions manuellement

Tu arrives sur l'écran de partitionnement manuel. Voici le schéma à appliquer :

#### Partition 1 : `/boot` (optionnel mais recommandé)

- **Point de montage** : `/boot`
- **Taille** : `1 GB` (1024 MB)
- **Type** : `ext4`

> 💡 `/boot` contient le noyau Linux. Le séparer permet de démarrer même si `/` est corrompu.

---

#### Partition 2 : `swap`

- **Point de montage** : `swap`
- **Taille** : `4 GB` (4096 MB) - Équivalent à la RAM
- **Type** : `swap`

> 💡 **Règle du swap** : Taille = RAM si RAM < 8 GB, sinon taille = RAM/2

---

#### Partition 3 : `/` (root)

- **Point de montage** : `/`
- **Taille** : `20 GB`
- **Type** : `xfs` (par défaut Rocky Linux) ou `ext4`

> 💡 La racine `/` contient le système de base. 20 GB suffisent largement.

---

#### Partition 4 : `/var`

- **Point de montage** : `/var`
- **Taille** : `15 GB`
- **Type** : `xfs` ou `ext4`

> 💡 `/var` contient les logs et les fichiers temporaires. En SOC, les logs peuvent prendre beaucoup de place.

---

#### Partition 5 : `/home`

- **Point de montage** : `/home`
- **Taille** : `Reste du disque` (environ 20 GB)
- **Type** : `xfs` ou `ext4`

> 💡 Utilise tout l'espace restant pour `/home`.

---

### Étape 3 : Valider le partitionnement

1. Vérifie que toutes les partitions sont bien créées
2. Clique sur **Done**
3. Confirme les changements
4. Continue l'installation normalement

---

## 📖 Méthode 2 : Partitionnement post-installation (AVANCÉ)

> ⚠️ **Danger** : Cette méthode nécessite de manipuler un disque en production et peut entraîner une perte de données. Utilise-la uniquement si tu sais ce que tu fais ou pour un second disque.

Si tu veux ajouter un **second disque** à une VM déjà installée et le partitionner, voici comment :

### Étape 1 : Ajouter un disque à la VM

1. Éteins la VM
2. Dans les paramètres de la VM, ajoute un second disque virtuel (20-30 GB)
3. Redémarre la VM

---

### Étape 2 : Identifier le nouveau disque

```bash
lsblk
```

**Résultat attendu :**

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   60G  0 disk
├─sda1   8:1    0   59G  0 part /
└─sda2   8:2    0    1G  0 part [SWAP]
sdb      8:16   0   30G  0 disk       <-- Nouveau disque
```

Le nouveau disque apparaît comme `/dev/sdb`.

---

### Étape 3 : Partitionner le nouveau disque avec `fdisk`

```bash
sudo fdisk /dev/sdb
```

#### Commandes fdisk :

1. **`n`** → Créer une nouvelle partition
2. **`p`** → Partition primaire
3. **`1`** → Numéro de partition
4. **Entrée** → Premier secteur (par défaut)
5. **`+10G`** → Taille de la partition (10 GB par exemple)
6. **`w`** → Écrire les changements et quitter

Répète l'opération pour créer plusieurs partitions si nécessaire.

---

### Étape 4 : Formater les partitions

```bash
sudo mkfs.ext4 /dev/sdb1   # Partition 1 en ext4
sudo mkfs.xfs /dev/sdb2    # Partition 2 en xfs
```

---

### Étape 5 : Monter les partitions

Créer les points de montage :

```bash
sudo mkdir -p /mnt/data
sudo mkdir -p /mnt/logs
```

Monter les partitions :

```bash
sudo mount /dev/sdb1 /mnt/data
sudo mount /dev/sdb2 /mnt/logs
```

---

### Étape 6 : Rendre le montage permanent

Édite le fichier `/etc/fstab` :

```bash
sudo nano /etc/fstab
```

Ajoute ces lignes à la fin :

```
/dev/sdb1  /mnt/data  ext4  defaults  0  2
/dev/sdb2  /mnt/logs  xfs   defaults  0  2
```

Sauvegarde et teste :

```bash
sudo mount -a
```

---

## 🧪 Commandes de vérification

### Vérifier les partitions

```bash
lsblk
```

**Résultat attendu :**

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   60G  0 disk
├─sda1   8:1    0    1G  0 part /boot
├─sda2   8:2    0    4G  0 part [SWAP]
├─sda3   8:3    0   20G  0 part /
├─sda4   8:4    0   15G  0 part /var
└─sda5   8:5    0   20G  0 part /home
```

---

### Vérifier l'espace disque

```bash
df -h
```

**Résultat attendu :**

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda3        20G  2.1G   17G  11% /
/dev/sda1       974M  150M  757M  17% /boot
/dev/sda4        15G  1.2G   13G   9% /var
/dev/sda5        20G  150M   19G   1% /home
```

---

### Vérifier le swap

```bash
free -h
```

**Résultat attendu :**

```
              total        used        free      shared  buff/cache   available
Mem:          3.8Gi       500Mi       2.5Gi        10Mi       800Mi       3.1Gi
Swap:         4.0Gi          0B       4.0Gi
```

---

### Vérifier le fichier fstab

```bash
cat /etc/fstab
```

**Contenu attendu :**

```
UUID=xxx  /       xfs     defaults        0 1
UUID=xxx  /boot   ext4    defaults        0 2
UUID=xxx  /var    xfs     defaults        0 2
UUID=xxx  /home   xfs     defaults        0 2
UUID=xxx  swap    swap    defaults        0 0
```

---

## 📊 Tableau récapitulatif des tailles recommandées

| Partition   | Taille recommandée | Description                           |
|-------------|--------------------|---------------------------------------|
| `/boot`     | 1 GB               | Noyau et fichiers de démarrage        |
| `swap`      | 4 GB (= RAM)       | Mémoire virtuelle                     |
| `/`         | 20 GB              | Système de base                       |
| `/var`      | 15 GB              | Logs et données variables             |
| `/home`     | Reste (~20 GB)     | Répertoires utilisateurs              |

**Total pour 60 GB :** 1 + 4 + 20 + 15 + 20 = 60 GB

---

## ⏱️ Durée estimée

**Temps total : 45 minutes**

- Lecture et compréhension : 10 min
- Partitionnement pendant installation : 15 min
- OU Partitionnement post-installation : 30 min
- Vérifications : 10 min

---

## 🔗 Prochaine étape

Maintenant que ton système est partitionné de manière sécurisée, configure le réseau en IP fixe :

➡️ **[03_config_reseau.md](./03_config_reseau.md)** - Configuration réseau avec IP fixe

Si tu veux passer directement au hardening, consulte :

➡️ **[04_securisation_ssh.md](./04_securisation_ssh.md)** - Sécurisation de SSH (à créer)

---

## 📚 Ressources complémentaires

- [Guide LVM Rocky Linux](https://docs.rockylinux.org/guides/file_sharing/local_file_systems/)
- [Partitionnement Linux (EN)](https://wiki.archlinux.org/title/Partitioning)
- [fstab documentation](https://man7.org/linux/man-pages/man5/fstab.5.html)

---

**✅ Checkpoint :** Ton système dispose désormais d'un partitionnement sécurisé qui limite les risques en cas d'attaque ou de saturation.
