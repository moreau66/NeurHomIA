# Guide des Alias MQTT

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-08T10:00:00

## Introduction

Les alias MQTT sont des noms lisibles et mémorisables qui remplacent les topics et payloads MQTT techniques. Ils simplifient la création de scénarios en permettant d'utiliser des termes comme "Lever du soleil" au lieu de `astral/default/sunrise`.

NeurHomIA propose deux systèmes d'alias complémentaires :

| Système | Description | Source |
|---------|-------------|--------|
| **Alias Globaux** | Créés par l'utilisateur pour les appareils | Store local + GitHub |
| **Alias de Microservices** | Fournis par les microservices système | Registre dynamique |

> ⚠️ **Règle critique** : Tous les noms d'alias doivent être **globalement uniques** dans le système (insensible à la casse).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ALIAS GLOBAUX                            │
│  (Utilisateur/Appareils)                                    │
├─────────────────────────────────────────────────────────────┤
│  useAliases (Store)     ←→  AliasesCache (GitHub sync)      │
│  aliasGeneratorService  ←→  Templates prédéfinis            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 ALIAS DE MICROSERVICES                       │
│  (Événements système)                                        │
├─────────────────────────────────────────────────────────────┤
│  useMicroserviceAliasRegistry  ←→  microserviceAliasDefinitions │
│  Catégories: astronomical, weather, system, time, device    │
└─────────────────────────────────────────────────────────────┘
```

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `src/store/use-aliases.ts` | Store Zustand des alias globaux |
| `src/services/aliasesCache.ts` | Cache et synchronisation GitHub |
| `src/services/aliasGeneratorService.ts` | Génération automatique d'alias |
| `src/services/microserviceAliasRegistry.ts` | Registre des alias de microservices |
| `src/types/microserviceAlias.ts` | Types pour les alias de microservices |
| `src/data/microserviceAliasDefinitions.ts` | Définitions des alias astronomiques |
| `src/hooks/useMicroserviceAliasRegistry.ts` | Hook React pour le registre |

---

## Alias Globaux

Les alias globaux sont créés par l'utilisateur pour nommer de manière lisible les topics MQTT de ses appareils.

### Interface `GlobalAlias`

```typescript
interface GlobalAlias {
  id: string;           // UUID généré automatiquement
  deviceId: string;     // ID de l'entité source
  deviceName: string;   // Nom de l'entité
  topicKey: string;     // Clé du topic (ex: "state", "brightness")
  topic: string;        // Topic MQTT complet
  payload: string;      // Payload associé
  alias: string;        // Nom lisible (doit être unique)
  description?: string; // Description optionnelle
  createdAt: string;    // Date de création ISO
  updatedAt: string;    // Date de mise à jour ISO
}
```

### Actions du Store `useAliases`

| Action | Description |
|--------|-------------|
| `addAlias(alias)` | Créer un nouvel alias |
| `updateAlias(id, updates)` | Modifier un alias existant |
| `removeAlias(id)` | Supprimer un alias |
| `getAliasesByDevice(deviceId)` | Filtrer par entité |
| `getAliasesByTopic(topicKey)` | Filtrer par clé de topic |
| `searchAliases(query)` | Recherche multi-critères |
| `aliasExists(name, excludeId?)` | Vérifier l'unicité du nom |
| `importAliases(aliases)` | Importer depuis JSON |
| `exportAliases()` | Exporter vers JSON |

### Validation d'unicité

L'unicité des noms d'alias est vérifiée automatiquement :

```typescript
// Vérification avant création/modification
const exists = aliasExists(newName, currentAliasId);
if (exists) {
  toast.error("Un alias avec ce nom existe déjà");
  return;
}
```

La comparaison est insensible à la casse et ignore les espaces superflus.

---

## Génération Automatique d'Alias

Le service `aliasGeneratorService` propose des alias pré-configurés selon le type d'appareil.

### Templates par type d'appareil

| Type | Exemples d'alias générés |
|------|--------------------------|
| `weather_station` | Température extérieure, Humidité relative, Pression atmosphérique |
| `smart_lamp` | État d'alimentation, Luminosité, Couleur |
| `smart_window` | Position des volets, Mode automatique |
| `thermostat` | Température de consigne, Mode de fonctionnement |
| `motion_sensor` | Mouvement détecté, Niveau batterie |
| `door_sensor` | État porte, Dernier mouvement |
| `smart_plug` | État prise, Consommation |

### Interface `AliasTemplate`

```typescript
interface AliasTemplate {
  topicKey: string;     // Clé du topic MQTT
  alias: string;        // Nom suggéré pour l'alias
  description: string;  // Description de l'alias
  category?: string;    // Catégorie optionnelle
}
```

### Processus de génération

1. **Recherche de templates** correspondants au type d'appareil
2. **Génération de noms intelligents** si aucun template trouvé
3. **Évitement des doublons** avec les alias existants
4. **Proposition à l'utilisateur** pour validation

```typescript
import { aliasGeneratorService } from '@/services/aliasGeneratorService';

// Obtenir les templates pour un type d'appareil
const templates = aliasGeneratorService.getTemplatesForDevice('smart_lamp');

// Générer des alias pour une entité
const suggestions = aliasGeneratorService.generateAliases(entity);
```

---

## Alias de Microservices

Les alias de microservices sont fournis par les services système (Astral2MQTT, Meteo2MQTT, etc.) et représentent des événements ou états utilisables dans les scénarios.

### Types d'alias (`AliasType`)

| Type | Description | Exemple |
|------|-------------|---------|
| `trigger` | Déclencheur d'événement | Mouvement détecté |
| `condition` | Condition à évaluer | Luminosité > 50% |
| `action` | Action à exécuter | Allumer lampe |
| `temporal_event` | Événement temporel | Lever du soleil |
| `state` | État observable | Porte ouverte |
| `sensor` | Capteur de données | Température |

### Contextes d'utilisation (`AliasUsageContext`)

| Contexte | Section du scénario |
|----------|---------------------|
| `triggers` | Quand (déclencheurs) |
| `conditions` | Si (conditions) |
| `actions` | Alors (actions) |
| `calendar` | Calendrier (événements planifiés) |

### Catégories (`AliasCategory`)

| Catégorie | Description | Exemples |
|-----------|-------------|----------|
| `astronomical` | Événements astronomiques | Lever/coucher soleil, phases lunaires |
| `weather` | Météo | Température, pluie, vent |
| `system` | Système | CPU, RAM, stockage |
| `time` | Temporel | Horaires, délais |
| `device` | Appareils | États des équipements |
| `communication` | Communication | Telegram, notifications |
| `custom` | Personnalisé | Alias sur mesure |

### Interface `MicroserviceAlias`

```typescript
interface MicroserviceAlias {
  // Identification
  id: string;
  name: string;
  description: string;
  
  // Classification
  type: AliasType;
  category: AliasCategory;
  usableIn: AliasUsageContext[];
  
  // MQTT
  mqtt_topic: string;
  mqtt_payload_schema?: object;
  
  // Paramètres configurables
  parameters?: Record<string, AliasParameter>;
  
  // Métadonnées
  icon?: string;
  color?: string;
  microserviceId: string;
  microserviceName: string;
  requiresActive: boolean;
  
  // Optionnel
  examples?: string[];
  tags?: string[];
  deprecated?: boolean;
  version?: string;
}
```

### Paramètres d'alias (`AliasParameter`)

```typescript
interface AliasParameter {
  type: 'string' | 'number' | 'boolean' | 'select' | 'time' | 'date';
  required: boolean;
  default?: any;
  min?: number;
  max?: number;
  unit?: string;
  options?: { label: string; value: any }[];
  description?: string;
  placeholder?: string;
}
```

### Exemple : Alias astronomique

```typescript
{
  id: 'astral_sunrise',
  name: 'Lever du soleil',
  description: 'Déclenche au moment du lever du soleil',
  type: 'temporal_event',
  category: 'astronomical',
  usableIn: ['triggers', 'conditions', 'calendar'],
  mqtt_topic: 'astral/{location}/sunrise',
  parameters: {
    location: { 
      type: 'string', 
      required: true, 
      default: 'default',
      description: 'Localisation géographique'
    },
    offset: { 
      type: 'number', 
      required: false, 
      default: 0, 
      min: -120, 
      max: 120, 
      unit: 'minutes',
      description: 'Décalage par rapport à l\'heure exacte'
    }
  },
  icon: '🌅',
  color: '#FF6B35',
  microserviceId: 'astral2mqtt',
  microserviceName: 'Astral2MQTT',
  requiresActive: true,
  tags: ['soleil', 'matin', 'lever', 'astronomie']
}
```

---

## Synchronisation GitHub

Les alias globaux peuvent être synchronisés avec un dépôt GitHub pour le partage et la sauvegarde.

### Configuration (`useAliasesSync`)

```typescript
interface AliasesSyncState {
  enabled: boolean;              // Synchronisation activée
  autoNotify: boolean;           // Notifications automatiques
  checkFrequency: 'daily' | 'weekly' | 'monthly' | 'manual';
  lastCheck: number;             // Timestamp dernière vérification
}
```

### Cycle de synchronisation

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Démarrage  │────▶│ localStorage │────▶│   GitHub    │
│    App      │     │   (cache)    │     │   (fetch)   │
└─────────────┘     └──────────────┘     └──────────────┘
                           │                    │
                           ▼                    ▼
                    ┌──────────────────────────────┐
                    │      Fusion des alias        │
                    │   (GitHub prioritaire)       │
                    └──────────────────────────────┘
```

1. **Initialisation** : `AliasesCache.initialize()` au démarrage
2. **Cache local** : Chargement depuis `localStorage` si disponible
3. **Vérification GitHub** : Si `shouldCheck()` retourne `true`
4. **Fusion** : Stratégie **GitHub prioritaire** pour les doublons
5. **Notification** : Alerte si doublons détectés

### Stratégie de fusion

| Situation | Comportement |
|-----------|--------------|
| Alias unique local | Conservé |
| Alias unique GitHub | Ajouté |
| Doublon (même deviceId + topicKey + payload) | GitHub écrase le local |
| Conflit de nom | Notification à l'utilisateur |

### Méthodes `AliasesCache`

| Méthode | Description |
|---------|-------------|
| `initialize()` | Initialisation au démarrage de l'app |
| `loadFromGitHub()` | Chargement depuis le dépôt GitHub |
| `loadFromLocal()` | Chargement depuis `/data/aliases.json` |
| `getMergedAliases()` | Récupère les alias fusionnés |
| `checkForUpdates()` | Vérifie les nouvelles versions |
| `forceFullReload()` | Force un rechargement complet |
| `refresh()` | Rafraîchissement manuel |
| `getLastCheck()` | Date de dernière vérification |

### Configuration GitHub

La synchronisation utilise la configuration globale GitHub :

```typescript
// Configuration dans useGitHubConfig
{
  owner: "moreau66",
  repository: "NeurHomIA",
  enabled: true,
  // Fichier source : data/aliases.json
}
```

---

## Interface de Gestion (UI)

### Page `/Aliases`

La page de gestion des alias propose :

- **Modes d'affichage** : Grille ou Liste
- **Recherche** : Multi-critères (alias, description, entité, topic)
- **Filtres avancés** : Par topic, clé, entité
- **Tri** : Sur toutes les colonnes
- **Actions en lot** : Sélection multiple pour suppression

### Création d'un alias

1. Cliquer sur "Nouvel alias"
2. Sélectionner une **entité** source
3. Choisir une **clé de topic** (state, brightness, etc.)
4. Définir le **nom** (vérifié unique) et la **description**
5. Mode avancé : Personnaliser le **payload**
6. Valider la création

### Édition d'un alias

1. Cliquer sur l'alias dans la liste
2. Modifier les champs souhaités
3. Le nom est re-validé pour l'unicité
4. Sauvegarder les modifications

### Intégration à la bibliothèque

Un alias peut être transformé en composant réutilisable :

1. Bouton "Créer composant" sur l'alias
2. Choix de la catégorie : trigger, condition, action
3. Ajout de tags personnalisés
4. Le composant devient disponible dans la bibliothèque

---

## Utilisation dans les Scénarios

### Sélection via `DeviceTopicSelector`

```typescript
import { useAliases } from '@/store/use-aliases';

function TriggerEditor({ deviceId }) {
  const { getAliasesByDevice } = useAliases();
  const availableAliases = getAliasesByDevice(deviceId);
  
  return (
    <Select>
      {availableAliases.map(alias => (
        <SelectItem key={alias.id} value={alias.id}>
          {alias.alias}
        </SelectItem>
      ))}
    </Select>
  );
}
```

### Sélection via `UnifiedActionSelector`

Le composant `UnifiedActionSelector` propose :

- **Onglet "Alias"** : Recherche directe par nom
- **Filtrage** : Par terme de recherche
- **Affichage** : Topic et payload associés
- **Insertion** : Clic pour sélectionner

### Analyse des dépendances

Le service `scenarioLifecycleService` analyse les alias utilisés :

```typescript
import { scenarioLifecycleService } from '@/services/scenarioLifecycleService';

// Analyser les dépendances d'un scénario
const dependencies = scenarioLifecycleService.analyzeDependencies(scenario);

// Résultat :
// [
//   { microserviceId: 'astral2mqtt', aliasIds: ['astral_sunrise'], available: true },
//   { microserviceId: 'meteo2mqtt', aliasIds: ['meteo_rain'], available: false }
// ]
```

### Vérification de disponibilité

Avant l'exécution, le système vérifie :

1. **Extraction** des `aliasId` depuis Quand/Si/Alors
2. **Groupement** par microservice source
3. **Vérification** de disponibilité du microservice
4. **Suspension automatique** si microservice déconnecté

---

## Registre des Microservices

### Store `useMicroserviceAliasRegistry`

| Méthode | Description |
|---------|-------------|
| `registerAlias(alias)` | Enregistrer un alias |
| `registerAliasesFromMicroservice(id, aliases)` | Enregistrer par lot |
| `unregisterMicroserviceAliases(id)` | Retirer tous les alias d'un microservice |
| `getAliasesByType(type)` | Filtrer par type |
| `getAliasesByContext(context)` | Filtrer par contexte d'usage |
| `getAliasesByCategory(category)` | Filtrer par catégorie |
| `searchAliases(query)` | Recherche textuelle |
| `isAliasAvailable(id)` | Vérifier si utilisable |
| `getMicroserviceStatus(id)` | État du microservice source |
| `getAllAliases()` | Récupérer tous les alias |

### Enregistrement par un microservice

```typescript
import { useMicroserviceAliasRegistry } from '@/hooks/useMicroserviceAliasRegistry';

function Astral2MQTTService() {
  const { registerAliasesFromMicroservice } = useMicroserviceAliasRegistry();
  
  useEffect(() => {
    registerAliasesFromMicroservice('astral2mqtt', [
      { id: 'astral_sunrise', name: 'Lever du soleil', ... },
      { id: 'astral_sunset', name: 'Coucher du soleil', ... },
      { id: 'astral_noon', name: 'Midi solaire', ... },
    ]);
  }, []);
}
```

### Persistance

Le registre est persisté dans `localStorage` :

- **Clé** : `microservice-alias-registry`
- **Format** : Sérialisation des `Map` en JSON
- **Restauration** : Automatique au chargement

---

## Bonnes Pratiques

### Nommage des alias

✅ **Recommandé** :
- Noms descriptifs et explicites
- Utiliser des termes métier
- Inclure le contexte si nécessaire

❌ **À éviter** :
- Noms techniques ou cryptiques
- Abréviations non standard
- Noms trop longs

| ❌ Mauvais | ✅ Bon |
|-----------|--------|
| `L1_ST` | `Lampe salon état` |
| `T_EXT` | `Température extérieure` |
| `zigbee_0x123_state` | `Détecteur entrée` |

### Organisation

- **Catégoriser** les alias de microservices correctement
- **Documenter** les alias personnalisés avec des descriptions
- **Utiliser les templates** automatiques quand disponibles
- **Vérifier l'unicité** avant création

### Maintenance

- **Synchroniser régulièrement** avec GitHub
- **Supprimer** les alias orphelins (entités supprimées)
- **Mettre à jour** les descriptions si les usages changent

---

## Dépannage

### Alias non disponible dans un scénario

1. **Vérifier le microservice source**
   - Le microservice doit être actif
   - Contrôler `requiresActive` dans la définition

2. **Vérifier le contexte d'usage**
   - L'alias doit être compatible avec la section (Quand/Si/Alors)
   - Voir `usableIn` dans la définition

### Doublon détecté lors de la synchronisation

1. **Comportement par défaut** : GitHub est prioritaire
2. **Conserver l'alias local** : Le renommer avec un suffixe unique
3. **Résoudre le conflit** : Supprimer l'un des deux alias

### Synchronisation GitHub échouée

1. **Vérifier la configuration**
   ```typescript
   // Dans useGitHubConfig
   { owner: "moreau66", enabled: true }
   ```

2. **Contrôler l'accès au dépôt**
   - Le dépôt doit être public
   - Le fichier `data/aliases.json` doit exister

3. **Forcer le rechargement**
   ```typescript
   await AliasesCache.forceFullReload();
   ```

### Alias non généré automatiquement

1. **Vérifier le type d'appareil**
   - Le type doit avoir des templates définis
   - Voir `aliasGeneratorService.getTemplatesForDevice()`

2. **Créer manuellement**
   - Utiliser le formulaire de création
   - Définir alias, topic et payload

---

## Voir aussi

- [Guide d'Intégration MQTT](guide-integration-mqtt.md) - Topics et messages
- [Guide des Entités MQTT](guide-entites-mqtt.md) - Configuration des entités
- [Guide des Scénarios](guide-scenarios.md) - Utilisation des alias dans les règles
- [Synchronisation GitHub](guide-synchronisation-github.md) - Configuration de la synchronisation
