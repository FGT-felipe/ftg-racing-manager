import 'ftg_league_model.dart';

/// Modelo de dominio que representa el universo completo del juego.
///
/// Contiene todas las ligas activas organizadas por jerarquía. Este es el
/// contenedor de más alto nivel en la jerarquía del dominio.
class GameUniverse {
  /// Lista de ligas activas
  final List<FtgLeague> leagues;

  /// Fecha de creación del universo
  final DateTime createdAt;

  /// Versión del juego/esquema de datos
  final String gameVersion;

  GameUniverse({
    required this.leagues,
    required this.createdAt,
    this.gameVersion = "3.0.0",
  });

  /// Obtiene una liga por su ID
  FtgLeague? getLeagueById(String id) {
    try {
      return leagues.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retorna una lista de todas las ligas activas ordenadas por tier
  List<FtgLeague> getAllLeagues() {
    final sortedLeagues = List<FtgLeague>.from(leagues);
    sortedLeagues.sort((a, b) => a.tier.compareTo(b.tier));
    return sortedLeagues;
  }

  /// Retorna el número total de ligas activas
  int totalActiveLeagues() {
    return leagues.length;
  }

  /// Retorna el total de equipos en todo el universo
  int totalTeams() {
    return leagues.fold(0, (sum, league) => sum + league.totalTeams());
  }

  /// Crea una nueva instancia del universo con una liga agregada
  /// (inmutable - retorna nueva instancia)
  GameUniverse addLeague(FtgLeague league) {
    final updatedLeagues = List<FtgLeague>.from(leagues);
    updatedLeagues.add(league);
    return copyWith(leagues: updatedLeagues);
  }

  /// Crea una nueva instancia del universo con una liga removida
  /// (inmutable - retorna nueva instancia)
  GameUniverse removeLeague(String leagueId) {
    final updatedLeagues = List<FtgLeague>.from(leagues);
    updatedLeagues.removeWhere((l) => l.id == leagueId);
    return copyWith(leagues: updatedLeagues);
  }

  /// Serializa el universo a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'leagues': leagues.map((league) => league.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'gameVersion': gameVersion,
    };
  }

  /// Crea una instancia de GameUniverse desde un mapa de Firestore
  factory GameUniverse.fromMap(Map<String, dynamic> map) {
    final leaguesList = map['leagues'] as List<dynamic>? ?? [];
    final leagues = leaguesList
        .map(
          (leagueData) =>
              FtgLeague.fromMap(Map<String, dynamic>.from(leagueData)),
        )
        .toList();

    return GameUniverse(
      leagues: leagues,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      gameVersion: map['gameVersion'] ?? '1.0.0',
    );
  }

  /// Crea una copia del universo con valores actualizados
  GameUniverse copyWith({
    List<FtgLeague>? leagues,
    DateTime? createdAt,
    String? gameVersion,
  }) {
    return GameUniverse(
      leagues: leagues ?? this.leagues,
      createdAt: createdAt ?? this.createdAt,
      gameVersion: gameVersion ?? this.gameVersion,
    );
  }

  @override
  String toString() =>
      'GameUniverse(v$gameVersion, ${leagues.length} leagues, ${totalTeams()} teams)';
}
