# Guide des Scénarios d'Automatisation 🎬

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Ce guide couvre le système complet de scénarios d'automatisation QUAND/SI/ALORS de NeurHomIA.

---

## 📑 Table des matières

1. [Introduction](#-1-introduction)
2. [Architecture et concepts](#-2-architecture-et-concepts)
3. [Structure d'un scénario](#-3-structure-dun-scénario)
4. [Création de scénarios](#-4-création-de-scénarios)
5. [Éditeur de règles](#-5-éditeur-de-règles)
6. [Planification calendaire](#-6-planification-calendaire)
7. [Backend d'exécution](#-7-backend-dexécution)
8. [Modèles et templates](#-8-modèles-et-templates)
9. [Import/Export](#-9-importexport)
10. [Monitoring et suivi](#-10-monitoring-et-suivi)
11. [Bonnes pratiques](#-11-bonnes-pratiques)
12. [Dépannage](#-12-dépannage)

---

## 🎯 1. Introduction

Le système de scénarios de NeurHomIA permet d'automatiser votre maison intelligente grâce à une logique intuitive **QUAND/SI/ALORS** :

- **QUAND** : Définit les événements déclencheurs (message MQTT, horaire, événement astronomique)
- **SI** : Spécifie les conditions à vérifier avant l'exécution
- **ALORS** : Liste les actions à exécuter si les conditions sont remplies

### Caractéristiques principales

| Fonctionnalité | Description |
|----------------|-------------|
| 🔗 Intégration MQTT | Communication native avec tous les appareils MQTT |
| ⚡ Multi-backend | Exécution via Scheduler Python ou Local Engine Node.js |
| 📅 Planification | Horaires fixes, récurrence, événements astronomiques |
| 🧩 Modèles | Templates prédéfinis et personnels réutilisables |
| 📤 Import/Export | Sauvegarde et partage de scénarios au format JSON |

---

## 🏗️ 2. Architecture et Concepts

### Flux d'exécution

```
┌─────────────────────────────────────────────────────────────┐
│                     Événement Déclencheur                   │
│              (Message MQTT, Horaire, Astronomie)            │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    QUAND (Déclencheurs)                     │
│         Vérifie si l'événement correspond aux règles        │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     SI (Conditions)                         │
│      Évalue toutes les conditions (ET/OU/Groupes)           │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    ALORS (Actions)                          │
│         Exécute les actions définies via MQTT               │
└─────────────────────────────────────────────────────────────┘
```

### Composants logiciels

| Composant | Fichier | Description |
|-----------|---------|-------------|
| Types | `src/types/rules.ts` | Interfaces TypeScript (Scenario, RuleItem, etc.) |
| Builder | `RuleBuilder.tsx` | Orchestrateur des sections QUAND/SI/ALORS |
| Éditeur | `RulesEditor.tsx` | Interface principale d'édition de scénarios |
| Section | `RuleSection.tsx` | Gestion d'une section de règles individuelle |
| Wizard | `ScenarioWizard.tsx` | Assistant de création guidée |
| Planification | `ScenarioScheduleConfig.tsx` | Configuration de la planification calendaire |
| Backend | `ExecutionBackendConfigCard.tsx` | Configuration du backend d'exécution |

---

## 📦 3. Structure d'un Scénario

### Interface TypeScript complète

```typescript
interface Scenario {
  // Identité
  name: string;                    // Nom du scénario
  description: string;             // Description détaillée
  tags?: string[];                 // Tags pour le filtrage et l'organisation
  
  // Localisation
  location?: string;               // ID de la localisation
  locationName?: string;           // Nom affiché de la localisation
  
  // Règles d'automatisation
  Quand: RuleItem[];               // Déclencheurs
  Si: RuleItem[];                  // Conditions
  Alors: RuleItem[];               // Actions
  
  // État et cycle de vie
  status?: ScenarioStatus;         // active | paused | suspended | error
  
  // Planification
  calendarSchedule?: CalendarScheduleConfig;
  schedulerTaskId?: string;        // ID de tâche dans le Scheduler
  
  // Backend d'exécution
  executionBackend?: 'scheduler_microservice' | 'local_engine' | 'auto';
  activeBackend?: 'scheduler_microservice' | 'local_engine';
}
```

### Types de RuleItem

| Type | Description | Exemple |
|------|-------------|---------|
| `RuleCondition` | Condition avec topic MQTT | `zigbee/capteur/état = "on"` |
| `LogicalOperator` | Opérateur logique | `ET`, `OU`, `SINON` |
| `RuleGroup` | Groupe de conditions imbriquées | `(A ET B) OU C` |

### Statuts de scénario

```typescript
type ScenarioStatus = 'active' | 'paused' | 'suspended' | 'error';
```

| Statut | Icône | Description |
|--------|-------|-------------|
| `active` | 🟢 | Actif et opérationnel |
| `paused` | ⏸️ | Mis en pause manuellement |
| `suspended` | ⚠️ | Suspendu (dépendance manquante) |
| `error` | 🔴 | En erreur, nécessite intervention |

---

## ✨ 4. Création de Scénarios

### Méthode 1 : Assistant (Wizard) 🧙‍♂️

L'assistant guide pas à pas la création d'un scénario :

1. **Choisir un modèle**
   - Modèles officiels (Sécurité, Notification, Éclairage, Climat)
   - Modèles personnels sauvegardés

2. **Personnaliser les paramètres**
   - Nom et description
   - Tags et localisation

3. **Configurer les appareils**
   - Sélection des entités MQTT
   - Configuration des valeurs

4. **Finaliser**
   - Révision du scénario
   - Configuration de la planification
   - Choix du backend d'exécution

### Méthode 2 : Éditeur direct ✏️

Pour les utilisateurs avancés :

1. Cliquer sur **"Nouveau scénario"**
2. Remplir le nom et la description
3. Ajouter manuellement les règles dans chaque section
4. Configurer la planification et le backend
5. Sauvegarder

---

## 🔧 5. Éditeur de Règles

### Section QUAND (Déclencheurs) 🎯

Définit les événements qui déclenchent le scénario :

| Type de déclencheur | Description | Exemple |
|---------------------|-------------|---------|
| Message MQTT | Réception d'un message sur un topic | `zigbee/capteur_mouvement/occupancy` |
| Horaire fixe | Heure précise de la journée | `08:00` tous les jours |
| Événement astronomique | Lever/coucher du soleil | Au coucher du soleil |
| Changement d'état | Modification de valeur d'une entité | Température > 25°C |

### Section SI (Conditions) ✅

Conditions à vérifier avant l'exécution des actions :

**Opérateurs de comparaison :**

| Opérateur | Signification | Exemple |
|-----------|---------------|---------|
| `=` | Égal | `état = "on"` |
| `≠` | Différent | `mode ≠ "absent"` |
| `>` | Supérieur | `température > 20` |
| `<` | Inférieur | `luminosité < 100` |
| `≥` | Supérieur ou égal | `humidité ≥ 60` |
| `≤` | Inférieur ou égal | `batterie ≤ 20` |
| `contient` | Contient la chaîne | `message contient "alerte"` |

### Section ALORS (Actions) ⚡

Actions exécutées si les conditions sont remplies :

| Type d'action | Description | Exemple |
|---------------|-------------|---------|
| Publication MQTT | Envoyer un message MQTT | `zigbee/lampe/set → {"state":"ON"}` |
| Commande appareil | Contrôler un appareil | Allumer la lumière du salon |
| Notification | Envoyer une alerte | Notification push mobile |
| Webhook HTTP | Appeler une URL externe | Intégration IFTTT |

### Opérateurs logiques

```
┌─────────────────────────────────────────────────────────────┐
│  ET   : Toutes les conditions doivent être vraies           │
│  OU   : Au moins une condition doit être vraie              │
│  SINON: Action alternative si condition fausse              │
└─────────────────────────────────────────────────────────────┘
```

### Groupes de conditions

Les groupes permettent de créer des logiques complexes :

```
Exemple : (Capteur1 ET Capteur2) OU (Capteur3 ET Heure > 18:00)

┌─────────────────────────────────────────┐
│ Groupe 1                                │
│   Capteur mouvement salon = true   ET   │
│   Luminosité salon < 100                │
├─────────────────────────────────────────┤
│                   OU                    │
├─────────────────────────────────────────┤
│ Groupe 2                                │
│   Capteur présence entrée = true   ET   │
│   Heure actuelle > 18:00                │
└─────────────────────────────────────────┘
```

---

## 📅 6. Planification Calendaire

### Types de planification disponibles

| Type | Description | Cas d'usage |
|------|-------------|-------------|
| `always` | Déclenché uniquement par événements MQTT | Réaction aux capteurs |
| `fixed_time` | Heure fixe quotidienne | Réveil à 07:00 |
| `recurring` | Récurrence périodique | Tous les lundis à 08:00 |
| `astronomical` | Basé sur le soleil | Au coucher du soleil |
| `specific_days` | Jours spécifiques | Du lundi au vendredi |
| `period` | Période définie | Du 1er décembre au 31 janvier |

### Configuration TypeScript

```typescript
interface CalendarScheduleConfig {
  type: "always" | "fixed_time" | "recurring" | "astronomical" | "specific_days" | "period";
  enabled: boolean;
  configuration: {
    // Heure d'exécution
    time?: string;                    // Format "HH:MM"
    
    // Jours de la semaine (0=Dimanche, 1=Lundi, ..., 6=Samedi)
    days?: number[];
    
    // Événement astronomique
    astronomicalEvent?: "sunrise" | "sunset" | "dawn" | "dusk";
    offset?: number;                  // Décalage en minutes (+/-)
    
    // Récurrence
    recurrence?: "daily" | "weekly" | "monthly";
    
    // Période
    startDate?: string;               // Format "YYYY-MM-DD"
    endDate?: string;
  };
}
```

### Exemples de configuration

**Allumer les lumières au coucher du soleil :**
```json
{
  "type": "astronomical",
  "enabled": true,
  "configuration": {
    "astronomicalEvent": "sunset",
    "offset": -15
  }
}
```

**Chauffage du lundi au vendredi à 6h30 :**
```json
{
  "type": "specific_days",
  "enabled": true,
  "configuration": {
    "time": "06:30",
    "days": [1, 2, 3, 4, 5]
  }
}
```

---

## ⚡ 7. Backend d'Exécution

NeurHomIA supporte deux backends d'exécution pour les scénarios :

### Scheduler Python (Microservice) 🐍

| Caractéristique | Description |
|-----------------|-------------|
| Type | Microservice centralisé |
| Planification | Cron avancée avec APScheduler |
| Monitoring | Statistiques complètes via MQTT |
| Déploiement | Docker recommandé |

**Topics MQTT :**
- `neurhomia/scheduler/status` : État du scheduler
- `neurhomia/scheduler/tasks/{id}` : État des tâches

### Local Engine (Node.js) 🟢

| Caractéristique | Description |
|-----------------|-------------|
| Type | Backend local Node.js |
| Planification | node-cron + calculs astronomiques |
| Avantage | Fonctionne sans dépendance externe |
| API | REST sur port 3001 |

**Topics MQTT :**
- `neurhomia/local-engine/status` : État du Local Engine
- `neurhomia/local-engine/scenarios/status` : Statistiques

### Mode Auto 🔄

Le mode automatique :
1. Tente d'utiliser le Scheduler Python en priorité
2. Bascule sur le Local Engine si le Scheduler est indisponible
3. Affiche le backend actif dans l'interface

### Indicateurs visuels

| Indicateur | Backend |
|------------|---------|
| 🟣 Violet | Scheduler Python actif |
| 🟢 Vert | Local Engine actif |
| 🔵 Bleu | Mode Auto |
| ⚠️ Orange | Non synchronisé |
| 🔴 Rouge | Erreur |

---

## 📚 8. Modèles et Templates

### Modèles officiels

Templates prédéfinis par catégorie :

| Catégorie | Modèles disponibles |
|-----------|---------------------|
| 🔒 **Sécurité** | Armement/désarmement alarme, Détection intrusion |
| 🔔 **Notification** | SMS, Push mobile, Webhook, Email |
| 💡 **Éclairage** | Présence, Horaire, Ambiance |
| 🌡️ **Climat** | Chauffage automatique, Climatisation, Ventilation |
| 🏠 **Confort** | Scénarios réveil, Départ maison, Retour maison |

### Créer un modèle personnel

1. Créer ou éditer un scénario
2. Cliquer sur **"Sauvegarder comme modèle"**
3. Donner un nom et une description au modèle
4. Le modèle apparaît dans l'onglet **"Mes modèles"** du wizard

### Utiliser un modèle

1. Ouvrir l'assistant de création (Wizard)
2. Choisir l'onglet **"Modèles officiels"** ou **"Mes modèles"**
3. Sélectionner le modèle souhaité
4. Personnaliser les paramètres
5. Finaliser le scénario

---

## 📤 9. Import/Export

### Exporter un scénario

1. Ouvrir le scénario en édition
2. Cliquer sur **"Exporter"**
3. Un fichier JSON est téléchargé

### Exporter tous les scénarios

1. Aller dans **Configuration** → **Sauvegarde**
2. Cliquer sur **"Exporter les scénarios"**
3. Un fichier JSON contenant tous les scénarios est téléchargé

### Importer des scénarios

1. Aller dans **Configuration** → **Sauvegarde**
2. Cliquer sur **"Importer"**
3. Sélectionner le fichier JSON
4. Les scénarios sont fusionnés avec les existants

### Format JSON d'export

```json
{
  "name": "Éclairage salon présence",
  "description": "Allume le salon quand mouvement détecté",
  "tags": ["éclairage", "présence", "salon"],
  "location": "salon",
  "locationName": "Salon",
  "Quand": [
    {
      "type": "condition",
      "topic": "zigbee/capteur_mouvement_salon/occupancy",
      "operator": "=",
      "value": "true"
    }
  ],
  "Si": [
    {
      "type": "condition",
      "topic": "zigbee/capteur_luminosite_salon/illuminance",
      "operator": "<",
      "value": "100"
    }
  ],
  "Alors": [
    {
      "type": "condition",
      "topic": "zigbee/lampe_salon/set",
      "value": "{\"state\":\"ON\",\"brightness\":255}"
    }
  ],
  "status": "active",
  "executionBackend": "auto"
}
```

---

## 📊 10. Monitoring et Suivi

### Dashboard des scénarios

Le tableau de bord affiche :

- ✅ Nombre de scénarios actifs
- ⏸️ Scénarios en pause
- ⚠️ Scénarios en erreur
- 📈 Statistiques d'exécution

### Historique d'exécution

Chaque scénario conserve un historique :
- Date et heure d'exécution
- Résultat (succès/échec)
- Actions effectuées
- Erreurs éventuelles

### Topics MQTT de monitoring

| Topic | Description |
|-------|-------------|
| `neurhomia/scenarios/status` | État global de tous les scénarios |
| `neurhomia/scenarios/{name}/execution` | Événements d'exécution d'un scénario |
| `neurhomia/scenarios/{name}/error` | Erreurs d'un scénario |

### Alertes

Configuration des alertes pour :
- Scénario passé en erreur
- Échec d'exécution répété
- Backend d'exécution indisponible

---

## ✅ 11. Bonnes Pratiques

### Nommage 📝

```
✅ Bon : "Éclairage salon - Présence soir"
✅ Bon : "Chauffage - Départ travail semaine"
❌ Mauvais : "Scénario 1"
❌ Mauvais : "test"
```

### Organisation 📁

- **Localisation** : Associer chaque scénario à une pièce
- **Tags cohérents** : Utiliser des tags standardisés
  - Par fonction : `éclairage`, `chauffage`, `sécurité`
  - Par moment : `matin`, `soir`, `nuit`
  - Par mode : `présent`, `absent`, `vacances`

### Performance ⚡

| À faire | À éviter |
|---------|----------|
| Limiter les conditions à 5-10 maximum | Conditions trop nombreuses |
| Utiliser des groupes pour la lisibilité | Logique trop complexe |
| Tester en mode simulation | Déployer sans test |
| Vérifier les boucles | Scénario qui se déclenche lui-même |

### Sécurité 🔒

- **Tester d'abord** : Utiliser le mode simulation
- **Vérifier les payloads** : S'assurer que les messages MQTT sont corrects
- **Backup régulier** : Exporter les scénarios périodiquement
- **Documenter** : Ajouter des descriptions claires

---

## 🐛 12. Dépannage

### Le scénario ne se déclenche pas

1. **Vérifier le statut**
   - Le scénario doit être en statut `active`
   - Vérifier qu'il n'est pas en pause

2. **Vérifier le déclencheur QUAND**
   - Le topic MQTT est-il correct ?
   - Le message reçu correspond-il à la condition ?

3. **Consulter les logs**
   - Logs du Scheduler Python : `docker logs neurhomia-scheduler`
   - Logs du Local Engine : `docker logs neurhomia-local-engine`

### Le scénario n'est pas synchronisé

1. **Vérifier la connexion au backend**
   - Le Scheduler ou Local Engine est-il en ligne ?
   - L'indicateur de statut est-il vert ?

2. **Synchroniser manuellement**
   - Cliquer sur le bouton "Synchroniser"
   - Vérifier les erreurs affichées

3. **Redémarrer le backend**
   ```bash
   docker restart neurhomia-scheduler
   # ou
   docker restart neurhomia-local-engine
   ```

### Les actions ne s'exécutent pas

1. **Vérifier les conditions SI**
   - Toutes les conditions sont-elles remplies ?
   - Les valeurs comparées sont-elles correctes ?

2. **Vérifier le payload MQTT**
   - Le format JSON est-il valide ?
   - Le topic de destination existe-t-il ?

3. **Tester manuellement**
   - Utiliser MQTT Explorer pour envoyer le message
   - Vérifier la réaction de l'appareil

### Erreur "Boucle détectée"

Le scénario se déclenche lui-même :

```
❌ QUAND : zigbee/lampe/state = "ON"
   ALORS : zigbee/lampe/set → {"state":"ON"}
```

**Solution :** Utiliser des topics différents pour le déclencheur et l'action, ou ajouter une condition pour éviter la boucle.

---

## 📚 Voir aussi

- [Guide du Local Engine](guide-local-engine.md) - Backend Node.js d'exécution
- [Guide d'Installation](guide-installation.md) - Installation complète
- [Guide de Production](guide-production.md) - Déploiement en production
- [Documentation des fichiers](DOCUMENTATION-FICHIERS.md) - Structure du code source
