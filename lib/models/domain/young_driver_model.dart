import 'country_model.dart';

/// Modelo de dominio que representa un piloto joven generado por la academia.
///
/// A diferencia del Driver de core_models, este modelo está específicamente
/// diseñado para pilotos prometedores sin experiencia y vinculados a un país.
class YoungDriver {
  /// ID único del piloto
  final String id;

  /// Nombre completo del piloto
  final String name;

  /// Nacionalidad del piloto (obligatoria, vinculada al país de la academia)
  final Country nationality;

  /// Edad del piloto (típicamente 16-19 años para jóvenes promesas)
  final int age;

  /// Habilidad base inicial (sin experiencia en carreras)
  /// Rango típico: 30-60 para jóvenes
  final int baseSkill;

  /// Género del piloto ('M' o 'F')
  final String gender;

  /// Potencial máximo que puede alcanzar (70-99)
  final int potential;

  YoungDriver({
    required this.id,
    required this.name,
    required this.nationality,
    required this.age,
    required this.baseSkill,
    required this.gender,
    required this.potential,
  });

  /// Serializa el piloto joven a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nationality': nationality.toMap(),
      'age': age,
      'baseSkill': baseSkill,
      'gender': gender,
      'potential': potential,
    };
  }

  /// Crea una instancia de YoungDriver desde un mapa de Firestore
  factory YoungDriver.fromMap(Map<String, dynamic> map) {
    return YoungDriver(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown Driver',
      nationality: Country.fromMap(
        Map<String, dynamic>.from(map['nationality'] ?? {}),
      ),
      age: map['age'] ?? 18,
      baseSkill: map['baseSkill'] ?? 40,
      gender: map['gender'] ?? 'M',
      potential: map['potential'] ?? 75,
    );
  }

  @override
  String toString() =>
      'YoungDriver($name, ${nationality.code}, age $age, skill $baseSkill)';
}
