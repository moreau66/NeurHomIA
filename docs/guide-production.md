# Guide de Production 🚀

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide vous accompagne dans la configuration et l'utilisation de votre application avec un broker MQTT de production.

---

L'application **démarre en mode PRODUCTION par défaut**.

Le mode simulation n'est activé que si vous l'activez manuellement via l'interface (menu "Simulation MQTT").

### Vérifier le Mode Actif

Plusieurs indicateurs vous permettent de savoir quel mode est actif :

1. **Badge dans la sidebar** :
   - 🟢 "Production" (vert) → Mode production actif
   - 🔴 "Simulation" (rouge) → Mode simulation actif
   - 🟡 "Pas de broker" (jaune) → Aucun broker configuré (fallback simulation)

2. **Menu "Simulation MQTT"** :
   - Badge rouge clignotant sur l'icône si le mode simulation est actif
   - Visible même quand la sidebar est réduite

3. **Logs de démarrage** (console navigateur) :
   - `[MQTT Service] 🔌 Mode: PRODUCTION`
   - `[MQTT Service] 🧪 Mode: SIMULATION`

4. **Console MQTT** :
   - Les messages indiquent "Production Service" ou "Simulation Service"

## 📑 Table des matières

- [Comportement par Défaut](#-comportement-par-défaut)
- [Pré-requis](#pré-requis)
- [Configuration du Broker MQTT](#configuration-du-broker-mqtt)
- [Sécurité](#sécurité)
- [Tests de Connexion](#tests-de-connexion)
- [Migration Progressive](#migration-progressive)
- [Monitoring et Logs](#monitoring-et-logs)
- [Checklist de Production](#checklist-de-production)
- [Troubleshooting](#troubleshooting)
- [Support](#support)
- [Ressources](#ressources)
- [Voir aussi](#-voir-aussi)

---

## ⚙️ Comportement par Défaut

L'application **démarre en mode PRODUCTION par défaut**.

Le mode simulation n'est activé que si vous l'activez manuellement via l'interface (menu "Simulation MQTT").

### Vérifier le Mode Actif

Plusieurs indicateurs vous permettent de savoir quel mode est actif :

1. **Badge dans la sidebar** :
   - 🟢 "Production" (vert) → Mode production actif
   - 🔴 "Simulation" (rouge) → Mode simulation actif
   - 🟡 "Pas de broker" (jaune) → Aucun broker configuré (fallback simulation)

2. **Menu "Simulation MQTT"** :
   - Badge rouge clignotant sur l'icône si le mode simulation est actif
   - Visible même quand la sidebar est réduite

3. **Logs de démarrage** (console navigateur) :
   - `[MQTT Service] 🔌 Mode: PRODUCTION`
   - `[MQTT Service] 🧪 Mode: SIMULATION`

4. **Console MQTT** :
   - Les messages indiquent "Production Service" ou "Simulation Service"

---

## Pré-requis

Avant de passer en production, assurez-vous d'avoir :

- ✅ Un broker MQTT configuré et accessible
- ✅ Les identifiants d'authentification (username/password)
- ✅ Les certificats TLS/SSL (recommandé pour la production)
- ✅ Les règles de pare-feu configurées
- ✅ Un plan de sauvegarde et de récupération

## Configuration du Broker MQTT

### 1. Variables d'Environnement

Créez un fichier `.env.local` avec les variables suivantes :

```bash
# ========================================
# Configuration MQTT PRODUCTION (REQUIS)
# ========================================
# URL du broker MQTT de production
# Formats supportés :
#   - WebSocket: ws://broker:9001 ou wss://broker:9001 (sécurisé)
#   - MQTT direct: mqtt://broker:1883 ou mqtts://broker:8883 (sécurisé)
# 
# ⚠️ IMPORTANT : L'application démarre en mode PRODUCTION par défaut
# Si non configuré, un warning s'affichera et l'app basculera en simulation
VITE_MQTT_BROKER_URL=wss://votre-broker.example.com:8883

# Authentification (fortement recommandé en production)
VITE_MQTT_USERNAME=votre_utilisateur
VITE_MQTT_PASSWORD=votre_mot_de_passe_securise
```

Le basculement simulation/production se fait via l'interface utilisateur.

### 2. Configuration dans l'Interface

1. Accédez à **Configuration MQTT**
2. Utilisez le composant **Mode de Fonctionnement MQTT**
3. Cliquez sur **Configurer le broker de production**
4. Renseignez :
   - URL du broker (format WebSocket : `ws://` ou `wss://`)
   - Nom d'utilisateur (optionnel)
   - Mot de passe (optionnel)
5. Sauvegardez la configuration
6. Basculez le switch vers **Production**

### 3. Formats d'URL Supportés

| Type | Format | Exemple | Usage |
|------|--------|---------|-------|
| WebSocket | `ws://host:port` | `ws://localhost:9001` | Développement |
| WebSocket Sécurisé | `wss://host:port` | `wss://broker.example.com:8883` | Production |
| MQTT classique | `mqtt://host:port` | `mqtt://localhost:1883` | Serveur uniquement |
| MQTT sécurisé | `mqtts://host:port` | `mqtts://broker.example.com:8883` | Serveur uniquement |

⚠️ **Important** : Pour les applications web, utilisez toujours `ws://` ou `wss://`.

## Sécurité

### TLS/SSL (Fortement Recommandé)

Pour une connexion sécurisée :

1. Utilisez `wss://` au lieu de `ws://`
2. Assurez-vous que votre broker supporte TLS
3. Vérifiez que les certificats sont valides

### Authentification

Configurez toujours une authentification :

```javascript
{
  username: "votre_utilisateur",
  password: "mot_de_passe_fort_et_unique"
}
```

### ACL (Access Control Lists)

Configurez les ACL sur votre broker Mosquitto :

```conf
# mosquitto.conf
acl_file /etc/mosquitto/acl.conf

# acl.conf
user application_user
topic read home/#
topic write home/commands/#
```

### Best Practices de Sécurité

1. ✅ Utilisez des mots de passe forts et uniques
2. ✅ Activez TLS/SSL en production
3. ✅ Limitez les permissions via ACL
4. ✅ Changez régulièrement les mots de passe
5. ✅ Utilisez des certificats clients pour l'authentification mutuelle
6. ✅ Surveillez les tentatives de connexion échouées
7. ✅ Isolez le broker dans un réseau privé si possible

## Tests de Connexion

### Test Manuel

1. Utilisez le bouton **Tester** dans la carte du broker
2. Vérifiez les logs de connexion
3. Testez la publication sur un topic de test
4. Testez la réception de messages

### Test Automatisé

Créez des messages de test dans le **Broker de Simulation** :

```json
{
  "topic": "test/connexion",
  "payload": "{\"test\": true, \"timestamp\": 1234567890}",
  "schedule": { "type": "once", "value": "2025-01-15T10:00:00Z" }
}
```

### Vérification des Logs

Consultez les logs dans :
- **Console de Debug** (onglet Simulation & Tests)
- **Monitoring API** (si configuré)
- Logs du broker MQTT côté serveur

## Migration Progressive

### Stratégie Recommandée

1. **Phase 1 : Test en parallèle**
   - Gardez la simulation active
   - Activez le broker de production
   - Comparez les résultats

2. **Phase 2 : Migration partielle**
   - Migrez les topics non-critiques d'abord
   - Surveillez attentivement
   - Validez le bon fonctionnement

3. **Phase 3 : Migration complète**
   - Migrez tous les topics
   - Désactivez la simulation
   - Monitoring intensif pendant 48h

### Rollback

En cas de problème :

1. Basculez immédiatement en mode **Simulation**
2. Analysez les logs d'erreur
3. Corrigez la configuration
4. Reprenez la migration

## Monitoring et Logs

### Configuration du Logging

Dans la configuration du broker :

```javascript
{
  logConnections: true,
  logSubscriptions: true,
  logMessages: true,
  logErrors: true,
  persistLogs: true,
  logRetentionDays: 30
}
```

### Métriques à Surveiller

- Taux de connexions réussies/échouées
- Latence moyenne des messages
- Nombre de messages par seconde
- Utilisation de la bande passante
- Erreurs de publication/souscription

### Alertes Recommandées

Configurez des alertes pour :
- Perte de connexion au broker
- Taux d'erreur > 5%
- Latence > 1 seconde
- Absence de heartbeat des microservices critiques

## Checklist de Production

### Avant le Déploiement

- [ ] Broker MQTT installé et configuré
- [ ] Certificats TLS/SSL valides
- [ ] Authentification configurée (username/password)
- [ ] ACL définies pour tous les utilisateurs
- [ ] Pare-feu configuré
- [ ] Tests de connexion réussis
- [ ] Monitoring configuré
- [ ] Alertes configurées
- [ ] Documentation à jour
- [ ] Plan de rollback défini

### Configuration Application

- [ ] Variables d'environnement configurées
- [ ] Mode production activé
- [ ] URL du broker correcte (wss://)
- [ ] Identifiants renseignés
- [ ] Topics correctement mappés
- [ ] QoS approprié pour chaque topic
- [ ] Retain configuré si nécessaire

### Après le Déploiement

- [ ] Vérifier la connexion au broker
- [ ] Tester la publication de messages
- [ ] Tester la réception de messages
- [ ] Vérifier les logs (pas d'erreurs)
- [ ] Monitoring actif pendant 48h
- [ ] Performance acceptable
- [ ] Sauvegarde de la configuration

### En Continu

- [ ] Monitoring quotidien
- [ ] Sauvegarde hebdomadaire de la configuration
- [ ] Mise à jour mensuelle des certificats si nécessaire
- [ ] Audit trimestriel de sécurité
- [ ] Revue semestrielle de l'architecture

---

## ⚡ Déploiement du Local Engine

Le **Local Engine** est un backend Node.js alternatif pour l'exécution locale des scénarios.

### Docker Compose

Ajoutez le service dans votre `docker-compose.yml` :

```yaml
services:
  local-engine:
    build:
      context: ./backend/local-engine
      dockerfile: Dockerfile
    container_name: neurhomia-local-engine
    restart: unless-stopped
    environment:
      - MQTT_BROKER_HOST=mosquitto
      - MQTT_BROKER_PORT=1883
      - HTTP_PORT=3001
      - LOG_LEVEL=info
      - LATITUDE=48.8566
      - LONGITUDE=2.3522
    ports:
      - "3001:3001"
    networks:
      - mcp-network
    depends_on:
      - mosquitto
```

### Variables d'environnement Production

| Variable | Défaut | Description |
|----------|--------|-------------|
| `MQTT_BROKER_HOST` | localhost | Hôte du broker MQTT |
| `MQTT_BROKER_PORT` | 1883 | Port du broker MQTT |
| `HTTP_PORT` | 3001 | Port de l'API HTTP |
| `LOG_LEVEL` | info | Niveau de log (`debug`, `info`, `warn`, `error`) |
| `LATITUDE` | 48.8566 | Latitude pour calculs astronomiques |
| `LONGITUDE` | 2.3522 | Longitude pour calculs astronomiques |

### Configuration Frontend

Dans l'interface NeurHomIA :

1. Accédez à **Configuration** → **API**
2. Dans **Backends d'Exécution**, configurez l'URL : `http://localhost:3001`
3. Activez le Local Engine
4. Configurez le fallback si nécessaire

### Monitoring MQTT

Topics de statut du Local Engine :

| Topic | Description |
|-------|-------------|
| `neurhomia/local-engine/status` | `online` / `offline` |
| `neurhomia/local-engine/heartbeat` | Heartbeat toutes les 10s |
| `neurhomia/local-engine/scenarios/status` | Statistiques des scénarios |
| `neurhomia/local-engine/scenarios/executed` | Événement d'exécution |
| `neurhomia/local-engine/scenarios/error` | Événement d'erreur |

📚 **Documentation complète** : [Guide du Local Engine](guide-local-engine.md)

---

## Troubleshooting

### Problème : Connexion échouée

**Solutions** :
1. Vérifiez l'URL du broker (format correct ?)
2. Vérifiez les identifiants
3. Vérifiez que le broker est accessible (pare-feu)
4. Testez avec un client MQTT externe (MQTT Explorer)

### Problème : Messages non reçus

**Solutions** :
1. Vérifiez la souscription aux topics
2. Vérifiez le QoS
3. Vérifiez les ACL sur le broker
4. Testez avec un topic simple

### Problème : Déconnexions fréquentes

**Solutions** :
1. Augmentez `keepAliveInterval`
2. Réduisez `reconnectPeriod`
3. Vérifiez la stabilité réseau
4. Vérifiez les limites du broker (max clients)

## Support

Pour toute question ou problème :

1. Consultez les logs de l'application
2. Consultez les logs du broker
3. Testez avec le mode simulation
4. Contactez le support technique

## Ressources

- [Documentation Mosquitto](https://mosquitto.org/documentation/)
- [MQTT Specification](https://mqtt.org/mqtt-specification/)
- [TLS/SSL Best Practices](https://mosquitto.org/man/mosquitto-tls-7.html)
- [MQTT Security Fundamentals](https://www.hivemq.com/mqtt-security-fundamentals/)

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Développement](guide-developpement.md) - Contribuer au projet
- [Guide du Mode Simulation](guide-mode-simulation.md) - Test sans infrastructure
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications
- [Guide des Sauvegardes](guide-sauvegardes.md) - Systèmes de sauvegarde
- [Préconisations Architecture MCP](guide-preconisations.md) - Standards microservices

---

_Documentation NeurHomIA_
