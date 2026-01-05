# Guide du Webhook GitHub 🔗

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Le webhook GitHub permet une **synchronisation automatique en temps réel** entre votre dépôt GitHub et NeurHomIA.

---

## 📑 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Prérequis](#-prérequis)
- [Configuration Étape par Étape](#-configuration-étape-par-étape)
- [Vérification de la Configuration](#-vérification-de-la-configuration)
- [Sécurité](#-sécurité)
- [Fichiers Déclencheurs](#-fichiers-déclencheurs)
- [Dépannage](#-dépannage)
- [Test Local avec ngrok](#-test-local-avec-ngrok)
- [Voir aussi](#-voir-aussi)

---

## Vue d'ensemble

**Avantages du webhook** :
- 🚀 Synchronisation instantanée (sans intervention manuelle)
- 🔒 Sécurisé par signature HMAC SHA256
- 📊 Traçabilité des événements

> ⚠️ **Prérequis** : Vous devez disposer des droits **administrateur** sur le dépôt GitHub pour configurer un webhook.

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

| Élément | Description |
|---------|-------------|
| Compte GitHub | Avec accès au dépôt cible |
| Droits admin | Droits administrateur sur le dépôt |
| URL publique | URL accessible publiquement pour votre serveur NeurHomIA |
| Secret webhook | Configuré dans NeurHomIA (panneau Configuration → GitHub) |

> 💡 **Astuce** : Pour les tests locaux, utilisez [ngrok](https://ngrok.com) pour exposer votre serveur local (voir section [Test Local avec ngrok](#-test-local-avec-ngrok)).

## 🚀 Configuration Étape par Étape

### Étape 1 : Accéder aux paramètres du dépôt

1. Ouvrez votre dépôt GitHub dans votre navigateur
2. Cliquez sur l'onglet **Settings** (⚙️) en haut à droite
3. Dans le menu latéral gauche, cliquez sur **Webhooks**

```
┌─────────────────────────────────────────────────────────────┐
│  github.com/votre-org/votre-depot                           │
├─────────────────────────────────────────────────────────────┤
│  Code   Issues   Pull requests   Actions   Projects   Wiki  │
│                                                   [Settings]│
├───────────────┬─────────────────────────────────────────────┤
│ General       │                                             │
│ Access        │   Webhooks                                  │
│ ► Webhooks ◄  │   ──────────                                │
│ Branches      │   Webhooks allow external services to be    │
│ Tags          │   notified when certain events happen.      │
│               │                                             │
│               │   [Add webhook]                             │
└───────────────┴─────────────────────────────────────────────┘
```

### Étape 2 : Créer un nouveau webhook

1. Cliquez sur le bouton **Add webhook**
2. GitHub vous demandera peut-être de confirmer votre mot de passe

Vous arrivez sur le formulaire de configuration du webhook.

### Étape 3 : Configurer l'URL du Payload

Remplissez le champ **Payload URL** avec l'URL de votre endpoint webhook :

```
https://votre-serveur.com/api/github/webhook
```

| Champ | Valeur |
|-------|--------|
| **Payload URL** | `https://votre-serveur.com/api/github/webhook` |
| **Content type** | `application/json` |

```
┌─────────────────────────────────────────────────────────────┐
│  Add webhook                                                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Payload URL *                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ https://votre-serveur.com/api/github/webhook        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  Content type                                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ application/json                               ▼    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

> ⚠️ **Important** : L'URL doit être accessible publiquement. GitHub ne peut pas atteindre les serveurs locaux (localhost).

### Étape 4 : Définir le Secret

Le secret permet de vérifier que les requêtes proviennent bien de GitHub.

#### Générer un secret sécurisé

Utilisez l'une de ces méthodes pour générer un secret :

**Option 1 : Ligne de commande (recommandé)**
```bash
openssl rand -hex 32
```

**Option 2 : Via NeurHomIA**
Dans le panneau **Configuration → GitHub Sync**, utilisez le bouton "Générer" pour créer un secret aléatoire.

#### Configuration du secret

1. **Dans GitHub** : Collez le secret dans le champ "Secret"
2. **Dans NeurHomIA** : Collez le même secret dans le champ "Webhook Secret" du panneau GitHub Sync

```
┌─────────────────────────────────────────────────────────────┐
│  Secret                                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ a1b2c3d4e5f6...                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ⓘ Utilisé pour valider la signature des payloads           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

> 🔒 **Sécurité** : Le secret doit être **identique** dans GitHub et NeurHomIA. Ne le partagez jamais publiquement.

### Étape 5 : Sélectionner les événements

Choisissez les événements qui déclencheront le webhook :

1. Sélectionnez **"Just the push event"**
2. Cette option déclenche le webhook uniquement lors des push sur le dépôt

```
┌─────────────────────────────────────────────────────────────┐
│  Which events would you like to trigger this webhook?       │
│                                                              │
│  ○ Just the push event.                        ◄─── Choisir │
│  ○ Send me everything.                                       │
│  ○ Let me select individual events.                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

> 💡 **Note** : NeurHomIA traite uniquement les événements `push`. Les autres événements seront ignorés.

### Étape 6 : Activer et créer le webhook

1. Assurez-vous que la case **"Active"** est cochée
2. Cliquez sur le bouton **"Add webhook"**

```
┌─────────────────────────────────────────────────────────────┐
│  ☑ Active                                                    │
│  We will deliver event details when this hook is triggered.  │
│                                                              │
│                              [Add webhook]                    │
└─────────────────────────────────────────────────────────────┘
```

GitHub envoie automatiquement un **ping** de test. Si tout est configuré correctement, vous verrez un message de succès.

## ✅ Vérification de la Configuration

### Test avec le Webhook Tester

NeurHomIA inclut un outil de test intégré :

1. Accédez à **Configuration → GitHub Sync**
2. Dépliez la section **"Testeur de Webhook"**
3. Sélectionnez le type d'événement (push ou ping)
4. Cliquez sur **"Envoyer le test"**

### Vérification dans GitHub

1. Retournez dans **Settings → Webhooks**
2. Cliquez sur votre webhook
3. Allez dans l'onglet **"Recent Deliveries"**

| Code réponse | Signification |
|--------------|---------------|
| ✅ 200 | Succès - Le webhook fonctionne |
| ❌ 401 | Erreur d'authentification (secret incorrect) |
| ❌ 404 | URL non trouvée |
| ❌ 500 | Erreur serveur |
| ⚠️ Timeout | Serveur non accessible |

## 🔒 Sécurité

### Signature HMAC SHA256

GitHub signe chaque payload avec votre secret en utilisant HMAC SHA256 :

```
X-Hub-Signature-256: sha256=<signature>
```

NeurHomIA vérifie cette signature avant de traiter le webhook. Si la signature ne correspond pas, la requête est rejetée avec une erreur 401.

### Bonnes pratiques

| Pratique | Raison |
|----------|--------|
| 🔒 Utilisez HTTPS | Chiffre les données en transit |
| 🔑 Secret fort | Minimum 32 caractères aléatoires |
| 🔄 Rotation régulière | Changez le secret périodiquement |
| 📋 Ne pas exposer | Ne commitez jamais le secret dans le code |
| 🛡️ Validez la signature | Toujours vérifier X-Hub-Signature-256 |

## 🔧 Fichiers Déclencheurs

Le webhook déclenche la synchronisation pour ces fichiers :

| Chemin dans GitHub | Fichier local | Description |
|--------------------|---------------|-------------|
| `data/aliases.json` | `public/data/aliases.json` | Alias d'entités |
| `data/dynamic-pages.json` | `public/data/dynamic-pages.json` | Pages dynamiques |
| `data/dynamic-widgets.json` | `public/data/dynamic-widgets.json` | Widgets dynamiques |
| `data/entities-category.json` | `public/data/entities-category.json` | Catégories d'entités |
| `data/mqtt-brokers.json` | `public/data/mqtt-brokers.json` | Configuration MQTT |
| `data/scenario-tags.json` | `public/data/scenario-tags.json` | Tags de scénarios |
| `data/scenario-templates.json` | `public/data/scenario-templates.json` | Templates de scénarios |

> 💡 Les modifications sur d'autres fichiers ne déclenchent pas de synchronisation.

## ❓ Dépannage

### Le webhook ne se déclenche pas

| Vérification | Solution |
|--------------|----------|
| URL accessible | Testez l'URL dans un navigateur |
| Webhook actif | Vérifiez la case "Active" dans GitHub |
| Événements | Vérifiez que "push" est sélectionné |
| Logs GitHub | Consultez "Recent Deliveries" |

### Erreur 401 Unauthorized

Le secret est incorrect ou manquant :

1. Vérifiez que le secret dans GitHub correspond exactement à celui dans NeurHomIA
2. Attention aux espaces en début/fin de chaîne
3. Régénérez un nouveau secret si nécessaire

### Erreur 500 Internal Server Error

Problème côté serveur NeurHomIA :

1. Consultez les logs de l'application
2. Vérifiez la configuration MQTT
3. Assurez-vous que le service de synchronisation fonctionne

### Timeout

Le serveur NeurHomIA n'est pas accessible :

1. Vérifiez que le serveur est démarré
2. Vérifiez les règles de firewall
3. Pour les tests locaux, utilisez ngrok

## 🧪 Test Local avec ngrok

Pour tester le webhook en environnement de développement local :

### Installation de ngrok

```bash
# macOS
brew install ngrok

# npm (toutes plateformes)
npm install -g ngrok

# Ou téléchargez depuis https://ngrok.com/download
```

### Exposition du serveur local

```bash
# Exposez votre serveur local (port 5173 par défaut pour Vite)
ngrok http 5173
```

ngrok affiche une URL publique :

```
Forwarding  https://abc123.ngrok.io -> http://localhost:5173
```

### Configuration dans GitHub

Utilisez l'URL ngrok comme Payload URL :

```
https://abc123.ngrok.io/api/github/webhook
```

> ⚠️ **Note** : L'URL ngrok change à chaque redémarrage (sauf avec un compte payant).

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide de Synchronisation GitHub](guide-synchronisation-github.md) - Synchronisation manuelle des fichiers
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Production](guide-production.md) - Déploiement en production
- [Guide du Monitoring MQTT](guide-monitoring-mqtt.md) - Surveillance des communications
- [Structure JSON Microservices](microservice-json.md) - Format des configurations

---

_Documentation NeurHomIA_
