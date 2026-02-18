import 'dart:math';
import 'country_model.dart';
import 'young_driver_model.dart';
import '../../services/driver_portrait_service.dart';
import '../../services/driver_name_service.dart';

/// Fábrica para generar pilotos jóvenes prometedores de un país específico.
///
/// Implementa el patrón Factory con contexto inmutable (Country).
/// Cada CountryLeague tiene su propia academia vinculada a su país.
class YouthAcademyFactory {
  /// País del cual esta academia genera pilotos (inmutable)
  final Country country;

  /// Generador de números aleatorios
  final Random _random;

  /// Servicio centralizado de nombres de pilotos
  final DriverNameService _nameService;

  YouthAcademyFactory(this.country)
    : _random = Random(),
      _nameService = DriverNameService();

  /// Genera un piloto joven prometedor de este país
  ///
  /// El piloto tendrá:
  /// - Nationality del país de la academia (garantizado)
  /// - Edad entre 16-19 años
  /// - BaseSkill entre 35-55 (sin experiencia)
  /// - Potential entre 70-95
  /// - Nombre simulado basado en el país
  YoungDriver generatePromisingDriver() {
    final id = _generateId();
    final gender = _generateGender();
    final age = _generateAge();

    return YoungDriver(
      id: id,
      name: _generateName(gender),
      nationality: country,
      age: age,
      baseSkill: _generateBaseSkill(),
      gender: gender,
      potential: _generatePotential(),
      portraitUrl: DriverPortraitService().getPortraitUrl(
        driverId: id,
        countryCode: country.code,
        gender: gender,
        age: age,
      ),
    );
  }

  /// Genera un ID único para el piloto usando timestamp y random
  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(999999);
    return 'young_${country.code}_${timestamp}_$randomSuffix';
  }

  /// Genera un nombre simulado usando el servicio centralizado
  String _generateName(String gender) {
    return _nameService.generateName(gender: gender, countryCode: country.code);
  }

  /// Genera edad para piloto joven (16-19 años)
  int _generateAge() {
    return 16 + _random.nextInt(4); // 16, 17, 18, 19
  }

  /// Genera habilidad base para piloto sin experiencia (35-55)
  int _generateBaseSkill() {
    return 35 + _random.nextInt(21); // 35 to 55
  }

  /// Genera género del piloto
  String _generateGender() {
    return _random.nextBool() ? 'M' : 'F';
  }

  /// Genera potencial máximo del piloto (70-95)
  int _generatePotential() {
    return 70 + _random.nextInt(26); // 70 to 95
  }
}
