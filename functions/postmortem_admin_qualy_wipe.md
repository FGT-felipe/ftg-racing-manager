# Postmortem: Admin Tool Wipes Qualifying Grids R1–R3
**Date:** 2026-03-26
**Severity:** Critical — Data loss in production
**Status:** Resolved (partial recovery executed)

---

## Resumen ejecutivo

El admin tool `resetQualifyingSession`, creado para corregir un bug de neumáticos en R3, ejecutó un `batch.update({ qualyGrid: [], qualifyingResults: [] })` sobre **todos** los documentos de la colección `races` que tuvieran `qualyGrid.length > 0`, sin discriminar entre rondas completadas y la ronda activa. Se perdieron los qualifying grids de R1, R2 y R3. Se recuperaron parcialmente mediante `teams/{teamId}/notifications`.

---

## Línea de tiempo

| Hora (COT) | Evento |
|---|---|
| ~2026-03-21 18:00 | R3 qualifying corre vía CF programado. Escribe `qualyGrid` en `races/…_r3`. Bug de neumático activo: `qualifyingBestCompound` guardado como `"soft"` para todos. |
| ~2026-03-22 14:00 | R3 race corre. Usa el `qualyGrid` corrompido como grilla de largada. `finalPositions` escrito correctamente. |
| 2026-03-25 21:20 | Se crea y despliega `resetQualifyingSession` en commit `c94f875`. El tool itera `collection('races')` sin filtro de `isFinished` y borra `qualyGrid` de R1, R2 y R3. |
| 2026-03-26 06:29 | Usuario detecta "NO QUALY DATA FOUND" en Last Results. |
| 2026-03-26 ~09:00 | Diagnóstico. Datos confirmados perdidos en race docs. |
| 2026-03-26 ~10:00 | Recuperación via `notifications` subcollection. 60/66 posiciones exactas, 6 aproximadas cruzadas con transacciones. |
| 2026-03-26 ~10:30 | `restore_qualy_r1_r2_r3.js --write` ejecutado. R1, R2, R3 restaurados en Firestore. |

---

## Causa raíz

```js
// CÓDIGO ORIGINAL — BUGGY
const racesSnap = await getDocs(collection(db, 'races'));
for (const rDoc of racesSnap.docs) {
    const grid = rDoc.data()?.qualyGrid;
    if (!grid || grid.length === 0) continue;
    // ❌ Sin filtro isFinished — toca TODAS las rondas
    racesBatch.update(rDoc.ref, { qualyGrid: [], qualifyingResults: [] });
}
```

**El error:** La intención era limpiar solo la ronda activa (sin `isFinished`). La implementación iteró toda la colección. No había dry-run, no había confirmación, no había scope guard.

```js
// CÓDIGO CORREGIDO
if (rData?.isFinished === true) continue; // ← guard añadido
```

---

## Impacto

| Área | Impacto |
|---|---|
| `races/{id}.qualyGrid` | Borrado en R1, R2, R3 |
| `races/{id}.qualifyingResults` | Borrado en R1, R2, R3 |
| UI Last Results → Qualifying Classification | "NO QUALY DATA FOUND" en todas las rondas |
| `teams/{teamId}.weekStatus.driverSetups` | Reseteado para equipos humanos (intencional para R3/R4, no intencional para R1/R2) |
| Lap times de qualifying | **Irrecuperables** — no almacenados en ninguna fuente secundaria |
| Posiciones de qualifying | Recuperadas 60/66 exactas, 6 aproximadas (pilotos de GBA Racing via transacciones) |

---

## Recuperación

**Fuente de datos utilizada:** `teams/{teamId}/notifications` (tipo `QUALIFYING_RESULT`)
La función de qualifying escribe atómicamente a `news` y `notifications` para cada equipo. Los notifications sobrevivieron porque el admin tool no los tocó.

**Limitaciones de la recuperación:**
- `lapTime`, `gap`, `tyreCompound` no se almacenan en notifications → mostrados como "—" en UI
- 2 pilotos por ronda (equipo GBA Racing) no tenían notifications → posiciones inferidas de transacciones de premios P1/P2/P3 y finalPositions

**Scripts creados:**
- `scripts/emergency/dump_qualy_from_news.js` — diagnóstico read-only vía news
- `scripts/emergency/dump_r3_all_sources.js` — diagnóstico exhaustivo multi-fuente
- `scripts/emergency/restore_qualy_r1_r2_r3.js` — recovery script (dry-run por defecto, `--write` para ejecutar)

---

## Qué falló en el proceso

1. **Sin dry-run:** El tool ejecutó writes sin previo listado de documentos afectados.
2. **Sin scope guard:** Ninguna validación de si el documento era una ronda histórica completada.
3. **Sin revisión de superficie de impacto:** No se verificó cuántos docs serían afectados antes de ejecutar.
4. **Datos críticos en una sola colección:** `qualyGrid` solo existía en `races/{id}`. Ninguna colección inmutable de backup.
5. **Emergency scripts sin news:** `force_race_local.js` no llama a `addOfficeNews`, creando un gap en la cadena de recovery.
6. **Sin exports automáticos:** Firestore no tenía backups programados configurados.

---

## Action Items

### Inmediatos (ya aplicados en este hotfix)
- [x] Guard `isFinished === true` en `resetQualifyingSession` para no tocar rondas completadas
- [x] Frontend: normalización `qualifyingResults || qualyGrid` en ResultsPanel
- [x] Frontend: `subscribeToRace` llama callback con `null` cuando el doc no existe (fix "Connecting to race control")
- [x] UI: mensaje "Waiting for Race Start" en lugar de "Leaderboard DNF"

### Backlog (ver ROADMAP.md T-018 a T-022)
- [ ] **T-018** Dry-run mode + pre-flight en todos los admin tools destructivos
- [ ] **T-019** Firestore Scheduled Export a Cloud Storage (backup diario automático)
- [ ] **T-020** Colección `qualifying_results` inmutable como fuente secundaria permanente
- [ ] **T-021** `force_race_local.js` debe escribir `addOfficeNews` al completar qualifying
- [ ] **T-022** Audit completo de admin tools: scope guards, documentación de riesgo

---

## Lecciones aprendidas

> **Regla nueva (ver CLAUDE.md §4):** Todo admin tool que itere una colección completa debe tener un scope guard explícito y un comentario `// SCOPE: ...` que documente qué documentos afecta. Ningún tool destructivo puede ejecutarse sin modo dry-run previo.

> **Regla nueva:** Datos que son fuente de verdad para estadísticas, economía o clasificaciones deben escribirse en al menos dos colecciones: la principal (mutable, operacional) y una secundaria inmutable (append-only) que nunca sea limpiada por operaciones administrativas.
