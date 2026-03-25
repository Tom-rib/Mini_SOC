# 07 - SELinux : Contrôle d'accès obligatoire

## 🎯 Objectif
Configurer SELinux en mode **enforcing** pour appliquer une politique de sécurité MAC (Mandatory Access Control). 
SELinux complète le système classique de permissions Unix en contrôlant l'accès au niveau du noyau.

**Durée estimée :** 45 minutes

---

## 📚 Concepts importants

### Qu'est-ce que SELinux ?
SELinux (Security-Enhanced Linux) ajoute une couche de contrôle d'accès au-dessus des permissions Unix traditionnelles.

Exemple simplifié :
- **Permissions Unix :** "Ce fichier appartient à root, groupe root, permission 644"
- **SELinux :** "Seul le processus `httpd` en contexte `httpd_t` peut accéder à ce fichier en lecture"

### Les 3 modes de SELinux

| Mode | Comportement | Utilisé pour |
|------|-------------|-------------|
| **Disabled** | SELinux complètement désactivé | Dépannage seulement |
| **Permissive** | Journalise les violations, ne les bloque pas | Test avant enforcing |
| **Enforcing** | Applique la politique, bloque les violations | Production |

### Contexte SELinux
Chaque fichier, utilisateur et processus a un contexte SELinux au format :
```
user_u:role_r:type_t:level
```
Exemple : `system_u:object_r:httpd_config_t:s0`

---

## ⚙️ Étape 1 : Vérifier l'état actuel

```bash
getenforce
```

**Output attendu :**
```
Enforcing
```

Si le résultat est `Disabled` ou `Permissive`, tu vas le changer.

```bash
sestatus
```

**Output attendu :**
```
SELinux status:                 enabled
Current mode:                   enforcing
Mode from config file:          enforcing
Policy version:                 33
Policy MLS status:              enabled
Max policy version:             33
```

---

## ⚙️ Étape 2 : Configurer SELinux en mode Enforcing

### Éditer le fichier de configuration
```bash
sudo nano /etc/selinux/config
```

Trouve la ligne `SELINUX=` et modifie-la comme ceci :

```
SELINUX=enforcing
```

Trouve aussi la ligne `SELINUXTYPE=` et vérifie qu'elle est à :

```
SELINUXTYPE=targeted
```

Sauvegarde : `Ctrl+O`, puis `Ctrl+X`.

### Exemple du fichier complet
```
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=enforcing

# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted policy (default)
#     mls - Multi-Level Security (advanced)
SELINUXTYPE=targeted
```

---

## ⚙️ Étape 3 : Appliquer les modifications

### Option A : Sans redémarrage (mode permissive → enforcing)
```bash
sudo semanage permissive -d -a httpd_t 2>/dev/null || true
```

### Option B : Redémarrer pour charger la nouvelle config
```bash
sudo reboot
```

Attends le redémarrage complet (~1 min).

---

## ⚙️ Étape 4 : Vérifier après le changement

```bash
getenforce
```

**Output attendu :**
```
Enforcing
```

```bash
sestatus -v
```

**Output attendu (résumé) :**
```
Current mode:                   enforcing
Mode from config file:          enforcing
...
```

---

## 🔍 Étape 5 : Analyser les logs SELinux

Les violations SELinux sont journalisées dans deux endroits :

### 1. Logs système
```bash
sudo tail -50 /var/log/messages | grep -i selinux
```

**Exemple de sortie :**
```
Nov 15 10:23:45 server audit: type=AVC msg=audit(1699971825.123:456): avc: denied { write } for pid=1234 comm="nginx" name="access.log" dev="dm-0" ino=789456 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:httpd_log_t:s0 tclass=file permissive=1
```

### 2. Logs d'audit (plus détaillés)
```bash
sudo tail -50 /var/log/audit/audit.log | grep -i selinux
```

### Interpréter une violation
La ligne d'erreur fournie indique :
- `avc: denied` = Type de violation
- `{ write }` = Action refusée (write, read, execute, etc.)
- `comm="nginx"` = Processus responsable
- `scontext=system_u:system_r:httpd_t:s0` = Contexte du processus
- `tcontext=system_u:object_r:httpd_log_t:s0` = Contexte du fichier cible

---

## 🔧 Gestion avancée : Commandes utiles

### Voir le contexte d'un fichier
```bash
ls -Z /var/www/html/
```

**Output attendu :**
```
system_u:object_r:httpd_sys_rw_content_t:s0 index.html
system_u:object_r:httpd_sys_rw_content_t:s0 page.html
```

### Changer le contexte d'un fichier
```bash
sudo chcon -t httpd_sys_rw_content_t /var/www/html/uploads/
```

### Voir le contexte d'un processus
```bash
ps -eZ | grep nginx
```

**Output attendu :**
```
system_u:system_r:httpd_t:s0   1234 ?  Ss  0:00 nginx: master process
```

### Gérer les booléens SELinux
SELinux a des options on/off appelées "booléens" pour adapter la politique.

```bash
# Voir tous les booléens
getsebool -a
```

**Exemple :**
```
httpd_can_network_connect --> off
httpd_can_network_memcache --> off
httpd_can_sendmail --> off
```

```bash
# Activer un booléen (permettre à Nginx de se connecter au réseau)
sudo setsebool -P httpd_can_network_connect on
```

Le flag `-P` rend le changement permanent (sauvegardé au redémarrage).

### Lister les booléans pour un service
```bash
getsebool -a | grep httpd
```

---

## ✅ Vérification finale

### Checklist de vérification

- [ ] `getenforce` retourne `Enforcing`
- [ ] `/etc/selinux/config` contient `SELINUX=enforcing`
- [ ] `sestatus -v` affiche le mode enforcing
- [ ] Les logs d'audit n'ont pas d'erreurs bloquantes (ou peu et documentées)
- [ ] Les services critiques (SSH, Web, etc.) fonctionnent correctement

### Tester SELinux sans impact

Avant d'appliquer une politique stricte, tu peux tester en mode permissive :

```bash
sudo semanage permissive -a httpd_t
```

Cela met uniquement le service httpd en mode permissive, le reste reste en enforcing.

---

## 🆘 Troubleshooting courant

### Problème 1 : Un service ne démarre plus après activation SELinux

**Symptôme :**
```
systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled)
   Active: failed (Result: exit-code)
```

**Cause probable :** Le contexte SELinux du fichier ou du processus est incorrect.

**Solution :**
```bash
# 1. Vérifier l'erreur exacte
sudo tail -20 /var/log/audit/audit.log | grep denied

# 2. Générer une règle de correction
sudo audit2allow -a -M httpd_fix
sudo semodule -i httpd_fix.pp
```

### Problème 2 : Trop de logs "denied"

**Cause possible :** La politique SELinux est trop restrictive.

**Solution rapide :** Passer en mode permissive temporairement
```bash
sudo semanage permissive -a httpd_t
```

Ou revenir temporairement à permissive global :
```bash
sudo semanage permissive -a unconfined_domain_type
```

### Problème 3 : "Permission denied" bien que les permissions Unix soient correctes

**Solution :** Vérifier le contexte SELinux
```bash
ls -Z /var/www/html/
# Doit être : system_u:object_r:httpd_sys_content_t:s0
```

Corriger si nécessaire :
```bash
sudo restorecon -Rv /var/www/html/
```

---

## 📋 Résumé des commandes clés

```bash
# Vérifier l'état
getenforce
sestatus -v

# Voir contextes
ls -Z /chemin/fichier
ps -eZ | grep processus

# Changer contexte
sudo chcon -t type_t /fichier
sudo restorecon -Rv /repertoire

# Gérer booléens
getsebool -a
sudo setsebool -P nom_boolean on/off

# Logs
sudo tail -50 /var/log/audit/audit.log | grep denied
sudo ausearch -m AVC -ts recent
```

---

## 🎓 Points clés à retenir

1. **SELinux = couche de sécurité supplémentaire** : C'est en plus des permissions Unix, pas à la place.
2. **Enforcing = bloque**, Permissive = journalise seulement.
3. **Contexte SELinux** : Chaque ressource a un contexte (utilisateur, rôle, type).
4. **Politique targeted** : C'est le standard en production, elle protège les services critiques.
5. **Logs importants** : `/var/log/audit/audit.log` est la source de vérité pour les erreurs SELinux.

---

## 📚 Ressources complémentaires

- Documentation officielle : `man selinux`
- Logs SELinux : `man ausearch`
- Gestion de contextes : `man chcon`

