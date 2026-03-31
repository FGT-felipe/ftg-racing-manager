# AI Schema Definition: Firestore Graph

> Single source of truth for all Firestore document shapes.
> TypeScript interfaces live in `functions/src/shared/types.ts`.
> Business constants (costs, thresholds) live in `functions/src/config/constants.ts`.

---

## 1. Global Entities

### `universe/game_universe_v1`
Denormalized aggregate rebuilt by `scripts/emergency/sync_universe.js` after each race.
```
leagues: LeagueSnapshot[]   // standings snapshot per league
config:  {}                 // reserved for global sim constants
```

---

## 2. Competitive Layer

### `leagues/{leagueId}`
```
teams:           string[]   // array of teamIds in this league
tier:            number     // 1 = top division, 2 = lower
currentSeasonId: string     // reference to active seasons/{id}
```

### `seasons/{seasonId}`
```
calendar: RaceEvent[]
  id:          string       // e.g. "r1", "r2"
  trackName:   string       // full display name, e.g. "Autódromo José Carlos Pace"
  circuitId:   string       // key into circuits config, e.g. "interlagos"
  totalLaps:   number
  weatherPractice:   string
  weatherQualifying: string
  weatherRace:       string
  countryCode: string       // ISO 3166-1 alpha-2
  flagEmoji:   string
  isCompleted: boolean

standings:
  drivers: { [driverId]: number }   // season points total
  teams:   { [teamId]:   number }
```

---

## 3. Team Management

### `teams/{teamId}`
```
id:           string
name:         string
budget:       number          // total liquid assets (USD)
managerId:    string          // Firebase Auth UID (empty string for bots)
isBot:        boolean
managerName:  string
backgroundId: string          // onboarding background selection

transferBudgetPercentage: number  // % of budget allocated to transfers (default 20)

carStats: {                   // one entry per driver slot
  "0": { aero, powertrain, chassis, reliability? }   // all 1–100
  "1": { aero, powertrain, chassis, reliability? }
}

facilities: {
  hq:           { level: number }   // HQ level 1–5, maintenance = level × $15k/week
  youthAcademy: {
    level:                number    // 1–2 (max 2), upgrade cost = $1M
    establishmentFee:     number
    lastUpgradeSeasonId:  string    // prevents double-upgrade per season
    countryCode:          string    // regional scouting focus (immutable after creation)
  }
}

sponsors: {
  [slot: "hood"|"sidepod_left"|"sidepod_right"|"rear_wing"|"engine_cover"]: {
    sponsorId:            string
    sponsorName:          string
    objectiveDescription: string
    objectiveBonus:       number    // paid on objective completion
    weeklyBasePayment:    number
    racesRemaining:       number
    countryCode:          string
  }
}

weekStatus: {
  globalStatus?:              string  // "practice"|"qualifying"|"raceStrategy"|"race"|"postRace"
  practiceCompleted:          boolean
  strategySet:                boolean
  lockAt:                     Timestamp
  fitnessTrainerLevel?:       number  // 0–5
  upgradeCooldownWeeksLeft?:  number
  psychologistLevel?:             number   // HR Manager level 1–5 (default 1)
  psychologistName?:              string   // HR Manager display name
  psychologistCountry?:           string   // HR Manager country code
  psychologistAssignedTo?:        string   // driverId for weekly morale session
  psychologistUpgradedThisWeek?:  boolean  // level change lock (resets weekly)
  psychologistSessionDoneThisWeek?: boolean // session lock (resets weekly)
  driverSetups?: {
    [driverId]: CarSetup
  }
}

seasonPoints:    number
seasonRaces:     number
seasonWins:      number
seasonPodiums:   number
seasonPoles:     number
lastRaceDebrief: string
lastRaceResult:  string
```

#### Sub-collections

**`teams/{teamId}/transactions`**
```
id:          string
description: string
amount:      number          // negative = expense, positive = income
date:        string          // ISO 8601
type:        "REWARD" | "UPGRADE" | "SALARY" | "ACADEMY" | "TRANSFER" | "SPONSOR" | "PRIZE"
```

**`teams/{teamId}/news`**
```
title:     string
message:   string
type:      "SUCCESS" | "WARNING" | "ERROR" | "INFO"
teamId:    string
timestamp: Timestamp
isRead:    boolean
```

**`teams/{teamId}/academy/config`** (single document)
```
level:               number
countryCode:         string
establishmentFee:    number
lastUpgradeSeasonId: string
```

**`teams/{teamId}/academy/config/candidates`** (sub-collection)
```
id:              string
name:            string
age:             number
countryCode:     string
growthPotential: number      // 1–5 stars (affects XP calculation)
potentialStars:  number      // cosmetic display only
currentStars:    number
stats:           DriverStats
status:          "candidate"
specialty?:      "rain_master" | "tyre_whisperer" | "late_braker" | "defensive_minister"
```

**`teams/{teamId}/academy/config/selected`** (sub-collection — active trainees)
```
(same shape as candidates, plus:)
status:              "trainee"
xp:                  number    // accumulated XP (500 XP = skill level-up)
weeklyXP:            number    // XP gained last processing cycle
isMarkedForPromotion: boolean  // +25% XP bonus when true
pendingEvent?: {
  type:   "INTENSIVE_TRAINING" | "MORALE_BOOST" | "SKILL_FOCUS" | ...
  desc:   string
  stat?:  string               // target skill for single-stat events
}
```

---

## 4. Driver Entity

### `drivers/{driverId}`
```
id:           string
teamId:       string          // empty string if free agent
name:         string
age:          number
salary:       number          // annual USD
potential:    number          // 1–5 stars
currentStars: number          // 1–5
gender:       "male" | "female"
countryCode:  string
role?:        "driver" | "reserve" | "ex_driver"
contractYearsRemaining: number

stats: {                      // all values 1–20
  cornering:    number
  braking:      number
  focus:        number
  fitness:      number        // physical condition, decays after events
  adaptability: number
  consistency:  number
  smoothness:   number
  overtaking:   number
  morale?:      number        // 0–100. Default 70 (MORALE_DEFAULT) when absent. Affects lap time via MORALE_LAPTIME_FACTOR formula.
  traits?:      string[]      // e.g. ["rain_master"]
}

seasonPoints:     number
seasonRaces:      number
seasonWins:       number
seasonPodiums:    number
seasonPoles:      number
form:             number      // recent performance trend
championshipForm: number

isTransferListed:   boolean
transferListedAt?:  Timestamp
marketValue:        number
currentHighestBid:  number
highestBidderTeamId?: string

specialty?:  string    // assigned via academy pipeline when a stat >= 11 (see DriverSpecialty type)
             // Values: "Rainmaster" | "Tyre Whisperer" | "Late Braker" | "Defensive Minister"
             //       | "Apex Hunter" | "Iron Nerve" | "Qualy Ace" | "Iron Wall"
             // Once assigned, never changes. Only one specialty per driver.
             // Triggers in post-race.ts when: !specialty AND baseSkill >= 8 AND stat >= 11.
             // Priority order: adaptability > smoothness > braking > overtaking > cornering
             //                > consistency > focus > fitness
```

---

## 5. Car Setup

### `CarSetup` (stored in `weekStatus.driverSetups` and race `setups`)
```
frontWing:      number    // 0–100 (0 = min downforce / top speed)
rearWing:       number    // 0–100
suspension:     number    // 0–100 (0 = soft/bumps, 100 = stiff/aero)
gearRatio:      number    // 0–100 (0 = acceleration, 100 = top speed)
tyreCompound:   "soft" | "medium" | "hard" | "wet"
qualifyingStyle: "defensive" | "normal" | "offensive" | "mostRisky"
raceStyle:       "defensive" | "normal" | "offensive" | "mostRisky"
initialFuel:    number    // liters (0–100)
pitStops:       TyreCompound[]   // one entry per planned stop
pitStopStyles:  DrivingStyle[]
pitStopFuel:    number[]
```

---

## 6. Race Document

### `races/{seasonId}_{eventId}`  (e.g. `S1_r3`)
```
seasonId:   string
eventId:    string          // e.g. "r3"
circuitId:  string
countryCode: string
isFinished: boolean
postRaceProcessed:    boolean
postRaceProcessingAt: Timestamp  // scheduled 2h after race end

qualyGrid: QualyGridEntry[]   // sorted by position after qualifying
  driverId:       string
  driverName:     string
  teamId:         string
  teamName:       string
  lapTime:        number      // milliseconds
  isCrashed:      boolean
  tyreCompound:   TyreCompound
  setupSubmitted: boolean
  position:       number
  gap:            number      // ms behind P1

finalPositions: { [driverId]: number }  // 1-based finishing position
dnfs:           string[]               // driverIds that did not finish
fast_lap_driver: string
fast_lap_time:   number                // milliseconds
totalTimes:      { [driverId]: number }

setups: { [driverId]: CarSetup }       // setup used in the race

raceLog: RaceLapLog[]                  // per-lap telemetry snapshot
  lap:      number
  lapTimes: { [driverId]: number }
  positions: { [driverId]: number }
  tyres:    { [driverId]: TyreCompound }
  events:   LapEvent[]
    lap:      number
    driverId: string
    desc:     string
    type:     "DNF" | "PIT" | "OVERTAKE" | "INFO"
```

---

## 7. Qualifying Backup (Immutable)

### `qualifying_results/{seasonId}_{raceEventId}`  (e.g. `S1_r4`)
> **Append-only.** Written once by `runQualifyingLogic()` immediately after `races/{id}.qualyGrid` is saved.
> No pipeline, admin tool, or emergency script deletes or updates this collection.
> If qualifying is re-run via emergency recovery, the entry is safely overwritten with the corrected grid.
```
seasonId:    string
raceEventId: string          // e.g. "r4"
trackName:   string
circuitId:   string
qualyGrid:   QualyGridEntry[]   // identical shape to races/{id}.qualyGrid
createdAt:   Timestamp
```

---

## 8. Manager Entity

### `managers/{managerId}` (Auth UID as document ID)
```
id:           string    // same as Firebase Auth UID
name:         string
email:        string
teamId:       string
country:      string    // ISO 3166-1 alpha-2
backgroundId: string    // onboarding selection (cosmetic)
role:         "driver" | "engineer" | "ex_driver" | "investor"
createdAt:    Timestamp
```

---

## 9. Transfer Bids

> **Note:** There is no standalone `transferBids` collection. Bids are stored directly on the driver document.
> See `drivers/{driverId}.currentHighestBid` and `drivers/{driverId}.highestBidderTeamId`.
> The `transferBids` Firestore rule was removed in v1.5.8 as it was legacy with no active code references.

---

## Removed / Legacy Collections

| Collection | Removed | Reason |
|---|---|---|
| `leagues/{id}/press_news` | v1.5.8 | League-wide news system discarded due to performance issues. Rule and dead code removed. |
| `users` | v1.5.8 | Legacy Firestore rule with no active code references. User identity is handled by `managers/{uid}`. Firebase Auth accounts are unaffected. |
