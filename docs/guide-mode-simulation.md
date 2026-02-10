# Guide du Mode Simulation 🧪

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide vous explique comment et quand utiliser le mode simulation de l'application MQTT.

---

## 📑 Table des matières

- [Qu'est-ce que le Mode Simulation ?](#-quest-ce-que-le-mode-simulation-)
- [Quand Utiliser le Mode Simulation ?](#-quand-utiliser-le-mode-simulation-)
- [Activation du Mode Simulation](#-activation-du-mode-simulation)
- [Indicateurs Visuels](#-indicateurs-visuels-du-mode-actif)
- [Fonctionnalités](#-fonctionnalités-du-mode-simulation)
- [Configuration Avancée](#-configuration-avancée)
- [Basculer entre Modes](#-basculer-entre-simulation-et-production)
- [Logs et Debugging](#-logs-et-debugging)
- [Bonnes Pratiques](#-bonnes-pratiques)
- [Comportement par Défaut](#-comportement-par-défaut)
- [Support](#-support)
- [Voir aussi](#-voir-aussi)

---

## 🎯 Qu'est-ce que le Mode Simulation ?

Le mode simulation est un environnement de test intégré qui simule un broker MQTT complet directement dans votre navigateur. Il vous permet de développer et tester votre application sans avoir besoin d'infrastructure MQTT externe.

## 📋 Quand Utiliser le Mode Simulation ?

### ✅ Utilisations Recommandées

- **Développement** : Développer de nouvelles fonctionnalités sans dépendances externes
- **Tests** : Valider des scénarios complexes et des cas limites
- **Démonstration** : Présenter l'application à des clients sans infrastructure réelle
- **Formation** : Apprendre le protocole MQTT et tester des configurations
- **Prototypage** : Tester rapidement des idées avant l'implémentation production

### ❌ Limitations

- Pas de persistance des messages après rechargement de la page
- Performance limitée par le navigateur (recommandé < 1000 messages/seconde)
- Pas de connexion réseau réelle
- Le scheduler utilise `setTimeout`/`setInterval` (moins précis qu'un broker réel)

## 🔄 Activation du Mode Simulation

### Méthode 1 : Via l'Interface (Recommandée)

1. **Connectez-vous** en tant qu'administrateur
2. Accédez au menu **Simulation MQTT** (icône de fiole dans la sidebar)
3. Activez le switch **"Mode Simulation"** en haut de la page
4. Un badge rouge **"Simulation"** apparaît dans le header de la sidebar

### Méthode 2 : Automatique (Fallback)

Si aucun broker de production n'est configuré (`VITE_MQTT_BROKER_URL` vide), l'application :

1. Affiche un warning dans la console : `⚠️ No production broker configured`
2. Bascule automatiquement en mode simulation
3. Affiche un badge jaune **"Pas de broker"** dans la sidebar

## 📊 Indicateurs Visuels du Mode Actif

### Dans la Sidebar

| Indicateur                     | Mode       | Description                                    |
| ------------------------------ | ---------- | ---------------------------------------------- |
| 🟢 Badge vert "Production"     | Production | Connecté au broker réel                        |
| 🔴 Badge rouge "Simulation"    | Simulation | Mode simulation actif                          |
| 🟡 Badge jaune "Pas de broker" | Fallback   | Pas de broker configuré, simulation par défaut |

### Menu "Simulation MQTT"

Quand le mode simulation est actif :

- **Sidebar ouverte** : Fond rouge avec texte blanc
- **Sidebar réduite** : Badge rouge clignotant sur l'icône de fiole
- **Tooltip** : "⚠️ Mode actif" au survol

### Dans la Console Navigateur

```javascript
[MQTT Service] 🧪 Mode: SIMULATION
[Simulation Broker] Initial state: SIMULATION
[AppInitializer] Simulation mode active, starting periodic data simulation
```

## 🛠️ Fonctionnalités du Mode Simulation

### 1. Microservices Virtuels

Créez des microservices qui simulent des comportements réels :

- **Heartbeats périodiques** : Vérification de l'état de santé
- **Publication de données** : Température, humidité, statuts...
- **Commandes administratives** : Arrêt, redémarrage, configuration
- **Discovery automatique** : Publication de schémas JSON pour l'auto-découverte

**Accès** : Onglet "Virtual Microservices" dans `/mqtt-simulation`

### 2. Messages Programmés

Planifiez l'envoi de messages MQTT avec différents types de programmation :

| Type         | Description                       | Exemple                       |
| ------------ | --------------------------------- | ----------------------------- |
| **Interval** | Répétitif toutes les X secondes   | Toutes les 5s                 |
| **Once**     | Une seule fois à une date précise | Le 15/01/2025 à 10h           |
| **Cron**     | Expression cron avancée           | `0 */6 * * *` (toutes les 6h) |

**Accès** : Onglet "Configuration" dans `/mqtt-simulation`

### 3. Scénarios Pré-configurés

Chargez des scénarios de test prêts à l'emploi :

- **Journée Typique** : Simulation d'une journée normale
- **Alerte Incendie** : Test de gestion d'urgence
- **Charge Élevée** : Test de performance
- **Panne Réseau** : Simulation de déconnexions

**Accès** : Onglet "Scenarios" dans `/mqtt-simulation`

### 4. Amélioration Réaliste

Le service `simulationEnhancer` ajoute du réalisme :

```typescript
import { simulationEnhancer } from '@/services/simulationEnhancer';

// Ajouter des variations aléatoires
const value = simulationEnhancer.addRandomVariation(20.5, { variation: 0.5 });
// Résultat : entre 20.0 et 21.0

// Simuler une latence réseau
await simulationEnhancer.simulateNetworkLatency();

// Simuler une panne occasionnelle
const shouldFail = simulationEnhancer.shouldSimulateFailure(0.1); // 10% de chance
```

## 🔧 Configuration Avancée

### Exporter/Importer une Configuration

**Export** :

```javascript
// Depuis l'interface : bouton "Exporter" dans l'onglet Configuration
// Télécharge un fichier JSON avec tous les messages programmés
```

**Import** :

```javascript
// Depuis l'interface : bouton "Importer" dans l'onglet Configuration
// Charge les messages depuis un fichier JSON
```

### Format de Configuration

```json
{
  "scheduledMessages": [
    {
      "id": "unique-id",
      "topic": "home/sensors/temperature",
      "payload": "{\"value\": 22.5, \"unit\": \"°C\"}",
      "qos": 0,
      "retain": false,
      "enabled": true,
      "schedule": {
        "type": "interval",
        "value": 5
      },
      "description": "Température du salon"
    }
  ]
}
```

## 🔄 Basculer entre Simulation et Production

### De Simulation vers Production

1. Assurez-vous que `VITE_MQTT_BROKER_URL` est configuré
2. Allez dans **Simulation MQTT**
3. Désactivez le switch **"Mode Simulation"**
4. Vérifiez le badge vert **"Production"** dans la sidebar

**⚠️ Note** : Les messages programmés et microservices virtuels sont automatiquement désactivés en production.

### De Production vers Simulation

1. Allez dans **Simulation MQTT**
2. Activez le switch **"Mode Simulation"**
3. Vérifiez le badge rouge **"Simulation"** dans la sidebar
4. Les microservices virtuels et messages programmés redeviennent actifs

## 📝 Logs et Debugging

### Console de Simulation

Accessible dans l'onglet "Messages" de `/mqtt-simulation` :

- **Temps réel** : Affichage instantané des messages publiés/reçus
- **Filtrage** : Par topic, type, ou contenu
- **Actions** : Copier, supprimer, rééditer

### Logs Navigateur

Les logs détaillés sont disponibles dans la console du navigateur :

```javascript
[MQTT Simulation] Connected successfully
[MQTT Simulation] Publishing to home/test: {"test": true}
[MQTT Simulation] Message routed to 2 subscribers
```

### Monitoring des Microservices

Vérifiez l'état de santé des microservices virtuels :

- **Heartbeat** : Dernier battement de cœur reçu
- **Statut** : Actif / Inactif / Erreur
- **Messages** : Nombre de messages publiés

## 🚀 Bonnes Pratiques

### Développement

1. ✅ Commencez toujours par le mode simulation
2. ✅ Créez des scénarios de test pour chaque fonctionnalité
3. ✅ Testez les cas limites (panne, latence, charge)
4. ✅ Validez la découverte automatique avec des microservices virtuels

### Tests

1. ✅ Utilisez des topics dédiés aux tests (`test/...`)
2. ✅ Créez des scénarios reproductibles
3. ✅ Documentez vos configurations de test
4. ✅ Exportez les configurations pour partage avec l'équipe

### Transition vers Production

1. ✅ Testez en parallèle (simulation + production)
2. ✅ Comparez les résultats
3. ✅ Migrez progressivement les topics
4. ✅ Gardez la simulation disponible pour les tests futurs

## ⚠️ Comportement par Défaut

**Rappel Important** : Depuis la version 2.0, l'application **démarre en mode production par défaut**.

- Si `VITE_MQTT_BROKER_URL` est configuré → Mode **Production**
- Si `VITE_MQTT_BROKER_URL` est vide → Fallback **Simulation** (avec warning)
- Activation manuelle de la simulation → Mode **Simulation**

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Production](guide-production.md) - Configuration du broker MQTT réel
- [Guide de Simulation](guide-simulation.md) - Fonctionnalités avancées de simulation
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications
- [Préconisations Architecture MCP](guide-preconisations.md) - Standards microservices

---

## 🆘 Support

### Problèmes Courants

**Q : Le mode simulation ne s'active pas**

- Vérifiez que vous êtes bien administrateur
- Rechargez la page après activation
- Vérifiez la console pour les erreurs

**Q : Les messages ne sont pas publiés**

- Vérifiez que le mode simulation est bien actif (badge rouge)
- Vérifiez que les messages programmés sont activés (enabled: true)
- Consultez l'onglet "Messages" pour les logs

**Q : Perte de configuration après rechargement**

- Les messages programmés sont sauvegardés automatiquement
- Les microservices virtuels doivent être exportés manuellement
- Utilisez l'export/import pour sauvegarder vos configurations

### Aide Supplémentaire

Pour toute question ou problème :

1. Consultez les logs de la console navigateur
2. Vérifiez le badge de statut dans la sidebar
3. Testez avec un scénario simple
4. Contactez le support technique

---

_Documentation NeurHomIA_
