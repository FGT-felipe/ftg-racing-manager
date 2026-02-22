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
- **Visibilidad de Ligas**: La liga de **Nivel 3 (FTG Karting Championship)** está oculta de las tablas de clasificación (Standings) y selectores generales para evitar confusión al manager, ya que funciona como un simulador de trasfondo para la academia.

### Calendario de Temporada
- Cada temporada tiene exactamente **9 carreras**.
- Las carreras se programan **1 por semana**, separadas por exactamente 7 días.
- La primera carrera se programa 7 días después de la fecha de inicio de la temporada.
- Los 9 circuitos son fijos para todas las ligas y se definen en `CircuitService`:
  1. 🇲🇽 Autodromo Hermanos Rodriguez (Mexico)
  2. 🇧🇷 Autódromo José Carlos Pace (Interlagos)
  3. 🇺🇸 Miami International Autodrome
  4. 🇧🇷 Sao Paulo Street Circuit
  5. 🇺🇸 Indianapolis Motor Speedway
  6. 🇨🇦 Circuit Gilles Villeneuve (Montreal)
  7. 🇺🇸 Las Vegas Strip Circuit
  8. 🇺🇸 Circuit of the Americas (Texas)
  9. 🇦🇷 Autódromo Oscar y Juan Gálvez (Buenos Aires)
- El calendario se genera en `database_seeder.dart` y **siempre debe usar los 9 circuitos**.
- **NUNCA reducir el número de carreras** al modificar el seeder.

---

## 2. Gestión de Pilotos

### Generación de Pilotos (Semilla)
- **Balance de Género**: Cada equipo debe estar compuesto por **un hombre y una mujer**. La asignación del rol de Piloto Principal (Main) y Piloto Secundario (Secondary) se realiza de forma **aleatoria**, permitiendo equipos liderados por mujeres y otros por hombres.
- **Exclusión de Nivel 3**: La generación automática de pilotos de la semilla **ignora la liga de Tier 3**. Los pilotos de esta liga solo se generan a través del sistema de la Academia de Jóvenes (graduados).
- **Distribución de Nacionalidades**: 
    - 40% de los pilotos son **Colombianos (CO)**.
    - 60% pertenecen al **Resto del Mundo** (Sudamérica, Europa, Asia, USA).
- **Atributos (Stats)**: Los niveles de habilidad base dependen del Tier de la liga en la que se generan.
- **Identidad Visual**: Los avatares se seleccionan aleatoriamente de un pool de 12 imágenes por género desde las carpetas `drivers/male` y `drivers/female`.

### Academia de Jóvenes
- La el sistema debe generar nuevos pilotos por cada academia según las reglas que se explican aquí.
- Cada equipo tiene una academia de jóvenes asociada. 
- Esta se consigue comprando el nivel 1 en las instalaciones. 
La academia se puede mejorar hasta el nivel 5 pero solo 1 nivel por temporada.
- Si no se tiene la academia, no se pueden generar pilotos jóvenes.
- Los pilotos jóvenes se generan con un nivel base de 7 en el nivel 1 de academia y aumentan hasta base 15 en el nivel máximo de la academia.
- Los pilotos jóvenes tienen un potencial de crecimiento de entre 5 y 12 puntos según el nivel de la academia.
- Los pilotos jóvenes tienen un contrato de 1 año.
- Los pilotos jóvenes tienen un salario de $100,000.
- Los pilotos jóvenes tienen un nivel de experiencia de 0.
- La única forma de conseguir pilotos jóvenes y con potencial, es en la academia.
- A mayor nivel de academia, mayor número de candidatos de alto potencial aparecerán.
- Al comprar la academia aparecen 2 candidatos jóvenes a seguir.
- Los candidatos no seleccionados expiran cada semana luego de la actualización del fin de semana y aparecen nuevos candidatos a seleccionar. Si se selecciona 1, entonces el no seleccionado expira y aparece 1, si no se selecciona ninguno, ambos expiran y aparecen 2 más a la semana.
- La academia siempre debe dar la opción de un piloto hombre y una mujer con sus respectivos avatares.
- Cuando se construye el primer nivel de la academia, el manager puede elegir el país de origen de los pilotos jóvenes. Este país será el país de origen de todos los pilotos jóvenes que se generen en la academia.
- Cada nivel de academia permite tener 2 pilotos jóvenes más.
- El manager puede seleccionar 1 solo piloto de los candidatos para seguirlo.
- Entre más rápido seleccione al piloto, más entrenamiento tendrá durante toda la temporada.
- la FTG Karting Championship es el campeonato donde los pilotos jóvenes pueden debutar.
- El campeonato de jóvenes no requiere configuraciones de setup ni neumáticos. Simplemente se hace una simulación durante la carrera de las ligas principales para darle algo de experiencia y según el resultado mejorar algunos porcentajes de sus habilidades.
- Solo Cuando termina la temporada, los pilotos jóvenes que no fueron seleccionados se eliminan.
- Solo Cuando termina la temporada, los pilotos jóvenes que fueron seleccionados se pueden ascender al equipo principal. Si el piloto es ascendido, se elimina de la academia de jóvenes y se convierte en un piloto del equipo principal.
- El manager puede elegir si el piloto joven reemplaza al piloto principal o al piloto secundario.
- Si el piloto joven reemplaza al piloto principal o al piloto secundario, el piloto reemplazado queda como agente libre en el mercado de fichajes (no implementado aún).
- Un piloto ascendido siempre cobrará menos por que ama a su equipo, su moral será del 100% y su salario será del 50% de lo que cobraría normalmente. El índice de disminución de moral será menor que cualquier otro piloto.
- Los stats de los pilotos no aparecen con un valor fijo, sino un rango de valor según su potencial actual y su potencial máximo. Esto hace que el manager tome una decisión a consciencia de cuál pueden ser sus stats finales al alcanzar su pico.
- Reglas sobre la UI de la academia de jóvenes:
    - Los stats de los pilotos no aparecen con un valor fijo, sino un rango de valor según su potencial actual y su potencial máximo. Esto hace que el manager tome una decisión a consciencia de cuál pueden ser sus stats finales al alcanzar su pico.
    - La pantalla de la academia muestra un banner tipo rules, explicando que cada semana llegan nuevos jóvenes promesas a la academia. 
    -  La pantalla de la academia de jóvenes le permite al manager ver los pilotos jóvenes que tiene disponibles.
    -  La pantalla de la academia de jóvenes le permite al manager seleccionar 1 solo piloto de los candidatos para seguirlo.
    -  La pantalla de la academia de jóvenes le permite al manager mejorar la academia de jóvenes.
    -  La pantalla de la academia de ver el progreso (por porcentajes) que está teniendo su joven piloto.
    -  Cada semana habrá en una sección de informes dentro de la academia, saldrá un resumen de qué tanto mejoró el piloto y el potencial que tiene.
    - Todos los gastos de academia y el contrato del piloto joven salen del presupuesto del equipo y se deben ver reflejados en los movimientos en Finances, con la categoría "Academy".
    - El manager puede decidir dejar de entrenar al piloto en cualquier momento, pero no podrá recuperar el dinero invertido en la academia.
    - Si el manager elimina a alguno de los 2 candidatos (sea el seleccionado o no), trae el número de candidatos disponibles a 2 si hay hueco disponible.
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
- **Livery (Librea)**: El sistema de personalización de libreas está **temporalmente oculto** en la interfaz de equipo hasta que se defina un diseño visual más robusto.

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

### Visibilidad
- **Roadmap Visible**: Todas las instalaciones definidas en el sistema son visibles en el HQ desde el inicio. Aquellas que no tienen funcionalidad implementada aún se muestran con la cintilla "COMING SOON" para informar al usuario de futuras mejoras.
- **Instalaciones No Compradas**: Las instalaciones a Nivel 0 son plenamente visibles y permiten la compra inmediata si se dispone del presupuesto.

---

## 6. Reglajes y Simulación (Setups)

### Configuración del Coche
- **Parámetros**: Alas (Delantera y Trasera), Suspensión y Relación de Marchas.
- **Rango de Valores**: Todos los parámetros de reglaje se configuran en un rango de **0 a 100**.
- **Neumáticos**: Existen 4 compuestos (Blando, Medio, Duro y Lluvia), cada uno con diferentes tasas de desgaste y rendimiento según la temperatura y clima.
- **Estilo de Conducción**: Los pilotos pueden configurarse en 4 estilos (Defensivo, Normal, Ofensivo y Riesgo Máximo), afectando el ritmo y la probabilidad de error/accidente.

---

## 7. Perfiles de Manager (Backgrounds)

Al crear un nuevo manager, el usuario debe seleccionar un contexto previo o perfil ("background"). Este perfil otorga bonificaciones (pros) y penalizaciones (contras) pasivas que impactan diferentes sistemas del juego.

### Lista de Perfiles y Efectos

#### 1. Ex-Driver (Ex-Piloto)
*Using your racing intuition to lead.*
- **Pros:**
  - Bono técnico en sesiones de carrera (Mejores tiempos/ritmo).
  - Mayor precisión en el feedback de los pilotos para el setup.
  - Mayor motivación y menos errores en paradas en boxes (Pit crew respect).
- **Contras:**
  - Progresión lenta de atributos de gestión del manager.
  - Salario necesario y expectativas financieras más altas.
  - Sesgo hacia estrategias y estilos agresivos impulsados por IA (o desgaste de gomas).

#### 2. Business Admin (Administrador)
*Optimization and profit above all.*
- **Pros:**
  - Mejores tratos financieros y pagos en patrocinios (`+15%` base).
  - Menores costos al mejorar instalaciones en el HQ (`-10%` o similar).
  - Bonificación en ingresos de marketing semanales.
- **Contras:**
  - Tasa alta de recuperación de fatiga (los pilotos se cansan más rápido o se quejan más).
  - Interacciones técnicas menos eficientes (desarrollo de R&D sufre un poco).
  - Aversión al riesgo (moral afectada por tácticas arriesgadas).

#### 3. Bureaucrat (Burócrata)
*Master of rules and politics.*
- **Pros:**
  - Contratos de personal y salarios son más económicos (`-10%`).
  - Reducción o inmunidad a ciertas penalizaciones menores (FIA).
  - Estabilidad en la confianza de la directiva (Toleran mejor rachas de derrotas).
- **Contras:**
  - Armonía de equipo inestable y alta probabilidad de peleas de pilotos.
  - Desarrollo de mejoras del coche más lento.
  - Impacto negativo en moral si hay eventos mediáticos aburridos.

#### 4. Ex-Engineer (Ex-Ingeniero)
*Technical excellence is the only way.*
- **Pros:**
  - Aceleración en el setup del coche y en R&D.
  - Mayor porcentaje base en la fiabilidad técnica del coche.
  - Curva de mejora tecnológica más temprana.
- **Contras:**
  - Multiplicador menor de ganancia de Experiencia (XP) para los pilotos.
  - Menos ingresos por patrocinios informales.
  - Penalización a la moral por exceso de microgestión en pits.

#### 5. No Experience (Sin Experiencia)
*A fresh perspective on the sport.*
- **Pros:**
  - Potencial de máximo crecimiento en todos los stats del manager.
  - Sin prejuicios ni rivalidades (relaciones neutras al nacer el universo).
  - Balance perfecto como estilo de liderazgo por defecto.
- **Contras:**
  - Cero buffs automáticos iniciales al llegar al equipo.
  - Reputación muy baja al entrar en la liga.
  - Mayor rango de error o "ruido" al ver los stats de telemetría reales.

---

## 8. Identidad Visual y UI

### Diseño "Onyx" (Premium Dark)
Todas las tarjetas (cards) de gestión (Team, Personal, Drivers, Engineering, Finances, Sponsors) deben adherirse al lenguaje de diseño estéticamente premium establecido en el HQ:
- **Fondo**: Gradiente lineal de `#1E1E1E` (arriba-izquierda) a `#0A0A0A` (abajo-derecha).
- **Bordes**: Grosor de `1px` con color `Colors.white.withValues(alpha: 0.1)`.
- **Esquinas**: Radio de borde (BorderRadius) fijo de `12px`.
- **Sombras**: BoxShadow profundo (`blurRadius: 12-16`, `offset: (0, 6-8)`) con color `Colors.black.withValues(alpha: 0.4)`.
- **Estructura**: Se debe evitar el widget `Card` nativo de Flutter en favor de `Container` con la decoración descrita para mayor control visual.

### Micro-interacciones
- **Hover Effects**: Los elementos interactivos dentro de las tarjetas deben tener sutiles cambios de opacidad o escala.
- **Coming Soon**: Los módulos en desarrollo deben usar el filtro de opacidad y una etiqueta "COMING SOON" con tipografía `900` de Google Fonts Poppins.

### Onboarding (Team Selection)
- **Background Tecnológico**: Las tarjetas de selección de equipo deben utilizar la imagen `blueprints/blueprintcars.png` como fondo con una opacidad reducida (`0.15`) para reforzar la estética técnica y de ingeniería del juego desde el primer contacto.
