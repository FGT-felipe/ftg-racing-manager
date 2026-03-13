# AI Technical Strategy: Senior Architectural Roadmap

## 1. Frontend Layer (Svelte 5)
- **Dependency Inversion**: Decouple Firestore SDK from Runes. Move to a Repository Pattern to allow Mocking/Testing during CI/CD.
- **Off-Main-Thread Processing**: Utilize Web Workers for Race Telemetry interpolation (easing functions) to maintain 60 FPS UI.
- **Hydration Optimization**: Move Documentation and static assets to SSG (Static Site Generation) to improve LCP (Largest Contentful Paint).

## 2. Backend Layer (Cloud Functions V2)
- **Modularization**: Refactor `index.js` into Domain-Driven Design (DDD) sub-modules using TypeScript.
- **Compute Optimization**: Port SimEngine math to Rust/WASM to reduce cold start latency and execution cost per race.
- **Event-Driven Architecture**: Use Pub/Sub for cross-service communication (e.g. `RaceFinished` -> `ProcessEconomy` + `GenerateNews`).

## 3. Data Tier (Firestore & Beyond)
- **OLAP Migration**: Move historical stats and leaderboard data to BigQuery or a dedicated Relational DB to alleviate Firestore's filtering limitations.
- **Write Throttling Management**: Implement document sharding for the `universe` singleton if traffic exceeds 10k concurrent write bursts.
- **Schema Governance**: Implement Zod validation on the frontend and Firestore Rules to enforce cross-document integrity.

## 4. Infrastructure & Security
- **App Check Enforcement**: Zero-trust access to write functions.
- **Automated Stress Testing**: Use Playwright with mocked Firebase signals to simulate high-concurrency race finish scenarios.
