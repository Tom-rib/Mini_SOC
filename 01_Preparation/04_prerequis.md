# ✅ 4. Prérequis et Matériel

**Durée de lecture estimée** : 10 minutes  
**Objectif** : Vérifier que tu as tout ce qu'il faut avant de commencer  
**Prérequis** : Avoir compris l'architecture (voir [`02_architecture_schema.md`](02_architecture_schema.md))

---

## 🖥️ Configuration Matérielle Requise

### Minimum ABSOLU (peut être serré)

| Composant | Requis | Notes |
|---|---|---|
| **CPU** | 8 cores | 4 cores = très lent, la virtualisation sera limite |
| **RAM** | 16 GB | 12 GB = peut crasher pendant tests lourds |
| **Disque** | 150 GB SSD | 100 GB = limite, pas de place pour snapshots |
| **Réseau** | 1 Gbps Ethernet | WiFi = peut ralentir |

### Recommandé (Confortable)

| Composant | Idéal |
|---|---|
| **CPU** | 16 cores (12x3 VM) |
| **RAM** | 32 GB (8 GB par VM + OS host) |
| **Disque** | 300 GB SSD (Nvme) |
| **Réseau** | Filaire Gigabit |

### Répartition RAM par VM

```
Ton ordinateur (OS Host)      : 4-6 GB
├─ VM 1 (Web Server)          : 4 GB
├─ VM 2 (SOC/SIEM)            : 6 GB ⭐ (Elasticsearch gourmand)
├─ VM 3 (Monitoring)          : 4 GB
└─ VM 4 (Kali - optionnel)    : 2 GB

Total : 4-6 + 4 + 6 + 4 + 2 = 20-22 GB
```

⚠️ **Important** : Ne pas allouer TOUTE ta RAM aux VMs, garder 2-4 GB pour l'OS host !

### Budget Estimé

Si tu n'as pas le matériel :

| Option | Coût | Pros | Cons |
|---|---|---|---|
| **Cloud (AWS/Azure/GCP)** | 100-150€/mois | Facile setup, pays à l'usage | Cher, données en ligne |
| **Louer un serveur dédié** | 30-50€/mois | Puissant, 24/7 | Partagé, délai setup |
| **Acheter occasion** | 200-500€ | One-time cost | Risque vieillissement |
| **Home lab existant** | 0€ | FREE | Performance variable |

---

## 💾 Logiciels & Hyperviseurs

### 1. Hyperviseur de Virtualisation

Choisis UN :

#### ✅ **VirtualBox** (Recommandé pour débuter)

| Aspect | Détail |
|---|---|
| **Téléchargement** | https://www.virtualbox.org/wiki/Downloads |
| **Système** | Windows, macOS, Linux |
| **Gratuit** | ✅ Open Source |
| **Performance** | Bon (pas le meilleur) |
| **Snapshots** | ✅ Excellents |
| **Réseau** | ✅ Bridge/NAT simple |
| **Installation** | Très facile |

**Setup VirtualBox**
```bash
# macOS
brew install virtualbox

# Windows
# Télécharger .exe depuis virtualbox.org

# Linux (Ubuntu/Debian)
sudo apt install virtualbox

# Linux (Rocky/Fedora)
sudo dnf install -y VirtualBox
```

#### ✅ **Proxmox VE** (Pro, plus complexe)

| Aspect | Détail |
|---|---|
| **Type** | Hyperviseur bare-metal |
| **Gratuit** | ✅ Open Source |
| **Performance** | ⭐⭐⭐⭐⭐ (Meilleur) |
| **Snapshots** | ✅ Très rapides |
| **Réseau** | Avancé (VLAN, bonds) |
| **Installation** | Plus complexe (bare-metal) |
| **Hardware** | Nécessite PC dédié |

#### ✅ **KVM** (Linux only, performant)

```bash
sudo dnf install -y qemu-kvm virt-manager

# Interface graphique
virt-manager

# Ou CLI
virsh list
```

#### ❌ **VMware Workstation** (Payant, overkill)

---

### 2. Système d'Exploitation ISO

Tu auras besoin des ISO pour installer les VMs :

#### Rocky Linux 9 (3 exemplaires)

```
À télécharger :
https://rockylinux.org/download

Fichier : Rocky-9.x-Minimal-x86_64-dvd.iso
(Prendre "Minimal" pour installation légère)

Taille : ~1.2 GB
```

**Vérifier intégrité** (important !)
```bash
# Télécharger le checksum
# Vérifier l'ISO
sha256sum Rocky-9.3-Minimal-x86_64-dvd.iso
# Comparer avec le fichier .sha256 officiel
```

#### Kali Linux (optionnel, pour attaques)

```
À télécharger :
https://www.kali.org/get-kali/

Fichier : kali-linux-rolling-vmware-amd64.7z
(Précompilé = installation 1 click)

Ou : kali-linux-rolling-installer-amd64.iso (manuel)
```

---

### 3. Outils Locaux (Ton ordinateur)

#### Obligatoires

| Outil | Pourquoi | Téléchargement |
|---|---|---|
| **Terminal/Bash** | Administrer les VMs | Déjà installé (Linux/macOS) ou WSL2 (Windows) |
| **SSH Client** | Accès à distance aux VMs | Déjà installé (Windows 10+, Linux, macOS) |
| **Git** | Versionner ton projet | https://git-scm.com/downloads |
| **Text Editor** | Documentation + scripts | VSCode, Vim, Nano (déjà là) |

#### Optionnels (Utiles)

| Outil | Usage |
|---|---|
| **Nmap** | Scanner réseau, tests attaques |
| **Wireshark** | Analyser le trafic réseau |
| **Ansible** | Automatiser configurations |
| **Docker** | Alternative à VMs si tu veux |

**Installation macOS/Linux**
```bash
# macOS (Homebrew)
brew install nmap wireshark ansible

# Linux (Fedora/Rocky)
sudo dnf install -y nmap wireshark-cli ansible

# Linux (Ubuntu/Debian)
sudo apt install -y nmap wireshark ansible
```

---

## 📚 Connaissances Préalables Requises

### Niveau 1 : Essentiel (Tu dois savoir ça)

- ✅ **Ligne de commande Bash**
  - Naviguer directories : `cd`, `ls`, `pwd`
  - Éditer fichiers : `nano`, `vi`, `cat`
  - Permissions : `chmod`, `chown`
  - Processes : `ps`, `kill`, `top`

- ✅ **SSH**
  - Connexion basique : `ssh user@host`
  - Générer clés : `ssh-keygen`
  - Copier fichiers : `scp`, `rsync`

- ✅ **Réseau de base**
  - Adresses IP (IPv4 : 192.168.x.x)
  - Ports (SSH=22, HTTP=80, HTTPS=443)
  - Concepts : firewall, ports ouverts/fermés

- ✅ **Adminintration Linux**
  - Packages : `dnf` / `apt`
  - Services : `systemctl`
  - Users : `useradd`, `passwd`
  - Sudo : utiliser `sudo` correctement

### Niveau 2 : Utile (Accélère l'apprentissage)

- ⭐ **Fichiers de configuration**
  - Éditer `.conf` avec respect syntax
  - Commentaires `#`
  - Indentation = important

- ⭐ **Logs Linux**
  - Lire `/var/log/`
  - Format timestamps
  - Comprendre syslog

- ⭐ **Firewall**
  - Ports : qu'est-ce qu'un port ?
  - Pare-feu : bloquer/permettre
  - iptables/firewalld : concepts basiques

### Niveau 3 : Avancé (Bonus)

- 🚀 **Ansible** ou **Bash scripting**
  - Automatiser tâches répétitives
  - Pas obligatoire mais utile

- 🚀 **Docker**
  - Conteneurisation (alternative à VMs)
  - Compose pour multi-services

- 🚀 **Monitoring & Logs**
  - ELK Stack : Elasticsearch, Logstash, Kibana
  - Prometheus/Grafana
  - Wazuh

---

## 📋 Checklist Avant de Commencer

### Étape 1 : Matériel ✅

- [ ] **RAM** : 16 GB minimum (32 GB idéal)
- [ ] **Disque** : 150 GB SSD libre minimum
- [ ] **CPU** : 8 cores ou plus
- [ ] **Réseau** : Accès Internet stable

### Étape 2 : Hyperviseur ✅

- [ ] VirtualBox 7.0+ installé et testé
  ```bash
  vboxmanage --version  # Doit afficher numéro version
  ```

- [ ] OU Proxmox/KVM installé et testé

### Étape 3 : ISO Téléchargées ✅

- [ ] Rocky Linux 9 Minimal (3x)
  ```bash
  # Après téléchargement
  sha256sum Rocky-9.x-Minimal-x86_64-dvd.iso
  # Vérifier contre fichier officiel
  ```

- [ ] Kali Linux (optionnel, pour attaques)

### Étape 4 : Outils Locaux ✅

- [ ] Bash/Terminal fonctionnel
  ```bash
  bash --version  # Affiche version Bash
  ```

- [ ] SSH client installé
  ```bash
  ssh -V  # Affiche version OpenSSH
  ```

- [ ] Git installé
  ```bash
  git --version  # Affiche version Git
  ```

- [ ] Éditeur de texte (VSCode, Vim, etc.)

### Étape 5 : Connaissances ✅

- [ ] Je maîtrise Bash/Terminal (Niveau 1)
- [ ] Je connais SSH (Niveau 1)
- [ ] Je comprends les bases réseau (Niveau 1)
- [ ] Je peux administrer Linux (Niveau 1)

### Étape 6 : Espace de Travail ✅

- [ ] Dossier GitHub créé : `/home/user/mini-soc-rocky/`
  ```bash
  git init /home/user/mini-soc-rocky/
  ```

- [ ] Structure README créée

- [ ] Snapshots VirtualBox planifiés

---

## 🚨 Pièges Courants & Solutions

### Piège 1 : "Je n'ai que 8 GB RAM"

**❌ Mauvais** : Allouer 4 GB à chaque VM
```
VM 1 : 4 GB → Nginx + logs lents
VM 2 : 4 GB → Elasticsearch crash régulièrement
Résultat : FREEZE constant
```

**✅ Bon** : Réduire ou utiliser swap
```
VM 1 : 2 GB (web basique)
VM 2 : 4 GB (SIEM critique)
VM 3 : 2 GB (monitoring)
OS Host : 2 GB minimum libre
Résultat : Lent mais opérationnel
```

### Piège 2 : "Hyperviseur trop vieux"

**❌ Mauvais** : Utiliser VirtualBox 5.2 (2017)
```
VirtualBox -v → 5.2.x
Résultat : Bugs, performance médiocre
```

**✅ Bon** : Mettre à jour vers 7.x
```bash
# Vérifier version
vboxmanage --version

# Mettre à jour (macOS)
brew upgrade virtualbox

# Mettre à jour (Linux)
sudo dnf upgrade virtualbox
```

### Piège 3 : "Les VMs sont lentes"

**❌ Mauvais** : Tout mettre sur un disque HDD
```
HDD = 5400 RPM = très lent
VMs freeze régulièrement
```

**✅ Bon** : Utiliser un SSD (ou au moins Fusion Drive)
```
SSD = 150+ Mbps = 30x plus rapide
VMs fluides
```

### Piège 4 : "Je n'arrive pas à me connecter en SSH"

**❌ Mauvais** : Oublier de générer clés SSH
```bash
ssh -p 2222 user@192.168.1.10
# → Permission denied (publickey)
```

**✅ Bon** : Générer clés et configurer
```bash
# Sur ton ordinateur
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa_lab

# Sur la VM
ssh-copy-id -i ~/.ssh/id_rsa_lab.pub -p 2222 user@192.168.1.10

# Maintenant ça marche
ssh -p 2222 -i ~/.ssh/id_rsa_lab user@192.168.1.10
```

### Piège 5 : "Elasticsearch bouffe toute la RAM"

**❌ Mauvais** : Laisser Elasticsearch avec defaults
```
JVM_MEMORY = 50% du RAM = 3 GB sur une VM 6 GB
Résultat : Lenteur, swap utilisé
```

**✅ Bon** : Limiter la mémoire Elasticsearch
```bash
# Fichier : /etc/elasticsearch/elasticsearch-env.sh
ES_JAVA_OPTS="-Xms512m -Xmx512m"  # Max 512 MB

# Redémarrer
systemctl restart elasticsearch
```

---

## 🎯 Plan d'Action à Partir d'Ici

### Semaine 0 (Avant de commencer)

- [ ] Vérifier matériel (cette liste)
- [ ] Installer hyperviseur
- [ ] Télécharger ISO Rocky Linux
- [ ] Tester VirtualBox avec VM test

### Semaine 1

- [ ] Lire tous les fichiers de préparation
- [ ] Créer les 3 VM (mais ne pas les configurer)
- [ ] Vérifier réseau entre VMs

### Semaine 2-3 (Rôle 1 commence)

- [ ] VM 1 : Installation Rocky Linux
- [ ] VM 1 : Hardening (SSH, Firewall, SELinux)

### Semaine 3-4 (Rôle 2 commence)

- [ ] VM 2 : Installation Wazuh
- [ ] VM 1 : Configuration logs (rsyslog, Wazuh agent)

### Semaine 4-5 (Rôle 3 commence)

- [ ] VM 3 : Installation Zabbix/Prometheus
- [ ] Tous : Tester communication inter-VMs

### Semaine 5-6

- [ ] Tests d'attaques
- [ ] Rédaction documentation
- [ ] Rapports finaux

---

## 📚 Ressources d'Apprentissage

### Documentation Officielle

| Outil | URL |
|---|---|
| **Rocky Linux** | https://docs.rockylinux.org/ |
| **Wazuh** | https://documentation.wazuh.com/ |
| **Elasticsearch** | https://www.elastic.co/guide/en/elasticsearch/reference/ |
| **Prometheus** | https://prometheus.io/docs/ |
| **Zabbix** | https://www.zabbix.com/documentation/ |

### Tutoriels Pratiques

- YouTube : "Linux Server Administration"
- Linux Academy : "Rocky Linux Administration"
- TryHackMe.com : Cybersecurity labs (gratuit)

### Communautés

- r/linuxadministration (Reddit)
- Stack Overflow (questions techniques)
- Wazuh Community (forums Wazuh)

---

## ✋ Besoin d'Aide ?

Si tu as un doute avant de commencer :

1. **Relire** [`02_architecture_schema.md`](02_architecture_schema.md)
2. **Vérifier** cette liste prérequis
3. **Demander** à un formateur ou pair

---

## 📚 Prochaines Étapes

1. ✅ Tu as lu cette page et tu as le matériel
2. 👉 **Lire** [`05_timeline.md`](05_timeline.md) (planification 6 semaines)
3. 🚀 Commencer l'installation !

---

**Version** : 1.0  
**Dernière mise à jour** : Février 2026  
**À jour pour** : VirtualBox 7.0+, Rocky Linux 9.3+, Wazuh 4.7+
