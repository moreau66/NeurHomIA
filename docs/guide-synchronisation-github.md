# Guide de Synchronisation GitHub 📥

> **Version** : 1.0.0 | **Mise à jour** : 2026-02-06T10:00:00

NeurHomIA intègre un système de synchronisation unidirectionnelle avec le dépôt GitHub officiel. Ce système permet de maintenir vos fichiers de données à jour avec les dernières configurations fournies par le développeur.

**Source officielle** : [github.com/moreau66/NeurHomIA](https://github.com/moreau66/NeurHomIA)

> ⚠️ **Important** : La synchronisation est **lecture seule**. Les fichiers sont téléchargés depuis GitHub vers votre installation locale. Vos modifications locales ne sont pas envoyées vers GitHub.

---

## 📑 Table des matières

- [Indicateur dans la Navbar](#-indicateur-dans-la-navbar)
- [Fichiers Synchronisés](#-fichiers-synchronisés)
- [Statuts de Synchronisation](#-statuts-de-synchronisation)
- [Interface de Paramétrage](#-interface-de-paramétrage)
- [Mode API Docker](#-mode-api-docker-automatique)
- [Sauvegarde et Restauration](#-sauvegarde--restauration)
- [Notifications Automatiques](#-notifications-automatiques)
- [Comparaison des Versions](#-comparaison-des-versions)
- [Dépannage](#-dépannage)
- [Voir aussi](#-voir-aussi)

---

## 📍 Indicateur dans la Navbar

Un indicateur visuel dans la barre latérale affiche l'état de synchronisation :

| État | Affichage | Description |
|------|-----------|-------------|
| À jour | ✅ (vert) | Tous les fichiers sont synchronisés |
| Mises à jour | 📥 **3** (badge bleu) | Nombre de fichiers avec mises à jour disponibles |
| Vérification | ⟳ (animation) | Vérification en cours |

L'indicateur reste visible même lorsque la barre latérale est en mode réduit (collapsed).

**Cliquer sur l'indicateur** vous redirige vers les paramètres de synchronisation.

## 📋 Fichiers Synchronisés

Le système surveille les fichiers suivants dans `public/data/` :

| Fichier | Description |
|---------|-------------|
| `aliases.json` | Alias d'entités |
| `dynamic-pages.json` | Pages dynamiques microservices |
| `dynamic-widgets.json` | Widgets dynamiques |
| `entities-category.json` | Catégories d'entités |
| `mqtt-brokers.json` | Configuration des brokers MQTT |
| `scenario-tags.json` | Tags de scénarios |
| `scenario-templates.json` | Templates de scénarios |

## 🔄 Statuts de Synchronisation

Chaque fichier peut avoir l'un des statuts suivants :

| Statut | Icône | Badge | Description |
|--------|-------|-------|-------------|
| `up_to_date` | ✅ | **À jour** (vert) | Le fichier local correspond à la version GitHub |
| `update_available` | ⬇️ | **Mise à jour** (bleu) | Une nouvelle version est disponible sur GitHub |
| `new_file` | 📄 | **Nouveau** (violet) | Le fichier existe sur GitHub mais pas localement |
| `local_only` | ⚠️ | **Local uniquement** (jaune) | Le fichier existe localement mais pas sur GitHub |
| `error` | ❌ | **Erreur** (rouge) | Erreur lors de la vérification |

## 🛠️ Interface de Paramétrage

Accédez aux paramètres via : **Configuration → Synchronisation GitHub** ou cliquez sur l'indicateur dans la navbar.

### Fonctionnalités disponibles

1. **Vérifier** - Vérifie manuellement l'état de tous les fichiers
2. **Tout télécharger** - Télécharge toutes les mises à jour disponibles
3. **Téléchargement individuel** - Télécharge un fichier spécifique

### Tableau des fichiers

Le tableau affiche pour chaque fichier :
- **Fichier** : Nom du fichier avec icône de statut
- **Version locale** : Version ou timestamp du fichier local
- **Version GitHub** : Version ou timestamp sur GitHub
- **Statut** : Badge coloré indiquant l'état
- **Action** : Bouton de téléchargement si disponible

## 🐳 Mode API Docker (Automatique)

Lorsque l'API Docker est disponible (port 3001), les fichiers sont écrits automatiquement dans votre installation.

### Indicateurs API

| État | Affichage |
|------|-----------|
| Connectée | 🔌 **API Docker connectée** + badge "Écriture automatique" (vert) |
| Non disponible | 🔌 **API Docker non disponible** + badge "Téléchargement manuel" (jaune) |

### Configuration Docker

L'API de synchronisation doit être exposée sur le port 3001. Consultez le fichier `docker-compose.yml` pour la configuration.

```yaml
services:
  sync-api:
    # Configuration du service de synchronisation
    ports:
      - "3001:3001"
    volumes:
      - ./public/data:/app/data
```

### Endpoints API

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/api/sync/health` | GET | Vérifie la disponibilité de l'API |
| `/api/sync/write` | POST | Écrit un fichier dans public/data |
| `/api/sync/backup` | GET | Crée une sauvegarde de tous les fichiers |
| `/api/sync/restore` | POST | Restaure depuis un fichier de backup |

## 💾 Sauvegarde & Restauration

### Créer une sauvegarde

1. Cliquez sur **Créer une sauvegarde**
2. Un fichier `data-backup-YYYY-MM-DD.json` est téléchargé
3. Ce fichier contient tous vos fichiers de données

### Restaurer une sauvegarde

1. Cliquez sur **Restaurer...**
2. Sélectionnez un fichier de backup `.json`
3. Les fichiers sont restaurés dans `public/data/`

### Option clearExisting

Lors de la restauration via l'API, l'option `clearExisting` permet de :

- **`false`** (par défaut) : Fusionne avec les fichiers existants
- **`true`** : Supprime tous les fichiers existants avant restauration

> ⚠️ **Attention** : L'option `clearExisting: true` supprime tous les fichiers existants de manière irréversible.

## 🔔 Notifications Automatiques

### Vérification au démarrage

Si l'option **"Vérification automatique au démarrage"** est activée :

1. L'application vérifie les mises à jour au lancement
2. Si des mises à jour sont disponibles, une notification toast apparaît
3. L'indicateur navbar affiche le nombre de mises à jour

### Notifications toast

| Type | Message |
|------|---------|
| ⚠️ Warning | `X mise(s) à jour disponible(s)` |
| ✅ Success | `Tous les fichiers sont à jour` |
| ✅ Success | `X fichier(s) synchronisé(s) automatiquement` |
| ❌ Error | `Erreur lors de la vérification` |

## 🔧 Comparaison des Versions

Le système compare les versions selon cette priorité :

1. **Champ `version`** : Comparaison numérique (ex: 1.0 < 2.0)
2. **Champ `timestamp`** : Comparaison de dates
3. **Hash de contenu** : Longueur du JSON stringifié

```json
{
  "version": "2.1.0",
  "timestamp": "2024-01-15T10:30:00Z",
  "metadata": {
    "author": "NeurHomIA Team"
  },
  // ... données
}
```

## ❓ Dépannage

### L'indicateur ne s'affiche pas

- Vérifiez que la synchronisation est activée dans les paramètres
- Effectuez une vérification manuelle

### API Docker non disponible

- Vérifiez que le conteneur est démarré : `docker ps`
- Vérifiez le port 3001 : `curl http://localhost:3001/api/sync/health`
- Consultez les logs : `docker logs <container_name>`

### Erreur de téléchargement

- Vérifiez votre connexion internet
- Le dépôt GitHub peut être temporairement indisponible
- Essayez de télécharger le fichier manuellement depuis GitHub

### Fichiers non mis à jour après téléchargement manuel

- Placez les fichiers dans `public/data/`
- Rafraîchissez la page de l'application
- Vérifiez les permissions des fichiers

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide de Configuration du Webhook GitHub](guide-webhook-github.md) - Synchronisation automatique via webhook
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Production](guide-production.md) - Déploiement en production
- [Guide des Sauvegardes](guide-sauvegardes.md) - Systèmes de sauvegarde
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications
- [Structure JSON Microservices](microservice-json.md) - Format des configurations

---

_Documentation NeurHomIA_
