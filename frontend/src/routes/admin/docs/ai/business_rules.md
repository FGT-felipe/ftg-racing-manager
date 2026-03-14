# AI Technical Specification: Platform Governance & Sim Physics

## 1. Manager Role Modifiers (Authoritative)
| Role | Physics Adjust | Stats/Economy Adjust | Limitations |
| :--- | :--- | :--- | :--- |
| `ex_driver` | `pace: *0.98`, `crash: +0.001` | N/A | N/A |
| `ex_engineer` | `tyre_wear: *0.9` | `max_upgrades: 2/wk`, `upgrade_cost: *2` (fib) | N/A |
| `business_admin`| `pace: *1.02` | `sponsor_pay: *1.15`, `facility_upg: *0.9` | N/A |
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

## 5. Transfer Market
- **Duration**: Hardcoded 24 hours.
- **Resolution**: Best bid wins, seller gets funds, driver contract resets to 1 year.
- **Bot Cleaning**: Expired unsold listings for `teamId: null` drivers are DELETED.
