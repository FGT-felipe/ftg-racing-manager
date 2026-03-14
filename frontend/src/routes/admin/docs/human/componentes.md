# Arquitectura de Componentes y Diseño de Sistemas

Este documento detalla la estructura y los patrones de implementación de la interfaz de usuario de FTG Racing Manager.

---

## 1. Patrones de Diseño de Componentes
Seguimos el patrón **Atomic Design** adaptado a la reactividad de Svelte 5.

### Componentes de Presentación (Pure UI)
Ubicados en `src/lib/components/ui`, estos componentes no tienen dependencias de stores y solo reaccionan a props.
*   **`CountryFlag`**: Renderizado de flags optimizado con `Lucide` y sprites.
*   **`DriverAvatar`**: Generador dinámico de retratos basado en `Dicebear` y semillas deterministas.
*   **`StatusBadge`**: Sistema de estados (Success, Warning, Danger) reutilizable con variantes semánticas.

### Componentes de Negocio (Connected)
Ubicados en `src/lib/components/features`, estos componentes están acoplados a stores específicos.
*   **`RaceStatusHero`**: El orquestador visual del Dashboard. Escucha al `timeStore` y `seasonStore`.
*   **`StandingsCard`**: Visualización de tablas de championship con lógica de filtrado reactiva en cliente.
*   **`SetupSlider`**: UI para el Parc Fermé que valida los límites de configuración en tiempo real.

---

## 2. Implementación Técnica (Senior)

### Reactividad de Svelte 5
Todos los componentes deben implementar el patrón de **Props Desestructuradas** para máxima legibilidad:
```svelte
<script lang="ts">
  let { title, value, variant = 'default' } = $props();
</script>
```

### Estándares de Estilo y Visualización
*   **Z-Index Strategy**: Sistema de capas estrictamente definido (Basal, Floating, Modal, Overlay).
*   **Micro-interacciones**: Uso intensivo de `transition:fade` y `animate:flip` de Svelte para transiciones de posición en tablas (Standings).
*   **Optimización de Renderizado**: Los componentes pesados (ej. `RaceLivePanel`) utilizan `$derived` para memoizar transformaciones de telemetría y evitar re-renders innecesarios de todo el DOM.

---

## 4. Estándares de Layout de Carrera
*   **Grid System**: Las pestañas de sesión (Practice, Qualifying, Race) utilizan un sistema de 12 columnas.
*   **Proporción 7/5**: La columna izquierda (Setup/Controls) ocupa 7 columnas (`lg:col-span-7`), mientras que la derecha (Live Classification/Telemetry) ocupa 5 (`lg:col-span-5`).
*   **Espaciado**: Se utiliza un `gap-5` y `space-y-5` consistente para mantener una estética compacta y técnica.

---

## 3. Guía de Interfaz (Design System)
*   **Typography**: Outfit para encabezados (Legibilidad deportiva), Inter para datos tubulares (Telemetría).
*   **Color tokens**:
    *   `Accent`: `--color-primary` (Gold/Champagne) para victorias.
    *   `Danger`: `--color-error` (Racing Red) para DNFs y fallos mecánicos.
    *   `Surface`: `--color-surface-900` (Deep Black) para el fondo inmersivo.
