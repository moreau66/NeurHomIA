#!/bin/bash
# build-iso.sh – Script de construction de l'ISO Ubuntu Server personnalisée pour NeurHomIA
# Usage : ./build-iso.sh

set -e  # Arrêt en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Variables ---
WORK_DIR="$HOME/neurhomia-iso"
ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
ISO_FILENAME="ubuntu-24.04-live-server-amd64.iso"
EXTRACT_DIR="$WORK_DIR/extracted"
AUTOINSTALL_DIR="$WORK_DIR/autoinstall"
OUTPUT_ISO="$WORK_DIR/neurhomia-server-auto.iso"
ISO_LABEL="NEURHOMIA_SRV"

# --- Vérification des dépendances ---
echo -e "${YELLOW}[1/7] Vérification des dépendances...${NC}"
for cmd in wget 7z mkisofs; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}Erreur : $cmd n'est pas installé.${NC}"
        echo "Installez-le avec : sudo apt install p7zip-full genisoimage wget"
        exit 1
    fi
done

# --- Création des dossiers de travail ---
echo -e "${YELLOW}[2/7] Création des dossiers de travail...${NC}"
mkdir -p "$EXTRACT_DIR" "$AUTOINSTALL_DIR"

# --- Téléchargement de l'ISO Ubuntu ---
echo -e "${YELLOW}[3/7] Téléchargement de l'ISO Ubuntu Server...${NC}"
if [ ! -f "$WORK_DIR/$ISO_FILENAME" ]; then
    wget -O "$WORK_DIR/$ISO_FILENAME" "$ISO_URL"
else
    echo "Fichier déjà présent, téléchargement ignoré."
fi

# --- Extraction de l'ISO ---
echo -e "${YELLOW}[4/7] Extraction de l'ISO...${NC}"
7z x "$WORK_DIR/$ISO_FILENAME" -o"$EXTRACT_DIR" -y >/dev/null

# --- Génération du fichier user-data avec le hash du mot de passe "neurhomia" ---
echo -e "${YELLOW}[5/7] Création du fichier user-data...${NC}"
PASSWORD_HASH=$(openssl passwd -6 "neurhomia")
if [ $? -ne 0 ]; then
    echo -e "${RED}Erreur : impossible de générer le hash du mot de passe.${NC}"
    exit 1
fi

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
    # Télécharger le script de premier boot (ajustez l'URL)
    - mkdir -p /target/opt/neurhomia
    - curtin in-target -- wget -O /opt/neurhomia/firstboot.sh https://raw.githubusercontent.com/votre-compte/neurhomia/main/firstboot-config.sh
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

# Création du fichier meta-data vide
touch "$AUTOINSTALL_DIR/meta-data"

# --- Copie du dossier autoinstall dans l'image extraite ---
echo -e "${YELLOW}[6/7] Copie de l'autoinstall dans l'image extraite...${NC}"
cp -r "$AUTOINSTALL_DIR" "$EXTRACT_DIR/"

# --- Recréation de la nouvelle ISO ---
echo -e "${YELLOW}[7/7] Création de la nouvelle ISO...${NC}"
mkisofs -D -r -V "$ISO_LABEL" -cache-inodes -J -l -b isolinux/isolinux.bin \
        -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
        -o "$OUTPUT_ISO" "$EXTRACT_DIR"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}ISO générée avec succès : $OUTPUT_ISO${NC}"
    echo "Vous pouvez maintenant graver cette ISO sur une clé USB (avec dd, Rufus, etc.)."
else
    echo -e "${RED}Erreur lors de la création de l'ISO.${NC}"
    exit 1
fi