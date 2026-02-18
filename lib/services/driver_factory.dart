import 'dart:math';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';
import 'driver_portrait_service.dart';
import 'driver_name_service.dart';
import 'driver_status_service.dart';

/// Fábrica para generar pilotos experimentados de un país específico.
///
/// Similar a TeamFactory pero para pilotos con experiencia.
/// Genera stats basados en el tier de la división (Élite vs Profesional).
class DriverFactory {
  /// País del cual esta fábrica genera pilotos (inmutable)
  final Country country;

  /// Generador de números aleatorios
  final Random _random;

  /// Servicio de nombres de pilotos
  final DriverNameService _nameService;

  /// Contador para IDs únicos por país
  static final Map<String, int> _countryCounters = {};

  DriverFactory(this.country)
    : _random = Random(),
      _nameService = DriverNameService() {
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
    final stats = _generateStats(isElite, age);
    final statPotentials = _generateStatPotentials(isElite, stats);
    final traits = _generateTraits(age);

    final potential = _generatePotentialStars(isElite);
    final priorStats = _generatePriorStats(isElite, age, potential);

    // Initial Driver without title to calculate it
    final baseDriver = Driver(
      id: id,
      teamId: null,
      name: _generateName(gender),
      age: age,
      potential: potential,
      points: 0,
      gender: gender,
      championships: priorStats['championships']!,
      races: priorStats['races']!,
      wins: priorStats['wins']!,
      podiums: priorStats['podiums']!,
      poles: priorStats['poles']!,
      stats: stats,
      statPotentials: statPotentials,
      traits: traits,
      countryCode: country.code,
      portraitUrl: DriverPortraitService().getPortraitUrl(
        driverId: id,
        countryCode: country.code,
        gender: gender,
        age: age,
      ),
    );

    final statusTitle = DriverStatusService.calculateTitle(baseDriver);

    return baseDriver.copyWith(statusTitle: statusTitle);
  }

  /// Genera un ID único para el piloto
  String _generateId() {
    final countryCode = country.code.toLowerCase();
    final counter = _countryCounters[country.code]!;
    _countryCounters[country.code] = counter + 1;
    return 'driver_${countryCode}_$counter';
  }

  /// Genera un nombre completo del piloto usando el servicio centralizado
  String _generateName(String gender) {
    return _nameService.generateName(gender: gender, countryCode: country.code);
  }

  /// Genera edad basada en división.
  /// Todos los equipos empiezan con pilotos entre 29 y 40 años
  /// para motivar el uso de la academia.
  int _generateAge(bool isElite) {
    return 29 + _random.nextInt(12); // 29 to 40
  }

  /// Genera potencial como estrellas de ojeo (1-5).
  /// Élite: 3-5 estrellas
  /// Profesional: 1-4 estrellas
  int _generatePotentialStars(bool isElite) {
    if (isElite) {
      return 3 + _random.nextInt(3); // 3, 4, 5
    } else {
      return 1 + _random.nextInt(4); // 1, 2, 3, 4
    }
  }

  /// Genera género aleatorio
  String _generateGender() {
    return _random.nextBool() ? 'M' : 'F';
  }

  /// Genera estadísticas históricas coherentes (Races, Wins, Podiums, Titles)
  /// Basado en edad, potencial y división.
  Map<String, int> _generatePriorStats(bool isElite, int age, int potential) {
    // Años de carrera profesional
    final yearsPro = (age - 20).clamp(0, 15);
    if (yearsPro == 0) {
      return {
        'races': 0,
        'wins': 0,
        'podiums': 0,
        'poles': 0,
        'championships': 0,
      };
    }

    int totalRaces = 0;
    int totalWins = 0;
    int totalPodiums = 0;
    int totalTitles = 0;

    // Ratios de éxito basados en potencial (estrellas 1-5)
    final baseWinRatio = potential * 0.05; // 0.05 to 0.25
    final basePodiumRatio = potential * 0.12; // 0.12 to 0.60

    for (int i = 0; i < yearsPro; i++) {
      // Temporadas de 9 carreras (estándar del juego)
      final seasonRaces = 9;
      totalRaces += seasonRaces;

      // Variación por año (algunos años mejores que otros)
      final yearMod = 0.5 + _random.nextDouble(); // 0.5x to 1.5x

      int yearWins = (seasonRaces * baseWinRatio * yearMod).floor();
      if (yearWins > seasonRaces) yearWins = seasonRaces;

      int yearPodiums = (seasonRaces * basePodiumRatio * yearMod).floor();
      if (yearPodiums > seasonRaces) yearPodiums = seasonRaces;
      if (yearPodiums < yearWins) yearPodiums = yearWins;

      totalWins += yearWins;
      totalPodiums += yearPodiums;

      // Lógica de Campeón: 80% o más de victorias en la temporada
      if (yearWins >= (seasonRaces * 0.8).ceil()) {
        totalTitles++;
      }
    }

    final poles = (totalWins * 1.1).floor();

    return {
      'races': totalRaces,
      'wins': totalWins,
      'podiums': totalPodiums,
      'poles': poles,
      'championships': totalTitles,
    };
  }

  /// Genera todos los stats del piloto con los nuevos 11 atributos.
  ///
  /// Élite: 60-85 en stats de conducción, 55-80 en mentales
  /// Profesional: 40-65 en stats de conducción, 35-60 en mentales
  Map<String, int> _generateStats(bool isElite, int age) {
    final drivingMin = isElite ? 60 : 40;
    final drivingMax = isElite ? 85 : 65;
    final mentalMin = isElite ? 55 : 35;
    final mentalMax = isElite ? 80 : 60;

    int r(int min, int max) => min + _random.nextInt(max - min + 1);

    // Ajuste por edad: pilotos mayores tienen mejor feedback/consistency pero peor fitness
    final ageFitnessBonus = age > 35 ? -10 : (age < 25 ? 5 : 0);
    final ageFeedbackBonus = age > 32 ? 8 : 0;
    final ageConsistencyBonus = age > 32 ? 5 : 0;

    return {
      // Habilidades de Conducción
      DriverStats.braking: r(drivingMin, drivingMax),
      DriverStats.cornering: r(drivingMin, drivingMax),
      DriverStats.smoothness: r(drivingMin, drivingMax),
      DriverStats.overtaking: r(drivingMin, drivingMax),
      DriverStats.consistency: (r(drivingMin, drivingMax) + ageConsistencyBonus)
          .clamp(0, 100),
      DriverStats.adaptability: r(drivingMin, drivingMax),
      // Estadísticas Mentales y de Equipo
      DriverStats.fitness: (r(mentalMin, mentalMax) + ageFitnessBonus).clamp(
        0,
        100,
      ),
      DriverStats.feedback: (r(mentalMin, mentalMax) + ageFeedbackBonus).clamp(
        0,
        100,
      ),
      DriverStats.focus: r(mentalMin, mentalMax),
      DriverStats.morale:
          65 +
          _random.nextInt(21), // 65-85 (todos empiezan relativamente felices)
      // Atributos Externos
      DriverStats.marketability: r(30, isElite ? 75 : 55),
    };
  }

  /// Genera el potencial máximo por stat.
  /// El techo de cada stat es ligeramente superior al valor actual,
  /// con variación para crear diversidad entre pilotos.
  Map<String, int> _generateStatPotentials(
    bool isElite,
    Map<String, int> currentStats,
  ) {
    final potentials = <String, int>{};

    for (final statKey in DriverStats.all) {
      final current = currentStats[statKey] ?? 50;
      // El potencial máximo es el valor actual + un margen de mejora
      // Élite: puede mejorar 5-20 puntos más
      // Profesional: puede mejorar 3-15 puntos más
      final maxGrowth = isElite
          ? 5 +
                _random.nextInt(16) // 5 to 20
          : 3 + _random.nextInt(13); // 3 to 15

      // Stats físicos tienen menor techo de mejora para veteranos
      int ceiling = (current + maxGrowth).clamp(0, 100);

      // Algunos pilotos son "one-trick ponies": excelentes en un área
      // pero con techo bajo en otras. Esto crea diversidad.
      if (_random.nextInt(100) < 20) {
        // 20% de chance de tener un stat con techo muy alto (especialista)
        ceiling = (current + 15 + _random.nextInt(16)).clamp(0, 100);
      } else if (_random.nextInt(100) < 15) {
        // 15% de chance de tener un stat con techo bajo (debilidad permanente)
        ceiling = (current + _random.nextInt(6)).clamp(0, 100);
      }

      potentials[statKey] = ceiling;
    }

    return potentials;
  }

  /// Genera rasgos aleatorios para el piloto.
  /// La mayoría de pilotos tienen 0-2 rasgos.
  List<DriverTrait> _generateTraits(int age) {
    final traits = <DriverTrait>[];
    final allTraits = DriverTrait.values;

    // Rasgos basados en edad
    if (age > 35 && _random.nextInt(100) < 40) {
      traits.add(DriverTrait.veteran);
    }
    if (age < 23 && _random.nextInt(100) < 30) {
      traits.add(DriverTrait.youngProdigy);
    }

    // Rasgos aleatorios (excluyendo los ya asignados por edad)
    final remainingTraits = allTraits
        .where(
          (t) =>
              !traits.contains(t) &&
              t != DriverTrait.veteran &&
              t != DriverTrait.youngProdigy,
        )
        .toList();

    // 30% de chance de tener un rasgo adicional
    if (_random.nextInt(100) < 30 && remainingTraits.isNotEmpty) {
      traits.add(remainingTraits[_random.nextInt(remainingTraits.length)]);
    }

    // 10% de chance de tener un segundo rasgo adicional
    if (_random.nextInt(100) < 10 && remainingTraits.length > 1) {
      final available = remainingTraits
          .where((t) => !traits.contains(t))
          .toList();
      if (available.isNotEmpty) {
        traits.add(available[_random.nextInt(available.length)]);
      }
    }

    return traits;
  }
}
