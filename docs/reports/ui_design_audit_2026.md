# UI Design Audit 2026 — FTG Racing Manager V3
**Fecha:** 2026-02-28  
**Método:** Extracción literal línea-por-línea de cada archivo `.dart` en `lib/`  
**Regla:** Ningún diseño inventado. Solo código existente.

---

## 1. Theme Global (`lib/theme/app_theme.dart`)

| Token | Valor | Uso |
|:---|:---|:---|
| `appBackground` | `Color(0xFF15151E)` | `scaffoldBackgroundColor` |
| `textNormal` | `Color(0xFFFFFFFF)` | `onSurface`, texto general |
| `accentHighlight` | `Color(0xFFC1C4F4)` | Íconos, badges, highlights, `secondary` |
| `primaryButton` | `Color(0xFF3A40B1)` | `primary` color scheme, botones |
| `secondaryButton` | `Color(0xFF292A33)` | Card background, outlined buttons |
| `buttonHover` | `Color(0xFF424686)` | Hover state para botones |
| `error` | `Color(0xFFEF5350)` | Error states |

### Tipografía Theme
| Estilo | Fuente | Peso | Uso |
|:---|:---|:---|:---|
| `headlineMedium` | `GoogleFonts.poppins` | `w900` | Títulos principales |
| `headlineSmall` | `GoogleFonts.poppins` | `w900` | Subtítulos |
| `titleLarge` | `GoogleFonts.poppins` | `w900` | Títulos de sección |
| `bodyLarge` | `GoogleFonts.raleway` | normal, 16px | Cuerpo principal |
| `bodyMedium` | `GoogleFonts.raleway` | normal, 14px, alpha 0.8 | Cuerpo secundario |
| `labelLarge` | `GoogleFonts.raleway` | bold | Labels |

### AppBar Theme
- **Background:** `appBackground`
- **Elevation:** `0`
- **Center title:** `true`
- **Title style:** `GoogleFonts.poppins`, 20px, `w900`, letterSpacing 1.5

### Card Theme
- **Color:** `secondaryButton` (`0xFF292A33`)
- **Elevation:** `2`
- **Shadow:** `black` alpha 0.3
- **Border radius:** `12`

### ElevatedButton Theme
- **Background:** `primaryButton`, hover → `buttonHover`
- **Foreground:** `textNormal`
- **Elevation:** `0`
- **Font:** `GoogleFonts.raleway` bold
- **Shape:** `StadiumBorder`
- **Padding:** `horizontal: 24, vertical: 12`

### OutlinedButton Theme
- **Foreground:** `textNormal`
- **Background:** `secondaryButton`, hover → `buttonHover`
- **Border:** `textNormal` alpha 0.1, width 1
- **Shape:** `StadiumBorder`

### BottomNavigationBar Theme
- **Background:** `secondaryButton`
- **Selected color:** `accentHighlight`
- **Unselected color:** `textNormal` alpha 0.5
- **Elevation:** `8`
- **Font selected:** `GoogleFonts.raleway` bold, 12px
- **Font unselected:** `GoogleFonts.raleway` 12px

### TabBar Theme
- **Indicator:** `UnderlineTabIndicator`, color `accentHighlight`, width 2
- **Label font:** `GoogleFonts.poppins` bold, 12px, letterSpacing 1.1
- **Label color:** `accentHighlight`
- **Unselected color:** `textNormal` alpha 0.4

---

## 2. OnyxTable (`lib/widgets/common/onyx_table.dart`)

**Tipo:** Widget reutilizable con header fijo y rows scrolleables.

### Header
- **Padding:** `vertical: 12, horizontal: 20`
- **Background:** `Colors.white` alpha 0.03
- **Border bottom:** `Colors.white` alpha 0.05
- **Font:** `GoogleFonts.poppins`, `w700`, 10px, letterSpacing 1.1, color white alpha 0.4
- **Text transform:** `.toUpperCase()`

### Row
- **Padding:** `vertical: 14, horizontal: 20`
- **Border bottom:** `Colors.white` alpha 0.05, width 0.5
- **Alternate:** par → transparent, impar → white alpha 0.01
- **Hover:** `Color(0xFF00C853)` alpha 0.05
- **Highlighted:** `Color(0xFF00C853)` alpha 0.1 + border-left 4px `Color(0xFF00C853)`
- **Font normal:** `GoogleFonts.inter`, 12px, `w500`, white alpha 0.9
- **Font highlighted:** `GoogleFonts.inter`, 12px, `w900`, `Color(0xFF00C853)`
- **Font position column:** white alpha 0.5

**Usado en:** `StandingsScreen`, `TransferMarketScreen`, `FinancesScreen`, `GarageScreen`

---

## 3. OnyxSkeleton (`lib/widgets/common/onyx_skeleton.dart`)

**Tipo:** Placeholder de carga animado (shimmer).

- **Color animado:** `Colors.white` alpha oscila entre `0.05` y `0.12`
- **Duración ciclo:** 1500ms, curva `Curves.easeInOut`, loop infinito (reverse)
- **Border radius:** configurable, default `8`

**Usado en:** Estados de carga de tablas y tarjetas.

---

## 4. NewBadgeWidget (`lib/widgets/common/new_badge.dart`)

**Tipo:** Badge "NEW" con animación pulsante.

- **Background:** `Colors.amber`
- **Border radius:** `12`
- **Shadow:** `Colors.amber` alpha 0.4, blur 4, offset (0,2)
- **Offset posición:** `Offset(8, -8)` respecto al hijo
- **Animación:** `FadeTransition` del ícono `Icons.star`, Tween 0.5→1.0, 1s, loop reverse
- **Texto:** "NEW", 8px, blanco, bold, letterSpacing 0.5
- **Ícono:** `Icons.star`, blanco, 10px
- **Lógica:** Visible solo si `createdAt` < 7 días, o `forceShow=true`

**Usado en:** Navegación sidebar, tarjetas de contenido nuevo.

---

## 5. InstructionCard (`lib/widgets/common/instruction_card.dart`)

**Tipo:** Tarjeta informativa con ícono y descripción.

- **Padding:** `24`
- **Gradient:** `primary` alpha 0.1 → `Color(0xFF0A0A0A)` (topLeft→bottomRight)
- **Border:** `primary` alpha 0.3, width 1
- **Border radius:** `12`
- **Shadow:** `black` alpha 0.4, blur 15, offset (0,8)
- **Título font:** `GoogleFonts.poppins`, 20px, `w900`, letterSpacing 1.5, color primary alpha 0.9
- **Ícono:** 32px, color `primary`
- **Descripción font:** `bodyMedium`, height 1.5, `onSurface` alpha 0.8

**Usado en:** `HQScreen`, pantallas vacías, instrucciones iniciales.

---

## 6. DriverStars (`lib/widgets/common/driver_stars.dart`)

**Tipo:** 5 estrellas para rating de pilotos.

| Estado | Color | Ícono |
|:---|:---|:---|
| Actual (filled) | `Colors.blueAccent` | `Icons.star_rounded` |
| Potencial (max) | `Colors.amber` alpha 0.5 | `Icons.star_rounded` |
| Vacía | `Colors.white` alpha 0.2 | `Icons.star_outline_rounded` |

- **Tamaño default:** 14px

**Usado en:** `DriverCard`, `TransferMarketDriverCard`, `DriversScreen`.

---

## 7. DynamicLoadingIndicator (`lib/widgets/common/dynamic_loading_indicator.dart`)

**Tipo:** Indicador de carga con frases rotativas.

- **Spinner:** `CircularProgressIndicator`, color `Color(0xFF00C853)`
- **Texto font:** `GoogleFonts.raleway`, 14px, `Colors.white70`, letterSpacing 1
- **Transición:** `AnimatedSwitcher`, 500ms, `FadeTransition`
- **Rotación frases:** cada 3 segundos

**Usado en:** Pantallas de carga global, splash.

---

## 8. Breadcrumbs (`lib/widgets/common/breadcrumbs.dart`)

**Tipo:** Navegación breadcrumb con hover.

- **Separador:** "/" en `GoogleFonts.raleway`, 12px, white alpha 0.2
- **Link font:** `GoogleFonts.raleway`, 11px, letterSpacing 1.0, `.toUpperCase()`
- **Link activo (last):** blanco, bold
- **Link inactivo:** white alpha 0.5, `w500`
- **Hover:** blanco
- **Cursor:** `SystemMouseCursors.click` si tiene `onTap`

**Usado en:** `DriversScreen`, `PersonalScreen`, sub-navegación.

---

## 9. AppLogo (`lib/widgets/common/app_logo.dart`)

**Tipo:** Logo de marca "FTG / RACING MANAGER".

- **"FTG" font:** `GoogleFonts.montserrat`, `w900`, `size * 0.6`, letterSpacing -1.0, height 1.0
- **"RACING MANAGER" font:** `GoogleFonts.montserrat`, `w600`, `size * 0.18`, letterSpacing 2.5
- **Color:** `theme.colorScheme.onSurface`
- **Default size:** 40

**Usado en:** Sidebar header, Landing screen.

---

## 10. NotificationCard (`lib/widgets/notification_card.dart`)

**Tipo:** Tarjeta de notificación con íconos por tipo.

### Tipos de notificación y colores:
| Tipo | Ícono | Color |
|:---|:---|:---|
| `ALERT` | `Icons.warning_amber_rounded` | `Colors.orangeAccent` |
| `SUCCESS` | `Icons.check_circle_outline_rounded` | `Color(0xFF00C853)` |
| `TEAM` | `Icons.group_outlined` | `theme.colorScheme.secondary` |
| `OFFICE` (RACE_RESULT) | `Icons.emoji_events_outlined` | `Color(0xFFFFD700)` (Gold) |
| `OFFICE` (QUALY_RESULT) | `Icons.timer_outlined` | `Colors.tealAccent` |
| `OFFICE` (other) | `Icons.business_center_outlined` | `Colors.blueGrey` |
| `NEWS` / default | `Icons.newspaper_outlined` | `Colors.blueAccent` |

### Estilos:
- **Container:** `theme.cardTheme.color`, radius 12, shadow black alpha 0.4 blur 8 offset (0,4)
- **Border no leído:** `iconColor` alpha 0.2
- **Ícono container:** circular, `iconColor` alpha 0.1 background
- **Tipo label:** `GoogleFonts.poppins`, 10px, bold, `iconColor`, letterSpacing 1.2
- **Título:** `GoogleFonts.poppins`, 14px, bold
- **Timestamp:** 10px, `onSurface` alpha 0.4
- **Mensaje:** 13px, `onSurface` alpha 0.7, height 1.4

**Usado en:** Dashboard (lista de notificaciones), panel de notificaciones.

---

## 11. PressNewsCard (`lib/widgets/press_news_card.dart`)

**Tipo:** Tarjeta estilo periódico para noticias de liga.

### Card exterior:
- **Background:** `Color(0xFFF4F1EA)` (off-white newspaper)
- **Border:** `black` alpha 0.2, width 1
- **Border radius:** `4`
- **Shadow:** `black` alpha 0.1, blur 4, offset (2,2)

### Header "MOTORSPORT DAILY":
- **Font:** `GoogleFonts.playfairDisplay`, 10px, bold, letterSpacing 1.5, `black87`

### Tipo/Fecha row:
- **Tipo font:** `GoogleFonts.oswald`, 9px, `w600`, `black54`, letterSpacing 0.5
- **Fecha font:** `fontFamily: 'Courier'`, 9px, `black54`

### Título noticia:
- **Font:** `GoogleFonts.merriweather`, 14px, `w900`, `black87`, height 1.2

### Botón "Read full article":
- **Border:** `black87`, radius 2
- **Font:** `GoogleFonts.oswald`, 10px, bold, `black87`

### Dialog expandido:
- **Background dialog:** `Color(0xFFF4F1EA)`
- **Título dialog font:** `GoogleFonts.merriweather`, 22px, `w900`
- **Contenido font:** `GoogleFonts.ptSerif`, 14px, `black87`, height 1.6
- **Imagen manager_join:** Asset `news/newManager.png`, 220px height, border black87 2px

**Usado en:** Dashboard (news feed), modal de artículo.

---

## 12. CarSchematicWidget (`lib/widgets/car_schematic_widget.dart`)

**Tipo:** Panel de stats del coche (niveles de mejora).

### Container:
- **Width:** 180px default
- **Padding:** 16
- **Background:** `cardTheme.color` alpha 0.5
- **Border radius:** 12
- **Border:** `Colors.white10`

### Stats con colores hardcodeados:
| Stat | Color barra |
|:---|:---|
| Power | `Colors.orangeAccent` |
| Aero | `Colors.cyanAccent` |
| Handling | `Colors.purpleAccent` |
| Reliability | `Colors.greenAccent` |

### Stat rows:
- **Label:** 10px, `Colors.white60`, `w500`
- **Value:** 11px, bold, color del stat
- **Progress bar:** `LinearProgressIndicator`, height 2px, background white alpha 0.05, barra color alpha 0.8

**Usado en:** `EngineeringScreen`, `GarageScreen`.

---

## 13. CarSelector (`lib/widgets/car_selector.dart`)

**Tipo:** Selector de livery con sprite sheet.

### Arrow buttons:
- **Shape:** circular, 40x40px
- **Background:** white alpha 0.05
- **Border:** `accentColor` (secondary) alpha 0.2
- **Ícono:** chevron, `accentColor`, 24px

### Index label:
- **Font:** `GoogleFonts.poppins`, 11px, `w700`, `Colors.white38`, letterSpacing 1.2

**Usado en:** `CreateManagerScreen` (onboarding).

---

## 14. FuelInput (`lib/widgets/fuel_input.dart`)

**Tipo:** Input numérico compacto para combustible.

- **Width:** 65, Height: 28
- **Background:** white alpha 0.05
- **Border radius:** 12
- **Border:** white alpha 0.1
- **Texto input:** 11px, bold, `Colors.orange`
- **Sufijo "L":** 8px, `Colors.white24`, bold

**Usado en:** `RaceStrategyScreen` (stint fuel input).

---

## 15. ResponsiveShell (`lib/widgets/responsive_shell.dart`)

**Tipo:** Layout responsive con NavigationRail (desktop ≥800px) y BottomNavigationBar (mobile).

### Desktop NavigationRail:
- **Label type:** `NavigationRailLabelType.all`
- **Group alignment:** `-0.9`
- **Min width:** 80
- **Divider:** `dividerColor` alpha 0.1, thickness 1
- **Content max width:** 1600px

### Mobile Bottom Navigation:
- **Border top:** `dividerColor` alpha 0.1, width 1

### Ítems de navegación:
| Ítem | Ícono outline | Ícono selected |
|:---|:---|:---|
| HQ | `dashboard_rounded` | `dashboard` |
| Office | `business_center_outlined` | `business_center` |
| Garage | `build_circle_outlined` | `build_circle` |
| Season | `emoji_events_outlined` | `emoji_events` |
| Market | `groups_outlined` | `groups` |

**Usado en:** Layout principal de la aplicación.

---

## 16. Dashboard Widgets (`lib/screens/home/dashboard_widgets.dart`)

### 16.1 TeamHeader
- **Avatar:** 60x60, circular, `teamColor` alpha 0.2, border `teamColor` 2px
- **Ícono:** `Icons.shield`, `teamColor`, 30px
- **Nombre manager:** `bodyMedium` theme
- **Nombre equipo:** `headlineMedium`, `w900`, letterSpacing 1.0, `.toUpperCase()`

### 16.2 StatusCard
- **Background:** `cardTheme.color`
- **Border radius:** 12
- **Gradient:** `mainColor` alpha 0.1 → transparent (topLeft→bottomRight)
- **`mainColor`:** Race weekend → `error`, normal → `primaryButton`
- **Status text:** `mainColor`, bold, letterSpacing 2.0, 12px, `.toUpperCase()`
- **Time text:** `mainColor`, 28px, `w900`
- **Ícono:** `Icons.flag` (race) o `Icons.factory` (normal)

### 16.3 FinanceCard
| Elemento | Estilo |
|:---|:---|
| Container bg | `Color(0xFF121212)`, gradient `#1E1E1E`→`#0A0A0A` |
| Border | white alpha 0.1 |
| Border radius | 12 |
| Shadow | black alpha 0.3, blur 15, offset (0,8) |
| Icon container | `color` alpha 0.1 bg, radius 12, border `color` alpha 0.3 |
| Ícono | `Icons.account_balance_wallet`, 20px |
| Label "TEAM BUDGET" | 9px, bold, letterSpacing 1.2, white alpha 0.4 |
| Valor "$X.X M" | `fontFamily: 'monospace'`, 18px, `w900`, `Color(0xFFFFD700)` Gold |
| SURPLUS/DEFICIT | 9px, `w900`, letterSpacing 1.0, verde/rojo |
| Estimado | 10px, bold, white alpha 0.5 |

### 16.4 NewsItemCard
- **Width:** 280, margin right 16
- **Padding:** 16
- **Background:** `cardTheme.color`
- **Border radius:** 12
- **Source:** `secondary` color, 10px, bold, `.toUpperCase()`
- **Headline:** `bodyMedium`, `w600`, maxLines 2

### 16.5 UpcomingCircuitCard
- **Height:** 180
- **Gradient:** `#15151E` → `#292A33` (bottomLeft→topRight)
- **Border radius:** 12
- **Label "NEXT GP":** `orangeAccent`, letterSpacing 1.2, bold
- **Country badge:** white24 bg, radius 12, blanco bold
- **Circuit name:** `headlineMedium`, `w900`, blanco
- **Ícono:** `Icons.route`, white70, 20px

### 16.6 RaceStatusHero
**Widget complejo con countdown en tiempo real.**

| Estado | Color | Botón |
|:---|:---|:---|
| `practice` | `Color(0xFF00C853)` | WEEKEND SETUP |
| `qualifying` | `Color(0xFFFFB800)` | VIEW QUALIFYING |
| `raceStrategy` | `Color(0xFFFF6D00)` | SET RACE STRATEGY |
| `race` | `Color(0xFFFF5252)` | GO TO RACE |
| `postRace` | `Color(0xFF9E9E9E)` | VIEW RESULTS |

**Container:**
- Gradient: `#1E1E1E` → `#0A0A0A`
- Border: white alpha 0.1
- Shadow: black alpha 0.5, blur 20, offset (0,10)
- Border radius: 12

**Background icon clima:** 200px, opacity 0.05, right -20, top -20

**Status badge:** padding h12 v6, `statusColor` alpha 0.1 bg, border `statusColor`, radius 12, font bold letterSpacing 1.5 12px

**Circuit name:** 24px, `w900`, blanco, letterSpacing 1.0

**Countdown label:** 10px, `w900`, white alpha 0.5, letterSpacing 1.5

**Time blocks:**
- Background: white alpha 0.05, radius 8
- Valor: `fontFamily: 'monospace'`, 20px, `w900`, blanco
- Label: 8px, bold, letterSpacing 1.0

**Separador ":":** 18px, bold, `onSurface` alpha 0.3

**Fecha:** `Icons.calendar_today` + texto 10px, white alpha 0.4, `w600`

**Live indicator:**
- Blinking dot: `FadeTransition`, 1s loop, `Color(0xFFFF5252)`, `Icons.fiber_manual_record` 12px
- Off: `Icons.do_not_disturb_on_total_silence`, white alpha 0.2
- Texto ON LIVE: 10px, `w900`, letterSpacing 1.0, `Color(0xFFFF5252)`
- Badge bg: white alpha 0.03, border red alpha 0.2, radius 12

**Action button (Onyx CTA):**
- Gradient: `#2A2A2A` → `#000000`
- Border: `Color(0xFF00C853)` alpha 0.3
- Shadow: black alpha 0.3, blur 8, offset (0,4)
- Texto: `w900`, letterSpacing 1.2, 13px, `Color(0xFF00C853)`
- Radius: 100 (stadium)

**Circuit Intel:**
- Header: 9px, bold, letterSpacing 0.8, white alpha 0.4
- Laps value: `fontFamily: 'monospace'`, 14px, `w900`, `Color(0xFFFFD700)` Gold
- Weather icons: day letter + emoji
- Compact chips: white alpha 0.05 bg, white alpha 0.1 border, radius 12, 8px bold white alpha 0.7

### 16.7 PreparationChecklist
- **Container:** mismos estilos que FinanceCard (gradient #1E1E1E→#0A0A0A, border, shadow)
- **Título:** white alpha 0.4, 9px, bold, letterSpacing 1.5
- **Item labels:** 11px, `w900`, blanco, letterSpacing 0.5, `.toUpperCase()`
- **Status badge completo:** `Color(0xFF00C853)` alpha 0.1 bg, border alpha 0.5, radius 12
- **Status badge pendiente:** `Color(0xFFFFAB00)` alpha 0.1 bg
- **Ícono completo:** `Icons.check`, 10px
- **Ícono pendiente:** `Icons.priority_high`, 10px
- **Status texto:** `fontFamily: 'monospace'`, 10px, `w900`

**Usado en:** Dashboard screen.

---

## 17. _PersonalCard con COMING SOON (`lib/screens/management/personal_screen.dart`)

**Tipo:** Grid de tarjetas (GridView.count) para módulos de personal.

### PersonalCard:
- **Gradient:** `#1E1E1E` → `#0A0A0A`
- **Border:** white alpha 0.1, width 1
- **Border radius:** 12
- **Shadow:** black alpha 0.4, blur 12, offset (0,6)
- **Ícono:** 34px, enabled → `secondary`, disabled → `Colors.grey` alpha 0.5
- **Título font:** `GoogleFonts.poppins`, `w900`, 14px, letterSpacing 0.5, `.toUpperCase()`
- **Título enabled:** blanco, disabled → grey

### COMING SOON Ribbon (when `!isEnabled`):
- **Posición:** `top: 10, right: -25`
- **Rotación:** `0.785 rad` (45°)
- **Width:** 100
- **Background:** `Colors.redAccent` alpha 0.8
- **Padding:** symmetric vertical 4
- **Texto:** 7px, `w900`, blanco, letterSpacing 1.0
- **Texto (l10n):** `comingSoonBanner`

**Tarjetas disponibles:**
| Módulo | Ícono | Habilitado |
|:---|:---|:---|
| Drivers | `Icons.people_alt_rounded` | ✅ Sí |
| Fitness Trainer | `Icons.fitness_center_rounded` | ❌ |
| Chief Engineer | `Icons.engineering_rounded` | ❌ |
| HR Manager | `Icons.badge_rounded` | ❌ |
| Marketing Manager | `Icons.campaign_rounded` | ❌ |

**Usado en:** Management → Personal.

---

## 18. Colores Hardcodeados (Fuera de Tokens del Theme)

Estos colores aparecen hardcodeados directamente en widgets, no pasan por `AppTheme`:

| Color | Hex | Nombre | Ubicaciones |
|:---|:---|:---|:---|
| Deep Charcoal | `0xFF121216` | Card bg | `DriverCard`, `TransferMarketDriverCard` |
| Deep Black | `0xFF121212` | Container bg | `FinanceCard`, `PreparationChecklist` |
| Card Gradient Start | `0xFF1E1E1E` | Card top-left | Múltiples cards |
| Card Gradient End | `0xFF0A0A0A` | Card bottom-right | Múltiples cards |
| Success Green | `0xFF00C853` | Acciones positivas | `OnyxTable`, `RaceStatusHero`, `NotificationCard` |
| Neon Green | `0xFF00E676` | Acentos élite | (theme) |
| Gold | `0xFFFFD700` | Valores monetarios, race result | `FinanceCard`, `NotificationCard` |
| Amber | `0xFFFFC107` | NewBadge, star potential | `NewBadgeWidget`, `DriverStars` |
| Soft Red | `0xFFFF5252` | Live indicator, race status | `RaceStatusHero`, blinking dot |
| Qualifying Yellow | `0xFFFFB800` | Qualifying status | `RaceStatusHero` |
| Strategy Orange | `0xFFFF6D00` | Race strategy status | `RaceStatusHero` |
| Warning Amber | `0xFFFFAB00` | Pending checklist | `PreparationChecklist` |
| Newspaper Paper | `0xFFF4F1EA` | PressNewsCard bg | `PressNewsCard` |
| Grey Post-Race | `0xFF9E9E9E` | Post-race status | `RaceStatusHero` |

---

## 19. Fuentes Utilizadas (Google Fonts)

| Fuente | Uso principal |
|:---|:---|
| `Poppins` | Titles, headings, labels, AppBar, badges (w900 dominante) |
| `Raleway` | Body text, buttons, breadcrumbs, loading phrases |
| `Montserrat` | Logo "FTG", brand typography (w900, w600) |
| `Inter` | Onyx table data cells |
| `Merriweather` | PressNewsCard headlines (newspaper serif) |
| `Playfair Display` | "MOTORSPORT DAILY" header |
| `Oswald` | PressNewsCard type labels, article button |
| `PT Serif` | PressNewsCard dialog body text |
| `monospace` (system) | Financial values, countdown numbers, checklist status |
| `Courier` (system) | PressNewsCard timestamps |

---

## 20. Animaciones Existentes

| Widget | Tipo | Duración | Detalle |
|:---|:---|:---|:---|
| `OnyxSkeleton` | Shimmer alpha | 1500ms loop | Alpha 0.05→0.12 |
| `NewBadgeWidget` | Pulse fade | 1000ms loop | Opacity 0.5→1.0 del ícono star |
| `DynamicLoadingIndicator` | Text switcher | 500ms fade | Frases rotan cada 3s |
| `DriverCard` | Flip 3D | 600ms | rotateY 0→π, Curves.easeInOut |
| `RaceStatusHero` | Blinking dot | 1000ms loop | FadeTransition del dot rojo |
| `RaceStatusHero` | Timer tick | 1s interval | Countdown en tiempo real |

---

## 21. Resumen de Archivos y Widgets por Módulo

### `lib/widgets/common/` (8 widgets reutilizables)
| Archivo | Widget | Categoría |
|:---|:---|:---|
| `onyx_table.dart` | `OnyxTable` | Data display |
| `onyx_skeleton.dart` | `OnyxSkeleton` | Loading state |
| `new_badge.dart` | `NewBadgeWidget` | Indicator |
| `instruction_card.dart` | `InstructionCard` | Info card |
| `driver_stars.dart` | `DriverStars` | Rating |
| `dynamic_loading_indicator.dart` | `DynamicLoadingIndicator` | Loading |
| `breadcrumbs.dart` | `Breadcrumbs` | Navigation |
| `app_logo.dart` | `AppLogo` | Branding |

### `lib/widgets/` (7 widgets de nivel superior)
| Archivo | Widget | Categoría |
|:---|:---|:---|
| `notification_card.dart` | `NotificationCard` | Notification |
| `press_news_card.dart` | `PressNewsCard` | News card |
| `car_schematic_widget.dart` | `CarSchematicWidget` | Stats display |
| `car_selector.dart` | `CarSelector` | Livery picker |
| `fuel_input.dart` | `FuelInput` | Input control |
| `responsive_shell.dart` | `ResponsiveMainScaffold` | Layout |
| `auth_wrapper.dart` | `AuthWrapper` | Auth gate |

### `lib/screens/home/` (Dashboard)
| Archivo | Widget(s) |
|:---|:---|
| `dashboard_widgets.dart` | `TeamHeader`, `StatusCard`, `FinanceCard`, `NewsItemCard`, `UpcomingCircuitCard`, `RaceStatusHero`, `PreparationChecklist` |

### `lib/screens/management/`
| Archivo | Widget(s) |
|:---|:---|
| `personal_screen.dart` | `PersonalScreen`, `_PersonalCard` (con COMING SOON ribbon) |

### `lib/screens/drivers/widgets/`
| Archivo | Widget(s) |
|:---|:---|
| `driver_card.dart` | `DriverCard`, `RadarChartPainter`, `GridPainter` |

### `lib/screens/race/`
| Archivo | Widget(s) |
|:---|:---|
| `garage_screen.dart` | `GarageScreen` (Practice/Qualifying/Race tabs), `_buildDriverSelector`, `_buildCircuitIntel`, `_buildPitBoard`, `_buildQualifyingPitBoard`, `_buildDriverStyleCard`, `_buildSetupCard`, `_buildFitnessBar`, `_buildSmallTyreIcon`, `_buildCopyBadge`, `_buildLastLapCard`, `_buildLapHistoryCard`, `_buildFeedbackCard` |
| `race_strategy_screen.dart` | `RaceStrategyScreen`, `_buildSlider`, `_buildStyleSelector`, pit stop rows |

---

## 22. DriverCard (`lib/screens/drivers/widgets/driver_card.dart`)

**Tipo:** Tarjeta de piloto con animación flip 3D (front/back), radar chart, skills, career stats.

### Card Container (Front & Back):
- **Margin:** vertical 12, horizontal 16
- **Background:** `Color(0xFF121216)` (Deep Charcoal)
- **Border radius:** `16`
- **Border:** white alpha 0.05, width 1
- **Shadow:** black alpha 0.5, blur 20, offset (0,10)

### Background Grid Pattern (`GridPainter`):
- **Lines:** white alpha 0.03, strokeWidth 0.5
- **Step:** 30px (both horizontal and vertical)
- Fills entire card behind content via `Positioned.fill` + `ClipRRect`

### Left Accent Border (Front view):
- **Width:** 4px
- **Color:** `Color(0xFF00E676)` (Neon Green)
- **Position:** left 0, top 24, bottom 24
- **Shape:** `BorderRadius.horizontal(right: 4)`
- **Shadow:** neon green alpha 0.3, blur 12, spread 1

### Flip Badge (top center):
- **Background:** `Color(0xFFFF00FF)` alpha 0.1 (Neon Pink)
- **Border:** neon pink alpha 0.5
- **Border radius:** `4`
- **Shadow:** neon pink alpha 0.2, blur 8, spread 1
- **Texto:** "FLIP", `GoogleFonts.montserrat`, `w900`, 10px, letterSpacing 1.5, color neon pink
- **Position:** top 12, centered

### Transfer Market Ribbon (when `isTransferListed`):
- **Position:** top 12, left -30
- **Rotation:** `-0.785398 rad` (-45°)
- **Width:** 150
- **Background:** `Colors.amber`
- **Shadow:** black45, blur 4, offset (0,2)
- **Texto:** "TRANSFER MARKET", black, bold, 10px, letterSpacing 1.0

### Level Badge:
| Stars | Texto | Color |
|:---|:---|:---|
| ≥5 | "ÉLITE" | `Color(0xFF00E676)` |
| ≥4 | "PRO" | `Color(0xFFFFEE58)` |
| <4 | "AMATEUR" | `Color(0xFFA0AEC0)` |

- **Background:** `levelColor` alpha 0.15
- **Border:** `levelColor` alpha 0.5
- **Border radius:** `6`
- **Font:** `GoogleFonts.montserrat`, `w900`, 11px, letterSpacing 1.5

### Portrait:
- **Size:** 80x80, circular
- **Border:** `levelColor` alpha 0.5, width 3
- **Shadow glow:** `levelColor` alpha 0.2, blur 20, spread 2

### Driver Name:
- **Font:** `GoogleFonts.montserrat`, `w900`, 22px, letterSpacing -0.5, blanco, `.toUpperCase()`

### Age:
- **Font:** `GoogleFonts.montserrat`, `w600`, 14px, `Color(0xFFFFC107)` (amber)

### Contract Details Section:
- **Container:** white alpha 0.02, radius 12, border white alpha 0.05
- **Title:** `GoogleFonts.montserrat`, bold, 11px, `Color(0xFFA0AEC0)`, letterSpacing 1.2
- **Market value label:** `GoogleFonts.montserrat`, bold, 10px, `Color(0xFFA0AEC0)`, letterSpacing 0.5
- **Market value amount:** `GoogleFonts.robotoMono`, `w900`, 20px, blanco

### Stat Indicators (skills section, grid 2 columns):
- **Label font:** `GoogleFonts.montserrat`, bold, 8px, `Color(0xFFA0AEC0)`, letterSpacing 0.2
- **Value font:** `GoogleFonts.robotoMono`, `w900`, 13px

| Rango (displayValue /20) | Color |
|:---|:---|
| ≥15 (High) | `Color(0xFF00E676)` |
| ≥10 (Medium) | `Color(0xFFFFEE58)` |
| <10 (Low) | `Color(0xFFFF5252)` |

- **Progress bar:** 4px height, bg white alpha 0.05, radius 2
- **Glow en ≥15:** `boxShadow` color alpha 0.5, blur 6, spread 1

### Radar Chart (`RadarChartPainter`):
- **Size:** 200x200
- **Grid:** 5 concentric rings, white alpha 0.1, stroke 1
- **Axis lines:** same paint
- **Data fill:** `Color(0xFF00E676)` alpha 0.4
- **Data border:** `Color(0xFF00E676)`, stroke 2
- **Glow (any stat≥75):** `MaskFilter.blur(BlurStyle.outer, 4)`
- **Data points:** circles radius 3, solid `Color(0xFF00E676)`

### Career Stats Summary (Back view):
- **Container:** white alpha 0.02, radius 12, border white alpha 0.05
- **Title:** `GoogleFonts.montserrat`, bold, `Color(0xFFA0AEC0)`, 11px, letterSpacing 1.2
- **Stat circles:** icono en círculo `Color(0xFF15151E)` bg, border secondary alpha 0.1
- **Íconos:** `emoji_events_rounded` (títulos), `military_tech_rounded` (wins), `star_rounded` (podiums), `flag_rounded` (races)
- **Value font:** 16px, `w900`, letterSpacing -0.5
- **Label font:** `labelSmall`, white54, 8px, bold, letterSpacing 0.5

### Status Title Badge (Back view):
- **Gradient:** `Color(0xFF00E676)` alpha 0.15 → alpha 0.05
- **Border:** neon green alpha 0.3, radius 8
- **Ícono:** `Icons.shield_rounded`, 16px, neon green
- **Font:** `GoogleFonts.montserrat`, `w900`, 12px, letterSpacing 1.5

### Highest Bid Badge (when transfer listed):
- **Background:** `Colors.amber` alpha 0.1
- **Border:** amber alpha 0.3, radius 8
- **"Highest Bid:" label:** 11px, amber, bold
- **"YOU HAVE THE HIGHEST BID":** 9px, `Colors.greenAccent`, `w900`

### Cancel Bid Button:
- **Background:** `Colors.red` alpha 0.2
- **Border:** red alpha 0.5, radius 4
- **Texto:** "CANCEL BID", 9px, `Colors.redAccent`, bold

### Action Buttons (bottom):
- **"Transfer Market" FilledButton:** bg `Color(0xFF00C853)`, white, `GoogleFonts.montserrat` 11px bold, radius 100, hover glow blur 12
- **"RENEW CONTRACT" FilledButton:** theme primary, `GoogleFonts.montserrat` 11px bold, radius 100, hover glow blur 12
- **"CANCEL TRANSFER" OutlinedButton:** `Color(0xFFFF5252)` foreground + side, `GoogleFonts.montserrat` 12px bold, radius 100
- **"PLACE BID" FilledButton:** bg `Color(0xFFFFC107)`, foreground black, `GoogleFonts.montserrat` 12px `w900` letterSpacing 1.0, ícono `Icons.gavel` 16px

### Potential Stars (`_buildPotentialStars`):
- **5 estrellas** generadas con `List.generate(5, ...)`
- **Star size:** 24px, padding-right 6

| Tipo | Color | Ícono | Glow |
|:---|:---|:---|:---|
| Current | `Color(0xFF00B0FF)` (Neon Electric Blue) | `star_rounded` | blur 8, spread 1, solid `#00B0FF` |
| Potential (no current) | `Color(0xFFFFD700)` (Golden Yellow) | `star_rounded` | blur 4, alpha 0.4, `#FFD700` |
| Empty | `Colors.white10` | `star_outline_rounded` | none |

### Contract Row (`_buildContractRow`):
- **Label:** `Color(0xFFA0AEC0)`, 13px
- **Value:** white (o `valueColor`), 13px, `GoogleFonts.robotoMono`, bold
- **Padding:** vertical 4

### TinyTable (`_buildTinyTable`) — componente reutilizable:
- **Title:** `GoogleFonts.montserrat`, 11px, bold, `Color(0xFFA0AEC0)`, letterSpacing 1.2
- **Header row:** padding v8, border bottom white alpha 0.1 width 1
- **Header text:** `labelSmall`, `secondary` alpha 0.7, bold, 9px
- **Data row padding:** vertical 10
- **Zebra striping:** odd rows → white alpha 0.05
- **Data text:** `GoogleFonts.robotoMono`, 11px, white, first column bold
- **Empty state:** `bodySmall`, `secondary` alpha 0.5, italic

### Championship Form Table (`_buildChampionshipForm`):
- **Usa `_buildTinyTable`**
- **Title:** "CHAMPIONSHIP FORM" (localized)
- **Headers:** EVENT (flex 3) | Q (flex 1) | R (flex 1) | P (flex 1)
- **Alignments:** left, center, center, center
- **Max rows:** 5
- **Data:** vacío actualmente (placeholder para implementación futura)

### Career History Table (`_buildCareerHistory`):
- **Usa `_buildTinyTable`**
- **Title:** "CAREER HISTORY" (localized)
- **Headers:** YEAR (flex 1) | TEAM (flex 2) | SERIES (flex 2) | R (flex 1) | P (flex 1) | W (flex 1)
- **Alignments:** all center
- **Badge columns:** [1, 2] (team y series) → usa `_buildTeamBadgeOverlay`
- **Max rows:** 5
- **Data:** generado con `_generateStableHistory` (distribución proporcional de stats en 5 años)

### Team Badge Overlay (`_buildTeamBadgeOverlay`):
- **Padding:** h6 v2
- **Background:** white alpha 0.05, radius 4
- **Border:** white alpha 0.1
- **Font:** `GoogleFonts.montserrat`, 8px, bold, `Color(0xFFA0AEC0)`

**Animación:** Flip 3D, 600ms, `Curves.easeInOut`, `rotateY` 0→π

**Usado en:** `DriversScreen`, `TransferMarketScreen` modal.

---

## 29. Transfer Market Screen (`lib/screens/market/transfer_market_screen.dart`)

**Tipo:** Pantalla de mercado de transferencias con tabla OnyxTable, countdown, modales de bid. 641 líneas.

### Market Closed State:
- **Ícono:** `Icons.lock_clock`, 64px, `theme.colorScheme.error`
- **Título:** "Transfer Market is Closed", `headlineSmall`
- **Subtítulo:** texto normal default

### Driver Table (usa OnyxTable):
- **Columns:** Driver (flex 4) | Age (flex 1) | Potential (flex 3) | Market Value (flex 2) | Highest Bid (flex 2) | Time Left (flex 2) | Action (flex 2)

### Table Row (`_buildRow`):
- **Driver cell:** `CircleAvatar` radius 12 + nombre 13px bold, underline, `decorationColor: Colors.white24`, click → `_showDriverDetail`
- **Age:** 13px
- **Potential:** `DriverStars` widget
- **Market Value:** 13px, `Colors.white70`
- **Highest Bid:** 13px, bold, color verde si `isMyBid`, amber sino
- **Time Left:** `_MarketCountdown` widget
- **Action (otro equipo):** FilledButton `#00C853`, white, radius 100, padding h12, minSize (60,32), ícono `Icons.gavel` 14px + "Bid" 12px
- **Action (propio):** "Your Driver", grey, 12px

### Skeleton Table:
- **Mismo OnyxTable** con 8 filas de `OnyxSkeleton` (height 20, último con borderRadius 100, width 60, height 32)

### Pagination Controls:
- **Centered Row:** `IconButton chevron_left` | "Page X" bold white | `IconButton chevron_right`
- **Padding:** vertical 16

### Market Countdown (`_MarketCountdown`):
- **Timer:** `Timer.periodic` 1 segundo
- **Format:** `HHh MMm SSs`
- **Expired text:** "Resolving...", `Colors.redAccent`, 13px
- **Active text:** `Colors.white70`, 13px

### Bid Modal (`_showBidModal`):
- **Tipo:** `AlertDialog` con `StatefulBuilder`
- **Title:** "Place Transfer Bid"
- **Content:** nombre piloto + "Current Highest Bid: $X"
- **Bid controls:** `IconButton remove_circle` (red) | amount 20px bold | `IconButton add_circle` (green)
- **Increment:** ±$100,000
- **Min bid:** marketValue (si no hay bid) o `currentHighestBid + 50000`
- **Actions:** "Cancel" TextButton + `_BidButton`

### Driver Detail Dialog:
- **Background:** `Colors.transparent`, elevation 0
- **Inset padding:** h20 v24
- **Width:** `min(screenWidth * 0.85, 1200)`
- **Uses:** `StreamBuilder<DocumentSnapshot>` para live updates
- **Content:** `TransferMarketDriverCard`

---

## 30. TransferMarketDriverCard (`lib/screens/market/widgets/transfer_market_driver_card.dart`)

**Tipo:** Card detallada del piloto en el mercado de transferencias. 1086 líneas. Distinta a `DriverCard` de `DriversScreen`.

### Diferencias con DriverCard (§22):
- No tiene flip animation
- Radar chart más grande: 300x300 (vs 200x200)
- Stat indicator labels: `Colors.white70`, 10px (vs `#A0AEC0`, 8px)
- Stat indicator values: 14px (vs 13px)
- Grid ratio: 4.5 (vs 5.0), crossAxisSpacing 24 (vs 12)
- Market value font: 24px (vs 20px)
- Contract title: `Colors.white70` (vs `#A0AEC0`)
- Incluye Morale y Marketability en contract section
- Incluye Termination cost
- Usa tablas `_buildCleanTable` (vs `_buildTinyTable`)

### "TRANSFER MARKET" Badge (Stats section):
- **Background:** `Color(0xFFFFC107)` alpha 0.1
- **Border:** `Color(0xFFFFC107)` alpha 0.3, radius 4
- **Font:** `GoogleFonts.montserrat`, bold, 10px, `Color(0xFFFFC107)`, letterSpacing 0.5

### Clean Table (`_buildCleanTable`) — variante de tabla:
- **Header padding:** h8 v8
- **Header font:** `GoogleFonts.montserrat`, `Colors.white30`, bold, 10px
- **First column aligned left, rest center**
- **Divider:** height 1, `Colors.white10`
- **Row padding:** h8 v10
- **Zebra striping:** even → transparent, odd → white alpha 0.05
- **Row font:** `GoogleFonts.inter`, `Colors.white70`, 11px
- **Empty message:** white24, italic, 12px

### Form Table (Championship Form):
- **Headers:** EVENT (flex 4) | Q | R | P (flex 1 each)
- **Empty message:** "No Data Available Yet"

### History Table (Career History):
- **Headers:** YEAR (flex 1) | TEAM (flex 2) | SERIES (flex 2) | R (flex 1) | P (flex 1) | W (flex 1)
- **Data:** generado con `_generateHistory`

### Table Section wrapper (`_buildTableSection`):
- **Title:** `GoogleFonts.montserrat`, `Colors.white60`, bold, 12px, letterSpacing 1.2
- **Spacing:** 12px below title

### Highest Bidder Confirmation (action buttons):
- **Container:** `Color(0xFF00E676)` alpha 0.1 bg, radius 12, border `#00E676` alpha 0.3
- **Ícono:** `Icons.check_circle_outline`, 20px, `Color(0xFF00E676)`
- **Texto:** "YOU HAVE THE HIGHEST BID", `GoogleFonts.montserrat`, bold, 10px, `Color(0xFF00E676)`

### "WITHDRAW BID" Button:
- **OutlinedButton**, full width, height 48, radius 100
- **Side:** `Color(0xFFFF5252)`
- **Foreground:** `Color(0xFFFF5252)`
- **Font:** `GoogleFonts.montserrat`, bold, 12px
- **Loading:** `CircularProgressIndicator` 20x20, strokeWidth 2, `Color(0xFFFF5252)`

### "PLACE BID" Button (full):
- **FilledButton**, full width, height 54, radius 100
- **Background:** `Color(0xFFFFC107)` (Traffic Yellow)
- **Foreground:** black
- **Elevation:** 0
- **Hover glow:** amber `#FFC107`, blur 15, spread 0, `AnimatedContainer` 200ms
- **Ícono:** `Icons.gavel`, 18px
- **Font:** `GoogleFonts.montserrat`, `w900`, 16px, letterSpacing 1.0

**Usado en:** `TransferMarketScreen._showDriverDetail` modal.

---


## 23. Weekend Setup — GarageScreen (`lib/screens/race/garage_screen.dart`)

**Tipo:** Pantalla principal de setup con 3 tabs (Practice, Qualifying, Race). 5225 líneas.

### Tabs (TabBar principal):
- **Tab bar container:** `appBarTheme.backgroundColor`, border bottom white alpha 0.1
- **Label color:** `theme.primaryColor`
- **Unselected:** `Colors.white24`
- **Indicator weight:** 4px
- **Tabs:** "PRACTICE", "QUALIFYING", "RACE" (`.toUpperCase()`)

### Parc Fermé Badge (AppBar action, cuando `!isPaddockOpen`):
- **Border:** `Colors.redAccent`, radius 12
- **Texto:** 11px, `Colors.redAccent`, bold, `.toUpperCase()`

### 23.1 Driver Selector Card
- **Height:** 110, horizontal scroll
- **Width por card:** 220
- **Animation:** `AnimatedContainer`, 250ms
- **Background:** `Color(0xFF121212)`, gradient selected `#2A2A2A`→`#121212`, unselected `#1E1E1E`→`#0A0A0A`
- **Border:** selected → `theme.primaryColor` width 2, unselected → white alpha 0.1 width 1
- **Shadow:** selected → primary alpha 0.3 blur 10 offset (0,4), unselected → black alpha 0.4 blur 4 offset (0,2)
- **Portrait area:** 35% flex, image fit cover, gradient fade right→left black alpha 0.8 → transparent
- **Name font:** 12px, `w900`, selected → white, unselected → white alpha 0.5, letterSpacing 0.5
- **Setup sent icon:** `Icons.check_circle`, green, 14px
- **Laps count:** 9px, `w900`, letterSpacing 0.5, maxed → orange, else → white38

### 23.2 DNF Overlay
- **Background:** `Colors.red` alpha 0.55, radius 10
- **Texto "DNF":** 28px, `w900`, blanco, letterSpacing 4.0
- **Shadow:** blur 10, black

### 23.3 Fitness Bar
- **Bar width:** 110px, height 4px
- **Bar bg:** `Colors.white10`, radius 2
- **Bar glow:** barColor alpha 0.3, blur 4

| Fitness | Color |
|:---|:---|
| ≥75 (High) | `Color(0xFF00C853)` |
| 40-74 (Med) | `Color(0xFFFFB800)` |
| <40 (Low) | `Color(0xFFFF5252)` |

- **Ícono:** `Icons.bolt`, 8px, barColor
- **Label font:** 8.5px, `w900`, letterSpacing 0.3, barColor

### 23.4 Pit Board (Practice)
- **Container:** gradient `#1E1E1E`→`#0A0A0A`, border white alpha 0.1, radius 12, shadow black alpha 0.4 blur 15 offset (0,8)
- **Header:** `Icons.developer_board` + "PIT BOARD", `theme.primaryColor`, 11px, `w900`, letterSpacing 2.0
- **Message area:** black bg, radius 8, border white alpha 0.1
- **Message font:** `fontFamily: 'monospace'`, `w900`, 14px, letterSpacing 1.5, color primary o white24
- **AnimatedSwitcher:** 500ms fade

### 23.5 Qualifying Pit Board
- **Container:** mismos estilos que Pit Board (gradient, border, shadow)
- **Session status header:** blinking `AnimatedBuilder`, `Color(0xFF00E676)`, 12px, `w900`, letterSpacing 2.5
- **Session closed:** `Color(0xFFFF5252)` para cerrado
- **Status badge:** loading → red alpha 0.1 bg + red border, else → white alpha 0.05 bg + white alpha 0.2 border
- **Status font:** `fontFamily: 'monospace'`, `w900`, 11px, letterSpacing 1.0
- **Laps counter:** "LAPS", white alpha 0.5, 10px, `w900`, letterSpacing 1.0
- **Laps value:** `Color(0xFFFFD700)`, monospace, `w900`, 16px

### 23.6 Pit Board Field (reusable)
- **Background:** white alpha 0.05
- **Border:** white alpha 0.1, radius 12
- **Label:** white alpha 0.5, 9px, `w900`, letterSpacing 0.8
- **Value:** `Color(0xFFFFD700)` (gold), monospace, `w900`, 15px

### 23.7 Circuit Intel Card
- **Height:** 80px
- **Border:** white alpha 0.1, radius 12

| Clima | Gradient |
|:---|:---|
| Rain/Storm | `#222222` → `#0A0A0A` |
| Partly cloudy | `#121E2A` → `#05080A` |
| Cloudy/Overcast | `#1E222A` → `#0A0B0F` |
| Sunny (default) | `#453018` → `#0F0B08` |

- **Background weather icon:** right -10, top -10, size 100, accentColor alpha 0.12
- **Gradient fade overlay:** stops [0.55, 1.0]
- **Header:** `Icons.info_outline` 11px + "CIRCUIT INTEL" white `w900` letterSpacing 1.5 9px
- **Circuit name:** white alpha 0.35, 9px, bold

### 23.8 Circuit Chip (reusable)
- **Padding:** h8 v3, radius 6

| Tipo | Background | Text Color |
|:---|:---|:---|
| Weather | weatherColor alpha 0.1 | weatherColor |
| Extreme High / Critical | `FF5252` alpha 0.1 | `FF5252` |
| Low priority | `00C853` alpha 0.1 | `00C853` |
| Default (medium) | `FFB800` alpha 0.1 | `FFB800` |

- **Font:** 10px, bold

### 23.9 Driver Style Card
- **Container:** `Color(0xFF121212)`, radius 12, border white alpha 0.08, shadow black alpha 0.5 blur 16 offset (0,8)
- **Header:** `Icons.tune` 12px white38 + "DRIVER STYLE" 11px `w900` letterSpacing 2.0

**Style buttons (4 opciones):**
| Style | Ícono | Color |
|:---|:---|:---|
| Most Risky | `keyboard_double_arrow_up` | `Color(0xFFFF3D3D)` |
| Offensive | `keyboard_arrow_up` | `Color(0xFFFF9800)` |
| Normal | `remove` | `Color(0xFF00C853)` |
| Defensive | `keyboard_arrow_down` | `Color(0xFF42A5F5)` |

- **Button size:** 48x48, radius 10
- **Selected bg:** color alpha 0.18, border color width 1.5, shadow color alpha 0.8 blur 8 offset (0,2)
- **Unselected bg:** white alpha 0.03, border white alpha 0.08 width 1
- **Ícono:** 20px, selected → color, unselected → white24
- **Label:** 7px, `w900`, letterSpacing 0.4

### 23.10 Copy Badge (pill-shaped)
- **Background:** color alpha 0.12
- **Border:** color alpha 0.4, radius 20
- **Animation:** `AnimatedContainer`, 150ms
- **Icon:** 10px
- **Font:** 9px, `w900`, letterSpacing 0.8

### 23.11 Small Tyre Icon
- **Size:** 14x14, circular
- **Border:** compound color, width 2
- **Texto:** compound initial, 7px, bold

| Compuesto | Color |
|:---|:---|
| Soft | `Colors.red` |
| Medium | `Colors.yellow` |
| Hard | `Colors.white` |
| Wet | `Colors.blue` |

### 23.12 Qualifying Results Table (`_buildQualifyingResultsPanel`)
**Diseño distinto a OnyxTable.** Tabla custom con header dorado y filas con highlighting.

#### Panel Container:
- **Background:** `Colors.black`
- **Border:** white alpha 0.1, radius 8

#### Gold Header:
- **Background:** `Color(0xFFFFB800)` alpha 0.1
- **Border radius:** top only 8
- **Ícono:** `Icons.emoji_events`, 18px, `Color(0xFFFFB800)`
- **Título:** "QUALIFYING RESULTS", `w900`, 13px, letterSpacing 1.5, `Color(0xFFFFB800)`
- **Track name:** 10px, white alpha 0.5, bold

#### Column Headers:
- **Background:** white alpha 0.05
- **Style (`_qualyHeaderStyle`):** 9px, `w900`, letterSpacing 1.0, `Colors.white38`
- **Columnas:** POS (35px fijo) | DRIVER (flex 4) | CONSTRUCTOR (flex 3) | TYRE (30px) | TIME (flex 2) | LAPS (40px)

#### Data Rows (`_buildQualifyingResultRow`):
- **Padding:** h16 v8
- **Player team row:** bg `secondary` alpha 0.1, left border 3px `secondary` color
- **Non-player row:** transparent bg, bottom border white alpha 0.1

**Position coloring:**
| Posición | Color |
|:---|:---|
| P1-P3 (con tiempo) | `Color(0xFFFFB800)` (gold) |
| P4+ (con tiempo) | white alpha 0.9 |
| Sin tiempo | white alpha 0.4, muestra "—" |

**Driver name:**
- Player team: 11px, bold, `secondary` color
- Has time: 11px, normal, white alpha 0.9
- No time: 11px, normal, white alpha 0.4

**Constructor name:** 10px, has time → white alpha 0.7, no time → white alpha 0.4

**Tyre column:** `_buildSmallTyreIcon` (14x14 circle)

**Time column:**
- Con tiempo: 11px, bold, monospace, white
- Sin tiempo: 11px, monospace, white alpha 0.3, muestra `--:--.---`

**Gap (debajo del tiempo):**
- 9px, monospace, white alpha 0.5, formato `+X.XXX`

**Laps:** 11px, bold, white alpha 0.5, center

### 23.13 Setup Card (`_buildSetupCard`) + Compact Sliders

#### Setup Card Container:
- **Background:** `Color(0xFF121212)`
- **Border:** white alpha 0.08, radius 12
- **Shadow:** black alpha 0.5, blur 20, offset (0,10)
- **Gradient overlay:** `Positioned.fill`, white alpha 0.02 → transparent (topLeft→bottomRight)
- **Padding:** 20

#### Card Title:
- **Font:** 13px, `w900`, letterSpacing 2.0, white, `.toUpperCase()`
- **Copy badges (derecha):** "SET QUALY" (ícono `timer_outlined`, primaryColor) y "SET RACE" (ícono `flag_outlined`, redAccent)

#### Compact Slider (`_buildCompactSlider`):
- **Label area:** 100px width
- **Label font:** 12px, `onSurface` alpha 0.5
- **Hint icon:** `Icons.help_outline`, 14px, `onSurface` alpha 0.3 (si hay hint)
- **Slider theme:**
  - `activeTrackColor`: `secondary`
  - `inactiveTrackColor`: `onSurface` alpha 0.1
  - `thumbColor`: `secondary`
  - `overlayColor`: `secondary` alpha 0.2
  - `trackHeight`: 3px
  - `thumbShape`: `RoundSliderThumbShape`, enabledThumbRadius 6
  - `overlayShape`: `RoundSliderOverlayShape`, overlayRadius 12
- **Range:** 0-100, divisions 100
- **Value display:** 32px width, monospace, 12px, `w900`, `onSurface`, right-aligned
- **Locked state:** opacity 0.4, `AbsorbPointer`, lock icon `Icons.lock` 12px orange

#### Sliders (4 config params):
| Slider | Campo |
|:---|:---|
| Front Wing | `setup.frontWing` |
| Rear Wing | `setup.rearWing` |
| Suspension | `setup.suspension` |
| Gear Ratio | `setup.gearRatio` |

#### Tyre Compound Selector (in setup card):
- **Label:** "TYRE COMPOUND", 9px, `w900`, white54, letterSpacing 1.0
- **Wrap spacing:** 8
- **Chip style:** padding h10 v6, radius 6
- **Selected:** compoundColor alpha 0.15 bg, compoundColor border
- **Unselected:** white alpha 0.02 bg, white alpha 0.05 border
- **Content:** `_buildSmallTyreIcon` + compound name, 10px, `w900`

#### Pit Stop Selector (in setup card):
- **Label:** "RACE STRATEGY", 9px, `w900`, white54, letterSpacing 1.0
- **Stop label:** "PIT STOP X", 10px, `w900`, white54
- **Remove button:** `Icons.remove_circle_outline`, 16px, redAccent
- **Compound chips:** padding h10 v6, radius 12, `AnimatedContainer` 200ms
- **Selected:** compoundColor alpha 0.15 bg, compoundColor border
- **Unselected:** white alpha 0.05 bg, transparent border
- **Font:** 9px, bold, selected → compoundColor, unselected → white24
- **Add button:** OutlinedButton, "ADD PIT STOP", 10px bold, full width, height 36, border primaryColor alpha 0.5

**Usado en:** Practice, Qualifying, Race tabs del GarageScreen.

---

## 24. Race Strategy (`lib/screens/race/race_strategy_screen.dart`)

### Setup Sliders:
- **Track height:** 2px
- **Thumb:** `RoundSliderThumbShape`, radius 6
- **Overlay:** radius 12
- **Active color:** `theme.colorScheme.secondary`
- **Label font:** 12px, `onSurface` alpha 0.7
- **Value font:** 12px, bold, `onSurface`

### Style Selector (compact, inline):
| Style | Ícono | Color |
|:---|:---|:---|
| Defensive | `keyboard_arrow_down` | `Color(0xFF42A5F5)` |
| Normal | `remove` | `Color(0xFF00C853)` |
| Offensive | `keyboard_arrow_up` | `Color(0xFFFF9800)` |
| Most Risky | `keyboard_double_arrow_up` | `Color(0xFFFF3D3D)` |

- **Selected:** color alpha 0.2 bg, color border, radius 12
- **Unselected:** transparent, white10 border
- **Ícono:** 14px

### Tyre Compound Selector (circular):
- **Shape:** circle
- **Selected:** tyreColor alpha 0.2 bg, tyreColor border
- **Unselected:** transparent, white10 border
- **Texto:** first letter, 9px, bold

### Pit Stop Row:
- **Container:** `surfaceContainerHighest` alpha 0.1, radius 12
- **Label "STOP X":** 10px, `w900`, white38
- **Start row:** same but alpha 0.3 bg
- **Lock icon:** `Icons.lock_outline`, 10px, orange

### Submit Button:
- **Width:** full
- **Padding:** vertical 20
- **Active bg:** `theme.primaryColor`
- **Submitted bg:** `Colors.grey`
- **Icon active:** `Icons.check_circle`
- **Icon submitted:** `Icons.lock`

### Circuit Characteristics Chips:
- **Background:** dark → `Colors.blueGrey[800]`
- **Font:** 12px, `onSurface`

**Usado en:** Weekend Setup flow (desde Qualifying tab o dashboard CTA).

---

## 25. Tyre System (colores globales)

Dos versiones de colores de compuestos existen en el código:

### `garage_screen.dart` `_getTyreColor()` y `_buildSmallTyreIcon()`:
| Compuesto | Color |
|:---|:---|
| Soft | `Colors.red` |
| Medium | `Colors.yellow` |
| Hard | `Colors.white` |
| Wet | `Colors.blue` |

### `race_strategy_screen.dart` `_getTyreColor()`:
| Compuesto | Color |
|:---|:---|
| Soft | `Colors.redAccent` |
| Medium | `Colors.yellowAccent` |
| Hard | `Colors.white70` |
| Wet | `Colors.blueAccent` |

**Nota:** Inconsistencia entre ambos archivos. Garage usa colores puros, Strategy usa Accent variants.

---

## 26. Animaciones Adicionales (no incluidas en §20)

| Widget | Tipo | Duración | Detalle |
|:---|:---|:---|:---|
| `DriverCard` flip | 3D rotateY | 600ms | `Curves.easeInOut`, perspective 0.001 |
| `GarageScreen` blinking controller | Opacity loop | 1000ms | Texto sesión qualifying, `repeat(reverse: true)` |
| `GarageScreen` driver selector | AnimatedContainer | 250ms | Cambio de estado selected |
| `GarageScreen` driver style buttons | AnimatedContainer | 200ms | Hover/selected state |
| `GarageScreen` copy badge | AnimatedContainer | 150ms | Hover animation |
| `GarageScreen` pit board message | AnimatedSwitcher | 500ms | FadeTransition on change |

---

## 27. Colores Hardcodeados Adicionales

| Color | Hex | Nombre | Ubicaciones |
|:---|:---|:---|:---|
| Neon Pink | `0xFFFF00FF` | Flip badge | `DriverCard` flip badge |
| Stat Blue Grey | `0xFFA0AEC0` | Labels muted | `DriverCard` contract labels, stat names |
| Yellow Star | `0xFFFFEE58` | Pro level / medium stat | `DriverCard` level badge, stat indicator |
| Red Danger | `0xFFFF3D3D` | Most risky style | `GarageScreen`, `RaceStrategyScreen` style selector |
| Blue Defensive | `0xFF42A5F5` | Defensive style | `GarageScreen`, `RaceStrategyScreen` style selector |
| Orange Attack | `0xFFFF9800` | Offensive style | `GarageScreen`, `RaceStrategyScreen` style selector |
| Sunny gradient start | `0xFF453018` | Warm circuit intel | `GarageScreen` circuit intel |
| Cloudy gradient start | `0xFF1E222A` | Cloudy circuit intel | `GarageScreen` circuit intel |
| Rain gradient start | `0xFF222222` | Rain circuit intel | `GarageScreen` circuit intel |

---

## 28. Fuentes Adicionales

| Fuente | Uso |
|:---|:---|
| `GoogleFonts.robotoMono` | Market value amount, stat display values en DriverCard |

---

## 31. Race Day Screen (`lib/screens/race/race_day_screen.dart`)

**Tipo:** Viewer en vivo de carrera que lee datos pre-computados de Firestore. 2300 líneas. Layout: Header + (Leaderboard 60% | EventFeed + Commentary 40%).

### Locked State (`_buildLockedState`):
- **Ícono:** `Icons.lock_clock_outlined`, 64px, white alpha 0.15
- **Título:** `raceDayTitle.toUpperCase()`, 22px, `w900`, white alpha 0.5, letterSpacing 2.0
- **Subtítulo:** (flag emoji + circuit name), 14px, white alpha 0.3
- **Countdown badge:** padding h20 v10, bg white alpha 0.05, radius 12, border white alpha 0.08
  - Texto: 11px, bold, white alpha 0.4, letterSpacing 1.2

### Race Header (`_buildRaceHeader`):
- **Container:** padding 20, radius 12
  - **Gradient:** `LinearGradient` topLeft→bottomRight `[#1E1E1E, #0A0A0A]`
  - **Border:** white alpha 0.1
  - **BoxShadow:** black alpha 0.5, blur 20, offset (0,10)

#### LIVE Indicator (when `isLive`):
- **`FadeTransition`** con `_pulseController` (animación de pulso)
- **Container:** padding h10 v5, radius 12
  - **Background:** `#FF5252` alpha 0.15
  - **Border:** `#FF5252` alpha 0.5
- **Ícono:** `Icons.fiber_manual_record`, 10px, `#FF5252`
- **Texto:** "LIVE", `#FF5252`, `w900`, 11px, letterSpacing 1.5

#### FINISHED Badge (when `_isFinished`):
- **Background:** `#00C853` alpha 0.1
- **Border:** `#00C853` alpha 0.4
- **Texto:** `#00C853`, `w900`, 11px, letterSpacing 1.5

#### PRE-RACE Badge:
- **Background:** white alpha 0.05
- **Border:** white alpha 0.1
- **Texto:** `Colors.white54`, `w900`, 11px, letterSpacing 1.5

#### Circuit Name:
- **Font:** 18px, `w900`, white, letterSpacing 1.0
- **Format:** `'🏳️ CIRCUIT NAME'` (flag emoji + uppercase)

#### Lap Counter:
- **Container:** padding h16 v8, bg white alpha 0.05, radius 12
- **"LAP" label:** white alpha 0.4, 10px, bold, letterSpacing 1.0
- **Current lap number:** `monospace`, 22px, `w900`, white
- **" / totalLaps":** `monospace`, 14px, bold, white alpha 0.4

#### Progress Bar:
- **`LinearProgressIndicator`**, minHeight 6, radius 4
- **Background:** white alpha 0.08
- **Color (in-progress):** `#FF5252`
- **Color (finished):** `#00C853`

#### Fastest Lap Row:
- **Ícono:** `Icons.timer`, 14px, `#E040FB` (Magenta/Purple)
- **Label:** "FASTEST LAP", 9px, `w900`, letterSpacing 1.0, white alpha 0.4
- **Value:** `monospace`, 11px, bold, `#E040FB`
- **No data:** "—", 11px, white alpha 0.3

#### Race Time Row:
- **Ícono:** `Icons.schedule`, 14px, white alpha 0.4
- **Label:** "RACE", 9px, `w900`, letterSpacing 1.0, white alpha 0.4
- **Value:** `monospace`, 11px, bold, white alpha 0.7

### Leaderboard (`_buildLeaderboard`):
- **Container:** bg `#0A0A0A`, radius 12, border white alpha 0.08

#### Leaderboard Header:
- **Background:** `#FF5252` alpha 0.08, border-radius top 12
- **Ícono:** `Icons.format_list_numbered`, 16px, `#FF5252`
- **Título:** "RACE POSITIONS", 11px, `w900`, letterSpacing 1.5, `#FF5252`
- **Count badge:** "XX DRIVERS", 10px, bold, white alpha 0.3

#### Column Headers:
- **Background:** white alpha 0.03
- **Padding:** h16 v8
- **Columns:** (icon 16px) | POS (24px) | DRIVER (flex 2) | LATEST (55px) | BEST (55px) | INTERVAL (flex 1)
- **Font:** 9px, `w900`, letterSpacing 1.0, white alpha 0.3

#### Leaderboard Row:
- **Padding:** h16 v10
- **Player team highlight:** bg `secondary` alpha 0.08, left border `secondary` width 3
- **Border bottom:** white alpha 0.04

##### Position Change Icons:
| Estado | Ícono | Color |
|:---|:---|:---|
| Gained | `Icons.arrow_drop_up` | `#00C853` (green) |
| Lost | `Icons.arrow_drop_down` | `#FF5252` (red) |
| Same | `Icons.remove` | white alpha 0.3 |

##### Position Number:
- **DNF:** "DNF", `#FF5252`, 13px, `w900`
- **P1-P3:** `#FFB800` (gold), 13px, `w900`
- **P4+:** white alpha 0.7, 13px, `w900`

##### Driver Name Cell:
- **Normal:** 11px, `w500`, white alpha 0.9
- **Player team:** 11px, `w900`, `secondary` color
- **Fastest lap holder:** 11px, `w500`, `#E040FB`
- **DNF:** 11px, `w500`, white alpha 0.3
- **Team name (sub):** 8px, white alpha 0.4 (or 0.2 if DNF)

##### Tyre Compound Indicator (circle):
- **Shape:** `BoxShape.circle`, padding 3, margin-right 6
- **Border width:** 1.5
- **Text:** shorthand (S/M/H/W), 7px, bold
- **Colores tyre:**

| Compound | Color |
|:---|:---|
| Soft | `Colors.redAccent` |
| Medium | `Colors.yellowAccent` |
| Hard | `Colors.white70` |
| Wet | `Colors.blueAccent` |

##### Pitting Indicator (when in boxes):
- **Ícono:** `Icons.local_gas_station`, 10px, `#FFB800`
- **Texto:** "IN BOXES", 9px, `w900`, `#FFB800`, letterSpacing 0.5

##### Lap Time Columns (LATEST / BEST):
- **Font:** `monospace`, 10px
- **Normal:** white alpha 0.7
- **DNF:** white alpha 0.3
- **Fastest lap (BEST):** `#E040FB`, bold

##### Interval:
- **Font:** `monospace`, 11px, bold, right-aligned
- **Leader:** "LEADER" (localized)
- **DNF:** "RETIRED", `#FF5252`
- **Gap:** "+X.XXXs", white alpha 0.7
- **Fastest lap holder:** `#E040FB`

---

## 32. Event Feed / Pit Board (`_buildEventFeed`)

**Tipo:** Panel derecho superior con eventos del equipo del jugador.

### Container:
- **Background:** `#0A0A0A`, radius 12, border white alpha 0.08

### Header:
- **Background:** `#FFB800` alpha 0.08, border-radius top 12
- **Ícono:** `Icons.developer_board`, 16px, `#FFB800`
- **Título:** "PIT BOARD", 11px, `w900`, letterSpacing 1.5, `#FFB800`
- **Events count:** 10px, bold, white alpha 0.3

### Empty State:
- **Ícono:** `Icons.radio_button_unchecked`, 32px, white alpha 0.1
- **Texto:** "LIGHTS OUT SOON" o "NO EVENTS YET", 11px, bold, white alpha 0.2, letterSpacing 1.0

### Event Item (`_buildEventItem`):
- **Padding:** h12 v10
- **Player team highlight:** `secondary` alpha 0.05
- **Border bottom:** white alpha 0.04

#### Lap Badge:
- **Width:** 36px, padding v2, bg white alpha 0.05, radius 6
- **Texto:** "L{lap}", 9px, `w900`, white alpha 0.4, letterSpacing 0.5, centered

#### Event Type Colors & Icons:

| Type | Color | Icon |
|:---|:---|:---|
| OVERTAKE | `#00C853` | `Icons.swap_vert` |
| PIT | `#FFB800` | `Icons.local_gas_station` |
| DNF | `#FF5252` | `Icons.warning_amber_rounded` |
| INFO | `Colors.blueAccent` | `Icons.info_outline` |
| Default | `Colors.white54` | `Icons.radio_button_unchecked` |

#### Driver Name:
- **Font:** 10px, `w900`, letterSpacing 0.5
- **Player team:** `secondary` color
- **Other:** white alpha 0.7

#### Description:
- **Font:** 11px, `w500`, event color alpha 0.8

#### Type Badge:
- **Padding:** h6 v2, radius 8
- **Background:** event color alpha 0.1
- **Border:** event color alpha 0.3
- **Texto:** 8px, `w900`, event color, letterSpacing 0.5

---

## 33. Commentary Feed (`_buildCommentaryFeed`)

**Tipo:** Panel derecho inferior, estilo broadcast TV/radio con efecto CRT scan lines.

### Container:
- **Background:** `#080810` (más oscuro que los paneles normales)
- **Radius:** 12
- **Border:** `#00BCD4` (Cyan) alpha 0.15

### Header (Broadcast style):
- **Gradient:** `[#00BCD4 alpha 0.12, #080810]`
- **Border-radius:** top 12

#### "ON AIR" Badge:
- **Padding:** h6 v2, radius 4
- **Background:** `#00BCD4` alpha 0.15
- **Border:** `#00BCD4` alpha 0.4
- **Texto:** "ON AIR", 8px, `w900`, `#00BCD4`, letterSpacing 1.5

#### Header Icons:
- **Podcast icon:** `Icons.podcasts`, 14px, `#00BCD4`
- **TV icon:** `Icons.tv`, 14px, white alpha 0.15

#### Title:
- **Texto:** "COMMENTARY", 10px, `w900`, letterSpacing 1.5, `#00BCD4`

### Scan Line Overlay (`_ScanLinePainter`):
- **CustomPainter** overlay con `IgnorePointer`
- **Líneas horizontales** cada 3px
- **Color:** black alpha 0.04, strokeWidth 1
- **Efecto CRT/TV vintage**

### Commentary Item (`_CommentaryItem`):
- **Padding:** h14 v10

#### Background Color:
| Estado | Player | Non-Player |
|:---|:---|:---|
| Newest | `#FFD54F` alpha 0.1 | `#00BCD4` alpha 0.08 |
| Older | `#FFD54F` alpha 0.04 | transparent |

#### Border Bottom:
- **Player:** `#FFD54F` alpha 0.1
- **Non-player:** `#00BCD4` alpha 0.06

#### Lap Indicator:
- **Texto "L{lap}":** 9px, `w900`
  - Player: `#FFD54F` alpha 0.6
  - Non-player: `#00BCD4` alpha 0.5
- **Icon mapping:**

| Type | Icon |
|:---|:---|
| DNF | `Icons.warning_amber_rounded` |
| PIT | `Icons.local_gas_station` |
| OVERTAKE | `Icons.swap_vert` |
| FINISH | `Icons.flag` |
| FASTEST_LAP | `Icons.timer` |
| Default | `Icons.mic` |

- **Icon size:** 12px
- **Fastest lap icon color:** `#E040FB` alpha 0.6
- **Player icon color:** `#FFD54F` alpha 0.4
- **Non-player icon color:** `#00BCD4` alpha 0.3

#### Commentary Text:
- **Font:** 11px, italic, lineHeight 1.4
- **Newest + player:** `#FFD54F` alpha 1.0
- **Older + player:** `#FFD54F` alpha 0.7
- **Newest + non-player:** white alpha 0.95
- **Older + non-player:** white alpha 0.5

#### Typewriter Animation (newest only):
- **Timer:** `Timer.periodic`, 18ms per tick
- **Speed:** 2 chars per tick
- **Cursor:** "▌" character
  - Player: `#FFD54F` alpha 0.7, bold
  - Non-player: `#00BCD4` alpha 0.7, bold

---

## 34. Race Live Screen (`lib/screens/race/race_live_screen.dart`)

**Tipo:** Pantalla de simulación de carrera en vivo con leaderboard simplificado. 550 líneas.

### Events Header:
- **Height:** 80px, full width
- **Background:** `surfaceContainerHighest`
- **Padding:** 12
- **Empty state:** "Green Flag", `primary`, bold
- **Event format:** "[Lap X] TYPE: DriverName", `secondary`, bold

### Fastest Lap Info Bar:
- **Background:** `surfaceContainerHighest` alpha 0.5
- **Padding:** h12 v6
- **Fastest lap:** `Icons.timer` 14px `#E040FB` + nombre + tiempo, 11px bold `#E040FB`
- **Race time:** `Icons.schedule` 14px + "RACE: HH:MM:SS", 11px bold, `onSurface` alpha 0.7

### Leaderboard Rows (Card + ListTile):
- **Card margin:** h8 v4
- **Position:** 18px, bold, width 30
- **Fastest lap icon:** `Icons.timer` 16px `#E040FB`
- **Interval:**
  - DNF: "RETIRED", `Colors.red`, bold
  - Leader: "LEADER", `primaryColor`, bold
  - Gap: "+X.XXXs", `primaryColor`, bold
  - Fastest lap: `#E040FB`, bold

---

## 35. Internal Timing Card (`lib/screens/race/widgets/internal_timing_card.dart`)

**Tipo:** Card de tiempos internos para práctica, integrada en garage. 274 líneas.

### Container:
- **Card:** margin `(0, 8, 16, 16)`, `surface` color, radius 16, padding 20

### Title Row:
- **Ícono:** `Icons.timer`, 20px, `#00FF88` (Neon Green)
- **Texto:** "INTERNAL TIMING", `titleMedium`, bold, letterSpacing 1.2, `#1A1A1A`

### Table Header:
- **Background:** `#00FF88` alpha 0.1, radius 12
- **Padding:** v8 h12
- **Font:** `RobotoMono`, bold, 12px, `#1A1A1A`
- **Columns:** POS (40px) | DRIVER (flex 2) | BEST LAP (flex 2, right) | GAP (flex 1, right)

### Timing Rows:
- **Padding:** v10 h12, margin-bottom 4, radius 6
- **Fastest row bg:** `#00FF88` alpha 0.15
- **Other rows:** transparent

#### Position:
- **Font:** `RobotoMono`, bold, 16px
- **Fastest:** `#00FF88`
- **Other:** `#1A1A1A`

#### Driver Name:
- **Font:** `RobotoMono`, 14px
- **Fastest:** bold
- **Other:** normal
- **Color:** `#1A1A1A`

#### Best Lap Time:
- **Font:** `RobotoMono`, 14px, right-aligned
- **Fastest:** bold, `#00FF88`
- **Other:** normal, `#1A1A1A`

#### Gap:
- **Font:** `RobotoMono`, 12px, right-aligned, `#666666`
- **Fastest:** "—"
- **Other:** "+X.XXX"

### Empty State:
- "No lap times recorded yet", bodyMedium color, italic


**Nota:** Este widget usa `#1A1A1A` (casi negro) en vez del esquema oscuro habitual, probablemente diseñado para una superficie clara.

---

## 36. OnyxSkeleton (`lib/widgets/common/onyx_skeleton.dart`)

**Tipo:** Skeleton shimmer loading placeholder animado. 61 líneas.

### Container:
- **Width/Height:** configurable (params)
- **Border radius:** default 8
- **Color:** `Colors.white` con alpha animado entre **0.05 → 0.12**

### Animación:
- **Controller:** `SingleTickerProviderStateMixin`
- **Duration:** 1500ms, `repeat(reverse: true)` (loop infinito)
- **Tween:** `0.05 → 0.12` (alpha de white)
- **Curve:** `Curves.easeInOut`
- **Builder:** `AnimatedBuilder`

**Usado en:** `TransferMarketScreen._buildSkeletonTable`, `GarageScreen` loading states.

---

## 37. OnyxTable (`lib/widgets/common/onyx_table.dart`)

**Tipo:** Tabla de datos reutilizable con header fijo y scroll. 240 líneas.

### Header:
- **Padding:** v12 h20
- **Background:** white alpha 0.03
- **Border bottom:** white alpha 0.05
- **Font:** `GoogleFonts.poppins`, `w700`, 10px, letterSpacing 1.1, white alpha 0.4
- **Text transform:** `.toUpperCase()`

### Data Row Wrapper (`_buildRowWrapper`):
- **Padding:** v14 h20
- **Hover:** `MouseRegion` con `_hoveredIndex` state

| Estado | Background | Left Border |
|:---|:---|:---|
| Highlighted | `#00C853` alpha 0.1 | `#00C853` width 4 |
| Hovered | `#00C853` alpha 0.05 | none |
| Even rows | transparent | none |
| Odd rows | white alpha 0.01 | none |

- **Border bottom:** white alpha 0.05, width 0.5

### Data Cell Text (`_buildRowFromData`):
- **Font:** `GoogleFonts.inter`, 12px
- **Position column (i==0):** white alpha 0.5, `w500`
- **Points column (last):** white alpha 0.9, `w700`
- **Other columns:** white alpha 0.9, `w500`
- **Highlighted rows:** `#00C853` color, `w900`/`w700`

### Scroll Features:
- **Scrollbar:** `thumbVisibility: true`
- **onReachEnd callback:** triggered at `maxScrollExtent - 200` (infinite scroll)
- **shrinkWrap option:** `NeverScrollableScrollPhysics` para embedded tables

**Usado en:** `StandingsScreen`, `TransferMarketScreen`, `_LastRaceStandingsTab`.

---

## 38. DriverStars (`lib/widgets/common/driver_stars.dart`)

**Tipo:** Widget inline de estrellas para tablas (diferente al `_buildPotentialStars` de DriverCard). 39 líneas.

### Estrellas (5 total):
- **Size:** default 14px (configurable)
- **Ícono:** `Icons.star_rounded` / `Icons.star_outline_rounded`

| Tipo | Color |
|:---|:---|
| Current (index < currentStars) | `Colors.blueAccent` |
| Potential (index < maxStars) | `Colors.amber` alpha 0.5 |
| Empty (index >= maxStars) | white alpha 0.2 |

**Nota:** Usa colores distintos al `_buildPotentialStars` del DriverCard:
- DriverStars: `blueAccent` / `amber 0.5`
- _buildPotentialStars: `#00B0FF` con glow / `#FFD700` con glow

**Usado en:** `StandingsScreen._DriversStandingsTab` (columna POT).

---

## 39. StandingsScreen (`lib/screens/standings_screen.dart`)

**Tipo:** Pantalla de clasificaciones con 3 tabs y dropdown de liga. 676 líneas.

### Header:
- **Title:** `GoogleFonts.poppins`, 24px, `w900`, letterSpacing 1.5
- **League Dropdown:** `surfaceContainerHighest` bg, radius 12, `DropdownButton` con `surface` dropdownColor

### Main Container:
- **Background:** `#121212`
- **Gradient:** `LinearGradient` topLeft→bottomRight `[#1E1E1E, #0A0A0A]`
- **Border:** white alpha 0.08
- **Radius:** 16
- **BoxShadow:** black alpha 0.4, blur 24, offset (0,12)

### TabBar:
- **Indicator color:** `#00C853`
- **Label color:** `#00C853`
- **Unselected label:** white alpha 0.3
- **Indicator size:** `TabBarIndicatorSize.label`
- **Font:** `GoogleFonts.poppins`, 13px, bold, letterSpacing 1.2
- **Tabs:** DRIVERS | CONSTRUCTORS | RACE RESULTS
- **Divider below:** white alpha 0.05, height/thickness 1

### Drivers Tab:
- **OnyxTable** con 8 columnas: POS, DRIVER, POT, TEAM, R, W, P, POINTS
- **flexValues:** `[1, 4, 3, 4, 1, 1, 1, 2]`
- **POT column:** `DriverStars` widget
- **Highlight:** player team rows

### Constructors Tab:
- **OnyxTable** con 7 columnas: POS, TEAM, R, W, P, Pl, POINTS
- **flexValues:** `[1, 7, 1, 1, 1, 1, 2]`
- **Team name:** `TextSpan` con manager info: `Inter` `w700` 12px + " (🏴 Manager Name)" `Inter` `w400` 11px, white alpha 0.35

### Last Race Tab:
- **Layout:** `ListView` con padding 16 (no OnyxTable wrapping, sino `shrinkWrap: true`)
- **Section title:** `secondary` color, bold, 16px
- **Sub-section title:** bold, 13px
- **Race Results OnyxTable:** 4 columnas [1,4,4,2], shrinkWrap, top 10 results con +points
- **Constructors OnyxTable:** 3 columnas [1,7,2], shrinkWrap, aggregated team points

---

## 40. ResponsiveMainScaffold (`lib/widgets/responsive_shell.dart`)

**Tipo:** Shell responsivo principal con NavigationRail (desktop) y BottomNavigationBar (mobile). 158 líneas.

### Desktop Layout (≥ 800px):
- **NavigationRail:**
  - `labelType: NavigationRailLabelType.all`
  - `groupAlignment: -0.9` (alineado arriba)
  - `minWidth: 80`
- **VerticalDivider:** `dividerColor` alpha 0.1, width/thickness 1
- **Content:** `ConstrainedBox` maxWidth 1600 + `IndexedStack`

### Mobile Layout (< 800px):
- **BottomNavigationBar** con 5 items
- **Body:** `IndexedStack`

### 5 Destinos (compartidos):

| Index | Icon (outlined → filled) | Label |
|:---|:---|:---|
| 0 | `dashboard_rounded` → `dashboard` | HQ |
| 1 | `business_center_outlined` → `business_center` | Office |
| 2 | `build_circle_outlined` → `build_circle` | Garage |
| 3 | `emoji_events_outlined` → `emoji_events` | Season |
| 4 | `groups_outlined` → `groups` | Market |

---

## 41. AppLogo (`lib/widgets/common/app_logo.dart`)

**Tipo:** Logo de la app "FTG RACING MANAGER". 56 líneas.

### "FTG":
- **Font:** `GoogleFonts.montserrat`, `w900`, `size * 0.6`, `onSurface`, letterSpacing -1.0, height 1.0

### "RACING MANAGER":
- **Font:** `GoogleFonts.montserrat`, `w600`, `size * 0.18`, `onSurface`, letterSpacing 2.5

---

## 42. Breadcrumbs (`lib/widgets/common/breadcrumbs.dart`)

**Tipo:** Navegación con breadcrumbs clickeables. 94 líneas.

### Separator:
- **"/"** en `GoogleFonts.raleway`, 12px, white alpha 0.2, padding h8

### BreadcrumbLink:
- **Font:** `GoogleFonts.raleway`, 11px, letterSpacing 1.0, uppercase
- **Last (current):** white, bold
- **Previous (hover):** white alpha 0.5 → white on hover
- **Cursor:** `SystemMouseCursors.click` (clickeable) / `.basic` (último)

---

## 43. DynamicLoadingIndicator (`lib/widgets/common/dynamic_loading_indicator.dart`)

**Tipo:** Loading con frases rotativas dinámicas. 110 líneas.

### Spinner:
- **`CircularProgressIndicator`** color `#00C853`

### Rotating Text:
- **`AnimatedSwitcher`** duration 500ms, `FadeTransition`
- **Font:** `GoogleFonts.raleway`, 14px, `Colors.white70`, letterSpacing 1
- **Timer:** `Timer.periodic`, default 3s (`switchDuration`)
- **8 frases** localizadas (o `customPhrases`)

---

## 44. InstructionCard (`lib/widgets/common/instruction_card.dart`)

**Tipo:** Card con instrucciones/onboarding. 81 líneas.

### Container:
- **Padding:** 24
- **Gradient:** `primary` alpha 0.1 → `#0A0A0A`
- **Border:** `primary` alpha 0.3, width 1, radius 12
- **BoxShadow:** black alpha 0.4, blur 15, offset (0,8)

### Icon:
- **`primary` color**, 32px

### Title:
- **Font:** `GoogleFonts.poppins`, 20px, `w900`, letterSpacing 1.5, `primary` alpha 0.9

### Description:
- **Font:** `bodyMedium`, height 1.5, `onSurface` alpha 0.8

---

## 45. NewBadgeWidget (`lib/widgets/common/new_badge.dart`)

**Tipo:** Badge "NEW" con animación pulsante, visible por 7 días. 117 líneas.

### Badge Container:
- **Color:** `Colors.amber` (solid amber/golden)
- **Padding:** h6 v2, radius 12
- **BoxShadow:** amber alpha 0.4, blur 4, offset (0,2)
- **Transform:** `Offset(8, -8)` (fuera del widget padre)

### Star Icon:
- **`Icons.star`**, white, 10px
- **`FadeTransition`** pulsante: alpha `0.5 → 1.0`, 1s, `repeat(reverse: true)`, `easeInOut`

### "NEW" Text:
- **Color:** white, 8px, bold, letterSpacing 0.5

### Configuración:
- **`badgeAlignment`:** default `Alignment.topRight`
- **Visibility:** `DateTime.now().difference(createdAt).inDays < 7` o `forceShow`

---

## 46. NotificationCard (`lib/widgets/notification_card.dart`)

**Tipo:** Card de notificación con tipificación por tipo. 178 líneas.

### Container:
- **Margin bottom:** 12
- **Color:** `cardTheme.color`
- **Radius:** 12
- **Border:** transparent (read) / `iconColor` alpha 0.2 (unread)
- **BoxShadow:** black alpha 0.4, blur 8, offset (0,4)

### Icon Container:
- **Shape:** `BoxShape.circle`, padding 8
- **Background:** `iconColor` alpha 0.1
- **Icon:** `iconColor`, 20px

### Notification Type Colors & Icons:

| Type | Icon | Color |
|:---|:---|:---|
| ALERT | `warning_amber_rounded` | `Colors.orangeAccent` |
| SUCCESS | `check_circle_outline_rounded` | `#00C853` |
| TEAM | `group_outlined` | `secondary` |
| OFFICE (RACE_RESULT) | `emoji_events_outlined` | `#FFD700` (Gold) |
| OFFICE (QUALY_RESULT) | `timer_outlined` | `Colors.tealAccent` |
| OFFICE (other) | `business_center_outlined` | `Colors.blueGrey` |
| NEWS / default | `newspaper_outlined` | `Colors.blueAccent` |

### Type Label:
- **Font:** `GoogleFonts.poppins`, 10px, bold, `iconColor`, letterSpacing 1.2

### Title:
- **Font:** `GoogleFonts.poppins`, 14px, bold, `onSurface`

### Message:
- **Font:** 13px, `onSurface` alpha 0.7, height 1.4

### Timestamp:
- **Font:** 10px, `onSurface` alpha 0.4
- **Format:** "X mins ago" / "X hours ago" / "dd/mm"

---

## 47. PressNewsCard (`lib/widgets/press_news_card.dart`)

**Tipo:** Card estilo periódico/prensa para noticias de liga. 333 líneas. **Tema claro único (newspaper).**

### Card Container:
- **Background:** `#F4F1EA` (Off-white newspaper)
- **Radius:** 4 (angular, no rounded)
- **Border:** black alpha 0.2, width 1
- **BoxShadow:** black alpha 0.1, blur 4, offset (2,2)

### Header "MOTORSPORT DAILY":
- **Font:** `GoogleFonts.playfairDisplay`, 10px, bold, letterSpacing 1.5, black87
- **Divider:** black alpha 0.3, thickness 1, height 8

### Type & Date Row:
- **Type:** `GoogleFonts.oswald`, 9px, `w600`, black54, letterSpacing 0.5
- **Date:** 9px, black54, `fontFamily: 'Courier'` (monospace)

### Title:
- **Font:** `GoogleFonts.merriweather`, 14px, `w900`, black87, height 1.2
- **Max lines:** 2, ellipsis

### "Read Full Article" Button:
- **Container:** border black87, radius 2
- **Font:** `GoogleFonts.oswald`, 10px, bold, black87

### Dialog (Full Article):
- **Background:** `#F4F1EA`
- **Max:** 500x700
- **Title dialog:** `GoogleFonts.playfairDisplay`, 18px, bold, letterSpacing 2.0
- **Date dialog:** `GoogleFonts.oswald`, 11px, letterSpacing 1.0, black54
- **Divider:** black alpha 0.8, thickness 2
- **Headline:** `GoogleFonts.merriweather`, 22px, `w900`, height 1.2
- **Body:** `GoogleFonts.ptSerif`, 14px, black87, height 1.6
- **Close btn:** `GoogleFonts.oswald`, black87, bold, letterSpacing 1.0

### Fuentes únicas de este componente:
| Fuente | Uso |
|:---|:---|
| `GoogleFonts.playfairDisplay` | Título periódico "MOTORSPORT DAILY" |
| `GoogleFonts.merriweather` | Headlines/títulos artículos |
| `GoogleFonts.oswald` | Type labels, dates, buttons |
| `GoogleFonts.ptSerif` | Body text del artículo |

---

## 48. FuelInput (`lib/widgets/fuel_input.dart`)

**Tipo:** Input compacto de combustible con sufijo "L". 99 líneas.

### Container:
- **Width:** 65px, **Height:** 28px
- **Background:** white alpha 0.05
- **Radius:** 12
- **Border:** white alpha 0.1

### TextField:
- **Keyboard:** decimal number
- **Align:** center
- **Font:** 11px, bold, `Colors.orange`
- **Decoration:** none (no border, isDense, zero padding)

### Suffix "L":
- **Font:** 8px, `Colors.white24`, bold, padding-right 6

---

## 49. CarSchematicWidget (`lib/widgets/car_schematic_widget.dart`)

**Tipo:** Visualización de stats del auto. 120 líneas.

### Container:
- **Width:** 180px default
- **Padding:** 16
- **Background:** `cardTheme.color` alpha 0.5
- **Radius:** 12
- **Border:** `Colors.white10`

### Title:
- **Font:** 12px, bold, `primaryColor`, letterSpacing 1.2

### Stats:
- **Valores calculados:** `(stat / 20 * 100).toStringAsFixed(1)` (levels 1-20 → %)
---

## 50. Garage Driver Selector (`lib/screens/race/garage_screen.dart::_buildDriverSelector`)

**Tipo:** Selector horizontal de pilotos en formato tarjeta interactiva con imagen y estadística. 200 líneas.

### Container (SizedBox + ListView):
- **Height:** 110px
- **Item Width:** 220px
- **Margin:** right 12

### AnimatedContainer (Card):
- **Duration:** 250ms
- **Border Radius:** 12
- **Border:** 
  - Selected: `theme.primaryColor`, width 2
  - Unselected: white alpha 0.1, width 1
- **Gradient Background:**
  - Selected: `[#2A2A2A, #121212]` (topLeft to bottomRight)
  - Unselected: `[#1E1E1E, #0A0A0A]`
- **BoxShadow:**
  - Selected: `primaryColor` alpha 0.3, blur 10, offset `(0, 4)`
  - Unselected: black alpha 0.4, blur 4, offset `(0, 2)`

### Layout (Row):
- **Left (35%):** Portrait Area. `BoxFit.cover`. Gradient overlay de `black alpha 0.8` (centerRight) a `transparent` (centerLeft).
- **Right (65%):** Info Area. Padding h12 v10.

### Text & Icons:
- **Name:** uppercase, 12px, `w900`, letterSpacing 0.5. Color white (selected) o white alpha 0.5 (unselected).
- **Check icon (Sent):** `Icons.check_circle`, color `Colors.green`, size 14.
- **Fitness Bar:** `_buildFitnessBar` (ver detales en su propio método).
- **Laps info:** `Icons.speed` (size 10) + text 9px `w900` letterSpacing 0.5. Color `Colors.orange` (si completó el máx) o `Colors.white38`.

### DNF Overlay:
- **Fondo:** `Colors.red` alpha 0.55
- **Radius:** 10
- **Texto:** "DNF" uppercase, white, 28px, `w900`, letterSpacing 4.0, sombra negra blur 10.

---

## 51. Garage Driver Feedback Card (`lib/screens/race/garage_screen.dart::_buildFeedbackCard`)

**Tipo:** Tarjeta de chat para feedback del piloto tras las vueltas de simulación. 160 líneas.

### Card Container:
- **Margin:** `LTRB(0, 4, 12, 12)`
- **Background:** `#0A0A0A`
- **Radius:** 12
- **Border:** white alpha 0.1

### Header:
- **Background:** white alpha 0.05
- **Radius:** top 12
- **Padding:** h16 v12
- **Icon:** `Icons.chat_bubble_outline`, 16px, white alpha 0.5
- **Text:** uppercase, 11px, `w900`, letterSpacing 1.5, white alpha 0.5

### Session Group Container (List Item):
- **Background:** white alpha 0.05
- **Border:** white alpha 0.1
- **Radius:** 12
- **Padding & Margin:** 12

### Session Header:
- **Avatar:** CircleAvatar 10px rad, color dinámico por piloto (`_driverColor`). Letra inicial blanca 9px bold.
- **Name:** uppercase, 11px, `w900`, white70, letterSpacing 1.0.
- **Best Lap Time:** 10px, `w900`, `theme.primaryColor` alpha 0.8, monospace.
- **Divider:** height 1, thickness 0.5, white alpha 0.1, padding vertical 8.

### Message Row:
- **Padding:** vertical 3
- **Chevron:** `Icons.keyboard_arrow_right`, 14px, color de confianza alpha 0.8 (ej: verde, amarillo, naranja).
- **Message:** 12px, `w500`, color de confianza alpha 0.8.

### Lap Setup Dialog (`_showLapSetupDialog`):
- **Background:** `surface`
- **Lap Time Title:** 16px, bold
- **DetailsRows:** (Aero, Power, etc.) label 14px, valor monospace 14px bold.
- **Confidence:** "#%", bold, color métrico.
- **Feedback String:** italic, 13px, onSurface alpha 0.6, centrado.
- **Botones:** CERRAR / RESTAURAR CONFIGURACIÓN, uppercase. 

### Confidence Colors (`_getConfidenceColor`):
- `>= 0.98`: `#00C853` (Green)
- `> 0.90`: `#64DD17`
- `> 0.70`: `#FFB800`
---

## 52. Finances Balance Header (`lib/screens/office/finances_screen.dart::FinancesScreen.build`)

**Tipo:** Tarjeta de cabecera con el saldo actual del equipo. 45 líneas.

### Container:
- **Margin:** 20px
- **Padding:** 32px
- **Width:** `double.infinity`
- **Border Radius:** 12
- **Gradient Background:** `[#1E1E1E, #0A0A0A]` (topLeft to bottomRight)
- **Border:** white alpha 0.1, width 1
- **BoxShadow:** black alpha 0.4, blur 12, offset `(0, 6)`

### Typography:
- **Título ("CURRENT BALANCE"):** grey, 12px, bold, letterSpacing 1.5
- **Monto:** 42px, `w900`, `Colors.redAccent` (si es negativo) u `onSurface` (si es positivo/0). Utiliza `FinanceService.formatCurrency`.

---

## 53. Transaction Tile (`lib/screens/office/finances_screen.dart::_buildTransactionTile`)

**Tipo:** Elemento de lista (ListTile) para mostrar movimientos financieros. 70 líneas.

### Container:
- **Margin:** bottom 12
- **Background:** `#121212`
- **Border Radius:** 12
- **Border:** white alpha 0.05, width 1

### ListTile Component:
- **Content Padding:** horizontal 16, vertical 4
- **Leading (Icon):**
  - **Container:** padding 10, background iconColor alpha 0.1, radius 12
  - **Iconos/Colores:** SPONSOR (handshake, secondary color), SALARY (person, orange), UPGRADE (build_circle, blue), REWARD (emoji_events, amber), PRACTICE (directions_car, blueGrey). Default: monetization_on.
- **Title:** description, `onSurface`, bold
- **Subtitle:** date formato `E, h:mm a`, grey, 12px
- **Trailing:** monto formatado, fontWeight bold, 16px, color `Colors.green` o `Colors.red`.

---

## 54. Transfer Market Budget Card (`lib/screens/office/finances_screen.dart::_TransferBudgetCard`)

**Tipo:** Tarjeta interactiva con un Slider para setear el presupuesto del mercado de transferencias. 120 líneas.

### Container:
- Está envuelto en un **`NewBadgeWidget`** (badge Alignment bottomRight).
- **Padding:** 20px
- **Background:** `#15151A`
- **Border Radius:** 12
- **Border:** `primaryColor` alpha 0.2

### Estructura:
- **Row 1:** Título ("Transfer Market Budget", secondary color, bold, letterSpacing 1.1) + Botón `FilledButton.tonal` "Save" (compact).
- **Row 2:** Texto asignado ("Allocated: XX%") + Monto máximo en `Colors.greenAccent`, bold.
- **Slider:** values 10 a 90, divisions 80, `activeColor: primaryColor`.
- **Text inferior:** Disclaimer pequeño, 10px, grey.

---

## 55. Sponsor Offer Card (`lib/screens/office/sponsorship_screen.dart::_SponsorOfferCard`)

**Tipo:** Tarjeta de oferta de patrocinador para negociar tácticas. Diseño se adapta (Vertical para Mobile, Horizontal para Desktop). 500 líneas.

### Container:
- **Margin:** vertical 4
- **Padding:** 16px
- **Background Gradient:** `[#1E1E1E, #0A0A0A]` (topLeft to bottomRight)
- **Border Radius:** 12
- **Border:** white alpha 0.1
- **BoxShadow:** black alpha 0.4, blur 12, offset `(0, 6)`

### Title & Bonuses:
- **Title Name:** uppercase, white, 16px, `w900`, `Poppins`, letterSpacing 1.2.
- **Admin Bonus (+15%):** Container verde alpha 0.2, radius 12, padding h8 v4. Texto verde 10px bold.

### Data Layout (Mobile/Vertical):
- Usa `_infoRow` para mostrar datos: `Icon` (color dividerColor, size 16) + Label (`onSurface` alpha 0.38, 12px) + Value (`fontWeight` bold, 13px, colores específicos: green, white0.7, blue, orangeAccent).

### Data Layout (Desktop/Horizontal):
- Utiliza `_infoChip` envueltos en un `Wrap` (spacing 16).
- **Chip:** Row con ícono (white alpha 0.2, size 14) + Texto (color respectivo, 11px, bold).

### Negotiation Buttons (`_tacticBtn`):
- Son `ElevatedButton`. Forma `StadiumBorder()`. Padding vertical 14.
- **Estilo "Mute" Hover:**
  - Background (default): white alpha 0.05
  - Background (hovered): Revela un color distintivo (Rojo `#xFFFF5733`, Amarillo `#FFF1C40F`, Naranja `#FFE9967A`).
  - Foreground (default): white alpha 0.4
  - Foreground (hovered): Crema claro `#FFFEF9E7`
- **Tácticas texto:** uppercase, 9px, `w900`, `Poppins`, letterSpacing 1.2.

---

## 56. Active Sponsor Contract Widget (`lib/screens/office/sponsorship_screen.dart::_buildDesktopRightPanel`)

**Tipo:** Visualización del contrato cuando la parte seleccionada (alerón, casco, etc) ya tiene patrocinio activo en Desktop.

### Container:
- Título: `ACTIVE CONTRACT: [SLOT]`, color secondary, bold, letterSpacing 1.5, 12px.
- **Inner Padding:** 32px
- **Background:** `secondary` alpha 0.05
- **Border Radius:** 12

### Estructura Intena:
- Ícono central `verified` grande (64px, color secondary).
- Título Patrocinador: `onSurface`, 32px, bold.
- **Data (`_DetailItem`):** Label small (secondary, 12px) + Value big (`onSurface`, 18px, bold). Distribuidos con `MainAxisAlignment.spaceAround`.

---

## 57. Team Selection Card (`lib/screens/onboarding/team_selection_screen.dart::_TeamSelectionCard`)

**Tipo:** Tarjeta interactiva para la selección de equipo al crear cuenta.

### Container:
- **Background:** Gradient Linear desde `#1A1A1A` a `#121212`.
- **Border:** `BorderSide(width: 1)` dinámico: `amber` alpha 0.3 si está ocupado, `white10` bloqueado, `white24` normal.
- **Image Background:** Opacity 0.15 de `'blueprints/blueprintcars.png'` escalada en modo `cover`.
- **Border Radius:** 12

### Visuals:
- **Badge superior ("SELECTED"):** Si equipo está ocupado. Transformación de giro 45º, amber transparente con texto negro 9px w900.
- **Datos Listados:** Nombre de equipo (`white` 18px), Pilotos con Flags e iconos. Presupuesto abajo en gris. Button primario tipo "SELECT TEAM" si está libre.

---

## 58. Calendar Event Item (`lib/screens/calendar/calendar_screen.dart::_buildCalendarItem`)

**Tipo:** Un `ListTile` estilizado para simular las rondas del calendario de la F1.

### Container:
- **Background:** `primaryColor` alpha 0.1 si es actual, de lo contrario color defecto tipo `cardTheme`.
- **Border:** `primaryColor` width 2 si es actual, de lo contrario `divider` transparente alpha 0.1.

### Text & Icons:
- **Leading:** Columna con "RN" (Round 1,2..). Amarillo/primario y un emoji del país enorme (20px).
- **Title:** `trackName.toUpperCase()`, w900, espaciado corto.
- **Subtitle:** Rows con iconos grises (calendar, loop), fechas y vueltas.
- **Trailing:** Ícono de confirmación (`check_circle` verde) o chapa "SCHEDULED" según estado del evento.

---

## 59. Transfer Market Bid Modal (`lib/screens/market/transfer_market_screen.dart::_showBidModal`)

**Tipo:** `AlertDialog` con layout básico para subastar en el mercado de pilotos.

### Content:
- **Títulos:** Texto explicativo del "Current Highest Bid" (`SizedBox` separadores).
- **Bid Input (Row):**
  - **Decrementar:** `IconButton(Icons.remove_circle, Colors.red)`.
  - **Monto Central:** Currency formated text, fontWeight `bold`, size 20.
  - **Incrementar:** `IconButton(Icons.add_circle, Colors.green)`.
- **Acciones:** `TextButton` para cancelar y `FilledButton.tonal` para confirmar enviando el BidAmount actual.

---

## 60. Youth Academy Candidate Card (`lib/screens/hq/youth_academy_screen.dart::_CandidateCard`)

**Tipo:** Tarjeta de visualización para ver atributos tempranos y un rango de potencial.

### Content:
- **Layout General:** Container redondeado y oscuro usado para enmarcar.
- **Title:** "Candidate ID" y Botón "Enroll".
- **InfoTags (`_infoTag`):** Fichas tipo Chip informativas generadas estáticamente (ej, fondo azulado). Tienen `BorderRadius.circular(6)`.
- **StatRangeBar (`_buildStatRangeBar`):** Barra doble para simular incertidumbre. Stack con un contenedor base gris, y otro contenedor que representa la brecha entre el Stat Min y Max del joven. Posicionado usando Alignment o offsets/width para dar un efecto visual de progreso condicional ("Entre X y Y de potencial histórico").

---
