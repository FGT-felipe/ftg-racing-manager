# Postmortem: Bug de Vista Racing Post-Carrera R3

**Fecha del incidente:** 22 de marzo de 2026  
**Severidad:** Media — La vista Racing mostraba "Live Leaderboard DNF" en vez del Garaje. Temporizador incorrecto (~2h en vez de ~5d).  
**Estado:** Corregido ✅

---

## 1. ¿Qué pasó?

Tras la ejecución exitosa de la R3 (domingo 22-Mar), la vista `/racing` mostraba el panel `RaceLivePanel` con "Live Leaderboard DNF" y "Waiting for Race Start" en lugar del panel `GaragePanel` con las pestañas de Practice, Qualy y Race Strategy para preparar la R4.

Adicionalmente, el panel de Qualifying mostraba un temporizador de ~2 horas (contando hasta el lunes 00:00) en lugar de ~5 días (contando hasta el sábado 14:00, hora real de la Qualy R4).

---

## 2. Causas Raíz

### Bug #1 — Fallback de `weekStatus` no maneja `postRace` (`CRÍTICO`)
**Archivo:** `frontend/src/routes/racing/+page.svelte`, línea ~28.

El campo `weekStatus.globalStatus` no existe en Firestore (nunca fue escrito por el backend). El fallback usaba `timeService.currentStatus` que devuelve `"postRace"` los domingos después de las 16:00. La condición en línea ~133 (`["race", "postrace"].includes(weekStatus.toLowerCase())`) matcheaba `postRace` → mostraba `RaceLivePanel` vacío.

```js
// ANTES (buggy):
let weekStatus = $derived(
    teamStore.value.team?.weekStatus?.globalStatus ||
        timeService.currentStatus ||   // ← devuelve "postRace" el domingo noche
        "practice",
);
// Luego:
if (["race", "postrace"].includes(weekStatus.toLowerCase())) → RaceLivePanel (vacío)
```

```js
// DESPUÉS (corregido):
let weekStatus = $derived.by(() => {
    const firestoreStatus = teamStore.value.team?.weekStatus?.globalStatus;
    if (firestoreStatus) return firestoreStatus;
    const timeStatus = timeService.currentStatus;
    if (timeStatus === RaceWeekStatus.POST_RACE) return "practice";
    return timeStatus || "practice";
});
```

### Bug #2 — Temporizador contaba hasta el próximo cambio de estado, no hasta Qualy (`MEDIO`)
**Archivo:** `frontend/src/lib/components/racing/QualifyingPanel.svelte`, línea ~26.

`getTimeUntilNextEvent()` calcula el tiempo hasta el próximo cambio de estado del `timeService`. El domingo a las 22:00, el próximo cambio es lunes 00:00 (inicio de `PRACTICE`), no el sábado 14:00 (inicio de `QUALIFYING`).

```js
// ANTES: getTimeUntilNextEvent() → 2h (hasta lunes 00:00)
// DESPUÉS: getTimeUntil(RaceWeekStatus.QUALIFYING) → 5d (hasta sábado 14:00)
```

### Bug #3 — Texto de estado usaba comparación incorrecta (`BAJO`)
**Archivo:** `QualifyingPanel.svelte`, línea ~139.

La condición `currentStatus === 'practice'` mostraba "In Progress" para cualquier estado que no fuera `practice` (incluyendo `postRace`, `raceStrategy`, etc.). Corregido a `currentStatus === RaceWeekStatus.QUALIFYING`.

---

## 3. Correcciones Aplicadas

| Fix | Archivo | Cambio |
|-----|---------|--------|
| Fallback `postRace → practice` | `racing/+page.svelte` | `$derived.by()` con mapeo explícito de `POST_RACE` |
| Temporizador a Qualy | `QualifyingPanel.svelte` | `getTimeUntil(QUALIFYING)` en lugar de `getTimeUntilNextEvent()` |
| Texto de estado | `QualifyingPanel.svelte` | Comparación contra `RaceWeekStatus.QUALIFYING` |

---

## 4. Lecciones Aprendidas

1. **`globalStatus` no existe en el backend**: El campo `weekStatus.globalStatus` nunca fue escrito por `functions/index.js`. Todo el control del estado de la vista Racing depende del fallback en el frontend. Este fallback DEBE manejar todos los estados posibles del `timeService`, incluyendo `POST_RACE`.
2. **`getTimeUntilNextEvent()` no es lo mismo que "tiempo hasta la siguiente sesión"**: Esta función cuenta hasta el siguiente *cambio de estado* del `timeService`, no hasta una sesión específica. Para temporizadores específicos, usar `getTimeUntil(targetStatus)`.
3. **No usar comparaciones de strings para enums**: Usar siempre `RaceWeekStatus.QUALIFYING` en lugar de `'practice'` o `'qualifying'` para evitar errores silenciosos con estados no contemplados.
