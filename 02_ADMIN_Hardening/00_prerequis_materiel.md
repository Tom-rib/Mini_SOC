# 01 - Prérequis matériel et logiciel

## 📋 Objectif

Vérifier que tu disposes de tout le matériel et les logiciels nécessaires avant de démarrer le projet Mini SOC.

---

## 🎓 Concepts clés

**Pourquoi vérifier les prérequis ?**

Un projet d'infrastructure nécessite des ressources matérielles et logicielles spécifiques. Commencer sans vérifier les prérequis peut mener à des blocages en cours de route (manque de RAM, incompatibilités, etc.).

Ce fichier te permet de valider que ton environnement est prêt avant de commencer l'installation.

---

## 🛠️ Prérequis matériel

### Machine hôte recommandée

| Composant | Minimum | Recommandé |
|-----------|---------|------------|
| **CPU** | 4 cœurs | 6-8 cœurs |
| **RAM** | 12 GB | 16 GB ou plus |
| **Stockage** | 150 GB libre | 200 GB SSD |
| **Réseau** | Carte Ethernet ou WiFi | Ethernet filaire |

> 💡 **Note** : Les 3 VMs vont tourner simultanément. Prévois assez de ressources.

---

### Répartition des ressources par VM

| VM | Rôle | CPU | RAM | Disque |
|----|------|-----|-----|--------|
| VM 1 | Serveur Web | 2 cœurs | 4 GB | 60 GB |
| VM 2 | SOC/SIEM | 2 cœurs | 4 GB | 80 GB |
| VM 3 | Monitoring | 2 cœurs | 4 GB | 60 GB |
| **Total** | - | **6 cœurs** | **12 GB** | **200 GB** |

---

## 💿 Prérequis logiciel

### Hyperviseur (choisis-en UN)

- **VirtualBox** (gratuit) : [Télécharger](https://www.virtualbox.org/)
- **VMware Workstation** (essai gratuit) : [Télécharger](https://www.vmware.com/)
- **KVM/QEMU** (Linux natif)
- **Proxmox** (si serveur dédié)

> 💡 **Recommandation** : VirtualBox si tu débutes, VMware si tu as déjà de l'expérience.

---

### ISO Rocky Linux

- **Version recommandée** : Rocky Linux 9.x (dernière stable)
- **Téléchargement** : [https://rockylinux.org/download](https://rockylinux.org/download)
- **Variante** : DVD ISO (contient tous les paquets)
- **Taille** : ~10 GB

---

### Outils complémentaires

| Outil | Utilité | Installation |
|-------|---------|--------------|
| **PuTTY** ou **MobaXterm** (Windows) | Client SSH | [putty.org](https://www.putty.org/) |
| **Terminal** (Linux/Mac) | Client SSH natif | Déjà installé |
| **Navigateur Web** | Accès interfaces Wazuh/Grafana | Chrome/Firefox |
| **Éditeur de texte** | Édition de configs locales | VSCode, Notepad++ |

---

## 🧪 Commandes de vérification

### Vérifier les ressources de la machine hôte

**Windows :**

```powershell
systeminfo | findstr /C:"Processors" /C:"RAM"
```

**Linux :**

```bash
lscpu | grep "CPU(s)"
free -h
df -h
```

**Mac :**

```bash
sysctl hw.ncpu
sysctl hw.memsize
df -h
```

---

### Vérifier l'hyperviseur

**VirtualBox :**

```bash
VBoxManage --version
```

**VMware :**

```bash
vmware --version
```

---

### Vérifier l'ISO Rocky Linux

Vérifie l'intégrité de l'ISO téléchargée avec la somme de contrôle SHA256 :

**Linux/Mac :**

```bash
sha256sum Rocky-9.x-x86_64-dvd.iso
```

**Windows (PowerShell) :**

```powershell
Get-FileHash Rocky-9.x-x86_64-dvd.iso -Algorithm SHA256
```

Compare le résultat avec le checksum officiel sur le site Rocky Linux.

---

## 📊 Checklist de validation

Avant de continuer, coche chaque élément :

- [ ] Machine hôte avec au moins 12 GB RAM et 150 GB disque libre
- [ ] Hyperviseur installé et fonctionnel
- [ ] ISO Rocky Linux 9.x téléchargée et vérifiée
- [ ] Client SSH disponible (PuTTY, Terminal, etc.)
- [ ] Connexion Internet stable
- [ ] Temps disponible (au moins 2h pour la première VM)

---

## ⏱️ Durée estimée

**Temps total : 30 minutes**

- Vérification matériel : 5 min
- Téléchargement ISO : 10-20 min (selon connexion)
- Installation hyperviseur : 5-10 min
- Tests : 5 min

---

## 🔗 Prochaine étape

Une fois les prérequis validés, passe à la planification du réseau :

➡️ **[02_schema_reseau.md](./02_schema_reseau.md)** - Architecture réseau du projet

---

## 📚 Ressources complémentaires

- [Rocky Linux - System Requirements](https://docs.rockylinux.org/guides/installation/)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [VMware Documentation](https://docs.vmware.com/)

---

**✅ Checkpoint :** Tu as vérifié que ton environnement est prêt. Tu peux maintenant passer à l'architecture réseau du projet.
