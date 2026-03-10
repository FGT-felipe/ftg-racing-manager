# Reglas de Producto - FTG Racing Manager

Este documento centraliza las reglas lógicas y de negocio para los diferentes módulos del juego. Actualizado para reflejar la estructura y funcionalidades de la versión más reciente.

## 1. Universo y Ligas

### Estructura Jerárquica
El universo del juego se organiza en una serie de ligas jerárquicas en lugar de ligas por país:
1. **FTG World Championship** (Nivel 1 - Élite)
2. **FTG 2nd Series** (Nivel 2 - Profesional)
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

### Academia de Jóvenes (Youth Academy)
- Ahora accesible como un **ítem de nivel superior en la barra de navegación** (Top-Level Item) para mayor visibilidad.
- Cada equipo puede adquirir una academia de jóvenes pagando la cuota inicial ($100k).
- La academia se puede mejorar hasta el **nivel 5**, pero solo se permite **1 mejora por temporada**.
- Al comprar la academia, el manager elige un **País de Origen** que aplicará a todos los pilotos graduados de ella.

#### Lógica de Estrellas y Visualización
- **Pilotos de Academia**: Se calculan usando **Redondeo (`round`)**.
    - `Habilidad Actual = round(baseSkill / 20)`. Mínimo 1 estrella.
    - `Potencial Máximo = round((baseSkill + growthPotential) / 20)`. Mínimo 1 estrella.
- **Pilotos Profesionales**: Se calculan usando **Techo (`ceil`)**.
    - `Habilidad Actual = ceil(promedioStats / 20)`. Tope máximo limitado por su potencial.
- **Visualización (Standard FTG)**:
    - **Azul**: Nivel de habilidad actual.
    - **Ámbar (Opacidad 50%)**: Diferencia entre habilidad actual y potencial máximo.
    - **Outline/Vacía**: Espacios restantes hasta completar 5 estrellas.

#### Influencia del Nivel de Academia (Scouting)
El nivel de la academia dicta la calidad de los candidatos encontrados semanalmente:
- **Nivel 1**: Candidatos de 1.0 a 3.0 estrellas actuales. Potencial máximo topado en 3.5 estrellas.
- **Nivel 3**: Candidatos de 1.5 a 3.5 estrellas actuales. Potencial máximo topado en 4.5 estrellas.
- **Nivel 5**: Candidatos de 2.0 a 4.0 estrellas actuales. Único nivel donde aparecen pilotos de **5.0 estrellas de potencial**.
- **Cuota de Scouting**: 20 prospectos en Nivel 1, aumentando +5 por nivel (hasta 40 en Nivel 5). Si se alcanza, no aparecen más hasta la próxima temporada.

#### Especializaciones de Pilotos
Los pilotos jóvenes pueden "despertar" una especialidad durante su entrenamiento si cumplen:
1. `baseSkill >= 40`.
2. Una estadística específica alcanza **55 puntos**.
- **Especialidades**:
    - **Rainmaster**: Adaptabilidad >= 55.
    - **Tyre Whisperer**: Smoothness >= 55.
    - **Late Braker**: Braking >= 55.
    - **Defensive Minister**: Overtaking >= 55.
- **Persistencia**: Las especialidades son permanentes y **se transfieren al equipo principal** tras la promoción.

#### Roster, Entrenamiento y Promoción
- **Capacidad (Slots)**: 4 slots en Nivel 1, +1 por nivel adicional. El rol `Bureaucrat` otorga **+2 adicionales** por nivel.
- **Entrenamiento**: Los seleccionados ganan XP semanalmente en el simulador de fondo (Karting Championship).
- **Ascenso (Promotion)**:
    - Se realiza al finalizar la temporada (Season End).
    - Los pilotos ascendidos reciben el título de **"Rookie"**.
    - Inician con **100% de moral**.
    - Su salario es el **50%** del salario del piloto al que reemplazan (ventaja competitiva de la academia).
    - Límite máximo de 5 pilotos totales en el equipo (incluyendo reservas).

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
- **Ejemplos**: Rapid Blue, Green Panther, Crimson Velocity.

### Generación de Equipos
- **Globalidad**: Los equipos no están atados a un país, pero tienen identidades temáticas.
- **Presupuesto**: Los bots inician con presupuestos base estandarizados según su liga.
- **IDs**: Siguen un contador global único para asegurar trazabilidad.

---

## 5. Instalaciones (Facilities)

### Nombre e Interfaz
- El menú de instalaciones se ha renombrado de "HQ" a **Facilities** en la navegación global.
- Todas las instalaciones se consolidan bajo esta pestaña, incluyendo la Team Office y el Garage.

### Costos y Mejora
- **Precio de Mejora**: El costo base para subir de nivel es `$100,000 * (Nivel Actual + 1)`.
- **Nivel Máximo**: Las instalaciones pueden llegar hasta el **nivel 5**.
- **Mantenimiento**: Cada instalación tiene un costo de mantenimiento semanal de `Nivel * $15,000` (es $0 si el nivel es 0).

### Bonificaciones Automáticas
- **Oficina del Equipo (Team Office)**: Aumenta el presupuesto en un **5% por nivel**.
- **Garage**: Aumenta la capacidad de reparación en un **2% por nivel**.
- **Academia de Jóvenes**: Otorga **10 puntos de scouting** adicionales por nivel (visualizado en la cuota). Funcionalmente la Academia ya no se visita en Facilities sino en su propio menú "Academy", pero comparte la arquitectura de datos de las instalaciones.

---

## 6. Reglajes y Simulación (Setups)

### Configuración del Coche y Calificación
- **Parámetros**: Alas (Delantera y Trasera), Suspensión y Relación de Marchas en un rango de **0 a 100**.
- **Neumáticos**: Existen 4 compuestos (Blando, Medio, Duro y Lluvia).
- **DriverSetupInfo**: La comunicación entre los componentes de setup y las estrategias en carrera están fuertemente tipadas usando `DriverSetupInfo` para garantizar validaciones de tipos de compuestos antes y después de `_buildCarConfiguration` o `_buildStrategyAndPitStops`.

### Estilo de Conducción
- Los pilotos usan 4 estilos (Defensivo, Normal, Ofensivo y Riesgo Máximo), afectando el tiempo por vuelta, degradación y probabilidad de accidente.

---

## 7. Perfiles de Manager (Backgrounds)

El perfil otorga buffs y debuffs pasivos desde el inicio del universo.
1. **Ex-Driver**: Bono técnico en pista, más tacto de setup, menos progreso de gestión, salario alto, agresión IA.
2. **Business Admin**: Mejores contratos financieros (+15%), costos de HQ más baratos (-10%). *Contra:* Fatiga de pilotos altísima.
3. **Bureaucrat**: Salarios económicos (-10%), menor penalización FIA. *Especial:* **Otorga +2 slots base adicionales en la Youth Academy**. *Contra:* Peleas de equipo, I+D lento.
4. **Ex-Engineer**: R&D ultra veloz, mejoras en setup. *Contra:* Reducción de XP a pilotos.
5. **No Experience**: Gran potencial de crecimiento total futuro, pero sin beneficios iniciales.

---

## 8. Identidad Visual y UI

### Diseño "Onyx" y Temas Dinámicos
- Ahora la aplicación soporta una **alternancia de temas Dark/Light (Toggle)** en tiempo real.
- El lenguaje de diseño estéticamente premium ("Onyx") se ha adaptado a la variante luminosa conservando las sombras pesadas, bordes definidos y accesibilidad visual.
- **Fondo Dark**: Gradiente lineal de `#1E1E1E` a `#0A0A0A` con bordes blancos tenues.
- **Fondo Light**: Transiciones suaves y alto contraste en textos para evitar pérdida de legibilidad, tarjetas claras reteniendo proporciones idénticas a Onyx.
- **Estructura Constante**: Se ha regulado profundamente un uso estandarizado que evita colores directos duros o barras separadoras dobles, restaurando limpiezas en Dashboards y modales.

### Badges tipo New
- Al agregar elementos nuevos, muestran una cintilla dorada o el punto rojo ("New Dot") en la interfaz, con duración de tiempo limitado automatizada.

---

## 9. Finanzas (Finances) y CFO Dashboard

### Flujo de Caja y Run-Rate
- El Dashboard financiero abandonó los viejos promedios históricos en favor de un enfoque proactivo de CFO.
- Ahora existe un **True Cash Flow Projection**. Se calcula un **Run-Rate Semanal** que expone ingresos fijos frente a gastos fijos proyectados de la semana actual.
- Otorga una visión instantánea de la quema o rentabilidad que tendrá un equipo semana a semana, eliminando cifras infladas pasadas.

---

## 10. Mercado de Fichajes y Transferencias

### Accesibilidad Global
- El "Transfer Market" es ahora un **Top-Level Item** en la navegación.
- El botón "Fire" se ha actualizado y abre ventanas de "Transfer Market" para poder liberar pilotos asumiendo un 10% de su valor, o publicarlos a subasta.
- Cualquier jugador expuesto tiene la pestaña **TRANSFER MARKET** o la posibilidad de **CANCEL TRANSFER** (con penalización de moral y sin reembolso del fee).

### El Sistema de Subastas y Límites
- **Roster Total**: Un equipo **NO puede tener más de 5 pilotos** entre Principales, Secundarios, Reservas y Jóvenes asimilados. Si llega a 5, se bloquearán nuevas pujas o ascensos de Academia.
- Cada oferta inicial equivale al marketability + stats + edad, y los sobrecargos de puja avanzan de 100k en 100k.
- Durante las últimas 24 hrs que dura la puja, los tiempos y pujadores secretos se actualizan. Quien ofrezca más a contrarreloj lo incorpora.
- Si entra un piloto adicional y los asientos A y B están llenos, pasa automáticamente al estatus de **Reserve**.
- Los pilotos subastados activamente jamás participan de simulaciones del fin de semana (Qualy/Carrera).

### Presupuesto y Contratos Renovadores
- Existe una barra especial (0-100%) para destinar X porcentaje de la billetera global estrictamente al fondo de transferencias. (Nunca excede 90% ni es inferior al 10% obligatorio operativo).
- Las **renovaciones (Renew)** constan de 3 intentos vitalicios por temporada. Duraciones de 1, 3 o 5 años con saltos de banda salarial fijados en 100k.
- Pilotos a 1 año del retiro (iconizado con cintilla de cuenta regresiva) rechazan contratos de >1 temporada.
- Los pilotos de mayor lealtad u éxito pueden jubilarse y convertirse en **Leyendas del Equipo**, quedando perennemente en el Team Office Hall of Fame. 