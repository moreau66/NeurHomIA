#!/bin/bash
# firstboot-config.sh – Configuration interactive de NeurHomIA au premier démarrage
# Version avec changement forcé du mot de passe par défaut

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root." >&2
    exit 1
fi

# Fonctions utilitaires
get_ip() {
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -n1
}

detect_interfaces() {
    ls /sys/class/net/ | grep -v lo
}

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
        if ((o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255)); then
            return 0
        fi
    fi
    return 1
}

# ============================================
#   BIENVENUE
# ============================================
whiptail --title "NeurHomIA - Configuration initiale" \
         --msgbox "Bienvenue dans l'assistant de configuration de votre serveur NeurHomIA.\n\nNous allons configurer le réseau, la sécurité et les services essentiels." 12 60

# ============================================
#   CONFIGURATION RÉSEAU
# ============================================
INTERFACES=$(detect_interfaces)
if [ -z "$INTERFACES" ]; then
    whiptail --msgbox "Aucune interface réseau filaire détectée. Vérifiez votre matériel." 8 60
    exit 1
fi

interface_list=()
for iface in $INTERFACES; do
    interface_list+=("$iface" "")
done

SELECTED_IFACE=$(whiptail --menu "Choisissez l'interface à configurer :" 15 60 4 "${interface_list[@]}" 3>&1 1>&2 2>&3)
if [ -z "$SELECTED_IFACE" ]; then
    whiptail --msgbox "Aucune interface sélectionnée. Le script va continuer avec les paramètres par défaut (DHCP)." 8 60
else
    if (whiptail --yesno "Utiliser DHCP pour $SELECTED_IFACE ?" 8 50); then
        cat > /etc/netplan/99-neurhomia.yaml <<EOF
network:
  version: 2
  ethernets:
    $SELECTED_IFACE:
      dhcp4: true
      optional: true
EOF
    else
        STATIC_IP=$(whiptail --inputbox "Entrez l'adresse IP avec CIDR (ex: 192.168.1.100/24)" 8 60 3>&1 1>&2 2>&3)
        GATEWAY=$(whiptail --inputbox "Entrez l'adresse de la passerelle par défaut" 8 60 3>&1 1>&2 2>&3)
        DNS=$(whiptail --inputbox "Entrez les serveurs DNS (séparés par des virgules)" 8 60 "8.8.8.8,1.1.1.1" 3>&1 1>&2 2>&3)

        if ! validate_ip "${STATIC_IP%%/*}"; then
            whiptail --msgbox "Adresse IP invalide. Abandon." 8 60
            exit 1
        fi

        cat > /etc/netplan/99-neurhomia.yaml <<EOF
network:
  version: 2
  ethernets:
    $SELECTED_IFACE:
      addresses:
        - $STATIC_IP
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [$(echo $DNS | sed 's/,/ /g')]
EOF
    fi

    netplan apply
    sleep 3
    CURRENT_IP=$(get_ip)
    whiptail --msgbox "Configuration réseau appliquée. Adresse IP : $CURRENT_IP" 8 60
fi

# ============================================
#   CHANGEMENT DU MOT DE PASSE PAR DÉFAUT
# ============================================
if (whiptail --yesno "Le mot de passe par défaut pour l'utilisateur 'neurhomia' est 'neurhomia'.\n\nPour des raisons de sécurité, il est fortement recommandé de le changer.\n\nVoulez-vous le modifier maintenant ?" 12 60); then
    while true; do
        NEW_PASS=$(whiptail --passwordbox "Nouveau mot de passe :" 8 60 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            whiptail --msgbox "Changement de mot de passe annulé. Vous pourrez le faire plus tard avec la commande 'passwd'." 8 60
            break
        fi
        NEW_PASS2=$(whiptail --passwordbox "Confirmation :" 8 60 3>&1 1>&2 2>&3)
        if [ "$NEW_PASS" != "$NEW_PASS2" ]; then
            whiptail --msgbox "Les mots de passe ne correspondent pas. Veuillez réessayer." 8 60
        elif [ -z "$NEW_PASS" ]; then
            whiptail --msgbox "Le mot de passe ne peut pas être vide." 8 60
        else
            echo "neurhomia:$NEW_PASS" | chpasswd
            if [ $? -eq 0 ]; then
                whiptail --msgbox "Mot de passe changé avec succès." 8 60
                break
            else
                whiptail --msgbox "Erreur lors du changement de mot de passe. Veuillez réessayer." 8 60
            fi
        fi
    done
else
    whiptail --msgbox "Attention : vous conservez le mot de passe par défaut. Pensez à le changer rapidement après la configuration." 8 60
fi

# ============================================
#   CONFIGURATION SSH
# ============================================
if (whiptail --yesno "Voulez-vous ajouter une clé publique SSH pour l'utilisateur neurhomia ?" 8 60); then
    SSH_KEY=$(whiptail --inputbox "Collez votre clé publique (ssh-rsa AAAA...)" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$SSH_KEY" ]; then
        mkdir -p /home/neurhomia/.ssh
        echo "$SSH_KEY" >> /home/neurhomia/.ssh/authorized_keys
        chown -R neurhomia:neurhomia /home/neurhomia/.ssh
        chmod 700 /home/neurhomia/.ssh
        chmod 600 /home/neurhomia/.ssh/authorized_keys
        sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config.d/99-neurhomia.conf
        systemctl restart sshd
        whiptail --msgbox "Clé SSH ajoutée. L'authentification par mot de passe a été désactivée." 8 60
    fi
fi

# ============================================
#   PARE-FEU UFW
# ============================================
whiptail --infobox "Configuration du pare-feu UFW..." 8 40
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 1883/tcp comment 'MQTT'
ufw allow 8080/tcp comment 'NeurHomIA'
ufw allow 9001/tcp comment 'MQTT WebSocket'
whiptail --msgbox "Pare-feu UFW activé. Règles par défaut appliquées." 8 60

# ============================================
#   INSTALLATION DE NEURHOMIA (DOCKER COMPOSE)
# ============================================
whiptail --infobox "Clonage du dépôt NeurHomIA et démarrage des conteneurs..." 8 60
cd /opt
if [ -d "neurhomia" ]; then
    rm -rf neurhomia
fi
git clone https://github.com/cce66/NeurHomIA.git neurhomia
cd neurhomia

PROFILES=$(whiptail --checklist "Sélectionnez les profils à activer (ESPACE pour sélectionner) :" 15 50 4 \
    "zigbee2mqtt" "Pont Zigbee" OFF \
    "meteo" "Station météo" OFF \
    "backup" "Sauvegardes" OFF \
    3>&1 1>&2 2>&3)

PROFILES_CLEAN=$(echo $PROFILES | sed 's/"//g')
if [ -n "$PROFILES_CLEAN" ]; then
    PROFILES_ARGS="--profile $(echo $PROFILES_CLEAN | sed 's/ / --profile /g')"
else
    PROFILES_ARGS=""
fi

docker compose $PROFILES_ARGS up -d

# ============================================
#   FINALISATION
# ============================================
CURRENT_IP=$(get_ip)
whiptail --title "Terminé" \
         --msgbox "Configuration terminée !\n\nAdresse IP : $CURRENT_IP\n\nAccédez au dashboard : http://$CURRENT_IP:8080\n\nLe service de premier démarrage va maintenant se désactiver." 12 60

systemctl disable neurhomia-firstboot.service
rm /etc/systemd/system/neurhomia-firstboot.service
systemctl daemon-reload

exit 0