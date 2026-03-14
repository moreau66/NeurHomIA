# API Reference MCP JSON-RPC over MQTT

> **Version** : 1.0.0 | **Mise à jour** : 2026-03-09T10:00:00

Documentation complète de l'API MCP pour le développement de microservices.

## Architecture générale

### Communication JSON-RPC 2.0

```json
{
  "jsonrpc": "2.0",
  "method": "service.method",
  "params": {},
  "id": "unique-request-id",
  "mcp_metadata": {
    "service_id": "weather-service",
    "timestamp": "2024-01-01T12:00:00Z",
    "request_id": "req-123",
    "priority": "normal"
  }
}
```

### Topics MQTT

- **Requests**: `mcp/services/{service_id}/jsonrpc/request`
- **Responses**: `mcp/services/{service_id}/jsonrpc/response`
- **Discovery**: `mcp/discovery/{service_id}`
- **Heartbeat**: `mcp/heartbeat/{service_id}`
- **Events**: `mcp/events/{service_id}/{event_type}`
- **Logs**: `mcp/logs/{service_id}`

## Méthodes MCP obligatoires

### 1. mcp.list_tools

Liste tous les outils disponibles.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.list_tools",
  "id": "1"
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {
        "name": "weather.get_current",
        "description": "Obtient les données météo actuelles",
        "inputSchema": {
          "type": "object",
          "properties": {
            "location": {"type": "string"}
          },
          "required": ["location"]
        },
        "category": "data",
        "permissions": ["weather:read"]
      }
    ]
  },
  "id": "1"
}
```

### 2. mcp.call_tool

Appelle un outil spécifique.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.call_tool",
  "params": {
    "name": "weather.get_current",
    "arguments": {
      "location": "Paris"
    }
  },
  "id": "2"
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Temperature: 22°C, Humidity: 65%"
      }
    ],
    "isError": false
  },
  "id": "2"
}
```

### 3. mcp.list_resources

Liste toutes les ressources disponibles.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.list_resources",
  "id": "3"
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "resources": [
      {
        "uri": "weather/widget/current",
        "name": "Widget météo actuel",
        "description": "Affiche la météo actuelle",
        "mimeType": "application/json"
      }
    ]
  },
  "id": "3"
}
```

### 4. mcp.get_resource

Récupère une ressource spécifique.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.get_resource",
  "params": {
    "uri": "weather/widget/current"
  },
  "id": "4"
}
```

### 5. mcp.health_check

Vérifie l'état de santé du microservice.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "mcp.health_check",
  "id": "5"
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "status": "healthy",
    "version": "1.0.0",
    "uptime": 3600,
    "memory_usage": 45.2,
    "cpu_usage": 12.1
  },
  "id": "5"
}
```

## SDK Python - Décorateurs

### @mcp_tool

Décore une méthode pour l'exposer comme outil MCP.

```python
@mcp_tool(
    name="calculator.add",
    description="Additionne deux nombres",
    category="utility",
    permissions=["math:basic"],
    rate_limit={"calls": 100, "period": 60},
    timeout=5000,
    caching={"enabled": True, "ttl": 300}
)
def add_numbers(self, a: float, b: float) -> dict:
    return {"result": a + b}
```

**Paramètres:**
- `name` (str): Nom unique de l'outil
- `description` (str): Description de la fonctionnalité
- `category` (str): Catégorie ("utility", "data", "automation", etc.)
- `permissions` (list): Permissions requises
- `rate_limit` (dict): Limitation du taux d'appel
- `timeout` (int): Timeout en millisecondes
- `caching` (dict): Configuration du cache

### @mcp_resource

Décore une méthode pour l'exposer comme ressource MCP.

```python
@mcp_resource(
    uri="sensors/temperature/widget",
    name="Widget température",
    description="Widget d'affichage de température",
    mimeType="application/json",
    resourceType="widget"
)
def get_temperature_widget(self) -> dict:
    return {
        "id": "temp-widget",
        "name": "Température",
        "sections": [...]
    }
```

## Gestion des erreurs

### Codes d'erreur standardisés

```python
class MCPErrorCodes:
    PARSE_ERROR = -32700
    INVALID_REQUEST = -32600
    METHOD_NOT_FOUND = -32601
    INVALID_PARAMS = -32602
    INTERNAL_ERROR = -32603
    
    # Codes personnalisés MCP
    AUTHENTICATION_FAILED = -32000
    PERMISSION_DENIED = -32001
    RATE_LIMIT_EXCEEDED = -32002
    SERVICE_UNAVAILABLE = -32003
    VALIDATION_ERROR = -32004
```

### Format d'erreur

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32001,
    "message": "Permission denied",
    "data": {
      "required_permission": "weather:read",
      "user_permissions": ["basic"]
    }
  },
  "id": "1"
}
```

## Configuration du microservice

### Classe de base MCPMicroservice

```python
class WeatherService(MCPMicroservice):
    def __init__(self):
        super().__init__(
            service_id="weather-service",
            mqtt_host="localhost",
            mqtt_port=1883,
            mqtt_username="user",
            mqtt_password="pass",
            api_key="secure-key",
            discovery_interval=30,
            heartbeat_interval=10,
            log_level="INFO"
        )
```

### Métadonnées de service

```python
def get_service_metadata(self) -> dict:
    return {
        "service_id": "weather-service",
        "name": "Service Météo",
        "description": "Fournit des données météorologiques",
        "version": "1.0.0",
        "author": "Mon Nom",
        "category": "data",
        "tags": ["weather", "sensors", "iot"]
    }
```

## Patterns avancés

### Authentification et sécurité

```python
@mcp_tool(permissions=["admin:system"])
def secure_operation(self, data: dict) -> dict:
    # Vérification automatique des permissions
    return {"status": "success"}
```

### Gestion d'état

```python
class StatefulService(MCPMicroservice):
    def __init__(self):
        super().__init__("stateful-service")
        self.state = {}
    
    @mcp_tool(name="state.set")
    def set_state(self, key: str, value: any) -> dict:
        self.state[key] = value
        return {"status": "updated"}
```

### Événements et notifications

```python
def notify_temperature_change(self, temperature: float):
    self.publish_event("temperature_changed", {
        "temperature": temperature,
        "timestamp": datetime.now().isoformat()
    })
```

## Monitoring et logs

### Logs structurés

```python
import logging
logger = logging.getLogger(__name__)

@mcp_tool(name="data.process")
def process_data(self, data: dict) -> dict:
    logger.info("Processing data", extra={
        "data_size": len(data),
        "processing_time": time.time()
    })
    return {"processed": True}
```

### Métriques

```python
def get_metrics(self) -> dict:
    return {
        "requests_total": self.request_counter,
        "errors_total": self.error_counter,
        "response_time_avg": self.avg_response_time
    }
```