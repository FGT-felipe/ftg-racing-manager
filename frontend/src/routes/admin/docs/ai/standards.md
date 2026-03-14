# AI Technical Specification: Development Governance & Rules

This document provides rigid constraints and rules for AI agents modifying this codebase. Adherence to these protocols is mandatory to prevent regression and high-entropy code generation.

## 1. Code Synthesis Protocols (Svelte 5)
- **Rune Enforcement**: NEVER use Svelte 4 `writable` or `readable` stores for local state. Use `$state` and class-based reactive patterns.
- **Dependency Tracking**: Use `$derived` for all state transformations. Do not over-subscribe to Firestore listeners; ensure clean-up on component unmount or effect re-run.
- **Snippet Pattern**: Use `{#snippet children()}` for layout and generic container patterns.

## 2. Persistence & Data Integrity Rules
- **Transactional Safety**: All mutations affecting economic fields (`budget`, `value`, `price`) or relational mapping (`teamId`, `driverId`) MUST be encapsulated in a Firestore `runTransaction` or a server-side Cloud Function.
- **Service Isolation**: Business logic MUST reside in `src/lib/services`. Store orchestration MUST reside in `src/lib/stores`. DO NOT perform direct Firestore calls from `.svelte` component files.
- **Schema Validation**: Before writing to Firestore, validate that types match the existing schema documentation in `services.md`.

## 3. UI/UX Consistency Standards
- **Design Tokens**: Use standard Tailwind utilities. Custom colors must reference `app.css` definitions.
- **Aesthetics**: Maintain the "Premium Dark Gold" aesthetic. High contrast, subtle gradients, and `backdrop-blur` for overlays are standard.
- **Interactivity**: Add `aria-label` and `id` to all interactive elements for automated E2E test targeting.

## 4. Verification & Testing Requirements
- **Unit Testing**: Complex deterministic logic (Finance, Simulation math) MUST include Vitest suites.
- **Error Handling**: Implement specific try-catch blocks with scoped logging: `[COMPONENT_NAME:METHOD] Error description`.
- **Async Safety**: Gated Firebase calls behind `browser` environment checks and/or `authStore.loading` checks to prevent race conditions during SSR.

## 5. Documentation Maintenance
- **Sync Rule**: Every contribution that introduces a new data structure, Service, or Cloud Function contract MUST trigger an update to the corresponding markdown file in `/docs/ai/`.
