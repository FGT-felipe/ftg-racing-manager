# Análisis de Arquitectura y Plan de Modularización - FTG Racing Manager

## 1. Evaluación de la Arquitectura Actual

La aplicación utiliza un patrón de diseño basado en carpetas por tipo (`models`, `services`, `screens`, `widgets`), lo cual es común en etapas tempranas pero genera problemas de escalabilidad a medida que el proyecto crece.

### Puntos Críticos Identificados:
*   **Modelos Monolíticos:** El archivo `core_models.dart` (>1300 líneas) contiene casi todas las entidades del negocio (League, RaceEvent, Season, Team, etc.). Esto dificulta la navegación y provoca que cualquier cambio pequeño afecte a toda la app.
*   **Servicios con Lógica Mezclada:** `RaceService` (>1700 líneas) maneja desde simulación de setups hasta XP post-carrera. Hay una alta dependencia entre servicios manejada de forma plana en la carpeta `services`.
*   **Acoplamiento de Datos (Firebase):** Los modelos están fuertemente ligados a la estructura de Firestore mediante métodos `toMap` manuales, lo que hace que cambiar la base de datos o la estructura de datos sea arriesgado.
*   **Performance:** Al no estar modularizada, la IA tiene que leer archivos gigantes para hacer cambios pequeños, lo que aumenta la probabilidad de errores y de "romper" funcionalidades no relacionadas.

---

## 2. Propuesta de Modularización (Feature-First)

Para que el Product Manager pueda decir "IA, actualiza el módulo X", debemos pasar de una estructura por "tipo de archivo" a una **estructura por "funcionalidad" (Features)**.

### Módulos Propuestos:

| Módulo | Responsabilidad | Componentes Clave |
| :--- | :--- | :--- |
| **`módulo_núcleo` (Core)** | Lógica compartida, tipos básicos, utilidades de red y auth. | `AuthService`, `UserModel`, `AppTheme` |
| **`módulo_carreras` (Racing)** | Simulación de sesiones, resultados y telemetría. | `RaceService`, `RaceEvent`, `CarSetup` |
| **`módulo_gestión_equipo` (Team)** | Gestión de personal, finanzas e instalaciones (HQ). | `TeamService`, `Facility`, `FinanceService` |
| **`módulo_mercado` (Market)** | Fichajes de pilotos y subastas de patrocinadores. | `TransferMarketService`, `SponsorService`, `Driver` |
| **`módulo_campeonato` (Season)** | Calendario, clasificaciones y gestión de ligas. | `SeasonService`, `League`, `Standings` |

---

## 3. Flujo de Información y Performance

### Mejoras Propuestas:
1.  **Repository Pattern:** Introducir una capa de repositorios entre los servicios y Firebase para cachear datos y reducir lecturas innecesarias.
2.  **DTOs (Data Transfer Objects):** Separar el modelo de la base de datos del modelo de la UI para evitar reconstrucciones de pantalla globales cuando solo cambia un dato pequeño.
3.  **Lazy Loading de Módulos:** Asegurar que el `módulo_carreras` no se cargue ni ocupe memoria mientras el usuario está en el `módulo_mercado`.

---

## 4. Hoja de Ruta para el Desarrollo Orgánico

El objetivo es que los prompts del PM sean específicos:
*   *Mal:* "IA, arregla los problemas en el servicio de carreras."
*   *Bien:* "IA, en el `módulo_carreras`, mejora el componente de `telemetría` para que consuma menos CPU."

Esta estructura permite que la IA trabaje en **aislamiento**, garantizando que el performance general no se degrade por cambios locales.
