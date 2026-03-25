# 06 - Configuration du Firewall

**Durée estimée :** 1h  
**Rôle concerné :** Administrateur système & hardening

---

## 🎯 Objectif de cette étape

Mettre en place un pare-feu avec firewalld pour contrôler précisément ce qui entre et sort du serveur. Le principe : **tout est fermé par défaut, on ouvre uniquement ce qui est nécessaire**.

**Pourquoi ?**
- Réduire la surface d'attaque
- Bloquer les scans de ports
- Empêcher les connexions non autorisées
- Définir des zones de confiance réseau

---

## 📋 Ce que vous allez faire

1. Installer et activer firewalld
2. Comprendre le concept de zones
3. Configurer la zone "public" (Internet)
4. Ouvrir les ports nécessaires (SSH custom, HTTP, HTTPS)
5. Rendre les règles persistantes
6. Tester avec nmap

---

## Étape 1 : Installation de firewalld

Sur Rocky Linux, firewalld est normalement installé par défaut.

```bash
# Vérifier si firewalld est installé
rpm -qa | grep firewalld
```

**Si pas installé :**
```bash
sudo dnf install -y firewalld
```

**Activer et démarrer le service :**

```bash
# Activer au démarrage
sudo systemctl enable firewalld

# Démarrer maintenant
sudo systemctl start firewalld

# Vérifier le statut
sudo systemctl status firewalld
```

**Output attendu :**
```
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled)
   Active: active (running) since Wed 2024-02-06 10:30:00 CET
```

---

## 📖 Comprendre les zones firewalld

### Concept des zones

Firewalld utilise des **zones** qui définissent le niveau de confiance d'un réseau.

| Zone | Niveau de confiance | Usage |
|------|---------------------|-------|
| **drop** | Aucun | Tout est rejeté silencieusement |
| **block** | Aucun | Tout est rejeté avec une réponse ICMP |
| **public** | Faible | Internet, connexions externes (défaut) |
| **external** | Faible | Réseaux externes avec masquerading (NAT) |
| **dmz** | Moyen | Zone démilitarisée, serveurs exposés |
| **work** | Moyen | Réseau de travail |
| **home** | Élevé | Réseau domestique |
| **internal** | Élevé | Réseau interne de confiance |
| **trusted** | Total | Tout le trafic est autorisé |

**Pour ce projet, on utilisera principalement la zone `public`.**

---

## Étape 2 : État actuel du firewall

```bash
# Voir la configuration actuelle
sudo firewall-cmd --list-all

# Voir la zone par défaut
sudo firewall-cmd --get-default-zone

# Voir toutes les zones actives
sudo firewall-cmd --get-active-zones
```

**Output typique :**
```
public (active)
  target: default
  interfaces: eth0
  services: dhcpv6-client ssh
  ports: 
  protocols: 
```

---

## Étape 3 : Configuration de la zone public

### Définir public comme zone par défaut

```bash
sudo firewall-cmd --set-default-zone=public
```

### Retirer le service SSH par défaut (port 22)

On l'a changé pour 2222, donc on retire le service SSH prédéfini.

```bash
sudo firewall-cmd --permanent --zone=public --remove-service=ssh
```

---

## Étape 4 : Ouvrir les ports nécessaires

### Port SSH custom (2222)

```bash
# Ouvrir le port 2222 en TCP
sudo firewall-cmd --permanent --zone=public --add-port=2222/tcp
```

### Port HTTP (80)

```bash
# Pour le serveur web
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
```

### Port HTTPS (443)

```bash
# Pour le serveur web sécurisé
sudo firewall-cmd --permanent --zone=public --add-port=443/tcp
```

**Alternative avec des services prédéfinis :**

```bash
# Au lieu d'ouvrir manuellement 80 et 443, vous pouvez utiliser :
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
```

---

## Étape 5 : Ports pour Wazuh et monitoring (ajout futur)

**Pour le SOC (SIEM Wazuh) :**

```bash
# Port agent Wazuh (si besoin)
sudo firewall-cmd --permanent --zone=public --add-port=1514/tcp
sudo firewall-cmd --permanent --zone=public --add-port=1515/tcp

# Interface Web Wazuh
sudo firewall-cmd --permanent --zone=public --add-port=55000/tcp
```

**Pour Zabbix/Prometheus :**

```bash
# Zabbix agent
sudo firewall-cmd --permanent --zone=public --add-port=10050/tcp

# Prometheus
sudo firewall-cmd --permanent --zone=public --add-port=9090/tcp

# Grafana
sudo firewall-cmd --permanent --zone=public --add-port=3000/tcp
```

**Note :** Ces ports sont à ajouter plus tard selon vos besoins. Pour l'instant, focalisez-vous sur SSH, HTTP, HTTPS.

---

## Étape 6 : Recharger la configuration

**Important :** Les modifications avec `--permanent` ne sont actives qu'après rechargement.

```bash
# Recharger firewalld pour appliquer les règles permanentes
sudo firewall-cmd --reload
```

**Vérifier la nouvelle configuration :**

```bash
sudo firewall-cmd --list-all
```

**Output attendu :**
```
public (active)
  target: default
  interfaces: eth0
  services: dhcpv6-client
  ports: 2222/tcp 80/tcp 443/tcp
  protocols: 
  forward: yes
  masquerade: no
```

---

## Étape 7 : Règles avancées (optionnel)

### Bloquer le ping (ICMP)

```bash
# Bloquer les requêtes ping
sudo firewall-cmd --permanent --zone=public --add-icmp-block=echo-request
sudo firewall-cmd --reload
```

**Pourquoi ?** Empêcher la découverte du serveur via ping.

### Limiter les tentatives de connexion SSH

Firewalld peut limiter le nombre de connexions.

```bash
# Ajouter une règle rich rule pour limiter SSH
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" port port="2222" protocol="tcp" limit value="3/m" accept'
sudo firewall-cmd --reload
```

**Explication :** Limite à 3 nouvelles connexions SSH par minute.

### Autoriser uniquement certaines IP (whitelist)

```bash
# Exemple : autoriser uniquement votre IP pour SSH
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="VOTRE_IP/32" port port="2222" protocol="tcp" accept'

# Et bloquer tout le reste pour SSH
sudo firewall-cmd --permanent --zone=public --remove-port=2222/tcp
sudo firewall-cmd --reload
```

---

## Étape 8 : Zones multiples (configuration avancée)

### Créer une zone interne pour le SOC

```bash
# Activer la zone internal
sudo firewall-cmd --permanent --zone=internal --add-interface=eth1

# Autoriser tout depuis le réseau interne
sudo firewall-cmd --permanent --zone=internal --add-service=ssh
sudo firewall-cmd --permanent --zone=internal --add-service=http
sudo firewall-cmd --permanent --zone=internal --add-service=https

sudo firewall-cmd --reload
```

**Cas d'usage :** Si vous avez plusieurs interfaces réseau (eth0 pour Internet, eth1 pour réseau privé).

---

## Étape 9 : Tests de validation

### Test 1 : Scanner les ports avec nmap (depuis l'extérieur)

**Depuis votre machine locale :**

```bash
# Scanner les ports TCP
nmap -sT -p 1-10000 IP_DU_SERVEUR
```

**Output attendu :**
```
PORT     STATE SERVICE
2222/tcp open  unknown
80/tcp   open  http
443/tcp  open  https
```

Seuls les ports que vous avez ouverts doivent apparaître.

### Test 2 : Vérifier que le port 22 est fermé

```bash
nmap -p 22 IP_DU_SERVEUR
```

**Output attendu :**
```
PORT   STATE  SERVICE
22/tcp closed ssh
```

Parfait ! Le port 22 n'est plus accessible.

### Test 3 : Tester la connexion SSH

```bash
ssh -p 2222 admin@IP_DU_SERVEUR
```

Doit fonctionner sans problème.

---

## Étape 10 : Logs du firewall

### Activer les logs pour les connexions bloquées

```bash
# Activer le logging
sudo firewall-cmd --set-log-denied=all
sudo firewall-cmd --reload
```

### Consulter les logs

```bash
# Voir les connexions bloquées
sudo journalctl -u firewalld -f

# Ou dans les logs système
sudo tail -f /var/log/messages | grep -i firewall
```

**Exemple d'output :**
```
Feb 06 10:45:12 rocky kernel: FINAL_REJECT: IN=eth0 OUT= SRC=1.2.3.4 DST=192.168.1.10 PROTO=TCP DPT=22
```

Ici, une tentative de connexion sur le port 22 a été bloquée depuis l'IP 1.2.3.4.

---

## ✅ Checklist de validation

- [ ] firewalld installé et actif
- [ ] Zone public définie comme défaut
- [ ] Port 2222 (SSH custom) ouvert
- [ ] Port 80 (HTTP) ouvert
- [ ] Port 443 (HTTPS) ouvert
- [ ] Service SSH (port 22) retiré
- [ ] Configuration rechargée et persistante
- [ ] Test nmap montre uniquement les ports autorisés
- [ ] Connexion SSH sur 2222 fonctionne
- [ ] Port 22 est fermé (closed)
- [ ] Logs activés pour les connexions refusées

---

## ❌ Erreurs courantes

### Problème : "FirewallD is not running"

**Cause :** Le service n'est pas démarré

**Solution :**
```bash
sudo systemctl start firewalld
sudo systemctl enable firewalld
```

### Problème : Règles ajoutées mais pas appliquées

**Cause :** Oubli de recharger ou de mettre `--permanent`

**Solution :**
```bash
# Si vous avez oublié --permanent :
sudo firewall-cmd --runtime-to-permanent

# Puis recharger :
sudo firewall-cmd --reload
```

### Problème : "Permission denied" après configuration

**Cause :** Mauvaise zone ou règle trop restrictive

**Diagnostic :**
```bash
# Voir les connexions bloquées
sudo journalctl -u firewalld | grep -i reject

# Voir toutes les règles actives
sudo firewall-cmd --list-all-zones
```

### Problème : nmap montre encore le port 22 ouvert

**Cause :** SSH n'a pas été retiré de la zone

**Solution :**
```bash
sudo firewall-cmd --permanent --zone=public --remove-service=ssh
sudo firewall-cmd --reload
```

---

## 📝 Notes importantes

1. **Ordre des règles** : Les règles sont évaluées de la plus spécifique à la plus générale
2. **--permanent** : Sans ce flag, les règles disparaissent au reboot
3. **Zones multiples** : Une interface réseau ne peut être que dans UNE zone à la fois
4. **Rich rules** : Permettent des règles complexes (limitation de débit, source IP, etc.)

---

## 🔗 Prochaine étape

→ **07_selinux.md** (si applicable) : Configuration de SELinux pour une sécurité renforcée  
→ **08_fail2ban.md** : Protection contre les attaques brute force

---

## 📚 Commandes de référence

```bash
# Gestion du service
sudo systemctl status firewalld
sudo systemctl start firewalld
sudo systemctl stop firewalld
sudo systemctl restart firewalld

# Configuration des zones
sudo firewall-cmd --get-default-zone           # Voir la zone par défaut
sudo firewall-cmd --set-default-zone=ZONE      # Définir la zone par défaut
sudo firewall-cmd --get-active-zones           # Zones actives
sudo firewall-cmd --list-all                   # Tout afficher (zone courante)
sudo firewall-cmd --list-all-zones             # Tout afficher (toutes zones)

# Gestion des ports
sudo firewall-cmd --permanent --add-port=PORT/tcp
sudo firewall-cmd --permanent --remove-port=PORT/tcp
sudo firewall-cmd --list-ports

# Gestion des services
sudo firewall-cmd --permanent --add-service=SERVICE
sudo firewall-cmd --permanent --remove-service=SERVICE
sudo firewall-cmd --list-services

# Appliquer les modifications
sudo firewall-cmd --reload                     # Recharger
sudo firewall-cmd --runtime-to-permanent       # Sauvegarder la config runtime

# Rich rules (règles avancées)
sudo firewall-cmd --permanent --add-rich-rule='RULE'
sudo firewall-cmd --list-rich-rules

# Logs
sudo firewall-cmd --set-log-denied=all         # Activer les logs
sudo journalctl -u firewalld -f                # Suivre les logs

# Tests
sudo firewall-cmd --query-port=PORT/tcp        # Tester si un port est ouvert
sudo firewall-cmd --query-service=SERVICE      # Tester si un service est actif
```

---

## 🔍 Annexe : Exemples de rich rules

### Limiter le débit SSH

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="2222" protocol="tcp" limit value="5/m" accept'
```

### Bloquer une IP spécifique

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="1.2.3.4" reject'
```

### Autoriser une plage d'IP

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" accept'
```

### Logger les tentatives SSH

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="2222" protocol="tcp" log prefix="SSH_ATTEMPT" level="info" accept'
```

---

## 🎓 Concepts clés à retenir

- **Défaut deny** : Tout est fermé sauf ce qui est explicitement autorisé
- **Zones** : Segmentent le réseau selon le niveau de confiance
- **Persistance** : Toujours utiliser `--permanent` pour garder les règles après reboot
- **Tests** : Toujours vérifier avec nmap après modification
- **Logs** : Activer les logs pour détecter les tentatives d'intrusion
