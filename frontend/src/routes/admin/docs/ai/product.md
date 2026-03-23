# Product Vision & Functional Scope

## Core Value Proposition

A technical, high-depth F1-style team management simulation focused on real-time decision making and long-term team evolution. Players manage every aspect of a racing operation across multiple seasons and league tiers.

## Design Principles

- **Telemetric Precision:** UI elements mimic real racing telemetry and dashboards.
- **Micro-interactions:** Svelte transitions deliver a high-quality, app-like feel on the web.
- **Responsive Logic:** Fully functional on desktop and tablet. Mobile supported for monitoring and decisions.
- **Premium Aesthetic:** Dark gold theme. Every screen should feel like a professional motorsport tool.

## Functional Modules

### 1. Driver Lifecycle
From Youth Academy scouting → contract signing → career development → free agency and retirement.
- Academy generates 1M/1F candidate pair per scouting session, scaled by facility level.
- Base skill increases at 500 XP increments. Specialties (RainMaster, etc.) unlock at skill ≥ 8.
- Fitness recovers +1.5% per day via scheduled Cloud Function.

### 2. Financial Strategy
- Revenue: Race prizes (Win=$500k, P2=$350k, P3=$250k, DNF consolation=$25k), Qualifying prizes (P1=$50k, P2=$30k, P3=$15k), Sponsor contracts.
- Expenses: Driver salaries (annual ÷ 52/week), Staff salaries, HQ Maintenance (Level × $15k/week), Fitness Trainer (up to $500k/week at level 5), Academy trainee costs.
- Manager role modifiers apply to salary costs, sponsor bonuses, and upgrade prices.

### 3. Engineering: Fibonacci Upgrade Curve
Car parts follow Fibonacci cost scaling to prevent "power creep":
- Formula: `Level × Fibonacci(Level) × $100,000`
- Maximum level: 20
- AI teams auto-upgrade 30% weekly (random stat: Aero, Engine, or Chassis).

### 4. Real-time Racing Weekend
- **Practice:** Active setup simulation with telemetry feedback. Feedback precision scales with driver's Adaptability skill.
- **Qualifying:** Single-attempt or multiple attempts. Best lap locked into Parc Fermé.
- **Race Strategy:** Tyre compound, fuel load, driving style. Parc Fermé lifted if qualifying was in rain.
- **Race:** Automated simulation via Cloud Functions. Results available post-simulation.

### 5. Sponsorship System
- 3 available slots per team. Negotiate based on sponsor personality vs. manager tactic.
- Base success probability: 30%. Personality match adds +50%.
- Business Admin role adds +15% to all sponsor payouts.

### 6. League Structure
- **FTG World Championship** (Tier 1) — unlocked from launch.
- **FTG 2th Series** (Tier 2) — locked until Tier 1 is 100% filled with human managers.
- Shared race calendar: all leagues compete in the same race weekend on the same circuit.

## Player Roles (Manager Types)

| Role | Key Advantage | Trade-off |
|---|---|---|
| Ex-Driver | +2% race pace | +0.1% crash probability |
| Ex-Engineer | 2 car upgrades/week, +5% qualy pace, -10% tyre wear | Upgrade parts cost ×2 |
| Business Admin | +15% sponsor revenue, -10% facility upgrades | -2% race pace |
| Bureaucrat | +2 academy slots/level, -10% facility upgrades | 2-week cooldown after car upgrades |
