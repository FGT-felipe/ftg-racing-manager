# AI Technical Specification: UX & Design System

## Visual Design Tokens
- **Theme**: Premium Dark Gold.
- **Palette**:
  - `bg-base`: #0a0a0c
  - `primary`: #c5a059
  - `status-ok`: #4ade80 (Green-400)
  - `status-warn`: #facc15 (Yellow-400)
  - `status-crit`: #f87171 (Red-400)

## Animation Specs (Svelte Transitions)
- **Page Transitions**: `fly({ y: 10, duration: 400 })`
- **Modal Overlays**: `fade({ duration: 200 })` with `backdrop-blur-md`.

## Accessibility & SEO
- **Semantic HTML**: Use `<header>`, `<main>`, `<aside>`.
- **Interactivity**: All buttons must have unique `id` and `aria-label` for automated testing.
- **Dynamic Meta**: Title updates via `<svelte:head>` based on active route.
## Racing Grid Standards
- **System**: 12-column grid.
- **Ratio**: `7/5` (`col-span-7` Left / `col-span-5` Right).
- **Spacing**: `gap-5` (Grid), `space-y-5` (Containers).
- **Files**: `PracticePanel.svelte`, `QualifyingSetupTab.svelte`, `PracticeSetupTab.svelte`.
