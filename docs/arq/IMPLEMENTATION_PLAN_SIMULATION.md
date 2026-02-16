# Plan de Implementación: Motor de Simulación en Tiempo Real

Este documento detalla la estrategia para transformar el sistema de carreras de FTG Racing Manager de una simulación instantánea a una experiencia de fin de semana en tiempo real.

## 1. Visión General

El objetivo es crear un ciclo de juego inmersivo donde el jugador participa activamente durante la semana de carrera. El tiempo real (sincronizado con Bogotá, UTC-5) dictará las fases del evento.

### Ciclo Semanal
*   **Lunes - Viernes:** Desarrollo del coche, gestión de patrocinadores, finanzas, prácticas, entrenamientos de pilotos, ojeos de personal y pilotos. Se puede enviar el setup para la clásificación pero eso bloquea las prácticas. Máximo 6 sesiones de práctica por piloto.
*   **Sábado (mañana/tarde):** Sesión de Clasificación, 3 intentos por piloto con modificaciones entre intentos. Se puede enviar el setup para la carrera pero eso bloquea la clasificación.
*   **Sábado (noche) - Domingo (mañana):** Estrategia de carrera final. Se puede enviar el setup para la carrera pero eso bloquea la clasificación.
*   **Domingo (tarde):** La Carrera (Evento principal). Se bloquean todas las configuraciones del juego: finanzas, compras, coches, pilotos, etc. Se habilita un botón para ver la carrera en vivo. Que muestre los tiempos de vuelta, posiciones, incidentes, etc. La carrera debería durar en tiempo real lo que dura una carrera real, según el circuito. (Ejemplo: 1 hora).
*   **Domingo (noche):** Post-carrera y recompensas. Se habilita un botón para ver los resultados de la carrera y se otorgan las recompensas correspondientes en dinero, puntos, se actualizan las finanzas del equipo con los gastos + ingresos, tabla de clasificación de pilotos, tabla de clasificación de constructores. 

## 2. Arquitectura del Sistema

### A. TimeService (Gestor Temporal)
*   **Responsabilidad:** Proveer la "hora del juego" y el "estado actual".
*   **Zona Horaria:** Bogotá (UTC-5).
*   **Estados (Enum `RaceWeekStatus`):**
    *   `Practice`: Lunes 00:00 - Sábado 13:59.
    *   `Qualifying`: Sábado 14:00 - Sábado 15:00. (Setup bloqueado al finalizar).
    *   `RaceStrategy`: Sábado 15:01 - Domingo 13:59. (Permite ajustes estratégicos pero no de piezas).
    *   `Race`: Domingo 14:00 - Domingo 16:00. (Simulación activa).
    *   `PostRace`: Domingo 16:01 - Domingo 23:59.

### B. RaceService (Motor de Resultados)
*   Evolucionará de un script único a un servicio con métodos específicos por fase.
*   Mantendrá el estado de la sesión actual en Firestore (tiempos de vuelta, posiciones, incidentes).

### C. Sistema de Setup (Nueva Lógica)
*   **Concepto:** Cada circuito tiene un "Setup Ideal" oculto (ej. Downforce: 80, Suspension: 40).
*   **Acción del Jugador:** Ajustar sliders de `Front Wing`, `Rear Wing`, `Suspension Stiffness`, `Gear Ratio`.
*   **Feedback:** Durante la práctica, el piloto da feedback ("Sobreviraje", "Lento en rectas") basado en qué tan lejos está el setup del ideal.
*   **Confianza:** Un valor (0-100%) que multiplica el rendimiento del piloto en Clasificación y Carrera.

## 3. Plan de Desarrollo por Fases

### Fase 1: Investigación y Diseño (Completado)
*   Análisis de código actual (`TimeService`, `RaceService`).
*   Definición de estados y lógica.

### Fase 2: Lógica de Tiempo y Estados (En Progreso)
*   **Tarea:** Refinar `TimeService`.
*   **Entregable:** `TimeService` robusto que emite cambios de estado y maneja correctamente la zona horaria.
*   **Tarea:** Implementar `Qualifying Lock`.
*   **Entregable:** Propiedad `isSetupLocked` en el servicio que previene cambios en la UI.

### Fase 3: Motor de Simulación (Core)
*   **Tarea:** Lógica de Práctica.
    *   Algoritmo que toma el setup del jugador y genera tiempos de vuelta + feedback de texto.
*   **Tarea:** Lógica de Clasificación.
    *   Simulación de "vuelta rápida" única (Shootout) el sábado.
    *   Guarda la parrilla de salida (`startingGrid`) en la base de datos de la carrera.
*   **Tarea:** Lógica de Carrera.
    *   Simulación vuelta a vuelta (o por segmentos de 10 vueltas).
    *   Cálculo de incidentes (adelantamientos, choques).
    *   Consumo de neumáticos/combustible (versión simplificada).

### Fase 4: Interfaz de Usuario (Dashboard)
*   **Dashboard Dinámico:** El widget central cambia según el estado (`RaceWeekStatus`).
    *   *Práctica:* Botón "Ir al Taller/Pista".
    *   *Clasificación:* Countdown o Botón "Realizar vuelta".
    *   *Carrera:* Botón "Ver Carrera" o "Resultados en Vivo".
*   **Widgets:**
    *   `UpcomingCircuitCard`: Muestra info de la pista (Nombre, Curvas, Longitud).

### Fase 5: Sección "Last Race" y Resultados
*   Historial de carreras previas.
*   Detalle de puntos ganados y cambios en el campeonato.

### Fase 6: Verificación y QA
*   Tests unitarios para `TimeService` (cambios de hora borde).
*   Simulación acelerada de un fin de semana completo.
*   Validación de bloqueos de UI.

## 4. Estructura de Datos (Propuesta Firestore)

*   `races/{raceId}`
    *   `status`: 'scheduled', 'qualifying', 'completed'
    *   `grid`: Map<DriverId, Position>
    *   `results`: List<RaceResult>
    *   `weather`: 'dry', 'rain'
*   `teams/{teamId}/setup`
    *   `currentSetup`: Map<String, int>
    *   `confidence`: double (0.0 - 1.0)

Este plan servirá como hoja de ruta para las siguientes iteraciones.
