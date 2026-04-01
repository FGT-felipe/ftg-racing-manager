---
created: 2026-03-26
due: 2026-03-29 (próximo domingo de carrera)
status: pending
---

# Sync Universe después de la carrera R4

## Qué hacer

Después de que corra la simulación de la carrera del domingo, ejecutar desde `functions/`:

```bash
node sync_universe.js
```

## Por qué

En V1.5.0 se modificó `simulateLap` para incluir el factor de moral de los pilotos.
El documento `universe/game_universe_v1` es un agregado desnormalizado que alimenta
la página `/season/standings`. Sin este sync, los standings quedan stale.

## Cuándo exactamente

Después de que `postRaceProcessing` complete exitosamente (Sunday ~16:00).
Verificar en Firebase Console → Functions que `postRaceProcessing` tiene timestamp reciente antes de correr este script.

## Cómo marcar como hecho

Cambiar `status: pending` a `status: done` y agregar `completed: YYYY-MM-DD`.
