# Guía de Despliegue a Producción (Svelte Migration)

Para pasar los usuarios de la versión Flutter a esta nueva versión en Svelte, sigue estos pasos:

## 1. Configuración del Adaptador
Dado que Firebase Hosting es principalmente estático, te recomiendo usar `adapter-static` en SvelteKit.
1. Instala el adaptador: `npm i -D @sveltejs/adapter-static`
2. Actualiza `svelte.config.js`:
```javascript
import adapter from '@sveltejs/adapter-static';
// ... 
    kit: {
        adapter: adapter({
            fallback: 'index.html' // Para Single Page Application
        })
    }
```

## 2. Configurar Firebase Hosting
Actualiza tu `firebase.json` para que apunte a la carpeta de build de Svelte (usualmente `build` o `dist` dependiendo del adaptador):

```json
{
  "hosting": {
    "public": "frontend/build", 
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

## 3. Direccionamiento de Usuarios
Para que los usuarios que entran al dominio principal vean la versión Svelte:
1. **Opción A (Reemplazo Total):** Despliega el build de Svelte sobre el sitio de hosting actual. Firebase se encargará de servir los nuevos archivos.
2. **Opción B (Beta Segmentada):** Puedes usar un subdominio (ej: `beta.formulatrackglory.com`) para Svelte y poner un banner en la versión Flutter invitando a probar la beta.

## 4. Limpieza de Datos
He revisado y para el usuario "tester" que mencionaste:
- Se recomienda que lo elimines directamente desde la consola de **Firebase Auth**.
- Una vez eliminado, busca en la colección `managers` el documento con su UID (si lo conoces) y bórralo.
- El equipo que seleccionó volverá a estar disponible (isBot: true, managerId: "") si limpias el campo `managerId` en el documento del equipo correspondiente en la colección `teams`.

**Nota:** He dejado el sistema listo con logs claros en la consola para que identifiques si algún usuario no tiene equipo asignado.
