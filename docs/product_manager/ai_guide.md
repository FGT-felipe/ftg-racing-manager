# Guía de Interacción IA para el Product Manager - FTG Racing Manager

Esta guía establece las reglas y el lenguaje que debe usar el Product Manager para que la IA realice cambios precisos, modulares y seguros en la aplicación.

---

## 1. El Diccionario del PM (Módulos y Componentes)

Para que el desarrollo sea "orgánico", debes referirte a las partes de la app por sus nombres técnicos establecidos:

### Main Modules & Components:
*   **`CoreModule`**: Shared logic, basic types, network utilities, and authentication.
    *   *Components:* `AuthService`, `UserModel`, `AppTheme`.
*   **`RacingModule`**: Session simulation, results, and telemetry.
    *   *Components:* `RaceService`, `RaceEvent`, `CarSetup`.
*   **`TeamManagementModule`**: Personnel management, finances, and facilities (HQ).
    *   *Components:* `TeamService`, `Facility`, `FinanceService`.
*   **`MarketModule`**: Driver signings and sponsor auctions.
    *   *Components:* `TransferMarketService`, `SponsorService`, `Driver`.
*   **`SeasonModule`**: Calendar, standings, and league management.
    *   *Components:* `SeasonService`, `League`, `Standings`.

---

## 2. Reglas de Oro para lanzar Prompts (Instrucciones)

Cada vez que lances un prompt a la IA, sigue esta estructura para evitar errores de performance:

### REGLA 1: Especificar el "Contexto de Módulo"
Siempre empieza indicando en qué módulo quieres trabajar.
> *Ejemplo:* "En el `MarketModule`, añade un filtro de edad a la lista de pilotos."

### REGLA 2: Usar el "Lego de Componentes"
Si quieres cambiar la UI, nombra el componente de diseño.
> *Ejemplo:* "Actualiza el `DataBadge` del piloto para que sea rojo si su moral es baja."

### REGLA 3: Prohibir el "Efecto Cascada"
Pide explícitamente que no se modifiquen otros módulos.
> *Ejemplo:* "Implementa este cambio en el `RacingModule` asegurándote de no afectar al performance del `TeamManagementModule`."

---

## 3. Plantillas de Prompt Recomendadas

### Para un Nuevo Módulo / Funcionalidad:
> "Actúa como desarrollador senior. Crea un nuevo submódulo llamado `Scouting` dentro del `TeamManagementModule`. Usa el patrón de Repositorio para la data y asegúrate de que use el componente `OnyxTable` para mostrar los resultados."

### Para Mejorar uno Existente:
> "En el `SeasonModule`, optimiza el flujo de información de la pantalla de clasificaciones. Evita reconstrucciones innecesarias (rebuilds) y usa el sistema de colores definido en `CoreModule`."

### Para Arreglar un Bug:
> "Hay un bug en el `RaceService` cuando se calcula el desgaste de neumáticos. Arréglalo sin modificar la lógica de XP de los pilotos."

---

## 4. Validación de Performance

Cada vez que la IA termine una tarea, el PM puede pedirle una **"Micro-auditoría de Performance"**:
> "Confírmame que este cambio no ha aumentado el número de lecturas en Firebase y que el archivo modificado no excede las 300 líneas de código para mantener la modularidad."

---

## 5. Conclusión

Siguiendo estas reglas, el desarrollo de **FTG Racing Manager** será más rápido, limpio y permitirá iteraciones constantes sin miedo a romper el sistema principal de simulación.
