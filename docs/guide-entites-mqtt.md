# Guide des Entités MQTT 📡

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide détaille le système d'entités MQTT de NeurHomIA : types, structure, configuration, découverte automatique, entités calculées et liens entre entités.

---

## 📑 Table des matières

1. [Introduction aux Entités](#-1-introduction-aux-entités)
2. [Types d'Entités](#-2-types-dentités)
3. [Structure d'une Entité](#-3-structure-dune-entité)
4. [Configuration des Topics MQTT](#-4-configuration-des-topics-mqtt)
5. [Catégories d'Entités](#-5-catégories-dentités)
6. [Découverte Automatique](#-6-découverte-automatique)
7. [Entités Calculées](#-7-entités-calculées)
8. [Liens entre Entités](#-8-liens-entre-entités)
9. [Métadonnées Avancées](#-9-métadonnées-avancées)
10. [Bonnes Pratiques](#-10-bonnes-pratiques)
11. [Dépannage](#-11-dépannage)
12. [API et Topics MQTT](#-12-api-et-topics-mqtt)

---

## 🎯 1. Introduction aux Entités

Une **entité** dans NeurHomIA représente tout élément connecté au système domotique. C'est l'unité de base pour :

- **Surveiller** : Lecture d'états et de valeurs via MQTT
- **Contrôler** : Envoi de commandes aux appareils
- **Automatiser** : Utilisation dans les scénarios QUAND/SI/ALORS
- **Visualiser** : Affichage dans les widgets et dashboards

Les entités communiquent via le protocole **MQTT** et peuvent être :
- Découvertes automatiquement (microservices, Home Assistant, Zigbee2MQTT, Tasmota)
- Créées manuellement via l'interface
- Calculées à partir d'autres entités

---

## 🏷️ 2. Types d'Entités

NeurHomIA distingue trois types fondamentaux d'entités :

### Tableau des Types

| Type | Constante | Description | Exemples |
|------|-----------|-------------|----------|
| **Physique** | `physical` | Appareils physiques connectés | Lampes, thermostats, capteurs, volets |
| **Virtuel** | `virtual` | États virtuels et données calculées | Météo, système, entités calculées, IA |
| **Humain** | `human` | Personnes et présences | Membres de la famille, détecteurs de présence |

### Interface TypeScript

```typescript
type EntityType = 'physical' | 'virtual' | 'human';

// Icône par défaut selon le type
const ENTITY_TYPE_ICONS = {
  physical: 'Cpu',      // Appareils physiques
  virtual: 'Cloud',     // Données virtuelles
  human: 'User',        // Personnes
};
```

### Quand utiliser chaque type ?

- **`physical`** : Pour tout appareil réel connecté en MQTT
- **`virtual`** : Pour les données système, météo, calculs, services
- **`human`** : Pour le tracking de présence et les profils utilisateurs

---

## 📦 3. Structure d'une Entité

### Interface Principale

```typescript
interface Entity {
  // Identité
  id: string;                    // Identifiant unique (ex: "lamp-salon-1")
  name: string;                  // Nom d'affichage (ex: "Lampe Salon")
  description: string;           // Description optionnelle
  
  // Classification
  type: string;                  // Catégorie (ex: "smart_lamp", "temp_sensor")
  typeId: string;                // ID de catégorie (normalisation)
  entityType: EntityType;        // physical | virtual | human
  
  // Localisation
  location: string;              // Nom de la pièce (ex: "Salon")
  locationId: string;            // ID de localisation
  
  // État
  status: "online" | "offline" | "unknown";
  lastSeen: string;              // Date ISO de dernière activité
  
  // Configuration MQTT
  mqtt_topics: Record<string, MqttTopicInfo>;
  
  // Données étendues
  metadata?: EntityMetadata;
}
```

### Interface MqttTopicInfo

```typescript
interface MqttTopicInfo {
  topic: string;                 // Topic MQTT (ex: "zigbee2mqtt/lamp/state")
  type: 'state' | 'command' | 'attributes' | 'availability';
  payload?: string;              // Dernier payload reçu
  lastValue?: string | number;   // Dernière valeur parsée
  lastUpdated?: string;          // Date de dernière mise à jour
  qos?: 0 | 1 | 2;              // Quality of Service
  retain?: boolean;              // Message retenu
}
```

### Exemple Complet

```json
{
  "id": "lamp-salon-001",
  "name": "Lampe Salon",
  "description": "Lampe LED RGBW du salon",
  "type": "Lampe intelligente",
  "typeId": "smart_lamp",
  "entityType": "physical",
  "location": "Salon",
  "locationId": "salon",
  "status": "online",
  "lastSeen": "2026-01-17T10:30:00Z",
  "mqtt_topics": {
    "state": {
      "topic": "zigbee2mqtt/lamp-salon/state",
      "type": "state",
      "lastValue": "ON"
    },
    "command": {
      "topic": "zigbee2mqtt/lamp-salon/set",
      "type": "command"
    },
    "brightness": {
      "topic": "zigbee2mqtt/lamp-salon/brightness",
      "type": "state",
      "lastValue": 75
    }
  }
}
```

---

## 🔗 4. Configuration des Topics MQTT

### Types de Topics

| Type | Usage | Direction | Exemple |
|------|-------|-----------|---------|
| `state` | Lecture de l'état | Entrée (subscribe) | `zigbee2mqtt/lamp/state` |
| `command` | Envoi de commandes | Sortie (publish) | `zigbee2mqtt/lamp/set` |
| `attributes` | Attributs supplémentaires | Entrée | `zigbee2mqtt/lamp/attributes` |
| `availability` | Disponibilité de l'entité | Entrée | `zigbee2mqtt/lamp/availability` |

### Conventions de Nommage

```
<préfixe>/<appareil>/<attribut>
```

**Exemples :**
- `zigbee2mqtt/0x00158d0001234567/state`
- `tasmota/switch-cuisine/POWER`
- `neurhomia/meteo/temperature`
- `homeassistant/light/salon/state`

### Configuration Multi-Topics

Une entité peut avoir plusieurs topics pour différents attributs :

```typescript
mqtt_topics: {
  "state": { topic: "zigbee2mqtt/lamp/state", type: "state" },
  "brightness": { topic: "zigbee2mqtt/lamp/brightness", type: "state" },
  "color_temp": { topic: "zigbee2mqtt/lamp/color_temp", type: "state" },
  "set": { topic: "zigbee2mqtt/lamp/set", type: "command" },
  "availability": { topic: "zigbee2mqtt/lamp/availability", type: "availability" }
}
```

---

## 📋 5. Catégories d'Entités

### Entités Physiques

| ID | Nom | Icône | Description |
|----|-----|-------|-------------|
| `smart_lamp` | Lampe intelligente | `Lightbulb` | LED contrôlable (on/off, luminosité, couleur) |
| `smart_thermostat` | Thermostat | `Thermometer` | Régulation de température |
| `smart_switch` | Interrupteur | `ToggleLeft` | Contrôle à distance |
| `temp_sensor` | Capteur température | `ThermometerSun` | Mesure de température ambiante |
| `humidity_sensor` | Capteur humidité | `Droplets` | Mesure d'humidité |
| `motion_sensor` | Capteur mouvement | `Activity` | Détection de présence |
| `door_sensor` | Capteur porte | `DoorOpen` | Détection ouverture/fermeture |
| `smart_plug` | Prise intelligente | `Plug` | Contrôle électrique avec mesure |
| `security_camera` | Caméra | `Camera` | Surveillance vidéo |
| `smart_lock` | Serrure | `Lock` | Contrôle d'accès |
| `roller_shutter` | Volet roulant | `ArrowUpDown` | Volet motorisé |
| `smoke_detector` | Détecteur fumée | `AlertTriangle` | Sécurité incendie |
| `water_leak_sensor` | Détecteur fuite | `Waves` | Détection de fuites d'eau |

### Entités Virtuelles

| ID | Nom | Icône | Description |
|----|-----|-------|-------------|
| `weather_state` | Météo | `Cloud` | Données météorologiques |
| `system_state` | Système | `Server` | États du système |
| `calculated_state` | Calculé | `Calculator` | Valeurs calculées/agrégées |
| `time_state` | Temporel | `Clock` | Lever/coucher soleil, heures |
| `astronomy_station` | Astronomie | `Moon` | Phases lunaires, saisons |
| `ai_assistant` | Assistant IA | `Bot` | Intégration Ollama/LLM |
| `container` | Container Docker | `Container` | Gestion Docker |
| `service` | Microservice | `Cog` | Services NeurHomIA |

### Entités Humaines

| ID | Nom | Icône | Description |
|----|-----|-------|-------------|
| `person` | Personne | `User` | Membre de la famille |
| `presence_detector` | Présence | `Users` | Détection de zone |
| `user_profile` | Profil utilisateur | `UserCog` | Préférences personnalisées |

---

## 🔍 6. Découverte Automatique

NeurHomIA supporte plusieurs protocoles de découverte automatique.

### Protocoles Supportés

| Protocole | Topic Pattern | Description |
|-----------|---------------|-------------|
| **NeurHomIA** | `+/entity/discovery` | Microservices NeurHomIA natifs |
| **Home Assistant** | `homeassistant/+/+/config` | Format HA Discovery |
| **Zigbee2MQTT** | `zigbee2mqtt/bridge/devices` | Appareils Zigbee |
| **Tasmota** | `tasmota/discovery/#` | Appareils Tasmota |
| **Docker2MQTT** | `docker2mqtt/entity/discovery` | Conteneurs Docker |

### Topics d'Écoute par Défaut

```
+/entity/discovery
microservice/+/entity/discovery
meteo2mqtt/entity/discovery
astral2mqtt/entity/discovery
docker2mqtt/entity/discovery
zigbee2mqtt/bridge/devices
homeassistant/+/+/config
tasmota/discovery/#
```

### Schéma de Découverte NeurHomIA

```typescript
interface EntityDiscoverySchema {
  entity: {
    id: string;
    name: string;
    type: string;
    typeId: string;
    entityType: EntityType;
    description?: string;
    category?: string;
    mqtt_topics: Record<string, {
      topic: string;
      type: string;
      description?: string;
    }>;
  };
  metadata?: {
    manufacturer?: string;
    model?: string;
    firmware_version?: string;
    icon?: string;
  };
  source: {
    microservice: string;
    version?: string;
    timestamp: string;
  };
}
```

### Exemple de Message de Découverte

```json
{
  "entity": {
    "id": "temp-salon-001",
    "name": "Température Salon",
    "type": "Capteur température",
    "typeId": "temp_sensor",
    "entityType": "physical",
    "description": "Capteur Xiaomi LYWSD03MMC",
    "mqtt_topics": {
      "temperature": {
        "topic": "zigbee2mqtt/temp-salon/temperature",
        "type": "state",
        "description": "Température en °C"
      },
      "humidity": {
        "topic": "zigbee2mqtt/temp-salon/humidity",
        "type": "state",
        "description": "Humidité en %"
      },
      "battery": {
        "topic": "zigbee2mqtt/temp-salon/battery",
        "type": "state",
        "description": "Niveau de batterie en %"
      }
    }
  },
  "metadata": {
    "manufacturer": "Xiaomi",
    "model": "LYWSD03MMC",
    "firmware_version": "1.0.0_0159",
    "icon": "ThermometerSun"
  },
  "source": {
    "microservice": "zigbee2mqtt",
    "version": "1.35.0",
    "timestamp": "2026-01-17T10:00:00Z"
  }
}
```

### Activer la Découverte

1. Aller dans **Entités** > **Découverte**
2. Configurer les protocoles actifs
3. Cliquer sur "Démarrer la découverte"
4. Les entités apparaissent automatiquement

---

## ⚡ 7. Entités Calculées

Les entités calculées permettent de créer des valeurs dérivées à partir d'autres entités.

> 📖 Pour une documentation détaillée, consultez le [Guide des Entités Calculées](guide-entites-calculees.md).

### Types de Calcul

| Type | Description | Exemple |
|------|-------------|---------|
| `average` | Moyenne de plusieurs valeurs | Température moyenne maison |
| `sum` | Somme de valeurs | Consommation électrique totale |
| `min` | Valeur minimale | Température la plus basse |
| `max` | Valeur maximale | Température la plus haute |
| `count` | Comptage | Nombre de fenêtres ouvertes |
| `custom` | Formule personnalisée | Calculs complexes |
| `conversion` | Conversion de valeur | Batterie → Niveau (Bon/Faible) |

### Types de Conversion

19 types de conversion sont disponibles :

| Conversion | Entrée | Sortie |
|------------|--------|--------|
| `battery_to_level` | Pourcentage batterie | Bon / Moyen / Faible / Critique |
| `signal_to_quality` | Force signal dB | Excellent / Bon / Moyen / Faible |
| `temperature_to_comfort` | Température °C | Froid / Frais / Confortable / Chaud |
| `humidity_to_level` | Humidité % | Sec / Normal / Humide |
| `percentage_to_grade` | Pourcentage | A / B / C / D / E |
| `numeric_to_boolean` | Nombre | Vrai / Faux |

### Configuration

```typescript
interface CalculationConfig {
  type: 'average' | 'sum' | 'min' | 'max' | 'count' | 'custom' | 'conversion';
  sourceEntities?: string[];       // IDs des entités sources
  sourceTopic?: string;            // Topic source (pour conversion)
  formula?: string;                // Formule personnalisée
  conversionType?: string;         // Type de conversion
  valueRange?: {                   // Plages de valeurs
    min: number;
    max: number;
    levels: { value: number; label: string; color: string }[];
  };
  updateTrigger?: 'realtime' | 'periodic' | 'on_change';
  updateInterval?: number;         // Intervalle en secondes
}
```

---

## 🔗 8. Liens entre Entités

Le système **EntityLink** permet de créer des automatisations simples entre entités sans passer par les scénarios complets.

### Concept

Un lien définit une relation **Source → Cibles** :
- Quand la source publie un message
- Une ou plusieurs actions sont déclenchées sur les cibles

### Interface EntityLink

```typescript
interface EntityLink {
  id: string;
  name: string;
  description?: string;
  enabled: boolean;
  
  // Source
  sourceEntityId: string;
  sourceTopic: string;
  
  // Déclencheur
  trigger: EntityLinkTrigger;
  
  // Cibles
  targets: EntityLinkTarget[];
  
  // Métadonnées
  createdAt: string;
  updatedAt: string;
  executionCount: number;
  lastExecutedAt?: string;
}
```

### Types de Déclencheurs

| Type | Description | Usage |
|------|-------------|-------|
| `state_change` | Changement d'état spécifique | "Quand passe à ON" |
| `value_change` | Toute modification de valeur | "Quand la valeur change" |
| `any_message` | N'importe quel message | "Quand un message arrive" |
| `conditional_mapping` | Mappages conditionnels | "ON→ON, OFF→OFF" |

### Configuration des Déclencheurs

```typescript
interface EntityLinkTrigger {
  type: 'state_change' | 'value_change' | 'any_message' | 'conditional_mapping';
  
  // Pour state_change
  fromState?: string;              // État de départ (optionnel)
  toState?: string;                // État d'arrivée
  
  // Pour conditional_mapping
  mappings?: TriggerValueMapping[];
}

interface TriggerValueMapping {
  triggerValue: string;            // Valeur déclenchante
  targetPayloads: Record<string, string>;  // Payloads par cible
}
```

### Configuration des Cibles

```typescript
interface EntityLinkTarget {
  id: string;
  entityId: string;
  topic: string;
  payload?: string;                // Payload fixe
  payloadTemplate?: string;        // Template avec variables
  delay?: number;                  // Délai en ms
}
```

### Exemple Complet

```json
{
  "id": "link-interrupteur-lampes",
  "name": "Interrupteur → Lampes Salon",
  "description": "L'interrupteur contrôle les 3 lampes du salon",
  "enabled": true,
  "sourceEntityId": "switch-salon-001",
  "sourceTopic": "zigbee2mqtt/switch-salon/action",
  "trigger": {
    "type": "conditional_mapping",
    "mappings": [
      {
        "triggerValue": "on",
        "targetPayloads": {
          "target-1": "{\"state\":\"ON\"}",
          "target-2": "{\"state\":\"ON\"}",
          "target-3": "{\"state\":\"ON\"}"
        }
      },
      {
        "triggerValue": "off",
        "targetPayloads": {
          "target-1": "{\"state\":\"OFF\"}",
          "target-2": "{\"state\":\"OFF\"}",
          "target-3": "{\"state\":\"OFF\"}"
        }
      }
    ]
  },
  "targets": [
    { "id": "target-1", "entityId": "lamp-salon-001", "topic": "zigbee2mqtt/lamp-1/set" },
    { "id": "target-2", "entityId": "lamp-salon-002", "topic": "zigbee2mqtt/lamp-2/set" },
    { "id": "target-3", "entityId": "lamp-salon-003", "topic": "zigbee2mqtt/lamp-3/set" }
  ],
  "executionCount": 142,
  "lastExecutedAt": "2026-01-17T10:30:00Z"
}
```

### Liens vs Scénarios

| Critère | EntityLink | Scénario |
|---------|------------|----------|
| Complexité | Simple (1 source → N cibles) | Complexe (QUAND/SI/ALORS) |
| Conditions | Mappages simples | Conditions multiples, opérateurs logiques |
| Planification | Non | Oui (cron, astronomique, périodique) |
| Performance | Très rapide | Standard |
| Usage | Liaisons directes | Automatisations avancées |

---

## 📊 9. Métadonnées Avancées

### Interface EntityMetadata

```typescript
interface EntityMetadata {
  // Informations fabricant
  manufacturer?: string;
  model?: string;
  firmware_version?: string;
  hardware_version?: string;
  serial_number?: string;
  
  // Visuel
  icon?: string;                   // Nom d'icône Lucide
  color?: string;                  // Couleur personnalisée
  image_url?: string;              // Image de l'appareil
  
  // Maintenance
  installation_date?: string;
  last_maintenance?: string;
  warranty_end?: string;
  notes?: string;
  
  // Intégration
  integration_type?: string;       // zigbee, wifi, zwave...
  gateway_id?: string;
  room_id?: string;
  floor_id?: string;
  
  // Sécurité
  is_critical?: boolean;           // Appareil critique
  requires_confirmation?: boolean; // Confirmation avant action
  
  // Métriques
  battery_level?: number;
  signal_strength?: number;
  uptime_seconds?: number;
  error_count?: number;
  
  // Alertes
  alerts?: AlertConfig[];
  
  // Données personnalisées
  custom?: Record<string, any>;
}
```

### Configuration des Alertes

```typescript
interface AlertConfig {
  id: string;
  name: string;
  enabled: boolean;
  condition: {
    topic: string;
    operator: '=' | '!=' | '>' | '<' | '>=' | '<=';
    value: string | number;
  };
  severity: 'info' | 'warning' | 'error' | 'critical';
  notification: {
    type: 'toast' | 'email' | 'mqtt' | 'webhook';
    target?: string;
  };
  cooldown?: number;               // Temps minimum entre alertes (secondes)
}
```

---

## ✅ 10. Bonnes Pratiques

### Nommage

- **IDs** : Utiliser un format cohérent `type-location-numero` (ex: `lamp-salon-001`)
- **Noms** : Descriptifs et lisibles (ex: "Lampe Plafond Salon")
- **Topics** : Suivre les conventions du protocole utilisé

### Organisation

- **Localisations** : Grouper les entités par pièce/zone
- **Catégories** : Utiliser les `typeId` standards
- **Tags** : Ajouter des métadonnées personnalisées si nécessaire

### Performance

- **QoS** : Utiliser QoS 0 pour les états fréquents, QoS 1 pour les commandes critiques
- **Retain** : Activer pour les états, désactiver pour les événements
- **Découverte** : Limiter la fréquence des scans automatiques

### Sécurité

- **Appareils critiques** : Marquer `is_critical: true` pour les serrures, alarmes
- **Confirmation** : Activer `requires_confirmation` pour les actions sensibles
- **Alertes** : Configurer des alertes pour les états anormaux

---

## 🐛 11. Dépannage

### Entité non détectée

1. Vérifier que le protocole de découverte est activé
2. Vérifier la connexion MQTT au broker
3. Vérifier que l'appareil publie sur les topics attendus
4. Consulter les logs de découverte dans le Moniteur MQTT

### Statut "offline" permanent

1. Vérifier le topic `availability` de l'entité
2. Vérifier que l'appareil est alimenté
3. Vérifier la connectivité réseau/Zigbee/Z-Wave
4. Redémarrer l'appareil ou le coordinateur

### Valeurs non mises à jour

1. Vérifier le topic `state` configuré
2. Vérifier le format du payload (JSON vs texte)
3. Vérifier les permissions de souscription MQTT
4. Consulter l'historique des messages dans le Moniteur

### Commandes sans effet

1. Vérifier le topic `command` configuré
2. Vérifier le format du payload attendu par l'appareil
3. Vérifier les permissions de publication MQTT
4. Tester manuellement avec un client MQTT (MQTT Explorer)

### Entité calculée incorrecte

1. Vérifier les entités sources configurées
2. Vérifier la formule ou le type de conversion
3. Vérifier que les sources publient des valeurs numériques
4. Consulter le [Guide des Entités Calculées](guide-entites-calculees.md)

---

## 📡 12. API et Topics MQTT

### Topics de Monitoring

| Topic | Description |
|-------|-------------|
| `neurhomia/entities/status` | État global des entités |
| `neurhomia/entities/+/state` | État d'une entité spécifique |
| `neurhomia/entities/discovery` | Événements de découverte |
| `neurhomia/entities/errors` | Erreurs liées aux entités |

### Format des Messages d'État

```json
{
  "entity_id": "lamp-salon-001",
  "state": "ON",
  "attributes": {
    "brightness": 75,
    "color_temp": 350
  },
  "timestamp": "2026-01-17T10:30:00Z"
}
```

### Commandes Standards

```json
// Allumer une lampe
{ "state": "ON" }

// Régler la luminosité
{ "state": "ON", "brightness": 128 }

// Changer la couleur
{ "state": "ON", "color": { "r": 255, "g": 100, "b": 50 } }

// Commande de volet
{ "position": 50 }  // 0 = fermé, 100 = ouvert
```

---

## 📚 Voir aussi

- [Guide des Scénarios](guide-scenarios.md) - Utiliser les entités dans les automatisations
- [Guide des Entités Calculées](guide-entites-calculees.md) - Créer des entités avec formules
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveiller les communications
- [Guide du Local Engine](guide-local-engine.md) - Backend d'exécution des scénarios
- [Structure JSON Microservices](microservice-json.md) - Format de découverte

---

_Documentation NeurHomIA - Janvier 2026_
