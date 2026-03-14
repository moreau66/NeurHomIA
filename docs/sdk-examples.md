# Exemples de microservices MCP

> **Version** : 1.0.0 | **Mise à jour** : 2026-03-09T10:00:00

Cette section présente des exemples complets de microservices MCP pour différents cas d'usage.

## 1. Calculatrice Simple

### Description
Microservice de base démontrant les opérations mathématiques simples.

### Fichiers
- `examples/simple_calculator/calculator_service.py`
- `examples/simple_calculator/README.md`

### Fonctionnalités
- Opérations de base (addition, soustraction, multiplication, division)
- Opérations avancées (puissance, racine carrée)
- Historique des calculs
- Widget d'interface pour NeurHomIA

### Outils exposés
- `math.add` - Addition de deux nombres
- `math.subtract` - Soustraction
- `math.multiply` - Multiplication
- `math.divide` - Division (avec gestion division par zéro)
- `math.power` - Élévation à la puissance
- `math.sqrt` - Racine carrée
- `calculator.clear_history` - Effacement de l'historique

### Ressources exposées
- `calculator/history` - Historique des calculs avec statistiques
- `calculator/widget` - Configuration du widget pour l'interface

### Lancement
```bash
cd examples/simple_calculator
python calculator_service.py
```

### Test
```bash
python ../../tools/test_client.py --service-id calculator-service --method math.add --params '{"a": 5, "b": 3}'
```

---

## 2. Capteurs IoT (À venir)

### Description
Microservice pour la gestion de capteurs IoT avec différents types de données.

### Fonctionnalités prévues
- Lecture de capteurs de température
- Capteurs d'humidité et de pression
- Historique et tendances
- Alertes en cas de valeurs anormales
- Dashboard de monitoring

### Outils à implémenter
- `sensors.read_temperature`
- `sensors.read_humidity`
- `sensors.get_trends`
- `alerts.configure`

---

## 3. Domotique (À venir)

### Description
Microservice de contrôle domotique pour lumières, volets, thermostats.

### Fonctionnalités prévues
- Contrôle des lumières (on/off, intensité, couleur)
- Gestion des volets roulants
- Contrôle de thermostats
- Scénarios d'automatisation
- Planning temporel

### Outils à implémenter
- `lights.toggle`
- `lights.set_brightness`
- `shutters.open`
- `shutters.close`
- `thermostat.set_temperature`
- `scenarios.execute`

---

## 4. Station Météo (À venir)

### Description
Microservice pour données météorologiques avec prévisions et historiques.

### Fonctionnalités prévues
- Données météo actuelles
- Prévisions sur 7 jours
- Historique météorologique
- Alertes météo
- Widget météo personnalisable

### Outils à implémenter
- `weather.get_current`
- `weather.get_forecast`
- `weather.get_history`
- `alerts.weather_warning`

---

## Structure type d'un exemple

Chaque exemple suit cette structure standardisée :

```
examples/
├── nom_exemple/
│   ├── README.md                 # Documentation spécifique
│   ├── service.py               # Microservice principal
│   ├── config.py                # Configuration
│   ├── requirements.txt         # Dépendances spécifiques
│   ├── docker-compose.yml       # Déploiement
│   ├── tests/                   # Tests unitaires
│   │   ├── test_service.py
│   │   └── test_integration.py
│   └── schemas/                 # Schémas spécifiques
│       ├── tools.json
│       └── resources.json
```

## Patterns communs

### 1. Gestion d'erreurs standardisée

```python
@mcp_tool(name="example.method")
def method_with_error_handling(self, param: str) -> Dict[str, Any]:
    try:
        # Logique métier
        result = self._process_data(param)
        return {"status": "success", "data": result}
    except ValueError as e:
        logger.error(f"Erreur de validation: {e}")
        raise MCPError(-32602, f"Paramètre invalide: {e}")
    except Exception as e:
        logger.error(f"Erreur interne: {e}")
        raise MCPError(-32603, "Erreur interne du service")
```

### 2. Logging structuré

```python
import logging
import json

class StructuredLogger:
    def __init__(self, service_id: str):
        self.service_id = service_id
        self.logger = logging.getLogger(service_id)
    
    def log_tool_call(self, tool_name: str, params: Dict, result: Any):
        self.logger.info(json.dumps({
            "event": "tool_call",
            "service_id": self.service_id,
            "tool": tool_name,
            "params": params,
            "success": True,
            "timestamp": datetime.now().isoformat()
        }))
```

### 3. Configuration par environnement

```python
import os
from dataclasses import dataclass

@dataclass
class ServiceConfig:
    service_id: str = os.getenv("SERVICE_ID", "example-service")
    mqtt_host: str = os.getenv("MQTT_HOST", "localhost")
    api_key: str = os.getenv("API_KEY", "change-me")
    
    # Configuration spécifique au service
    update_interval: int = int(os.getenv("UPDATE_INTERVAL", "30"))
    cache_enabled: bool = os.getenv("CACHE_ENABLED", "true").lower() == "true"
```

### 4. Tests d'intégration

```python
import unittest
from unittest.mock import patch, MagicMock

class TestExampleService(unittest.TestCase):
    def setUp(self):
        self.service = ExampleService()
    
    @patch('example_service.external_api_call')
    def test_tool_with_mock(self, mock_api):
        mock_api.return_value = {"data": "test"}
        result = self.service.example_tool("test_param")
        self.assertEqual(result["status"], "success")
    
    def test_tool_validation(self):
        with self.assertRaises(ValueError):
            self.service.example_tool("")  # Paramètre vide
```

## Conseils de développement

### 1. Modularité
- Séparez la logique métier des détails MCP
- Utilisez des services séparés pour les appels externes
- Implémentez des interfaces claires entre composants

### 2. Observabilité
- Loggez toutes les opérations importantes
- Incluez des métriques de performance
- Implémentez des health checks détaillés

### 3. Robustesse
- Gérez tous les cas d'erreur possibles
- Implémentez des timeouts appropriés
- Prévoyez des mécanismes de retry

### 4. Documentation
- Documentez tous les outils et ressources
- Fournissez des exemples d'utilisation
- Maintenez un changelog des versions

## Tests et validation

### Validation automatique
```bash
# Validation du microservice
python tools/validate_microservice.py examples/simple_calculator/calculator_service.py

# Tests unitaires
python -m pytest examples/simple_calculator/tests/

# Tests d'intégration
python tools/test_client.py --service-id calculator-service --run-all-tests
```

### Monitoring en temps réel
```bash
# Surveillance des messages MQTT
python tools/mqtt_monitor.py --service-id calculator-service

# Surveillance des performances
python tools/performance_monitor.py --service-id calculator-service
```