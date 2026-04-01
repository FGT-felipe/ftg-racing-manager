# Reglas de Negocio & Simulación: Manual del Staff

Esta sección documenta la lógica autoritativa del simulador y las reglas operativas de la plataforma, extraídas directamente de los servicios del frontend y el motor de Firebase.

---

## 1. Identidad y Carrera (Onboarding)
El rol del Manager define ventajas pasivas permanentes y limitaciones operativas.

### Roles de Manager
*   **Ex-Driver**:
    *   *Pace*: +2% velocidad en carrera (lt * 0.98).
    *   *Riesgo*: +0.001 de probabilidad base de accidente.
*   **Ex-Engineer**:
    *   *Engineering*: Permite 2 mejoras de coche por semana (otros: 1).
    *   *Qualy*: +5% velocidad en clasificación (lt * 0.95).
    *   *Tires*: -10% de desgaste de neumáticos en carrera.
    *   *Coste*: Las mejoras de piezas cuestan x2 (basado en Fibonacci).
*   **Business Admin**:
    *   *Economy*: 10% de descuento en upgrades de instalaciones.
    *   *Sponsors*: Multiplicador de pagos de +15%.
    *   *Pace*: -2% de velocidad en carrera (lt * 1.02).
*   **Bureaucrat**:
    *   *Academy*: Slots de academia extra (+2 por nivel).
    *   *Economy*: 10% de descuento en upgrades de instalaciones.
    *   *Limit*: Cooldown de 2 semanas tras cada mejora de coche.

### Gestión de Equipo
*   **Reclamo**: Solo se pueden reclamar equipos marcados como `isBot: true`.
*   **Cambio de Nombre**: El primer cambio es gratuito. Los siguientes cuestan **$500,000**.
*   **Divisiones**: La Liga 2 (`ftg_2th`) permanece bloqueada hasta que la Liga 1 (`ftg_world`) esté 100% llena de managers humanos.

---

## 2. Motor de Simulación y Física
Lógica determinista ejecutada en el backend para garantizar integridad.

### Reglas de Neumáticos
*   **Degradación Exponencial**: El tiempo de vuelta aumenta según `(Wear/100)^2 * 8.0s`.
*   **Efecto Clima**: 
    *   **Penalización de Superficie**: Toda sesión con lluvia añade un retraso base de **+1.5s** (incluso con el neumático correcto).
    *   **Neumáticos**: La lluvia añade **5.0s** de penalización extra por vuelta si no se usan neumáticos `Wet`. Los neumáticos `Wet` en seco penalizan **3.0s**.
    *   **Especialistas (Rain Master)**: Los pilotos con el rasgo `rainMaster` reciben un bono de ritmo (`df -0.015`) en sesiones de lluvia.
*   **Parc Fermé**: No se aplica si la sesión de Clasificación es con lluvia.
*   **Regla de Neumáticos de Salida (Qualy Wet -> Race Dry)**: Si la clasificación fue con lluvia (`weatherQualifying` incluye 'rain'/'wet'), se anula la obligación de empezar la carrera con el neumático de la mejor vuelta. El manager tiene libre elección para la carrera (si esta es en seco). En la UI, esto se refleja como "Elección Libre" frente a "Bloqueado por Qualy".
*   **Excepción de Compuestos**: En carreras con lluvia, no es obligatorio usar el compuesto `Hard`.

### Estrategia y Riesgo
*   **Estilo de Conducción**:
    *   *Most Risky*: +0.04 pace, probabilidad de choque 0.003, consumo combustible +35%, desgaste gomas +60%.
    *   *Offensive*: +0.02 pace, probabilidad de choque 0.0015, consumo combustible +15%, desgaste gomas +25%.
    *   *Defensive*: -0.01 pace, probabilidad de choque 0.0005, ahorro combustible 15%, ahorro gomas 25%.

---

## 3. Economía y Ciclos Semanales
El backend procesa la economía todos los lunes a las 00:00 UTC (Post-GP).

*   **Sueldos**: Los salarios anuales de pilotos y staff se dividen entre **52** para el pago semanal.
*   **Mantenimiento HQ**: Nivel de instalación * **$15,000** semanal.
*   **Entrenador de Fitness**: Coste semanal escalonado (Hasta **$500k** en nvl 5).
*   **Premios Qualy**: P1 ($50k), P2 ($30k), P3 ($15k).
*   **Premios Carrera**: Win ($500k), P2 ($350k), P3 ($250k). DNF garantiza un pago de consolación de $25k.

---

## 4. Ingeniería: La Curva Fibonacci
El coste de mejora de piezas sigue la secuencia de Fibonacci para evitar el "power creep".

*   **Fórmula**: `Nivel * Fibonacci(Nivel) * $100,000`.
*   **Nivel Máximo**: 20.
*   **Auto-Upgrade AI**: Los equipos bot tienen un 30% de probabilidad semanal de subir +1 nivel en Aero, Motor o Chasis de forma gratuita.

---

## 5. Academia y Desarrollo de Pilotos
Sistema de progresión basado en XP acumulado.

*   **Evolución**: Se requieren **500 XP** para subir +1 en `Base Skill`.
*   **Generación de XP**: Basado en el potencial del piloto + Nivel de Academia.
*   **Eventos de Crisis**: 15% de probabilidad semanal de evento negativo (Falta de foco, fatiga) si no hay crecimiento.
*   **Especialidades**: Un piloto de academia solo puede desbloquear una especialidad (Rainmaster, etc.) si su `Base Skill` es >= 8.
*   **Recuperación Física**: Los pilotos recuperan **+1.5%** de Fitness cada día a medianoche.
*   **Generación de Candidatos (Scouting)**:
    *   Toda sesión de scouting genera siempre **2 candidatos en simultáneo**.
    *   Distribución paritaria garantizada: **1 Hombre y 1 Mujer** por sesión.
    *   **Escalado por Nivel**: El nivel de la academia define el rango de estrellas inicial (Nivel 1: ~1.5 estrellas actuales, ~3.5 potenciales).

---

## 5.5 Sistema de Moral

**Rango:** 0–100%. Default: **70** (MORALE_DEFAULT) cuando el campo no existe.

**Efecto en simulación:** La moral afecta el laptime via la fórmula:
```
moraleFactor = MORALE_LAPTIME_FACTOR * (morale - MORALE_NEUTRAL) / 100
```
- `MORALE_LAPTIME_FACTOR = 0.02`, `MORALE_NEUTRAL = 50`
- A morale=100: −1% en laptime (piloto más rápido)
- A morale=0: +1% en laptime (piloto más lento)
- El factor se aplica tanto en la práctica (cliente) como en la carrera (CF)

**Psicólogo (HR Manager):**
- Instalación en `/management/personnel/hr-manager`
- Sesión manual: 1 vez por semana → boost de +5 a +20 puntos según nivel
- Niveles 1–5, mismo esquema de costos que el fitness trainer
- Salario semanal desde $0 (Nvl 1) hasta $500k (Nvl 5)

**Eventos que modifican la moral:**
| Evento | Delta |
|---|---|
| Ganar carrera | +15 |
| Podio (P2/P3) | +8 |
| Pole Position | +10 |
| Objetivo de patrocinador cumplido | +8 |
| P10+ (sin puntos) | −5 |
| DNF | −10 |
| Despido (`DISMISS_MORALE_PENALTY`) | −20 |
| Listado en mercado de transferencias | −10 |
| Negociación fallida (por intento) | −5 |
| Setup de práctica malo (< 60% confianza) | −5 |
| Setup de práctica bueno (> 85% confianza) | +1 |
| Sesión manual con psicólogo | +5 a +20 según nivel |

**Constantes:** `src/lib/constants/economics.ts` — `MORALE_DEFAULT`, `MORALE_NEUTRAL`, `MORALE_LAPTIME_FACTOR`, `MORALE_EVENT_*`

---

## 6. Mercado de Transferencias

### Flujo completo de transferencia (T-028)

1. **Listado**: El manager lista un piloto. Se descuenta la tarifa de listado (10% del valor de mercado). El piloto recibe penalización de moral (`MORALE_EVENT_TRANSFER_LISTED`).
2. **Subasta**: Las pujas duran **24 horas**. Puja mínima = `marketValue`; incremento = `TRANSFER_MARKET_BID_INCREMENT`.
3. **Resolución** (CF `resolveTransferMarket`, cada hora en :00): Al vencer el plazo:
   - **Sin puja**: El piloto se deslistea. Si no tiene equipo (generado por sistema), se elimina.
   - **Con puja ganadora**: La tarifa de transferencia (`highestBid`) se descuenta inmediatamente del budget del comprador. Se acredita al vendedor. El piloto entra en estado `pendingNegotiation = true`. La tarifa **NO se reembolsa** si las negociaciones fallan.
4. **Configuración de fichaje** (`TransferSetupModal`): El manager comprador selecciona:
   - Rol del piloto entrante: `main` | `secondary` | `equal` (no `reserve` — reservas son exclusivos de academia)
   - Piloto del equipo que será reemplazado (uno de los slots activos, carIndex 0 o 1)
5. **Negociación de contrato** (`NegotiationModal`): El manager propone salario y años. El piloto puede contra-proponer. Máx. 3 intentos (`NEGOTIATION_MAX_ATTEMPTS`). Cada intento fallido aplica penalización de moral (`NEGOTIATION_MORALE_PENALTY_PER_FAIL`).
6. **Cierre** (`staffService.finalizeTransferAcquisition`):
   - **Aceptado**: El piloto entra al equipo con el rol y slot del reemplazado. El reemplazado queda libre (`role: 'ex_driver'`, `teamId: null`) y se auto-lista en el mercado a su valor de mercado actual (**sin tarifa de listado**).
   - **Rechazado**: El piloto regresa a su equipo original. La tarifa de transferencia ya está perdida.

### Reglas adicionales
*   **Valor de Mercado**: Calculado con `calculateDriverMarketValue` — fórmula basada en potencial, rendimiento actual y edad. NO equivale al salario anual.
*   **Tarifa de Listado**: 10% del valor de mercado, deducida al publicar (`TRANSFER_MARKET_LISTING_FEE_RATE`). Exenta para auto-listados por reemplazo.
*   **Limpieza**: Los pilotos generados por el sistema sin equipo y sin pujas en 24h son eliminados.
*   **Roles de piloto**: Ver sección `role` en `database_schema.md`. Los pilotos del transfer market deben tener `role` poblado — si falta, la UI muestra "Unknown". El resolver no asigna rol (lo elige el manager en el setup).
*   **Universe sync**: El `scheduledHourlyMaintenance` (CF, :30 cada hora) reconstruye `universe/game_universe_v1` con `gender` y `countryCode` incluidos en cada entrada de piloto.

### Despido de Piloto (Dismiss)
*   **Coste**: Salario anual completo del piloto (indemnización por rescisión).
*   **Estado post-despido**: El piloto queda como agente libre (`teamId: null`, `role: 'Unassigned'`).
*   **Valor de mercado post-despido**: Se resetea al salario anual del piloto (ya no usa la fórmula de potencial).
*   **Penalización moral**: -20 puntos de moral al ser despedido (`DISMISS_MORALE_PENALTY`).
*   **Aviso de equipo**: Si el piloto despedido era titular y el equipo no tiene reservas, el equipo compite con un solo coche hasta contratar reemplazo.

---

## 7. Configuración de Carrera (Race Setup)
*   **Best Setup**: El sistema guarda automáticamente la configuración (`CarSetup`) de la mejor vuelta obtenida durante las sesiones de práctica. Esta configuración puede ser recuperada en la pestaña de Estrategia de Carrera mediante el botón "Best Setup".
*   **Preconfiguración**: Al iniciar la configuración de carrera, el sistema precarga el setup de Clasificación o Práctica si no existe una estrategia guardada previamente.
*   **Flexibilidad**: A diferencia de Clasificación (Parc Fermé), el manager tiene libertad total para ajustar los parámetros aerodinámicos y mecánicos antes del inicio oficial del Gran Premio.

---

## 8. Dashboard: Preparación de Carrera (Race Prep)
*   **Lógica de Preparación**: El indicador de "Readiness" en el dashboard se calcula en base a las tareas críticas del fin de semana.
*   **Setups de Carrera**: Este ítem se marca como completado (`isComplete`) únicamente cuando ambos pilotos principales tienen guardada una **Estrategia de Carrera** (pestaña Race Setup). Esto elimina la dependencia de completar sesiones previas (Práctica/Qualy) para ver el indicador en verde.
*   **Patrocinadores**: Requiere que el equipo tenga al menos un contrato de patrocinio activo para ser marcado como completado.
*   **Instalaciones (Opcional)**: Informa sobre el estado de las infraestructuras. Actualmente se considera completado por defecto si el equipo es válido.
