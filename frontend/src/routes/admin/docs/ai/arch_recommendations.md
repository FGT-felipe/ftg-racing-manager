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

### 3.1 App Check — COMPLETE ✅🔒

**What was done:**
- Removed `invoker: "public"` from `megaFixDebriefs`, `forceFixGBA`, `restoreDriversHistory`.
- Added `if (!request.auth) throw new HttpsError("unauthenticated", ...)` to all 3 admin functions.
- Added `enforceAppCheck: true` to all 3 admin functions.
- Added `initializeAppCheck` with `ReCaptchaV3Provider` to `frontend/src/lib/firebase/config.ts`, guarded by `browser` + `VITE_RECAPTCHA_SITE_KEY` env check.
- reCAPTCHA v3 site key registered and active in `.env.local`.

**Needs QA:** Verify admin tools still respond correctly from the browser (App Check token must pass attestation).

### 3.2 Zod Validation on Firestore Writes — COMPLETE ✅

**What was done:**
- Installed Zod v4. Created `src/lib/schemas/car-setup.schema.ts` and `src/lib/schemas/sponsor.schema.ts`.
- `CarSetupSchema` — validates all 11 fields including enum guards on `tyreCompound`, `qualifyingStyle`, `raceStyle`. Called in `PracticeService.savePracticeRun()` before `updateDoc`.
- `ActiveContractSchema` — validates all contract fields before writing to `sponsors.{slot}`. Called in `SponsorService.signContract()` before `runTransaction`.
- Both use `safeParse` + throw with console.error namespace context on failure.

**Needs QA:** Run through practice lap save and sponsor negotiation flows to confirm no regressions.

### 3.3 Repository Pattern (Frontend) — COMPLETE ✅

**What was done:**
- Created `src/lib/repositories/driver.repository.ts` — `docRef()`, `getDriver()`, `getTeamDrivers()`, `updateDriverStats()`.
- Created `src/lib/repositories/team.repository.ts` — `docRef()`, `getTeam()`. No `updateBudget()` — budget mutations must stay in `runTransaction` per §3.3.
- Created `src/lib/repositories/race.repository.ts` — `docRef()`, `getRace()`. Qualifying grid is written by Cloud Functions, not the frontend.
- Refactored `staff.svelte.ts`: removed `doc`, `getDoc`, `getDocs`, `query`, `where` SDK imports; all driver/team document references now go through repositories.

**Design note:** `runTransaction` calls still import Firebase SDK directly — transactions require a shared `transaction` object that can't be abstracted away. Repositories expose `docRef()` so services don't need to construct collection paths themselves.

**Needs QA:** Smoke test staff flows (fitness trainer, driver training, contract renewal).

### 3.4 Web Workers for Race Telemetry — NOT APPLICABLE ⏭️

**Assessment (2026-03-23):** `RaceLivePanel` has no interpolation loop on the main thread. It receives Firestore `onSnapshot` updates and renders them directly. Animations are handled by Svelte (`animate:flip`, `in:slide`), not a JS loop.

**If this ever becomes relevant:** The trigger is implementing smooth position interpolation between snapshots (animating driver positions frame-by-frame between lap updates). At that point, move the interpolation loop to a Web Worker that posts `{ positions }` on each `requestAnimationFrame`, and have the component read from that state only.

### 3.5 SSG for `/admin/docs` — COMPLETE ✅

**What was done:**
- Added `export const prerender = true` to `src/routes/admin/docs/+page.server.ts`.
- Build verified: `build/admin/docs.html` is generated as static HTML with all markdown content embedded at build time. No Firestore reads on load.
- No dynamic dependencies — the `load` function uses only `fs.readFileSync`.

**Needs QA:** Minimal — verify docs page loads and section switching works after deploy.

---

## 4. Not doing (intentional)

- **Playwright E2E tests** — Prohibited per CLAUDE.md. QA is manual.
- **`addPressNews`** — Dead code in `index.js`, confirmed commented out. Not extracted.
- **Flutter codebase** — 100% deprecated. Do not modify.
