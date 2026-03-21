# Postmortem: Falla de Simulación del Fin de Semana R3

**Fecha del incidente:** 21 de marzo de 2026  
**Severidad:** Alta — Qualy no generó resultados. La UI se quedó en "Session Qualifying In Progress" indefinidamente.  
**Estado:** Corregido ✅ (pendiente deploy + recuperación manual)

---

## 1. ¿Qué pasó?

La simulación automática de la Qualy de Ronda 3 (sábado 21 de marzo) no generó resultados. La pantalla de "Qualy Live" mostraba "Session Qualifying In Progress" con un contador regresivo que nunca cambiaba. La colección `races` en Firestore nunca recibió el documento con `qualyGrid`, confirmando que la función `scheduledQualifying` murió silenciosamente.

**Este es el mismo Bug #1 documentado en `postmortem_r2.md`, que nunca fue corregido en el código desplegado.**

---

## 2. Causa Raíz

### Bug #1 (REINCIDENCIA) — Variable `extraCrash` sin declarar (`CRÍTICO`)
**Archivo:** `functions/index.js`, función `SimEngine.simulateLap()`, línea ~355.

El parche documentado en el postmortem R2 (`let extraCrash = 0;`) **nunca fue aplicado al archivo `index.js` desplegado**. La línea seguía siendo:

```js
// ANTES (buggy):
if (teamRole === "ex_driver") {
  extraCrash = 0.001;  // ← ReferenceError en strict mode: extraCrash no está declarada
}
const crashed = Math.random() < (accProb + extraCrash);
```

```js
// DESPUÉS (corregido):
let extraCrash = 0;       // ← Declaración obligatoria
if (teamRole === "ex_driver") {
  extraCrash = 0.001;
}
const crashed = Math.random() < (accProb + extraCrash);
```

### Bug #2 (REINCIDENCIA) — qualyGrid truthiness checks (`MEDIO`)
**Archivo:** `functions/index.js`, funciones `runQualifyingLogic()` y `runRaceLogic()`.

Ambas funciones usaban `if (rSnap.data().qualyGrid)` en vez de `.length > 0`. Un array vacío `[]` es truthy en JavaScript, lo que provocaría que:
- La qualy creyera que ya terminó (y saltara la liga).
- La carrera intentara simular sobre una grilla vacía.

---

## 3. ¿Por qué se repitió?

1. **El fix de R2 no fue desplegado**: El archivo `index.js` tenía la fecha `Deployment: 2026-02-24`, anterior al incidente R2 del 16-Mar-2026. Esto indica que la corrección original se aplicó solo localmente durante la recuperación manual (con `run_simulation.js`), pero nunca se hizo `firebase deploy --only functions` con el fix incluido.
2. **Sin CI/CD**: No existe un pipeline automatizado que ejecute linting o tests antes del deploy. El bug habría sido detectable con un simple linter configurado con `"use strict"`.
3. **Sin verificación post-deploy**: No se verificó en Firebase Console que la función desplegada incluyera el fix.

---

## 4. Correcciones Aplicadas

| Fix | Línea | Cambio |
|-----|-------|--------|
| `let extraCrash = 0` | ~354 | Declaración de variable antes del `if` |
| qualyGrid length check (qualy) | ~906 | `qualyGrid && qualyGrid.length > 0` |
| qualyGrid length check (race) | ~1224 | `!qualyGrid \|\| qualyGrid.length === 0` |

---

## 5. Acciones Preventivas Obligatorias

1. **Deploy inmediato**: `firebase deploy --only functions` tras aplicar los fixes.
2. **Recuperación manual**: Ejecutar el pipeline completo (ver `postmortem_r2.md` sección 6).
3. **Verificación post-deploy**: Confirmar en Firebase Console → Functions que `scheduledQualifying` tiene timestamp de deploy del 21-Mar-2026.
4. **Agregar ESLint strict mode**: Configurar `"use strict"` y `no-undef` en las reglas de ESLint del proyecto `/functions`.
5. **Checklist pre-deploy**: Antes de cada `firebase deploy`, verificar que `index.js` no tenga variables sin declarar con `npx eslint index.js --rule "no-undef: error"`.

---

## 6. Pipeline de Recuperación (igual que R2)

> Ejecutar en orden desde `/functions`:

```
Paso 1 (Reset):        node reset_all.js
Paso 2 (Qualy):        node run_simulation.js qualy
Paso 3 (Verificar):    Firebase Console → races → qualyGrid.length > 0
Paso 4 (Deploy):       firebase deploy --only functions
```

> La carrera del domingo usará la función desplegada con el fix.
