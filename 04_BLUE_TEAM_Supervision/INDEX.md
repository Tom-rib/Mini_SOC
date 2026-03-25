# 📑 INDEX - Navigation et références croisées

---

## 📖 Fichiers principaux

### 05. Configuration des alertes Grafana (1h)
**Fichier** : `05_configuration_alertes.md`

**Sections** :
1. Concept des alertes (notification channels)
2. Types d'alertes (CPU, Disk, Service, RAM)
3. Configuration dans Grafana (step-by-step)
4. Tests des alertes (stress test)
5. Gestion des faux positifs
6. Validation et checklists

**Livrable** : 4 alertes configurées + emails testés

**Prérequis** : Grafana + Prometheus  
**Durée** : 1 heure  
**Difficulty** : ⭐⭐ Moyen  

---

### 06. Seuils et baselines (1h)
**Fichier** : `06_seuils_baselines.md`

**Sections** :
1. Concept d'une baseline
2. Évaluer baseline CPU (30 jours)
3. Évaluer baseline RAM
4. Évaluer baseline Disk
5. Formule : baseline + 30% = seuil
6. Réviser les baselines
7. Éviter faux positifs

**Livrable** : Fichier `baselines.md` complété

**Prérequis** : 30 jours de données Prometheus  
**Durée** : 1 heure  
**Difficulty** : ⭐⭐ Moyen  

**Note** : Lire après 05_configuration_alertes.md

---

### 07. Intégration Wazuh (1h)
**Fichier** : `07_integration_wazuh.md`

**Sections** :
1. Architecture d'intégration (Wazuh → Prometheus → Grafana)
2. Installer wazuh-exporter (Python)
3. Script Python d'export (200+ lignes)
4. Configurer Prometheus job
5. Créer dashboards Grafana
6. Alertes croisées (système + sécurité)
7. Requêtes PromQL utiles

**Livrable** : Dashboard Wazuh opérationnel

**Prérequis** : Wazuh Manager + Prometheus  
**Durée** : 1 heure  
**Difficulty** : ⭐⭐⭐ Avancé  

**Note** : Lire après 05 et 06

---

### 08. Procédures d'Incident Response (1h)
**Fichier** : `08_procedures_ir.md`

**Sections** :
1. Principes d'une procédure IR (5 phases)
2. PROCÉDURE #1 : Brute force SSH
   - Détection (logs)
   - Analyse (commandes)
   - Contention (bloquer)
   - Remédiation (hardening)
3. PROCÉDURE #2 : Upload malveillant
4. PROCÉDURE #3 : Scan réseau
5. PROCÉDURE #4 : Escalade privilèges
6. PROCÉDURE #5 : Connexion hors horaires

**Livrable** : 5 procédures écrites et testées

**Prérequis** : Wazuh + Fail2ban + Firewall  
**Durée** : 1 heure  
**Difficulty** : ⭐⭐⭐ Avancé  

---

### 09. Playbooks Ansible (1h30)
**Fichier** : `09_playbooks_ir.md`

**Sections** :
1. Installation Ansible
2. Configuration inventaire et SSH
3. Playbook #1 : Bloquer une IP (YAML)
4. Playbook #2 : Arrêter un service
5. Playbook #3 : Collecter les logs
6. Playbook #4 : Recovery après incident
7. Organiser les playbooks (folders)
8. Variables centralisées (group_vars)
9. Chaîner les playbooks (orchestration)
10. Tester les playbooks (--check, -vvv)

**Livrable** : 4 playbooks YAML testés + orchestration

**Prérequis** : Ansible + SSH keys  
**Durée** : 1h30  
**Difficulty** : ⭐⭐⭐ Avancé  

**Bash scripts** : 4 playbooks complets (800+ lignes)

---

### 10. Scripts Bash automatisés (1h30)
**Fichier** : `10_scripts_automatises.md`

**Sections** :
1. Concept : automation vs manuel
2. Script #1 : Bloquer IP + notifications
   - Firewall + IPTables
   - Email + Slack
   - Collecte preuves
3. Script #2 : Tuer un processus
4. Script #3 : Générer rapport Markdown
5. Intégrer avec Wazuh active-response
6. Chaîner les scripts (orchestration)
7. Automatiser avec Wazuh

**Livrable** : 3 scripts Bash testés + intégration Wazuh

**Prérequis** : Bash + Wazuh active-response  
**Durée** : 1h30  
**Difficulty** : ⭐⭐⭐ Avancé  

**Bash code** : 3 scripts complets (500+ lignes)

---

### 11. Gestion des incidents (45 min)
**Fichier** : `11_gestion_incidents.md`

**Sections** :
1. Workflow d'un incident (6 phases)
2. Système de ticketing basé sur fichiers
3. Template de ticket (markdown)
4. Scripts de gestion :
   - Créer un ticket
   - Déplacer un ticket (workflow)
   - Dashboard de suivi
5. SLA et KPI
6. Archivage et conformité
7. Intégration Wazuh

**Livrable** : Système de ticketing + 5 tickets d'exemple

**Prérequis** : /var/incident_tickets/ + scripts  
**Durée** : 45 minutes  
**Difficulty** : ⭐⭐ Moyen  

---

## 🔗 Dépendances et ordre de lecture

```
05_alertes
    ↓
06_baselines ← Dépend de 05
    ↓
07_wazuh ← Dépend de 05+06
    ↓
08_procedures (lecture indépendante)
    ↓
09_playbooks ← Dépend de 08
    ↓
10_scripts ← Dépend de 08+09
    ↓
11_gestion ← Intègre tout
```

**Chemin recommandé** : 05 → 06 → 07 → 08 → 09 → 10 → 11

**Chemin rapide** (4h) : 05 → 08 → 10 → 11 (skip 06, 07, 09)

---

## 🔍 Index par sujet

### Alerting & Monitoring
- **05_configuration_alertes.md** : Créer des alertes Grafana
- **06_seuils_baselines.md** : Baselines intelligentes
- **07_integration_wazuh.md** : Dashboard Wazuh

### Incident Response (Procédures)
- **08_procedures_ir.md** : 5 procédures IR écrites
  - Brute force SSH
  - Upload malveillant
  - Scan réseau
  - Escalade privilèges
  - Connexion hors horaires

### Automatisation
- **09_playbooks_ir.md** : Ansible (YAML)
- **10_scripts_automatises.md** : Bash (scripts)

### Gestion
- **11_gestion_incidents.md** : Ticketing + KPI

---

## 🔑 Commandes clés par fichier

### 05. Configuration des alertes
```bash
# Tester une alerte
stress --cpu 2 --timeout 5m

# Vérifier la notification
curl http://localhost:9090/api/v1/query?query=up
```

### 06. Baselines
```bash
# Analyser 30 jours
curl "http://prometheus:9090/query?query=rate(...)[30d]"

# Dashboard baseline dans Grafana
```

### 07. Intégration Wazuh
```bash
# Installer l'exporter
pip install requests prometheus-client

# Tester les métriques
curl http://localhost:9100/metrics | grep wazuh_
```

### 08. Procédures IR
```bash
# Vérifier les logs SSH
grep "Failed password" /var/log/secure

# Vérifier Fail2ban
sudo fail2ban-client status sshd
```

### 09. Playbooks Ansible
```bash
# Test syntax
ansible-playbook block_ip.yml --syntax-check

# Dry run (test)
ansible-playbook block_ip.yml -e "attacker_ip=X" --check

# Exécution réelle
ansible-playbook block_ip.yml -e "attacker_ip=X"
```

### 10. Scripts Bash
```bash
# Bloquer une IP
sudo /usr/local/bin/ir_block_ip.sh 192.168.1.50 3600

# Tuer un processus
sudo /usr/local/bin/ir_kill_process.sh nginx 15

# Générer un rapport
sudo /usr/local/bin/ir_generate_report.sh INC_001
```

### 11. Gestion incidents
```bash
# Créer un ticket
sudo /usr/local/bin/create_incident_ticket.sh brute_force HIGH

# Dashboard
/usr/local/bin/incident_dashboard.sh

# Déplacer un ticket
sudo /usr/local/bin/move_incident.sh INC_20250206_001 IN_PROGRESS
```

---

## 📊 Cas d'usage par section

| Cas d'usage | Fichiers | Durée |
|------------|----------|-------|
| Brute force SSH | 08 + 09 + 10 + 11 | 25 min |
| Upload malveillant | 08 + 10 + 11 | 20 min |
| Pic CPU | 05 + 06 + 09 | 15 min |
| Scan réseau | 08 + 10 | 15 min |
| Escalade privilèges | 08 + 09 + 10 | 20 min |

---

## ✅ Métriques de succès

### Alerting (05 + 06)
- [ ] 4+ alertes configurées
- [ ] Baselines établies pour 3 métriques
- [ ] Seuils appliqués
- [ ] Tests réussis

### Wazuh (07)
- [ ] Exporter opérationnel
- [ ] Prometheus scrape Wazuh
- [ ] Dashboard créé
- [ ] Alertes croisées fonctionnelles

### IR Procédures (08)
- [ ] 5 procédures écrites
- [ ] Chaque procédure testée
- [ ] Commandes validées
- [ ] Logs capturés

### Automatisation (09 + 10)
- [ ] 4 playbooks créés
- [ ] 3 scripts bash créés
- [ ] Ansible inventory configuré
- [ ] Tests en dry-run réussis
- [ ] Workflow complet testé

### Gestion (11)
- [ ] Système de ticketing créé
- [ ] Workflow (4 states) implémenté
- [ ] Dashboard KPI fonctionnel
- [ ] 5+ tickets test créés

---

## 🎯 Prochaines étapes

Après avoir complété ce module :

1. **SOAR Implementation**
   - Orchestrer les réactions complexes
   - Créer des workflows avancés

2. **Threat Intelligence**
   - Intégrer OSINT feeds
   - Corréler avec IOCs

3. **Advanced Forensics**
   - Collect avancée d'artefacts
   - Analyse post-mortem

4. **Red Team Simulation**
   - Tester les défenses
   - Trouver les gaps

---

## 🔍 Recherche rapide

### Par mot-clé

**Brute force** → 08 (proc #1) + 09 + 10 + 11  
**Firewall** → 08 (contention) + 09 + 10  
**Alerts** → 05 + 06 + 07  
**Automation** → 09 + 10  
**Wazuh** → 07 + 10 + 11  
**Ansible** → 09  
**Bash** → 10  
**Tickets** → 11  

### Par technologie

**Grafana** → 05, 06, 07  
**Prometheus** → 05, 06, 07  
**Wazuh** → 07, 08, 10, 11  
**Ansible** → 09  
**Bash/Linux** → 08, 10  
**Python** → 07  

### Par niveau

**Moyen (⭐⭐)** : 05, 06, 11  
**Avancé (⭐⭐⭐)** : 07, 08, 09, 10  

---

## 📚 Ressources externes

### Documentation officielle
- Grafana : https://grafana.com/docs/
- Prometheus : https://prometheus.io/docs/
- Wazuh : https://documentation.wazuh.com/
- Ansible : https://docs.ansible.com/
- Bash : https://www.gnu.org/software/bash/manual/

### Tutoriels
- Grafana Alerting : [lien formation]
- Prometheus PromQL : [lien formation]
- Ansible Playbooks : [lien formation]
- Bash Scripting : [lien formation]

---

## 💬 Support

### Questions fréquentes

**Q: Par où commencer ?**  
A: Lisez le README.md, puis suivez l'ordre 05 → 06 → 07 → 08 → 09 → 10 → 11

**Q: Combien de temps pour tout ?**  
A: ~7h30 au total. Compressible à 4-5h si vous skippez 06, 07.

**Q: Dois-je faire tous les scripts/playbooks ?**  
A: Au minimum 1 script + 1 playbook pour comprendre l'automatisation.

**Q: Peut-on adapter pour d'autres contextes ?**  
A: Oui, les concepts s'appliquent à Debian, Ubuntu, CentOS.

---

## 🏁 Validation finale

Pour valider votre compréhension :

**Niveau 1 (Débutant)** : Lire 05 + 06 + 08  
**Niveau 2 (Intermédiaire)** : Lire + tester 05 + 06 + 07 + 08 + 11  
**Niveau 3 (Expert)** : Compléter 05-11 + adapter à votre contexte  

---

**Dernière mise à jour** : 2025-02-06  
**Version** : 1.0  

Happy learning! 🚀
