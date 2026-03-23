# AI Technical Specification: Architecture & State

## System Topology

```yaml
frontend:
  framework: SvelteKit (Svelte 5 Runes)
  language: TypeScript
  styling: Tailwind CSS (custom tokens in app.css)
  state_management:
    pattern: "Reactive Store-Service"
    stores: "src/lib/stores/*.svelte.ts"      # Firestore listeners, reactive state
    services: "src/lib/services/*.svelte.ts"  # Stateless logic, Firebase API
  routing: SvelteKit file-based routing
  hosting: Firebase Hosting

backend:
  infrastructure: Firebase v10+
  compute: Cloud Functions v2 (Node.js 20, strict mode)
  db: Firestore NoSQL
  auth: Firebase Authentication (Google OAuth)
  timezone: America/Bogota (UTC-5)
```

---

## Auth & Onboarding State Machine

```
[Login Page]
    ↓ Google sign-in success
[checkProfile]
    ├─ Profile missing  → /onboarding/create-manager
    └─ Profile exists
         ↓
    [checkTeam]
         ├─ Team missing   → /onboarding/team-selection
         └─ Team exists    → / (Dashboard)
```

---

## Race Weekend State Machine

| Time (COT) | Status | UI Panel Shown |
|---|---|---|
| Mon 00:00 → Sat 13:59 | `practice` | GaragePanel |
| Sat 14:00 | `qualifying` | QualifyingPanel |
| Sat 15:00 | `raceStrategy` | StrategyPanel |
| Sun 14:00 | `race` | RaceLivePanel |
| Sun 16:00 | `postRace` | GaragePanel (fallback) |

> **⚠️ CRITICAL — `weekStatus.globalStatus` does not exist in Firestore.**
> The `/racing` page derives status from `timeService.currentStatus`. When the status is `POST_RACE` (Sunday 16:00+), the UI **must** map it to `"practice"` to render `GaragePanel` — not an empty `RaceLivePanel`.
> See `human/postmortem_r3.md` for the incident history.

> **⚠️ Countdown timers:** Use `getTimeUntil(RaceWeekStatus.QUALIFYING)` to count to a specific session.
> Do NOT use `getTimeUntilNextEvent()` — it counts to the next state transition, which may be Monday 00:00.

---

## Weekend Pipeline (Cloud Functions)

```
Phase 1 — QUALIFYING   Sat 15:00 COT  scheduledQualifying  → writes qualyGrid to Race doc
Phase 2 — RACE         Sun 14:00 COT  scheduledRace        → writes finalPositions, updates drivers/ teams/
Phase 3 — ECONOMY      ~Sun 15:00     postRaceProcessing   → salaries, sponsors, XP, resets weekStatus
Phase 4 — STANDINGS    MANUAL ⚠️      sync_universe.js     → propagates data to universe/game_universe_v1
```

**Critical:** The `/season/standings` page reads from the denormalized `universe/game_universe_v1` document, not from `drivers/` or `teams/` directly. Phases 1–3 do NOT update the universe document. Phase 4 must be run manually after any manual race simulation.

---

## Reactive State Patterns

```typescript
// Raw data from Firestore
let team = $state<Team | null>(null);

// Derived UI-ready values
let formattedBudget = $derived(formatCurrency(team?.budget ?? 0));

// Side effects (Firebase listeners, DOM)
$effect(() => {
  const unsub = onSnapshot(teamDoc, (snap) => {
    team = snap.data() as Team;
  });
  return unsub; // cleanup on unmount
});

// Prevent circular deps when writing to sibling stores
$effect(() => {
  const val = someStore.value;
  untrack(() => { otherStore.update(val); });
});
```

---

## Route Structure

```
src/routes/
├── +layout.svelte              # App shell, auth guard, nav
├── +page.svelte                # Dashboard
├── login/                      # Auth entry point
├── onboarding/
│   ├── create-manager/         # Manager profile creation
│   └── team-selection/         # Claim a bot team
├── racing/
│   ├── +page.svelte            # Race weekend hub (Garage / Qualy / Strategy / Race panels)
│   └── live/                   # Real-time race telemetry
├── season/
│   ├── calendar/
│   └── standings/
├── management/
│   ├── finances/
│   ├── sponsors/
│   └── personnel/
│       ├── drivers/
│       └── fitness/
├── facilities/
│   ├── engineering/
│   ├── garage/
│   └── office/
├── academy/
├── market/
├── settings/
└── admin/
    └── docs/                   # In-app documentation viewer
```

---

## DevOps & Quality Assurance

- **Deployment:** Firebase Hosting (frontend) + Cloud Functions v2 (backend).
- **CI/CD:** Not yet configured (GitHub Actions blueprint exists in `arch_recommendations.md`).
- **Testing:**
  - Unit: `cd frontend && npm run test` (Vitest)
  - E2E: **Playwright is prohibited** — manual QA only.
- **Post-deploy verification:** After deploying `functions/index.js`, confirm in Firebase Console → Functions that the timestamp matches the deployment.

---

## Implementation Blueprints (Future)

### Error Boundary
```
src/routes/+error.svelte  →  handles auth_failure, firestore_permission_denied, route_not_found
```

### Observability (Planned)
```typescript
// src/hooks.server.ts
import { handleErrorWithSentry, sentryHandle } from "@sentry/sveltekit";
import { sequence } from "@sveltejs/kit/hooks";
export const handle = sequence(sentryHandle());
export const handleError = handleErrorWithSentry();
```

### CI/CD (Planned)
```yaml
# .github/workflows/deploy.yml
jobs:
  validate:
    steps:
      - run: npm ci && npm run check && npm run test
  deploy:
    needs: validate
    steps:
      - uses: FirebaseExtended/action-hosting-deploy@v0
```
