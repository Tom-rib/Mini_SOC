# 01 - Installation de base Rocky Linux

## 📋 Objectif

Installer Rocky Linux en mode **minimal** (sans interface graphique) pour disposer d'un système propre, léger et sécurisé. Cette installation servira de base pour le serveur web exposé ou les autres composants du SOC.

---

## 🎓 Concepts clés

**Pourquoi une installation minimale ?**

Une installation minimale de Rocky Linux ne contient que les paquets essentiels au fonctionnement du système. Cela réduit la surface d'attaque (moins de services = moins de failles potentielles), améliore les performances et facilite la maintenance.

En entreprise, les serveurs Linux sont rarement équipés d'interfaces graphiques. Tout se fait en ligne de commande via SSH. Ce projet te prépare à ce type d'environnement professionnel.

---

## 🛠️ Prérequis

Avant de commencer, assure-toi d'avoir :

- **ISO Rocky Linux** téléchargée (version 9.x recommandée)
- **Machine virtuelle** créée avec :
  - 4 GB de RAM minimum
  - 60 GB d'espace disque
  - 1 carte réseau (NAT ou Bridge selon ton environnement)
- **Hyperviseur** : VirtualBox, VMware, KVM, Proxmox, etc.

---

## 📖 Étapes d'installation

### Étape 1 : Démarrage sur l'ISO

1. Monte l'ISO Rocky Linux dans ta VM
2. Démarre la VM
3. Sélectionne **"Install Rocky Linux"** dans le menu de démarrage

---

### Étape 2 : Choix de la langue et du clavier

1. Sélectionne **Français** (ou ta langue préférée)
2. Configure le clavier en **Français (AZERTY)** ou selon ta disposition
3. Clique sur **Continuer**

> 💡 **Astuce** : En entreprise, on garde souvent l'anglais pour faciliter le support et la documentation internationale.

---

### Étape 3 : Sélection du type d'installation

Dans l'écran de résumé de l'installation :

1. Clique sur **Installation Destination** (Destination de l'installation)
2. Vérifie que ton disque virtuel (60 GB) est bien sélectionné
3. **Important** : Garde l'option de partitionnement automatique pour l'instant (nous le refaisons dans le fichier suivant si nécessaire)
4. Clique sur **Terminé**

---

### Étape 4 : Sélection des logiciels (CRITIQUE)

1. Clique sur **Software Selection** (Sélection des logiciels)
2. Choisis **"Minimal Install"** dans la colonne de gauche
3. Dans la colonne de droite, tu peux ajouter (optionnel mais recommandé) :
   - ☑️ Standard
   - ☑️ Security Tools
   - ☑️ System Tools
4. **Ne coche PAS** :
   - ❌ Server with GUI
   - ❌ Workstation
   - ❌ Tout ce qui contient "Desktop"
5. Clique sur **Terminé**

> ⚠️ **Important** : Pas d'interface graphique ! Tout se fera en ligne de commande.

---

### Étape 5 : Configuration réseau

1. Clique sur **Network & Hostname**
2. Active ta carte réseau (bouton ON/OFF en haut à droite)
3. Note l'adresse IP attribuée (DHCP temporaire)
4. Change le hostname :
   - Hostname : `soc-web-rocky` (ou `soc-siem-rocky`, selon la VM)
5. Clique sur **Apply**, puis **Done**

---

### Étape 6 : Création du compte root

1. Clique sur **Root Password**
2. Entre un mot de passe **fort** (minimum 12 caractères, majuscules, chiffres, symboles)
3. Confirme le mot de passe
4. **Coche** "Allow root SSH login with password" (on le désactivera plus tard pour la sécurité)
5. Clique sur **Done**

> 🔐 **Note de sécurité** : En production, on désactive toujours le login root direct. On passe par un compte utilisateur + sudo.

---

### Étape 7 : Création d'un compte utilisateur (optionnel mais recommandé)

1. Clique sur **User Creation**
2. Remplis les champs :
   - Full name : `Admin SOC`
   - Username : `admin-soc` (ou ton prénom)
   - Password : mot de passe fort
3. Coche **"Make this user administrator"** (donne les droits sudo)
4. Clique sur **Done**

---

### Étape 8 : Lancer l'installation

1. Vérifie que tous les points sont validés (pas d'icône d'avertissement rouge)
2. Clique sur **Begin Installation**
3. Attends que l'installation se termine (environ 5-10 minutes selon ton matériel)

---

### Étape 9 : Redémarrage et connexion

1. Clique sur **Reboot** une fois l'installation terminée
2. Retire l'ISO du lecteur virtuel (pour éviter de reboucler sur l'installation)
3. La VM redémarre
4. Tu arrives sur un écran de connexion en mode texte :

```bash
Rocky Linux 9.x (Blue Onyx)
Kernel 5.14.0-xxx

soc-web-rocky login: _
```

5. Connecte-toi avec le compte **root** ou ton compte utilisateur créé

---

## 🧪 Commandes de vérification post-installation

Une fois connecté, vérifie que tout fonctionne correctement :

### Vérifier la version de Rocky Linux

```bash
cat /etc/os-release
```

**Résultat attendu :**

```
NAME="Rocky Linux"
VERSION="9.x (Blue Onyx)"
ID="rocky"
...
```

---

### Vérifier le hostname

```bash
hostnamectl
```

**Résultat attendu :**

```
Static hostname: soc-web-rocky
Icon name: computer-vm
Chassis: vm
Operating System: Rocky Linux 9.x
```

---

### Vérifier l'espace disque

```bash
df -h
```

**Résultat attendu :**

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        60G  2.5G   55G   5% /
...
```

---

### Vérifier la connectivité réseau

```bash
ip addr show
ping -c 4 google.com
```

**Résultat attendu :**

- Une adresse IP visible sur eth0 ou enp0s3
- 4 paquets envoyés et reçus sans perte

---

### Vérifier les mises à jour

```bash
sudo dnf check-update
```

> 💡 Rocky Linux utilise **dnf** (équivalent de `apt` sur Debian/Ubuntu) pour gérer les paquets.

---

### Mettre à jour le système

```bash
sudo dnf update -y
```

Cette commande installe toutes les mises à jour de sécurité disponibles. C'est **obligatoire** avant de continuer.

---

## ⏱️ Durée estimée

**Temps total : 1h à 2h**

- Installation : 10-15 min
- Configuration manuelle : 15 min
- Mises à jour : 15-30 min
- Vérifications et tests : 15-20 min

---

## 🔗 Prochaine étape

Une fois l'installation validée et le système à jour, passe à l'étape suivante :

➡️ **[02_partitionnement.md](./02_partitionnement.md)** - Configuration d'un partitionnement sécurisé

Si tu veux approfondir directement la sécurisation réseau, consulte :

➡️ **[03_config_reseau.md](./03_config_reseau.md)** - Configuration réseau en IP fixe

---

## 📚 Ressources complémentaires

- [Documentation officielle Rocky Linux](https://docs.rockylinux.org/)
- [Guide d'installation Rocky Linux (EN)](https://docs.rockylinux.org/guides/installation/)
- [Différences RHEL vs Rocky Linux](https://wiki.rockylinux.org/)

---

**✅ Checkpoint :** Tu as maintenant une installation propre et fonctionnelle de Rocky Linux. Ton système est prêt à être sécurisé et configuré pour le projet SOC.
