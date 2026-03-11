#!/bin/bash
# build-iso.sh – Construction de l'ISO Ubuntu Server personnalisée pour NeurHomIA
# Usage : ./build-iso.sh
# Compatible : Linux natif ou WSL2 sous Windows

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Variables ---
WORK_DIR="$HOME/neurhomia-iso"
ISO_VERSION="24.04.4"
ISO_URL="https://releases.ubuntu.com/${ISO_VERSION}/ubuntu-${ISO_VERSION}-live-server-amd64.iso"
ISO_FILENAME="ubuntu-${ISO_VERSION}-live-server-amd64.iso"
SHA256_URL="https://releases.ubuntu.com/${ISO_VERSION}/SHA256SUMS"
EXTRACT_DIR="$WORK_DIR/extracted"
AUTOINSTALL_DIR="$WORK_DIR/autoinstall"
OUTPUT_ISO="$WORK_DIR/neurhomia-server-auto.iso"
ISO_LABEL="NEURHOMIA_SRV"
GITHUB_REPO="moreau66/NeurHomIA"
GITHUB_BRANCH="main"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║    🏠 NeurHomIA – Construction de l'ISO       ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# --- [1/8] Vérification des dépendances ---
echo -e "${YELLOW}[1/8] Vérification des dépendances...${NC}"
MISSING=""
for cmd in wget 7z xorriso curl openssl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done

if [ -n "$MISSING" ]; then
    echo -e "${RED}Dépendances manquantes :${MISSING}${NC}"
    echo ""
    echo "Installez-les avec :"
    echo -e "  ${GREEN}sudo apt update && sudo apt install -y p7zip-full xorriso wget curl openssl${NC}"
    echo ""
    echo "Sous Windows (WSL2), ouvrez d'abord un terminal Ubuntu WSL."
    exit 1
fi

# --- [2/8] Demande du mot de passe ---
echo -e "${YELLOW}[2/8] Configuration du mot de passe utilisateur...${NC}"
echo "L'utilisateur 'neurhomia' sera créé sur le serveur."
echo ""
while true; do
    read -s -p "Mot de passe pour l'utilisateur neurhomia (min 8 car.) : " USER_PASSWORD
    echo
    if [ ${#USER_PASSWORD} -lt 8 ]; then
        echo -e "${RED}Le mot de passe doit faire au moins 8 caractères.${NC}"
        continue
    fi
    read -s -p "Confirmation : " USER_PASSWORD_CONFIRM
    echo
    if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}Les mots de passe ne correspondent pas.${NC}"
        continue
    fi
    break
done

PASSWORD_HASH=$(echo "$USER_PASSWORD" | openssl passwd -6 -stdin)
if [ $? -ne 0 ] || [ -z "$PASSWORD_HASH" ]; then
    echo -e "${RED}Erreur : impossible de générer le hash du mot de passe.${NC}"
    exit 1
fi
echo -e "${GREEN}✔ Mot de passe configuré.${NC}"

# --- [3/8] Création des dossiers de travail ---
echo -e "${YELLOW}[3/8] Création des dossiers de travail...${NC}"
mkdir -p "$EXTRACT_DIR" "$AUTOINSTALL_DIR"

# --- [4/8] Téléchargement de l'ISO Ubuntu ---
echo -e "${YELLOW}[4/8] Téléchargement de l'ISO Ubuntu Server ${ISO_VERSION}...${NC}"
if [ ! -f "$WORK_DIR/$ISO_FILENAME" ]; then
    wget -O "$WORK_DIR/$ISO_FILENAME" "$ISO_URL"
else
    echo "Fichier déjà présent, téléchargement ignoré."
fi

# --- [5/8] Vérification SHA256 ---
echo -e "${YELLOW}[5/8] Vérification de l'intégrité (SHA256)...${NC}"
if [ ! -f "$WORK_DIR/SHA256SUMS" ]; then
    wget -q -O "$WORK_DIR/SHA256SUMS" "$SHA256_URL" || true
fi

if [ -f "$WORK_DIR/SHA256SUMS" ]; then
    cd "$WORK_DIR"
    if sha256sum -c SHA256SUMS 2>/dev/null | grep -q "$ISO_FILENAME: OK"; then
        echo -e "${GREEN}✔ Intégrité vérifiée.${NC}"
    else
        echo -e "${RED}⚠ La vérification SHA256 a échoué ou le fichier n'a pas été trouvé dans SHA256SUMS.${NC}"
        read -p "Continuer quand même ? (o/n) : " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[OoYy]$ ]]; then
            exit 1
        fi
    fi
    cd - >/dev/null
else
    echo -e "${YELLOW}⚠ Impossible de télécharger SHA256SUMS, vérification ignorée.${NC}"
fi

# --- [6/8] Extraction de l'ISO ---
echo -e "${YELLOW}[6/8] Extraction de l'ISO...${NC}"
rm -rf "$EXTRACT_DIR"/*
7z x "$WORK_DIR/$ISO_FILENAME" -o"$EXTRACT_DIR" -y >/dev/null

# --- [7/8] Création du fichier user-data ---
echo -e "${YELLOW}[7/8] Création des fichiers autoinstall...${NC}"

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
    - fail2ban
    - git
    - whiptail
    - curl
    - wget
    - htop
    - net-tools
    - unattended-upgrades
    - apt-listchanges
  updates: security
  late-commands:
    # Activer Docker
    - curtin in-target -- systemctl enable docker
    - curtin in-target -- usermod -aG docker neurhomia
    # Télécharger le script de premier boot
    - mkdir -p /target/opt/neurhomia
    - curtin in-target -- wget -O /opt/neurhomia/firstboot-cfg.sh https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/scripts/build-iso2usb/firstboot-cfg.sh
    - curtin in-target -- chmod +x /opt/neurhomia/firstboot-cfg.sh
    # Créer le service systemd pour le premier démarrage
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
EOF

# Création du fichier meta-data vide
touch "$AUTOINSTALL_DIR/meta-data"

# Copie dans l'image extraite
cp -r "$AUTOINSTALL_DIR" "$EXTRACT_DIR/"

# --- [8/8] Recréation de la nouvelle ISO (UEFI + BIOS) ---
echo -e "${YELLOW}[8/8] Création de la nouvelle ISO (UEFI + BIOS)...${NC}"

# Vérifier la présence des fichiers de boot
if [ -f "$EXTRACT_DIR/boot/grub/i386-pc/eltorito.img" ]; then
    BIOS_BOOT="-b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info"
else
    BIOS_BOOT=""
    echo -e "${YELLOW}⚠ Pas de boot BIOS trouvé, l'ISO sera UEFI uniquement.${NC}"
fi

xorriso -as mkisofs \
    -r -V "$ISO_LABEL" \
    -o "$OUTPUT_ISO" \
    --sort-weight 0 / \
    --sort-weight 1 /boot \
    $BIOS_BOOT \
    --efi-boot boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b "$EXTRACT_DIR/boot/grub/efi.img" \
    "$EXTRACT_DIR" 2>/dev/null || {
    # Fallback simplifié si la commande complexe échoue
    echo -e "${YELLOW}⚠ Fallback vers une commande xorriso simplifiée...${NC}"
    xorriso -as mkisofs \
        -r -V "$ISO_LABEL" \
        -o "$OUTPUT_ISO" \
        -J -joliet-long \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin 2>/dev/null || true \
        -partition_cyl_align off \
        -partition_offset 16 \
        "$EXTRACT_DIR"
}

if [ -f "$OUTPUT_ISO" ]; then
    ISO_SIZE=$(du -h "$OUTPUT_ISO" | cut -f1)
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    ✅ ISO générée avec succès !                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Fichier : ${CYAN}$OUTPUT_ISO${NC}"
    echo -e "  Taille  : ${CYAN}$ISO_SIZE${NC}"
    echo ""
    echo -e "  ${YELLOW}Étape suivante :${NC} Gravez cette ISO sur une clé USB."
    echo ""

    # Détection WSL pour message spécifique
    if grep -qi microsoft /proc/version 2>/dev/null; then
        WIN_PATH=$(wslpath -w "$OUTPUT_ISO" 2>/dev/null || echo "$OUTPUT_ISO")
        echo -e "  ${CYAN}Sous Windows (WSL), le fichier est accessible ici :${NC}"
        echo -e "  ${GREEN}$WIN_PATH${NC}"
        echo ""
        echo "  Utilisez Rufus ou Ventoy depuis Windows pour graver la clé USB."
    else
        echo "  Exemples :"
        echo "    • Ventoy : copiez l'ISO sur la clé Ventoy"
        echo "    • dd     : sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress conv=fsync"
    fi
    echo ""
else
    echo -e "${RED}Erreur lors de la création de l'ISO.${NC}"
    exit 1
fi
