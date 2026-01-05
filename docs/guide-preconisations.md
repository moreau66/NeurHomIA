# Préconisations Architecture MCP 🏗️

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Ce document définit les standards et préconisations pour développer des microservices compatibles avec l'architecture **MCP (Model Context Protocol) JSON-RPC over MQTT** de NeurHomIA.

---

## 📑 Table des matières

- [Objectif](#-objectif)
- [Vue d'ensemble de l'Architecture](#-vue-densemble-de-larchitecture)
- [Spécifications JSON-RPC 2.0](#-spécifications-json-rpc-20-sur-mqtt)
- [Patterns MCP Obligatoires](#-patterns-mcp-obligatoires)
- [SDK Python MCP-MQTT](#-sdk-python-mcp-mqtt)
- [Interfaces MCP Standardisées](#-interfaces-mcp-standardisées)
- [Topics MQTT et Sécurité](#-topics-mqtt-et-sécurité)
- [Exemples Pratiques](#-exemples-pratiques-complets)
- [Standards de Développement](#-standards-de-développement)
- [Référence API](#-référence-api-complète)
- [Outils de Développement](#-outils-de-développement)
- [Déploiement](#-déploiement-et-bonnes-pratiques)
- [Voir aussi](#-voir-aussi)

---

## 🎯 Objectif

## 🏗️ Vue d'ensemble de l'Architecture

```
┌─────────────┐    JSON-RPC     ┌─────────────┐    JSON-RPC     ┌─────────────────┐
│  NeurHomIA  │◄───over MQTT───►│ Broker MQTT │◄───over MQTT───►│ Microservices   │
│  (Frontend) │                 │  (Mosquitto)│                 │    (Python)     │
└─────────────┘                 └─────────────┘                 └─────────────────┘
```

### Avantages de cette Architecture

- **Standardisation** : JSON-RPC 2.0 pour une API uniforme
- **Découplage** : Communication asynchrone via MQTT
- **Sécurité** : Authentification et permissions intégrées
- **Scalabilité** : Ajout facile de nouveaux microservices
- **Fiabilité** : Gestion robuste des erreurs et reconnexions
- **Debugging** : Traçabilité complète des échanges

## 📋 Spécifications JSON-RPC 2.0 sur MQTT

### Structure des Requêtes

```json
{
  "jsonrpc": "2.0",
  "method": "mcp.list_tools",
  "params": {
    "filter": "weather"
  },
  "id": "req_001",
  "auth": {
    "api_key": "your_api_key",
    "service_id": "weather_service"
  }
}
```

### Structure des Réponses

```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {
        "name": "get_weather",
        "description": "Get current weather data",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {"type": "string"}
          }
        }
      }
    ]
  },
  "id": "req_001"
}
```

### Structure des Erreurs

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "param": "location",
      "expected": "string",
      "received": "null"
    }
  },
  "id": "req_001"
}
```

### Topics MQTT Standardisés

```
mcp/{service_id}/jsonrpc/request    # Requêtes JSON-RPC vers le microservice
mcp/{service_id}/jsonrpc/response   # Réponses JSON-RPC du microservice
mcp/{service_id}/discovery          # Auto-découverte du microservice
mcp/{service_id}/heartbeat          # Maintien de session
mcp/{service_id}/events             # Événements asynchrones
mcp/{service_id}/logs               # Logs et debugging
```

## 🔄 Patterns MCP Obligatoires

### 1. Discovery Pattern

Chaque microservice DOIT publier ses capacités au démarrage :

```json
{
  "service_id": "weather_service",
  "name": "Weather Service",
  "version": "1.0.0",
  "description": "Provides weather data and forecasts",
  "capabilities": {
    "tools": ["get_weather", "get_forecast"],
    "resources": ["weather_widget"],
    "events": ["weather_alert"]
  },
  "mcp_version": "1.0",
  "status": "ready",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Topic** : `mcp/{service_id}/discovery`

### 2. Heartbeat Pattern

Maintien de session toutes les 30 secondes :

```json
{
  "service_id": "weather_service",
  "status": "alive",
  "uptime": 3600,
  "active_connections": 2,
  "last_activity": "2024-01-15T10:35:00Z",
  "timestamp": "2024-01-15T10:35:30Z"
}
```

**Topic** : `mcp/{service_id}/heartbeat`

### 3. Tools Pattern

Exposition d'outils via MCP standardisés :

```python
@mcp_tool
async def get_weather(location: str) -> dict:
    """Get current weather for a location"""
    # Implémentation
    return {"temperature": 22, "humidity": 65}
```

### 4. Resources Pattern

Publication de ressources (widgets, pages) :

```json
{
  "resource_type": "widget",
  "resource_id": "weather_widget",
  "config": {
    "id": "weather_widget",
    "name": "Weather Widget",
    "version": "1.0.0",
    "device_types": ["weather"],
    "sections": [...]
  }
}
```

## 🐍 SDK Python MCP-MQTT

### Classe de Base

```python
from mcp_mqtt_sdk import MCPMicroservice, mcp_tool, mcp_resource
import asyncio
import json

class WeatherService(MCPMicroservice):
    def __init__(self):
        super().__init__(
            service_id="weather_service",
            name="Weather Service",
            version="1.0.0",
            description="Provides weather data and forecasts"
        )
    
    @mcp_tool
    async def get_weather(self, location: str) -> dict:
        """Get current weather for a location"""
        # Votre logique métier ici
        return {
            "location": location,
            "temperature": 22,
            "humidity": 65,
            "description": "Sunny"
        }
    
    @mcp_tool  
    async def get_forecast(self, location: str, days: int = 5) -> list:
        """Get weather forecast for a location"""
        # Votre logique métier ici
        return [{"day": i, "temp": 20+i} for i in range(days)]
    
    @mcp_resource
    async def weather_widget(self) -> dict:
        """Publish weather widget configuration"""
        return {
            "id": "weather_widget",
            "name": "Weather Widget",
            "device_types": ["weather"],
            "sections": [
                {
                    "id": "current",
                    "title": "Current Weather",
                    "fields": [
                        {"key": "temperature", "label": "Temperature", "type": "number"},
                        {"key": "humidity", "label": "Humidity", "type": "number"}
                    ]
                }
            ]
        }

# Usage
if __name__ == "__main__":
    service = WeatherService()
    asyncio.run(service.start())
```

### Installation du SDK

```bash
pip install mcp-mqtt-sdk
```

### Configuration

```python
# config.py
MCP_CONFIG = {
    "mqtt": {
        "broker": "localhost",
        "port": 1883,
        "username": "mcp_user",
        "password": "mcp_password"
    },
    "service": {
        "heartbeat_interval": 30,
        "discovery_interval": 60,
        "max_retries": 3
    },
    "logging": {
        "level": "INFO",
        "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    }
}
```

## 🔧 Interfaces MCP Standardisées

### MCPTool Interface

```python
from typing import Any, Dict, List, Optional
from pydantic import BaseModel

class MCPToolParameter(BaseModel):
    name: str
    type: str
    description: str
    required: bool = True
    default: Optional[Any] = None

class MCPTool(BaseModel):
    name: str
    description: str
    parameters: List[MCPToolParameter]
    category: Optional[str] = None
    examples: Optional[List[Dict]] = None
    
    class Config:
        schema_extra = {
            "example": {
                "name": "get_weather",
                "description": "Get current weather data",
                "parameters": [
                    {
                        "name": "location",
                        "type": "string",
                        "description": "City name or coordinates",
                        "required": True
                    }
                ],
                "category": "weather"
            }
        }
```

### MCPResource Interface

```python
class MCPResource(BaseModel):
    resource_type: str  # "widget", "page", "data"
    resource_id: str
    name: str
    version: str
    config: Dict[str, Any]
    dependencies: Optional[List[str]] = None
    
    class Config:
        schema_extra = {
            "example": {
                "resource_type": "widget",
                "resource_id": "weather_widget",
                "name": "Weather Widget",
                "version": "1.0.0",
                "config": {
                    "device_types": ["weather"],
                    "sections": [...]
                }
            }
        }
```

### MCPCapability Interface

```python
class MCPCapability(BaseModel):
    capability_type: str  # "tool", "resource", "event"
    name: str
    description: str
    version: str
    status: str  # "available", "disabled", "error"
    metadata: Optional[Dict[str, Any]] = None
```

## 🔐 Topics MQTT et Sécurité

### Convention de Nommage

```
mcp/                                # Namespace racine MCP
├── {service_id}/                   # ID unique du microservice
│   ├── jsonrpc/
│   │   ├── request                 # Requêtes JSON-RPC
│   │   ├── response                # Réponses JSON-RPC
│   │   └── notification            # Notifications asynchrones
│   ├── discovery                   # Auto-découverte
│   ├── heartbeat                   # Maintien de session
│   ├── events                      # Événements métier
│   └── logs                        # Logs et debugging
└── system/                         # Topics système globaux
    ├── discovery                   # Découverte globale
    ├── health                      # Santé du système
    └── events                      # Événements système
```

### Authentification

Chaque requête DOIT inclure une section `auth` :

```json
{
  "jsonrpc": "2.0",
  "method": "mcp.call_tool",
  "params": {...},
  "id": "req_001",
  "auth": {
    "api_key": "mcp_api_key_123456",
    "service_id": "weather_service",
    "timestamp": "2024-01-15T10:30:00Z",
    "signature": "sha256_signature_optional"
  }
}
```

### Permissions Granulaires

```python
# Exemple de décorateur pour permissions
@mcp_tool
@require_permission("weather:read")
async def get_weather(self, location: str) -> dict:
    pass

@mcp_tool  
@require_permission("weather:admin")
async def update_station_config(self, config: dict) -> bool:
    pass
```

## 📝 Exemples Pratiques Complets

### 1. Microservice Météo Complet

```python
# weather_service.py
from mcp_mqtt_sdk import MCPMicroservice, mcp_tool, mcp_resource
import aiohttp
import asyncio

class WeatherService(MCPMicroservice):
    def __init__(self):
        super().__init__(
            service_id="weather_service",
            name="Weather Service", 
            version="1.2.0",
            description="Complete weather service with forecasts and alerts"
        )
        self.api_key = "your_weather_api_key"
        self.base_url = "https://api.openweathermap.org/data/2.5"
    
    async def on_startup(self):
        """Called when service starts"""
        self.session = aiohttp.ClientSession()
        await self.publish_widget_config()
        
    async def on_shutdown(self):
        """Called when service stops"""
        await self.session.close()
    
    @mcp_tool
    async def get_current_weather(self, location: str, units: str = "metric") -> dict:
        """Get current weather for a location
        
        Args:
            location: City name or coordinates (lat,lon)
            units: Temperature units (metric, imperial, kelvin)
        """
        try:
            url = f"{self.base_url}/weather"
            params = {
                "q": location,
                "appid": self.api_key,
                "units": units
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "location": data["name"],
                        "temperature": data["main"]["temp"],
                        "feels_like": data["main"]["feels_like"],
                        "humidity": data["main"]["humidity"],
                        "pressure": data["main"]["pressure"],
                        "description": data["weather"][0]["description"],
                        "icon": data["weather"][0]["icon"],
                        "wind_speed": data.get("wind", {}).get("speed", 0),
                        "timestamp": data["dt"]
                    }
                else:
                    raise Exception(f"API Error: {response.status}")
                    
        except Exception as e:
            self.logger.error(f"Error getting weather: {e}")
            raise
    
    @mcp_tool
    async def get_forecast(self, location: str, days: int = 5, units: str = "metric") -> list:
        """Get weather forecast for a location
        
        Args:
            location: City name or coordinates
            days: Number of days (1-5)
            units: Temperature units
        """
        try:
            url = f"{self.base_url}/forecast"
            params = {
                "q": location,
                "appid": self.api_key,
                "units": units,
                "cnt": days * 8  # 8 forecasts per day (every 3h)
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    forecasts = []
                    
                    for item in data["list"]:
                        forecasts.append({
                            "datetime": item["dt_txt"],
                            "temperature": item["main"]["temp"],
                            "description": item["weather"][0]["description"],
                            "icon": item["weather"][0]["icon"],
                            "humidity": item["main"]["humidity"],
                            "wind_speed": item.get("wind", {}).get("speed", 0)
                        })
                    
                    return forecasts
                else:
                    raise Exception(f"API Error: {response.status}")
                    
        except Exception as e:
            self.logger.error(f"Error getting forecast: {e}")
            raise
    
    @mcp_tool
    async def get_weather_alerts(self, location: str) -> list:
        """Get weather alerts for a location"""
        # Implémentation des alertes météo
        return []
    
    @mcp_resource
    async def weather_widget_config(self) -> dict:
        """Weather widget configuration"""
        return {
            "id": "weather_widget",
            "name": "Weather Widget",
            "version": "1.2.0",
            "device_types": ["weather", "sensor"],
            "display": {
                "icon": "cloud-sun",
                "color": "hsl(200, 70%, 50%)",
                "background_gradient": "linear-gradient(135deg, hsl(200, 70%, 50%), hsl(220, 60%, 60%))"
            },
            "sections": [
                {
                    "id": "current",
                    "title": "Current Weather",
                    "type": "grid",
                    "fields": [
                        {
                            "key": "temperature",
                            "label": "Temperature",
                            "type": "number",
                            "unit": "°C",
                            "format": "0.1f"
                        },
                        {
                            "key": "humidity", 
                            "label": "Humidity",
                            "type": "number",
                            "unit": "%"
                        },
                        {
                            "key": "pressure",
                            "label": "Pressure", 
                            "type": "number",
                            "unit": "hPa"
                        },
                        {
                            "key": "wind_speed",
                            "label": "Wind Speed",
                            "type": "number", 
                            "unit": "m/s"
                        }
                    ]
                },
                {
                    "id": "forecast",
                    "title": "5-Day Forecast",
                    "type": "list",
                    "max_items": 5
                }
            ],
            "interactions": [
                {
                    "type": "refresh",
                    "action": "get_current_weather",
                    "icon": "refresh-cw"
                },
                {
                    "type": "configure",
                    "action": "configure_location",
                    "icon": "settings"
                }
            ]
        }

# Lancement du service
if __name__ == "__main__":
    service = WeatherService()
    asyncio.run(service.start())
```

### 2. Microservice Docker Complet

```python
# docker_service.py
from mcp_mqtt_sdk import MCPMicroservice, mcp_tool, mcp_resource
import docker
import asyncio

class DockerService(MCPMicroservice):
    def __init__(self):
        super().__init__(
            service_id="docker_service",
            name="Docker Management Service",
            version="1.0.0", 
            description="Manage Docker containers and images"
        )
        self.client = None
    
    async def on_startup(self):
        """Initialize Docker client"""
        try:
            self.client = docker.from_env()
            self.logger.info("Docker client initialized")
        except Exception as e:
            self.logger.error(f"Failed to initialize Docker client: {e}")
            raise
    
    @mcp_tool
    async def list_containers(self, all: bool = False) -> list:
        """List Docker containers
        
        Args:
            all: Include stopped containers
        """
        containers = []
        for container in self.client.containers.list(all=all):
            containers.append({
                "id": container.id[:12],
                "name": container.name,
                "image": container.image.tags[0] if container.image.tags else container.image.id,
                "status": container.status,
                "created": container.attrs["Created"],
                "ports": container.ports
            })
        return containers
    
    @mcp_tool
    async def start_container(self, container_id: str) -> dict:
        """Start a Docker container"""
        try:
            container = self.client.containers.get(container_id)
            container.start()
            return {"success": True, "message": f"Container {container_id} started"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    @mcp_tool
    async def stop_container(self, container_id: str) -> dict:
        """Stop a Docker container"""
        try:
            container = self.client.containers.get(container_id)
            container.stop()
            return {"success": True, "message": f"Container {container_id} stopped"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    @mcp_tool
    async def get_container_logs(self, container_id: str, lines: int = 100) -> str:
        """Get container logs"""
        try:
            container = self.client.containers.get(container_id)
            logs = container.logs(tail=lines).decode('utf-8')
            return logs
        except Exception as e:
            return f"Error getting logs: {e}"

if __name__ == "__main__":
    service = DockerService()
    asyncio.run(service.start())
```

## 📊 Standards de Développement

### Structure de Projet Recommandée

```
my_microservice/
├── src/
│   ├── __init__.py
│   ├── main.py                 # Point d'entrée principal
│   ├── service.py              # Classe MCPMicroservice
│   ├── tools/                  # Outils MCP
│   │   ├── __init__.py
│   │   ├── weather_tools.py
│   │   └── admin_tools.py
│   ├── resources/              # Ressources MCP
│   │   ├── __init__.py
│   │   ├── widgets.py
│   │   └── pages.py
│   ├── models/                 # Modèles Pydantic
│   │   ├── __init__.py
│   │   └── weather.py
│   └── utils/                  # Utilitaires
│       ├── __init__.py
│       └── helpers.py
├── tests/                      # Tests unitaires
├── config/                     # Fichiers de configuration
├── requirements.txt            # Dépendances Python
├── Dockerfile                  # Image Docker
├── docker-compose.yml          # Déploiement local
└── README.md                   # Documentation
```

### Tests Recommandés

```python
# tests/test_weather_service.py
import pytest
import asyncio
from unittest.mock import AsyncMock, patch
from src.service import WeatherService

@pytest.fixture
async def weather_service():
    service = WeatherService()
    await service.on_startup()
    yield service
    await service.on_shutdown()

@pytest.mark.asyncio
async def test_get_current_weather(weather_service):
    """Test getting current weather"""
    with patch.object(weather_service.session, 'get') as mock_get:
        # Mock API response
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={
            "name": "Paris",
            "main": {"temp": 20, "humidity": 60},
            "weather": [{"description": "clear", "icon": "01d"}],
            "dt": 1642262400
        })
        mock_get.return_value.__aenter__.return_value = mock_response
        
        result = await weather_service.get_current_weather("Paris")
        
        assert result["location"] == "Paris"
        assert result["temperature"] == 20
        assert result["humidity"] == 60

@pytest.mark.asyncio  
async def test_mcp_tool_registration():
    """Test that MCP tools are properly registered"""
    service = WeatherService()
    tools = await service.list_tools()
    
    tool_names = [tool["name"] for tool in tools]
    assert "get_current_weather" in tool_names
    assert "get_forecast" in tool_names
```

### Logging et Debugging

```python
# Configuration logging recommandée
import logging
import json
from datetime import datetime

class MCPFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "service": getattr(record, 'service_id', 'unknown'),
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        if hasattr(record, 'mcp_context'):
            log_entry['mcp_context'] = record.mcp_context
            
        return json.dumps(log_entry)

# Usage dans le microservice
logger = logging.getLogger(__name__)
logger.info("Processing MCP request", extra={
    'service_id': self.service_id,
    'mcp_context': {
        'method': 'get_weather',
        'request_id': 'req_001',
        'client_id': 'neurhomia_client'
    }
})
```

## 📚 Référence API Complète

### Méthodes MCP Standard Obligatoires

#### 1. `mcp.list_tools`

Liste tous les outils disponibles du microservice.

**Requête :**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.list_tools",
  "params": {
    "filter": "optional_category_filter"
  },
  "id": "req_001"
}
```

**Réponse :**
```json
{
  "jsonrpc": "2.0", 
  "result": {
    "tools": [
      {
        "name": "get_weather",
        "description": "Get current weather data",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {"type": "string", "description": "City name"}
          },
          "required": ["location"]
        },
        "category": "weather"
      }
    ]
  },
  "id": "req_001"
}
```

#### 2. `mcp.call_tool`

Appelle un outil spécifique du microservice.

**Requête :**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.call_tool", 
  "params": {
    "tool_name": "get_weather",
    "arguments": {
      "location": "Paris"
    }
  },
  "id": "req_002"
}
```

**Réponse :**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "data": {
      "location": "Paris",
      "temperature": 22,
      "humidity": 65
    }
  },
  "id": "req_002"
}
```

#### 3. `mcp.list_resources`

Liste toutes les ressources disponibles (widgets, pages).

**Requête :**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.list_resources",
  "params": {
    "resource_type": "widget" // optional filter
  },
  "id": "req_003"
}
```

#### 4. `mcp.get_resource`

Récupère une ressource spécifique.

**Requête :**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.get_resource",
  "params": {
    "resource_id": "weather_widget"
  },
  "id": "req_004"
}
```

#### 5. `mcp.health_check`

Vérifie l'état de santé du microservice.

**Requête :**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.health_check",
  "params": {},
  "id": "req_005"
}
```

**Réponse :**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "status": "healthy",
    "uptime": 3600,
    "version": "1.0.0",
    "dependencies": {
      "database": "connected",
      "external_api": "connected"
    }
  },
  "id": "req_005"
}
```

### Codes d'Erreur Standardisés

| Code | Message | Description |
|------|---------|-------------|
| -32700 | Parse error | JSON invalide |
| -32600 | Invalid Request | Requête JSON-RPC invalide |
| -32601 | Method not found | Méthode inexistante |
| -32602 | Invalid params | Paramètres invalides |
| -32603 | Internal error | Erreur interne |
| -32000 | Server error | Erreur serveur générique |
| -32001 | Unauthorized | Authentification requise |
| -32002 | Forbidden | Permissions insuffisantes |
| -32003 | Resource not found | Ressource introuvable |
| -32004 | Timeout | Timeout de la requête |
| -32005 | Rate limited | Limite de taux dépassée |

## 🛠️ Outils de Développement

### 1. Simulateur MQTT Local

```bash
# Lancement du broker MQTT local avec Docker
docker run -it -p 1883:1883 -p 9001:9001 \
  -v $(pwd)/mosquitto.conf:/mosquitto/config/mosquitto.conf \
  eclipse-mosquitto
```

```
# mosquitto.conf
listener 1883
allow_anonymous true
log_type all
log_dest stdout
```

### 2. Client de Test MCP

```python
# test_client.py
import asyncio
import json
from mcp_mqtt_sdk import MCPClient

async def test_weather_service():
    client = MCPClient("test_client")
    await client.connect()
    
    # Test list tools
    response = await client.call_method(
        service_id="weather_service",
        method="mcp.list_tools",
        params={}
    )
    print("Available tools:", response)
    
    # Test call tool
    response = await client.call_method(
        service_id="weather_service", 
        method="mcp.call_tool",
        params={
            "tool_name": "get_weather",
            "arguments": {"location": "Paris"}
        }
    )
    print("Weather data:", response)
    
    await client.disconnect()

if __name__ == "__main__":
    asyncio.run(test_weather_service())
```

### 3. Validateur de Schémas

```python
# schema_validator.py
from jsonschema import validate, ValidationError
import json

MCP_REQUEST_SCHEMA = {
    "type": "object",
    "properties": {
        "jsonrpc": {"const": "2.0"},
        "method": {"type": "string"},
        "params": {"type": "object"},
        "id": {"type": "string"},
        "auth": {
            "type": "object",
            "properties": {
                "api_key": {"type": "string"},
                "service_id": {"type": "string"}
            },
            "required": ["api_key", "service_id"]
        }
    },
    "required": ["jsonrpc", "method", "id"]
}

def validate_mcp_request(request_data):
    try:
        validate(instance=request_data, schema=MCP_REQUEST_SCHEMA)
        return True, None
    except ValidationError as e:
        return False, str(e)
```

### 4. Générateur de Squelettes

```bash
# Installation du générateur
pip install mcp-scaffold

# Génération d'un nouveau microservice
mcp-scaffold create --name weather_service --type api_client

# Génération avec template spécifique
mcp-scaffold create --name docker_service --template docker_management
```

### 5. Dashboard de Debugging

Interface web pour monitorer les échanges MCP :

```python
# debug_dashboard.py
from flask import Flask, render_template, jsonify
from mcp_mqtt_sdk import MCPMonitor

app = Flask(__name__)
monitor = MCPMonitor()

@app.route("/")
def dashboard():
    return render_template("dashboard.html")

@app.route("/api/services")
def list_services():
    return jsonify(monitor.get_active_services())

@app.route("/api/messages")
def get_messages():
    return jsonify(monitor.get_recent_messages())

if __name__ == "__main__":
    app.run(debug=True, port=5000)
```

## 🚀 Déploiement et Bonnes Pratiques

### Docker Configuration

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ ./src/
COPY config/ ./config/

CMD ["python", "-m", "src.main"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  weather-service:
    build: .
    environment:
      - MQTT_BROKER=mosquitto
      - MQTT_PORT=1883
      - API_KEY=${WEATHER_API_KEY}
    depends_on:
      - mosquitto
    restart: unless-stopped

  mosquitto:
    image: eclipse-mosquitto:latest
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf
```

### Variables d'Environnement

```bash
# .env
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=mcp_user
MQTT_PASSWORD=mcp_password
API_KEY=your_api_key_here
LOG_LEVEL=INFO
HEARTBEAT_INTERVAL=30
```

### Monitoring et Alertes

```python
# health_monitor.py
import asyncio
from mcp_mqtt_sdk import MCPHealthMonitor

async def monitor_services():
    monitor = MCPHealthMonitor()
    
    # Surveiller tous les services MCP
    await monitor.start_monitoring([
        "weather_service",
        "docker_service", 
        "ia_service"
    ])
    
    # Alertes automatiques
    monitor.on_service_down(send_alert)
    monitor.on_high_latency(log_warning)

async def send_alert(service_id, status):
    print(f"ALERT: Service {service_id} is {status}")

async def log_warning(service_id, latency):
    print(f"WARNING: High latency for {service_id}: {latency}ms")
```

## 📖 Ressources et Support

### Documentation Officielle
- [MCP Protocol Specification](https://modelcontextprotocol.io/docs)
- [MQTT 5.0 Specification](https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)

### Exemples de Microservices
- [Weather Service Example](./examples/weather_service/)
- [Docker Management Example](./examples/docker_service/)
- [AI Assistant Example](./examples/ia_service/)

### Support et Communauté
- **Issues GitHub** : [Lien vers le repository]
- **Discord** : [Lien vers le serveur Discord]
- **Documentation** : [Lien vers la documentation complète]

---

## 📝 Changelog

### Version 1.0.0 (2024-01-15)
- Architecture MCP JSON-RPC over MQTT initiale
- SDK Python de base
- Exemples de microservices
- Documentation complète

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Développement](guide-developpement.md) - Contribuer au projet
- [Guide de Production](guide-production.md) - Déploiement en production
- [Guide du Mode Simulation](guide-mode-simulation.md) - Test sans infrastructure
- [Structure JSON Microservices](microservice-json.md) - Format des configurations
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications

---

_Documentation NeurHomIA_