# Guide de Simulation MQTT 🎮

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Ce guide explique comment utiliser l'environnement de simulation MQTT complet pour développer et tester votre application sans infrastructure réelle.

---

## 📑 Table des matières

1. [Introduction](#introduction)
2. [Architecture Simulation vs Production](#architecture-simulation-vs-production)
3. [Configuration du Broker](#configuration-du-broker)
4. [Microservices Virtuels](#microservices-virtuels)
5. [Messages Programmés](#messages-programmés)
6. [Scénarios de Test](#scénarios-de-test)
7. [Console de Debug](#console-de-debug)
8. [Export/Import](#exportimport)
9. [Bonnes Pratiques](#bonnes-pratiques)
10. [Voir aussi](#-voir-aussi)

---
## Introduction

L'environnement de simulation MQTT (accessible via `/mqtt-simulation`) permet de :
- **Développer sans infrastructure** : Aucun broker MQTT réel nécessaire
- **Tester des scénarios** : Simuler des situations normales, d'urgence ou de charge
- **Découverte automatique** : Les microservices virtuels publient des messages de découverte comme en production
- **Interactions complètes** : Pub/sub, heartbeats, commandes, réponses
- **Debugging avancé** : Console en temps réel pour observer tous les messages

## Architecture Simulation vs Production

### Mode Production (`/mqtt-config`)
```
Plateforme (React) ↔ Broker MQTT Réel (Mosquitto) ↔ Microservices Réels
```
- Configuration du broker externe
- Connexion WebSocket sécurisée
- Gestion des abonnements/publications réels

### Mode Simulation (`/mqtt-simulation`)
```
Plateforme (React) ↔ Broker de Simulation (JS) ↔ Microservices Virtuels
```
- Broker interne JavaScript
- Simulation de latence, perte de messages
- Découverte automatique des entités et microservices
- Messages programmés avec scheduler

**Important** : Quand la simulation est active, le menu "Simulation MQTT" devient rouge dans la sidebar.

## Microservices Virtuels

### Qu'est-ce qu'un microservice virtuel ?

Un microservice virtuel simule le comportement d'un microservice réel :
- Publication de messages MQTT périodiques
- Heartbeat pour indiquer l'état de santé
- Réponse aux commandes administratives
- Découverte automatique des entités

## Configuration du Broker

Accédez à l'onglet **Configuration** dans `/mqtt-simulation` pour configurer le comportement du broker simulé :

### Paramètres Disponibles

1. **Latence Réseau** (min/max en ms)
   - Simule des délais réseau réalistes
   - Exemple : 10-100ms pour un réseau local, 50-500ms pour Internet

2. **Taux de Perte de Messages** (0-50%)
   - Simule la perte de paquets réseau
   - 0% = aucune perte, 5% = conditions normales, 20% = réseau instable

3. **Quality of Service (QoS)** par défaut
   - QoS 0 : Au plus une fois (pas de garantie)
   - QoS 1 : Au moins une fois (acknowledge)
   - QoS 2 : Exactement une fois (handshake complet)

4. **Journalisation** : Active/désactive les logs détaillés

5. **Taille de l'Historique** : Nombre de messages conservés en mémoire (100-5000)

### Créer un microservice virtuel

#### À partir d'un Template

1. Accédez à `/mqtt-simulation`
2. Onglet **Microservices Virtuels**
3. Cliquez sur **Nouveau microservice**
4. Sélectionnez un template pré-configuré :
   - 🌤️ **Station Météo** : Température, humidité, vent, pression
   - 🐳 **Docker Monitoring** : État et stats des conteneurs
   - 💻 **System Monitor** : CPU, RAM, disque
   - ⚙️ **Microservice MCP Custom** : Template vide personnalisable

#### Configuration Avancée

Personnalisez votre microservice :

```json
{
  "name": "Mon Capteur Virtuel",
  "type": "sensor-service",
  "version": "1.0.0",
  "heartbeat": {
    "enabled": true,
    "interval": 30000,
    "topic": "microservices/sensor-service/heartbeat",
    "stability": 95
  },
  "entities": [...],
  "publications": [...],
  "adminCommands": [...]
}
```

**Paramètres importants** :
- `heartbeat.stability` : Probabilité que le service soit en ligne (0-100%)
- `heartbeat.interval` : Fréquence du heartbeat en millisecondes
- `publications` : Messages automatiques publiés périodiquement

### Gérer les Microservices Virtuels

#### Actions disponibles

- **Activer/Désactiver** : Switch pour démarrer/arrêter un microservice
- **Éditer** : Modifier la configuration complète
- **Dupliquer** : Créer une copie pour des tests A/B
- **Supprimer** : Retirer définitivement

#### Contrôles Globaux

- **Tout démarrer** : Active tous les microservices
- **Tout arrêter** : Désactive tous les microservices
- **Exporter** : Sauvegarder toute la configuration
- **Importer** : Charger une configuration existante

## Broker de Simulation

### Messages Planifiés

Le broker de simulation permet de planifier des messages MQTT :

#### Types de Planification

1. **Intervalle** : Publier régulièrement
   ```json
   {
     "topic": "home/temperature",
     "payload": "{\"value\": 22.5}",
     "schedule": { "type": "interval", "value": 5000 }
   }
   ```

2. **Une fois** : Publication unique à une date/heure
   ```json
   {
     "schedule": { "type": "once", "value": "2025-01-15T10:00:00Z" }
   }
   ```

3. **Cron** : Expression cron (avancé)
   ```json
   {
     "schedule": { "type": "cron", "value": "*/5 * * * *" }
   }
   ```

#### Configuration des Messages

- **Topic** : Chemin MQTT (ex: `home/living/light`)
- **Payload** : Contenu JSON ou texte
- **QoS** : Qualité de service (0, 1, 2)
- **Retain** : Conserver le dernier message
- **Description** : Note pour identifier le message

### Démarrer la Simulation

1. Configurez vos messages planifiés
2. Activez les messages souhaités (switch)
3. Cliquez sur **Démarrer**
4. Observez les logs en temps réel

## Scénarios de Test

### Scénarios Pré-configurés

#### 🌅 Journée Type
Simule une journée normale :
- Réveil (lumières, température)
- Activité diurne (présence, mouvements)
- Coucher (extinction progressive)

**Usage** : Tester les automations quotidiennes

#### 🔥 Alerte Incendie
Séquence d'urgence :
- Détection de fumée
- Activation alarmes
- Ouverture volets
- Notifications

**Usage** : Valider les procédures d'urgence

#### 🔍 Découverte Progressive
Ajout progressif d'appareils :
- Nouveau capteur toutes les 30s
- Différents types de devices
- Test de l'auto-discovery

**Usage** : Tester la découverte dynamique

#### ⚡ Charge Élevée
Test de performance :
- Messages haute fréquence (100ms)
- Plusieurs capteurs simultanés
- Agrégation de données

**Usage** : Stress test, optimisation

#### 🌤️ Météo Dynamique
Changements météo :
- Température variable
- Humidité, pression
- Tendances réalistes

**Usage** : Tester les automations météo

#### 🔋 Monitoring Énergie
Suivi énergétique :
- Consommation maison
- Production solaire
- État batterie

**Usage** : Tester la gestion d'énergie

### Charger un Scénario

1. Cliquez sur **Scénarios**
2. Parcourez les scénarios disponibles
3. Cliquez sur un scénario pour le charger
4. Les messages sont automatiquement ajoutés
5. Cliquez sur **Démarrer** pour lancer la simulation

### Créer un Scénario Personnalisé

1. Créez vos messages manuellement
2. Testez le scénario
3. Exportez la configuration
4. Partagez avec votre équipe

## Export/Import

### Exporter une Configuration

#### Microservices Virtuels
1. Bouton **Exporter** dans la section Microservices Virtuels
2. Fichier JSON téléchargé : `virtual-microservices-YYYY-MM-DD.json`

#### Broker de Simulation
1. Bouton **Exporter** dans la section Broker de Simulation
2. Fichier JSON téléchargé : `simulation-broker-YYYY-MM-DD.json`

### Importer une Configuration

1. Cliquez sur **Importer**
2. Sélectionnez le fichier JSON
3. Les éléments sont ajoutés (pas de remplacement)
4. Vérifiez la configuration importée

### Format des Fichiers

#### Microservices
```json
[
  {
    "id": "uuid",
    "name": "Mon Service",
    "type": "custom",
    "version": "1.0.0",
    "enabled": true,
    "heartbeat": {...},
    "entities": [...],
    "publications": [...],
    "adminCommands": [...]
  }
]
```

#### Messages Planifiés
```json
[
  {
    "id": "uuid",
    "topic": "test/topic",
    "payload": "{\"test\": true}",
    "schedule": { "type": "interval", "value": 5000 },
    "enabled": true,
    "qos": 0,
    "retain": false
  }
]
```

## Améliorations Réalistes

Pour rendre vos simulations plus réalistes, le système intègre :

### Variations Aléatoires

Les valeurs numériques varient légèrement :
```javascript
// Température avec ±5% de variation
{
  "temperature": 22.5  // → peut devenir 21.4 à 23.6
}
```

### Latence Réseau

Délai aléatoire simulant la latence :
- Min: 50ms
- Max: 200ms

### Taux d'Échec

Certaines opérations peuvent échouer :
- Success rate configurable (0-100%)
- Simule les timeouts, erreurs réseau

### Déconnexions Temporaires

Simule des pertes de connexion :
- Probabilité configurable
- Durée aléatoire (1-5 secondes)

### Utilisation dans le Code

```typescript
import { simulationEnhancer } from '@/services/simulationEnhancer';

// Variation de valeur
const temp = simulationEnhancer.addRandomVariation(22.5, 5);

// Latence
await simulationEnhancer.addNetworkLatency(50, 200);

// Test d'échec
if (!simulationEnhancer.simulateFailure(95)) {
  console.log('Échec simulé');
}

// Bruit sur JSON
const data = { temp: 22.5, humidity: 45 };
const noisyData = simulationEnhancer.addJsonNoise(data, 5);
```

## Debugging

### Console de Debug

La console affiche en temps réel :
- Messages publiés
- Messages reçus
- Erreurs
- Timestamp précis

#### Filtres
- Par type (publish/subscribe/receive)
- Par topic (recherche)
- Par période

#### Actions
- **Pause** : Figer l'affichage
- **Effacer** : Vider les logs
- **Exporter** : Sauvegarder les logs

### Logs du Scheduler

Consultez la console navigateur :
```
[Simulation Scheduler] Starting with 5 messages
[Simulation Scheduler] Publishing to home/temp: {"value": 22.5}
```

### Heartbeat Monitoring

Vérifiez l'état de santé :
```
✅ Microservice actif - heartbeat reçu
⚠️ Microservice instable - heartbeat intermittent (stability: 70%)
❌ Microservice arrêté - pas de heartbeat
```

## Bonnes Pratiques

### Développement

1. ✅ Commencez simple (1-2 microservices)
2. ✅ Utilisez des scénarios pré-configurés
3. ✅ Testez chaque fonctionnalité individuellement
4. ✅ Augmentez progressivement la complexité

### Tests

1. ✅ Créez un scénario par cas d'usage
2. ✅ Exportez vos configurations de test
3. ✅ Documentez vos scénarios
4. ✅ Testez les cas limites (charge, erreurs)

### Passage en Production

1. ✅ Validez tous les scénarios en simulation
2. ✅ Comparez simulation vs réalité
3. ✅ Conservez la simulation pour le debugging
4. ✅ Utilisez les mêmes topics en production

## Limitations

- Le scheduler utilise `setTimeout`/`setInterval` (pas de vrai cron)
- Pas de persistance des messages (pas de vrai broker)
- Latence simulée, pas réelle
- Pas de QoS réel (simplifié)

## Exemples d'Utilisation

### Test d'Automation

```json
{
  "scenario": "Test allumage automatique",
  "messages": [
    {
      "topic": "home/living/motion",
      "payload": "{\"motion\": true}",
      "schedule": { "type": "once", "value": "2025-01-15T18:00:00Z" }
    },
    {
      "topic": "home/living/light/expected",
      "payload": "{\"state\": \"ON\"}",
      "schedule": { "type": "once", "value": "2025-01-15T18:00:05Z" }
    }
  ]
}
```

### Test de Charge

```json
{
  "scenario": "100 messages/seconde",
  "messages": [
    {
      "topic": "perf/test/1",
      "schedule": { "type": "interval", "value": 10 }
    },
    // ... répéter pour 10 topics
  ]
}
```

## FAQ

**Q: Puis-je utiliser la simulation ET la production en même temps ?**
R: Oui, mais ce n'est pas recommandé car cela peut créer des conflits. Préférez tester en simulation puis basculer en production.

**Q: Les microservices virtuels consomment-ils beaucoup de ressources ?**
R: Non, ils sont très légers. Vous pouvez en exécuter des dizaines simultanément.

**Q: Comment reproduire un bug ?**
R: Exportez votre configuration au moment du bug, puis rechargez-la pour reproduire exactement la même situation.

**Q: Puis-je partager mes scénarios ?**
R: Oui, exportez-les en JSON et partagez les fichiers avec votre équipe.

## Conclusion

Le système de simulation est un outil puissant pour :
- Développer rapidement
- Tester exhaustivement
- Débugger efficacement
- Former et démontrer

N'hésitez pas à expérimenter et créer vos propres scénarios !

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide du Mode Simulation](guide-mode-simulation.md) - Activation du mode simulation
- [Guide de Production](guide-production.md) - Passage en production
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications
- [Guide des Sauvegardes](guide-sauvegardes.md) - Systèmes de sauvegarde
- [Structure JSON Microservices](microservice-json.md) - Format des configurations

---

_Documentation NeurHomIA_


## 📚 Voir aussi

- [Guide des Entités Calculées](guide-entites-calculees.md)
- [Guide Mode Simulation](guide-mode-simulation.md)
- [Guide Mode Simulation](guide-mode-simulation.md)
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md)
- [Guide de Production](guide-production.md)
- [Guide de Sauvegardes](guide-sauvegardes.md)
- [Guide de Simulation](guide-simulation.md)
- [Guide de Synchronisation GitHub](guide-synchronisation-github.md)

- [Structure JSON Microservices](microservice-json.md)
