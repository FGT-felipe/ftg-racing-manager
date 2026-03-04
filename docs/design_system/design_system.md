# FTG Racing Manager — Consolidated Design System V3
**Fecha:** 2026-03-01  
**Fuente:** Extracción literal del código Dart (`lib/`)  
**Regla:** Solo tokens y valores existentes en el código. Ningún diseño inventado.

---

## 1. Design Tokens

### 1.1 Color Palette — Core (from `app_theme.dart`)

| Token | Hex | CSS Variable | Uso |
|:---|:---|:---|:---|
| `appBackground` | `#15151E` | `--app-bg` | `scaffoldBackgroundColor`, fondo global |
| `textNormal` | `#FFFFFF` | `--text-normal` | `onSurface`, texto principal |
| `accentHighlight` | `#C1C4F4` | `--accent-highlight` | Íconos, badges, highlights, `secondary` |
| `primaryButton` | `#3A40B1` | `--primary-button` | `primary` color scheme, botones, sliders |
| `secondaryButton` | `#292A33` | `--secondary-button` | Card bg, outlined buttons, nav bg |
| `buttonHover` | `#424686` | `--button-hover` | Hover state botones |
| `error` | `#EF5350` | `--error` | Error states |

### 1.2 Color Palette — Extended (Hardcoded across widgets)

| Token | Hex | CSS Variable | Ubicaciones |
|:---|:---|:---|:---|
| Deep Charcoal | `#121216` | `--deep-charcoal` | `DriverCard`, `TransferMarketDriverCard` bg |
| Deep Black / Onyx | `#121212` | `--deep-black` | `FinanceCard`, `SetupCard`, `DriverStyleCard`, `Checklist`, `GarageScreen` |
| Card Gradient Start | `#1E1E1E` | `--card-grad-start` | Múltiples cards (topLeft) |
| Card Gradient End | `#0A0A0A` | `--card-grad-end` | Múltiples cards (bottomRight) |
| Success Green | `#00C853` | `--success-green` | `OnyxTable` highlight, `RaceStatusHero`, `NotificationCard`, `FitnessBar`, `LoadingIndicator` |
| Neon Green | `#00E676` | `--neon-green` | `DriverCard` accent, `RadarChart`, level badge ÉLITE, qualifying session |
| Gold | `#FFD700` | `--gold` | Valores monetarios, `FinanceCard`, `PitBoardField`, `LapCounter`, office notification |
| Amber | `#FFC107` | `--amber` | `NewBadge`, `TransferMarket` badge, `PlaceBid` button, star potential |
| Soft Red | `#FF5252` | `--soft-red` | Live indicator, race status, LIVE badge, progress bar, `CancelTransfer` |
| Qualifying Yellow | `#FFB800` | `--qualifying-yellow` | Qualifying status, `CircuitIntel`, `EventFeed` header, `QualyResults` gold positions |
| Strategy Orange | `#FF6D00` | `--strategy-orange` | Race strategy status |
| Warning Amber | `#FFAB00` | `--warning-amber` | Pending checklist |
| Post-Race Grey | `#9E9E9E` | `--post-race-grey` | Post-race status |
| Newspaper Paper | `#F4F1EA` | `--newspaper-paper` | `PressNewsCard` bg |
| Neon Pink | `#FF00FF` | `--neon-pink` | `DriverCard` flip badge |
| Stat Blue Grey | `#A0AEC0` | `--stat-blue-grey` | `DriverCard` contract labels, stat names |
| Yellow Star / Pro | `#FFEE58` | `--yellow-star` | Pro level badge, medium stat indicator |
| Red Danger | `#FF3D3D` | `--red-danger` | Most Risky driving style |
| Blue Defensive | `#42A5F5` | `--blue-defensive` | Defensive driving style |
| Orange Attack | `#FF9800` | `--orange-attack` | Offensive driving style |
| Electric Blue | `#00B0FF` | `--electric-blue` | `_buildPotentialStars` current stars (DriverCard) |
| Fastest Lap Purple | `#E040FB` | `--fastest-lap-purple` | Fastest lap holder in Race Day, Internal Timing |
| Commentary Cyan | `#00BCD4` | `--commentary-cyan` | Commentary feed border/header/text |
| Commentary Gold | `#FFD54F` | `--commentary-gold` | Player team commentary highlights |
| Internal Timing Green | `#00FF88` | `--timing-green` | Internal Timing Card accent |
| Internal Timing Dark | `#1A1A1A` | `--timing-dark` | Internal Timing Card text (light-surface widget) |
| CRT Background | `#080810` | `--crt-bg` | Commentary feed container |

### 1.3 Semantic Color Scales

#### Race Status Colors
| Estado | Color | Hex |
|:---|:---|:---|
| Practice (Paddock Open) | Success Green | `#00C853` |
| Qualifying | Qualifying Yellow | `#FFB800` |
| Race Strategy | Strategy Orange | `#FF6D00` |
| Race (Live) | Soft Red | `#FF5252` |
| Post-Race | Post-Race Grey | `#9E9E9E` |

#### Driver Stat Indicator (displayValue /20)
| Rango | Umbral | Color | Hex |
|:---|:---|:---|:---|
| High | ≥15 | Neon Green | `#00E676` |
| Medium | ≥10 | Yellow Star | `#FFEE58` |
| Low | <10 | Soft Red | `#FF5252` |

#### Driver Level Badges
| Stars | Label | Color | Hex |
|:---|:---|:---|:---|
| ≥5 | ÉLITE | Neon Green | `#00E676` |
| ≥4 | PRO | Yellow Star | `#FFEE58` |
| <4 | AMATEUR | Stat Blue Grey | `#A0AEC0` |

#### Fitness Bar Colors
| Fitness | Umbral | Color | Hex |
|:---|:---|:---|:---|
| High | ≥75 | Success Green | `#00C853` |
| Medium | 40-74 | Qualifying Yellow | `#FFB800` |
| Low | <40 | Soft Red | `#FF5252` |

#### Driving Style Colors
| Style | Color | Hex |
|:---|:---|:---|
| Most Risky | Red Danger | `#FF3D3D` |
| Offensive | Orange Attack | `#FF9800` |
| Normal | Success Green | `#00C853` |
| Defensive | Blue Defensive | `#42A5F5` |

#### Tyre Compound Colors
| Compound | Garage (pure) | Strategy (accent) |
|:---|:---|:---|
| Soft | `Colors.red` | `Colors.redAccent` |
| Medium | `Colors.yellow` | `Colors.yellowAccent` |
| Hard | `Colors.white` | `Colors.white70` |
| Wet | `Colors.blue` | `Colors.blueAccent` |

> **⚠️ Inconsistencia:** `garage_screen.dart` usa colores puros, `race_strategy_screen.dart` y `race_day_screen.dart` usan variantes Accent.

#### Confidence Colors (Feedback)
| Threshold | Color | Hex |
|:---|:---|:---|
| ≥ 0.98 | Green | `#00C853` |
| > 0.90 | Light Green | `#64DD17` |
| > 0.70 | Yellow | `#FFB800` |

#### Leaderboard Position Colors
| Position | Color |
|:---|:---|
| P1-P3 (con tiempo) | `#FFB800` (Gold) |
| P4+ (con tiempo) | white alpha 0.9 |
| DNF | `#FF5252` |

#### Weather Gradients (Circuit Intel)
| Weather | Gradient Start | Gradient End |
|:---|:---|:---|
| Rain/Storm | `#222222` | `#0A0A0A` |
| Partly Cloudy | `#121E2A` | `#05080A` |
| Cloudy/Overcast | `#1E222A` | `#0A0B0F` |
| Sunny (default) | `#453018` | `#0F0B08` |

#### Circuit Chip Priority Colors
| Priority | Background | Text Color |
|:---|:---|:---|
| Critical/High | `#FF5252` alpha 0.1 | `#FF5252` |
| Medium/Default | `#FFB800` alpha 0.1 | `#FFB800` |
| Low | `#00C853` alpha 0.1 | `#00C853` |
| Weather | weatherColor alpha 0.1 | weatherColor |

#### Event Feed Type Colors
| Type | Color | Hex |
|:---|:---|:---|
| OVERTAKE | Success Green | `#00C853` |
| PIT | Qualifying Yellow | `#FFB800` |
| DNF | Soft Red | `#FF5252` |
| INFO | Blue Accent | `Colors.blueAccent` |
| Default | White Muted | `Colors.white54` |

#### Notification Type Colors
| Type | Color |
|:---|:---|
| ALERT | `Colors.orangeAccent` |
| SUCCESS | `#00C853` |
| TEAM | `theme.colorScheme.secondary` |
| OFFICE (RACE_RESULT) | `#FFD700` |
| OFFICE (QUALY_RESULT) | `Colors.tealAccent` |
| OFFICE (other) | `Colors.blueGrey` |
| NEWS / default | `Colors.blueAccent` |

#### Car Schematic Stat Colors
| Stat | Color |
|:---|:---|
| Power | `Colors.orangeAccent` |
| Aero | `Colors.cyanAccent` |
| Handling | `Colors.purpleAccent` |
| Reliability | `Colors.greenAccent` |

---

## 2. Typography System

### 2.1 Font Stack

| Fuente | Paquete | Uso Principal |
|:---|:---|:---|
| **Poppins** | Google Fonts | Títulos, headings, labels, AppBar, badges, nav tabs (`w900` dominante) |
| **Raleway** | Google Fonts | Body text, buttons, breadcrumbs, loading phrases |
| **Montserrat** | Google Fonts | Logo "FTG", DriverCard (nombre, badges, contract), brand typography (`w900`, `w600`) |
| **Inter** | Google Fonts | OnyxTable data cells, CleanTable data rows |
| **Roboto Mono** | Google Fonts | Market value, stat display values, Internal Timing card data |
| **Merriweather** | Google Fonts | PressNewsCard headlines (newspaper serif) |
| **Playfair Display** | Google Fonts | "MOTORSPORT DAILY" header |
| **Oswald** | Google Fonts | PressNewsCard type labels, article button |
| **PT Serif** | Google Fonts | PressNewsCard dialog body text |
| `monospace` | System | Financial values, countdown numbers, checklist status, pit board, lap times |
| `Courier` | System | PressNewsCard timestamps |

### 2.2 Type Scale (Theme-level)

| Style | Font | Weight | Size | Extra |
|:---|:---|:---|:---|:---|
| `headlineMedium` | Poppins | `w900` | — | Títulos principales |
| `headlineSmall` | Poppins | `w900` | — | Subtítulos |
| `titleLarge` | Poppins | `w900` | — | Títulos de sección |
| `bodyLarge` | Raleway | normal | 16px | Cuerpo principal |
| `bodyMedium` | Raleway | normal | 14px | alpha 0.8 |
| `labelLarge` | Raleway | bold | — | Labels |

### 2.3 Component-Specific Typography

| Context | Font | Weight | Size | Letter-Spacing | Extra |
|:---|:---|:---|:---|:---|:---|
| **AppBar title** | Poppins | `w900` | 20px | 1.5 | — |
| **OnyxTable header** | Poppins | `w700` | 10px | 1.1 | `.toUpperCase()`, white alpha 0.4 |
| **OnyxTable data** | Inter | `w500` | 12px | — | white alpha 0.9 |
| **DriverCard name** | Montserrat | `w900` | 22px | -0.5 | `.toUpperCase()` |
| **DriverCard stat label** | Montserrat | bold | 8px | 0.2 | `#A0AEC0` |
| **DriverCard stat value** | Roboto Mono | `w900` | 13px | — | Colored by range |
| **Market value** | Roboto Mono | `w900` | 20px (card) / 24px (transfer) | — | White |
| **Section header label** | — | `w900` | 9px | 1.5 | `.toUpperCase()`, white alpha 0.4 |
| **Countdown number** | monospace | `w900` | 20px | — | White |
| **Breadcrumb link** | Raleway | `w500`/bold | 11px | 1.0 | `.toUpperCase()` |
| **Badge text** | — | `w900` | 12px | 1.5 | Colored |
| **Logo "FTG"** | Montserrat | `w900` | `size * 0.6` | -1.0 | height 1.0 |
| **Logo "RACING MANAGER"** | Montserrat | `w600` | `size * 0.18` | 2.5 | — |
| **Newspaper headline** | Merriweather | `w900` | 14px | — | black87, height 1.2 |
| **Newspaper header** | Playfair Display | bold | 10px | 1.5 | black87 |
| **Newspaper type** | Oswald | `w600` | 9px | 0.5 | black54 |
| **Newspaper body** | PT Serif | normal | 14px | — | black87, height 1.6 |

---

## 3. Spacing & Layout

### 3.1 Border Radius Scale

| Token | Value | Usage |
|:---|:---|:---|
| `radius-sm` | `4px` | PressNewsCard, small badges |
| `radius-md` | `6px` | Level badges, circuit chips, tyre chips |
| `radius-lg` | `8px` | OnyxSkeleton, time blocks, qualifying panel |
| `radius-xl` | `12px` | Cards, containers, badges, inputs (standard) |
| `radius-2xl` | `16px` | DriverCard, Standings container |
| `radius-pill` | `20px` / `100px` | Copy badges, pit stop chips |
| `radius-stadium` | `50px` / `100%` | Buttons (StadiumBorder) |

### 3.2 Standard Spacing

| Token | Value | Usage |
|:---|:---|:---|
| `space-xs` | `4px` | Gaps between small elements |
| `space-sm` | `8px` | Inner gaps, chips |
| `space-md` | `12px` | Card gaps, section padding |
| `space-lg` | `16px` | Section spacing, card padding |
| `space-xl` | `20px` | Container padding, margin |
| `space-2xl` | `24px` | Major section gaps, card padding |
| `space-3xl` | `32px` | Hero sections |

### 3.3 Layout Constraints

| Token | Value | Usage |
|:---|:---|:---|
| Content max width | `1600px` | Desktop content area |
| Dialog max width | `min(screenWidth * 0.85, 1200)` | Modal dialogs |
| NavigationRail min width | `80px` | Desktop sidebar |
| Desktop breakpoint | `800px` | Rail ↔ BottomNav switch |
| Driver selector card width | `220px` | Garage horizontal scroll |
| Driver selector height | `110px` | Garage card height |

---

## 4. Shadow & Elevation System

| Level | Shadow | Usage |
|:---|:---|:---|
| **Subtle** | `0 2px 4px rgba(0,0,0,0.3-0.4)` | Unselected cards, small elements |
| **Default** | `0 4px 8px rgba(0,0,0,0.3-0.4)` | Notification cards, CTA buttons |
| **Elevated** | `0 6px 12px rgba(0,0,0,0.4)` | Personal cards, sponsor cards, finance header |
| **Prominent** | `0 8px 15px rgba(0,0,0,0.3-0.4)` | FinanceCard, InstructionCard, pit boards |
| **Hero** | `0 10px 20px rgba(0,0,0,0.5)` | RaceStatusHero, DriverCard, race header |
| **Maximum** | `0 12px 24px rgba(0,0,0,0.4)` | Standings container |
| **Accent Glow** | `0 0 12px color(alpha 0.3)` | DriverCard left accent, stat bars |

---

## 5. Animation System

| Widget | Type | Duration | Curve | Detail |
|:---|:---|:---|:---|:---|
| `OnyxSkeleton` | Shimmer alpha | 1500ms | `easeInOut` | Alpha 0.05→0.12, loop reverse |
| `NewBadgeWidget` | Pulse fade | 1000ms | `easeInOut` | Opacity 0.5→1.0 (star icon), loop reverse |
| `DynamicLoadingIndicator` | Text switcher | 500ms | fade | Frases rotan cada 3s |
| `DriverCard` | Flip 3D | 600ms | `easeInOut` | rotateY 0→π |
| `RaceStatusHero` | Blinking dot | 1000ms | — | FadeTransition del dot rojo, loop |
| `RaceStatusHero` | Timer tick | 1000ms | — | Countdown en tiempo real |
| `RaceDayScreen` | Pulse (LIVE) | 1000ms | — | FadeTransition controller, loop |
| `GarageScreen` | Blinking text | 1000ms | — | Qualifying session text, repeat(reverse) |
| `GarageScreen` | Driver selector | 250ms | — | AnimatedContainer state change |
| `GarageScreen` | Style buttons | 200ms | — | AnimatedContainer hover/selected |
| `GarageScreen` | Copy badge | 150ms | — | AnimatedContainer hover |
| `GarageScreen` | Pit board msg | 500ms | fade | AnimatedSwitcher message swap |
| `Commentary` | Typewriter | 18ms/tick | — | 2 chars/tick, "▌" cursor |

---

## 6. Component Library

### 6.1 Common Widgets (`lib/widgets/common/`)

#### OnyxTable
**File:** `onyx_table.dart` (240 lines)  
**Type:** Reusable data table with fixed header and scrollable rows.

| Part | Style |
|:---|:---|
| **Header bg** | white alpha 0.03 |
| **Header border** | white alpha 0.05 (bottom) |
| **Header font** | Poppins `w700`, 10px, ls 1.1, white alpha 0.4, `.toUpperCase()` |
| **Row padding** | v14 h20 |
| **Row border** | white alpha 0.05, width 0.5 (bottom) |
| **Even rows** | transparent |
| **Odd rows** | white alpha 0.01 |
| **Hover** | `#00C853` alpha 0.05 |
| **Highlighted** | `#00C853` alpha 0.1 + border-left 4px `#00C853` |
| **Data font** | Inter `w500`, 12px, white alpha 0.9 |
| **Highlighted font** | Inter `w900`, `#00C853` |
| **Position col** | white alpha 0.5, `w500` |
| **Last col** | white alpha 0.9, `w700` |

**Used in:** `StandingsScreen`, `TransferMarketScreen`, `FinancesScreen`, `GarageScreen`

#### OnyxSkeleton
**File:** `onyx_skeleton.dart` (61 lines)  
**Type:** Loading shimmer placeholder.

- Color: white alpha 0.05 → 0.12
- Duration: 1500ms, `easeInOut`, loop reverse
- Border radius: configurable, default `8`

#### NewBadgeWidget
**File:** `new_badge.dart` (117 lines)  
**Type:** Pulsing "NEW" amber badge.

- Background: `Colors.amber`
- Padding: h6 v2, radius 12
- Shadow: amber alpha 0.4, blur 4, offset (0,2)
- Transform: `Offset(8, -8)` from parent
- Star icon: white, 10px, pulsing (0.5→1.0, 1s loop)
- Text: "NEW", white, 8px, bold, ls 0.5
- Visibility: `createdAt < 7 days` or `forceShow`

#### InstructionCard
**File:** `instruction_card.dart` (81 lines)  
**Type:** Onboarding/info card with gradient.

- Padding: 24
- Gradient: primary alpha 0.1 → `#0A0A0A`
- Border: primary alpha 0.3, width 1, radius 12
- Shadow: black alpha 0.4, blur 15, offset (0,8)
- Title: Poppins `w900`, 20px, ls 1.5, primary alpha 0.9
- Icon: 32px, primary color
- Description: `bodyMedium`, height 1.5, `onSurface` alpha 0.8

#### DriverStars
**File:** `driver_stars.dart` (39 lines)  
**Type:** Inline star rating for tables.

| State | Color | Icon |
|:---|:---|:---|
| Current | `Colors.blueAccent` | `star_rounded` |
| Potential | `Colors.amber` alpha 0.5 | `star_rounded` |
| Empty | white alpha 0.2 | `star_outline_rounded` |

Size: 14px default.

> **Note:** Different from `_buildPotentialStars` in DriverCard which uses `#00B0FF` with glow / `#FFD700` with glow at 24px.

#### DynamicLoadingIndicator
**File:** `dynamic_loading_indicator.dart` (110 lines)

- Spinner: `CircularProgressIndicator`, color `#00C853`
- Text: Raleway, 14px, white70, ls 1
- Transition: AnimatedSwitcher, 500ms fade
- Rotation: every 3s (configurable)

#### Breadcrumbs
**File:** `breadcrumbs.dart` (94 lines)

- Separator: "/" in Raleway, 12px, white alpha 0.2
- Link: Raleway, 11px, ls 1.0, `.toUpperCase()`
- Active (last): white, bold
- Inactive: white alpha 0.5, `w500`, hover → white
- Cursor: click (if `onTap`), basic (last)

#### AppLogo
**File:** `app_logo.dart` (56 lines)

- "FTG": Montserrat `w900`, `size * 0.6`, ls -1.0, height 1.0
- "RACING MANAGER": Montserrat `w600`, `size * 0.18`, ls 2.5
- Color: `onSurface`
- Default size: 40

### 6.2 Feature Widgets (`lib/widgets/`)

#### NotificationCard
**File:** `notification_card.dart` (178 lines)

- Container: cardTheme.color, radius 12, shadow black alpha 0.4 blur 8 offset (0,4)
- Border: transparent (read) / `iconColor` alpha 0.2 (unread)
- Icon container: circular, `iconColor` alpha 0.1 bg
- Type label: Poppins, 10px, bold, iconColor, ls 1.2
- Title: Poppins, 14px, bold
- Message: 13px, `onSurface` alpha 0.7, height 1.4
- Timestamp: 10px, `onSurface` alpha 0.4

#### PressNewsCard
**File:** `press_news_card.dart` (333 lines)  
**Theme:** Light (newspaper-style, unique in the app)

- Card: `#F4F1EA` bg, radius **4**, border black alpha 0.2, shadow black alpha 0.1 blur 4 offset (2,2)
- Header: Playfair Display 10px bold, ls 1.5, black87
- Type: Oswald 9px `w600`, black54, ls 0.5
- Date: Courier 9px, black54
- Headline: Merriweather 14px `w900`, black87, height 1.2
- Button: border black87 radius 2, Oswald 10px bold
- Dialog bg: `#F4F1EA`, headline Merriweather 22px `w900`, body PT Serif 14px, height 1.6

#### CarSchematicWidget
**File:** `car_schematic_widget.dart` (120 lines)

- Container: 180px width, padding 16, cardTheme.color alpha 0.5, radius 12, border white10
- Stats: 4 bars (Power/orange, Aero/cyan, Handling/purple, Reliability/green)
- Label: 10px, white60, `w500`
- Value: 11px, bold, stat color
- Progress bar: 2px height, bg white alpha 0.05, bar color alpha 0.8

#### CarSelector
**File:** `car_selector.dart`

- Arrow buttons: circular 40x40, bg white alpha 0.05, border secondary alpha 0.2
- Icon: chevron, secondary color, 24px
- Index label: Poppins 11px `w700`, white38, ls 1.2

#### FuelInput
**File:** `fuel_input.dart` (99 lines)

- Size: 65x28px
- Background: white alpha 0.05, radius 12, border white alpha 0.1
- Input: 11px, bold, `Colors.orange`, center-aligned
- Suffix "L": 8px, white24, bold

#### ResponsiveMainScaffold
**File:** `responsive_shell.dart` (158 lines)

**Desktop (≥800px):**
- NavigationRail: labelType all, groupAlignment -0.9, minWidth 80
- Divider: dividerColor alpha 0.1
- Content: maxWidth 1600

**Mobile (<800px):**
- BottomNavigationBar + border top dividerColor alpha 0.1

**Nav Items:**
| Item | Outline Icon | Selected Icon |
|:---|:---|:---|
| HQ | `dashboard_rounded` | `dashboard` |
| Office | `business_center_outlined` | `business_center` |
| Garage | `build_circle_outlined` | `build_circle` |
| Season | `emoji_events_outlined` | `emoji_events` |
| Market | `groups_outlined` | `groups` |

### 6.3 Dashboard Widgets (`lib/screens/home/dashboard_widgets.dart`)

#### TeamHeader
- Avatar: 60x60 circle, teamColor alpha 0.2 bg, border 2px
- Icon: `Icons.shield`, teamColor, 30px
- Manager: `bodyMedium` theme
- Team name: `headlineMedium` `w900`, ls 1.0, `.toUpperCase()`

#### StatusCard
- Background: cardTheme.color, radius 12
- Gradient: mainColor alpha 0.1 → transparent
- Status text: mainColor, bold, ls 2.0, 12px, `.toUpperCase()`
- Time: mainColor, 28px, `w900`

#### FinanceCard
- Container: gradient `#1E1E1E`→`#0A0A0A`, border white alpha 0.1, radius 12, shadow blur 15
- Label: 9px, bold, ls 1.2, white alpha 0.4
- Value: monospace, 18px, `w900`, `#FFD700`
- Status: 9px, `w900`, ls 1.0, green/red

#### RaceStatusHero
**Complex widget with real-time countdown.**

- Container: gradient `#1E1E1E`→`#0A0A0A`, border white alpha 0.1, shadow blur 20, radius 12
- Weather bg: 200px, opacity 0.05, positioned right -20 top -20
- Status badge: padding h12 v6, statusColor alpha 0.1 bg, statusColor border, radius 12
- Circuit name: 24px, `w900`, white, ls 1.0
- Time blocks: bg white alpha 0.05, radius 8, monospace 20px `w900`
- Live dot: blinking, `#FF5252`, 12px, FadeTransition loop
- CTA button: gradient `#2A2A2A`→`#000`, border `#00C853` alpha 0.3, radius 100 (stadium)

#### PreparationChecklist
- Container: same as FinanceCard (gradient, border, shadow)
- Title: white alpha 0.4, 9px, bold, ls 1.5
- Items: 11px, `w900`, white, ls 0.5, `.toUpperCase()`
- Complete badge: `#00C853` alpha 0.1 bg, alpha 0.5 border, radius 12
- Pending badge: `#FFAB00` alpha 0.1 bg

### 6.4 Driver Cards

#### DriverCard (`lib/screens/drivers/widgets/driver_card.dart`)
**Type:** Flip 3D card with radar chart, front/back views.

- Container: margin v12 h16, bg `#121216`, radius **16**, border white alpha 0.05, shadow blur 20
- Grid pattern: white alpha 0.03, step 30px
- Left accent: 4px `#00E676`, top 24 bottom 24, glow blur 12
- Flip badge: `#FF00FF` alpha 0.1 bg, neon pink border/text
- Transfer ribbon: amber bg, -45° rotation, bold 10px
- Portrait: 80x80 circle, levelColor border 3px, glow blur 20
- Name: Montserrat `w900`, 22px, ls -0.5, `.toUpperCase()`
- Age: Montserrat `w600`, 14px, `#FFC107`
- Contract section: white alpha 0.02 bg, radius 12
- Stat indicators: 2-column grid, 4px bars with glow on high stats
- Radar chart: 200x200, 5 rings, `#00E676` fill alpha 0.4

#### TransferMarketDriverCard (`lib/screens/market/widgets/`)
**Differences from DriverCard:**
- No flip animation
- Radar chart: 300x300 (vs 200x200)
- Market value: 24px (vs 20px)
- Stats labels: white70, 10px (vs `#A0AEC0`, 8px)
- Uses `_buildCleanTable` (vs `_buildTinyTable`)
- Includes Morale, Marketability, Termination cost

### 6.5 Garage & Race Screens

#### GarageScreen — Driver Selector
- Card: 220x110, AnimatedContainer 250ms
- Selected: gradient `#2A2A2A`→`#121212`, border primary 2px, shadow primary alpha 0.3
- Unselected: gradient `#1E1E1E`→`#0A0A0A`, border white alpha 0.1 1px
- Portrait: 35% width, gradient fade
- Name: 12px, `w900`, ls 0.5, white (selected) / white alpha 0.5

#### GarageScreen — Setup Card
- Container: `#121212`, radius 12, border white alpha 0.08, shadow blur 20
- Gradient overlay: white alpha 0.02 → transparent
- Title: 13px, `w900`, ls 2.0, `.toUpperCase()`
- Compact Slider: track 3px, thumb radius 6, secondary color
- Tyre compound chips: padding h10 v6, radius 6
- Pit stop chips: padding h10 v6, radius 12

#### GarageScreen — Driver Style Card
- Container: `#121212`, radius 12, border white alpha 0.08, shadow blur 16
- Buttons: 48x48, radius 10
- Selected: color alpha 0.18 bg, color border 1.5px, glow
- Unselected: white alpha 0.03 bg, white alpha 0.08 border

#### GarageScreen — Pit Board
- Container: gradient `#1E1E1E`→`#0A0A0A`, border white alpha 0.1, radius 12
- Header: primary icon + "PIT BOARD", ls 2.0
- Message: monospace, `w900`, 14px, ls 1.5

#### GarageScreen — Circuit Intel
- Height: 80px, border white alpha 0.1, radius 12
- Weather-themed gradient (see Weather Gradients table)
- Background weather icon: 100px, accentColor alpha 0.12
- Header: "CIRCUIT INTEL" white `w900` 9px ls 1.5
- Chips: padding h8 v3, radius 6, 10px bold

#### Qualifying Results Table
- Panel: black bg, border white alpha 0.1, radius 8
- Gold header: `#FFB800` alpha 0.1 bg, icon + "QUALIFYING RESULTS" 13px
- Column headers: 9px `w900` ls 1.0, white38
- Player row: secondary alpha 0.1 bg, left border 3px secondary

### 6.6 Race Day (`lib/screens/race/race_day_screen.dart`)

#### Race Header
- Container: gradient `#1E1E1E`→`#0A0A0A`, border white alpha 0.1, shadow blur 20
- LIVE badge: `#FF5252` alpha 0.15 bg, alpha 0.5 border, pulsing dot
- FINISHED: `#00C853` alpha 0.1 bg, alpha 0.4 border
- PRE-RACE: white alpha 0.05 bg, alpha 0.1 border
- Lap counter: monospace 22px `w900` white / 14px bold white alpha 0.4
- Progress bar: 6px height, `#FF5252` (live) / `#00C853` (finished)
- Fastest lap: `#E040FB` 11px bold monospace

#### Leaderboard
- Container: `#0A0A0A`, radius 12, border white alpha 0.08
- Header: `#FF5252` alpha 0.08 bg, "RACE POSITIONS" 11px `w900`
- Player highlight: secondary alpha 0.08 bg, left border 3px
- Position arrows: up `#00C853` / down `#FF5252` / same white alpha 0.3

#### Event Feed
- Container: `#0A0A0A`, radius 12, border white alpha 0.08
- Header: `#FFB800` alpha 0.08 bg, "PIT BOARD" 11px `w900`
- Lap badge: 36px wide, 9px `w900`, white alpha 0.4
- Type badge: padding h6 v2, radius 8, event color alpha 0.1 bg

#### Commentary Feed (CRT Style)
- Container: `#080810` bg, radius 12, border `#00BCD4` alpha 0.15
- Header gradient: `#00BCD4` alpha 0.12 → `#080810`
- "ON AIR" badge: `#00BCD4` alpha 0.15 bg, alpha 0.4 border, 8px `w900`
- Scan lines: CustomPainter, every 3px, black alpha 0.04
- Player text: `#FFD54F` (newest alpha 1.0, older alpha 0.7)
- Non-player text: white alpha 0.95 (newest) / alpha 0.5 (older)
- Typewriter: 18ms/tick, 2 chars, "▌" cursor

### 6.7 Office & Finance Screens

#### Finances Balance Header
- Container: gradient `#1E1E1E`→`#0A0A0A`, padding 32, radius 12
- Label: grey, 12px, bold, ls 1.5
- Amount: 42px, `w900`, redAccent (negative) / onSurface (positive)

#### Transaction Tile
- Container: `#121212`, radius 12, border white alpha 0.05
- Icon container: iconColor alpha 0.1 bg, padding 10, radius 12
- Title: bold
- Amount: bold, 16px, green (+) / red (-)

#### Transfer Budget Card
- Container: `#15151A`, radius 12, border primaryColor alpha 0.2, padding 20
- Wrapped in NewBadgeWidget (bottomRight)
- Slider: 10-90%, activeColor primaryColor

#### Sponsor Offer Card
- Container: gradient `#1E1E1E`→`#0A0A0A`, radius 12, border white alpha 0.1
- Title: Poppins `w900`, 16px, white, ls 1.2
- Tactic buttons: stadium shape, mute default (white alpha 0.05 bg), reveal color on hover
  - Persuasive: `#FF5733`
  - Negotiator: `#F1C40F`
  - Collaborative: `#E9967A`

### 6.8 Onboarding & Misc

#### Team Selection Card
- Gradient: `#1A1A1A` → `#121212`
- Border: dynamic (amber alpha 0.3 if occupied, white10 locked, white24 normal)
- Blueprint bg: opacity 0.15
- "SELECTED" ribbon: 45° rotation, amber bg

#### Calendar Event Item
- Current round: primaryColor alpha 0.1 bg, primaryColor 2px border
- Normal: cardTheme default
- Round number: yellow/primary
- Track name: `.toUpperCase()`, `w900`

#### Youth Academy Candidate Card
- Container: `#121212`, radius 12, border white alpha 0.05
- InfoTags: chip style, radius 6
- StatRangeBar: stacked bars showing min-max uncertainty

#### Internal Timing Card
- **! Light surface anomaly** — uses `#1A1A1A` text on light bg (`surface`)
- Title: "INTERNAL TIMING", `#00FF88` icon, `#1A1A1A` text
- Header: `#00FF88` alpha 0.1 bg, Roboto Mono 12px bold
- Fastest row: `#00FF88` alpha 0.15 bg
- Data: Roboto Mono, `#1A1A1A`

---

## 7. Table Variants

| Table | File | Header Font | Data Font | Zebra | Highlights |
|:---|:---|:---|:---|:---|:---|
| **OnyxTable** | `onyx_table.dart` | Poppins `w700` 10px | Inter `w500` 12px | white alpha 0.01 | `#00C853` bg + left border |
| **TinyTable** | `driver_card.dart` | labelSmall, secondary alpha 0.7 | Roboto Mono 11px | white alpha 0.05 (odd) | — |
| **CleanTable** | `transfer_market_driver_card.dart` | Montserrat white30 10px | Inter white70 11px | white alpha 0.05 (odd) | — |
| **QualyResults** | `garage_screen.dart` | custom w900 9px white38 | mixed 11px | — | secondary alpha 0.1 + left border |
| **Leaderboard** | `race_day_screen.dart` | w900 9px white alpha 0.3 | mixed 10-13px | — | secondary alpha 0.08 + left border |

---

## 8. Repeated Container: Gradient + Border (observed in 10+ widgets)

> **Note:** This is NOT a named widget or class in the code. It is a repeated inline `BoxDecoration` pattern found across multiple widgets.

```dart
// Example from FinanceCard (dashboard_widgets.dart L83-95)
decoration: BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
  ),
  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ],
)
```

**Found in:** `FinanceCard`, `PreparationChecklist`, `RaceStatusHero`, `_buildPitBoard`, `SetupCard`, `_buildDriverSelector` (unselected), `StandingsScreen`, `SponsorOfferCard`, `_buildBalanceHeader`, `_buildCircuitIntel`.

---

## 9. RaceStatusHero — statusText Container (dashboard_widgets.dart L559-577)

> **Note:** This is NOT a named component. It is the inline `Container` + `BoxDecoration` used inside `RaceStatusHero.build()` to display the current race week status.

```dart
// Actual code from dashboard_widgets.dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: statusColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: statusColor),
  ),
  child: Text(
    statusText, // from AppLocalizations
    style: TextStyle(
      color: statusColor,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
      fontSize: 12,
    ),
  ),
)
```

**statusColor values by status:**
| Status | Color | Hex |
|:---|:---|:---|
| practice | statusColor | `0xFF00C853` |
| qualifying | statusColor | `0xFFFFB800` |
| raceStrategy | statusColor | `0xFFFF6D00` |
| race | statusColor | `0xFFFF5252` |
| postRace | statusColor | `0xFF9E9E9E` |

---

## 10. Repeated Label TextStyle (observed in 6+ widgets)

> **Note:** This is NOT a named style or theme entry. It is a repeated inline `TextStyle` found across multiple widgets.

```dart
// Example from PreparationChecklist (dashboard_widgets.dart L1104-1109)
TextStyle(
  color: Colors.white.withValues(alpha: 0.4),
  fontSize: 9,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.5,
)
```

**Found in:** `FinanceCard` ("TEAM BUDGET"), `PreparationChecklist` ("PRE-RACE CHECKLIST"), `_buildCountdownRow` (countdown labels), `_buildPitBoardField` (field labels), `_buildCircuitIntel` ("CIRCUIT INTEL"), `SponsorOfferCard` header.

---

## 11. Known Inconsistencies

| Issue | Details | Location |
|:---|:---|:---|
| **Tyre colors** | Garage uses pure (`red`, `yellow`, `white`, `blue`), Strategy/RaceDay uses Accent variants | `garage_screen.dart` vs `race_strategy_screen.dart` / `race_day_screen.dart` |
| **Star rating** | `DriverStars` uses `blueAccent`/`amber 0.5`. `_buildPotentialStars` in DriverCard uses `#00B0FF` with glow / `#FFD700` with glow at 24px | `driver_stars.dart` vs `driver_card.dart` |
| **Internal Timing Card** | Uses `#1A1A1A` dark text on light surface — breaks the dark theme | `internal_timing_card.dart` |
| **Card backgrounds** | Some use `cardTheme.color` (`#292A33`), others use `#121212` / `#121216` directly | Multiple files |
| **Stat label color** | DriverCard uses `#A0AEC0`, TransferMarketDriverCard uses `Colors.white70` | Both card files |

---

## 12. File Inventory

### `lib/widgets/common/` (8 widgets)
| File | Widget | Category |
|:---|:---|:---|
| `onyx_table.dart` | OnyxTable | Data display |
| `onyx_skeleton.dart` | OnyxSkeleton | Loading state |
| `new_badge.dart` | NewBadgeWidget | Indicator |
| `instruction_card.dart` | InstructionCard | Info card |
| `driver_stars.dart` | DriverStars | Rating |
| `dynamic_loading_indicator.dart` | DynamicLoadingIndicator | Loading |
| `breadcrumbs.dart` | Breadcrumbs | Navigation |
| `app_logo.dart` | AppLogo | Branding |

### `lib/widgets/` (7 widgets)
| File | Widget | Category |
|:---|:---|:---|
| `notification_card.dart` | NotificationCard | Notification |
| `press_news_card.dart` | PressNewsCard | News card |
| `car_schematic_widget.dart` | CarSchematicWidget | Stats display |
| `car_selector.dart` | CarSelector | Livery picker |
| `fuel_input.dart` | FuelInput | Input control |
| `responsive_shell.dart` | ResponsiveMainScaffold | Layout |
| `auth_wrapper.dart` | AuthWrapper | Auth gate |

### `lib/screens/home/`
| File | Widgets |
|:---|:---|
| `dashboard_widgets.dart` | TeamHeader, StatusCard, FinanceCard, NewsItemCard, UpcomingCircuitCard, RaceStatusHero, PreparationChecklist |

### `lib/screens/drivers/widgets/`
| File | Widgets |
|:---|:---|
| `driver_card.dart` | DriverCard, RadarChartPainter, GridPainter |

### `lib/screens/market/`
| File | Widgets |
|:---|:---|
| `transfer_market_screen.dart` | TransferMarketScreen, _MarketCountdown, Bid Modal |
| `widgets/transfer_market_driver_card.dart` | TransferMarketDriverCard |

### `lib/screens/race/`
| File | Widgets |
|:---|:---|
| `garage_screen.dart` | GarageScreen (Practice/Qualifying/Race tabs), DriverSelector, CircuitIntel, PitBoard, DriverStyleCard, SetupCard, QualifyingResults |
| `race_strategy_screen.dart` | RaceStrategyScreen, Sliders, StyleSelector, PitStops |
| `race_day_screen.dart` | RaceDayScreen, Leaderboard, EventFeed, CommentaryFeed |
| `race_live_screen.dart` | RaceLiveScreen |
| `widgets/internal_timing_card.dart` | InternalTimingCard |

### `lib/screens/management/`
| File | Widgets |
|:---|:---|
| `personal_screen.dart` | PersonalScreen, _PersonalCard (COMING SOON ribbon) |

### `lib/screens/office/`
| File | Widgets |
|:---|:---|
| `finances_screen.dart` | BalanceHeader, TransactionTile, TransferBudgetCard |
| `sponsorship_screen.dart` | SponsorOfferCard, ActiveContractPanel |

### `lib/screens/standings/`
| File | Widgets |
|:---|:---|
| `standings_screen.dart` | StandingsScreen (3 tabs), Drivers/Constructors/Race Results |

### `lib/screens/onboarding/`
| File | Widgets |
|:---|:---|
| `team_selection_screen.dart` | TeamSelectionCard |

### `lib/screens/calendar/`
| File | Widgets |
|:---|:---|
| `calendar_screen.dart` | CalendarEventItem |

### `lib/screens/hq/`
| File | Widgets |
|:---|:---|
| `youth_academy_screen.dart` | CandidateCard, StatRangeBar |
