/// Modelo de dominio que representa una división dentro de una liga nacional.
///
/// Extiende el concepto de Division del core_models con capacidad máxima
/// y lista de equipos participantes. Las divisiones están ordenadas por tier
/// (1 = élite, 2 = segunda división, etc.)
class LeagueDivision {
  /// ID único de la división
  final String id;

  /// ID de la CountryLeague a la que pertenece esta división
  final String countryLeagueId;

  /// Nombre de la división (e.g., "Primera División", "División de Plata")
  final String name;

  /// Nivel jerárquico: 1 = élite, 2 = segunda, etc.
  final int tier;

  /// Cantidad máxima de equipos permitidos en esta división
  final int maxCapacity;

  /// Lista de IDs de equipos que participan en esta división
  final List<String> teamIds;

  LeagueDivision({
    required this.id,
    required this.countryLeagueId,
    required this.name,
    required this.tier,
    required this.maxCapacity,
    this.teamIds = const [],
  });

  /// Verifica si la división está llena
  bool isFull() => teamIds.length >= maxCapacity;

  /// Verifica si hay espacio disponible
  bool hasSpace() => !isFull();

  /// Retorna la cantidad de slots disponibles
  int availableSlots() => maxCapacity - teamIds.length;

  /// Serializa la división a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryLeagueId': countryLeagueId,
      'name': name,
      'tier': tier,
      'maxCapacity': maxCapacity,
      'teamIds': teamIds,
    };
  }

  /// Crea una instancia de LeagueDivision desde un mapa de Firestore
  factory LeagueDivision.fromMap(Map<String, dynamic> map) {
    return LeagueDivision(
      id: map['id'] ?? '',
      countryLeagueId: map['countryLeagueId'] ?? '',
      name: map['name'] ?? '',
      tier: map['tier'] ?? 1,
      maxCapacity: map['maxCapacity'] ?? 10,
      teamIds: List<String>.from(map['teamIds'] ?? []),
    );
  }

  /// Crea una copia de la división con equipos actualizados
  LeagueDivision copyWith({
    String? id,
    String? countryLeagueId,
    String? name,
    int? tier,
    int? maxCapacity,
    List<String>? teamIds,
  }) {
    return LeagueDivision(
      id: id ?? this.id,
      countryLeagueId: countryLeagueId ?? this.countryLeagueId,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      teamIds: teamIds ?? this.teamIds,
    );
  }

  @override
  String toString() =>
      'LeagueDivision($name, Tier $tier, ${teamIds.length}/$maxCapacity teams)';
}
