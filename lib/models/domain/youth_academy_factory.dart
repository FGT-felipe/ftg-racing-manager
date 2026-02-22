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

    // Base skill scales with academy level: 7 → 15
    final baseSkill = 7 + ((level - 1) * 2);

    // Growth potential: 5-12, higher levels unlock higher range
    final maxGrowth = 5 + (level * 1.4).floor(); // level 1 → 6, level 5 → 12
    final growthPotential =
        5 + _random.nextInt((maxGrowth - 5 + 1).clamp(1, 8));

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
      salary: 100000,
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
