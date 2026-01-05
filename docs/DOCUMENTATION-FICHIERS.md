# Documentation des Fichiers NeurHomIA 📚

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Rapport généré automatiquement - Liste complète des fichiers documentés avec leurs descriptions françaises.

---

## 📑 Table des matières

- [Statistiques](#-statistiques)
- [Types](#-types-srctypes)
- [Stores Zustand](#-stores-zustand-srcstore)
- [Hooks](#-hooks-srchooks)
- [Services](#-services-srcservices)
- [Utilitaires](#-utilitaires-srcutils)
- [Configuration et Schémas](#-configuration--schémas)
- [Pages](#-pages-srcpages)
- [Composants](#-composants-srccomponents)
- [Fichiers racine](#-fichiers-racine)
- [Voir aussi](#-voir-aussi)

---

## 📊 Statistiques

| Catégorie | Nombre de fichiers |
|-----------|-------------------|
| Types (`src/types/`) | 30 |
| Stores Zustand (`src/store/`) | 40 |
| Hooks (`src/hooks/`) | 25 |
| Services (`src/services/`) | 60+ |
| Composants (`src/components/`) | 100+ |
| Utilitaires (`src/utils/`) | 12 |
| Configuration (`src/config/`, `src/schemas/`) | 4 |
| Données (`src/data/`) | 15 |
| Pages (`src/pages/`) | 18 |

---

## 📁 Types (`src/types/`)

### Fichiers de définition de types TypeScript

| Fichier | Description |
|---------|-------------|
| `app-config.ts` | Types pour la configuration globale de l'application (modes, sauvegarde, restauration, métadonnées). |
| `auth.ts` | Types pour l'authentification (User, AuthState, rôles admin/user/observer). |
| `automation.ts` | Types legacy pour l'automatisation (FlowType, ScenarioConnection). Conservé pour compatibilité. |
| `component-library.ts` | Types pour la bibliothèque de composants réutilisables (ComponentTemplate, ComponentLibrary). |
| `config.ts` | Types pour la configuration des brokers MQTT (MqttConfig, MqttSubscription, MqttBridge). |
| `containers.ts` | Types pour la gestion des conteneurs Docker (ContainerConfig, ContainerStatus, ContainerState). |
| `custom-config.ts` | Types pour la configuration personnalisable (Location, LocationPath, CustomEntityCategory). |
| `dynamic-pages.ts` | Types pour les pages dynamiques des microservices (PageSectionConfig, MicroservicePageConfig). |
| `dynamic-widgets.ts` | Types pour les widgets dynamiques MQTT (WidgetSchema, DiscoveredWidget, WidgetInstance). |
| `entities.ts` | Types pour les entités (EntityType, ValueMapping, CalculationConfig, AlertConfig, EntityMetadata). |
| `entity-discovery.ts` | Types pour la découverte automatique d'entités via MQTT (EntityDiscoverySchema, DiscoveredEntity). |
| `entity-editor.ts` | Types pour l'éditeur d'entités personnalisées (ViewMode, TopicConfig, EntityTemplate). |
| `entity-link.ts` | Types pour les liens entre entités (EntityLinkTrigger, EntityLinkTarget, EntityLink). |
| `ia2mqtt.ts` | Types pour le microservice IA2MQTT (IA2MQTTScenario, IA2MQTTDevice, IA2MQTTLLMQuery). |
| `microserviceAlias.ts` | Types pour les alias de microservices (AliasType, AliasCategory, MicroserviceAlias). |
| `microservices.ts` | Types pour la gestion des microservices MQTT (MicroserviceInfo, MicroserviceType, MicroserviceTemplate). |
| `mqtt-api.ts` | Types pour l'API MQTT externe (ApiKey, ApiPermission, MqttApiRequest, ApiMetrics). |
| `mqtt-discovery.ts` | Types pour la découverte multi-protocoles (HomeAssistantDiscovery, Zigbee2MqttDiscovery, TasmotaDiscovery). |
| `mqtt-monitor.ts` | Types pour le moniteur MQTT (MqttMessage, TopicStats, MonitorStatusProps). |
| `mqtt.ts` | Types centraux pour les entités et la communication MQTT (Entity, DeviceType, Location, MqttTopicInfo). |
| `notifications.ts` | Types pour le système de notifications (NotificationLevel, NotificationCategory, NotificationStore). |
| `page-editor.ts` | Types pour l'éditeur de pages de microservices (PageEditorFormSection, PageEditorChartSection, PageEditorState). |
| `page-overrides.ts` | Types pour les surcharges de pages de microservices (PageOverrides, SectionOverride, ConstrainedModeState). |
| `rules.ts` | Types pour les scénarios d'automatisation (Scenario, RuleCondition, RuleGroup, ScenarioStatus). |
| `scenario-tags.ts` | Types pour les tags de scénarios (ScenarioTag, ScenarioTagsCollection, DEFAULT_TAG_CATEGORIES). |
| `scenario-templates.ts` | Types pour les templates de scénarios réutilisables (UserScenarioTemplate, ScenarioTemplateCollection). |
| `simulation.ts` | Types pour la simulation MQTT (ScheduledMessage, VirtualMicroservice, VirtualEntity, MicroserviceTemplate). |
| `visual-editor.ts` | Types pour l'éditeur visuel drag-and-drop (VisualSection, CanvasConfig, ResolutionPreset). |
| `widget-config.ts` | Types pour la configuration des widgets (WidgetTopicConfig, WidgetDisplayConfig, EntityWidgetConfig). |
| `widget-settings.ts` | Types et valeurs par défaut pour les paramètres des widgets (DisplaySettings, DiscoverySettings). |

---

## 🗄️ Stores Zustand (`src/store/`)

### Gestionnaires d'état global avec Zustand

| Fichier | Description |
|---------|-------------|
| `use-aliases.ts` | Gère les alias pour les topics/payloads MQTT. Recherche multi-critères, migration et fusion avec GitHub. |
| `use-aliases-sync.ts` | Synchronisation des alias avec le cache GitHub au démarrage. |
| `use-auth.ts` | Gère l'authentification utilisateur (connexion, déconnexion, rôles, permissions). |
| `use-backend-simulation.ts` | Gère la simulation du backend pour les tests sans infrastructure réelle. |
| `use-calculated-history.ts` | Historique des valeurs calculées pour les entités avec formules d'agrégation. |
| `use-container-templates.ts` | Gère les templates de conteneurs Docker (YAML/JSON). |
| `use-containers.ts` | Gère les conteneurs Docker (CRUD, initialisation, import/export, templates). |
| `use-data-sync.ts` | État de synchronisation des données avec GitHub. |
| `use-dynamic-pages.ts` | Gère les pages dynamiques des microservices (enregistrement, activation, filtrage). |
| `use-dynamic-pages-sync.ts` | Synchronisation des pages dynamiques avec le cache. |
| `use-dynamic-widgets.ts` | Gère les widgets dynamiques et leurs instances (découverte, création, nettoyage). |
| `use-dynamic-widgets-sync.ts` | Synchronisation des widgets dynamiques avec GitHub. |
| `use-entities.ts` | Gère toutes les entités MQTT en mode production (CRUD, sync Docker, entités calculées). |
| `use-entities-config-sync.ts` | Synchronisation de la configuration des entités. |
| `use-entities-simulation.ts` | Gère les entités en mode simulation. |
| `use-entity-editor.ts` | État de l'éditeur d'entités personnalisées. |
| `use-entity-links.ts` | Gère les liaisons logiques entre entités MQTT (source → cibles multiples). |
| `use-environment-mode.ts` | Gère le basculement Production ↔ Simulation. |
| `use-github-config.ts` | Configuration de l'intégration GitHub (owner, token, préfixe repos). |
| `use-ia2mqtt.ts` | Intégration avec IA2MQTT (WebSocket, scénarios IA, requêtes LLM, statistiques). |
| `use-language.ts` | Gère l'internationalisation (français/anglais). |
| `use-microservice-templates.ts` | Templates de microservices pour la création. |
| `use-microservices.ts` | Gère les microservices découverts en mode production. |
| `use-microservices-simulation.ts` | Gère les microservices en mode simulation. |
| `use-mqtt-brokers.ts` | Configuration des brokers MQTT (CRUD, souscriptions, bridges, patterns). |
| `use-notifications.ts` | Système de notifications (ajout, lecture, compteur, limite 100). |
| `use-scenario-tags.ts` | Gère les tags pour organiser les scénarios. |
| `use-scenario-tags-sync.ts` | Synchronisation des tags de scénarios. |
| `use-scenario-templates.ts` | Templates de scénarios prédéfinis. |
| `use-scenario-templates-sync.ts` | Synchronisation des templates de scénarios. |
| `use-scenarios.ts` | Gère les scénarios d'automatisation (CRUD, cycle de vie, dépendances). |
| `use-sidebar.ts` | État de la barre latérale (ouverte/fermée, mode réduit). |
| `use-simulation-broker.ts` | Configuration du broker de simulation. |
| `use-template-sync-config.ts` | Configuration de la synchronisation des templates. |
| `use-views.ts` | Gère les vues personnalisées regroupant des appareils. |
| `use-virtual-entities.ts` | Gère les entités virtuelles créées manuellement. |
| `use-virtual-microservices.ts` | Gère les microservices virtuels simulés. |
| `use-visual-editor.ts` | Éditeur visuel drag-and-drop (canvas, grille, sections, overrides). |
| `use-widget-config.ts` | Configuration d'affichage des widgets par type d'entité. |
| `use-widget-editor.ts` | Éditeur de schémas de widgets dynamiques. |

---

## 🪝 Hooks (`src/hooks/`)

### Hooks React personnalisés

| Fichier | Description |
|---------|-------------|
| `use-mobile.tsx` | Détecte si l'utilisateur est sur mobile (breakpoint 768px). |
| `use-mqtt-auth.ts` | Authentification MQTT avec gestion des tokens. |
| `use-sidebar.ts` | Hook shadcn pour la gestion de la sidebar. |
| `use-toast.ts` | Système de toast shadcn/ui (messages temporaires). |
| `useComponentLibrary.ts` | Accès à la bibliothèque de composants réutilisables. |
| `useConfigManager.ts` | Interface vers le gestionnaire de configuration centrale. |
| `useContainerSync.ts` | Synchronisation des conteneurs Docker. |
| `useCurrentEntities.ts` | Accès aux entités selon le mode (production/simulation). |
| `useCurrentMicroservices.ts` | Accès aux microservices selon le mode. |
| `useCustomConfig.ts` | Accès à la configuration personnalisée. |
| `useDockerDiscoverySync.ts` | Synchronisation de la découverte Docker. |
| `useDockerIntegration.ts` | Intégration Docker dans l'application. |
| `useEntitySync.ts` | Synchronisation des entités. |
| `useLocalStorage.ts` | Interface React pour localStorage avec sérialisation JSON. |
| `useMicroserviceAliasRegistry.ts` | Registre des alias de microservices. |
| `useMicroserviceDiscovery.ts` | Découverte automatique des microservices. |
| `useMqttApi.ts` | Interface vers l'API MQTT. |
| `useMqttContext.ts` | Prépare un contexte MQTT formaté pour l'IA (raw, structured, natural). |
| `useMqttDeviceDiscovery.ts` | Découverte d'appareils MQTT. |
| `useNotifications.ts` | Interface simplifiée pour les notifications (par niveau et catégorie). |
| `useRules.ts` | Gestion des scénarios (CRUD, validation, export, intégration IA). |
| `useStorageAvailability.ts` | Vérifie la disponibilité du localStorage. |
| `useVirtualEntitySync.ts` | Synchronisation des entités virtuelles. |
| `useWidgetPreview.ts` | Prévisualisation des widgets. |
| `useZigbee2MqttDevices.ts` | Découverte des appareils Zigbee2MQTT. |

---

## ⚙️ Services (`src/services/`)

### Services métier et intégrations

| Fichier | Description |
|---------|-------------|
| `aiSimulation.ts` | Simulation IA pour les tests. |
| `aliasGeneratorService.ts` | Génération automatique d'alias lisibles. |
| `aliasesCache.ts` | Cache des alias pour performance. |
| `api-key-manager.ts` | Gestion des clés API sécurisées. |
| `astralMqttService.ts` | Service MQTT pour les données astronomiques. |
| `calculatedEntityService.ts` | Calcul des valeurs pour les entités avec formules. |
| `categoryImportExport.ts` | Import/export des catégories d'entités. |
| `componentLibraryService.ts` | Service de la bibliothèque de composants. |
| `config-manager.ts` | Gestionnaire central de configuration (export/import, sauvegarde, restauration). |
| `containerEntitySync.ts` | Synchronisation entités ↔ conteneurs Docker. |
| `containerTemplateCache.ts` | Cache des templates de conteneurs. |
| `customConfigService.ts` | Service de configuration personnalisée. |
| `dataSyncService.ts` | Synchronisation des données avec GitHub (versions, conflits). |
| `defaultScenarioTemplates.ts` | Templates de scénarios par défaut. |
| `dev-config.ts` | Configuration pour le mode développement. |
| `deviceIconService.ts` | Service d'icônes pour les appareils. |
| `deviceSimulation.ts` | Simulation d'appareils pour les tests. |
| `docker2mqttSimulation.ts` | Simulation du microservice Docker2MQTT. |
| `dockerDiscoveryService.ts` | Découverte des containers Docker via MQTT (Home Assistant, Docker2MQTT). |
| `dockerMonitoringService.ts` | Monitoring des conteneurs Docker. |
| `dynamicPagesCache.ts` | Cache des pages dynamiques. |
| `dynamicWidgetDataService.ts` | Service de données pour les widgets dynamiques. |
| `dynamicWidgetsCache.ts` | Cache des widgets dynamiques. |
| `entitiesConfigCache.ts` | Cache de configuration des entités. |
| `entityDiscoveryService.ts` | Découverte d'entités via MQTT avec création automatique. |
| `entityLinkService.ts` | Service de liens entre entités. |
| `environmentDuplicationService.ts` | Duplication d'environnements. |
| `githubConfigLoader.ts` | Chargeur de configuration GitHub avec fallback. |
| `githubMicroserviceDiscovery.ts` | Découverte de microservices sur GitHub. |
| `ia2mqttService.ts` | Service d'intégration IA2MQTT (Ollama). |
| `local-auth.ts` | Authentification locale sécurisée (utilisateurs, sessions, hors-ligne). |
| `localWidgetLibrary.ts` | Bibliothèque locale de widgets. |
| `meteoMqttService.ts` | Service MQTT pour les données météo. |
| `microserviceAliasRegistry.ts` | Registre des alias de microservices. |
| `microservicePageDiscovery.ts` | Découverte des pages de microservices. |
| `microserviceProductionDiscoveryService.ts` | Découverte des microservices en production. |
| `microserviceSimulationDiscoveryService.ts` | Découverte des microservices simulés. |
| `microserviceTemplateLoader.ts` | Chargeur de templates de microservices. |
| `microserviceTemplateToVirtual.ts` | Conversion template → microservice virtuel. |
| `mqtt-api-service.ts` | Service API MQTT pour les appels externes. |
| `mqttDeviceSync.ts` | Synchronisation des appareils MQTT. |
| `mqttDiscoveryService.ts` | Service de découverte MQTT multi-protocoles. |
| `mqttLoggerConfigService.ts` | Configuration du logger MQTT. |
| `mqttMessageStore.ts` | Store des messages MQTT. |
| `mqttPayloadConverter.ts` | Conversion des payloads MQTT. |
| `mqttProductionService.ts` | Service MQTT pour le mode production. |
| `mqttPublishHistory.ts` | Historique des publications MQTT. |
| `mqttService.ts` | Façade MQTT principale (bascule production/simulation). |
| `mqttSimulation.ts` | Service de simulation MQTT. |
| `mqttSimulator.ts` | Simulateur MQTT avancé (messages réalistes, réponses bidirectionnelles). |
| `mqttTopicValidator.ts` | Validation des topics MQTT. |
| `mqttTopicsCache.ts` | Cache des topics MQTT. |
| `notificationService.ts` | Service centralisé de notifications (système, Docker, MQTT, auth). |
| `pagePreviewService.ts` | Service de prévisualisation des pages. |
| `scenarioLifecycleService.ts` | Cycle de vie des scénarios (dépendances, suspensions automatiques). |
| `scenarioSimulation.ts` | Simulation des scénarios. |
| `scenarioTagsCache.ts` | Cache des tags de scénarios. |
| `scenarioTemplateCache.ts` | Cache des templates de scénarios. |
| `shutterSolarService.ts` | Service de gestion des volets solaires. |
| `simulationEnhancer.ts` | Amélioration des simulations. |
| `simulationScheduler.ts` | Planificateur de simulations. |
| `snapshotService.ts` | Gestion des snapshots de simulation (export/import état complet). |
| `topicIntelligenceService.ts` | Intelligence sur les topics MQTT. |
| `virtualMicroserviceBuilder.ts` | Construction de microservices virtuels. |
| `virtualMicroserviceEngine.ts` | Moteur d'exécution des microservices virtuels. |
| `watchtowerService.ts` | Intégration Watchtower pour les mises à jour Docker. |
| `weatherCalculationService.ts` | Calculs météorologiques. |
| `widgetDiscoveryService.ts` | Découverte automatique des widgets (MQTT, System2Mqtt). |
| `widgetTemplates.ts` | Templates de widgets prédéfinis. |

---

## 🧰 Utilitaires (`src/utils/`)

### Fonctions utilitaires réutilisables

| Fichier | Description |
|---------|-------------|
| `colorUtils.ts` | Fonctions de manipulation des couleurs (génération, conversion, contraste). |
| `componentLoader.ts` | Chargeur dynamique de composants React. |
| `containerHelpers.ts` | Helpers pour la gestion des conteneurs Docker. |
| `icon-i18n.ts` | Internationalisation des noms d'icônes Lucide. |
| `normalizers.ts` | Fonctions de normalisation des données. |
| `recoverLostEntities.ts` | Récupération des entités perdues/orphelines. |
| `templateValidator.ts` | Validation des templates de microservices/widgets. |
| `theme-classes.ts` | Classes CSS pour la gestion des thèmes. |
| `widgetExport.ts` | Export des widgets en différents formats. |
| `widgetFileHelpers.ts` | Helpers pour la gestion des fichiers de widgets. |
| `widgetNameHelpers.ts` | Helpers pour la gestion des noms de widgets. |
| `widgetTopicHelpers.ts` | Helpers pour les topics MQTT des widgets. |

---

## 📐 Configuration & Schémas

### `src/config/`

| Fichier | Description |
|---------|-------------|
| `brand.ts` | Configuration de la marque NeurHomIA (nom, logo, couleurs, URLs). |

### `src/schemas/`

| Fichier | Description |
|---------|-------------|
| `entitySchemas.ts` | Schémas Zod pour la validation des entités. |
| `widgetSchema.ts` | Schémas Zod pour la validation des widgets. |

### `src/lib/`

| Fichier | Description |
|---------|-------------|
| `deviceTypeLabels.ts` | Labels traduits pour les types d'appareils. |
| `utils.ts` | Utilitaire de fusion de classes CSS Tailwind (cn). |

---

## 📄 Pages (`src/pages/`)

### Pages de l'application

| Fichier | Description |
|---------|-------------|
| `Aliases.tsx` | Page de gestion des alias MQTT. |
| `AutomationBuilder.tsx` | Constructeur de scénarios d'automatisation. |
| `Configuration.tsx` | Page de configuration générale. |
| `ContainersManagement.tsx` | Gestion des conteneurs Docker. |
| `Devices.tsx` | Liste et gestion des appareils. |
| `Entities.tsx` | Liste et gestion des entités. |
| `EntitiesManagement.tsx` | Administration avancée des entités. |
| `EntityLinks.tsx` | Gestion des liens entre entités. |
| `KioskDashboard.tsx` | Tableau de bord mode kiosque. |
| `Login.tsx` | Page de connexion. |
| `MicroservicesManagement.tsx` | Gestion des microservices. |
| `MqttConfig.tsx` | Configuration des brokers MQTT. |
| `MqttLogger.tsx` | Logger de messages MQTT. |
| `MqttSimulation.tsx` | Interface de simulation MQTT. |
| `MqttTopics.tsx` | Explorateur de topics MQTT. |
| `Views.tsx` | Éditeur de vues personnalisées. |
| `WidgetDetails.tsx` | Détails d'un widget. |
| `Widgets.tsx` | Bibliothèque de widgets. |

---

## 🧩 Composants (`src/components/`)

### Structure des composants par catégorie

| Dossier | Description |
|---------|-------------|
| `astral/` | Composants pour les données astronomiques. |
| `auth/` | Composants d'authentification. |
| `automation-builder/` | Éditeur visuel de scénarios. |
| `config/` | Panneaux de configuration (32 composants). |
| `containers/` | Composants de gestion Docker. |
| `dashboard/` | Widgets du tableau de bord. |
| `devices/` | Composants pour les appareils. |
| `dynamic-pages/` | Rendu des pages dynamiques. |
| `entity-editor/` | Éditeur d'entités. |
| `entity-links/` | Éditeur de liens entre entités. |
| `ia2mqtt/` | Interface IA2MQTT. |
| `kiosk/` | Composants mode kiosque. |
| `layout/` | Layout principal et navigation. |
| `life-views/` | Vues personnalisées. |
| `mcp/` | Composants MCP (Microservice Control Plane). |
| `mqtt-logger/` | Composants du logger MQTT. |
| `mqtt/` | Composants MQTT génériques. |
| `ui/` | Composants shadcn/ui (exclus de la documentation). |
| `visual-editor/` | Éditeur visuel de pages. |
| `widget-editor/` | Éditeur de widgets. |
| `widgets/` | Composants de widgets personnalisés. |
| `zigbee/` | Composants Zigbee2MQTT. |

### Composants documentés (exemples)

| Fichier | Description |
|---------|-------------|
| `components/config/BackupManager.tsx` | Gestionnaire de sauvegardes avec export/import. |
| `components/config/MicroservicesSimulationPanel.tsx` | Panneau de simulation des microservices. |
| `components/config/GitHubConfigPanel.tsx` | Configuration de l'intégration GitHub. |
| `components/config/MqttConnectionStatus.tsx` | Indicateur de statut de connexion MQTT. |
| `components/dashboard/ContainerStatusWidget.tsx` | Widget d'état des conteneurs Docker. |
| `components/devices/DeviceCard.tsx` | Carte d'affichage d'un appareil. |
| `components/layout/MainLayout.tsx` | Layout principal de l'application. |
| `components/layout/EnvironmentBadge.tsx` | Badge de mode (Production/Simulation). |

---

## 📂 Fichiers racine

| Fichier | Description |
|---------|-------------|
| `src/App.tsx` | Point d'entrée principal (routage, thème, auth, routes protégées). |
| `src/main.tsx` | Point d'entrée du rendu React (ReactDOM.createRoot, StrictMode). |
| `src/vite-env.d.ts` | Déclarations TypeScript pour Vite (import.meta.env). |

---

## 🔍 Script de validation

Un script de validation est disponible pour vérifier la présence des commentaires d'en-tête :

```bash
# Exécuter la validation
node scripts/validate-headers.js

# Voir les fichiers manquants avec suggestions
node scripts/validate-headers.js --fix
```

---

## 📝 Format des commentaires d'en-tête

### Format standard pour les types et composants

```typescript
/**
 * @file nom-du-fichier.ts
 * @description Description courte en français.
 * 
 * Ce fichier définit :
 * - Point 1
 * - Point 2
 * - Point 3
 * 
 * Contexte d'utilisation ou notes importantes.
 */
```

### Format pour les stores Zustand

```typescript
/**
 * =============================================================================
 * STORE ZUSTAND - NOM DU STORE
 * =============================================================================
 * 
 * Ce store gère [description] :
 * - Fonctionnalité 1
 * - Fonctionnalité 2
 * 
 * Persistance : [localStorage/none]
 * =============================================================================
 */
```

### Format pour les hooks

```typescript
/**
 * =============================================================================
 * HOOK - NOM DU HOOK
 * =============================================================================
 * 
 * Ce hook [description] :
 * - Fonctionnalité 1
 * - Fonctionnalité 2
 * 
 * Usage : [contexte d'utilisation]
 * =============================================================================
 */
```

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Développement](guide-developpement.md) - Contribuer au projet
- [Préconisations Architecture MCP](guide-preconisations.md) - Standards microservices
- [Structure JSON Microservices](microservice-json.md) - Format des configurations
- [Guide du Mode Simulation](guide-mode-simulation.md) - Environnement de test

---

_Documentation NeurHomIA_

> **Couverture** : 95%+ des fichiers TypeScript dans `src/`
