# Architectural Roadmap — FTG Racing Manager

> Last updated: 2026-03-23. Priority is the backend refactor. Frontend improvements are deferred.

---

## 1. The Core Problem: The Functions Monolith

`functions/index.js` is a **2,696-line JavaScript file** that contains every piece of backend logic. This is the single biggest risk in the project.

### Why it's dangerous

- **Silent failures in strict mode.** Node.js Cloud Functions run with `"use strict"`. An undeclared variable crashes the *entire simulation pipeline* for all leagues. This is exactly what caused R2 and R3 postmortems. TypeScript would catch these at compile time.
- **No isolation.** The `simulateLap()` physics engine, `postRaceProcessing()` economy, the Transfer Market resolver, and admin fix tools all share the same file and scope. A bug in one can silently corrupt another.
- **Untestable.** The sim engine cannot be unit tested in isolation because it's entangled with Firestore calls. There is no way to verify a physics change without deploying and running a full race.
- **Cognitive overload.** The file exceeds the context window of any AI agent and most human developers. Finding the blast radius of a change requires reading thousands of lines.
- **Plain JavaScript.** No type safety, no compile-time checks, no autocomplete contracts between modules.

### Current domain map (what lives in `index.js`)

| Lines | Domain | Responsibility |
|---|---|---|
| 1–25 | Config | `FALLBACK_BONUSES` constants |
| 26–185 | Sponsor | `evaluateObjective()` |
| 186–608 | Circuits | `getCircuit()` — hardcoded circuit data |
| 609–696 | Shared utils | `sleep()`, `addOfficeNews()`, `fetchTeams()` |
| 697–790 | Academy | `generateAcademyCandidate()` |
| 791–1178 | Sim Engine | `simulateLap()`, tire physics, weather, crash logic |
| 1179–1749 | Qualifying | `runQualifyingLogic()` |
| 1750–2286 | Race + Economy | `runRaceLogic()`, `postRaceProcessing()` |
| 2287–2348 | Fitness | `scheduledDailyFitnessRecovery` |
| 2349–2465 | Transfer Market | `resolveTransferMarket` |
| 2466–2696 | Admin tools | `megaFixDebriefs`, `forceFixGBA`, `restoreDriversHistory` |

---

## 2. Target Architecture

### Module structure

```
functions/
├── src/
│   ├── index.ts                        # Entry point — re-exports only, zero logic
│   │
│   ├── config/
│   │   ├── constants.ts                # FALLBACK_BONUSES, NAME_CHANGE_COST, etc.
│   │   └── circuits.ts                 # Circuit definitions (extracted from getCircuit())
│   │
│   ├── shared/
│   │   ├── types.ts                    # All TypeScript interfaces (Team, Driver, Race…)
│   │   ├── firestore.ts                # fetchTeams(), batch helpers, chunk utilities
│   │   └── notifications.ts            # addOfficeNews(), addPressNews()
│   │
│   ├── domains/
│   │   ├── simulation/
│   │   │   ├── sim-engine.ts           # simulateLap() — pure function, zero Firestore
│   │   │   ├── qualifying.ts           # runQualifyingLogic()
│   │   │   └── race-engine.ts          # runRaceLogic()
│   │   │
│   │   ├── economy/
│   │   │   ├── post-race.ts            # postRaceProcessing orchestration
│   │   │   ├── sponsors.ts             # evaluateObjective(), bonus calculations
│   │   │   └── salaries.ts             # Salary + HQ maintenance calculations
│   │   │
│   │   ├── academy/
│   │   │   └── candidate-factory.ts    # generateAcademyCandidate()
│   │   │
│   │   ├── transfer-market/
│   │   │   └── resolver.ts             # resolveTransferMarket
│   │   │
│   │   └── fitness/
│   │       └── recovery.ts             # scheduledDailyFitnessRecovery
│   │
│   └── schedulers/
│       └── jobs.ts                     # All onSchedule + onCall exports wired to domains
│
├── src/__tests__/
│   ├── sim-engine.test.ts              # Unit tests for pure simulation math
│   ├── sponsors.test.ts                # Unit tests for objective evaluation
│   └── economy.test.ts                 # Unit tests for salary/bonus calculations
│
├── package.json                        # + typescript, ts-jest devDependencies
└── tsconfig.json
```

### Design principles

1. **`index.ts` exports only.** No logic lives there. It only imports from `schedulers/jobs.ts`.
2. **`sim-engine.ts` is a pure module.** `simulateLap()` takes data as arguments and returns a result. Zero Firestore calls. This makes it unit-testable without a Firebase emulator.
3. **One file per domain.** No file exceeds 400 lines. If it grows, extract a sub-module.
4. **TypeScript everywhere.** The class of bug from R2/R3 (`let extraCrash` undeclared) becomes a compile error — `tsc` fails before deployment.
5. **Constants are centralized.** No magic numbers in logic files. All business values live in `config/constants.ts`.
6. **Types are shared.** `shared/types.ts` is the single source of truth for data shapes, imported by both domain modules and (eventually) the frontend.

---

## 3. Migration Strategy

**Not a big-bang rewrite.** The current `index.js` stays deployed and functional. Migration happens domain by domain. Each domain is extracted, tested, and the new TypeScript build replaces the equivalent section in `index.js` only when verified.

### Migration order (safest first)

1. **Config + Shared** — No risk. Extract constants, types, and utility functions.
2. **Sim Engine** — Highest value. Extract `simulateLap()` as a pure function and write unit tests. This directly addresses the R2/R3 root cause.
3. **Economy** — Extract sponsor evaluation and salary logic. Unit test `evaluateObjective()`.
4. **Academy + Transfer Market** — Independent domains, low coupling.
5. **Qualifying + Race orchestration** — Depend on Sim Engine and Economy being stable first.
6. **Fitness + Admin tools** — Last, lowest risk.

---

## 4. Functions Directory Cleanup

The `functions/` directory contains ~30 diagnostic/fix scripts and temp JSON files from past incidents. These must be organized before the refactor begins, otherwise the migration creates confusion about what is production code vs. throwaway tooling.

```
functions/
├── src/                    # New TypeScript source (production)
├── scripts/                # Admin + diagnostic scripts (not deployed)
│   ├── emergency/          # Recovery scripts (sync_universe, force_post_race, etc.)
│   └── migrations/         # One-time migration scripts
├── index.js                # Legacy — kept until TypeScript migration completes
└── package.json
```

Temp JSON files (`_adc_temp_*.json`, `_t12.json`, etc.) and log files (`run_log.txt`, `log_post_race.txt`, `eslint_output.txt`) are deleted immediately.

---

## 5. Frontend Architecture (Deferred)

These improvements are valid but blocked on the backend stabilization:

- **Repository Pattern**: Decouple Firestore SDK from Svelte Runes to enable mocked unit tests on the frontend.
- **Web Workers**: Move race telemetry interpolation off the main thread for 60 FPS UI.
- **SSG for docs**: Move `/admin/docs` to static generation to improve LCP.
- **Zod validation**: Schema validation on Firestore writes.
- **App Check**: Zero-trust enforcement on all write Cloud Functions.
- **CI/CD Pipeline**: GitHub Actions — lint + typecheck + test before every deploy.
