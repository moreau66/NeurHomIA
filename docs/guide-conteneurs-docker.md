# Guide des Conteneurs Docker

## Vue d'ensemble

NeurHomeIA utilise une architecture modulaire basée sur des **templates de conteneurs Docker**. Cette approche permet :

- **Déploiement rapide** de microservices préconfigurés
- **Synchronisation des versions** depuis GitHub
- **Mises à jour automatiques** via Watchtower
- **Gestion centralisée** de l'ensemble des services

Le système s'articule autour de quatre composants principaux :

```
┌─────────────────────────────────────────────────────────────────┐
│                    Interface Utilisateur                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ TemplateManager │  │ ContainerPanel  │  │ Watchtower      │  │
│  │ (Catalogue)     │  │ (Déployés)      │  │ Notifications   │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
└───────────┼─────────────────────┼─────────────────────┼─────────┘
            │                     │                     │
            ▼                     ▼                     ▼
┌─────────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ ContainerTemplate   │  │ useContainers   │  │ watchtowerSvc   │
│ Cache               │  │ (Zustand Store) │  │ (MQTT Events)   │
│ - GitHub sync       │  │ - État déployé  │  │ - MAJ auto      │
│ - Versions          │  │ - Config        │  │ - Notifications │
└─────────┬───────────┘  └─────────────────┘  └─────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Repositories                          │
│  MCP-Mosquitto  │  MCP-Zigbee2Mqtt  │  MCP-Docker2Mqtt  │  ...  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Templates de Conteneurs

### Structure d'un Template

Chaque template de conteneur suit l'interface `ContainerTemplate` définie dans `src/data/containerTemplates.ts` :

```typescript
interface ContainerTemplate {
  // Identification
  id: string;                    // Identifiant unique (ex: "mosquitto")
  name: string;                  // Nom d'affichage (ex: "Eclipse Mosquitto")
  category: "core" | "optional" | "custom";
  
  // Description
  description: string;           // Description courte
  longDescription?: string;      // Description détaillée
  
  // Image Docker
  image: string;                 // Image Docker (ex: "eclipse-mosquitto")
  defaultVersion: string;        // Version par défaut (ex: "2.0.18")
  
  // Configuration réseau
  ports: ContainerPortMapping[]; // Mappings de ports
  webUrl?: string;               // URL de l'interface web
  
  // Stockage
  volumes: ContainerVolumeMapping[];
  
  // Environnement
  environment: ContainerEnvVar[];
  
  // Politique de redémarrage
  restart: "no" | "always" | "on-failure" | "unless-stopped";
  autoStart: boolean;
  
  // Métadonnées
  icon?: string;                 // Icône Lucide (ex: "Radio")
  tags: string[];                // Tags pour le filtrage
  author?: string;
  createdAt?: string;
  
  // Documentation
  documentation?: string;
  repoUrl?: string;              // URL du repository GitHub
  readmeUrl?: string;            // URL du README
  
  // Configuration MCP (optionnel)
  mcp_metadata?: {
    service_id: string;
    topics: {
      discovery: string;
      data?: string;
      commands?: string;
    };
    ui_component?: {
      component_path: string;
      mode?: "embedded" | "standalone";
    };
    schemas?: {
      mcp?: string;
      tools?: string;
      resources?: string;
    };
  };
}
```

### Types de Mappings

#### Ports

```typescript
interface ContainerPortMapping {
  container: number;  // Port interne au conteneur
  host: number;       // Port exposé sur l'hôte
}

// Exemple
{ container: 1883, host: 1883 }  // MQTT
{ container: 8080, host: 8080 }  // Web UI
```

#### Volumes

```typescript
interface ContainerVolumeMapping {
  container: string;  // Chemin dans le conteneur
  host: string;       // Chemin sur l'hôte (relatif ou absolu)
}

// Exemple
{ container: "/mosquitto/config", host: "./mosquitto/config" }
{ container: "/mosquitto/data", host: "./mosquitto/data" }
```

#### Variables d'Environnement

```typescript
interface ContainerEnvVar {
  key: string;        // Nom de la variable
  value: string;      // Valeur par défaut
}

// Exemple
{ key: "TZ", value: "Europe/Paris" }
{ key: "MQTT_BROKER", value: "mosquitto" }
```

### Convention de Nommage GitHub

Les templates sont hébergés sur GitHub selon une convention stricte :

| Élément | Convention | Exemple |
|---------|------------|---------|
| Repository | `MCP-{ServiceName}` | `MCP-Zigbee2Mqtt` |
| Fichier template | `MCP-Template.json` | Racine du dépôt |
| Propriétaire | Configurable | `moreau66` (défaut) |

Structure type d'un repository :
```
MCP-Zigbee2Mqtt/
├── MCP-Template.json      # Template de conteneur
├── README.md              # Documentation
├── docker-compose.yml     # Composition Docker (optionnel)
├── config/                # Fichiers de configuration
│   └── configuration.yaml
└── schemas/               # Schémas MCP (optionnel)
    ├── mcp-schema.json
    └── tools-schema.json
```

### Templates Disponibles

#### Templates Core

| ID | Nom | Image | Description |
|----|-----|-------|-------------|
| `mosquitto` | Eclipse Mosquitto | `eclipse-mosquitto` | Broker MQTT central |
| `zigbee2mqtt` | Zigbee2MQTT | `koenkk/zigbee2mqtt` | Passerelle Zigbee vers MQTT |

#### Templates Optionnels

| ID | Nom | Image | Description |
|----|-----|-------|-------------|
| `duckdb` | DuckDB | `duckdb/duckdb` | Base de données analytique |
| `sqlite2mqtt` | SQLite2MQTT | `moreau66/sqlite2mqtt` | Base de données légère + API REST |
| `ollama` | Ollama | `ollama/ollama` | LLM local (IA) |
| `docker2mqtt` | Docker2MQTT | `moreau66/docker2mqtt` | Monitoring Docker via MQTT |
| `meteo2mqtt` | Meteo2MQTT | `moreau66/meteo2mqtt` | Données météorologiques |
| `astral2mqtt` | Astral2MQTT | `moreau66/astral2mqtt` | Données astronomiques |

---

## Synchronisation GitHub

### Configuration GitHub

La configuration est gérée par le store Zustand `useGitHubConfig` (`src/store/use-github-config.ts`) :

```typescript
interface GitHubConfigState {
  owner: string;           // Propriétaire GitHub (ex: "moreau66")
  token?: string;          // Token d'accès (optionnel, pour dépôts privés)
  repoPrefix: string;      // Préfixe des dépôts (ex: "MCP-")
  templateFile: string;    // Nom du fichier template (ex: "MCP-Template.json")
  enabled: boolean;        // Activer/désactiver la synchronisation
  webhookSecret: string;   // Secret pour les webhooks
}
```

#### Méthodes de Configuration

```typescript
const { 
  owner, 
  setOwner, 
  setToken, 
  setRepoPrefix,
  setEnabled,
  loadFromFile,
  resetConfig,
  exportConfig 
} = useGitHubConfig();

// Charger la configuration depuis github-config.json
await loadFromFile();

// Modifier le propriétaire
setOwner("mon-username");

// Configurer un token pour dépôts privés
setToken("ghp_xxxxxxxxxxxx");

// Réinitialiser aux valeurs par défaut
await resetConfig();

// Exporter la configuration courante
exportConfig();
```

### Service de Découverte

Le service `GitHubMicroserviceDiscovery` découvre automatiquement les templates depuis GitHub :

```typescript
// Méthodes principales
await GitHubMicroserviceDiscovery.listMicroserviceRepos()
// → Retourne la liste des dépôts avec préfixe MCP-

await GitHubMicroserviceDiscovery.loadTemplate(repoName)
// → Charge le fichier MCP-Template.json d'un dépôt

await GitHubMicroserviceDiscovery.discoverAll()
// → Découvre et charge tous les templates disponibles

await GitHubMicroserviceDiscovery.checkForUpdates()
// → Vérifie les nouvelles versions des templates
```

#### Flux de Découverte

```
1. Lister les repos GitHub avec préfixe "MCP-"
           │
           ▼
2. Pour chaque repo, charger MCP-Template.json
           │
           ▼
3. Parser et valider le JSON
           │
           ▼
4. Ajouter au cache local
           │
           ▼
5. Comparer les versions avec les templates déployés
```

### Cache des Templates

Le `ContainerTemplateCache` (`src/services/containerTemplateCache.ts`) gère le cache local des templates :

```typescript
// Chargement
ContainerTemplateCache.loadFromGitHub()      // Charge depuis GitHub
ContainerTemplateCache.loadFromLocalStorage() // Fallback offline

// Accès aux templates
ContainerTemplateCache.getAll()              // Tous les templates
ContainerTemplateCache.getById(id)           // Template par ID
ContainerTemplateCache.getCoreTemplates()    // Templates "core" uniquement

// Gestion des versions
ContainerTemplateCache.getVersionStatus(id)  // État de version d'un template
ContainerTemplateCache.checkForUpdates()     // Vérifier les MAJ disponibles
ContainerTemplateCache.updateDeployedVersion(id, version) // Marquer comme déployé

// Rafraîchissement
ContainerTemplateCache.refresh()             // Force le rechargement complet
```

#### Structure du Cache

```typescript
interface CachedTemplate {
  template: ContainerTemplate;
  cachedAt: number;           // Timestamp du cache
  deployedVersion?: string;   // Version actuellement déployée
  latestVersion: string;      // Dernière version disponible
}
```

### Configuration de Synchronisation

Le store `useTemplateSyncConfig` gère la fréquence de synchronisation :

```typescript
interface TemplateSyncConfig {
  frequency: "daily" | "weekly" | "monthly" | "manual";
  lastCheck: number;          // Timestamp dernière vérification
  notifyOnUpdate: boolean;    // Notifications automatiques
}

// Vérifier si une synchronisation est nécessaire
const shouldSync = useTemplateSyncConfig.getState().shouldCheck();

// Mettre à jour après synchronisation
useTemplateSyncConfig.getState().updateLastCheck();
```

---

## Déploiement de Conteneurs

### Store Zustand `useContainers`

Le store principal `useContainers` (`src/store/use-containers.ts`) gère l'état de tous les conteneurs déployés :

```typescript
interface ContainersState {
  // État
  containers: Record<ContainerType, ContainerState>;
  
  // Actions de gestion
  initializeCoreContainers: (ids?: string[]) => void;
  addContainerFromTemplate: (id: string, template: ContainerTemplate) => void;
  removeContainer: (type: ContainerType) => void;
  
  // Configuration
  updateConfig: (type: ContainerType, config: Partial<ContainerConfig>) => void;
  updateStatus: (type: ContainerType, status: Partial<ContainerStatus>) => void;
  
  // Import/Export
  exportToJSON: () => string;
  importFromJSON: (json: string) => void;
  
  // Templates personnalisés
  saveAsTemplate: (containerId: string, templateData: Partial<ContainerTemplate>) => void;
}
```

### Types de Conteneurs

Les interfaces de `src/types/containers.ts` définissent la structure des conteneurs :

#### ContainerConfig

```typescript
interface ContainerConfig {
  id: string;
  name: string;
  image: string;
  version: string;
  autoStart: boolean;
  ports: ContainerPortMapping[];
  volumes: ContainerVolumeMapping[];
  environment: ContainerEnvVar[];
  restart: ContainerRestartPolicy;
  webUrl?: string;
  extra?: Record<string, any>;
}
```

#### ContainerStatus

```typescript
interface ContainerStatus {
  isRunning: boolean;
  status: "running" | "stopped" | "error" | "loading" | "not_created";
  startedAt?: string;
  version?: string;
  port?: number;
  memory?: string;
  cpu?: string;
}
```

#### ContainerState

```typescript
interface ContainerState {
  config: ContainerConfig;
  status: ContainerStatus;
  template?: ContainerTemplate;  // Référence au template d'origine
}
```

### Flux de Déploiement

```
┌─────────────────────────────────────────────────────────────────┐
│                     1. SÉLECTION DU TEMPLATE                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ ContainerTemplateManager → ContainerTemplateCard        │    │
│  │ L'utilisateur parcourt le catalogue et clique "Déployer"│    │
│  └─────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  2. DIALOGUE DE DÉPLOIEMENT                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ ContainerDeploymentDialog                                │    │
│  │ - Affiche la configuration par défaut                   │    │
│  │ - Option "Démarrer immédiatement"                       │    │
│  │ - Bouton "Déployer"                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    3. AJOUT AU STORE                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ useContainers.addContainerFromTemplate(id, template)    │    │
│  │ - Conversion template → config via templateToConfig()   │    │
│  │ - Initialisation du statut                              │    │
│  │ - Sauvegarde dans le store Zustand                      │    │
│  └─────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                4. MISE À JOUR DU CACHE                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ ContainerTemplateCache.updateDeployedVersion(id, ver)   │    │
│  │ - Marque la version comme déployée                      │    │
│  │ - Permet la détection des mises à jour futures          │    │
│  └─────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   5. NOTIFICATION                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Toast de confirmation                                    │    │
│  │ "Conteneur {nom} ajouté avec succès"                    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Helpers de Conversion

Le fichier `src/utils/containerHelpers.ts` fournit des fonctions utilitaires :

```typescript
// Convertir un template en configuration
function templateToConfig(template: ContainerTemplate): ContainerConfig {
  return {
    id: template.id,
    name: template.name,
    image: template.image,
    version: template.defaultVersion,
    autoStart: template.autoStart,
    ports: template.ports,
    volumes: template.volumes,
    environment: template.environment,
    restart: template.restart,
    webUrl: template.webUrl
  };
}

// Valider un template
function validateTemplate(template: ContainerTemplate): { 
  valid: boolean; 
  errors: string[] 
} {
  const errors: string[] = [];
  
  // Validation des ports (1-65535)
  // Validation des volumes (chemin absolu dans le conteneur)
  // Validation des variables d'environnement (pas d'espaces ni de =)
  
  return { valid: errors.length === 0, errors };
}
```

### Assistant de Première Utilisation

Le composant `FirstRunWizard` guide les nouveaux utilisateurs :

```typescript
// Templates proposés par défaut
const DEFAULT_WIZARD_TEMPLATES = [
  "duckdb",      // Base de données analytique
  "mosquitto",   // Broker MQTT (essentiel)
  "sqlite",      // Base de données légère
  "zigbee2mqtt"  // Passerelle Zigbee
];
```

#### Comportement

1. **Affichage** : S'affiche si aucun conteneur n'est déployé ET `firstrun-wizard-completed !== 'true'`
2. **Sélection** : L'utilisateur coche les conteneurs à installer
3. **Installation** : Déploiement en batch des conteneurs sélectionnés
4. **Skip** : Option de passer en mode simulation
5. **Completion** : Flag `firstrun-wizard-completed` sauvegardé dans localStorage

---

## Gestion des Versions

### Détection des Versions

```typescript
interface VersionStatus {
  upToDate: boolean;        // true si version déployée = dernière version
  latestVersion: string;    // Dernière version disponible
  deployedVersion?: string; // Version actuellement déployée
  needsUpdate: boolean;     // true si mise à jour disponible
}

// Obtenir le statut d'un template
const status = ContainerTemplateCache.getVersionStatus("mosquitto");
// → { upToDate: false, latestVersion: "2.0.20", deployedVersion: "2.0.18", needsUpdate: true }
```

### Affichage dans l'Interface

Le composant `ContainerTemplateCard` affiche visuellement l'état des versions :

| État | Badge | Bouton |
|------|-------|--------|
| Non déployé | - | "Déployer" (actif) |
| À jour | Vert | "Déjà déployé" (désactivé) |
| Mise à jour disponible | Rouge | "Mettre à jour" (actif, variant destructive) |

```tsx
// Logique de détermination du bouton
const { containers } = useContainers();
const isDeployed = template.id in containers;
const versionStatus = ContainerTemplateCache.getVersionStatus(template.id);

if (!isDeployed) {
  // Bouton "Déployer"
} else if (versionStatus.needsUpdate) {
  // Bouton "Mettre à jour" (destructive)
} else {
  // Bouton "Déjà déployé" (disabled)
}
```

### Processus de Mise à Jour

1. **Détection** : `ContainerTemplateCache.checkForUpdates()` compare les versions
2. **Notification** : Badge visuel sur le template + notification système
3. **Action** : Clic sur "Mettre à jour" → Re-déploiement avec nouvelle version
4. **Mise à jour du cache** : `updateDeployedVersion(id, newVersion)`

---

## Intégration Watchtower

### Service Watchtower

Le service `watchtowerService` (`src/services/watchtowerService.ts`) écoute les événements de mise à jour Docker :

```typescript
interface WatchtowerEvent {
  container_name: string;      // Nom du conteneur
  image: string;               // Image Docker
  current_image_id?: string;   // ID image actuelle
  latest_image_id?: string;    // ID nouvelle image
  timestamp: number;           // Timestamp de l'événement
  event_type: 
    | "update_available"       // Mise à jour disponible
    | "updating"               // Mise à jour en cours
    | "updated"                // Mise à jour terminée
    | "update_failed"          // Échec de mise à jour
    | "no_update";             // Pas de mise à jour
}
```

### Topics MQTT Watchtower

Watchtower publie sur des topics MQTT spécifiques :

| Topic | Description |
|-------|-------------|
| `docker/events/watchtower/update_available` | Nouvelle version détectée |
| `docker/events/watchtower/updating` | Mise à jour en cours |
| `docker/events/watchtower/updated` | Mise à jour terminée |
| `docker/events/watchtower/update_failed` | Échec de mise à jour |
| `docker/events/watchtower/no_update` | Aucune mise à jour |

### Utilisation du Service

```typescript
import { watchtowerService } from "@/services/watchtowerService";

// Connexion au service
await watchtowerService.connect();

// S'abonner aux événements
const unsubscribe = watchtowerService.subscribe("all", (event) => {
  console.log(`Événement Watchtower: ${event.event_type} pour ${event.container_name}`);
});

// Déclencher une mise à jour manuelle
await watchtowerService.triggerUpdate("mosquitto");
// → Publie sur docker/commands/mosquitto/update

// Simulation (développement)
watchtowerService.simulateWatchtowerEvents();

// Déconnexion
watchtowerService.disconnect();
```

### Composant WatchtowerNotifications

Le composant `WatchtowerNotifications` affiche les événements en temps réel :

```tsx
<WatchtowerNotifications />
```

#### Fonctionnalités

- **Liste des événements** : Affichage chronologique des derniers événements
- **Icônes par type** : 
  - `update_available` → `Download` (bleu)
  - `updating` → `RefreshCw` (orange, animation)
  - `updated` → `CheckCircle` (vert)
  - `update_failed` → `AlertCircle` (rouge)
- **Actions** : Bouton "Mettre à jour" pour les conteneurs avec MAJ disponible
- **Effacer** : Bouton pour vider la liste des événements
- **Intégration toast** : Notifications système pour les événements importants

---

## Interface Utilisateur

### Page Conteneurs

La page `ContainersManagement` (`src/pages/ContainersManagement.tsx`) organise la gestion en onglets :

| Onglet | Composant | Description |
|--------|-----------|-------------|
| Découverte | `DockerDiscoveryTab` | Découverte de conteneurs Docker existants |
| Templates | `ContainerTemplateManager` | Catalogue des templates disponibles |
| Déployé(s) | `DeployedContainerCard` (liste) | Conteneurs actuellement déployés |

### Composants Principaux

#### ContainerTemplateManager

Catalogue et gestion des templates :

```tsx
<ContainerTemplateManager />
```

- Recherche par nom/tag
- Filtrage par catégorie (core/optional/custom)
- Grille de `ContainerTemplateCard`
- Bouton de rafraîchissement GitHub
- Onglets : Catalogue | Créer | Import/Export

#### ContainerTemplateCard

Carte d'un template avec actions :

```tsx
<ContainerTemplateCard template={template} />
```

- Affichage : nom, description, image, tags
- Liens : GitHub, documentation
- Badge de version
- Bouton de déploiement contextuel

#### ContainerDeploymentDialog

Modal de confirmation de déploiement :

```tsx
<ContainerDeploymentDialog 
  template={template}
  open={open}
  onOpenChange={setOpen}
/>
```

- Résumé de la configuration
- Checkbox "Démarrer immédiatement"
- Boutons Annuler / Déployer

#### ContainerPanel

Panneau de gestion d'un conteneur déployé :

```tsx
<ContainerPanel containerId="mosquitto" containerState={state} />
```

- Mode lecture : affichage de la config
- Mode édition : modification des paramètres
- Contrôles : start/stop/restart
- URL web avec bouton "Ouvrir"

#### DeployedContainerCard

Carte d'un conteneur dans la liste des déployés :

```tsx
<DeployedContainerCard containerId="mosquitto" containerState={state} />
```

- Statut visuel (running/stopped/error)
- Actions rapides
- Lien vers le panel détaillé

#### FirstRunWizard

Assistant première utilisation :

```tsx
<FirstRunWizard onComplete={() => window.location.reload()} />
```

- Liste des templates core recommandés
- Sélection multiple
- Installation batch
- Option "Passer" (mode simulation)

---

## Conteneurs Spécifiques

### Composants UI Dédiés

Certains conteneurs disposent de composants UI personnalisés :

| Conteneur | Composant | Fonctionnalités |
|-----------|-----------|-----------------|
| Mosquitto | `MosquittoContainer` | Stats, clients connectés, topics actifs |
| Zigbee2MQTT | `Zigbee2MQTTContainer` | Appareils appairés, réseau mesh |
| Ollama | `OllamaContainer` | Modèles chargés, interface de chat |
| SQLite | `SQLiteContainer` | Tables, requêtes, export |
| DuckDB | `DuckDBContainer` | Requêtes analytiques, graphiques |
| Meteo2MQTT | `Meteo2MqttContainer` | Prévisions, widgets météo |
| Astral2MQTT | `Astral2MqttContainer` | Lever/coucher soleil, phases lunaires |
| Docker2MQTT | `Docker2MqttContainer` | Liste conteneurs, ressources système |

### Configuration MCP

Les conteneurs avec `mcp_metadata` s'intègrent au système de communication :

```json
{
  "mcp_metadata": {
    "service_id": "zigbee2mqtt",
    "topics": {
      "discovery": "mcp/services/zigbee2mqtt/discovery",
      "data": "zigbee2mqtt/+",
      "commands": "zigbee2mqtt/bridge/request/#"
    },
    "ui_component": {
      "component_path": "Zigbee2MqttContainer",
      "mode": "embedded"
    }
  }
}
```

---

## Import/Export

### Export des Conteneurs

```typescript
const { exportToJSON } = useContainers();

const jsonData = exportToJSON();
// Retourne :
// {
//   "version": "1.0",
//   "exported_at": "2024-01-15T10:30:00Z",
//   "containers": { ... }
// }

// Téléchargement
const blob = new Blob([jsonData], { type: 'application/json' });
const url = URL.createObjectURL(blob);
// Créer lien de téléchargement...
```

### Import des Conteneurs

```typescript
const { importFromJSON } = useContainers();

try {
  importFromJSON(jsonData);
  // Fusionne avec les conteneurs existants
  toast({ title: "Import réussi" });
} catch (error) {
  toast({ title: "Erreur d'import", variant: "destructive" });
}
```

### Composant Import/Export

```tsx
<ContainerImportExport />
```

Fournit :
- Zone de texte pour coller du JSON
- Bouton "Importer"
- Bouton "Exporter" (téléchargement automatique)

### Templates Personnalisés

Sauvegarder un conteneur modifié comme template :

```typescript
const { saveAsTemplate } = useContainers();

saveAsTemplate("mon-mosquitto", {
  name: "Mon Mosquitto Custom",
  description: "Configuration personnalisée avec TLS",
  tags: ["mqtt", "tls", "custom"]
});

// Sauvegardé dans localStorage: "custom-container-templates"
```

Récupérer les templates personnalisés :

```typescript
import { getCustomTemplates } from "@/data/containerTemplates";

const customs = getCustomTemplates();
// → { "mon-mosquitto": ContainerTemplate, ... }
```

---

## Bonnes Pratiques

### Configuration des Conteneurs

1. **Volumes** : Toujours utiliser des volumes pour la persistance des données
   ```json
   "volumes": [
     { "container": "/data", "host": "./service/data" },
     { "container": "/config", "host": "./service/config" }
   ]
   ```

2. **Politique de redémarrage** : Utiliser `unless-stopped` en production
   ```json
   "restart": "unless-stopped"
   ```

3. **Versions** : Préférer les tags de version spécifiques plutôt que `latest`
   ```json
   "defaultVersion": "2.0.18"
   ```

4. **Variables sensibles** : Marquer les variables sensibles comme `required`
   ```json
   "environment": [
     { "key": "MQTT_PASSWORD", "value": "", "required": true, "sensitive": true }
   ]
   ```

### Synchronisation GitHub

1. **Activer la synchronisation** : Permet les mises à jour automatiques
2. **Fréquence** : `weekly` est un bon compromis
3. **Notifications** : Activer pour être informé des nouvelles versions
4. **Token** : Configurer un token pour les dépôts privés

### Mises à Jour Watchtower

1. **Connexion MQTT** : S'assurer que Watchtower publie sur le broker configuré
2. **Topics** : Vérifier que les topics correspondent à la configuration
3. **Surveillance** : Consulter régulièrement les notifications de mise à jour
4. **Test** : Utiliser `simulateWatchtowerEvents()` en développement

### Organisation des Templates

1. **Catégorisation** : 
   - `core` : Services essentiels (Mosquitto, Zigbee2MQTT)
   - `optional` : Services complémentaires (bases de données, IA)
   - `custom` : Templates personnalisés

2. **Tags** : Utiliser des tags descriptifs pour faciliter la recherche
   ```json
   "tags": ["mqtt", "broker", "core", "messaging"]
   ```

3. **Documentation** : Toujours inclure des liens vers la documentation
   ```json
   "documentation": "https://mosquitto.org/documentation/",
   "repoUrl": "https://github.com/eclipse/mosquitto"
   ```

---

## Schéma JSON de Référence

Le schéma complet des templates est disponible dans :
`docs/schemas/microservice-container-template-schema.json`

Ce schéma définit :
- Structure complète des templates
- Validation des champs obligatoires
- Types de données attendus
- Valeurs par défaut

---

## Références

- [Guide d'Installation](./guide-installation.md) - Prérequis Docker
- [Guide Synchronisation GitHub](./guide-synchronisation-github.md) - Configuration GitHub
- [Schéma Template](./schemas/microservice-container-template-schema.json) - JSON Schema
- [docker-compose.yml](../docker-compose.yml) - Configuration de référence
