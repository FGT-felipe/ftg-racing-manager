import '../models/simulation_models.dart';

class CircuitService {
  static final CircuitService _instance = CircuitService._internal();
  factory CircuitService() => _instance;
  CircuitService._internal();

  /// Datos estáticos de circuitos con lógica de desgaste, combustible y pesos de rendimiento.
  final Map<String, CircuitProfile> _circuits = {
    'mexico': CircuitProfile(
      id: 'mexico',
      name: 'Autodromo Hermanos Rodriguez',
      flagEmoji: '🇲🇽',
      baseLapTime: 76.0,
      laps: 71,
      tyreWearMultiplier: 1.1,
      fuelConsumptionMultiplier: 1.0,
      aeroWeight: 0.4,
      powertrainWeight: 0.4,
      chassisWeight: 0.2,
      idealSetup: CarSetup(
        frontWing: 80,
        rearWing: 75,
        suspension: 50,
        gearRatio: 85,
      ),
      difficulty: 0.6,
      overtakingDifficulty: 0.4,
      characteristics: {
        'Top Speed': 'High',
        'Tyre Wear': 'Medium',
        'Fuel Consumption': 'Normal',
      },
    ),
    'vegas': CircuitProfile(
      id: 'vegas',
      name: 'Las Vegas Strip Circuit',
      flagEmoji: '🇺🇸',
      baseLapTime: 92.0,
      laps: 50,
      tyreWearMultiplier: 0.8,
      fuelConsumptionMultiplier: 1.1,
      aeroWeight: 0.2,
      powertrainWeight: 0.6,
      chassisWeight: 0.2,
      idealSetup: CarSetup(
        frontWing: 25,
        rearWing: 20,
        suspension: 70,
        gearRatio: 90,
      ),
      difficulty: 0.5,
      overtakingDifficulty: 0.3,
      characteristics: {
        'Night Race': 'Yes',
        'Top Speed': 'Very High',
        'Tyre Wear': 'Low',
        'Fuel Consumption': 'High',
      },
    ),
    'interlagos': CircuitProfile(
      id: 'interlagos',
      name: 'Autódromo José Carlos Pace',
      flagEmoji: '🇧🇷',
      baseLapTime: 70.5,
      laps: 71,
      tyreWearMultiplier: 1.2,
      fuelConsumptionMultiplier: 1.2,
      aeroWeight: 0.3,
      powertrainWeight: 0.3,
      chassisWeight: 0.4,
      idealSetup: CarSetup(
        frontWing: 65,
        rearWing: 60,
        suspension: 45,
        gearRatio: 55,
      ),
      difficulty: 0.6,
      overtakingDifficulty: 0.4,
      characteristics: {
        'Elevation': 'Significant',
        'Weather': 'Unpredictable',
        'Tyre Wear': 'High',
        'Top Speed': 'Medium',
        'Fuel Consumption': 'High',
      },
    ),
    'miami': CircuitProfile(
      id: 'miami',
      name: 'Miami International Autodrome',
      flagEmoji: '🇺🇸',
      baseLapTime: 90.0,
      laps: 57,
      tyreWearMultiplier: 1.0,
      fuelConsumptionMultiplier: 1.0,
      aeroWeight: 0.4,
      powertrainWeight: 0.3,
      chassisWeight: 0.3,
      idealSetup: CarSetup(
        frontWing: 55,
        rearWing: 50,
        suspension: 60,
        gearRatio: 65,
      ),
      difficulty: 0.5,
      overtakingDifficulty: 0.5,
      characteristics: {
        'Environment': 'Complex',
        'Surface': 'Smooth',
        'Top Speed': 'High',
        'Tyre Wear': 'Normal',
        'Fuel Consumption': 'Normal',
      },
    ),
    'san_pablo_street': CircuitProfile(
      id: 'san_pablo_street',
      name: 'Sao Paulo Street Circuit',
      flagEmoji: '🇧🇷',
      baseLapTime: 82.0,
      laps: 40,
      tyreWearMultiplier: 1.3,
      fuelConsumptionMultiplier: 1.3,
      aeroWeight: 0.2,
      powertrainWeight: 0.2,
      chassisWeight: 0.6,
      idealSetup: CarSetup(
        frontWing: 85,
        rearWing: 80,
        suspension: 30, // Soft for streets
        gearRatio: 35,
      ),
      difficulty: 0.8,
      overtakingDifficulty: 0.7,
      characteristics: {
        'Type': 'Street',
        'Bumpy': 'Yes',
        'Tyre Wear': 'High',
        'Top Speed': 'Low',
        'Fuel Consumption': 'Very High',
      },
    ),
    'indianapolis': CircuitProfile(
      id: 'indianapolis',
      name: 'Indianapolis Motor Speedway',
      flagEmoji: '🇺🇸',
      baseLapTime: 72.0,
      laps: 73,
      tyreWearMultiplier: 1.1,
      fuelConsumptionMultiplier: 1.1,
      aeroWeight: 0.3,
      powertrainWeight: 0.4,
      chassisWeight: 0.3,
      idealSetup: CarSetup(
        frontWing: 40,
        rearWing: 35,
        suspension: 75,
        gearRatio: 80,
      ),
      difficulty: 0.5,
      overtakingDifficulty: 0.4,
      characteristics: {
        'Oval Section': 'Partial',
        'Top Speed': 'Very High',
        'Tyre Wear': 'Medium',
        'Fuel Consumption': 'High',
      },
    ),
    'montreal': CircuitProfile(
      id: 'montreal',
      name: 'Circuit Gilles Villeneuve',
      flagEmoji: '🇨🇦',
      baseLapTime: 73.0,
      laps: 70,
      tyreWearMultiplier: 0.9,
      fuelConsumptionMultiplier: 1.3,
      aeroWeight: 0.2,
      powertrainWeight: 0.4,
      chassisWeight: 0.4,
      idealSetup: CarSetup(
        frontWing: 45,
        rearWing: 40,
        suspension: 55,
        gearRatio: 70,
      ),
      difficulty: 0.6,
      overtakingDifficulty: 0.4,
      characteristics: {
        'Braking': 'Heavy',
        'Kerbs': 'Aggressive',
        'Fuel Consumption': 'High',
        'Top Speed': 'High',
        'Tyre Wear': 'Low',
      },
    ),
    'texas': CircuitProfile(
      id: 'texas',
      name: 'Circuit of the Americas',
      flagEmoji: '🇺🇸',
      baseLapTime: 94.0,
      laps: 56,
      tyreWearMultiplier: 1.4,
      fuelConsumptionMultiplier: 1.1,
      aeroWeight: 0.5,
      powertrainWeight: 0.2,
      chassisWeight: 0.3,
      idealSetup: CarSetup(
        frontWing: 75,
        rearWing: 70,
        suspension: 50,
        gearRatio: 60,
      ),
      difficulty: 0.7,
      overtakingDifficulty: 0.4,
      characteristics: {
        'S-Curves': 'Technical',
        'Elevation': 'Extreme Turn 1',
        'Tyre Wear': 'Very High',
        'Top Speed': 'Normal',
        'Fuel Consumption': 'High',
      },
    ),
    'buenos_aires': CircuitProfile(
      id: 'buenos_aires',
      name: 'Autódromo Oscar y Juan Gálvez',
      flagEmoji: '🇦🇷',
      baseLapTime: 74.0,
      laps: 72,
      tyreWearMultiplier: 1.1,
      fuelConsumptionMultiplier: 1.0,
      aeroWeight: 0.3,
      powertrainWeight: 0.2,
      chassisWeight: 0.5,
      idealSetup: CarSetup(
        frontWing: 65,
        rearWing: 60,
        suspension: 45,
        gearRatio: 50,
      ),
      difficulty: 0.6,
      overtakingDifficulty: 0.6,
      characteristics: {
        'Technical': 'Very',
        'Top Speed': 'Medium',
        'Tyre Wear': 'Medium',
        'Fuel Consumption': 'Normal',
      },
    ),
  };

  /// Obtiene el perfil del circuito por ID (o nombre parcial para fallback)
  CircuitProfile getCircuitProfile(String circuitIdOrName) {
    String searchKey = circuitIdOrName.toLowerCase();

    // Intenta buscar exacto
    if (_circuits.containsKey(searchKey)) {
      return _circuits[searchKey]!;
    }

    // Búsqueda por nombre parcial si el ID no matchea exacto
    for (var circuit in _circuits.values) {
      if (circuit.name.toLowerCase().contains(searchKey)) {
        return circuit;
      }
    }

    // Fallback genérico si no encuentra el específico
    return CircuitProfile(
      id: 'generic',
      name: 'Generic Circuit',
      flagEmoji: '🏁',
      baseLapTime: 85.0,
      laps: 50,
      idealSetup: CarSetup(
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
      ),
    );
  }

  List<CircuitProfile> getAllCircuits() {
    return _circuits.values.toList();
  }
}
