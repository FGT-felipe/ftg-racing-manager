import 'dart:math';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';
import 'driver_portrait_service.dart';

/// Fábrica para generar pilotos experimentados de un país específico.
///
/// Similar a TeamFactory pero para pilotos con experiencia.
/// Genera stats basados en el tier de la división (Élite vs Profesional).
class DriverFactory {
  /// País del cual esta fábrica genera pilotos (inmutable)
  final Country country;

  /// Generador de números aleatorios
  final Random _random;

  /// Contador para IDs únicos por país
  static final Map<String, int> _countryCounters = {};

  DriverFactory(this.country) : _random = Random() {
    _countryCounters.putIfAbsent(country.code, () => 0);
  }

  /// Genera un piloto para una división específica
  ///
  /// tier 1 (Élite): stats 60-85, edad 22-35, más experiencia
  /// tier 2 (Profesional): stats 40-65, edad 20-38, menos experiencia
  Driver generateDriver({required int divisionTier}) {
    final isElite = divisionTier == 1;
    final id = _generateId();
    final gender = _generateGender();
    final age = _generateAge(isElite);

    return Driver(
      id: id,
      teamId: null, // Se asignará después
      name: _generateName(),
      age: age,
      potential: _generatePotential(isElite),
      points: 0,
      gender: gender,
      races: _generatePriorRaces(isElite),
      wins: 0, // Sin victorias iniciales
      podiums: 0,
      poles: 0,
      stats: _generateStats(isElite),
      countryCode: country.code,
      portraitUrl: DriverPortraitService().getPortraitUrl(
        driverId: id,
        countryCode: country.code,
        gender: gender,
        age: age,
      ),
    );
  }

  /// Genera un ID único para el piloto
  String _generateId() {
    final countryCode = country.code.toLowerCase();
    final counter = _countryCounters[country.code]!;
    _countryCounters[country.code] = counter + 1;

    return 'driver_${countryCode}_$counter';
  }

  /// Genera un nombre completo del piloto
  String _generateName() {
    final firstNames = _firstNamesByCountry[country.code] ?? _defaultFirstNames;
    final lastNames = _lastNamesByCountry[country.code] ?? _defaultLastNames;

    final firstName = firstNames[_random.nextInt(firstNames.length)];
    final lastName = lastNames[_random.nextInt(lastNames.length)];

    return '$firstName $lastName';
  }

  /// Genera edad basada en división
  /// Élite: 22-35 años (pilotos en su prime)
  /// Profesional: 20-38 años (más variedad, incluye jóvenes y veteranos)
  int _generateAge(bool isElite) {
    // OLD Logic:
    // if (isElite) {
    //   return 22 + _random.nextInt(14); // 22 to 35
    // } else {
    //   return 20 + _random.nextInt(19); // 20 to 38
    // }

    // NEW Logic:
    // Todos los equipos empiezan con pilotos entre 29 y 40 años
    // para motivar el uso de la academia.
    return 29 + _random.nextInt(12); // 29 to 40
  }

  /// Genera potencial basado en división
  /// Élite: 70-95 (alto potencial)
  /// Profesional: 50-80 (potencial medio)
  int _generatePotential(bool isElite) {
    if (isElite) {
      return 70 + _random.nextInt(26); // 70 to 95
    } else {
      return 50 + _random.nextInt(31); // 50 to 80
    }
  }

  /// Genera género aleatorio
  String _generateGender() {
    return _random.nextBool() ? 'M' : 'F';
  }

  /// Genera carreras previas basado en división
  /// Élite: 10-50 carreras (experiencia significativa)
  /// Profesional: 0-20 carreras (menos experiencia)
  int _generatePriorRaces(bool isElite) {
    if (isElite) {
      return 10 + _random.nextInt(41); // 10 to 50
    } else {
      return _random.nextInt(21); // 0 to 20
    }
  }

  /// Genera stats completos basados en división
  /// Élite: 60-85 en cada stat
  /// Profesional: 40-65 en cada stat
  Map<String, int> _generateStats(bool isElite) {
    final min = isElite ? 60 : 40;
    final max = isElite ? 85 : 65;

    return {
      'consistency': min + _random.nextInt(max - min + 1),
      'overtaking': min + _random.nextInt(max - min + 1),
      'defending': min + _random.nextInt(max - min + 1),
      'racecraft': min + _random.nextInt(max - min + 1),
      'speed': min + _random.nextInt(max - min + 1),
    };
  }

  /// Nombres por país
  static const Map<String, List<String>> _firstNamesByCountry = {
    'BR': [
      'Lucas',
      'Gabriel',
      'Sofia',
      'Maria',
      'João',
      'Ana',
      'Miguel',
      'Isabela',
    ],
    'AR': [
      'Mateo',
      'Santiago',
      'Valentina',
      'Emma',
      'Diego',
      'Lucía',
      'Benjamín',
      'Martina',
    ],
    'CO': [
      'Matías',
      'Samuel',
      'Isabella',
      'Catalina',
      'Andrés',
      'Camila',
      'Sebastián',
      'Valeria',
    ],
    'MX': [
      'Miguel',
      'Diego',
      'Sofía',
      'Valentina',
      'Alejandro',
      'Regina',
      'Carlos',
      'Fernanda',
    ],
    'UY': [
      'Joaquín',
      'Mateo',
      'Martina',
      'Sofía',
      'Nicolás',
      'Valentina',
      'Felipe',
      'Emma',
    ],
    'CL': [
      'Matías',
      'Benjamín',
      'Sofía',
      'Florencia',
      'Vicente',
      'Isidora',
      'Agustín',
      'Emilia',
    ],
  };

  static const Map<String, List<String>> _lastNamesByCountry = {
    'BR': [
      'Silva',
      'Santos',
      'Oliveira',
      'Souza',
      'Costa',
      'Ferreira',
      'Rodrigues',
      'Almeida',
    ],
    'AR': [
      'González',
      'Rodríguez',
      'Fernández',
      'López',
      'Martínez',
      'García',
      'Pérez',
      'Sánchez',
    ],
    'CO': [
      'García',
      'Rodríguez',
      'González',
      'Hernández',
      'López',
      'Martínez',
      'Torres',
      'Ramírez',
    ],
    'MX': [
      'García',
      'Hernández',
      'López',
      'González',
      'Martínez',
      'Rodríguez',
      'Pérez',
      'Sánchez',
    ],
    'UY': [
      'González',
      'Rodríguez',
      'Fernández',
      'García',
      'López',
      'Martínez',
      'Pérez',
      'Sánchez',
    ],
    'CL': [
      'González',
      'Muñoz',
      'Rojas',
      'Díaz',
      'Pérez',
      'Soto',
      'Contreras',
      'Silva',
    ],
  };

  static const List<String> _defaultFirstNames = [
    'Alex',
    'Jordan',
    'Taylor',
    'Morgan',
    'Casey',
    'Riley',
  ];

  static const List<String> _defaultLastNames = [
    'Smith',
    'Johnson',
    'Williams',
    'Brown',
    'Jones',
    'Garcia',
  ];
}
