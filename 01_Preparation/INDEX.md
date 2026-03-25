# 📚 01_PREPARATION - Index Complet

**Bienvenue dans la phase de préparation du projet Mini SOC !**

Cette section contient **5 documents essentiels** pour bien démarrer. Lis-les dans l'ordre proposé.

---

## 📖 Documents de Préparation

### 1️⃣ **[01_contexte_objectifs.md](01_contexte_objectifs.md)** ⏱️ 15 min

**Quoi ?** Comprendre le projet et ses objectifs  
**Contenu** :
- Contexte : Simulation d'entreprise sous attaque
- Les 3 rôles détaillés (Admin, SOC, IR)
- 5 attaques à simuler avec exemples
- Compétences validées
- FAQ débutants

**À lire si** : Tu veux savoir de quoi ce projet parle
**Apprend** : La "grande image" du projet

---

### 2️⃣ **[02_architecture_schema.md](02_architecture_schema.md)** ⏱️ 15 min

**Quoi ?** L'architecture technique du projet  
**Contenu** :
- Schéma global des 3 VMs
- Flux de données détaillé
- Cycle complet d'une attaque
- Configuration réseau (IP, ports)
- Matrice de communication inter-VMs
- Zones de sécurité

**À lire si** : Tu veux comprendre comment les machines communiquent
**Apprend** : L'infrastructure réseau et les flux

---

### 3️⃣ **[03_roles_equipes.md](03_roles_equipes.md)** ⏱️ 20 min

**Quoi ?** Le rôle spécifique de chaque personne  
**Contenu** :
- **Rôle 1 (Admin & Hardening)** :
  - Installation Rocky Linux
  - SSH sécurisé, Firewall, SELinux, Auditd
  - Configuration détaillée avec code
  - Livrables & checklist

- **Rôle 2 (SOC & Détection)** :
  - Wazuh Manager & Elasticsearch
  - Centralisation des logs
  - Règles personnalisées (avec exemples XML)
  - Dashboards Kibana
  - Livrables & checklist

- **Rôle 3 (Monitoring & IR)** :
  - Zabbix/Prometheus/Grafana
  - Dashboards
  - Playbooks Incident Response
  - Scripts bash automatisés
  - Livrables & checklist

**À lire si** : Tu as un rôle spécifique, ou tu veux comprendre ce que les autres font
**Apprend** : Les détails techniques de chaque rôle

---

### 4️⃣ **[04_prerequis.md](04_prerequis.md)** ⏱️ 10 min

**Quoi ?** Vérifier ton matériel et tes connaissances  
**Contenu** :
- Configuration matérielle requise (RAM, CPU, disque)
- Hyperviseurs (VirtualBox, Proxmox, KVM)
- ISO à télécharger
- Outils locaux (Git, SSH, etc.)
- Connaissances préalables
- Checklist complète
- Pièges courants & solutions

**À lire si** : Tu veux vérifier que tu as le matériel
**Apprend** : Ce qu'il te faut pour débuter

---

### 5️⃣ **[05_timeline.md](05_timeline.md)** ⏱️ 10 min

**Quoi ?** Organiser le projet sur 6 semaines  
**Contenu** :
- Gantt global des 6 semaines
- Détail hebdomadaire par rôle
- Heures estimées
- Points de synchronisation
- Réunions d'équipe proposées
- Livrables finaux
- Métriques de succès

**À lire si** : Tu veux savoir comment organiser ton temps
**Apprend** : La planification du projet

---

## 🎯 Par Où Commencer ?

### Si tu DÉBUTES (Recommandé)

```
Semaine 0 (Préparation)
1. Lis 01_contexte_objectifs.md (comprendre)
2. Lis 02_architecture_schema.md (visualiser)
3. Lis 04_prerequis.md (vérifier matériel)
4. Lis 05_timeline.md (planifier)
5. Lis 03_roles_equipes.md (détails rôle)

Puis : Commencer l'installation !
```

### Si tu REPRENDS le projet (Rafraîchissement)

```
1. Lis 05_timeline.md (où tu en es)
2. Lis 03_roles_equipes.md (ton rôle)
3. Va directement à 02_INSTALLATION/
```

### Si tu FORMES une équipe (Coordinateur)

```
1. Lis TOUS les fichiers
2. Imprime 05_timeline.md (planning)
3. Imprime 03_roles_equipes.md (rôles)
4. Crée Slack/Discord pour équipe
5. Planifie réunions lundi/jeudi
```

---

## 📊 Résumé Rapide

### Les 3 Rôles

| Rôle | Machines | Focus | Heures |
|---|---|---|---|
| **1 - Admin & Hardening** | VM 1 | Sécuriser l'OS | 34h |
| **2 - SOC & Détection** | VM 2 | Détecter attaques | 46h |
| **3 - Monitoring & IR** | VM 3 | Réagir aux incidents | 36h |

### Les 3 Machines

| VM | Rôle | IP | RAM | Disque |
|---|---|---|---|---|
| VM 1 | Serveur Web | 192.168.1.10 | 4 GB | 30 GB |
| VM 2 | SOC / SIEM | 192.168.1.20 | 6 GB | 50 GB |
| VM 3 | Monitoring | 192.168.1.30 | 4 GB | 30 GB |

### Les 6 Semaines

| Semaine | Thème | Rôle 1 | Rôle 2 | Rôle 3 |
|---|---|---|---|---|
| **S1** | Infrastructure | VM 1 install | VM 2 install | VM 3 install |
| **S2** | Hardening de base | SSH + FW | rsyslog | Zabbix |
| **S3** | Cœur SOC | SELinux + Audit | Wazuh + ELK | Grafana |
| **S4** | Intégration | Wazuh Agent | Règles perso | Alertes |
| **S5** | Tests | Validation | Dashboard Kibana | Playbooks IR |
| **S6** | Attaques | Tests | Analyses | Rapports |

---

## ✅ Checklist d'Étude

Avant de passer à l'installation, assure-toi que :

- [ ] J'ai compris le contexte du projet (document 1)
- [ ] Je visualise l'architecture réseau (document 2)
- [ ] Je maîtrise mon rôle (document 3)
- [ ] J'ai le matériel requis (document 4)
- [ ] J'ai un plan sur 6 semaines (document 5)
- [ ] Mon équipe connaît le planning (si groupe)
- [ ] GitHub repo créé et structuré
- [ ] Hyperviseur installé et testé

---

## 🚀 Prochaines Étapes

Une fois cette section lue :

1. **Vérifier matériel** (document 4)
2. **Créer repo GitHub** avec structure :
   ```
   mini-soc-rocky/
   ├── 01_PREPARATION/     ← Tu es ici
   ├── 02_INSTALLATION/    ← Étapes détaillées
   ├── 03_CONFIGURATION/   ← Configs spécifiques
   ├── 04_TESTS/          ← Scénarios d'attaques
   ├── 05_RAPPORTS/       ← Documents finaux
   └── README.md          ← Vue d'ensemble
   ```

3. **Installer VirtualBox** et tester
4. **Lancer installation** (semaine 1)

---

## 📞 Questions Fréquentes

### Q: Combien de temps ça prend ?

**R:** 6 semaines à 6-8h/semaine pour une équipe de 3 personnes.  
Seul = 3-4 mois. Peut être accéléré avec Ansible/Docker.

### Q: Je dois faire les 3 rôles ?

**R:** Non, tu peux en choisir un. Mais les 3 = plus complet pour le portfolio.

### Q: On peut utiliser Docker au lieu de VMs ?

**R:** Oui, mais moins pédagogique pour comprendre l'OS. À décider en équipe.

### Q: Les attaques sont réelles/dangereuses ?

**R:** Non, tu les simules volontairement. Pas de risque (réseau isolé).

### Q: Combien d'espace disque ?

**R:** 150 GB minimum en SSD. 300 GB confortable.

---

## 📚 Ressources Externals

- [Rocky Linux Docs](https://docs.rockylinux.org/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [Zabbix Docs](https://www.zabbix.com/documentation/)

---

## 💡 Conseil Final

> **Comprendre > Copier/Coller**
> 
> Ce projet n'est pas une liste de commandes à exécuter.  
> C'est une *expérience pédagogique*.
> 
> Prends le temps de comprendre **pourquoi** chaque étape.  
> Les meilleurs apprentissages viennent des erreurs.
> 
> Bonne chance ! 🚀

---

**Version** : 1.0  
**Dernière mise à jour** : Février 2026  
**Créé par** : Équipe La Plateforme
