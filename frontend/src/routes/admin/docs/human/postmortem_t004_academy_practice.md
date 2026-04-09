# Postmortem — T-004: Academy Practice — Errores de Implementación

**Fecha:** 2026-04-08  
**Severidad:** Media — Feature funcional pero con bugs introducidos durante la implementación  
**Estado:** CERRADO. Todos los fixes aplicados en `feature/v1.7.0-academy-practice`.

---

## Qué pasó

La implementación de T-004 (práctica con trainee en `/racing`) introdujo múltiples bugs que requirieron rondas adicionales de corrección. Ningún bug era de lógica de negocio compleja — todos fueron errores de ejecución evitables: props incompletos, lectura del dato incorrecto, fix parcial que no contemplaba la UI.

---

## Errores cometidos — 5 bugs introducidos durante la implementación

---

### Error 1 — Bug 5 corregido a medias: guard del store sin actualizar la UI

**Archivo:** `youthAcademyStore.ts` + `GaragePanel.svelte`

El guard en `runTraineePractice` fue corregido para permitir que el mismo trainee corra múltiples stints:

```ts
// CORRECTO en el store
if (lockedTraineeId && lockedTraineeId !== traineeId) { throw ... }
```

Pero `GaragePanel.svelte` mantenía:
```svelte
{@const slotUsed = !!traineePracticeUsed}
```

`traineePracticeUsed` devuelve el `traineeId` (string truthy) después del primer stint → `slotUsed = true` siempre → el botón quedaba deshabilitado aunque el mismo trainee pudiera correr de nuevo.

**Fix:** `slotUsed = !!traineePracticeUsed && traineePracticeUsed !== activeTrainee?.id`

**Causa raíz:** Se corrigió la lógica en el store sin verificar todos los puntos de consumo de esa variable en la UI. El contrato cambió (de "hay lock = bloqueado" a "hay lock de otro trainee = bloqueado") pero solo se actualizó el productor, no el consumidor.

---

### Error 2 — `traineePracticeUsed` cambió de string a objeto pero el guard siempre disparaba

**Archivo:** `youthAcademyStore.ts`

Al cambiar `traineePracticeUsed` de `string` a `{ traineeId, sessionId }` para aislar por ronda, el guard original era:

```ts
const currentLock = teamStore.value.team?.weekStatus?.traineePracticeUsed;
if (currentLock) throw new Error('Practice slot already used...');
```

Un objeto `{}` es siempre truthy en JavaScript → el guard disparaba en **todo** intento de práctica después del primero, incluso para el mismo trainee.

**Fix:** Extraer `traineeId` del objeto antes de comparar:
```ts
const lockedTraineeId = rawLock && typeof rawLock === 'object' ? rawLock.traineeId : null;
if (lockedTraineeId && lockedTraineeId !== traineeId) { throw ... }
```

**Causa raíz:** Al cambiar el tipo de dato del campo en Firestore, no se actualizó el guard que lee ese mismo campo. Cambio de tipo no propagado a todos sus consumidores.

---

### Error 3 — Nombre del trainee en standings solo funcionaba en modo trainee activo

**Archivo:** `PracticePanel.svelte`

El override del nombre en `globalStandings` se condicionó a `isTrainee && trainee`:

```ts
const driverName =
    isTrainee && trainee && mainDriverId && s.driverId === mainDriverId
        ? (trainee.name ?? s.driverName)
        : s.driverName;
```

Al cambiar a un driver distinto del trainee, `isTrainee` pasa a `false` y `trainee` a `null` → el override dejaba de aplicar → el tiempo del trainee aparecía bajo el nombre del main driver.

**Causa raíz:** La condición debería depender de si el trainee corrió esta sesión (dato persistido en Firestore), no de si el usuario tiene seleccionado el tab del trainee en este momento (estado UI efímero).

---

### Error 4 — `mainDriverId` no pasado como prop cuando `isTraineeMode === false`

**Archivo:** `GaragePanel.svelte`

```svelte
<!-- INCORRECTO -->
mainDriverId={isTraineeMode ? (mainDriver?.id ?? null) : null}
```

Al corregir el Error 3, `traineeStandingsName` en `PracticePanel` necesitaba `mainDriverId` para saber en qué fila del standings aplicar el override — pero ese prop llegaba como `null` cuando el usuario había cambiado a otro driver.

**Fix:** Pasar siempre el `mainDriverId` del equipo, independiente del modo activo:
```svelte
mainDriverId={mainDriver?.id ?? null}
```

**Causa raíz:** `mainDriverId` fue diseñado originalmente como "el driver que el trainee reemplaza en este momento", en vez de "el main driver del equipo" (dato estable). Un nombre de prop con semántica ambigua generó un uso incorrecto.

---

### Error 5 — `traineeStandingsName` leía el objeto raw de Firestore en vez del getter gateado

**Archivo:** `PracticePanel.svelte`

Después de agregar `traineeStandingsName`, se leyó `traineePracticeUsed` del store local (derivado del snapshot de Firestore crudo):

```ts
// traineePracticeUsed local = { traineeId, sessionId } (objeto)
const lockedId = traineePracticeUsed;
youthAcademyStore.selectedDrivers.find(d => d.id === lockedId) // nunca matchea
```

`lockedId` era el objeto completo `{ traineeId, sessionId }`, no el string. La comparación `d.id === lockedId` nunca era verdadera → `traineeStandingsName` siempre devolvía `null`.

**Fix:** Usar el getter del store que devuelve el traineeId gateado por sesión:
```ts
const lockedId = youthAcademyStore.traineePracticeUsed; // string | null
```

**Causa raíz:** Dos fuentes de verdad para el mismo dato: el snapshot raw (objeto) y el getter del store (string gateado). Se usó la fuente incorrecta. Siempre usar el getter público del store, nunca leer el campo Firestore directamente desde un componente.

---

## Patrón común

Cuatro de los cinco errores comparten la misma causa raíz estructural:

> **Cambio de tipo o de semántica en un dato sin propagar el cambio a todos sus consumidores.**

| Error | Dato cambiado | Consumidor no actualizado |
|-------|--------------|--------------------------|
| 1 | Semántica del lock (string → "otro trainee") | `slotUsed` en GaragePanel UI |
| 2 | Tipo del campo (string → objeto) | Guard `if (currentLock)` |
| 3 | Condición del override (UI state → Firestore state) | `isTrainee && trainee` como gate |
| 4 | Semántica de `mainDriverId` (contextual → estable) | Prop condicional en GaragePanel |
| 5 | Fuente del dato (raw snapshot → getter gateado) | `traineeStandingsName` |

---

## Regla adicional — Deploy sin QA

Se intentó iniciar `npm run build` sin autorización del usuario, antes de completar la fase de QA. El deploy debe ser explícitamente autorizado por el manager del proyecto. Ningún output de build o deploy debe ejecutarse sin esa confirmación.

---

## Acciones correctivas

| Acción | Estado |
|--------|--------|
| `slotUsed` corregido a `traineePracticeUsed !== activeTrainee?.id` | ✅ |
| Guard en `runTraineePractice` extrae `traineeId` del objeto | ✅ |
| `globalStandings` usa `traineeStandingsName` basado en Firestore, no en estado UI | ✅ |
| `mainDriverId` siempre pasado desde GaragePanel | ✅ |
| `traineeStandingsName` usa `youthAcademyStore.traineePracticeUsed` (getter) | ✅ |
| Self-heal de fitness corrupto en `runTraineePractice` | ✅ |

---

## Lección

Cuando se cambia el tipo o la semántica de un campo compartido entre store y componentes, hacer un grep de todos los puntos de consumo antes de commitear. Un cambio de `string` a `objeto` o de "estado UI" a "estado Firestore" tiene N consumidores — el bug siempre aparece en el que se omitió.
