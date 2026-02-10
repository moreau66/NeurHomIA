# Guide d'Installation 🚀

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide détaille l'installation complète de NeurHomIA, un système de gestion d'automatisation domestique avec support des widgets et pages dynamiques.

---

## 📑 Table des matières

- [Prérequis](#-prérequis)
- [Installation rapide avec Docker](#-installation-rapide-avec-docker-recommandée)
- [Installation manuelle](#-installation-manuelle-développement)
- [Configuration Docker](#-configuration-docker-complète)
- [Configuration MQTT](#-configuration-mqtt)
- [Intégration Home Assistant](#-intégration-avec-home-assistant)
- [Configuration des microservices](#-configuration-des-microservices)
- [Développement](#-développement)
- [Production et sécurité](#-production-et-sécurité)
- [Maintenance et monitoring](#-maintenance-et-monitoring)
- [Dépannage](#-dépannage)
- [Ressources](#-ressources)
- [Voir aussi](#-voir-aussi)

---

## 📋 Prérequis

- **Docker** >= 20.10 et **Docker Compose** >= 2.0 (recommandé)
- **Node.js** >= 18.0 et **npm** >= 8.0 (pour le développement)
- **Git** pour cloner le repository
- **Système** : Linux, macOS ou Windows avec WSL2

## 🚀 Installation rapide avec Docker (Recommandée)

### 1. Cloner le projet

```bash
git clone https://github.com/votre-username/neurhomia.git
cd neurhomia
```

### 2. Configuration des variables d'environnement

```bash
cp .env.example .env
```

Éditez le fichier `.env` selon vos besoins :

```bash
# Configuration MQTT
MQTT_BROKER_URL=mqtt://mosquitto:1883
MQTT_USERNAME=admin
MQTT_PASSWORD=changeme

# Configuration de l'application
APP_PORT=8080
NODE_ENV=production

# Configuration des microservices
ASTRAL2MQTT_ENABLED=true
DOCKER2MQTT_ENABLED=true
METEO2MQTT_ENABLED=true
```

### 3. Démarrer tous les services

```bash
docker-compose up -d
```

### 4. Vérifier l'installation

- **Interface Web** : http://localhost:8080
- **MQTT Broker** : mqtt://localhost:1883
- **Logs** : `docker-compose logs -f`

## 🔧 Installation manuelle (Développement)

### 1. Prérequis système

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm git mosquitto mosquitto-clients

# macOS avec Homebrew
brew install node npm git mosquitto

# Windows (utiliser WSL2)
```

### 2. Installation des dépendances

```bash
git clone https://github.com/votre-username/neurhomia.git
cd neurhomia
npm install
```

### 3. Configuration locale

```bash
cp .env.example .env.local
```

### 4. Démarrer le serveur de développement

```bash
npm run dev
```

L'application sera disponible sur http://localhost:8080

## 🐳 Configuration Docker Complète

### Structure des services

Le fichier `docker-compose.yml` inclut :

- **app** : Interface web React/Vite
- **mosquitto** : Broker MQTT
- **meteo2mqtt** : Microservice météo (optionnel)
- **astral2mqtt** : Microservice astronomique (optionnel)
- **zigbee2mqtt** : Interface Zigbee (optionnel)

### Variables d'environnement essentielles

| Variable          | Description            | Défaut                  |
| ----------------- | ---------------------- | ----------------------- |
| `MQTT_BROKER_URL` | URL du broker MQTT     | `mqtt://mosquitto:1883` |
| `MQTT_USERNAME`   | Nom d'utilisateur MQTT | `admin`                 |
| `MQTT_PASSWORD`   | Mot de passe MQTT      | `changeme`              |
| `APP_PORT`        | Port de l'application  | `8080`                  |
| `NODE_ENV`        | Environnement          | `production`            |

---

## ⚡ Installation du Local Engine (Optionnel)

Le **Local Engine** est un backend Node.js alternatif pour l'exécution des scénarios d'automatisation. Il peut fonctionner en parallèle ou en fallback du Scheduler Python.

### Prérequis

- Node.js 18+ (20 recommandé)
- Accès au broker MQTT

### Installation

```bash
cd backend/local-engine
npm install
```

### Configuration

```bash
cp .env.example .env
```

Éditez le fichier `.env` :

```bash
# MQTT
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883

# API
HTTP_PORT=3001

# Astronomie (pour triggers lever/coucher soleil)
LATITUDE=48.8566
LONGITUDE=2.3522
```

### Démarrage

```bash
# Développement
npm run dev

# Production
npm run build && npm start
```

### Vérification

```bash
curl http://localhost:3001/api/health
# {"status":"healthy","service":"local-engine",...}
```

📚 **Documentation complète** : [Guide du Local Engine](guide-local-engine.md)

---

### Commandes Docker utiles

```bash
# Démarrer tous les services
docker-compose up -d

# Voir les logs
docker-compose logs -f [service_name]

# Redémarrer un service
docker-compose restart [service_name]

# Mettre à jour les images
docker-compose pull && docker-compose up -d

# Arrêter tous les services
docker-compose down

# Supprimer les volumes (attention : perte de données)
docker-compose down -v
```

## 🔌 Configuration MQTT

### Broker Mosquitto

Le fichier `mosquitto/mosquitto.conf` est automatiquement configuré avec :

```conf
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd

# Configuration pour les widgets dynamiques
topic read homeassistant/+/+/config
topic write homeassistant/+/+/set
topic read +/widget/discovery
```

### Créer des utilisateurs MQTT

```bash
# Entrer dans le container
docker-compose exec mosquitto sh

# Créer un utilisateur
mosquitto_passwd -c /mosquitto/config/passwd admin

# Redémarrer le service
docker-compose restart mosquitto
```

### Topics MQTT importants

- `homeassistant/+/+/config` : Découverte Home Assistant
- `+/widget/discovery` : Découverte de widgets dynamiques
- `docker/containers/+/state` : État des containers
- `weather/+/data` : Données météorologiques
- `astral/+/data` : Données astronomiques

## 🏠 Intégration avec Home Assistant

### 1. Configuration dans Home Assistant

Ajoutez dans `configuration.yaml` :

```yaml
mqtt:
  broker: IP_DE_VOTRE_SERVEUR
  port: 1883
  username: admin
  password: changeme
  discovery: true
  discovery_prefix: homeassistant
```

### 2. Widgets automatiques

Les devices MQTT apparaîtront automatiquement dans :

- Home Assistant (via découverte MQTT)
- Le dashboard (via widgets dynamiques)

## 🔧 Configuration des microservices

### Astral2Mqtt

```bash
# Configuration dans .env
ASTRAL2MQTT_LATITUDE=48.8566
ASTRAL2MQTT_LONGITUDE=2.3522
ASTRAL2MQTT_TIMEZONE=Europe/Paris
```

### Docker2Mqtt

```bash
# Configuration dans .env
DOCKER2MQTT_SOCKET=/var/run/docker.sock
DOCKER2MQTT_DISCOVERY=true
```

### Meteo2Mqtt

```bash
# Configuration dans .env
METEO2MQTT_API_KEY=votre_cle_api_openweather
METEO2MQTT_LOCATION="Paris,FR"
METEO2MQTT_INTERVAL=300
```

## 🛠️ Développement

### Mode développement local

Le projet utilise Vite pour le développement avec hot-reload :

```bash
npm install
npm run dev  # Démarre sur http://localhost:8080
```

### Mode simulation MQTT

En développement, le système utilise un **broker MQTT simulé** intégré :

- ✅ Pas besoin d'installer Mosquitto localement
- ✅ Données de test préchargées (devices, microservices)
- ✅ Simulation temps réel (météo, astronomie, Docker)
- 📚 Documentation complète : `docs/guide-mode-simulation.md`

Pour utiliser un broker MQTT réel, configurez `.env.local` :

```bash
VITE_MQTT_BROKER_URL=ws://localhost:9001
VITE_MQTT_USERNAME=admin
VITE_MQTT_PASSWORD=changeme
```

### Guide pour contributeurs

Consultez **[DEV-GUIDE.md](DEV-GUIDE.md)** pour :

- Configuration de l'environnement de développement (VSCode)
- Structure du projet et conventions de code
- Workflow de contribution (Git, commits, Pull Requests)
- Debugging et outils de développement

## 📊 Production et sécurité

### 1. Configuration de production

```bash
# Variables de production dans .env
NODE_ENV=production
MQTT_USE_TLS=true
MQTT_CA_CERT=/certs/ca.crt
MQTT_CLIENT_CERT=/certs/client.crt
MQTT_CLIENT_KEY=/certs/client.key
```

### 2. Reverse Proxy avec Nginx

Exemple de configuration nginx :

```nginx
server {
    listen 80;
    server_name votre-domaine.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 3. SSL/TLS avec Let's Encrypt

```bash
# Installation certbot
sudo apt install certbot python3-certbot-nginx

# Obtenir un certificat
sudo certbot --nginx -d votre-domaine.com

# Renouvellement automatique
sudo crontab -e
0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔍 Maintenance et monitoring

### Logs

```bash
# Logs de l'application
docker-compose logs -f app

# Logs MQTT
docker-compose logs -f mosquitto

# Logs de tous les services
docker-compose logs -f
```

### Sauvegarde

```bash
# Sauvegarde des volumes Docker
docker run --rm -v smart-home-mqtt-dashboard_mosquitto_data:/data -v $(pwd):/backup alpine tar czf /backup/mosquitto-backup.tar.gz /data

# Sauvegarde de la configuration
cp .env backup/.env.$(date +%Y%m%d)
```

### Mise à jour

```bash
# Mise à jour du code
git pull origin main

# Reconstruction des images
docker-compose build --no-cache

# Redémarrage des services
docker-compose down && docker-compose up -d
```

## 🐛 Dépannage

### Problèmes courants

**L'interface web ne se charge pas**

```bash
# Vérifier les logs
docker-compose logs app
# Vérifier que le port 8080 est libre
netstat -tlnp | grep 8080
```

**MQTT ne fonctionne pas**

```bash
# Tester la connexion MQTT
mosquitto_pub -h localhost -p 1883 -u admin -P changeme -t test -m "hello"
mosquitto_sub -h localhost -p 1883 -u admin -P changeme -t test
```

**Les widgets dynamiques n'apparaissent pas**

```bash
# Vérifier les topics de découverte
mosquitto_sub -h localhost -p 1883 -u admin -P changeme -t "+/widget/discovery"
```

### Commandes de diagnostic

```bash
# État des containers
docker-compose ps

# Utilisation des ressources
docker stats

# Espace disque
docker system df

# Nettoyage
docker system prune -a
```

## 📚 Ressources

- [Documentation MQTT](https://mqtt.org/)
- [Home Assistant MQTT Discovery](https://www.home-assistant.io/docs/mqtt/discovery/)
- [Docker Compose Guide](https://docs.docker.com/compose/)
- [Mosquitto Configuration](https://mosquitto.org/man/mosquitto-conf-5.html)

## 🤝 Support

- **Issues** : https://github.com/votre-username/neurhomia/issues
- **Discussions** : https://github.com/votre-username/neurhomia/discussions
- **Wiki** : https://github.com/votre-username/neurhomia/wiki

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide de Développement](guide-developpement.md) - Configuration de l'environnement de développement
- [Guide de Production](guide-production.md) - Déploiement en production
- [Guide du Mode Simulation](guide-mode-simulation.md) - Tester sans infrastructure
- [Préconisations Architecture MCP](guide-preconisations.md) - Standards de développement microservices
- [Guide de Synchronisation GitHub](guide-synchronisation-github.md) - Synchronisation des fichiers
- [Structure JSON Microservices](microservice-json.md) - Format des configurations

---

_Documentation NeurHomIA_
