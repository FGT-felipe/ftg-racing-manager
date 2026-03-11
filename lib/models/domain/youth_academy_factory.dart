import 'dart:math';
import 'country_model.dart';
import 'young_driver_model.dart';
import '../../services/driver_portrait_service.dart';
import '../../services/driver_name_service.dart';
import '../../models/core_models.dart';

/// Fábrica para generar pilotos jóvenes prometedores para la academia.
///
/// Genera stats escalados según el nivel de la academia:
/// - Nivel 1: baseSkill ~7, growthPotential 5-7
/// - Nivel 5: baseSkill ~15, growthPotential 5-12
class YouthAcademyFactory {
  final Random _random;
  final DriverNameService _nameService;

  YouthAcademyFactory({Random? random})
    : _random = random ?? Random(),
      _nameService = DriverNameService();

  /// Genera un par de candidatos (1 hombre + 1 mujer) para la academia.
  ///
  /// [academyLevel]: Nivel actual de la academia (1-5)
  /// [country]: País de la academia (elegido al comprar)
  List<YoungDriver> generateCandidatePair({
    required int academyLevel,
    required Country country,
  }) {
    return [
      generatePromisingDriver(
        academyLevel: academyLevel,
        country: country,
        forcedGender: 'M',
      ),
      generatePromisingDriver(
        academyLevel: academyLevel,
        country: country,
        forcedGender: 'F',
      ),
    ];
  }

  /// Genera un piloto joven prometedor.
  ///
  /// Stats escalados por nivel de academia:
  /// - Base skill: 7 + (level - 1) * 2 → 7 at level 1, 15 at level 5
  /// - Growth potential: 5 + random(0, level * 1.5) → better academies find higher-ceiling talent
  YoungDriver generatePromisingDriver({
    required int academyLevel,
    required Country country,
    String? forcedGender,
  }) {
    final id = _generateId(country.code);
    final gender = forcedGender ?? (_random.nextBool() ? 'M' : 'F');
    final age = _generateAge();
    final level = academyLevel.clamp(1, 5);

    // Determine potential stars and base skill based on Academy Level
    // Each star represents roughly 20 points of skill (0-100 scale)
    // Level 1: Current potential 1-3 stars (20-60). Max potential 2-3.5 stars
    // Level 5: Current potential 2-4 stars (40-80). Max potential 4-5 stars

    double minCurrentStars;
    double maxCurrentStars;
    double minMaxStars;
    double maxMaxStars;

    switch (level) {
      case 1:
        minCurrentStars = 1.0;
        maxCurrentStars = 3.0;
        minMaxStars = 2.0;
        maxMaxStars = 3.5;
        break;
      case 2:
        minCurrentStars = 1.0;
        maxCurrentStars = 3.5;
        minMaxStars = 2.5;
        maxMaxStars = 4.0;
        break;
      case 3:
        minCurrentStars = 1.5;
        maxCurrentStars = 3.5;
        minMaxStars = 3.0;
        maxMaxStars = 4.5;
        break;
      case 4:
        minCurrentStars = 2.0;
        maxCurrentStars = 4.0;
        minMaxStars = 3.5;
        maxMaxStars = 5.0;
        break;
      case 5:
      default:
        minCurrentStars = 2.0;
        maxCurrentStars = 4.0;
        minMaxStars = 4.0;
        maxMaxStars = 5.0;
        break;
    }

    // Generate actual star values
    final currentStars =
        minCurrentStars +
        (_random.nextDouble() * (maxCurrentStars - minCurrentStars));

    // Max stars cannot be lower than current stars
    final actualMinMax = max(currentStars, minMaxStars);
    final maxStars =
        actualMinMax + (_random.nextDouble() * (maxMaxStars - actualMinMax));

    // Convert stars to 0-100 skill scale (1 star = ~20 points)
    final baseSkill = (currentStars * 20).round().clamp(10, 80);
    final maxSkill = (maxStars * 20).round().clamp(baseSkill, 100);

    final growthPotential = maxSkill - baseSkill;

    // Generate stat ranges based on baseSkill and growthPotential
    final statRangeMin = <String, int>{};
    final statRangeMax = <String, int>{};

    for (final statKey in DriverStats.all) {
      // Each stat has a base ± random variance
      final variance = _random.nextInt(4); // 0-3 variance
      final minVal = (baseSkill - 2 + variance).clamp(1, 100);
      final maxVal = (baseSkill + growthPotential + variance).clamp(
        minVal,
        100,
      );
      statRangeMin[statKey] = minVal;
      statRangeMax[statKey] = maxVal;
    }

    // Expiration: 7 days from now (weekly cycle)
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    return YoungDriver(
      id: id,
      name: _nameService.generateName(
        gender: gender,
        countryCode: country.code,
      ),
      nationality: country,
      age: age,
      baseSkill: baseSkill,
      gender: gender,
      growthPotential: growthPotential,
      portraitUrl: DriverPortraitService().getPortraitUrl(
        driverId: id,
        gender: gender,
        countryCode: country.code,
        age: age,
      ),
      status: 'candidate',
      expiresAt: expiresAt,
      salary: 10000,
      contractYears: 1,
      statRangeMin: statRangeMin,
      statRangeMax: statRangeMax,
    );
  }

  /// Genera un solo candidato de reemplazo con el género especificado.
  YoungDriver generateReplacement({
    required int academyLevel,
    required Country country,
    required String gender,
  }) {
    return generatePromisingDriver(
      academyLevel: academyLevel,
      country: country,
      forcedGender: gender,
    );
  }

  String _generateId(String countryCode) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(999999);
    return 'young_${countryCode}_${timestamp}_$randomSuffix';
  }

  int _generateAge() {
    return 16 + _random.nextInt(4); // 16, 17, 18, 19
  }
}
