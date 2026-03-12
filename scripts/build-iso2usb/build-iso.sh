#!/bin/bash
# build-iso.sh – Construction de l'ISO d'installation automatique pour NeurHomIA
# Version avec détection automatique des fichiers de boot (BIOS/UEFI)
# Compatible avec Ubuntu 24.04+ (structure GRUB)

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
    if [[ "$USER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ISO_VERSION="$USER_VERSION"
        echo -e "${GREEN}Version sélectionnée : $ISO_VERSION${NC}"
    else
        echo -e "${RED}Format de version invalide. Utilisation de la version par défaut $DEFAULT_VERSION.${NC}"
        ISO_VERSION="$DEFAULT_VERSION"
    fi
fi

# ------------------------------
# Configuration
# ------------------------------
WORK_DIR="$HOME/neurhomia-iso"
ISO_FILENAME="ubuntu-${ISO_VERSION}-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/${ISO_VERSION%.*}/ubuntu-${ISO_VERSION}-live-server-amd64.iso"
EXTRACT_DIR="$WORK_DIR/extracted"
AUTOINSTALL_DIR="$WORK_DIR/autoinstall"
OUTPUT_ISO="$WORK_DIR/neurhomia-server-${ISO_VERSION}-auto.iso"
LABEL="NEURHOMIA_SRV"

# URL du script de premier démarrage (à personnaliser !)
FIRSTBOOT_SCRIPT_URL="https://raw.githubusercontent.com/moreau66/neurhomia/main/firstboot-config.sh"
DEFAULT_PASSWORD="neurhomia"

# ------------------------------
# Vérification des dépendances
# ------------------------------
echo -e "${YELLOW}Vérification des dépendances...${NC}"
command -v wget >/dev/null 2>&1 || { echo -e "${RED}wget est requis. Installez-le avec : sudo apt install wget${NC}"; exit 1; }
command -v 7z >/dev/null 2>&1 || { echo -e "${RED}p7zip-full est requis. Installez-le avec : sudo apt install p7zip-full${NC}"; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo -e "${RED}openssl est requis. Installez-le avec : sudo apt install openssl${NC}"; exit 1; }
command -v xorriso >/dev/null 2>&1 || { echo -e "${RED}xorriso est requis. Installez-le avec : sudo apt install xorriso${NC}"; exit 1; }

# ------------------------------
# Préparation des dossiers
# ------------------------------
echo -e "${YELLOW}Préparation de l'espace de travail...${NC}"
mkdir -p "$WORK_DIR"
rm -rf "$EXTRACT_DIR" "$AUTOINSTALL_DIR"
mkdir -p "$EXTRACT_DIR" "$AUTOINSTALL_DIR"

# ------------------------------
# Téléchargement de l'ISO (si non existante)
# ------------------------------
if [ ! -f "$WORK_DIR/$ISO_FILENAME" ]; then
    echo -e "${YELLOW}Téléchargement de l'ISO Ubuntu Server ${ISO_VERSION}...${NC}"
    wget -O "$WORK_DIR/$ISO_FILENAME" "$ISO_URL"
else
    echo -e "${GREEN}L'ISO $ISO_FILENAME existe déjà dans $WORK_DIR. Utilisation de la copie locale.${NC}"
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
echo -e "${GREEN}Hash généré.${NC}"

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
    - mkdir -p /target/opt/neurhomia
    - curtin in-target -- wget -O /opt/neurhomia/firstboot.sh $FIRSTBOOT_SCRIPT_URL
    - curtin in-target -- chmod +x /opt/neurhomia/firstboot.sh
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

touch "$AUTOINSTALL_DIR/meta-data"

# ------------------------------
# Intégration de l'autoinstall
# ------------------------------
cp -r "$AUTOINSTALL_DIR" "$EXTRACT_DIR/"

# ------------------------------
# Création de l'ISO avec xorriso (détection automatique)
# ------------------------------
echo -e "${YELLOW}Création de la nouvelle ISO (avec xorriso)...${NC}"

# Vérification du fichier de boot BIOS
if [ ! -f "$EXTRACT_DIR/boot/grub/i386-pc/eltorito.img" ]; then
    echo -e "${RED}Erreur : fichier 'boot/grub/i386-pc/eltorito.img' introuvable. Vérifiez la structure de l'ISO extraite.${NC}"
    exit 1
fi

# Détection du fichier de boot UEFI
EFI_PATH=""
if [ -f "$EXTRACT_DIR/boot/grub/efi.img" ]; then
    EFI_PATH="boot/grub/efi.img"
else
    # Recherche insensible à la casse d'un fichier .efi dans le dossier EFI/
    EFI_FILE=$(find "$EXTRACT_DIR/EFI" -type f -iname "*.efi" 2>/dev/null | head -n1)
    if [ -n "$EFI_FILE" ]; then
        EFI_PATH="${EFI_FILE#$EXTRACT_DIR/}"
        echo -e "${GREEN}Fichier EFI détecté : $EFI_PATH${NC}"
    else
        echo -e "${RED}Erreur : aucun fichier de boot EFI trouvé (ni efi.img, ni .efi).${NC}"
        exit 1
    fi
fi

# Création de l'ISO hybride (BIOS + UEFI)
xorriso -as mkisofs -r -V "$LABEL" -J -joliet-long -l \
    -iso-level 3 -no-emul-boot -boot-load-size 4 -boot-info-table \
    -b boot/grub/i386-pc/eltorito.img -c boot.catalog \
    -eltorito-alt-boot -e "$EFI_PATH" -no-emul-boot \
    -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
    -o "$OUTPUT_ISO" "$EXTRACT_DIR"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}ISO créée avec succès : $OUTPUT_ISO${NC}"
else
    echo -e "${RED}Échec de la création de l'ISO. Vérifiez les messages ci-dessus.${NC}"
    exit 1
fi

# ------------------------------
# Finalisation
# ------------------------------
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ISO générée : $OUTPUT_ISO${NC}"
echo -e "${GREEN}Mot de passe par défaut : $DEFAULT_PASSWORD${NC}"
echo -e "${GREEN}========================================${NC}"
