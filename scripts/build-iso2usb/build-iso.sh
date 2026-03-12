#!/bin/bash
# build-iso.sh – Construction de l'ISO d'installation automatique pour NeurHomIA
# Usage : ./build-iso.sh
# Nécessite : wget, p7zip-full, genisoimage (ou mkisofs), openssl

set -e  # Arrêt en cas d'erreur

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ------------------------------
# Demande interactive de la version d'Ubuntu
# ------------------------------
DEFAULT_VERSION="24.04.4"
echo -e "${YELLOW}Quelle version d'Ubuntu Server souhaitez-vous utiliser ? (par défaut : $DEFAULT_VERSION)${NC}"
echo -e "Format attendu : X.Y.Z (exemple : 24.04.4)"
read -p "Version : " USER_VERSION

if [ -z "$USER_VERSION" ]; then
    ISO_VERSION="$DEFAULT_VERSION"
    echo -e "${GREEN}Version par défaut sélectionnée : $ISO_VERSION${NC}"
else
    # Validation simple : doit correspondre à un format comme 24.04.4
    if [[ "$USER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ISO_VERSION="$USER_VERSION"
        echo -e "${GREEN}Version sélectionnée : $ISO_VERSION${NC}"
    else
        echo -e "${RED}Format de version invalide. Utilisation de la version par défaut $DEFAULT_VERSION.${NC}"
        ISO_VERSION="$DEFAULT_VERSION"
    fi
fi

# ------------------------------
# Configuration utilisateur (basée sur la version choisie)
# ------------------------------
WORK_DIR="$HOME/neurhomia-iso"                # Répertoire de travail
ISO_FILENAME="ubuntu-${ISO_VERSION}-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/${ISO_VERSION%.*}/ubuntu-${ISO_VERSION}-live-server-amd64.iso"
EXTRACT_DIR="$WORK_DIR/extracted"              # Contenu de l'ISO extrait
AUTOINSTALL_DIR="$WORK_DIR/autoinstall"        # Dossier autoinstall
OUTPUT_ISO="$WORK_DIR/neurhomia-server-${ISO_VERSION}-auto.iso"
LABEL="NEURHOMIA_SRV"                          # Étiquette du volume ISO

# URL du script de premier démarrage (à personnaliser !)
FIRSTBOOT_SCRIPT_URL="https://raw.githubusercontent.com/moreau66/neurhomia/main/firstboot-config.sh"

# Mot de passe par défaut (sera hashé automatiquement)
DEFAULT_PASSWORD="neurhomia"

# ------------------------------
# Vérification des dépendances
# ------------------------------
echo -e "${YELLOW}Vérification des dépendances...${NC}"
command -v wget >/dev/null 2>&1 || { echo -e "${RED}wget est requis. Installez-le avec : sudo apt install wget${NC}"; exit 1; }
command -v 7z >/dev/null 2>&1 || { echo -e "${RED}p7zip-full est requis. Installez-le avec : sudo apt install p7zip-full${NC}"; exit 1; }
command -v mkisofs >/dev/null 2>&1 || command -v genisoimage >/dev/null 2>&1 || { echo -e "${RED}mkisofs ou genisoimage est requis. Installez-le avec : sudo apt install genisoimage${NC}"; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo -e "${RED}openssl est requis. Installez-le avec : sudo apt install openssl${NC}"; exit 1; }

# ------------------------------
# Nettoyage et création des dossiers
# ------------------------------
echo -e "${YELLOW}Préparation de l'espace de travail...${NC}"
rm -rf "$WORK_DIR"
mkdir -p "$EXTRACT_DIR" "$AUTOINSTALL_DIR"

# ------------------------------
# Téléchargement de l'ISO Ubuntu
# ------------------------------
if [ ! -f "$WORK_DIR/$ISO_FILENAME" ]; then
    echo -e "${YELLOW}Téléchargement de l'ISO Ubuntu Server ${ISO_VERSION}...${NC}"
    wget -O "$WORK_DIR/$ISO_FILENAME" "$ISO_URL"
else
    echo -e "${GREEN}L'ISO est déjà présente dans $WORK_DIR. Utilisation de la copie locale.${NC}"
fi

# ------------------------------
# Extraction de l'ISO
# ------------------------------
echo -e "${YELLOW}Extraction de l'ISO...${NC}"
7z x "$WORK_DIR/$ISO_FILENAME" -o"$EXTRACT_DIR"

# ------------------------------
# Génération du hash du mot de passe
# ------------------------------
echo -e "${YELLOW}Génération du hash du mot de passe par défaut...${NC}"
PASSWORD_HASH=$(openssl passwd -6 "$DEFAULT_PASSWORD")
echo -e "${GREEN}Hash généré : $PASSWORD_HASH${NC}"

# ------------------------------
# Création du fichier user-data
# ------------------------------
echo -e "${YELLOW}Création du fichier user-data...${NC}"
cat > "$AUTOINSTALL_DIR/user-data" <<EOF
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
  identity:
    hostname: neurhomia-box
    username: neurhomia
    password: "$PASSWORD_HASH"
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - docker.io
    - docker-compose-plugin
    - ufw
    - git
    - whiptail
    - curl
  late-commands:
    # Télécharger le script de premier boot
    - mkdir -p /target/opt/neurhomia
    - curtin in-target -- wget -O /opt/neurhomia/firstboot.sh $FIRSTBOOT_SCRIPT_URL
    - curtin in-target -- chmod +x /opt/neurhomia/firstboot.sh
    # Créer un service systemd pour exécuter le script au premier démarrage
    - |
      cat <<'SERV' > /target/etc/systemd/system/neurhomia-firstboot.service
      [Unit]
      Description=NeurHomIA First Boot Configuration
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      RemainAfterExit=yes
      ExecStart=/opt/neurhomia/firstboot.sh
      StandardOutput=journal+console

      [Install]
      WantedBy=multi-user.target
      SERV
    - curtin in-target -- systemctl enable neurhomia-firstboot.service
  shutdown: reboot
EOF

# Fichier meta-data vide (obligatoire)
touch "$AUTOINSTALL_DIR/meta-data"

# ------------------------------
# Copie du dossier autoinstall dans l'image extraite
# ------------------------------
echo -e "${YELLOW}Intégration du dossier autoinstall dans l'ISO...${NC}"
cp -r "$AUTOINSTALL_DIR" "$EXTRACT_DIR/"

# ------------------------------
# Recréation de l'ISO
# ------------------------------
echo -e "${YELLOW}Création de la nouvelle ISO...${NC}"
# On détermine la commande mkisofs disponible (mkisofs ou genisoimage)
if command -v mkisofs >/dev/null 2>&1; then
    MKISOFS_CMD="mkisofs"
else
    MKISOFS_CMD="genisoimage"
fi

$MKISOFS_CMD -D -r -V "$LABEL" -cache-inodes -J -l -b isolinux/isolinux.bin \
        -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
        -o "$OUTPUT_ISO" "$EXTRACT_DIR"

# ------------------------------
# Finalisation
# ------------------------------
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ISO générée avec succès : $OUTPUT_ISO${NC}"
echo -e "${GREEN}Vous pouvez maintenant graver cette ISO sur une clé USB (avec dd, Rufus, etc.).${NC}"
echo -e "${GREEN}Le mot de passe par défaut est : $DEFAULT_PASSWORD (à changer au premier démarrage)${NC}"
echo -e "${GREEN}========================================${NC}"
