# Guide du Monitoring MQTT 📡

> **Version** : 1.0.0 | **Mise à jour** : Janvier 2026

Ce guide détaille l'utilisation du système de monitoring MQTT amélioré de NeurHomIA.

---

## 📑 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Interface de Monitoring](#interface-de-monitoring)
- [Utilisation Pratique](#utilisation-pratique)
- [Exemples de Payloads](#exemples-de-payloads)
- [Dépannage](#dépannage)
- [Bonnes Pratiques](#bonnes-pratiques)
- [Topics Communs par Type d'Entité](#topics-communs-par-type-dentité)
- [Voir aussi](#-voir-aussi)

---

## Vue d'ensemble

Le monitoring MQTT permet de :
- Surveiller les communications en temps réel
- Envoyer des commandes aux entités
- Diagnostiquer les problèmes de connexion
- Tester les topics et payloads

## Interface de Monitoring

### Accès au Monitoring

1. Naviguez vers **Entités** → **Gestion**
2. Sélectionnez une entité dans la liste
3. Cliquez sur le bouton **Monitorer**

### Workflow de Connexion

Le monitoring MQTT suit un workflow en 3 étapes :

#### 1. Connexion au Broker MQTT
- **Bouton** : "Connecté" / "Déconnecter"
- **Description** : Établit ou coupe la connexion avec le broker MQTT
- **Indicateur** : Badge vert (connecté) ou rouge (déconnecté)

#### 2. Abonnement aux Topics
- **Bouton** : "Abonné" / "Désabonner"
- **Description** : S'abonne aux topics de l'entité pour recevoir les messages
- **Prérequis** : Connexion MQTT active
- **Indicateur** : Badge bleu (abonné) ou gris (non abonné)

#### 3. Envoi de Messages
- **Sélecteur de topic** : Liste déroulante des topics disponibles
- **Champ message** : Payload JSON à envoyer
- **Bouton Envoyer** : Actif uniquement si un topic est sélectionné

## Utilisation Pratique

### Surveiller une Entité

1. **Connectez-vous** au broker MQTT
2. **Abonnez-vous** aux topics de l'entité
3. Les messages apparaîtront en temps réel dans le journal

### Envoyer une Commande

1. Assurez-vous d'être connecté et abonné
2. **Sélectionnez un topic** dans la liste déroulante
3. **Saisissez le payload** JSON (ex: `{"state": "ON"}`)
4. Cliquez sur **Envoyer**

### Aide Contextuelle

- **Bouton d'aide** (icône "?") : Affiche une aide détaillée
- **Tooltips** : Survolez les boutons pour des explications rapides
- **Indicateurs visuels** : Couleurs et icônes pour le statut

## Exemples de Payloads

### Éclairage
```json
{"state": "ON", "brightness": 255}
{"state": "OFF"}
{"color": {"r": 255, "g": 0, "b": 0}}
```

### Capteur de Température
```json
{"temperature": 22.5, "unit": "°C"}
```

### Volet/Store
```json
{"position": 50}
{"state": "OPEN"}
{"state": "CLOSE"}
```

## Dépannage

### Le bouton "Envoyer" est inactif
- ✅ Vérifiez qu'un topic est sélectionné
- ✅ Assurez-vous d'être connecté au broker MQTT

### Aucun message reçu
- ✅ Vérifiez la connexion MQTT
- ✅ Confirmez l'abonnement aux topics
- ✅ Vérifiez que l'entité publie des données

### Erreur de connexion
- ✅ Vérifiez la configuration du broker MQTT
- ✅ Contrôlez les credentials d'authentification
- ✅ Assurez-vous que le broker est accessible

## Bonnes Pratiques

1. **Toujours se connecter** avant de s'abonner
2. **Sélectionner le bon topic** selon l'action souhaitée
3. **Valider le format JSON** avant l'envoi
4. **Utiliser l'aide contextuelle** en cas de doute
5. **Surveiller le journal** pour les erreurs

## Topics Communs par Type d'Entité

### Éclairage
- `state` : État ON/OFF
- `brightness` : Luminosité (0-255)
- `color` : Couleur RGB

### Capteurs
- `state` : Valeur principale du capteur
- `attributes` : Attributs additionnels
- `availability` : Disponibilité de l'entité

### Automatisation
- `command` : Commandes d'action
- `config` : Configuration de l'entité
- `status` : État d'exécution

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation de NeurHomIA
- [Guide de Production](guide-production.md) - Configuration du broker MQTT réel
- [Guide du Mode Simulation](guide-mode-simulation.md) - Test sans infrastructure
- [Guide de Simulation](guide-simulation.md) - Fonctionnalités avancées de simulation
- [Structure JSON Microservices](microservice-json.md) - Format des configurations
- [Préconisations Architecture MCP](guide-preconisations.md) - Standards microservices

---

_Documentation NeurHomIA_
