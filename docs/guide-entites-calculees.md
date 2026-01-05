# Guide des Entités Calculées 🧮

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Ce guide explique comment créer et utiliser les entités calculées dans NeurHomIA pour transformer et enrichir vos données d'entités.

---

## 📑 Table des matières

- [Qu'est-ce qu'une Entité Calculée ?](#quest-ce-quune-entité-calculée-)
- [Types de Conversion Disponibles](#types-de-conversion-disponibles)
- [Création d'une Entité Calculée](#création-dune-entité-calculée)
- [Exemples d'Usage](#exemples-dusage)
- [Utilisation Avancée](#utilisation-avancée)
- [Intégration MQTT](#intégration-mqtt)
- [Dépannage](#dépannage)
- [Bonnes Pratiques](#bonnes-pratiques)
- [API REST](#api-rest)
- [Voir aussi](#-voir-aussi)

---

## Qu'est-ce qu'une Entité Calculée ?

Une entité calculée transforme automatiquement la valeur d'une entité source selon des règles prédéfinies. Elle permet de :

- **Convertir des valeurs** : Transformer un pourcentage de batterie en niveau qualitatif
- **Enrichir les données** : Ajouter des informations contextuelles 
- **Standardiser l'affichage** : Harmoniser les unités et formats
- **Créer des alertes visuelles** : Associer des couleurs selon les seuils

## Types de Conversion Disponibles

### `battery_to_level`
Convertit un pourcentage de batterie en niveau qualitatif :
- **0-20%** : Critique (rouge)
- **21-50%** : Faible (orange) 
- **51-80%** : Bon (vert)
- **81-100%** : Excellent (bleu)

### `signal_to_quality`
Transforme une force de signal en qualité de connexion :
- **0-25%** : Très faible
- **26-50%** : Faible
- **51-75%** : Bonne
- **76-100%** : Excellente

### `temperature_to_comfort`
Évalue le confort thermique :
- **< 16°C** : Froid
- **16-19°C** : Frais
- **20-24°C** : Confortable
- **25-28°C** : Chaud
- **> 28°C** : Très chaud

### `humidity_to_level`
Classifie le niveau d'humidité :
- **< 30%** : Sec
- **30-50%** : Optimal
- **51-70%** : Humide
- **> 70%** : Très humide

### `percentage_to_grade`
Convertit un pourcentage en note :
- **90-100%** : A (Excellent)
- **80-89%** : B (Bien)
- **70-79%** : C (Correct)
- **60-69%** : D (Insuffisant)
- **< 60%** : F (Échec)

### `numeric_to_boolean`
Transforme une valeur numérique en état binaire :
- **> seuil** : Actif/ON
- **≤ seuil** : Inactif/OFF

## Création d'une Entité Calculée

### Via l'Interface

1. **Naviguez** vers **Entités** → **Gestion**
2. **Cliquez** sur **Créer l'entité**
3. **Sélectionnez** le type "Entité Calculée"
4. **Configurez** les paramètres :
   - **Nom** : Nom d'affichage de l'entité
   - **Entité source** : Entité dont la valeur sera transformée
   - **Type de conversion** : Méthode de transformation
   - **Plage de valeurs** : Configuration des seuils et labels

### Configuration des Plages

La configuration des plages permet de définir :

```json
{
  "min": 0,
  "max": 100,
  "unit": "%",
  "levels": [
    {
      "min": 0,
      "max": 20,
      "label": "Critique",
      "color": "hsl(0, 75%, 55%)"
    },
    {
      "min": 21,
      "max": 50,
      "label": "Faible", 
      "color": "hsl(40, 90%, 60%)"
    }
  ]
}
```

#### Propriétés des Niveaux

- **min/max** : Bornes du niveau (incluses)
- **label** : Texte affiché pour ce niveau
- **color** : Couleur HSL pour l'affichage

## Exemples d'Usage

### Surveillance de Batterie

**Objectif** : Convertir le pourcentage de batterie d'un capteur Zigbee en niveau qualitatif.

**Configuration** :
- **Entité source** : `zigbee_temperature_sensor_battery`
- **Type** : `battery_to_level`
- **Résultat** : "Critique", "Faible", "Bon", "Excellent"

### Qualité de Signal WiFi

**Objectif** : Transformer la force du signal RSSI en qualité de connexion.

**Configuration** :
- **Entité source** : `wifi_device_signal_strength`
- **Type** : `signal_to_quality`
- **Plage personnalisée** :
  - -90 à -70 dBm : Signal faible
  - -69 à -50 dBm : Signal correct
  - -49 à -30 dBm : Signal fort

### Confort Thermique

**Objectif** : Évaluer le confort d'une pièce selon la température.

**Configuration** :
- **Entité source** : `salon_temperature`
- **Type** : `temperature_to_comfort`
- **Résultat** : "Froid", "Frais", "Confortable", "Chaud"

## Utilisation Avancée

### Plages Personnalisées

Vous pouvez créer des plages entièrement personnalisées :

```json
{
  "min": 0,
  "max": 5000,
  "unit": "ppm",
  "levels": [
    {"min": 0, "max": 400, "label": "Excellent", "color": "hsl(120, 60%, 50%)"},
    {"min": 401, "max": 1000, "label": "Bon", "color": "hsl(80, 60%, 50%)"},
    {"min": 1001, "max": 2000, "label": "Moyen", "color": "hsl(40, 90%, 60%)"},
    {"min": 2001, "max": 5000, "label": "Mauvais", "color": "hsl(0, 75%, 55%)"}
  ]
}
```

### Mise à Jour Automatique

Les entités calculées se mettent à jour automatiquement quand l'entité source change. Vous pouvez configurer :

- **Intervalle de mise à jour** : Fréquence de recalcul (secondes)
- **Seuil de changement** : Variation minimale pour déclencher une mise à jour
- **Filtrage** : Ignorer les valeurs aberrantes

## Intégration MQTT

### Publication Automatique

Les entités calculées publient automatiquement sur :
- **État** : `calculatedentity/{entity_id}/state`
- **Attributs** : `calculatedentity/{entity_id}/attributes`
- **Configuration** : `calculatedentity/{entity_id}/config`

### Format du Message

```json
{
  "state": "Bon",
  "value": 75,
  "level": 2,
  "color": "hsl(120, 60%, 50%)",
  "unit": "%",
  "last_updated": "2024-01-15T10:30:00Z"
}
```

## Dépannage

### L'entité calculée ne se met pas à jour

**Vérifications** :
- ✅ L'entité source publie des données
- ✅ La configuration de plage est valide
- ✅ L'intervalle de mise à jour n'est pas trop long

### Valeur incorrecte affichée

**Solutions** :
- ✅ Vérifiez les bornes min/max des niveaux
- ✅ Contrôlez le type de conversion utilisé
- ✅ Testez avec une valeur connue

### Couleurs non appliquées

**Points à vérifier** :
- ✅ Format HSL correct : `hsl(hue, saturation%, lightness%)`
- ✅ Valeurs dans les bonnes plages (H: 0-360, S/L: 0-100%)
- ✅ Cache du navigateur vidé

## Bonnes Pratiques

1. **Noms descriptifs** : Utilisez des noms clairs pour vos entités
2. **Plages logiques** : Assurez-vous que les niveaux se chevauchent pas
3. **Couleurs cohérentes** : Utilisez une palette harmonieuse
4. **Documentation** : Documentez vos conversions personnalisées
5. **Test** : Vérifiez avec des valeurs connues avant déploiement

## API REST

### Créer une Entité Calculée

```bash
POST /api/entities/calculated
Content-Type: application/json

{
  "name": "Niveau Batterie Salon",
  "source_entity": "salon_sensor_battery",
  "conversion_type": "battery_to_level",
  "value_range": {
    "min": 0,
    "max": 100,
    "unit": "%"
  }
}
```

### Obtenir la Configuration

```bash
GET /api/entities/calculated/{entity_id}/config
```

### Mettre à Jour

```bash
PUT /api/entities/calculated/{entity_id}
Content-Type: application/json

{
  "value_range": {
    "levels": [...]
  }
}
```

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide du Mode Simulation](guide-mode-simulation.md) - Test sans infrastructure
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications
- [Structure JSON Microservices](microservice-json.md) - Format des configurations
- [Guide de Production](guide-production.md) - Déploiement en production

---

_Documentation NeurHomIA_
```
