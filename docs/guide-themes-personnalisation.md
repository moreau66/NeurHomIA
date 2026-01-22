# Guide des Thèmes et Personnalisation

> Documentation complète du système de thèmes de NeurHomIA : architecture, tokens CSS, personnalisation de l'interface et bonnes pratiques de développement.

---

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture du ThemeProvider](#architecture-du-themeprovider)
3. [Design Tokens CSS](#design-tokens-css)
4. [Configuration Tailwind](#configuration-tailwind)
5. [Utilitaires de Migration](#utilitaires-de-migration)
6. [Fonction cn() pour les Classes](#fonction-cn-pour-les-classes)
7. [Intégration avec les Bibliothèques Tierces](#intégration-avec-les-bibliothèques-tierces)
8. [Animations Personnalisées](#animations-personnalisées)
9. [Personnalisation Avancée](#personnalisation-avancée)
10. [Bonnes Pratiques](#bonnes-pratiques)

---

## Vue d'Ensemble

### Présentation du Système de Thèmes

NeurHomIA dispose d'un système de thèmes complet supportant trois modes :

| Mode | Description |
|------|-------------|
| **Light** | Thème clair avec fond lumineux |
| **Dark** | Thème sombre pour réduire la fatigue visuelle |
| **System** | Détection automatique des préférences système |

### Technologies Utilisées

- **React Context** : Gestion de l'état du thème
- **CSS Custom Properties** : Variables CSS pour les tokens de design
- **Tailwind CSS** : Classes utilitaires mappées sur les tokens
- **localStorage** : Persistance du choix utilisateur

### Architecture du Design System

```
┌─────────────────────────────────────────────────────────────┐
│                    ThemeProvider                            │
│                   (React Context)                           │
│                                                             │
│  • État: theme ("dark" | "light" | "system")               │
│  • Méthode: setTheme()                                     │
│  • Persistance: localStorage("vite-ui-theme")              │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Classe CSS sur <html>                          │
│                                                             │
│  document.documentElement.classList.add("dark" | "light")  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│            Variables CSS (index.css)                        │
│                                                             │
│  :root { --background: 222 33% 97%; ... }                  │
│  .dark { --background: 222 47% 11%; ... }                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│           Tailwind Utilities                                │
│                                                             │
│  bg-background → hsl(var(--background))                    │
│  text-foreground → hsl(var(--foreground))                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Composants UI                                  │
│                                                             │
│  <Card className="bg-card text-card-foreground" />         │
└─────────────────────────────────────────────────────────────┘
```

---

## Architecture du ThemeProvider

### Fichier Principal

**Emplacement :** `src/components/ui/theme-provider.tsx`

### Types et Interface

```typescript
// Types de thèmes supportés
type Theme = "dark" | "light" | "system";

// Props du Provider
type ThemeProviderProps = {
  children: React.ReactNode;
  defaultTheme?: Theme;        // Défaut: "system"
  storageKey?: string;         // Défaut: "vite-ui-theme"
};

// État du contexte
type ThemeProviderState = {
  theme: Theme;
  setTheme: (theme: Theme) => void;
};
```

### Implémentation du Provider

```typescript
export function ThemeProvider({
  children,
  defaultTheme = "system",
  storageKey = "vite-ui-theme",
  ...props
}: ThemeProviderProps) {
  // Récupération du thème depuis localStorage ou utilisation du défaut
  const [theme, setTheme] = useState<Theme>(
    () => (localStorage.getItem(storageKey) as Theme) || defaultTheme
  );

  // Application de la classe CSS sur <html>
  useEffect(() => {
    const root = window.document.documentElement;
    root.classList.remove("light", "dark");

    if (theme === "system") {
      const systemTheme = window.matchMedia("(prefers-color-scheme: dark)")
        .matches
        ? "dark"
        : "light";
      root.classList.add(systemTheme);
      return;
    }

    root.classList.add(theme);
  }, [theme]);

  // Valeur exposée par le contexte
  const value = {
    theme,
    setTheme: (theme: Theme) => {
      localStorage.setItem(storageKey, theme);
      setTheme(theme);
    },
  };

  return (
    <ThemeProviderContext.Provider {...props} value={value}>
      {children}
    </ThemeProviderContext.Provider>
  );
}
```

### Hook useTheme

```typescript
export const useTheme = () => {
  const context = useContext(ThemeProviderContext);

  if (context === undefined)
    throw new Error("useTheme must be used within a ThemeProvider");

  return context;
};
```

### Utilisation dans l'Application

**Wrapping dans App.tsx :**

```tsx
import { ThemeProvider } from "@/components/ui/theme-provider";

function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
      <RouterProvider router={router} />
    </ThemeProvider>
  );
}
```

**Utilisation du Hook :**

```tsx
import { useTheme } from "@/components/ui/theme-provider";

function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  
  return (
    <Button onClick={() => setTheme(theme === "dark" ? "light" : "dark")}>
      {theme === "dark" ? <Sun /> : <Moon />}
    </Button>
  );
}
```

### Persistance et Détection Système

| Fonctionnalité | Implémentation |
|----------------|----------------|
| Stockage | `localStorage.setItem("vite-ui-theme", theme)` |
| Récupération | `localStorage.getItem("vite-ui-theme")` |
| Détection système | `window.matchMedia("(prefers-color-scheme: dark)")` |

---

## Design Tokens CSS

### Fichier Principal

**Emplacement :** `src/index.css`

### Format des Valeurs

Toutes les couleurs sont définies en **HSL sans la fonction hsl()** pour permettre l'utilisation avec l'opacité Tailwind :

```css
/* Définition */
--primary: 240 75% 60%;

/* Utilisation dans Tailwind */
background-color: hsl(var(--primary));           /* Opaque */
background-color: hsl(var(--primary) / 0.5);     /* 50% opacité */
```

### Tokens de Couleurs Principales

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--background` | `222 33% 97%` | `222 47% 11%` | Fond de page principal |
| `--foreground` | `222 84% 4.9%` | `210 40% 98%` | Texte principal |
| `--card` | `0 0% 100%` | `222 47% 14%` | Fond des cartes |
| `--card-foreground` | `222 84% 4.9%` | `210 40% 98%` | Texte des cartes |
| `--popover` | `0 0% 100%` | `222 47% 11%` | Fond des popovers |
| `--popover-foreground` | `222 84% 4.9%` | `210 40% 98%` | Texte des popovers |

### Tokens Sémantiques

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--primary` | `240 75% 60%` | `240 75% 65%` | Actions principales, liens |
| `--primary-foreground` | `210 40% 98%` | `210 40% 98%` | Texte sur primary |
| `--secondary` | `220 14.3% 95.9%` | `217.2 32.6% 17.5%` | Actions secondaires |
| `--secondary-foreground` | `222 47.4% 11.2%` | `210 40% 98%` | Texte sur secondary |
| `--muted` | `210 40% 96.1%` | `217.2 32.6% 17.5%` | Éléments atténués |
| `--muted-foreground` | `215.4 16.3% 46.9%` | `215 20.2% 65.1%` | Texte atténué |
| `--accent` | `262 83% 58%` | `262 83% 58%` | Accent violet |
| `--accent-foreground` | `210 40% 98%` | `210 40% 98%` | Texte sur accent |
| `--destructive` | `0 84.2% 60.2%` | `0 62.8% 30.6%` | Actions dangereuses |
| `--destructive-foreground` | `210 40% 98%` | `210 40% 98%` | Texte sur destructive |

### Tokens de Formulaires

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--border` | `214.3 31.8% 91.4%` | `217.2 32.6% 17.5%` | Bordures générales |
| `--input` | `214.3 31.8% 91.4%` | `217.2 32.6% 17.5%` | Bordures des inputs |
| `--ring` | `240 75% 60%` | `240 75% 65%` | Focus ring |
| `--radius` | `0.5rem` | `0.5rem` | Border radius de base |

### Tokens de Sidebar

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--sidebar-background` | `220 30% 98%` | `222 47% 14%` | Fond de la sidebar |
| `--sidebar-foreground` | `222 47% 11.2%` | `210 40% 98%` | Texte de la sidebar |
| `--sidebar-primary` | `240 75% 60%` | `240 75% 65%` | Éléments actifs |
| `--sidebar-primary-foreground` | `0 0% 100%` | `0 0% 100%` | Texte sur primary |
| `--sidebar-accent` | `240 4.8% 95.9%` | `240 3.7% 25.9%` | Surbrillance au survol |
| `--sidebar-accent-foreground` | `240 5.9% 10%` | `210 40% 98%` | Texte sur accent |
| `--sidebar-border` | `220 13% 91%` | `240 3.7% 25.9%` | Bordures internes |
| `--sidebar-ring` | `240 75% 60%` | `240 75% 65%` | Focus ring sidebar |

### Tokens d'Automation (React Flow)

Ces tokens sont utilisés pour les nœuds du flow builder d'automatisation :

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--automation-blue` | `217 91% 50%` | `217 91% 70%` | Nœuds IF (conditions) |
| `--automation-indigo` | `239 84% 60%` | `239 84% 73%` | Nœuds Device |
| `--automation-purple` | `258 90% 60%` | `258 90% 72%` | Nœuds ELSE |
| `--automation-teal` | `173 80% 35%` | `173 80% 50%` | Nœuds THEN (actions) |

```css
/* Utilisation dans React Flow */
.react-flow__node-if { @apply border-automation-blue; }
.react-flow__node-then { @apply border-automation-teal; }
.react-flow__node-else { @apply border-automation-purple; }
.react-flow__node-device { @apply border-automation-indigo; }
```

### Tokens de Charts (Recharts)

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--chart-1` | `234 89% 73%` | `229 93% 81%` | Série 1 |
| `--chart-2` | `255 91% 76%` | `252 94% 85%` | Série 2 |
| `--chart-3` | `270 95% 75%` | `269 97% 85%` | Série 3 |
| `--chart-4` | `238 83% 66%` | `234 89% 73%` | Série 4 |
| `--chart-5` | `0 0% 45%` | `0 0% 45%` | Série 5 |

### Tokens Typographiques

| Token | Valeur | Usage |
|-------|--------|-------|
| `--font-sans` | `'Lato', ui-sans-serif, system-ui...` | Texte courant |
| `--font-serif` | `'EB Garamond', ui-serif, Georgia...` | Titres élégants |
| `--font-mono` | `'Fira Code', ui-monospace...` | Code et données |

### Tokens de Shadows

| Token | Valeur | Usage |
|-------|--------|-------|
| `--shadow-2xs` | `0 1px 3px 0px hsl(0 0% 0% / 0.05)` | Très subtile |
| `--shadow-xs` | `0 1px 3px 0px hsl(0 0% 0% / 0.05)` | Extra small |
| `--shadow-sm` | `0 1px 3px 0px hsl(0 0% 0% / 0.1), 0 1px 2px -1px...` | Small |
| `--shadow-md` | `0 1px 3px 0px hsl(0 0% 0% / 0.1), 0 2px 4px -1px...` | Medium |
| `--shadow-lg` | `0 1px 3px 0px hsl(0 0% 0% / 0.1), 0 4px 6px -1px...` | Large |
| `--shadow-xl` | `0 1px 3px 0px hsl(0 0% 0% / 0.1), 0 8px 10px -1px...` | Extra large |
| `--shadow-2xl` | `0 1px 3px 0px hsl(0 0% 0% / 0.25)` | Maximum |

### Token Spécial : Zone d'Édition

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--edit-zone-background` | `210 40% 96%` | `230 15% 18%` | Fond des zones d'édition |

```css
.edit-zone {
  @apply bg-[hsl(var(--edit-zone-background))] text-foreground;
}
```

---

## Configuration Tailwind

### Fichier de Configuration

**Emplacement :** `tailwind.config.ts`

### Mapping CSS Variables → Tailwind

```typescript
export default {
  darkMode: ["class"],  // Activation du mode sombre par classe
  theme: {
    extend: {
      colors: {
        // Couleurs de base
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        
        // Couleurs avec variantes
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))'
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))'
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))'
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))'
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))'
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))'
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))'
        },
        
        // Couleurs de sidebar
        sidebar: {
          DEFAULT: 'hsl(var(--sidebar-background))',
          foreground: 'hsl(var(--sidebar-foreground))',
          primary: 'hsl(var(--sidebar-primary))',
          'primary-foreground': 'hsl(var(--sidebar-primary-foreground))',
          accent: 'hsl(var(--sidebar-accent))',
          'accent-foreground': 'hsl(var(--sidebar-accent-foreground))',
          border: 'hsl(var(--sidebar-border))',
          ring: 'hsl(var(--sidebar-ring))'
        },
        
        // Couleurs d'automation
        automation: {
          blue: 'hsl(var(--automation-blue))',
          indigo: 'hsl(var(--automation-indigo))',
          purple: 'hsl(var(--automation-purple))',
          teal: 'hsl(var(--automation-teal))'
        }
      },
      
      // Border radius
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)'
      },
      
      // Box shadows
      boxShadow: {
        '2xs': 'var(--shadow-2xs)',
        xs: 'var(--shadow-xs)',
        sm: 'var(--shadow-sm)',
        md: 'var(--shadow-md)',
        lg: 'var(--shadow-lg)',
        xl: 'var(--shadow-xl)',
        '2xl': 'var(--shadow-2xl)'
      }
    }
  }
} satisfies Config;
```

### Classes Tailwind Générées

| Classe CSS | Variable Utilisée | Exemple d'utilisation |
|------------|-------------------|----------------------|
| `bg-background` | `--background` | `<div className="bg-background">` |
| `text-foreground` | `--foreground` | `<p className="text-foreground">` |
| `bg-primary` | `--primary` | `<button className="bg-primary">` |
| `text-primary-foreground` | `--primary-foreground` | `<span className="text-primary-foreground">` |
| `bg-card` | `--card` | `<Card className="bg-card">` |
| `text-card-foreground` | `--card-foreground` | `<CardContent className="text-card-foreground">` |
| `border-border` | `--border` | `<div className="border border-border">` |
| `shadow-md` | `--shadow-md` | `<Card className="shadow-md">` |
| `rounded-lg` | `--radius` | `<div className="rounded-lg">` |
| `border-automation-blue` | `--automation-blue` | `<div className="border-automation-blue">` |

---

## Utilitaires de Migration

### Fichier d'Utilitaires

**Emplacement :** `src/utils/theme-classes.ts`

### Objet themeClasses

Cet objet facilite la migration des couleurs hardcodées vers les tokens sémantiques :

```typescript
export const themeClasses = {
  // Backgrounds
  bg: {
    page: 'bg-background',           // Fond de page
    card: 'bg-card',                 // Fond de carte
    input: 'bg-input',               // Fond d'input
    muted: 'bg-muted',               // Fond atténué
    accent: 'bg-accent',             // Fond accent
    popover: 'bg-popover',           // Fond popover
  },
  
  // Textes
  text: {
    default: 'text-foreground',      // Texte principal
    card: 'text-card-foreground',    // Texte sur carte
    muted: 'text-muted-foreground',  // Texte atténué
    accent: 'text-accent-foreground',// Texte sur accent
  },
  
  // Borders
  border: {
    default: 'border-border',        // Bordure standard
    input: 'border-input',           // Bordure input
  }
};
```

### Table de Migration

| Ancienne Classe (hardcodée) | Nouvelle Classe (token) |
|-----------------------------|-------------------------|
| `text-white` | `text-foreground` |
| `bg-white` | `bg-background` |
| `text-gray-400` | `text-muted-foreground` |
| `text-gray-300` | `text-muted-foreground` |
| `text-gray-500` | `text-muted-foreground` |
| `bg-gray-100` | `bg-muted` |
| `bg-gray-900` | `bg-background` |
| `bg-[#0f172a]` | `bg-background` |
| `bg-[#1e293b]` | `bg-card` |
| `bg-[#334155]` | `bg-muted` |

### Exemple de Migration

**Avant (couleurs hardcodées) :**
```tsx
<div className="bg-white text-gray-900 border border-gray-200">
  <p className="text-gray-500">Texte secondaire</p>
</div>
```

**Après (tokens sémantiques) :**
```tsx
<div className="bg-background text-foreground border border-border">
  <p className="text-muted-foreground">Texte secondaire</p>
</div>
```

---

## Fonction cn() pour les Classes

### Fichier

**Emplacement :** `src/lib/utils.ts`

### Implémentation

```typescript
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### Fonctionnalités

| Bibliothèque | Rôle |
|--------------|------|
| `clsx` | Concatène les classes conditionnellement |
| `tailwind-merge` | Résout les conflits de classes Tailwind |

### Exemples d'Utilisation

**Classes conditionnelles :**
```tsx
<div className={cn(
  "p-4 rounded-lg",
  isActive && "bg-accent",
  disabled && "opacity-50 pointer-events-none"
)} />
```

**Fusion avec override :**
```tsx
// twMerge résout le conflit : bg-primary gagne
<Button className={cn("bg-secondary", "bg-primary")} />
// Résultat : "bg-primary"
```

**Composant avec classes personnalisables :**
```tsx
interface CardProps {
  className?: string;
  children: React.ReactNode;
}

function Card({ className, children }: CardProps) {
  return (
    <div className={cn(
      "bg-card text-card-foreground rounded-lg shadow-md p-4",
      className  // Permet l'override par le parent
    )}>
      {children}
    </div>
  );
}

// Utilisation
<Card className="shadow-xl">Contenu</Card>
// shadow-xl remplace shadow-md grâce à twMerge
```

---

## Intégration avec les Bibliothèques Tierces

### Sonner (Notifications Toast)

**Fichier :** `src/components/ui/sonner.tsx`

```tsx
import { useTheme } from "@/components/ui/theme-provider";
import { Toaster as Sonner, type ToasterProps } from "sonner";

const Toaster = ({ ...props }: ToasterProps) => {
  const { theme = "system" } = useTheme();

  return (
    <Sonner
      theme={theme as ToasterProps["theme"]}
      className="toaster group"
      toastOptions={{
        classNames: {
          toast:
            "group toast group-[.toaster]:bg-background group-[.toaster]:text-foreground group-[.toaster]:border-border group-[.toaster]:shadow-lg",
          description: "group-[.toast]:text-muted-foreground",
          actionButton:
            "group-[.toast]:bg-primary group-[.toast]:text-primary-foreground",
          cancelButton:
            "group-[.toast]:bg-muted group-[.toast]:text-muted-foreground",
        },
      }}
      {...props}
    />
  );
};
```

### Recharts (Graphiques)

**Fichier :** `src/components/ui/chart.tsx`

Le système de charts utilise les tokens via un mécanisme de thèmes :

```typescript
const THEMES = { light: "", dark: ".dark" } as const;

type ChartConfig = {
  [k in string]: {
    label?: React.ReactNode;
    icon?: React.ComponentType;
  } & (
    | { color?: string; theme?: never }
    | { color?: never; theme: Record<keyof typeof THEMES, string> }
  );
};
```

**Utilisation :**
```tsx
const chartConfig = {
  desktop: {
    label: "Desktop",
    color: "hsl(var(--chart-1))",
  },
  mobile: {
    label: "Mobile",
    color: "hsl(var(--chart-2))",
  },
} satisfies ChartConfig;
```

### React Flow (Automatisation)

**Styles dans :** `src/index.css`

```css
/* Base des nœuds */
.react-flow__node {
  @apply rounded-md bg-card border-2 border-border shadow-md text-sm text-card-foreground;
  padding: 8px;
  width: 180px;
}

/* Types de nœuds avec couleurs spécifiques */
.react-flow__node-if {
  @apply border-automation-blue;
}

.react-flow__node-then {
  @apply border-automation-teal;
}

.react-flow__node-else {
  @apply border-automation-purple;
}

.react-flow__node-device {
  @apply border-automation-indigo;
}

.react-flow__node-event {
  @apply border-accent;
}

.react-flow__node-action {
  @apply border-primary;
}

/* Handles (points de connexion) */
.react-flow__handle {
  @apply bg-primary border-2 border-background w-3 h-3;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: var(--primary);
  border: 2px solid var(--background);
}

.react-flow__handle:hover {
  transform: translate(-50%, -50%) scale(1.3);
  background-color: var(--accent);
}

/* Edges (connexions) */
.react-flow__edge-path {
  stroke-width: 2;
}

.react-flow__edge.selected .react-flow__edge-path,
.react-flow__edge:hover .react-flow__edge-path {
  stroke-width: 3;
  stroke: var(--accent);
}

.react-flow__connection-path {
  stroke: var(--accent);
  stroke-width: 2;
}
```

---

## Animations Personnalisées

### Keyframes Disponibles

| Animation | Description | Durée |
|-----------|-------------|-------|
| `fade-in` | Apparition avec fondu et translation Y | 0.3s |
| `scale-in` | Apparition avec effet de scale | 0.2s |
| `slide-up` | Glissement vers le haut | 0.4s |
| `pulse-slow` | Pulsation lente (opacité) | 2s |
| `pulse-subtle` | Pulsation avec légère mise à l'échelle | 2s |
| `spin-slow` | Rotation continue lente | 3s |
| `simulation-active` | Animation pour le mode simulation | 1.5s |
| `accordion-down` | Ouverture d'accordéon | 0.2s |
| `accordion-up` | Fermeture d'accordéon | 0.2s |

### Définitions des Keyframes

```css
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes scale-in {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes slide-up {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes pulse-subtle {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.8;
    transform: scale(1.1);
  }
}

@keyframes simulation-active {
  0%, 100% {
    transform: scale(1) rotate(0deg);
    opacity: 1;
  }
  50% {
    transform: scale(1.15) rotate(10deg);
    opacity: 0.5;
  }
}
```

### Classes Utilitaires d'Animation

```css
.animate-fade-in {
  animation: fade-in 0.3s ease-out;
}

.animate-scale-in {
  animation: scale-in 0.2s ease-out;
}

.animate-slide-up {
  animation: slide-up 0.4s ease-out;
}

.animate-spin-slow {
  animation: spin-slow 3s linear infinite;
}

.animate-pulse-slow {
  animation: pulse-slow 1s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s ease-in-out infinite;
}

.animate-simulation-active {
  animation: simulation-active 1.5s ease-in-out infinite;
}
```

### Utilisation

```tsx
// Apparition animée d'un élément
<Card className="animate-fade-in">
  Contenu qui apparaît en fondu
</Card>

// Indicateur de chargement rotatif
<Loader2 className="animate-spin-slow h-8 w-8" />

// Élément pulsant pour attirer l'attention
<Badge className="animate-pulse-subtle">Nouveau</Badge>

// Mode simulation actif
<div className={cn(
  "transition-all",
  isSimulating && "animate-simulation-active"
)}>
  État de l'appareil
</div>
```

---

## Personnalisation Avancée

### Créer un Thème Personnalisé

Pour créer une palette de couleurs personnalisée, modifiez les variables dans `src/index.css` :

```css
:root {
  /* Palette verte personnalisée */
  --primary: 142 76% 36%;           /* Vert émeraude */
  --primary-foreground: 0 0% 100%;
  
  --accent: 330 81% 60%;            /* Rose complémentaire */
  --accent-foreground: 0 0% 100%;
  
  /* Ajustez les autres tokens pour harmoniser */
  --ring: 142 76% 36%;
}

.dark {
  /* Versions plus claires pour le mode sombre */
  --primary: 142 76% 46%;
  --accent: 330 81% 70%;
  --ring: 142 76% 46%;
}
```

### Ajouter un Nouveau Token

**Étape 1 : Définir dans index.css**

```css
:root {
  --success: 142 76% 36%;
  --success-foreground: 0 0% 100%;
  --warning: 38 92% 50%;
  --warning-foreground: 0 0% 0%;
}

.dark {
  --success: 142 76% 46%;
  --success-foreground: 0 0% 100%;
  --warning: 38 92% 60%;
  --warning-foreground: 0 0% 0%;
}
```

**Étape 2 : Mapper dans tailwind.config.ts**

```typescript
colors: {
  // ... autres couleurs
  success: {
    DEFAULT: 'hsl(var(--success))',
    foreground: 'hsl(var(--success-foreground))'
  },
  warning: {
    DEFAULT: 'hsl(var(--warning))',
    foreground: 'hsl(var(--warning-foreground))'
  }
}
```

**Étape 3 : Utiliser avec Tailwind**

```tsx
<Badge className="bg-success text-success-foreground">
  Succès
</Badge>

<Alert className="bg-warning/10 border-warning text-warning-foreground">
  Attention
</Alert>
```

### Créer une Variante de Composant

Exemple avec un bouton "premium" :

```tsx
// Dans src/components/ui/button.tsx
const buttonVariants = cva(
  "inline-flex items-center justify-center...",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground...",
        destructive: "bg-destructive text-destructive-foreground...",
        // Nouvelle variante
        premium: [
          "bg-gradient-to-r from-primary to-accent",
          "text-primary-foreground",
          "shadow-lg shadow-primary/25",
          "hover:shadow-xl hover:shadow-primary/30",
          "transition-all duration-300"
        ].join(" "),
      }
    }
  }
);
```

---

## Bonnes Pratiques

### ✅ À Faire

| Pratique | Exemple |
|----------|---------|
| Utiliser les tokens sémantiques | `bg-background`, `text-foreground` |
| Utiliser `cn()` pour les classes conditionnelles | `cn("base", condition && "modifier")` |
| Tester les deux modes (clair/sombre) | Vérifier visuellement chaque composant |
| Grouper les tokens par fonction | background, text, border, etc. |
| Documenter les nouveaux tokens | Ajouter au guide de design |

### ❌ À Éviter

| Anti-pattern | Alternative |
|--------------|-------------|
| Couleurs hardcodées (`text-white`) | Tokens (`text-foreground`) |
| Valeurs HSL dans les composants | Variables CSS |
| Classes Tailwind conflictuelles | Utiliser `cn()` avec twMerge |
| Opacités sur couleurs hardcodées | `hsl(var(--color) / opacity)` |
| Oublier le mode sombre | Toujours définir `.dark` |

### Checklist de Revue de Code

- [ ] Aucune couleur hardcodée (pas de `#hex`, `rgb()`, `text-white`, `bg-gray-*`)
- [ ] Tous les nouveaux tokens définis dans `:root` ET `.dark`
- [ ] Nouveaux tokens mappés dans `tailwind.config.ts`
- [ ] Composants testés en mode clair et sombre
- [ ] Animations accessibles (respect de `prefers-reduced-motion`)
- [ ] Contrastes suffisants (WCAG AA minimum)

### Outils de Débogage

**Inspecter les variables CSS :**
```javascript
// Dans la console du navigateur
getComputedStyle(document.documentElement).getPropertyValue('--primary');
// Retourne : "240 75% 60%"
```

**Forcer un thème temporairement :**
```javascript
document.documentElement.classList.remove('light', 'dark');
document.documentElement.classList.add('dark');
```

---

## Ressources Complémentaires

### Documentation Externe

- [Tailwind CSS - Dark Mode](https://tailwindcss.com/docs/dark-mode)
- [CSS Custom Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties)
- [shadcn/ui - Theming](https://ui.shadcn.com/docs/theming)

### Fichiers de Référence

| Fichier | Description |
|---------|-------------|
| `src/index.css` | Variables CSS et animations |
| `tailwind.config.ts` | Configuration Tailwind |
| `src/components/ui/theme-provider.tsx` | Provider React |
| `src/utils/theme-classes.ts` | Utilitaires de migration |
| `src/lib/utils.ts` | Fonction `cn()` |

---

## Changelog

| Version | Date | Modifications |
|---------|------|---------------|
| 1.0 | 2024-01 | Création initiale du guide |

---

*Guide maintenu par l'équipe NeurHomIA*
