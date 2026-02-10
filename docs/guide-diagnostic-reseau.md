# Guide du Diagnostic Réseau

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide documente le système de diagnostic réseau de NeurHomIA, accessible via la page `/network-diagnostics`. Il permet de surveiller la connectivité, mesurer les performances et recevoir des alertes automatiques en cas de problème.

---

## 📑 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Cibles de diagnostic](#cibles-de-diagnostic)
- [Types de tests](#types-de-tests)
- [Système d'alertes automatiques](#système-dalertes-automatiques)
- [Configuration des seuils](#configuration-des-seuils)
- [Intégration du Scheduler Python](#intégration-du-scheduler-python)
- [Historique et métriques](#historique-et-métriques)
- [Architecture technique](#architecture-technique)
- [Dépannage](#dépannage)

---

## Vue d'ensemble

La page de diagnostic réseau fournit une vue complète de la santé de l'infrastructure NeurHomIA :

- **Tests de connectivité** : HTTP, WebSocket et MQTT
- **Résolution DNS simulée** : Vérification des noms d'hôtes
- **Mesures de latence** : Temps de réponse en millisecondes
- **Alertes automatiques** : Notifications en cas de panne ou dégradation
- **Historique persistant** : Stocké dans `localStorage`

### Accès

La page est accessible aux administrateurs via :

```
/network-diagnostics
```

Ou depuis le menu latéral : **Paramètres > Diagnostic Réseau**

---

## Cibles de diagnostic

Le système teste deux types de cibles :

### Cibles fixes

Ces cibles sont toujours disponibles :

| Cible | Type | Description |
|-------|------|-------------|
| **Local Engine** | HTTP | Backend Node.js (`http://localhost:3001/health`) |
| **GitHub API** | HTTP | API GitHub (`https://api.github.com`) |
| **Connectivité Internet** | HTTP | Test de connectivité générale |

### Cibles dynamiques

Ces cibles sont détectées automatiquement selon la configuration :

| Cible | Type | Condition |
|-------|------|-----------|
| **Brokers MQTT** | WebSocket | Configurés dans le store `use-mqtt-brokers` |
| **Scheduler Python** | MQTT Status | Activé dans `useExecutionConfig` |

---

## Types de tests

### Test de connectivité HTTP

```typescript
// Vérifie qu'un endpoint HTTP répond
const result = await fetch(url, { 
  method: 'HEAD',
  signal: AbortSignal.timeout(5000)
});
```

**Statuts possibles** :
- ✅ `online` : Réponse HTTP 2xx
- ❌ `offline` : Timeout ou erreur réseau
- ⚠️ `degraded` : Réponse lente (> seuil configuré)

### Test de connectivité WebSocket

```typescript
// Vérifie la connexion WebSocket MQTT
const ws = new WebSocket(`ws://${host}:${port}`);
ws.onopen = () => { /* connecté */ };
ws.onerror = () => { /* échec */ };
```

Utilisé pour tester les brokers MQTT.

### Test de résolution DNS (simulé)

Vérifie que les noms d'hôtes sont résolvables en testant la connectivité vers l'adresse.

### Mesure de latence

La latence est mesurée comme le temps entre l'envoi de la requête et la réception de la réponse :

```typescript
const start = performance.now();
await fetch(url);
const latency = performance.now() - start;
```

---

## Système d'alertes automatiques

Le système d'alertes surveille en continu l'état des services et envoie des notifications.

### Types d'alertes

| Type | Icône | Description |
|------|-------|-------------|
| `down` | 🔴 | Service devenu indisponible |
| `recover` | 🟢 | Service rétabli après une panne |
| `high_latency` | 🟡 | Latence dépassant le seuil configuré |

### Configuration par service

Chaque cible peut être configurée individuellement :

```typescript
interface AlertConfig {
  enabled: boolean;           // Alertes activées
  latencyThreshold: number;   // Seuil de latence (ms)
  notifyOnDown: boolean;      // Notifier si offline
  notifyOnRecover: boolean;   // Notifier si rétabli
  notifyOnHighLatency: boolean; // Notifier si latence élevée
}
```

### Anti-spam (cooldown)

Pour éviter les notifications répétitives :

- **Délai configurable** : 5 minutes par défaut entre deux alertes du même type
- **Persistance** : L'état est stocké dans le store Zustand
- **Par service** : Chaque cible a son propre cooldown

---

## Configuration des seuils

### Seuils par défaut

| Service | Seuil de latence | Justification |
|---------|------------------|---------------|
| Local Engine | 500 ms | Backend local, doit être rapide |
| GitHub API | 2000 ms | API externe, latence variable |
| Brokers MQTT | 1000 ms | Communication temps réel |
| Scheduler Python | 120 s | Intervalle de heartbeat |

### Personnalisation

Via l'onglet **Alertes** de la page de diagnostic :

1. Sélectionner un service dans la liste
2. Activer/désactiver les types d'alertes
3. Ajuster le seuil de latence
4. Sauvegarder

---

## Intégration du Scheduler Python

Le Scheduler Python est un composant optionnel qui exécute les scénarios programmés.

### Détection automatique

Le système détecte le Scheduler via le store `useExecutionConfig` :

```typescript
const { schedulerEnabled } = useExecutionConfig();
if (schedulerEnabled) {
  // Ajouter le Scheduler aux cibles de diagnostic
}
```

### Test de connectivité MQTT

Contrairement aux autres cibles, le Scheduler est testé via MQTT :

1. **Topic surveillé** : `neurhomia/services/scheduler-service/heartbeat`
2. **Fréquence** : Heartbeat toutes les 30 secondes
3. **Latence** : Temps écoulé depuis le dernier heartbeat

### Informations affichées

```typescript
interface SchedulerStatus {
  lastHeartbeat: Date;        // Dernier signal reçu
  activeTasks: number;        // Scénarios actifs
  nextExecution: Date;        // Prochaine exécution programmée
  version: string;            // Version du Scheduler
}
```

---

## Historique et métriques

### Stockage

L'historique des tests est persisté dans `localStorage` :

```typescript
const STORAGE_KEY = 'neurhomia_diagnostics_history';
const MAX_ENTRIES = 1000; // Par cible
```

### Métriques calculées

Pour chaque cible, le système calcule :

| Métrique | Description |
|----------|-------------|
| `min` | Latence minimale observée |
| `max` | Latence maximale observée |
| `avg` | Moyenne arithmétique |
| `p95` | 95e percentile |
| `p99` | 99e percentile |

### Visualisation

L'onglet **Performance** affiche des graphiques Recharts :

- **Courbe de latence** : Évolution dans le temps
- **Distribution** : Histogramme des temps de réponse
- **Tendances** : Comparaison avec les périodes précédentes

### Export

Bouton **Exporter** pour télécharger l'historique en JSON :

```json
{
  "exportDate": "2026-01-27T10:30:00Z",
  "targets": [...],
  "history": [...],
  "stats": {...}
}
```

---

## Architecture technique

### Fichiers principaux

| Fichier | Rôle |
|---------|------|
| `src/pages/NetworkDiagnostics.tsx` | Page principale avec onglets |
| `src/hooks/useDiagnosticsRunner.ts` | Hook orchestrant les tests |
| `src/services/networkDiagnosticsService.ts` | Service de tests réseau |
| `src/services/diagnosticsAlertService.ts` | Service d'alertes |
| `src/store/use-diagnostics-alert-config.ts` | Configuration des alertes |

### Composants UI

| Composant | Description |
|-----------|-------------|
| `NetworkDiagnosticsHeader` | En-tête avec statut global |
| `DiagnosticsStatsCards` | Cartes de statistiques |
| `ConnectivityPanel` | Onglet connectivité |
| `PerformancePanel` | Onglet performance |
| `DnsResolutionPanel` | Onglet DNS |
| `DiagnosticsHistoryPanel` | Onglet historique |
| `AlertConfigPanel` | Onglet configuration alertes |

### Flux de données

```
┌─────────────────────────────────────────────────────────────┐
│                    NetworkDiagnostics                        │
│                         (Page)                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   useDiagnosticsRunner                       │
│                        (Hook)                                │
│  - Orchestration des tests                                   │
│  - Gestion de l'historique                                   │
│  - Calcul des statistiques                                   │
└─────────────────────────────────────────────────────────────┘
          │                              │
          ▼                              ▼
┌──────────────────────┐    ┌──────────────────────────────────┐
│ networkDiagnostics   │    │ diagnosticsAlertService          │
│      Service         │    │                                  │
│ - Tests HTTP/WS      │    │ - Comparaison états              │
│ - Mesures latence    │    │ - Envoi notifications            │
│ - Résolution DNS     │    │ - Gestion cooldown               │
└──────────────────────┘    └──────────────────────────────────┘
                                         │
                                         ▼
                            ┌──────────────────────────────────┐
                            │ use-diagnostics-alert-config     │
                            │           (Store)                │
                            │ - Seuils par service             │
                            │ - Préférences notifications      │
                            │ - Historique cooldown            │
                            └──────────────────────────────────┘
```

---

## Dépannage

### Le Local Engine ne répond pas

1. Vérifier que le conteneur Docker est démarré :
   ```bash
   docker ps | grep local-engine
   ```

2. Vérifier les logs :
   ```bash
   docker logs neurhomia-local-engine
   ```

3. Tester manuellement :
   ```bash
   curl http://localhost:3001/health
   ```

### Les brokers MQTT sont offline

1. Vérifier la configuration dans **Paramètres > Brokers MQTT**
2. S'assurer que le port WebSocket est ouvert (généralement 9001)
3. Tester avec un client MQTT externe (MQTT Explorer)

### Le Scheduler Python ne répond pas

1. Vérifier que le Scheduler est activé dans la configuration
2. Surveiller le topic MQTT :
   ```
   neurhomia/services/scheduler-service/heartbeat
   ```
3. Consulter les logs du Scheduler Python

### Les alertes ne fonctionnent pas

1. Vérifier que les alertes sont activées pour le service
2. Vérifier le cooldown (peut bloquer les alertes répétitives)
3. Vérifier les permissions de notification du navigateur

### L'historique ne se charge pas

1. Vérifier l'espace disponible dans `localStorage`
2. Effacer l'historique ancien via le bouton dédié
3. Réinitialiser via les DevTools (Application > Storage)

---

## Voir aussi

- [Guide du Local Engine](guide-local-engine.md)
- [Guide d'Intégration MQTT](guide-integration-mqtt.md)
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md)
- [Guide des Microservices](guide-microservices.md)

---

_Documentation NeurHomIA - Janvier 2026_
