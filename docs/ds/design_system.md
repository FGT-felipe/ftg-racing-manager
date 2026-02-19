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
| **Onyx Background** | `#121212` | Fondo de paneles de telemetría y Pit Boards. |
| **Onyx Gradient (Start)**| `#1E1E1E` | Inicio del degradado premium. |
| **Onyx Gradient (End)** | `#0A0A0A` | Fin del degradado premium. |
| **Telemetry Value** | `#FFD700` | Color dorado para tiempos y datos competitivos. |
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
- **Poppins Black (Google Fonts)**: Utilizada para **Headlines**, títulos de gran impacto y **Navegación de Primer Nivel**.
  - Carácter: Moderno, agresivo, audaz.
  - Peso: `Black` (900).
- **Raleway (Google Fonts)**: Utilizada para **Body text**, botones, datos y **Navegación de Nivel 2+**.
  - Carácter: Elegante, alta legibilidad.
  - Peso: `Regular` (400) para lectura, `Bold` (700) para énfasis/botones, `Black` (900) para sub-elementos jerárquicos.

### Escala de Texto (Provisional)
- **H1 (AppBar/Title)**: 20px, Poppins Black (Uppercase, Letter Spacing 1.5).
- **H2 (Section Header)**: 18px, Poppins Black.
- **Nav Level 1**: 14px, Poppins Black (Uppercase, Letter Spacing 1.2).
- **Nav Level 2**: 12px, Raleway Bold (Uppercase).
- **Body Large**: 16px, Raleway Regular.

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
  - Fila superior con ícono (32px) y título en `Poppins Black` (Primary 90% opacidad).
  - Cuerpo de texto descriptivo con altura de línea `1.5`.
- **Ubicación**: Siempre en la parte superior de la vista, ocupando el 100% del ancho disponible.

#### 2. Tarjetas de Categoría (Category Cards)
Utilizadas en hubs de gestión (ej. Personal Screen).
- **Interactividad**: Efecto `InkWell` para navegación.
- **Estado Bloqueado**: Opacidad del 50% en el color de fondo e íconos en gris.
- **Badge "Soon"**: Cintilla diagonal roja (`RedAccent`) en la esquina superior derecha rotada 45 grados para funcionalidades en desarrollo.

#### 3. Tarjetas de Instalaciones (Facility Cards)
Diseñadas para mostrar progresión y costos operativos.
- **Relación de Aspecto**: 1.0 (Cuadrada).
- **Estructura Interna**:
  - **Nivel (Solo si está comprada)**: Texto "LEVEL X" en la parte superior (`Raleway Bold`, 9px, letter-spacing 1.2) seguido de un divisor tenue.
  - **Parte Superior**: Ícono centrado (34-40px) y Título (`Poppins Black`, 14-16px).
  - **Divisor Central**: Línea tenue (`White10` o opacidad 0.1) que separa la cabecera de los detalles técnicos.
  - **Sección de Detalles**: Texto alineado a la izquierda (`Raleway`, 11-12px) con etiquetas:
    - *Purchase/Upgrade Level*: Costo de inversión.
    - *Maintenance Cost*: Costo operativo semanal (Color sutil/muted).
    - *Bonus*: Beneficio otorgado por el nivel actual.
- **Interactividad**: Botón de acción (`ElevatedButton`) alineado a la derecha en la sección inferior.
- **Estados**: 
  - *Bloqueado/Soon*: Opacidad 50%, íconos grises, cinta "SOON".
  - *Activo*: Colores vibrantes, detalles visibles.

#### 4. Migas de Pan (Breadcrumbs)
Elemento de guía jerárquica para pantallas profundas.
- **Tipografía**: `Raleway` (11-12px), color `Text Muted`.
- **Separador**: Carácter `/` con opacidad reducida.
- **Interactividad**: Los niveles superiores son interactivos (Hover: Highlight blanco).
- **Estilo**: Siempre en Mayúsculas con letter-spacing 1.0 para un look moderno y racing.

#### 5. Controlador de Sidebar (Sidebar Toggle)
Botón minimalista posicionado en el borde derecho del sidebar.
- **Forma**: Circular (24x24px).
- **Color**: Fondo `#secondary` (Accent), Icono Negro.
- **Comportamiento**: Flota en el borde para permitir el colapsado total (ancho 0px). Incluye una rotación animada de la flecha indicadora.

### Interactividad (Buttons & Selectors)
- **Elevated Buttons**: Altura generosa (12-16px padding vertical), 8px border radius. Look moderno de "Flat neumorphism".
- **Selection Outline**: Relación de 1px con el color `#secondary` para indicar foco activo.
- **Sliders**: Tracks de color `#secondary` con fondos de carril muy sutiles (`alpha: 0.1`).

#### 6. Paneles de Telemetría 'Onyx' (Pit Board & Results)
Diseñados para representar datos críticos de carrera con un look de alta tecnología.
- **Estética "Onyx Deep"**: Contenedores con degradado lineal (`TopLeft` a `BottomRight`) y bordes refinados de 1px con 10% de opacidad.
- **Estandarización de Altura**: Uso mandatorio de `IntrinsicHeight` en filas de datos para asegurar que todos los "cajones" de telemetría tengan la misma altura visual.
- **Pit Board Fields (Cajones de Datos)**:
  - **Etiqueta**: Mayúsculas, 9px, `letterSpacing: 0.8`, opacidad 40%.
  - **Valor**: `fontFamily: 'monospace'`, 15px+, `fontWeight: 900`, color `#FFD700` (Gold).
  - **Padding**: Estándar de `8px vertical, 10px horizontal`.
- **Tablas de Resultados y Práctica**:
  - **Cabeceras**: Fondo sutil de `white.withOpacity(0.03)` y bordes inferiores de 1px.
  - **Iconografía**: Uso de iconos específicos por sesión (Copa para Qualifying, Reloj para Practice).
  - **Filas de Datos**: Altura optimizada para visualización densa, con `InkWell` para mostrar detalles del setup.
  - **Resaltado (PB)**: Uso de colores de acento (Verde para PB, Purpura para Global Best) tanto en texto como en fondo de fila (opacidad 8%).

#### 7. Tarjetas de Piloto 'Onyx' (Weekend Setup)
Componente híbrido que combina identidad visual con telemetría de preparación.
- **Estructura 35/65**: 
  - **35% Izquierda**: Avatar a sangre (Portrait) con un degradado de transición hacia la zona de datos.
  - **65% Derecha**: Contenedor de información con padding de 12px.
- **Formato de Nombre**: Regla de visualización `[Inicial]. [Apellido]` (ej. "F. ALONSO").
  - Estilo: Mayúsculas, `fontSize: 12-13px`, `fontWeight: 900`.
- **Indicadores de Progreso**: Integración de la barra de fitness y contador de vueltas con iconos de telemetría.
- **Interactividad**: Elevación y sombra dinámica en estado seleccionado, con un borde de 2px en el color primario del equipo.

#### 8. Intel de Circuito 'Onyx' (Dynamic Weather)
Visualización adaptativa que utiliza el clima actual como lenguaje visual.
- **Estructura 35/65**:
  - **35% Izquierda**: Fondo con un icono de clima centrado (120px) con opacidad del 15% y un matiz sutil del color de acento.
  - **65% Derecha**: Información técnica (chips de características y enfoque de rendimiento).
- **Lógica de Colores Dinámica**:
  | Clima | Color de Acento | Tono Onyx (Gradient) | Ícono |
  | :--- | :--- | :--- | :--- |
  | **Soleado** | Naranja (`Amber`) | Cálido (Marrón Cálido `#453018` / Negro) | `wb_sunny` |
  | **Lluvioso** | Gris (`Grey`) | Neutro (Gris/Negro) | `umbrella` |
  | **Nublado/Sol** | Azul (`Blue`) | Frío (Azul/Negro) | `wb_cloudy` |
  | **Nublado** | Gris Azulado (`BlueGrey`) | Mate (Acero/Negro) | `cloud` |
- **Jerarquía**: El título "CIRCUIT INTEL" y el icono de info adoptan el color de acento para reforzar la temática climática.
- **Optimización en Race Tab**: Para maximizar el espacio útil, el componente se posiciona en paralelo al selector de pilotos utilizando una distribución de `flex: 60/40`, permitiendo configurar la estrategia con todo el contexto visual en una sola fila.

---

#### 9. Tarjeta de Estrategia de Carrera 'Onyx'
Diseñada para la configuración crítica pre-carrera, enfocada en la legibilidad y el orden de ejecución.
- **Visuales**: Fondo Onyx Deep (`#121212`) con gradiente superior izquierdo a transparente y sombras pesadas (`blurRadius: 20`).
- **Distribución 60/40**:
  - **60% Izquierda**: Configuración del Coche (Alerones, Suspensión, etc.).
  - **40% Derecha**: Estrategia de Paradas y Combustible.
- **Aparciencia de Tabla**:
  - Las filas de estrategia (Race Start, Stop 1, Stop 2) utilizan un fondo alternado para facilitar la lectura horizontal.
  - **Fila Impar**: `Colors.white.withValues(alpha: 0.03)`
  - **Fila Par**: `Colors.transparent`
- **Inputs Aliniados a la Izquierda**: Todos los selectores de neumáticos y campos de combustible se alinean a la izquierda para mantener una columna visual limpia.
- **Unidad de Combustible**: Estándar en **Litros (L)** con precisión de un decimal (ej. "50.0 L").

#### 10. Intel de Circuito Cualitativo
Evolución del sistema de información para aumentar el desafío estratégico.
- **Categorización**: Sustitución de valores numéricos por etiquetas cualitativas:
  - `Very Low`, `Low`, `Normal`, `High`, `Very High`.
- **Organización en 3 Filas**:
  - **Fila 1**: Vueltas Totales y Clima.
  - **Fila 2**: Enfoque Técnico (Aero/Power) y Velocidad Punta (Top Speed).
  - **Fila 3**: Desgaste de Neumáticos (Tyre Wear) y Consumo (Fuel).

---

## 4. Navegación Jerárquica

El sistema utiliza una arquitectura de información sin íconos (Icon-less), centrada en la tipografía y el contraste.

### Niveles de Jerarquía
1. **Nivel 1 (Global)**: Dashboard, HQ, Racing, Management, Season. Estilo `Poppins Black`.
2. **Nivel 2 (Secciones)**: Ej. HQ -> Garage. Siempre visibles en Desktop si el padre está expandido. Estilo `Raleway Bold`.
3. **Nivel 3 (Detalle)**: Ej. Personal -> Drivers. Colapsables mediante chevrons laterales.

### Comportamiento por Plataforma
- **Desktop (Sidebar Total Collapse)**: 
  - Sidebar desaparece completamente al colapsar (ancho 0px).
  - Solo el **Sidebar Toggle** permanece visible en el borde izquierdo de la pantalla.
  - Los ítems de Nivel 1 actúan como headers fijos; sus hijos de Nivel 2 son persistentes (no colapsables).
- **Mobile (Navbar Hub)**: 
  - Nivel 1 en `BottomNavigationBar` (Solo Texto Uppercase).
  - Nivel 2 en un `SubNavbar` horizontal scrollable justo debajo del AppBar.
  - Navegación automática: Al tocar "Management", el sistema redirige al usuario directamente a "Personal" (primer hijo).

---

## 5. Patrones de Feedback y Badges

- **Diagonal Ribbon ("SOON")**: Indica características planificadas. Color: Rojo vibrante, texto blanco.
- **Status Indicator ("CURRENT")**: Fondo sólido `Primary`, texto negro.
- **Checkmark Completion**: Ícono `check_circle` en color `Success`.
- **Driver Style Badges**:
  - **Defensive**: Azul (`shield`).
  - **Normal**: Verde (`directions_car`).
  - **Offensive**: Naranja (`flash_on`).
  - **Risky**: Rojo (`warning`).

---

## 6. Layout

- **MaxWidth (Desktop Content)**: 1400px.
- **Padding Lateral**: 20px.
- **Spacing vertical**: Sistema de 8px (8, 16, 24, 32).
- **Responsive Shell**: Breakpoint de `600px`.
