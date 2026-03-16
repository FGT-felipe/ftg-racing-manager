# Postmortem: Falla de Simulación del Fin de Semana R2

**Fecha del incidente:** 16 de marzo de 2026  
**Severidad:** Alta — Todas las ligas afectadas, resultados inexistentes durante más de 3 horas.  
**Estado:** Resuelto ✅

---

## 1. ¿Qué pasó?

La simulación automática de la Ronda 2 (Qualy del sábado y Carrera del domingo) no generó resultados visibles para ningún jugador. La aplicación mostraba la carrera como "en progreso" indefinidamente. Los standings no se actualizaron, los fondos no cambiaron, y el equipo financiero no recibió los pagos de carrera ni los bonos de sponsors.

---

## 2. Causas Raíz (3 bugs independientes)

### Bug #1 — Variable sin declarar en el motor de físicas (`CRÍTICO`)
**Archivo:** `functions/index.js`, función `simulateLap()`, línea ~352.

Un parche previo agregó una penalización especial de riesgo de choque para mánagers tipo "Ex-Driver". El código correcto debía ser:
```js
let extraCrash = 0;          // ← FALTABA esta línea
if (teamRole === "ex_driver") {
  extraCrash = 0.001;
}
const crashed = Math.random() < (accProb + extraCrash); // línea 361
```
Sin la declaración `let`, Node.js en modo estricto lanzaba un `ReferenceError` silencioso **para cada escudería de cada liga**. Esto abortaba el loop de simulación sin guardar la grilla. El resultado: `qualyGrid: []` (vacío), pero la carrera se marcaba como completada.

**¿Por qué fue tan difícil de detectar?** Porque el `catch` del loop guardaba el error solo en los logs de Firebase, no en la consola local. PowerShell además mezclaba warnings de `punycode` que ocultaban el error real.

### Bug #2 — Array vacío evaluado como `true` (`MEDIO`)
**Archivo:** `functions/index.js`, función `runRaceLogic()`.

El chequeo para saltar una liga ya simulada era:
```js
if (rSnap.data().qualyGrid) continue;   // ANTES ← cualquier array es truthy, incluso []
if (rSnap.data().qualyGrid.length > 0) continue; // CORRECTO ← ya corregido en parche previo
```
Esto causaba que la carrera intentara simular sobre una grilla vacía, produciendo archivos de resultados vacíos (`finalPositions: {}`).

### Bug #3 — Standings leen de documento cacheado, no en tiempo real (`ESTRUCTURAL`)
**Archivo:** La página `/season/standings` lee del documento `universe` de Firestore, un documento **denormalizado** que agrega los datos de todas las ligas.

**El problema:** El script `runRaceLogic` actualiza los documentos individuales de `drivers/` y `teams/`, pero el documento `universe` es un caché estático que **nadie actualiza automáticamente**. Debe ser sincronizado manualmente con `node sync_universe.js` después de cada simulación manual.

---

## 3. Cronología del Incidente

| Hora (COT) | Evento |
|---|---|
| Sáb ~15:00 | `scheduledQualifying` dispara; muere silenciosamente (Bug #1) |
| Dom ~14:00 | `scheduledRace` dispara; encuentra grilla vacía (Bug #2) |
| Dom ~15:30 | Admin detecta que la R2 no tiene resultados |
| Dom ~16:00 | Diagnóstico: stack trace capturado, Bug #1 identificado |
| Dom ~16:10 | Corrección de `let extraCrash = 0;` aplicada en `index.js` |
| Dom ~16:15 | Reset de datos sucios de R2 en Firestore (`node reset_all.js`) |
| Dom ~16:30 | Qualy & Race simuladas exitosamente con `run_simulation.js` |
| Dom ~17:00 | `postRaceProcessing` ejecutado con `force_post_race.js` |
| Dom ~17:15 | Standings actualizados con `node sync_universe.js` |

---

## 4. Impacto en Jugadores

- **Resultados de carrera:** No disponibles por ~3h. ✅ Resueltos.
- **Finanzas:** Sin actualizaciones de budget por ~4h. ✅ Resuelta con `force_post_race.js`.
- **Standings:** Standings mostrando datos de R1 por ~4h. ✅ Resueltos con `sync_universe.js`.
- **Notificaciones de bonos de sponsors:** Se procesan dentro de `postRaceProcessing`. ✅ Incluidas.
- **Experiencia de pilotos:** Incluida en `postRaceProcessing`. ✅ Incluida.

---

## 5. Acciones Preventivas para el Futuro

1. **Declarar siempre variables antes de usarlas en condicionales** — `let extraCrash = 0;` antes de cualquier `if` que la asigne.
2. **Checar grilla con `.length > 0`, nunca con solo la existencia del array** — `qualyGrid: []` es truthy en JavaScript.
3. **Después de cualquier simulación manual, siempre ejecutar el pipeline completo** (ver sección 6).
4. **Verificar en la Consola de Firebase** después de Qualy que `qualyGrid` tiene al menos 20 entradas antes del domingo.

---

## 6. Pipeline Completo del Fin de Semana

> Este es el checklist a seguir manualmente si alguna simulación automática falla.
> Todos los comandos se ejecutan desde la carpeta `/functions`.

```
SÁBADO (Qualy):
──────────────────────────────────────────────
□ Automático: scheduledQualifying @ 15:00 COT

VERIFICACIÓN POST-QUALY (ir a Firebase Console):
□ Race document → qualyGrid.length > 0
□ Race document → status: "qualifying"

DOMINGO (Carrera):
──────────────────────────────────────────────
□ Automático: scheduledRace @ 14:00 COT

VERIFICACIÓN POST-CARRERA:
□ Race document → isFinished: true, status: "completed"
□ Race document → finalPositions (no vacío)
□ Race document → postRaceProcessed: true (puede demorar ~1h)
□ UI Standings muestran puntos actualizados

──────────────────────────────────────────────
SI ALGO FALLA → RECUPERACIÓN MANUAL:
──────────────────────────────────────────────
Paso 1 (Reset):        node reset_all.js
Paso 2 (Qualy):        node run_simulation.js qualy
Paso 3 (Carrera):      node run_simulation.js race
Paso 4 (Finanzas):     node force_post_race.js
Paso 5 (Standings):    node sync_universe.js
```

---

## 7. Estado del Universo Tras la Recuperación

| Liga | Qualy | Carrera | Finanzas | Standings |
|---|---|---|---|---|
| FTG World Championship | ✅ 22 pilotos | ✅ Completa | ✅ Procesada | ✅ Synced |
| FTG 2th Series | ✅ Compartida | ✅ Completa | ✅ Procesada | ✅ Synced |
| FTG Karting Championship | ✅ Compartida | ✅ Completa | ✅ Procesada | ✅ Synced |
