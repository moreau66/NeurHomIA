# Structure JSON Microservices 📄

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce document décrit la structure JSON requise pour l'intégration de microservices avec l'architecture **MCP (Model Context Protocol) JSON-RPC over MQTT** et widgets personnalisés dynamiques.

---

## 📑 Table des Matières

1. [Architecture MCP JSON-RPC over MQTT](#architecture-mcp-json-rpc-over-mqtt)
2. [Topics MCP Discovery](#topics-mcp-discovery)
3. [Structure MicroserviceMCP](#structure-microservicemcp)
4. [Structure WidgetSchema avec MCP](#structure-widgetschema-avec-mcp)
5. [Structure MicroservicePageConfig avec MCP](#structure-microservicepageconfig-avec-mcp)
6. [Exemples Complets MCP](#exemples-complets-mcp)
7. [Migration MQTT vers MCP](#migration-mqtt-vers-mcp)
8. [Validation et Bonnes Pratiques](#validation-et-bonnes-pratiques)

## Architecture MCP JSON-RPC over MQTT

L'architecture MCP (Model Context Protocol) remplace l'approche MQTT traditionnelle par un système standardisé de communication JSON-RPC over MQTT.

### Principes Fondamentaux
- **JSON-RPC 2.0** : Protocole standardisé pour les requêtes/réponses
- **Discovery Pattern** : Auto-découverte des microservices via topics MCP
- **Tools & Resources** : Exposition d'outils (méthodes) et de ressources (widgets, pages)
- **Heartbeat** : Maintien de session automatique
- **Sécurité** : Authentification par API keys et permissions granulaires

### Flux de Communication
```
NeurHomIA (Frontend) ←→ MQTT Broker ←→ Microservices MCP (Python)
```

## Topics MCP Discovery

### Microservices MCP
- **Discovery**: `mcp/{service_id}/discovery`
- **JSON-RPC Request**: `mcp/{service_id}/jsonrpc/request`
- **JSON-RPC Response**: `mcp/{service_id}/jsonrpc/response`
- **JSON-RPC Notification**: `mcp/{service_id}/jsonrpc/notification`
- **Heartbeat**: `mcp/{service_id}/heartbeat`

### Widgets (compatible MCP)
- **Publication**: `homeassistant/widget/{schema_id}/config`
- **Payload**: Structure `WidgetSchema` avec liaisons MCP

### Pages Dynamiques (compatible MCP)
- **Publication**: `homeassistant/microservice/{service_id}/config`
- **Payload**: Structure `MicroservicePageConfig` avec configuration MCP

### Legacy MQTT (déprécié)
- **Entités Calculées**: `calculatedentity/{entity_id}/config`
- **État**: `calculatedentity/{entity_id}/state`
- **Attributs**: `calculatedentity/{entity_id}/attributes`

## Structure WidgetSchema

```typescript
interface WidgetSchema {
  id: string;                    // Identifiant unique du widget
  name: string;                  // Nom affiché du widget
  version: string;               // Version du schéma (semver)
  description?: string;          // Description optionnelle
  author?: string;               // Auteur du widget
  deviceTypes: string[];         // Types d'appareils supportés
  
  display: {
    icon?: string;               // Icône Lucide React
    primaryColor?: string;       // Couleur primaire (HSL)
    secondaryColor?: string;     // Couleur secondaire (HSL)
    size: 'small' | 'medium' | 'large';
    refreshInterval?: number;    // Intervalle de rafraîchissement (ms)
  };
  
  sections: WidgetSectionConfig[];
  interactions?: WidgetInteractionConfig[];
  
  dataMapping: {
    [fieldKey: string]: {
      topic: string;             // Topic MQTT source
      path?: string;             // Chemin JSONPath dans le payload
      transform?: string;        // Transformation JavaScript
      fallback?: any;            // Valeur par défaut
    };
  };
  
  createdAt: string;            // ISO timestamp
  updatedAt: string;            // ISO timestamp
}
```

### WidgetSectionConfig

```typescript
interface WidgetSectionConfig {
  id: string;
  title?: string;
  fields: WidgetFieldConfig[];
  layout: 'grid' | 'list' | 'horizontal';
  columns?: number;             // Pour layout 'grid'
  collapsible?: boolean;
  visible: boolean;
}
```

### WidgetFieldConfig

```typescript
interface WidgetFieldConfig {
  key: string;                  // Clé unique dans la section
  label: string;                // Libellé affiché
  type: 'text' | 'number' | 'boolean' | 'icon' | 'progress' | 'chart' | 'button';
  unit?: string;                // Unité pour les valeurs numériques
  icon?: string;                // Icône Lucide React
  format?: string;              // Format d'affichage (ex: "0.1f", "HH:mm")
  min?: number;                 // Valeur minimale
  max?: number;                 // Valeur maximale
  precision?: number;           // Nombre de décimales
  visible: boolean;
  style?: {
    color?: string;             // Couleur HSL
    background?: string;        // Arrière-plan HSL
    size?: 'small' | 'medium' | 'large';
    align?: 'left' | 'center' | 'right';
  };
}
```

### WidgetInteractionConfig

```typescript
interface WidgetInteractionConfig {
  type: 'refresh' | 'toggle' | 'command' | 'navigate';
  label: string;
  icon?: string;                // Icône Lucide React
  topic?: string;               // Topic MQTT pour commandes
  payload?: any;                // Payload à publier
  confirmation?: string;        // Message de confirmation
  style?: 'primary' | 'secondary' | 'destructive';
}
```

## Structure MicroservicePageConfig

```typescript
interface MicroservicePageConfig {
  service_id: string;           // Identifiant unique du service
  page_info: {
    title: string;
    description: string;
    icon: string;               // Icône Lucide React
    category: string;           // Catégorie pour groupement
    version: string;            // Version du service
    sections: PageSectionConfig[];
    navigation: {
      menuLabel: string;        // Libellé dans le menu
      position: number;         // Position dans le menu
      parent?: string;          // Menu parent (optionnel)
    };
  };
  mqtt_config: {
    subscribe_topics: string[];
    publish_topics: string[];
    data_mappings: Record<string, any>;
  };
  api_endpoints?: Record<string, string>;
  actions: PageActionConfig[];
  createdAt: string;
  updatedAt: string;
}
```

### PageSectionConfig

```typescript
interface PageSectionConfig {
  id: string;
  type: 'form' | 'table' | 'chart' | 'chat' | 'monitoring' | 'widget' | 'info';
  title: string;
  description?: string;
  config: Record<string, any>;  // Configuration spécifique au type
  visible: boolean;
  order: number;                // Ordre d'affichage
}
```

### PageActionConfig

```typescript
interface PageActionConfig {
  id: string;
  type: 'button' | 'toggle' | 'command';
  label: string;
  icon?: string;                // Icône Lucide React
  topic?: string;               // Topic MQTT
  payload?: any;                // Payload à publier
  confirmation?: string;        // Message de confirmation
  style?: 'primary' | 'secondary' | 'destructive';
}
```

## Exemples Complets

### Exemple Widget Capteur Température

```json
{
  "id": "temp-sensor-v2",
  "name": "Capteur Température Avancé",
  "version": "2.1.0",
  "description": "Widget pour capteurs de température avec historique",
  "author": "IoT Solutions",
  "deviceTypes": ["temp_sensor", "climate_sensor"],
  
  "display": {
    "icon": "Thermometer",
    "primaryColor": "hsl(200, 85%, 45%)",
    "secondaryColor": "hsl(200, 50%, 70%)",
    "size": "medium",
    "refreshInterval": 30000
  },
  
  "sections": [
    {
      "id": "main-display",
      "title": "Température Actuelle",
      "fields": [
        {
          "key": "temperature",
          "label": "Température",
          "type": "number",
          "unit": "°C",
          "icon": "Thermometer",
          "format": "0.1f",
          "visible": true,
          "style": {
            "size": "large",
            "align": "center"
          }
        },
        {
          "key": "humidity",
          "label": "Humidité",
          "type": "progress",
          "unit": "%",
          "icon": "Droplets",
          "min": 0,
          "max": 100,
          "visible": true
        }
      ],
      "layout": "grid",
      "columns": 2,
      "visible": true
    }
  ],
  
  "interactions": [
    {
      "type": "refresh",
      "label": "Actualiser",
      "icon": "RefreshCw",
      "style": "secondary"
    }
  ],
  
  "dataMapping": {
    "temperature": {
      "topic": "sensors/{device_id}/temperature",
      "path": "$.value",
      "fallback": 0
    },
    "humidity": {
      "topic": "sensors/{device_id}/humidity",
      "path": "$.value",
      "fallback": 50
    }
  },
  
  "createdAt": "2024-01-15T10:00:00.000Z",
  "updatedAt": "2024-01-15T10:00:00.000Z"
}
```

### Exemple Page Microservice

```json
{
  "service_id": "weather-service",
  "page_info": {
    "title": "Service Météorologique",
    "description": "Gestion des données météorologiques locales",
    "icon": "Cloud",
    "category": "Environnement",
    "version": "1.2.0",
    "sections": [
      {
        "id": "current-weather",
        "type": "monitoring",
        "title": "Conditions Actuelles",
        "description": "Données météo en temps réel",
        "config": {
          "metrics": ["temperature", "humidity", "pressure"],
          "refreshInterval": 60000
        },
        "visible": true,
        "order": 1
      },
      {
        "id": "weather-config",
        "type": "form",
        "title": "Configuration",
        "config": {
          "fields": [
            {
              "name": "location",
              "type": "text",
              "label": "Localisation",
              "required": true
            },
            {
              "name": "update_interval",
              "type": "number",
              "label": "Intervalle (minutes)",
              "min": 5,
              "max": 1440
            }
          ]
        },
        "visible": true,
        "order": 2
      }
    ],
    "navigation": {
      "menuLabel": "Météo",
      "position": 30,
      "parent": "Environnement"
    }
  },
  "mqtt_config": {
    "subscribe_topics": [
      "weather/+/data",
      "weather/config/response"
    ],
    "publish_topics": [
      "weather/config/set",
      "weather/command"
    ],
    "data_mappings": {
      "temperature": "weather/{location}/data.temperature",
      "humidity": "weather/{location}/data.humidity"
    }
  },
  "actions": [
    {
      "id": "update-weather",
      "type": "button",
      "label": "Forcer la mise à jour",
      "icon": "RefreshCw",
      "topic": "weather/command",
      "payload": {"action": "update"},
      "style": "primary"
    }
  ],
  "createdAt": "2024-01-15T10:00:00.000Z",
  "updatedAt": "2024-01-15T10:00:00.000Z"
}
```

## Types d'Appareils Supportés

### Widgets
- `weather_station` - Station météo
- `astronomy_station` - Station astronomique
- `thermostat` - Thermostat
- `light` - Éclairage
- `plug` - Prise connectée
- `temp_sensor` - Capteur température
- `container` - Conteneur Docker
- `climate_sensor` - Capteur climatique
- `motion_sensor` - Détecteur de mouvement
- `door_sensor` - Capteur de porte
- `switch` - Interrupteur
- `fan` - Ventilateur
- `cover` - Volet/Store
- `calculated_entity` - Entité calculée avec conversion de valeurs

### Types de Sections Pages
- `form` - Formulaire de configuration
- `table` - Tableau de données
- `chart` - Graphiques et courbes
- `chat` - Interface de chat/IA
- `monitoring` - Monitoring temps réel
- `widget` - Widget embarqué
- `info` - Information statique

## Icônes Supportées

Toutes les icônes [Lucide React](https://lucide.dev/icons/) sont supportées. Exemples :
- `Thermometer`, `Droplets`, `Sun`, `Moon`
- `Power`, `Settings`, `RefreshCw`, `Play`
- `Home`, `Shield`, `Wifi`, `Battery`
- `AlertTriangle`, `CheckCircle`, `Info`

## Couleurs et Thèmes

### Format HSL Requis
Toutes les couleurs doivent utiliser le format HSL :
```
hsl(hue, saturation%, lightness%)
```

### Couleurs Sémantiques Recommandées
- Primary: `hsl(200, 85%, 45%)`
- Secondary: `hsl(200, 50%, 70%)`
- Success: `hsl(120, 60%, 50%)`
- Warning: `hsl(40, 90%, 60%)`
- Error: `hsl(0, 75%, 55%)`

## Validation et Bonnes Pratiques

### Validation Obligatoire
- ✅ `id` unique et descriptif
- ✅ `version` respectant semver
- ✅ Couleurs au format HSL
- ✅ Icônes existantes dans Lucide
- ✅ Topics MQTT valides
- ✅ Types de champs supportés

### Bonnes Pratiques
- 📝 Descriptions claires et concises
- 🎨 Cohérence des couleurs avec le thème
- 📊 Sections logiquement organisées
- 🔄 Intervalles de rafraîchissement appropriés
- 🚫 Éviter les données sensibles en dur
- 📱 Design responsive (tailles small/medium/large)

### Exemples d'Erreurs Communes
```json
// ❌ Couleur au mauvais format
"primaryColor": "#ff0000"

// ✅ Format correct
"primaryColor": "hsl(0, 100%, 50%)"

// ❌ Icône inexistante
"icon": "MyCustomIcon"

// ✅ Icône Lucide valide
"icon": "Thermometer"
```

## Scripts d'Exemple

### Publication Widget via MQTT
```bash
mosquitto_pub -h localhost -t "homeassistant/widget/temp-sensor-v2/config" \
  -f widget-schema.json
```

### Publication Page via MQTT
```bash
mosquitto_pub -h localhost -t "homeassistant/microservice/weather-service/config" \
  -f page-config.json
```

---

## Entités Calculées

### Configuration d'Entité Calculée

```json
{
  "entity_id": "battery_level_sensor",
  "name": "Niveau Batterie Converti",
  "source_entity": "zigbee_device_battery",
  "conversion_type": "battery_to_level",
  "value_range": {
    "min": 0,
    "max": 100,
    "unit": "%",
    "levels": [
      {"min": 0, "max": 20, "label": "Critique", "color": "hsl(0, 75%, 55%)"},
      {"min": 21, "max": 50, "label": "Faible", "color": "hsl(40, 90%, 60%)"},
      {"min": 51, "max": 80, "label": "Bon", "color": "hsl(120, 60%, 50%)"},
      {"min": 81, "max": 100, "label": "Excellent", "color": "hsl(200, 85%, 45%)"}
    ]
  },
  "update_interval": 30
}
```

### Types de Conversion Disponibles

- `battery_to_level` - Conversion batterie en niveau qualitatif
- `signal_to_quality` - Force signal vers qualité de connexion
- `temperature_to_comfort` - Température vers niveau de confort
- `humidity_to_level` - Humidité vers niveau d'humidité
- `percentage_to_grade` - Pourcentage vers note alphabétique
- `numeric_to_boolean` - Valeur numérique vers état binaire

### Monitoring MQTT Amélioré

Le système inclut désormais :

- **Workflow guidé** : Connexion → Abonnement → Envoi de messages
- **Sélecteur de topics** : Liste des topics disponibles pour l'entité
- **Aide contextuelle** : Explications détaillées de chaque action
- **Indicateurs visuels** : Badges de statut avec couleurs sémantiques
- **Tooltips informatifs** : Aide instantanée sur survol

**Note** : Cette structure est en évolution. Consultez la documentation mise à jour pour les dernières modifications.

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Développement](guide-developpement.md) - Contribuer au projet
- [Préconisations Architecture MCP](guide-preconisations.md) - Standards de développement
- [Guide du Mode Simulation](guide-mode-simulation.md) - Test sans infrastructure
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications
- [Guide des Entités Calculées](guide-entites-calculees.md) - Entités avec conversion de valeurs

---

_Documentation NeurHomIA_