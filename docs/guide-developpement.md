# Guide de Développement 💻

> **Version** : 0.9.9 | **Mise à jour** : Janvier 2026

Guide rapide pour contribuer au projet NeurHomIA.

---

## 📑 Table des matières

- [Prérequis](#-prérequis)
- [Installation rapide](#-installation-rapide)
- [Structure du projet](#-structure-du-projet)
- [Configuration VSCode](#-configuration-vscode)
- [Conventions de code](#-conventions-de-code)
- [Workflow de contribution](#-workflow-de-contribution)
- [Debugging](#-debugging)
- [Scripts disponibles](#-scripts-disponibles)
- [Questions fréquentes](#-questions-fréquentes)
- [Ressources](#-ressources)
- [Voir aussi](#-voir-aussi)

---

## 📋 Prérequis

### Obligatoire

- **Node.js** >= 18.0 ([télécharger](https://nodejs.org/))
- **npm** >= 8.0 (inclus avec Node.js)
- **Git** ([télécharger](https://git-scm.com/))

### Recommandé

- **VSCode** ([télécharger](https://code.visualstudio.com/))
- **Docker Desktop** (optionnel, pour tester l'intégration complète)

### Vérification de l'installation

```bash
node --version  # v18.0.0 ou supérieur
npm --version   # 8.0.0 ou supérieur
git --version   # 2.x.x ou supérieur
```

---

## 🚀 Installation rapide

### 1. Fork et clone

```bash
# Fork le projet sur GitHub puis clone ton fork
git clone https://github.com/TON-USERNAME/neurhomia.git
cd neurhomia

# Ajoute le repo original comme remote
git remote add upstream https://github.com/neurhomia/neurhomia.git
```

### 2. Installer les dépendances

```bash
npm install
```

Cette commande installe toutes les dépendances du projet :

- React 18 + TypeScript
- Vite (build tool et dev server)
- Radix UI + Tailwind CSS + shadcn/ui
- Zustand + React Query (gestion d'état)
- mqtt.js (client MQTT)

### 3. Démarrer le serveur de développement

```bash
npm run dev
```

➡️ L'application est accessible sur **http://localhost:8080**

#### Hot Reload

Vite détecte automatiquement les modifications de code et recharge la page :

- ⚡ Rafraîchissement instantané des composants React
- 🔄 Rechargement complet si nécessaire
- 📊 Affichage des erreurs dans le navigateur

### 4. Mode simulation MQTT

Par défaut, le projet utilise un **broker MQTT simulé** :

- ✅ Aucune configuration nécessaire
- ✅ Données de test préchargées
- ✅ Voir le badge rouge "Simulation" dans la sidebar

#### Configuration avancée (optionnel)

Pour connecter un broker MQTT réel, créer `.env.local` :

```bash
VITE_MQTT_BROKER_URL=ws://localhost:9001
VITE_MQTT_USERNAME=admin
VITE_MQTT_PASSWORD=changeme
```

Voir `docs/guide-mode-simulation.md` pour plus de détails.

---

## 🏗️ Structure du projet

```
neurhomia/
├── src/
│   ├── components/          # Composants React
│   │   ├── ui/             # Composants de base (shadcn/ui)
│   │   ├── widgets/        # Widgets métiers (météo, capteurs, etc.)
│   │   ├── automation-builder/  # Éditeur d'automatisations
│   │   ├── config/         # Panneaux de configuration
│   │   ├── containers/     # Gestion des containers Docker
│   │   ├── devices/        # Gestion des devices MQTT
│   │   ├── dynamic-pages/  # Pages dynamiques MCP
│   │   ├── layout/         # Layout global (sidebar, header)
│   │   └── ...
│   ├── pages/              # Pages principales (routing)
│   ├── services/           # Services métiers (MQTT, simulation, etc.)
│   ├── store/              # Stores Zustand (état global)
│   ├── types/              # Définitions TypeScript
│   ├── hooks/              # Hooks React personnalisés
│   ├── utils/              # Utilitaires (helpers, formatters)
│   ├── data/               # Données statiques (templates, samples)
│   └── main.tsx            # Point d'entrée
├── docs/                   # Documentation technique
├── mcp-microservice-starter-kit/  # Kit de développement MCP
├── mosquitto/              # Configuration Mosquitto (Docker)
├── public/                 # Assets statiques
├── .env.example            # Variables d'environnement (template)
├── docker-compose.yml      # Orchestration Docker
└── vite.config.ts          # Configuration Vite
```

### Technologies principales

- **React 18** + **TypeScript** - Interface utilisateur
- **Vite** - Build tool et serveur de développement
- **Zustand** - Gestion d'état global (+ persistence localStorage)
- **React Query** - Gestion des données asynchrones
- **Radix UI + Tailwind CSS** - Composants et styling
- **shadcn/ui** - Bibliothèque de composants UI
- **mqtt.js** - Client MQTT pour la communication temps réel

### Patterns et conventions

#### Stores Zustand

Gestion d'état global avec persistance automatique :

```tsx
// src/store/use-devices.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface DevicesStore {
  devices: Device[];
  addDevice: (device: Device) => void;
}

export const useDevices = create<DevicesStore>()(
  persist(
    (set) => ({
      devices: [],
      addDevice: (device) => set((state) => ({
        devices: [...state.devices, device]
      })),
    }),
    { name: 'devices-storage' }
  )
);
```

#### Services

Logique métier isolée :

```tsx
// src/services/mqttService.ts
export class MqttService {
  private client: mqtt.MqttClient | null = null;

  connect(url: string, options: mqtt.IClientOptions) {
    this.client = mqtt.connect(url, options);
  }

  publish(topic: string, message: string) {
    this.client?.publish(topic, message);
  }
}
```

---

## 🎨 Configuration VSCode

### Extensions recommandées

Le projet inclut une liste d'extensions recommandées dans `.vscode/extensions.json`.

VSCode proposera automatiquement de les installer au premier lancement.

**Extensions essentielles** :

- **ESLint** - Linting du code
- **Prettier** - Formatage automatique
- **Tailwind CSS IntelliSense** - Autocomplétion Tailwind
- **TypeScript** - Support TypeScript amélioré
- **Error Lens** - Affichage des erreurs inline

### Settings automatiques

Le fichier `.vscode/settings.json` configure automatiquement :

- ✅ Formatage automatique à la sauvegarde
- ✅ Correction ESLint automatique
- ✅ Support TypeScript du workspace
- ✅ Autocomplétion Tailwind CSS avancée

### Debugging

Configuration disponible dans `.vscode/launch.json` :

1. Ouvrir l'onglet "Run and Debug" (Ctrl+Shift+D)
2. Sélectionner "Debug in Chrome"
3. Appuyer sur **F5** pour démarrer

Points d'arrêt disponibles directement dans VSCode !

---

## 📝 Conventions de code

### Nommage des fichiers

- **Composants** : `PascalCase.tsx` (ex: `TemperatureWidget.tsx`)
- **Hooks** : `use-*.ts` ou `camelCase.ts` (ex: `use-devices.ts`, `useMqtt.ts`)
- **Services** : `camelCase.ts` (ex: `mqttService.ts`)
- **Types** : `kebab-case.ts` (ex: `mqtt-types.ts`)
- **Stores** : `use-{domain}.ts` (ex: `use-devices.ts`)

### Structure d'un composant

```tsx
import { FC } from 'react';
import { Button } from '@/components/ui/button';
import { useDevices } from '@/store/use-devices';

interface DeviceCardProps {
  deviceId: string;
  onToggle?: () => void;
}

export const DeviceCard: FC<DeviceCardProps> = ({ deviceId, onToggle }) => {
  const { devices } = useDevices();
  const device = devices.find(d => d.id === deviceId);

  if (!device) return null;

  return (
    <div className="p-4 border rounded-lg bg-background">
      <h3 className="text-lg font-bold text-foreground">{device.name}</h3>
      <Button onClick={onToggle}>Toggle</Button>
    </div>
  );
};
```

### Règles de style

#### Imports

Ordre recommandé :

1. React et libs externes
2. Composants internes
3. Hooks
4. Services
5. Types
6. Styles

```tsx
// ✅ Bon
import { FC, useState } from 'react';
import { useQuery } from '@tanstack/react-query';

import { Button } from '@/components/ui/button';
import { TemperatureWidget } from '@/components/widgets/TemperatureWidget';

import { useDevices } from '@/store/use-devices';

import { mqttService } from '@/services/mqttService';

import { Device, DeviceType } from '@/types/devices';
```

#### TypeScript

- **Toujours typer** les paramètres et retours de fonction
- **Préférer `interface`** pour les objets
- **Utiliser `type`** pour les unions, intersections
- **Éviter `any`**, préférer `unknown` si nécessaire

```tsx
// ✅ Bon
interface Device {
  id: string;
  name: string;
}

type DeviceType = 'light' | 'sensor' | 'switch';

function formatTemperature(value: number): string {
  return `${value.toFixed(1)}°C`;
}

// ❌ À éviter
function formatTemperature(value: any) {
  return `${value.toFixed(1)}°C`;
}
```

#### Tailwind CSS

- **Utiliser les classes utilitaires** Tailwind
- **Utiliser les tokens sémantiques** (`bg-background`, `text-foreground`, etc.)
- **Éviter les styles inline** sauf cas exceptionnels
- **Utiliser `cn()`** pour combiner les classes conditionnelles

```tsx
import { cn } from '@/lib/utils';

// ✅ Bon - Utilise les variables CSS
<div className={cn(
  "flex items-center gap-2 p-4 bg-background text-foreground",
  isActive && "bg-primary text-primary-foreground",
  isDisabled && "opacity-50 pointer-events-none"
)}>
  {children}
</div>

// ❌ À éviter - Couleurs en dur
<div style={{ backgroundColor: '#fff', color: '#000' }}>
  {children}
</div>
```

### Organisation du code

- **Un composant par fichier**
- **Props typées en haut du fichier**
- **Logique métier dans des hooks personnalisés**
- **JSX lisible** (max 80-100 caractères par ligne)
- **Composants petits et focalisés**

---

## 🤝 Workflow de contribution

### 1. Créer une branche

```bash
# Toujours partir de main à jour
git checkout main
git pull upstream main

# Créer une branche descriptive
git checkout -b feature/nom-de-ta-feature
# ou
git checkout -b fix/nom-du-bug
```

**Convention de nommage des branches** :

- `feature/description` - Nouvelle fonctionnalité
- `fix/description` - Correction de bug
- `docs/description` - Documentation
- `refactor/description` - Refactoring
- `test/description` - Ajout de tests

### 2. Développer

```bash
# Démarrer le serveur de dev
npm run dev

# ... coder ...

# Vérifier le lint
npm run lint

# Tester le build
npm run build
```

### 3. Commits

**Format** :

```
<type>: <description courte>

<description longue optionnelle>
```

**Types** :

- `feat` - Nouvelle fonctionnalité
- `fix` - Correction de bug
- `docs` - Documentation
- `style` - Formatage (sans changement de code)
- `refactor` - Refactoring
- `test` - Ajout de tests
- `chore` - Tâches de maintenance

**Exemples** :

```bash
git commit -m "feat: add temperature widget with unit conversion"
git commit -m "fix: resolve MQTT connection timeout issue"
git commit -m "docs: update installation instructions for Windows"
git commit -m "refactor: migrate useDevices to Zustand v5 API"
```

### 4. Push et Pull Request

```bash
# Push vers ton fork
git push origin feature/nom-de-ta-feature
```

Sur GitHub :

1. Ouvre une Pull Request depuis ton fork vers `neurhomia/neurhomia:main`
2. Remplis le template de PR :
   - Description de la modification
   - Motivation et contexte
   - Type de changement
3. Attends les reviews et applique les suggestions

### 5. Maintenir la branche à jour

```bash
# Récupérer les dernières modifications
git fetch upstream
git rebase upstream/main

# Résoudre les conflits si nécessaire, puis
git push --force-with-lease origin feature/nom-de-ta-feature
```

### Checklist avant PR

- [ ] Le code compile sans erreur (`npm run build`)
- [ ] Le lint passe sans erreur (`npm run lint`)
- [ ] Le code respecte les conventions du projet
- [ ] La documentation est à jour si nécessaire
- [ ] Les commits sont atomiques et bien nommés
- [ ] La branche est à jour avec `main`

---

## 🐛 Debugging

### Chrome DevTools

1. Ouvrir l'application : `http://localhost:8080`
2. Ouvrir DevTools : **F12** ou **Ctrl+Shift+I**
3. **Onglet Sources** : Poser des points d'arrêt dans le code TypeScript
4. **Onglet Console** : Voir les logs et erreurs
5. **Onglet Network** : Analyser les requêtes réseau

### VSCode Debugging

1. Configuration disponible dans `.vscode/launch.json`
2. Appuyer sur **F5** pour démarrer le debugging
3. Points d'arrêt directement dans VSCode
4. Variables inspectables en temps réel

### React DevTools

Installer l'extension navigateur [React DevTools](https://react.dev/learn/react-developer-tools)

Permet de :

- Inspecter l'arbre des composants
- Voir les props et l'état des composants
- Profiler les performances

### MQTT Debugging

**Via l'interface** :

- Menu **"MQTT Logger"** : Logs en temps réel de tous les messages
- Menu **"MQTT Topics"** : Explorer les topics et leurs données
- Menu **"Simulation MQTT"** : Console de debugging du mode simulation

**Ligne de commande** (si Mosquitto installé) :

```bash
# S'abonner à tous les topics
mosquitto_sub -h localhost -p 1883 -u admin -P changeme -t '#'

# S'abonner à un topic spécifique
mosquitto_sub -h localhost -p 1883 -u admin -P changeme -t 'homeassistant/+/+/config'

# Publier un message de test
mosquitto_pub -h localhost -p 1883 -u admin -P changeme -t 'test' -m 'Hello'
```

---

## 🛠️ Scripts disponibles

```bash
# Développement avec hot reload
npm run dev

# Build de production
npm run build

# Build de développement (avec sourcemaps)
npm run build:dev

# Lint du code
npm run lint

# Preview du build de production
npm run preview
```

---

## ❓ Questions fréquentes

### Le serveur ne démarre pas

**Symptômes** :

```
Error: Cannot find module 'vite'
```

**Solution** :

```bash
# Supprimer node_modules et package-lock.json
rm -rf node_modules package-lock.json

# Réinstaller les dépendances
npm install
```

### Hot reload ne fonctionne pas

**Causes possibles** :

- WSL2 (Windows) : Problème de surveillance des fichiers
- Docker : Volumes mal configurés

**Solution (WSL2)** :

Ajouter dans `vite.config.ts` :

```ts
export default defineConfig({
  server: {
    watch: {
      usePolling: true
    }
  }
})
```

### Erreurs TypeScript dans VSCode

**Symptômes** :

- "Cannot find module '@/...'"
- Types non reconnus

**Solution** :

Dans VSCode :

- **Ctrl+Shift+P** → "TypeScript: Restart TS Server"

Si le problème persiste, vérifier que `tsconfig.json` contient :

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

### MQTT ne se connecte pas

**En mode simulation** : Pas besoin de broker externe, la connexion est automatique.

**En mode production** :

1. Vérifier que Mosquitto est démarré :

   ```bash
   docker-compose ps mosquitto
   ```

2. Vérifier les credentials dans `.env.local` :

   ```bash
   VITE_MQTT_BROKER_URL=ws://localhost:9001
   VITE_MQTT_USERNAME=admin
   VITE_MQTT_PASSWORD=changeme
   ```

3. Tester la connexion manuellement :
   ```bash
   mosquitto_sub -h localhost -p 1883 -u admin -P changeme -t test
   ```

### Les widgets dynamiques n'apparaissent pas

1. Vérifier que le mode simulation est activé (badge rouge "Simulation" dans la sidebar)
2. Consulter le **MQTT Logger** pour voir les messages de découverte
3. Vérifier les topics de découverte :
   ```bash
   mosquitto_sub -h localhost -p 1883 -u admin -P changeme -t "+/widget/discovery"
   ```

---

## 📚 Ressources

### Documentation du projet

- [INSTALL.md](INSTALL.md) - Installation et configuration
- [docs/guide-mode-simulation.md](docs/guide-mode-simulation.md) - Mode simulation MQTT
- [docs/microservice-json.md](docs/microservice-json.md) - Structure JSON des microservices
- [mcp-microservice-starter-kit/](mcp-microservice-starter-kit/) - Kit de développement MCP

### Documentation officielle

- [React](https://react.dev/) - Documentation React
- [TypeScript](https://www.typescriptlang.org/docs/) - Documentation TypeScript
- [Vite](https://vitejs.dev/) - Documentation Vite
- [Zustand](https://zustand-demo.pmnd.rs/) - Documentation Zustand
- [Radix UI](https://www.radix-ui.com/) - Documentation Radix UI
- [Tailwind CSS](https://tailwindcss.com/) - Documentation Tailwind
- [MQTT](https://mqtt.org/) - Documentation MQTT

### Communauté

- **Issues** : https://github.com/neurhomia/neurhomia/issues
- **Discussions** : https://github.com/neurhomia/neurhomia/discussions

---

## 🎯 Prochaines étapes

Maintenant que ton environnement est configuré, tu peux :

1. **Explorer le code** : Parcours la structure du projet
2. **Tester le mode simulation** : Active le mode simulation et explore les fonctionnalités
3. **Lire la doc technique** : Consulte `docs/guide-mode-simulation.md`
4. **Créer ta première branche** : Commence à contribuer !

Des guides dédiés seront ajoutés ultérieurement pour :

- 📦 Développement de widgets personnalisés
- 🔌 Développement de microservices MCP
- 🏗️ Architecture MCP détaillée

---

## 📚 Voir aussi

- [Index de la Documentation](index.md) - Page d'accueil de la documentation
- [Guide d'Installation](guide-installation.md) - Installation complète avec Docker
- [Guide de Production](guide-production.md) - Déploiement en production
- [Guide du Mode Simulation](guide-mode-simulation.md) - Environnement de test
- [Préconisations Architecture MCP](guide-preconisations.md) - Standards microservices
- [Structure JSON Microservices](microservice-json.md) - Format des configurations
- [Documentation des Fichiers](DOCUMENTATION-FICHIERS.md) - Vue d'ensemble du code

---

_Documentation NeurHomIA_
