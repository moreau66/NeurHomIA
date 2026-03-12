#!/bin/bash
# build-iso.sh – Construction de l'ISO d'installation automatique pour NeurHomIA
# Version avec détection automatique des fichiers de boot (BIOS/UEFI)
# Gravure interactive sur clé USB et conservation des anciennes ISO

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ------------------------------
# Déterminer le répertoire de travail (même avec sudo)
# ------------------------------
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    WORK_DIR="$REAL_HOME/neurhomia-iso"
else
    WORK_DIR="$HOME/neurhomia-iso"
fi

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
ISO_FILENAME="ubuntu-${ISO_VERSION}-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/${ISO_VERSION%.*}/ubuntu-${ISO_VERSION}-live-server-amd64.iso"
EXTRACT_DIR="$WORK_DIR/extracted"
AUTOINSTALL_DIR="$WORK_DIR/autoinstall"
OUTPUT_ISO="$WORK_DIR/neurhomia-server-${ISO_VERSION}-auto.iso"
LABEL="NEURHOMIA_SRV"

# URL du script de premier démarrage (à personnaliser !)
FIRSTBOOT_SCRIPT_URL="https://raw.githubusercontent.com/votre-compte/neurhomia/main/firstboot-config.sh"
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

# Sauvegarde de l'ancienne ISO si elle existe
if [ -f "$OUTPUT_ISO" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_ISO="${OUTPUT_ISO%.*}_${TIMESTAMP}.${OUTPUT_ISO##*.}"
    mv "$OUTPUT_ISO" "$BACKUP_ISO"
    echo -e "${YELLOW}Ancienne ISO sauvegardée sous : $BACKUP_ISO${NC}"
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
# Demande de gravure sur clé USB
# ------------------------------
# Fonction de gravure améliorée avec démontage automatique
burn_iso() {
    local iso_path="$1"
    echo -e "${YELLOW}Voulez-vous graver cette ISO sur une clé USB ? (o/N)${NC}"
    read -r answer
    if [[ ! "$answer" =~ ^[OoYy]$ ]]; then
        echo -e "${GREEN}Vous pourrez graver l'ISO plus tard avec la commande :${NC}"
        echo -e "  sudo dd if=$iso_path of=/dev/sdX bs=4M status=progress conv=fsync"
        return
    fi

    # Vérifier les droits sudo
    if ! sudo -v &>/dev/null; then
        echo -e "${RED}Vous devez avoir les droits sudo pour graver une clé USB.${NC}"
        return
    fi

    while true; do
        echo -e "${YELLOW}Recherche des périphériques USB...${NC}"
        # Liste des périphériques de type disk, avec transport USB, et taille < 64 Go
        mapfile -t devices < <(lsblk -d -o NAME,SIZE,TYPE,TRAN -n -l 2>/dev/null | grep -E 'disk.*usb' | awk '$2 ~ /^[0-9.]+[GM]?/ { if ($2 ~ /G/ && $2+0 < 64) print; else if ($2 ~ /M/ && $2+0 < 64000) print }')
        # Si pas de périphérique USB détecté, élargir à tout disk de taille < 64G
        if [ ${#devices[@]} -eq 0 ]; then
            mapfile -t devices < <(lsblk -d -o NAME,SIZE,TYPE -n -l 2>/dev/null | grep disk | awk '$2 ~ /^[0-9.]+[GM]?/ { if ($2 ~ /G/ && $2+0 < 64) print; else if ($2 ~ /M/ && $2+0 < 64000) print }')
        fi

        if [ ${#devices[@]} -eq 0 ]; then
            echo -e "${RED}Aucune clé USB détectée.${NC}"
            echo -e "${YELLOW}Insérez une clé USB, puis appuyez sur Entrée pour réessayer, ou tapez 'q' pour quitter.${NC}"
            read -r retry
            if [[ "$retry" == "q" ]]; then
                echo -e "${GREEN}Gravure annulée.${NC}"
                return
            fi
            continue
        fi

        # Afficher les périphériques trouvés
        echo -e "${GREEN}Périphériques détectés :${NC}"
        local i=1
        for dev in "${devices[@]}"; do
            # Extraire le nom et la taille
            name=$(echo "$dev" | awk '{print $1}')
            size=$(echo "$dev" | awk '{print $2}')
            echo "  $i) /dev/$name ($size)"
            ((i++))
        done
        echo -e "${YELLOW}Choisissez le numéro du périphérique à utiliser, ou 'q' pour annuler :${NC}"
        read -r choice
        if [[ "$choice" == "q" ]]; then
            echo -e "${GREEN}Gravure annulée.${NC}"
            return
        fi
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#devices[@]} ]; then
            echo -e "${RED}Choix invalide.${NC}"
            continue
        fi

        selected_dev="/dev/$(echo "${devices[$((choice-1))]}" | awk '{print $1}')"

        # Vérifier que le périphérique existe toujours
        if [ ! -e "$selected_dev" ]; then
            echo -e "${RED}Le périphérique $selected_dev n'existe plus. Il a peut-être été retiré.${NC}"
            continue
        fi

        # Vérifier si le périphérique a des partitions montées
        mounted_partitions=$(lsblk -no NAME,MOUNTPOINT "$selected_dev" 2>/dev/null | awk '$2 {print $1, $2}')
        if [ -n "$mounted_partitions" ]; then
            echo -e "${RED}Le périphérique $selected_dev a des partitions montées :${NC}"
            echo "$mounted_partitions"
            echo -e "${YELLOW}Voulez-vous démonter automatiquement ces partitions ? (o/N)${NC}"
            read -r unmount_answer
            if [[ "$unmount_answer" =~ ^[OoYy]$ ]]; then
                # Récupérer la liste des points de montage à démonter
                mount_points=$(echo "$mounted_partitions" | awk '{print $2}')
                for mp in $mount_points; do
                    echo -e "Démontage de $mp..."
                    sudo umount "$mp" || {
                        echo -e "${RED}Échec du démontage de $mp. Vérifiez que le point de montage n'est pas utilisé.${NC}"
                        continue 2  # retourne au début de la boucle while
                    }
                done
                # Après démontage, on continue vers la confirmation
            else
                echo -e "${RED}Veuillez démonter manuellement les partitions avant de continuer.${NC}"
                continue
            fi
        fi

        echo -e "${RED}Attention : vous allez écraser toutes les données sur $selected_dev.${NC}"
        echo -e "${YELLOW}Êtes-vous sûr de vouloir continuer ? (oui/NON)${NC}"
        read -r confirm
        if [[ ! "$confirm" =~ ^[OoYy]([Ee][Ss]?)?$ ]]; then
            echo -e "${GREEN}Gravure annulée.${NC}"
            return
        fi

        # Exécuter la gravure
        echo -e "${YELLOW}Gravure de l'ISO sur $selected_dev...${NC}"
        sudo dd if="$iso_path" of="$selected_dev" bs=4M status=progress conv=fsync
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Gravure terminée avec succès !${NC}"
            echo -e "Vous pouvez maintenant utiliser cette clé pour démarrer votre mini-PC."
        else
            echo -e "${RED}Erreur lors de la gravure. Vérifiez que vous avez les droits sudo et que le périphérique n'est pas monté.${NC}"
        fi
        break
    done
}
# Appel de la fonction de gravure
burn_iso "$OUTPUT_ISO"

# ------------------------------
# Finalisation
# ------------------------------
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Processus terminé.${NC}"
echo -e "${GREEN}ISO disponible : $OUTPUT_ISO${NC}"
echo -e "${GREEN}========================================${NC}"
