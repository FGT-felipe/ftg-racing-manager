# Informe de Consistencia del Sistema de Diseño - FTG Racing Manager

## 1. Análisis de Identidad Visual (Sim Racing Premium)

La aplicación tiene una base sólida inspirada en juegos de gestión de carreras modernos (como F1 Manager o Motorsport Manager), utilizando una paleta oscura con acentos vibrantes.

### Consistencias Positivas:
*   **Tipografía de Alto Impacto:** El uso de `Poppins` con peso 900 para encabezados (`w900`) comunica velocidad y agresividad competitiva.
*   **Jerarquía de Color:** El contraste entre el fondo `0xFF15151E` y los botones primarios `0xFF3A40B1` está bien definido para la navegación principal.
*   **Estética "Glassmorphism" / Dark Tech:** El uso de tarjetas con `secondaryButton` como fondo crea una profundidad visual adecuada para pantallas con mucha información técnica.

---

## 2. Inconsistencias y Puntos de Dolor

### Inconsistencias de Diseño:
*   **Mezcla de Estilos de Botones:** Se observa el uso de `StadiumBorder` (bordes redondeados) en botones, pero algunas tarjetas y tablas mantienen bordes rectos o con radios de esquina muy pequeños (12px). Esto genera una disonancia visual entre elementos "orgánicos" y "técnicos".
*   **Gamas de Colores Ad-hoc:** Se han detectado opacidades manuales (`withOpacity` / `.withValues`) dispersas en el código en lugar de usar tokens de color definidos en el JSON del sistema de diseño.
*   **Densidad de Información:** En las tablas (especialmente `OnyxTable`), la densidad de datos es alta pero la separación visual (negativos/márgenes) es inconsistente con el resto de la UI, lo que cansa la vista del usuario.

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

El sistema de diseño es **técnicamente consistente pero visualmente heterogéneo**. Modularizar los componentes permitiría que la IA diga: "He actualizado el `DataBadge` en el módulo de `mercado`", asegurando que el cambio se refleje automáticamente en toda la aplicación con la misma estética.
