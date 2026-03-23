# AI Technical Specification: Development Governance & Standards

> **Scope:** Mandatory rules for any AI agent modifying this codebase. Non-compliance causes regression, silent failures, or financial data corruption.

---

## 1. Code Synthesis Protocols (Svelte 5)

- **Rune Enforcement:** Never use Svelte 4 `writable` or `readable` stores for local state. Use `$state` and class-based reactive patterns exclusively.
- **Derived State:** Use `$derived` for all computed values (formatting, filtering, sorting). Do not subscribe to Firestore inside components.
- **Effects:** Reserve `$effect` for DOM integrations and Firebase SDK listeners. Use `untrack()` inside effects that write to unrelated stores to prevent circular dependencies.
- **Snippets:** Use `{#snippet children()}` for layout delegation and complex UI fragment passing to child components.
- **Cleanup:** `$effect` that opens Firestore listeners must return a cleanup function (unsubscribe).

---

## 2. Architecture: Service / Store Separation (Hard Rule)

```
src/lib/services/*.svelte.ts  →  Stateless logic, Firebase API calls, pure functions
src/lib/stores/*.svelte.ts    →  Reactive state, onSnapshot listeners, UI orchestration
src/routes/**/*.svelte        →  UI only — zero direct Firestore calls allowed
```

- **Prohibition:** Never call `doc()`, `getDoc()`, `setDoc()`, `updateDoc()`, or `collection()` directly from a `.svelte` component file.
- **Transactional Safety:** All mutations to `budget`, driver/team ownership, or economic fields must use `runTransaction` or a server-side Cloud Function. No exceptions.
- **Schema Validation:** Before writing to Firestore, verify types match the existing schema in `database_schema.md`.

---

## 3. UI/UX Consistency Standards

- **Design Tokens:** Use standard Tailwind utilities. Custom colors must reference CSS variables defined in `app.css` (e.g., `bg-app-primary`, `text-app-text`). Never use raw hex codes or inline styles.
- **Aesthetic:** Maintain the "Premium Dark Gold" theme. High contrast, subtle gradients, `backdrop-blur-md` for modal overlays.
- **Modals & Dialogs:** Native browser dialogs (`alert`, `confirm`, `prompt`) are **strictly prohibited**. Use `uiStore` and the custom modal system.
- **Mobile First:** All designs target mobile first, scaling to desktop dashboards. Use responsive Tailwind prefixes (`md:`, `lg:`).
- **Transitions:** Page entries use `fly({ y: 10, duration: 400 })`. Modal overlays use `fade({ duration: 200 })`.
- **Interactivity:** Add `aria-label` and `id` to all interactive elements for semantic accessibility.

---

## 4. Cloud Functions — Strict Mode Safety

Firebase Functions run in Node.js strict mode. Violations only appear in Firebase logs — not in local console output.

### Variable Declaration (Postmortem R2/R3 — Critical Bug Pattern)
```js
// WRONG — ReferenceError in strict mode
if (teamRole === "ex_driver") { extraCrash = 0.001; }

// CORRECT — always declare before conditional assignment
let extraCrash = 0;
if (teamRole === "ex_driver") { extraCrash = 0.001; }
```

### Array Guard Pattern
```js
// WRONG — empty array [] is truthy, causes false-positive skip
if (rSnap.data().qualyGrid) { continue; }

// CORRECT
if (rSnap.data().qualyGrid?.length > 0) { continue; }
```

---

## 5. Error Handling & Quality

- **Silent failures are forbidden.** No empty `catch` blocks.
- **Scoped logging format:** `console.error('[ServiceName:methodName] Error description', error)`
- **Debug logs:** Use `console.debug` during development. Remove all debug logs before production deploy.
- **Async Safety:** Gate Firebase calls behind `browser` checks and/or `authStore.loading` state to prevent SSR hydration race conditions.

---

## 6. Testing

- **Playwright E2E tests are prohibited.** Manual QA is performed by the team.
- **Vitest unit tests are mandatory** for all new deterministic logic: finance calculations, simulation math, service method contracts.
- **Test file convention:** `my_service.svelte.ts` → `my_service.test.ts` (co-located in same directory).

---

## 7. Documentation Maintenance

Every contribution that introduces a new data structure, Service, Store, or Cloud Function contract **must** update the corresponding markdown file in `docs/ai/`. This keeps the AI context accurate for future sessions.
