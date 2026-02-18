import 'country_league_model.dart';

/// Modelo de dominio que representa el universo completo del juego.
///
/// Contiene todas las ligas activas organizadas por país. Este es el
/// contenedor de más alto nivel en la jerarquía del dominio.
class GameUniverse {
  /// Mapa de ligas activas, indexado por código de país
  /// Key = country code (e.g., "BR", "AR", "MX")
  /// Value = CountryLeague
  final Map<String, CountryLeague> activeLeagues;

  /// Fecha de creación del universo
  final DateTime createdAt;

  /// Versión del juego/esquema de datos
  final String gameVersion;

  GameUniverse({
    required this.activeLeagues,
    required this.createdAt,
    this.gameVersion = "1.0.0",
  });

  /// Obtiene la liga de un país específico por su código
  CountryLeague? getLeagueByCountry(String countryCode) {
    return activeLeagues[countryCode];
  }

  /// Retorna una lista de todas las ligas activas
  List<CountryLeague> getAllLeagues() {
    return activeLeagues.values.toList();
  }

  /// Retorna el número total de ligas activas
  int totalActiveLeagues() {
    return activeLeagues.length;
  }

  /// Retorna el total de equipos en todo el universo
  int totalTeams() {
    return activeLeagues.values.fold(
      0,
      (sum, league) => sum + league.totalTeams(),
    );
  }

  /// Crea una nueva instancia del universo con una liga agregada
  /// (inmutable - retorna nueva instancia)
  GameUniverse addLeague(CountryLeague league) {
    final updatedLeagues = Map<String, CountryLeague>.from(activeLeagues);
    updatedLeagues[league.country.code] = league;
    return copyWith(activeLeagues: updatedLeagues);
  }

  /// Crea una nueva instancia del universo con una liga removida
  /// (inmutable - retorna nueva instancia)
  GameUniverse removeLeague(String countryCode) {
    final updatedLeagues = Map<String, CountryLeague>.from(activeLeagues);
    updatedLeagues.remove(countryCode);
    return copyWith(activeLeagues: updatedLeagues);
  }

  /// Serializa el universo a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'activeLeagues': activeLeagues.map(
        (code, league) => MapEntry(code, league.toMap()),
      ),
      'createdAt': createdAt.toIso8601String(),
      'gameVersion': gameVersion,
    };
  }

  /// Crea una instancia de GameUniverse desde un mapa de Firestore
  factory GameUniverse.fromMap(Map<String, dynamic> map) {
    final leaguesMap = map['activeLeagues'] as Map<String, dynamic>? ?? {};
    final activeLeagues = leaguesMap.map(
      (code, leagueData) => MapEntry(
        code,
        CountryLeague.fromMap(Map<String, dynamic>.from(leagueData)),
      ),
    );

    return GameUniverse(
      activeLeagues: activeLeagues,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      gameVersion: map['gameVersion'] ?? '1.0.0',
    );
  }

  /// Crea una copia del universo con valores actualizados
  GameUniverse copyWith({
    Map<String, CountryLeague>? activeLeagues,
    DateTime? createdAt,
    String? gameVersion,
  }) {
    return GameUniverse(
      activeLeagues: activeLeagues ?? this.activeLeagues,
      createdAt: createdAt ?? this.createdAt,
      gameVersion: gameVersion ?? this.gameVersion,
    );
  }

  @override
  String toString() =>
      'GameUniverse(v$gameVersion, ${activeLeagues.length} leagues, $totalTeams teams)';
}
