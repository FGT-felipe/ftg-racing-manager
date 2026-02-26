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
    
### Estado Físico y Recuperación
- El atributo **Fitness** (0-100) es crítico para el rendimiento y la seguridad.
- Los pilotos **recuperan 10 puntos de Fitness diariamente** de forma automática (hasta un máximo de 100).
- El perfil de Manager **Business Admin** tiene una penalización en este aspecto (los pilotos se cansan más rápido o recuperan más lento).

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

### Badges tipo New
- Cuando se agregue un elemento nuevo sea cual sea, debe aparecer una cintilla tipo "New" en la esquina superior derecha del elemento. Esta cintilla debe ser dorada y debe desaparecer automáticamente después de 7 días. Debe tener una animación de una ícono con forma de estrella que parpadee suavemente.

## 9. Mercado de pilotos

### Tarjetas de pilotos
- En las tarjetas de pilotos en el "Contract Details" debe aparecer el valor del piloto en el mercado, calculado por su edad, potencial y stats actuales + su nivel de marketability.
- El botón "Fire" que existe actualmente debe cambiar por un botón llamado "Transfer Market" que abra un modal para poner al piloto en el mercado de transferencias o liberarlo por completo. El costo de la operación equivale al 10% del valor del piloto en el mercado. Si el piloto es liberado, debe ser eliminado del equipo y no podrá ser contratado nuevamente. Si se pone en el mercado de transferencias, debe aparecer un nuevo botón llamado "Cancel Transfer" que permita cancelar la operación. El costo de la operación no se recupera. Si se cancela la operación, el piloto debe permanecer en el equipo pero su moral se verá afectada negativamente.
- La tarjeta del piloto que está en el mercado de fillajes, debe tener una cintilla en la esquina izquierda superior que diga "TRANSFER MARKET" y en la esquina derecha inferior que diga "CANCEL TRANSFER" con un botón para cancelar la operación.

### Mercado de transferencias
- En el navbar aparece una opción llamada "Transfer Market"
- Al entrar en el mercado de transferencias, se debe mostrar una lista de pilotos que están en el mercado de transferencias.
- En la lista de pilotos, se debe mostrar el valor del piloto en el mercado, calculado por su edad, potencial y stats actuales + su nivel de marketability.
- El mercado de transferencias funciona por sistema de pujas, es decir, los equipos pujan por los pilotos y el equipo que más puje se lleva al piloto.
- El sistema de pujas funciona de la siguiente manera:
  - Cada equipo tiene un presupuesto para fichajes que sale de su balance actual.
  - Los equipos pueden pujar por los pilotos, igualando el valor del piloto en el mercado inicialmente. A partir de ahí, pueden pujar por múltiplos de 100k.
  - Las pujas duran 24 horas.
  - El equipo que más puje se lleva al piloto.
  - Un piloto en el mercaje de fichajes no puede ser liberado.
  - Un piloto en el mercaje de fichajes no puede ser puesto en el mercaje de fichajes nuevamente.
  - Las pujas son secretas, es decir, los equipos no pueden ver las pujas de los otros equipos, pero sabrán si su puja ha sido superada por otro equipo y el número de pujas que se han realizado por el piloto.
  - Cuando exista el sistema de Ojeador, se podrán ver todos los stats del piloto, su contrato actual y su valor en el mercado y el equipo que está ganando la puja en el momento.
  - En la tabla que muestra la lista de pilotos, debe haber un cronómetro que muestre el tiempo restante para que finalice la puja. → La tabla debe tener estilo Onyx.
  - Es un piloto cada 24 horas que sale al mercado de fichajes.
  - El admin puede generar pilotos para el mercado de fichajes manualmente desde la vista de admin, sin afectar el resto de la base de datos.
  - Los pilotos generados desde la vista de admin para el mercado de fichajes, tendrán stats de forma aleatoria, con una probabilidad de un 10% de ser un piloto con potencial de 5 estrellas, un 20% de ser un piloto con potencial de 4 estrellas, un 30% de ser un piloto con potencial de 3 estrellas, un 20% de ser un piloto con potencial de 2 estrellas y un 20% de ser un piloto con potencial de 1 estrella.
  - Los pilotos generados desde la vista de admin para el mercado de fichajes, tendrán un contrato de 1 año y un salario de 100k. El valor del piloto en el mercado será también dependerá de su marketability.
  - El admin podrá generar un total de 100 pilotos por vez, y podrá generar pilotos cada 24 horas. Esto se hace para evitar que el mercado de fichajes se llene de pilotos generados por el admin y equilibrar si ningún equipo pone pilotos en el mercado de fichajes.
  - La tabla del mercado de fichajes debe tener la bandera del país del piloto, su  nombre, su edad, su nivel de marketability, su contrato actual, su salario, su valor en el mercado y el equipo que está ganando la puja en el momento, además del contador de tiempo restante para que finalice la puja. Debe tener un botón para pujar por el piloto. Si se da click en el nombre, se abrirá un modal con la información del piloto, similar a la vista de detalles del piloto de la academia: un rango de stats entre 1 y 100 para cada stat cercano a su stat real, pero no igual para no revelar el potencial del piloto y sus stats reales. En el modal se debe mostrar el nombre del piloto, su edad, su nacionalidad, su nivel de marketability, su contrato actual, su salario, su valor en el mercado y el equipo que está ganando la puja en el momento, además del contador de tiempo restante para que finalice la puja. Debe tener un botón para pujar por el piloto. Si se da click en el botón de pujar, se abrirá un modal con un text input para pujar por el piloto debe tener un botón para pujar por el piloto. El valor de la puja no debe superar el presupuesto para fichajes del equipo.
  - El mercado de fichajes se abre al inicio de la temporada y se cierra faltando 1 carrera para el final de la temporada.
  - Durante las simulaciones de carreras y Qualy los pilotos que estén en el mercado de fichajes, no podrán participar en las carreras. 
  
  ### Gestión financiera, presupuesto para fichajes
  - En la vista Finances, debe aparecer una tarjeta que permita con un slider, ajustar el presupuesto para fichajes, pero teniendo en cuenta que a mayor presupuesto para fichajes, menos dinero tendrá para gastos de mantenimiento, salarios y desarrollo de piezas. El slider debe tener un rango de 0 a 100, y debe mostrar el porcentaje de presupuesto para fichajes que se está asignando. Debe tener un botón para guardar los cambios.  Si el manager asigna un 20% del presupuesto para fichajes, le quedará un 80% del presupuesto para gastos de mantenimiento, salarios y desarrollo de piezas. Si el manager asigna un 100% del presupuesto para fichajes, le quedará un 0% del presupuesto para gastos de mantenimiento, salarios y desarrollo de piezas.
  - Regla de salvación financiera: un manager jamás podrá asignar un presupuesto para fichajes que sea menor al 10% del presupuesto total, ni mayor al 90% del presupuesto total. Esto se hace para evitar que un manager se quede sin dinero para gastos de mantenimiento, salarios y desarrollo de piezas, o que un manager tenga demasiado dinero para gastos de mantenimiento, salarios y desarrollo de piezas.

  ### Contratos de pilotos
  - El botón "Renew" en la vista de detalles de piloto, debe abrir un modal que permita configurar los siguientes parámetros para negociar con el piloto.
    - Número de temporadas mínimo 1, 3 o 5 temporadas.
    - Rango salarial: el rango salarial debe ser calculado en base al salario actual del piloto y su nivel de marketability. El rango salarial debe ser de 100k en 100k, y debe tener un mínimo de 100k y un máximo de 10M. El rango salarial debe ser de 100k en 100k, y debe tener un mínimo de 100k y un máximo de 10M.
    - Contract Status: Main Driver, Secondary Driver, Equal Status.
    - La moral del piloto influirá en la negociación, de manera que si la moral del piloto es baja, será más difícil negociar con él. Si la moral del piloto es alta, será más fácil negociar con él.
    - El piloto aceptará la oferta si el salario está dentro del rango salarial y el contrato es de al menos 1 temporada. Si el contrato es de 3 o 5 temporadas, el salario debe ser mayor al salario actual del piloto. Si el contrato es de 1 temporada, el salario puede ser igual o mayor al salario actual del piloto.
    - Si el piloto acepta la oferta, se debe actualizar el contrato del piloto y se debe actualizar el salario del piloto. Si el piloto no acepta la oferta, se debe actualizar la moral del piloto y se debe actualizar el salario del piloto.
    - Todos esos cambios deben reflejarse en la vista de detalles del piloto y en el balance finaciero con sus respectivos movimientos.
    - Todos los pilotos tienen 3 intentos de negociación por temporada. Si el piloto no acepta la oferta, el piloto se irá del equipo al finalizar su contrato.
    - Los pilotos que estén cerca de la edad de retiro, tendrán una cintilla debajo de su avatar que indique se retiran en 1 temporada. Siempre se debe mostrar esta cintilla si el piloto está en su última temporada. Si el piloto se retira, se debe eliminar del equipo y no podrá ser contratado nuevamente. Un piloto que se retira la próxima temporada no aceptará renovaciones de contrato, ni contratos de más de 1 temporada. Si el piloto acepta un contrato de 1 temporada, se debe eliminar del equipo al finalizar su contrato.
    - Los pilotos con un potencial de 4 o 5 estrellas durante su carrera, se retirarán a los 38 años. Los pilotos con un potencial de 3 estrellas se retirarán a los 36 años. Los pilotos con un potencial de 2 estrellas se retirarán a los 34 años. Los pilotos con un potencial de 1 estrella se retirarán a los 32 años.
    - Un piloto que se haya destacado durante una o varias temporadas y esté cerca de retirarse, puede marcarse como leyenda. Si un piloto es marcado como leyenda del equipo, se mostrará una cintilla debajo de su avatar que indique que es una leyenda del equipo. Un piloto leyenda aparecerá en el Hall de la fama del equipo en el Team Office. La única información será su avatar, nombre, nacionalidad y el Career Status que existe actualmente, pero con colores dorados.