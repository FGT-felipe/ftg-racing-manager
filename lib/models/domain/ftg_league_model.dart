import 'country_model.dart';
import '../core_models.dart';
import 'youth_academy_factory.dart';

/// Modelo de dominio que representa una liga de FTG.
///
/// Una liga agrupa 11 equipos y sus pilotos.
/// No utiliza divisiones en esta versión simplificada.
class FtgLeague {
  /// ID único de la liga
  final String id;

  /// Nombre de la liga (e.g., "FTG World Championship")
  final String name;

  /// Lista de equipos de la liga (11 equipos)
  final List<Team> teams;

  /// Lista de pilotos activos en la liga
  final List<Driver> drivers;

  /// ID de la temporada actualmente en curso
  final String currentSeasonId;

  /// Nivel o jerarquía de la liga (1 = Principal, 2 = Secundaria, etc.)
  final int tier;

  /// País por defecto de la academia de la liga
  final Country academyCountry;

  /// Fábrica de pilotos jóvenes vinculada a esta liga
  late final YouthAcademyFactory academy;

  FtgLeague({
    required this.id,
    required this.name,
    required this.teams,
    required this.drivers,
    required this.currentSeasonId,
    required this.tier,
    Country? academyDefaultCountry,
  }) : academyCountry =
           academyDefaultCountry ??
           Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴') {
    academy = YouthAcademyFactory();
  }

  /// Retorna el total de equipos en la liga
  int totalTeams() {
    return teams.length;
  }

  /// Serializa la liga a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teams': teams.map((t) => t.toMap()).toList(),
      'drivers': drivers.map((d) => d.toMap()).toList(),
      'currentSeasonId': currentSeasonId,
      'tier': tier,
    };
  }

  /// Crea una instancia de FtgLeague desde un mapa de Firestore
  factory FtgLeague.fromMap(Map<String, dynamic> map) {
    return FtgLeague(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      teams: (map['teams'] as List<dynamic>? ?? [])
          .map((t) => Team.fromMap(Map<String, dynamic>.from(t)))
          .toList(),
      drivers: (map['drivers'] as List<dynamic>? ?? [])
          .map((d) => Driver.fromMap(Map<String, dynamic>.from(d)))
          .toList(),
      currentSeasonId: map['currentSeasonId'] ?? '',
      tier: map['tier'] ?? 1,
    );
  }

  /// Crea una copia de la liga con valores actualizados
  FtgLeague copyWith({
    String? id,
    String? name,
    List<Team>? teams,
    List<Driver>? drivers,
    String? currentSeasonId,
    int? tier,
  }) {
    return FtgLeague(
      id: id ?? this.id,
      name: name ?? this.name,
      teams: teams ?? this.teams,
      drivers: drivers ?? this.drivers,
      currentSeasonId: currentSeasonId ?? this.currentSeasonId,
      tier: tier ?? this.tier,
    );
  }

  @override
  String toString() =>
      'FtgLeague($name, ${totalTeams()} teams, ${drivers.length} drivers)';
}
