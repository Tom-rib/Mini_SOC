# 🔥 Mémo Firewalld - Gestion du Firewall Rocky Linux

> **Objectif** : Référence rapide pour configurer firewalld dans le projet SOC.  
> **Contexte** : Utilisation de zones, ouverture de ports sélectifs, règles personnalisées.  
> **Important** : Utiliser `--permanent` pour rendre les changements persistants au reboot.

---

## 1️⃣ Démarrage & Statut

### Vérifier l'état de Firewalld

```bash
systemctl status firewalld
# Devrait afficher : active (running)

systemctl is-active firewalld
# Output : active

firewall-cmd --state
# Output : running
```

### Démarrer/arrêter Firewalld

```bash
# Démarrer
systemctl start firewalld

# Arrêter (⚠️ attention, bloque tout)
systemctl stop firewalld

# Redémarrer
systemctl restart firewalld

# Recharger config
firewall-cmd --reload

# Activer au démarrage
systemctl enable firewalld
```

---

## 2️⃣ Zones Firewalld

### Concept : Zones = Profils de Sécurité

| Zone | Écoute | Usage | Exemple |
|------|--------|-------|---------|
| `public` | Fermée par défaut | WAN, inconnu | Internet |
| `internal` | Plus permissive | LAN de confiance | Réseau interne |
| `trusted` | Tout accepté | Partenaires, VPN | Administrateurs |
| `dmz` | Restreint | Serveurs exposés | Web serveur |
| `drop` | Tout rejeté | Très restrictif | Hostiles |

### Lister les zones

```bash
firewall-cmd --get-zones
# public drop internal trusted external dmz

firewall-cmd --list-all-zones
# Affiche toutes les zones avec leur config
```

### Zone par défaut

```bash
firewall-cmd --get-default-zone
# Affiche zone actuelle (ex: public)

firewall-cmd --set-default-zone=public
# Change zone par défaut
```

### Interfaces réseau → Zone

```bash
# Voir zones actives
firewall-cmd --get-active-zones

# Assigner interface à zone
firewall-cmd --permanent --change-interface=eth0 --zone=internal
firewall-cmd --reload

# Vérifier
firewall-cmd --info-zone=internal
```

---

## 3️⃣ Ouvrir des Ports

### Ajouter port (TCP/UDP)

```bash
# TEMPORAIRE (disparaît au reload)
firewall-cmd --add-port=2222/tcp
firewall-cmd --add-port=80/tcp
firewall-cmd --add-port=443/tcp
firewall-cmd --add-port=9200/udp

# PERMANENT (persiste)
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp

# Appliquer les changements
firewall-cmd --reload
```

### Ajouter plusieurs ports

```bash
# Plages de ports
firewall-cmd --permanent --add-port=5000-5100/tcp
firewall-cmd --reload

# Liste de ports individuels
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload
```

### Spécifier la zone

```bash
# Par défaut = zone par défaut (public)
firewall-cmd --permanent --add-port=2222/tcp

# Spécifier zone
firewall-cmd --permanent --add-port=2222/tcp --zone=internal
firewall-cmd --reload
```

### Lister ports ouverts

```bash
firewall-cmd --list-ports
# 2222/tcp 80/tcp 443/tcp

firewall-cmd --permanent --list-ports
# Voir config permanente
```

### Supprimer un port

```bash
# Temporaire
firewall-cmd --remove-port=2222/tcp

# Permanent
firewall-cmd --permanent --remove-port=2222/tcp
firewall-cmd --reload
```

---

## 4️⃣ Services Prédéfinis

### Ajouter service

```bash
# Services disponibles
firewall-cmd --get-services | tr ' ' '\n' | head -20

# Ajouter service (SSH, HTTP, HTTPS, etc.)
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Voir ports d'un service
firewall-cmd --info-service=http
# Affiche port 80/tcp
```

### Lister services ouverts

```bash
firewall-cmd --list-services
# ssh http https

firewall-cmd --permanent --list-services
# Config permanente
```

### Supprimer service

```bash
firewall-cmd --permanent --remove-service=http
firewall-cmd --reload
```

### Services courants

| Service | Ports | Usage |
|---------|-------|-------|
| `ssh` | 22/tcp | Accès distant |
| `http` | 80/tcp | Web HTTP |
| `https` | 443/tcp | Web HTTPS |
| `mysql` | 3306/tcp | Base données |
| `dns` | 53/tcp, 53/udp | Serveur DNS |
| `ntp` | 123/udp | Synchronisation temps |
| `ftp` | 20,21/tcp | Transfer fichiers |
| `smtp` | 25/tcp | Envoi email |
| `pop3` | 110/tcp | Récupération email |

---

## 5️⃣ Règles Personnalisées (Rich Rules)

### Syntaxe Rich Rule

```bash
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="IP" port protocol="tcp" port="PORT" accept'
```

### Exemples de règles

#### Autoriser une IP spécifique

```bash
# Accepter IP 192.168.1.100 sur SSH
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="2222" accept'

firewall-cmd --reload
```

#### Refuser une IP

```bash
# Bloquer IP 10.0.0.50
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.50" reject'

firewall-cmd --reload
```

#### Port accessibilité par source

```bash
# Autoriser 192.168.1.0/24 sur port 3306
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="3306" accept'

firewall-cmd --reload
```

#### Forward vers IP interne

```bash
# Forward port 80 local → 192.168.1.50:8080
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port protocol="tcp" port="80" forward-port to-port="8080" to-addr="192.168.1.50"'

firewall-cmd --reload
```

#### Rate limiting (protection brute force)

```bash
# Limiter connexions SSH (max 3 par minute)
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port protocol="tcp" port="22" limit value="3/m" accept'

firewall-cmd --reload
```

### Lister les règles personnalisées

```bash
firewall-cmd --list-rich-rules
# Affiche toutes les rich rules temporaires

firewall-cmd --permanent --list-rich-rules
# Config permanente
```

### Supprimer une règle

```bash
# Copier la règle complète et utiliser --remove-rich-rule
firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="2222" accept'

firewall-cmd --reload
```

---

## 6️⃣ Configuration Masquerading & NAT

### NAT (Network Address Translation)

```bash
# Activer NAT sur interface
firewall-cmd --permanent --add-masquerade --zone=external

# Vérifier
firewall-cmd --permanent --list-all --zone=external

firewall-cmd --reload
```

### Forward entre zones

```bash
# Permettre trafic zone interne → zone externe
firewall-cmd --permanent --add-forward --zone=internal --to-zone=external

firewall-cmd --reload
```

---

## 7️⃣ Affichage & Diagnostic

### Afficher la config complète d'une zone

```bash
firewall-cmd --info-zone=public
# Affiche tous les détails (ports, services, règles)

firewall-cmd --permanent --info-zone=public
# Config permanente
```

### Lister tout ce qui est ouvert

```bash
# Zone par défaut
firewall-cmd --list-all

# Zone spécifique
firewall-cmd --list-all --zone=internal

# Version permanente
firewall-cmd --permanent --list-all
```

### Voir les changements non appliqués

```bash
# Les changements temporaires
firewall-cmd --list-ports
firewall-cmd --list-services

# Les changements permanents
firewall-cmd --permanent --list-ports
firewall-cmd --permanent --list-services
```

---

## 8️⃣ Configuration du Projet Mini SOC

### Configuration recommandée

#### VM 1 (Serveur Web)

```bash
# Zone : DMZ (demilitarized)
firewall-cmd --set-default-zone=dmz

# Services/ports
firewall-cmd --permanent --add-port=2222/tcp          # SSH custom
firewall-cmd --permanent --add-service=http           # Port 80
firewall-cmd --permanent --add-service=https          # Port 443
firewall-cmd --permanent --add-port=9200/tcp          # Elasticsearch (si applicable)

# Refuser connexions par défaut (impliquement deny)
firewall-cmd --permanent --set-target=DENY

firewall-cmd --reload
```

#### VM 2 (SOC / SIEM)

```bash
# Zone : internal (réseau interne)
firewall-cmd --set-default-zone=internal

# Services/ports
firewall-cmd --permanent --add-port=2222/tcp          # SSH
firewall-cmd --permanent --add-port=514/tcp           # Syslog (logs)
firewall-cmd --permanent --add-port=514/udp           # Syslog UDP
firewall-cmd --permanent --add-port=5000/tcp          # Beats input
firewall-cmd --permanent --add-port=9200/tcp          # Elasticsearch
firewall-cmd --permanent --add-port=5601/tcp          # Kibana
firewall-cmd --permanent --add-port=1514/tcp          # Wazuh API
firewall-cmd --permanent --add-port=1515/tcp          # Wazuh agents

firewall-cmd --reload
```

#### VM 3 (Monitoring)

```bash
# Zone : internal
firewall-cmd --set-default-zone=internal

# Services/ports
firewall-cmd --permanent --add-port=2222/tcp          # SSH
firewall-cmd --permanent --add-port=9090/tcp          # Prometheus
firewall-cmd --permanent --add-port=3000/tcp          # Grafana
firewall-cmd --permanent --add-port=10050/tcp         # Zabbix agent
firewall-cmd --permanent --add-port=10051/tcp         # Zabbix server

firewall-cmd --reload
```

### Bloquer IPs attaquantes

```bash
# Pendant les tests, bloquer une IP attaquante
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.99" drop'

# Vérifier
firewall-cmd --list-rich-rules

firewall-cmd --reload
```

---

## 9️⃣ Troubleshooting Firewalld

### Le firewall bloque SSH - Comment restaurer accès ?

```bash
# DANGER : Arrêter temporairement (raccourci d'urgence)
systemctl stop firewalld
# Retrouvez accès rapidement !

# Fixer la config
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --permanent --add-service=ssh

# Relancer
systemctl restart firewalld

# Vérifier
firewall-cmd --list-ports
```

### Le port que j'ai ajouté ne marche pas

```bash
# 1. Vérifier que firewalld est actif
systemctl is-active firewalld

# 2. Vérifier que le port est dans la config
firewall-cmd --list-ports
firewall-cmd --permanent --list-ports

# 3. Vérifier qu'il n'y a pas de blocage autre (SELinux, iptables)
getenforce                           # Voir mode SELinux
sudo iptables -L -n | grep 2222      # Voir iptables

# 4. Tester accès
ss -tulpn | grep LISTEN              # Service écoute ?
curl -v localhost:port               # Port répond ?
```

### Règle en permanent mais pas appliquée

```bash
# Vous avez oublié le reload !
firewall-cmd --permanent --add-port=1234/tcp
# Le port n'est PAS ouvert maintenant

firewall-cmd --reload
# Maintenant c'est appliqué

# Toujours tester après reload
firewall-cmd --list-ports
```

### Rollback rapide

```bash
# Réinitialiser firewalld
firewall-cmd --complete-reload

# Ou redémarrer le service
systemctl restart firewalld

# Ou éditer directement les fichiers
nano /etc/firewalld/zones/public.xml
systemctl restart firewalld
```

---

## 1️⃣0️⃣ Commandes à Retenir Absolument

| Action | Commande |
|--------|----------|
| Voir config zone | `firewall-cmd --list-all` |
| Ajouter port | `firewall-cmd --permanent --add-port=PORT/tcp` |
| Ajouter service | `firewall-cmd --permanent --add-service=http` |
| Supprimer port | `firewall-cmd --permanent --remove-port=PORT/tcp` |
| Ajouter règle | `firewall-cmd --permanent --add-rich-rule='...'` |
| Recharger config | `firewall-cmd --reload` |
| Redémarrer service | `systemctl restart firewalld` |
| Voir ports ouverts | `firewall-cmd --list-ports` |
| Déboguer | `firewall-cmd --list-all --zone=ZONE` |

---

## 1️⃣1️⃣ Points Clés pour le Projet

1. **Toujours ajouter `--permanent`** sinon les changements disparaissent
2. **Toujours faire `firewall-cmd --reload`** après changement permanent
3. **Ouvrir SSH en premier** ou vous pouvez vous bloquer vous-même
4. **Tester après chaque changement** : `firewall-cmd --list-all`
5. **Zones par VM** : DMZ pour web, internal pour SOC/monitoring
6. **Rich rules pour règles complexes** : blocs par source IP, rate limiting, forwarding

---

**Dernière mise à jour** : Documentation projet Mini SOC  
**Niveau** : 2e année admin systèmes & réseaux  
**Prudence** : Firewall peut vous bloquer - testez toujours l'accès SSH !
