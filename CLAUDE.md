# FTG Racing Manager — Claude Development Guide

## 1. Mandatory Pre-Development Review

Before modifying or creating any module, service, or feature, read the relevant documentation under:

```
frontend/src/routes/admin/docs/ai/
```

| Document | When to read |
|---|---|
| `standards.md` | Always — governs code patterns |
| `architecture.md` | Always — state machines, critical fallbacks |
| `services.md` | When touching services, stores, or Cloud Functions |
| `database_schema.md` | When touching Firestore reads/writes |
| `weekend_pipeline.md` | When touching race simulation or scheduled functions |
| `human/postmortem_r2.md` / `human/postmortem_r3.md` | When modifying `functions/index.js` |
| `human/postmortem_admin_qualy_wipe.md` | When creating or modifying any admin tool |

---

## 2. Technology Stack

This is a **Svelte 5 + Firebase** web application. The Flutter codebase (`lib/`) is **deprecated and must not be modified**. All new development happens in `frontend/`.

```
frontend/        ← SvelteKit 5 (active — all development here)
functions/       ← Firebase Cloud Functions v2 (Node.js 20, strict mode)
lib/             ← DEPRECATED Flutter code. Do not touch.
```

**Frontend stack:** SvelteKit · Svelte 5 Runes · TypeScript · Tailwind CSS · Firebase v10
**Backend:** Firestore · Cloud Functions v2 · Firebase Auth · Firebase Hosting

---

## 3. Core Development Rules

### 3.1 Reactivity (Svelte 5 Runes — Non-negotiable)

- **Use `$state()`** for reactive data from Firestore.
- **Use `$derived()`** for all computed values — formatting, filtering, transformations.
- **Use `$effect()`** sparingly — only for DOM integrations or Firebase SDK synchronization.
- **Never use** Svelte 4 `writable` / `readable` stores for local state.
- **Expose reactive state** via class getters, not raw store exports.

### 3.2 Architecture: Service / Store Separation

```
src/lib/services/*.svelte.ts  →  Stateless logic, pure Firebase API calls
src/lib/stores/*.svelte.ts    →  UI reactivity, Firestore onSnapshot listeners
src/routes/**/*.svelte        →  UI only — NO direct Firestore calls
```

**Hard rule:** Never call `doc()`, `getDoc()`, `setDoc()`, or `collection()` directly from a `.svelte` component file.

### 3.3 Transactional Safety

Every mutation that affects **budget**, driver/team **ownership**, or **economic fields** (`budget`, `value`, `salary`) **must** use `runTransaction` or a server-side Cloud Function.

Silent writes outside transactions are forbidden for these fields.

### 3.4 Error Handling

- Empty `catch` blocks are **forbidden**.
- All errors must be logged with namespace context:
  ```typescript
  console.error('[SponsorService:negotiate] Failed to write transaction:', e);
  ```
- Use `try/catch` at the boundary where recovery or user feedback is possible, not at every line.

### 3.5 UI/UX Standards

- **No browser dialogs.** `alert()`, `confirm()`, and `prompt()` are prohibited. Use `uiStore` and custom modal components.
- **Tailwind CSS only.** No inline styles, no raw hex codes. Custom colors reference variables defined in `app.css`.
- **Design tokens** — All surfaces and colors use CSS variables (`--app-primary`, `--app-surface`, `--app-bg`, etc.). Never reference design values by literal color.
- **Mobile First.** Design for mobile, then scale up to desktop dashboards.
- **Design aesthetic:** Premium Dark Gold — high contrast, subtle gradients, `backdrop-blur` for overlays.

### 3.6 Anti-Hardcoding

Every business value must be centralized:

- **Text:** Use the i18n utility (`src/lib/utils/i18n.ts`) for all user-facing strings.
- **Business constants:** Reference `reglas_negocio.md` and centralize in `src/lib/constants/`. Never embed fees, thresholds, or multipliers directly in logic.
  - Examples: Team rename fee ($500k), HQ maintenance (Level × $15k), XP threshold (500 XP), Fibonacci upgrade multipliers.
- **Firestore config:** Prefer Firestore-stored config for values that change over time.

---

## 4. Cloud Functions — Critical Safety Rules

> **Context:** Functions run in Node.js strict mode. Violations are silent — they fail in Firebase logs only, not in local console.

### 4.1 Variable Declaration (Postmortem R2/R3 — Critical)

**Always declare variables with `let` before any conditional assignment.**

```js
// WRONG — throws ReferenceError in strict mode
if (teamRole === "ex_driver") { extraCrash = 0.001; }
const crashed = Math.random() < (accProb + extraCrash);

// CORRECT
let extraCrash = 0;
if (teamRole === "ex_driver") { extraCrash = 0.001; }
const crashed = Math.random() < (accProb + extraCrash);
```

### 4.2 Array Guard Pattern (Postmortem R2/R3 — Critical)

**Always check `array.length > 0`, not just array existence. Empty arrays are truthy.**

```js
// WRONG — [] is truthy, causes false skip
if (rSnap.data().qualyGrid) { continue; }

// CORRECT
if (rSnap.data().qualyGrid?.length > 0) { continue; }
```

### 4.3 Deploy Verification Rule

After ANY fix to `functions/index.js`, remind the user to:
1. Run `firebase deploy --only functions`
2. Verify in Firebase Console → Functions that the deployment timestamp is current

A local-only fix is **not** a deployed fix. See `postmortem_r3.md` — R2's fix was applied locally but never deployed, causing an identical failure 5 days later.

### 4.4 Admin Tool Safety Rules (Postmortem admin_qualy_wipe — Critical)

**Every admin tool that iterates a collection must have an explicit scope guard and a `// SCOPE:` comment.**

```ts
// WRONG — touches ALL race documents including completed historical rounds
for (const rDoc of racesSnap.docs) {
    racesBatch.update(rDoc.ref, { qualyGrid: [] });
}

// CORRECT — scope guard protects completed documents
// SCOPE: Only unfinished races (isFinished !== true)
for (const rDoc of racesSnap.docs) {
    if (rDoc.data()?.isFinished === true) continue;
    racesBatch.update(rDoc.ref, { qualyGrid: [] });
}
```

**All admin tools that write to Firestore must support dry-run mode** and print a pre-flight summary of affected document IDs before executing any writes.

**Data durability rule:** Any field that feeds statistics, economic history, or classification records must be written to at least two places: the operational collection (mutable) and an immutable append-only collection. Example: `races/{id}.qualyGrid` (operational) + `qualifying_results/{id}` (immutable backup). See T-020.

### 4.5 Universe Sync (Manual Step)

The `/season/standings` page reads from `universe/game_universe_v1` (a denormalized aggregate). After any manual race simulation:

```bash
# Run from /functions directory
node sync_universe.js
```

This step is **not automatic**. Without it, standings remain stale.

---

## 5. Race Weekend State Machine

```
Monday 00:00 → Saturday 13:59  →  practice
Saturday 14:00                  →  qualifying
Saturday 15:00                  →  raceStrategy
Sunday 14:00                    →  race
Sunday 16:00                    →  postRace  (maps to "practice" in UI fallback)
```

**Critical fallback:** `weekStatus.globalStatus` does NOT exist in the backend. The `/racing` page derives status from `timeService.currentStatus`. When status is `POST_RACE`, the UI must map it to `"practice"` to render `GaragePanel` — not `RaceLivePanel` (empty).

**Timers:** Use `getTimeUntil(RaceWeekStatus.QUALIFYING)` for session countdowns — NOT `getTimeUntilNextEvent()`, which counts to the next state change and may return Monday 00:00.

---

## 6. Testing Policy

- **Playwright E2E tests are prohibited.** Do not create, suggest, or run Playwright tests. QA is performed manually by the team.
- **Vitest unit tests are required** for new deterministic logic (finance calculations, simulation math, service methods).
- **Test files live alongside their source:** `service.svelte.ts` → `service.test.ts`.
- **Async safety:** Gate all Firebase calls behind `browser` environment checks and/or `authStore.loading` checks to prevent SSR race conditions.

---

## 7. Documentation Maintenance

When you modify a business rule, data structure, service interface, or architectural pattern, update the corresponding markdown file:

| Change type | Update file |
|---|---|
| New/changed service or store | `ai/services.md` |
| New/changed data shape | `ai/database_schema.md` |
| New business rule or economic value | `human/reglas_negocio.md` |
| New/changed component pattern | `ai/components.md` |
| Simulation or Cloud Function logic | `ai/weekend_pipeline.md` |
| **Any version bump** | `README.md` — update the `**Version:**` line |

**JSDoc is mandatory** for all public methods in services and stores (parameters, return types, side effects).

---

## 8. Emergency Recovery Protocol

If any automated simulation fails, run from `functions/` in order:

```bash
node scripts/emergency/force_race_local.js qualy  # 1. Re-run qualifying
node scripts/emergency/force_race_local.js race    # 2. Re-run race  (or force_race_wrapper.js)
node scripts/emergency/force_post_race.js          # 3. Force economy processing
node scripts/emergency/sync_universe.js            # 4. Sync Standings UI
```

**Do not skip steps.** Each depends on the previous completing cleanly (Exit code 0).

> **Note:** `reset_all.js` and `run_simulation.js` do not exist. Use `force_race_local.js` or `force_race_wrapper.js` for manual race simulation.

---

## 9. Version Control Conventions

### 9.1 Branch Naming

Every branch must use one of these prefixes — never use `feature/` for work that isn't a new user-facing feature:

| Prefix | When to use |
|---|---|
| `feature/` | New user-facing module or functionality |
| `fix/` | Bug fix (any severity) |
| `chore/` | Tech debt, refactoring, docs, tooling, deps — no user-facing change |
| `hotfix/` | Urgent production fix branched directly from `main` |

**Format:** `<type>/<version>-<short-description>` when tied to a version, or `<type>/<short-description>` for isolated work.

```
feature/v4.2.0-transfer-market-filters
fix/v4.1.8-driver-name-truncation
chore/v4.1.7-tech-debt
hotfix/qualifying-crash-loop
```

### 9.2 Commit Messages — Conventional Commits

Format: `<type>(<scope>): <imperative description>`

| Type | When |
|---|---|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `chore` | Tooling, deps, config |
| `refactor` | Code restructure with no behavior change |
| `docs` | Documentation only |
| `style` | Formatting, i18n, visual tweaks |
| `test` | Adding or fixing tests |

### 9.3 Pull Request Structure

Every PR must include these three sections:

```markdown
## Motivation
<Why this change was needed — the problem, constraint, or decision behind it.>

## Summary
<What changed — bullet points.>

## Test plan
<Checklist of what to verify manually.>
```

The **Motivation** section is mandatory — it's the long-term record of *why*, which is never obvious from the diff alone.

### 9.4 Versioning Strategy

- **Patch** (`4.1.x`) — fixes and chore branches
- **Minor** (`4.x.0`) — feature branches adding new functionality
- **Major** (`x.0.0`) — reserved for architectural rewrites

---

## 10. Multi-Task Execution Rule

When the user requests multiple fixes or tasks in a single message, **execute them sequentially, one at a time**. Do not parallelize work across independent tasks.

**Required process:**
1. Pick the first task (prioritize by urgency if indicated).
2. Investigate it fully — read all relevant files before writing code.
3. Implement the fix.
4. Confirm it is correct (verify the right fields, conditions, and data flow).
5. Only then move to the next task.

**Rationale:** Parallel execution causes assumptions to go unverified and fixes to target the wrong fields or conditions — leading to bugs that are worse than the originals.

---

## 11. Propagación de Cambios de Tipo y Semántica (Postmortem T-004 — Critical)

Cuando se cambia el **tipo** o la **semántica** de un campo compartido entre store y componentes, es obligatorio hacer un grep de todos sus consumidores antes de escribir una sola línea de código.

**Regla:** Antes de cambiar el tipo de un campo (ej. `string` → `{ id, sessionId }`) o su semántica (ej. "hay lock" → "hay lock de otro"), ejecutar:

```bash
grep -r "nombreDelCampo" frontend/src --include="*.ts" --include="*.svelte"
```

Luego actualizar **cada** punto de consumo en el mismo commit. Un cambio de tipo con N consumidores debe producir N actualizaciones — no 1.

### Casos concretos que deben disparar este proceso

| Situación | Acción obligatoria |
|---|---|
| Campo Firestore cambia de tipo primitivo a objeto | Grep + actualizar guards de truthiness (`if (x)` → `if (x?.id)`) |
| Semántica de un lock cambia ("existe" → "es de otro") | Grep + actualizar todos los `!!campo` en la UI |
| Prop de componente cambia de condicional a siempre presente | Grep + verificar todos los consumidores del prop |
| Dato disponible en dos fuentes (raw snapshot vs getter gateado) | Siempre usar el getter público del store — nunca el snapshot raw desde un componente |

### Verificación de producto antes de implementar

Antes de escribir código, releer la decisión de producto tal como fue acordada en el planning. Si la implementación contradice lo acordado, **parar y corregir** — no asumir que la interpretación propia es válida.

Ejemplo del T-004: el planning acordó explícitamente "el mismo trainee puede correr múltiples stints, el lock solo bloquea rotar a otro trainee". La implementación hizo lo opuesto. El usuario tuvo que reportarlo como bug.

### Verificación antes de commitear

Después de cualquier cambio que afecte un campo compartido, verificar explícitamente:

1. ¿Todos los `if (campo)` siguen siendo válidos con el nuevo tipo?
2. ¿Todos los props que dependen de este campo están actualizados?
3. ¿La UI consume el getter del store o el snapshot raw? (debe ser el getter)
4. ¿El fix cubre el backend (store/service) **y** el frontend (componente)?

Ver `human/postmortem_t004_academy_practice.md` — 5 bugs en una sola feature por no seguir este proceso.

---

## 12. Implementar Exactamente Lo Que Se Pidió

Las decisiones de producto se acuerdan en el planning (`/start-dev`). La implementación debe respetar esas decisiones al pie de la letra — no interpretarlas, no simplificarlas, no mejorarlas sin autorización.

**Antes de escribir código, releer la decisión de producto acordada.** Si hay ambigüedad, preguntar. No asumir.

Si la implementación contradice lo acordado, es un bug introducido por el desarrollador — no por el usuario.

**Prohibido:**
- Implementar una versión "simplificada" de lo pedido sin avisar
- Tomar decisiones de producto unilateralmente durante la implementación
- Ignorar respuestas dadas durante el Q&A del planning

**El planning existe para evitar re-trabajo. Si se ignora, el re-trabajo es responsabilidad del desarrollador.**

---

## 13. Root Cause Discipline & State Lifecycle (Postmortem v1.7.x)

Four consecutive releases (v1.7.0 → v1.7.3 hotfix) shipped patches to the same subsystem (`weekStatus.driverSetups`) without anyone fixing the actual root cause: `processPostRace` doesn't clear the record between rounds. The rules below codify the lessons. See `human/postmortem_v17_session_gate_cascade.md`.

### 13.1 Identify root cause before writing the fix

Before any P1 fix, write one sentence: *"the bug happens because X writes/doesn't write Y, read by Z."* If you can't write that sentence, you don't understand the bug yet — do not start coding.

When the bad data comes from an upstream write (or absent write), the fix belongs upstream. Patching the read is acceptable only when the upstream is out of scope, **and that case must be logged as debt in the PR description with an explicit TODO**.

### 13.2 Bug-in-other-faces check

Before closing any fix, ask: *"can this same bug appear in a different component that reads the same field?"* If yes, fix it at the source or touch every consumer in the same PR. Do not ship a fix that just relocates the bug.

> v1.7.1 patched `PreparationChecklist`. v1.7.3 patched `QualifyingSetupTab`, `PracticePanel`, `RaceSetupTab`, `StrategyPanel`, and `PreparationChecklist` again. Five components, same root cause, five independent patches.

### 13.3 Walk the state machine before closing the PR

When the change touches a phased subsystem (race weekend, hiring flow, transfer market), write in the PR body how the code behaves in **every phase × every user branch**. For race weekend: 4 phases (practice → qualifying → race strategy → race) × 2 user paths (with practice / without practice) = 8 cells. Skipping a cell is a guaranteed bug in that cell.

> v1.7.3 fixed the tyre compound revert for users who practiced. The "user did not practice this round" branch was never walked. The bug surfaced ~3 hours later in production with players in the active session.

### 13.4 `$effect` never resets state on snapshot re-runs

`$effect` re-runs on every snapshot of the watched store, including unrelated writes (budget, sponsors, charge fees). Resetting `$state` inside `$effect` based on a derived value silently destroys live user input.

State resets inside `$effect` are only allowed when the trigger is a deliberate input change (e.g. `driverId` switch). Track the previous input in a `let` outside `$state` and compare before resetting:

```ts
let loadedDriverId: string | null = null;
$effect(() => {
    if (driverId !== loadedDriverId) {
        loadedDriverId = driverId;
        setup = { ...defaults }; // reset only on driver switch
    }
    // ... load logic that does not clobber live user input
});
```

### 13.5 Strip user-editable fields in every load branch

When a `$effect` loads a saved Firestore object onto a `$state` the user is editing, strip the fields the user controls live (e.g. `tyreCompound`, active sliders) **from every load branch**, not only the main one. The bug always surfaces in the branch you forgot.

```ts
const { tyreCompound: _q, ...quali } = qualifyingObj;  setup = { ...setup, ...quali };
const { tyreCompound: _p, ...prac  } = practiceObj;     setup = { ...setup, ...prac  };
```

### 13.6 `arrayUnion` requires an explicit lifecycle

Any array field written with `arrayUnion` must have a documented "first write of scope" condition that **overwrites** instead of appending. If the data is per-session, the overwrite fires when the sessionId changes.

```ts
async saveQualyResult(..., isFreshSession: boolean) {
    await updateDoc(ref, {
        qualifyingRuns: isFreshSession ? [run] : arrayUnion(run),
    });
}
```

Without this, R(N-1) entries leak into R(N+1) until a manual cleanup is done.

### 13.7 Gate by own sessionId — never by proxy

To check whether data belongs to the current session, compare the sessionId **owned by that data** (`qualifyingSessionId` for qualifying, `raceSessionId` for race strategy). Never use a sibling subsystem's session field as a proxy. A driver may qualify without practicing — using `practice.sessionId` as the qualifying gate hides their fresh data.

### 13.8 Cross-boundary state needs explicit cleanup

Any field that survives beyond its natural lifecycle (across rounds, sessions, requests) is debt unless a cleanup mechanism exists. Document the lifecycle (creation → mutation → cleanup) in `weekend_pipeline.md` or `database_schema.md` before merging.

---

## 14. Hotfix & Deploy Gate

### 14.1 One branch, one objective

If a second bug surfaces during implementation, open a new branch. Branch ballooning is prohibited during hotfix windows. The only exception: bugs that block QA of the original fix — and even then, log them explicitly in the PR.

> `fix/v1.7.3-trainee-standings-name` started as a cosmetic naming fix. It ended up touching 6 files and merging 5 P1s in a single commit, with no individual review. Three hours later, two of them had returned in production.

### 14.2 Hotfix walkthrough is mandatory

Before deploying any hotfix to production, write in chat:
- *the bug was X*
- *the previous line did Y*
- *the new line does Z*
- *the new version does NOT fail in scenarios A, B, C because ...*

If you can't write that, the fix is not ready.

### 14.3 `/deploy` requires explicit text confirmation

A green build is not authorization to deploy. After `npm run build` succeeds, **stop and wait** for the user to type a confirmation (`ship`, `deploy`, `go`) before uploading to hosting. The user is the only QA gate; bypassing it ships untested fixes to live players.

### 14.4 Reporting a fix

When telling the user a bug is fixed, cite four things: file, line, exact change, and **why** the new code prevents the failure. "Fixed, deploying" without those four pieces does not count.

---

## 15. Flutter Deprecation Status

The Flutter codebase (`lib/`, `android/`, `pubspec.yaml`) is **100% migrated** to Svelte. It is kept for reference only. **Do not modify any Flutter files.**

All features previously in Flutter are now implemented in `frontend/`. The Flutter code may be deleted from the repository at any time.
