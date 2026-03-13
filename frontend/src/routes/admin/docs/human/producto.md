# Visión de Producto y Filosofía Técnica

## 1. Propuesta de Valor Estratégica
FTG Racing Manager no es solo un juego de gestión, es un **Simulador de Decisiones Técnicas**. El producto se diferencia por la fidelidad en la ejecución de las reglas de la FIA (ficticias pero rigurosas) y un bucle de feedback inmediato entre la estrategia y el resultado.

## 2. Pilares de Diseño Senior
### A. Telemetric Authenticity
Cada elemento de la UI (Svelte 5) debe comportarse como un tablero de telemetría real. La reactividad no es solo estética, es funcional: los cambios de setup en práctica deben reflejarse inmediatamente en los modelos predictivos de tiempo de vuelta del manager.

### B. Scalable Meta-Game
El diseño de la base de datos permite ligas de miles de equipos sin degradación de performance mediante:
*   **Lazy Loading de Resultados**: El log de carrera solo se descarga al entrar al Race Center.
*   **Snapshot Consistency**: Los perfiles de pilotos se congelan al inicio de la temporada para evitar inconsistencias durante las carreras.

## 3. Roadmap de Ingeniería (Technical Debt & Improvements)
*   **Q3 2026 - Data Visualization**: Implementar `Chart.js` o `D3.js` para visualización de degradación comparativa de neumáticos.
*   **Q4 2026 - Edge Computing**: Mover parte de la validación de setup a **Firebase Data Connect** o **Vercel Edge Functions** para reducir latencia percibida.
*   **Q1 2027 - Advanced AI Drivers**: Migración del motor de decisiones de adelantamiento a un modelo basado en cadenas de Markov para mayor realismo estocástico.

## 4. Retención y engagement Loops
*   **Daily Focus**: El sistema de eventos de la Youth Academy obliga a una interacción mínima diaria para maximizar el potencial de los candidatos.
*   **Social Proof**: El StandingsCard global crea una competencia asíncrona constante entre managers.
