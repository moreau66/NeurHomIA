# 💾 Guide : Clé USB d'Installation NeurHomIA

> **Version** : 2.1.0 | **Mise à jour** : 2026-03-13T10:00:00

Ce guide vous accompagne dans la création d'une clé USB bootable qui installe automatiquement **Ubuntu Server 24.04 LTS sécurisé** avec **NeurHomIA pré-configuré** sur un mini-PC.
L'expérience est similaire à Home Assistant OS : insérez la clé, démarrez, et obtenez un système domotique fonctionnel en ~10 minutes.

---

## 📑 Table des matières

- [Concept](#concept)
- [Prérequis](#prerequis)
- [Préparer l'environnement de travail](#preparer-lenvironnement-de-travail)
- [Méthode rapide — Script automatisé (recommandée)](#methode-rapide--script-automatise-recommandee)
- [Méthode manuelle (avancée)](#methode-manuelle-avancee)
- [Création de la clé USB](#creation-de-la-cle-usb)
- [Installation sur le mini-PC](#installation-sur-le-mini-pc)
- [Post-installation](#post-installation)
- [Dépannage](#depannage)
- [Checklist sécurité](#checklist-securite)

---

## Concept

```
┌──────────────┐      ┌────────────┐      ┌────────────────────────┐
│  Clé USB     │ ───> │  Mini PC   │ ───> │  NeurHomIA Ready       │
│  bootable    │      │  boot USB  │      │  http://<ip>:8080      │
│  autoinstall │      │  ~10 min   │      │  Docker + MQTT + Sécu  │
└──────────────┘      └────────────┘      └────────────────────────┘
```

Le système combine **Ubuntu autoinstall** (installation non-interactive) et un **script de premier démarrage** interactif :

1. **L'ISO personnalisée** installe Ubuntu Server avec les paquets essentiels
2. **Au premier boot**, un assistant interactif (whiptail) configure :
   - ✅ Réseau (DHCP ou IP statique)
   - ✅ Mot de passe sécurisé
   - ✅ Clé SSH (optionnel)
   - ✅ Firewall UFW + fail2ban
   - ✅ Mises à jour automatiques
   - ✅ Profils Docker au choix (Zigbee, météo, etc.)
   - ✅ NeurHomIA cloné et démarré

---

## Prérequis

### Mini-PC recommandés

| Modèle neuf              | CPU         | RAM     | Stockage    | Prix indicatif |
| ------------------------ | ----------- | ------- | ----------- | -------------- |
| **Beelink Mini S12 Pro** | Intel N100  | 8 Go    | 256 Go SSD  | ~150 €         |
| **MeLe Quieter4C**       | Intel N100  | 8 Go    | 256 Go eMMC | ~130 €         |
| **Intel NUC 12**         | Intel i3/i5 | 8-16 Go | 256+ Go SSD | ~250-400 €     |
| **Dell Optiplex MFF**    | Intel i3/i5 | 8-32 Go | 256+ Go SSD | ~150-400 €     |
| **Trigkey Green G4**     | Intel N100  | 16 Go   | 500 Go SSD  | ~180 €         |

| Modèle occasion       | CPU         | RAM     | Stockage    | Prix indicatif |
| --------------------- | ----------- | ------- | ----------- | -------------- |
| **Dell Optiplex MFF** | Intel i3/i5 | 8-32 Go | 256+ Go SSD | ~150-400 €     |

> **Minimum requis** : CPU x86_64, 4 Go RAM, 64 Go stockage, port Ethernet (recommandé) ou WiFi.

### Matériel nécessaire

- 🔑 **Clé USB 8 Go minimum** (16 Go recommandé)
- 💻 **PC de préparation** (Windows ou Linux) pour créer la clé
- 🌐 **Connexion Internet** sur le mini-PC (Ethernet recommandé)
- 📺 **Écran + clavier** temporairement pour le premier boot (assistant interactif)

### Logiciels de gravure

| OS               | Logiciel                | Lien                                         |
| ---------------- | ----------------------- | -------------------------------------------- |
| Windows          | **Rufus**               | [rufus.ie](https://rufus.ie)                 |
| macOS            | **balenaEtcher**        | [etcher.balena.io](https://etcher.balena.io) |
| Linux            | **dd** ou **Ventoy**    | Intégré / [ventoy.net](https://ventoy.net)   |
| Multi-plateforme | **Ventoy** (recommandé) | [ventoy.net](https://ventoy.net)             |

> 💡 **Ventoy** est recommandé car il permet de mettre plusieurs ISOs sur la même clé et supporte nativement l'autoinstall.

---

## Préparer l'environnement de travail

Le script de construction de l'ISO fonctionne sous **Linux**. Si vous êtes sous Windows, utilisez **WSL2** (Windows Subsystem for Linux).

### 🪟 Sous Windows (WSL2)

#### 1. Installer WSL2

Ouvrez **PowerShell en tant qu'administrateur** et exécutez :

```powershell
wsl --install -d Ubuntu-24.04
```

> Redémarrez l'ordinateur si demandé. Au premier lancement, WSL vous demandera de créer un nom d'utilisateur et un mot de passe Linux.

#### 2. Ouvrir le terminal Ubuntu

Lancez l'application **Ubuntu** depuis le menu Démarrer, ou tapez `wsl` dans PowerShell.

#### 3. Installer les dépendances

Dans le terminal Ubuntu WSL :

```bash
sudo apt update && sudo apt install -y p7zip-full xorriso wget curl openssl
```

#### 4. Note importante pour la gravure USB

L'ISO générée sera accessible depuis l'Explorateur Windows via :

```
\\wsl$\Ubuntu\home\<votre-utilisateur>\neurhomia-iso\
```

> ⚠️ **WSL ne peut pas accéder directement aux périphériques USB pour graver.** Vous devez utiliser **Rufus** ou **Ventoy** depuis Windows en naviguant vers le fichier ISO dans le chemin ci-dessus.

### 🐧 Sous Linux

#### 1. Installer les dépendances

```bash
sudo apt update && sudo apt install -y p7zip-full xorriso wget curl openssl
```

> Sur Fedora/RHEL : `sudo dnf install -y p7zip xorriso wget curl openssl`
> Sur Arch : `sudo pacman -S p7zip xorriso wget curl openssl`

#### 2. C'est tout !

Vous pouvez passer directement à la méthode rapide ci-dessous.

---

## Méthode rapide — Script automatisé (recommandée)

Cette méthode utilise le script `build-iso.sh` qui automatise toute la création de l'ISO. **3 commandes suffisent.**

### Télécharger les scripts

```bash
# Créer un dossier de travail
mkdir -p ~/neurhomia-build && cd ~/neurhomia-build

# Télécharger le script de construction
curl -O https://raw.githubusercontent.com/moreau66/NeurHomIA/main/scripts/build-iso2usb/build-iso.sh

# Rendre exécutable
chmod +x build-iso.sh
```

### Lancer la construction

```bash
./build-iso.sh
```

Le script va :

1. ✅ Vérifier les dépendances installées
2. ✅ Vous demander un mot de passe pour l'utilisateur `neurhomia`
3. ✅ Télécharger l'ISO Ubuntu Server 24.04.4 (~2 Go)
4. ✅ Vérifier l'intégrité (SHA256)
5. ✅ Extraire l'ISO et injecter la configuration autoinstall
6. ✅ Reconstruire une ISO hybride (UEFI + BIOS)
7. ✅ **Valider automatiquement l'ISO** (structure autoinstall, boot UEFI/BIOS, taille, checksum SHA256)

> ⏱️ Durée : ~5-15 minutes selon votre connexion Internet.

À la fin, le script affiche le chemin de l'ISO générée :

```
✅ ISO générée avec succès !
  Fichier : ~/neurhomia-iso/neurhomia-server-auto.iso
```

> 💡 **Sous WSL**, le script affiche automatiquement le chemin Windows pour accéder à l'ISO.

### Ce que fait le script au premier boot

L'ISO contient un service systemd qui lance automatiquement l'assistant `firstboot-cfg.sh` au premier démarrage. Cet assistant interactif (whiptail) vous guide pour :

| Étape | Configuration                                       |
| ----- | --------------------------------------------------- |
| 1     | Choix de l'interface réseau et mode (DHCP/statique) |
| 2     | Changement du mot de passe par défaut               |
| 3     | Ajout d'une clé SSH (optionnel)                     |
| 4     | Configuration du pare-feu UFW                       |
| 5     | Activation de fail2ban                              |
| 6     | Mises à jour de sécurité automatiques               |
| 7     | Sélection des profils Docker (Zigbee, météo, etc.)  |
| 8     | Choix du fuseau horaire                             |
| 9     | Mot de passe MQTT personnalisé                      |
| 10    | Clonage et démarrage de NeurHomIA                   |

➡️ Passez maintenant à la section [Création de la clé USB](#creation-de-la-cle-usb).

---

## Méthode manuelle (avancée)

> Cette méthode est destinée aux utilisateurs avancés qui veulent personnaliser le fichier `user-data` en détail.

### Étape 1 — Télécharger l'ISO

Téléchargez **Ubuntu Server 24.04.4 LTS** (Live Server) :

🔗 [https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso](https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso)

```bash
# Vérifier l'intégrité
wget https://releases.ubuntu.com/24.04.4/SHA256SUMS
sha256sum -c SHA256SUMS 2>/dev/null | grep ubuntu-24.04.4-live-server-amd64.iso
# Doit afficher : ubuntu-24.04.4-live-server-amd64.iso: OK
```

### Étape 2 — Créer le fichier user-data minimal

Après gravure de l'ISO sur la clé USB, créez un dossier `autoinstall/` à la racine avec deux fichiers :

```
clé USB/
├── (contenu ISO Ubuntu)
└── autoinstall/
    ├── meta-data          ← fichier vide (requis)
    └── user-data          ← configuration ci-dessous
```

```bash
# Fichier meta-data (vide)
touch autoinstall/meta-data
```

#### Fichier `user-data`

> Générez d'abord le hash de votre mot de passe :
>
> ```bash
> openssl passwd -6 "votre_mot_de_passe"
> ```

```yaml
#cloud-config
autoinstall:
  version: 1
  locale: fr_FR.UTF-8
  keyboard:
    layout: fr
  network:
    network:
      version: 2
      ethernets:
        all-eth:
          match:
            name: "en*"
          dhcp4: true
          optional: true
  storage:
    layout:
      name: lvm
      sizing-policy: all
  identity:
    hostname: neurhomia-box
    username: neurhomia
    # Remplacez par le hash généré ci-dessus
    password: "$6$rounds=4096$VOTRE_HASH_ICI"
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - docker.io
    - docker-compose-plugin
    - ufw
    - fail2ban
    - curl
    - wget
    - git
    - htop
    - net-tools
    - unattended-upgrades
    - apt-listchanges
    - whiptail
  updates: security
  late-commands:
    - curtin in-target -- systemctl enable docker
    - curtin in-target -- usermod -aG docker neurhomia
    - mkdir -p /target/opt/neurhomia
    - curtin in-target -- wget -O /opt/neurhomia/firstboot-cfg.sh https://raw.githubusercontent.com/moreau66/NeurHomIA/main/scripts/build-iso2usb/firstboot-cfg.sh
    - curtin in-target -- chmod +x /opt/neurhomia/firstboot-cfg.sh
    - |
      cat > /target/etc/systemd/system/neurhomia-firstboot.service <<'SERV'
[Unit]
Description=NeurHomIA First Boot Configuration
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/opt/neurhomia/firstboot-cfg.sh
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
SERV
    - curtin in-target -- systemctl enable neurhomia-firstboot.service
  shutdown: reboot
```

> 💡 Le `user-data` est volontairement minimal : toute la configuration avancée (réseau, SSH, firewall, Docker profiles) est gérée par l'assistant `firstboot-cfg.sh` au premier démarrage.

### Étape 3 — Modifier le GRUB (optionnel)

Pour forcer l'autoinstall au boot, modifiez `/boot/grub/grub.cfg` sur la clé :

```bash
menuentry "Installation Ubuntu Server auto" {
  set gfxpayload=keep
  linux /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/cdrom/autoinstall/ ---
  initrd /casper/initrd
}
```

---

## Création de la clé USB

### Méthode 1 : Ventoy (recommandée)

**Ventoy** permet de simplement copier l'ISO sur la clé sans gravure.

```bash
# 1. Installer Ventoy sur la clé USB
# Télécharger depuis https://ventoy.net
# Exécuter Ventoy2Disk et sélectionner votre clé USB

# 2. Copier l'ISO sur la partition Ventoy
cp ~/neurhomia-iso/neurhomia-server-auto.iso /media/ventoy/
```

> Si vous avez utilisé la **méthode rapide**, l'autoinstall est déjà intégré dans l'ISO, pas besoin de dossier `autoinstall/` séparé.
>
> Si vous avez utilisé la **méthode manuelle**, copiez aussi le dossier `autoinstall/` :
>
> ```bash
> cp -r autoinstall/ /media/ventoy/
> ```

### Méthode 2 : Rufus (Windows)

1. Ouvrez **Rufus** ([rufus.ie](https://rufus.ie))
2. Sélectionnez votre clé USB
3. Cliquez sur **SÉLECTION** et choisissez l'ISO :
   - Méthode rapide : naviguez vers `\\wsl$\Ubuntu\home\<user>\neurhomia-iso\neurhomia-server-auto.iso`
   - Méthode manuelle : choisissez l'ISO Ubuntu téléchargée
4. Schéma de partition : **GPT** (UEFI) — recommandé pour les mini-PC récents
5. Cliquez sur **DÉMARRER**
6. Si méthode manuelle : copiez le dossier `autoinstall/` à la racine de la clé après gravure

### Méthode 3 : dd (Linux)

```bash
# ⚠️ ATTENTION : vérifiez bien le périphérique (/dev/sdX) !
# Listez vos disques : lsblk

sudo dd if=~/neurhomia-iso/neurhomia-server-auto.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

> Pour la méthode manuelle avec `dd`, vous devez d'abord intégrer l'autoinstall dans l'ISO (voir la section méthode rapide) ou utiliser Ventoy.

### Méthode 4 : balenaEtcher (macOS)

1. Ouvrez **balenaEtcher** ([etcher.balena.io](https://etcher.balena.io))
2. Sélectionnez l'ISO
3. Sélectionnez la clé USB
4. Cliquez sur **Flash!**

---

## Installation sur le mini-PC

### Préparation du BIOS

1. **Branchez** la clé USB sur le mini-PC
2. **Démarrez** le mini-PC et accédez au BIOS (touche `F2`, `F12`, `DEL` ou `ESC` selon le modèle)
3. **Configurez** :
   - Boot order : USB en premier
   - Secure Boot : **Désactivé** (recommandé)
   - Mode UEFI (recommandé) ou Legacy

### Installation automatique

1. **Démarrez** depuis la clé USB
2. L'installateur Ubuntu détecte automatiquement le fichier `autoinstall/user-data`
3. **L'installation est 100% automatique** — aucune interaction requise
4. Durée estimée : **8 à 15 minutes** selon le matériel et la connexion Internet
5. Le mini-PC **redémarre automatiquement** à la fin

### Premier démarrage — Assistant interactif

Après le redémarrage automatique, l'assistant de configuration se lance :

> ⚠️ **Un écran et un clavier sont nécessaires** pour cette étape.

L'assistant vous guide à travers les étapes suivantes :

1. **🌐 Réseau** — Choix de l'interface, DHCP ou IP statique
2. **🔑 Mot de passe** — Changement du mot de passe par défaut
3. **🔐 SSH** — Ajout optionnel d'une clé publique SSH
4. **🛡️ Firewall** — UFW configuré automatiquement (ports 22, 80, 443, 1883, 8080, 9001)
5. **🚫 fail2ban** — Protection anti-bruteforce activée
6. **📦 Docker** — Sélection des profils (Zigbee, météo, backup, etc.)
7. **🔧 MQTT** — Configuration du mot de passe MQTT
8. **🚀 Démarrage** — NeurHomIA cloné et lancé

> ⏱️ Durée totale : ~5 minutes de configuration + ~5 minutes de téléchargement des images Docker.

À la fin, l'assistant affiche l'adresse d'accès :

```
✅ Configuration terminée !
  Dashboard : http://192.168.1.xxx:8080
```

L'assistant se désactive automatiquement après la première exécution.

---

## Post-installation

### Trouver l'adresse IP du serveur

**Depuis le mini-PC** (si écran branché) :

```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

**Depuis votre réseau** (depuis un autre PC) :

```bash
# Scanner le réseau local
nmap -sn 192.168.1.0/24 | grep -B 2 "neurhomia"

# Ou via votre box/routeur : consultez la liste des appareils connectés
```

### Accéder au dashboard

Ouvrez votre navigateur et accédez à :

```
http://<adresse-ip>:8080
```

### Commandes utilitaires intégrées

| Commande                   | Description                              |
| -------------------------- | ---------------------------------------- |
| `neurhomia-status`         | État des conteneurs, disque et mémoire   |
| `neurhomia-logs`           | Journaux en direct (Ctrl+C pour quitter) |
| `neurhomia-logs mosquitto` | Journaux d'un service spécifique         |
| `neurhomia-restart`        | Redémarrer tous les services             |
| `neurhomia-update`         | Mettre à jour NeurHomIA depuis GitHub    |

### Vérifier l'état des services

```bash
# Commande intégrée
neurhomia-status

# Ou manuellement
cd /opt/neurhomia
docker compose ps
docker compose logs --tail=20
```

### Actions recommandées après installation

#### 1. Ajouter votre clé SSH (si pas fait pendant l'assistant)

```bash
# Depuis votre PC de travail :
ssh-copy-id neurhomia@<adresse-ip>

# Puis désactiver l'authentification par mot de passe SSH :
sudo nano /etc/ssh/sshd_config.d/99-neurhomia.conf
# Changer : PasswordAuthentication yes → PasswordAuthentication no
sudo systemctl restart sshd
```

#### 2. Configurer les sauvegardes

Consultez le [Guide des Sauvegardes](guide-sauvegardes.md) pour configurer les sauvegardes automatiques.

---

## Dépannage

### Le mini-PC ne boot pas sur la clé USB

| Problème                   | Solution                                                 |
| -------------------------- | -------------------------------------------------------- |
| Clé USB non détectée       | Essayez un autre port USB (préférez USB 2.0/3.0 arrière) |
| Boot sur le disque interne | Vérifiez l'ordre de boot dans le BIOS (F2/F12/DEL)       |
| Secure Boot bloque         | Désactivez Secure Boot dans le BIOS                      |
| Mode UEFI/Legacy           | Essayez l'autre mode si l'un ne fonctionne pas           |

### L'autoinstall ne se lance pas

| Problème                     | Solution                                                            |
| ---------------------------- | ------------------------------------------------------------------- |
| Installation interactive     | Le dossier `autoinstall/` n'est pas à la racine de la clé           |
| Erreur YAML                  | Vérifiez l'indentation du `user-data` (espaces, pas de tabulations) |
| Fichier `meta-data` manquant | Créez un fichier vide `meta-data`                                   |

### L'assistant de premier boot ne se lance pas

```bash
# Vérifier le statut du service
sudo systemctl status neurhomia-firstboot.service

# Voir les logs
sudo journalctl -u neurhomia-firstboot.service

# Lancer manuellement si nécessaire
sudo /opt/neurhomia/firstboot-cfg.sh
```

### Docker ne démarre pas après installation

```bash
# Vérifier le statut Docker
sudo systemctl status docker

# Si Docker n'est pas démarré
sudo systemctl start docker
sudo systemctl enable docker

# Vérifier que l'utilisateur est dans le groupe docker
# Remplacez <utilisateur> par le nom choisi lors de l'installation (ex: neurhomia)
groups <utilisateur>
# Si docker n'apparaît pas :
sudo usermod -aG docker <utilisateur>
newgrp docker
```

### NeurHomIA n'est pas accessible

```bash
# Vérifier si les conteneurs tournent
neurhomia-status

# Si aucun conteneur ne tourne, lancer manuellement
cd /opt/neurhomia
docker compose up -d

# Vérifier le firewall
sudo ufw status
# Les ports 8080 et 1883 doivent être ALLOW

# Vérifier la connectivité réseau
ip addr show
ping -c 3 8.8.8.8
```

### Problèmes réseau

```bash
# Pas de DHCP ? Configurer une IP statique
sudo nano /etc/netplan/99-neurhomia.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp1s0:  # Adaptez au nom de votre interface
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
```

```bash
sudo netplan apply
```

---

## Checklist sécurité

Après l'installation, vérifiez ces points de sécurité :

### ✅ Configuré automatiquement par l'assistant

- [x] Firewall UFW activé (ports 22, 80, 443, 1883, 8080, 9001)
- [x] fail2ban activé (SSH : 3 tentatives max, ban 2h)
- [x] SSH : root login interdit
- [x] SSH : nombre de tentatives limité (3)
- [x] Mises à jour de sécurité automatiques (`unattended-upgrades`)
- [x] Utilisateur non-root avec sudo

### ⚠️ Vérifié pendant l'assistant (mais à confirmer)

- [ ] **Mot de passe changé** (l'assistant le propose)
- [ ] **Mot de passe MQTT personnalisé** (l'assistant le demande)
- [ ] **Clé SSH ajoutée** (optionnel pendant l'assistant)

### 🔒 Durcissement optionnel

```bash
# Changer le port SSH (ex: 2222)
sudo nano /etc/ssh/sshd_config.d/99-neurhomia.conf
# Ajouter : Port 2222
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
sudo systemctl restart sshd

# Activer le 2FA SSH (optionnel)
sudo apt install libpam-google-authenticator
google-authenticator

# Limiter les connexions réseau avec iptables
sudo ufw limit ssh comment 'Rate limit SSH'
```

---

## Mini-PC recommandés — Guide d'achat

### Budget (~130-180 €)

| Modèle                   | Avantages                            | Inconvénients            |
| ------------------------ | ------------------------------------ | ------------------------ |
| **Beelink Mini S12 Pro** | Silencieux, compact, N100 performant | RAM soudée               |
| **MeLe Quieter4C**       | Fanless (0 bruit), très compact      | eMMC plus lent qu'un SSD |
| **Trigkey Green G4**     | 16 Go RAM, bon rapport qualité/prix  | Moins connu              |

### Performance (~250-400 €)

| Modèle               | Avantages                      | Inconvénients            |
| -------------------- | ------------------------------ | ------------------------ |
| **Intel NUC 12/13**  | Fiable, extensible, communauté | Plus cher                |
| **Beelink SER5 Pro** | AMD Ryzen, puissant            | Consommation plus élevée |

### Critères de choix

- **Silence** : Privilégiez les modèles fanless pour un serveur 24/7
- **Ethernet** : Port Gigabit indispensable (évitez le WiFi seul)
- **RAM** : 8 Go minimum, 16 Go confortable
- **Stockage** : SSD NVMe ou SATA, évitez le HDD
- **Consommation** : Les Intel N100 consomment ~6-10W (très économique)

---

## Architecture du système installé

```
┌───────────────────────────────────────────────────┐
│                Ubuntu Server 24.04                │
│                                                   │
│  ┌─────────────────────────────────────────────┐  │
│  │                Docker Engine                │  │
│  │                                             │  │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐  │  │
│  │  │ NeurHomIA │ │ Mosquitto │ │ file-sync │  │  │
│  │  │   :8080   │ │   :1883   │ │    API    │  │  │
│  │  └───────────┘ └───────────┘ └───────────┘  │  │
│  │                                             │  │
│  │  ┌───────────────────────────────────────┐  │  │
│  │  │     Services optionnels (profiles)    │  │  │
│  │  │   astral2mqtt │ docker2mqtt │ meteo   │  │  │
│  │  │   zigbee2mqtt │ xmqtt2mqtt  │ backup  │  │  │
│  │  └───────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│  🔒 UFW Firewall │ 🛡️ fail2ban │ 🔑 SSH secured   │
└───────────────────────────────────────────────────┘
```

---
