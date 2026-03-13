# Estructura de Base de Datos - Firestore Schema

Este documento describe la arquitectura de datos relacional y no-relacional implementada en Firebase Firestore para FTG Racing Manager.

---

## Colecciones Principales

### 1. `universe` (Configuración Global)
Contiene el estado maestro de la simulación.
*   **Doc: `game_universe_v1`**:
    *   `leagues`: Mapa de objetos de liga.
    *   `currentSeasonId`: ID de la temporada activa global.
    *   `lastGlobalUpdate`: Timestamp de la última sincronización.

### 2. `leagues`
Define la jerarquía de competititvidad.
*   **Campos**:
    *   `name`: Nombre de la liga (ej. FTG World Championship).
    *   `tier`: Nivel (1: Pro, 2: Academy).
    *   `teams`: Array de IDs de equipos inscritos.
    *   `currentSeasonId`: ID de la temporada en curso para esta liga.

### 3. `teams`
El eje central de la gestión del usuario.
*   **Campos**:
    *   `name`: Nombre del equipo.
    *   `managerId`: UID del usuario (Firebase Auth).
    *   `budget`: Balance financiero actual.
    *   `isBot`: Boolean para equipos controlados por IA.
    *   `carStats`: Mapa `{ "0": { aero: N, ... }, "1": { ... } }`.
    *   `facilities`: Mapa `{ office: { level: N }, ... }`.
    *   `weekStatus`: Estado de completitud de tareas semanales (setup, sponsors, etc).
*   **Sub-colecciones**:
    *   `news`: Historial de noticias y reportes de carrera.
    *   `notifications`: Alertas de UI.
    *   `transactions`: Ledger contable de ingresos y egresos.
    *   `academy/config`: Configuración de la Youth Academy.
        *   `candidates`: Candidatos disponibles para scouting.
        *   `selected`: Pilotos actualmente en formación.

### 4. `drivers`
Entidades de pilotos (Main Squad y Transfers).
*   **Campos**:
    *   `teamId`: Relación con la colección `teams`.
    *   `name`, `age`, `nationality`: Datos biográficos.
    *   `stats`: Mapa exhaustivo de habilidades (braking, cornering, focus, etc).
    *   `salary`: Coste anual.
    *   `isTransferListed`: Flag para el mercado.
    *   `currentHighestBid`: Puja actual en subasta.

### 5. `seasons`
Calendario y standings de campeonato.
*   **Campos**:
    *   `leagueId`: Relación con la liga.
    *   `calendar`: Array de objetos de carrera (`{ trackName, circuitId, isCompleted, weather }`).
    *   `standings`: Mapa de puntos acumulados por piloto y equipo.

### 6. `races`
Resultados históricos y logs de telemetría.
*   **ID**: `{seasonId}_{eventId}`.
*   **Campos**:
    *   `finalPositions`: Mapping `{ driverId: position }`.
    *   `qualyGrid`: Grid de partida generado.
    *   `fast_lap_driver`: ID del poseedor de la vuelta rápida.
*   **Sub-colección: `laps`**:
    *   Docs por número de vuelta (muestreo cada 5 vueltas) con `lapTimes` y `events`.

---

## 7. `managers`
Perfiles de usuario maestro.
*   **ID**: `uid`.
*   **Campos**:
    *   `name`: Nombre del manager.
    *   `role`: BackgroundId seleccionado (Ex-Engineer, etc).
    *   `teamId`: ID del equipo bajo su mando.
    *   `reputation`: Stat de progresión de carrera.
