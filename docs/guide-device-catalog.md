# Catalogue d'Appareils Multi-Technologies 📦

> **Version** : 1.0.0 | **Mise à jour** : 2026-03-01T10:00:00

Guide complet du système de catalogue d'appareils générique multi-technologies (Zigbee, Z-Wave, Matter, KNX, Custom). Architecture MQTT, transfert d'images base64 avec chunking, conversion `exposes` → `TopicConfig` et composants UI.

---

## 📑 Table des matières

1. [Introduction](#1-introduction)
2. [Architecture MQTT](#2-architecture-mqtt)
3. [Topics MQTT](#3-topics-mqtt)
4. [Format DeviceDefinition](#4-format-devicedefinition)
5. [Technologies supportées](#5-technologies-supportées)
6. [Conversion exposes → TopicConfig](#6-conversion-exposes--topicconfig)
7. [Transfert d'images MQTT](#7-transfert-dimages-mqtt)
8. [Lazy loading des images](#8-lazy-loading-des-images)
9. [Store Zustand useDeviceCatalog](#9-store-zustand-usedevicecatalog)
10. [Composants UI](#10-composants-ui)
11. [Intégration éditeur de catégorie](#11-intégration-éditeur-de-catégorie)
12. [Créer un microservice de catalogue](#12-créer-un-microservice-de-catalogue)

---

## 1. Introduction

Le système de catalogue permet à tout microservice de publier une base de données d'appareils via MQTT dans un format standardisé. Le frontend reçoit, indexe et affiche ces catalogues automatiquement, indépendamment de la technologie source.

**Principe** : un microservice (ex: `devicedb2mqtt`) lit les définitions d'appareils depuis une source (fichiers JSON, base de données, API) et les publie sur des topics MQTT normalisés. Le frontend les stocke dans un store Zustand persisté en localStorage.

---

## 2. Architecture MQTT

```
┌─────────────────────┐     ┌─────────────────────┐     ┌──────────────────┐
│  devicedb2mqtt      │     │  zwavedb2mqtt       │     │  matterdb2mqtt   │
│  (Zigbee catalog)   │     │  (Z-Wave catalog)   │     │  (Matter catalog)│
└────────┬────────────┘     └────────┬────────────┘     └────────┬─────────┘
         │                           │                           │
         │  MQTT publish             │  MQTT publish             │  MQTT publish
         ▼                           ▼                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Broker MQTT (Mosquitto)                            │
│                                                                             │
│  devicedb/zigbee/devices/list     devicedb/zwave/devices/list               │
│  devicedb/zigbee/images/{model}   devicedb/zwave/images/{model}             │
│  devicedb/zigbee/heartbeat        devicedb/matter/devices/list              │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     │  MQTT subscribe (wildcards)
                                     ▼
                          ┌──────────────────────┐
                          │   Frontend NeurHomIA │
                          │                      │
                          │  useDeviceCatalog    │
                          │  DeviceModelPicker   │
                          │  DeviceCatalogImage  │
                          └──────────────────────┘
```

---

## 3. Topics MQTT

| Topic                                    | Direction     | Description                                    |
| ---------------------------------------- | ------------- | ---------------------------------------------- |
| `devicedb/{tech}/devices/list`           | MS → Frontend | Liste complète des appareils d'une technologie |
| `devicedb/{tech}/devices/{model}`        | MS → Frontend | Définition d'un appareil spécifique            |
| `devicedb/{tech}/images/{model}`         | MS → Frontend | Image base64 (avec support chunking)           |
| `devicedb/{tech}/images/{model}/request` | Frontend → MS | Requête lazy d'une image                       |
| `devicedb/{tech}/heartbeat`              | MS → Frontend | Heartbeat du microservice                      |
| `mcp/services/devicedb/discovery`        | MS → Frontend | Discovery MCP du service                       |

**Wildcards souscrits par le frontend** :

- `devicedb/+/devices/list` — toutes les listes
- `devicedb/+/images/+` — toutes les images

Les helpers TypeScript sont dans `DEVICE_CATALOG_TOPICS` :

```typescript
import { DEVICE_CATALOG_TOPICS } from '@/types/device-catalog';

DEVICE_CATALOG_TOPICS.devicesList('zigbee')       // "devicedb/zigbee/devices/list"
DEVICE_CATALOG_TOPICS.deviceImage('zigbee', 'E27') // "devicedb/zigbee/images/E27"
DEVICE_CATALOG_TOPICS.requestImage('zigbee', 'E27') // "devicedb/zigbee/images/E27/request"
```

---

## 4. Format DeviceDefinition

Chaque appareil suit l'interface `DeviceDefinition` :

```typescript
interface DeviceDefinition {
  model: string;            // Identifiant unique du modèle
  vendor: string;           // Fabricant
  description: string;      // Description courte
  technology: DeviceTechnology; // 'zigbee' | 'zwave' | 'matter' | 'knx' | 'custom'
  zigbee_models?: string[]; // Modèles Zigbee alternatifs (optionnel)
  features: string[];       // Catégories de fonctionnalités (ex: ['light', 'sensor'])
  exposes: DeviceExpose[];  // Capacités exposées (détail ci-dessous)
  options?: DeviceOption[]; // Options de configuration optionnelles
  imageBase64?: string;     // Image embarquée (optionnel)
  imageFormat?: 'png' | 'jpg' | 'webp' | 'svg';
}
```

### Exemple concret — WF4C_WF6C (Zigbee)

```json
{
  "model": "WF4C_WF6C",
  "vendor": "Acuity Brands Lighting (ABL)",
  "description": "Juno 4\" and 6\" LED smart wafer downlight",
  "technology": "zigbee",
  "zigbee_models": ["ABL-LIGHT-Z-201"],
  "features": ["light"],
  "exposes": [
    {
      "type": "light",
      "features": {
        "state": true,
        "brightness": { "range": [0, 254] },
        "color_temp": { "range": [200, 370], "unit": "mireds" }
      }
    },
    {
      "type": "numeric",
      "property": "linkquality",
      "access": 1
    }
  ]
}
```

### Message de liste (DeviceCatalogListMessage)

```json
{
  "technology": "zigbee",
  "version": "1.0.0",
  "count": 2847,
  "devices": [ /* tableau de DeviceDefinition */ ],
  "timestamp": "2026-03-01T10:00:00Z"
}
```

---

## 5. Technologies supportées

| Technologie | Clé      | Icône | Exemple microservice           |
| ----------- | -------- | ----- | ------------------------------ |
| Zigbee      | `zigbee` | 📡    | `devicedb2mqtt`                |
| Z-Wave      | `zwave`  | 🔗    | `zwavedb2mqtt`                 |
| Matter      | `matter` | 🏠    | `matterdb2mqtt`                |
| KNX         | `knx`    | 🔌    | `knxdb2mqtt`                   |
| Custom      | `custom` | ⚙️    | Tout microservice personnalisé |

Le type `DeviceTechnology` et les labels/icônes associés sont définis dans `src/types/device-catalog.ts`.

---

## 6. Conversion exposes → TopicConfig

Le service `deviceCatalogService.ts` convertit les `exposes` d'un appareil en `TopicConfig[]` utilisables par l'éditeur d'entités.

### Fonction principale

```typescript
import { convertExposesToTopics } from '@/services/deviceCatalogService';

const topics = convertExposesToTopics(device.exposes, 'zigbee', 'zigbee2mqtt/salon/lumiere');
// → TopicConfig[] prêtes pour l'éditeur
```

### Table des mappings features connus

| Feature                           | Description         | Catégorie  | Type    | Unité  |
| --------------------------------- | ------------------- | ---------- | ------- | ------ |
| `state`                           | État on/off         | state      | string  | —      |
| `brightness`                      | Luminosité          | control    | number  | —      |
| `color_temp`                      | Température couleur | control    | number  | mireds |
| `color` / `color_xy` / `color_hs` | Couleur             | control    | json    | —      |
| `temperature`                     | Température         | sensor     | number  | °C     |
| `humidity`                        | Humidité            | sensor     | number  | %      |
| `pressure`                        | Pression            | sensor     | number  | hPa    |
| `occupancy`                       | Présence            | sensor     | boolean | —      |
| `contact`                         | Contact             | sensor     | boolean | —      |
| `battery`                         | Batterie            | diagnostic | number  | %      |
| `linkquality`                     | Qualité signal      | diagnostic | number  | lqi    |
| `power`                           | Puissance           | sensor     | number  | W      |
| `energy`                          | Énergie             | sensor     | number  | kWh    |
| `voltage`                         | Tension             | sensor     | number  | V      |
| `current`                         | Intensité           | sensor     | number  | A      |
| `position`                        | Position volet      | control    | number  | %      |
| `water_leak`                      | Fuite d'eau         | sensor     | boolean | —      |
| `smoke`                           | Fumée               | sensor     | boolean | —      |
| `co2`                             | CO2                 | sensor     | number  | ppm    |
| `illuminance`                     | Luminosité ambiante | sensor     | number  | lx     |

Les features non listées sont converties avec des valeurs par défaut (catégorie `state`, type `string`).

### Conversion complète device → catégorie

```typescript
import { deviceToEntityCategory } from '@/services/deviceCatalogService';

const category = deviceToEntityCategory(device);
// → { name, description, icon, defaultTopics, metadata }
```

---

## 7. Transfert d'images MQTT

Les images sont transférées en base64 via MQTT sur `devicedb/{tech}/images/{model}`.

### Format du message (DeviceImageMessage)

```typescript
interface DeviceImageMessage {
  model: string;
  technology: DeviceTechnology;
  format: 'png' | 'jpg' | 'webp' | 'svg';
  size: number;          // Taille en octets de l'image complète
  data: string;          // Base64 (un chunk)
  chunk: number;         // Numéro du chunk (1-indexed)
  totalChunks: number;   // Nombre total de chunks
  timestamp: string;
}
```

### Protocole de chunking

Pour les images dépassant **128 kB** en base64, le microservice découpe les données en plusieurs messages :

1. Le microservice calcule `totalChunks = ceil(base64.length / CHUNK_SIZE)`
2. Chaque message porte `chunk` (1 à N) et `totalChunks`
3. Le frontend accumule les chunks dans un `DeviceImageChunkBuffer`
4. Quand `receivedChunks.size === totalChunks`, les chunks sont concaténés dans l'ordre
5. Le résultat est converti en data URL : `data:image/{format};base64,{fullData}`

```
Microservice                           Frontend (useDeviceCatalog)
    │                                       │
    │── chunk 1/3 ─────────────────────────▶│ buffer.set(1, data)
    │── chunk 2/3 ─────────────────────────▶│ buffer.set(2, data)
    │── chunk 3/3 ─────────────────────────▶│ buffer.set(3, data)
    │                                       │ → 3/3 reçus → reconstruction
    │                                       │ → data URL stockée dans images[]
```

Pour les images ≤ 128 kB, un seul message avec `chunk: 1, totalChunks: 1` suffit.

---

## 8. Lazy loading des images

Les images ne sont pas envoyées avec le catalogue initial. Elles sont chargées **à la demande** quand un composant en a besoin.

### Mécanisme

1. Le composant `DeviceCatalogImage` vérifie si l'image est dans le cache (`images[key]`)
2. Si absente, il appelle `requestImage(tech, model)` du store
3. Le store publie sur `devicedb/{tech}/images/{model}/request` :
   ```json
   { "model": "WF4C_WF6C", "technology": "zigbee", "timestamp": "..." }
   ```
4. Le microservice reçoit la requête et publie l'image sur `devicedb/{tech}/images/{model}`
5. Le store reçoit l'image, la reconstruit si chunked, et la stocke dans `images[]`
6. Le composant se met à jour automatiquement via Zustand

### Protection anti-doublon

- Un `Set<string>` non persisté (`pendingImageRequests`) empêche les requêtes multiples
- Si l'image est déjà dans le cache ou déjà demandée, `requestImage()` est un no-op
- Le set est nettoyé à la réception de l'image complète

---

## 9. Store Zustand useDeviceCatalog

Fichier : `src/store/use-device-catalog.ts`

### État

| Propriété            | Type                                                                  | Description                                     |
| -------------------- | --------------------------------------------------------------------- | ----------------------------------------------- |
| `devices`            | `Partial<Record<DeviceTechnology, Record<string, DeviceDefinition>>>` | Devices indexés par technologie puis modèle     |
| `images`             | `Record<string, string>`                                              | Cache d'images data URL (clé: `{tech}/{model}`) |
| `technologies`       | `DeviceTechnology[]`                                                  | Technologies découvertes                        |
| `isLoading`          | `boolean`                                                             | Chargement en cours                             |
| `searchQuery`        | `string`                                                              | Terme de recherche                              |
| `selectedTechnology` | `DeviceTechnology \| 'all'`                                           | Filtre technologie                              |
| `lastUpdated`        | `Partial<Record<DeviceTechnology, Date>>`                             | Dernière mise à jour par techno                 |

### Actions principales

| Action                        | Description                                            |
| ----------------------------- | ------------------------------------------------------ |
| `loadCatalog(msg)`            | Charge un catalogue complet reçu via MQTT              |
| `loadDevice(tech, device)`    | Ajoute/met à jour un device individuel                 |
| `handleImageMessage(msg)`     | Traite un message d'image (avec chunking)              |
| `requestImage(tech, model)`   | Publie une requête d'image lazy                        |
| `isImagePending(tech, model)` | Vérifie si une image est en cours de chargement        |
| `subscribeToMqtt()`           | Souscrit aux wildcards et retourne un unsubscribe      |
| `getFilteredDevices()`        | Retourne les devices filtrés par recherche/technologie |
| `getDevice(tech, model)`      | Retourne un device spécifique                          |
| `getTotalCount()`             | Nombre total de devices toutes technologies            |
| `reset()`                     | Réinitialise le store                                  |

### Persistance

Le store est persisté dans `localStorage` sous la clé `neurhomia-device-catalog`. Seules les données sont persistées (`devices`, `images`, `technologies`, `lastUpdated`). Les buffers de chunks et les requêtes pendantes ne sont pas persistés.

---

## 10. Composants UI

### DeviceModelPicker

Fichier : `src/components/entity-editor/DeviceModelPicker.tsx`

Dialog de sélection d'un modèle d'appareil depuis le catalogue.

**Fonctionnalités** :

- Filtrage par technologie via onglets
- Recherche par modèle, fabricant ou description
- Aperçu de l'image lazy-loaded via MQTT
- Affichage des features et du nombre d'exposes
- Pré-remplissage automatique de la configuration de l'éditeur

**Props** :

```typescript
interface DeviceModelPickerProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (device: DeviceDefinition, autoConfig: ReturnType<typeof deviceToEntityCategory>) => void;
}
```

### DeviceCatalogImage

Fichier : `src/components/entity-editor/DeviceCatalogImage.tsx`

Composant d'image lazy-loaded depuis le catalogue MQTT.

**Comportement** :

1. Vérifie le cache d'images du store
2. Si absent : déclenche `requestImage()` et affiche un `Skeleton`
3. Si reçu : affiche l'image avec `object-contain`
4. Si pas de réponse : affiche un emoji fallback

**Props** :

```typescript
interface DeviceCatalogImageProps {
  model: string;
  technology: DeviceTechnology;
  fallback?: string;    // Emoji par défaut : '📦'
  className?: string;
  imgClassName?: string;
}
```

---

## 11. Intégration éditeur de catégorie

Le `DeviceModelPicker` s'intègre dans l'éditeur de catégories d'entités via un bouton "Catalogue" :

1. L'utilisateur ouvre le picker depuis l'éditeur de catégorie
2. Il sélectionne un modèle d'appareil
3. Le callback `onSelect` reçoit le `DeviceDefinition` et la configuration auto-générée
4. L'éditeur pré-remplit :
   - **Nom** : `{vendor} {model}`
   - **Description** : description du device
   - **Icône** : emoji basé sur les features (💡 light, 🌡️ climate, etc.)
   - **Topics** : `TopicConfig[]` générés depuis les `exposes`

---

## 12. Créer un microservice de catalogue

Pour ajouter le support d'une nouvelle technologie, créez un microservice qui respecte le protocole suivant :

### Protocole obligatoire

1. **Publication du catalogue** sur `devicedb/{tech}/devices/list` au format `DeviceCatalogListMessage`
2. **Heartbeat** sur `devicedb/{tech}/heartbeat` toutes les 30 secondes
3. **Discovery MCP** sur `mcp/services/devicedb/discovery` pour la détection automatique
4. **Réponse aux requêtes d'images** : souscrire à `devicedb/{tech}/images/+/request`, répondre sur `devicedb/{tech}/images/{model}`

### Template Docker Compose

```yaml
services:
  {tech}db2mqtt:
    image: neurhomia/{tech}db2mqtt:latest
    container_name: {tech}db2mqtt
    restart: unless-stopped
    environment:
      - MQTT_HOST=mosquitto
      - MQTT_PORT=1883
      - TECHNOLOGY={tech}
      - PUBLISH_INTERVAL=3600
      - CHUNK_SIZE=131072
    depends_on:
      - mosquitto
```

### Checklist

- [ ] Publie sur `devicedb/{tech}/devices/list` au démarrage et périodiquement
- [ ] Chaque `DeviceDefinition` a un `model` unique, un `vendor`, des `features` et des `exposes`
- [ ] Souscrit à `devicedb/{tech}/images/+/request` pour le lazy loading
- [ ] Découpe les images > 128 kB en chunks de 128 kB max
- [ ] Publie un heartbeat régulier
- [ ] Publie le message de discovery MCP

---

## 🔗 Fichiers associés

| Fichier                                               | Rôle                                        |
| ----------------------------------------------------- | ------------------------------------------- |
| `src/types/device-catalog.ts`                         | Types, interfaces et helpers de topics      |
| `src/store/use-device-catalog.ts`                     | Store Zustand (état, MQTT, cache)           |
| `src/services/deviceCatalogService.ts`                | Conversion exposes → TopicConfig, recherche |
| `src/components/entity-editor/DeviceModelPicker.tsx`  | UI de sélection                             |
| `src/components/entity-editor/DeviceCatalogImage.tsx` | Image lazy-loaded MQTT                      |

---

## 📖 Voir aussi

- [Guide Microservices](guide-microservices.md) — Catalogue des microservices NeurHomIA
- [Guide Intégration MQTT](guide-integration-mqtt.md) — Brokers, connexion et souscription
- [Guide Entités MQTT](guide-entites-mqtt.md) — Types d'entités et configuration
