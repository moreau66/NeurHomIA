# Guide des Sauvegardes 💾

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

Ce guide explique les différents systèmes de sauvegarde disponibles dans NeurHomIA et quand utiliser chacun d'entre eux.

---

## 📑 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Sauvegarde de la Configuration Applicative](#1-sauvegarde-de-la-configuration-applicative)
- [Sauvegarde des Fichiers de Données GitHub](#2-sauvegarde-des-fichiers-de-données-github)
- [Snapshots de Simulation MQTT](#3-snapshots-de-simulation-mqtt)
- [Tableau de décision](#tableau-de-décision--quel-système-utiliser-)
- [Ordre de restauration recommandé](#ordre-de-restauration-recommandé)
- [FAQ](#faq)
- [Résumé visuel](#résumé-visuel)
- [Voir aussi](#-voir-aussi)

---

## Vue d'ensemble

NeurHomIA dispose de **3 systèmes de sauvegarde distincts**, chacun ayant un rôle spécifique :

| Système                        | Données sauvegardées                       | Stockage            | Prérequis       |
| ------------------------------ | ------------------------------------------ | ------------------- | --------------- |
| **Configuration applicative**  | Entités, scénarios, vues, widgets, brokers | localStorage        | Aucun           |
| **Fichiers de données GitHub** | Fichiers JSON de `public/data/`            | Système de fichiers | API Docker      |
| **Snapshots de simulation**    | État complet de simulation MQTT            | Export JSON         | Mode simulation |

---

## 1. Sauvegarde de la Configuration Applicative

### Emplacement

`Config. Système` → `Gestion des données` → onglet **Sauvegarde** / **Restauration**

### Composants concernés

- `BackupManager.tsx` - Création de sauvegardes
- `RestoreManager.tsx` - Restauration de sauvegardes

### Données sauvegardées

- ✅ Entités et leur configuration
- ✅ Scénarios et automatisations
- ✅ Vues personnalisées
- ✅ Widgets et leur disposition
- ✅ Containers et groupes
- ✅ Brokers MQTT configurés
- ✅ Templates personnalisés

### Caractéristiques

- **Stockage** : localStorage du navigateur
- **Séparation** : Par mode (Production / Simulation)
- **Format de fichier** : `neurhomia-{mode}-{date}-{heure}.json`
- **Persistance** : Locale au navigateur (effacée si vous videz les données du navigateur)

### Quand l'utiliser ?

- Avant une mise à jour majeure de l'application
- Pour sauvegarder votre configuration personnelle
- Pour transférer votre configuration vers un autre navigateur
- Régulièrement (recommandé : 1x/semaine)

### Comment faire ?

1. Aller dans `Config. Système` → `Gestion des données`
2. Sélectionner l'onglet **Sauvegarde**
3. Choisir le mode (Production ou Simulation)
4. Cocher les types de données à sauvegarder
5. Cliquer sur **Créer une sauvegarde**
6. Le fichier JSON est téléchargé automatiquement

---

## 2. Sauvegarde des Fichiers de Données GitHub

### Emplacement

`Config. Système` → `Synchronisation GitHub` → section **Sauvegarde des fichiers de données**

### Composant concerné

- `DataSyncSettings.tsx`

### Données sauvegardées

- ✅ `aliases.json` - Alias des entités
- ✅ `scenario-tags.json` - Tags de scénarios
- ✅ `entity-templates.json` - Templates d'entités
- ✅ Autres fichiers du dossier `public/data/`

### Caractéristiques

- **Stockage** : Système de fichiers via API Docker (port 3001)
- **Synchronisation** : Avec le dépôt GitHub
- **Format de fichier** : `data-backup-{date}.json`
- **Persistance** : Permanente (versionnée avec Git)

### Prérequis

- ⚠️ API Docker active sur le port 3001
- ⚠️ Accès en écriture au dossier `public/data/`

### Quand l'utiliser ?

- Avant de modifier manuellement les fichiers JSON
- Avant un `git pull` qui pourrait écraser vos modifications locales
- Pour créer un point de restauration des définitions partagées

### Comment faire ?

1. S'assurer que l'API Docker est active (indicateur vert)
2. Aller dans `Config. Système` → `Synchronisation GitHub`
3. Cliquer sur **Sauvegarder** dans la section appropriée
4. Le fichier est téléchargé automatiquement

---

## 3. Snapshots de Simulation MQTT

### Emplacement

`Simulation MQTT` → bouton **Exporter Snapshot**

### Composant concerné

- `MqttSimulation.tsx`
- `snapshotService.ts`

### Données sauvegardées

- ✅ Entités de simulation
- ✅ Microservices configurés
- ✅ Messages MQTT programmés
- ✅ État complet de la simulation

### Caractéristiques

- **Stockage** : Export JSON téléchargeable
- **Isolation** : Indépendant des autres systèmes
- **Format de fichier** : `snapshot_{nom}_{timestamp}.json`
- **Portabilité** : Facilement partageable

### Quand l'utiliser ?

- Pour sauvegarder un scénario de test spécifique
- Pour partager une simulation avec un collègue
- Pour reproduire un bug dans un environnement identique
- Avant de modifier une simulation complexe

### Comment faire ?

1. Aller dans la page **Simulation MQTT**
2. Configurer votre simulation (entités, microservices, messages)
3. Cliquer sur **Exporter Snapshot**
4. Donner un nom descriptif au snapshot
5. Le fichier JSON est téléchargé

---

## Tableau de décision : Quel système utiliser ?

| Situation                                      | Système recommandé         |
| ---------------------------------------------- | -------------------------- |
| Sauvegarder ma configuration quotidienne       | Configuration applicative  |
| Avant une mise à jour de l'app                 | Configuration applicative  |
| Transférer vers un autre navigateur            | Configuration applicative  |
| Modifier les fichiers `public/data/`           | Fichiers de données GitHub |
| Avant un `git pull`                            | Fichiers de données GitHub |
| Partager une simulation de test                | Snapshot de simulation     |
| Reproduire un bug en simulation                | Snapshot de simulation     |
| Sauvegarde complète avant intervention majeure | Les 3 systèmes             |

---

## Ordre de restauration recommandé

Si vous devez tout restaurer après une perte de données :

1. **Fichiers de données GitHub** (en premier)
   - Restaure les définitions de base (aliases, templates, tags)
   - Nécessaire pour que les autres données soient cohérentes

2. **Configuration applicative** (ensuite)
   - Restaure votre configuration personnalisée
   - Utilise les définitions restaurées à l'étape 1

3. **Snapshots de simulation** (si nécessaire)
   - Restaure vos scénarios de test
   - Indépendant des deux autres

---

## FAQ

### Q: Mes sauvegardes de configuration sont-elles synchronisées entre navigateurs ?

**Non.** Les sauvegardes de configuration sont stockées dans le localStorage, qui est propre à chaque navigateur. Exportez votre sauvegarde et importez-la dans l'autre navigateur.

### Q: L'API Docker n'est pas accessible, que faire ?

Vérifiez que le container Docker est bien lancé et que le port 3001 est accessible. La sauvegarde des fichiers GitHub nécessite cette API.

### Q: Puis-je restaurer une sauvegarde de Production en mode Simulation ?

**Oui, mais avec précaution.** Les données seront importées dans le mode actif. Assurez-vous de bien sélectionner le mode souhaité avant la restauration.

### Q: Les snapshots de simulation incluent-ils les messages MQTT envoyés ?

Les snapshots incluent les **messages programmés** (à envoyer), pas l'historique des messages déjà envoyés.

### Q: À quelle fréquence dois-je faire des sauvegardes ?

- **Configuration applicative** : 1x/semaine ou avant chaque modification importante
- **Fichiers GitHub** : Avant chaque modification manuelle des fichiers
- **Snapshots** : À chaque simulation importante à conserver

---

## Résumé visuel

```
┌─────────────────────────────────────────────────────────────────┐
│                     SYSTÈMES DE SAUVEGARDE                      │
├─────────────────────┬─────────────────────┬─────────────────────┤
│   Configuration     │   Fichiers GitHub   │   Snapshots MQTT    │
│    applicative      │                     │                     │
├─────────────────────┼─────────────────────┼─────────────────────┤
│ • Entités           │ • aliases.json      │ • Entités simulation│
│ • Scénarios         │ • scenario-tags     │ • Microservices     │
│ • Vues              │ • entity-templates  │ • Messages prévus   │
│ • Widgets           │ • Autres fichiers   │                     │
│ • Brokers           │   public/data/      │                     │
├─────────────────────┼─────────────────────┼─────────────────────┤
│ localStorage        │ Fichiers + Docker   │ Export JSON         │
│ (navigateur)        │ API (port 3001)     │ (téléchargement)    │
└─────────────────────┴─────────────────────┴─────────────────────┘
```

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Production](guide-production.md) - Déploiement en production
- [Guide du Mode Simulation](guide-mode-simulation.md) - Environnement de test
- [Guide de Synchronisation GitHub](guide-synchronisation-github.md) - Synchronisation des fichiers
- [Guide de Simulation](guide-simulation.md) - Fonctionnalités de simulation

---

_Documentation NeurHomIA_