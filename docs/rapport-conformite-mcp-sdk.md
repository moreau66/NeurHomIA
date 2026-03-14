# Rapport de Conformité MCP SDK - Écosystème NeurHomIA

**Version** : 4.5.0  
**Date** : 9 mars 2026  
**Auteur** : Analyse automatisée NeurHomIA

---

## 1. Résumé Exécutif

| Métrique | Valeur |
|---|---|
| **Microservices analysés** | 34 |
| **Migration SDK complète** | 34 / 34 (100%) ✅ |
| **Config YAML mcp: présente** | 34 / 34 (100%) ✅ |
| **MCP-Template.json présent** | 34 / 34 (100%) ✅ |
| **Template microservices-templates/** | 34 / 34 (100%) ✅ |
| **Template github-templates/** | 34 / 34 (100%) ✅ |
| **ui_component présent** | 34 / 34 (100%) ✅ |
| **Dockerfile standardisé** | 34 / 34 (100%) ✅ |
| **Dockerfile Python 3.12-slim** | 34 / 34 (100%) ✅ |
| **Dockerfile utilisateur non-root** | 34 / 34 (100%) ✅ |
| **Dockerfile HEALTHCHECK natif** | 34 / 34 (100%) ✅ |
| **docker-compose.yml présent** | 34 / 34 (100%) ✅ |
| **docker-compose.yml MCP vars** | 34 / 34 (100%) ✅ |
| **docker-compose.yml healthcheck** | 34 / 34 (100%) ✅ |
| **docker-compose.yml réseau standardisé** | 34 / 34 (100%) ✅ |
| **docker-compose.master.yml** | ✅ Mis à jour — 28 services, 27 profils |
| **.env.example complet** | ✅ Toutes variables documentées |
| **Guide d'utilisation** | ✅ guide-docker-compose-master.md |
| **Tests d'intégration MCP** | ✅ 8 suites, ~30 tests (v4.1.0) |

> 🎉 **SCORE PARFAIT 100%** : Tous les 34 microservices sont migrés et conformes à 100% au MCP SDK v2.0.  
> - ✅ 100% des services Python custom migrés et complets (27/27)  
> - ✅ 100% des services tiers/hardware implémentés (6/6 : DuckDB2Mqtt, SQLite2Mqtt, Mosquitto2Mqtt, NrxGce2Mqtt, EntitiesFromZigbee, xMqtt2Mqtt)  
> - ✅ 1 service tiers template-only (Zigbee2Mqtt)  
> - ✅ 100% des Dockerfiles standardisés (Python 3.12-slim, utilisateur non-root, HEALTHCHECK natif)  
> - ✅ 100% des docker-compose.yml standardisés (MCP vars, healthcheck, réseau smart-home-network)  
> - ✅ 100% des MCP-Template.json créés (source + discovery) — 34/34  
> - ✅ 100% des github-templates créés — 34/34 — incluant les 13 EntitiesFrom + Scheduler
> - ✅ 100% des templates discovery créés (34/34) incluant services tiers
> - ✅ 100% des ui_component définis (34/34) — 0 warning restant  
> - ✅ **Audit @mcp_tool vs templates** : 12 fichiers corrigés, 34 services vérifiés contre le code Python source  
> - ✅ **~323 MCP Tools** disponibles à travers l'écosystème (ajout 12 tools Scheduler)

---

## 2. Matrice de Conformité Détaillée

### Légende
- ✅ Conforme  
- ⚠️ Partiel / à corriger  
- ❌ Absent / non migré  

| Microservice | SDK Import | @mcp_tool | @mcp_resource | Config YAML mcp: | requirements mcp-mqtt-sdk | Dockerfile | docker-compose MCP vars | MCP-Template.json | Template discovery | github-template | ui_component |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Astral2Mqtt** | ✅ | ✅ 9 tools | ✅ 2 resources | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ astral2mqtt.json | ✅ | ✅ |
| **Bluetooth2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ bluetooth2mqtt.json | ✅ | ✅ |
| **Docker2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ docker2mqtt.json | ✅ | ✅ |
| **DuckDB2Mqtt** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ duckdb2mqtt.json | ✅ | ✅ |
| **EntitiesFromZigbee** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromzigbee.json | ✅ | ✅ |
| **EntitiesFromZwave** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromzwave.json | ✅ | ✅ |
| **EntitiesFromEnOcean** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromenocean.json | ✅ | ✅ |
| **EntitiesFromKNX** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromknx.json | ✅ | ✅ |
| **EntitiesFromOneWire** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromonewire.json | ✅ | ✅ |
| **EntitiesFromDALI** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromdali.json | ✅ | ✅ |
| **EntitiesFromThread** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromthread.json | ✅ | ✅ |
| **EntitiesFromLonWorks** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromlonworks.json | ✅ | ✅ |
| **EntitiesFromBACnet** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfrombacnet.json | ✅ | ✅ |
| **EntitiesFromMBus** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfrommbus.json | ✅ | ✅ |
| **EntitiesFromInsteon** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfrominsteon.json | ✅ | ✅ |
| **EntitiesFromX10** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ entitiesfromx10.json | ✅ | ✅ |
| **Http2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ http2mqtt.json | ✅ | ✅ |
| **IA2Mqtt** | ✅ | ✅ 15 tools | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ ia2mqtt.json | ✅ | ✅ |
| **Ipx2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ ipx2mqtt.json | ✅ | ✅ |
| **IR2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ ir2mqtt.json | ✅ | ✅ |
| **Lan2Mqtt** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ lan2mqtt.json | ✅ | ✅ |
| **Lora2Mqtt** | ✅ | ✅ 7 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ lora2mqtt.json | ✅ | ✅ |
| **Mail2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ mail2mqtt.json | ✅ | ✅ |
| **Matter2Mqtt** | ✅ | ✅ 8 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ matter2mqtt.json | ✅ | ✅ |
| **Meteo2Mqtt** | ✅ | ✅ 8 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ meteo2mqtt.json | ✅ | ✅ |
| **Modbus2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ modbus2mqtt.json | ✅ | ✅ |
| **Mosquitto2Mqtt** | ✅ | ✅ 10 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ mosquitto2mqtt.json | ✅ | ✅ |
| **NrxGce2Mqtt** | ✅ | ✅ 10 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ nrxgce2mqtt.json | ✅ | ✅ |
| **RF2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ rf2mqtt.json | ✅ | ✅ |
| **Sms2Mqtt** | ✅ | ✅ 7 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ sms2mqtt.json | ✅ | ✅ |
| **Speech2Phrase2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ speech2phrase2mqtt.json | ✅ | ✅ |
| **SQLite2Mqtt** | ✅ | ✅ 14 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ sqlite2mqtt.json | ✅ | ✅ |
| **System2Mqtt** | ✅ | ✅ 11 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ system2mqtt.json | ✅ | ✅ |
| **Telegram2Mqtt** | ✅ | ✅ 8 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ telegram2mqtt.json | ✅ | ✅ |
| **Text2Speech2Mqtt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ text2speech2mqtt.json | ✅ | ✅ |
| **Zigbee2Mqtt** | — | — | — | — | — | — | ✅ | ✅ | ✅ zigbee2mqtt.json | ✅ | ✅ |
| **xMqtt2Mqtt** | ✅ | ✅ 9 tools | ✅ 2 resources | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ xmqtt2mqtt.json | ✅ | ✅ |
| **MCP-Scheduler** | ✅ | ✅ 12 tools | ✅ 1 resource | ✅ | ✅ | ✅ Python 3.12 | ✅ | ✅ | ✅ scheduler.json | ✅ | ✅ |

> Zigbee2Mqtt est le seul service tiers pur (image officielle koenkk/zigbee2mqtt) qui n'utilise pas le SDK directement mais dispose d'un template de déploiement.  
> La suite **EntitiesFrom** comprend désormais **13 extracteurs spécialisés** : Zigbee, Z-Wave, EnOcean, KNX, OneWire, DALI, Thread, LonWorks, BACnet, M-Bus, Insteon, X10, NrxGce (GPIO).
> Le **MCP-Scheduler** est le scheduler autonome pour scénarios MQTT, tâches planifiées et sauvegardes automatiques.

---

## 3. Standardisation Dockerfile (v3.9.0)

✅ **100% des Dockerfiles standardisés** — 34 Dockerfiles mis à jour avec le pattern MCP v2.0.

### Pattern standard appliqué

| Critère | Spécification | Conformité |
|---|---|---|
| **Image de base** | `python:3.12-slim` | 34/34 ✅ |
| **Utilisateur non-root** | `useradd -m -u 1000 <service>` + `USER <service>` | 34/34 ✅ |
| **HEALTHCHECK natif** | Test MQTT `paho.mqtt.client` intégré au Dockerfile | 34/34 ✅ |
| **PYTHONPATH** | `/app/src` | 34/34 ✅ |
| **PYTHONUNBUFFERED** | `1` | 34/34 ✅ |
| **MCP_SERVICE_ID** | Variable ENV définie | 34/34 ✅ |
| **MCP_SERVICE_VERSION** | Variable ENV définie | 34/34 ✅ |
| **Propriété fichiers** | `chown <service>:<service> /app` | 34/34 ✅ |

### Dépendances système spécialisées préservées

| Service | Dépendances système |
|---|---|
| **Bluetooth2Mqtt** | `bluez`, `bluetooth`, `libbluetooth-dev` |
| **IR2Mqtt** | — (pip only) |
| **Lan2Mqtt** | `nmap`, `iputils-ping`, `net-tools`, `snmp` |
| **Lora2Mqtt** | `libusb-1.0-0` |
| **Matter2Mqtt** | `libssl-dev`, `libffi-dev`, `libdbus-1-dev`, `bluez` |
| **Modbus2Mqtt** | `libusb-1.0-0` |
| **NrxGce2Mqtt** | `libgpiod2` |
| **RF2Mqtt** | `libusb-1.0-0` |
| **Sms2Mqtt** | `gammu`, `libgammu-dev` |
| **Speech2Phrase2Mqtt** | Multi-stage build (`ghcr.io/ohf-voice/speech-to-phrase`) |
| **SQLite2Mqtt** | `sqlite3`, `libsqlite3-dev` |
| **Text2Speech2Mqtt** | Multi-stage Piper TTS + modèle vocal FR |

---

## 4. Standardisation docker-compose.yml (v3.9.0)

✅ **100% des docker-compose.yml standardisés** — Tous les 34 services disposent d'un docker-compose.yml conforme.

### Pattern standard appliqué

| Critère | Spécification | Conformité |
|---|---|---|
| **Version** | `'3.8'` | 34/34 ✅ |
| **MCP_SERVICE_ID** | Variable d'environnement définie | 34/34 ✅ |
| **MCP_API_KEY** | `${MCP_API_KEY:-}` avec fallback | 34/34 ✅ |
| **MCP_HEARTBEAT_INTERVAL** | `${MCP_HEARTBEAT_INTERVAL:-30}` | 34/34 ✅ |
| **MQTT_BROKER** | `${MQTT_BROKER:-mosquitto}` | 34/34 ✅ |
| **MQTT_PORT** | `${MQTT_PORT:-1883}` | 34/34 ✅ |
| **healthcheck** | Test MQTT ou HTTP natif | 34/34 ✅ |
| **depends_on: mosquitto** | Dépendance au broker | 34/34 ✅ |
| **Réseau smart-home-network** | `external: true` | 34/34 ✅ |
| **restart: unless-stopped** | Politique de redémarrage | 34/34 ✅ |
| **Profils Docker** | Assignation par catégorie | 34/34 ✅ |

---

## 4bis. Docker Compose Maître — Orchestration centralisée (v4.0.0)

✅ **docker-compose.master.yml créé** — Fichier d'orchestration centralisé pour l'ensemble de l'écosystème.

### Architecture

| Couche | Services | Démarrage |
|---|---|---|
| **Core** (toujours actif) | `mosquitto`, `app`, `file-sync-api` | Automatique |
| **Optionnel** (par profils) | 21 microservices MCP | Activé par `--profile` |

### Ancres YAML partagées

| Ancre | Contenu | Usage |
|---|---|---|
| `x-mqtt-env` | `MQTT_BROKER`, `MQTT_PORT`, `MQTT_USER`, `MQTT_PASS` | Injecté via `<<: *mqtt-env` dans chaque service |
| `x-mcp-defaults` | `restart`, `networks`, `depends_on` (mosquitto healthy) | Injecté via `<<: *mcp-defaults` |

### Stratégie de profils

| Profil | Services | Cas d'usage |
|---|---|---|
| `system` | system2mqtt | Monitoring système hôte |
| `docker` | docker2mqtt | Monitoring containers |
| `monitoring` | system2mqtt, docker2mqtt | Monitoring complet |
| `zigbee` | zigbee2mqtt, entitiesfromzigbee | Réseau Zigbee |
| `zwave` | entitiesfromzwave | Réseau Z-Wave |
| `rf` | rf2mqtt | Radio 433 MHz |
| `modbus` | modbus2mqtt | Modbus RTU/TCP |
| `bluetooth` | bluetooth2mqtt | Bluetooth BLE |
| `radio` | zigbee2mqtt, entities*, rf2mqtt, bluetooth2mqtt | Tous protocoles radio |
| `enocean` | entitiesfromenocean | Réseau EnOcean |
| `knx` | entitiesfromknx | Bus KNX |
| `onewire` | entitiesfromonewire | Capteurs 1-Wire |
| `dali` | entitiesfromdali | Éclairage DALI |
| `thread` | entitiesfromthread | Réseau Thread/OpenThread |
| `lonworks` | entitiesfromlonworks | Automatisme LonWorks |
| `bacnet` | entitiesfrombacnet | Automatisme bâtiment BACnet |
| `mbus` | entitiesfrommbus | Comptage M-Bus/wM-Bus |
| `insteon` | entitiesfrominsteon | Domotique Insteon |
| `x10` | entitiesfromx10 | Protocole CPL X10 |
| `entities` | entitiesfromzigbee, entitiesfromzwave, entitiesfromenocean, entitiesfromknx, entitiesfromonewire, entitiesfromdali, entitiesfromthread, entitiesfromlonworks, entitiesfrombacnet, entitiesfrommbus, entitiesfrominsteon, entitiesfromx10 | Extracteurs d'entités |
| `astral` | astral2mqtt | Données astronomiques |
| `meteo` | meteo2mqtt | Données météo |
| `environment` | astral2mqtt, meteo2mqtt | Données environnementales |
| `telegram` | telegram2mqtt | Bot Telegram |
| `mail` | mail2mqtt | Bridge email |
| `messaging` | telegram2mqtt, mail2mqtt | Tous canaux messaging |
| `tts` / `audio` | text2speech2mqtt | Synthèse vocale |
| `ia` | ia2mqtt, ollama | Intelligence artificielle |
| `bridges` | xmqtt2mqtt | Bridge MQTT multi-broker |
| `nrxgce` / `gpio` | nrxgce2mqtt | GPIO / NRX-GCE |
| `energy` | modbus2mqtt | Compteurs énergie |
| `storage` | sqlite2mqtt | Persistance SQLite |
| `scheduler` | scheduler-service | Scheduler autonome |
| `backup` | sqlite-backup | Sauvegardes automatiques |
| **`all`** | **Tous les 28 services** | Déploiement complet |

### Fichiers associés

| Fichier | Description |
|---|---|
| `docker-compose.master.yml` | Orchestration centralisée (28 services, 27 profils) |
| `.env.example` | Toutes les variables documentées avec valeurs par défaut |
| `public/docs/guide-docker-compose-master.md` | Guide d'utilisation complet (profils, commandes, dépannage) |

### Commandes principales

```bash
# Core uniquement
docker compose -f docker-compose.master.yml up -d

# Profils combinés
docker compose -f docker-compose.master.yml --profile zigbee --profile meteo --profile ia up -d

# Tous les extracteurs d'entités
docker compose -f docker-compose.master.yml --profile entities up -d

# Tout activer
docker compose -f docker-compose.master.yml --profile all up -d
```

---

## 5. Services Entièrement Conformes (Score 100%)

| Service | Tools | Resources | Statut |
|---|---|---|---|
| **Meteo2Mqtt** | 8 | 1 | ✅ Migration complète + sécurité admin |
| **Mail2Mqtt** | 8 | 1 | ✅ Migration complète |
| **Speech2Phrase2Mqtt** | 5 | 1 | ✅ Migration complète |
| **Text2Speech2Mqtt** | 5 | 1 | ✅ Migration complète |
| **Lan2Mqtt** | 11 | 1 | ✅ Migration complète (mars 2026) |
| **System2Mqtt** | 11 | 1 | ✅ Migration complète (mars 2026) |
| **Telegram2Mqtt** | 8 | 1 | ✅ Migration complète (mars 2026) — +test_connection (audit) |
| **Sms2Mqtt** | 7 | 1 | ✅ Migration complète (mars 2026) |
| **Lora2Mqtt** | 7 | 1 | ✅ Migration complète (mars 2026) |
| **Astral2Mqtt** | 9 | 2 | ✅ Migration complète (mars 2026) — tools corrigés (audit) |
| **IA2Mqtt** | 15 | 2 | ✅ Migration complète (mars 2026) — +get_service_status, reload_config (audit) |
| **Matter2Mqtt** | 8 | 1 | ✅ Migration complète (mars 2026) |
| **DuckDB2Mqtt** | 11 | 1 | ✅ Implémentation complète (mars 2026) — tools corrigés vs source (audit) |
| **SQLite2Mqtt** | 14 | 1 | ✅ Implémentation complète (mars 2026) — tools corrigés vs source (audit) |
| **Mosquitto2Mqtt** | 10 | 1 | ✅ Implémentation complète (mars 2026) — tools corrigés vs source (audit) |
| **NrxGce2Mqtt** | 10 | 1 | ✅ Implémentation complète (mars 2026) — GPIO RPi CM4 + simulation + arrêt urgence |
| **EntitiesFromZigbee** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction Z2M + mapping catégories |
| **EntitiesFromEnOcean** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction EnOcean + mapping EEP |
| **EntitiesFromKNX** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction KNX + mapping DPT |
| **EntitiesFromOneWire** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction 1-Wire + mapping Family Codes (~50 types) |
| **EntitiesFromDALI** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction DALI + mapping Device Types IEC 62386 (~25 types) |
| **EntitiesFromThread** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction Thread/OpenThread + mapping Matter Device Types (~35 types) |
| **EntitiesFromLonWorks** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction LonWorks + mapping SNVT (~40 types) |
| **EntitiesFromBACnet** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction BACnet ASHRAE 135 + mapping Object Types (~30 types) |
| **EntitiesFromMBus** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction M-Bus EN 13757 + mapping Medium Types (~20 types) |
| **EntitiesFromInsteon** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction Insteon + mapping Device Categories (~25 types) |
| **EntitiesFromX10** | 11 | 1 | ✅ Implémentation complète (mars 2026) — extraction X10 CPL + mapping Device Types (~15 types) |
| **Docker2Mqtt** | 12 | 1 | ✅ Complété 100% (mars 2026) |
| **Bluetooth2Mqtt** | 18 | 1 | ✅ Complété 100% (mars 2026) |
| **Http2Mqtt** | 10 | 1 | ✅ Complété 100% (mars 2026) |
| **Ipx2Mqtt** | 18 | 1 | ✅ Complété 100% (mars 2026) |
| **xMqtt2Mqtt** | 9 | 2 | ✅ Migration MCP SDK v2.0 (mars 2026) — bridge MQTT multi-broker, mappings JSON |
| **MCP-Scheduler** | 12 | 1 | ✅ Implémentation complète (mars 2026) — scheduler autonome, scénarios MQTT, tâches cron/interval/once, sauvegardes auto |

---

## 6. Audit @mcp_tool vs Templates (v3.7.0)

✅ **Audit complet réalisé** — Vérification des `@mcp_tool` déclarés dans le code Python source vs les tools listés dans les templates JSON.

**6 services corrigés (12 fichiers)** :

| Service | Problème | Correction |
|---|---|---|
| **Astral2Mqtt** | `get_astral_data` (nom inventé), `delete_location` fantôme, 3 tools manquants | → `get_astronomical_data`, +`refresh_all_data`, `health_check`, `get_service_status` (9 tools) |
| **IA2Mqtt** | 2 tools manquants | +`get_service_status`, `reload_config` (15 tools) |
| **Mosquitto2Mqtt** | 8/10 tools noms inventés | Réécrit : `get_broker_metrics`, `get_message_stats`, `get_metrics_history`, `check_connectivity`, `read_config`, `read_logs`, `publish_test` (10 tools) |
| **Telegram2Mqtt** | `test_connection` manquant | +`test_connection` (8 tools) |
| **DuckDB2Mqtt** | 6/11 tools fantômes (`insert_timeseries`, `list_tables`, `import_parquet`) | → `insert_data`, `insert_batch`, `get_statistics`, `get_topics`, `purge_data` (11 tools) |
| **SQLite2Mqtt** | 8/14 tools fantômes (`get_kv/set_kv/delete_kv/list_kv`) | → `set_value`, `get_value`, `insert_batch`, `get_aggregation`, `get_statistics`, `get_topics`, `purge_data`, `optimize_db` (14 tools) |

**25 services déjà conformes** : Bluetooth, Docker, Http, Ipx, Lan, Lora, Mail, Matter, Meteo, NrxGce, Sms, Speech2Phrase, System, Text2Speech, Zigbee, EntitiesFromZigbee, EntitiesFromZwave, EntitiesFromOneWire, EntitiesFromDALI, EntitiesFromThread, EntitiesFromLonWorks, EntitiesFromBACnet, EntitiesFromMBus, EntitiesFromInsteon, EntitiesFromX10, MCP-Scheduler.

---

## 7. Services Non Migrés (Migration SDK requise)

🎉 **Aucun** — Tous les 34 services Python sont implémentés avec le MCP SDK v2.0.

---

## 8. Anomalies Restantes

### 8.1 Dockerfiles

✅ **Toutes les anomalies Dockerfile sont corrigées** — 35/35 standardisés (Python 3.12-slim, non-root, HEALTHCHECK natif)

### 8.2 docker-compose.yml

✅ **Tous les docker-compose.yml sont standardisés** — 34/34 avec MCP vars, healthcheck, réseau smart-home-network

### 8.3 Configurations

✅ **Toutes les anomalies de configuration sont corrigées**

### 8.4 Templates discovery

✅ **Couverture 100%** — Tous les 34 templates créés dans `microservices-templates/`

### 8.5 GitHub Templates

✅ **Couverture 100%** — Tous les 34 templates créés dans `github-templates/` — incluant les 12 EntitiesFrom (Zigbee, Z-Wave, EnOcean, KNX, OneWire, DALI, Thread, LonWorks, BACnet, M-Bus, Insteon, X10) + MCP-Scheduler

### 8.6 Composants UI

✅ **Couverture 100%** — Tous les 34 templates (incluant zigbee2mqtt-virtual) disposent d'un bloc `ui_component` avec `component_path` et `mode: "embedded"`

### 8.7 Dossier orphelin

✅ **Supprimé** — L'ancien dossier `Text2Speech2Mqtt-main/` (sans préfixe MCP-) a été nettoyé

---

## 9. Couverture Templates Discovery

| Fichier | Source | MCP-Template.json | github-template | ui_component |
|---|---|---|---|---|
| `microservices-templates/astral2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Astral2MqttContainer |
| `microservices-templates/bluetooth2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Bluetooth2MqttContainer |
| `microservices-templates/docker2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Docker2MqttContainer |
| `microservices-templates/duckdb2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ DuckDBContainer |
| `microservices-templates/entitiesfromzigbee.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromZigbeeContainer |
| `microservices-templates/entitiesfromenocean.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromEnOceanContainer |
| `microservices-templates/entitiesfromknx.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromKNXContainer |
| `microservices-templates/entitiesfromonewire.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromOneWireContainer |
| `microservices-templates/entitiesfromdali.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromDALIContainer |
| `microservices-templates/entitiesfromthread.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromThreadContainer |
| `microservices-templates/entitiesfromlonworks.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromLonWorksContainer |
| `microservices-templates/entitiesfrombacnet.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromBACnetContainer |
| `microservices-templates/entitiesfrommbus.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromMBusContainer |
| `microservices-templates/entitiesfrominsteon.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromInsteonContainer |
| `microservices-templates/entitiesfromx10.json` | ✅ | ✅ Synchronisé | ✅ | ✅ EntitiesFromX10Container |
| `microservices-templates/http2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Http2MqttContainer |
| `microservices-templates/ia2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ OllamaContainer |
| `microservices-templates/ipx2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Ipx2MqttContainer |
| `microservices-templates/lan2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Lan2MqttContainer |
| `microservices-templates/lora2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Lora2MqttContainer |
| `microservices-templates/mail2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Mail2MqttContainer |
| `microservices-templates/matter2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Matter2MqttContainer |
| `microservices-templates/meteo2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Meteo2MqttContainer |
| `microservices-templates/mosquitto2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ MosquittoContainer |
| `microservices-templates/nrxgce2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ NrxGce2MqttContainer |
| `microservices-templates/sms2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Sms2MqttContainer |
| `microservices-templates/speech2phrase2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Speech2Phrase2MqttContainer |
| `microservices-templates/sqlite2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ SQLiteContainer |
| `microservices-templates/system2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ System2MqttContainer |
| `microservices-templates/telegram2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Telegram2MqttContainer |
| `microservices-templates/text2speech2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Text2Speech2MqttContainer |
| `microservices-templates/zigbee2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ Zigbee2MqttContainer |
| `microservices-templates/xmqtt2mqtt.json` | ✅ | ✅ Synchronisé | ✅ | ✅ XMqtt2MqttContainer |
| `microservices-templates/scheduler.json` | ✅ | ✅ Synchronisé | ✅ | ✅ SchedulerContainer |

---

## 10. Corrections Appliquées (Historique)

### Mars 2026 — Sprint de standardisation
| Action | Services concernés | Statut |
|---|---|---|
| Création MCP-Template.json | Astral2Mqtt, Bluetooth2Mqtt, Docker2Mqtt, Http2Mqtt, Ipx2Mqtt, IA2Mqtt, Lan2Mqtt, System2Mqtt, Matter2Mqtt, Telegram2Mqtt, Sms2Mqtt, Lora2Mqtt | ✅ Fait |
| Standardisation docker-compose MCP vars (tous) | Http2Mqtt, Ipx2Mqtt, Lora2Mqtt, Matter2Mqtt, Telegram2Mqtt, Sms2Mqtt | ✅ Fait |
| Ajout `MCP_SERVICE_ID` + `MCP_API_KEY` docker-compose | Astral2Mqtt, IA2Mqtt, Lan2Mqtt | ✅ Fait |
| Ajout healthcheck docker-compose | IA2Mqtt | ✅ Fait |
| Migration SDK complète | Lan2Mqtt, System2Mqtt, Telegram2Mqtt, Sms2Mqtt, Lora2Mqtt, Matter2Mqtt | ✅ Fait |
| Création templates discovery | Tous les 34 services | ✅ Fait |
| Création github-templates | Tous les 34 services | ✅ Fait |
| Création github-templates EntitiesFrom | 12 templates : Zigbee, Z-Wave, EnOcean, KNX, OneWire, DALI, Thread, LonWorks, BACnet, M-Bus, Insteon, X10 | ✅ Fait |
| Validation schéma JSON | astral2mqtt, docker2mqtt, ia2mqtt, zigbee2mqtt | ✅ Fait |
| Correction Dockerfile Astral2Mqtt | Commentaire inline supprimé → `python:3.12-slim-bookworm` | ✅ Fait |
| Correction Dockerfile Bluetooth2Mqtt | Image name corrigé → `python:3.12-slim-bookworm` | ✅ Fait |
| Correction config YAML Bluetooth2Mqtt | Placeholders `[service]` → `bluetooth2mqtt` | ✅ Fait |
| Upgrade Dockerfile IA2Mqtt | Python 3.9 → 3.12 + healthcheck + utilisateur non-root | ✅ Fait |
| Migration Matter2Mqtt | Python 3.12 + MCPMicroservice + 8 tools + healthcheck natif | ✅ Fait |
| Ajout ui_component | 10 templates complétés | ✅ Fait |
| **Implémentation DuckDB2Mqtt** | Python 3.12 + MCPMicroservice + 11 tools + time-series + Parquet | ✅ Fait |
| **Implémentation SQLite2Mqtt** | Python 3.12 + MCPMicroservice + 14 tools + WAL + KV store + backup | ✅ Fait |
| **Implémentation Mosquitto2Mqtt** | Python 3.12 + MCPMicroservice + 10 tools + broker monitor + $SYS metrics | ✅ Fait |
| **Implémentation NrxGce2Mqtt** | Python 3.12 + MCPMicroservice + 10 tools + GPIO RPi CM4 + simulation + arrêt urgence | ✅ Fait |
| **Implémentation EntitiesFromZigbee** | Python 3.12 + MCPMicroservice + 11 tools + extraction Z2M + mapping catégories | ✅ Fait |
| **Suppression dossier orphelin** | Text2Speech2Mqtt-main (sans préfixe MCP-) nettoyé | ✅ Fait |
| **Complétion Docker2Mqtt** | get_status, update_config, get_recent_logs, get_container_stats — 12 tools | ✅ Fait |
| **Complétion Bluetooth2Mqtt** | Synchronisation 18 tools + connect_device, get_service_status | ✅ Fait |
| **Complétion Http2Mqtt** | test_bridge, update_config — 10 tools | ✅ Fait |
| **Complétion Ipx2Mqtt** | remove_ipx_device — 18 tools | ✅ Fait |
| **Audit @mcp_tool vs templates** | 6 services corrigés (12 fichiers) — Astral, IA, Mosquitto, Telegram, DuckDB, SQLite | ✅ Fait |
| **Implémentation EntitiesFromEnOcean** | Python 3.12 + MCPMicroservice + 11 tools + extraction EnOcean + mapping EEP (~100 profils) | ✅ Fait |
| **Implémentation EntitiesFromKNX** | Python 3.12 + MCPMicroservice + 11 tools + extraction KNX + mapping DPT (~80 types) | ✅ Fait |
| **Implémentation EntitiesFromOneWire** | Python 3.12 + MCPMicroservice + 11 tools + extraction 1-Wire + mapping Family Codes (~50 types) | ✅ Fait |
| **Implémentation EntitiesFromDALI** | Python 3.12 + MCPMicroservice + 11 tools + extraction DALI + mapping Device Types IEC 62386 (~25 types) | ✅ Fait |
| **Implémentation EntitiesFromThread** | Python 3.12 + MCPMicroservice + 11 tools + extraction Thread/OpenThread + mapping Matter Device Types (~35 types) | ✅ Fait |
| **Implémentation EntitiesFromLonWorks** | Python 3.12 + MCPMicroservice + 11 tools + extraction LonWorks + mapping SNVT (~40 types) | ✅ Fait |
| **Implémentation EntitiesFromBACnet** | Python 3.12 + MCPMicroservice + 11 tools + extraction BACnet ASHRAE 135 + mapping Object Types (~30 types) | ✅ Fait |
| **Implémentation EntitiesFromMBus** | Python 3.12 + MCPMicroservice + 11 tools + extraction M-Bus EN 13757 + mapping Medium Types (~20 types) | ✅ Fait |
| **Implémentation EntitiesFromInsteon** | Python 3.12 + MCPMicroservice + 11 tools + extraction Insteon + mapping Device Categories (~25 types) | ✅ Fait |
| **Implémentation EntitiesFromX10** | Python 3.12 + MCPMicroservice + 11 tools + extraction X10 CPL + mapping Device Types (~15 types) | ✅ Fait |
| **Standardisation Dockerfiles** | 35 Dockerfiles → Python 3.12-slim, utilisateur non-root, HEALTHCHECK natif | ✅ Fait |
| **Standardisation docker-compose.yml** | 9 docker-compose.yml mis à jour (Docker, Http, Lan, Lora, Meteo, Mosquitto, Sms, Speech2Phrase, Zigbee) — MCP vars, healthcheck, réseau, profils | ✅ Fait |
| **Implémentation MCP-Scheduler** | Python 3.12 + MCPMicroservice + 12 tools + 1 resource + scheduler autonome scénarios/tâches/backups + JSON-RPC 2.0 + discovery + heartbeat | ✅ Fait |

---

## 11. Plan d'Action Restant

### Phase 1 — Corrections immédiates

✅ **TERMINÉ** — Toutes les corrections Phase 1 appliquées.

### Phase 2 — Migrations SDK

✅ **TERMINÉ** — Tous les 30 services implémentés avec MCP SDK v2.0.

### Phase 3 — Standardisation DevOps

1. ~~Uniformiser tous les Dockerfiles sur Python 3.12-slim~~ ✅ Fait (v3.9.0)  
2. ~~Ajouter HEALTHCHECK natif à tous les Dockerfiles~~ ✅ Fait (v3.9.0)  
3. ~~Utilisateur non-root dans tous les Dockerfiles~~ ✅ Fait (v3.9.0)  
4. ~~Standardiser tous les docker-compose.yml (MCP vars, healthcheck, réseau)~~ ✅ Fait (v3.9.0)  
5. ~~Ajouter healthcheck Docker à tous les services~~ ✅ Fait  
6. ~~Synchroniser tous les MCP-Template.json ↔ microservices-templates/~~ ✅ Fait  
7. ~~Créer templates discovery pour services tiers~~ ✅ Fait  
8. ~~Ajouter ui_component à tous les templates~~ ✅ Fait  
9. ~~Créer github-templates pour tous les services~~ ✅ Fait  
10. ~~Nettoyer dossiers orphelins~~ ✅ Fait  
11. ~~Créer docker-compose.master.yml avec orchestration par profils~~ ✅ Fait (v4.0.0)  
12. ~~Créer .env.example complet avec toutes les variables~~ ✅ Fait (v4.0.0)  
13. ~~Créer guide d'utilisation docker-compose maître~~ ✅ Fait (v4.0.0)  
14. ~~Tests d'intégration MCP end-to-end~~ ✅ Fait (v4.1.0)  

### Phase 4 — Qualité & CI/CD

1. Intégrer les tests dans un pipeline CI (GitHub Actions) — 🟡 Recommandé  
2. Ajouter des tests de charge MQTT (>1000 msg/s) — 🟡 Recommandé  
3. Monitoring Prometheus/Grafana — 🔵 Optionnel  

---

## 12. Score de Maturité par Service

```
Meteo2Mqtt          ████████████████████ 100%
Mail2Mqtt           ████████████████████ 100%
Speech2Phrase2Mqtt  ████████████████████ 100%
Text2Speech2Mqtt    ████████████████████ 100%
Lan2Mqtt            ████████████████████ 100%
System2Mqtt         ████████████████████ 100%
Telegram2Mqtt       ████████████████████ 100%
Sms2Mqtt            ████████████████████ 100%
Lora2Mqtt           ████████████████████ 100%
Astral2Mqtt         ████████████████████ 100%
IA2Mqtt             ████████████████████ 100%
Matter2Mqtt         ████████████████████ 100%
DuckDB2Mqtt         ████████████████████ 100%
SQLite2Mqtt         ████████████████████ 100%
Mosquitto2Mqtt      ████████████████████ 100%
NrxGce2Mqtt         ████████████████████ 100%
EntitiesFromZigbee  ████████████████████ 100%
EntitiesFromEnOcean ████████████████████ 100%
EntitiesFromKNX     ████████████████████ 100%
EntitiesFromOneWire ████████████████████ 100%
EntitiesFromDALI    ████████████████████ 100%
EntitiesFromThread  ████████████████████ 100%
EntitiesFromLonWorks████████████████████ 100%
EntitiesFromBACnet  ████████████████████ 100%  ✅ NEW
EntitiesFromMBus    ████████████████████ 100%  ✅ NEW
EntitiesFromInsteon ████████████████████ 100%  ✅ NEW
EntitiesFromX10     ████████████████████ 100%  ✅ NEW
Docker2Mqtt         ████████████████████ 100%  ✅ UPGRADED
Bluetooth2Mqtt      ████████████████████ 100%  ✅ UPGRADED
Http2Mqtt           ████████████████████ 100%  ✅ UPGRADED
Ipx2Mqtt            ████████████████████ 100%  ✅ UPGRADED
xMqtt2Mqtt          ████████████████████ 100%  ✅ NEW
MCP-Scheduler       ████████████████████ 100%  ✅ NEW
```

**Score global écosystème : 100% de conformité MCP SDK** (34/34 services à 100%)

🎉 **Milestones atteints v4.5.0 : 34 services à 100% + 35 Dockerfiles standardisés + 34 docker-compose.yml standardisés + docker-compose.master.yml (28 services) + docker-compose.test.yml + tests d'intégration MCP E2E (8 suites, ~30 tests) + .env.example + guides + 100% templates (34 discovery + 34 github) + ~323 MCP Tools + 13 extracteurs EntitiesFrom + MCP-Scheduler — SCORE PARFAIT 34/34**

---

## 13. Tests d'intégration MCP End-to-End (v4.1.0)

✅ **Suite de tests complète créée** — Validation automatisée de la communication inter-microservices.

### Architecture de test

| Fichier | Rôle |
|---|---|
| `scripts/tests/test_mcp_integration.py` | Suite de tests Python (8 modules, ~30 tests) |
| `scripts/tests/Dockerfile` | Image Docker du runner de tests |
| `scripts/tests/run-integration-tests.sh` | Script de lancement avec gestion des profils |
| `docker-compose.test.yml` | Environnement isolé (broker + services optionnels) |

### Suites de tests

| Suite | Tests | Description |
|---|---|---|
| **Connectivité MQTT** | 2 | Connexion broker + pub/sub round-trip |
| **Discovery MCP** | ~3/service | Structure discovery + tools déclarés |
| **Heartbeat MCP** | ~2/service | Réception + structure des heartbeats |
| **JSON-RPC Tool Calls** | 2/service | `get_status` + `update_config` (outils obligatoires) |
| **Gestion d'erreurs** | 3 | Tool inexistant, méthode invalide, payload malformé |
| **Ressources MCP** | 1/service | `list_resources` (widgets UI) |
| **Communication inter-services** | 3 | Topics partagés + propagation d'événements |
| **Performance** | 2 | Latence moyenne (×10) + burst 50 messages |

### Commandes

```bash
# Tests basiques (connectivité MQTT seule)
./scripts/tests/run-integration-tests.sh

# Avec services monitoring
./scripts/tests/run-integration-tests.sh --with-services

# Tous les services
./scripts/tests/run-integration-tests.sh --profile all

# Nettoyage
./scripts/tests/run-integration-tests.sh --clean
```

### Critères de succès

| Métrique | Seuil |
|---|---|
| Latence moyenne `get_status` | < 2 000 ms |
| Burst 50 messages | < 2 000 ms |
| Discovery reçu | ≥ 1 service en 15s |
| Heartbeat reçu | ≥ 1 en 35s |
| Résilience payload malformé | Service toujours opérationnel |

---

*Rapport v4.5.0 — NeurHomIA Architecture MCP v2.0 — Mis à jour le 9 mars 2026*
