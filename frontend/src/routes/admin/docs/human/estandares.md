# Estándares de Desarrollo y Gobernanza (Senior)

Este documento define la normativa técnica que debe seguirse para cualquier modificación o expansión del ecosistema FTG Racing Manager. El incumplimiento de estas premisas compromete la integridad de la simulación y la escalabilidad del producto.

---
NUNCA HARDCODEAR NADA, TODO DEBE SER CONFIGURABLE DESDE EL BACKEND

## 1. Patrones de Reactividad (Svelte 5)
El proyecto utiliza **Svelte 5 Runes**. Es imperativo evitar el uso de `writable` stores antiguos para estados reactivos en Favor de `$state`.

*   **Estados**: Usar `$state()` para datos crudos.
*   **Derivados**: Usar `$derived()` para cualquier transformación de datos (ej. formatear moneda, filtrar listas).
*   **Efectos**: El uso de `$effect()` debe ser el último recurso, preferiblemente para integraciones con el DOM o sincronización externa (SDK Firebase).
*   **Encapsulamiento**: Las clases de lógica deben usar getters para exponer estados reactivos de forma controlada.

---

## 2. Componentización y UI
Seguimos una arquitectura de componentes modular y de diseño premium.

*   **Estilo**: Usar Tailwind CSS exclusivamente. Prohibido el uso de styles inline o CSS en línea.
*   **Tokens**: Respetar las variables definidas en `app.css` (`--app-primary`, `--app-surface`).
*   **Slots & Snippets**: Utilizar `{#snippet ...}` de Svelte 5 para pasar fragmentos de UI complejos a componentes hijos.
*   **Diálogos y Modales**: El uso de diálogos nativos del navegador (`alert`, `confirm`, `prompt`) está terminantemente **PROHIBIDO**. Se debe utilizar el sistema de modales del `uiStore`.
*   **Responsividad**: Aplicar el enfoque *Mobile First*. Priorizar visualizaciones compactas para móviles que escalen a tableros de mando en desktop.

---

## 3. Interacción con Firebase y Backend
La integridad de los datos es la prioridad máxima, especialmente en transacciones económicas.

*   **Transacciones**: Toda operación que involucre el `budget` o cambio de propiedad de un piloto DEBE ejecutarse dentro de un `runTransaction`.
*   **Servicios vs Stores**:
    *   Los **Services** (`src/lib/services`) gestionan llamadas puras a la API y lógica stateless.
    *   Los **Stores** (`src/lib/stores`) orquestan la reactividad del frontend y escuchan cambios (`onSnapshot`).
*   **Costo de Lectura**: Evitar lecturas innecesarias. Utilizar filtros dinámicos en las queries y evitar `getDocs` masivos si se puede usar un listener puntual.

---

## 4. Gestión de Errores y Calidad
*   **Silent Failures**: No se permiten bloques `catch` vacíos. Los errores deben loguearse con contexto (`console.error('[NamespaceService] Error message')`).
*   **Testing**: Todo nuevo servicio complejo en el backend debe incluir un archivo `.test.ts` que valide el caso de éxito y el de fallo.
*   **Logging**: Durante el desarrollo usar `console.debug`. En producción el código debe estar limpio de logs de depuración (auditar antes de PR).

---

## 5. Documentación de Código
*   **JSDoc**: Obligatorio para métodos públicos en servicios y stores, detallando parámetros y retorno.
*   **Auto-documentación**: Al añadir un nuevo servicio o vista, se debe actualizar el archivo correspondiente en `/docs` para reflejar el cambio en la arquitectura o reglas de negocio.
