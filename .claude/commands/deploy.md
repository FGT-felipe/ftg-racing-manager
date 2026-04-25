# Deploy — Merge, Build & Ship

Ejecuta el pipeline completo de deploy: merge a main, sincronización de versión, build y despliegue a Firebase Hosting (y Functions si aplica).

**Uso:** `/deploy` — ejecutar desde la branch que se quiere mergear.

---

## Step 0 — Working tree check (BLOQUEANTE)

Ejecuta `git status --short`.

- Si hay archivos tracked modificados sin commitear → **STOP**. No continuar hasta que el working tree esté limpio.
- Si hay archivos en `functions/lib/` modificados que no pertenecen a esta branch → **STOP**. Resolverlos primero (ver incidente v1.2.0).
- Solo se permiten archivos untracked que estén en `.gitignore` (caches, builds).

## Step 1 — Identificar branch y versión

- Leer la branch actual con `git branch --show-current`. Si es `main` → **STOP**: no se hace deploy directo desde main sin branch.
- Leer `APP_VERSION` de `frontend/src/lib/constants/app_constants.ts`.
- Derivar la versión semántica: `V1.3.0` → `1.3.0`.

## Step 2 — Sincronizar versión en todos los archivos

La fuente de verdad es `app_constants.ts`. Verificar y actualizar si es necesario:

| Archivo | Campo | Debe ser |
|---------|-------|----------|
| `frontend/src/lib/constants/app_constants.ts` | `APP_VERSION` | `'V{X.Y.Z}'` |
| `frontend/package.json` | `"version"` | `"{X.Y.Z}"` |

Si alguno difiere, actualizarlo y hacer commit en la branch actual antes de continuar.

## Step 3 — Merge a main

```bash
git checkout main
git merge --no-ff <branch> -m "Merge <branch> → main"
```

Verificar que el merge fue exitoso (exit code 0). Si hay conflictos → **STOP** y reportar.

## Step 4 — Build frontend

```bash
cd frontend && npm run build
```

- Debe terminar con exit code 0.
- Output en `frontend/build/` — no modificar manualmente.
- Si el build falla → **STOP**, reportar el error, NO desplegar.

## Step 5 — Deploy a Firebase

Determinar qué desplegar inspeccionando qué cambió en la branch mergeada (`git diff main~1 --name-only`):

- Si hay cambios en `functions/` → `firebase deploy --only hosting,functions`
- Si solo hay cambios en `frontend/` → `firebase deploy --only hosting`

Ejecutar desde la raíz del repositorio.

## Step 6 — Git tag, push & sync

```bash
git tag v{X.Y.Z}
git push
git push --tags
```

Crear el tag, hacer push de commits y tags a origin automáticamente.

## Step 7 — Actualizar ROADMAP.md

- Mover la entry de **En progreso** a **Completado** con el número de versión.
- Marcar la feature en la tabla de **Backlog** como completada (tachado + ✅).
- Actualizar el campo `Actualizado:` en el header del ROADMAP.

## Step 8 — Eliminar branch mergeada

```bash
git branch -d <branch>
```

## Step 9 — Post-deploy reminders

Mostrar siempre:
- [ ] Verificar en Firebase Console → Hosting que el deploy tiene timestamp actual.
- [ ] Si se deployaron Functions: verificar timestamp en Firebase Console → Functions.
- [ ] Si la branch tocó simulación de carrera: ejecutar `node sync_universe.js` desde `functions/`.
- [ ] Smoke test en producción: abrir la app y verificar que la versión en pantalla muestra `V{X.Y.Z}`.

---

## Output esperado

Imprimir un resumen final:

```
✅ Merged:   feature/v1.3.0-whats-new-page → main
✅ Version:  V1.3.0 (app_constants + package.json sincronizados)
✅ Build:    frontend/build/ generado sin errores
✅ Deploy:   Firebase Hosting actualizado
✅ Push:     Commits y tags sincronizados a origin
🏷️  Tag:     v1.3.0 → GitHub
```
