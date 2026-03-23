# Architectural Roadmap — FTG Racing Manager

> Last updated: 2026-03-23. Backend refactor complete and deployed. Active focus: frontend quality and security.

---

## 1. Backend Refactor — COMPLETE ✅

The `functions/index.js` monolith has been fully migrated to TypeScript modules.

### What was done

| Épica | Deliverable | Status |
|---|---|---|
| 0 — Cleanup | Moved scripts to `scripts/emergency/` and `scripts/migrations/`. Deleted temp files. Fixed CLAUDE.md. | ✅ |
| 1 — Config + Shared | `config/constants.ts`, `config/circuits.ts`, `shared/types.ts`, `shared/admin.ts`, `shared/utils.ts`, `shared/firestore.ts`, `shared/notifications.ts` | ✅ |
| 2 — Sim Engine | `domains/simulation/sim-engine.ts` (pure, zero Firestore), `qualifying.ts`, `race-engine.ts`. 7 unit tests including R2/R3 regression test. | ✅ |
| 3 — Economy | `domains/economy/sponsors.ts` (pure `evaluateObjective()`), `salaries.ts` (pure calc helpers), `post-race.ts` (orchestrator). 18 unit tests. | ✅ |
| 4 — Independent domains | `domains/academy/candidate-factory.ts`, `domains/fitness/recovery.ts`, `domains/transfer-market/resolver.ts`, `domains/admin/tools.ts` | ✅ |
| 5 — Wiring + Cutover | `schedulers/jobs.ts`, `src/index.ts`, `firebase.json` predeploy, `package.json` main → `lib/index.js` | ✅ Deployed |

### Current module structure

```
functions/
├── src/
│   ├── index.ts                        ← Entry point, re-exports only
│   ├── config/
│   │   ├── constants.ts                ← All business constants
│   │   └── circuits.ts                 ← Circuit definitions
│   ├── shared/
│   │   ├── types.ts                    ← All TypeScript interfaces
│   │   ├── admin.ts                    ← Firebase Admin init
│   │   ├── firestore.ts                ← fetchTeams(), chunkedBatchWrite()
│   │   ├── notifications.ts            ← addOfficeNews()
│   │   └── utils.ts                    ← sleep()
│   ├── domains/
│   │   ├── simulation/
│   │   │   ├── sim-engine.ts           ← simulateLap() — PURE, zero Firestore
│   │   │   ├── qualifying.ts
│   │   │   └── race-engine.ts
│   │   ├── economy/
│   │   │   ├── post-race.ts
│   │   │   ├── sponsors.ts             ← evaluateObjective() — PURE
│   │   │   └── salaries.ts             ← salary/maintenance calcs — PURE
│   │   ├── academy/
│   │   │   └── candidate-factory.ts    ← generateAcademyCandidate() — PURE
│   │   ├── transfer-market/
│   │   │   └── resolver.ts
│   │   ├── fitness/
│   │   │   └── recovery.ts
│   │   └── admin/
│   │       └── tools.ts
│   ├── schedulers/
│   │   └── jobs.ts                     ← All Cloud Function exports
│   └── __tests__/
│       ├── sim-engine.test.ts          ← 7 tests (incl. R2/R3 regression)
│       ├── sponsors.test.ts            ← 5 tests
│       └── economy.test.ts             ← 13 tests
└── index.js                            ← Legacy. Kept for rollback. Deprecate after R(n+1) verified.
```

### Remaining backend task

- **Tarea 5.7**: After the first successful race weekend on the TypeScript build, rename `index.js` → `_legacy_index.js.bak`. Delete after R(n+2).

---

## 2. CI/CD Pipeline — COMPLETE ✅

GitHub Actions workflow at `.github/workflows/ci.yml`. Runs on every PR to `main` and every push to `core/**` branches:

- `functions`: `npm ci` → `typecheck` → `test`
- `frontend`: `npm ci` → `svelte-check`

Prevents broken code from reaching `main`. No secrets required — checks only, no deploy.

---

## 3. Pending Improvements (priority order)

### 3.1 App Check — HIGH PRIORITY 🔒

**Problem:** Several Cloud Functions use `invoker: "public"` — `megaFixDebriefs`, `forceFixGBA`, `restoreDriversHistory`. These are callable by anyone with the project ID.

**Fix:**
1. Enable App Check in Firebase Console with reCAPTCHA v3 for web.
2. Add `enforceAppCheck: true` to all write `onCall` functions in `tools.ts` and any future admin handlers.
3. Remove `invoker: "public"` from admin tools and require Firebase Auth instead.

**Needs QA:** Yes — verify the app still works after App Check is enforced (app must pass the attestation token on every call).

### 3.2 Zod Validation on Firestore Writes — MEDIUM PRIORITY

**Problem:** The frontend writes to Firestore without schema validation. A malformed setup object (e.g., `tyreCompound: null`) can corrupt the simulation.

**Fix:** Add Zod schemas in `src/lib/schemas/` for `CarSetup`, `SponsorContract`, and `TeamWeekStatus`. Validate before every `setDoc`/`updateDoc` call in services.

**Needs QA:** Yes — run through strategy submission, sponsor negotiation, and HQ upgrade flows.

### 3.3 Repository Pattern (Frontend) — MEDIUM PRIORITY

**Problem:** Services call Firestore SDK directly, making them untestable in isolation and tightly coupled to Firebase.

**Fix:** Introduce a thin repository layer:
```
src/lib/repositories/
  ├── driver.repository.ts     ← getDriver(), updateDriverStats()
  ├── team.repository.ts       ← getTeam(), updateBudget()
  └── race.repository.ts       ← getRace(), saveQualyGrid()
```
Services import repositories, not the Firestore SDK directly. Repositories can be swapped for in-memory fakes in tests.

**Needs QA:** Yes — smoke test all service flows after the refactor.

### 3.4 Web Workers for Race Telemetry — LOW PRIORITY

**Problem:** Race live view interpolates lap-by-lap telemetry on the main thread, causing UI jank on low-end devices.

**Fix:** Move the interpolation loop (`RaceLivePanel`) to a Web Worker. The worker posts position updates every frame; the Svelte component only reads state.

**Needs QA:** Yes — verify race live view on mobile.

### 3.5 SSG for `/admin/docs` — LOW PRIORITY

**Problem:** The docs routes (`/admin/docs/**`) are rendered client-side even though they are purely static markdown. This adds unnecessary LCP latency.

**Fix:** Add `export const prerender = true` to each docs layout. Requires verifying all links are static (no dynamic Firestore reads in docs pages).

**Needs QA:** Minimal — verify docs pages load correctly after prerender.

---

## 4. Not doing (intentional)

- **Playwright E2E tests** — Prohibited per CLAUDE.md. QA is manual.
- **`addPressNews`** — Dead code in `index.js`, confirmed commented out. Not extracted.
- **Flutter codebase** — 100% deprecated. Do not modify.
