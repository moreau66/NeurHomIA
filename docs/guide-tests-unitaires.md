# Guide des Tests Unitaires — NeurHomIA

> **Version** : 1.0.0 | **Mise à jour** : 2026-03-08T10:00:00

## Table des matières

1. [Introduction](#introduction)
2. [Stack de Tests](#stack-de-tests)
3. [Configuration](#configuration)
4. [Écriture de Tests](#écriture-de-tests)
5. [Modules Testés](#modules-testés)
6. [Conventions](#conventions)
7. [Exécution](#exécution)

---

## Introduction

NeurHomIA utilise **Vitest** comme framework de tests unitaires pour le frontend React/TypeScript. Les tests couvrent les services critiques : logger centralisé, matching de topics MQTT, et calcul d'entités dérivées.

### Objectifs

- ✅ Valider la logique métier sans dépendance au DOM
- ✅ Tester les conversions et mappings de données
- ✅ Vérifier le matching MQTT avec wildcards `+` et `#`
- ✅ Garantir la non-régression après refactoring

---

## Stack de Tests

| Package | Version | Rôle |
|---------|---------|------|
| `vitest` | ^3.x | Runner de tests, assertions |
| `@testing-library/react` | ^16.x | Rendu de composants React |
| `@testing-library/jest-dom` | ^6.x | Matchers DOM étendus |
| `jsdom` | ^20.x | Environnement DOM simulé |

---

## Configuration

### Fichier `vitest.config.ts`

```typescript
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react-swc";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/*.{test,spec}.{ts,tsx}"],
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
});
```

### Fichier `src/test/setup.ts`

```typescript
import "@testing-library/jest-dom";

Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => {},
  }),
});
```

### TypeScript : `tsconfig.app.json`

Ajouter `"vitest/globals"` dans `compilerOptions.types` :

```json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  }
}
```

---

## Écriture de Tests

### Structure d'un Test

```typescript
import { describe, it, expect } from "vitest";

describe("NomDuModule", () => {
  describe("fonctionnalité", () => {
    it("décrit le comportement attendu", () => {
      const result = maFonction(input);
      expect(result).toBe(expected);
    });
  });
});
```

### Mocking

```typescript
import { vi } from "vitest";

// Espionner une méthode console
const spy = vi.spyOn(console, "warn").mockImplementation(() => {});
expect(spy).toHaveBeenCalledWith("message");

// Mock d'un module
vi.mock("@/store/use-entities", () => ({
  useEntities: { getState: () => ({ entities: [] }) },
}));
```

---

## Modules Testés

### 1. Logger Centralisé (`logger.ts`)

**Fichier de test** : `src/test/logger.test.ts`

| Test | Description |
|------|-------------|
| `debug calls console.log` | Vérifie que `logger.debug()` appelle `console.log` en dev |
| `info calls console.info` | Vérifie que `logger.info()` appelle `console.info` |
| `warn calls console.warn` | Vérifie que `logger.warn()` est toujours actif |
| `error calls console.error` | Vérifie que `logger.error()` est toujours actif |
| `createScope prefixes` | Vérifie que le préfixe est ajouté automatiquement |

**Architecture du logger** :
- En production (`import.meta.env.PROD`) : seuls `warn` et `error` sont émis
- En développement : tous les niveaux sont actifs
- `createScope('[Prefix]')` crée un sous-logger préfixé

**Services migrés vers le logger** :
- `widgetDiscoveryService.ts`
- `microserviceSimulationDiscoveryService.ts`
- `meteoMqttService.ts`
- `watchtowerService.ts`
- `scenarioLifecycleService.ts`
- `calculatedEntityService.ts`
- `entityDiscoveryService.ts`

### 2. Topic Matcher MQTT (`mqttTopicMatcher.ts`)

**Fichier de test** : `src/test/mqttTopicMatcher.test.ts`

| Test | Description |
|------|-------------|
| Exact match | Topics identiques → `true` |
| Différents topics | Topics différents → `false` |
| Wildcard `+` | Remplace un seul niveau |
| Multiple `+` | Plusieurs wildcards single-level |
| Wildcard `#` | Remplace tous les niveaux restants |
| `#` en fin seulement | `#` au milieu → invalide |
| Combinaison `+` et `#` | `home/+/#` matche `home/salon/temp/value` |
| Topics MCP | `mcp/+/heartbeat` matche les heartbeats |

**Règles MQTT wildcards** :
- `+` : remplace exactement **un** niveau de topic
- `#` : remplace **zéro ou plusieurs** niveaux, uniquement en dernière position
- `#` seul matche **tous** les topics

### 3. Service de Calcul d'Entités (`calculatedEntityService.ts`)

**Fichier de test** : `src/test/calculatedEntityService.test.ts`

| Catégorie | Tests |
|-----------|-------|
| **validateConfig** | Source entities vide, interval manquant, formule custom absente, config valide |
| **Température** | C→F, F→C, K→C, NaN → valeur par défaut |
| **Value mapping** | numeric→boolean, string→boolean, range→boolean, normalisation 0-1 |
| **Batterie** | Niveaux Critical/Low/Medium/High |
| **Unités** | Mètres↔centimètres, pieds↔mètres |
| **Source values** | Stockage/récupération, entité inconnue |

---

## Conventions

### Nommage des Fichiers

| Pattern | Utilisation |
|---------|-------------|
| `*.test.ts` | Tests de logique pure (services, utilitaires) |
| `*.test.tsx` | Tests de composants React |
| `src/test/` | Répertoire principal des tests |
| `__tests__/` | Alternative : tests à côté des composants |

### Bonnes Pratiques

1. **Un `describe` par module/classe** — regroupe les tests logiquement
2. **Tests atomiques** — chaque `it()` teste un seul comportement
3. **Noms descriptifs** — le nom du test doit décrire le comportement attendu
4. **Pas de dépendances inter-tests** — chaque test est indépendant
5. **Mock minimal** — ne mocker que ce qui est strictement nécessaire
6. **Tester les cas limites** — NaN, undefined, tableaux vides, etc.

### Organisation par Catégorie

```
src/test/
├── setup.ts                          # Configuration globale
├── logger.test.ts                    # Tests du logger centralisé
├── mqttTopicMatcher.test.ts          # Tests du topic matcher MQTT
├── calculatedEntityService.test.ts   # Tests du service de calcul
└── [futurs tests...]
```

---

## Exécution

Les tests sont exécutés via Vitest dans l'environnement Lovable. Résultat actuel :

```
✓ src/test/mqttTopicMatcher.test.ts         (14 tests)
✓ src/test/logger.test.ts                   (5 tests)
✓ src/test/calculatedEntityService.test.ts  (17 tests)

Test Files  3 passed (3)
     Tests  36 passed (36)
```

---

## Prochaines Étapes

| Module | Priorité | Description |
|--------|----------|-------------|
| `entityDiscoveryService` | 🟡 Moyenne | Tests de découverte d'entités MQTT |
| `mqttSimulation` | 🟡 Moyenne | Tests du service de simulation |
| Stores Zustand | 🟢 Basse | Tests des stores `use-entities`, `use-containers` |
| Composants React | 🟢 Basse | Tests de rendu avec `@testing-library/react` |

---

*Guide v1.0.0 — NeurHomIA Tests Unitaires — 8 mars 2026*
