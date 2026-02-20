# Plan de Implementación: Refactorización del Selector de Equipos y Corrección de Errores

Este plan detalla los cambios necesarios para mejorar el `TeamSelectionScreen`, implementar la lógica de bloqueo de ligas, actualizar el diseño visual a estilo "Onyx" y mostrar información detallada de pilotos y managers.

## 1. Corrección de Errores y Manejo de Excepciones
*   Mejorar el bloque `try-catch` en `_handleApplyJob` para proporcionar mensajes de error más claros.
*   Asegurar que la navegación a `MainLayout` sea robusta.

## 2. Lógica de Bloqueo de Ligas
*   Implementar un chequeo en `_loadLeagueData` para determinar si la liga superior ("World Championship") está completamente ocupada por managers humanos.
*   En `TeamSelectionScreen`, deshabilitar (o mostrar un mensaje) la sección de "2th Series" si la liga superior no está llena.

## 3. Mejora del Modelo de Datos en UI
*   Actualizar `_loadLeagueData` para mapear pilotos a sus respectivos equipos.
*   Implementar una función para cargar perfiles de managers para equipos que ya están ocupados.

## 4. Rediseño Visual (Estilo Onyx)
*   Crear un nuevo estilo de tarjeta `Onyx` para las tarjetas de equipo.
*   Paleta de colores: Fondos oscuros profundos, bordes sutiles, detalles en colores secundarios/acentos.

## 5. Actualización de `_TeamSelectionCard`
*   Mostrar nombres y banderas de los pilotos (Main y Secondary).
*   Si el equipo está ocupado:
    *   Mostrar nombre y bandera del Manager.
    *   Cambiar el botón por un texto "Unavailable".
*   Si el equipo está libre:
    *   Mostrar el botón "SELECT TEAM".

## Tareas Detalladas:

### Tarea 1: Actualizar `TeamSelectionScreen` y `_loadLeagueData`
- Cargar todos los pilotos de las ligas.
- Identificar equipos con managers.
- Determinar si "World" está lleno.

### Tarea 2: Implementar Carga de Managers Ocupados
- Obtener los perfiles de los managers desde la colección `managers` para los equipos donde `isBot == false`.

### Tarea 3: Modificar `_TeamSelectionCard`
- Recibir una lista de pilotos.
- Recibir información del manager (si aplica).
- Actualizar el layout para mostrar banderas y nombres.
- Aplicar diseño Onyx.
