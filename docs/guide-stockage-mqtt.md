# Guide du Stockage et de la Persistance MQTT

Ce guide détaille l'architecture de stockage des messages MQTT dans NeurHomIA, incluant les providers de stockage, les niveaux de QoS, la rétention des données et l'historique des messages.

---

## Table des matières

1. [Introduction](#introduction)
2. [Architecture Multi-Backend](#architecture-multi-backend)
3. [Fournisseurs de Stockage](#fournisseurs-de-stockage)
4. [Mécanisme de Fallback](#mécanisme-de-fallback)
5. [Communication MQTT avec les Microservices](#communication-mqtt-avec-les-microservices)
6. [Structure des Messages Stockés](#structure-des-messages-stockés)
7. [Filtrage et Recherche](#filtrage-et-recherche)
8. [Niveaux de QoS](#niveaux-de-qos)
9. [Rétention des Messages (Retain)](#rétention-des-messages-retain)
10. [Configuration de la Persistance](#configuration-de-la-persistance)
11. [Nettoyage Automatique](#nettoyage-automatique)
12. [Migration de Données](#migration-de-données)
13. [Export et Import JSON](#export-et-import-json)
14. [Historique des Valeurs Calculées](#historique-des-valeurs-calculées)
15. [Configuration du Broker Mosquitto](#configuration-du-broker-mosquitto)
16. [Bonnes Pratiques](#bonnes-pratiques)
17. [Dépannage](#dépannage)

---

## Introduction

La persistance des messages MQTT dans NeurHomIA répond à plusieurs besoins :

- **Débogage** : Analyser les échanges passés pour diagnostiquer des problèmes
- **Historique** : Conserver l'évolution des valeurs des capteurs
- **Audit** : Tracer les commandes envoyées aux actionneurs
- **Analytics** : Analyser les patterns de communication

Il est important de distinguer deux types de persistance :

| Type | Responsable | Portée |
|------|-------------|--------|
| **Rétention broker** | Mosquitto | Dernier message par topic (flag `retain`) |
| **Stockage applicatif** | NeurHomIA | Historique complet des messages |

---

## Architecture Multi-Backend

L'architecture de stockage utilise un pattern façade avec fallback automatique :

```
┌─────────────────────────────────────────────────────────────┐
│                   mqttMessageStore                          │
│            (Façade synchrone avec cache mémoire)            │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   StorageManager                             │
│           (Orchestration + Fallback automatique)            │
├───────────────┬───────────────────────┬─────────────────────┤
│  localStorage │      SQLite           │      DuckDB         │
│  (fallback)   │   (volumétrie         │   (analytics        │
│               │    moyenne)           │    haute perf.)     │
└───────────────┴───────────────────────┴─────────────────────┘
```

### Fichiers de l'Architecture

| Fichier | Rôle |
|---------|------|
| `src/services/mqttMessageStore.ts` | Façade synchrone avec cache mémoire |
| `src/services/storage/StorageManager.ts` | Orchestration des providers avec fallback |
| `src/services/storage/IStorageProvider.ts` | Interface commune des providers |
| `src/services/storage/LocalStorageProvider.ts` | Stockage navigateur (toujours disponible) |
| `src/services/storage/SQLiteStorageProvider.ts` | Communication avec container SQLite |
| `src/services/storage/DuckDBStorageProvider.ts` | Communication avec container DuckDB |
| `src/services/storage/MqttStorageBridge.ts` | Pattern request/response MQTT |
| `src/services/mqttLoggerConfigService.ts` | Configuration du logger |

### Flux de Données

1. **Réception** : Message MQTT reçu par `mqttService`
2. **Cache** : Ajout au cache mémoire de `mqttMessageStore`
3. **Persistance** : Écriture asynchrone via `StorageManager`
4. **Fallback** : Si le provider principal échoue, bascule vers localStorage

---

## Fournisseurs de Stockage

### Interface Commune `IStorageProvider`

Tous les providers implémentent cette interface :

```typescript
interface IStorageProvider {
  readonly name: string;
  readonly type: 'localStorage' | 'sqlite' | 'duckdb';
  
  // Disponibilité
  isAvailable(): Promise<boolean>;
  
  // Opérations CRUD
  saveMessage(message: MqttMessage): Promise<void>;
  saveMessages(messages: MqttMessage[]): Promise<void>;
  getMessages(filters?: MessageFilters): Promise<MqttMessage[]>;
  deleteMessages(filters?: MessageFilters): Promise<number>;
  clearAll(): Promise<void>;
  
  // Statistiques et maintenance
  getStats(): Promise<MessageStats>;
  getStorageSize(): Promise<number>;
  runAutoCleanup(daysToKeep: number): Promise<number>;
}
```

### Comparaison des Providers

| Provider | Disponibilité | Capacité | Performance | Usage Recommandé |
|----------|---------------|----------|-------------|------------------|
| **localStorage** | Toujours | ~5 Mo | Moyenne | Développement, fallback |
| **SQLite** | Container actif | Illimitée | Bonne | Production standard |
| **DuckDB** | Container actif | Illimitée | Excellente | Analytics, gros volumes |

### LocalStorageProvider

Stockage dans le navigateur, toujours disponible :

```typescript
class LocalStorageProvider implements IStorageProvider {
  readonly name = "LocalStorage";
  readonly type = "localStorage";
  
  private readonly STORAGE_KEY = "mqtt-messages-v2";
  
  async isAvailable(): Promise<boolean> {
    return true;  // Toujours disponible
  }
  
  async saveMessage(message: MqttMessage): Promise<void> {
    const messages = this.loadFromStorage();
    messages.push(this.serializeMessage(message));
    this.saveToStorage(messages);
  }
}
```

**Limites** :
- Quota navigateur (~5-10 Mo selon le navigateur)
- Performance dégradée au-delà de 5000 messages
- Pas de requêtes SQL avancées

### SQLiteStorageProvider

Stockage via microservice SQLite communiquant par MQTT :

```typescript
class SQLiteStorageProvider implements IStorageProvider {
  readonly name = "SQLite";
  readonly type = "sqlite";
  
  async isAvailable(): Promise<boolean> {
    const containers = useContainers.getState().containers;
    const sqliteContainer = containers["sqlite"];
    return sqliteContainer?.status?.isRunning === true;
  }
}
```

**Avantages** :
- Requêtes SQL complètes
- Pas de limite de stockage navigateur
- Transactions ACID

### DuckDBStorageProvider

Stockage analytique haute performance :

```typescript
class DuckDBStorageProvider implements IStorageProvider {
  readonly name = "DuckDB";
  readonly type = "duckdb";
  
  // Même structure que SQLite, topics différents
}
```

**Avantages** :
- Optimisé pour les requêtes analytiques
- Compression des données
- Excellente performance sur gros volumes

---

## Mécanisme de Fallback

### Stratégie `withFallback`

Le `StorageManager` implémente un fallback automatique :

```typescript
private async withFallback<T>(
  operation: (provider: IStorageProvider) => Promise<T>,
  operationName: string
): Promise<T> {
  try {
    return await operation(this.activeProvider);
  } catch (error) {
    if (this.activeProvider !== this.fallbackProvider) {
      console.warn(`[StorageManager] ${operationName} failed, falling back to localStorage`);
      return await operation(this.fallbackProvider);
    }
    throw error;
  }
}
```

### Scénarios de Fallback

| Situation | Comportement |
|-----------|--------------|
| Container SQLite/DuckDB arrêté | Bascule vers localStorage |
| Timeout MQTT (10 secondes) | Bascule vers localStorage |
| Erreur de parsing JSON | Bascule vers localStorage |
| localStorage plein | Erreur (pas de fallback possible) |

### Changement de Provider

```typescript
async setActiveProvider(type: StorageType): Promise<void> {
  const provider = this.getProviderByType(type);
  
  if (await provider.isAvailable()) {
    this.activeProvider = provider;
    console.log(`[StorageManager] Switched to ${provider.name}`);
  } else {
    console.warn(`[StorageManager] ${provider.name} not available, keeping current provider`);
  }
}
```

---

## Communication MQTT avec les Microservices

### Topics de Communication

| Provider | Insert | Query | Delete | Clear | Stats | Cleanup | Response |
|----------|--------|-------|--------|-------|-------|---------|----------|
| **SQLite** | `sqlite/mqtt-logger/insert` | `sqlite/mqtt-logger/query` | `sqlite/mqtt-logger/delete` | `sqlite/mqtt-logger/clear` | `sqlite/mqtt-logger/stats` | `sqlite/mqtt-logger/cleanup` | `sqlite/mqtt-logger/response` |
| **DuckDB** | `duckdb/mqtt-logger/insert` | `duckdb/mqtt-logger/query` | `duckdb/mqtt-logger/delete` | `duckdb/mqtt-logger/clear` | `duckdb/mqtt-logger/stats` | `duckdb/mqtt-logger/cleanup` | `duckdb/mqtt-logger/response` |

### Pattern Request/Response

Le `MqttStorageBridge` gère la communication asynchrone :

```typescript
class MqttStorageBridge {
  private pendingRequests: Map<string, PendingRequest<any>> = new Map();
  private readonly TIMEOUT = 10000; // 10 secondes

  async sendRequest<T>(
    requestTopic: string,
    responseTopic: string,
    payload: any
  ): Promise<T> {
    const requestId = payload.requestId;
    
    return new Promise((resolve, reject) => {
      // Timeout
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(requestId);
        reject(new Error(`Timeout: pas de réponse de ${requestTopic}`));
      }, this.TIMEOUT);

      // Stocker la requête en attente
      this.pendingRequests.set(requestId, { resolve, reject, timeout });

      // S'abonner au topic de réponse
      this.ensureResponseSubscription(responseTopic);

      // Publier la requête
      mqttService.publish(requestTopic, JSON.stringify(payload), 1);
    });
  }

  generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

### Format des Requêtes

**Requête d'insertion** :
```json
{
  "requestId": "req_1705762800000_abc123def",
  "action": "insert",
  "data": {
    "id": "msg-uuid-123",
    "type": "received",
    "topic": "home/temperature",
    "payload": "{\"value\": 21.5}",
    "timestamp": "2026-01-20T10:30:00.000Z",
    "qos": 1,
    "source": "p"
  }
}
```

**Requête de recherche** :
```json
{
  "requestId": "req_1705762800001_def456ghi",
  "action": "query",
  "filters": {
    "source": "p",
    "startDate": "2026-01-19T00:00:00.000Z",
    "endDate": "2026-01-20T23:59:59.999Z"
  }
}
```

**Format de réponse** :
```json
{
  "requestId": "req_1705762800001_def456ghi",
  "data": [...],
  "error": null
}
```

---

## Structure des Messages Stockés

### Interface `MqttMessage`

```typescript
interface MqttMessage {
  id: string;           // UUID unique (généré par uuid)
  type: 'sent' | 'received';  // Direction du message
  topic: string;        // Topic MQTT complet
  payload: string;      // Contenu du message (JSON ou texte)
  timestamp: Date;      // Date de réception/envoi
  qos?: 0 | 1 | 2;      // Niveau de qualité de service
  source: 's' | 'p';    // 's' = simulation, 'p' = production
  scheduledId?: string; // ID de planification (optionnel)
}
```

### Distinction Simulation / Production

| Source | Code | Description |
|--------|------|-------------|
| Simulation | `'s'` | Messages générés par le mode simulation |
| Production | `'p'` | Messages réels du broker MQTT |

Cette distinction permet de :
- Filtrer les messages par environnement
- Analyser séparément simulation et production
- Nettoyer sélectivement les données

### Interface `MessageStats`

```typescript
interface MessageStats {
  total: number;        // Nombre total de messages
  simulation: number;   // Messages de simulation (source='s')
  production: number;   // Messages de production (source='p')
  sent: number;         // Messages envoyés (type='sent')
  received: number;     // Messages reçus (type='received')
  storageSize: number;  // Taille en octets
  lastCleanup?: {       // Dernier nettoyage effectué
    date: Date;
    deletedCount: number;
  };
}
```

---

## Filtrage et Recherche

### Interface `MessageFilters`

```typescript
interface MessageFilters {
  source?: 'all' | 's' | 'p';    // Filtrer par source
  type?: 'all' | 'sent' | 'received';  // Filtrer par direction
  searchQuery?: string;           // Recherche textuelle
  searchScope?: {                 // Portée de recherche
    topic: boolean;
    payload: boolean;
  };
  startDate?: Date;               // Date de début
  endDate?: Date;                 // Date de fin
}
```

### Exemples de Filtrage

**Messages production uniquement** :
```typescript
const prodMessages = await storageManager.getMessages({
  source: 'p'
});
```

**Messages d'une période** :
```typescript
const weekMessages = await storageManager.getMessages({
  startDate: new Date('2026-01-13'),
  endDate: new Date('2026-01-20')
});
```

**Recherche par topic** :
```typescript
const tempMessages = await storageManager.getMessages({
  searchQuery: 'temperature',
  searchScope: { topic: true, payload: false }
});
```

**Recherche dans le payload** :
```typescript
const alertMessages = await storageManager.getMessages({
  searchQuery: 'alarm',
  searchScope: { topic: false, payload: true }
});
```

---

## Niveaux de QoS

### Qualité de Service MQTT

| QoS | Nom | Garantie | Persistance Broker |
|-----|-----|----------|-------------------|
| **0** | At most once | Aucune garantie | Non |
| **1** | At least once | Livraison garantie (doublons possibles) | Oui* |
| **2** | Exactly once | Livraison unique garantie | Oui* |

*Si `cleanSession=false` sur le client

### Impact sur le Stockage

**QoS 0** :
- Messages non rejouables après déconnexion
- Pas de confirmation de réception
- Usage : données non critiques (température fréquente)

**QoS 1** :
- Broker conserve le message jusqu'à confirmation
- Peut générer des doublons
- Usage : commandes importantes (allumer lumière)

**QoS 2** :
- Handshake en 4 étapes
- Garantie d'unicité
- Usage : transactions critiques (alarme)

### Configuration du QoS

Dans les actions de scénarios :
```typescript
interface MqttPublishTopic {
  topic: string;
  payload: string;
  qos: 0 | 1 | 2;
  retain: boolean;
}
```

---

## Rétention des Messages (Retain)

### Fonctionnement du Flag `retain`

Le flag `retain` dans MQTT indique au broker de :
1. Conserver le dernier message publié sur ce topic
2. L'envoyer automatiquement à tout nouveau souscripteur

**Important** : Un seul message retained par topic (le dernier écrase le précédent).

### Usage Recommandé

| Type de Donnée | Retain | Justification |
|----------------|--------|---------------|
| État courant (ON/OFF) | ✅ Oui | Les nouveaux clients doivent connaître l'état |
| Température actuelle | ✅ Oui | Valeur de référence utile |
| Événement ponctuel | ❌ Non | L'événement est passé |
| Alerte mouvement | ❌ Non | Ne doit pas être rejouée |
| Commande d'action | ❌ Non | Ne doit pas être ré-exécutée |

### Suppression d'un Message Retained

Publier un message vide avec `retain=true` :
```typescript
mqttService.publish('home/light/state', '', 1, true);
```

### Configuration dans NeurHomIA

```typescript
// Publication avec retain
mqttService.publish(
  'home/thermostat/setpoint',
  JSON.stringify({ value: 21 }),
  1,      // QoS
  true    // retain
);
```

---

## Configuration de la Persistance

### Service `mqttLoggerConfigService`

```typescript
interface MqttLoggerConfig {
  maxMessages: number;        // Limite de messages (défaut: 5000)
  autoCleanupDays: number;    // Rétention en jours (défaut: 7)
  autoCleanupEnabled: boolean; // Nettoyage automatique activé
  storageType: 'localStorage' | 'sqlite' | 'duckdb';
}

const DEFAULT_CONFIG: MqttLoggerConfig = {
  maxMessages: 5000,
  autoCleanupDays: 7,
  autoCleanupEnabled: true,
  storageType: 'localStorage',
};
```

### Méthodes du Service

| Méthode | Description |
|---------|-------------|
| `getConfig()` | Récupère la configuration complète |
| `updateConfig(partial)` | Met à jour partiellement la config |
| `resetConfig()` | Réinitialise aux valeurs par défaut |
| `getMaxMessages()` | Retourne la limite de messages |
| `getAutoCleanupDays()` | Retourne les jours de rétention |
| `isAutoCleanupEnabled()` | Vérifie si le nettoyage auto est activé |
| `getStorageType()` | Retourne le type de stockage actif |

### Persistance de la Configuration

- **Clé localStorage** : `mqtt-logger-config-v1`
- **Chargement** : Au démarrage de l'application
- **Sauvegarde** : À chaque modification via `updateConfig()`

### Interface de Configuration

Accessible via **Configuration > Journal** :
- Slider pour `maxMessages` (1000 - 50000)
- Slider pour `autoCleanupDays` (1 - 30)
- Switch pour `autoCleanupEnabled`
- Sélecteur pour `storageType`

---

## Nettoyage Automatique

### Méthode `runAutoCleanup`

```typescript
runAutoCleanup(): number {
  if (!mqttLoggerConfigService.isAutoCleanupEnabled()) {
    return 0;
  }

  const daysToKeep = mqttLoggerConfigService.getAutoCleanupDays();
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

  // Supprime les messages antérieurs à cutoffDate
  const initialCount = this.cachedMessages.length;
  this.cachedMessages = this.cachedMessages.filter(
    m => m.timestamp >= cutoffDate
  );
  
  const deletedCount = initialCount - this.cachedMessages.length;
  
  if (deletedCount > 0) {
    console.log(`[mqttMessageStore] Cleaned ${deletedCount} old messages`);
  }
  
  return deletedCount;
}
```

### Limite de Messages (`applyMaxLimit`)

```typescript
private applyMaxLimit(): void {
  const maxMessages = mqttLoggerConfigService.getMaxMessages();
  
  if (this.messages.length > maxMessages) {
    const toRemove = this.messages.length - maxMessages;
    // Supprime les plus anciens (début du tableau)
    this.messages = this.messages.slice(toRemove);
    console.log(`[mqttMessageStore] Removed ${toRemove} messages (limit: ${maxMessages})`);
  }
}
```

### Déclenchement du Nettoyage

Le nettoyage s'exécute :
1. **Au démarrage** : Vérification initiale
2. **Périodiquement** : Toutes les heures
3. **Manuellement** : Bouton "Nettoyer maintenant" dans Configuration

---

## Migration de Données

### Interface de Migration

```typescript
interface MigrationResult {
  success: boolean;
  messagesMigrated: number;
  sourceCleared: boolean;
  error?: string;
}

interface MigrationOptions {
  clearSourceAfterMigration?: boolean;  // Vider la source après
  batchSize?: number;                   // Taille des lots (défaut: 100)
  onProgress?: (progress: MigrationProgress) => void;
}

interface MigrationProgress {
  phase: 'reading' | 'writing' | 'clearing' | 'complete';
  current: number;
  total: number;
  percentage: number;
}
```

### Processus de Migration

1. **Phase `reading`** : Lecture de tous les messages de la source
2. **Phase `writing`** : Écriture par lots vers la destination
3. **Phase `clearing`** : Suppression de la source (si demandé)
4. **Phase `complete`** : Migration terminée

### Exemple d'Utilisation

```typescript
const result = await storageManager.migrateData(
  'localStorage',  // Source
  'sqlite',        // Destination
  {
    clearSourceAfterMigration: true,
    batchSize: 100,
    onProgress: (progress) => {
      console.log(`Migration: ${progress.percentage}% (${progress.phase})`);
    }
  }
);

if (result.success) {
  console.log(`Migré ${result.messagesMigrated} messages`);
}
```

### Cas d'Usage

- **Passage en production** : localStorage → SQLite
- **Upgrade performance** : SQLite → DuckDB
- **Sauvegarde** : SQLite → localStorage (export)

---

## Export et Import JSON

Cette section détaille les mécanismes de sauvegarde et de restauration des messages MQTT via des fichiers JSON.

### Export vers JSON

#### Format du Fichier Exporté

L'export génère un fichier JSON structuré contenant les métadonnées et les messages :

```typescript
interface MqttLogExport {
  exportDate: string;           // Date ISO de l'export
  filters: MessageFilters;      // Filtres appliqués lors de l'export
  stats: {
    totalExported: number;      // Nombre de messages exportés
    timeRange: {
      oldest: string;           // Timestamp du plus ancien message
      newest: string;           // Timestamp du plus récent message
    } | null;
  };
  messages: Array<{
    id: string;
    type: 'sent' | 'received';
    topic: string;
    payload: string;
    timestamp: string;          // Format ISO 8601
    qos?: 0 | 1 | 2;
    source: 's' | 'p';
    scheduledId?: string;
  }>;
}
```

#### Méthode `exportToJSON`

La méthode d'export dans `mqttMessageStore` :

```typescript
exportToJSON(filters?: MessageFilters): string {
  const messages = this.getMessages(filters);
  const exportData = {
    exportDate: new Date().toISOString(),
    filters: filters || {},
    stats: {
      totalExported: messages.length,
      timeRange: messages.length > 0 ? {
        oldest: messages[0].timestamp,
        newest: messages[messages.length - 1].timestamp,
      } : null,
    },
    messages: messages.map(m => ({
      ...m,
      timestamp: m.timestamp.toISOString(),
    })),
  };
  return JSON.stringify(exportData, null, 2);
}
```

#### Accès dans l'Interface

| Emplacement | Action |
|-------------|--------|
| **Page Journal MQTT** | Bouton "Exporter (JSON)" dans les filtres avancés |
| **Filtres actifs** | Les filtres source/type/période/recherche sont appliqués |
| **Nom du fichier** | `mqtt_log_{timestamp}_{source}.json` |

#### Cas d'Usage de l'Export

| Situation | Bénéfice |
|-----------|----------|
| Avant changement de provider | Sauvegarder les données localStorage |
| Débogage hors-ligne | Analyser les logs sur un autre poste |
| Archivage long terme | Conserver un historique au-delà de la rétention |
| Partage avec support | Transmettre des logs pour analyse |
| Avant suppression | Créer une sauvegarde avant nettoyage |

### Import depuis JSON

L'import de fichiers JSON permet de restaurer des messages exportés ou de fusionner des logs provenant de différentes sources.

#### Interfaces

```typescript
// Résultat de l'import
interface ImportResult {
  success: boolean;
  imported: number;       // Messages importés
  duplicates: number;     // Messages ignorés (déjà existants)
  errors: string[];       // Erreurs rencontrées
  warnings: string[];     // Informations (ex: date d'export)
}

// Prévisualisation avant import
interface ImportPreview {
  isValid: boolean;
  fileName: string;
  exportDate: string | null;
  totalMessages: number;
  newMessages: number;        // Messages qui seront importés
  duplicates: number;         // Doublons détectés
  timeRange: {
    oldest: Date;
    newest: Date;
  } | null;
  sourceBreakdown: {
    simulation: number;
    production: number;
  };
  typeBreakdown: {
    sent: number;
    received: number;
  };
  errors: string[];
}
```

#### Workflow d'Import

| Étape | Description |
|-------|-------------|
| 1. Sélection du fichier | Clic sur "Importer (JSON)", sélection d'un fichier `.json` |
| 2. Prévisualisation | Analyse du fichier sans import : statistiques, doublons, période |
| 3. Modal de confirmation | Affichage des détails avec option d'annuler ou confirmer |
| 4. Validation | Vérification de la structure `MqttLogExport` et des champs requis |
| 5. Import avec déduplication | Insertion des messages non-dupliqués par `id` |
| 6. Rapport visuel | Affichage du résultat dans la modal (importés/doublons/erreurs) |

#### Implémentation

##### Méthode `previewImport`

Analyse le fichier sans importer, pour afficher une prévisualisation :

```typescript
previewImport(jsonString: string, fileName: string): ImportPreview {
  const data = JSON.parse(jsonString);
  
  // Valider la structure (tableau messages requis)
  if (!data.messages || !Array.isArray(data.messages)) {
    return { isValid: false, errors: ["Format invalide : tableau 'messages' manquant"] };
  }
  
  // Comparer avec les messages existants
  const existingIds = new Set(this.cachedMessages.map(m => m.id));
  let newMessages = 0, duplicates = 0;
  
  for (const msg of data.messages) {
    if (existingIds.has(msg.id)) duplicates++;
    else newMessages++;
  }
  
  return { isValid: true, newMessages, duplicates, ... };
}
```

##### Méthode `importFromJSON`

Import effectif avec déduplication par ID :

```typescript
importFromJSON(jsonString: string): ImportResult {
  const data = JSON.parse(jsonString);
  
  // Validation du format
  if (!data.messages || !Array.isArray(data.messages)) {
    return { success: false, errors: ["Format invalide"] };
  }
  
  const existingIds = new Set(this.cachedMessages.map(m => m.id));
  
  for (const msg of data.messages) {
    // Validation des champs requis
    if (!msg.id || !msg.topic || !msg.timestamp || !msg.type || !msg.source) {
      errors.push("Message invalide ignoré: champs manquants");
      continue;
    }
    
    // Détection des doublons par ID
    if (existingIds.has(msg.id)) {
      duplicates++;
      continue;
    }
    
    // Conversion et ajout
    this.cachedMessages.push({ ...msg, timestamp: new Date(msg.timestamp) });
    imported++;
  }
  
  // Persistance asynchrone
  if (imported > 0) {
    storageManager.saveMessages(newMessages);
  }
  
  return { success: true, imported, duplicates, errors, warnings };
}
```

#### Interface Utilisateur

L'import s'effectue via le bouton **"Importer (JSON)"** dans la page Journal MQTT.

##### Composants

| Composant | Rôle |
|-----------|------|
| `MqttLogImportButton` | Bouton et gestion du fichier sélectionné |
| `MqttImportPreviewDialog` | Modal de prévisualisation et rapport |

##### Modal de Prévisualisation

Affiche avant l'import :
- **Nom du fichier** et date d'export originale
- **Aperçu** : nombre total de messages, nouveaux à importer, doublons
- **Répartition** : par source (simulation/production) et type (envoyé/reçu)
- **Période** : du plus ancien au plus récent message
- **Erreurs** : messages avec champs manquants

##### Rapport d'Import

Après confirmation, la modal affiche :
- Nombre de messages **importés** (vert)
- Nombre de **doublons** ignorés (jaune)  
- Nombre d'**erreurs** (rouge)
- **Warnings** informatifs (date d'export du fichier source)

#### Accès dans l'Interface

| Emplacement | Action |
|-------------|--------|
| **Page Journal MQTT** | Bouton "Importer (JSON)" à côté de l'export |
| **Modal de confirmation** | Prévisualisation avant import avec statistiques |
| **Formats acceptés** | Fichiers `.json` au format `MqttLogExport` |

### Bonnes Pratiques Export/Import

#### Recommandations pour l'Export

| Pratique | Raison |
|----------|--------|
| Exporter avant les nettoyages automatiques | Préserver les données importantes |
| Utiliser les filtres | Réduire la taille des fichiers |
| Nommer les exports clairement | Faciliter l'identification (`mqtt_prod_2026-01-20.json`) |
| Exporter régulièrement | Éviter la perte de données en cas de problème |

#### Recommandations pour l'Import

| Pratique | Raison |
|----------|--------|
| Vérifier l'espace disponible | Éviter les erreurs de quota |
| Importer sur un provider vide | Éviter les conflits de données |
| Tester sur peu de données d'abord | Valider le processus |
| Conserver le fichier source | Pouvoir réimporter si nécessaire |

#### Archivage Long Terme

| Pratique | Raison |
|----------|--------|
| Compresser les exports (gzip/zip) | Réduire l'espace de stockage |
| Stocker sur support externe | Protection contre les pannes |
| Conserver les métadonnées | Savoir quand et comment l'export a été fait |
| Organiser par date/type | Faciliter la recherche ultérieure |

### Exemple Complet d'Export

```typescript
// Dans un composant React
const handleExport = () => {
  // Appliquer les filtres actifs
  const filters: MessageFilters = {
    source: 'p',
    startDate: new Date('2026-01-01'),
    endDate: new Date('2026-01-20')
  };
  
  // Générer le JSON
  const jsonContent = mqttMessageStore.exportToJSON(filters);
  
  // Créer et télécharger le fichier
  const blob = new Blob([jsonContent], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `mqtt_log_${Date.now()}_production.json`;
  link.click();
  URL.revokeObjectURL(url);
};
```

---

## Historique des Valeurs Calculées

### Store `useCalculatedHistory`

Stocke l'historique des valeurs des entités calculées :

```typescript
interface HistoryDataPoint {
  timestamp: number;  // Unix timestamp en millisecondes
  value: any;         // Valeur calculée
  entityId: string;   // ID de l'entité source
}

interface CalculatedHistoryState {
  history: Record<string, HistoryDataPoint[]>;
  maxHistorySize: number;  // Défaut: 1000
}
```

### Méthodes Disponibles

| Méthode | Description |
|---------|-------------|
| `addDataPoint(entityId, value)` | Ajoute un nouveau point de données |
| `getEntityHistory(entityId, limit?)` | Récupère l'historique d'une entité |
| `clearEntityHistory(entityId)` | Efface l'historique d'une entité |
| `clearAllHistory()` | Efface tout l'historique |
| `pruneOldData()` | Supprime les données > 7 jours |
| `setMaxHistorySize(size)` | Définit la limite par entité |

### Persistance

- **Middleware** : Zustand `persist`
- **Clé localStorage** : `calculated-history-storage`
- **Stratégie** : Sauvegarde automatique à chaque modification

### Utilisation pour les Graphiques

```typescript
const { getEntityHistory } = useCalculatedHistory();

// Récupérer les 100 derniers points
const history = getEntityHistory('temperature-moyenne', 100);

// Formater pour Recharts
const chartData = history.map(point => ({
  time: new Date(point.timestamp).toLocaleTimeString(),
  value: point.value
}));
```

---

## Configuration du Broker Mosquitto

### Paramètres de Persistance

```conf
# Activation de la persistance
persistence true
persistence_location /mosquitto/data/

# Intervalle de sauvegarde (secondes)
autosave_interval 1800

# Sauvegarde à l'arrêt
autosave_on_changes false
```

### Limites de Messages

```conf
# Taille maximale d'un message (256 Mo)
message_size_limit 268435456
max_packet_size 268435456

# File d'attente
max_inflight_messages 100
max_queued_messages 1000
max_queued_bytes 0
```

### Topics de Découverte Automatique

| Pattern | Usage |
|---------|-------|
| `homeassistant/+/+/config` | Home Assistant discovery |
| `+/widget/discovery` | Widgets dynamiques NeurHomIA |
| `docker/containers/+/state` | État des containers Docker |

### Configuration TLS (Production)

```conf
listener 8883
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key
require_certificate false
```

---

## Bonnes Pratiques

### Choix du QoS

| Situation | QoS Recommandé |
|-----------|----------------|
| Télémétrie fréquente (température toutes les secondes) | 0 |
| États d'appareils (ON/OFF) | 1 |
| Commandes critiques (alarme, serrure) | 2 |
| Découverte de configuration | 1 avec retain |

### Utilisation du Retain

- ✅ **Activer** pour les états persistants (lumières, volets, température)
- ❌ **Désactiver** pour les événements (mouvement, bouton pressé)
- ✅ **Activer** pour les configurations de découverte
- ❌ **Désactiver** pour les commandes

### Configuration du Stockage

| Volume de Messages | Provider Recommandé |
|--------------------|---------------------|
| < 1000/jour | localStorage |
| 1000 - 10000/jour | SQLite |
| > 10000/jour | DuckDB |

### Rétention des Données

| Type de Données | Rétention Suggérée |
|-----------------|-------------------|
| Débogage | 1-3 jours |
| Historique capteurs | 7-14 jours |
| Audit sécurité | 30 jours |
| Analytics | 90+ jours (DuckDB) |

### Performance

- Limiter `maxMessages` selon la RAM disponible
- Utiliser les filtres pour les requêtes
- Préférer `saveMessages()` (batch) à `saveMessage()` (unitaire)
- Activer le nettoyage automatique

---

## Dépannage

### Stockage localStorage Plein

**Symptômes** : Erreur "QuotaExceededError", messages non sauvegardés

**Solutions** :
1. Réduire `maxMessages` dans Configuration
2. Lancer un nettoyage manuel
3. Migrer vers SQLite ou DuckDB
4. Exporter puis supprimer les anciens messages

### Container SQLite/DuckDB Non Disponible

**Symptômes** : Fallback automatique vers localStorage, warning dans la console

**Solutions** :
1. Vérifier l'état du container dans Containers
2. Redémarrer le container
3. Vérifier les logs du container
4. Le fallback localStorage reste fonctionnel

### Perte de Messages

**Symptômes** : Messages manquants dans l'historique

**Causes possibles** :
1. QoS 0 utilisé pendant une déconnexion
2. `cleanSession=true` sur le client
3. Nettoyage automatique trop agressif

**Solutions** :
1. Utiliser QoS 1 ou 2 pour les messages importants
2. Configurer `cleanSession=false`
3. Augmenter `autoCleanupDays`

### Timeout MQTT (10s)

**Symptômes** : Erreur "Timeout: pas de réponse de..."

**Causes possibles** :
1. Container surchargé
2. Broker MQTT déconnecté
3. Réseau lent

**Solutions** :
1. Vérifier la connexion au broker
2. Redémarrer le container de stockage
3. Le fallback localStorage prend le relais

### Messages Dupliqués

**Symptômes** : Mêmes messages apparaissent plusieurs fois

**Causes possibles** :
1. QoS 1 avec re-livraison
2. Reconnexion client avec messages en attente

**Solutions** :
1. Utiliser QoS 2 si l'unicité est critique
2. Implémenter une déduplication côté application (par ID)

---

## Voir Aussi

- [Guide d'Intégration MQTT](guide-integration-mqtt.md) - Configuration des brokers
- [Guide de Monitoring MQTT](guide-monitoring-mqtt.md) - Interface de surveillance
- [Guide des Entités Calculées](guide-entites-calculees.md) - Historique des calculs
- [Structure JSON des Microservices](microservice-json.md) - Containers SQLite/DuckDB
- [Guide des Sauvegardes](guide-sauvegardes.md) - Systèmes de backup complets
