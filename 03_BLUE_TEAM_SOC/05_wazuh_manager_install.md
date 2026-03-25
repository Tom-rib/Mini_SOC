# Wazuh Manager - Installation détaillée

**Objectif du chapitre :** Installer Wazuh Manager sur VM 2 (SOC / Logs / SIEM)

**Durée estimée :** 2 heures

**Prérequis :**
- VM Rocky Linux 8 ou 9 fraîchement installée
- 4 GB RAM minimum
- 30 GB espace disque libre
- Accès root ou sudo
- Connexion Internet (packages)
- Pare-feu: ports 1514 (TCP/UDP) et 443 (HTTPS) ouverts

---

## 1. Vérifications pré-installation

Avant de commencer, vérifie que ta machine est prête.

### Vérifier la version de Rocky Linux

```bash
cat /etc/rocky-release
```

**Résultat attendu :**
```
Rocky Linux release 9.x (Blue Onyx)
```

(Version 8 aussi acceptable)

### Vérifier l'espace disque

```bash
df -h
```

**À avoir :**
- `/` : au moins 30 GB libre
- Pas d'erreurs I/O

### Vérifier la RAM

```bash
free -h
```

**À avoir :**
- Au moins 4 GB libres après les services système

### Vérifier la connectivité Internet

```bash
ping -c 4 8.8.8.8
```

Résultat attendu : 4 réponses sans perte.

---

## 2. Préparation du système

### Mise à jour du système

```bash
sudo dnf update -y
sudo dnf upgrade -y
```

Redémarre si un kernel est mis à jour :

```bash
sudo reboot
```

### Installation des dépendances

Wazuh a besoin de plusieurs paquets :

```bash
sudo dnf install -y \
  curl \
  wget \
  gnupg \
  gcc \
  make \
  postgresql-devel \
  openssl-devel
```

### Créer l'utilisateur Wazuh (optionnel mais recommandé)

```bash
sudo useradd -r -s /bin/bash wazuh
sudo passwd -l wazuh  # Désactiver la connexion
```

Résultat attendu :
```
useradd: user 'wazuh' already exists (si déjà créé)
```

---

## 3. Installation de Wazuh Manager

### Télécharger le script d'installation officiel

Wazuh fournit un script d'installation automatisé. C'est la méthode la plus fiable.

```bash
curl -s https://packages.wazuh.com/4.7/wazuh-agent-4.7.0.tar.gz | sudo tar -xzf - -C /tmp
```

**Alternative (plus simple) : Installation via dépôt officiel**

Ajouter la clé GPG Wazuh :

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo rpm --import -
```

Ajouter le dépôt Wazuh :

```bash
sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
sudo tee /etc/yum.repos.d/wazuh.repo > /dev/null <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
```

Installer Wazuh Manager :

```bash
sudo dnf install -y wazuh-manager-4.7.0
```

Affichage attendu :
```
Installed:
  wazuh-manager-4.7.0-1.x86_64
  ...
Complete!
```

---

## 4. Démarrage du service Wazuh Manager

### Activer le démarrage automatique

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager
```

### Démarrer le service

```bash
sudo systemctl start wazuh-manager
```

### Vérifier que le service est actif

```bash
sudo systemctl status wazuh-manager
```

**Résultat attendu :**
```
● wazuh-manager.service - Wazuh Manager
   Loaded: loaded (/usr/lib/systemd/system/wazuh-manager.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-02-06 10:30:00 UTC; 30s ago
   ...
```

### Vérifier les ports ouverts

```bash
sudo ss -tuln | grep -E '1514|1515|443'
```

**Résultat attendu :**
```
tcp        0      0 0.0.0.0:1514            0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:1515            0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN
udp        0      0 0.0.0.0:1514            0.0.0.0:*
```

---

## 5. Configuration de base

### Localisation des fichiers Wazuh

```bash
ls -la /var/ossec/
```

Structure principale :
```
/var/ossec/
├── bin/                 # Commandes utilitaires
├── etc/                 # Configuration
│   ├── ossec.conf       # Configuration principale
│   ├── rules/           # Règles de détection
│   └── decoders/        # Parseurs de logs
├── logs/                # Logs Wazuh
│   ├── alerts/          # Alertes
│   └── ossec.log        # Log principal
├── queue/               # Queues interne
└── var/run/             # PID, sockets
```

### Éditer la configuration principale

```bash
sudo nano /var/ossec/etc/ossec.conf
```

**Sections importantes à vérifier :**

1. **Section `<global>` :**

```xml
<global>
  <json_out>yes</json_out>
  <alerts_log>yes</alerts_log>
  <logall>no</logall>
  <email_notification>no</email_notification>
  <log_alert_level>3</log_alert_level>
</global>
```

2. **Section `<alerts>` (logging des alertes) :**

```xml
<alerts>
  <log_alert_level>3</log_alert_level>
  <email_alert_level>12</email_alert_level>
</alerts>
```

3. **Section `<remote>` (réception agents) :**

```xml
<remote>
  <connection>secure</connection>
  <port>1514</port>
  <protocol>tcp</protocol>
  <max_clients>10000</max_clients>
</remote>
```

Les valeurs par défaut sont souvent bonnes. Si tu modifies, redémarre :

```bash
sudo systemctl restart wazuh-manager
```

---

## 6. Initialisation du Manager

### Créer une clé maître (optionnel mais recommandé)

```bash
sudo /var/ossec/bin/wazuh-control restart
```

### Vérifier que le Manager est opérationnel

```bash
sudo /var/ossec/bin/wazuh-control status
```

**Résultat attendu :**
```
wazuh-monitord is running...
wazuh-logcollector is running...
wazuh-remoted is running...
wazuh-analysisd is running...
wazuh-maild is running...
wazuh-execd is running...
wazuh-csyslogd is running...
wazuh-client.socket is running...
wazuh-client.service is running...
```

Tous les services doivent être "running".

### Vérifier les logs du Manager

```bash
sudo tail -f /var/ossec/logs/ossec.log
```

Ctrl+C pour quitter.

---

## 7. Installation de Wazuh Dashboard (Interface Web)

Wazuh Dashboard est l'interface Web pour visualiser les alertes.

### Installer les prérequis

```bash
sudo dnf install -y nodejs npm
```

### Installer Wazuh Dashboard

```bash
sudo dnf install -y wazuh-dashboard-4.7.0
```

### Activer et démarrer le service

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard
```

### Vérifier le statut

```bash
sudo systemctl status wazuh-dashboard
```

**Résultat attendu :**
```
Active: active (running)
```

---

## 8. Configuration de SELinux (si activé)

Si SELinux est en mode `enforcing`, il peut bloquer Wazuh.

### Vérifier le mode SELinux

```bash
getenforce
```

Résultat attendu : `Enforcing` ou `Disabled`

### Si SELinux bloque (erreurs dans les logs)

```bash
# Voir les erreurs SELinux
sudo audit2why -a

# Créer une règle pour Wazuh
sudo ausearch -c 'wazuh' --raw | audit2allow -M wazuh_local
sudo semodule -i wazuh_local.pp
```

**Alternative simple** (moins sécurisé, juste pour tests) :

```bash
sudo semanage boolean -m --on wazuh_manager_can_connect_any_port
```

---

## 9. Accès à l'interface Web

### URL d'accès

```
https://IP_VM2:443/app/wazuh
```

Remplace `IP_VM2` par l'IP de ta VM 2. Exemple :
```
https://192.168.1.50:443/app/wazuh
```

### Identifiants par défaut

```
Utilisateur : admin
Mot de passe : SecretPassword (ou voir ci-dessous)
```

**Obtenir le mot de passe initial :**

```bash
sudo grep "Initial password" /var/ossec/logs/ossec.log
```

Résultat :
```
2024-02-06T10:35:22.123456+00:00 hostname wazuh: Initial password: 'xxxxxxxxxxxxxxxx'
```

### Accès initial

1. Ouvre un navigateur Web
2. Va sur `https://IP_VM2:443/app/wazuh`
3. Accepte le certificat auto-signé (avertissement SSL)
4. Entre les identifiants

**⚠️ Sécurité :** Change immédiatement le mot de passe.

---

## 10. Changement du mot de passe administrateur

### Via l'interface Web

1. Clic en haut à droite → Admin
2. Onglet "Security"
3. Change ton mot de passe

### Via la ligne de commande

```bash
sudo /var/ossec/bin/wazuh-control restart
```

Puis depuis l'interface :

```bash
sudo /var/ossec/bin/wazuh_authd -f
```

---

## 11. Sauvegardes et optimisations (IMPORTANT)

### Sauvegarder la configuration

```bash
sudo cp -r /var/ossec/etc/ /home/user/wazuh_config_backup/
sudo cp /var/ossec/etc/ossec.conf /home/user/ossec.conf.backup
```

### Configurer la rétention des logs

```bash
sudo nano /etc/cron.daily/wazuh_logrotate
```

Ajoute :

```bash
#!/bin/bash
# Garder les alertes pendant 30 jours
find /var/ossec/logs/alerts/ -name "*.json" -type f -mtime +30 -delete
find /var/ossec/logs/archives/ -name "*.json" -type f -mtime +30 -delete
```

### Augmenter les limits (si beaucoup d'agents)

```bash
sudo nano /etc/security/limits.conf
```

Ajoute :

```
wazuh soft nofile 65536
wazuh hard nofile 65536
```

---

## 12. Vérifications finales (CHECKLIST)

Avant de passer à l'étape suivante, confirme :

- ✅ Version Wazuh installée
```bash
/var/ossec/bin/wazuh-control -v
```

- ✅ Services actifs
```bash
sudo systemctl status wazuh-manager wazuh-dashboard
```

- ✅ Ports ouverts
```bash
sudo ss -tuln | grep -E '1514|443'
```

- ✅ Interface Web accessible
```bash
https://IP_VM2:443/app/wazuh
```

- ✅ Pas d'erreurs dans les logs
```bash
sudo tail -20 /var/ossec/logs/ossec.log
```

---

## 13. Dépannage courant

### Problème 1 : Service wazuh-manager ne démarre pas

**Symptôme :**
```
Active: failed (Result: exit-code)
```

**Solution :**
```bash
# Vérifier les erreurs
sudo journalctl -u wazuh-manager -n 50

# Reconfigurer
sudo /var/ossec/bin/wazuh-control restart

# Si ossec.conf est cassé :
sudo nano /var/ossec/etc/ossec.conf
# Vérifier la syntaxe XML (balises fermées)
```

### Problème 2 : Interface Web ne charge pas

**Symptôme :**
```
ERR_CERT_AUTHORITY_INVALID (certificat auto-signé)
```

**Solution :**
1. Accepte le certificat (bouton "Advanced" → "Proceed")
2. Ou importe le certificat dans le navigateur

### Problème 3 : Agents ne se connectent pas (vu plus tard)

**Vérifier depuis le Manager :**
```bash
sudo ss -tuln | grep 1514
# Doit montrer LISTEN sur 0.0.0.0:1514
```

```bash
sudo tail -f /var/ossec/logs/ossec.log | grep -i agent
```

---

## 📚 Résumé des commandes clés

| Commande | Rôle |
|----------|------|
| `sudo systemctl start wazuh-manager` | Démarrer le Manager |
| `sudo /var/ossec/bin/wazuh-control status` | Vérifier tous les services |
| `sudo tail -f /var/ossec/logs/ossec.log` | Voir les logs en temps réel |
| `sudo nano /var/ossec/etc/ossec.conf` | Éditer la configuration |
| `https://IP:443/app/wazuh` | Accéder à l'interface Web |

---

## 💡 Mémo

**Manager = Cœur du SOC**
- Reçoit les logs des agents (port 1514)
- Analyse avec les règles
- Génère des alertes
- Expose une interface Web

**Prochaines étapes :**
1. Installer les agents sur les autres VM
2. Configurer les sources de logs
3. Créer des règles personnalisées

---

**Fin du chapitre 2 - Installation Manager**

Une fois que tu as confirmé toutes les cases de la checklist, continue vers l'installation des agents.
