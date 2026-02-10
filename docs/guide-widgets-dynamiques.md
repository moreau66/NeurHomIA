# Guide des Widgets Dynamiques 🎛️

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Les widgets dynamiques permettent de créer des interfaces personnalisées pour vos entités, générées à partir de schémas JSON. Ce guide couvre leur création, configuration et découverte automatique.

---

## 📑 Table des matières

1. [Introduction](#-introduction)
2. [Architecture du Système](#-architecture-du-système)
3. [Structure d'un Widget (WidgetSchema)](#-structure-dun-widget-widgetschema)
4. [Types de Champs](#-types-de-champs)
5. [Sections et Layouts](#-sections-et-layouts)
6. [Interactions](#-interactions)
7. [Mapping des Données](#-mapping-des-données)
8. [Découverte Automatique](#-découverte-automatique)
9. [Instances de Widgets](#-instances-de-widgets)
10. [Éditeur de Widgets](#-éditeur-de-widgets)
11. [Personnalisation et Styles](#-personnalisation-et-styles)
12. [Import/Export](#-importexport)
13. [Synchronisation GitHub](#-synchronisation-github)
14. [Bonnes Pratiques](#-bonnes-pratiques)
15. [Dépannage](#-dépannage)

---

## 📖 Introduction

### Concept

Les widgets dynamiques sont des composants UI générés automatiquement à partir de schémas JSON. Contrairement aux widgets statiques (WeatherWidget, ThermostatWidget...), ils offrent une flexibilité totale pour afficher n'importe quel type de données.

### Avantages

| Avantage | Description |
|----------|-------------|
| **Extensibilité** | Ajoutez de nouveaux widgets sans modifier le code |
| **Personnalisation** | Adaptez l'affichage à vos besoins spécifiques |
| **Découverte** | Les microservices publient leurs propres widgets |
| **Réutilisabilité** | Partagez des widgets via GitHub |

### Widgets vs Widgets Statiques

```
Widget Statique : WeatherWidget.tsx → Composant React codé
Widget Dynamique : schema.json → DynamicWidget.tsx → UI générée
```

---

## 🏗️ Architecture du Système

### Flux de données

```
WidgetSchema (JSON) → DynamicWidget → UI
       ↓                    ↓
WidgetInstance ←→ Store Zustand
       ↓
Device / Entity
```

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `src/types/dynamic-widgets.ts` | Interfaces TypeScript |
| `src/store/use-dynamic-widgets.ts` | Store Zustand |
| `src/components/widgets/DynamicWidget.tsx` | Rendu dynamique |
| `src/services/widgetDiscoveryService.ts` | Découverte MQTT |
| `src/services/dynamicWidgetsCache.ts` | Cache GitHub |
| `src/schemas/widgetSchema.ts` | Validation Zod |
| `mcp-microservice-starter-kit/schemas/widget-schema.json` | Schéma JSON officiel |

### Composants de rendu

| Composant | Description |
|-----------|-------------|
| `DynamicWidget.tsx` | Rendu principal d'un widget |
| `WidgetManager.tsx` | Résolution widget dynamique vs statique |
| `DynamicWidgetFieldRenderer.tsx` | Rendu des champs individuels |
| `DynamicWidgetSection.tsx` | Rendu des sections |

---

## 📋 Structure d'un Widget (WidgetSchema)

### Interface complète

```typescript
interface WidgetSchema {
  // Identification
  id: string;              // Identifiant unique (kebab-case)
  name: string;            // Nom d'affichage
  version: string;         // Version semver (1.0.0)
  description?: string;    // Description du widget
  author?: string;         // Auteur du widget
  
  // Compatibilité
  deviceTypes: string[];   // Types d'appareils compatibles
  
  // Affichage
  display: {
    icon?: string;           // Icône Lucide React
    primaryColor?: string;   // Couleur principale (HSL)
    secondaryColor?: string; // Couleur secondaire
    size: 'small' | 'medium' | 'large';
    refreshInterval?: number; // Intervalle de rafraîchissement (ms)
  };
  
  // Contenu
  sections: WidgetSectionConfig[];
  interactions?: WidgetInteractionConfig[];
  
  // Données
  dataMapping: Record<string, DataMappingConfig>;
  mcpResources?: Record<string, MCPResourceBinding>;
  
  // Métadonnées
  createdAt: string;
  updatedAt: string;
}
```

### Exemple minimal

```json
{
  "id": "temperature-simple",
  "name": "Température Simple",
  "version": "1.0.0",
  "deviceTypes": ["temp_sensor"],
  "display": {
    "icon": "Thermometer",
    "size": "small"
  },
  "sections": [
    {
      "id": "main",
      "fields": [
        {
          "key": "temperature",
          "label": "Température",
          "type": "number",
          "unit": "°C",
          "visible": true
        }
      ],
      "layout": "list",
      "visible": true
    }
  ],
  "dataMapping": {
    "temperature": {
      "topic": "sensor/temperature/state",
      "path": "value"
    }
  },
  "createdAt": "2026-01-18T00:00:00Z",
  "updatedAt": "2026-01-18T00:00:00Z"
}
```

---

## 🎨 Types de Champs

### Champs basiques

| Type | Description | Propriétés spécifiques |
|------|-------------|------------------------|
| `text` | Texte simple | `format`, `unit` |
| `number` | Valeur numérique | `precision`, `min`, `max`, `unit` |
| `boolean` | État ON/OFF | - |
| `icon` | Icône Lucide | `icon` |
| `button` | Bouton cliquable | `style` |

### Champs de progression

| Type | Description | Propriétés spécifiques |
|------|-------------|------------------------|
| `progress` | Barre de progression | `min`, `max`, `unit` |
| `gauge` | Jauge circulaire | `min`, `max` |

### Champs interactifs

| Type | Description | Propriétés spécifiques |
|------|-------------|------------------------|
| `slider` | Curseur interactif | `min`, `max`, `step` |
| `dial` | Cadran rotatif | `min`, `max`, `step` |
| `toggle-switch` | Interrupteur | - |
| `color-picker` | Sélecteur couleur | `colorFormat` (rgb/hex/hsv) |
| `keypad` | Clavier numérique | `codeLength`, `maxAttempts` |

### Champs avancés

| Type | Description | Propriétés spécifiques |
|------|-------------|------------------------|
| `chart` | Graphique | - |
| `rating` | Évaluation étoiles | `maxRating` |
| `status-indicator` | Indicateur d'état | `statusColors` |
| `image-viewer` | Visionneuse image | `imageUrl`, `allowZoom` |
| `timeline` | Ligne temporelle | `timelineItems` |

### Exemple de configuration

```typescript
// Champ slider
{
  key: "brightness",
  label: "Luminosité",
  type: "slider",
  min: 0,
  max: 100,
  step: 5,
  unit: "%",
  visible: true,
  style: {
    color: "hsl(45, 100%, 50%)",
    size: "medium"
  }
}

// Champ status-indicator
{
  key: "status",
  label: "État",
  type: "status-indicator",
  visible: true,
  statusColors: {
    "online": "hsl(120, 60%, 50%)",
    "offline": "hsl(0, 60%, 50%)",
    "warning": "hsl(45, 100%, 50%)"
  }
}

// Champ timeline
{
  key: "events",
  label: "Historique",
  type: "timeline",
  visible: true,
  timelineItems: [
    { date: "2026-01-18", title: "Installation", description: "Mise en service" },
    { date: "2026-01-17", title: "Configuration", description: "Paramétrage initial" }
  ]
}
```

---

## 📦 Sections et Layouts

### Interface WidgetSectionConfig

```typescript
interface WidgetSectionConfig {
  id: string;            // Identifiant unique
  title?: string;        // Titre optionnel
  fields: WidgetFieldConfig[];
  layout: 'grid' | 'list' | 'horizontal';
  columns?: number;      // Nombre de colonnes (pour grid)
  collapsible?: boolean; // Section repliable
  visible: boolean;      // Visibilité
}
```

### Types de layouts

| Layout | Description | Utilisation |
|--------|-------------|-------------|
| `list` | Empilé verticalement | Formulaires, listes simples |
| `grid` | Grille multi-colonnes | Dashboards, KPIs |
| `horizontal` | Aligné horizontalement | Boutons, contrôles compacts |

### Exemple multi-sections

```json
{
  "sections": [
    {
      "id": "header",
      "title": "État",
      "fields": [...],
      "layout": "horizontal",
      "visible": true
    },
    {
      "id": "controls",
      "title": "Contrôles",
      "fields": [...],
      "layout": "grid",
      "columns": 2,
      "collapsible": true,
      "visible": true
    },
    {
      "id": "details",
      "title": "Détails",
      "fields": [...],
      "layout": "list",
      "collapsible": true,
      "visible": true
    }
  ]
}
```

---

## 🔘 Interactions

### Interface WidgetInteractionConfig

```typescript
interface WidgetInteractionConfig {
  type: 'refresh' | 'toggle' | 'command' | 'navigate' | 'secure-command';
  label: string;
  icon?: string;
  topic?: string;         // Topic MQTT cible
  payload?: any;          // Payload à envoyer
  confirmation?: string;  // Message de confirmation
  requireCode?: boolean;  // Nécessite un code de sécurité
  style?: 'primary' | 'secondary' | 'destructive';
}
```

### Types d'interactions

| Type | Description | Exemple |
|------|-------------|---------|
| `refresh` | Rafraîchir les données | Actualiser la météo |
| `toggle` | Basculer un état | ON/OFF |
| `command` | Envoyer une commande MQTT | Ouvrir volet |
| `navigate` | Naviguer vers une page | Détails entité |
| `secure-command` | Commande avec code de sécurité | Déverrouiller porte |

### Exemple

```json
{
  "interactions": [
    {
      "type": "toggle",
      "label": "Allumer",
      "icon": "Power",
      "topic": "lamp/living/set",
      "payload": { "state": "toggle" },
      "style": "primary"
    },
    {
      "type": "secure-command",
      "label": "Déverrouiller",
      "icon": "Unlock",
      "topic": "lock/front/set",
      "payload": { "action": "unlock" },
      "confirmation": "Êtes-vous sûr de vouloir déverrouiller ?",
      "requireCode": true,
      "style": "destructive"
    }
  ]
}
```

---

## 🔗 Mapping des Données

### DataMapping (MQTT)

Configure la liaison entre les champs et les topics MQTT.

```typescript
interface DataMappingConfig {
  topic: string;          // Topic MQTT source
  path?: string;          // JSONPath pour extraire la valeur
  transform?: string;     // Transformation JavaScript
  fallback?: any;         // Valeur par défaut
}
```

### Exemple

```json
{
  "dataMapping": {
    "temperature": {
      "topic": "sensor/temp/state",
      "path": "value",
      "fallback": 0
    },
    "tempFahrenheit": {
      "topic": "sensor/temp/state",
      "path": "value",
      "transform": "value * 1.8 + 32"
    },
    "status": {
      "topic": "sensor/temp/availability",
      "path": "state",
      "fallback": "unknown"
    }
  }
}
```

### MCPResources (Microservices MCP)

Pour les widgets liés aux microservices MCP.

```typescript
interface MCPResourceBinding {
  service_id: string;      // ID du microservice
  resource_uri: string;    // URI de la ressource MCP
  method?: string;         // Méthode à appeler
  params?: any;            // Paramètres
  transform?: string;      // Transformation du résultat
  fallback?: any;          // Valeur par défaut
}
```

### Exemple MCP

```json
{
  "mcpResources": {
    "weather_data": {
      "service_id": "meteo2mqtt",
      "resource_uri": "mcp://meteo2mqtt/current",
      "method": "get_weather",
      "params": { "location": "Paris" },
      "fallback": {}
    },
    "forecast": {
      "service_id": "meteo2mqtt",
      "resource_uri": "mcp://meteo2mqtt/forecast",
      "params": { "days": 5 }
    }
  }
}
```

---

## 🔍 Découverte Automatique

### Sources de découverte

Les widgets peuvent être découverts automatiquement depuis plusieurs sources :

| Source | Description | Priorité |
|--------|-------------|----------|
| **GitHub** | Dépôt distant synchronisé | Haute |
| **MQTT** | Widgets publiés par microservices | Moyenne |
| **Local** | Fichier `/NeurHomIA/data/dynamic-widgets.json` | Basse |

### Topics MQTT de découverte

```
+/widget/discovery
homeassistant/+/widget/config
meteo2mqtt/+/widget/schema
astral2mqtt/+/widget/schema
neurhome_ia/widget/system2mqtt/+/config
```

### Catégories de widgets découverts

| Catégorie | Source | Description |
|-----------|--------|-------------|
| `github` | Dépôt GitHub | Widgets officiels et communautaires |
| `microservice` | MQTT | Widgets publiés par les microservices |
| `user` | Créé localement | Widgets personnalisés utilisateur |

### Format de message de découverte

```json
{
  "type": "widget_discovery",
  "source": "meteo2mqtt",
  "schema": {
    "id": "meteo-forecast",
    "name": "Prévisions Météo",
    "version": "1.0.0",
    ...
  }
}
```

### Adaptation des formats

Le service de découverte adapte automatiquement différents formats :

- **Format standard** : WidgetSchema natif
- **Format System2Mqtt** : Converti en WidgetSchema
- **Format Home Assistant** : Adapté si compatible

---

## 🏷️ Instances de Widgets

### Concept

Une **instance** lie un schéma de widget à un appareil spécifique.

```typescript
interface WidgetInstance {
  id: string;                // ID unique de l'instance
  schemaId: string;          // ID du WidgetSchema
  deviceId: string;          // ID de l'entité liée
  customConfig?: Partial<WidgetSchema>;  // Surcharges
  topicBindings?: TopicBindings;         // Mapping topics personnalisé
  createdAt: string;
  updatedAt: string;
}
```

### Cycle de vie

1. **Création** : Association schéma ↔ appareil
2. **Configuration** : Personnalisation des bindings
3. **Utilisation** : Rendu dans le dashboard
4. **Nettoyage** : Suppression des orphelins (appareil supprimé)

### TopicBindings

Personnalise le mapping MQTT par instance.

```typescript
interface TopicBindings {
  [fieldKey: string]: {
    subscribeTopic?: string;  // Topic d'écoute
    publishTopic?: string;    // Topic de commande
    jsonPath?: string;        // Chemin dans le JSON
  };
}
```

---

## ✏️ Éditeur de Widgets

### Composants de l'éditeur

| Composant | Description |
|-----------|-------------|
| `WidgetEditor.tsx` | Éditeur multi-onglets principal |
| `WidgetCanvas.tsx` | Canevas de conception visuelle |
| `WidgetPalette.tsx` | Palette de types de champs |
| `WidgetPropertiesPanel.tsx` | Panneau de propriétés détaillées |
| `WidgetTextualViewer.tsx` | Vue JSON brut |

### Fonctionnalités

- **Drag & Drop** : Ajout de sections et champs par glisser-déposer
- **Configuration visuelle** : Édition des propriétés via formulaires
- **Prévisualisation** : Rendu en temps réel
- **Export/Import** : Sauvegarde et partage JSON
- **Validation** : Vérification automatique du schéma

### Onglets de l'éditeur

| Onglet | Description |
|--------|-------------|
| Général | Métadonnées (nom, version, description) |
| Affichage | Configuration visuelle (icône, couleurs, taille) |
| Sections | Gestion des sections et champs |
| Interactions | Configuration des boutons d'action |
| Données | Mapping MQTT et MCP |
| Prévisualisation | Rendu du widget |
| JSON | Vue et édition du code JSON |

---

## 🎨 Personnalisation et Styles

### Style des champs

```typescript
interface FieldStyle {
  color?: string;        // Couleur du texte (HSL)
  background?: string;   // Couleur de fond
  size?: 'small' | 'medium' | 'large';
  align?: 'left' | 'center' | 'right';
}
```

### Configuration display

```typescript
display: {
  icon: "Thermometer",              // Icône Lucide React
  primaryColor: "hsl(210, 100%, 50%)",   // Couleur principale
  secondaryColor: "hsl(210, 50%, 30%)",  // Couleur secondaire
  size: "medium",                   // Taille : small, medium, large
  refreshInterval: 30000            // Rafraîchissement toutes les 30s
}
```

### Icônes disponibles

Toutes les icônes de [Lucide React](https://lucide.dev/icons/) sont supportées.

Exemples courants :
- `Thermometer`, `Droplets`, `Wind` (météo)
- `Lightbulb`, `Power`, `Plug` (électricité)
- `Lock`, `Unlock`, `Shield` (sécurité)
- `Home`, `Building`, `TreePine` (localisation)

---

## 📤 Import/Export

### Export d'un widget

```typescript
// Export simple
{
  id: "widget-id",
  schema: WidgetSchema,
  createdAt: "2026-01-18T00:00:00Z",
  updatedAt: "2026-01-18T00:00:00Z"
}
```

### Export avec métadonnées

```typescript
{
  version: "1.0.0",
  exportDate: "2026-01-18T00:00:00Z",
  type: "single",
  widgets: [{
    id: "widget-id",
    schema: WidgetSchema,
    createdAt: "...",
    updatedAt: "...",
    metadata: {
      exportedBy: "user@example.com",
      originalId: "original-id"
    }
  }]
}
```

### Export multiple

```typescript
{
  version: "1.0.0",
  exportDate: "2026-01-18T00:00:00Z",
  type: "multiple",
  widgets: [...]
}
```

### Import

L'import supporte :
- Fichiers JSON individuels
- Collections exportées
- Clonage depuis widgets découverts

---

## 🐙 Synchronisation GitHub

### Configuration

Via le store `useGitHubConfig` :

```typescript
{
  owner: "username",          // Propriétaire du dépôt
  token: "ghp_xxx",           // Token d'accès
  enabled: true,              // Activation
  repoPrefix: "NeurHomIA-"    // Préfixe des dépôts
}
```

### Cache et fusion

Le système de cache (`dynamicWidgetsCache.ts`) gère :

- **Stockage local** : localStorage avec compression
- **Priorité** : GitHub > Local > Microservice
- **Détection doublons** : Par ID de schéma
- **Notifications** : Alertes de mise à jour

### Fichier distant

Les widgets sont stockés dans :
```
data/dynamic-widgets.json
```

Format :
```json
{
  "widgets": [
    { "id": "...", "schema": {...} },
    ...
  ],
  "lastUpdated": "2026-01-18T00:00:00Z"
}
```

---

## ✅ Bonnes Pratiques

### Nommage

| Élément | Convention | Exemple |
|---------|------------|---------|
| ID widget | kebab-case | `temperature-living-room` |
| ID section | kebab-case | `main-controls` |
| Clé champ | camelCase | `currentTemperature` |

### Versioning

Utilisez le versioning sémantique :
- `1.0.0` → Version initiale
- `1.1.0` → Nouvelle fonctionnalité
- `1.0.1` → Correction de bug
- `2.0.0` → Changement incompatible

### Documentation

- Renseignez toujours `description`
- Ajoutez `author` pour les widgets partagés
- Documentez les topics attendus

### Performance

- Limitez le nombre de champs par section (< 10)
- Utilisez `refreshInterval` raisonnablement (> 10s)
- Évitez les transformations complexes dans `transform`

### Types d'appareils

Associez les bons `deviceTypes` :
```json
"deviceTypes": ["temp_sensor", "humidity_sensor"]
```

Types disponibles : voir [Guide des Entités MQTT](guide-entites-mqtt.md).

---

## 🔧 Dépannage

### Widget non affiché

| Symptôme | Cause probable | Solution |
|----------|----------------|----------|
| Widget invisible | `visible: false` | Vérifier les propriétés |
| Erreur de rendu | Schéma invalide | Valider avec le schéma Zod |
| Champs vides | Mapping incorrect | Vérifier `dataMapping` |

### Données non mises à jour

1. Vérifier le topic MQTT dans le moniteur
2. Contrôler le format du payload
3. Vérifier le `path` JSONPath
4. Tester la `transform` dans la console

### Synchronisation GitHub échouée

1. Vérifier le token d'accès
2. Contrôler les permissions du dépôt
3. Vérifier le format du fichier distant
4. Consulter les logs réseau

### Validation du schéma

Utilisez le validateur Zod :

```typescript
import { WidgetSchemaValidator } from '@/schemas/widgetSchema';

const result = WidgetSchemaValidator.safeParse(schema);
if (!result.success) {
  console.error(result.error.issues);
}
```

### Topics MQTT incorrects

- Utilisez des wildcards avec précaution (`+`, `#`)
- Vérifiez la casse (sensible)
- Testez avec le moniteur MQTT

---

## 📚 Voir aussi

- [Guide des Entités MQTT](guide-entites-mqtt.md) - Types d'entités et configuration
- [Structure JSON Microservices](microservice-json.md) - Format de découverte
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Débogage des topics

---

_Documentation NeurHomIA - Janvier 2026_
