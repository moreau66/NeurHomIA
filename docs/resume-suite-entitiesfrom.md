# Suite EntitiesFrom — Résumé des 13 Extracteurs d'Entités IoT

> **Version** : 1.1.0  
> **Date** : 9 mars 2026  
> **Écosystème** : NeurHomIA MCP SDK v2.0

---

## Vue d'ensemble

La suite **EntitiesFrom** est un ensemble de 13 microservices spécialisés dans l'extraction automatique d'entités IoT depuis différents protocoles et interfaces domotiques. Chaque extracteur :

- Écoute les topics MQTT du protocole associé
- Extrait et normalise les devices en entités NeurHomIA
- Applique un **mapping automatique** vers les 61 catégories du système
- Expose des **MCP tools** + **resources** via JSON-RPC over MQTT

| Métrique | Valeur |
|---|---|
| **Extracteurs** | 13 |
| **MCP Tools total** | 142 (12 × 11 + 10) |
| **Catégories IoT couvertes** | 61 |
| **Protocoles radio** | 5 (Zigbee, Z-Wave, EnOcean, Thread, LoRa*) |
| **Protocoles filaires** | 5 (KNX, DALI, LonWorks, M-Bus, 1-Wire) |
| **Protocoles CPL** | 2 (X10, Insteon) |
| **Protocoles IP** | 1 (BACnet/IP) |
| **Interfaces GPIO** | 1 (NrxGce — Raspberry Pi CM4) |

---

## Architecture commune

### Tools MCP (11 par service)

| Tool | Description |
|---|---|
| `get_status` | État du service (entités, uptime, MQTT) |
| `update_config` | Mise à jour de la configuration à chaud |
| `list_entities` | Liste paginée des entités extraites |
| `get_entity` | Détail d'une entité par ID |
| `extract_entities` | Extraction manuelle depuis le protocole |
| `sync_devices` | Synchronisation avec les devices source |
| `delete_entity` | Suppression d'une entité |
| `get_entity_categories` | Catégories disponibles et utilisées |
| `map_entity_category` | Re-mapping manuel d'une catégorie |
| `export_entities` | Export JSON des entités |
| `get_recent_logs` | Logs récents du service |

### Stack technique

- **Python 3.12-slim** + utilisateur non-root
- **paho-mqtt** + **pyyaml**
- **HEALTHCHECK** natif (test connexion MQTT)
- **Docker Compose** avec profils fonctionnels

---

## Les 13 Extracteurs

### 1. 🔵 EntitiesFromZigbee

| Propriété | Valeur |
|---|---|
| **Protocole** | Zigbee 3.0 (IEEE 802.15.4) |
| **Source** | Zigbee2MQTT (`zigbee2mqtt/bridge/devices`) |
| **Mapping** | Device categories Z2M → NeurHomIA |
| **Types mappés** | ~30 catégories |

**Exemples de mapping :**

| Type Z2M | Catégorie NeurHomIA |
|---|---|
| `light` | `light` |
| `switch` | `switch` |
| `sensor` / `temperature` | `temperature_sensor` |
| `lock` | `lock` |
| `cover` | `cover` |
| `climate` | `thermostat` |
| `fan` | `fan` |

---

### 2. 🟣 EntitiesFromZwave

| Propriété | Valeur |
|---|---|
| **Protocole** | Z-Wave Plus (série 700/800) |
| **Source** | Z-Wave JS (`zwave/devices/list`) |
| **Mapping** | Device Class → NeurHomIA |
| **Types mappés** | ~35 catégories |

**Exemples de mapping :**

| Device Class Z-Wave | Catégorie NeurHomIA |
|---|---|
| `SWITCH_BINARY` | `switch` |
| `SWITCH_MULTILEVEL` | `light` |
| `SENSOR_MULTILEVEL` | `sensor` |
| `THERMOSTAT` | `thermostat` |
| `DOOR_LOCK` | `lock` |
| `METER` | `smart_meter` |
| `ALARM` | `alarm_panel` |

---

### 3. 🟢 EntitiesFromEnOcean

| Propriété | Valeur |
|---|---|
| **Protocole** | EnOcean (ISO/IEC 14543-3-1x) |
| **Standard** | EEP (EnOcean Equipment Profiles) |
| **Source** | EnOcean Gateway (`enocean/devices/list`) |
| **Mapping** | Profils EEP → NeurHomIA |
| **Types mappés** | ~100 profils EEP |

**Exemples de mapping :**

| Profil EEP | Catégorie NeurHomIA |
|---|---|
| `F6-02-xx` (RPS) | `switch` (Rocker Switch) |
| `A5-02-xx` (4BS) | `temperature_sensor` |
| `A5-04-xx` | `humidity_sensor` |
| `A5-06-xx` | `light_sensor` |
| `A5-07-xx` | `occupancy_sensor` |
| `A5-08-xx` | `light_sensor` (Light+Occupancy) |
| `A5-09-xx` | `air_quality_sensor` |
| `D2-01-xx` (VLD) | `switch` (Electronic Switch) |
| `D5-00-xx` (1BS) | `contact_sensor` |

---

### 4. 🔴 EntitiesFromKNX

| Propriété | Valeur |
|---|---|
| **Protocole** | KNX (ISO 11801 / EN 50090) |
| **Standard** | DPT (Datapoint Types) |
| **Source** | KNX Gateway (`knx/devices/list`) |
| **Mapping** | DPT → NeurHomIA |
| **Types mappés** | ~80 types DPT |

**Exemples de mapping :**

| DPT | Catégorie NeurHomIA |
|---|---|
| `1.001` (Switch) | `switch` |
| `1.008` (Up/Down) | `cover` |
| `3.007` (Dimming) | `light` |
| `5.001` (Percentage) | `sensor` |
| `9.001` (Temperature °C) | `temperature_sensor` |
| `9.007` (Humidity %) | `humidity_sensor` |
| `9.004` (Lux) | `light_sensor` |
| `13.xxx` (Counter) | `smart_meter` |
| `14.xxx` (Float) | `sensor` |
| `20.102` (HVAC Mode) | `thermostat` |

---

### 5. 🟡 EntitiesFromOneWire

| Propriété | Valeur |
|---|---|
| **Protocole** | 1-Wire (Maxim/Dallas) |
| **Standard** | Family Codes |
| **Source** | 1-Wire Gateway (`onewire/devices/list`) |
| **Mapping** | Family Code → NeurHomIA |
| **Types mappés** | ~50 types (Family Codes) |

**Exemples de mapping :**

| Family Code | Puce | Catégorie NeurHomIA |
|---|---|---|
| `10` | DS18S20 | `temperature_sensor` |
| `28` | DS18B20 | `temperature_sensor` |
| `26` | DS2438 | `battery_sensor` / `temperature_sensor` |
| `12` | DS2406 | `switch` (2 canaux) |
| `05` | DS2405 | `switch` |
| `1D` | DS2423 | `smart_meter` (compteur) |
| `20` | DS2450 | `sensor` (ADC 4 canaux) |
| `29` | DS2408 | `switch` (8 canaux GPIO) |
| `3A` | DS2413 | `switch` (2 canaux PIO) |

---

### 6. 🟠 EntitiesFromDALI

| Propriété | Valeur |
|---|---|
| **Protocole** | DALI / DALI-2 (IEC 62386) |
| **Standard** | Device Types IEC 62386 |
| **Source** | DALI Gateway (`dali/devices/list`) |
| **Mapping** | Device Type → NeurHomIA |
| **Types mappés** | ~25 types |

**Exemples de mapping :**

| Device Type | Description | Catégorie NeurHomIA |
|---|---|---|
| `0` | Fluorescent lamp | `light` |
| `1` | Emergency lighting | `light` |
| `2` | HID lamp | `light` |
| `3` | Low voltage halogen | `light` |
| `6` | LED module | `light` |
| `7` | Switching function | `switch` |
| `8` | Colour control | `light` (RGB) |
| `23` | Diagnostics | `sensor` |
| `24` | Energy metering | `smart_meter` |
| `25` | Thermal gear protection | `temperature_sensor` |

---

### 7. ⚪ EntitiesFromThread

| Propriété | Valeur |
|---|---|
| **Protocole** | Thread / OpenThread (IEEE 802.15.4) |
| **Standard** | Matter Device Types |
| **Source** | Thread Border Router (`thread/devices/list`) |
| **Mapping** | Matter Device Type → NeurHomIA |
| **Types mappés** | ~35 types |

**Exemples de mapping :**

| Matter Device Type | Catégorie NeurHomIA |
|---|---|
| `0x0100` On/Off Light | `light` |
| `0x0101` Dimmable Light | `light` |
| `0x010A` On/Off Plug-in Unit | `switch` |
| `0x0301` Thermostat | `thermostat` |
| `0x0302` Temperature Sensor | `temperature_sensor` |
| `0x0303` Humidity Sensor | `humidity_sensor` |
| `0x000A` Door Lock | `lock` |
| `0x0015` Contact Sensor | `contact_sensor` |
| `0x0202` Window Covering | `cover` |
| `0x0850` Smoke/CO Alarm | `smoke_detector` |

---

### 8. 🟤 EntitiesFromLonWorks

| Propriété | Valeur |
|---|---|
| **Protocole** | LonWorks (CEA-709 / ISO/IEC 14908) |
| **Standard** | SNVT (Standard Network Variable Types) |
| **Source** | LonWorks Gateway (`lonworks/devices/list`) |
| **Mapping** | SNVT → NeurHomIA |
| **Types mappés** | ~40 types |

**Exemples de mapping :**

| SNVT | Description | Catégorie NeurHomIA |
|---|---|---|
| `SNVT_temp` | Temperature | `temperature_sensor` |
| `SNVT_lev_disc` | Discrete level | `switch` |
| `SNVT_lev_cont` | Continuous level | `light` |
| `SNVT_occupancy` | Occupancy | `occupancy_sensor` |
| `SNVT_hvac_mode` | HVAC mode | `thermostat` |
| `SNVT_power` | Power (W) | `power_sensor` |
| `SNVT_elec_kwh` | Energy (kWh) | `smart_meter` |
| `SNVT_flow` | Flow rate | `sensor` |
| `SNVT_press` | Pressure | `pressure_sensor` |
| `SNVT_ppm` | Parts per million | `air_quality_sensor` |

---

### 9. 🏢 EntitiesFromBACnet

| Propriété | Valeur |
|---|---|
| **Protocole** | BACnet (ASHRAE 135 / ISO 16484-5) |
| **Standard** | Object Types ASHRAE 135 |
| **Source** | BACnet Gateway (`bacnet/devices/list`) |
| **Mapping** | Object Type → NeurHomIA |
| **Types mappés** | ~30 types |

**Exemples de mapping :**

| Object Type | Description | Catégorie NeurHomIA |
|---|---|---|
| `analog-input` | Entrée analogique | `sensor` |
| `analog-output` | Sortie analogique | `switch` |
| `binary-input` | Entrée TOR | `binary_sensor` |
| `binary-output` | Sortie TOR | `switch` |
| `multi-state-input` | Multi-états entrée | `sensor` |
| `loop` | Boucle PID | `thermostat` |
| `schedule` | Programmation | `scheduler` |
| `calendar` | Calendrier | `scheduler` |
| `trend-log` | Historisation | `sensor` |
| `accumulator` | Compteur énergie | `smart_meter` |

---

### 10. 💧 EntitiesFromMBus

| Propriété | Valeur |
|---|---|
| **Protocole** | M-Bus / wM-Bus (EN 13757) |
| **Standard** | Medium Types EN 13757 |
| **Source** | M-Bus Gateway (`mbus/devices/list`) |
| **Mapping** | Medium Type → NeurHomIA |
| **Types mappés** | ~20 types |

**Exemples de mapping :**

| Medium Type | Description | Catégorie NeurHomIA |
|---|---|---|
| `0x02` | Electricity | `smart_meter` |
| `0x03` | Gas | `smart_meter` |
| `0x04` | Heat (outlet) | `smart_meter` |
| `0x06` | Hot water | `smart_meter` |
| `0x07` | Water | `smart_meter` |
| `0x08` | Heat Cost Allocator | `smart_meter` |
| `0x0A` | Cooling (outlet) | `smart_meter` |
| `0x0C` | Heat (inlet) | `smart_meter` |
| `0x15` | Hot water (volume) | `smart_meter` |
| `0x16` | Cold water | `smart_meter` |

---

### 11. 🏠 EntitiesFromInsteon

| Propriété | Valeur |
|---|---|
| **Protocole** | Insteon (Dual-Band RF + Powerline) |
| **Standard** | Device Categories (Dev Cat / Sub Cat) |
| **Source** | Insteon Hub (`insteon/devices/list`) |
| **Mapping** | (DevCat, SubCat) → NeurHomIA |
| **Types mappés** | ~25 catégories (+ fallback par DevCat haute) |

**Exemples de mapping :**

| DevCat | Description | Catégorie NeurHomIA |
|---|---|---|
| `0x01` | Dimmable Lighting | `light` |
| `0x02` | Switched Lighting | `switch` |
| `0x03` | Network Bridges | `sensor` |
| `0x04` | Irrigation Control | `switch` |
| `0x05` | Climate Control | `thermostat` |
| `0x07` | Sensors & Actuators | `sensor` |
| `0x09` | Energy Management | `smart_meter` |
| `0x0E` | Windows/Coverings | `cover` |
| `0x0F` | Access Control | `lock` |
| `0x10` | Security/Health | `alarm_panel` |

---

### 12. ⚡ EntitiesFromX10

| Propriété | Valeur |
|---|---|
| **Protocole** | X10 (CPL / Courants Porteurs en Ligne) |
| **Standard** | Device Types propriétaires |
| **Source** | X10 Interface (`x10/devices/list`) |
| **Mapping** | Device Type → NeurHomIA |
| **Types mappés** | ~15 types |

**Exemples de mapping :**

| Device Type X10 | Description | Catégorie NeurHomIA |
|---|---|---|
| `lamp` | Lamp Module (dimmable) | `light` |
| `appliance` | Appliance Module | `switch` |
| `switch` | Wall Switch | `switch` |
| `dimmer` | Wall Dimmer | `light` |
| `motion` | Motion Sensor | `motion_sensor` |
| `remote` | Remote Control | `sensor` |
| `thermostat` | Thermostat Module | `thermostat` |
| `camera` | Security Camera | `camera` |
| `chime` | Door Chime | `doorbell` |
| `siren` | Security Siren | `siren` |

---

### 13. 🔌 NrxGce2Mqtt (GPIO / GCE Electronics)

| Propriété | Valeur |
|---|---|
| **Interface** | GPIO Raspberry Pi CM4 (GCE Electronics NRX board) |
| **Entrées** | 8 entrées digitales optoisolées |
| **Sorties** | 8 relais (250V/10A) + 1 LED utilisateur |
| **Source** | Hardware GPIO direct (`/dev/gpiochip0`) |
| **Mapping** | Entrées → `sensor` / Relais → `switch` |
| **Tools** | 10 (get_status, update_config, set_relay, get_relay, get_input, toggle_relay, set_user_led, get_all_inputs, get_all_relays, emergency_stop) |
| **Mode simulation** | ✅ (`GPIO_SIMULATION=true` pour dev sans matériel) |

**Exemples de mapping :**

| Type GPIO | Description | Catégorie NeurHomIA |
|---|---|---|
| `input_0..7` | Entrée digitale optoisolée | `sensor` |
| `relay_0..7` | Relais de puissance | `switch` |
| `user_led` | LED utilisateur (status) | `light` |
| `emergency_stop` | Arrêt d'urgence (tous relais OFF) | `alarm_panel` |

---

## Matrice de couverture protocole × domaine

| Domaine | Zigbee | Z-Wave | EnOcean | KNX | 1-Wire | DALI | Thread | LonWorks | BACnet | M-Bus | Insteon | X10 | NrxGce |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Éclairage** | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| **Commutation** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| **Température** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | — |
| **CVC / Climat** | ✅ | ✅ | ✅ | ✅ | — | — | ✅ | ✅ | ✅ | — | ✅ | ✅ | — |
| **Énergie / Comptage** | ✅ | ✅ | — | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ | ✅ | — | — |
| **Sécurité** | ✅ | ✅ | ✅ | ✅ | — | — | ✅ | — | ✅ | — | ✅ | ✅ | ✅ |
| **Ouvrants** | ✅ | ✅ | ✅ | ✅ | — | — | ✅ | — | — | — | ✅ | — | — |
| **Qualité air** | ✅ | ✅ | ✅ | ✅ | — | — | — | ✅ | ✅ | — | — | — | — |
| **GPIO / I/O** | — | — | — | — | — | — | — | — | — | — | — | — | ✅ |

---

## Déploiement

### Profils Docker Compose

```bash
# Un seul protocole
docker compose -f docker-compose.master.yml --profile zigbee up -d

# Tous les extracteurs
docker compose -f docker-compose.master.yml --profile entities up -d

# Combinaison libre
docker compose -f docker-compose.master.yml --profile zigbee --profile knx --profile bacnet up -d
```

### Variables d'environnement

Chaque extracteur utilise une clé API dédiée :

| Service | Variable |
|---|---|
| EntitiesFromZigbee | `MCP_API_KEY_ENTITIES_ZIGBEE` |
| EntitiesFromZwave | `MCP_API_KEY_ENTITIES_ZWAVE` |
| EntitiesFromEnOcean | `MCP_API_KEY_ENTITIES_ENOCEAN` |
| EntitiesFromKNX | `MCP_API_KEY_ENTITIES_KNX` |
| EntitiesFromOneWire | `MCP_API_KEY_ENTITIES_ONEWIRE` |
| EntitiesFromDALI | `MCP_API_KEY_ENTITIES_DALI` |
| EntitiesFromThread | `MCP_API_KEY_ENTITIES_THREAD` |
| EntitiesFromLonWorks | `MCP_API_KEY_ENTITIES_LONWORKS` |
| EntitiesFromBACnet | `MCP_API_KEY_ENTITIES_BACNET` |
| EntitiesFromMBus | `MCP_API_KEY_ENTITIES_MBUS` |
| EntitiesFromInsteon | `MCP_API_KEY_ENTITIES_INSTEON` |
| EntitiesFromX10 | `MCP_API_KEY_ENTITIES_X10` |
| NrxGce2Mqtt | `MCP_API_KEY_NRXGCE` |

---

*Suite EntitiesFrom v1.1.0 — NeurHomIA MCP SDK v2.0 — 9 mars 2026*