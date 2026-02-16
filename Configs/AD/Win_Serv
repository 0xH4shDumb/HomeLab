# 🏢 Infrastructure H4SH Corp - Windows Server

![Status](https://img.shields.io/badge/Status-En%20D%C3%A9veloppement-green)
![Platform](https://img.shields.io/badge/Platform-Windows%20Server%202022%20|%20Cisco%20IOS-blue)
![Tools](https://img.shields.io/badge/Tools-PowerShell%20|%20Active%20Directory%20|%20GPO-orange)

## 📌 Présentation du Projet
Simulation complète d'une infrastructure d'entreprise multi-sites (Paris, Tokyo, New-York) pour la société fictive **H4SH Corp**.
L'objectif est de déployer un réseau sécurisé, automatisé et résilient, respectant les bonnes pratiques de l'industrie (Tiering model, Least Privilege, Segmentation).

## 🏗️ Architecture
* **Contrôleur de Domaine :** Windows Server 2019/2022 (AD DS, DNS, DHCP)
* **Réseau :** Topologie Cisco (VLANs, ROAS, ACLs)
* **Postes Clients :** Windows 10 Pro

## 🚀 Fonctionnalités Déployées

### 🔐 Active Directory & Identité
* **Structure OU Hiérarchique :** Organisation géographique (`Pays > Ville > Service`).
* **Automatisation :** Script PowerShell personnalisé pour le déploiement massif d'utilisateurs via CSV.
* **Modèle de Tiering (Sécurité) :** Séparation stricte entre les comptes Administrateurs (`_ADMINISTRATION`) et les utilisateurs standards.

### 📂 Serveur de Fichiers & Stockage
* **Lecteurs Réseau :** Déploiement automatique via GPO (Lecteur Z: Commun, Lecteur P: Personnel).
* **Sécurité des Données :**
    * **ABE (Access-Based Enumeration) :** Masquage des dossiers non autorisés.
    * **Redirection de Dossiers :** Bureau et Documents redirigés sur le serveur pour la sauvegarde.
    * **ACLs Strictes :** Principe du moindre privilège appliqué par service (RH, IT, etc.).

### 🖥️ Stratégies de Groupe (GPO)
* Mappage automatique des lecteurs.
* Configuration régionale (Clavier AZERTY forcé sur l'OU France).
* Restrictions de sécurité.

## 🛠️ Installation & Usage
1.  Cloner le repo.
2.  Importer les configurations Cisco dans Packet Tracer/GNS3.
3.  Exécuter `Import-Users.ps1` sur le DC pour peupler l'AD.

---
*Projet réalisé par Théo TITEUX dans le cadre d'un Portfolio DevOps/SysAdmin.*
