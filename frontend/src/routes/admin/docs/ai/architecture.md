# AI Technical Specification: Architecture & State

## System Topology
```yaml
frontend:
  framework: Svelte 5 (Runes)
  state_management: 
    pattern: "Reactive Store-Service"
    stores: "src/lib/stores/*.svelte.ts"
    services: "src/lib/services/*.svelte.ts"
backend:
  infrastructure: Firebase v10+
  compute: Cloud Functions v2 (Node.js 20)
  db: Firestore NoSQL
  auth: Firebase Authentication
```

## State Machine: Auth & Onboarding
```json
{
  "initial": "login",
  "transitions": {
    "login": { "SUCCESS": "checkProfile" },
    "checkProfile": {
      "EXISTS": "checkTeam",
      "MISSING": "/onboarding/create-manager"
    },
    "checkTeam": {
      "EXISTS": "dashboard",
      "MISSING": "/onboarding/team-selection"
    }
  }
}
```

## State Machine: Race Weekend
```json
{
  "states": ["waiting", "practice", "qualifying", "raceStrategy", "race", "postRace"],
  "triggers": {
    "qualifying": "forceQualy (Cloud Function)",
    "race": "forceRace (Cloud Function)",
    "transition": "syncUniverse (Daily/Weekly Schedule)"
  }
}
```
> **⚠️ CRITICAL**: `weekStatus.globalStatus` does NOT exist in the backend. The frontend `/racing` page falls back to `timeService.currentStatus`. When status is `POST_RACE`, the fallback MUST map to `"practice"` to show GaragePanel. See `postmortem_r3_ui.md`.
> For countdowns to a specific session, use `getTimeUntil(RaceWeekStatus.QUALIFYING)` — NOT `getTimeUntilNextEvent()`.


## DevOps & Quality Assurance
- **Deployment**: Firebase Hosting / Cloud Functions v2.
- **CI/CD Target**: GitHub Actions (Not configured).
- **Testing Entrypoints**:
  - Unit: `npm run test` (Vitest).
  - E2E: `npx playwright test` (Partial coverage).
- **Localization**: Manual/Hardcoded. Strategy: Proposed `svelte-i18n`.

## Implementation Blueprints (IA Context)

### 1. Observability: Sentry-SvelteKit
```typescript
// src/hooks.server.ts blueprint
import { handleErrorWithSentry, sentryHandle } from "@sentry/sveltekit";
import { sequence } from "@sveltejs/kit/hooks";

export const handle = sequence(sentryHandle());
export const handleError = handleErrorWithSentry();
```

### 2. CI/CD: GitHub Actions (Firebase)
```yaml
# .github/workflows/deploy.yml
jobs:
  validate:
    steps:
      - run: npm ci
      - run: npm run check
      - run: npm run test
  deploy:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
```

### 3. Error Boundary Pattern
```json
{
  "pattern": "Global Routing Error Catch",
  "implementation": "src/routes/+error.svelte",
  "context": ["auth_failure", "firestore_permission_denied", "route_not_found"]
}
```

## State Reactivity Patterns (Runes)
- Use `$state()` for raw data fetched from Firestore.
- Use `$derived()` for UI-ready transformations (Formatting, filtering).
- Use `untrack()` inside effects that update unrelated stores to prevent circular dependencies.
