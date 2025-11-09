# NeurHomIA - Données de configuration

Ce dossier contient les données de configuration par défaut pour NeurHomIA, synchronisées automatiquement via GitHub.

## 📁 Structure des fichiers

### `scenario-templates.json`
Templates de scénarios d'automatisation pré-configurés pour une mise en place rapide de règles communes.

**Catégories disponibles :**
- **Sécurité** : Armement/désarmement automatique, alertes, vérifications
- **Notification** : Envoi de SMS, notifications push via webhooks

**Structure :**
```json
{
  "version": "1.0.0",
  "timestamp": "2025-01-XX...",
  "data": {
    "templates": [...]
  }
}
```

### `entities-category.json`
Configuration complète des catégories d'entités, localisations et chemins de localisation.

**Contient :**
- **entityCategories** : Types d'appareils (lampes, capteurs, volets, etc.)
- **locations** : Hiérarchie des localisations (zones, niveaux, pièces)
- **locationPaths** : Chemins MQTT-like pour l'organisation spatiale
- **defaults** : Valeurs par défaut pour la création d'entités

**Structure :**
```json
{
  "version": 1,
  "timestamp": "2025-01-XX...",
  "data": {
    "entityCategories": [...],
    "locations": [...],
    "locationPaths": [...],
    "defaults": {...}
  }
}
```

## 🔄 Synchronisation

### Configuration automatique

Les fichiers sont automatiquement synchronisés avec NeurHomIA selon les paramètres définis :

1. **Fréquence de synchronisation** (configurable dans l'application) :
   - Quotidienne (par défaut)
   - Hebdomadaire
   - Mensuelle
   - Manuelle uniquement

2. **Chargement initial** :
   - Au premier démarrage de l'application
   - Lors de la connexion à un nouveau repository GitHub

3. **Vérification des mises à jour** :
   - Selon la fréquence configurée
   - Notification automatique en cas de nouvelles données disponibles
   - Synchronisation manuelle via l'interface de configuration

### URLs de chargement

Les fichiers sont chargés depuis GitHub via les URLs suivantes :
```
https://raw.githubusercontent.com/{owner}/NeurHomIA/main/data/scenario-templates.json
https://raw.githubusercontent.com/{owner}/NeurHomIA/main/data/entities-category.json
```

Où `{owner}` est le nom du propriétaire du repository GitHub (configurable dans l'application).

## 🔀 Gestion des conflits

### Priorité des données

**GitHub = Source de vérité** pour les données par défaut.

En cas de doublon d'identifiant (`id`) entre :
- ✅ **Données GitHub** → Conservées (priorité haute)
- ⚠️ **Données personnalisées** → Écrasées avec notification à l'utilisateur

### Ajouts personnalisés

Les utilisateurs peuvent ajouter leurs propres éléments :
- Catégories d'entités personnalisées
- Localisations spécifiques à leur domicile
- Templates de scénarios adaptés à leurs besoins

Ces éléments personnalisés :
- Reçoivent automatiquement le flag `isCustom: true`
- Sont stockés localement dans le navigateur
- Sont fusionnés avec les données GitHub à l'affichage
- Ne sont **PAS** écrasés lors des synchronisations (sauf conflit d'ID)

### Notification des conflits

Lors d'une synchronisation, si un conflit est détecté :
```
⚠️ Conflit détecté lors de la synchronisation GitHub

Les éléments personnalisés suivants ont été remplacés par les données GitHub :
- Catégorie "smart_lamp" (ID identique)
- Localisation "salon" (ID identique)

Vos autres ajouts personnalisés ont été conservés.
```

## 🛠️ Utilisation dans l'application

### Chargement des données

Les services NeurHomIA utilisent ces fichiers comme base de données de référence :

**Pour les scénarios** (`ScenarioTemplateCache`) :
- Charge `scenario-templates.json`
- Génère automatiquement les IDs et métadonnées manquantes
- Fusionne avec les templates personnels de l'utilisateur

**Pour les entités** (`EntitiesConfigCache`) :
- Charge `entities-category.json`
- Marque les données GitHub avec `isCustom: false`
- Fusionne avec les ajouts personnalisés (`isCustom: true`)

### Interface utilisateur

Dans la section **Configuration > Synchronisation GitHub** :
- Visualisation de la date de dernière synchronisation
- Compteur d'éléments GitHub vs personnalisés
- Bouton de synchronisation manuelle
- Configuration de la fréquence de vérification
- Option d'activation/désactivation des notifications

## 📝 Maintenance

### Mise à jour des fichiers

Pour ajouter de nouveaux templates ou catégories :

1. Modifier le fichier JSON concerné
2. Incrémenter le numéro de `version`
3. Mettre à jour le `timestamp`
4. Commit et push sur la branche `main`

Les utilisateurs recevront automatiquement les nouvelles données lors de la prochaine vérification.

### Versioning

- `version` : Numéro de version du schéma de données (incrémenté en cas de changement de structure)
- `timestamp` : Date de dernière modification (format ISO 8601)

### Validation

Les données sont validées lors du chargement :
- Structure JSON conforme
- Présence des champs obligatoires
- Types de données corrects
- IDs uniques au sein de chaque collection

En cas d'erreur de validation :
- Message d'erreur détaillé dans la console
- Utilisation des données locales en cache
- Notification à l'utilisateur via toast

## 🔐 Authentification GitHub

L'accès aux fichiers peut être :
- **Public** : Aucune authentification requise (lecture seule)
- **Privé** : Token GitHub nécessaire (configurable dans l'application)

Le token GitHub (optionnel) permet :
- L'accès aux repositories privés
- L'augmentation des limites de taux d'API
- L'accès à des organizations privées

## 📚 Ressources

- [Documentation NeurHomIA](../README.md)
- [Configuration GitHub](../github-config.json)
- [Templates de containers](../github-templates/)
- [Guide de contribution](../CONTRIBUTING.md)

---

**Version du document** : 1.0.0  
**Dernière mise à jour** : 2025-01-22
