# Guide de démarrage rapide MCP

> **Version** : 1.0.0 | **Mise à jour** : 2026-03-09T10:00:00

Ce guide vous accompagne étape par étape pour créer votre premier microservice MCP compatible avec NeurHomIA.

## Prérequis

- Python 3.8+
- Docker (optionnel)
- Accès à un broker MQTT

## Étape 1 : Installation de l'environnement

### 1.1 Créer un environnement virtuel

```bash
python -m venv mcp_env
source mcp_env/bin/activate  # Linux/Mac
# ou
mcp_env\Scripts\activate     # Windows
```

### 1.2 Installer les dépendances

```bash
pip install mcp-mqtt-sdk paho-mqtt pydantic
```

## Étape 2 : Créer votre premier microservice

### 2.1 Structure du projet

```
mon_microservice/
├── main.py
├── config.py
├── requirements.txt
└── Dockerfile
```

### 2.2 Configuration (config.py)

```python
import os
from dataclasses import dataclass

@dataclass
class Config:
    # MQTT Configuration
    MQTT_BROKER_HOST: str = os.getenv("MQTT_BROKER_HOST", "localhost")
    MQTT_BROKER_PORT: int = int(os.getenv("MQTT_BROKER_PORT", "1883"))
    MQTT_USERNAME: str = os.getenv("MQTT_USERNAME", "")
    MQTT_PASSWORD: str = os.getenv("MQTT_PASSWORD", "")
    
    # Service Configuration
    SERVICE_ID: str = os.getenv("SERVICE_ID", "my-microservice")
    API_KEY: str = os.getenv("API_KEY", "your-secure-api-key")
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")

config = Config()
```

### 2.3 Microservice principal (main.py)

```python
import logging
from mcp_mqtt_sdk import MCPMicroservice, mcp_tool, mcp_resource
from config import config

# Configuration du logging
logging.basicConfig(level=config.LOG_LEVEL)
logger = logging.getLogger(__name__)

class MonMicroservice(MCPMicroservice):
    
    def __init__(self):
        super().__init__(
            service_id=config.SERVICE_ID,
            mqtt_host=config.MQTT_BROKER_HOST,
            mqtt_port=config.MQTT_BROKER_PORT,
            api_key=config.API_KEY
        )
    
    @mcp_tool(
        name="math.add",
        description="Additionne deux nombres",
        category="utility",
        permissions=["basic"]
    )
    def add_numbers(self, a: float, b: float) -> dict:
        """Additionne deux nombres et retourne le résultat."""
        result = a + b
        logger.info(f"Addition: {a} + {b} = {result}")
        return {
            "result": result,
            "operation": "addition",
            "operands": [a, b]
        }
    
    @mcp_tool(
        name="math.multiply",
        description="Multiplie deux nombres",
        category="utility"
    )
    def multiply_numbers(self, a: float, b: float) -> dict:
        """Multiplie deux nombres."""
        result = a * b
        return {
            "result": result,
            "operation": "multiplication",
            "operands": [a, b]
        }
    
    @mcp_resource(
        uri="calculator/status",
        name="Statut de la calculatrice",
        description="Informations sur l'état du microservice calculatrice"
    )
    def get_calculator_status(self) -> dict:
        """Retourne le statut du microservice."""
        return {
            "service_id": self.service_id,
            "status": "active",
            "operations_supported": ["add", "multiply"],
            "version": "1.0.0"
        }

if __name__ == "__main__":
    service = MonMicroservice()
    logger.info(f"Démarrage du microservice {config.SERVICE_ID}")
    service.run()
```

## Étape 3 : Test du microservice

### 3.1 Démarrer le microservice

```bash
python main.py
```

### 3.2 Tester avec l'outil de test

```bash
python ../tools/test_client.py --service-id my-microservice --method math.add --params '{"a": 5, "b": 3}'
```

## Étape 4 : Déploiement avec Docker

### 4.1 Dockerfile

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "main.py"]
```

### 4.2 docker-compose.yml

```yaml
version: '3.8'
services:
  mon-microservice:
    build: .
    environment:
      - MQTT_BROKER_HOST=mosquitto
      - SERVICE_ID=my-microservice
      - API_KEY=your-secure-api-key
    depends_on:
      - mosquitto
    restart: unless-stopped

  mosquitto:
    image: eclipse-mosquitto:2
    ports:
      - "1883:1883"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf
```

## Étape 5 : Validation et monitoring

### 5.1 Valider le microservice

```bash
python ../tools/validate_microservice.py my-microservice
```

### 5.2 Monitorer les messages MQTT

```bash
python ../tools/mqtt_monitor.py --service-id my-microservice
```

## Prochaines étapes

1. Consultez [`EXAMPLES.md`](./EXAMPLES.md) pour des exemples plus complexes
2. Lisez [`API_REFERENCE.md`](./API_REFERENCE.md) pour la documentation complète
3. Explorez les templates dans `templates/` pour différents types de microservices

## Troubleshooting

En cas de problème, consultez [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) ou utilisez l'outil de diagnostic :

```bash
python ../tools/diagnostic.py --service-id my-microservice
```