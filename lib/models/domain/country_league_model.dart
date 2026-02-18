import 'country_model.dart';
import 'league_division_model.dart';
import 'youth_academy_factory.dart';

/// Modelo de dominio que representa la liga nacional de un país.
///
/// Agrupa todas las divisiones de un país en una estructura jerárquica.
/// Cada liga tiene múltiples divisiones ordenadas por tier (1, 2, 3, etc.)
class CountryLeague {
  /// ID único de la liga
  final String id;

  /// País al que pertenece esta liga
  final Country country;

  /// Nombre de la liga (e.g., "Liga Brasileña", "Liga Argentina")
  final String name;

  /// Lista de divisiones ordenadas por tier (élite primero)
  final List<LeagueDivision> divisions;

  /// ID de la temporada actualmente en curso
  final String currentSeasonId;

  /// Fábrica de pilotos jóvenes de este país
  late final YouthAcademyFactory academy;

  CountryLeague({
    required this.id,
    required this.country,
    required this.name,
    required this.divisions,
    required this.currentSeasonId,
  }) {
    // Inicializar la academia con el país de esta liga
    academy = YouthAcademyFactory(country);
  }

  /// Obtiene una división por su tier (1 = élite, 2 = segunda, etc.)
  LeagueDivision? getDivisionByTier(int tier) {
    try {
      return divisions.firstWhere((div) => div.tier == tier);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene una división por su ID
  LeagueDivision? getDivisionById(String divisionId) {
    try {
      return divisions.firstWhere((div) => div.id == divisionId);
    } catch (e) {
      return null;
    }
  }

  /// Retorna el total de equipos en todas las divisiones
  int totalTeams() {
    return divisions.fold(0, (sum, div) => sum + div.teamIds.length);
  }

  /// Serializa la liga a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'country': country.toMap(),
      'name': name,
      'divisions': divisions.map((div) => div.toMap()).toList(),
      'currentSeasonId': currentSeasonId,
    };
  }

  /// Crea una instancia de CountryLeague desde un mapa de Firestore
  factory CountryLeague.fromMap(Map<String, dynamic> map) {
    return CountryLeague(
      id: map['id'] ?? '',
      country: Country.fromMap(Map<String, dynamic>.from(map['country'] ?? {})),
      name: map['name'] ?? '',
      divisions: (map['divisions'] as List<dynamic>? ?? [])
          .map((div) => LeagueDivision.fromMap(Map<String, dynamic>.from(div)))
          .toList(),
      currentSeasonId: map['currentSeasonId'] ?? '',
    );
  }

  /// Crea una copia de la liga con valores actualizados
  CountryLeague copyWith({
    String? id,
    Country? country,
    String? name,
    List<LeagueDivision>? divisions,
    String? currentSeasonId,
  }) {
    return CountryLeague(
      id: id ?? this.id,
      country: country ?? this.country,
      name: name ?? this.name,
      divisions: divisions ?? this.divisions,
      currentSeasonId: currentSeasonId ?? this.currentSeasonId,
    );
  }

  @override
  String toString() =>
      'CountryLeague(${country.name}, ${divisions.length} divisions, $totalTeams teams)';
}
