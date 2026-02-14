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
    // GP Hermanos Rodríguez - Mexico (Alta altitud, gran recta)
    'hermanos_rodriguez': CircuitProfile(
      id: 'hermanos_rodriguez',
      name: 'Autódromo Hermanos Rodríguez',
      baseLapTime: 76.0,
      idealSetup: CarSetup(
        frontWing: 80, // Alta carga por aire fino
        rearWing: 75,
        suspension: 50,
        gearRatio: 85, // Larga recta
        tyrePressure: 45,
      ),
      difficulty: 0.6,
      overtakingDifficulty: 0.4,
      characteristics: {
        'Altitude': 'Very High',
        'Cooling': 'Difficult',
        'Top Speed': 'High',
      },
    ),
    // GP Termas de Río Hondo - Argentina (Fluido, rápido)
    'termas': CircuitProfile(
      id: 'termas',
      name: 'Autódromo Termas de Río Hondo',
      baseLapTime: 98.0,
      idealSetup: CarSetup(
        frontWing: 60,
        rearWing: 55,
        suspension: 60,
        gearRatio: 60,
        tyrePressure: 55,
      ),
      difficulty: 0.5,
      overtakingDifficulty: 0.3,
      characteristics: {'Flow': 'Good', 'Tyre Wear': 'Medium'},
    ),
    // GP Tocancipá - Colombia (Corto, trabado, altura)
    'tocancipa': CircuitProfile(
      id: 'tocancipa',
      name: 'Autódromo de Tocancipá',
      baseLapTime: 65.0, // Vuelta corta
      idealSetup: CarSetup(
        frontWing: 85,
        rearWing: 80,
        suspension: 40,
        gearRatio: 30, // Corta
        tyrePressure: 50,
      ),
      difficulty: 0.55,
      overtakingDifficulty: 0.7,
      characteristics: {'Layout': 'Tight', 'Altitude': 'High'},
    ),
    // GP El Pinar - Uruguay (Técnico)
    'el_pinar': CircuitProfile(
      id: 'el_pinar',
      name: 'Autódromo Víctor Borrat Fabini',
      baseLapTime: 72.0,
      idealSetup: CarSetup(
        frontWing: 65,
        rearWing: 60,
        suspension: 55,
        gearRatio: 45,
        tyrePressure: 50,
      ),
      difficulty: 0.5,
      overtakingDifficulty: 0.6,
    ),
    // GP Yahuarcocha - Ecuador (Escénico, media velocidad)
    'yahuarcocha': CircuitProfile(
      id: 'yahuarcocha',
      name: 'Autódromo Internacional de Yahuarcocha',
      baseLapTime: 90.0,
      idealSetup: CarSetup(
        frontWing: 55,
        rearWing: 50,
        suspension: 50,
        gearRatio: 55,
        tyrePressure: 50,
      ),
      difficulty: 0.45,
      overtakingDifficulty: 0.4,
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
