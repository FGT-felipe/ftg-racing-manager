# Informe de Consistencia del Sistema de Diseño - FTG Racing Manager

## 1. Análisis de Identidad Visual (Sim Racing Premium)

La aplicación tiene una base sólida inspirada en juegos de gestión de carreras modernos (como F1 Manager o Motorsport Manager), utilizando una paleta oscura con acentos vibrantes.

### Consistencias Positivas:
*   **Tipografía de Alto Impacto:** El uso de `Poppins` con peso 900 para encabezados (`w900`) comunica velocidad y agresividad competitiva.
*   **Jerarquía de Color:** El contraste entre el fondo `0xFF15151E` y los botones primarios `0xFF3A40B1` está bien definido para la navegación principal.
*   **Estética "Glassmorphism" / Dark Tech:** El uso de tarjetas con `secondaryButton` como fondo crea una profundidad visual adecuada para pantallas con mucha información técnica.

---

## 2. Inconsistencias y Puntos de Dolor

### Inconsistencias de Diseño Identificadas:
*   **Dicotomía en Tablas (Onyx vs. Flat):**
    *   **Onyx Style:** Utilizado en `StandingsScreen` y `MarketScreen`. Presenta contenedores oscuros con gradientes complejos, sombras profundas (`blurRadius: 24`) y bordes definidos.
    *   **Flat Style:** Utilizado en `TeamScreen` (desglose de pilotos) y tablas internas de `DriverCard`. Carece de profundidad visual, usando divisores simples y fondos planos.
*   **Dualidad en Tarjetas (Neon vs. Border-only):**
    *   **Neon/Glow Style:** La `DriverCard` rediseñada utiliza efectos de neón (`0xFFFF00FF`), sombras con brillo (`glow shadows`) y fondos con patrones de rejilla (`CustomPaint`).
    *   **Simple Border Style:** Componentes como `InstructionCard` o `NameChangeCard` utilizan bordes de 1px con opacidades bajas, sintiéndose "desactualizados".
*   **Radios de Curvatura Inconsistentes:** Se mezclan elementos con `borderRadius: 16` con otros de `12` o `8` sin un criterio de jerarquía claro.

### 2. Análisis por Módulos

#### RacingModule (El mayor "Outlier")
*   **Inconsistencia de Componentes:** Es el único módulo crítico que **no utiliza `OnyxTable`**. Las tablas de `GarageScreen` y `RaceDayScreen` son implementaciones manuales que no heredan los estilos globales de datos técnicos.
*   **Degradación Tipográfica:** Se observa el uso de `TextStyle` estándar en lugar de los tokens de `GoogleFonts` en elementos de telemetría y cronometraje.
*   **Lógica Monolítica:** La extrema longitud de archivos (ej. `garage_screen.dart` con 5000+ líneas) ha provocado que el diseño se "congele" en patrones antiguos mientras el resto de la app evoluciona.

#### MarketModule vs. TeamManagementModule
*   **Botones Divergentes:** Mientras el `MarketModule` usa `FilledButton` estándar de Flutter para las pujas, el `TeamManagementModule` utiliza contenedores con gradientes manuales y bordes verdes neón para acciones similares de confirmación.
*   **Feedback Visual:** El `Market` usa un sistema de cuenta regresiva simple, mientras que el `RacingModule` usa un "Pit Board" animado con un lenguaje visual único que no se repite en el resto de la gestión.

---

## 3. Propuesta de Componentes "LEGO" para el PM

---

## 3. Propuesta de Componentes "LEGO" para el PM

Para facilitar que la IA actualice la UI sin desmoronar el diseño, proponemos una biblioteca de **Componentes de Diseño Atómicos**:

### Categoría: Data & Tables
*   **`OnyxTable`**: Unificado con estados de carga (`OnyxSkeleton`) y bordes coherentes.
*   **`DataBadge`**: Para mostrar estadísticas de pilotos (velocidad, fiabilidad) con indicadores visuales de mejora/empeoramiento.

### Categoría: Feedback & News
*   **`PressNewsCard`**: Estilo editorial para noticias del paddock.
*   **`ActionNotification`**: Notificaciones críticas que requieren acción inmediata del manager.

### Categoría: Technical Detail
*   **`CarSchematicWidget`**: Visualización técnica del monoplaza para áreas de ingeniería.

---

## 4. Sugerencia de Mejora de Performance Visual

*   **Micro-animaciones:** Implementar transiciones suaves (`Hero` animations) al navegar entre la lista de pilotos y el detalle del piloto.
*   **Optimización de Asset Loading:** Asegurar que los retratos de los pilotos (`portrait_service`) tengan un placeholder de baja resolución para evitar saltos visuales durante la carga.

---

## 5. Conclusión para el PM

El sistema de diseño es **técnicamente consistente pero visualmente heterogéneo**, siendo el `RacingModule` el punto más crítico de divergencia. Se recomienda:
1.  **Refactorizar `RacingModule`**: Dividir las pantallas monolíticas en widgets reutilizables que implementen `OnyxTable`.
2.  **Unificar Botones de Acción**: Crear un widget `OnyxActionButton` que encapsule los gradientes y efectos neón para todas las confirmaciones críticas (compras, renovaciones, envíos de setup).
3.  **Centralizar Tokens**: Migrar todas las opacidades manuales a un `AppColors` centralizado para evitar el uso de colores "a ojo" en el código.
