# 📦 Guide des Templates de Scénarios

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide détaille le système de templates de scénarios dans NeurHomIA : création, catégories, paramètres et partage via GitHub.

---

## 📑 Table des matières

- [Introduction](#introduction)
- [Architecture du Système](#architecture-du-système)
- [Structure d'un Template](#structure-dun-template)
- [Catégories de Templates](#catégories-de-templates)
- [Création de Templates](#création-de-templates)
- [Aperçu et Preview](#aperçu-et-preview)
- [Synchronisation GitHub](#synchronisation-github)
- [Export et Partage](#export-et-partage)
- [Import de Templates](#import-de-templates)
- [Utilisation dans ScenarioWizard](#utilisation-dans-scenariowizard)
- [Interface de Gestion](#interface-de-gestion)
- [Bonnes Pratiques](#bonnes-pratiques)
- [Dépannage](#dépannage)

---

## Introduction

Les templates de scénarios sont des modèles réutilisables pour créer rapidement des automatisations dans NeurHomIA. Ils permettent de :

- **Accélérer la création** : Partir d'un modèle plutôt que de zéro
- **Standardiser** : Appliquer les mêmes patterns dans plusieurs projets
- **Partager** : Distribuer des automatisations via GitHub

### Deux sources de templates

| Source | Description | Modifiable |
|--------|-------------|------------|
| **GitHub** | Templates officiels synchronisés depuis le dépôt | Non (lecture seule) |
| **Personnels** | Templates créés par l'utilisateur | Oui |

---

## Architecture du Système

### Diagramme des composants

```
┌─────────────────────────────────────────────────────────────┐
│                  TEMPLATES GITHUB                            │
│      (moreau66/NeurHomIA/data/scenario-templates.json)       │
├─────────────────────────────────────────────────────────────┤
│  ScenarioTemplateCache  →  Chargement + Cache localStorage   │
│  useScenarioTemplatesSync  →  Configuration synchronisation  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                  useScenarioTemplates                        │
│                  (Store Zustand central)                     │
├─────────────────────────────────────────────────────────────┤
│  - getAllTemplates()  →  GitHub + Personnels fusionnés       │
│  - createTemplateFromScenario()  →  Création depuis scénario │
│  - importTemplatesFromFile()  →  Import JSON                 │
│  - exportTemplate() / exportCollection()  →  Export JSON     │
└─────────────────────────────────────────────────────────────┘
```

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `src/types/scenario-templates.ts` | Interfaces TypeScript |
| `src/store/use-scenario-templates.ts` | Store Zustand principal |
| `src/store/use-scenario-templates-sync.ts` | Configuration de synchronisation |
| `src/services/scenarioTemplateCache.ts` | Cache et chargement GitHub |
| `src/services/defaultScenarioTemplates.ts` | Templates par défaut intégrés |
| `public/data/scenario-templates.json` | Fichier source local |
| `neurhomia-github/data/scenario-templates.json` | Fichier source GitHub |

---

## Structure d'un Template

### Interface `UserScenarioTemplate`

```typescript
interface UserScenarioTemplate {
  id: string;               // UUID unique
  name: string;             // Nom du template
  description: string;      // Description détaillée
  category: string;         // Catégorie (Sécurité, Éclairage, etc.)
  icon: string;             // Nom d'icône Lucide
  preview: {
    triggers: string[];     // Aperçu des déclencheurs
    conditions: string[];   // Aperçu des conditions
    actions: string[];      // Aperçu des actions
  };
  template: Partial<Scenario>;  // Structure du scénario
  metadata: {
    author: string;         // Auteur du template
    createdAt: string;      // Date de création ISO
    updatedAt: string;      // Dernière modification
    usageCount: number;     // Compteur d'utilisation
    isPersonal: boolean;    // true = personnel, false = GitHub
    tags: string[];         // Tags de recherche
    version: string;        // Version du template
  };
}
```

### Structure du scénario intégré

```typescript
template: {
  name: "Armement automatique nocturne",
  description: "Arme l'alarme tous les soirs à 23h00",
  tags: ["alarme", "sécurité", "horaire"],
  Quand: [
    {
      type: "Horaire",
      time: "23:00"
    }
  ],
  Si: [
    {
      type: "Jour de la semaine",
      days: ["Lun", "Mar", "Mer", "Jeu", "Ven"]
    }
  ],
  Alors: [
    {
      type: "MQTT_Publish",
      topic: "alarme/cmd/arm",
      payload: "ON"
    }
  ]
}
```

### Interface `ScenarioTemplateCollection`

Pour le partage de plusieurs templates :

```typescript
interface ScenarioTemplateCollection {
  name: string;           // Nom de la collection
  description: string;    // Description
  author: string;         // Auteur
  templates: UserScenarioTemplate[];
  metadata: {
    createdAt: string;    // Date de création
    version: string;      // Version de la collection
    tags: string[];       // Tags globaux
  };
}
```

---

## Catégories de Templates

### Catégories prédéfinies

| Catégorie | Icône | Description |
|-----------|-------|-------------|
| **Sécurité** | Shield | Alarme, surveillance, détection intrusion |
| **Éclairage** | Lightbulb | Lampes, ambiances lumineuses, gradation |
| **Chauffage** | Thermometer | Température, climatisation, confort thermique |
| **Énergie** | Zap | Consommation, optimisation, délestage |
| **Confort** | Home | Volets, multimédia, ambiance générale |
| **Notification** | Bell | Alertes SMS, push, email, Telegram |
| **Surveillance** | Eye | Caméras, présence, détection mouvement |
| **Automatisation** | Settings | Scénarios système, maintenance |
| **Personnalisé** | Settings | Catégorie libre définie par l'utilisateur |

### Icônes disponibles

Icônes Lucide compatibles :

- **Actions** : Lightbulb, LightbulbOff, Power, Play, Pause
- **Sécurité** : Shield, ShieldOff, Lock, Unlock, AlertTriangle
- **Environnement** : Thermometer, Sun, Moon, Cloud, Droplets
- **Communication** : MessageSquare, Bell, Mail, Phone
- **Système** : Settings, Clock, Calendar, Timer, Zap
- **Statut** : CheckCircle, XCircle, AlertCircle, Info

---

## Création de Templates

### Méthode 1 : Depuis un scénario existant

Via le composant `SaveAsTemplateModal` accessible depuis l'éditeur de scénarios :

1. **Ouvrir l'éditeur** de scénarios (`/scenarios`)
2. **Sélectionner un scénario** existant
3. **Cliquer sur "Sauvegarder comme modèle"** (icône template)
4. **Renseigner les métadonnées** :

| Champ | Obligatoire | Description |
|-------|-------------|-------------|
| Nom | ✅ | Nom descriptif du template |
| Description | ✅ | Explication du comportement |
| Catégorie | ✅ | Sélection parmi les catégories |
| Icône | ✅ | Icône Lucide représentative |
| Tags | ❌ | Mots-clés séparés par virgules |
| Personnel | ❌ | Marquer comme personnel (par défaut : oui) |

5. **Valider** la création

### Tags rapides suggérés

L'interface propose des tags fréquents :

- `éclairage`, `sécurité`, `confort`, `automatique`
- `nuit`, `jour`, `matin`, `soir`
- `horaire`, `présence`, `absence`

### Méthode 2 : Import de fichier JSON

Via le gestionnaire de templates :

1. **Accéder** à Configuration > Modèles de scénarios
2. **Cliquer** sur "Importer"
3. **Sélectionner** un fichier `.json`
4. **Validation automatique** du format
5. **Confirmation** du nombre de templates importés

### Formats supportés

| Format | Structure |
|--------|-----------|
| Template individuel | `{ id, name, template, metadata, ... }` |
| Collection | `{ name, templates: [...], metadata: {...} }` |

---

## Aperçu et Preview

### Section `preview`

Chaque template inclut un aperçu lisible des règles :

```typescript
preview: {
  triggers: ["Horaire: 23:00"],
  conditions: ["Jours: Lundi à Vendredi"],
  actions: ["MQTT: Armer l'alarme"]
}
```

### Affichage dans l'interface

| Section | Icône | Couleur |
|---------|-------|---------|
| Déclencheurs (Quand) | Clock | Bleu |
| Conditions (Si) | Filter | Orange |
| Actions (Alors) | Zap | Vert |

### Génération automatique

Lors de la création d'un template, l'aperçu est généré automatiquement :

```typescript
const generatePreview = (scenario: Scenario) => ({
  triggers: scenario.Quand.map(q => formatTrigger(q)),
  conditions: scenario.Si.map(s => formatCondition(s)),
  actions: scenario.Alors.map(a => formatAction(a))
});

// Exemple de formatage
const formatTrigger = (trigger: RuleCondition) => {
  switch (trigger.type) {
    case 'Horaire': return `Horaire: ${trigger.time}`;
    case 'MQTT_Subscribe': return `MQTT: ${trigger.topic}`;
    default: return trigger.type;
  }
};
```

---

## Synchronisation GitHub

### Service `ScenarioTemplateCache`

| Méthode | Description |
|---------|-------------|
| `initialize()` | Initialisation au démarrage de l'application |
| `loadFromGitHub()` | Chargement depuis le dépôt distant |
| `checkForUpdates()` | Vérification des mises à jour disponibles |
| `refresh()` | Rafraîchissement manuel avec notification |
| `forceFullReload()` | Réinitialisation complète du cache |
| `getGitHubTemplates()` | Récupère les templates GitHub chargés |
| `getGitHubCount()` | Nombre de templates GitHub |
| `getLastSyncDate()` | Date de dernière synchronisation |
| `clear()` | Vider le cache local |

### Configuration de synchronisation

Via le store `useScenarioTemplatesSync` :

```typescript
interface ScenarioTemplatesSyncState {
  enabled: boolean;        // Synchronisation activée
  frequency: SyncFrequency;
  lastCheck: number;       // Timestamp dernière vérification
  autoNotify: boolean;     // Notifications automatiques
}

type SyncFrequency = 'daily' | 'weekly' | 'monthly' | 'manual';
```

### Cycle de synchronisation

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Vérification shouldCheck() selon la fréquence           │
│    └─ daily: > 24h depuis lastCheck                        │
│    └─ weekly: > 7 jours                                    │
│    └─ monthly: > 30 jours                                  │
│    └─ manual: uniquement sur demande                       │
├─────────────────────────────────────────────────────────────┤
│ 2. Chargement depuis GitHub                                 │
│    URL: raw.githubusercontent.com/.../scenario-templates.json│
├─────────────────────────────────────────────────────────────┤
│ 3. Transformation des données                               │
│    └─ Ajout des IDs uniques                                │
│    └─ Enrichissement des métadonnées                       │
│    └─ isPersonal: false pour les templates GitHub          │
├─────────────────────────────────────────────────────────────┤
│ 4. Stockage dans localStorage                               │
│    Clé: "scenario-templates-cache"                         │
├─────────────────────────────────────────────────────────────┤
│ 5. Notification si différence détectée                      │
│    "X nouveau(x) template(s) disponible(s)"                │
└─────────────────────────────────────────────────────────────┘
```

### URL de synchronisation

```
https://raw.githubusercontent.com/{owner}/NeurHomIA/main/data/scenario-templates.json
```

Le propriétaire (`owner`) est configuré dans `useGitHubConfig`.

---

## Export et Partage

### Export individuel

Via `exportTemplate(templateId)` :

- **Format** : JSON individuel
- **Nom de fichier** : `scenario-template-{nom-slugifié}.json`
- **Contenu** : Template complet avec métadonnées

```json
{
  "id": "template-123",
  "name": "Armement nocturne",
  "description": "...",
  "category": "Sécurité",
  "icon": "Shield",
  "preview": { ... },
  "template": { ... },
  "metadata": { ... }
}
```

### Export global

Via `exportAllTemplates()` :

- **Format** : `ScenarioTemplateCollection`
- **Nom de fichier** : `scenario-templates-collection-{date}.json`
- **Contenu** : Tous les templates personnels

### Export de sélection

Via `exportCollection(templateIds, collectionName)` :

- **Format** : `ScenarioTemplateCollection` partielle
- **Personnalisation** : Nom et description de la collection
- **Sélection** : Templates choisis via checkboxes

### Exemple de collection exportée

```json
{
  "name": "Mes templates sécurité",
  "description": "Collection de scénarios de sécurité",
  "author": "Utilisateur",
  "templates": [
    { ... },
    { ... }
  ],
  "metadata": {
    "createdAt": "2026-01-20T10:30:00.000Z",
    "version": "1.0",
    "tags": ["sécurité", "alarme"]
  }
}
```

---

## Import de Templates

### Méthode `importTemplatesFromFile`

Processus d'import :

1. **Lecture** du fichier JSON
2. **Détection** du format (template individuel ou collection)
3. **Validation** de chaque template (structure requise)
4. **Détection des doublons** par comparaison du nom
5. **Attribution** d'un nouvel ID unique
6. **Ajout** au store avec `isPersonal: true`

### Interface `TemplateImportResult`

```typescript
interface TemplateImportResult {
  success: boolean;     // Import réussi globalement
  errors: string[];     // Erreurs bloquantes
  warnings: string[];   // Avertissements (doublons, etc.)
  imported: number;     // Nombre de templates importés
  duplicates: number;   // Nombre de doublons ignorés
}
```

### Gestion des doublons

| Situation | Comportement |
|-----------|--------------|
| Même nom exact | Ignoré (compteur `duplicates`) |
| Nom similaire | Importé avec avertissement |
| ID existant | Nouvel ID généré |

### Validation requise

Champs obligatoires pour un import valide :

- `name` : Nom du template
- `template` : Structure du scénario
- `category` : Catégorie (ou "Personnalisé" par défaut)

---

## Utilisation dans ScenarioWizard

### Assistant de création

L'assistant de création de scénarios propose les templates :

1. **Choix du type** :
   - Templates officiels (GitHub)
   - Templates personnels
   - Création vide

2. **Parcours par catégorie** :
   - Filtrage par catégorie
   - Recherche textuelle
   - Affichage de l'aperçu

3. **Personnalisation** :
   - Modification du nom
   - Choix de la localisation
   - Sélection des appareils

4. **Génération** :
   - Création du scénario final
   - Incrémentation du compteur d'utilisation

### Récupération des templates

```typescript
const { getAllTemplates, incrementUsage } = useScenarioTemplates();

// Récupère GitHub + Personnels fusionnés
const allTemplates = getAllTemplates();

// Filtre par catégorie
const securityTemplates = allTemplates.filter(
  t => t.category === 'Sécurité'
);

// Lors de l'utilisation
const handleUseTemplate = (templateId: string) => {
  incrementUsage(templateId);
  // ... création du scénario
};
```

### Compteur d'utilisation

Le champ `metadata.usageCount` est incrémenté à chaque utilisation :

- Visible dans les statistiques
- Permet de trier par popularité
- Persisté dans le store local

---

## Interface de Gestion

### Composant `ScenarioTemplatesManager`

Fonctionnalités principales :

| Fonction | Description |
|----------|-------------|
| Statistiques | Total templates, utilisations, catégories |
| Import | Bouton d'import de fichiers JSON |
| Export tout | Export de tous les templates personnels |
| Export sélection | Export des templates sélectionnés |
| Suppression groupée | Suppression multiple (personnels uniquement) |

### Onglets de vue

| Onglet | Affichage |
|--------|-----------|
| Tous les modèles | Liste complète avec badges |
| Par catégorie | Groupement thématique |
| Récents | Tri par date de création |
| Populaires | Tri par nombre d'utilisations |

### Badges distinctifs

| Badge | Couleur | Signification |
|-------|---------|---------------|
| GitHub | Bleu | Template synchronisé depuis GitHub |
| Personnel | Gris | Template créé par l'utilisateur |

### Composant `ScenarioTemplatesSyncSettings`

Configuration de la synchronisation :

- **Activation/désactivation** : Toggle de synchronisation
- **Fréquence** : daily, weekly, monthly, manual
- **Notifications** : Activer/désactiver les alertes
- **Synchronisation manuelle** : Bouton "Synchroniser maintenant"
- **Informations** : Source GitHub, nombre de templates, dernière sync

---

## Bonnes Pratiques

### Nommage

✅ **À faire** :
- Noms descriptifs et explicites
- Indiquer le déclencheur principal
- Mentionner l'objectif

❌ **À éviter** :
- Noms génériques ("Mon scénario 1")
- Abréviations obscures
- Noms trop longs (> 50 caractères)

### Catégorisation

- Choisir la catégorie correspondant à l'**objectif principal**
- Utiliser "Personnalisé" uniquement si aucune catégorie ne convient
- Cohérence avec les templates existants

### Tags

- Utiliser des mots-clés **pertinents pour la recherche**
- Inclure : lieu, moment, appareil, action
- Maximum recommandé : 5-7 tags

### Documentation

- Rédiger une **description complète** du comportement
- Préciser les **prérequis** (appareils, configuration)
- Mentionner les **effets secondaires** éventuels

### Test avant partage

1. **Créer** le scénario depuis le template
2. **Tester** en mode simulation
3. **Valider** le comportement attendu
4. **Exporter** uniquement si fonctionnel

---

## Dépannage

### Template non visible

| Cause | Solution |
|-------|----------|
| Synchronisation désactivée | Activer dans les paramètres |
| Cache expiré | Forcer un rafraîchissement |
| Erreur de chargement | Vérifier la connexion réseau |

**Commandes de diagnostic** :

```typescript
// Vérifier le cache
console.log(ScenarioTemplateCache.getGitHubCount());
console.log(ScenarioTemplateCache.getLastSyncDate());

// Forcer le rechargement
await ScenarioTemplateCache.forceFullReload();
```

### Import échoué

| Erreur | Solution |
|--------|----------|
| "Format JSON invalide" | Vérifier la syntaxe JSON |
| "Structure manquante" | Ajouter les champs obligatoires |
| "Fichier trop volumineux" | Diviser en plusieurs fichiers |

### Synchronisation bloquée

1. **Vérifier** la configuration GitHub (`owner` renseigné)
2. **Contrôler** l'accès au dépôt (public ou token valide)
3. **Forcer** un rechargement avec `forceFullReload()`
4. **Vider** le cache si nécessaire avec `clear()`

### Template corrompu

Si un template ne peut pas être utilisé :

1. **Exporter** le template en JSON
2. **Vérifier** la structure `template` (Quand, Si, Alors)
3. **Corriger** les erreurs dans le fichier
4. **Supprimer** l'ancien template
5. **Réimporter** le fichier corrigé

---

## Voir aussi

- [Guide des Scénarios](guide-scenarios.md) - Système d'automatisation QUAND/SI/ALORS
- [Guide de Synchronisation GitHub](guide-synchronisation-github.md) - Synchronisation des données
- [Guide des Alias MQTT](guide-alias-mqtt.md) - Alias utilisables dans les templates
- [Documentation des Fichiers](DOCUMENTATION-FICHIERS.md) - Structure du projet

---

_Documentation NeurHomIA - Janvier 2026_
