# Postmortem — Weekly Update Failure (Round 4, 2026-03-29)

**Fecha del incidente:** 2026-03-30 (detectado lunes)
**Severidad:** Alta — standings desactualizados, eventos semanales parcialmente ausentes
**Rama de corrección:** `hotfix/weekly-update-reliability`
**Estado:** En análisis — pendiente datos adicionales del usuario

---

## Síntomas reportados

1. `/season/standings` muestra datos de rondas anteriores (standings stale)
2. Algunos equipos no recibieron eventos semanales (academia, salarios, bonos de patrocinador)

---

## Análisis de la función `postRaceProcessing`

### Cómo funciona actualmente

La función `exports.postRaceProcessing` (index.js:1797) corre cada 30 minutos via Cloud Scheduler. Al encontrar una carrera con `isFinished == true` y `postRaceProcessed == false`, ejecuta el pipeline semanal completo:

```
1. Sponsor payouts + decrement racesRemaining
2. Facility maintenance deduction
3. Driver salary deductions
4. Fitness trainer + psychologist salary
5. Academy XP, events, specialization triggers
6. weekStatus reset para todos los equipos
7. AI bot upgrades (30% por stat)
8. Marca la carrera como postRaceProcessed = true
```

### Bugs identificados

---

#### Bug #1 — Universe Sync no automatizado (causa más probable del síntoma 1)

**Dónde:** Ausente en `postRaceProcessing` — requiere paso manual
**Código actual:** El sync de `universe/game_universe_v1` no está incluido en el pipeline.
**Efecto:** `/season/standings` siempre muestra datos stale tras carrera. Requiere `node sync_universe.js` manual.
**Diagnóstico:** Si `postRaceProcessed == true` en Firestore pero standings están desactualizados → este es el bug.

---

#### Bug #2 — Scope limitado a equipos en `finalPositions` (posible causa del síntoma 2)

**Dónde:** index.js:1823-1832
```js
const driverIds = Object.keys(rd.finalPositions || {});
const teamIdsSet = new Set();
for (const did of driverIds) {
    const dDoc = await db.collection("drivers").doc(did).get();
    if (dDoc.exists) { teamIdsSet.add(dDoc.data().teamId); }
}
```
**Efecto:** Solo los equipos cuyos pilotos aparecen en `finalPositions` reciben economía semanal.
Si `finalPositions` está incompleto (piloto sin `teamId`, driver document faltante, bot team sin registro completo) → el equipo queda fuera del ciclo económico.
**Diagnóstico pendiente:** Confirmar si todos los drivers en `finalPositions` tienen `teamId` correcto en Firestore.

---

#### Bug #3 — `weekStatus` reset por reemplazo total (regresión silenciosa v1.5.0)

**Dónde:** index.js:2241-2267
```js
batch.update(tRef, {
    "weekStatus": {
        practiceCompleted: false,
        // ... solo campos conocidos al momento de escritura
        psychologistSessionDoneThisWeek: false,  // agregado manualmente
    }
});
```
**Efecto:** El reset escribe un objeto completo reemplazando `weekStatus`. Cualquier campo nuevo añadido al `weekStatus` en futuras versiones (o ya existente y no listado aquí) se **pierde silenciosamente** tras el reset.
**Riesgo activo:** Los campos del sistema de moral añadidos en v1.5.0 deben estar explícitamente en esta lista o se borran cada semana.

---

#### Bug #4 — Año hardcodeado en promoción de academia

**Dónde:** index.js:2152
```js
const currentYear = 2026;  // ← hardcodeado
```
**Efecto:** Incorrecto en temporada 2027+. Los drivers promovidos tendrán careerHistory con años incorrectos.
**Solución:** `const currentYear = new Date().getFullYear();`

---

#### Bug #5 — Riesgo de timeout con lectura Firestore secuencial

**Dónde:** Loop principal index.js:1855 — cada iteración de equipo hace múltiples `await` encadenados
**Efecto:** Con muchos equipos (>10 por liga × múltiples ligas), la función puede exceder los 300 segundos de timeout. El error se loguea pero `postRaceProcessed` queda en `false`, causando re-ejecución que puede procesar economía **dos veces**.
**Diagnóstico pendiente:** Revisar Firebase Console → Functions → postRaceProcessing → logs de ejecución para la carrera de Round 4.

---

#### Bug #6 — Sin observabilidad para el manager

**Dónde:** No existe notificación al manager de que el procesamiento semanal completó
**Efecto:** No hay forma de saber si el proceso corrió sin revisar Firebase Console. Los managers no reciben ninguna confirmación in-app.

---

## Pasos de diagnóstico inmediato (pre-fix)

> Ejecutar antes de implementar la corrección para entender el estado actual:

### 1. Verificar si postRaceProcessed está en true
En Firebase Console → Firestore → `races` → buscar la carrera de Round 4:
- Si `postRaceProcessed == false` y `postRaceProcessingAt` ya pasó → el proceso nunca corrió
- Si `postRaceProcessed == true` → corrió, pero universe sync falta

### 2. Verificar Firebase Functions logs
Firebase Console → Functions → `postRaceProcessing` → Logs → Filtrar por Round 4 date (2026-03-29):
- ¿Aparece `"Post-race processing: {raceId}"`?
- ¿Aparece `"Post-race done: {raceId}"`?
- ¿Hay errores entre los dos?

### 3. Recovery inmediata (si postRaceProcessed == false)
```bash
cd functions/scripts/emergency
node force_post_race.js     # Forza el pipeline económico
node sync_universe.js       # Actualiza standings
```

### 4. Recovery inmediata (si postRaceProcessed == true pero standings stale)
```bash
cd functions/scripts/emergency
node sync_universe.js       # Solo falta el sync
```

---

## Plan de corrección (pendiente datos adicionales del usuario)

### Fase 1 — Recovery inmediata (sin código)
- Correr scripts de diagnóstico
- Determinar si se necesita `force_post_race.js` o solo `sync_universe.js`

### Fase 2 — Fixes en `functions/index.js`
Los siguientes cambios están planificados, pendiente confirmación del scope con el usuario:

| # | Fix | Impacto | Riesgo |
|---|-----|---------|--------|
| F1 | Automatizar universe sync al final de `postRaceProcessing` | Elimina standings stale | Bajo |
| F2 | Expandir scope a TODOS los equipos activos (no solo `finalPositions`) | Garantiza economía completa | Medio — requiere query adicional |
| F3 | Cambiar `weekStatus` reset a escritura parcial (FieldValue.delete + merge) | Previene pérdida de campos nuevos | Bajo |
| F4 | Reemplazar `const currentYear = 2026` por `new Date().getFullYear()` | Correcto en 2027+ | Mínimo |
| F5 | Agregar `addOfficeNews` al finalizar el pipeline por equipo | Observabilidad in-app | Bajo |
| F6 | Paralelizar reads con `Promise.all` donde sea seguro | Reduce riesgo timeout | Medio |

### Fase 3 — Documentación
- Actualizar `weekend_pipeline.md` con el nuevo comportamiento
- Agregar scope guard y `// SCOPE:` comment al loop de equipos
- Crear script de diagnóstico `check_post_race_status.js`

---

## Preguntas pendientes al usuario

1. ¿Qué muestra `postRaceProcessed` en Firestore para la carrera de Round 4?
2. ¿Hay errores en Firebase Console → Functions → postRaceProcessing logs del 2026-03-29?
3. ¿Cuáles equipos específicamente no recibieron eventos semanales?
4. ¿El `sync_universe.js` se corrió manualmente tras la carrera?
5. ¿Quieres que el universe sync sea totalmente automático (incluido en postRaceProcessing) o prefieres mantenerlo manual con mejor documentación?

---

*Documento creado: 2026-03-30 | Autor: Claude Code | Estado: Análisis en curso*
