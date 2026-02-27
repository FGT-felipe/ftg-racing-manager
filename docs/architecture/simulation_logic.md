# Documentación del Simulador de Carreras y Clasificación (Qualy)

Este documento detalla las reglas de negocio y la lógica técnica aplicada en los simuladores de `ftg-racing-manager`.

## 1. Modelo de Rendimiento Base (Lap Time)

Tanto la Clasificación como la Carrera utilizan un modelo de rendimiento base para calcular el tiempo de vuelta (`actualLapTime`). Los factores que influyen son:

### A. Rendimiento del Coche (`carPerformanceFactor`)
El rendimiento del coche se calcula comparando las estadísticas del equipo con los pesos específicos de cada circuito:
- **Aerodinámica (Aero)**
- **Tren de Potencia (Powertrain)**
- **Chasis (Chassis)**

Cada circuito tiene sus propios pesos (ej. Monza prioriza Powertrain, Mónaco prioriza Chasis).

### B. Habilidad del Piloto (`driverFactor`)
Se promedian las estadísticas del piloto con diferentes pesos para el rendimiento puro:
- **Frenada (Braking)**: 30%
- **Paso por curva (Cornering)**: 40%
- **Adaptabilidad (Adaptability)**: 15%
- **Enfoque (Focus)**: 15%

### C. Configuración del Coche (Setup Penalty)
Se calcula la "Setup Confidence" (0% a 100%) comparando el setup actual del usuario con el **Setup Ideal** oculto del circuito.
- Cualquier desviación en Alerón Delantero, Alerón Trasero, Suspensión o Relación de Marchas añade una penalización de tiempo proporcional a la magnitud del error.

---

## 2. Simulador de Clasificación (Qualifying)

La Clasificación es una simulación directa de "mejor tiempo de vuelta":
- **Estilo de Conducción**: El piloto aplica un multiplicador de riesgo/recompensa. Un estilo "Arriesgado" mejora el tiempo pero aumenta exponencialmente la probabilidad de accidente (DNF).
- **Consistencia**: Un bajo valor en la estadística de Consistencia del piloto aumenta la varianza aleatoria del tiempo de vuelta.

---

## 3. Simulador de Carrera (Race Session)

La carrera se simula vuelta a vuelta, gestionando el desgaste y la estrategia.

### A. Gestión de Neumáticos
- **Degradación**: El desgaste aumenta cada vuelta según el circuito, el compuesto seleccionado (S/M/H/W) y la suavidad (`Smoothness`) del piloto.
- **Penalización por Desgaste**: A medida que el % de desgaste aumenta, el tiempo de vuelta empeora de forma cuadrática.
- **Compuestos**:
    - **Soft**: Más rápido, pero de degradación muy alta.
    - **Medium**: Balanceado.
    - **Hard**: Más lento, pero muy duradero.
    - **Wet**: Esencial en condiciones de lluvia (si se implementa), penalización masiva en seco.

### B. Efecto del Combustible
- **Consumo**: El coche gasta combustible cada vuelta según el estilo de conducción.
- **Efecto Peso**: El coche se vuelve linealmente más rápido a medida que el tanque se vacía (aprox. 1.5s de diferencia entre tanque lleno y vacío).

### C. Estrategia de Pit Stop
- **Lógica de Parada**: Los pilotos (IA y Player) entran a boxes si:
    1. El desgaste del neumático es > 80%.
    2. El combustible restante es insuficiente para completar 2.5 vueltas más.
- **Regla del Compuesto Duro**: Existe una regla de negocio que obliga a usar el compuesto **Hard** al menos una vez durante la carrera. De no hacerlo, se aplica una penalización de **35 segundos** al final de la carrera.

### D. Incidentes y Adelantamientos
- **Accidentes (DNF)**: Probabilidad calculada en cada vuelta basada en `Focus`, `Consistency` y el `DriverStyle`.
- **Adelantamientos**: Se detectan cambios en el orden de los pilotos al final de cada vuelta comparando los tiempos totales acumulados. El "Estilo de Conducción" (ej. Ofensivo) facilita el adelantamiento pero aumenta el desgaste de gomas.

### E. Bonificaciones de Rasgos (`Traits`)
Los rasgos específicos del piloto añaden modificadores directos:
- `First Lap Hero`: Mejora el rendimiento en la vuelta 1.
- `Tyre Saver`: Reduce el desgaste de neumáticos en un 15%.
- `Aggressive`: Mejora el ritmo pero aumenta el riesgo de DNF.

### F. Vuelta Rápida (Fastest Lap)
La vuelta más rápida se calcula de forma **independiente** a la posición de carrera:
- En cada vuelta, se identifica al piloto con el menor `lapTime` individual de esa vuelta.
- Este piloto es resaltado con un indicador morado (🟣) en el leaderboard, independientemente de su posición general.
- El líder de la carrera (P1) se determina por **tiempo total acumulado**, no por la vuelta más rápida. Es perfectamente posible que un piloto en posiciones intermedias, por ejemplo con neumáticos frescos tras un pit stop, registre la vuelta más rápida.
