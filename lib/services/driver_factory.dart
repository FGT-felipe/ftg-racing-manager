import 'dart:math';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';
import 'driver_portrait_service.dart';
import 'driver_name_service.dart';
import 'driver_status_service.dart';

/// Fábrica para generar pilotos experimentados.
///
/// Genera stats basados en el tier de la división.
/// Implementa distribución de nacionalidades: 40% CO, 60% Mundo.
class DriverFactory {
  /// Generador de números aleatorios
  final Random _random;

  /// Servicio de nombres de pilotos
  final DriverNameService _nameService;

  /// Contador para IDs únicos
  static int _globalCounter = 0;

  DriverFactory({Random? random})
    : _random = random ?? Random(),
      _nameService = DriverNameService();

  /// Genera un piloto para una competición
  ///
  /// [forcedCountry]: Si se provee, el piloto será de este país.
  /// [forcedGender]: Si se provee, será 'M' o 'F'.
  /// [divisionTier]: Afecta el rango de stats.
  Driver generateDriver({
    required int divisionTier,
    Country? forcedCountry,
    String? forcedGender,
  }) {
    final isElite = divisionTier == 1;
    final id = _generateId();
    final gender = forcedGender ?? _generateGender();
    final country = forcedCountry ?? _pickRandomCountry();
    final age = _generateAge(isElite);
    final stats = _generateStats(isElite, age);
    final statPotentials = _generateStatPotentials(isElite, stats);
    final traits = _generateTraits(age);

    final potential = _generatePotentialStars(isElite);
    final priorStats = _generatePriorStats(isElite, age, potential);

    final baseDriver = Driver(
      id: id,
      teamId: null,
      name: _generateName(gender, country.code),
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
        gender: gender,
      ),
    );

    final statusTitle = DriverStatusService.calculateTitle(baseDriver);

    return baseDriver.copyWith(statusTitle: statusTitle);
  }

  /// Genera un ID único para el piloto
  String _generateId() {
    return 'driver_${DateTime.now().millisecondsSinceEpoch}_${_globalCounter++}';
  }

  /// Genera un nombre completo usando el servicio centralizado
  String _generateName(String gender, String countryCode) {
    return _nameService.generateName(gender: gender, countryCode: countryCode);
  }

  /// Pick a random country based on required distribution:
  /// 40% Colombia, 60% Rest of the World
  Country _pickRandomCountry() {
    final roll = _random.nextInt(100);
    if (roll < 40) {
      return Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴');
    }

    // 60% Rest of World (Other SA, Europe, Asia, USA)
    final worldCountries = [
      Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷'),
      Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷'),
      Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽'),
      Country(code: 'UY', name: 'Uruguay', flagEmoji: '🇺🇾'),
      Country(code: 'CL', name: 'Chile', flagEmoji: '🇨🇱'),
      Country(code: 'ES', name: 'España', flagEmoji: '🇪🇸'),
      Country(code: 'IT', name: 'Italia', flagEmoji: '🇮🇹'),
      Country(code: 'GB', name: 'Reino Unido', flagEmoji: '🇬🇧'),
      Country(code: 'DE', name: 'Alemania', flagEmoji: '🇩🇪'),
      Country(code: 'FR', name: 'Francia', flagEmoji: '🇫🇷'),
      Country(code: 'JP', name: 'Japón', flagEmoji: '🇯🇵'),
      Country(code: 'US', name: 'EUA', flagEmoji: '🇺🇸'),
    ];

    return worldCountries[_random.nextInt(worldCountries.length)];
  }

  /// Genera edad basada en división.
  int _generateAge(bool isElite) {
    return 29 + _random.nextInt(12); // 29 to 40
  }

  /// Genera potencial (1-5 estrellas).
  int _generatePotentialStars(bool isElite) {
    if (isElite) {
      return 3 + _random.nextInt(3);
    } else {
      return 1 + _random.nextInt(4);
    }
  }

  /// Genera género aleatorio
  String _generateGender() {
    return _random.nextBool() ? 'M' : 'F';
  }

  /// Genera estadísticas históricas coherentes
  Map<String, int> _generatePriorStats(bool isElite, int age, int potential) {
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

    final baseWinRatio = potential * 0.05;
    final basePodiumRatio = potential * 0.12;

    for (int i = 0; i < yearsPro; i++) {
      final seasonRaces = 9;
      totalRaces += seasonRaces;
      final yearMod = 0.5 + _random.nextDouble();

      int yearWins = (seasonRaces * baseWinRatio * yearMod).floor();
      if (yearWins > seasonRaces) yearWins = seasonRaces;

      int yearPodiums = (seasonRaces * basePodiumRatio * yearMod).floor();
      if (yearPodiums > seasonRaces) yearPodiums = seasonRaces;
      if (yearPodiums < yearWins) yearPodiums = yearWins;

      totalWins += yearWins;
      totalPodiums += yearPodiums;

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

  /// Genera todos los stats del piloto.
  Map<String, int> _generateStats(bool isElite, int age) {
    final drivingMin = isElite ? 60 : 40;
    final drivingMax = isElite ? 85 : 65;
    final mentalMin = isElite ? 55 : 35;
    final mentalMax = isElite ? 80 : 60;

    int r(int min, int max) => min + _random.nextInt(max - min + 1);

    final ageFitnessBonus = age > 35 ? -10 : (age < 25 ? 5 : 0);
    final ageFeedbackBonus = age > 32 ? 8 : 0;
    final ageConsistencyBonus = age > 32 ? 5 : 0;

    return {
      DriverStats.braking: r(drivingMin, drivingMax),
      DriverStats.cornering: r(drivingMin, drivingMax),
      DriverStats.smoothness: r(drivingMin, drivingMax),
      DriverStats.overtaking: r(drivingMin, drivingMax),
      DriverStats.consistency: (r(drivingMin, drivingMax) + ageConsistencyBonus)
          .clamp(0, 100),
      DriverStats.adaptability: r(drivingMin, drivingMax),
      DriverStats.fitness: (r(mentalMin, mentalMax) + ageFitnessBonus).clamp(
        0,
        100,
      ),
      DriverStats.feedback: (r(mentalMin, mentalMax) + ageFeedbackBonus).clamp(
        0,
        100,
      ),
      DriverStats.focus: r(mentalMin, mentalMax),
      DriverStats.morale: 65 + _random.nextInt(21),
      DriverStats.marketability: r(30, isElite ? 75 : 55),
    };
  }

  /// Genera el potencial máximo por stat.
  Map<String, int> _generateStatPotentials(
    bool isElite,
    Map<String, int> currentStats,
  ) {
    final potentials = <String, int>{};

    for (final statKey in DriverStats.all) {
      final current = currentStats[statKey] ?? 50;
      final maxGrowth = isElite
          ? 5 + _random.nextInt(16)
          : 3 + _random.nextInt(13);

      int ceiling = (current + maxGrowth).clamp(0, 100);

      if (_random.nextInt(100) < 20) {
        ceiling = (current + 15 + _random.nextInt(16)).clamp(0, 100);
      } else if (_random.nextInt(100) < 15) {
        ceiling = (current + _random.nextInt(6)).clamp(0, 100);
      }

      potentials[statKey] = ceiling;
    }

    return potentials;
  }

  /// Genera rasgos aleatorios para el piloto.
  List<DriverTrait> _generateTraits(int age) {
    final traits = <DriverTrait>[];
    final allTraits = DriverTrait.values;

    if (age > 35 && _random.nextInt(100) < 40) {
      traits.add(DriverTrait.veteran);
    }
    if (age < 23 && _random.nextInt(100) < 30) {
      traits.add(DriverTrait.youngProdigy);
    }

    final remainingTraits = allTraits
        .where(
          (t) =>
              !traits.contains(t) &&
              t != DriverTrait.veteran &&
              t != DriverTrait.youngProdigy,
        )
        .toList();

    if (_random.nextInt(100) < 30 && remainingTraits.isNotEmpty) {
      traits.add(remainingTraits[_random.nextInt(remainingTraits.length)]);
    }

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
