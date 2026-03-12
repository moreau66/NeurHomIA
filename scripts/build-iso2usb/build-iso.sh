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

    # Calculer un hash de vérification (SHA256 des 10 premiers Mo de l'ISO)
    echo -e "${YELLOW}Calcul de l'empreinte de vérification de l'ISO...${NC}"
    local iso_hash=$(dd if="$iso_path" bs=1M count=10 2>/dev/null | sha256sum | awk '{print $1}')
    echo -e "Empreinte (10 premiers Mo) : $iso_hash"

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

        # Vérifier la taille de la clé par rapport à l'ISO (utilisation de lsblk)
        iso_size=$(stat -c%s "$iso_path")
        # Récupérer la taille du périphérique en bytes avec lsblk
        dev_size=$(lsblk -bno SIZE "$selected_dev" 2>/dev/null | head -n1)
        if [ -z "$dev_size" ]; then
            echo -e "${RED}Impossible de déterminer la taille du périphérique $selected_dev.${NC}"
            continue
        fi
        if [ "$iso_size" -gt "$dev_size" ]; then
            echo -e "${RED}L'ISO ($(numfmt --to=iec $iso_size)) est plus grande que la clé ($(numfmt --to=iec $dev_size)). Impossible de graver.${NC}"
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
                mount_points=$(echo "$mounted_partitions" | awk '{print $2}')
                for mp in $mount_points; do
                    echo -e "Démontage de $mp..."
                    sudo umount "$mp" || {
                        echo -e "${RED}Échec du démontage de $mp. Vérifiez que le point de montage n'est pas utilisé.${NC}"
                        continue 2
                    }
                done
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

        if [ $? -ne 0 ]; then
            echo -e "${RED}Erreur lors de la gravure. Vérifiez que vous avez les droits sudo et que le périphérique n'est pas monté.${NC}"
            continue
        fi

        # Vider les caches et forcer l'écriture
        sync
        sudo blockdev --flushbufs "$selected_dev" 2>/dev/null || true  # Ignorer si échec

        # Vérification par hash (10 premiers Mo)
        echo -e "${YELLOW}Vérification de l'écriture par comparaison d'empreinte...${NC}"
        local dev_hash=$(sudo dd if="$selected_dev" bs=1M count=10 2>/dev/null | sha256sum | awk '{print $1}')
        if [ "$dev_hash" = "$iso_hash" ]; then
            echo -e "${GREEN}Vérification réussie : l'empreinte correspond. La gravure est valide.${NC}"
            echo -e "${GREEN}Gravure terminée avec succès !${NC}"
            echo -e "Vous pouvez maintenant utiliser cette clé pour démarrer votre mini-PC."
        else
            echo -e "${RED}Échec de la vérification : l'empreinte ne correspond pas.${NC}"
            echo -e "  ISO hash   : $iso_hash"
            echo -e "  Clé hash   : $dev_hash"
            echo -e "${YELLOW}Voulez-vous réessayer la gravure sur le même périphérique ? (o/N)${NC}"
            read -r retry_write
            if [[ "$retry_write" =~ ^[OoYy]$ ]]; then
                continue
            else
                echo -e "${GREEN}Gravure annulée.${NC}"
            fi
        fi
        break
    done
}
