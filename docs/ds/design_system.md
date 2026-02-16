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
- **Border Radius**: 8px (Estándar para tarjetas, botones y modales).
- **Elevación**: Sutil (Elevation 2), utilizando sombras con opacidad `0.3` sobre el fondo `#15151E`.
- **Zebra Tables**: Las tablas de standings utilizan un fondo nulo para filas normales y un fondo `#secondary` con opacidad `0.15` para filas resaltadas.
- **Highlighters**: Las filas seleccionadas o del jugador incluyen una **borde izquierdo de 4px** con el color `#secondary`.

### Interactividad (Buttons & Selectors)
- **Elevated Buttons**: Altura generosa (12-16px padding vertical), sin bordes redondeados excesivos (8px). Sin sombras de elevación plana para un look moderno de "Flat neumorphism".
- **Selection Outline**: Los elementos seleccionables (como pilotos en el Paddock) utilizan un **borde de 1px** del color `#secondary` al estar activos.
- **Sliders**: Tracks de color `#secondary` con fondos de carril muy sutiles (`alpha: 0.1`).

### Micro-animaciones y Visuales
- **Gradients**: Se favorecen gradientes lineales sutiles de `TopLeft` a `BottomRight` mezclando el color de la tarjeta con el fondo de la pantalla para crear profundidad en "Hero sections".
- **Iconografía**: Lineal (Outlined) para un look limpio, transicionando a relleno (Filled) solo para estados activos si es necesario.

---

## 4. Layout
- **Padding Lateral**: 20px (Dashboard) / 16px (Tabs/Resto).
- **Spacing vertical**: Sistema de 8px (8, 16, 24, 32).
