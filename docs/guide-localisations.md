# Guide des Localisations 📍

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Ce guide détaille le système de localisations dans NeurHomIA, couvrant la structure hiérarchique, la configuration, les icônes et l'utilisation dans les entités.

---

## 📑 Table des matières

1. [Introduction](#introduction)
2. [Architecture et Concepts](#architecture-et-concepts)
3. [Structure des Localisations](#structure-des-localisations)
4. [Types de Localisations](#types-de-localisations)
5. [Localisations par Défaut](#localisations-par-défaut)
6. [Interface de Gestion](#interface-de-gestion)
7. [Création de Localisations](#création-de-localisations)
8. [Topics MQTT et Localisations](#topics-mqtt-et-localisations)
9. [Utilisation dans les Entités](#utilisation-dans-les-entités)
10. [Personnalisation](#personnalisation)
11. [Synchronisation GitHub](#synchronisation-github)
12. [Import/Export](#importexport)
13. [Bonnes Pratiques](#bonnes-pratiques)
14. [Dépannage](#dépannage)

---

## Introduction

Les **localisations** dans NeurHomIA représentent l'organisation spatiale de votre habitat domotique. Elles permettent de :

- **Organiser les entités** par emplacement physique (zone, niveau, pièce)
- **Générer automatiquement** les paths MQTT pour la communication
- **Filtrer et regrouper** les appareils par localisation
- **Structurer les scénarios** avec des conditions géographiques

Le système utilise une **structure hiérarchique** à 3 niveaux : Zone → Niveau → Pièce.

---

## Architecture et Concepts

### Hiérarchie des Localisations

```
Zone (Intérieur)
  └─ Niveau (RDC)
       └─ Pièce (Salon)
            └─ Entités (Lampe, Thermostat, Capteur...)
```

### Fichiers Clés

| Fichier | Rôle |
|---------|------|
| `src/types/custom-config.ts` | Interfaces `Location` et `LocationPath` |
| `src/services/customConfigService.ts` | Service de gestion des localisations |
| `src/hooks/useCustomConfig.ts` | Hook d'accès aux données |
| `src/components/config/LocationPathManager.tsx` | Interface de gestion UI |
| `src/data/devices.ts` | Données statiques (legacy) |

### Flux de Données

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub (distant)                      │
│         public/data/entities-category.json               │
└─────────────────────┬───────────────────────────────────┘
                      │ sync
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  CustomConfigService                     │
│    - Chargement et fusion des configurations             │
│    - Gestion des localisations personnalisées            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   useCustomConfig                        │
│    - Hook React pour accès aux données                   │
│    - Rafraîchissement automatique                        │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              LocationPathManager                         │
│    - Interface de gestion utilisateur                    │
│    - CRUD des localisations                              │
└─────────────────────────────────────────────────────────┘
```

---

## Structure des Localisations

### Interface `Location` (Hiérarchique)

Représente une localisation dans l'arbre hiérarchique :

```typescript
interface Location {
  id: string;              // Identifiant unique (ex: "interieur_rdc_salon")
  name: string;            // Nom d'affichage (ex: "Salon")
  type: string;            // Type : "zone" | "niveau" | "piece"
  description: string;     // Description de la localisation
  parent_id: string | null; // ID du parent (null pour les zones racine)
  children?: Location[];   // Enfants directs (optionnel)
}
```

### Interface `LocationPath` (MQTT)

Représente un chemin MQTT pour les topics :

```typescript
interface LocationPath {
  id: string;              // Identifiant unique
  name: string;            // Nom d'affichage
  path: string;            // Path MQTT complet (ex: "interieur/rdc/salon")
  segments: string[];      // Segments du path (ex: ["interieur", "rdc", "salon"])
  type: string;            // Type de localisation
  description: string;     // Description
  isCustom?: boolean;      // true si créé par l'utilisateur
}
```

### Exemple Concret

```typescript
// Localisation hiérarchique
const salonLocation: Location = {
  id: "interieur_rdc_salon",
  name: "Salon",
  type: "piece",
  description: "Pièce de vie principale",
  parent_id: "interieur_rdc"
};

// Path MQTT correspondant
const salonPath: LocationPath = {
  id: "interieur_rdc_salon",
  name: "Salon",
  path: "interieur/rdc/salon",
  segments: ["interieur", "rdc", "salon"],
  type: "piece",
  description: "Pièce de vie principale",
  isCustom: false
};
```

---

## Types de Localisations

NeurHomIA définit **3 types** de localisations organisés hiérarchiquement :

| Type | Description | Position | Exemples | Icônes suggérées |
|------|-------------|----------|----------|------------------|
| `zone` | Zone principale | Niveau 1 | Intérieur, Extérieur, Annexes | `MapPin`, `Home`, `Building` |
| `niveau` | Niveau/étage | Niveau 2 | RDC, Étage, Sous-sol | `Layers`, `ArrowUp`, `ArrowDown` |
| `piece` | Pièce individuelle | Niveau 3+ | Salon, Cuisine, Chambre | `DoorOpen`, `Bed`, `UtensilsCrossed` |

### Profondeur Maximale

La profondeur maximale recommandée est de **4 niveaux** :

```
Zone → Niveau → Pièce → Sous-zone (optionnel)
```

Exemple avec 4 niveaux :
```
exterieur/jardin/potager/serre
```

---

## Localisations par Défaut

NeurHomIA fournit **29 localisations prédéfinies** organisées en 4 zones principales.

### Zone "Non-localisé" (1)

| ID | Nom | Path | Description |
|----|-----|------|-------------|
| `non-localise` | Non-localisé | `non-localise` | Localisation par défaut |

> ⚠️ Cette localisation est utilisée pour les entités sans emplacement défini.

### Zone "Annexes" (4)

| ID | Nom | Path | Type |
|----|-----|------|------|
| `annexes` | Annexes | `annexes` | zone |
| `annexes_abri-jardin` | Abri de jardin | `annexes/abri-jardin` | piece |
| `annexes_garage` | Garage | `annexes/garage` | piece |
| `annexes_veranda` | Véranda | `annexes/veranda` | piece |

### Zone "Extérieur" (9)

| ID | Nom | Path | Type |
|----|-----|------|------|
| `exterieur` | Extérieur | `exterieur` | zone |
| `exterieur_allee` | Allée | `exterieur/allee` | piece |
| `exterieur_balcon` | Balcon | `exterieur/balcon` | piece |
| `exterieur_cour` | Cour | `exterieur/cour` | piece |
| `exterieur_entree` | Entrée | `exterieur/entree` | piece |
| `exterieur_jardin` | Jardin | `exterieur/jardin` | piece |
| `exterieur_piscine` | Piscine | `exterieur/piscine` | piece |
| `exterieur_terrasse` | Terrasse | `exterieur/terrasse` | piece |
| `exterieur_portail` | Portail | `exterieur/portail` | piece |

### Zone "Intérieur" (15)

#### Niveau RDC (8)

| ID | Nom | Path |
|----|-----|------|
| `interieur` | Intérieur | `interieur` |
| `interieur_rdc` | RDC | `interieur/rdc` |
| `interieur_rdc_cuisine` | Cuisine | `interieur/rdc/cuisine` |
| `interieur_rdc_salon` | Salon | `interieur/rdc/salon` |
| `interieur_rdc_salle-a-manger` | Salle à manger | `interieur/rdc/salle-a-manger` |
| `interieur_rdc_entree` | Entrée | `interieur/rdc/entree` |
| `interieur_rdc_wc` | WC | `interieur/rdc/wc` |
| `interieur_rdc_buanderie` | Buanderie | `interieur/rdc/buanderie` |

#### Niveau Étage (5)

| ID | Nom | Path |
|----|-----|------|
| `interieur_etage` | Étage | `interieur/etage` |
| `interieur_etage_chambre-1` | Chambre 1 | `interieur/etage/chambre-1` |
| `interieur_etage_chambre-2` | Chambre 2 | `interieur/etage/chambre-2` |
| `interieur_etage_salle-de-bain` | Salle de bain | `interieur/etage/salle-de-bain` |
| `interieur_etage_couloir` | Couloir | `interieur/etage/couloir` |

#### Niveau Sous-sol (2)

| ID | Nom | Path |
|----|-----|------|
| `interieur_sous-sol` | Sous-sol | `interieur/sous-sol` |
| `interieur_sous-sol_cave` | Cave | `interieur/sous-sol/cave` |

---

## Interface de Gestion

L'interface `LocationPathManager` propose deux onglets principaux :

### Onglet "Gestion des localisations"

#### Formulaire d'Ajout

- **Path parent** : Sélection du parent dans la hiérarchie
- **Nouveau segment** : Segment à ajouter (kebab-case recommandé)
- **Nom d'affichage** : Nom visible dans l'interface
- **Aperçu du path** : Affichage du path MQTT généré

#### Liste des Localisations

- Affichage trié par ordre hiérarchique
- **Badge "Par défaut"** : Localisation système (non supprimable)
- **Badge "Personnalisé"** : Localisation utilisateur
- **Action Supprimer** : Disponible uniquement pour les personnalisées

### Onglet "Topics MQTT par localisation"

Pour chaque localisation :

| Information | Description |
|-------------|-------------|
| Patterns disponibles | Modèles de topics pour cette localisation |
| Topics utilisés | Topics réellement actifs |
| Nombre d'entités | Compteur d'entités associées |
| Liste des entités | Détail des entités par localisation |

---

## Création de Localisations

### Étapes de Création

1. **Sélectionner un parent** (optionnel)
   - Choisir dans la liste déroulante
   - Laisser vide pour créer une zone racine

2. **Saisir le segment**
   - Format kebab-case recommandé (ex: `bureau-etage`)
   - Éviter les caractères spéciaux

3. **Définir le nom d'affichage**
   - Nom lisible (ex: "Bureau Étage")

4. **Valider la création**
   - Le path est généré automatiquement

### Exemple de Création

```
Configuration :
  - Parent : interieur/rdc
  - Segment : bureau
  - Nom : Bureau

Résultat :
  - ID : interieur_rdc_bureau
  - Path : interieur/rdc/bureau
  - Type : piece
  - isCustom : true
```

### Validation Automatique

Le système vérifie automatiquement :

| Règle | Description |
|-------|-------------|
| Format segment | Caractères alphanumériques et tirets |
| Unicité | Le path ne doit pas déjà exister |
| Profondeur | Maximum 4 niveaux recommandé |
| Parent valide | Le parent doit exister |

---

## Topics MQTT et Localisations

### Génération Automatique des Patterns

Pour chaque localisation, des patterns MQTT sont générés automatiquement :

```
domotique/{path}/temperature/+/value
domotique/{path}/humidity/+/value
domotique/{path}/light/+/state
domotique/{path}/switch/+/state
domotique/{path}/shutter/+/position
domotique/{path}/motion/+/state
domotique/{path}/door/+/state
domotique/{path}/window/+/state
meteo/{path}/+/+
astral/{path}/+/+
```

### Exemple Concret

Pour la localisation `interieur/rdc/salon` :

```mqtt
# Topics générés
domotique/interieur/rdc/salon/light/lamp_001/state
domotique/interieur/rdc/salon/light/lamp_001/set
domotique/interieur/rdc/salon/temperature/sensor_001/value
domotique/interieur/rdc/salon/humidity/sensor_001/value
domotique/interieur/rdc/salon/shutter/volet_001/position
domotique/interieur/rdc/salon/shutter/volet_001/set
```

### Structure du Topic

```
{prefix}/{zone}/{niveau}/{piece}/{type}/{device_id}/{action}
```

| Segment | Description | Exemple |
|---------|-------------|---------|
| `prefix` | Namespace principal | `domotique` |
| `zone` | Zone de la maison | `interieur` |
| `niveau` | Niveau/étage | `rdc` |
| `piece` | Pièce | `salon` |
| `type` | Type d'entité | `light` |
| `device_id` | Identifiant appareil | `lamp_001` |
| `action` | Action ou état | `state`, `set`, `value` |

---

## Utilisation dans les Entités

### Sélection de la Localisation

Lors de la création d'une entité, la localisation est sélectionnée via un menu déroulant :

```typescript
// Dans le formulaire de création d'entité
<Select value={entity.locationId} onValueChange={setLocationId}>
  {locationPaths.map(loc => (
    <SelectItem key={loc.id} value={loc.id}>
      {loc.path} - {loc.name}
    </SelectItem>
  ))}
</Select>
```

### Propriétés de l'Entité

```typescript
interface Entity {
  // ...
  locationId: string;     // ID de la localisation (ex: "interieur_rdc_salon")
  location: string;       // Nom d'affichage (ex: "Salon")
  locationPath?: string;  // Path complet (ex: "interieur/rdc/salon")
  // ...
}
```

### Filtrage par Localisation

#### Dans le Dashboard

```typescript
// Filtrer les entités par localisation
const entitiesBySalon = entities.filter(
  e => e.locationId === "interieur_rdc_salon"
);

// Filtrer par zone (toutes les entités intérieures)
const entitiesInterior = entities.filter(
  e => e.locationPath?.startsWith("interieur/")
);
```

#### Dans les Scénarios

```typescript
// Condition sur la localisation
{
  type: "location",
  operator: "equals",
  value: "interieur/rdc/salon",
  entityFilter: true
}
```

---

## Personnalisation

### Ajouter une Localisation Personnalisée

#### Via l'Interface (Recommandé)

1. Ouvrir **Configuration** → **Localisations**
2. Sélectionner le parent souhaité
3. Remplir le formulaire
4. Cliquer sur **Ajouter**

#### Via le Service (Programmatique)

```typescript
import { CustomConfigService } from '@/services/customConfigService';

const newLocation: LocationPath = {
  id: "interieur_rdc_bureau",
  name: "Bureau",
  path: "interieur/rdc/bureau",
  segments: ["interieur", "rdc", "bureau"],
  type: "piece",
  description: "Espace de travail",
  isCustom: true
};

CustomConfigService.addCustomLocationPath(newLocation);
```

### Propriété `isCustom`

| Valeur | Signification | Suppression |
|--------|---------------|-------------|
| `true` | Créée par l'utilisateur | ✅ Autorisée |
| `false` | Localisation par défaut | ❌ Interdite |

### Suppression d'une Localisation

Lors de la suppression d'une localisation personnalisée :

1. **Vérification** : Aucune entité ne doit être associée
2. **Réaffectation** : Si des entités existent, les réaffecter d'abord
3. **Suppression** : La localisation est retirée du système

```typescript
// Supprimer une localisation
CustomConfigService.removeCustomLocationPath("interieur_rdc_bureau");
```

---

## Synchronisation GitHub

### Source de Données Distante

Les localisations par défaut sont stockées dans le dépôt GitHub :

```
public/data/entities-category.json
```

### Hook `useCustomConfig`

```typescript
const { 
  locationPaths,           // Liste des localisations
  refreshFromGitHub,       // Synchroniser avec GitHub
  forceFullReload,         // Forcer un rechargement complet
  lastSyncDate,            // Date de dernière synchronisation
  isLoading                // État de chargement
} = useCustomConfig();
```

### Processus de Fusion

1. **Chargement GitHub** : Récupération des données distantes
2. **Chargement Local** : Récupération du cache localStorage
3. **Fusion** : Combinaison des deux sources
4. **Priorité** : Les personnalisées (`isCustom: true`) sont préservées

```
GitHub (défaut) + localStorage (custom) → État final
```

---

## Import/Export

### Format d'Export

```json
{
  "version": "1.0.0",
  "exportDate": "2026-01-18T10:30:00Z",
  "locationPaths": [
    {
      "id": "interieur_rdc_bureau",
      "name": "Bureau",
      "path": "interieur/rdc/bureau",
      "segments": ["interieur", "rdc", "bureau"],
      "type": "piece",
      "description": "Espace de travail",
      "isCustom": true
    }
  ]
}
```

### Export des Localisations

```typescript
// Exporter toutes les localisations personnalisées
const customLocations = locationPaths.filter(l => l.isCustom);
const exportData = JSON.stringify({ locationPaths: customLocations }, null, 2);
```

### Import des Localisations

```typescript
// Importer depuis un fichier JSON
const importData = JSON.parse(fileContent);
importData.locationPaths.forEach(loc => {
  CustomConfigService.addCustomLocationPath({
    ...loc,
    isCustom: true
  });
});
```

### Réinitialisation

Le bouton **"Réinitialiser"** :

1. Supprime toutes les localisations personnalisées
2. Restaure les 29 localisations par défaut
3. Réaffecte les entités orphelines à "Non-localisé"

---

## Bonnes Pratiques

### Nommage des Segments

| ✅ Recommandé | ❌ À éviter |
|---------------|-------------|
| `chambre-1` | `Chambre 1` |
| `salle-de-bain` | `salle_de_bain` |
| `bureau-etage` | `bureauÉtage` |

### Organisation Hiérarchique

```
✅ Bonne structure :
interieur/
  ├── rdc/
  │   ├── salon/
  │   ├── cuisine/
  │   └── bureau/
  └── etage/
      ├── chambre-1/
      └── chambre-2/

❌ Structure plate (éviter) :
salon/
cuisine/
chambre-1/
chambre-2/
```

### Recommandations

1. **Limiter la profondeur** à 3-4 niveaux maximum
2. **Utiliser le kebab-case** pour les segments
3. **Documenter** les localisations personnalisées
4. **Éviter les doublons** de noms dans un même niveau
5. **Grouper logiquement** les entités par localisation

---

## Dépannage

### Localisation Non Affichée

**Symptôme** : Une localisation n'apparaît pas dans la liste.

**Solutions** :
1. Vérifier la synchronisation GitHub via `refreshFromGitHub()`
2. Forcer un rechargement complet via `forceFullReload()`
3. Vérifier le localStorage dans les DevTools

### Entités Orphelines

**Symptôme** : Des entités affichent "Localisation inconnue".

**Solutions** :
1. Réaffecter les entités à une localisation valide
2. Utiliser "Non-localisé" comme localisation par défaut
3. Recréer la localisation manquante

### Path MQTT Incorrect

**Symptôme** : Les topics MQTT ne correspondent pas aux attentes.

**Solutions** :
1. Vérifier les segments dans `LocationPathManager`
2. Recréer la localisation avec les bons segments
3. Mettre à jour les entités associées

### Synchronisation GitHub Échouée

**Symptôme** : Les localisations par défaut ne se chargent pas.

**Solutions** :
1. Vérifier la connexion réseau
2. Vérifier le token GitHub dans `useGitHubConfig`
3. Vérifier l'URL du dépôt et le chemin du fichier

### Conflit de Fusion

**Symptôme** : Des localisations dupliquées apparaissent.

**Solutions** :
1. Identifier les doublons par leur `id`
2. Supprimer les versions personnalisées si nécessaire
3. Forcer un rechargement depuis GitHub

---

## Voir Aussi

- [Guide des Entités MQTT](guide-entites-mqtt.md) - Types d'entités et configuration
- [Guide des Scénarios](guide-scenarios.md) - Automatisations avec conditions de localisation
- [Format MCP Template](microservice-json.md) - Structure des microservices
- [Guide des Widgets Dynamiques](guide-widgets-dynamiques.md) - Widgets par localisation

---

*Documentation NeurHomIA - Système de Localisations*
