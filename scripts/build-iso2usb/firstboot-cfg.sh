#!/bin/bash
# firstboot-cfg.sh – Configuration interactive de NeurHomIA au premier démarrage
# Téléchargé automatiquement par l'autoinstall Ubuntu
# Version : 2.0.0

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root." >&2
    exit 1
fi

# --- Détection dynamique de l'utilisateur ---
# L'utilisateur créé par autoinstall (pas root)
TARGET_USER=$(grep -E "^[^:]+:[^:]+:1000:" /etc/passwd | cut -d: -f1 2>/dev/null || echo "neurhomia")
if [ -z "$TARGET_USER" ]; then
    TARGET_USER="neurhomia"
fi
TARGET_HOME=$(eval echo "~$TARGET_USER")

GITHUB_REPO="moreau66/NeurHomIA"
GITHUB_BRANCH="main"

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
         --msgbox "Bienvenue dans l'assistant de configuration de votre serveur NeurHomIA.\n\nUtilisateur détecté : $TARGET_USER\n\nNous allons configurer le réseau, la sécurité et les services essentiels." 14 60

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
if (whiptail --yesno "Le mot de passe par défaut pour l'utilisateur '$TARGET_USER' a été défini lors de la création de l'ISO.\n\nPour des raisons de sécurité, il est fortement recommandé de le changer.\n\nVoulez-vous le modifier maintenant ?" 12 60); then
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
            echo "$TARGET_USER:$NEW_PASS" | chpasswd
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
# Créer le fichier de durcissement SSH
cat > /etc/ssh/sshd_config.d/99-neurhomia.conf <<EOF
PermitRootLogin no
PasswordAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowUsers $TARGET_USER
EOF

if (whiptail --yesno "Voulez-vous ajouter une clé publique SSH pour l'utilisateur $TARGET_USER ?" 8 60); then
    SSH_KEY=$(whiptail --inputbox "Collez votre clé publique (ssh-rsa AAAA...)" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$SSH_KEY" ]; then
        mkdir -p "$TARGET_HOME/.ssh"
        echo "$SSH_KEY" >> "$TARGET_HOME/.ssh/authorized_keys"
        chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.ssh"
        chmod 700 "$TARGET_HOME/.ssh"
        chmod 600 "$TARGET_HOME/.ssh/authorized_keys"
        sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config.d/99-neurhomia.conf
        systemctl restart sshd
        whiptail --msgbox "Clé SSH ajoutée. L'authentification par mot de passe a été désactivée." 8 60
    fi
else
    systemctl restart sshd
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
#   FAIL2BAN
# ============================================
whiptail --infobox "Configuration de fail2ban..." 8 40
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
EOF
systemctl enable fail2ban
systemctl restart fail2ban

# ============================================
#   MISES À JOUR AUTOMATIQUES
# ============================================
whiptail --infobox "Configuration des mises à jour automatiques..." 8 50
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable unattended-upgrades

# ============================================
#   INSTALLATION DE NEURHOMIA (DOCKER COMPOSE)
# ============================================
whiptail --infobox "Clonage du dépôt NeurHomIA et démarrage des conteneurs..." 8 60
cd /opt
if [ -d "neurhomia" ]; then
    rm -rf neurhomia
fi
git clone "https://github.com/${GITHUB_REPO}.git" neurhomia
cd neurhomia
chown -R "$TARGET_USER:$TARGET_USER" /opt/neurhomia

PROFILES=$(whiptail --checklist "Sélectionnez les profils à activer (ESPACE pour sélectionner) :" 20 60 8 \
    "zigbee2mqtt" "Pont Zigbee" OFF \
    "astral2mqtt" "Lever/coucher soleil" OFF \
    "docker2mqtt" "Surveillance Docker" OFF \
    "xmqtt2mqtt" "Pont MQTT générique" OFF \
    "meteo" "Station météo" OFF \
    "backup" "Sauvegardes automatiques" OFF \
    3>&1 1>&2 2>&3)

PROFILES_CLEAN=$(echo $PROFILES | sed 's/"//g')
PROFILES_ARGS=""
if [ -n "$PROFILES_CLEAN" ]; then
    for p in $PROFILES_CLEAN; do
        PROFILES_ARGS="$PROFILES_ARGS --profile $p"
    done
fi

# Créer le fichier .env
MQTT_PASS=$(whiptail --inputbox "Mot de passe MQTT (utilisateur: admin)" 8 60 "changeme" 3>&1 1>&2 2>&3)
MQTT_PASS=${MQTT_PASS:-changeme}

cat > /opt/neurhomia/.env <<EOF
# NeurHomIA - Configuration
NODE_ENV=production
APP_PORT=8080
MQTT_BROKER_URL=mqtt://mosquitto:1883
MQTT_USERNAME=admin
MQTT_PASSWORD=$MQTT_PASS
MQTT_PORT=1883
MQTT_WS_PORT=9001
TZ=Europe/Paris
EOF
chown "$TARGET_USER:$TARGET_USER" /opt/neurhomia/.env

# Créer le service systemd
cat > /etc/systemd/system/neurhomia.service <<EOF
[Unit]
Description=NeurHomIA - Plateforme Domotique Intelligente
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=$TARGET_USER
WorkingDirectory=/opt/neurhomia
ExecStartPre=/usr/bin/docker compose $PROFILES_ARGS pull
ExecStart=/usr/bin/docker compose $PROFILES_ARGS up -d
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose restart
Restart=on-failure
RestartSec=10
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF
systemctl enable neurhomia.service

# Démarrer les conteneurs
docker compose $PROFILES_ARGS up -d

# ============================================
#   COMMANDES UTILITAIRES
# ============================================
cat > /usr/local/bin/neurhomia-status <<'CMDEOF'
#!/bin/bash
echo "=== NeurHomIA - État des services ==="
cd /opt/neurhomia && docker compose ps
echo ""
echo "=== Utilisation disque ==="
df -h / | tail -1
echo ""
echo "=== Mémoire ==="
free -h | head -2
CMDEOF
chmod +x /usr/local/bin/neurhomia-status

cat > /usr/local/bin/neurhomia-logs <<'CMDEOF'
#!/bin/bash
cd /opt/neurhomia && docker compose logs -f --tail=50 "$@"
CMDEOF
chmod +x /usr/local/bin/neurhomia-logs

cat > /usr/local/bin/neurhomia-restart <<'CMDEOF'
#!/bin/bash
echo "Redémarrage de NeurHomIA..."
cd /opt/neurhomia && docker compose restart
echo "✅ Redémarré"
CMDEOF
chmod +x /usr/local/bin/neurhomia-restart

cat > /usr/local/bin/neurhomia-update <<'CMDEOF'
#!/bin/bash
echo "=== Mise à jour de NeurHomIA ==="
cd /opt/neurhomia
echo "[1/3] Récupération des mises à jour..."
git pull origin main
echo "[2/3] Mise à jour des images Docker..."
docker compose pull
echo "[3/3] Redémarrage..."
docker compose up -d
echo "✅ NeurHomIA mis à jour"
CMDEOF
chmod +x /usr/local/bin/neurhomia-update

# ============================================
#   MESSAGE MOTD
# ============================================
CURRENT_IP=$(get_ip)
cat > /etc/motd <<EOF

╔═══════════════════════════════════════════════╗
║           🏠 NeurHomIA Server                 ║
║                                               ║
║  Dashboard : http://${CURRENT_IP:-IP_SERVEUR}:8080           ║
║  MQTT      : ${CURRENT_IP:-IP_SERVEUR}:1883                  ║
║                                               ║
║  Commandes utiles :                           ║
║    neurhomia-status   → état des services     ║
║    neurhomia-logs     → journaux en direct    ║
║    neurhomia-restart  → redémarrer            ║
║    neurhomia-update   → mettre à jour         ║
╚═══════════════════════════════════════════════╝

EOF

# ============================================
#   FINALISATION
# ============================================
whiptail --title "Terminé" \
         --msgbox "Configuration terminée !\n\nUtilisateur : $TARGET_USER\nAdresse IP : $CURRENT_IP\n\nAccédez au dashboard : http://$CURRENT_IP:8080\n\nLe service de premier démarrage va maintenant se désactiver." 14 60

systemctl disable neurhomia-firstboot.service
rm -f /etc/systemd/system/neurhomia-firstboot.service
systemctl daemon-reload

exit 0
