# 🔐 H4sh Lab - Infrastructure Réseau Sécurisée

Infrastructure réseau complète avec segmentation VLAN, DMZ et monitoring SOC pour laboratoire de cybersécurité.

## 📋 Table des Matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Segmentation VLAN](#segmentation-vlan)
- [Matrice de Sécurité](#matrice-de-sécurité)
- [Installation](#installation)
- [Configuration](#configuration)
- [Tests de Validation](#tests-de-validation)
- [Dépannage](#dépannage)

## 🎯 Vue d'ensemble

Ce projet implémente une infrastructure réseau d'entreprise sécurisée avec :

- **Segmentation réseau** : 8 VLANs isolés
- **DMZ double** : Zone externe (exposition Internet) et zone interne (services critiques)
- **SOC/SIEM** : Monitoring avec Wazuh et Splunk
- **Firewall avancé** : Protection anti-DDoS, anti-scan, règles de segmentation strictes
- **Architecture 3-tiers** : Routeur → Switch distribution → Switches d'accès

### Équipements

- **1x RouterH4sh** : MikroTik CHR (Cloud Hosted Router) - Routage et Firewall
- **1x SW1** : MikroTik CRS328-24P-4S+ - Switch de distribution
- **2x LAN-H4sh1/2** : MikroTik CRS328-24P-4S+ - Switches d'accès

## 🏗️ Architecture

```
                    INTERNET (192.168.1.0/24)
                            |
                    [Cloud1 - Bridge]
                            |
                    ┌───────┴────────┐
                    │  RouterH4sh    │ ← Firewall/NAT/Routage
                    │  ether1: WAN   │
                    │  ether10: LAN  │
                    └───────┬────────┘
                            │
                       Trunk VLANs
                            │
                    ┌───────┴────────┐
                    │      SW1       │ ← Distribution
                    └───┬────────┬───┘
                        │        │
            ┌───────────┘        └───────────┐
            │                                │
    ┌───────┴────────┐              ┌───────┴────────┐
    │  LAN-H4sh1     │              │  LAN-H4sh2     │
    │  - PC1, PC2    │              │  - PC3         │
    │  - AD Server   │              │  - Web Server  │
    │  - Wazuh       │              │  - IT Server   │
    └────────────────┘              │  - Splunk      │
                                    └────────────────┘
```

## 🌐 Segmentation VLAN

| VLAN | Nom | Réseau | Usage | Accès Internet |
|------|-----|--------|-------|----------------|
| 10 | LAN | 172.16.10.0/24 | Employés | ✅ Complet |
| 20 | IT | 172.16.20.0/24 | Administration | ✅ Complet |
| 30 | WiFi-Emp | 172.16.30.0/24 | WiFi employés | ✅ Complet |
| 31 | WiFi-Guest | 172.16.31.0/24 | WiFi invités | ✅ HTTP/HTTPS uniquement |
| 100 | SOC | 172.16.100.0/24 | Monitoring/SIEM | ✅ Threat intel |
| 200 | DMZ-EXT | 172.16.200.0/24 | Exposition Internet | ✅ Updates |
| 201 | DMZ-INT | 172.16.201.0/24 | Services critiques | ✅ Updates |
| 999 | MGMT | 172.16.255.0/24 | Management | ✅ NTP/Updates |

### Plan d'Adressage Détaillé

#### VLAN 10 - LAN Employés
- **Gateway** : 172.16.10.254
- **DHCP** : 172.16.10.100-200
- **Équipements** : PC1 (.101), PC2 (.102), PC3 (.103)

#### VLAN 100 - SOC
- **Gateway** : 172.16.100.254
- **Wazuh** : 172.16.100.10 (ports 1514, 1515, 55000)
- **Splunk** : 172.16.100.20 (ports 8000, 9997)

#### VLAN 200 - DMZ Externe
- **Gateway** : 172.16.200.254
- **Web Server** : 172.16.200.10
- **NAT depuis Internet** :
  - `192.168.1.200:80` → `172.16.200.10:80` (HTTP)
  - `192.168.1.200:443` → `172.16.200.10:443` (HTTPS)
  - `192.168.1.200:2222` → `172.16.200.10:22` (SSH)

#### VLAN 201 - DMZ Interne
- **Gateway** : 172.16.201.254
- **AD Server** : 172.16.201.10 (dc.lab.local)
- **Services AD** : 53, 88, 135, 389, 445, 464, 636, 3268, 3269, 3389

#### VLAN 999 - Management
- **RouterH4sh** : 172.16.255.254 (gateway + management)
- **SW1** : 172.16.255.11
- **LAN-H4sh1** : 172.16.255.12
- **LAN-H4sh2** : 172.16.255.13

## 🔒 Matrice de Sécurité

### Règles de Firewall (Résumé)

| Source | Destination | Ports/Protocole | Action | Justification |
|--------|-------------|-----------------|--------|---------------|
| Internet | DMZ-EXT | 80, 443, 22 | ✅ ACCEPT | Services web publics |
| Internet | Autres VLANs | * | ❌ DROP | Protection périmètre |
| DMZ-EXT | Internet | * | ✅ ACCEPT | Updates, DNS |
| DMZ-EXT | DMZ-INT | 445, 3389, 1433 | ✅ ACCEPT | Pivot contrôlé (pentest) |
| DMZ-EXT | LAN/IT/WiFi | * | ❌ DROP | Isolation DMZ |
| DMZ-INT | Internet | * | ✅ ACCEPT | Updates Windows |
| DMZ-INT | LAN | * | ❌ DROP | Anti-pivot critique |
| LAN | Internet | * | ✅ ACCEPT | Accès employés |
| LAN | DMZ-INT | AD services | ✅ ACCEPT | Authentification |
| LAN | DMZ-EXT | * | ❌ DROP | Segmentation |
| LAN | IT | * | ❌ DROP | Principe du moindre privilège |
| IT | TOUS | * | ✅ ACCEPT | Administration complète |
| WiFi-Guest | Internet | 80, 443 | ✅ ACCEPT | Navigation uniquement |
| WiFi-Guest | Internes | * | ❌ DROP | Isolation totale |
| SOC | TOUS | Monitoring | ✅ ACCEPT | Visibilité complète |
| TOUS | SOC | 1514, 1515 | ✅ ACCEPT | Envoi de logs |

### Protections Actives

- ✅ **Anti-Port Scanning** : Détection NMAP, blacklist 2 semaines
- ✅ **Anti-SYN Flood** : Limite 25 paquets/5s
- ✅ **Connection Tracking** : Established/Related en premier
- ✅ **BPDU Guard** : Protection contre les boucles
- ✅ **Logging** : Tous les drops sont loggés

## 🚀 Installation

### Prérequis

- GNS3 2.2+
- Images MikroTik CHR 7.8+
- 4 Go RAM minimum pour la VM GNS3
- Connaissances réseau de base

### Import dans GNS3

1. **Créer la topologie** :
   - Ajouter 1x RouterH4sh (CHR)
   - Ajouter 3x Switches MikroTik (SW1, LAN-H4sh1, LAN-H4sh2)
   - Ajouter 1x Cloud (bridge vers réseau hôte)

2. **Câblage** :
   ```
   Cloud1 eth0 → RouterH4sh ether1
   RouterH4sh ether10 → SW1 ether1
   SW1 ether2 → LAN-H4sh1 ether24
   SW1 ether3 → LAN-H4sh2 ether24
   ```

3. **Appliquer les configurations** :
   ```bash
   # Sur chaque équipement, copier-coller le contenu du fichier correspondant
   # OU importer via /import file=xxx.rsc
   ```

## ⚙️ Configuration

### Configuration Rapide

```bash
# 1. RouterH4sh
/import file=configs/RouterH4sh.rsc

# 2. SW1
/import file=configs/SW1.rsc

# 3. LAN-H4sh1
/import file=configs/LAN-H4sh1.rsc

# 4. LAN-H4sh2
/import file=configs/LAN-H4sh2.rsc
```

### Paramètres à Personnaliser

Avant l'import, modifiez ces paramètres dans les fichiers :

- **RouterH4sh** :
  - `192.168.1.200/24` → Votre réseau WAN
  - `gateway=192.168.1.254` → Votre passerelle
  - Mots de passe des utilisateurs

- **Tous les switches** :
  - Mots de passe des utilisateurs
  - Serveurs NTP si nécessaire

## ✅ Tests de Validation

### Tests de Connectivité de Base

```bash
# Depuis RouterH4sh
ping 172.16.255.11  # SW1
ping 172.16.255.12  # LAN-H4sh1
ping 172.16.255.13  # LAN-H4sh2
ping 8.8.8.8        # Internet

# Depuis SW1
ping 172.16.255.254 # RouterH4sh

# Depuis PC1 (VLAN 10)
ping 172.16.10.254  # Gateway
ping 8.8.8.8        # Internet
ping 172.16.201.10  # AD Server (doit fonctionner)
```

### Tests de Sécurité

```bash
# Depuis PC1 (LAN)
ping 172.16.200.10  # DMZ-EXT → ❌ Doit échouer
ping 172.16.20.x    # IT VLAN → ❌ Doit échouer

# Depuis DMZ-EXT (172.16.200.10)
ping 172.16.10.101  # LAN → ❌ Doit échouer
telnet 172.16.201.10 445  # DMZ-INT SMB → ✅ Doit fonctionner (pivot)

# Depuis WiFi Guest
ping 172.16.10.101  # LAN → ❌ Doit échouer
curl http://google.com  # Internet → ✅ Doit fonctionner
```

### Vérification Firewall

```bash
# Sur RouterH4sh
/log print where topics~"firewall"

# Vérifier les compteurs
/ip firewall filter print stats

# Tester la détection de scan
# Depuis ton PC hôte :
nmap -sS 192.168.1.200
# Puis vérifier la blacklist :
/ip firewall address-list print where list=port-scanners
```

## 🔧 Dépannage

### Problème : Pas de ping entre VLANs

```bash
# Vérifier VLAN filtering
/interface bridge print
# vlan-filtering doit être "yes"

# Vérifier que bridge est membre des VLANs
/interface bridge vlan print
# "bridge" doit apparaître dans CURRENT-TAGGED

# Vérifier ingress-filtering
/interface bridge print detail
# Si ingress-filtering=yes et ça ne fonctionne pas, essayer de le désactiver
/interface bridge set bridge ingress-filtering=no
```

### Problème : VLAN Management ne fonctionne pas

```bash
# Vérifier l'interface VLAN
/interface vlan print
# vlan999-mgmt doit exister sur "bridge"

# Vérifier l'IP
/ip address print where interface=vlan999-mgmt

# Vérifier la route
/ip route print
```

### Problème : Internet ne fonctionne pas

```bash
# Sur RouterH4sh
# Vérifier NAT
/ip firewall nat print

# Vérifier route par défaut
/ip route print

# Tester depuis le routeur
/ping 8.8.8.8
```

### Logs Utiles

```bash
# Firewall drops
/log print where message~"DROP"

# Connexions invalides
/log print where message~"INVALID"

# Port scanning détecté
/log print where message~"port-scanners"
```

## 📊 Monitoring

### Dashboards Recommandés

- **Wazuh** : `http://172.16.100.10:55000`
- **Splunk** : `http://172.16.100.20:8000`

### Métriques à Surveiller

- Taux de paquets droppés par le firewall
- Tentatives de scan détectées
- Connexions depuis DMZ-EXT vers DMZ-INT (pivot)
- Trafic WiFi invités vers réseaux internes (doit être 0)

## 🎓 Cas d'Usage Pentest

Cette infrastructure permet de simuler :

1. **Pivot DMZ** : Compromission Web Server → Accès contrôlé DMZ-INT
2. **Élévation de privilèges** : DMZ-INT → Tentative d'accès LAN (bloqué et loggé)
3. **Exfiltration de données** : Monitoring des flux sortants suspects
4. **Reconnaissance** : Détection des scans de ports

## 📝 Changelog

### Version 1.0 (Février 2026)
- ✅ Architecture 3-tiers complète
- ✅ 8 VLANs segmentés
- ✅ Firewall avec 40+ règles
- ✅ Protection anti-DDoS et anti-scan
- ✅ NAT configuré pour DMZ-EXT
- ✅ DHCP sur VLANs utilisateurs
- ✅ DNS interne et statique

## 👤 Auteur

**0xH4shDumb**

## 📄 Licence

Ce projet est fourni à des fins éducatives uniquement.

---

**⚠️ Avertissement** : Cette infrastructure est conçue pour un environnement de laboratoire. Ne pas utiliser en production sans audit de sécurité complet.
