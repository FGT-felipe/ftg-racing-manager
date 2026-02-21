# Reglas de Producto - FTG Racing Manager

Este documento centraliza las reglas lógicas y de negocio para los diferentes módulos del juego.

## 1. Universo y Ligas

### Estructura Jerárquica
El universo del juego se organiza en una serie de ligas jerárquicas en lugar de ligas por país:
1. **FTG World Championship** (Nivel 1 - Élite)
2. **FTG 2th Series** (Nivel 2 - Profesional)
3. **FTG Karting Championship** (Nivel 3 - Academia/Iniciación)

### Composición de Ligas
- Cada liga contiene exactamente **11 equipos**.
- No existen las divisiones internas; los equipos y pilotos pertenecen directamente a la liga.
- El sistema de IDs es global para evitar colisiones entre ligas.

---

## 2. Gestión de Pilotos

### Generación de Pilotos (Semilla)
- **Balance de Género**: Cada equipo debe estar compuesto por **un hombre y una mujer**. La asignación del rol de Piloto Principal (Main) y Piloto Secundario (Secondary) se realiza de forma **aleatoria**, permitiendo equipos liderados por mujeres y otros por hombres.
- **Distribución de Nacionalidades**: 
    - 40% de los pilotos son **Colombianos (CO)**.
    - 60% pertenecen al **Resto del Mundo** (Sudamérica, Europa, Asia, USA).
- **Atributos (Stats)**: Los niveles de habilidad base dependen del Tier de la liga en la que se generan.
- **Identidad Visual**: Los avatares se seleccionan aleatoriamente de un pool de 12 imágenes por género desde las carpetas `drivers/male` y `drivers/female`.

### Academia de Jóvenes
- El país por defecto para la generación de talentos en la academia es **Colombia (CO)**.

---

## 3. Patrocinios (Sponsorships)

### Ofertas y Contratos
- **Bonificación por Rol**: Si el manager tiene el rol de `Business Admin`, todas las ofertas reciben un **15% de bonificación** en pagos y bonos.
- **Duración**: Los contratos tienen una duración aleatoria de entre **4 y 10 carreras**.
- **Personalidad**: Cada patrocinador tiene una personalidad aleatoria (Agresiva, Profesional o Amigable).

### Negociación
- **Intentos**: Máximo de **3 intentos** por oferta.
- **Tácticas vs Personalidad**:
    - **Persuasivo** funciona mejor con personalidades **Agresivas**.
    - **Negociador** funciona mejor con personalidades **Profesionales**.
    - **Colaborativo** funciona mejor con personalidades **Amigables**.
- **Probabilidades de Éxito**:
    - Base: 30%.
    - Match Perfecto: +50% (Total 80%).
    - Match Neutral (al menos uno es Profesional): +10% (Total 40%).
    - Match Opuesto: -20% (Total 10%).
- **Bloqueo**: Si se fallan los 3 intentos, el patrocinador se bloquea por **7 días**.

---

## 4. Gestión de Equipos

### Generación de Nombres de Equipos
- **Idioma**: Los nombres de los equipos deben estar en **inglés**.
- **Restricciones**: No se deben utilizar nombres de ciudades.
- **Formato**: Los nombres deben combinar cualidades (Velocidad, rapidez, etc.) y colores o animales/elementos.
- **Ejemplos**: Rapid Blue, Green Panther, Crimson Velocity, Apex Predators, etc.

### Generación de Equipos
- **Globalidad**: Los equipos no están atados a un país específico para la liga, pero pueden tener identidades temáticas según las reglas de nombres.
- **Presupuesto**: Los equipos bot se generan con presupuestos base estandarizados según su liga.
- **IDs**: Siguen un contador global único para asegurar trazabilidad.

---

## 5. Instalaciones (Facilities)

### Costos y Mejora
- **Precio de Mejora**: El costo para subir de nivel es `$100,000 * (Nivel Actual + 1)`.
- **Nivel Máximo**: Las instalaciones pueden llegar hasta el **nivel 5**.
- **Mantenimiento**: Cada instalación tiene un costo de mantenimiento semanal de `Nivel * $15,000` (es $0 si el nivel es 0).

### Bonificaciones por Tipo
- **Oficina del Equipo (Team Office)**: Aumenta el presupuesto en un **5% por nivel**.
- **Garage**: Aumenta la capacidad de reparación en un **2% por nivel**.
- **Academia de Jóvenes (Youth Academy)**: Otorga **10 puntos de ojeo (scouting)** adicionales por nivel.

---

## 6. Reglajes y Simulación (Setups)

### Configuración del Coche
- **Parámetros**: Alas (Delantera y Trasera), Suspensión y Relación de Marchas.
- **Rango de Valores**: Todos los parámetros de reglaje se configuran en un rango de **0 a 100**.
- **Neumáticos**: Existen 4 compuestos (Blando, Medio, Duro y Lluvia), cada uno con diferentes tasas de desgaste y rendimiento según la temperatura y clima.
- **Estilo de Conducción**: Los pilotos pueden configurarse en 4 estilos (Defensivo, Normal, Ofensivo y Riesgo Máximo), afectando el ritmo y la probabilidad de error/accidente.
