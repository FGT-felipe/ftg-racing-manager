# Plan de Refactorización V4 - FTG Racing Manager

## 1. Visión General
El objetivo de la V4 es transformar FTG Racing Manager de un prototipo monolítico a una plataforma escalable, modular y **AI-Native**. Buscamos eliminar la deuda técnica acumulada en la V3 y establecer una base sólida para expansiones futuras (multijugador tiempo real, telemetría avanzada).

---

## 2. Sistema de Diseño Elegido: **Token-Based Atomic Design**

Como experto en SimRacing y Flutter Web, elijo un sistema **Híbrido Basado en Tokens + Diseño Atómico**. 

### ¿Por qué este sistema?
1.  **Consistencia Inmune a la IA:** Al definir **Tokens** (Color, Spacing, Blur, Glow) en una capa única, evitamos que la IA use opacidades manuales o colores "parecidos". La IA solo podrá usar lo definido en `OnyxTokens`.
2.  **Estética SimRacing Premium:** Los juegos de alta gama (F1, iRacing) usan interfaces altamente repetitivas (data bars, lap timers). El **Diseño Atómico** nos permite crear "Atoms" (un LED de rpm) y "Organisms" (un Pit Board completo) que se comportan igual en todas las pantallas.
3.  **Performance Web:** Flutter Web sufre con gradientes complejos si no están optimizados. Centralizar los efectos "Onyx" en componentes atómicos permite optimizar el renderizado en un solo lugar.

---

## 3. Fases del Plan de Refactorización

### Fase 1: Cimentación (Design System 2.0) - **PRIORIDAD ACTUAL**
*   **Definición de Tokens:** Crear `lib/core/theme/tokens.dart` con escalas de color (Neon, Slate, DeepBlack), radios (8, 12, 16) y efectos de elevación (Glows, Shadows).
*   **Librería Atómica (`lib/widgets/onyx_ui/`):**
    *   **Atoms:** Buttons, Labels, Icons, ProgressLines.
    *   **Molecules:** TableCells, StatusBadges, InputFields.
    *   **Organisms:** `OnyxTable` (v2), `OnyxCard` (v2), `DataDashboard`.
*   **Unificación:** Eliminar el estilo "Flat" y migrar todo a "Onyx 2.0".

### Fase 2: El "Gran Desglose" (Arquitectura Modular)
*   **Splitting de Modelos:** Dividir `core_models.dart` en archivos por dominio dentro de sus respectivos módulos.
*   **Servicios Descentralizados:** Romper `RaceService` en sub-servicios de dominio:
    *   `SimulationEngine`: Lógica pura de cálculos de tiempo.
    *   `RacePersistence`: Interacción con Firestore.
    *   `EventEngine`: Generación de accidentes y pit-stops.

### Fase 3: Capa de Datos (Repository Pattern)
*   **Implementación de Repositorios:** Crear interfaces para cada entidad (ej: `IDriverRepository`).
*   **DTOs y Mappers:** Separar los objetos de Firebase de los objetos de la UI para evitar reconstrucciones innecesarias de Flutter.

### Fase 4: Migración del RacingModule (El Outlier)
*   Refactorizar `GarageScreen` y `RaceDayScreen` usando los nuevos componentes atómicos y la lógica modular. Eliminar el código monolítico de 5000+ líneas.

---

## 4. Estándares 2025-2026 (AI-Centric)

Para que el desarrollo sea fluido con IA, adoptaremos estas reglas:
1.  **Single File Responsibility:** Ningún archivo debe exceder las 400 líneas. Si crece, se extrae a un sub-componente.
2.  **DocStrings Semánticos:** Cada función debe tener un comentario `@ai` que explique el "por qué" y las reglas de negocio, permitiendo que la IA mantenga el contexto sin leer todo el servicio.
3.  **Strict State Management:** Migrar de `setState` disperso a un patrón más predecible (Bloc o Riverpod) por módulo para que la IA sepa exactamente dónde fluyen los datos.

---

## 5. Primeros Pasos Inmediatos
1.  Crear la estructura de carpetas `lib/core/theme/tokens`.
2.  Definir la paleta oficial de colores Neon/Onyx.
3.  Refactorizar el primer "Atom": `OnyxButton`.
