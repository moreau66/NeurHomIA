# Guide des Notifications 🔔

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Ce guide décrit le système de notifications de NeurHomIA : niveaux de sévérité, catégories thématiques, centre de notifications et utilisation dans le code.

---

## 📑 Table des matières

1. [Introduction](#1-introduction)
2. [Architecture du Système](#2-architecture-du-système)
3. [Niveaux de Notifications](#3-niveaux-de-notifications)
4. [Catégories de Notifications](#4-catégories-de-notifications)
5. [Structure d'une Notification](#5-structure-dune-notification)
6. [Centre de Notifications (UI)](#6-centre-de-notifications-ui)
7. [Utilisation dans le Code](#7-utilisation-dans-le-code)
8. [Intégration Watchtower](#8-intégration-watchtower)
9. [Notifications des Widgets](#9-notifications-des-widgets)
10. [Persistance et Stockage](#10-persistance-et-stockage)
11. [Bonnes Pratiques](#11-bonnes-pratiques)
12. [Dépannage](#12-dépannage)

---

## 1. Introduction

Le système de notifications de NeurHomIA permet de :

- **Informer** l'utilisateur des événements importants
- **Alerter** en cas de problèmes ou d'erreurs
- **Historiser** les événements pour consultation ultérieure
- **Catégoriser** les notifications par source (Docker, MQTT, etc.)

> **Différence avec les Toasts** : Les notifications sont persistantes et consultables dans le centre de notifications, contrairement aux toasts Sonner qui disparaissent après quelques secondes.

---

## 2. Architecture du Système

### Flux des notifications

```
notificationService.ts     → Service centralisé (hors React)
       ↓
use-notifications.ts       → Store Zustand (persisté localStorage)
       ↓
useNotifications.ts        → Hook interface simplifiée (React)
       ↓
NotificationCenter.tsx     → UI de consultation (navbar)
```

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `src/types/notifications.ts` | Interfaces TypeScript (Notification, NotificationLevel, etc.) |
| `src/store/use-notifications.ts` | Store Zustand avec persistance localStorage |
| `src/hooks/useNotifications.ts` | Hook d'accès simplifié pour les composants |
| `src/services/notificationService.ts` | Service centralisé + intégration Watchtower |
| `src/components/layout/NotificationCenter.tsx` | Interface utilisateur (centre de notifications) |

### Diagramme d'architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Composants React                          │
│  ┌─────────────────┐  ┌─────────────────────────────────┐  │
│  │ NotificationCenter │ │ Autres composants (via hook)    │  │
│  └────────┬────────┘  └────────────────┬────────────────┘  │
│           │                             │                    │
│           ▼                             ▼                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           useNotifications (hook)                    │   │
│  └────────────────────────┬────────────────────────────┘   │
└───────────────────────────┼─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              use-notifications (Store Zustand)              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ notifications[], unreadCount, addNotification(), ... │   │
│  └─────────────────────────────────────────────────────┘   │
│                            ▲                                │
│                            │                                │
│  ┌─────────────────────────┴───────────────────────────┐   │
│  │          notificationService (hors React)            │   │
│  │  - addNotification(), addDockerNotification(), ...   │   │
│  │  - Intégration Watchtower                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    localStorage
              (clé: notifications-storage)
```

---

## 3. Niveaux de Notifications

### Les 4 niveaux de sévérité

| Niveau | Icône | Couleur | Usage |
|--------|-------|---------|-------|
| `info` | ℹ️ Info | Bleu | Information générale, état, événement neutre |
| `success` | ✅ CheckCircle | Vert | Opération réussie, confirmation |
| `warning` | ⚠️ AlertTriangle | Jaune/Orange | Attention requise, dégradation |
| `error` | ❌ XCircle | Rouge | Erreur, échec, action requise |

### Type TypeScript

```typescript
// src/types/notifications.ts
export type NotificationLevel = "info" | "success" | "warning" | "error";
```

### Classes CSS par niveau

```typescript
const levelColors: Record<NotificationLevel, string> = {
  info: "bg-blue-500/10 text-blue-600 border-blue-200 dark:text-blue-400",
  success: "bg-green-500/10 text-green-600 border-green-200 dark:text-green-400",
  warning: "bg-yellow-500/10 text-yellow-600 border-yellow-200 dark:text-yellow-400",
  error: "bg-red-500/10 text-red-600 border-red-200 dark:text-red-400",
};
```

### Icônes par niveau

```typescript
import { Info, CheckCircle, AlertTriangle, XCircle } from "lucide-react";

const levelIcons: Record<NotificationLevel, LucideIcon> = {
  info: Info,
  success: CheckCircle,
  warning: AlertTriangle,
  error: XCircle,
};
```

---

## 4. Catégories de Notifications

### Les 5 catégories thématiques

| Catégorie | Label UI | Description | Sources typiques |
|-----------|----------|-------------|------------------|
| `system` | Système | Événements généraux de l'application | Démarrage, configuration, mises à jour |
| `docker` | Docker | Conteneurs, images, Watchtower | Déploiement, arrêt, mises à jour containers |
| `mqtt` | MQTT | Connexions, messages, brokers | Connexion broker, erreurs de publication |
| `auth` | Authentification | Connexions, sessions, utilisateurs | Login, logout, expiration session |
| `automation` | Automation | Scénarios, déclencheurs, actions | Exécution scénarios, erreurs triggers |

### Type TypeScript

```typescript
// src/types/notifications.ts
export type NotificationCategory = "system" | "docker" | "mqtt" | "auth" | "automation";
```

### Labels localisés

```typescript
const categoryLabels: Record<NotificationCategory, string> = {
  system: "Système",
  docker: "Docker",
  mqtt: "MQTT",
  auth: "Authentification",
  automation: "Automation",
};
```

### Icônes par catégorie

```typescript
import { Settings, Container, Radio, Shield, Zap } from "lucide-react";

const categoryIcons: Record<NotificationCategory, LucideIcon> = {
  system: Settings,
  docker: Container,
  mqtt: Radio,
  auth: Shield,
  automation: Zap,
};
```

---

## 5. Structure d'une Notification

### Interface principale

```typescript
// src/types/notifications.ts
export interface Notification {
  id: string;                      // UUID généré automatiquement (uuidv4)
  title: string;                   // Titre court et descriptif
  message: string;                 // Message détaillé
  level: NotificationLevel;        // Sévérité : info | success | warning | error
  category: NotificationCategory;  // Catégorie : system | docker | mqtt | auth | automation
  timestamp: number;               // Date de création en millisecondes (Date.now())
  read: boolean;                   // État lu/non-lu
  source?: string;                 // Source optionnelle (nom du service)
  actions?: NotificationAction[];  // Actions cliquables optionnelles
}
```

### Interface des actions

```typescript
export interface NotificationAction {
  label: string;                        // Texte du bouton
  action: () => void;                   // Callback à exécuter
  variant?: "default" | "destructive";  // Style du bouton
}
```

### Exemple de notification complète

```typescript
const notification: Notification = {
  id: "550e8400-e29b-41d4-a716-446655440000",
  title: "Conteneur démarré",
  message: "Le conteneur mosquitto a été démarré avec succès sur le port 1883.",
  level: "success",
  category: "docker",
  timestamp: 1705680000000,
  read: false,
  source: "DockerService",
  actions: [
    {
      label: "Voir les logs",
      action: () => navigateToContainerLogs("mosquitto"),
      variant: "default",
    },
    {
      label: "Arrêter",
      action: () => stopContainer("mosquitto"),
      variant: "destructive",
    },
  ],
};
```

---

## 6. Centre de Notifications (UI)

### Composant `NotificationCenter`

Le centre de notifications est accessible via l'icône cloche 🔔 dans la navbar.

### Fonctionnalités

| Fonctionnalité | Description |
|----------------|-------------|
| **Badge compteur** | Affiche le nombre de notifications non-lues |
| **Recherche** | Filtrage textuel sur titre et message |
| **Filtres catégorie** | Boutons pour filtrer par catégorie (Système, Docker, etc.) |
| **Filtres niveau** | Boutons pour filtrer par sévérité (Info, Erreur, etc.) |
| **Vue liste** | Liste scrollable des notifications |
| **Vue détail** | Affichage complet d'une notification sélectionnée |
| **Navigation** | Boutons précédent/suivant entre notifications |
| **Marquage lu** | Individuel ou global ("Tout marquer comme lu") |
| **Suppression** | Individuelle ou en lot (notifications filtrées) |

### Comportements automatiques

- **Auto-sélection** : La première notification non-lue est sélectionnée à l'ouverture
- **Marquage automatique** : Une notification est marquée comme lue quand elle est affichée
- **Formatage temporel** : Affichage relatif ("5m", "2h", "3j", "1sem")
- **Responsive** : Vue adaptée mobile (liste seule) et desktop (liste + détail)

### Structure de l'interface

```
┌────────────────────────────────────────────────────────────┐
│  Centre de notifications                           [X]     │
├────────────────────────────────────────────────────────────┤
│  🔍 Rechercher...                                          │
│  ┌──────┬──────┬──────┬──────┬──────┬──────┐              │
│  │ Tous │System│Docker│ MQTT │ Auth │ Auto │              │
│  └──────┴──────┴──────┴──────┴──────┴──────┘              │
│  ┌──────┬──────┬──────┬──────┐                            │
│  │ Tous │ Info │ Warn │Error │                            │
│  └──────┴──────┴──────┴──────┘                            │
├────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌────────────────────────────┐  │
│  │ • Conteneur démarré │  │ Conteneur démarré          │  │
│  │   Docker • 5m       │  │ ✅ success • docker        │  │
│  ├─────────────────────┤  │                            │  │
│  │   Connexion MQTT    │  │ Le conteneur mosquitto     │  │
│  │   MQTT • 2h         │  │ a été démarré avec succès  │  │
│  ├─────────────────────┤  │ sur le port 1883.          │  │
│  │   Erreur scénario   │  │                            │  │
│  │   Automation • 1j   │  │ Source: DockerService      │  │
│  └─────────────────────┘  │ Il y a 5 minutes           │  │
│                           │                            │  │
│                           │ [Voir logs] [Arrêter]      │  │
│                           └────────────────────────────┘  │
├────────────────────────────────────────────────────────────┤
│  [Tout marquer lu]              [◄ Préc] [Suiv ►]         │
│                                          [Effacer (3)]    │
└────────────────────────────────────────────────────────────┘
```

---

## 7. Utilisation dans le Code

### Via le Hook `useNotifications` (recommandé dans React)

```typescript
import { useNotifications } from "@/hooks/useNotifications";

const MyComponent = () => {
  const { 
    // Créateurs par niveau
    notifySuccess, 
    notifyError, 
    notifyWarning, 
    notifyInfo,
    // Créateurs par catégorie
    notifyDocker,
    notifyMqtt,
    notifyAuth,
    notifyAutomation,
    notifySystem,
    // Méthode générique
    notify,
    // État
    notifications,
    unreadCount,
    // Actions
    markAsRead,
    markAllAsRead,
    removeNotification,
    clearAll,
  } = useNotifications();

  // Notification par niveau
  const handleSuccess = () => {
    notifySuccess("Opération réussie", "Les données ont été sauvegardées.", "system");
  };

  // Notification par catégorie
  const handleDockerEvent = () => {
    notifyDocker("Conteneur arrêté", "nginx a été arrêté.", "warning");
  };

  // Notification générique
  const handleGeneric = () => {
    notify("Titre", "Message détaillé", "info", "mqtt");
  };

  return (
    <div>
      <span>Notifications non-lues : {unreadCount}</span>
      <button onClick={handleSuccess}>Succès</button>
      <button onClick={markAllAsRead}>Tout marquer lu</button>
    </div>
  );
};
```

### Via le Service `notificationService` (hors React)

```typescript
import { notificationService } from "@/services/notificationService";

// Dans un service, une fonction utilitaire, etc.
class DockerService {
  async startContainer(name: string) {
    try {
      await this.docker.start(name);
      notificationService.addDockerNotification(
        "Conteneur démarré",
        `${name} a été démarré avec succès.`,
        "success"
      );
    } catch (error) {
      notificationService.addDockerNotification(
        "Échec du démarrage",
        `Impossible de démarrer ${name}: ${error.message}`,
        "error"
      );
    }
  }
}

// Méthodes disponibles
notificationService.addNotification(title, message, level, category, source?);
notificationService.addDockerNotification(title, message, level);
notificationService.addMqttNotification(title, message, level);
notificationService.addAuthNotification(title, message, level);
notificationService.addAutomationNotification(title, message, level);
notificationService.addSystemNotification(title, message, level);
```

### Accès direct au Store Zustand

```typescript
import { useNotifications } from "@/store/use-notifications";

// Lecture de l'état (hors composant React)
const state = useNotifications.getState();
const allNotifications = state.notifications;
const dockerNotifs = state.getNotificationsByCategory("docker");
const unread = state.getUnreadNotifications();

// Modifications
useNotifications.getState().addNotification({
  title: "Test",
  message: "Message de test",
  level: "info",
  category: "system",
});

useNotifications.getState().markAllAsRead();
```

---

## 8. Intégration Watchtower

### Événements surveillés

Le `notificationService` s'abonne automatiquement aux événements Watchtower pour les mises à jour de conteneurs Docker :

| Événement Watchtower | Titre notification | Niveau |
|---------------------|-------------------|--------|
| `update_available` | "Mise à jour disponible" | `info` |
| `updating` | "Mise à jour en cours" | `info` |
| `updated` | "Mise à jour terminée" | `success` |
| `update_failed` | "Échec de la mise à jour" | `error` |
| `no_update` | "Aucune mise à jour" | `info` |

### Exemple de notification Watchtower

```
[Docker] Mise à jour terminée
nginx:latest a été mis à jour vers la version 1.25.3

Source: Watchtower
Catégorie: docker
Niveau: success
```

### Configuration Watchtower

Les notifications Watchtower sont automatiquement intégrées lorsque le service Watchtower est configuré. Voir le guide Docker pour plus de détails sur la configuration de Watchtower.

---

## 9. Notifications des Widgets

### Interface `NotificationSettings`

Les widgets dynamiques ont leurs propres paramètres de notifications :

```typescript
// src/types/dynamic-widgets.ts
interface NotificationSettings {
  enabled: boolean;        // Notifications activées/désactivées
  types: {
    newWidgets: boolean;   // Nouveaux widgets découverts
    updates: boolean;      // Mises à jour de widgets
    errors: boolean;       // Erreurs de widgets
    timeouts: boolean;     // Timeouts de découverte
    success: boolean;      // Opérations réussies
  };
}
```

### Valeurs par défaut

```typescript
const DEFAULT_NOTIFICATION_SETTINGS: NotificationSettings = {
  enabled: true,
  types: {
    newWidgets: true,   // ✅ Activé
    updates: true,      // ✅ Activé
    errors: true,       // ✅ Activé
    timeouts: true,     // ✅ Activé
    success: false,     // ❌ Désactivé (évite le spam)
  },
};
```

### Stockage

Les paramètres de notifications des widgets sont stockés dans localStorage avec la clé `widget-notification-settings`.

```typescript
// Lecture
const settings = JSON.parse(localStorage.getItem("widget-notification-settings") || "null");

// Écriture
localStorage.setItem("widget-notification-settings", JSON.stringify(settings));
```

---

## 10. Persistance et Stockage

### Store Zustand avec middleware `persist`

```typescript
// src/store/use-notifications.ts
export const useNotifications = create<NotificationStore>()(
  persist(
    (set, get) => ({
      notifications: [],
      unreadCount: 0,
      // ... actions
    }),
    {
      name: "notifications-storage",  // Clé localStorage
      partialize: (state) => ({
        notifications: state.notifications,
        unreadCount: state.unreadCount,
      }),
    }
  )
);
```

### Limite de stockage

- **Maximum** : 100 notifications conservées
- **Stratégie** : LIFO (Last In, First Out) - les plus anciennes sont supprimées
- **Application** : À chaque ajout de notification

```typescript
addNotification: (notification) => {
  const newNotification = { ...notification, id: uuidv4(), timestamp: Date.now(), read: false };
  set((state) => {
    const updated = [newNotification, ...state.notifications];
    const limited = updated.slice(0, 100);  // Limite à 100
    return {
      notifications: limited,
      unreadCount: limited.filter(n => !n.read).length,
    };
  });
};
```

### Cycle de vie d'une notification

```
1. Création
   └─ UUID généré automatiquement (uuidv4)
   └─ Timestamp = Date.now()
   └─ read = false

2. Ajout au store
   └─ Insertion en tête de liste (LIFO)
   └─ Truncation si > 100 notifications
   └─ Recalcul du unreadCount

3. Consultation
   └─ Affichage dans NotificationCenter
   └─ Marquage comme lu (read = true)

4. Suppression
   └─ Individuelle : removeNotification(id)
   └─ Globale : clearAll()
   └─ Automatique : au-delà de 100 notifications
```

### Clé localStorage

```
notifications-storage
```

Contenu stocké (exemple) :
```json
{
  "state": {
    "notifications": [
      {
        "id": "uuid-1",
        "title": "Notification 1",
        "message": "...",
        "level": "info",
        "category": "system",
        "timestamp": 1705680000000,
        "read": false
      }
    ],
    "unreadCount": 1
  },
  "version": 0
}
```

---

## 11. Bonnes Pratiques

### Choix du niveau approprié

| Situation | Niveau recommandé |
|-----------|-------------------|
| Information neutre, état | `info` |
| Opération réussie, confirmation | `success` |
| Dégradation, attention requise | `warning` |
| Erreur bloquante, échec | `error` |

> ⚠️ **Éviter** : N'abusez pas du niveau `error` pour des situations mineures.

### Rédaction des messages

- **Titre** : Court, descriptif, actionnable (max 50 caractères)
- **Message** : Détaillé mais concis, contexte utile
- **Source** : Identifier le service émetteur pour le debugging

```typescript
// ✅ Bon exemple
notifyError(
  "Connexion MQTT échouée",
  "Impossible de se connecter au broker mosquitto:1883. Vérifiez que le service est démarré.",
  "mqtt"
);

// ❌ Mauvais exemple
notifyError("Erreur", "Une erreur est survenue", "system");
```

### Catégorisation

Toujours utiliser la catégorie appropriée pour faciliter le filtrage :

- Événements Docker → `docker`
- Événements MQTT → `mqtt`
- Événements d'authentification → `auth`
- Événements de scénarios → `automation`
- Autres → `system`

### Fréquence des notifications

- **Éviter le spam** : Regrouper les notifications similaires
- **Debounce** : Attendre avant d'émettre des notifications répétitives
- **Désactivable** : Permettre à l'utilisateur de désactiver certaines notifications

### Actions utiles

Ajouter des actions quand pertinent :

```typescript
notificationService.addNotification(
  "Session expirée",
  "Votre session a expiré. Veuillez vous reconnecter.",
  "warning",
  "auth",
  "AuthService",
);
// Note : Les actions sont ajoutées via le store directement si nécessaire
```

---

## 12. Dépannage

### Notification non affichée

**Symptôme** : Une notification créée n'apparaît pas dans le centre.

**Solutions** :
1. Vérifier que le store est accessible :
   ```typescript
   console.log(useNotifications.getState().notifications);
   ```
2. Vérifier la limite de 100 notifications
3. S'assurer que le composant `NotificationCenter` est monté

### Compteur incorrect

**Symptôme** : Le badge affiche un nombre incorrect.

**Solutions** :
1. Forcer un recalcul :
   ```typescript
   const state = useNotifications.getState();
   state.markAsRead(state.notifications[0]?.id);
   ```
2. Vider le localStorage si corrompu :
   ```typescript
   localStorage.removeItem("notifications-storage");
   window.location.reload();
   ```

### Persistance perdue après rechargement

**Symptôme** : Les notifications disparaissent après un refresh.

**Solutions** :
1. Vérifier la présence de la clé dans localStorage :
   ```typescript
   console.log(localStorage.getItem("notifications-storage"));
   ```
2. Vérifier les quotas localStorage (5MB par défaut)
3. Vérifier les erreurs de parsing JSON

### Notifications dupliquées

**Symptôme** : La même notification apparaît plusieurs fois.

**Solutions** :
1. Vérifier que `addNotification` n'est pas appelé plusieurs fois
2. Ajouter un debounce sur les événements fréquents
3. Vérifier les effets React (`useEffect` sans dépendances correctes)

### Performance avec beaucoup de notifications

**Symptôme** : Le centre de notifications est lent.

**Solutions** :
1. La limite de 100 notifications devrait prévenir ce problème
2. Utiliser la virtualisation si nécessaire
3. Nettoyer régulièrement avec `clearAll()`

---

## Voir aussi

- [Guide des Widgets Dynamiques](guide-widgets-dynamiques.md) - Notifications spécifiques aux widgets
- [Documentation des Fichiers](DOCUMENTATION-FICHIERS.md) - Structure des fichiers du projet
- [Guide Docker](guide-docker.md) - Configuration de Watchtower

---

*Documentation NeurHomIA - Système de Notifications*
