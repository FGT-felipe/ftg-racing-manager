# AI Schema Definition: Firestore Graph

## 1. Global Entities
### `universe/game_universe_v1`
- `leagues`: { [leagueId: string]: LeagueObject }
- `config`: Global simulation constants.

## 2. Competitive Layer
### `leagues/{leagueId}`
- `teams`: Array<TeamID>
- `tier`: number (1 or 2)
- `currentSeasonId`: SeasonID reference.

### `seasons/{seasonId}`
- `calendar`: Array<{ circuitId: string, isCompleted: boolean, date: Timestamp }>
- `standings`: { drivers: { [id]: pts }, teams: { [id]: pts } }

## 3. Team Management
### `teams/{teamId}`
- `managerId`: AuthUID
- `isBot`: boolean
- `carStats`: { "0": DriverStatsObject, "1": DriverStatsObject }
- `sponsors`: { [slot: string]: ContractObject }
- `weekStatus`: { practiceCompleted: boolean, strategySet: boolean, lockAt: Timestamp }

#### Sub-collections
- `news`: Chronological race reports and events.
- `transactions`: Financial ledger { amount, type: "REWARD"|"UPGRADE"|"SALARY", date }.
- `academy/config/candidates`: Drivers with `status: "candidate"`.
- `academy/config/selected`: Drivers with `status: "trainee"`.

## 4. Driver Entity
### `drivers/{driverId}`
- `teamId`: TeamID (nullable if free agent)
- `countryCode`: ISO 3166-1 alpha-2 code.
- `stats`: { cornering, braking, focus, fitness, etc. } [Scale: 1-20]
- `transferMarket`: { isListed, highestBid, bidderId, expiresAt: Timestamp }

## 5. Telemetry & Results
### `races/{seasonId}_{raceEventId}`
- `status`: "completed" | "in_progress"
- `finalPositions`: { [driverId]: position_index }
- `fast_lap`: { driverId, time }
- `subcollections/laps`: Keyframe telemetry { lap_num: { telemetry_map } }
