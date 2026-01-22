# Guide des Microservices NeurHomeIA

## Table des matières

1. [Introduction et Architecture](#introduction-et-architecture)
2. [Microservice Core : Mosquitto](#microservice-core--mosquitto)
3. [Zigbee2MQTT - Passerelle Zigbee](#zigbee2mqtt---passerelle-zigbee)
4. [Astral2MQTT - Données Astronomiques](#astral2mqtt---données-astronomiques)
5. [Docker2MQTT - Monitoring Docker](#docker2mqtt---monitoring-docker)
6. [Meteo2MQTT - Service Météorologique](#meteo2mqtt---service-météorologique)
7. [IA2MQTT / Ollama - LLM Local](#ia2mqtt--ollama---llm-local)
8. [SQLite2MQTT - Base de Données Légère](#sqlite2mqtt---base-de-données-légère)
9. [DuckDB2MQTT - Base Analytique](#duckdb2mqtt---base-analytique)
10. [Découverte et Intégration MCP](#découverte-et-intégration-mcp)
11. [Tableau Récapitulatif](#tableau-récapitulatif)
12. [Bonnes Pratiques](#bonnes-pratiques)

---

## Introduction et Architecture

### Vue d'ensemble

NeurHomeIA utilise une architecture de microservices communicant via MQTT. Chaque microservice est un conteneur Docker autonome qui :

- Publie des données sur des topics MQTT spécifiques
- Écoute des commandes sur des topics dédiés
- S'annonce via le protocole MCP (Microservice Communication Protocol)
- Peut être déployé indépendamment des autres services

### Catégorisation des Microservices

| Catégorie | Description | Exemples |
|-----------|-------------|----------|
| **Core** | Services essentiels au fonctionnement | Mosquitto (broker MQTT) |
| **Gateway** | Passerelles vers des protocoles externes | Zigbee2MQTT |
| **Data** | Services de données et stockage | SQLite2MQTT, DuckDB2MQTT |
| **Sensor** | Capteurs virtuels et données externes | Astral2MQTT, Meteo2MQTT |
| **AI** | Intelligence artificielle | Ollama/IA2MQTT |
| **System** | Monitoring et infrastructure | Docker2MQTT |

### Architecture de Communication

```
┌─────────────────────────────────────────────────────────────────────┐
│                        NeurHomeIA Frontend                          │
│                    (React + MQTT.js WebSocket)                      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ ws://localhost:9001
┌─────────────────────────────────────────────────────────────────────┐
│                     Mosquitto MQTT Broker                           │
│                    Ports: 1883 (TCP), 9001 (WS)                     │
└─────────────────────────────────────────────────────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
    ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
    │Zigbee2  │   │Astral2  │   │Meteo2   │   │Docker2  │
    │MQTT     │   │MQTT     │   │MQTT     │   │MQTT     │
    └─────────┘   └─────────┘   └─────────┘   └─────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
    zigbee2mqtt/   astral/       weather/       docker/
    bridge/#       +/data        +/current      containers/#
```

### Convention de Nommage

Les microservices suivent la convention `{source}2mqtt` :

- `{source}` : La source de données (zigbee, astral, meteo, docker, etc.)
- `2mqtt` : Indique la publication vers MQTT

### Structure d'un Template de Microservice

```typescript
interface MicroserviceTemplate {
  metadata: {
    id: string;           // Identifiant unique
    name: string;         // Nom d'affichage
    version: string;      // Version du template
    description: string;  // Description fonctionnelle
    author: string;       // Auteur/mainteneur
    category: string;     // Catégorie (microservice, core, etc.)
    tags: string[];       // Tags pour la recherche
    icon: string;         // Icône Lucide React
  };
  container: {
    image: string;                    // Image Docker
    defaultVersion: string;           // Tag par défaut
    autoStart: boolean;               // Démarrage automatique
    webUrl?: string;                  // URL de l'interface web
    ports: PortMapping[];             // Mapping des ports
    volumes: VolumeMapping[];         // Volumes persistants
    environment: EnvironmentVar[];    // Variables d'environnement
    restart: RestartPolicy;           // Politique de redémarrage
    healthcheck?: HealthCheck;        // Vérification de santé
    labels?: Record<string, string>;  // Labels Docker
  };
  mcp: {
    service_id: string;               // ID MCP du service
    topics: {
      discovery: string;              // Topic d'annonce
      data: string;                   // Topic de données
      commands: string;               // Topic de commandes
    };
    schemas?: {
      mcp: string;                    // Schéma MCP
      tools: string;                  // Schéma des outils
      resources: string;              // Schéma des ressources
    };
  };
  docker_compose: {
    depends_on: string[];             // Dépendances
    networks: string[];               // Réseaux Docker
    profiles: string[];               // Profils de déploiement
  };
  dependencies: {
    required: string[];               // Dépendances obligatoires
    optional: string[];               // Dépendances optionnelles
  };
  documentation: {
    readme_url: string;               // Lien vers README
    github_url: string;               // Dépôt GitHub
    docker_hub_url: string;           // Image Docker Hub
  };
}
```

---

## Microservice Core : Mosquitto

### Description

Eclipse Mosquitto est le broker MQTT central de NeurHomeIA. Tous les autres microservices dépendent de lui pour la communication. C'est le seul microservice de catégorie "core".

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `eclipse-mosquitto:2.0` |
| **Catégorie** | Core |
| **Ports** | 1883 (MQTT TCP), 9001 (WebSocket) |
| **Auto-démarrage** | Oui |
| **Dépendances** | Aucune |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/mosquitto/config` | `./mosquitto/config` | rw | Configuration |
| `/mosquitto/data` | `./mosquitto/data` | rw | Données persistantes |
| `/mosquitto/log` | `./mosquitto/log` | rw | Logs |

### Fichier de Configuration

```ini
# mosquitto.conf
listener 1883
listener 9001
protocol websockets

# Persistance
persistence true
persistence_location /mosquitto/data/

# Logs
log_dest file /mosquitto/log/mosquitto.log
log_type all

# Sécurité (développement)
allow_anonymous true

# Sécurité (production)
# allow_anonymous false
# password_file /mosquitto/config/passwd
```

### Topics Système

| Topic | Description |
|-------|-------------|
| `$SYS/broker/clients/connected` | Nombre de clients connectés |
| `$SYS/broker/messages/received` | Messages reçus |
| `$SYS/broker/messages/sent` | Messages envoyés |
| `$SYS/broker/uptime` | Temps de fonctionnement |
| `mcp/services/mosquitto/discovery` | Annonce MCP du service |
| `mcp/mosquitto/status` | État du broker |

### Healthcheck

```yaml
healthcheck:
  test: ["CMD", "mosquitto_pub", "-h", "localhost", "-t", "health", "-m", "check", "-q", "1"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Composant UI

**Fichier** : `src/components/containers/MosquittoContainer.tsx`

**Fonctionnalités** :
- Affichage de l'état du broker (connecté/déconnecté)
- Édition de la configuration `mosquitto.conf`
- Édition du `docker-compose.yml`
- Statistiques de connexion

---

## Zigbee2MQTT - Passerelle Zigbee

### Description

Zigbee2MQTT est une passerelle qui permet d'intégrer des appareils Zigbee (capteurs, ampoules, prises) dans le système domotique via MQTT. Il utilise un coordinateur USB Zigbee pour communiquer avec les appareils.

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `koenkk/zigbee2mqtt:latest` |
| **Catégorie** | Gateway |
| **Interface Web** | `http://localhost:8080` |
| **Port** | 8080 |
| **Dépendances** | Mosquitto |

### Variables d'Environnement

| Variable | Valeur par défaut | Obligatoire | Description |
|----------|-------------------|-------------|-------------|
| `TZ` | `Europe/Paris` | Oui | Fuseau horaire |
| `ZIGBEE2MQTT_CONFIG_MQTT_SERVER` | `mqtt://mosquitto:1883` | Oui | URL du broker MQTT |
| `ZIGBEE2MQTT_CONFIG_SERIAL_PORT` | `/dev/ttyUSB0` | Oui | Port série du coordinateur |
| `ZIGBEE2MQTT_CONFIG_PERMIT_JOIN` | `false` | Non | Autoriser l'appairage |
| `ZIGBEE2MQTT_CONFIG_FRONTEND` | `true` | Non | Activer l'interface web |
| `ZIGBEE2MQTT_CONFIG_ADVANCED_CHANNEL` | `11` | Non | Canal Zigbee (11-26) |
| `ZIGBEE2MQTT_CONFIG_ADVANCED_NETWORK_KEY` | `GENERATE` | Non | Clé réseau |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/app/data` | `./zigbee2mqtt/data` | rw | Configuration et base de données |
| `/run/udev` | `/run/udev` | ro | Accès aux périphériques |

### Device Mapping

```yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
  # ou pour un coordinateur spécifique
  - /dev/serial/by-id/usb-Texas_Instruments_CC2531_USB_Dongle-if00:/dev/ttyUSB0
```

### Topics MQTT

#### Topics du Bridge

| Topic | Direction | Description |
|-------|-----------|-------------|
| `zigbee2mqtt/bridge/state` | ← | État du bridge (`online`/`offline`) |
| `zigbee2mqtt/bridge/info` | ← | Informations détaillées |
| `zigbee2mqtt/bridge/devices` | ← | Liste des appareils |
| `zigbee2mqtt/bridge/groups` | ← | Liste des groupes |
| `zigbee2mqtt/bridge/extensions` | ← | Extensions installées |
| `zigbee2mqtt/bridge/logging` | ← | Logs en temps réel |

#### Topics de Configuration

| Topic | Direction | Description |
|-------|-----------|-------------|
| `zigbee2mqtt/bridge/request/permit_join` | → | Activer/désactiver appairage |
| `zigbee2mqtt/bridge/request/networkmap` | → | Générer carte réseau |
| `zigbee2mqtt/bridge/request/device/remove` | → | Supprimer un appareil |
| `zigbee2mqtt/bridge/request/device/rename` | → | Renommer un appareil |
| `zigbee2mqtt/bridge/response/#` | ← | Réponses aux requêtes |

#### Topics des Appareils

| Topic | Direction | Description |
|-------|-----------|-------------|
| `zigbee2mqtt/{friendly_name}` | ← | État de l'appareil |
| `zigbee2mqtt/{friendly_name}/set` | → | Commande vers l'appareil |
| `zigbee2mqtt/{friendly_name}/get` | → | Lecture d'état |
| `zigbee2mqtt/{friendly_name}/availability` | ← | Disponibilité |

### Exemples de Commandes

#### Activer l'appairage (120 secondes)

```json
// Topic: zigbee2mqtt/bridge/request/permit_join
{
  "value": true,
  "time": 120
}
```

#### Contrôler une ampoule

```json
// Topic: zigbee2mqtt/salon_lampe/set
{
  "state": "ON",
  "brightness": 200,
  "color_temp": 370
}
```

#### Générer la carte réseau

```json
// Topic: zigbee2mqtt/bridge/request/networkmap
{
  "type": "raw",
  "routes": true
}
```

### Coordinateurs Compatibles

| Coordinateur | Puce | Recommandé |
|--------------|------|------------|
| CC2531 USB Dongle | CC2531 | Non (limité) |
| CC2652RB | CC2652 | Oui |
| ConBee II | deCONZ | Oui |
| Sonoff Zigbee 3.0 USB | CC2652P | Oui |
| SLZB-06 | CC2652P | Oui |

### Composant UI

**Fichier** : `src/components/containers/Zigbee2MQTTContainer.tsx`

**Onglets** :
- **Appareils** : Liste et contrôle des appareils Zigbee
- **Bridge** : État et configuration du bridge
- **Contrôle** : Appairage et carte réseau

---

## Astral2MQTT - Données Astronomiques

### Description

Astral2MQTT calcule et publie les données astronomiques (lever/coucher du soleil, phases de la lune, etc.) basées sur la localisation géographique. Idéal pour l'automatisation basée sur les cycles naturels.

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `moreau66/astral2mqtt:latest` |
| **Catégorie** | Sensor |
| **Interface Web** | Aucune |
| **Ports** | Aucun |
| **Dépendances** | Mosquitto |

### Variables d'Environnement

| Variable | Valeur par défaut | Obligatoire | Description |
|----------|-------------------|-------------|-------------|
| `MQTT_BROKER` | `mosquitto` | Oui | Adresse du broker MQTT |
| `MQTT_PORT` | `1883` | Oui | Port du broker MQTT |
| `MQTT_TOPIC` | `astral/data` | Oui | Topic de base |
| `MQTT_CLIENT_ID` | `astral2mqtt` | Oui | Identifiant client MQTT |
| `MQTT_USER` | `` | Non | Utilisateur MQTT |
| `MQTT_PASS` | `` | Non | Mot de passe MQTT (secret) |
| `LATITUDE` | `48.8566` | Oui | Latitude (Paris par défaut) |
| `LONGITUDE` | `2.3522` | Oui | Longitude |
| `TIMEZONE` | `Europe/Paris` | Oui | Fuseau horaire |
| `ASTRAL_INTERVAL` | `3600` | Oui | Intervalle de mise à jour (secondes) |
| `DISCOVERY_ENABLED` | `true` | Non | Activer Home Assistant Discovery |
| `DISCOVERY_DEVICE_NAME` | `Astral MQTT Bridge` | Non | Nom de l'appareil |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/app/config` | `./astral2mqtt/config` | rw | Configuration |
| `/app/logs` | `./astral2mqtt/logs` | rw | Logs |

### Topics MQTT

#### Données Solaires

| Topic | Type | Description |
|-------|------|-------------|
| `astral/{location}/sunrise` | Timestamp | Heure du lever du soleil |
| `astral/{location}/sunset` | Timestamp | Heure du coucher du soleil |
| `astral/{location}/solar_noon` | Timestamp | Midi solaire |
| `astral/{location}/dawn` | Timestamp | Aube (crépuscule civil) |
| `astral/{location}/dusk` | Timestamp | Crépuscule |
| `astral/{location}/day_length` | Duration | Durée du jour |
| `astral/{location}/current_elevation` | Degrees | Élévation actuelle du soleil |
| `astral/{location}/current_azimuth` | Degrees | Azimut actuel du soleil |

#### Données Lunaires

| Topic | Type | Description |
|-------|------|-------------|
| `astral/{location}/moon_phase` | String | Phase de la lune |
| `astral/{location}/moon_illumination` | Percent | Illumination lunaire |
| `astral/{location}/moonrise` | Timestamp | Lever de lune |
| `astral/{location}/moonset` | Timestamp | Coucher de lune |
| `astral/{location}/next_full_moon` | Date | Prochaine pleine lune |
| `astral/{location}/next_new_moon` | Date | Prochaine nouvelle lune |

#### Événements Spéciaux

| Topic | Type | Description |
|-------|------|-------------|
| `astral/{location}/golden_hour_start` | Timestamp | Début de l'heure dorée |
| `astral/{location}/golden_hour_end` | Timestamp | Fin de l'heure dorée |
| `astral/{location}/blue_hour_start` | Timestamp | Début de l'heure bleue |
| `astral/{location}/blue_hour_end` | Timestamp | Fin de l'heure bleue |

### Exemple de Payload

```json
{
  "sunrise": "2024-01-15T08:32:00+01:00",
  "sunset": "2024-01-15T17:15:00+01:00",
  "solar_noon": "2024-01-15T12:53:30+01:00",
  "day_length": "08:43:00",
  "current_elevation": 25.4,
  "current_azimuth": 180.2,
  "moon_phase": "waxing_gibbous",
  "moon_illumination": 78.5,
  "is_day": true,
  "timestamp": "2024-01-15T14:00:00+01:00"
}
```

### Cas d'Usage

| Automatisation | Condition | Action |
|----------------|-----------|--------|
| Volets automatiques | `sunrise - 30min` | Ouvrir les volets |
| Éclairage extérieur | `sunset` | Allumer les lumières |
| Mode nuit | `astral/moon_phase == "full_moon"` | Réduire éclairage jardin |
| Arrosage | `sunrise + 1h` | Démarrer arrosage |

### Composant UI

**Fichier** : `src/components/containers/Astral2MqttContainer.tsx`

**Fonctionnalités** :
- Configuration de la localisation (lat/long)
- Affichage des données solaires en temps réel
- Affichage des phases lunaires
- Calendrier des événements astronomiques

---

## Docker2MQTT - Monitoring Docker

### Description

Docker2MQTT surveille les conteneurs Docker en cours d'exécution et publie leurs états et statistiques via MQTT. Il permet également de contrôler les conteneurs (start/stop/restart) via des commandes MQTT.

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `moreau66/docker2mqtt:latest` |
| **Catégorie** | System |
| **Interface Web** | Aucune |
| **Ports** | Aucun |
| **Dépendances** | Mosquitto |

### Variables d'Environnement

| Variable | Valeur par défaut | Obligatoire | Description |
|----------|-------------------|-------------|-------------|
| `MQTT_BROKER` | `mosquitto` | Oui | Adresse du broker MQTT |
| `MQTT_PORT` | `1883` | Oui | Port du broker MQTT |
| `MQTT_TOPIC_PREFIX` | `docker` | Oui | Préfixe des topics |
| `MQTT_USER` | `` | Non | Utilisateur MQTT |
| `MQTT_PASS` | `` | Non | Mot de passe MQTT (secret) |
| `UPDATE_INTERVAL` | `30` | Oui | Intervalle de mise à jour (secondes) |
| `DOCKER_SOCKET` | `/var/run/docker.sock` | Oui | Chemin du socket Docker |
| `WATCHTOWER_ENABLED` | `false` | Non | Activer l'intégration Watchtower |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | ro | Socket Docker (lecture seule) |
| `/app/config` | `./docker2mqtt/config` | rw | Configuration |
| `/app/logs` | `./docker2mqtt/logs` | rw | Logs |

### Topics MQTT

#### État des Conteneurs

| Topic | Direction | Description |
|-------|-----------|-------------|
| `docker/containers` | ← | Liste de tous les conteneurs |
| `docker/containers/{name}/state` | ← | État d'un conteneur |
| `docker/containers/{name}/stats` | ← | Statistiques (CPU, RAM) |
| `docker/containers/{name}/logs` | ← | Dernières lignes de logs |

#### Commandes

| Topic | Direction | Payload | Description |
|-------|-----------|---------|-------------|
| `docker/commands/{name}/start` | → | `{}` | Démarrer un conteneur |
| `docker/commands/{name}/stop` | → | `{}` | Arrêter un conteneur |
| `docker/commands/{name}/restart` | → | `{}` | Redémarrer |
| `docker/commands/{name}/pause` | → | `{}` | Mettre en pause |
| `docker/commands/{name}/unpause` | → | `{}` | Reprendre |
| `docker/commands/{name}/remove` | → | `{"force": true}` | Supprimer |

#### Intégration Watchtower

| Topic | Direction | Description |
|-------|-----------|-------------|
| `docker/events/watchtower/update_available` | ← | Mise à jour disponible |
| `docker/events/watchtower/updating` | ← | Mise à jour en cours |
| `docker/events/watchtower/updated` | ← | Mise à jour terminée |
| `docker/events/watchtower/update_failed` | ← | Échec de mise à jour |

### Exemple de Payload - État

```json
{
  "container_id": "abc123def456",
  "name": "mosquitto",
  "image": "eclipse-mosquitto:2.0",
  "state": "running",
  "status": "Up 2 days",
  "created": "2024-01-13T10:00:00Z",
  "ports": [
    {"container": 1883, "host": 1883, "protocol": "tcp"},
    {"container": 9001, "host": 9001, "protocol": "tcp"}
  ],
  "networks": ["neurhomia-network"]
}
```

### Exemple de Payload - Statistiques

```json
{
  "container_name": "mosquitto",
  "cpu_percent": 2.5,
  "memory_usage": 52428800,
  "memory_limit": 1073741824,
  "memory_percent": 4.88,
  "network_rx_bytes": 1048576,
  "network_tx_bytes": 2097152,
  "block_read_bytes": 10485760,
  "block_write_bytes": 5242880,
  "timestamp": "2024-01-15T14:00:00Z"
}
```

### Sécurité

⚠️ **Important** : Le socket Docker donne un accès complet à Docker. En production :

1. Utilisez un proxy Docker (socket-proxy) pour limiter les permissions
2. Montez le socket en lecture seule (`ro`)
3. Limitez les commandes disponibles via configuration

```yaml
# Exemple avec docker-socket-proxy
docker-socket-proxy:
  image: tecnativa/docker-socket-proxy
  environment:
    CONTAINERS: 1
    IMAGES: 1
    INFO: 1
    POST: 0  # Désactive les commandes d'écriture
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
```

### Composant UI

**Fichier** : `src/components/containers/Docker2MqttContainer.tsx`

**Fonctionnalités** :
- Liste des conteneurs avec état en temps réel
- Statistiques CPU/RAM/Réseau
- Boutons de contrôle (Start/Stop/Restart)
- Notifications Watchtower

---

## Meteo2MQTT - Service Météorologique

### Description

Meteo2MQTT récupère les données météorologiques depuis des API externes et les publie via MQTT. Il supporte plusieurs fournisseurs (OpenWeatherMap, WeatherAPI, Météo-France).

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `moreau66/meteo2mqtt:latest` |
| **Catégorie** | Sensor |
| **Interface Web** | Aucune |
| **Ports** | Aucun |
| **Dépendances** | Mosquitto |

### Variables d'Environnement

| Variable | Valeur par défaut | Obligatoire | Description |
|----------|-------------------|-------------|-------------|
| `MQTT_HOST` | `localhost` | Oui | Hôte du broker MQTT |
| `MQTT_PORT` | `1883` | Oui | Port du broker MQTT |
| `MQTT_BASE_TOPIC` | `weather` | Oui | Topic de base |
| `API_KEY` | `` | Oui | Clé API du fournisseur (secret) |
| `WEATHER_PROVIDER` | `openweathermap` | Oui | Fournisseur météo |
| `CITY_NAME` | `Paris` | Oui | Nom de la ville |
| `COUNTRY_CODE` | `FR` | Oui | Code pays ISO 3166 |
| `LATITUDE` | `48.8566` | Oui | Latitude |
| `LONGITUDE` | `2.3522` | Oui | Longitude |
| `UPDATE_INTERVAL` | `600` | Oui | Intervalle de mise à jour (secondes) |
| `LANGUAGE` | `fr` | Non | Langue des descriptions |
| `UNITS` | `metric` | Non | Système d'unités |

### Fournisseurs Supportés

| Fournisseur | ID | Clé API | URL |
|-------------|----|---------| ----|
| OpenWeatherMap | `openweathermap` | Gratuite (limitée) | openweathermap.org |
| WeatherAPI | `weatherapi` | Gratuite (limitée) | weatherapi.com |
| Météo-France | `meteo` | Gratuite | api.meteo-france.fr |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/app/config.ini` | `./meteo2mqtt/config.ini` | rw | Configuration |
| `/app/logs` | `./meteo2mqtt/logs` | rw | Logs |

### Topics MQTT

#### Données Actuelles

| Topic | Description |
|-------|-------------|
| `weather/{city}/current` | Conditions météo actuelles |
| `weather/{city}/temperature` | Température |
| `weather/{city}/humidity` | Humidité |
| `weather/{city}/pressure` | Pression atmosphérique |
| `weather/{city}/wind` | Vitesse et direction du vent |
| `weather/{city}/description` | Description textuelle |

#### Prévisions

| Topic | Description |
|-------|-------------|
| `weather/{city}/forecast/today` | Prévisions du jour |
| `weather/{city}/forecast/tomorrow` | Prévisions de demain |
| `weather/{city}/forecast/week` | Prévisions sur 7 jours |

#### Alertes

| Topic | Description |
|-------|-------------|
| `weather/{city}/alerts` | Alertes météo actives |
| `weather/{city}/alerts/count` | Nombre d'alertes |

### Exemple de Payload - Conditions Actuelles

```json
{
  "temperature": 18.5,
  "feels_like": 17.2,
  "humidity": 65,
  "pressure": 1015,
  "wind_speed": 12.5,
  "wind_direction": 270,
  "wind_gust": 18.0,
  "clouds": 40,
  "visibility": 10000,
  "description": "Partiellement nuageux",
  "icon": "03d",
  "condition": "Clouds",
  "uv_index": 3,
  "sunrise": "08:32:00",
  "sunset": "17:15:00",
  "timestamp": "2024-01-15T14:00:00Z"
}
```

### Exemple de Payload - Prévisions

```json
{
  "date": "2024-01-16",
  "temp_min": 5.0,
  "temp_max": 12.0,
  "humidity": 70,
  "precipitation_probability": 30,
  "precipitation_amount": 2.5,
  "description": "Averses légères",
  "icon": "10d",
  "wind_speed": 15.0,
  "wind_direction": 180
}
```

### Cas d'Usage

| Automatisation | Condition | Action |
|----------------|-----------|--------|
| Arrosage intelligent | `precipitation_probability < 20` | Activer arrosage |
| Volets été | `temperature > 25 AND uv_index > 6` | Fermer volets |
| Alerte gel | `temperature < 2` | Notification + chauffage |
| Séchage linge | `humidity < 60 AND wind_speed > 10` | Notification "bon pour sécher" |

### Composant UI

**Fichier** : `src/components/containers/Meteo2MqttContainer.tsx`

**Fonctionnalités** :
- Configuration API (clé, fournisseur)
- Configuration localisation (ville, coordonnées)
- Affichage des conditions actuelles
- Configuration MQTT
- Édition avancée (config.ini, docker-compose.yml)

---

## IA2MQTT / Ollama - LLM Local

### Description

IA2MQTT intègre Ollama, permettant d'exécuter des modèles de langage (LLM) localement. Ces modèles peuvent être utilisés pour l'analyse de données, la génération de réponses automatiques, ou l'assistance intelligente.

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `ollama/ollama:latest` |
| **Catégorie** | AI |
| **API REST** | `http://localhost:11434` |
| **Port** | 11434 |
| **Dépendances** | Aucune (Mosquitto optionnel) |

### Variables d'Environnement

| Variable | Valeur par défaut | Obligatoire | Description |
|----------|-------------------|-------------|-------------|
| `OLLAMA_HOST` | `0.0.0.0` | Oui | Adresse d'écoute |
| `OLLAMA_MODELS` | `llama2` | Non | Modèles à précharger |
| `MQTT_BROKER` | `mosquitto` | Non | Adresse du broker MQTT |
| `MQTT_PORT` | `1883` | Non | Port du broker MQTT |
| `MQTT_TOPIC_PREFIX` | `ia` | Non | Préfixe des topics MQTT |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/root/.ollama` | `./ollama/data` | rw | Modèles et cache |

### Modèles Disponibles

| Modèle | Taille | RAM requise | Usage |
|--------|--------|-------------|-------|
| `llama2` | 7B | 8 GB | Généraliste |
| `llama2:13b` | 13B | 16 GB | Qualité supérieure |
| `mistral` | 7B | 8 GB | Instruction-following |
| `mixtral` | 8x7B | 48 GB | Mixture of Experts |
| `codellama` | 7B | 8 GB | Génération de code |
| `phi` | 2.7B | 4 GB | Léger et rapide |
| `neural-chat` | 7B | 8 GB | Conversationnel |
| `starling-lm` | 7B | 8 GB | Raisonnement |

### API REST

#### Lister les modèles

```bash
GET http://localhost:11434/api/tags
```

Réponse :
```json
{
  "models": [
    {
      "name": "llama2:latest",
      "size": 3825819519,
      "digest": "78e26419b446",
      "modified_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### Générer du texte

```bash
POST http://localhost:11434/api/generate
Content-Type: application/json

{
  "model": "llama2",
  "prompt": "Explique la domotique en 3 phrases.",
  "stream": false
}
```

Réponse :
```json
{
  "model": "llama2",
  "created_at": "2024-01-15T14:00:00Z",
  "response": "La domotique est l'ensemble des technologies...",
  "done": true,
  "total_duration": 5023456789,
  "prompt_eval_count": 12,
  "eval_count": 87
}
```

#### Télécharger un modèle

```bash
POST http://localhost:11434/api/pull
Content-Type: application/json

{
  "name": "mistral"
}
```

### Topics MQTT

| Topic | Direction | Description |
|-------|-----------|-------------|
| `ia/prompt` | → | Envoi d'un prompt |
| `ia/response` | ← | Réponse du modèle |
| `ia/status` | ← | État du service |
| `ia/models` | ← | Liste des modèles |
| `mcp/services/ia2mqtt/discovery` | ← | Annonce MCP |

### Exemple de Message MQTT

```json
// Topic: ia/prompt
{
  "model": "llama2",
  "prompt": "Quelle est la température idéale pour une chambre?",
  "request_id": "req_123",
  "options": {
    "temperature": 0.7,
    "max_tokens": 200
  }
}

// Topic: ia/response
{
  "request_id": "req_123",
  "model": "llama2",
  "response": "La température idéale pour une chambre se situe entre 16°C et 19°C...",
  "duration_ms": 2500,
  "tokens": 85
}
```

### Healthcheck

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Composant UI

**Fichier** : `src/components/containers/OllamaContainer.tsx`

**Fonctionnalités** :
- Liste des modèles installés
- Téléchargement de nouveaux modèles
- Interface de chat/prompt
- Statistiques d'utilisation
- Configuration MQTT

---

## SQLite2MQTT - Base de Données Légère

### Description

SQLite2MQTT fournit une base de données SQLite légère accessible via MQTT et API REST. Idéale pour le stockage local des données de capteurs et l'historique des entités.

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `moreau66/sqlite2mqtt:latest` |
| **Catégorie** | Data |
| **API REST** | `http://localhost:8080` |
| **Port** | 8080 |
| **Dépendances** | Mosquitto |

### Variables d'Environnement

| Variable | Valeur par défaut | Obligatoire | Description |
|----------|-------------------|-------------|-------------|
| `MQTT_BROKER` | `mosquitto` | Oui | Adresse du broker MQTT |
| `MQTT_PORT` | `1883` | Oui | Port du broker MQTT |
| `MQTT_TOPIC_PREFIX` | `sqlite` | Oui | Préfixe des topics |
| `MQTT_USER` | `` | Non | Utilisateur MQTT |
| `MQTT_PASS` | `` | Non | Mot de passe MQTT (secret) |
| `SQLITE_DATABASE` | `/app/data/database.db` | Oui | Chemin de la base de données |
| `AUTO_CREATE_TABLES` | `true` | Non | Création automatique des tables |
| `STORE_MQTT_MESSAGES` | `true` | Non | Stocker les messages MQTT |
| `STORE_TOPICS` | `+/+/state` | Non | Topics à stocker |
| `DATA_RETENTION_DAYS` | `30` | Non | Rétention des données (jours) |
| `BACKUP_ENABLED` | `true` | Non | Activer les sauvegardes |
| `BACKUP_INTERVAL` | `86400` | Non | Intervalle de sauvegarde (secondes) |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/app/data` | `./sqlite/data` | rw | Base de données |
| `/app/config` | `./sqlite/config` | rw | Configuration |
| `/app/logs` | `./sqlite/logs` | rw | Logs |
| `/app/backups` | `./sqlite/backups` | rw | Sauvegardes |

### Topics MQTT

#### Requêtes

| Topic | Direction | Description |
|-------|-----------|-------------|
| `sqlite/query` | → | Exécution de requête SQL |
| `sqlite/query/result` | ← | Résultat de la requête |
| `sqlite/insert` | → | Insertion de données |
| `sqlite/update` | → | Mise à jour de données |
| `sqlite/delete` | → | Suppression de données |

#### Administration

| Topic | Direction | Description |
|-------|-----------|-------------|
| `sqlite/backup` | → | Déclencher une sauvegarde |
| `sqlite/backup/status` | ← | État de la sauvegarde |
| `sqlite/vacuum` | → | Optimiser la base |
| `sqlite/status` | ← | État du service |

### Exemple de Requête MQTT

```json
// Topic: sqlite/query
{
  "query": "SELECT * FROM sensor_data WHERE entity_id = ? ORDER BY timestamp DESC LIMIT 10",
  "params": ["temperature_salon"],
  "request_id": "req_456"
}

// Topic: sqlite/query/result
{
  "request_id": "req_456",
  "success": true,
  "rows": [
    {"id": 1, "entity_id": "temperature_salon", "value": 21.5, "timestamp": "2024-01-15T14:00:00Z"},
    {"id": 2, "entity_id": "temperature_salon", "value": 21.3, "timestamp": "2024-01-15T13:55:00Z"}
  ],
  "row_count": 10,
  "duration_ms": 5
}
```

### API REST

#### Exécuter une requête

```bash
POST http://localhost:8080/api/query
Content-Type: application/json

{
  "query": "SELECT COUNT(*) as count FROM sensor_data",
  "params": []
}
```

#### Statistiques

```bash
GET http://localhost:8080/api/stats
```

Réponse :
```json
{
  "database_size_bytes": 10485760,
  "table_count": 5,
  "total_rows": 125000,
  "oldest_record": "2023-12-15T00:00:00Z",
  "newest_record": "2024-01-15T14:00:00Z"
}
```

### Schéma par Défaut

```sql
-- Table des messages MQTT stockés
CREATE TABLE IF NOT EXISTS mqtt_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  topic TEXT NOT NULL,
  payload TEXT,
  qos INTEGER DEFAULT 0,
  retain BOOLEAN DEFAULT FALSE,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Table des données de capteurs
CREATE TABLE IF NOT EXISTS sensor_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_id TEXT NOT NULL,
  value REAL,
  unit TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_mqtt_topic ON mqtt_messages(topic);
CREATE INDEX IF NOT EXISTS idx_sensor_entity ON sensor_data(entity_id);
CREATE INDEX IF NOT EXISTS idx_sensor_timestamp ON sensor_data(timestamp);
```

### Composant UI

**Fichier** : `src/components/containers/SQLiteContainer.tsx`

**Fonctionnalités** :
- Interface d'exécution de requêtes SQL
- Affichage des résultats en tableau
- Gestion des sauvegardes
- Statistiques de la base de données

---

## DuckDB2MQTT - Base Analytique

### Description

DuckDB2MQTT fournit une base de données analytique (OLAP) optimisée pour les requêtes complexes sur de grands volumes de données. Idéale pour l'analyse de séries temporelles et les agrégations.

### Configuration de Base

| Paramètre | Valeur |
|-----------|--------|
| **Image Docker** | `moreau66/duckdb2mqtt:latest` |
| **Catégorie** | Data |
| **API REST** | `http://localhost:8081` |
| **Port** | 8081 |
| **Dépendances** | Mosquitto |

### Variables d'Environnement

| Variable | Valeur par défaut | Obligatoire | Description |
|----------|-------------------|-------------|-------------|
| `MQTT_BROKER` | `mosquitto` | Oui | Adresse du broker MQTT |
| `MQTT_PORT` | `1883` | Oui | Port du broker MQTT |
| `MQTT_TOPIC_PREFIX` | `duckdb` | Oui | Préfixe des topics |
| `MQTT_USER` | `` | Non | Utilisateur MQTT |
| `MQTT_PASS` | `` | Non | Mot de passe MQTT (secret) |
| `DUCKDB_DATABASE` | `/app/data/analytics.duckdb` | Oui | Chemin de la base |
| `DUCKDB_MEMORY_LIMIT` | `2GB` | Non | Limite mémoire |
| `DUCKDB_THREADS` | `4` | Non | Nombre de threads |
| `AUTO_AGGREGATION` | `true` | Non | Agrégation automatique |
| `AGGREGATION_INTERVALS` | `hourly,daily,weekly` | Non | Intervalles d'agrégation |
| `DATA_RETENTION_DAYS` | `365` | Non | Rétention des données |
| `PARQUET_EXPORT` | `true` | Non | Export Parquet automatique |

### Volumes

| Chemin conteneur | Chemin hôte | Mode | Description |
|------------------|-------------|------|-------------|
| `/app/data` | `./duckdb/data` | rw | Base de données |
| `/app/config` | `./duckdb/config` | rw | Configuration |
| `/app/logs` | `./duckdb/logs` | rw | Logs |
| `/app/exports` | `./duckdb/exports` | rw | Exports Parquet |

### Topics MQTT

#### Requêtes

| Topic | Direction | Description |
|-------|-----------|-------------|
| `duckdb/query` | → | Requête SQL analytique |
| `duckdb/query/result` | ← | Résultat de la requête |
| `duckdb/aggregate` | → | Déclencher une agrégation |
| `duckdb/aggregate/result` | ← | Résultat de l'agrégation |

#### Agrégations Automatiques

| Topic | Direction | Description |
|-------|-----------|-------------|
| `duckdb/aggregate/hourly` | ← | Agrégations horaires |
| `duckdb/aggregate/daily` | ← | Agrégations journalières |
| `duckdb/aggregate/weekly` | ← | Agrégations hebdomadaires |

#### Export

| Topic | Direction | Description |
|-------|-----------|-------------|
| `duckdb/export/parquet` | → | Déclencher export Parquet |
| `duckdb/export/status` | ← | État de l'export |

### Comparaison SQLite vs DuckDB

| Critère | SQLite | DuckDB |
|---------|--------|--------|
| **Type** | OLTP (transactionnel) | OLAP (analytique) |
| **Cas d'usage** | Insertions fréquentes | Requêtes complexes |
| **Agrégations** | Lent sur gros volumes | Optimisé |
| **Mémoire** | Faible | Configurable (2GB+) |
| **Export** | SQL dump | Parquet natif |
| **Séries temporelles** | Basique | Fonctions avancées |

### Requêtes Analytiques Avancées

#### Moyenne mobile (7 jours)

```sql
SELECT 
  entity_id,
  timestamp,
  value,
  AVG(value) OVER (
    PARTITION BY entity_id 
    ORDER BY timestamp 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) as moving_avg_7d
FROM sensor_data
WHERE entity_id = 'temperature_salon'
ORDER BY timestamp DESC
LIMIT 100;
```

#### Agrégation horaire avec statistiques

```sql
SELECT 
  entity_id,
  date_trunc('hour', timestamp) as hour,
  COUNT(*) as samples,
  AVG(value) as avg_value,
  MIN(value) as min_value,
  MAX(value) as max_value,
  STDDEV(value) as std_dev
FROM sensor_data
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY entity_id, date_trunc('hour', timestamp)
ORDER BY hour DESC;
```

#### Détection d'anomalies

```sql
WITH stats AS (
  SELECT 
    entity_id,
    AVG(value) as mean,
    STDDEV(value) as std
  FROM sensor_data
  WHERE timestamp >= NOW() - INTERVAL '30 days'
  GROUP BY entity_id
)
SELECT 
  s.entity_id,
  s.timestamp,
  s.value,
  (s.value - stats.mean) / stats.std as z_score
FROM sensor_data s
JOIN stats ON s.entity_id = stats.entity_id
WHERE ABS((s.value - stats.mean) / stats.std) > 3
ORDER BY s.timestamp DESC;
```

### Healthcheck

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8081/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Composant UI

**Fichier** : `src/components/containers/DuckDBContainer.tsx`

**Onglets** :
- **Query** : Interface d'exécution de requêtes SQL
- **Configuration** : Paramètres de la base
- **Initialization** : Scripts d'initialisation
- **Backups** : Gestion des sauvegardes

---

## Découverte et Intégration MCP

### Protocole MCP (Microservice Communication Protocol)

MCP est le protocole standard de découverte et communication entre microservices dans NeurHomeIA.

### Topics de Découverte

| Topic | Description |
|-------|-------------|
| `mcp/services/+/discovery` | Annonce d'un service |
| `mcp/+/heartbeat` | Heartbeat périodique |
| `mcp/+/status` | État du service |
| `mcp/+/capabilities` | Capacités du service |

### Format du Message de Découverte

```json
{
  "service_id": "astral2mqtt",
  "name": "Astral2MQTT",
  "version": "1.0.0",
  "status": "online",
  "capabilities": ["tools", "resources"],
  "topics": {
    "data": "astral/+/data",
    "commands": "astral/commands/#"
  },
  "schemas": {
    "mcp": "https://github.com/moreau66/astral2mqtt/blob/main/docs/mcp-schema.json"
  },
  "timestamp": 1705327200,
  "uptime_seconds": 86400
}
```

### Format du Heartbeat

```json
{
  "service_id": "astral2mqtt",
  "status": "online",
  "timestamp": 1705327200,
  "metrics": {
    "messages_published": 1250,
    "messages_received": 42,
    "errors": 0,
    "uptime_seconds": 86400
  }
}
```

### Services de Découverte

#### Production

**Fichier** : `src/services/microservices/MicroserviceProductionDiscoveryService.ts`

- Souscription aux topics `mcp/services/+/discovery`
- Monitoring des heartbeats
- Détection des services hors ligne

#### Simulation

**Fichier** : `src/services/microservices/MicroserviceSimulationDiscoveryService.ts`

- Simulation de services pour le développement
- Données fictives réalistes
- Activation via mode simulation

### Registre des Alias de Microservices

**Fichier** : `src/hooks/useMicroserviceAliasRegistry.ts`

Chaque microservice peut définir des alias pour simplifier l'accès à ses données :

| Alias | Topic MQTT | Microservice |
|-------|------------|--------------|
| `soleil.lever` | `astral/+/sunrise` | Astral2MQTT |
| `meteo.temperature` | `weather/+/temperature` | Meteo2MQTT |
| `docker.cpu` | `docker/containers/+/stats/cpu` | Docker2MQTT |

---

## Tableau Récapitulatif

### Vue d'Ensemble des Microservices

| Microservice | Image Docker | Catégorie | Ports | Dépendances | Auto-start |
|--------------|--------------|-----------|-------|-------------|------------|
| **Mosquitto** | `eclipse-mosquitto:2.0` | Core | 1883, 9001 | - | ✅ |
| **Zigbee2MQTT** | `koenkk/zigbee2mqtt` | Gateway | 8080 | Mosquitto | ❌ |
| **Astral2MQTT** | `moreau66/astral2mqtt` | Sensor | - | Mosquitto | ❌ |
| **Docker2MQTT** | `moreau66/docker2mqtt` | System | - | Mosquitto | ❌ |
| **Meteo2MQTT** | `moreau66/meteo2mqtt` | Sensor | - | Mosquitto | ❌ |
| **Ollama** | `ollama/ollama` | AI | 11434 | - | ❌ |
| **SQLite2MQTT** | `moreau66/sqlite2mqtt` | Data | 8080 | Mosquitto | ❌ |
| **DuckDB2MQTT** | `moreau66/duckdb2mqtt` | Data | 8081 | Mosquitto | ❌ |

### Ressources Requises

| Microservice | RAM minimum | CPU | Stockage | GPU |
|--------------|-------------|-----|----------|-----|
| Mosquitto | 64 MB | 0.1 | 100 MB | ❌ |
| Zigbee2MQTT | 256 MB | 0.2 | 500 MB | ❌ |
| Astral2MQTT | 64 MB | 0.1 | 50 MB | ❌ |
| Docker2MQTT | 128 MB | 0.1 | 100 MB | ❌ |
| Meteo2MQTT | 64 MB | 0.1 | 50 MB | ❌ |
| Ollama | 4-48 GB | 2.0+ | 10+ GB | ✅ (optionnel) |
| SQLite2MQTT | 128 MB | 0.2 | 1+ GB | ❌ |
| DuckDB2MQTT | 2+ GB | 1.0 | 5+ GB | ❌ |

### Préfixes de Topics MQTT

| Microservice | Préfixe | Exemple de topic |
|--------------|---------|------------------|
| Mosquitto | `$SYS/`, `mcp/mosquitto/` | `$SYS/broker/clients/connected` |
| Zigbee2MQTT | `zigbee2mqtt/` | `zigbee2mqtt/salon_lampe/set` |
| Astral2MQTT | `astral/` | `astral/paris/sunrise` |
| Docker2MQTT | `docker/` | `docker/containers/mosquitto/state` |
| Meteo2MQTT | `weather/` | `weather/paris/current` |
| Ollama | `ia/` | `ia/response` |
| SQLite2MQTT | `sqlite/` | `sqlite/query/result` |
| DuckDB2MQTT | `duckdb/` | `duckdb/aggregate/hourly` |

---

## Bonnes Pratiques

### Déploiement

1. **Démarrer Mosquitto en premier** - C'est le service core requis par tous les autres
2. **Utiliser des versions spécifiques** - Éviter `latest` en production
3. **Configurer les volumes** - Toujours persister les données importantes
4. **Limiter les ressources** - Définir des limites CPU/RAM dans Docker Compose

### Configuration

1. **Variables sensibles** - Utiliser des secrets Docker pour les mots de passe et clés API
2. **Intervalles de mise à jour** - Adapter selon les besoins (météo: 10min, astral: 1h)
3. **Rétention des données** - Configurer selon l'espace disque disponible
4. **Healthchecks** - Activer pour la détection automatique des pannes

### Sécurité

1. **Socket Docker** - Toujours monter en lecture seule pour Docker2MQTT
2. **Authentification MQTT** - Activer en production
3. **Réseau Docker** - Isoler les microservices dans un réseau dédié
4. **Mises à jour** - Activer Watchtower pour les mises à jour automatiques

### Monitoring

1. **Logs centralisés** - Configurer les volumes de logs pour chaque service
2. **Heartbeats MCP** - Surveiller les services via `mcp/+/heartbeat`
3. **Alertes** - Configurer des notifications sur les échecs de healthcheck
4. **Métriques** - Utiliser Docker2MQTT pour surveiller les ressources

---

## Références

### Documentation Interne

- [Guide des Conteneurs Docker](./guide-conteneurs-docker.md) - Déploiement et gestion
- [Guide d'Intégration MQTT](./guide-integration-mqtt.md) - Topics et messages
- [Guide de Stockage MQTT](./guide-stockage-mqtt.md) - Persistance des données
- [Guide des Alias MQTT](./guide-alias-mqtt.md) - Simplification des topics

### Documentation Externe

| Microservice | GitHub | Docker Hub | Documentation |
|--------------|--------|------------|---------------|
| Mosquitto | [eclipse/mosquitto](https://github.com/eclipse/mosquitto) | [eclipse-mosquitto](https://hub.docker.com/_/eclipse-mosquitto) | [mosquitto.org](https://mosquitto.org/documentation/) |
| Zigbee2MQTT | [Koenkk/zigbee2mqtt](https://github.com/Koenkk/zigbee2mqtt) | [koenkk/zigbee2mqtt](https://hub.docker.com/r/koenkk/zigbee2mqtt) | [zigbee2mqtt.io](https://www.zigbee2mqtt.io/) |
| Ollama | [ollama/ollama](https://github.com/ollama/ollama) | [ollama/ollama](https://hub.docker.com/r/ollama/ollama) | [ollama.ai](https://ollama.ai/) |
