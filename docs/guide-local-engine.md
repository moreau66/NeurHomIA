# Guide du Local Engine ⚡

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Backend Node.js alternatif pour l'exécution locale des scénarios d'automatisation NeurHomIA.

---

## 📑 Table des matières

- [Introduction](#-introduction)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [API REST](#-api-rest)
- [Intégration Frontend](#-intégration-frontend)
- [Docker](#-docker)
- [Dépannage](#-dépannage)
- [Voir aussi](#-voir-aussi)

---

## 🎯 Introduction

Le **Local Engine** est un backend Node.js alternatif au Scheduler Python pour l'exécution des scénarios d'automatisation.

### Comparaison avec le Scheduler Python

| Caractéristique | Local Engine (Node.js) | Scheduler (Python) |
|-----------------|------------------------|---------------------|
| **Langage** | TypeScript/Node.js | Python |
| **Installation** | npm install | pip install |
| **Déploiement** | Docker ou natif | Docker ou natif |
| **Cas d'usage** | Exécution locale, fallback | Backend principal |
| **Port par défaut** | 3001 | 8000 |

### Cas d'utilisation

- 🏠 **Exécution 100% locale** : Aucune dépendance externe
- 🔄 **Fallback automatique** : Si le Scheduler Python est indisponible
- 🧪 **Développement** : Test rapide sans infrastructure complexe
- 📦 **Déploiement léger** : Container Docker minimal

---

## 🏗️ Architecture

### Structure des fichiers

```
backend/local-engine/
├── src/
│   ├── index.ts              # Point d'entrée principal
│   ├── config/
│   │   └── config.ts         # Configuration via variables d'environnement
│   ├── mqtt/
│   │   ├── client.ts         # Client MQTT avec reconnexion automatique
│   │   └── topics.ts         # Définition des topics MQTT
│   ├── engine/
│   │   ├── ScenarioManager.ts    # Gestionnaire de scénarios
│   │   ├── RuleEvaluator.ts      # Évaluateur de conditions
│   │   └── ActionExecutor.ts     # Exécuteur d'actions MQTT
│   ├── scheduler/
│   │   ├── CronScheduler.ts      # Planification cron (node-cron)
│   │   └── CalendarProcessor.ts  # Événements calendaires
│   ├── state/
│   │   └── MqttStateStore.ts     # Cache d'état des entités
│   ├── api/
│   │   ├── server.ts         # Serveur Express HTTP
│   │   └── routes.ts         # Routes REST API
│   ├── utils/
│   │   └── logger.ts         # Logger avec niveaux configurables
│   └── types/
│       └── index.ts          # Types TypeScript
├── Dockerfile                # Image Docker Node.js
├── docker-compose.yml        # Configuration Docker Compose
├── .env.example              # Template de configuration
├── package.json              # Dépendances npm
└── tsconfig.json             # Configuration TypeScript
```

### Diagramme des composants

```
┌─────────────────────────────────────────────────────────────┐
│                     Local Engine                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │ API Server  │    │   Scheduler  │    │  MQTT Client   │  │
│  │  (Express)  │    │  (node-cron) │    │    (mqtt.js)   │  │
│  └──────┬──────┘    └──────┬───────┘    └───────┬────────┘  │
│         │                  │                    │           │
│         ▼                  ▼                    ▼           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                  Scenario Manager                       ││
│  │  ┌────────────────┐  ┌────────────────────────────────┐ ││
│  │  │ RuleEvaluator  │  │      ActionExecutor           │ ││
│  │  └────────────────┘  └────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
│         │                                                   │
│         ▼                                                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                  MQTT State Store                       ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Installation

### Prérequis

- **Node.js** 18+ (20 recommandé)
- **npm** 8+ ou **pnpm**
- Accès au **broker MQTT**

### Installation des dépendances

```bash
cd backend/local-engine
npm install
```

### Compilation TypeScript

```bash
npm run build
```

### Premier démarrage

```bash
# Développement (avec hot-reload)
npm run dev

# Production
npm start
```

---

## ⚙️ Configuration

### Variables d'environnement

Copiez le template et éditez :

```bash
cp .env.example .env
```

### Variables disponibles

| Variable | Défaut | Description |
|----------|--------|-------------|
| `MQTT_BROKER_HOST` | `localhost` | Hôte du broker MQTT |
| `MQTT_BROKER_PORT` | `1883` | Port du broker MQTT |
| `MQTT_USERNAME` | - | Nom d'utilisateur MQTT (optionnel) |
| `MQTT_PASSWORD` | - | Mot de passe MQTT (optionnel) |
| `HTTP_PORT` | `3001` | Port de l'API HTTP |
| `SERVICE_ID` | `local-engine` | ID du service |
| `TOPIC_PREFIX` | `neurhomia` | Préfixe des topics MQTT |
| `LOG_LEVEL` | `info` | Niveau de log (`debug`, `info`, `warn`, `error`) |
| `LATITUDE` | `48.8566` | Latitude pour calculs astronomiques |
| `LONGITUDE` | `2.3522` | Longitude pour calculs astronomiques |

### Exemple de configuration

```bash
# .env
MQTT_BROKER_HOST=192.168.1.100
MQTT_BROKER_PORT=1883
MQTT_USERNAME=neurhomia
MQTT_PASSWORD=secret123
HTTP_PORT=3001
LOG_LEVEL=info
LATITUDE=48.8566
LONGITUDE=2.3522
```

---

## 🔌 API REST

### Endpoints disponibles

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/health` | Health check du service |
| `POST` | `/api/scenarios/sync` | Synchroniser un scénario |
| `POST` | `/api/scenarios/sync-all` | Synchroniser tous les scénarios |
| `DELETE` | `/api/scenarios/:id` | Supprimer un scénario |
| `POST` | `/api/scenarios/:id/trigger` | Déclencher manuellement un scénario |
| `GET` | `/api/scenarios/:id/status` | Statut d'un scénario |
| `GET` | `/api/scenarios/status` | Statut de tous les scénarios |

### Exemples de requêtes

```bash
# Health check
curl http://localhost:3001/api/health

# Synchroniser un scénario
curl -X POST http://localhost:3001/api/scenarios/sync \
  -H "Content-Type: application/json" \
  -d '{"scenario": {...}}'

# Déclencher un scénario manuellement
curl -X POST http://localhost:3001/api/scenarios/scene-1/trigger

# Obtenir le statut
curl http://localhost:3001/api/scenarios/status
```

### Réponses

```json
// GET /api/health
{
  "status": "healthy",
  "service": "local-engine",
  "version": "1.0.0",
  "uptime": 3600,
  "mqtt": "connected",
  "scenarios": {
    "total": 5,
    "active": 3,
    "scheduled": 2
  }
}

// GET /api/scenarios/status
{
  "scenarios": [
    {
      "id": "scene-1",
      "name": "Éclairage salon",
      "status": "active",
      "lastExecution": "2026-01-17T10:30:00Z",
      "nextExecution": "2026-01-17T18:00:00Z"
    }
  ]
}
```

---

## 🖥️ Intégration Frontend

### Configuration dans NeurHomIA

1. Accédez à **Configuration** → **API**
2. Dans la section **Backends d'Exécution**, configurez :
   - **URL du Local Engine** : `http://localhost:3001`
   - **Activé** : Oui
3. Optionnellement, configurez le **fallback automatique**

### Composants Frontend

- **ExecutionBackendConfigCard** : Configuration des backends
- **BackendIndicator** : Indicateur visuel du backend actif par scénario

### Modes de fonctionnement

| Mode | Description |
|------|-------------|
| **Scheduler uniquement** | Utilise le Scheduler Python |
| **Local Engine uniquement** | Utilise le Local Engine Node.js |
| **Auto (fallback)** | Local Engine en fallback si Scheduler indisponible |

---

## 🐳 Docker

### Build de l'image

```bash
cd backend/local-engine
docker build -t neurhomia-local-engine .
```

### Docker Compose

Ajoutez le service dans votre `docker-compose.yml` :

```yaml
services:
  local-engine:
    build:
      context: ./backend/local-engine
      dockerfile: Dockerfile
    container_name: neurhomia-local-engine
    restart: unless-stopped
    environment:
      - MQTT_BROKER_HOST=mosquitto
      - MQTT_BROKER_PORT=1883
      - HTTP_PORT=3001
      - LOG_LEVEL=info
      - LATITUDE=48.8566
      - LONGITUDE=2.3522
    ports:
      - "3001:3001"
    networks:
      - mcp-network
    depends_on:
      - mosquitto
```

### Démarrage

```bash
docker-compose up -d local-engine
```

### Logs

```bash
docker-compose logs -f local-engine
```

---

## 🔍 Topics MQTT

Le Local Engine publie sur les topics suivants :

| Topic | Description |
|-------|-------------|
| `neurhomia/local-engine/status` | Statut du service (`online`/`offline`) |
| `neurhomia/local-engine/heartbeat` | Heartbeat toutes les 10 secondes |
| `neurhomia/local-engine/scenarios/status` | Statistiques des scénarios |
| `neurhomia/local-engine/scenarios/executed` | Événement d'exécution de scénario |
| `neurhomia/local-engine/scenarios/error` | Événement d'erreur |

---

## 🐛 Dépannage

### Le service ne démarre pas

```bash
# Vérifier les logs
npm run dev

# Vérifier la configuration
cat .env
```

### Connexion MQTT échouée

```bash
# Tester la connexion MQTT
mosquitto_pub -h localhost -p 1883 -t test -m "hello"

# Vérifier l'hôte et le port
ping $MQTT_BROKER_HOST
nc -zv $MQTT_BROKER_HOST $MQTT_BROKER_PORT
```

### API ne répond pas

```bash
# Vérifier que le port est libre
netstat -tlnp | grep 3001

# Tester l'endpoint
curl -v http://localhost:3001/api/health
```

### Scénarios non exécutés

1. Vérifiez que le scénario est synchronisé : `GET /api/scenarios/status`
2. Vérifiez les conditions du scénario
3. Consultez les logs : `LOG_LEVEL=debug npm run dev`

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil
- [Guide d'Installation](guide-installation.md) - Installation complète
- [Guide de Production](guide-production.md) - Déploiement en production
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance MQTT
- [Documentation des Fichiers](DOCUMENTATION-FICHIERS.md) - Structure du projet

---

_Documentation NeurHomIA - Janvier 2026_
