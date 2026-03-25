# 03 - Sécuriser le transport des logs avec TLS/SSL

## 🎯 Objectif de cette étape

Chiffrer le transport des logs entre le serveur web et la VM SOC, pour qu'un attaquant ne puisse pas :
- **Voir** le contenu des logs en transit (confidentialité)
- **Modifier** les logs (intégrité)
- **Usurper l'identité** du serveur (authentification)

**Durée estimée** : 1 heure

---

## 📋 Concept : Pourquoi chiffrer ?

Imagine que tu envoies des logs en clair (plaintext) sur le réseau :

```
[Serveur Web] -------- "Failed password for root" -------- [Attaquant renifleur]
                                ↓
                    Attaquant voit tout ! ❌
```

Avec TLS :

```
[Serveur Web] -------- [CHIFFRÉ] -------- [SOC déchiffre]
                                ↓
                    Attaquant voit du charabia ✓
```

---

## 1. Comparaison : UDP, TCP, TLS

| Transport | Chiffrement | Fiabilité | Risques |
|-----------|------------|-----------|---------|
| **UDP** | ❌ Non | Aucune garantie | Logs perdus, espionnage, usurpation |
| **TCP** | ❌ Non | Garanti | Espionnage, modification de logs |
| **TLS** | ✓ Oui | Garanti + Sécurisé | Aucun (théoriquement) |

**Notre objectif** : UDP/TCP → TLS

---

## 2. Principes de TLS

### Ce que TLS protège

1. **Confidentialité** : chiffrage AES256
2. **Intégrité** : hash SHA-256 pour vérifier que rien n'a changé
3. **Authentification** : certificats X.509 pour vérifier que c'est bien la bonne VM SOC

### Fonctionnement simplifié

```
1. Client (serveur web) demande connexion sécurisée
2. Serveur (SOC) envoie son certificat
3. Client vérifie le certificat (n'est-ce vraiment la SOC ?)
4. Accord sur un chiffre
5. Tous les logs sont chiffrés à partir de là
```

---

## 3. Générer les certificats

### Approche 1 : Auto-signés (pour lab)

C'est le plus rapide pour apprendre. **Attention** : en production, utiliser une CA officielle.

**Sur la VM SOC, créer un répertoire pour les certs**

```bash
sudo mkdir -p /etc/pki/tls/certs
cd /etc/pki/tls/certs
```

**Générer la clé privée de la SOC**

```bash
# Créer une clé 2048 bits
sudo openssl genrsa -out soc-key.pem 2048

# Vérifier
ls -l soc-key.pem
```

**Générer le certificat auto-signé de la SOC**

```bash
sudo openssl req -new -x509 -days 365 \
  -key soc-key.pem \
  -out soc-cert.pem \
  -subj "/C=FR/ST=Provence/L=Marseille/O=Formation/CN=soc.local"
```

**Vérifier le certificat**

```bash
sudo openssl x509 -in soc-cert.pem -text -noout | head -20
```

**Résultat attendu** (extrait)
```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: ...
        Signature Algorithm: sha256WithRSAEncryption
        Subject: C = FR, ST = Provence, L = Marseille, O = Formation, CN = soc.local
        Validity
            Not Before: Jan 15 12:00:00 2025 GMT
            Not After : Jan 15 12:00:00 2026 GMT
```

**Combiner clé + certificat (optionnel, pour certains outils)**

```bash
sudo cat soc-key.pem soc-cert.pem > soc-bundle.pem
sudo chmod 600 soc-bundle.pem
```

---

### Approche 2 : Certificat signé par une CA personnelle

Pour une meilleure pratique (mais plus long).

**Créer une CA personnelle (une seule fois)**

```bash
# Clé de la CA
sudo openssl genrsa -out /etc/pki/tls/certs/ca-key.pem 2048

# Certificat de la CA
sudo openssl req -new -x509 -days 3650 \
  -key /etc/pki/tls/certs/ca-key.pem \
  -out /etc/pki/tls/certs/ca-cert.pem \
  -subj "/C=FR/ST=Provence/L=Marseille/O=Formation/CN=my-ca.local"
```

**Créer le certificat pour la SOC signé par la CA**

```bash
# Clé pour la SOC
sudo openssl genrsa -out /etc/pki/tls/certs/soc-key.pem 2048

# Demande de signature (CSR)
sudo openssl req -new \
  -key /etc/pki/tls/certs/soc-key.pem \
  -out /tmp/soc.csr \
  -subj "/C=FR/ST=Provence/L=Marseille/O=Formation/CN=soc.local"

# Signer le CSR avec la CA
sudo openssl x509 -req -days 365 \
  -in /tmp/soc.csr \
  -CA /etc/pki/tls/certs/ca-cert.pem \
  -CAkey /etc/pki/tls/certs/ca-key.pem \
  -CAcreateserial \
  -out /etc/pki/tls/certs/soc-cert.pem

# Nettoyer
sudo rm /tmp/soc.csr
```

---

### Vérifier et positionner les fichiers

**Sur la VM SOC**

```bash
# Vérifier les fichiers
ls -lh /etc/pki/tls/certs/soc-*.pem

# Résultat attendu
# -rw-r--r--. soc-key.pem    (clé privée, SECRET)
# -rw-r--r--. soc-cert.pem   (certificat public, OK à partager)

# Modifier les permissions de sécurité
sudo chmod 600 /etc/pki/tls/certs/soc-key.pem
sudo chown root:root /etc/pki/tls/certs/soc-*.pem
```

**Distribuer le certificat public au serveur web** (il en aura besoin pour vérifier)

```bash
# Sur la SOC, afficher le certificat
sudo cat /etc/pki/tls/certs/soc-cert.pem

# Copier ce contenu
```

**Sur le serveur web, créer le fichier**

```bash
sudo mkdir -p /etc/pki/tls/certs
sudo vi /etc/pki/tls/certs/soc-ca.pem

# Coller le contenu du certificat de la SOC
# Sauvegarder et quitter (:wq)

# Vérifier
sudo cat /etc/pki/tls/certs/soc-ca.pem
```

---

## 4. Configurer rsyslog avec TLS

### Sur le serveur web

**Éditer rsyslog**

```bash
sudo vi /etc/rsyslog.conf
```

**Remplacer la ligne d'envoi simple**

De :
```conf
*.* @@192.168.1.20:514
```

À :
```conf
# Module TLS pour rsyslog
$DefaultNetstreamDriver gtls
$DefaultNetstreamDriverCAFile /etc/pki/tls/certs/soc-ca.pem
$ActionSendStreamDriver gtls
$ActionSendStreamDriverMode 1            # 0=anon, 1=identity, 2=mutual
$ActionSendStreamDriverAuthMode x509/name
$ActionSendStreamDriverPermittedPeer soc.local

# Envoyer vers SOC avec TLS
*.* @@192.168.1.20:514
```

**Explication des paramètres**

| Paramètre | Signification |
|-----------|---|
| `$DefaultNetstreamDriver gtls` | Utiliser OpenSSL (gtls = GnuTLS) |
| `$DefaultNetstreamDriverCAFile` | Où trouver le certificat de la SOC pour la vérifier |
| `$ActionSendStreamDriverMode 1` | 1 = vérifier l'identité du serveur (recommandé) |
| `$ActionSendStreamDriverAuthMode x509/name` | Vérifier le CN (Common Name) du certificat |
| `$ActionSendStreamDriverPermittedPeer soc.local` | Le CN du certificat doit être exactement ceci |

**Vérifier la syntaxe**

```bash
sudo rsyslogd -N1
```

**Résultat attendu**
```
rsyslogd: version 8.2102.0, config validation run (level 0), master config /etc/rsyslog.conf
rsyslogd: End of config validation run. Syntax OK.
```

**Redémarrer rsyslog**

```bash
sudo systemctl restart rsyslog
sudo systemctl status rsyslog
```

---

### Sur la VM SOC : Configurer l'écoute TLS

**Éditer rsyslog sur la SOC**

```bash
sudo vi /etc/rsyslog.conf
```

**Ajouter la configuration du serveur TLS** (au début du fichier) :

```conf
# Charger le module d'écoute TCP/TLS
module(load="imtcp" StreamDriver.Name="gtls" StreamDriver.Mode="1")

# Configuration du certificat et clé
$DefaultNetstreamDriver gtls
$DefaultNetstreamDriverCAFile /etc/pki/tls/certs/soc-cert.pem
$DefaultNetstreamDriverCertFile /etc/pki/tls/certs/soc-cert.pem
$DefaultNetstreamDriverKeyFile /etc/pki/tls/certs/soc-key.pem

# Écouter sur le port 514 en TLS
input(type="imtcp" port="514" 
      StreamDriver.Name="gtls"
      StreamDriver.Mode="1"
      PermittedPeer="web01.local")

# Recevoir aussi en clair local
input(type="imuxsock" Socket="/dev/log" parseHostname="off")
```

**Alternative avec nommage de règles** (plus lisible) :

```conf
module(load="imtcp")

input(type="imtcp" port="514"
      name="remote-logs"
      StreamDriver.Name="gtls"
      StreamDriver.Mode="1"
      GnutlsPriorityString="NORMAL"
      PermittedPeer="web01.local")

# Définir un template pour ces logs
template(name="remote" type="list") {
    constant(value="[") constant(value=hostname) constant(value="] ")
    property(name="msg")
    constant(value="\n")
}

# Créer une file pour les logs distants
action(type="omfile" file="/var/log/remote/web01.log" template="remote")
```

**Vérifier la syntaxe**

```bash
sudo rsyslogd -N1
```

**Redémarrer rsyslog**

```bash
sudo systemctl restart rsyslog
sudo systemctl status rsyslog

# Vérifier que ça écoute
sudo ss -tuln | grep 514
```

**Résultat attendu**
```
tcp  LISTEN  0  32  0.0.0.0:514  0.0.0.0:*
```

---

## 5. Tester la connexion TLS

### Test 1 : Vérifier que la SOC écoute

```bash
# Sur la SOC
sudo ss -tuln | grep 514

# Résultat
tcp LISTEN 0 128 0.0.0.0:514 0.0.0.0:*
```

---

### Test 2 : Connecter avec `openssl s_client` (simulation client TLS)

**Depuis le serveur web**

```bash
# Vérifier la connexion TLS vers la SOC
openssl s_client -connect 192.168.1.20:514 \
  -CAfile /etc/pki/tls/certs/soc-ca.pem \
  -showcerts

# Résultat attendu : connexion réussie, certificat vérifiée
```

**Si ça fonctionne**, tu devrais voir quelque chose comme :

```
CONNECTED(00000003)
depth=0 C = FR, ST = Provence, L = Marseille, O = Formation, CN = soc.local
verify return:1
---
Certificate chain
 0 s:C = FR, ST = Provence, L = Marseille, O = Formation, CN = soc.local
   i:C = FR, ST = Provence, L = Marseille, O = Formation, CN = soc.local
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
---
Server certificate
...
---
```

**Si erreur "verify failure"** → le nom du certificat ne correspond pas. Voir Troubleshooting.

---

### Test 3 : Envoyer un message de test

**Sur le serveur web**

```bash
logger -t tls-test "Message test chiffré via TLS"

# Vérifier localement
grep "tls-test" /var/log/messages
```

**Sur la VM SOC**

```bash
# Vérifier que le message est reçu
tail -20 /var/log/messages | grep "tls-test"

# Ou si tu as créé un fichier custom pour les logs distants
sudo tail -20 /var/log/remote/web01.log
```

**Résultat attendu** : Tu devrais voir le message sur la SOC.

---

### Test 4 : Vérifier que c'est bien chiffré (optionnel)

**Capturer le trafic en clair** (la preuve qu'il est chiffré) :

```bash
# Sur la SOC ou un PC intermédiaire
sudo tcpdump -i eth0 -nn -A 'port 514'
```

**Résultat attendu** : Tu verras du trafic TCP port 514, mais le contenu sera du charabia binary (chiffré).

Si le message était en clair, tu verrais directement "tls-test" dans le dump.

---

## 6. Configurer Filebeat avec TLS

**Alternative à rsyslog, si tu utilises Filebeat.**

**Sur le serveur web, éditer `/etc/filebeat/filebeat.yml`**

```yaml
output.logstash:
  enabled: true
  hosts: ["192.168.1.20:5000"]
  
  # Configuration TLS
  ssl.enabled: true
  ssl.verification_mode: certificate
  ssl.certificate_authorities: 
    - "/etc/pki/tls/certs/soc-ca.pem"
  ssl.certificate: "/etc/pki/tls/certs/client-cert.pem"
  ssl.key: "/etc/pki/tls/certs/client-key.pem"
```

**Ou plus simple : TLS du côté serveur seulement**

```yaml
output.logstash:
  enabled: true
  hosts: ["192.168.1.20:5000"]
  
  ssl.enabled: true
  ssl.verification_mode: full
  ssl.certificate_authorities: ["/etc/pki/tls/certs/soc-ca.pem"]
```

**Tester la config**

```bash
sudo filebeat test output -c /etc/filebeat/filebeat.yml
```

**Redémarrer**

```bash
sudo systemctl restart filebeat
sudo journalctl -u filebeat -n 20
```

---

## 7. Troubleshooting

### Problème : "certificate verify failed"

**Cause** : Le CN du certificat ne correspond pas à `$ActionSendStreamDriverPermittedPeer`.

**Solution**

```bash
# Vérifier le CN du certificat
sudo openssl x509 -in /etc/pki/tls/certs/soc-cert.pem -noout -subject

# Résultat attendu
subject=C = FR, ST = Provence, L = Marseille, O = Formation, CN = soc.local

# Corriger dans rsyslog.conf si besoin
$ActionSendStreamDriverPermittedPeer soc.local  # Doit être exactement le CN
```

---

### Problème : "Unsupported algorithm" ou erreur SSL

**Cause** : Version d'OpenSSL ancienne ou incompatibilité.

**Solution**

```bash
# Spécifier des algorithms compatibles
$GnutlsPriorityString "NORMAL:!MD5:!DES:!RC4:!IDEA:!SEED:!aDSS:!MD5:!PSK"
```

ou

```bash
# Utiliser TLS 1.2 minimum
$GnutlsPriorityString "SECURE256:!ARCFOUR-128"
```

---

### Problème : Logs ne passent plus (rsyslog a redémarré mal)

**Solution**

```bash
# Revenir à la config de test
sudo cp /etc/rsyslog.conf.backup /etc/rsyslog.conf

# Vérifier que rsyslog fonctionne
sudo systemctl restart rsyslog
sudo systemctl status rsyslog

# Puis refaire la config TLS pas à pas
```

---

### Problème : Message "timeout waiting for TLS handshake"

**Cause** : La SOC n'a pas configuré le TLS en réception, ou port fermé.

**Solution**

```bash
# Sur la SOC, vérifier l'écoute
sudo netstat -tuln | grep 514

# Si vide, relancer rsyslog et vérifier la config
sudo systemctl restart rsyslog
sudo systemctl status rsyslog

# Vérifier le firewall
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=514/tcp
sudo firewall-cmd --permanent
sudo firewall-cmd --reload
```

---

## 8. Vérification avancée : Déboggage en temps réel

**Mode verbeux rsyslog** (voir les connections TLS)

```bash
# Sur la SOC
sudo systemctl stop rsyslog
sudo rsyslogd -d -n -f /etc/rsyslog.conf
```

Tu verrais les tentatives de connexion en détail. Appuyer sur Ctrl+C pour arrêter.

**Logs de rsyslog**

```bash
# Sur le serveur web, voir les erreurs d'envoi
sudo tail -f /var/log/messages | grep rsyslog
```

---

## 9. Sécurité avancée : Authentification mutuelle

**Pour que le serveur web vérifie aussi l'identité de la SOC** (sécurité maximale) :

**Sur le serveur web, ajouter**

```conf
$ActionSendStreamDriverAuthMode x509/name
$ActionSendStreamDriverPermittedPeer soc.local
```

**Sur la SOC, côté réception**

```conf
input(type="imtcp" port="514"
      StreamDriver.Name="gtls"
      StreamDriver.Mode="1"
      PermittedPeer="web01.local")
```

Les deux vérifient l'identité de l'autre → authentification mutuelle.

---

## ✅ Checklist finale

- [ ] Certificats générés sur la SOC (clé + cert)
- [ ] Certificat de la SOC copié sur le serveur web
- [ ] rsyslog config TLS sur le serveur web (syntaxe OK)
- [ ] rsyslog config TLS sur la SOC (écoute active)
- [ ] Message de test passé avec succès
- [ ] openssl s_client se connecte correctement
- [ ] tcpdump montre du trafic chiffré (pas de texte visible)

---

## ✨ Résultat

Tu as maintenant :

1. **Centralisation** : Logs du serveur web → VM SOC
2. **Sécurité** : Transport chiffré avec TLS
3. **Authentification** : Vérification des certificats

Les logs ne peuvent plus être effacés, lus ou modifiés en transit.

---

## 📚 Ressources complètes

### Générer rapidement des certificats

```bash
#!/bin/bash
# Script pour générer certs (à adapter)

SOC_IP="192.168.1.20"
SOC_NAME="soc.local"
WEBSERVER_NAME="web01.local"
DAYS=365

# Sur la SOC
openssl genrsa -out soc-key.pem 2048
openssl req -new -x509 -days $DAYS \
  -key soc-key.pem \
  -out soc-cert.pem \
  -subj "/CN=$SOC_NAME"

# Copier le certificat au serveur web
# scp soc-cert.pem web01:/etc/pki/tls/certs/soc-ca.pem
```

### Raccourci rsyslog TLS minimal

```conf
module(load="imtcp" StreamDriver.Name="gtls" StreamDriver.Mode="1")
input(type="imtcp" port="514")
$DefaultNetstreamDriver gtls
$DefaultNetstreamDriverCAFile /etc/pki/tls/certs/soc-ca.pem
*.* @@192.168.1.20:514
```

### Vérifier les certificats

```bash
# Afficher les infos d'un cert
openssl x509 -in soc-cert.pem -text -noout

# Vérifier une chaîne de certificats
openssl verify -CAfile ca-cert.pem soc-cert.pem

# Voir l'expiration
openssl x509 -in soc-cert.pem -noout -dates
```
