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
***NOTA***: TODOS LOS NOMBRES DEBEN PONERSE EN INGLÉS Y CON CAMELCASE POR STANDAR DE INDUSTRIA
| Module | Responsibility | Key Components |
| :--- | :--- | :--- |
| **`CoreModule`** | Lógica compartida, tipos básicos, utilidades de red y auth. | `AuthService`, `UserModel`, `AppTheme` |
| **`RacingModule`** | Simulación de sesiones, resultados y telemetría. | `RaceService`, `RaceEvent`, `CarSetup` |
| **`TeamManagementModule`** | Gestión de personal, finanzas e instalaciones (HQ). | `TeamService`, `Facility`, `FinanceService` |
| **`MarketModule`** | Fichajes de pilotos y subastas de patrocinadores. | `TransferMarketService`, `SponsorService`, `Driver` |
| **`SeasonModule`** | Calendario, clasificaciones y gestión de ligas. | `SeasonService`, `League`, `Standings` |

---

## 3. Análisis Profundo de Sistemas Críticos

### 3.1. Race Simulation Engine (`RacingModule`)
Es el núcleo técnico de la aplicación, contenido principalmente en `RaceService`.
*   **Simulación Síncrona vs. Asíncrona:**
    *   **Practices & Qualifying (Síncrona):** Ejecución inmediata en el cliente basada en modelos estocásticos. Calcula `setupConfidence` y `lapTime` instantáneamente para dar feedback al usuario.
    *   **Race Session (Asíncrona/Híbrida):** Simulación vuelta a vuelta que integra consumo de combustible, desgaste de neumáticos y eventos aleatorios (accidentes/DNF).
*   **Dependencia Estática:** Utiliza `CircuitService` para obtener perfiles de pista (`CircuitProfile`) que definen los pesos de importancia de Aero/Powertrain/Chassis.
*   **Desarrollo de Pilotos:** El `DriverDevelopmentService` traduce el rendimiento en pista en ganancia de XP estocástica, afectando el potencial a largo plazo.

### 3.2. Market & Negotiation Logic (`MarketModule`)
*   **Transfer Market:** Implementa un sistema de subastas con "cierre por tiempo" y bloqueos de última hora (5 min). Utiliza transacciones de Firestore para garantizar la integridad financiera entre compradores y vendedores.
*   **Sponsor System:** Sistema de negociación basado en "Personalidad vs. Táctica". Los patrocinadores tienen estados de bloqueo (`lockedUntil`) para evitar abusos de fuerza bruta en negociaciones.

### 3.3. Youth Academy System (`TeamManagementModule`)
*   **Pipeline de Talento:** Sistema de generación de candidatos (1 Masc. / 1 Fem.) con rangos de stats ocultos. 
*   **Lógica de Promoción:** Convierte un `YoungDriver` en un `Driver` completo, heredando el potencial del graduado pero con beneficios financieros (50% de salario del piloto anterior).

---

## 4. Flujo de Información y Performance

### Mejoras Propuestas:
1.  **Repository Pattern:** Introducir una capa de repositorios entre los servicios y Firebase para cachear datos y reducir lecturas innecesarias.
2.  **DTOs (Data Transfer Objects):** Separar el modelo de la base de datos del modelo de la UI para evitar reconstrucciones de pantalla globales cuando solo cambia un dato pequeño.
3.  **Lazy Loading de Módulos:** Asegurar que el `RacingModule` no se cargue ni ocupe memoria mientras el usuario está en el `MarketModule`.

---

## 5. Hoja de Ruta para el Desarrollo Orgánico

El objetivo es que los prompts del PM sean específicos:
*   *Mal:* "IA, arregla los problemas en el servicio de carreras."
*   *Bien:* "IA, en el `RacingModule`, mejora el componente de `telemetry` para que consuma menos CPU."

Esta estructura permite que la IA trabaje en **aislamiento**, garantizando que el performance general no se degrade por cambios locales.
