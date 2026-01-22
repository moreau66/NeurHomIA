# Guide d'Intégration MQTT 📡

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

## Table des matières

1. [Introduction](#introduction)
2. [Architecture MQTT](#architecture-mqtt)
3. [Configuration des Brokers](#configuration-des-brokers)
4. [Connexion au Broker](#connexion-au-broker)
5. [Souscription aux Topics](#souscription-aux-topics)
6. [Publication de Messages](#publication-de-messages)
7. [Format des Messages](#format-des-messages)
8. [Topics MQTT par Entité](#topics-mqtt-par-entité)
9. [Bridges Inter-Brokers](#bridges-inter-brokers)
10. [Mode Simulation](#mode-simulation)
11. [Utilisation dans les Widgets](#utilisation-dans-les-widgets)
12. [Topics du Local Engine](#topics-du-local-engine)
13. [Bonnes Pratiques](#bonnes-pratiques)
14. [Dépannage](#dépannage)

---

## Introduction

MQTT (Message Queuing Telemetry Transport) est le protocole de communication central de NeurHomIA. Il permet :

- **Communication temps réel** entre tous les composants du système
- **Architecture découplée** : les producteurs et consommateurs ne se connaissent pas
- **Légèreté** : idéal pour les appareils IoT à ressources limitées
- **Fiabilité** : niveaux de QoS garantissant la livraison des messages

Contrairement aux API REST traditionnelles (requête/réponse), MQTT utilise le pattern **Publish/Subscribe** : les clients publient sur des topics et s'abonnent aux topics qui les intéressent, le broker se charge de la distribution.

---

## Architecture MQTT

### Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                      MQTT Broker                             │
│                    (Mosquitto)                               │
└─────────────┬───────────────────────────────┬───────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │   mqttService   │◄────────────│  MqttBrokers    │
    │    (Façade)     │             │    (Store)      │
    └────────┬────────┘             └─────────────────┘
             │
    ┌────────┴────────┐
    ▼                 ▼
Production       Simulation
 Service           Service
```

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `src/services/mqttService.ts` | Façade principale avec bascule automatique |
| `src/services/mqttProductionService.ts` | Implémentation connexion broker réel |
| `src/services/mqttSimulation.ts` | Service de simulation sans broker |
| `src/services/interfaces/IMqttService.ts` | Contrat d'interface commun |
| `src/services/mqttDiscoveryService.ts` | Découverte automatique de brokers |
| `src/store/use-mqtt-brokers.ts` | Store Zustand pour configuration persistée |
| `src/types/config.ts` | Types TypeScript (MqttConfig, MqttMessage, etc.) |

### Interface commune `IMqttService`

```typescript
interface IMqttService {
  connect(brokerUrl?: string): Promise<void>;
  disconnect(): void;
  subscribe(topic: string, callback: (message: MqttMessage) => void): () => void;
  publish(topic: string, payload: string, qos?: 0 | 1 | 2): void;
  isConnected(): boolean;
}
```

---

## Configuration des Brokers

### Interface `MqttConfig`

```typescript
interface MqttConfig {
  id: string;                    // Identifiant unique
  name: string;                  // Nom d'affichage
  broker: string;                // URL (mqtt://host ou mqtts://host)
  port: number;                  // 1883 (standard) ou 8883 (TLS)
  clientId: string;              // ID client unique
  username?: string;             // Authentification
  password?: string;             // Mot de passe
  keepAlive: boolean;            // Maintenir la connexion active
  keepAliveInterval: number;     // Intervalle en secondes
  connectTimeout: number;        // Timeout de connexion (ms)
  reconnectPeriod: number;       // Délai de reconnexion (ms)
  maxReconnectAttempts: number;  // Nombre max de tentatives
  cleanSession: boolean;         // Session propre à chaque connexion
  isDefault: boolean;            // Broker par défaut
  active?: boolean;              // État actif/inactif
  
  // Sécurité
  useTls?: boolean;              // Connexion chiffrée
  verifyServerCert?: boolean;    // Vérifier le certificat serveur
  allowInsecure?: boolean;       // Autoriser connexions non sécurisées
  
  // Journalisation
  logConnections?: boolean;      // Logger les connexions
  logSubscriptions?: boolean;    // Logger les souscriptions
  logMessages?: boolean;         // Logger les messages
  logErrors?: boolean;           // Logger les erreurs
  persistLogs?: boolean;         // Persister les logs
  logRetentionDays?: number;     // Rétention en jours
  
  // Métadonnées système
  isSystem?: boolean;            // Broker géré par NeurHomIA
  autoDiscovered?: boolean;      // Découvert automatiquement
  category?: "core" | "custom" | "bridge";
  containerName?: string;        // Nom du container Docker
  healthStatus?: "running" | "stopped" | "error";
  
  // Topics configurés
  subscribedTopics?: MqttSubscription[];
  publishTopics?: MqttPublishTopic[];
  globalSubscription?: boolean;  // Abonnement global (#)
  bridges?: MqttBridge[];        // Ponts vers autres brokers
  
  createdAt: string;
  updatedAt: string;
}
```

### Types de brokers

| Type | `isSystem` | `category` | Description |
|------|------------|------------|-------------|
| Core | `true` | `"core"` | Mosquitto géré par NeurHomIA, non supprimable |
| Custom | `false` | `"custom"` | Broker externe configuré manuellement |
| Bridge | `false` | `"bridge"` | Pont entre deux brokers |

### Découverte automatique

Le système peut découvrir automatiquement un broker via :

1. **Variable d'environnement** :
   ```
   VITE_MQTT_BROKER_URL=mqtt://localhost:1883
   ```

2. **Service de découverte** :
   ```typescript
   import { MqttDiscoveryService } from '@/services/mqttDiscoveryService';
   
   const broker = await MqttDiscoveryService.discoverMcpBroker();
   if (broker) {
     console.log(`Broker trouvé: ${broker.broker}:${broker.port}`);
   }
   ```

---

## Connexion au Broker

### Via le service façade (recommandé)

```typescript
import { mqttService, updateMqttService } from '@/services/mqttService';

// Basculer vers le mode production
updateMqttService(false);  // isSimulationRunning = false

// La connexion est automatique si VITE_MQTT_BROKER_URL est défini
// Sinon, fallback vers le mode simulation
```

### Logique de bascule automatique

```typescript
export function updateMqttService(isSimulationRunning: boolean): void {
  const brokerUrl = import.meta.env.VITE_MQTT_BROKER_URL;
  
  if (isSimulationRunning) {
    // Mode SIMULATION : pas de broker requis
    mqttServiceInstance = new MqttSimulationService();
    mqttServiceInstance.connect();
  } else if (brokerUrl) {
    // Mode PRODUCTION : connexion au broker réel
    mqttServiceInstance = new MqttProductionService();
    mqttServiceInstance.connect(brokerUrl);
  } else {
    // Fallback : pas de broker configuré → simulation
    mqttServiceInstance = new MqttSimulationService();
    mqttServiceInstance.connect();
  }
}
```

### Via le service de production directement

```typescript
import { MqttProductionService } from '@/services/mqttProductionService';

const mqtt = new MqttProductionService();

await mqtt.connect('mqtt://localhost:1883', {
  keepalive: 60,
  reconnectPeriod: 5000,
  connectTimeout: 30000,
  clean: true,
  username: 'user',
  password: 'pass'
});
```

### Événements de connexion

| Événement | Description |
|-----------|-------------|
| `connect` | Connexion établie avec succès |
| `error` | Erreur de connexion ou de communication |
| `close` | Connexion fermée (volontaire ou non) |
| `reconnect` | Tentative de reconnexion automatique |
| `offline` | Client passé hors ligne |

---

## Souscription aux Topics

### Méthode `subscribe`

```typescript
import { mqttService } from '@/services/mqttService';

// Souscrire à un topic
const unsubscribe = mqttService.subscribe(
  'domotique/salon/light/+/state',
  (message) => {
    console.log(`Topic: ${message.topic}`);
    console.log(`Payload: ${message.payload}`);
    console.log(`QoS: ${message.qos}`);
    console.log(`Timestamp: ${message.timestamp}`);
  }
);

// Plus tard, se désabonner
unsubscribe();
```

### Wildcards MQTT

| Wildcard | Description | Exemple | Correspondance |
|----------|-------------|---------|----------------|
| `+` | Un seul niveau | `domotique/+/light/+/state` | `domotique/salon/light/lamp1/state` |
| `#` | Tous les niveaux suivants | `domotique/salon/#` | `domotique/salon/light/lamp1/state`, `domotique/salon/sensor/temp/value` |

⚠️ **Attention** : `#` doit toujours être le dernier caractère du topic.

### Interface `MqttSubscription`

```typescript
interface MqttSubscription {
  id: string;              // Identifiant unique
  topic: string;           // Pattern du topic
  qos: 0 | 1 | 2;          // Niveau de qualité de service
  enabled: boolean;        // Souscription active/inactive
  description?: string;    // Description optionnelle
  lastMessage?: {          // Dernier message reçu
    payload: string;
    timestamp: string;
  };
}
```

### Souscription globale

Pour recevoir **tous** les messages du broker :

```typescript
mqttService.subscribe('#', (message) => {
  // Reçoit tous les messages
  console.log(`[${message.topic}] ${message.payload}`);
});
```

---

## Publication de Messages

### Méthode `publish`

```typescript
import { mqttService } from '@/services/mqttService';

// Publication simple (QoS 0 par défaut)
mqttService.publish(
  'domotique/salon/light/lamp_001/set',
  'ON'
);

// Publication avec QoS spécifique
mqttService.publish(
  'domotique/salon/light/lamp_001/set',
  JSON.stringify({ state: 'ON', brightness: 200 }),
  1  // QoS 1 : au moins une livraison
);
```

### Niveaux de QoS (Quality of Service)

| QoS | Nom | Description | Usage recommandé |
|-----|-----|-------------|------------------|
| 0 | At most once | Fire & forget, pas de confirmation | Données fréquentes, perte acceptable |
| 1 | At least once | Livraison garantie, doublons possibles | Commandes importantes |
| 2 | Exactly once | Livraison unique garantie | Transactions critiques |

### Interface `MqttPublishTopic`

```typescript
interface MqttPublishTopic {
  id: string;              // Identifiant unique
  topic: string;           // Topic de publication
  description: string;     // Description du topic
  example_payload: string; // Exemple de payload
  qos: 0 | 1 | 2;          // QoS par défaut
  retain: boolean;         // Message retenu par le broker
}
```

### Messages retenus (Retain)

Un message avec `retain: true` est conservé par le broker et envoyé immédiatement à tout nouveau souscripteur :

```typescript
// Le broker conserve ce message
mqttService.publish('domotique/salon/light/lamp_001/state', 'ON', 1);
// Note: retain flag géré au niveau du broker ou de la configuration
```

---

## Format des Messages

### Interface `MqttMessage`

```typescript
interface MqttMessage {
  topic: string;           // Topic du message
  payload: string;         // Contenu (toujours string)
  timestamp: Date;         // Date de réception
  qos: 0 | 1 | 2;          // Niveau de QoS
  scheduledId?: string;    // ID si message planifié
}
```

### Interface `MqttMessage` (version config.ts)

```typescript
interface MqttMessage {
  id: string;              // Identifiant unique
  brokerId: string;        // ID du broker source
  topic: string;           // Topic
  payload: string;         // Contenu
  qos: 0 | 1 | 2;          // QoS
  retain: boolean;         // Message retenu
  timestamp: string;       // ISO 8601
}
```

### Formats de payload courants

| Format | Exemple | Usage |
|--------|---------|-------|
| Texte simple | `"ON"`, `"OFF"`, `"TOGGLE"` | États binaires, commandes simples |
| Nombre | `"22.5"`, `"255"`, `"0"` | Valeurs numériques (température, luminosité) |
| JSON | `{"state": "ON", "brightness": 200}` | Données structurées, attributs multiples |
| CSV | `"255,128,64"` | Couleurs RGB, listes de valeurs |
| Booléen | `"true"`, `"false"` | États on/off |

### Mapping des valeurs

Pour transformer les valeurs entre MQTT et l'interface :

```typescript
interface ValueMapping {
  type: 'direct' | 'linear' | 'map';
  input_range?: [number, number];   // Pour 'linear'
  output_range?: [number, number];  // Pour 'linear'
  value_map?: Record<string, string>; // Pour 'map'
}
```

**Exemples** :

```typescript
// Mapping linéaire : 0-100% → 0-255
const brightnessMapping: ValueMapping = {
  type: 'linear',
  input_range: [0, 100],
  output_range: [0, 255]
};

// Mapping de valeurs : texte → texte
const stateMapping: ValueMapping = {
  type: 'map',
  value_map: {
    'ON': 'true',
    'OFF': 'false',
    'TOGGLE': 'toggle'
  }
};
```

---

## Topics MQTT par Entité

### Interface `MqttTopicInfo`

```typescript
interface MqttTopicInfo {
  topic: string;                    // Topic complet
  description: string;              // Description
  example_payload: string;          // Exemple de payload
  direction: "subscribe" | "publish" | "bidirectional";
  subscribe_mapping?: ValueMapping; // Mapping en réception
  publish_mapping?: ValueMapping;   // Mapping en publication
}
```

### Interface `EnhancedMqttTopicInfo`

```typescript
interface EnhancedMqttTopicInfo extends MqttTopicInfo {
  category?: string;                // Catégorie (state, command, etc.)
  data_type?: "string" | "number" | "boolean" | "json";
  unit?: string;                    // Unité (°C, %, lux, etc.)
  suggested_payloads?: Array<{      // Valeurs suggérées
    label: string;
    value: string;
    description?: string;
  }>;
}
```

### Convention de nommage des topics

```
domotique/{localisation}/{type}/{appareil}/{action}
```

| Segment | Description | Exemples |
|---------|-------------|----------|
| `domotique` | Préfixe racine | Fixe |
| `{localisation}` | Emplacement hiérarchique | `salon`, `rdc/cuisine`, `etage1/chambre1` |
| `{type}` | Type d'appareil | `light`, `sensor`, `shutter`, `switch` |
| `{appareil}` | Identifiant unique | `lamp_001`, `temp_salon`, `volet_chambre` |
| `{action}` | Type de donnée | `state`, `set`, `value`, `position` |

**Exemples complets** :

| Topic | Description |
|-------|-------------|
| `domotique/salon/light/lamp_001/state` | État de la lampe (ON/OFF) |
| `domotique/salon/light/lamp_001/set` | Commande pour la lampe |
| `domotique/cuisine/sensor/temp_001/value` | Valeur du capteur de température |
| `domotique/chambre/shutter/volet_001/position` | Position du volet (0-100%) |
| `domotique/garage/switch/porte_001/state` | État du contacteur de porte |

---

## Bridges Inter-Brokers

### Interface `MqttBridge`

```typescript
interface MqttBridge {
  id: string;                      // Identifiant unique
  name: string;                    // Nom d'affichage
  remoteHost: string;              // Hôte du broker distant
  remotePort: number;              // Port (1883 ou 8883)
  username?: string;               // Authentification
  password?: string;               // Mot de passe
  useTls?: boolean;                // Connexion chiffrée
  enabled: boolean;                // Pont actif/inactif
  direction: "in" | "out" | "both"; // Direction des messages
  localPrefix?: string;            // Préfixe local ajouté
  remotePrefix?: string;           // Préfixe distant
  topicPatterns: MqttTopicPattern[]; // Patterns de topics à transférer
  keepAlive: number;               // Keepalive en secondes
  cleanSession: boolean;           // Session propre
  description?: string;            // Description optionnelle
  createdAt: string;
  updatedAt: string;
}
```

### Interface `MqttTopicPattern`

```typescript
interface MqttTopicPattern {
  id: string;
  pattern: string;         // Pattern avec wildcards
  description?: string;
  enabled: boolean;
  qos: 0 | 1 | 2;
}
```

### Directions de pont

| Direction | Description | Cas d'usage |
|-----------|-------------|-------------|
| `in` | Distant → Local | Recevoir des données d'un broker externe |
| `out` | Local → Distant | Envoyer des données vers un broker cloud |
| `both` | Bidirectionnel | Synchronisation complète entre brokers |

### Exemple de configuration

```typescript
const bridge: MqttBridge = {
  id: 'bridge-cloud',
  name: 'Pont vers Cloud',
  remoteHost: 'mqtt.cloud-provider.com',
  remotePort: 8883,
  username: 'user',
  password: 'secret',
  useTls: true,
  enabled: true,
  direction: 'out',
  localPrefix: '',
  remotePrefix: 'home/',
  topicPatterns: [
    { id: '1', pattern: 'domotique/+/sensor/#', enabled: true, qos: 1 }
  ],
  keepAlive: 60,
  cleanSession: true,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString()
};
```

---

## Mode Simulation

### Activation de la simulation

```typescript
import { updateMqttService } from '@/services/mqttService';

// Activer le mode simulation
updateMqttService(true);

// Vérifier le mode actuel
console.log(mqttService.isConnected()); // true (simulation)
```

### Caractéristiques du mode simulation

| Aspect | Comportement |
|--------|--------------|
| Broker | Aucun broker réel requis |
| Messages | Générés localement en mémoire |
| Historique | Conservé pendant la session |
| Souscriptions | Fonctionnelles (callbacks appelés) |
| Publications | Stockées et distribuées localement |
| Performances | Instantané, pas de latence réseau |

### Service `MqttSimulationService`

Le service de simulation implémente la même interface `IMqttService` :

```typescript
class MqttSimulationService implements IMqttService {
  private subscriptions: Map<string, Set<(msg: MqttMessage) => void>>;
  private messageHistory: MqttMessage[];
  
  connect(): Promise<void> {
    // Connexion immédiate (pas de réseau)
    return Promise.resolve();
  }
  
  subscribe(topic: string, callback: (msg: MqttMessage) => void): () => void {
    // Stockage du callback pour distribution ultérieure
  }
  
  publish(topic: string, payload: string, qos?: number): void {
    // Distribution immédiate aux souscripteurs correspondants
  }
}
```

### Génération de données de test

```typescript
// Certains services de simulation peuvent exposer cette méthode
if (mqttService.publishTestData) {
  mqttService.publishTestData();
}
```

---

## Utilisation dans les Widgets

### Pattern recommandé

```typescript
import { mqttService } from '@/services/mqttService';

const MyWidget = ({ device }) => {
  // 1. Récupérer la configuration des topics
  const mqttTopics = device.mqtt_topics;
  
  // 2. Fonction utilitaire de publication
  const publishMqttUpdate = (topicKey: string, payload: string) => {
    if (mqttTopics && mqttTopics[topicKey]) {
      const fullTopic = mqttTopics[topicKey].topic;
      const qos = mqttTopics[topicKey].qos || 1;
      
      mqttService.publish(fullTopic, payload, qos);
      console.log(`[MQTT] ${fullTopic} = ${payload}`);
    }
  };
  
  // 3. Utilisation
  const handleToggle = () => {
    publishMqttUpdate('set', device.state === 'ON' ? 'OFF' : 'ON');
  };
  
  return <Button onClick={handleToggle}>Toggle</Button>;
};
```

### Exemple concret : ShutterWidget

```typescript
const ShutterWidget = ({ device }) => {
  const publishMqttUpdate = (topic: string, payload: string, logMessage: string) => {
    const mqttTopics = (device as any).mqtt_topics;
    if (mqttTopics && mqttTopics[topic]) {
      const fullTopic = mqttTopics[topic].topic;
      mqttService.publish(fullTopic, payload, 1);
      console.log(`[MQTT] ${logMessage}: ${fullTopic} = ${payload}`);
    }
  };
  
  const handleOpen = () => publishMqttUpdate('open', 'OPEN', 'Ouverture');
  const handleClose = () => publishMqttUpdate('close', 'CLOSE', 'Fermeture');
  const handleStop = () => publishMqttUpdate('stop', 'STOP', 'Arrêt');
  const handlePosition = (pos: number) => publishMqttUpdate('position', String(pos), `Position ${pos}%`);
  
  // ...
};
```

### Souscription dans un composant React

```typescript
import { useEffect } from 'react';
import { mqttService } from '@/services/mqttService';

const SensorDisplay = ({ sensorTopic }) => {
  const [value, setValue] = useState<string | null>(null);
  
  useEffect(() => {
    const unsubscribe = mqttService.subscribe(sensorTopic, (message) => {
      setValue(message.payload);
    });
    
    return () => unsubscribe(); // Cleanup
  }, [sensorTopic]);
  
  return <div>Valeur: {value ?? 'En attente...'}</div>;
};
```

---

## Topics du Local Engine

Le backend Node.js (Local Engine) utilise des topics réservés pour la communication :

### Topics de statut

| Topic | Direction | Description |
|-------|-----------|-------------|
| `neurhomia/local-engine/status` | Publish | État du service (running/stopped) |
| `neurhomia/local-engine/heartbeat` | Publish | Battement de cœur périodique |

### Topics des scénarios

| Topic | Direction | Description |
|-------|-----------|-------------|
| `neurhomia/local-engine/scenarios/status` | Publish | État des scénarios actifs |
| `neurhomia/local-engine/scenarios/executed` | Publish | Notification d'exécution |
| `neurhomia/local-engine/scenarios/error` | Publish | Erreurs d'exécution |

### Topics de commande

| Topic | Direction | Description |
|-------|-----------|-------------|
| `neurhomia/local-engine/command/sync` | Subscribe | Demande de synchronisation |
| `neurhomia/local-engine/command/trigger` | Subscribe | Déclenchement manuel de scénario |

### Exemple de payload

```json
// neurhomia/local-engine/scenarios/executed
{
  "scenarioId": "scenario_001",
  "name": "Éclairage salon",
  "trigger": "cron",
  "executedAt": "2026-01-20T14:30:00Z",
  "actions": 3,
  "success": true
}
```

---

## Bonnes Pratiques

### Nommage des topics

✅ **Faire** :
- Utiliser des topics hiérarchiques et descriptifs
- Suivre une convention cohérente (`domotique/{zone}/{type}/{device}/{action}`)
- Utiliser des identifiants uniques pour les appareils

❌ **Éviter** :
- Topics trop longs ou cryptiques
- Espaces ou caractères spéciaux
- Incohérences de casse (préférer tout en minuscules)

### Choix du QoS

| Situation | QoS recommandé |
|-----------|----------------|
| Données de capteurs fréquentes | 0 |
| États d'appareils | 1 |
| Commandes importantes | 1 |
| Transactions critiques | 2 |

### Format des payloads

✅ **Faire** :
- Préférer JSON pour les données structurées
- Utiliser des valeurs standardisées (`ON`/`OFF`, `true`/`false`)
- Documenter les formats attendus

❌ **Éviter** :
- Payloads trop volumineux (MQTT n'est pas fait pour les gros fichiers)
- Formats propriétaires non documentés

### Gestion des erreurs

```typescript
try {
  await mqttService.connect('mqtt://broker:1883');
} catch (error) {
  console.error('Connexion échouée:', error);
  // Fallback vers simulation ou notification utilisateur
}
```

### Souscriptions efficaces

- Limiter les souscriptions au strict nécessaire
- Utiliser des wildcards ciblés plutôt que `#`
- Toujours se désabonner dans le cleanup des composants

---

## Dépannage

### Connexion échouée

**Symptômes** : Message d'erreur à la connexion, statut "disconnected"

**Vérifications** :
1. URL du broker correcte (protocole `mqtt://` ou `mqtts://`)
2. Port accessible (1883 standard, 8883 TLS)
3. Credentials valides si authentification requise
4. Broker démarré et accessible réseau

```bash
# Test de connexion
mosquitto_sub -h localhost -p 1883 -t '#' -v
```

### Messages non reçus

**Symptômes** : Souscription active mais pas de messages

**Vérifications** :
1. Topic de souscription correspond au topic de publication
2. Wildcards correctement utilisés (`+` vs `#`)
3. QoS suffisant pour garantir la livraison
4. Callback correctement défini

```typescript
// Debug : afficher tous les messages
mqttService.subscribe('#', (msg) => {
  console.log(`[DEBUG] ${msg.topic}: ${msg.payload}`);
});
```

### Mode simulation inattendu

**Symptômes** : L'application fonctionne mais sans données réelles

**Vérifications** :
1. Variable `VITE_MQTT_BROKER_URL` définie dans `.env`
2. Appel à `updateMqttService(false)` effectué
3. Pas d'erreur de connexion silencieuse

```typescript
// Forcer le mode production
updateMqttService(false);
console.log('Mode:', mqttService.isConnected() ? 'Connecté' : 'Déconnecté');
```

### Doublons de messages

**Symptômes** : Messages reçus plusieurs fois

**Causes possibles** :
1. Souscriptions multiples au même topic
2. QoS 1 avec relivraison après timeout
3. Bridge créant des boucles

**Solutions** :
- Vérifier le cleanup des souscriptions
- Utiliser QoS 0 si les doublons sont inacceptables
- Configurer correctement les préfixes de bridge

### Latence élevée

**Symptômes** : Délai important entre publication et réception

**Vérifications** :
1. Réseau entre client et broker
2. Charge du broker
3. QoS 2 utilisé inutilement

```typescript
// Mesurer la latence
const start = Date.now();
mqttService.publish('test/ping', String(start));
mqttService.subscribe('test/ping', (msg) => {
  console.log(`Latence: ${Date.now() - parseInt(msg.payload)}ms`);
});
```

---

## Voir aussi

- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Interface de surveillance
- [Guide des Entités MQTT](guide-entites-mqtt.md) - Configuration des appareils
- [Guide du Local Engine](guide-local-engine.md) - Backend Node.js
- [Référence JSON Microservices](microservice-json.md) - Format des configurations
