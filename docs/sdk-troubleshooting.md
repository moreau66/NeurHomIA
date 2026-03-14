# Guide de dépannage MCP

> **Version** : 1.0.0 | **Mise à jour** : 2026-03-09T10:00:00

Ce guide aide à diagnostiquer et résoudre les problèmes courants avec les microservices MCP.

## 🔧 Problèmes de connexion MQTT

### Service ne se connecte pas au broker MQTT

**Symptômes :**
- Timeout de connexion
- Messages d'erreur "Connection refused"
- Service démarre mais n'apparaît pas dans la découverte

**Solutions :**

1. **Vérifier la configuration MQTT**
```bash
# Tester la connexion au broker
mosquitto_pub -h localhost -p 1883 -t test/topic -m "test"
mosquitto_sub -h localhost -p 1883 -t test/topic
```

2. **Vérifier les variables d'environnement**
```bash
echo $MQTT_BROKER_HOST
echo $MQTT_BROKER_PORT
echo $MQTT_USERNAME
echo $MQTT_PASSWORD
```

3. **Vérifier les logs du broker**
```bash
docker logs mosquitto-container
```

4. **Tester avec l'outil de diagnostic**
```bash
python tools/mqtt_monitor.py --test-connection
```

### Messages MQTT perdus

**Symptômes :**
- Appels d'outils sans réponse
- Découverte intermittente
- Heartbeat manqués

**Solutions :**

1. **Augmenter le QoS**
```python
# Dans config.py
MQTT_QOS = 2  # Au lieu de 1
```

2. **Vérifier la rétention des messages**
```python
# Pour les messages de découverte
MQTT_RETAIN = True
```

3. **Monitorer les topics**
```bash
python tools/mqtt_monitor.py --service-id votre-service --verbose
```

---

## 🚫 Erreurs d'authentification

### API Key rejetée

**Symptômes :**
- Erreur "Authentication failed"
- Code d'erreur -32000

**Solutions :**

1. **Vérifier la clé API**
```bash
# Dans les logs du service
grep "API_KEY" logs/service.log
```

2. **Tester l'authentification**
```bash
python tools/test_client.py --service-id votre-service --test-auth
```

3. **Vérifier la configuration**
```python
# Dans config.py
API_KEY = "votre-clé-sécurisée"  # Au moins 8 caractères
ENABLE_AUTHENTICATION = True
```

### Permissions insuffisantes

**Symptômes :**
- Erreur "Permission denied"
- Code d'erreur -32001

**Solutions :**

1. **Vérifier les permissions des outils**
```python
@mcp_tool(
    name="tool.name",
    permissions=["permission:required"]  # Vérifier cette permission
)
```

2. **Configurer les permissions dans config.py**
```python
def get_permissions_config(self) -> dict:
    return {
        "basic": ["health.check", "echo.message"],
        "admin": ["*"]
    }
```

---

## 🐛 Erreurs de validation

### Schéma JSON invalide

**Symptômes :**
- Erreur de validation lors du démarrage
- Messages "Schema validation failed"

**Solutions :**

1. **Valider le microservice**
```bash
python tools/validate_microservice.py votre_service.py
```

2. **Vérifier la structure des outils**
```python
@mcp_tool(
    name="namespace.method",  # Doit contenir un point
    description="Description claire",  # Obligatoire
    category="utility"  # Doit être valide
)
```

3. **Valider les ressources**
```python
@mcp_resource(
    uri="service/resource",
    name="Nom de la ressource",
    mimeType="application/json",  # Doit être valide
    resourceType="data"  # Doit être valide
)
```

### Paramètres d'outils incorrects

**Symptômes :**
- Erreur "Invalid params"
- Code d'erreur -32602

**Solutions :**

1. **Vérifier les types de paramètres**
```python
def tool_method(self, param: str) -> Dict[str, Any]:  # Types explicites
    if not isinstance(param, str):
        raise ValueError("param doit être une chaîne")
```

2. **Ajouter la validation**
```python
from pydantic import BaseModel, validator

class ToolParams(BaseModel):
    param: str
    
    @validator('param')
    def validate_param(cls, v):
        if not v.strip():
            raise ValueError("param ne peut pas être vide")
        return v
```

---

## 🔄 Problèmes de découverte

### Service non découvert

**Symptômes :**
- Service ne s'affiche pas dans NeurHomIA
- Pas de messages de découverte

**Solutions :**

1. **Vérifier l'intervalle de découverte**
```python
# Dans config.py
DISCOVERY_INTERVAL = 30  # Secondes
```

2. **Forcer la découverte**
```bash
python tools/test_client.py --service-id votre-service --trigger-discovery
```

3. **Vérifier les métadonnées**
```python
def get_service_metadata(self) -> dict:
    return {
        "service_id": "service-unique",  # Doit être unique
        "name": "Nom du Service",
        "description": "Description claire",
        "version": "1.0.0"  # Format sémantique
    }
```

### Heartbeat manqué

**Symptômes :**
- Service marqué comme "hors ligne"
- Alertes de monitoring

**Solutions :**

1. **Ajuster l'intervalle de heartbeat**
```python
HEARTBEAT_INTERVAL = 10  # Secondes (minimum 5)
```

2. **Monitorer les heartbeats**
```bash
python tools/mqtt_monitor.py --service-id votre-service --topic heartbeat
```

---

## 💾 Problèmes de performance

### Lenteur des réponses

**Symptômes :**
- Timeouts fréquents
- Réponses lentes

**Solutions :**

1. **Profiler le code**
```python
import cProfile
import time

@mcp_tool(name="slow.tool")
def slow_tool(self, data: dict) -> dict:
    start_time = time.time()
    try:
        # Votre logique
        result = self._process_data(data)
        return result
    finally:
        duration = time.time() - start_time
        if duration > 1.0:  # Log si > 1 seconde
            logger.warning(f"Outil lent: {duration:.2f}s")
```

2. **Optimiser les requêtes externes**
```python
import asyncio
import aiohttp

class OptimizedService(MCPMicroservice):
    async def _fetch_data_async(self, url: str):
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as response:
                return await response.json()
```

3. **Implémenter le cache**
```python
from functools import lru_cache
from datetime import datetime, timedelta

class CachedService(MCPMicroservice):
    def __init__(self):
        super().__init__()
        self._cache = {}
        self._cache_ttl = {}
    
    def _get_cached(self, key: str, ttl: int = 300):
        if key in self._cache:
            if datetime.now() < self._cache_ttl[key]:
                return self._cache[key]
            else:
                del self._cache[key]
                del self._cache_ttl[key]
        return None
    
    def _set_cache(self, key: str, value: any, ttl: int = 300):
        self._cache[key] = value
        self._cache_ttl[key] = datetime.now() + timedelta(seconds=ttl)
```

### Fuite mémoire

**Symptômes :**
- Utilisation mémoire croissante
- Service qui crash après un certain temps

**Solutions :**

1. **Monitorer la mémoire**
```python
import psutil
import gc

def _monitor_memory(self):
    process = psutil.Process()
    memory_mb = process.memory_info().rss / 1024 / 1024
    if memory_mb > 500:  # Seuil d'alerte
        logger.warning(f"Mémoire élevée: {memory_mb:.1f}MB")
        gc.collect()  # Forcer le garbage collection
```

2. **Limiter les caches**
```python
from collections import deque

class LimitedCache:
    def __init__(self, max_size: int = 1000):
        self.cache = {}
        self.access_order = deque(maxlen=max_size)
    
    def set(self, key: str, value: any):
        if len(self.cache) >= self.access_order.maxlen:
            oldest = self.access_order.popleft()
            del self.cache[oldest]
        
        self.cache[key] = value
        self.access_order.append(key)
```

---

## 🐳 Problèmes Docker

### Container qui ne démarre pas

**Symptômes :**
- Exit code 1 ou 125
- Erreurs dans docker logs

**Solutions :**

1. **Vérifier les logs**
```bash
docker logs container-name --tail 50
```

2. **Tester en interactif**
```bash
docker run -it --rm container-name /bin/bash
python main.py
```

3. **Vérifier les variables d'environnement**
```bash
docker exec container-name env | grep -E "(MQTT|SERVICE|API)"
```

### Problèmes de réseau Docker

**Symptômes :**
- Impossible de joindre le broker MQTT
- DNS ne résout pas

**Solutions :**

1. **Vérifier le réseau Docker**
```bash
docker network ls
docker network inspect mcp-network
```

2. **Tester la connectivité**
```bash
docker exec service-container ping mosquitto-container
docker exec service-container nc -zv mosquitto 1883
```

---

## 🔍 Outils de diagnostic

### Script de diagnostic complet

```bash
#!/bin/bash
# diagnostic.sh

echo "=== Diagnostic MCP ==="

echo "1. Configuration MQTT"
mosquitto_pub -h $MQTT_BROKER_HOST -p $MQTT_BROKER_PORT -t test/diagnostic -m "test" 2>&1

echo "2. Services actifs"
python tools/mqtt_monitor.py --list-services

echo "3. Validation des schémas"
python tools/validate_microservice.py $1

echo "4. Test de connectivité"
python tools/test_client.py --service-id $1 --method mcp.health_check

echo "5. Logs récents"
tail -20 logs/service.log

echo "=== Fin du diagnostic ==="
```

### Monitoring en temps réel

```bash
# Terminal 1: Surveiller tous les messages
python tools/mqtt_monitor.py --all-topics

# Terminal 2: Surveiller un service spécifique
python tools/mqtt_monitor.py --service-id votre-service --verbose

# Terminal 3: Tester les outils
python tools/test_client.py --service-id votre-service --interactive
```

---

## 📞 Support et ressources

### Logs à fournir en cas de problème

1. **Logs du microservice**
```bash
tail -100 logs/service.log
```

2. **Logs MQTT**
```bash
python tools/mqtt_monitor.py --service-id votre-service --duration 60 > mqtt_debug.log
```

3. **Configuration sanitisée**
```bash
env | grep -E "(MQTT|SERVICE)" | sed 's/API_KEY=.*/API_KEY=***/' > config_debug.txt
```

### Ressources utiles

- **Documentation officielle** : `docs/PRECONISATIONS.md`
- **Schémas de validation** : `schemas/`
- **Exemples complets** : `examples/`
- **Outils de diagnostic** : `tools/`

### Commandes de debug fréquentes

```bash
# Validation complète
python tools/validate_microservice.py votre_service.py

# Test de tous les outils
python tools/test_client.py --service-id votre-service --test-all

# Monitoring en temps réel
python tools/mqtt_monitor.py --service-id votre-service --real-time

# Nettoyage des caches
python -c "import votre_service; service = votre_service.VotreService(); service.clear_cache()"
```