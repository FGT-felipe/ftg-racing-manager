# Postmortem — v1.7.x Session-Gate Cascade

**Fecha:** 2026-04-11
**Severidad:** P1 recurrente — 4 releases consecutivas con fixes al mismo subsistema, último hotfix a ~10 minutos del corte de qualy automático.
**Estado:** Hotfix desplegado (`e2d1ec1`). Causa raíz aún no atacada.

---

## 1. Resumen ejecutivo

Entre v1.7.0 y v1.7.3 (hotfix incluido) se shipearon **cuatro releases consecutivas** que tocan el mismo subsistema (`weekStatus.driverSetups`) y todas introducen o reabren bugs P1. El hotfix de hoy se desplegó con jugadores activos en la sesión de qualy en producción. El patrón no es mala suerte: es una decisión arquitectónica no resuelta que cada release intenta tapar con un parche distinto en vez de arreglarla en la fuente.

---

## 2. Línea de tiempo

| Release | Fecha | Qué tocó | Bugs introducidos |
|---|---|---|---|
| v1.7.0 (T-004) | 2026-04-08 | Trainee practice → introduce session gate vía `practice.sessionId` como proxy global | 5 bugs (ver `postmortem_t004_academy_practice.md`) |
| v1.7.1 | 2026-04-08 | PreparationChecklist gating | Parche del proxy, no de la fuente |
| v1.7.3 | 2026-04-11 AM | Trainee standings name → expandido a 5 fixes de session gating (qualy attempts, parc fermé, Race Prep, tyre compound, standings competidores) | Branch ballooneada con 6 archivos modificados, cada fix sin QA propia |
| v1.7.3 hotfix | 2026-04-11 ~13:50 | Tyre compound se reverteaba mid-attempt; runs viejos mezclados con nuevos vía `arrayUnion`; piloto que no practicó tenía su qualy oculta | Desplegado con jugadores en sesión activa |

Cuatro releases. Mismo subsistema. Causa raíz nunca tocada.

---

## 3. Causa raíz (la que nadie arregló)

El Cloud Function `processPostRace` **no limpia `weekStatus.driverSetups` al cerrar una ronda.** El registro de R(N) sobrevive intacto a R(N+1). Toda la complejidad de session gating en el frontend existe para compensar esa única línea faltante en backend.

```ts
// functions/index.js — processPostRace, ausente:
batch.update(teamRef, {
    'weekStatus.driverSetups': {},  // ← esta línea no existe
});
```

Cada bug P1 de v1.7.x es una variante de "datos de R(N-1) leakean a R(N+1)":

| Bug | Cómo leakea |
|---|---|
| Tyre compound revertido | `qualifying.tyreCompound` viejo se spreaded sobre el setup nuevo |
| Parc fermé bloqueado | `qualifyingParcFerme` viejo persiste |
| Race Prep al 100% | `race` (CarSetup) viejo cuenta como "enviado" |
| Qualy attempts mostrando 6/6 | `qualifyingAttempts: 6` viejo persiste |
| Trainee name en standings | Composición de objeto stale |
| Runs mezclados (hoy) | `qualifyingRuns[]` con `arrayUnion` acumula entre rondas |
| Piloto 2 sin runs (hoy) | Gate proxy `practice.sessionId` ocultaba su qualy fresca |

Cada fix añadió un nuevo session-tag (`practice.sessionId`, `qualifyingSessionId`, `raceSessionId`) o un nuevo strip-on-load. Ninguno borró el dato. La consecuencia: la complejidad del gating crece release a release y la superficie de bugs crece con ella.

---

## 4. Patrones de proceso que están fallando

### 4.1 Symptom-first fixing

Cuando aparece un P1, se parcha en el punto de lectura (componente) en vez de en el punto de origen (post-race CF). Resultado: el bug se mueve a otro componente que también lee el mismo campo, y la próxima release lo descubre.

**Evidencia:** v1.7.1 parchó `PreparationChecklist`. v1.7.3 parchó `QualifyingSetupTab`, `PracticePanel`, `RaceSetupTab`, `StrategyPanel` y `PreparationChecklist` otra vez. Cinco componentes distintos, mismo problema, cinco parches independientes.

### 4.2 No se camina la máquina de estados después del fix

Cada fix verifica solo el escenario reportado. Los fixes en `driverSetups` nunca son walked code-side por las cuatro fases del weekend (practice → qualy → race → next round) ni por las dos rutas del jugador (con práctica / sin práctica). Resultado: el bug aparece en la fase adyacente que nadie revisó.

**Evidencia:** El hotfix de hoy es exactamente eso. v1.7.3 AM "arregló" el tyre compound revertido para el caso "el usuario practicó este round". El caso "el usuario NO practicó este round" (driver 2 en producción) nunca fue caminado, y el bug seguía vivo.

### 4.3 Speed-ship sin QA humano

`/deploy` se ejecuta inmediatamente después de aplicar el fix, sin un alto explícito para que el manager del proyecto verifique en `localhost`. v1.7.3 se shipeó esta mañana. ~3 horas después, jugadores reportaron el mismo bug. El hotfix se desplegó con la sesión de qualy a 10 minutos.

### 4.4 Scope creep dentro de la misma branch

`fix/v1.7.3-trainee-standings-name` empezó como un fix de cosmetic naming (T-032). Terminó tocando 6 archivos y arreglando 5 P1s descubiertos durante la implementación. Cada fix incremental se agregó al mismo commit sin su propia ronda de verificación. La branch fue mergeada con la mentalidad de "ya que estamos, mandamos todo".

### 4.5 $effect como reset blanco

`QualifyingSetupTab` y `PracticePanel` reseteaban el estado del setup dentro de `$effect` cada vez que el efecto re-corría. Como `$effect` se re-ejecuta en cada snapshot del doc del team (incluyendo escrituras totalmente no relacionadas: budget, sponsors, charge fees), el reset destruía la selección viva del usuario. Este anti-patrón se cometió en al menos 3 archivos distintos en v1.7.x.

### 4.6 Cero cobertura de transición multi-ronda

No hay un solo test que cubra la transición R(N) → R(N+1). Vitest existe a nivel de funciones puras. El "happy path multi-ronda" lleva 4 versiones rompiéndose silenciosamente porque la única forma de detectarlo es jugar dos fines de semana completos.

### 4.7 `arrayUnion` sin lifecycle

`saveQualyResult` usa `arrayUnion` para `qualifyingRuns[]` sin nunca limpiarlo. Esto es válido dentro de una sesión, ilegal entre sesiones. La asunción "el array se limpia entre rondas" nunca se documentó ni se enforzó. El patrón ya existía antes de v1.7.x; nadie lo cuestionó hasta hoy.

---

## 5. Por qué llevamos tantos P1s

La causa raíz es proceso, no técnica. Tres factores compuestos:

1. **Asimetría entre velocidad de fix y velocidad de verificación.** Aplicar un parche toma minutos. Verificar que no rompió las otras 3 fases del weekend toma horas (requiere simular dos fines de semana o leer cuidadosamente toda la cadena). El primero se hace; el segundo se omite. La deuda se acumula en bugs futuros.

2. **Optimización local en cada fix.** Cada bug se trata como un incidente independiente. Nadie está leyendo los 7 postmortems anteriores ni preguntando "¿este es el mismo bug en otra cara?". Si esa pregunta se hubiera hecho en v1.7.1, habríamos arreglado el post-race CF en una tarde y evitado v1.7.2-hotfix, v1.7.3 y v1.7.3-hotfix.

3. **El usuario es la integration test suite.** No existe smoke test multi-ronda automatizado. Cada P1 se descubre en producción, en plena sesión activa, con presión de tiempo. Esa presión empeora la calidad del fix → más P1s.

---

## 6. Acciones correctivas

### Inmediatas (esta semana)

| # | Acción | Owner | Plazo |
|---|---|---|---|
| 1 | Limpiar `weekStatus.driverSetups` en `processPostRace` (CF). Esto borra ~80% de la deuda de gating del frontend. | Backend | Antes de R(N+1) |
| 2 | Eliminar todos los `isDriverStatusStale` proxies del frontend. Reemplazar por reads directos del campo correcto en cada subsistema (qualifying lee `qualifyingSessionId`, race lee `raceSessionId`, etc.). | Frontend | Mismo PR que #1 |
| 3 | Documentar en `weekend_pipeline.md` el lifecycle de `driverSetups`: cuándo nace, cuándo se resetea, qué campos sobreviven. | Docs | Mismo PR |

### Estructurales

| # | Acción | Por qué |
|---|---|---|
| 4 | `/deploy` no se ejecuta sin una pausa explícita para QA en localhost. El skill debe pedir confirmación textual del manager. | El último hotfix se shipeó a 10 minutos de qualy. |
| 5 | Cada fix que toque `driverSetups` debe walkear las 4 fases × 2 rutas (con/sin práctica) en el cuerpo del PR. Si no se hace, no se mergea. | El bug del piloto 2 hubiera salido en 30s de walking. |
| 6 | Adoptar regla "1 bug por commit" durante hotfix windows. Branch ballooning prohibido. | v1.7.3 mergeó 5 fixes en una sola review. |
| 7 | Crear un Vitest "multi-round transition" que cargue un team con `driverSetups` poblado de R(N), simule el post-race, y verifique que R(N+1) arranca limpio. | El bug de hoy hubiera fallado este test la primera vez. |

---

## 7. Lección

El subsistema `driverSetups` lleva 7 días de fixes consecutivos sin que nadie haya tocado la línea de código que lo arreglaría todo. El problema no es Svelte, no es Firestore, no es Cloud Functions. Es que el equipo (humano + IA) está optimizando latencia de respuesta a cada P1 individual en vez de latencia de resolución del root cause. Hasta que esa métrica cambie, los P1s del mismo subsistema seguirán apareciendo cada release.

> Un fix que mueve el bug a otro componente no es un fix. Es una externalización del trabajo al próximo desarrollador (o al próximo usuario en producción).
