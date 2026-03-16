# AI Spec: Weekend Event Pipeline & Emergency Recovery Protocol

## 1. Overview

The weekend event system executes in a sequential, multi-step pipeline across two days. Each step depends on the previous one completing successfully. The system is partially automated via Firebase Cloud Functions Scheduled Jobs, and partially requires manual script execution.

**Critical Architectural Constraint:** All leagues share ONE `currentSeasonId`. Therefore, Race documents (`{seasonId}_r2`, `{seasonId}_r3`) are shared across leagues. A race is considered global — not per-league. The qualifying grid contains ALL drivers from ALL leagues combined.

---

## 2. Complete Pipeline Specification

### Phase 1 — QUALIFYING (Saturday 15:00 COT)
**Trigger:** `exports.scheduledQualifying` (`onSchedule("0 15 * * 6")`)  
**Function:** `runQualifyingLogic()` in `functions/index.js`

**Execution:**
1. Reads `universe.leagues[]` to get all active leagues
2. For each league, reads `league.teams` array → extracts `teamId[]`
3. Calls `fetchTeams(teamIds)` → returns `DocumentSnapshot[]`
4. For each team, queries `drivers collection where teamId == team.id`
5. For each driver, reads `weekStatus.driverSetups[driverId].qualifying` for submitted setup
6. Calls `simulateLap(driver, setup, circuit, managerRole)` → returns `{ lapTime, isCrashed }`
7. Sorts by lapTime ascending → builds `qualyGrid` array
8. Writes to Race document:
   - `qualyGrid: DriverResult[]`
   - `qualifyingResults: DriverResult[]`
   - `status: "qualifying"`

**Guard Condition (CRITICAL):**
```js
// CORRECT — checks array has content
if (rSnap.data().qualyGrid && rSnap.data().qualyGrid.length > 0) {
  logger.info("[QUALY SKIP] qualyGrid already exists...");
  continue;
}
// WRONG — empty array [] is truthy in JS, causes false skip
if (rSnap.data().qualyGrid) { continue; }
```

### Phase 2 — RACE (Sunday 14:00 COT)
**Trigger:** `exports.scheduledRace` (`onSchedule("0 14 * * 0")`)  
**Function:** `runRaceLogic()` in `functions/index.js`

**Execution:**
1. For each league, reads Race document `{seasonId}_{raceEventId}`
2. Verifies `qualyGrid.length > 0` — skips if not ready
3. Simulates full race using `raceEngine.simulateRace(qualyGrid, circuit, setups)`
4. Commits via `statsBatch`:
   - `drivers/{id}`: `seasonPoints += pts`, `seasonRaces++`, `seasonWins++`, `form`, `stats.morale`, `championshipForm`
   - `teams/{id}`: `budget += prize`, `seasonPoints += pts`, `seasonRaces++`, `seasonWins++`
5. Updates Race document: `finalPositions`, `raceResults`, `totalTimes`, `dnfs`, `fast_lap_driver`, `isFinished: true`, `status: "completed"`
6. Updates Season calendar: `calendar[rIdx].isCompleted = true`
7. Sets `postRaceProcessingAt = now + 1h` and `postRaceProcessed: false` on Race document

### Phase 3 — POST-RACE ECONOMY (fires ~1h after race)
**Trigger:** `exports.postRaceProcessing` (`onSchedule("*/30 * * * *")`)  
**Condition:** `race.isFinished == true AND race.postRaceProcessed == false AND now >= race.postRaceProcessingAt`

**Execution:**
1. Reads `race.finalPositions` → extracts participating `driverIds`
2. Builds `teamIdsSet` from driver docs
3. Builds `managerRoles` map: `{ teamId → managerRole }`
4. For each team, processes weekly economy:
   - **Driver salaries**: `driver.salary / 52` per week, +20% if `managerRole == "ex_driver"`
   - **Fitness Trainer salary** (if `weekStatus.fitnessTrainerLevel > 0`)
   - **Sponsor bonuses**: evaluates objectives per active sponsor contract → creates `transactions/` and `notifications/` subcollection entries
   - **Academy trainee costs**: `traineeCount × 10000 / 52`
   - **Race prize income**: already credited in Phase 2
   - **Player development events** (random XP gains, morale shifts)
   - **Youth academy events** (random candidate generation or skill tweaks)
5. AI team car upgrades (30% chance per stat per team)
6. Resets `weekStatus` for all teams (clears driver setups, flags)
7. Sets `postRaceProcessed: true`, `processedAt: serverTimestamp()`

### Phase 4 — UNIVERSE SYNC (NOT AUTOMATED ⚠️)
**Script:** `functions/sync_universe.js`  
**Must be run manually after any manual race simulation.**

**Execution:**
- Reads the `universe/game_universe_v1` document
- For each league → each driver/team, fetches current values from `drivers/{id}` and `teams/{id}`
- Updates `universe.leagues[*].drivers[*]` and `universe.leagues[*].teams[*]` with fresh `seasonPoints`, `wins`, `podiums`, etc.
- **Why this exists:** The Standings page (`/season/standings`) reads from `universe` (a denormalized aggregate) rather than querying hundreds of collection docs. This is a performance optimization that requires an explicit sync step.

---

## 3. Known Bugs & Mitigations (Postmortem R2 — 2026-03-16)

### Bug 1: `ReferenceError: extraCrash is not defined` (CRITICAL)
**Location:** `simulateLap()` in `index.js` around line 352  
**Trigger:** Any driver processed when `managerRole == "ex_driver"` OR accessing `accProb + extraCrash` when `extraCrash` was never declared  
**Pattern:** Variable assigned inside `if` block without prior `let` declaration:
```js
// BUG — crashes in strict mode when not ex_driver
if (teamRole === "ex_driver") { extraCrash = 0.001; }
// CORRECT
let extraCrash = 0;
if (teamRole === "ex_driver") { extraCrash = 0.001; }
```
**Rule for AI:** ALWAYS declare variables with `let` or `const` before any conditional assignment in `index.js`. Firebase Functions run in strict mode. An undeclared variable assignment will throw a `ReferenceError` that is only visible in Firebase Logs, NOT in local PowerShell output.

### Bug 2: Empty Array Guard (`qualyGrid: []` is truthy)
**Already fixed.** Guard must use `.length > 0`.

### Bug 3: `managerStore` not imported in `finances/+page.svelte`
**Fixed.** When adding logic that uses a store in a new page, always verify the imports block.

---

## 4. Emergency Recovery Protocol

Run these commands from `functions/` directory in order:

```bash
# 1. Reset stale / corrupted race data for current season
node reset_all.js

# 2. Simulate qualifying
node run_simulation.js qualy

# 3. Simulate race
node run_simulation.js race

# 4. Force post-race economy processing (finances, XP, bonuses)
node force_post_race.js

# 5. Sync universe document (updates Standings page)
node sync_universe.js
```

**Do NOT skip steps.** Each depends on the previous.  
**Wait for each to exit cleanly (Exit code 0 in Node, or check log files).**

---

## 5. Verification Checklist (Firestore Console)

After each step, verify in the Firebase Console → Firestore:

| Check | Collection/Doc | Field | Expected |
|---|---|---|---|
| Qualy ran | `races/{seasonId}_{raceId}` | `qualyGrid` | `length > 20` |
| Race ran | `races/{seasonId}_{raceId}` | `isFinished` | `true` |
| Race ran | `races/{seasonId}_{raceId}` | `finalPositions` | Non-empty object |
| Economy ran | `races/{seasonId}_{raceId}` | `postRaceProcessed` | `true` |
| Standings updated | `universe/game_universe_v1` | `leagues[0].drivers[0].seasonPoints` | New value |

---

## 6. Scheduler Reference Table

| Function | Schedule | Timezone | What it does |
|---|---|---|---|
| `scheduledQualifying` | `0 15 * * 6` (Sat 15:00) | America/Bogota | Runs qualifying simulation |
| `scheduledRace` | `0 14 * * 0` (Sun 14:00) | America/Bogota | Runs full race simulation |
| `postRaceProcessing` | `*/30 * * * *` (every 30m) | America/Bogota | Processes economy when timer allows |
| `scheduledDailyFitnessRecovery` | `0 0 * * *` (midnight) | America/Bogota | +1.5 fitness to all active drivers |
| `sync_universe` | **MANUAL** | N/A | Must be called after any manual race sim |
