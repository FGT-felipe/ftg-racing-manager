# AI Technical Specification: Platform Governance & Sim Physics

## 1. Manager Role Modifiers (Authoritative)
| Role | Physics Adjust | Stats/Economy Adjust | Limitations |
| :--- | :--- | :--- | :--- |
| `ex_driver` | `pace: *0.98`, `crash: +0.001` | N/A | N/A |
| `engineer` | `tyre_wear: *0.9` | `max_upgrades: 2/wk`, `upgrade_cost: *2` (fib) | N/A |
| `business`| `pace: *1.02` | `sponsor_pay: *1.15`, `facility_upg: *0.9` | N/A |
| `bureaucrat` | N/A | `academy_slots: +level*2`, `facility_upg: *0.9`| `qualy_cooldown: 2wk` |

## 2. Simulation Engine Constants
- **Base Lap Time Equation**: `lt = circuit_base * car_factor * driver_factor + penalty + rand(±0.4)`
- **Car Factor**: `1.0 - (WeightedAvg(A,P,C) / 20.0 * 0.25)`
- **Driver Factor**: `1.0 - (Brk*0.02 + Crn*0.025 + (Foc-0.5)*0.01)`
- **Style Risk Table**:
    - `mostRisky`: `lt_delta: -0.04`, `crash_prob: 0.003`, `fuel: 1.35x`, `wear: 1.6x`
    - `offensive`: `lt_delta: -0.02`, `crash_prob: 0.0015`, `fuel: 1.15x`, `wear: 1.25x`
    - `defensive`: `lt_delta: +0.01`, `crash_prob: 0.0005`, `fuel: 0.85x`, `wear: 0.75x`
- **Tire Wear Penalty**: `(wear/100)^2 * 8.0s`
- **Fuel Weight Penalty**: `(fuel/100) * 1.5s`
- **Mandatory Hard Rule**: `+35.0s` penalty if `Hard` compound count == 0 on dry track. **Waived if Race is wet.**
- **Rain Logic**:
    - **Surface Penalty**: Every wet session adds a base `+1.5s` penalty (Even with correct tyres).
    - **Rain Master Bonus**: Drivers with `rainMaster` trait get a `df -0.015` (improved pace) modifier in wet sessions.
    - **Parc Fermé**: Disabled if Qualy session is wet.
    - **Starting Tyres**: The "Qualy Q2 tyre" rule is waived if Qualy was wet (`isQualyWet`). Managers can choose starting compound for the race even if it's dry.
    - **Tire Compounds**: Only `Soft`, `Medium`, `Hard`, and `Wet` are available. `Intermediate` tires are not implemented.

## 3. Platform Governance & i18n (CRITICAL)
- **Zero Hardcoding**: All user-facing strings must pass through `t()` helper in `$lib/utils/i18n.ts`.
- **Parity Rule**: Every key added to `translations.en` MUST exist in `translations.es` and vice versa.
- **Dynamic Values**: Use `{key}` placeholders for dynamic data within translations.
- **Salary Formula**: `AnnualSalary / 52` (Weekly deduction).
- **Facility Maintenance**: `Level * $15,000` (Weekly).
- **Staff (Trainer) Tiers**: `[0, 0, 50k, 120k, 250k, 500k]` by Level [0-5].
- **Prize Money (Race)**: P1: $500k, P2: $350k, P3: $250k, P4-P6: $150k, P7-P10: $100k, Finish/DNF: $25k.

## 4. Driver & Academy Evolution
- **Skill Level Up**: `500 XP` threshold.
- **Fitness Recovery**: `+1.5%` daily (cron at 00:00).
- **Age Peak Factors (Career Generation)**:
    - `<23`: 0.7-0.9x | `23-27`: 0.9-1.1x | `27-32`: 1.1-1.4x | `32-36`: 0.8-1.0x | `>36`: 0.5-0.8x
- **Specialization**: Locked until `BaseSkill >= 8`.
- **Academy Candidate Generation**:
    - **Session Size**: Always returns a pair (2 drivers).
    - **Gender Balance**: Strictly enforced **1 Male, 1 Female** per batch.
    - **Level Scaling**: Base skill and potential are calculated as `(Base + academyLevel * 2) + rand(0,4)`.
    - **Star Consistency**: `potentialStars` reflects `maxSkill / 4` to match main driver mechanics.

## 5. Transfer Market
- **Duration**: Hardcoded 24 hours.
- **Resolution**: Best bid wins, seller gets funds, driver contract resets to 1 year.
- **Bot Cleaning**: Expired unsold listings for `teamId: null` drivers are DELETED.

## 6. Parts Wear (T-007 Slice 1)

### Constants
| Constant | Value | Rationale |
|---|---|---|
| `PARTS_BASE_RACE_DELTA` | `8` | Flat degradation per race in Slice 1. No RNG — deterministic for predictable player planning. Tunable via Firestore config in Slice 2. |
| `PARTS_ENGINE_REPAIR_COST_FLAT` | `$25,000` | Flat cost balances regular repair against upgrade investment. Approximately 5% of mid-tier weekly budget. |
| `PARTS_TIER_THRESHOLDS` | `{ yellow: 80, orange: 50, red: 30 }` | Thresholds for tier badge color + shape. Values chosen to give ~3 races per tier band at base delta=8. |

### Formula (Slice 1)
- `computeWearDelta('race') = PARTS_BASE_RACE_DELTA = 8`
- `computeWearDelta('qualifying') = 0` (deferred to Slice 2)
- `newCondition = Math.max(0, currentCondition - delta)` — floors at 0, never negative
- `engineFactor = engineCondition / 100` — multiplies `powertrain` contribution in `simulateLap`
- Missing `parts/engine` doc → `engineFactor = 1.0` (no penalty, COMPAT-1)

### Tier Bands
| Tier | Range | Badge |
|---|---|---|
| green | 80–100 | ● |
| yellow | 50–79 | ▲ |
| orange | 30–49 | ◆ |
| red | 0–29 | ✕ |

---

## 7. Dashboard Readiness (Race Prep)
- **Logic**: Readiness (%) = (Completed Required Tasks / Total Required Tasks) * 100.
- **Race Setups (Mandatory)**: `isComplete` only if `weekStatus.driverSetups[driverId].race` exists for all main drivers (car 0 and 1). Previous sessions (Practice/Qualy) are ignored for this specific indicator.
- **Sponsors (Mandatory)**: `isComplete` if `team.sponsors` contains at least one entry.
- **Facilities (Optional)**: Informational only. `isComplete` by default if team is valid.
