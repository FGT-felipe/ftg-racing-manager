# Recomendaciones de Arquitectura Senior (Roadmap Técnico)

Como Arquitecto de Software Senior, he identificado áreas críticas para asegurar que la plataforma FTG Racing Manager sea escalable al nivel de 100,000+ usuarios concurrentes.

---

## 1. Frontend (Svelte 5 & UI)
*   **Modularización de Lógica**: Actualmente, los `stores` de Svelte gestionan tanto el estado como las llamadas a Firebase. Se recomienda extraer la capa de datos a un **Data Provider Pattern** (Inyección de Dependencias) para facilitar el testing unitario sin depender de la instancia de Firebase.
*   **Web Workers para Animaciones**: La simulación "Race Live" realiza cálculos de suavizado de posición. Mover esto a un Web Worker evitaría el bloqueo del Main Thread en dispositivos móviles.
*   **PWA & Offline-First**: Implementar Service Workers para cachear assets de circuitos y retratos de pilotos, permitiendo una experiencia "Instantly Loaded".

## 2. Backend (Firebase Cloud Functions)
*   **Desglose del Monolito**: El archivo `index.js` de 2500+ líneas es un riesgo de mantenimiento. Se debe migrar a una estructura de **TypeScript Modules** agrupada por dominio (Economía, Simulación, Mercado).
*   **Motor de Simulación en C++ (WASM)**: La simulación de carrera es pura matemática. Para manejar 500+ ligas simultáneamente sin disparar costes de Firebase, se puede compilar el motor de física a **WebAssembly**, permitiendo ejecuciones ultra-rápidas y económicas.
*   **Idempotencia en Transacciones**: Asegurar que los crons de economía sean 100% idempotentes mediante el uso de `uniqueCycleId` para evitar cobros dobles en caso de re-intentos de funciones.

## 3. Base de Datos (Evolución de Firestore)
*   **Estrategia Híbrida (Firestore + SQL)**: Firestore es excelente para tiempo real, pero deficiente para consultas analíticas complejas (ej. "Encontrar pilotos mayores de 30 años con 5+ poles en la última década").
    *   *Propuesta*: Utilizar **BigQuery** o una base de datos vectorial para el historial estadístico y scouting avanzado.
*   **Denormalización Controlada**: Para evitar "N+1 queries" en el Dashboard, se recomienda denormalizar el nombre y logo del equipo directamente en el documento del piloto.
*   **Sharding de Ligas**: Cuando la plataforma crezca, se deben "shardear" los documentos de `universe` por región geográfica para evitar límites de escritura en un solo documento maestro.

## 4. DevSecOps
*   **Firebase App Check**: Proteger el backend de bots maliciosos que intenten forzar transacciones de presupuesto.
*   **Observabilidad**: Integrar Google Cloud Trace para medir la latencia exacta de cada paso de la simulación de carrera.
