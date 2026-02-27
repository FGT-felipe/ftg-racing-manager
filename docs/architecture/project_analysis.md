# Análisis del Proyecto FTG Racing Manager

**Fecha:** Febrero 2026  
**Rol:** Desarrollador Senior Flutter/Dart  
**Objetivo:** Análisis del código para continuar el desarrollo del juego manager de automovilismo en tiempo real.

---

## 1. Visión general

**FTG Racing Manager** es un juego de gestión de automovilismo para navegador (Flutter Web), con soporte Android. Los jugadores actúan como **team principals**: dirigen un equipo, contratan y entrenan pilotos, firman sponsors, realizan prácticas semanales, configuran el setup para clasificación y carrera, y participan en un ciclo de fin de semana con clasificación y carrera simulada en tiempo real (sincronizado con Bogotá, UTC-5).

### Stack técnico
- **Frontend:** Flutter (SDK ^3.10.7), Material 3, Google Fonts
- **Backend / persistencia:** Firebase (Auth, Firestore)
- **Autenticación:** Firebase Auth + Google Sign-In
- **Cloud Functions:** Node.js (actualmente sin lógica de negocio; solo boilerplate)
- **Plataformas:** Web (principal), Android

### Estructura del repositorio
```
lib/
├── main.dart                 # App, AuthWrapper, ManagerProfileCheck, TeamCheck
├── firebase_options.dart
├── l10n/                     # Localización (inglés)
├── models/                   # core_models, simulation_models, user_models
├── screens/                  # auth, onboarding, home, race, office, account, etc.
├── services/                 # auth, time, race, circuit, team, finance, sponsor, etc.
├── theme/
├── utils/
└── widgets/
```

---

## 2. Arquitectura actual

### 2.1 Flujo de entrada (main.dart)
1. **AuthWrapper:** escucha `authStateChanges()`. Si no hay usuario → `LoginScreen`. Si hay usuario → **ManagerProfileCheck**.
2. **ManagerProfileCheck:** escucha el documento `managers/{uid}` en tiempo real. Si no existe perfil → `CreateManagerScreen`. Si existe → **TeamCheck**.
3. **TeamCheck:** escucha `teams` donde `managerId == uid`. Si no hay equipo → `TeamSelectionScreen`. Si hay equipo → **MainLayout(teamId)**.

El flujo está bien separado por responsabilidades y usa StreamBuilder para reacción en tiempo real. No hay inyección de dependencias; los servicios son singletons (factory + `_instance`).

### 2.2 Navegación principal (MainLayout)
- **Desktop (>900px):** `NavigationRail` + contenido en `IndexedStack`.
- **Móvil:** `BottomNavigationBar` + mismo `IndexedStack`.
- Pantallas: **Dashboard**, **Garage** (Engineering), **Office**, **Market** (Job Market), **Account**.

### 2.3 Modelos de datos

| Archivo | Contenido principal |
|--------|----------------------|
| **core_models.dart** | `League`, `RaceEvent`, `Season`, `Division`, `Transaction`, `NewsItem`, `SponsorOffer`, `ActiveContract`, `Team`, `Driver`; enums `SponsorTier`, `SponsorSlot`, `SponsorPersonality`. |
| **simulation_models.dart** | `CarSetup`, `CircuitProfile`, `PracticeRunResult`, `RaceEventLog`, `LapData`, `RaceSessionResult`. |
| **user_models.dart** | `ManagerRole` (enum con pros/cons), `ManagerProfile`. |

Los modelos tienen `toMap()` / `fromMap()` consistentes para Firestore. Falta documentación Dart en varios y no hay validación explícita de campos obligatorios en `fromMap`.

### 2.4 Servicios (singletons)

| Servicio | Responsabilidad |
|----------|-----------------|
| **TimeService** | Hora del juego (actualmente mock: 6 feb 2026 20:00 Bogotá), `RaceWeekStatus`, `isSetupLocked`, `getTimeUntilNextEvent()`, `formatDuration()`. |
| **RaceService** | `simulatePracticeRun()`, `simulateQualifying(seasonId)`, `simulateRaceSession()` (vuelta a vuelta con neumáticos/incidentes), `simulateNextRace(seasonId)` (lógica simplificada + batch Firestore: puntos, DNF, premios, calendario). |
| **CircuitService** | Datos estáticos de circuitos (Interlagos, Monza, Mónaco, Silverstone + genérico). `getCircuitProfile(id)`. |
| **TeamService** | `claimTeam(teamRef, userId)` con transacción. |
| **AuthService** | Stream del usuario actual. |
| **FinanceService**, **SponsorService**, **CarService** | Lógica de oficina, sponsors y coche (no revisados en detalle en este análisis). |

---

## 3. Lo que está implementado

### 3.1 Completado o muy avanzado
- **Auth:** Login (email + Google), creación de perfil de manager, selección de equipo.
- **Dashboard:** Header del equipo, hero de estado de la semana (`RaceStatusHero`), checklist (setup clasificación, estrategia, vueltas de práctica), tarjeta de finanzas, noticias (mock).
- **TimeService:** Estados `practice | qualifying | raceStrategy | race | postRace` y ventanas horarias (L–V práctica, Sáb 14:00 qualy, Dom 14:00–16:00 carrera, etc.). Mock de hora fija.
- **Garage (práctica):** Selector de piloto, sliders de setup (front/rear wing, suspension, gear ratio, tyre pressure), “Run practice lap” (máx. 10 por piloto), feedback del piloto y confianza, persistencia en `weekStatus` y subcolección `practice_results`, “Save & Send Setup” (bloqueo Parc Fermé con `TimeService.isSetupLocked`).
- **Office:** Balance, transacciones, acceso a Sponsorship.
- **RaceService:** Práctica (penalización por desviación del setup ideal, feedback, confianza), clasificación (simulación por equipo/piloto, grid ordenado), carrera simplificada (`simulateNextRace`: DNF por fiabilidad, puntos, premios, actualización de calendario).
- **Simulación vuelta a vuelta:** `simulateRaceSession()` con neumáticos, pit stops, adelantamientos, `LapData` y `RaceSessionResult` (aún no integrada en la UI de “carrera en vivo”).
- **Circuitos:** 4 circuitos con perfil (setup ideal, baseLapTime, dificultad, características).
- **Responsive:** Layout desktop (rail) vs móvil (bottom nav), `ResponsiveLayout`/shell.

### 3.2 Parcialmente implementado
- **QualifyingScreen:** Solo llama a `simulateQualifying(seasonId)` y muestra lista; no está enlazada al flujo del dashboard por estado (qualifying/raceStrategy) ni persiste la parrilla en un documento `races/{raceId}`.
- **RaceLiveScreen:** Botón “Watch race simulation” que llama a `simulateNextRace(seasonId)` y muestra un diálogo con el ganador; no usa `simulateRaceSession()` ni muestra cronología vuelta a vuelta ni tiempos en vivo.
- **Dashboard:** En estados distintos de `practice`, el botón de acción muestra un SnackBar “not implemented yet” en lugar de llevar a Qualifying o Race Live según el estado.
- **Circuito actual:** El circuito “actual” está hardcodeado (p. ej. Interlagos). No se obtiene del `Season`/`RaceEvent` en curso.

### 3.3 No implementado o solo definido
- **Hora real:** `TimeService.nowBogota` es una fecha fija; no hay integración con hora real (ni servidor ni paquete tipo `timezone`).
- **Firebase Functions:** Sin triggers para clasificación/carrera automática ni cron.
- **Colección `races/{raceId}`:** El plan menciona `status`, `grid`, `results`, `weather`; en el código no se crea ni actualiza esta estructura de forma integrada.
- **Estrategia de carrera (race strategy):** UI y modelo para “enviar setup para la carrera” y bloqueo después de clasificación.
- **Carrera en tiempo real:** Duración real (~1 h) y actualización progresiva de posiciones/tiempos/incidentes en la UI.
- **Post-carrera:** Pantalla de resultados, recompensas, actualización de tablas de campeonato (pilotos/constructores) mostradas en la app.
- **Reglas de Firestore:** Reglas permisivas con fecha de expiración (marzo 2026); no hay reglas por colección/rol.
- **Tests:** Solo `widget_test.dart` por defecto; no hay tests unitarios para TimeService, RaceService ni modelos.

---

## 4. Deuda técnica y riesgos

### 4.1 Arquitectura y estado
- **Sin inyección de dependencias:** Servicios accedidos por singleton; difícil de testear y de sustituir (p. ej. TimeService mock para QA).
- **Lógica de negocio en UI:** Parte de la lógica (p. ej. qué hacer según `RaceWeekStatus`) está en el dashboard y en pantallas concretas; convendría centralizarla en servicios o un “race week coordinator”.
- **Duplicación de fuentes de verdad:** Setup y vueltas de práctica en `weekStatus` y en `current_event/qualifying_setup`; hay que definir una fuente canónica para evitar inconsistencias.

### 4.2 Datos y Firestore
- **RaceEvent sin circuitId:** En `core_models.dart`, `RaceEvent` tiene `trackName`, `countryCode`, `date`, pero no `circuitId`; el `RaceService` y el Garage usan circuito fijo (“interlagos”).
- **SeasonId y raceId:** Qualifying y Race Live reciben `seasonId`; no está claro cómo se obtiene el “race actual” (índice en calendario vs documento en `races/`).
- **Índices:** `practice_results` usa `where('driverId')` + `orderBy('timestamp')`; asegurar índice compuesto en Firestore.

### 4.3 Seguridad
- **Reglas de Firestore:** Actualmente abiertas hasta una fecha; es crítico definir reglas por colección (lectura/escritura por `request.auth.uid` y `managerId`, validación de campos).
- **Simulación en cliente:** `simulateNextRace` y `simulateQualifying` se ejecutan desde el cliente y escriben en Firestore; un usuario podría abusar. La simulación de carrera/clasificación debería ejecutarse en Cloud Functions (o al menos validarse en el backend).

### 4.4 UX y consistencia
- **Límite de vueltas de práctica:** En el plan son 6 por piloto; en el Garage está 10. Unificar con el diseño.
- **Idioma:** Strings en inglés y español mezclados (plan en español, UI en inglés); revisar con l10n.
- **Driver stats:** El modelo `Driver` usa `stats` (speed, cornering, etc.); en `simulatePracticeRun` se usa `consistency` que puede no existir en todos los pilotos (se usa 50 por defecto).

---

## 5. Recomendaciones para continuar el desarrollo

### 5.1 Prioridad alta (motor y flujo de carrera)
1. **Unificar “carrera actual”:** Añadir `circuitId` (o al menos identificador) a `RaceEvent` y que CircuitService/RaceService reciban el circuito de la carrera en curso desde el calendario de la temporada.
2. **Documento `races/{raceId}`:** Crear/actualizar desde el cliente o (mejor) desde Cloud Functions: al iniciar fin de semana, crear `races/{raceId}` con `status: 'scheduled'`; tras clasificación, guardar `grid`; tras carrera, `results` y `status: 'completed'`.
3. **Conectar Dashboard con Qualifying y Race Live:** Según `TimeService.currentStatus`, que el botón del hero lleve a QualifyingScreen (qualifying/raceStrategy) o RaceLiveScreen (race/postRace), pasando `seasonId` y si es posible `raceId`.
4. **TimeService con hora real:** Usar hora del servidor (p. ej. llamada a Cloud Function que devuelva `Timestamp` o hora Bogotá) o paquete `timezone` con zona America/Bogota, y sustituir el mock por esa fuente para producción.

### 5.2 Prioridad media (simulación y backend)
5. **Mover simulación a Cloud Functions:** Implementar en `functions/` la ejecución de clasificación y de carrera (y opcionalmente “próxima carrera”) para que un solo cliente (admin o trigger programado) dispare la simulación; el cliente solo lee resultados. Así se evita manipulación y se centraliza la lógica.
6. **Integrar `simulateRaceSession` en la experiencia “carrera en vivo”:** Que RaceLiveScreen lea el `raceId` y, cuando la carrera esté en curso, muestre vueltas/posiciones/incidentes (desde Firestore actualizado por la función o por un worker).
7. **Race strategy (setup carrera):** Pantalla o paso para “enviar setup para la carrera” (bloqueando después) y persistirlo en `teams/{id}/current_event/race_setup` o similar, y que la simulación use ese setup.

### 5.3 Prioridad media-baja (calidad y producto)
8. **Reglas de Firestore:** Definir reglas por colección (`managers`, `teams`, `seasons`, `races`, subcolecciones) basadas en `auth.uid` y en `managerId` donde aplique.
9. **Tests:** Tests unitarios para `TimeService` (cambios de estado en bordes de hora/día), `RaceService.simulatePracticeRun` (con setup conocido y comprobar penalización/feedback), y `CarSetup`/modelos críticos.
10. **Límite de práctica:** Alinear límite de vueltas (6 en el plan vs 10 en código) y reflejarlo en UI y en validación al enviar setup.
11. **README y documentación:** Actualizar README con descripción del juego, entorno (Firebase, variables), y cómo ejecutar web/Android; opcionalmente un ARCHITECTURE.md con flujo de datos y decisiones.

### 5.4 Mejoras opcionales de arquitectura
- Introducir un **estado global** (Provider, Riverpod, Bloc) para “race week” (estado actual, carrera actual, permisos de UI) y que las pantallas dependan de ese estado en lugar de llamar a TimeService y Firestore por separado en cada pantalla.
- Extraer **casos de uso** (p. ej. “SubmitQualifyingSetup”, “RunQualifyingSession”) en clases o funciones que reciban repositorios/servicios inyectados, para facilitar tests y evolución.

---

## 6. Resumen ejecutivo

El proyecto tiene una **base sólida**: auth y onboarding, modelo de datos rico (equipos, pilotos, sponsors, temporadas, circuitos, setup), **TimeService** con estados de la semana bien definidos, **Garage** con práctica y feedback de pilotos muy jugable, y **RaceService** con simulación de práctica, clasificación y carrera (simplificada y vuelta a vuelta). La deuda principal está en: **integrar el flujo completo** (carrera actual → circuito → clasificación → parrilla → carrera en vivo → resultados), **mover la simulación crítica al backend** (Cloud Functions) y **endurecer seguridad y pruebas**. Con las prioridades indicadas arriba, el siguiente paso natural es unificar carrera actual + documento `races/` y conectar el dashboard con Qualifying y Race Live según el estado de la semana; en paralelo, preparar la migración de la simulación a Firebase Functions y el uso de hora real en TimeService.
