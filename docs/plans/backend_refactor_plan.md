# Backend Refactor Plan — Functions Monolith → TypeScript Modules

**Objetivo:** Descomponer `functions/index.js` (2,696 líneas, JavaScript) en módulos TypeScript por dominio, con tests unitarios para la lógica crítica de simulación.

**Principio guía:** Migración incremental. El `index.js` actual permanece desplegado y funcional en todo momento. Cada dominio se extrae, se verifica, y reemplaza su equivalente solo cuando está probado.

**Contexto crítico:**
- Node engine actual: **24** (no 20 — actualizar target TypeScript a `ES2022`)
- `addPressNews` está comentada en `index.js` — no se extrae (dead code)
- `firebase.json` tiene `"predeploy": []` — necesita ser actualizado antes del cutover
- `run_simulation.js` **no existe** en disco — CLAUDE.md lo referencia erróneamente; los scripts reales son `force_race_local.js` y `force_race_wrapper.js`

---

## Mapa de dominios actual (`index.js`)

| Líneas | Dominio | Responsabilidad |
|---|---|---|
| 1–25 | Config | `FALLBACK_BONUSES` constants |
| 26–185 | Sponsor | `evaluateObjective()` |
| 186–608 | Circuits | `getCircuit()` — ~400 líneas de datos de circuitos |
| 609–696 | Shared utils | `sleep()`, `addOfficeNews()`, `fetchTeams()` (`addPressNews` comentada) |
| 697–790 | Academy | `generateAcademyCandidate()` |
| 791–1178 | Sim Engine | `simulateLap()`, física de neumáticos, clima, lógica de crashes |
| 1179–1749 | Qualifying | `runQualifyingLogic()` |
| 1750–2286 | Race + Economy | `runRaceLogic()`, `postRaceProcessing()` |
| 2287–2348 | Fitness | `scheduledDailyFitnessRecovery` |
| 2349–2465 | Transfer Market | `resolveTransferMarket` |
| 2466–2696 | Admin Tools | `megaFixDebriefs`, `forceFixGBA`, `restoreDriversHistory` |

---

## Épica 0 — Limpieza y Preparación

> Precondición de todo lo demás. Sin esto, el directorio `functions/` es una mezcla de código de producción y scripts desechables.

### Tarea 0.1 — Limpiar `functions/` de archivos temporales

Eliminar todos los archivos que no son código de producción:

**Archivos temp/debug a eliminar:**
- `_adc_temp_check.json`, `_adc_temp_check2.json`, `_adc_temp_diag.json`, `_adc_temp_fix.json`, `_adc_temp_univ.json`
- `_t12.json`, `_t13.json`
- `race_r1_dump.json`
- `eslint_output.txt`, `run_log.txt`, `log_post_race.txt`
- `fix.js`, `fix_global_status.js` (one-off fixes ya aplicados)

**Scripts diagnósticos/admin a mover a `functions/scripts/emergency/`:**
- `sync_universe.js`, `force_post_race.js`, `force_race_local.js`, `force_race_wrapper.js`, `force_check.js`
- `check_economy.js`, `check_universe.js`, `audit_sponsors.js`
- `diag.js`, `diag_drivers.js`, `debug_audit.js`, `debug_gba.js`
- `dump_qualy.js`, `dump_r3.js`, `list_leagues.js`, `list_races.js`
- `send_bonus_summary.js`, `test_academy.js`

**Scripts de migración a mover a `functions/scripts/migrations/`:**
- `migrate_drivers_to_20_scale.js`, `migrate_sponsors.js`
- `fix_historical_bonuses.js`, `fix_points.js`, `fix_r1_fast_lap.js`
- `resimulate_r1.js`, `resimulate_r1_clean.js`, `resimulate_r1_fair.js`

---

### Tarea 0.2 — Actualizar `CLAUDE.md` con los nuevos paths

La sección "Emergency Recovery Protocol" de `CLAUDE.md` tiene dos errores que deben corregirse:

1. **`run_simulation.js` no existe.** Reemplazar con los scripts reales:
   ```bash
   # ANTES (incorrecto):
   node run_simulation.js qualy
   node run_simulation.js race

   # DESPUÉS (correcto):
   node scripts/emergency/force_race_local.js qualy   # o force_race_wrapper.js según el caso
   node scripts/emergency/force_race_local.js race
   ```

2. **Actualizar todos los paths** de emergency recovery al nuevo directorio:
   ```bash
   # Antes:          node reset_all.js
   # Después:        node scripts/emergency/reset_all.js   (si existe) o instrucción manual
   node scripts/emergency/force_post_race.js
   node scripts/emergency/sync_universe.js
   ```

---

### Tarea 0.3 — Configurar TypeScript en `functions/`

1. Instalar dependencias de desarrollo:
   ```bash
   cd functions
   npm install --save-dev typescript ts-node @types/node jest ts-jest @types/jest
   ```

2. Crear `functions/tsconfig.json`:
   ```json
   {
     "compilerOptions": {
       "target": "ES2022",
       "module": "commonjs",
       "lib": ["ES2022"],
       "outDir": "./lib",
       "rootDir": "./src",
       "strict": true,
       "noImplicitAny": true,
       "strictNullChecks": true,
       "esModuleInterop": true,
       "skipLibCheck": true
     },
     "include": ["src"],
     "exclude": ["node_modules", "lib", "scripts"]
   }
   ```
   > **Nota:** `target: "ES2022"` para alinearse con Node 24 (`"engines": { "node": "24" }` en `package.json`).

3. Crear `functions/jest.config.js`:
   ```js
   module.exports = {
     preset: 'ts-jest',
     testEnvironment: 'node',
     testMatch: ['**/__tests__/**/*.test.ts'],
   };
   ```

4. Actualizar `functions/package.json`:
   - Añadir a `"scripts"`: `"build": "tsc"`, `"test": "jest"`, `"typecheck": "tsc --noEmit"`
   - Mantener `"main": "index.js"` hasta el cutover (Épica 5)

5. Crear estructura de directorios vacía:
   ```
   functions/src/
   functions/src/__tests__/
   functions/src/config/
   functions/src/shared/
   functions/src/domains/simulation/
   functions/src/domains/economy/
   functions/src/domains/academy/
   functions/src/domains/transfer-market/
   functions/src/domains/fitness/
   functions/src/domains/admin/
   functions/src/schedulers/
   ```

6. Verificar: `npm run typecheck` pasa sin errores sobre archivos vacíos.

---

## Épica 1 — Config y Shared (Sin riesgo)

> Extraer constantes y utilidades. No cambia ningún comportamiento de producción.

### Tarea 1.1 — `src/config/constants.ts`

Extraer de `index.js`:
- `FALLBACK_BONUSES` (línea ~14)
- Constantes de negocio hardcodeadas en la lógica: `NAME_CHANGE_COST = 500_000`, salarios de entrenador fitness por nivel, costos de mantenimiento HQ, premios de carrera (Win=$500k, etc.), umbrales de XP.

```typescript
// src/config/constants.ts
export const FALLBACK_BONUSES: Record<string, number> = { ... };
export const RACE_PRIZES = { WIN: 500_000, P2: 350_000, P3: 250_000, DNF: 25_000 };
export const QUALY_PRIZES = { P1: 50_000, P2: 30_000, P3: 15_000 };
export const HQ_MAINTENANCE_PER_LEVEL = 15_000;
export const XP_PER_SKILL_LEVEL = 500;
export const NAME_CHANGE_COST = 500_000;
```

### Tarea 1.2 — `src/config/circuits.ts`

Extraer la función `getCircuit()` (~400 líneas, líneas 186–608) en un archivo de datos tipados.

```typescript
// src/config/circuits.ts
export interface Circuit { id: string; name: string; laps: number; baseTime: number; ... }
const CIRCUITS: Record<string, Circuit> = { ... };
export function getCircuit(circuitId: string): Circuit { ... }
```

### Tarea 1.3 — `src/shared/types.ts`

Definir las interfaces TypeScript de todas las entidades que fluyen por el sistema:

```typescript
export interface Team { id: string; name: string; budget: number; managerId: string; ... }
export interface Driver { id: string; teamId: string; stats: DriverStats; ... }
export interface DriverStats { cornering: number; braking: number; focus: number; fitness: number; ... }
export interface Race { id: string; qualyGrid: QualyResult[]; finalPositions: Record<string, number>; ... }
export interface CarSetup { aero: number; suspension: number; brakeBalance: number; ... }
export interface SponsorContract { slot: string; objectiveDescription: string; bonus: number; ... }
```

### Tarea 1.4 — `src/shared/utils.ts`

Extraer las utilidades genéricas sin dependencia de Firestore:
- `sleep(ms: number): Promise<void>` (línea ~614) — usada para escalonar procesamiento de ligas

```typescript
// src/shared/utils.ts
export function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}
```

### Tarea 1.5 — `src/shared/firestore.ts`

Extraer las funciones de utilidad de Firestore:
- `fetchTeams(teamIds: string[]): Promise<Team[]>`
- `chunkedBatchWrite(ops: BatchOperation[]): Promise<void>` (450 ops/chunk)

```typescript
// src/shared/firestore.ts
import { db } from './admin';
export async function fetchTeams(teamIds: string[]): Promise<Team[]> { ... }
export async function chunkedBatchWrite(ops: BatchOperation[], chunkSize = 450): Promise<void> { ... }
```

### Tarea 1.6 — `src/shared/notifications.ts`

Extraer `addOfficeNews`. **No extraer `addPressNews`** (está comentada en `index.js` — dead code, no migrar).

```typescript
// src/shared/notifications.ts
export async function addOfficeNews(teamId: string, data: NewsEntry): Promise<void> {
  // Escribe en teams/{teamId}/news y teams/{teamId}/notifications (batch)
}
```

### Tarea 1.7 — `src/shared/admin.ts`

Centralizar la inicialización de `firebase-admin`:

```typescript
// src/shared/admin.ts
import * as admin from 'firebase-admin';
admin.initializeApp();
export const db = admin.firestore();
export { admin };
```

Esto evita inicializar `admin` múltiples veces si los módulos se importan en paralelo.

---

## Épica 2 — Sim Engine (Máximo valor, máximo riesgo mitigado con tests)

> El corazón del sistema. La extracción como función pura + tests unitarios directamente previene la reincidencia de los bugs R2/R3.

### Tarea 2.1 — `src/domains/simulation/sim-engine.ts`

Extraer `simulateLap()` (~390 líneas, líneas 791–1178) como una **función pura**:

```typescript
// src/domains/simulation/sim-engine.ts
import { CarSetup, Driver, Circuit } from '../../shared/types';

export interface LapResult {
  driverId: string;
  lapTime: number;
  isCrashed: boolean;
  tireWear: number;
}

/**
 * Simulates a single lap. Pure function — no Firestore calls.
 * All inputs are plain data objects.
 */
export function simulateLap(
  driver: Driver,
  setup: CarSetup,
  circuit: Circuit,
  managerRole: string,
  sessionType: 'qualifying' | 'race',
): LapResult { ... }
```

**Regla de oro:** Si dentro de esta función aparece `db.`, `admin.`, o cualquier importación de `firebase-admin`/`firebase-functions`, el PR es rechazado.

### Tarea 2.2 — `src/__tests__/sim-engine.test.ts`

Escribir tests unitarios **sin Firebase Emulator**:

```typescript
describe('simulateLap', () => {
  it('returns a valid lap time for a mid-skill driver on dry track', () => { ... });
  it('adds +1.5s penalty on wet surface regardless of tyre compound', () => { ... });
  it('adds +8.0s penalty for dry tyres on wet track', () => { ... });
  it('adds +3.0s penalty for wet tyres on dry track', () => { ... });
  it('applies ex_driver crash probability bonus without ReferenceError', () => { ... });
  it('never crashes when crash probability is 0', () => { ... });
  it('respects Parc Ferme when qualifying setup is locked', () => { ... });
});
```

El test `'applies ex_driver crash probability bonus without ReferenceError'` es el **regression test directo** del bug R2/R3.

### Tarea 2.3 — `src/domains/simulation/qualifying.ts`

Extraer `runQualifyingLogic()` (~570 líneas, líneas 1179–1749). Depende de `sim-engine.ts` y `shared/firestore.ts`.

Preservar el guard crítico:
```typescript
// CORRECTO — verificar longitud, no solo existencia
if ((rSnap.data().qualyGrid?.length ?? 0) > 0) { continue; }
```

### Tarea 2.4 — `src/domains/simulation/race-engine.ts`

Extraer `runRaceLogic()` (~536 líneas, líneas 1750–2286, excluyendo el procesamiento de economía). Depende de `sim-engine.ts`.

---

## Épica 3 — Economy

### Tarea 3.1 — `src/domains/economy/sponsors.ts`

Extraer `evaluateObjective()` (~155 líneas, líneas 26–185) como función pura.

```typescript
export function evaluateObjective(
  contract: SponsorContract,
  raceData: RaceData,
  teamDrivers: string[],
): boolean { ... }
```

### Tarea 3.2 — `src/__tests__/sponsors.test.ts`

```typescript
describe('evaluateObjective', () => {
  it('detects "race win" objective correctly', () => { ... });
  it('detects "finish top 3" for either driver', () => { ... });
  it('detects "double podium" requiring both drivers in top 3', () => { ... });
  it('handles "home race win" only on matching countryCode', () => { ... });
  it('returns false for unrecognized objective strings', () => { ... });
});
```

### Tarea 3.3 — `src/domains/economy/salaries.ts`

Extraer toda la lógica de cálculo económico de `postRaceProcessing`:
- Salary calculation (annual / 52)
- Fitness trainer cost per level
- HQ maintenance (level × $15k) — usar `HQ_MAINTENANCE_PER_LEVEL` de `constants.ts`
- Ex-driver salary surcharge (+20%)

```typescript
export function calculateWeeklyDriverSalary(driver: Driver, managerRole: string): number { ... }
export function calculateFitnessTrainerCost(level: number): number { ... }
export function calculateHQMaintenance(hqLevel: number): number { ... }
```

### Tarea 3.4 — `src/__tests__/economy.test.ts`

```typescript
describe('calculateWeeklyDriverSalary', () => {
  it('returns annual salary / 52', () => { ... });
  it('applies +20% surcharge for ex_driver manager role', () => { ... });
});
describe('calculateHQMaintenance', () => {
  it('returns level * HQ_MAINTENANCE_PER_LEVEL', () => { ... });
});
```

### Tarea 3.5 — `src/domains/economy/post-race.ts`

Extraer el orquestador `postRaceProcessing`. Importa `sponsors.ts`, `salaries.ts`, y `shared/notifications.ts`.

---

## Épica 4 — Dominios independientes

> Bajo acoplamiento. Se pueden hacer en paralelo con la Épica 3.

### Tarea 4.1 — `src/domains/academy/candidate-factory.ts`

Extraer `generateAcademyCandidate()` (~93 líneas, líneas 697–790).

```typescript
export function generateAcademyCandidate(nation: string, level: number, gender: 'M' | 'F'): Driver { ... }
```

### Tarea 4.2 — `src/domains/transfer-market/resolver.ts`

Extraer `resolveTransferMarket` (~116 líneas, líneas 2349–2465).

### Tarea 4.3 — `src/domains/fitness/recovery.ts`

Extraer `scheduledDailyFitnessRecovery` (~62 líneas, líneas 2287–2348).

### Tarea 4.4 — `src/domains/admin/tools.ts`

Extraer las tres funciones de administración onCall (~230 líneas, líneas 2466–2696):
- `megaFixDebriefs` — regenera debriefs de carrera para todos los equipos
- `forceFixGBA` — fuerza el análisis GBA de un equipo específico
- `restoreDriversHistory` — restaura historial de carrera 2020–2025 para pilotos activos

```typescript
// src/domains/admin/tools.ts
// Nota: estas funciones SÍ usan Firestore (son admin tools, no sim engine)
// Conservar toda la lógica actual, solo tipar los parámetros y retornos.
export async function megaFixDebriefs(request: CallableRequest): Promise<AdminResult> { ... }
export async function forceFixGBA(request: CallableRequest): Promise<AdminResult> { ... }
export async function restoreDriversHistory(request: CallableRequest): Promise<AdminResult> { ... }
```

---

## Épica 5 — Wiring y Cutover

### Tarea 5.1 — `src/schedulers/jobs.ts`

Crear el archivo de exports que registra todas las Cloud Functions:

```typescript
// src/schedulers/jobs.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions';
import { runQualifyingLogic } from '../domains/simulation/qualifying';
import { runRaceLogic } from '../domains/simulation/race-engine';
import { postRaceProcessing } from '../domains/economy/post-race';
import { scheduledDailyFitnessRecovery } from '../domains/fitness/recovery';
import { resolveTransferMarket } from '../domains/transfer-market/resolver';
import { megaFixDebriefs, forceFixGBA, restoreDriversHistory } from '../domains/admin/tools';

setGlobalOptions({ maxInstances: 10 });

export const scheduledQualifying = onSchedule(
  { schedule: '0 15 * * 6', timeZone: 'America/Bogota', ... },
  runQualifyingLogic
);
export const scheduledRace = onSchedule(
  { schedule: '0 14 * * 0', timeZone: 'America/Bogota', ... },
  runRaceLogic
);
export const scheduledDailyFitness = onSchedule(
  { schedule: '0 0 * * *', timeZone: 'America/Bogota', ... },
  scheduledDailyFitnessRecovery
);
// postRaceProcessing, resolveTransferMarket, megaFixDebriefs, forceFixGBA, restoreDriversHistory ...
```

### Tarea 5.2 — `src/index.ts`

```typescript
// src/index.ts — re-exports only, zero logic
export * from './schedulers/jobs';
```

### Tarea 5.3 — Actualizar `firebase.json` con predeploy build step

Actualizar el array `predeploy` vacío en `firebase.json`:

```json
"functions": [{
  "source": "functions",
  "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]
}]
```

Esto garantiza que `tsc` compila antes de cada `firebase deploy --only functions`. Si el build falla, el deploy se cancela automáticamente.

### Tarea 5.4 — Actualizar `package.json` para el cutover

Cambiar el entry point:
```json
{
  "main": "lib/index.js"
}
```

### Tarea 5.5 — Build, verificación y deploy

1. `npm run typecheck` — sin errores en `functions/src/`
2. `npm run test` — todos los tests pasan
3. `npm run build` — compila TypeScript a `lib/`
4. `firebase deploy --only functions`
5. Verificar en Firebase Console → Functions que **todas las funciones** tienen el nuevo deployment timestamp
6. Confirmar que las 4 funciones programadas siguen activas: `scheduledQualifying`, `scheduledRace`, `postRaceProcessing`, `scheduledDailyFitnessRecovery`

### Tarea 5.6 — Plan de rollback

Si alguna función falla tras el deploy:

1. En `package.json`, revertir `"main"` a `"index.js"` (apunta al JS legacy)
2. En `firebase.json`, limpiar `predeploy` temporalmente
3. `firebase deploy --only functions` — restaura `index.js` como runtime
4. Tiempo estimado de rollback: < 5 minutos

El `index.js` **no se toca** durante toda la migración. Es el paracaídas.

### Tarea 5.7 — Deprecar `index.js`

Una vez verificado el primer fin de semana completo (qualy + carrera + post-race economy) con la versión TypeScript:
- Renombrar `index.js` a `_legacy_index.js.bak`
- Mantenerlo 2 semanas por si se necesita rollback manual
- Eliminar definitivamente tras verificar R(n+2)

---

## Criterios de Aceptación Global

- [ ] `npm run typecheck` pasa sin errores en `functions/src/`
- [ ] `npm run test` pasa con cobertura ≥ 80% en `sim-engine.ts` y `sponsors.ts`
- [ ] Ningún archivo en `functions/src/` supera las 400 líneas
- [ ] `sim-engine.ts` no contiene ninguna importación de `firebase-admin` o `firebase-functions`
- [ ] El test de regresión `'applies ex_driver crash probability without ReferenceError'` existe y pasa
- [ ] `firebase.json` tiene el predeploy build step configurado
- [ ] `CLAUDE.md` actualizado con las nuevas rutas de scripts de emergencia (`scripts/emergency/`)
- [ ] Firebase Console muestra el nuevo deployment timestamp tras el cutover
- [ ] Primer fin de semana post-migración sin incidentes de simulación

---

## Orden de ejecución recomendado

```
Épica 0  (Limpieza + CLAUDE.md + TS setup)   →  ~2-3h
Épica 1  (Config + Shared)                    →  ~3-4h
Épica 2  (Sim Engine + Tests)                 →  ~5-6h  ← mayor valor, mayor prioridad
Épica 3  (Economy)                            →  ~3-4h
Épica 4  (Dominios independ. + Admin Tools)   →  ~3-4h  (paralelizable con Épica 3)
Épica 5  (Wiring + Firebase.json + Cutover)   →  ~2-3h
```

**Total estimado:** ~18–24 horas de trabajo efectivo.

> La Épica 2 (Sim Engine) es la más importante. Si solo se hace una cosa, que sea extraer `simulateLap()` como función pura y escribir sus tests. Eso elimina el 90% del riesgo actual.
