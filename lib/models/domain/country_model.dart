/// Modelo de dominio que representa un país en el sistema de ligas.
///
/// Este modelo contiene la información básica de identificación de un país,
/// incluyendo su código ISO, nombre completo y emoji de bandera para UI.
class Country {
  /// Código ISO del país (e.g., "BR", "AR", "MX")
  final String code;

  /// Nombre completo del país (e.g., "Brasil", "Argentina")
  final String name;

  /// Emoji de bandera para mostrar en UI (e.g., "🇧🇷", "🇦🇷")
  final String flagEmoji;

  Country({required this.code, required this.name, required this.flagEmoji});

  /// Serializa el país a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {'code': code, 'name': name, 'flagEmoji': flagEmoji};
  }

  /// Crea una instancia de Country desde un mapa de Firestore
  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      flagEmoji: map['flagEmoji'] ?? '🏁',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Country($code: $name $flagEmoji)';
}
