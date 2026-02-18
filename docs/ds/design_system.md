# Fire Tower Games Design System (FTG-DS)

Este documento centraliza las directrices visuales, colores, tipografía y componentes principales de **FTG Racing Manager**. El objetivo es mantener la consistencia visual y elevar la calidad percibida de la aplicación (Efecto "Premium").

---

## 1. Fundamentos de Color

El sistema utiliza una paleta oscura moderna basada en un color de fondo profundo y acentos vibrantes para jerarquía y retroalimentación.

### Colores de Marca (Core)
| Elemento | Hexadecimal | Uso |
| :--- | :--- | :--- |
| **App Background** | `#15151E` | Fondo principal de todas las pantallas. |
| **Surface/Card** | `#292A33` | Color de fondo de tarjetas e inputs. |
| **Primary** | `#3A40B1` | Botones principales y acciones destacadas. |
| **Secondary/Accent** | `#C1C4F4` | Íconos, estados seleccionados, insignias y resaltados. |
| **Button Hover** | `#424686` | Feedback interactivo para botones primarios. |
| **Text Primary** | `#FFFFFF` | Títulos y lectura principal. |
| **Text Muted** | `rgba(255,255,255,0.7)` | Subtítulos y metadatos. |

### Colores de Estado (Feedback)
| Estado | Hexadecimal | Significado |
| :--- | :--- | :--- |
| **Error/Critical** | `#EF5350` | Fallos, DNFs, presupuestos negativos o alertas. |
| **Success** | `#00C853` | Sesiones abiertas, programas completados, finanzas positivas. |
| **Qualifying** | `#FFB800` | Sesión de clasificación, avisos o advertencias. |
| **Race/Strategy** | `#FF5252` | Día de carrera, criticidad alta. |
| **Neutral/Grey** | `#9E9E9E` | Deshabilitado, estados concluidos. |
| **Driver Stats Scale** | *Ver abajo* | Representación visual del nivel de habilidad (0-20). |

### Escala de Color para Driver Stats (0-20)
Esta escala proporciona feedback inmediato sobre la calidad de una estadística específica de un piloto.

| Rango | Color | Hexadecimal | Significado |
| :--- | :--- | :--- | :--- |
| **Crítico** | Rojo | `#EF5350` | Valor 0 (Inexistente/Grave) |
| **Bajo** | Naranja | `#FF7043` | Valores 1-5 (Nivel muy bajo) |
| **Medio-Bajo** | Amarillo | `#FFD54F` | Valores 6-9 (Nivel mejorable) |
| **Competente** | Cyan | `#26C6DA` | Valores 10-13 (Nivel profesional estándar) |
| **Alto/Elite** | Verde Claro | `#66BB6A` | Valores 14-17 (Potencial de podio) |
| **Maestro** | Verde Oscuro | `#2E7D32` | Valores 18-20 (Nivel campeón mundial) |

---

## 2. Tipografía

El sistema tipográfico utiliza una combinación de dos fuentes para separar la estructura de la narrativa.

### Estilos Principales
- **Outfit (Google Fonts)**: Utilizada para **Headlines** y títulos de gran impacto.
  - Carácter: Moderno, geométrico, audaz.
  - Peso: Principalmente `Bold` (700) o `Extra Bold`.
- **Inter (Google Fonts)**: Utilizada para **Body text**, botones y datos.
  - Carácter: Alta legibilidad en tamaños pequeños.
  - Peso: `Regular` (400) para lectura, `Bold` (700) para énfasis/botones.

### Escala de Texto (Provisional)
- **H1 (AppBar/Title)**: 20px, Outfit Bold.
- **H2 (Section Header)**: 18px, Outfit Bold.
- **Body Large**: 16px, Inter Regular.
- **Body Medium**: 14px, Inter Regular.
- **Table Data**: 12px, Inter Medium.
- **Labels/Overlines**: 10-11px, Inter Bold (Uppercase, Letter Spacing 1.2+).

---

## 3. Elementos de UI y Componentes

### Tarjetas y Contenedores
- **Border Radius**: 12px (Estándar actualizado para tarjetas premium), 8px para botones y modales pequeños.
- **Elevación**: Sutil (Elevation 4), utilizando sombras con opacidad `0.3` sobre el fondo `#15151E`.
- **Zebra Tables**: Las tablas de standings utilizan un fondo nulo para filas normales y un fondo `#secondary` con opacidad `0.15` para filas resaltadas.
- **Highlighters**: Las filas seleccionadas o del jugador incluyen una **borde izquierdo de 4px** con el color `#secondary`.

### Componentes Premium (Nuevos)
#### 1. Tarjetas de Instrucciones/Reglas (Instruction Cards)
Utilizadas para guiar al usuario en secciones complejas (Garage, Sponsors).
- **Fondo**: Gradiente lineal de `TopLeft` (Primary con 15% opacidad) a `BottomRight` (Surface).
- **Borde**: Borde completo de 1px en color `Primary` con 20% de opacidad.
- **Layout**: 
  - Fila superior con ícono (32px) y título en `Outfit Bold` (Primary 90% opacidad).
  - Cuerpo de texto descriptivo con altura de línea `1.5`.
- **Ubicación**: Siempre en la parte superior de la vista, ocupando el 100% del ancho disponible.

#### 2. Tarjetas de Categoría (Category Cards)
Utilizadas en hubs de gestión (ej. Personal Screen).
- **Interactividad**: Efecto `InkWell` para navegación.
- **Estado Bloqueado**: Opacidad del 50% en el color de fondo e íconos en gris.
- **Badge "Soon"**: Cintilla diagonal roja (`RedAccent`) en la esquina superior derecha rotada 45 grados para funcionalidades en desarrollo.

### Interactividad (Buttons & Selectors)
- **Elevated Buttons**: Altura generosa (12-16px padding vertical), 8px border radius. Look moderno de "Flat neumorphism".
- **Selection Outline**: Relación de 1px con el color `#secondary` para indicar foco activo.
- **Sliders**: Tracks de color `#secondary` con fondos de carril muy sutiles (`alpha: 0.1`).

---

## 4. Navegación Jerárquica

El sistema utiliza una arquitectura de información multinivel para organizar la complejidad del simulador.

### Niveles de Jerarquía
1. **Nivel 1 (Global)**: Dashboard, HQ, Racing, Management, Season.
2. **Nivel 2 (Secciones)**: Ej. HQ -> Garage, Management -> Personal.
3. **Nivel 3 (Detalle)**: Ej. Personal -> Drivers.

### Comportamiento por Plataforma
- **Desktop (Sidebar)**: 
  - Sidebar colapsable (70px a 250px).
  - Uso de `ExpansionTile` para categorías con hijos.
  - Identación progresiva (16px por nivel) para mantener claridad visual.
  - El estado se mantiene sincronizado: abrir una categoría selecciona automáticamente su primer submenú funcional.
- **Mobile (Navbar Hub)**: 
  - Nivel 1 en `BottomNavigationBar`.
  - Nivel 2 en un `SubNavbar` horizontal scrollable justo debajo del AppBar.
  - Navegación automática: Al tocar "Management", el sistema redirige al usuario directamente a "Personal" (primer hijo).

---

## 5. Patrones de Feedback y Badges

- **Diagonal Ribbon ("SOON")**: Indica características planificadas. Color: Rojo vibrante, texto blanco, fuente pequeña (8px) y Bold.
- **Status Indicator ("CURRENT")**: Fondo sólido `Primary`, texto negro `8-10px Bold`. Utilizado en el calendario para resaltar la carrera activa.
- **Checkmark Completion**: Ícono `check_circle` en color `Success` para tareas o eventos finalizados.

---

## 6. Layout

- **MaxWidth (Desktop Content)**: 1400px (Centrado con `ConstrainedBox` para evitar estiramiento excesivo en monitores ultra-wide).
- **Padding Lateral**: 20px (Dashboard/Hubs) / 16px (Vistas de detalle).
- **Spacing vertical**: Sistema de 8px (8, 16, 24, 32).
- **Responsive Shell**: Uso de `LayoutBuilder` para alternar entre Sidebar (Desktop) y BottomNav (Mobile) basado en un breakpoint de `600px` (ancho de tablet pequeña).
