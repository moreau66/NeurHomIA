# 🌐 Guide de Configuration des Brokers MQTT

> **Version** : 1.1.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide détaille toutes les options de configuration des brokers MQTT dans NeurHomIA, avec des exemples pratiques pour les principaux fournisseurs cloud.

---

## 📑 Table des matières

- [Introduction](#introduction)
- [Accès à l'interface](#-accès-à-linterface-de-configuration)
- [Assistant de configuration](#-assistant-de-configuration-guidé)
- [Templates de cas d'usage](#-templates-de-cas-dusage)
- [Compatibilité des écosystèmes](#-compatibilité-des-écosystèmes)
- [Paramètres de configuration](#-paramètres-de-configuration)
- [Exemples par fournisseur](#-exemples-de-configuration-par-fournisseur)
- [Configuration des topics](#-configuration-des-topics)
- [Bridges entre brokers](#-bridges-entre-brokers)
- [Sécurité et bonnes pratiques](#-sécurité-et-bonnes-pratiques)
- [Dépannage](#-dépannage)
- [Variables d'environnement](#-variables-denvironnement)

---

## Introduction

NeurHomIA supporte plusieurs types de brokers MQTT :

| Type | Description | Cas d'usage |
|------|-------------|-------------|
| **Local** | Mosquitto en conteneur Docker | Développement, réseau local isolé |
| **Cloud** | HiveMQ, EMQX, CloudMQTT, AWS IoT | Production, accès distant, haute disponibilité |
| **Bridge** | Synchronisation entre brokers | Réplication, agrégation multi-sites |

### Quand utiliser un broker externe ?

- ✅ Accès à distance depuis l'extérieur du réseau local
- ✅ Haute disponibilité et redondance
- ✅ Intégration avec des services cloud (AWS, Azure, Google Cloud)
- ✅ Monitoring et analytics avancés
- ✅ Scalabilité automatique

### Prérequis

- Compte chez le fournisseur cloud choisi
- Credentials (username/password ou certificats)
- Ports réseau ouverts (8883 pour MQTTS, 8884 pour WSS)

---

## 🖥️ Accès à l'interface de configuration

L'interface de configuration des brokers est accessible via :

1. **Menu principal** → Configuration système
2. **Section** → Brokers MQTT
3. **URL directe** : `/mqtt-config`

### Vue d'ensemble de l'interface

```
┌─────────────────────────────────────────────────────────┐
│  Configuration des Brokers MQTT                         │
├─────────────────────────────────────────────────────────┤
│  [+ Ajouter un broker]                                  │
├─────────────────────────────────────────────────────────┤
│  ● Mosquitto Local          Connecté    [Éditer] [×]    │
│  ○ HiveMQ Cloud             Déconnecté  [Éditer] [×]    │
│  ○ EMQX Production          Inactif     [Éditer] [×]    │
└─────────────────────────────────────────────────────────┘
```

---

## 🧙 Assistant de configuration guidé

NeurHomIA propose un assistant étape par étape pour configurer votre premier broker MQTT.

### Accès à l'assistant

- **Automatique** : S'ouvre à la première visite si aucun broker n'est configuré
- **Manuel** : Bouton "Assistant" dans la page `/mqtt-config`

### Étapes de l'assistant

| Étape | Description |
|-------|-------------|
| 1. Bienvenue | Présentation et choix du mode (guidé/manuel) |
| 2. Type de broker | Sélection parmi les presets (Mosquitto, HiveMQ, EMQX...) |
| 3. Cas d'usage | Templates pour écosystèmes domotiques |
| 4. Configuration | Formulaire pré-rempli avec aide contextuelle |
| 5. Test | Vérification de la connexion en temps réel |
| 6. Confirmation | Résumé et création du broker |

### Presets de brokers disponibles

| Preset | Port | TLS | Description |
|--------|------|-----|-------------|
| Mosquitto Local | 1883 | Non | Docker local, idéal pour le développement |
| HiveMQ Cloud | 8884 | WSS | Service cloud gratuit (100 connexions) |
| EMQX Cloud | 8883 | Oui | Plan serverless avec 1000 sessions/mois gratuites |
| CloudMQTT | Variable | Optionnel | Service simple (5 connexions gratuites) |
| Manuel | - | - | Configuration libre pour tout broker |

### Test de connexion intégré

L'assistant inclut un test de connexion en temps réel qui vérifie :

- ✅ Résolution DNS du broker
- ✅ Ouverture du port réseau
- ✅ Négociation TLS (si activé)
- ✅ Authentification MQTT
- ✅ Mesure de la latence

Le résultat s'affiche avec un indicateur visuel (succès/échec) et des détails de diagnostic.

---

## 🏠 Templates de cas d'usage

L'assistant propose des templates pré-configurés pour les principaux écosystèmes domotiques.

### Home Assistant

**Topics de découverte** :
- `homeassistant/+/+/config` - Auto-discovery MQTT
- `homeassistant/status` - État de Home Assistant

**Abonnements par défaut** : `homeassistant/#`

**Documentation** : [home-assistant.io/integrations/mqtt](https://www.home-assistant.io/integrations/mqtt/)

---

### Zigbee2MQTT

**Topics de découverte** :
- `zigbee2mqtt/bridge/state` - État du bridge
- `zigbee2mqtt/bridge/devices` - Liste des appareils

**Abonnements par défaut** : `zigbee2mqtt/#`

**Documentation** : [zigbee2mqtt.io](https://www.zigbee2mqtt.io/)

> 💡 **Astuce** : Le topic `zigbee2mqtt/bridge/devices` permet de récupérer automatiquement la liste de tous les appareils Zigbee appairés.

---

### Tasmota

**Topics de découverte** :
- `tasmota/discovery/+/config` - Auto-discovery
- `tele/+/LWT` - Disponibilité (Last Will and Testament)

**Abonnements par défaut** : `tasmota/#`, `tele/#`, `stat/#`, `cmnd/#`

**Documentation** : [tasmota.github.io/docs/MQTT](https://tasmota.github.io/docs/MQTT/)

> 💡 **Astuce** : Activez `SetOption19 1` pour utiliser le format de découverte Home Assistant.

---

### Shelly (Gen1/Gen2/Gen3)

Les appareils Shelly utilisent des structures de topics différentes selon leur génération.

**Gen1 (Shelly 1, Shelly 2.5, etc.)** :

| Topic | Description |
|-------|-------------|
| `shellies/announce` | Découverte des appareils |
| `shellies/+/info` | Informations système |
| `shellies/+/relay/0` | État du relais |

**Abonnements Gen1** : `shellies/#`

**Gen2/Gen3 (Shelly Plus, Shelly Pro, etc.)** :

| Topic | Description |
|-------|-------------|
| `+/status/sys` | État système |
| `+/status/switch:0` | État du switch |
| `+/events/rpc` | Événements RPC |

**Abonnements Gen2/3** : `+/status/#`, `+/events/rpc`

> ⚠️ **Important** : Les appareils Shelly Gen2/3 utilisent l'ID de l'appareil (ex: `shellyplus1-a8b1c2d3e4f5`) comme préfixe de topic au lieu de `shellies`.

**Documentation** : [shelly-api-docs.shelly.cloud](https://shelly-api-docs.shelly.cloud/)

---

### ESPHome

**Topics de découverte** :
- `esphome/discover` - Découverte globale
- `+/status` - Disponibilité des appareils

**Abonnements par défaut** :
- `+/sensor/+/state` - Capteurs
- `+/switch/+/state` - Interrupteurs
- `+/light/+/state` - Lumières
- `+/binary_sensor/+/state` - Capteurs binaires

**Documentation** : [esphome.io/components/mqtt](https://esphome.io/components/mqtt.html)

> 💡 **Astuce** : ESPHome supporte nativement le format de découverte Home Assistant. Activez `discovery: true` dans la configuration MQTT.

---

### Node-RED

**Topics de découverte** :
- `homeassistant/+/+/config` - Discovery format Home Assistant
- `homie/+/$state` - Convention Homie

**Abonnements par défaut** : `node-red/#`

**Documentation** : [nodered.org](https://nodered.org/)

> 💡 **Astuce** : Utilisez le nœud `mqtt-discovery` pour publier automatiquement vos entités au format Home Assistant.

---

## 📊 Compatibilité des écosystèmes

Tous les écosystèmes ne sont pas compatibles avec tous les types de brokers. Voici un tableau récapitulatif :

| Écosystème | Mosquitto Local | HiveMQ Cloud | EMQX Cloud | CloudMQTT | AWS IoT |
|------------|-----------------|--------------|------------|-----------|---------|
| Home Assistant | ✅ Recommandé | ✅ | ✅ | ⚠️ Limité | ✅ |
| Zigbee2MQTT | ✅ Recommandé | ❌ Local requis | ❌ Local requis | ❌ | ❌ |
| Tasmota | ✅ | ✅ | ✅ | ⚠️ Limité | ✅ |
| Shelly | ✅ | ✅ | ✅ | ⚠️ Limité | ✅ |
| ESPHome | ✅ | ✅ | ✅ | ⚠️ Limité | ✅ |
| Node-RED | ✅ | ✅ | ✅ | ✅ | ✅ |

**Légende** :
- ✅ Compatible et testé
- ⚠️ Compatible avec limitations (bande passante, connexions)
- ❌ Non compatible ou non recommandé

> 💡 **Recommandation** : Pour une installation domotique locale, privilégiez Mosquitto en Docker. Pour un accès distant sécurisé, combinez Mosquitto local avec un bridge vers HiveMQ ou EMQX Cloud.

---

## ⚙️ Paramètres de configuration

### Interface MqttConfig complète

```typescript
interface MqttConfig {
  // Identification
  id: string;                    // Identifiant unique (UUID)
  name: string;                  // Nom affiché dans l'interface
  
  // Connexion
  broker: string;                // URL du broker (mqtt://, mqtts://, ws://, wss://)
  port: number;                  // Port de connexion
  clientId?: string;             // ID client (auto-généré si absent)
  
  // Authentification
  username?: string;             // Nom d'utilisateur
  password?: string;             // Mot de passe
  
  // Sécurité TLS/SSL
  useTls?: boolean;              // Activer TLS (défaut: false)
  verifyServerCert?: boolean;    // Vérifier le certificat serveur (défaut: true)
  allowInsecure?: boolean;       // Autoriser les connexions non sécurisées (défaut: false)
  
  // Paramètres réseau
  keepAlive?: boolean;           // Activer le keepalive (défaut: true)
  keepAliveInterval?: number;    // Intervalle keepalive en secondes (défaut: 60)
  connectTimeout?: number;       // Timeout de connexion en ms (défaut: 30000)
  reconnectPeriod?: number;      // Délai de reconnexion en ms (défaut: 1000)
  maxReconnectAttempts?: number; // Tentatives max de reconnexion (défaut: 10)
  cleanSession?: boolean;        // Session propre à chaque connexion (défaut: true)
  
  // Journalisation
  logConnections?: boolean;      // Logger les connexions/déconnexions
  logSubscriptions?: boolean;    // Logger les abonnements
  logMessages?: boolean;         // Logger tous les messages
  logErrors?: boolean;           // Logger les erreurs
  persistLogs?: boolean;         // Persister les logs
  logRetentionDays?: number;     // Durée de rétention des logs en jours
  
  // Métadonnées
  isDefault?: boolean;           // Broker par défaut
  active?: boolean;              // Broker actif
  isSystem?: boolean;            // Broker système (non supprimable)
  category?: 'core' | 'bridge' | 'external'; // Catégorie
}
```

### Tableau récapitulatif des paramètres

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `name` | string | - | Nom affiché (obligatoire) |
| `broker` | string | - | URL complète du broker (obligatoire) |
| `port` | number | 1883 | Port de connexion |
| `clientId` | string | auto | Identifiant client unique |
| `username` | string | - | Nom d'utilisateur |
| `password` | string | - | Mot de passe |
| `useTls` | boolean | false | Activer le chiffrement TLS |
| `verifyServerCert` | boolean | true | Vérifier le certificat SSL |
| `allowInsecure` | boolean | false | Autoriser connexions non sécurisées |
| `keepAliveInterval` | number | 60 | Intervalle keepalive (secondes) |
| `connectTimeout` | number | 30000 | Timeout connexion (ms) |
| `reconnectPeriod` | number | 1000 | Délai reconnexion (ms) |
| `maxReconnectAttempts` | number | 10 | Tentatives max reconnexion |
| `cleanSession` | boolean | true | Session propre |

---

## 🏢 Exemples de configuration par fournisseur

### 1. HiveMQ Cloud (Gratuit)

**Site web** : [hivemq.com/cloud](https://www.hivemq.com/cloud/)

**Inscription** :
1. Créer un compte sur HiveMQ Cloud
2. Créer un cluster gratuit (jusqu'à 100 connexions)
3. Ajouter des credentials dans "Access Management"
4. Noter l'URL du cluster (format: `xxxxxx.s1.eu.hivemq.cloud`)

**Configuration NeurHomIA** :

```typescript
const hivemqConfig: MqttConfig = {
  id: "hivemq-cloud-1",
  name: "HiveMQ Cloud",
  broker: "wss://xxxxxx.s1.eu.hivemq.cloud:8884/mqtt",
  port: 8884,
  useTls: true,
  verifyServerCert: true,
  username: "votre-utilisateur",
  password: "votre-mot-de-passe",
  cleanSession: true,
  keepAliveInterval: 60,
  reconnectPeriod: 5000,
  maxReconnectAttempts: 10,
  category: "external",
  active: true
};
```

**⚠️ Particularités HiveMQ Cloud** :
- Utilise **WebSocket Secure (WSS)** obligatoirement
- Port **8884** pour WSS (pas 8883)
- Chemin `/mqtt` requis dans l'URL
- Certificats Let's Encrypt (vérification activée)

---

### 2. EMQX Cloud

**Site web** : [emqx.com/cloud](https://www.emqx.com/en/cloud)

**Plans disponibles** :

| Plan | Connexions | Prix |
|------|------------|------|
| Serverless | 1000 sessions/mois gratuites | Gratuit |
| Dedicated | Illimitées | À partir de 99$/mois |

**Inscription** :
1. Créer un compte EMQX Cloud
2. Déployer un cluster (Serverless pour les tests)
3. Configurer l'authentification dans "Authentication"
4. Noter l'endpoint (format: `xxxxxx.emqxsl.com`)

**Configuration NeurHomIA** :

```typescript
const emqxConfig: MqttConfig = {
  id: "emqx-cloud-1",
  name: "EMQX Cloud",
  broker: "mqtts://xxxxxx.emqxsl.com",
  port: 8883,
  useTls: true,
  verifyServerCert: true,
  username: "votre-utilisateur",
  password: "votre-mot-de-passe",
  cleanSession: true,
  keepAliveInterval: 60,
  category: "external",
  active: true
};
```

**Configuration WebSocket (alternative)** :

```typescript
const emqxWsConfig: MqttConfig = {
  id: "emqx-cloud-ws",
  name: "EMQX Cloud (WebSocket)",
  broker: "wss://xxxxxx.emqxsl.com:8084/mqtt",
  port: 8084,
  useTls: true,
  verifyServerCert: true,
  username: "votre-utilisateur",
  password: "votre-mot-de-passe"
};
```

**⚠️ Particularités EMQX Cloud** :
- Supporte MQTT natif (8883) ET WebSocket (8084)
- Configuration ACL granulaire disponible
- Dashboard de monitoring intégré

---

### 3. CloudMQTT

**Site web** : [cloudmqtt.com](https://www.cloudmqtt.com/)

**Plan gratuit** : "Cute Cat" (5 connexions, 10 Kbit/s)

**Inscription** :
1. Créer un compte CloudMQTT
2. Créer une instance "Cute Cat" (gratuite)
3. Noter les informations de connexion dans le dashboard

**Configuration NeurHomIA** :

```typescript
const cloudmqttConfig: MqttConfig = {
  id: "cloudmqtt-1",
  name: "CloudMQTT",
  broker: "mqtt://xxxxxx.cloudmqtt.com",
  port: 18850,  // Port spécifique à votre instance
  useTls: false,
  username: "votre-utilisateur",
  password: "votre-mot-de-passe",
  cleanSession: true,
  keepAliveInterval: 30,
  category: "external",
  active: true
};
```

**Configuration TLS** :

```typescript
const cloudmqttTlsConfig: MqttConfig = {
  id: "cloudmqtt-tls",
  name: "CloudMQTT (TLS)",
  broker: "mqtts://xxxxxx.cloudmqtt.com",
  port: 28850,  // Port TLS spécifique
  useTls: true,
  verifyServerCert: true,
  username: "votre-utilisateur",
  password: "votre-mot-de-passe"
};
```

**⚠️ Particularités CloudMQTT** :
- Ports personnalisés par instance (vérifier le dashboard)
- Limitations strictes sur le plan gratuit
- Interface simple mais fonctionnelle

---

### 4. Mosquitto Local (Docker)

**Configuration Docker Compose** :

```yaml
# docker-compose.yml
services:
  mosquitto:
    image: eclipse-mosquitto:2.0
    container_name: mosquitto
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
    restart: unless-stopped
```

**Fichier de configuration Mosquitto** :

```conf
# mosquitto/config/mosquitto.conf
listener 1883
protocol mqtt

listener 9001
protocol websockets

# Authentification (optionnel)
# password_file /mosquitto/config/passwd
# allow_anonymous false

# Persistance
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_type all
```

**Configuration NeurHomIA** :

```typescript
const mosquittoLocalConfig: MqttConfig = {
  id: "mosquitto-local",
  name: "Mosquitto Local",
  broker: "mqtt://localhost",
  port: 1883,
  useTls: false,
  allowInsecure: true,
  cleanSession: true,
  keepAliveInterval: 60,
  isSystem: true,
  isDefault: true,
  category: "core",
  active: true
};
```

**Configuration WebSocket (pour navigateurs)** :

```typescript
const mosquittoWsConfig: MqttConfig = {
  id: "mosquitto-local-ws",
  name: "Mosquitto Local (WebSocket)",
  broker: "ws://localhost:9001",
  port: 9001,
  useTls: false,
  allowInsecure: true
};
```

---

### 5. AWS IoT Core

**Console** : [console.aws.amazon.com/iot](https://console.aws.amazon.com/iot)

**Prérequis** :
- Compte AWS
- Certificats X.509 (Thing certificate)
- Policy IoT configurée

**Configuration NeurHomIA** (authentification par mot de passe avec Custom Authorizer) :

```typescript
const awsIotConfig: MqttConfig = {
  id: "aws-iot-1",
  name: "AWS IoT Core",
  broker: "mqtts://xxxxxx-ats.iot.eu-west-1.amazonaws.com",
  port: 8883,
  useTls: true,
  verifyServerCert: true,
  username: "votre-custom-authorizer-username",
  password: "votre-token",
  cleanSession: true,
  keepAliveInterval: 300,  // AWS recommande 300s
  category: "external",
  active: true
};
```

**Policy IAM minimale** :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect",
        "iot:Publish",
        "iot:Subscribe",
        "iot:Receive"
      ],
      "Resource": [
        "arn:aws:iot:eu-west-1:ACCOUNT_ID:client/${iot:ClientId}",
        "arn:aws:iot:eu-west-1:ACCOUNT_ID:topic/neurhomia/*",
        "arn:aws:iot:eu-west-1:ACCOUNT_ID:topicfilter/neurhomia/*"
      ]
    }
  ]
}
```

**⚠️ Particularités AWS IoT Core** :
- Authentification par certificat X.509 recommandée
- Custom Authorizer pour username/password
- Keepalive recommandé : 300 secondes
- Limites de messages selon le tier

---

### 6. Azure IoT Hub

**Console** : [portal.azure.com](https://portal.azure.com/)

**Configuration NeurHomIA** :

```typescript
const azureIotConfig: MqttConfig = {
  id: "azure-iot-1",
  name: "Azure IoT Hub",
  broker: "mqtts://votre-hub.azure-devices.net",
  port: 8883,
  useTls: true,
  verifyServerCert: true,
  username: "votre-hub.azure-devices.net/votre-device/?api-version=2021-04-12",
  password: "SharedAccessSignature sr=...",  // SAS Token
  cleanSession: true,
  keepAliveInterval: 60,
  category: "external",
  active: true
};
```

**⚠️ Particularités Azure IoT Hub** :
- Username au format spécifique avec api-version
- Password = SAS Token (durée limitée)
- Topics prédéfinis par Azure

---

## 📡 Configuration des topics

### Topics abonnés (Subscriptions)

L'interface de gestion des topics permet de configurer les abonnements :

```typescript
interface MqttSubscription {
  topic: string;      // Pattern de topic (wildcards autorisés)
  qos: 0 | 1 | 2;     // Qualité de service
  enabled: boolean;   // Actif ou non
}
```

**Exemples de patterns** :

| Pattern | Description |
|---------|-------------|
| `domotique/salon/lumiere` | Topic exact |
| `domotique/salon/+` | Tous les appareils du salon |
| `domotique/#` | Tous les topics domotique |
| `+/+/temperature` | Toutes les températures |

### Wildcards MQTT

| Wildcard | Signification | Exemple |
|----------|---------------|---------|
| `+` | Un niveau exactement | `salon/+/etat` → `salon/lumiere/etat` |
| `#` | Zéro ou plusieurs niveaux | `salon/#` → `salon/lumiere/rgb/rouge` |

### Topics de publication

```typescript
interface MqttPublishTopic {
  topic: string;       // Topic de publication
  qos: 0 | 1 | 2;      // Qualité de service
  retain: boolean;     // Conserver le dernier message
}
```

**Niveaux de QoS** :

| QoS | Nom | Garantie |
|-----|-----|----------|
| 0 | At most once | Aucune (fire and forget) |
| 1 | At least once | Message reçu au moins une fois |
| 2 | Exactly once | Message reçu exactement une fois |

---

## 🌉 Bridges entre brokers

### Cas d'usage

- **Synchronisation local → cloud** : Sauvegarder les données locales
- **Réplication multi-sites** : Plusieurs installations synchronisées
- **Agrégation** : Centraliser les données de plusieurs brokers

### Configuration d'un bridge

```typescript
interface MqttBridge {
  id: string;
  name: string;
  localBrokerId: string;      // ID du broker local
  remoteBrokerId: string;     // ID du broker distant
  direction: 'in' | 'out' | 'both';
  localPrefix: string;        // Préfixe ajouté/retiré localement
  remotePrefix: string;       // Préfixe ajouté/retiré à distance
  topicPatterns: Array<{
    pattern: string;
    enabled: boolean;
    qos: 0 | 1 | 2;
  }>;
  enabled: boolean;
}
```

**Exemple : Bridge Local → HiveMQ Cloud** :

```typescript
const bridgeConfig: MqttBridge = {
  id: "bridge-local-hivemq",
  name: "Bridge Local → HiveMQ",
  localBrokerId: "mosquitto-local",
  remoteBrokerId: "hivemq-cloud-1",
  direction: "out",
  localPrefix: "",
  remotePrefix: "neurhomia/maison1/",
  topicPatterns: [
    { pattern: "domotique/#", enabled: true, qos: 1 },
    { pattern: "capteurs/#", enabled: true, qos: 0 }
  ],
  enabled: true
};
```

**Résultat** :
- `domotique/salon/lumiere` (local) → `neurhomia/maison1/domotique/salon/lumiere` (cloud)

---

## 🔒 Sécurité et bonnes pratiques

### Recommandations essentielles

| Pratique | Importance | Description |
|----------|------------|-------------|
| ✅ TLS en production | **Critique** | Toujours `useTls: true` pour les brokers cloud |
| ✅ Credentials uniques | **Haute** | Un compte par application/environnement |
| ✅ Rotation des mots de passe | **Haute** | Changer régulièrement (90 jours max) |
| ✅ ACL restrictives | **Haute** | Limiter les topics autorisés côté broker |
| ✅ ClientId unique | **Moyenne** | Éviter les conflits de session |
| ⚠️ allowInsecure | **Éviter** | Uniquement en développement local |
| ⚠️ verifyServerCert: false | **Éviter** | Désactive la vérification SSL |

### Configuration de production recommandée

```typescript
const productionConfig: Partial<MqttConfig> = {
  useTls: true,
  verifyServerCert: true,
  allowInsecure: false,
  cleanSession: true,
  keepAliveInterval: 60,
  reconnectPeriod: 5000,
  maxReconnectAttempts: -1,  // Reconnexion infinie
  logErrors: true,
  persistLogs: true,
  logRetentionDays: 30
};
```

### Gestion des secrets

Les credentials ne doivent **jamais** être stockés dans le code source :

```typescript
// ❌ MAUVAIS - Ne jamais faire ça
const config = {
  password: "mon-mot-de-passe-secret"
};

// ✅ BON - Utiliser les variables d'environnement
const config = {
  password: import.meta.env.VITE_MQTT_PASSWORD
};
```

---

## 🔧 Dépannage

### Erreurs courantes et solutions

| Code/Message | Cause probable | Solution |
|--------------|----------------|----------|
| `Connection refused` | Port fermé ou firewall | Vérifier les règles réseau |
| `Not authorized` | Credentials invalides | Vérifier username/password |
| `Bad username or password` | Authentification échouée | Régénérer les credentials |
| `Connection timeout` | Serveur injoignable | Vérifier l'URL et le port |
| `Certificate error` | Certificat invalide | `allowInsecure: true` ou installer CA |
| `Client ID in use` | Conflit de session | Utiliser un clientId unique |
| `Disconnected` (répété) | Keepalive trop court | Augmenter `keepAliveInterval` |

### Diagnostic de connexion

1. **Vérifier l'URL** : Format correct (`mqtt://`, `mqtts://`, `ws://`, `wss://`)
2. **Tester le port** : `telnet broker.example.com 8883`
3. **Vérifier les credentials** : Tester avec un client MQTT externe (MQTT Explorer)
4. **Logs du broker** : Consulter les logs côté serveur

### Outils de diagnostic

- **MQTT Explorer** : Client graphique multi-plateforme
- **mosquitto_sub/pub** : Outils en ligne de commande
- **Wireshark** : Analyse des paquets réseau

---

## 🔐 Variables d'environnement

### Configuration via .env

```bash
# .env.local (développement)
VITE_MQTT_BROKER_URL=ws://localhost:9001
VITE_MQTT_USERNAME=
VITE_MQTT_PASSWORD=

# .env.production (production)
VITE_MQTT_BROKER_URL=wss://xxxxxx.s1.eu.hivemq.cloud:8884/mqtt
VITE_MQTT_USERNAME=prod-user
VITE_MQTT_PASSWORD=super-secret-password
VITE_MQTT_CLIENT_ID_PREFIX=neurhomia-prod
```

### Utilisation dans le code

```typescript
const defaultConfig: Partial<MqttConfig> = {
  broker: import.meta.env.VITE_MQTT_BROKER_URL || 'ws://localhost:9001',
  username: import.meta.env.VITE_MQTT_USERNAME,
  password: import.meta.env.VITE_MQTT_PASSWORD,
  clientId: `${import.meta.env.VITE_MQTT_CLIENT_ID_PREFIX || 'neurhomia'}-${Date.now()}`
};
```

---

## 📚 Ressources complémentaires

### Documentation officielle des fournisseurs

| Fournisseur | Documentation |
|-------------|---------------|
| HiveMQ | [docs.hivemq.com](https://docs.hivemq.com/) |
| EMQX | [docs.emqx.com](https://docs.emqx.com/) |
| CloudMQTT | [cloudmqtt.com/docs](https://www.cloudmqtt.com/docs.html) |
| AWS IoT | [docs.aws.amazon.com/iot](https://docs.aws.amazon.com/iot/) |
| Azure IoT | [docs.microsoft.com/azure/iot-hub](https://docs.microsoft.com/azure/iot-hub/) |
| Mosquitto | [mosquitto.org/documentation](https://mosquitto.org/documentation/) |

### Guides NeurHomIA connexes

- [Guide d'Intégration MQTT](guide-integration-mqtt.md) - Architecture et patterns
- [Guide du Stockage MQTT](guide-stockage-mqtt.md) - Persistance des messages
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications

---

_Documentation NeurHomIA - Janvier 2026_
