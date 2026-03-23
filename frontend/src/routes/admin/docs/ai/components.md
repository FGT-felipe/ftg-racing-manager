# AI Technical Specification: UX & Component System

## 1. Visual Design Tokens

All design values are defined as CSS variables in `src/app.css`. Never use raw hex codes or inline styles.

| Token | Value | Usage |
|---|---|---|
| `--app-bg` / `bg-app-bg` | `#0a0a0c` | Page background |
| `--app-surface` / `bg-app-surface` | `~#111114` | Card and panel surfaces |
| `--app-border` / `border-app-border` | `~rgba(255,255,255,0.08)` | Dividers, card edges |
| `--app-primary` / `text-app-primary` | `#c5a059` | Gold accent, CTA buttons |
| `--app-text` / `text-app-text` | `~#e8e8e8` | Primary text |
| `status-ok` | `text-green-400` | Healthy state indicators |
| `status-warn` | `text-yellow-400` | Caution state |
| `status-crit` | `text-red-400` | Error / critical state |

---

## 2. Animation Specs (Svelte Transitions)

```typescript
import { fly, fade } from 'svelte/transition';

// Page entry (standard)
<div in:fly={{ y: 10, duration: 400 }}>

// Modal overlay
<div transition:fade={{ duration: 200 }} class="backdrop-blur-md">
```

---

## 3. Layout Grid Standards

| Context | System | Ratio | Utility |
|---|---|---|---|
| Racing weekend panels | 12-column | 7/5 left/right | `grid-cols-12`, `col-span-7`, `col-span-5` |
| Grid gap | — | Standard | `gap-5` |
| Vertical container spacing | — | Standard | `space-y-5` |

Files that implement the racing grid: `PracticePanel.svelte`, `QualifyingPanel.svelte`, `StrategyPanel.svelte`, `RaceLivePanel.svelte`.

---

## 4. Component Catalogue

### Layout Components (`src/lib/components/layout/`)

| Component | Responsibility |
|---|---|
| `AppHeader.svelte` | Top navigation bar with team name, budget, notifications |
| `SubNavbar.svelte` | Section-level tab navigation (e.g., Management sub-pages) |
| `NotificationOverlay.svelte` | Slide-in notification tray |
| `InstructionCard.svelte` | Contextual guidance card for onboarding states |

### UI Primitives (`src/lib/components/ui/`)

| Component | Responsibility |
|---|---|
| `GlobalModal.svelte` | Application-wide modal portal (driven by `uiStore`) |
| `ConfirmationModal.svelte` | Generic destructive-action confirmation dialog |
| `Typewriter.svelte` | Animated text reveal for narrative content |
| `CountryFlag.svelte` | ISO country code → flag emoji/image renderer |

### Dashboard (`src/lib/components/dashboard/`)

| Component | Responsibility |
|---|---|
| `RaceStatusHero.svelte` | Race weekend status banner with countdown |
| `PreparationChecklist.svelte` | Race readiness indicator (practice / qualy / strategy / sponsors) |
| `StandingsCard.svelte` | Compact driver/team standings widget |
| `OfficeNews.svelte` | Team news feed from `news` subcollection |
| `DriverSmallCard.svelte` | Compact driver stat card for dashboard |
| `CarSchematic.svelte` | Visual car part levels (Fibonacci upgrade display) |

### Racing (`src/lib/components/racing/`)

| Component | Responsibility |
|---|---|
| `GaragePanel.svelte` | Practice week — car setup, telemetry feedback |
| `PracticePanel.svelte` | Practice session runner |
| `QualifyingPanel.svelte` | Qualifying session with lap timer |
| `StrategyPanel.svelte` | Pre-race strategy configuration |
| `RaceLivePanel.svelte` | Live race monitoring panel |
| `ResultsPanel.svelte` | Post-race results display |
| `tabs/PracticeSetupTab.svelte` | Aero/mechanical setup sliders (practice) |
| `tabs/QualifyingSetupTab.svelte` | Aero/mechanical setup sliders (qualifying) |
| `tabs/RaceSetupTab.svelte` | Tyre compound, fuel load, driving style |

### Shared (`src/lib/components/`)

| Component | Responsibility |
|---|---|
| `DriverAvatar.svelte` | Driver portrait with nationality badge |
| `DriverDetailModal.svelte` | Full driver stats modal |
| `DriverStars.svelte` | Star rating display (1–5 or 1–20 scale) |
| `OnyxTable.svelte` | Styled data table with sorting support |
| `AppLogo.svelte` | FTG branding mark |

---

## 5. Modal Pattern (uiStore)

**All modals must go through `uiStore`.** Never render modals conditionally in leaf components via local `$state` booleans that wrap `<dialog>` — use the centralized system.

```typescript
// Open a modal
import { uiStore } from '$lib/stores/ui.svelte';
uiStore.openModal({ component: MyModal, props: { data } });

// Close from within the modal
uiStore.closeModal();
```

---

## 6. Accessibility Standards

- All interactive elements (`<button>`, `<a>`, `<input>`) must have an `aria-label` and a unique `id`.
- Page titles update via `<svelte:head><title>...</title></svelte:head>` on each route.
- Use semantic HTML elements: `<header>`, `<main>`, `<aside>`, `<section>`, `<nav>`.

---

## 7. Responsive Strategy

- **Mobile First:** All UI is designed for `< 768px` first.
- Breakpoints follow Tailwind defaults: `sm:`, `md:`, `lg:`, `xl:`.
- Racing panels collapse to single-column on mobile (`grid-cols-1 md:grid-cols-12`).
- Navigation collapses to a bottom tab bar on mobile.
