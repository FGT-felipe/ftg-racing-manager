import '../models/simulation_models.dart';

class CircuitService {
  static final CircuitService _instance = CircuitService._internal();
  factory CircuitService() => _instance;
  CircuitService._internal();

  /// Datos estáticos de circuitos (Mock para Fase 3)
  /// En el futuro esto vendría de Firestore
  final Map<String, CircuitProfile> _circuits = {
    // Ejemplo: Interlagos (Sâo Paulo) - Requiere balance
    'interlagos': CircuitProfile(
      id: 'interlagos',
      name: 'Autódromo José Carlos Pace',
      baseLapTime: 70.5, // ~1:10.500
      idealSetup: CarSetup(
        frontWing: 65,
        rearWing: 60,
        suspension: 45,
        gearRatio: 55,
        tyrePressure: 50,
      ),
      difficulty: 0.6,
      overtakingDifficulty: 0.4,
      characteristics: {
        'Acceleration': 'Important',
        'Understeer': 'Normal',
        'Oversteer': 'Important',
        'Top Speed': 'Normal',
        'Tyre Wear': 'High',
        'Fuel Consumption': 'High',
      },
    ),
    // Ejemplo: Monza - Baja carga aerodinámica (Velocidad pura)
    'monza': CircuitProfile(
      id: 'monza',
      name: 'Autodromo Nazionale Monza',
      baseLapTime: 80.0, // ~1:20.000
      idealSetup: CarSetup(
        frontWing: 20,
        rearWing: 15,
        suspension: 80, // Dura para rectas
        gearRatio: 90, // Larga
        tyrePressure: 60,
      ),
      difficulty: 0.4,
      overtakingDifficulty: 0.3,
      characteristics: {
        'Acceleration': 'Important',
        'Top Speed': 'Crucial',
        'Downforce': 'Low Priority',
        'Tyre Wear': 'Medium',
        'Baling': 'Low',
      },
    ),
    // Ejemplo: Mónaco - Máxima carga
    'monaco': CircuitProfile(
      id: 'monaco',
      name: 'Circuit de Monaco',
      baseLapTime: 72.0, // ~1:12.000
      idealSetup: CarSetup(
        frontWing: 95,
        rearWing: 95,
        suspension: 30, // Suave para baches
        gearRatio: 20, // Corta
        tyrePressure: 40,
      ),
      difficulty: 0.9, // Muy difícil, error alto
      overtakingDifficulty: 0.95, // Casi imposible
      characteristics: {
        'Qualifying': 'Crucial',
        'Downforce': 'Maximum',
        'Overtaking': 'Impossible',
        'Tyre Wear': 'Low',
        'Driver Skill': 'Critical',
      },
    ),
    // Ejemplo: Silverstone - Alta velocidad y carga media-alta
    'silverstone': CircuitProfile(
      id: 'silverstone',
      name: 'Silverstone Circuit',
      baseLapTime: 86.0, // ~1:26.000
      idealSetup: CarSetup(
        frontWing: 70,
        rearWing: 65,
        suspension: 60,
        gearRatio: 65,
        tyrePressure: 55,
      ),
      difficulty: 0.7,
      overtakingDifficulty: 0.5,
      characteristics: {
        'Cornering': 'High Speed',
        'Tyre Wear': 'High',
        'Power': 'Important',
        'Weather': 'Unpredictable',
      },
    ),
  };

  /// Obtiene el perfil del circuito por ID (o nombre parcial para fallback)
  CircuitProfile getCircuitProfile(String circuitIdOrName) {
    // Intenta buscar exacto
    if (_circuits.containsKey(circuitIdOrName.toLowerCase())) {
      return _circuits[circuitIdOrName.toLowerCase()]!;
    }

    // Fallback genérico si no encuentra el específico
    // En producción esto debería buscar en DB o lanzar error
    return CircuitProfile(
      id: 'generic',
      name: 'Generic Circuit',
      baseLapTime: 85.0,
      idealSetup: CarSetup(
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
        tyrePressure: 50,
      ),
    );
  }
}
