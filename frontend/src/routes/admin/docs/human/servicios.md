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

### F. Backend Orchestration (Cloud Functions)
La lógica pesada se delega a las funciones de Firebase (Node.js) para garantizar imparcialidad y seguridad.
*   **Scheduled Jobs**: 
    *   `scheduledQualifying`: Ejecuta la clasificación los sábados a las 15:00 COT.
    *   `scheduledRace`: Simula la carrera completa los domingos a las 14:00 COT.
    *   `postRaceProcessing`: Procesa la economía, contratos de sponsors y evolución de pilotos 1 hora tras el fin de la carrera.
    *   `scheduledDailyFitnessRecovery`: Cron diario (00:00 COT) que recupera +1.5 de fatiga a todos los pilotos activos.
*   **SimEngine**: Implementa las leyes físicas del universo FTG (Degradación de gomas, consumo de combustible, probabilidades de accidente).
*   **Transfer Resolver**: Cron por hora que cierra subastas de pilotos tras 24h de expiración.

---

## 3. Integración y Seguridad
*   **Transacciones**: Todas las operaciones que afectan el `budget` o el `rango de stats` de un piloto se realizan mediante `runTransaction` de Firestore para evitar colisiones de estado.
*   **Persistencia Optimista**: La UI se actualiza inmediatamente tras la escritura, mientras que los listeners en los Stores aseguran la consistencia final con el servidor.
