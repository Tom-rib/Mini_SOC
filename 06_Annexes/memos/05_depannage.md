# 🔧 FAQ Dépannage - Troubleshooting Projet Mini SOC

> **Objectif** : Solutions rapides aux problèmes les plus courants du projet.  
> **Format** : Problème → Causes possibles → Solutions étape par étape  
> **À faire avant tout** : Vérifier que les 3 VM communiquent (ping, SSH)

---

## 🚨 Problèmes de Connexion SSH

### ❌ Problème : "Connection refused" ou "Connection timed out"

**Symptôme :**
```
ssh: connect to host 192.168.1.10 port 2222: Connection refused
# ou : Connection timed out
```

**Causes possibles :**
1. SSH ne tourne pas sur le serveur
2. Port SSH est fermé par firewall
3. Port SSH est mauvais
4. Serveur est arrêté

**✅ Solutions :**

```bash
# 1. Vérifier que SSH tourne sur le serveur
ssh soc "systemctl status sshd"

# 2. Vérifier firewall (port 2222 ouvert ?)
ssh soc "firewall-cmd --list-ports"
# Devrait afficher : 2222/tcp

# 3. Si port fermé, l'ouvrir
ssh soc "sudo firewall-cmd --permanent --add-port=2222/tcp"
ssh soc "sudo firewall-cmd --reload"

# 4. Vérifier que sshd écoute sur le port
ssh soc "ss -tulpn | grep sshd"
# Devrait afficher : 0.0.0.0:2222

# 5. Relancer SSH si modifié
ssh soc "sudo systemctl restart sshd"

# 6. Tester nouvelle connexion
ssh web   # Devrait marcher maintenant
```

---

### ❌ Problème : "Permission denied (publickey)"

**Symptôme :**
```
Permission denied (publickey).
# Ou : No more authentication methods to try.
```

**Causes possibles :**
1. Clé SSH ne correspond pas
2. Permissions sur `authorized_keys` mauvaises
3. Clé privée n'existe pas localement
4. SSH attend password à la place de clé

**✅ Solutions :**

```bash
# 1. Vérifier que clé privée existe localement
ls -la ~/.ssh/id_rsa
# Si n'existe pas : générer
ssh-keygen -t rsa -b 4096 -N ""

# 2. Vérifier permissions
ls -la ~/.ssh/
# .ssh doit être : drwx------ (700)
# id_rsa doit être : -rw------- (600)

# Fixer si nécessaire :
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa

# 3. Vérifier que clé publique est sur serveur
ssh soc "cat ~/.ssh/authorized_keys"

# 4. Si clé ne s'y trouve pas, la copier
ssh-copy-id -i ~/.ssh/id_rsa.pub admin@soc

# 5. Vérifier permissions authorized_keys sur serveur
ssh soc "ls -la ~/.ssh/authorized_keys"
# Doit être : -rw------- (600)

# Fixer si nécessaire :
ssh soc "chmod 600 ~/.ssh/authorized_keys"

# 6. Vérifier que config SSH n'exige pas password
ssh soc "grep -E 'PasswordAuthentication|PubkeyAuthentication' /etc/ssh/sshd_config"
# Devrait être : PasswordAuthentication no
#                PubkeyAuthentication yes

# 7. Relancer SSH
ssh soc "sudo systemctl restart sshd"

# 8. Tester
ssh soc "whoami"
```

---

### ❌ Problème : "ssh_exchange_identification: Connection closed"

**Symptôme :**
```
ssh_exchange_identification: Connection closed by remote host
```

**Causes :**
1. Limite de connexions SSH atteinte
2. Fail2ban a bloqué votre IP
3. SSH bloqué par SELinux

**✅ Solutions :**

```bash
# 1. Vérifier fail2ban
ssh soc "sudo fail2ban-client status sshd"

# 2. Si vous êtes bloqué, débloquer
ssh soc "sudo fail2ban-client set sshd unbanip YOUR_IP"

# 3. Vérifier SELinux
ssh soc "getenforce"
# Si "Enforcing", passer en permissive
ssh soc "sudo setenforce 0"

# 4. Relancer SSH
ssh soc "sudo systemctl restart sshd"

# 5. Tester
ssh soc "whoami"
```

---

## 🔥 Problèmes Firewall

### ❌ Problème : "Port ouvert mais pas accessible"

**Symptôme :**
```
Port 80 ouvert dans firewall mais site web ne répond pas
curl: (7) Failed to connect to localhost port 80: Connection refused
```

**Causes possibles :**
1. Service n'écoute pas sur le port
2. Firewall pas reloadé
3. Service est arrêté
4. Port est dans une autre zone

**✅ Solutions :**

```bash
# 1. Vérifier que service tourne
ssh web "systemctl status nginx"
# Devrait être : active (running)

# 2. Vérifier que service écoute sur le port
ssh web "ss -tulpn | grep nginx"
# Devrait afficher : 0.0.0.0:80

# 3. Vérifier firewall
ssh web "firewall-cmd --list-ports"
ssh web "firewall-cmd --list-services"

# 4. Ajouter port si absent
ssh web "sudo firewall-cmd --permanent --add-port=80/tcp"

# 5. Recharger firewall (c'est souvent ça !)
ssh web "sudo firewall-cmd --reload"

# 6. Vérifier à nouveau
ssh web "firewall-cmd --list-ports"

# 7. Tester accès
curl http://192.168.1.10
```

---

### ❌ Problème : "Tous les ports fermés accidentellement"

**Symptôme :**
```
Aucune connexion SSH/HTTP ne passe, vous êtes bloqué
```

**Causes :**
Mauvaise configuration firewall, target=DENY appliqué

**✅ Solutions :**

```bash
# Vous êtes bloqué ? Pas bon.
# À faire AVANT de configurer firewall :

# 1. Arrêter temporairement firewall (raccourci d'urgence)
ssh web "sudo systemctl stop firewalld"

# 2. Vous avez accès à nouveau

# 3. Reconfigurer correctement
ssh web "sudo firewall-cmd --set-default-zone=public"
ssh web "sudo firewall-cmd --permanent --add-port=2222/tcp"
ssh web "sudo firewall-cmd --permanent --add-service=http"
ssh web "sudo firewall-cmd --permanent --add-service=https"
ssh web "sudo firewall-cmd --reload"

# 4. Redémarrer firewall
ssh web "sudo systemctl start firewalld"

# 5. Vérifier
ssh web "firewall-cmd --list-all"
```

---

## 🛡️ Problèmes Wazuh

### ❌ Problème : "Agent ne se connecte pas au Manager"

**Symptôme :**
```
Agent en rouge/non connecté dans interface Wazuh
/var/ossec/bin/wazuh-control agent_control -l → Agent disconnected
```

**Causes possibles :**
1. Port 1514 fermé par firewall
2. IP Manager incorrecte dans config agent
3. Agent pas enregistré
4. Manager est arrêté

**✅ Solutions :**

```bash
# 1. Vérifier que manager tourne
ssh soc "systemctl status wazuh-manager"

# 2. Vérifier port 1514 sur manager
ssh soc "firewall-cmd --list-ports"
# Devrait afficher : 1514/tcp

# Si fermé, l'ouvrir :
ssh soc "sudo firewall-cmd --permanent --add-port=1514/tcp"
ssh soc "sudo firewall-cmd --reload"

# 3. Sur l'agent, vérifier config
ssh web "grep -A3 '<server>' /var/ossec/etc/ossec.conf"
# Devrait afficher IP du manager (192.168.1.20)

# 4. Vérifier agent est enregistré
ssh soc "/var/ossec/bin/manage_agents -l"
# Agent doit s'afficher avec ID et IP

# 5. Redémarrer agent
ssh web "sudo systemctl restart wazuh-agent"

# 6. Vérifier state
ssh web "/var/ossec/bin/wazuh-control state"
# Devrait dire : running

# 7. Vérifier depuis manager
ssh soc "/var/ossec/bin/wazuh-control agent_control -l"
# Agent doit être : Connected

# 8. Tester de nouveau (30 sec de délai possible)
sleep 30
ssh soc "/var/ossec/bin/wazuh-control agent_control -l"
```

---

### ❌ Problème : "Pas de logs collectés par Wazuh"

**Symptôme :**
```
Manager vide, aucune alerte, aucun événement
tail -f /var/ossec/logs/alerts/alerts.json → Rien
```

**Causes possibles :**
1. Logs sources n'existent pas
2. Fichiers de logs trop peu de permissions
3. Config `ossec.conf` pas correcte
4. Agent pas restarté après modif

**✅ Solutions :**

```bash
# 1. Vérifier que logs existent sur agent
ssh web "ls -la /var/log/secure /var/log/messages /var/log/nginx/"
# Fichiers doivent exister

# 2. Vérifier permissions (agent peut lire ?)
ssh web "ls -la /var/log/secure"
# Doit être readable

# 3. Vérifier config agent pour localfiles
ssh web "grep -A2 '<localfile>' /var/ossec/etc/ossec.conf"
# Chemins doivent être corrects

# 4. Générer test event
ssh web "echo 'TEST LOG MESSAGE' | tee -a /var/log/messages"

# 5. Redémarrer agent
ssh web "sudo systemctl restart wazuh-agent"

# 6. Attendre 10-15 secondes
sleep 15

# 7. Vérifier sur manager
ssh soc "tail -20 /var/ossec/logs/alerts/alerts.json | grep 'TEST'"

# 8. Si toujours rien, vérifier logs agent
ssh web "tail -50 /var/ossec/logs/ossec.log"
# Chercher erreurs : "cannot open" ou "permission denied"

# 9. Relancer agent en verbose
ssh web "sudo systemctl restart wazuh-agent"
ssh web "sudo tail -f /var/ossec/logs/ossec.log" # Sur agent
```

---

### ❌ Problème : "Interface web Wazuh ne répond pas"

**Symptôme :**
```
https://SOC_IP:443 → Erreur 403, 502, timeout
```

**Causes possibles :**
1. Service web arrêté
2. Port 443 fermé par firewall
3. Certificate SSL expiré
4. Elasticsearch arrêté

**✅ Solutions :**

```bash
# 1. Vérifier que manager tourne
ssh soc "systemctl status wazuh-manager"

# 2. Vérifier que firewall ouvre port 443
ssh soc "firewall-cmd --list-ports"
# Devrait afficher : 443/tcp

# Si fermé :
ssh soc "sudo firewall-cmd --permanent --add-port=443/tcp"
ssh soc "sudo firewall-cmd --reload"

# 3. Vérifier qu'Elasticsearch tourne
ssh soc "systemctl status elasticsearch"

# Si arrêté :
ssh soc "sudo systemctl start elasticsearch"

# 4. Vérifier Kibana
ssh soc "systemctl status kibana"

# Si arrêté :
ssh soc "sudo systemctl start kibana"

# 5. Attendre 30 sec (Elasticsearch démarre lentement)
sleep 30

# 6. Tester accès
ssh soc "curl -k https://localhost:443" # Depuis manager
# Ou accès distant : https://192.168.1.20:443

# 7. Vérifier certificats SSL
ssh soc "ls -la /etc/pki/tls/certs/"
# Certificats doivent exister (dates valides)
```

---

## 📊 Problèmes Monitoring (Zabbix/Prometheus)

### ❌ Problème : "Agent monitoring ne se connecte pas"

**Symptôme :**
```
Agent non disponible dans Zabbix/Prometheus
Impossible de récupérer métriques CPU/RAM/Disque
```

**Causes :**
1. Port 10050/10051 fermé
2. Firewall bloque agent
3. Certificat invalide

**✅ Solutions :**

```bash
# 1. Vérifier agent monitoring
ssh monitoring "systemctl status zabbix-agent"

# 2. Ouvrir ports si fermés
ssh monitoring "sudo firewall-cmd --permanent --add-port=10050/tcp"
ssh monitoring "sudo firewall-cmd --reload"

# 3. Vérifier port écoute
ssh monitoring "ss -tulpn | grep 10050"

# 4. Redémarrer agent
ssh monitoring "sudo systemctl restart zabbix-agent"

# 5. Tester depuis server
ssh soc "zabbix_get -s 192.168.1.30 -k 'system.uptime'"
# Devrait retourner temps uptime
```

---

## 💾 Problèmes d'Espace Disque

### ❌ Problème : "Disque plein"

**Symptôme :**
```
/var partition pleine
Logs arrêtent d'être collectés
Services en erreur
```

**Causes :**
1. Logs trop volumineux
2. Elasticsearch/Kibana utilise trop d'espace
3. Audits générés trop de données

**✅ Solutions :**

```bash
# 1. Voir l'espace disque
ssh soc "df -h"
# Identifier partition pleine (généralement /var)

# 2. Trouver les gros fichiers
ssh soc "du -sh /var/log/* | sort -rh | head -10"
# Voir quels logs prennent place

# 3. Archiver/supprimer vieux logs
ssh soc "tar -czf /backup/logs-backup.tar.gz /var/log/*.log*"
ssh soc "rm -f /var/log/*.log*"

# Ou rotation automatique (logrotate)
ssh soc "cat /etc/logrotate.d/wazuh"

# 4. Vérifier Elasticsearch volume
ssh soc "curl -s 'localhost:9200/_cat/indices?v' | head -20"
# Voir taille indices (très volumineuses = compresser)

# 5. Supprimer vieux indices Elasticsearch
ssh soc "curl -X DELETE 'localhost:9200/wazuh-alerts-2025.01*'"
# Garder seulement 30 jours

# 6. Vérifier de nouveau
ssh soc "df -h"
# Espace doit être libéré
```

---

## 🔐 Problèmes SELinux

### ❌ Problème : "Permission denied" avec SELinux enforcing"

**Symptôme :**
```
SSH works, mais services ne peuvent pas accéder fichiers
Logs : "SELinux policy violation"
```

**Causes :**
SELinux en mode enforcing avec règles restrictives

**✅ Solutions :**

```bash
# 1. Vérifier mode SELinux
ssh web "getenforce"
# Valeurs : Enforcing / Permissive / Disabled

# 2. Pour le projet, mode permissif suffit
ssh web "sudo setenforce 0"
# Permissive = log violations mais n'empêche pas

# 3. Rendre permanent (modifier fichier)
ssh web "sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config"

# 4. Redémarrer pour appliquer
ssh web "sudo reboot"

# 5. Vérifier après reboot
ssh web "getenforce"
# Devrait dire : Permissive
```

---

## 🔄 Problèmes Réseau & Ping

### ❌ Problème : "VMs ne communiquent pas du tout"

**Symptôme :**
```
Aucun ping entre les 3 VM
SSH impossible même en local
```

**Causes :**
1. VMs sur réseaux différents
2. Switch/route réseau mal configuré
3. Cartes réseau pas activées

**✅ Solutions :**

```bash
# 1. Vérifier IPs sur chaque VM
ssh web "ip addr show"
# Affiche interface + IP (ex: eth0 192.168.1.10)

# 2. Vérifier routes
ssh web "ip route show"
# Default route doit pointer vers routeur/gateway

# 3. Test ping entre VMs
ssh web "ping -c 3 192.168.1.20"  # Vers SOC

# 4. Si ping fail, vérifier firewall sur destination
ssh soc "firewall-cmd --list-all"

# 5. Autoriser ICMP (ping) si fermé
ssh soc "sudo firewall-cmd --permanent --add-icmp-block-inversion"
ssh soc "sudo firewall-cmd --reload"

# 6. Ou désactiver firewall temporairement (debug)
ssh soc "sudo systemctl stop firewalld"

# 7. Retest ping
ssh web "ping -c 3 192.168.1.20"

# 8. Si OK, reconfigurer firewall proprement
```

---

## 🛠️ Commandes de Debug Universelles

```bash
# Sur n'importe quelle VM, tester :

# 1. Connectivité réseau
ip addr show                        # IPs
ip route show                       # Routes
ping 8.8.8.8                       # Ping public
ss -tulpn                          # Ports écoutants

# 2. Services critiques
systemctl status sshd
systemctl status firewalld
systemctl status wazuh-manager (ou agent)

# 3. Logs d'erreurs
tail -100 /var/log/messages
tail -100 /var/log/secure
journalctl -u sshd -n 50           # Logs systemd

# 4. Espace disque
df -h
du -sh /var/log /var/ossec

# 5. Certificats SSL
openssl x509 -in /path/cert.pem -noout -dates

# 6. Configuration
cat /etc/ssh/sshd_config | grep -v "^#"
firewall-cmd --list-all
```

---

## 📋 Checklist Avant de Demander Aide

Avant de déclarer "ça marche pas" :

- [ ] Vérifier que VM source tourne
- [ ] Vérifier que VM destination tourne
- [ ] Tester ping entre les deux
- [ ] Vérifier firewall (ports ouverts ?)
- [ ] Vérifier service est démarré (`systemctl status`)
- [ ] Vérifier logs pertinents (`tail /var/log/...`)
- [ ] Redémarrer le service (`systemctl restart`)
- [ ] Attendre 30 secondes (Wazuh/Elasticsearch lents)
- [ ] Vérifier permissions fichiers/certificats
- [ ] Si toujours fail : demander de l'aide avec logs

---

## 🆘 Escalade d'Urgence

Si rien ne marche et vous êtes bloqué :

```bash
# 1. Arrêter le service problématique
ssh soc "sudo systemctl stop wazuh-manager"

# 2. Reprendre configuration
ssh soc "sudo systemctl start wazuh-manager"

# 3. Vérifier avec verbose
ssh soc "sudo systemctl restart wazuh-manager -vv"
ssh soc "tail -f /var/ossec/logs/ossec.log"

# 4. Réinitialiser config si tout échoue
ssh soc "sudo rm -rf /var/ossec/etc/*"
ssh soc "sudo systemctl restart wazuh-manager"

# 5. Reboot en dernier recours
ssh soc "sudo reboot"
```

---

**Dernière mise à jour** : Documentation projet Mini SOC  
**Niveau** : 2e année admin systèmes & réseaux  
**Astuce** : 90% des problèmes = firewall ou service arrêté !
