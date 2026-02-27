# Listado de Errores — FTG Racing Manager

**Origen:** Análisis basado en `ANALISIS_PROYECTO.md` e `IMPLEMENTATION_PLAN_SIMULATION.md`  
**Fecha:** Febrero 2026

Cada error de producto puede estar relacionado con uno o más errores técnicos (campo **Relación**). Los IDs permiten trazabilidad entre producto y técnica.

---

## 1. Errores de producto

| ID | Descripción | Relación (errores técnicos) |
|----|-------------|-----------------------------|
| **P001** | El motor de simulación no está en tiempo real: la carrera no dura lo que dura una carrera real (~1 h según plan) ni avanza en tiempo real. | T001, T002, T003 |
| **P002** | La pantalla "Carrera en vivo" no muestra cronología vuelta a vuelta ni tiempos/posiciones/incidentes en vivo; solo un botón que ejecuta una simulación instantánea y muestra el ganador en un diálogo. | T002, T010 |
| **P003** | La hora del juego no avanza en tiempo real ni está sincronizada con Bogotá (UTC-5) en producción; el usuario no vive el ciclo real del fin de semana. | T001, T003 |
| **P004** | Límite de vueltas de práctica incoherente con el diseño: el plan especifica **6 sesiones por piloto**; la app permite **10 vueltas por piloto**. | T004 |
| **P005** | No existe pantalla de resultados post-carrera ni visualización clara de recompensas, puntos y actualización de tablas de campeonato (pilotos y constructores). | T005, T006 |
| **P006** | No existe flujo de "estrategia de carrera": no hay paso para enviar el setup para la carrera ni bloqueo después de la clasificación según el plan. | T007 |
| **P007** | El circuito usado en práctica/simulación puede no corresponder al circuito de la carrera actual del calendario (p. ej. circuito genérico en lugar del de la fecha). | T008, T009 |
| **P008** | La simulación de carrera no utiliza la parrilla de clasificación guardada ni el motor vuelta a vuelta; la experiencia "carrera en vivo" está desacoplada del flujo clasificación → parrilla → carrera. | T002, T010 |
| **P009** | Riesgo de producto: la simulación de clasificación y carrera se ejecuta en el cliente; un usuario podría manipular resultados o disparar simulaciones no válidas. | T011 |
| **P010** | El piloto puede dar feedback/confianza basado en un stat "consistency" que no existe en todos los pilotos (p. ej. pilotos seedeados solo tienen speed/cornering), generando comportamiento por defecto no documentado. | T012 |
| **P011** | El checklist del dashboard muestra "X/20 laps" como total de vueltas de práctica; no está alineado con "6 por piloto" del plan ni con el límite real de 10 por piloto en el Garage. | T004, T016 |

---

## 2. Errores técnicos

| ID | Descripción | Relación (errores de producto) |
|----|-------------|--------------------------------|
| **T001** | `TimeService.useMockTime` está en `true` por defecto; `nowBogota` devuelve una fecha fija (`2026-02-06T20:00:00`) cuando el mock está activo, por lo que el tiempo del juego no avanza. | P001, P003 |
| **T002** | `RaceLiveScreen` solo llama a `simulateNextRace(seasonId)` (simulación simplificada e instantánea) y no a `simulateRaceSession()`; no hay UI para mostrar vueltas, posiciones ni incidentes en tiempo real ni duración real de carrera. | P001, P002, P008 |
| **T003** | No hay integración con hora del servidor (p. ej. Cloud Function que devuelva timestamp) ni flujo de producción que use `timezone` con `America/Bogota` de forma fiable; el plan exige sincronización con Bogotá. | P001, P003 |
| **T004** | En `garage_screen.dart` el límite de vueltas de práctica por piloto está hardcodeado a **10**; el plan de implementación especifica **máximo 6 sesiones por piloto**. | P004, P011 |
| **T005** | No existe pantalla ni flujo dedicado de resultados post-carrera ("Last Race") ni widget que muestre detalle de puntos ganados y cambios en el campeonato. | P005 |
| **T006** | No se muestran en la app las tablas de clasificación de pilotos y constructores actualizadas tras la carrera. | P005 |
| **T007** | No hay UI ni modelo persistido para "race strategy" (enviar setup para la carrera) ni bloqueo explícito tras la clasificación; el plan indica que enviar setup de carrera bloquea la clasificación. | P006 |
| **T008** | En `RaceService.simulateNextRace`, al actualizar el calendario de la temporada tras completar la carrera, el `RaceEvent` se reconstruye **sin** el campo `circuitId` (solo se pasan `id`, `trackName`, `countryCode`, `date`, `isCompleted`), por lo que al persistir en Firestore se pierde el identificador del circuito. | P007 |
| **T009** | El `DatabaseSeeder` define circuitos con `circuitId` (`hermanos_rodriguez`, `termas`, `tocancipa`, `el_pinar`, `yahuarcocha`) que **no existen** en `CircuitService.getCircuitProfile()`; solo están definidos `interlagos`, `monza`, `monaco`, `silverstone`. Para la mayoría de carreras del calendario se usa el perfil genérico. | P007 |
| **T010** | `simulateRaceSession()` (simulación vuelta a vuelta con neumáticos, pit stops, adelantamientos) no está integrada en `RaceLiveScreen`; la parrilla guardada en `races/{raceId}` (por `saveQualifyingGrid`) no se utiliza para alimentar esta simulación en la UI. | P002, P008 |
| **T011** | `simulateNextRace` y `simulateQualifying` se ejecutan en el cliente y escriben directamente en Firestore; no hay Cloud Functions que centralicen o validen la simulación, lo que permite abuso o manipulación. | P009 |
| **T012** | En `Driver.fromMap` el valor por defecto de `stats` es `{'speed': 50, 'cornering': 50}`; no se incluye `consistency`. En `RaceService.simulatePracticeRun` se usa `driver.stats['consistency'] ?? 50`, por lo que los pilotos seedeados (solo con speed/cornering) usan 50 por defecto sin que esté documentado o unificado en el modelo. | P010 |
| **T013** | Reglas de Firestore son permisivas: una sola regla `match /{document=**} { allow read, write: if request.time < timestamp.date(2026, 3, 3); }` permite a cualquier cliente con referencia a la base leer y escribir todo; no hay reglas por colección ni por `auth.uid`/`managerId`. | — (seguridad) |
| **T014** | Duplicación de fuentes de verdad: el setup y las vueltas de práctica viven en `weekStatus` y también se hace referencia a `current_event/qualifying_setup` en el análisis; no hay una única fuente canónica, con riesgo de inconsistencias. | — (arquitectura) |
| **T015** | No hay inyección de dependencias; los servicios son singletons (factory + `_instance`), lo que dificulta tests unitarios y sustitución por mocks (p. ej. `TimeService` mock para QA). | — (arquitectura) |
| **T016** | En el dashboard, `PreparationChecklist` recibe `totalLaps: 20` como total de vueltas; el plan indica 6 por piloto (12 total para 2 pilotos) y el Garage usa 10 por piloto. El valor 20 no refleja ni el plan ni la validación real del Garage. | P011 |

---

## 3. Resumen de relaciones (producto → técnica)

- **P001** → T001, T002, T003  
- **P002** → T002, T010  
- **P003** → T001, T003  
- **P004** → T004  
- **P005** → T005, T006  
- **P006** → T007  
- **P007** → T008, T009  
- **P008** → T002, T010  
- **P009** → T011  
- **P010** → T012  
- **P011** → T004, T016  

Errores técnicos sin relación explícita a producto en esta lista: **T013** (seguridad), **T014** (datos), **T015** (arquitectura).

---

## 4. Referencias

- `ANALISIS_PROYECTO.md` — Análisis del código y estado del proyecto.
- `IMPLEMENTATION_PLAN_SIMULATION.md` — Plan del motor de simulación en tiempo real y ciclo del fin de semana.
