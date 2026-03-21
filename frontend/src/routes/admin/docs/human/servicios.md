# Arquitectura de Servicios y Lógica de Negocio (Senior)

## 1. Filosofía de Servicios
En este ecosistema, los servicios son **Stateless Logic Providers** encargados de la comunicación con Firebase y la ejecución de reglas de negocio puras. El estado se delega a los **Stores (Runes)**, asegurando que la lógica de persistencia y la de UI estén desacopladas.

---

## 2. Catálogo de Servicios Core

### A. TimeService (Orquestador Chronos)
Es el metrónomo del sistema. Determina el estado de la liga (`practice`, `qualifying`, `race`, etc.) basándose en la zona horaria de Bogotá (UTC-5).
*   **Responsabilidad**: Lock/Unlock de setups (Parc Fermé) y cálculo de cuentas regresivas.
*   **Lógica Crítica**: El estado de la semana se deriva de una matriz de tiempo fija. Las prácticas se bloquean (solo lectura) el Sábado a las 13:00 COT o tras el primer intento de Qualy. Qualy inicia el Sábado a las 14:00 y Carrera el Domingo a las 14:00.

### B. SponsorService (Gestor de Contratos)
Gestiona el sistema de negociación de patrocinios mediante una máquina de estados compleja.
*   **Negociación**: Utiliza un sistema de probabilidad basado en la **Personalidad del Sponsor** vs. **Táctica del Manager**.
*   **Sign-Off**: Realiza transacciones atómicas que impactan el `budget` del equipo e inyectan una `ActiveContract` en el documento del equipo.
*   **Bonos**: Implementa multiplicadores para roles específicos como `Business Admin` (+15%).

### C. PracticeService (Simulación de Campo)
Implementa el motor de física simplificado para las sesiones de práctica.
*   **Feedback**: Traduce la desviación del setup ideal en narrativa técnica (ej. "Understeer" vs "Oversteer"). La precisión del feedback escala con la habilidad de `Feedback` del piloto.
*   **Setup Hints**: Genera rangos visuales dinámicos. Un piloto con alta `Adaptability` proporciona rangos más estrechos y precisos.
*   **Gestión de Qualifying**: Persiste los `setupHints` en el `lastQualyResult` y permite el fallback de hints desde las sesiones de práctica. Incluye selector de agresividad (`Driving Aggression`) que impacta directamente en el tiempo de vuelta y riesgo de accidente.
*   **Clima y Neumáticos**: Implementa la lógica de penalización por neumáticos incorrectos. El compuesto `Wet` es obligatorio en sesiones de lluvia para evitar una penalización de +8.0s por vuelta. En seco, los neumáticos `Wet` sufren sobrecalentamiento y penalizan +3.0s.
*   **Bloqueo de Sesión**: Una vez iniciada la Qualy o pasado el límite de tiempo, la sesión de práctica entra en modo **"Read-Only"**, permitiendo ver telemetría pero bloqueando nuevas tandas.

### D. StaffService (Gestión de Personal)
Orquestador de recursos humanos y optimización de rendimiento físico.
*   **Fitness Training**: Gestiona la recuperación de fatiga post-carrera.
*   **Mercado de Pilotos**: Implementa la lógica de despido (con penalización del 10% del valor de mercado) y el listado en el mercado de transferencias.

### E. RaceService (Bridge de Simulación)
Actúa como puente entre el cliente y el SimEngine de Cloud Functions.
*   **Benchmarking**: Recupera resultados de otros competidores de la liga para comparativas en tiempo real.
*   **Triggers**: Expone métodos para forzar simulaciones de Qualy/Carrera (reservado para administradores).

### F. AcademyService (Gestor de Cantera)
Gestiona el ciclo de vida de los pilotos junior y el scouting inicial.
*   **Generación**: Implementa la lógica de escalado por nivel y el balance de género (1M, 1F) para candidatos.
*   **Persistencia**: Centraliza el guardado de candidatos y el conteo de plazas ocupadas.

### G. Backend Orchestration (Cloud Functions)
Lógica pesada se delega a las funciones de Firebase (Node.js) para garantizar imparcialidad y seguridad.

*   **Pipeline completo del fin de semana (4 fases):**

    | Fase | Función | Cuándo | Qué hace |
    |------|---------|--------|----------|
    | 1. Qualy | `scheduledQualifying` | Sáb 15:00 COT | Simula clasificación, escribe `qualyGrid` en el Race doc |
    | 2. Carrera | `scheduledRace` | Dom 14:00 COT | Simula carrera, actualiza `drivers/` y `teams/` con puntos, premios y stats |
    | 3. Economía | `postRaceProcessing` | ~1h tras carrera | Salarios, bonos de sponsors, eventos de academia, restablece `weekStatus` |
    | 4. Standings | `sync_universe.js` ⚠️ | **Manual** | Propaga `seasonPoints` hacia el documento `universe` cacheado |

*   **Dependencia crítica — Universe Sync:**
    La página de Standings (`/season/standings`) lee del documento **denormalizado** `universe/game_universe_v1`. Las Fases 1-3 actualizan los documentos individuales de `drivers/` y `teams/`, pero **el universo no se actualiza automáticamente**. Si los puntajes en la app no cambian tras la carrera, siempre ejecutar `node sync_universe.js` desde la carpeta `/functions`.

*   **`scheduledDailyFitnessRecovery`**: Cron diario (00:00 COT). Recupera +1.5 de fatiga a todos los pilotos activos.
*   **Transfer Resolver**: Cron por hora que cierra subastas de pilotos tras 24h de expiración.

---

## 3. Integración y Seguridad
*   **Transacciones**: Todas las operaciones que afectan el `budget` o el `rango de stats` de un piloto se realizan mediante `runTransaction` de Firestore para evitar colisiones de estado.
*   **Persistencia Optimista**: La UI se actualiza inmediatamente tras la escritura, mientras que los listeners en los Stores aseguran la consistencia final con el servidor.

---

## 4. Protocolo de Recuperación de Emergencia

> Si alguna simulación automática falla, ejecutar en orden desde `/functions`:

```bash
node reset_all.js              # 1. Limpia datos corruptos de R2/R3
node run_simulation.js qualy   # 2. Simula Qualy manualmente
node run_simulation.js race    # 3. Simula Carrera manualmente
node force_post_race.js        # 4. Fuerza procesamiento financiero
node sync_universe.js          # 5. Sincroniza Standings en la UI
```

> **Postmortem:** Ver [postmortem_r2.md](postmortem_r2.md) y [postmortem_r3.md](postmortem_r3.md) para análisis de incidentes de simulación.

---

## 5. Administración (AdminService)
Orquestador de herramientas de mantenimiento masivo.
*   **Recuperación**: El método `fixBrokenAcademies` detecta equipos con instalaciones activas pero sin configuración o candidatos, inyectando un batch inicial de 2 pilotos (1M, 1F) escalados por nivel.
*   **Protección**: Nunca sobrescribe datos de pilotos ya contratados (`selected`), asegurando que no haya pérdida de progreso.

