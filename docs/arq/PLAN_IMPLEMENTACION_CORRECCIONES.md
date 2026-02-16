# Plan de implementación de correcciones — FTG Racing Manager

**Objetivo:** Corregir los errores listados en `listado_errores.md` de forma ordenada por módulo, con pasos detallados que cualquier modelo de lenguaje pueda seguir para programar.

**Referencias:** `listado_errores.md`, `ANALISIS_PROYECTO.md`, `IMPLEMENTATION_PLAN_SIMULATION.md`.

---

## Cómo usar este plan (para modelos de lenguaje)

1. **Orden de ejecución:** Respetar el orden de módulos cuando se indique "Dependencias". Las tareas dentro de un módulo pueden implementarse en secuencia.
2. **IDs:** Cada tarea referencia los IDs de `listado_errores.md` (P001–P011, T001–T016) que corrige.
3. **Archivos:** Se listan rutas relativas a la raíz del proyecto (`lib/`, `firestore.rules`, etc.).
4. **Criterios de aceptación:** Verificar al terminar cada tarea.
5. **Constantes compartidas:** Donde se defina una constante (p. ej. máximo de vueltas de práctica), usar un único lugar (preferiblemente en un archivo de constantes o en el modelo/servicio que sea la fuente de verdad).

---

## Constantes del proyecto (definir una sola vez)

Antes de implementar, definir en un único lugar las constantes que hoy están dispersas:

| Constante | Valor según plan | Uso |
|-----------|------------------|-----|
| `kMaxPracticeLapsPerDriver` | 6 | Garage: límite por piloto; Dashboard: total = 6 * número de pilotos del equipo |
| Zona horaria juego | `America/Bogota` (UTC-5) | TimeService |
| Duración ventana carrera (ejemplo) | Domingo 14:00–16:00 | Ya en TimeService |

**Acción:** Crear `lib/utils/app_constants.dart` (o similar) con:

```dart
/// Máximo de vueltas de práctica por piloto (plan: 6).
const int kMaxPracticeLapsPerDriver = 6;
```

Usar este archivo en `garage_screen.dart`, `dashboard_screen.dart` y `dashboard_widgets.dart` donde se use el límite o el total de vueltas.

---

## Módulo 1: Modelos de datos (Driver, RaceEvent, fuentes de verdad)

### 1.1 Driver — stat `consistency` en valor por defecto y seeder

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P010, T012 |
| **Archivos** | `lib/models/core_models.dart`, `lib/services/database_seeder.dart` |

**Pasos:**

1. En `lib/models/core_models.dart`, en la clase `Driver`:
   - En `fromMap`, cambiar el valor por defecto de `stats` para incluir `consistency`:
     - De: `map['stats'] ?? {'speed': 50, 'cornering': 50}`
     - A: `map['stats'] ?? {'speed': 50, 'cornering': 50, 'consistency': 50}`
   - Añadir documentación Dart al mapa `stats` indicando que las claves esperadas incluyen al menos `speed`, `cornering`, `consistency` (y otras que use la simulación).

2. En `lib/services/database_seeder.dart`, donde se crean pilotos con `stats: {'speed': speed, 'cornering': cornering}`:
   - Añadir `'consistency': 40 + random.nextInt(41)` (o similar, rango 40–80) para que todos los pilotos seedeados tengan el stat.

**Criterios de aceptación:**

- `Driver.fromMap({})` (o sin `stats`) produce un driver con `stats['consistency'] == 50`.
- Los pilotos creados por el seeder tienen la clave `consistency` en `stats`.
- `RaceService.simulatePracticeRun` puede seguir usando `driver.stats['consistency'] ?? 50` sin cambio de comportamiento para datos ya existentes; los nuevos datos serán coherentes.

---

### 1.2 RaceEvent — preservar `circuitId` al actualizar calendario (simulateNextRace)

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P007, T008 |
| **Archivos** | `lib/services/race_service.dart` |

**Pasos:**

1. En `lib/services/race_service.dart`, localizar el bloque donde se construye `updatedCalendar` tras completar la carrera (alrededor de `updatedCalendar[raceIndex] = RaceEvent(...)`).
2. En la construcción del `RaceEvent` que reemplaza a `currentRace`, incluir **todos** los campos del modelo:
   - `id`, `trackName`, `countryCode`, **`circuitId: currentRace.circuitId`**, `date`, `isCompleted: true`.
3. Asegurar que `toMap()` del `RaceEvent` ya incluye `circuitId` (verificar en `core_models.dart`); si no, añadirlo.

**Criterios de aceptación:**

- Después de ejecutar `simulateNextRace`, el documento de la temporada en Firestore tiene en `calendar[raceIndex]` el campo `circuitId` igual al de la carrera recién completada.
- No se pierde `circuitId` en carreras siguientes al leer la temporada.

---

### 1.3 (Opcional) Fuente única de verdad para setup y vueltas de práctica — T014

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | T014 (arquitectura) |
| **Archivos** | Documento de decisión; `lib/services/race_service.dart`, `lib/screens/race/garage_screen.dart`, dashboard si usa setup |

**Pasos (resumen):**

- Decidir y documentar: "La fuente canónica del setup de clasificación y de las vueltas de práctica es `teams/{teamId}.weekStatus` (campos `currentSetup`, `practiceLaps`, `qualifyingSetup`, etc.). No duplicar en `current_event/` salvo que se migre explícitamente."
- Revisar que Garage y Qualifying lean/escriban solo en esa fuente; eliminar o deprecar escrituras duplicadas.

Puede dejarse para una fase posterior si se priorizan correcciones de producto.

---

## Módulo 2: TimeService (tiempo real y mock)

### 2.1 Hora real Bogotá y control del mock — T001, T003, P001, P003

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | T001, T003, P001, P003 |
| **Archivos** | `lib/services/time_service.dart`, `lib/main.dart` (o donde se inicialice la app) |

**Pasos:**

1. En `lib/services/time_service.dart`:
   - Cambiar el valor por defecto de `useMockTime` a **`false`** para que en producción se use la hora real.
   - Asegurar que cuando `useMockTime == false`, `nowBogota` use siempre el paquete `timezone` con la zona `America/Bogota` (ya existe el try/catch con `tz.getLocation(_bogotaZone)` y `tz.TZDateTime.now(location)`). Comprobar que `timezone` está inicializado: en `main.dart` debe llamarse `tz.initializeTimeZone()` o usar `tz.initializeDatabase()` si aplica; si no está, añadir la inicialización al arranque de la app.
   - Documentar en comentario o en README: "En desarrollo, poner `TimeService.useMockTime = true` en main.dart para usar hora fija (p. ej. 2026-02-06 20:00). En producción, dejar `false`."

2. En `lib/main.dart` (o el punto de entrada):
   - Inicializar la base de datos de timezone si el paquete lo requiere (consultar documentación de `timezone` en pub.dev).
   - Opcional: leer una variable de entorno o flag de compilación (kDebugMode) para poner `TimeService.useMockTime = true` solo en debug, y `false` en release.

**Criterios de aceptación:**

- Con `useMockTime = false`, `nowBogota` devuelve la hora actual en Bogotá (UTC-5).
- Con `useMockTime = true`, `nowBogota` devuelve la fecha fija definida en código (para tests/QA).
- La app no lanza por falta de inicialización de timezone.

---

### 2.2 (Opcional) Hora del servidor para evitar manipulación de reloj cliente — T003

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | T003 (refuerzo) |
| **Archivos** | `functions/` (Cloud Function), `lib/services/time_service.dart` |

**Pasos (resumen):**

- Crear una Cloud Function (p. ej. `getServerTime`) que devuelva `Timestamp.now()` o la hora del servidor en ISO.
- En el cliente, opcionalmente llamar a esta función al iniciar o periódicamente y usar ese valor como referencia para "hora del juego" en lugar de solo `DateTime.now()` del dispositivo (evita que el usuario adelante el reloj).
- Documentar que la fuente canónica en producción puede ser el servidor; el plan exige sincronización con Bogotá, por lo que el servidor debe devolver hora UTC y el cliente convertir a America/Bogota, o el servidor devolver ya hora Bogotá.

Puede implementarse en una fase posterior.

---

## Módulo 3: CircuitService y DatabaseSeeder (circuitos alineados)

### 3.1 Circuitos del calendario existentes en CircuitService — P007, T009

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P007, T009 |
| **Archivos** | `lib/services/circuit_service.dart`, `lib/services/database_seeder.dart` |

**Pasos:**

1. En `lib/services/circuit_service.dart`:
   - Añadir perfiles `CircuitProfile` para cada `circuitId` que usa el seeder: `hermanos_rodriguez`, `termas`, `tocancipa`, `el_pinar`, `yahuarcocha`.
   - Para cada uno, definir al menos: `id`, `name`, `baseLapTime`, `idealSetup` (CarSetup con los 5 valores), `difficulty`, `overtakingDifficulty`, `characteristics` (mapa). Pueden usarse valores razonables inspirados en los circuitos existentes (interlagos, monza, monaco, silverstone) según el tipo de pista (más rectas = menos downforce, etc.).

2. Alternativa si se prefiere no duplicar datos:
   - En `database_seeder.dart`, cambiar los `circuitId` del calendario para que solo usen IDs que ya existen en CircuitService: p. ej. `interlagos`, `monza`, `monaco`, `silverstone`, y repetir o usar `generic` para el resto. Así no se añaden perfiles nuevos pero el calendario es coherente con CircuitService.

3. Elegir una de las dos estrategias y aplicarla de forma consistente.

**Criterios de aceptación:**

- Para cada carrera del calendario seedeado, `CircuitService().getCircuitProfile(event.circuitId)` devuelve un perfil específico (no genérico) si se optó por añadir perfiles; o el calendario solo usa IDs existentes si se optó por alinear el seeder.
- No hay referencias a circuitIds inexistentes en CircuitService en el flujo normal (práctica, clasificación, carrera).

---

## Módulo 4: Garage — límite de vueltas de práctica (6 por piloto)

### 4.1 Constante y validación en Garage — P004, T004, P011, T016

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P004, T004, P011, T016 |
| **Archivos** | `lib/utils/app_constants.dart` (crear si no existe), `lib/screens/race/garage_screen.dart` |

**Pasos:**

1. Crear o actualizar `lib/utils/app_constants.dart` con:
   - `const int kMaxPracticeLapsPerDriver = 6;`

2. En `lib/screens/race/garage_screen.dart`:
   - Importar la constante (p. ej. `import '../../utils/app_constants.dart';`).
   - Sustituir todas las apariciones del número **10** que representen el máximo de vueltas por piloto por `kMaxPracticeLapsPerDriver` (búsqueda: "10" en contexto de laps, practice, "Max 10 laps", "10 laps", etc.).
   - Ajustar mensajes de UI: "Driver finished practice session (Max 10 laps)" → "Max 6 laps" (o usar la constante en el texto si se formatea).
   - Donde se valida `if (currentLaps >= 10)` usar `>= kMaxPracticeLapsPerDriver`.
   - Donde se muestra "X/10 laps" usar "$laps/${kMaxPracticeLapsPerDriver} laps" o equivalente.

**Criterios de aceptación:**

- Un piloto no puede hacer más de 6 vueltas de práctica en una semana.
- La UI muestra "6" como máximo por piloto en el Garage.
- La constante está en un solo archivo para facilitar cambios futuros.

---

## Módulo 5: Dashboard — checklist de vueltas (total correcto)

### 5.1 PreparationChecklist con total alineado al plan — P011, T016

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P011, T016 |
| **Archivos** | `lib/screens/home/dashboard_screen.dart`, `lib/utils/app_constants.dart` |

**Pasos:**

1. En `lib/screens/home/dashboard_screen.dart`:
   - Importar `app_constants.dart` y usar `kMaxPracticeLapsPerDriver`.
   - Calcular el total máximo de vueltas de práctica como: **número de pilotos del equipo × kMaxPracticeLapsPerDriver**. El número de pilotos puede obtenerse del equipo (p. ej. si hay una lista de drivers en el equipo) o de una constante si siempre son 2 (p. ej. `const int kDefaultDriversPerTeam = 2`). Si el equipo no expone la lista de pilotos en el snapshot actual, usar `kMaxPracticeLapsPerDriver * 2` como total mientras no se tenga dinámico.
   - Donde se pasa `totalLaps: 20` a `PreparationChecklist`, sustituir por el valor calculado (p. ej. `totalLaps: kMaxPracticeLapsPerDriver * 2` o según número de pilotos).

**Criterios de aceptación:**

- El checklist muestra "X / 12" (o el total que corresponda: 6×número de pilotos), no "X / 20".
- El valor está alineado con el límite del Garage (6 por piloto).

---

## Módulo 6: RaceService — integración de simulateRaceSession y parrilla (RaceLiveScreen)

Este módulo corrige la experiencia "carrera en vivo": usar la parrilla guardada y el motor vuelta a vuelta, y opcionalmente duración en tiempo real.

### 6.1 RaceLiveScreen: usar parrilla y simulateRaceSession — P002, P008, T002, T010

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P002, P008, T002, T010 |
| **Archivos** | `lib/screens/race/race_live_screen.dart`, `lib/services/race_service.dart`, `lib/services/season_service.dart`, `lib/services/circuit_service.dart`, modelos en `lib/models/` |

**Pasos:**

1. **Obtener carrera actual y documento de carrera:**
   - En `RaceLiveScreen`, con `seasonId` obtener la temporada activa (SeasonService) y la carrera actual (getCurrentRace).
   - Obtener `raceId` con `SeasonService().raceDocumentId(seasonId, currentRace.event)` o `getOrCreateRaceDocument`.
   - Cargar el documento `races/{raceId}` (SeasonService.getRaceDocument) para leer `grid` o `qualifyingResults`, y `status`.

2. **Cargar datos para simulateRaceSession:**
   - Si `status` no es `qualifying` o no hay parrilla, mostrar mensaje tipo "Run qualifying first" o deshabilitar "Start race" hasta que exista parrilla.
   - Obtener circuito: `CircuitService().getCircuitProfile(currentRace.event.circuitId)`.
   - Construir `grid`: lista de mapas con al menos `driverId`, y si hace falta `teamId`, `lapTime`, etc., a partir de `qualifyingResults` del documento de carrera.
   - Cargar todos los equipos y pilotos involucrados (por driverIds del grid): construir `teamsMap`, `driversMap`, `setupsMap` (por piloto; si no hay setup guardado, usar CarSetup por defecto o el de weekStatus del equipo).

3. **Llamar a simulateRaceSession:**
   - Invocar `RaceService().simulateRaceSession(raceId: raceId, circuit: circuit, grid: grid, teamsMap: teamsMap, driversMap: driversMap, setupsMap: setupsMap)`.
   - La firma actual de `simulateRaceSession` debe coincidir; si espera tipos distintos (p. ej. grid como lista de objetos con team/setup), adaptar la construcción de `grid` o añadir un método auxiliar en RaceService que construya los mapas a partir de `raceId` (leyendo Firestore).

4. **UI de carrera en vivo:**
   - Mostrar el resultado de la simulación (RaceSessionResult): lista de vueltas (`laps`), `finalPositions`, `totalTimes`, `dnfs`.
   - En lugar de un solo botón "WATCH RACE SIMULATION" que hace todo de golpe, ofrecer al menos:
     - Opción A: "Run full race simulation" que ejecuta `simulateRaceSession` y luego muestra una pantalla o diálogo con: tabla de posiciones finales, lista de vueltas (lap by lap) con posiciones y eventos (pit, overtake), y al final persistir resultados con `SeasonService().saveRaceResults` y actualizar calendario/puntos (la lógica de puntos y calendario hoy está en `simulateNextRace`; ver paso 5).
   - Opción B (mejor UX): simular vuelta a vuelta con un delay (Timer o Future.delayed) y actualizar la UI en cada vuelta (posición, tiempos, incidentes), de forma que el usuario vea la carrera "en vivo" aunque sea acelerada (p. ej. 1 vuelta cada 2 segundos). Esto requiere que `simulateRaceSession` pueda exponer laps de forma incremental o que se reimplemente un bucle en el cliente que simule lap a lap y actualice Firestore/UI.

5. **Persistir resultados y actualizar temporada:**
   - Tras obtener `RaceSessionResult`, llamar a `SeasonService().saveRaceResults(raceId, result.finalPositions, extraResults)`.
   - Actualizar el calendario de la temporada (marcar la carrera como completada) y aplicar puntos/premios a pilotos y equipos. Esta lógica está hoy en `simulateNextRace`; puede extraerse a un método `applyRaceResults(seasonId, raceId, RaceSessionResult)` que actualice puntos, budget y calendario, y llamarlo desde RaceLiveScreen después de `simulateRaceSession`, para no ejecutar dos veces la simulación (una en Session y otra en NextRace). Alternativa: que `simulateRaceSession` solo compute resultados y que un único método "commitRaceResults" persista en Firestore (grid ya está; results, calendar, points, budget).

**Criterios de aceptación:**

- RaceLiveScreen usa la parrilla guardada en `races/{raceId}` (tras clasificación).
- Se llama a `simulateRaceSession` con circuito, parrilla, equipos, pilotos y setups correctos.
- El usuario ve al menos: posiciones finales y/o cronología de vueltas/incidentes.
- Los resultados se persisten en `races/{raceId}` y en calendario/puntos/budget (sin duplicar lógica con simulateNextRace o integrando ambas).

---

### 6.2 (Opcional) Carrera con duración en tiempo real (~1 h) — P001, T002

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P001, T002 (parcial) |
| **Archivos** | `lib/screens/race/race_live_screen.dart`, `lib/services/race_service.dart` |

**Pasos (resumen):**

- Definir duración real de la carrera por circuito (p. ej. 60 minutos) en CircuitService o constantes.
- En lugar de ejecutar las 50 vueltas de golpe, repartir las vueltas en el tiempo real: p. ej. 50 laps en 60 minutos → 1 lap cada 1,2 minutos. Usar un Timer que cada X segundos "avance" una vuelta: ejecutar solo la lógica de esa vuelta (o precalcular todas las vueltas y mostrar progresivamente cada lap en su timestamp). Actualizar Firestore con el estado de la carrera (opcional) para que otros clientes vean en vivo.
- La UI debe mostrar countdown o "Lap X/50" y actualizar posiciones/tiempos según ese ritmo.

Puede implementarse en una fase posterior una vez 6.1 esté estable.

---

## Módulo 7: Estrategia de carrera (race strategy) — setup para la carrera

### 7.1 UI y persistencia de race strategy — P006, T007

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P006, T007 |
| **Archivos** | Nuevos o existentes: pantalla o sección "Race Strategy", `lib/screens/race/` (p. ej. `race_strategy_screen.dart`), dashboard, `lib/services/time_service.dart`, Firestore `teams/{id}` |

**Pasos:**

1. **Modelo y persistencia:**
   - Definir dónde se guarda el setup de carrera: p. ej. `teams/{teamId}.weekStatus.raceSetup` (Map con los mismos campos que CarSetup) y opcionalmente `raceStrategySubmittedAt` (timestamp). Si ya existe `qualifyingSetup`, añadir `raceSetup` de forma análoga.
   - En TimeService ya existe `isSetupLocked`; el plan indica que en RaceStrategy se puede "enviar setup para la carrera" pero eso bloquea la clasificación. Aclarar: normalmente clasificación ya pasó; el bloqueo es "no cambiar más el setup de carrera una vez enviado". Añadir si hace falta una bandera `isRaceSetupLocked` (true después de enviar race setup) o reutilizar lógica existente.

2. **UI:**
   - Crear una pantalla o paso "Race Strategy" accesible cuando `currentStatus == RaceWeekStatus.raceStrategy` (y opcionalmente en qualifying si el plan permite enviar setup de carrera antes). La pantalla debe mostrar sliders de setup (reutilizar los del Garage si es posible) y un botón "Submit race setup" que guarde en `weekStatus.raceSetup` y marque como enviado.
   - En el Dashboard, cuando el estado sea `raceStrategy`, el botón del hero puede llevar a esta pantalla en lugar de solo a Qualifying (o además de Qualifying, según diseño: si clasificación ya se hizo, el botón principal en raceStrategy sería "Set race strategy").

3. **Uso en simulación:**
   - En RaceService, al simular la carrera (simulateRaceSession o simulateNextRace), para el equipo del jugador usar `team.weekStatus['raceSetup']` si existe, sino `currentSetup` o `qualifyingSetup`, para construir el CarSetup del piloto.

**Criterios de aceptación:**

- El usuario puede enviar un "race setup" durante la ventana Race Strategy.
- El setup de carrera se persiste en el equipo y se usa en la simulación de la carrera.
- Una vez enviado, la UI puede mostrar "Race setup locked" y no permitir edición (opcional).

---

## Módulo 8: Post-carrera — resultados y tablas de campeonato

### 8.1 Pantalla de resultados de la última carrera — P005, T005

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P005, T005 |
| **Archivos** | Nueva pantalla `lib/screens/race/race_results_screen.dart` o similar, navegación desde Dashboard/main_layout, `lib/screens/home/dashboard_screen.dart` |

**Pasos:**

1. Crear pantalla "Race results" o "Last race" que:
   - Reciba `seasonId` y opcionalmente `raceId` (o el índice de la última carrera completada).
   - Cargue el documento `races/{raceId}` con `status == completed` y muestre: podio, posiciones finales, puntos ganados por el equipo del usuario, DNFs si los hay.
   - Muestre recompensas (dinero ganado, puntos sumados) de forma clara.

2. Navegación:
   - Cuando `currentStatus == RaceWeekStatus.postRace`, el botón principal del Dashboard (o un card "View race results") debe llevar a esta pantalla.
   - Pasar `seasonId` y el `raceId` de la última carrera (p. ej. la última con status completed del calendario de la temporada).

**Criterios de aceptación:**

- En post-race el usuario puede abrir una pantalla dedicada con resultados de la carrera recién terminada y recompensas.

---

### 8.2 Tablas de clasificación (pilotos y constructores) — P005, T006

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P005, T006 |
| **Archivos** | `lib/screens/standings_screen.dart` (si existe) o nueva pantalla, integración en Dashboard o pestaña "Standings" |

**Pasos:**

1. Si existe `standings_screen.dart`, revisar que muestre:
   - Tabla de pilotos: todos los pilotos de la liga/temporada ordenados por puntos (lectura desde `teams` + subcolección `drivers`, o colección agregada si existe).
   - Tabla de constructores: equipos ordenados por suma de puntos de sus pilotos (o por `teams.points` si se actualiza).

2. Si no existe, crear una pantalla o sección que:
   - Lea equipos de la temporada/liga y sus pilotos (y puntos).
   - Ordene y muestre dos listas: pilotos por puntos, equipos por puntos.
   - Sea accesible desde el Dashboard (enlace "Standings") o desde la pantalla de resultados de carrera.

3. Asegurar que tras cada carrera los puntos se actualicen en Firestore (ya lo hace `simulateNextRace` o el método que aplique resultados de `simulateRaceSession`), de modo que al abrir Standings se vean los datos actualizados.

**Criterios de aceptación:**

- El usuario puede ver la clasificación de pilotos y de constructores actualizada tras la carrera.

---

## Módulo 9: Reglas de Firestore (seguridad)

### 9.1 Reglas por colección y auth — T013

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | T013 |
| **Archivos** | `firestore.rules` |

**Pasos:**

1. Reemplazar la regla única permisiva por reglas específicas, por ejemplo:
   - `managers`: solo el usuario autenticado puede leer/escribir su documento `managers/{uid}` donde `uid == request.auth.uid`.
   - `teams`: lectura para usuarios autenticados; escritura solo si el equipo tiene `managerId == request.auth.uid` o si es creación con `managerId == request.auth.uid`.
   - `seasons`, `leagues`, `divisions`: lectura para autenticados; escritura restringida (p. ej. solo admin o solo desde Cloud Functions; si las funciones se ejecutan con admin SDK, las escrituras desde el cliente pueden limitarse a solo lectura para usuarios normales).
   - `races`: lectura para autenticados; escritura preferiblemente solo desde Cloud Functions (deny write from client) o con validación estricta.
   - Subcolecciones `teams/{id}/drivers`: mismas reglas que el equipo padre.
   - Ajustar según modelo de datos real (nombres de campos: `managerId`, etc.).

2. Documentar en el proyecto que las simulaciones que escriben en `seasons`, `races`, `teams` (puntos, calendario) deberían moverse a Cloud Functions (T011) para no depender de reglas de escritura en cliente.

**Criterios de aceptación:**

- Las reglas limitan lectura/escritura por colección y por `request.auth.uid` / `managerId` donde aplique.
- No existe una regla `match /{document=**} { allow read, write }` sin condición de tiempo ni de auth.

---

## Módulo 10: Backend (Cloud Functions) — simulación en servidor

### 10.1 Mover simulación a Cloud Functions — P009, T011

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | P009, T011 |
| **Archivos** | `functions/` (Node.js o Dart), cliente Flutter (llamadas a callable functions) |

**Pasos (resumen):**

- Crear Cloud Functions (callable o HTTP) que reciban `seasonId` y opcionalmente `raceId` y ejecuten la lógica de:
  - `simulateQualifying`: leer temporada, equipos, pilotos, circuitos; calcular parrilla; escribir en `races/{raceId}` (grid, status). El cliente solo invoca la función y luego lee el documento de la carrera.
  - `simulateRace` o "commitRaceResults": leer parrilla de `races/{raceId}`, ejecutar lógica equivalente a `simulateRaceSession` + aplicación de puntos y actualización de calendario/budget; escribir resultados en Firestore. El cliente solo invoca y luego lee resultados.
- En el cliente Flutter, sustituir llamadas directas a `RaceService().simulateQualifying(seasonId)` y a la ejecución de la carrera por llamadas a `FirebaseFunctions.instance.httpsCallable('simulateQualifying')` (y similar), pasando los parámetros necesarios.
- Mantener la lógica de simulación (algoritmos) en un solo lugar: o bien en el backend (reimplementar en Node/TypeScript) o exponer el código Dart en Cloud Functions for Firebase si se usa Dart en functions.

**Criterios de aceptación:**

- Un usuario no puede ejecutar simulación de clasificación o carrera directamente desde el cliente de forma que escriba en Firestore; solo la Cloud Function escribe.
- El cliente solo puede invocar la función (con control de quién puede invocar, p. ej. solo usuarios autenticados o solo un rol admin).

Este módulo es de mayor alcance y puede planificarse como proyecto aparte (reimplementar RaceService en Node o configurar Dart Cloud Functions).

---

## Módulo 11: (Opcional) Arquitectura — inyección de dependencias y tests

### 11.1 Inyección de dependencias — T015

| Campo | Detalle |
|-------|---------|
| **Errores que corrige** | T015 |
| **Archivos** | Toda la capa de servicios y pantallas que los usan |

**Pasos (resumen):**

- Introducir un contenedor de dependencias (Provider, Riverpod, get_it, etc.) y registrar interfaces de TimeService, RaceService, etc., con implementaciones concretas.
- En tests y en QA, registrar implementaciones mock (p. ej. TimeService que devuelve fechas fijas). Las pantallas y servicios reciben el servicio por constructor o por contexto en lugar de usar el singleton directo.
- Refactor gradual: empezar por TimeService y RaceService, luego el resto.

### 11.2 Tests unitarios

- Añadir tests para: TimeService (cambios de estado en bordes de hora/día), RaceService.simulatePracticeRun (setup conocido, comprobar penalización y feedback), Driver.fromMap (stats con/sin consistency), CarSetup.
- Ubicación sugerida: `test/unit/time_service_test.dart`, `test/unit/race_service_test.dart`, etc.

---

## Orden recomendado de implementación

| Fase | Módulos | Motivo |
|------|---------|--------|
| 1 | Constantes + Módulo 1 (modelos) + Módulo 3 (circuitos) | Base de datos y modelos coherentes |
| 2 | Módulo 2 (TimeService) | Hora real necesaria para flujo completo |
| 3 | Módulo 4 (Garage) + Módulo 5 (Dashboard) | Límite 6 y checklist sin dependencias complejas |
| 4 | Módulo 6 (RaceLiveScreen + simulateRaceSession) + 1.2 (circuitId en RaceEvent) | Carrera en vivo y no perder circuitId |
| 5 | Módulo 7 (Race strategy) | Mejora flujo fin de semana |
| 6 | Módulo 8 (Post-carrera, resultados, standings) | Cierra ciclo de carrera |
| 7 | Módulo 9 (Firestore rules) | Seguridad |
| 8 | Módulo 10 (Cloud Functions) | Seguridad y consistencia backend |
| 9 | Módulo 11 (DI, tests) | Calidad y mantenibilidad |

---

## Resumen de archivos clave por módulo

| Módulo | Archivos principales |
|--------|----------------------|
| Constantes | `lib/utils/app_constants.dart` |
| Modelos | `lib/models/core_models.dart`, `lib/services/database_seeder.dart` |
| TimeService | `lib/services/time_service.dart`, `lib/main.dart` |
| CircuitService/Seeder | `lib/services/circuit_service.dart`, `lib/services/database_seeder.dart` |
| Garage | `lib/screens/race/garage_screen.dart` |
| Dashboard | `lib/screens/home/dashboard_screen.dart`, `lib/screens/home/dashboard_widgets.dart` |
| RaceService | `lib/services/race_service.dart` |
| Race Live | `lib/screens/race/race_live_screen.dart`, `lib/services/season_service.dart` |
| Race Strategy | Nueva pantalla, `lib/screens/home/dashboard_screen.dart` |
| Post-carrera | Nueva pantalla resultados, `lib/screens/standings_screen.dart` |
| Firestore | `firestore.rules` |
| Backend | `functions/` |

Este plan puede usarse por un modelo de lenguaje para generar commits incrementales por tarea o por módulo, referenciando siempre los IDs de `listado_errores.md` en mensajes de commit o en PRs.
