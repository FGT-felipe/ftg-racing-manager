# Postmortem — Transfer Market: Flujo Roto, Recovery Destructiva, Datos Congelados

**Fecha:** 2026-03-31
**Fecha cierre:** 2026-04-01
**Severidad:** Alta
**Estado:** CERRADO. Todos los fixes aplicados y mergeados en fix/v1.6.0.

---

## Qué pasó

El manager de GBA Racing pujó por Kendall Thomas en el mercado de transferencias. Tras vencer el plazo de 24h, Kendall desapareció del mercado sin ingresar al equipo, sin notificación, y sin movimiento financiero visible. El manager reportó pérdida de dinero y driver.

---

## Causa raíz — 3 bugs encadenados

### Bug 1 — Type mismatch: `transferListedAt` string vs Timestamp

`staff.svelte.ts` guardaba `transferListedAt` como ISO string (`new Date().toISOString()`).  
El resolver de la CF consultaba con `Timestamp.fromDate()`.  
Firestore no compara tipos distintos → **el resolver nunca encontraba ningún driver listado.**  
Efecto: todos los transfers listados vivían en limbo indefinidamente.

### Bug 2 — Resolver hace transferencia directa, omite el flujo de negociación

Cuando el resolver sí hubiera procesado un driver, lo transfería inmediatamente:
```js
teamId: highestBidderId   // directo, sin pendingNegotiation
```
El método `fetchPendingNegotiations()` existe en el frontend pero **nunca es invocado** porque el resolver nunca escribe `pendingNegotiation: true`. El flujo de contrato negociado, los 3 intentos, y la selección del piloto a reemplazar, nunca se implementaron en la CF.

### Bug 3 — El resolver no descuenta el presupuesto del comprador

Al resolver una puja ganada, solo se acredita al vendedor. El comprador nunca paga.

---

## Lo que empeoró la situación durante la recovery

El script `patch_stuck_transfer.js`, diseñado para procesar transfers con `transferListedAt` como string, convirtió **todos** los campos de string a Timestamp. Esto rompió la query del frontend (`fetchPage`) que usaba cutoff como string ISO. Resultado: **el mercado quedó vacío** para todos los managers.

Fix aplicado: `transfer_market.svelte.ts` ahora usa `Timestamp.fromMillis()` como cutoff. `staff.svelte.ts` ahora guarda `Timestamp.now()`. Ambos tipos alineados.

---

## Flujo correcto — Cómo debe funcionar (T-028)

```
Manager hace puja
    ↓
Modal de negociación de contrato (máx. 3 intentos)
    ├─ Manager elige a qué piloto reemplaza (Main Driver / Secondary Driver / Equal)
    └─ Reserva es exclusivo para pilotos de academia, no aplica acá
    ↓
Si el piloto acepta:
    → driver.pendingNegotiation = true
    → driver.pendingBuyerTeamId = teamId
    → driver.pendingRole = rol acordado
    → driver.pendingReplacedDriverId = id del piloto que sale
    → La puja queda "locked" (no puede ser superada si contrato fue aceptado)
    ↓
Cuando vence el plazo y se gana la puja (resolver):
    → Kendall entra con el rol acordado
    → Luis Díaz (o quien sea) se va: teamId="", role="ex_driver"
    → Luis Díaz se lista automáticamente en el transfer market a valor de mercado
    → Se descuenta highestBid del presupuesto del comprador
    → Se acredita highestBid al vendedor (si tenía equipo)
    → Se registra transacción en ambos equipos
    → Se envía news + notification a ambos equipos
    ↓
Si el piloto no acepta (3 intentos fallidos):
    → pendingNegotiation se limpia
    → La puja sigue activa pero sin contrato garantizado
    → El manager puede reintentar o cancelar su puja
```

---

## Roles válidos en el transfer market

| Rol | Aplica a |
|-----|----------|
| Main Driver | Piloto comprado en mercado |
| Secondary Driver | Piloto comprado en mercado |
| Equal | Piloto comprado en mercado |
| Reserve | **Solo academia** — no disponible en transfer market |

---

## Impacto en datos

- **Kendall Thomas:** recuperada vía script manual. Asignada como reemplazo de Luis Díaz en GBA Racing.
- **Luis Díaz:** liberado (`ex_driver`, `teamId: ""`). Listado en transfer market a valor de mercado.
- **Universe doc:** sincronizado con `node sync_universe.js`.
- **Drivers en el mercado:** `transferListedAt` convertidos a Timestamp. Mercado operativo.

---

## Acciones correctivas

| Acción | Estado |
|--------|--------|
| `staff.svelte.ts`: `Timestamp.now()` en lugar de `toISOString()` | ✅ Aplicado |
| `transfer_market.svelte.ts`: cutoff como `Timestamp.fromMillis()` | ✅ Aplicado |
| `sync_universe.js`: sincronizar standings | ✅ Ejecutado |
| Luis Díaz: listar en transfer market | ✅ Listado |
| T-028: flujo completo `pendingNegotiation` (TransferSetupModal + NegotiationModal) | ✅ Implementado en fix/v1.6.0 |
| T-028: descontar budget del comprador en el resolver | ✅ Implementado en fix/v1.6.0 |
| T-028: auto-listing del driver reemplazado en el resolver | ✅ Implementado en fix/v1.6.0 |
| T-028: sync universe en el resolver | ✅ Implementado en fix/v1.6.0 |
| Auditoría de hardcoding post-fix | ✅ Limpiado en fix/v1.6.0 |

---

## Lección

Las preguntas de producto en `/start-dev` definen el contrato del flujo. Si la implementación no respeta ese contrato (como ocurrió acá: el resolver ignoró el flujo `pendingNegotiation` acordado), el bug es inevitable. El resolver debe ser revisado contra las decisiones de producto antes de cada deploy que toque economía o transferencias.
