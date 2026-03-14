# Guide d'utilisation — Docker Compose Maître

> **Version** : 1.0.0  
> **Date** : 9 mars 2026  
> **Fichier** : `docker-compose.master.yml`

---

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Prérequis](#prérequis)
3. [Installation rapide](#installation-rapide)
4. [Architecture des profils](#architecture-des-profils)
5. [Commandes de démarrage](#commandes-de-démarrage)
6. [Configuration des variables](#configuration-des-variables)
7. [Gestion des secrets](#gestion-des-secrets)
8. [Ports exposés](#ports-exposés)
9. [Périphériques matériels](#périphériques-matériels)
10. [Volumes persistants](#volumes-persistants)
11. [Dépannage](#dépannage)

---

## Vue d'ensemble

Le fichier `docker-compose.master.yml` orchestre l'ensemble de l'écosystème NeurHomeIA : **17 services** répartis en **3 services core** (toujours actifs) et **14 microservices optionnels** activables par profils.

```
┌─────────────────────────────────────────────────────┐
│                    CORE (toujours actif)            │
│  mosquitto · app · file-sync-api                    │
├─────────────────────────────────────────────────────┤
│  PROFILS OPTIONNELS                                 │
│  ┌─────────────┐ ┌───────────────┐ ┌─────────────┐ │
│  │  monitoring  │ │    radio      │ │ environment │ │
│  │ system2mqtt  │ │ zigbee2mqtt   │ │ astral2mqtt │ │
│  │ docker2mqtt  │ │ entities*     │ │ meteo2mqtt  │ │
│  │              │ │ rf2mqtt       │ │             │ │
│  │              │ │ modbus2mqtt   │ │             │ │
│  │              │ │ bluetooth2mqtt│ │             │ │
│  └─────────────┘ └───────────────┘ └─────────────┘ │
│  ┌─────────────┐ ┌───────────────┐ ┌─────────────┐ │
│  │  messaging   │ │    audio      │ │     ia      │ │
│  │ telegram2mqtt│ │ text2speech   │ │  ia2mqtt    │ │
│  │ mail2mqtt    │ │               │ │  ollama     │ │
│  └─────────────┘ └───────────────┘ └─────────────┘ │
│  ┌─────────────┐ ┌───────────────┐ ┌─────────────┐ │
│  │   bridges    │ │    gpio       │ │   storage   │ │
│  │ xmqtt2mqtt   │ │ nrxgce2mqtt   │ │ sqlite2mqtt │ │
│  └─────────────┘ └───────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## Prérequis

| Outil | Version minimale |
|-------|-----------------|
| Docker | 24.0+ |
| Docker Compose | 2.20+ (plugin V2) |
| RAM disponible | 2 Go (core) / 8 Go (all + IA) |
| Espace disque | 5 Go minimum |

---

## Installation rapide

```bash
# 1. Cloner le projet
git clone https://github.com/votre-org/neurhomia.git
cd neurhomia

# 2. Créer le fichier de configuration
cp .env.example .env

# 3. Éditer les variables selon votre installation
nano .env

# 4. Créer le dossier des secrets (si profil mail activé)
mkdir -p secrets
echo "votre_mot_de_passe" > secrets/email_password.txt

# 5. Démarrer les services core
docker compose -f docker-compose.master.yml up -d
```

---

## Architecture des profils

Les profils permettent d'activer uniquement les services nécessaires. Chaque microservice appartient à un ou plusieurs profils :

### Profils individuels

| Profil | Services activés | Matériel requis |
|--------|-----------------|-----------------|
| `system` | system2mqtt | — |
| `docker` | docker2mqtt | Docker socket |
| `zigbee` | zigbee2mqtt, entitiesfromzigbee | Dongle Zigbee USB |
| `zwave` | entitiesfromzwave | Dongle Z-Wave USB |
| `rf` | rf2mqtt | Récepteur RF 433 MHz |
| `modbus` | modbus2mqtt | Adaptateur Modbus RTU |
| `bluetooth` | bluetooth2mqtt | Adaptateur Bluetooth |
| `astral` | astral2mqtt | — |
| `meteo` | meteo2mqtt | — (clé API requise) |
| `telegram` | telegram2mqtt | — (token bot requis) |
| `mail` | mail2mqtt | — (compte email requis) |
| `tts` / `audio` | text2speech2mqtt | Carte son `/dev/snd` |
| `ia` | ia2mqtt, ollama | — (GPU recommandé) |
| `bridges` | xmqtt2mqtt | — |
| `nrxgce` / `gpio` | nrxgce2mqtt | GPIO (ou mode simulation) |
| `storage` | sqlite2mqtt | — |
| `backup` | sqlite-backup | — |

### Profils de regroupement

| Profil | Inclut |
|--------|--------|
| `monitoring` | system2mqtt, docker2mqtt |
| `radio` | zigbee2mqtt, entitiesfromzigbee, rf2mqtt, bluetooth2mqtt |
| `environment` | astral2mqtt, meteo2mqtt |
| `messaging` | telegram2mqtt, mail2mqtt |
| `entities` | entitiesfromzigbee, entitiesfromzwave |
| `energy` | modbus2mqtt |
| **`all`** | **Tous les services** |

---

## Commandes de démarrage

### Services core uniquement (minimal)

```bash
docker compose -f docker-compose.master.yml up -d
```

### Activer un profil spécifique

```bash
# Zigbee uniquement
docker compose -f docker-compose.master.yml --profile zigbee up -d

# Monitoring complet
docker compose -f docker-compose.master.yml --profile monitoring up -d
```

### Combiner plusieurs profils

```bash
# Zigbee + Météo + IA
docker compose -f docker-compose.master.yml \
  --profile zigbee \
  --profile meteo \
  --profile ia \
  up -d
```

### Tout activer

```bash
docker compose -f docker-compose.master.yml --profile all up -d
```

### Arrêter les services

```bash
# Arrêter tout
docker compose -f docker-compose.master.yml --profile all down

# Arrêter avec suppression des volumes (⚠️ données perdues)
docker compose -f docker-compose.master.yml --profile all down -v
```

### Redémarrer un service spécifique

```bash
docker compose -f docker-compose.master.yml restart meteo2mqtt
```

### Consulter les logs

```bash
# Tous les services
docker compose -f docker-compose.master.yml --profile all logs -f

# Un service spécifique
docker compose -f docker-compose.master.yml logs -f ia2mqtt

# Les 50 dernières lignes
docker compose -f docker-compose.master.yml logs --tail=50 mosquitto
```

### Vérifier l'état des services

```bash
docker compose -f docker-compose.master.yml --profile all ps
```

---

## Configuration des variables

Toutes les variables sont documentées dans `.env.example`. Voici les plus importantes :

### MQTT (obligatoire)

```env
MQTT_USER=admin
MQTT_PASS=un_mot_de_passe_fort
```

> Ces identifiants sont partagés automatiquement avec tous les microservices via l'ancre YAML `x-mqtt-env`.

### Clés API MCP

Chaque microservice peut avoir sa propre clé d'authentification :

```env
MCP_API_KEY_SYSTEM=mcp_system_xxxxx
MCP_API_KEY_IA=mcp_ia_xxxxx
```

> Laisser vide pour désactiver l'authentification MCP sur un service donné.

### Géolocalisation (Astral & Météo)

```env
ASTRAL_LATITUDE=48.8566
ASTRAL_LONGITUDE=2.3522
METEO2MQTT_LOCATION=Paris,FR
```

---

## Gestion des secrets

Les secrets sensibles (mots de passe email, tokens) ne doivent **jamais** être dans `.env` en production.

### Secret fichier (Mail)

```bash
mkdir -p secrets
echo "mot_de_passe_application" > secrets/email_password.txt
chmod 600 secrets/email_password.txt
```

### Bonnes pratiques

- ✅ Utiliser des **app passwords** (Gmail, Outlook)
- ✅ Restreindre les permissions des fichiers secrets (`chmod 600`)
- ✅ Ajouter `secrets/` au `.gitignore`
- ❌ Ne jamais commiter de secrets dans le dépôt

---

## Ports exposés

| Port | Service | Configurable via |
|------|---------|-----------------|
| **1883** | MQTT (TCP) | `MQTT_PORT` |
| **9001** | MQTT (WebSocket) | `MQTT_WS_PORT` |
| **8080** | Application NeurHomeIA | `APP_PORT` |
| 8000 | API IA2MQTT | `IA_API_PORT` |
| 8081 | Interface Zigbee2MQTT | `ZIGBEE_WEB_PORT` |
| 8082 | API SQLite2MQTT | `SQLITE_PORT` |
| 8086 | API NRX-GCE | `NRXGCE_PORT` |
| 8089 | API RF2MQTT | `RF_WEB_PORT` |
| 8090 | API Modbus2MQTT | `MODBUS_WEB_PORT` |
| 11434 | API Ollama | `OLLAMA_PORT` |

> Les ports en **gras** sont ceux du core, toujours exposés.

---

## Périphériques matériels

Certains services nécessitent un accès à des périphériques physiques :

| Service | Device par défaut | Variable |
|---------|------------------|----------|
| zigbee2mqtt | `/dev/ttyUSB0` | `ZIGBEE_DEVICE` |
| rf2mqtt | `/dev/ttyUSB1` | `RF_DEVICE` |
| modbus2mqtt | `/dev/ttyUSB2` | `MODBUS_DEVICE` |
| bluetooth2mqtt | `/dev/bus/usb` | — (fixe) |
| text2speech2mqtt | `/dev/snd` | — (fixe) |

> ⚠️ Vérifiez vos mappings USB avec `ls -la /dev/ttyUSB*` avant le démarrage.

### Mode simulation (NRX-GCE)

Pour tester sans matériel GPIO :

```env
GPIO_SIMULATION=true
```

---

## Volumes persistants

| Volume | Usage |
|--------|-------|
| `mosquitto_data` | Messages MQTT retenus |
| `mosquitto_logs` | Logs du broker |
| `zigbee_data` | Configuration Zigbee2MQTT |
| `ollama_data` | Modèles LLM téléchargés |
| `sqlite_data` | Base de données SQLite |

### Sauvegardes automatiques

Activez le profil `backup` pour des sauvegardes SQLite quotidiennes :

```bash
docker compose -f docker-compose.master.yml --profile backup up -d
```

Les backups sont stockés dans `./backups/` avec une rétention de 7 jours.

---

## Dépannage

### Le service ne démarre pas

```bash
# Vérifier les logs du service
docker compose -f docker-compose.master.yml logs service_name

# Vérifier que Mosquitto est healthy
docker inspect neurhomia-mosquitto --format='{{.State.Health.Status}}'
```

### Erreur « device not found »

Le périphérique USB n'est pas connecté ou a changé de numéro :

```bash
# Lister les périphériques disponibles
ls -la /dev/ttyUSB* /dev/ttyACM*

# Adapter la variable dans .env
ZIGBEE_DEVICE=/dev/ttyACM0
```

### Conflit de ports

```bash
# Trouver quel processus utilise un port
sudo lsof -i :8080

# Changer le port dans .env
APP_PORT=8888
```

### Réinitialiser un service

```bash
# Supprimer et recréer un service
docker compose -f docker-compose.master.yml rm -sf service_name
docker compose -f docker-compose.master.yml --profile profil up -d service_name
```

### Vérifier la connectivité MQTT

```bash
# Depuis l'hôte
docker exec neurhomia-mosquitto mosquitto_pub -t test/ping -m "hello"

# Écouter les messages MCP
docker exec neurhomia-mosquitto mosquitto_sub -t "mcp/#" -v
```

---

> 📖 Pour plus de détails sur chaque microservice, consultez le [Guide des Microservices](guide-microservices.md) et le [Rapport de Conformité MCP](rapport-conformite-mcp-sdk.md).
