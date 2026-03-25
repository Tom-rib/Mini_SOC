# 03 - Configuration réseau en IP fixe

## 📋 Objectif

Configurer une **adresse IP fixe** sur Rocky Linux pour garantir que les machines du SOC soient toujours accessibles à la même adresse. En production, les serveurs doivent avoir des IP fixes pour permettre la surveillance, les règles firewall et l'accès SSH stable.

---

## 🎓 Concepts clés

**DHCP vs IP fixe**

Par défaut, lors de l'installation, Rocky Linux obtient une adresse IP via DHCP (Dynamic Host Configuration Protocol). Cela signifie que l'adresse peut changer à chaque redémarrage, ce qui pose problème pour :

- Les règles de firewall (basées sur IP source/destination)
- La configuration du SIEM (collecte de logs depuis des IP précises)
- L'accès SSH régulier (tu ne veux pas chercher l'IP à chaque fois)

**En entreprise**, tous les serveurs ont des IP fixes. Tu vas apprendre à configurer cela sur Rocky Linux avec **NetworkManager** (l'outil moderne de gestion réseau sous RHEL/Rocky).

---

## 🛠️ Prérequis

- Rocky Linux installé (voir [01_installation_base.md](./01_installation_base.md))
- Accès root ou sudo
- Connexion SSH ou accès console

---

## 📖 Étape 1 : Identifier l'interface réseau

Commence par lister les interfaces réseau disponibles :

```bash
ip addr show
```

**Résultat attendu :**

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP
    link/ether 08:00:27:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.50/24 brd 192.168.1.255 scope global dynamic enp0s3
```

> 💡 Note le nom de ton interface : **enp0s3** (ou eth0, ens33, etc. selon ton hyperviseur)

---

## 📖 Étape 2 : Définir le plan d'adressage

Avant de configurer, détermine ton architecture réseau :

**Exemple de plan d'adressage pour le Mini SOC :**

| Machine           | Hostname            | IP fixe         | Rôle                  |
|-------------------|---------------------|-----------------|-----------------------|
| VM 1              | soc-web-rocky       | 192.168.1.10    | Serveur Web exposé    |
| VM 2              | soc-siem-rocky      | 192.168.1.20    | SIEM / Wazuh Manager  |
| VM 3              | soc-monitor-rocky   | 192.168.1.30    | Monitoring / Grafana  |
| (Optionnel) VM 4  | kali-attacker       | 192.168.1.100   | Machine d'attaque     |

**Informations réseau nécessaires :**

- **Adresse IP** : 192.168.1.10 (exemple pour VM1)
- **Masque de sous-réseau** : 255.255.255.0 (soit /24)
- **Passerelle** : 192.168.1.1 (routeur/box Internet)
- **DNS** : 8.8.8.8 et 8.8.4.4 (Google DNS) ou 1.1.1.1 (Cloudflare)

> ⚠️ **Adapte ces valeurs** en fonction de ton réseau local. Vérifie avec `ip route` et `cat /etc/resolv.conf`.

---

## 📖 Étape 3 : Vérifier l'adresse IP actuelle (DHCP)

```bash
ip addr show enp0s3
```

**Résultat attendu :**

```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 192.168.1.50/24 brd 192.168.1.255 scope global dynamic enp0s3
```

L'adresse `192.168.1.50` est attribuée par DHCP (mot-clé **dynamic**).

---

## 📖 Étape 4 : Configurer une IP fixe avec `nmcli` (méthode moderne)

### Méthode 1 : Avec NetworkManager CLI (nmcli)

Rocky Linux utilise **NetworkManager** par défaut. Voici comment configurer une IP fixe en ligne de commande :

#### Lister les connexions existantes

```bash
nmcli connection show
```

**Résultat attendu :**

```
NAME                UUID                                  TYPE      DEVICE
enp0s3              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  ethernet  enp0s3
```

---

#### Configurer l'IP fixe

Remplace `enp0s3` par le nom de ta connexion et adapte les valeurs IP :

```bash
sudo nmcli connection modify enp0s3 \
  ipv4.addresses 192.168.1.10/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8 8.8.4.4" \
  ipv4.method manual
```

**Explication des paramètres :**

- `ipv4.addresses` : Adresse IP fixe + masque (/24)
- `ipv4.gateway` : Passerelle par défaut (routeur)
- `ipv4.dns` : Serveurs DNS (séparés par des espaces, entre guillemets)
- `ipv4.method manual` : Désactive DHCP et active IP fixe

---

#### Appliquer la configuration

```bash
sudo nmcli connection down enp0s3
sudo nmcli connection up enp0s3
```

Ou redémarre NetworkManager :

```bash
sudo systemctl restart NetworkManager
```

---

### Méthode 2 : Édition manuelle du fichier de configuration (alternative)

Si tu préfères éditer directement les fichiers de configuration (méthode classique RHEL/CentOS/Rocky) :

#### Localiser le fichier de configuration

```bash
ls /etc/sysconfig/network-scripts/
```

**Résultat attendu :**

```
ifcfg-enp0s3
```

---

#### Éditer le fichier de configuration

```bash
sudo nano /etc/sysconfig/network-scripts/ifcfg-enp0s3
```

Remplace le contenu par :

```bash
TYPE=Ethernet
BOOTPROTO=none          # Désactive DHCP
NAME=enp0s3
DEVICE=enp0s3
ONBOOT=yes              # Active l'interface au démarrage
IPADDR=192.168.1.10     # Adresse IP fixe
PREFIX=24               # Masque /24 = 255.255.255.0
GATEWAY=192.168.1.1     # Passerelle
DNS1=8.8.8.8            # DNS primaire
DNS2=8.8.4.4            # DNS secondaire
```

> 💡 **Important** : `BOOTPROTO=none` désactive DHCP. `ONBOOT=yes` active automatiquement l'interface au démarrage.

---

#### Redémarrer le réseau

```bash
sudo systemctl restart NetworkManager
```

Ou :

```bash
sudo nmcli connection down enp0s3
sudo nmcli connection up enp0s3
```

---

## 📖 Étape 5 : Configurer le hostname

Le hostname est le nom de ta machine sur le réseau. Change-le pour refléter son rôle :

### Afficher le hostname actuel

```bash
hostnamectl
```

---

### Changer le hostname

```bash
sudo hostnamectl set-hostname soc-web-rocky
```

Remplace `soc-web-rocky` par :

- `soc-web-rocky` pour le serveur Web
- `soc-siem-rocky` pour le SIEM
- `soc-monitor-rocky` pour le monitoring

---

### Vérifier le changement

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

### Éditer `/etc/hosts` (optionnel mais recommandé)

Ajoute ton hostname dans le fichier `/etc/hosts` pour éviter des erreurs de résolution :

```bash
sudo nano /etc/hosts
```

Ajoute cette ligne :

```
192.168.1.10    soc-web-rocky
```

---

## 🧪 Commandes de vérification

### Vérifier l'adresse IP

```bash
ip addr show enp0s3
```

**Résultat attendu :**

```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 192.168.1.10/24 brd 192.168.1.255 scope global enp0s3
```

L'adresse doit être `192.168.1.10` (ou celle que tu as configurée). Le mot-clé **dynamic** ne doit plus apparaître.

---

### Vérifier la passerelle

```bash
ip route show
```

**Résultat attendu :**

```
default via 192.168.1.1 dev enp0s3 proto static metric 100
192.168.1.0/24 dev enp0s3 proto kernel scope link src 192.168.1.10
```

La passerelle par défaut doit être `192.168.1.1`.

---

### Vérifier les DNS

```bash
cat /etc/resolv.conf
```

**Résultat attendu :**

```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

---

### Tester la connectivité Internet

```bash
ping -c 4 google.com
```

**Résultat attendu :**

```
PING google.com (142.250.x.x) 56(84) bytes of data.
64 bytes from xxx.xxx.xxx.xxx: icmp_seq=1 ttl=118 time=15.2 ms
...
4 packets transmitted, 4 received, 0% packet loss
```

---

### Tester la résolution DNS

```bash
nslookup google.com
```

**Résultat attendu :**

```
Server:     8.8.8.8
Address:    8.8.8.8#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.x.x
```

---

### Tester SSH depuis une autre machine (si SSH actif)

Depuis ta machine hôte ou une autre VM :

```bash
ssh admin-soc@192.168.1.10
```

Tu dois pouvoir te connecter sans erreur.

---

## 📊 Tableau récapitulatif des commandes réseau Rocky Linux

| Action                       | Commande                                          |
|------------------------------|---------------------------------------------------|
| Voir les interfaces          | `ip addr show` ou `nmcli device status`           |
| Voir les connexions          | `nmcli connection show`                           |
| Configurer IP fixe           | `nmcli connection modify <name> ipv4.addresses …` |
| Redémarrer une interface     | `nmcli connection down/up <name>`                 |
| Voir la table de routage     | `ip route show`                                   |
| Voir les DNS                 | `cat /etc/resolv.conf`                            |
| Tester la connectivité       | `ping <IP ou domaine>`                            |
| Voir le hostname             | `hostnamectl` ou `hostname`                       |
| Changer le hostname          | `hostnamectl set-hostname <nom>`                  |

---

## ⏱️ Durée estimée

**Temps total : 30 minutes**

- Lecture et compréhension : 10 min
- Configuration IP fixe : 10 min
- Configuration hostname : 5 min
- Tests et vérifications : 5 min

---

## 🔗 Prochaine étape

Maintenant que ton réseau est configuré avec une IP fixe, passe à la sécurisation du système :

➡️ **[04_securisation_ssh.md](./04_securisation_ssh.md)** - Sécurisation de SSH (à créer)

Si tu veux approfondir la configuration du firewall :

➡️ **[05_firewall_firewalld.md](./05_firewall_firewalld.md)** - Configuration du firewall avec firewalld (à créer)

---

## 📚 Ressources complémentaires

- [Guide NetworkManager Rocky Linux](https://docs.rockylinux.org/guides/network/basic_network_configuration/)
- [nmcli documentation (EN)](https://man7.org/linux/man-pages/man1/nmcli.1.html)
- [Rocky Linux - Network Scripts](https://docs.rockylinux.org/guides/network/network_interfaces/)

---

## 🛠️ Dépannage courant

### Problème : Pas de connexion Internet après configuration

**Solution :**

1. Vérifie la passerelle :

```bash
ip route show
```

2. Vérifie les DNS :

```bash
cat /etc/resolv.conf
```

3. Teste la passerelle :

```bash
ping 192.168.1.1
```

4. Redémarre NetworkManager :

```bash
sudo systemctl restart NetworkManager
```

---

### Problème : SSH ne fonctionne plus après changement d'IP

**Solution :**

Si tu te connectais en SSH avant, mets à jour ton client SSH avec la nouvelle IP fixe :

```bash
ssh admin-soc@192.168.1.10
```

Si tu as des erreurs de clé SSH (fingerprint mismatch), supprime l'ancienne entrée :

```bash
ssh-keygen -R 192.168.1.50  # Ancienne IP DHCP
```

---

**✅ Checkpoint :** Ton système dispose maintenant d'une configuration réseau stable avec IP fixe et hostname personnalisé. Tu peux passer à la sécurisation du système.
