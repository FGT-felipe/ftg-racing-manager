import '../models/domain/domain_models.dart';

/// Seeder para crear un GameUniverse completo con múltiples países.
///
/// Genera la estructura inicial del universo del juego con países
/// sudamericanos, cada uno con su liga nacional y divisiones.
class UniverseSeeder {
  /// Crea un universo inicial con países de Sudamérica
  ///
  /// Genera:
  /// - 6 países: Brasil, Argentina, Colombia, México, Uruguay, Chile
  /// - Cada país tiene 1 liga nacional
  /// - Cada liga tiene 2 divisiones (Élite y Profesional)
  /// - Las academias se auto-inicializan por país
  static GameUniverse createInitialUniverse() {
    final countries = _createCountries();
    final activeLeagues = <String, CountryLeague>{};

    for (final country in countries) {
      final league = _createCountryLeague(country);
      activeLeagues[country.code] = league;
    }

    return GameUniverse(
      activeLeagues: activeLeagues,
      createdAt: DateTime.now(),
      gameVersion: '1.0.0',
    );
  }

  /// Lista de países sudamericanos para el juego
  static List<Country> _createCountries() {
    return [
      Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷'),
      Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷'),
      Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴'),
      Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽'),
      Country(code: 'UY', name: 'Uruguay', flagEmoji: '🇺🇾'),
      Country(code: 'CL', name: 'Chile', flagEmoji: '🇨🇱'),
    ];
  }

  /// Crea una liga nacional con divisiones para un país
  static CountryLeague _createCountryLeague(Country country) {
    final divisions = _createDivisions(country);

    return CountryLeague(
      id: 'league_${country.code.toLowerCase()}',
      country: country,
      name: 'Liga ${country.name}',
      divisions: divisions,
      currentSeasonId: 'season_2026_${country.code.toLowerCase()}',
    );
    // La academy se auto-inicializa con el país!
  }

  /// Crea 2 divisiones para cada país
  ///
  /// División 1 (Élite): Tier 1, capacidad 10 equipos
  /// División 2 (Profesional): Tier 2, capacidad 10 equipos
  static List<LeagueDivision> _createDivisions(Country country) {
    final countryCode = country.code.toLowerCase();

    return [
      LeagueDivision(
        id: 'div_${countryCode}_elite',
        countryLeagueId: 'league_$countryCode',
        name: 'División Élite',
        tier: 1,
        maxCapacity: 10,
        teamIds: [], // Se poblarán en fases futuras
      ),
      LeagueDivision(
        id: 'div_${countryCode}_pro',
        countryLeagueId: 'league_$countryCode',
        name: 'División Profesional',
        tier: 2,
        maxCapacity: 10,
        teamIds: [],
      ),
    ];
  }
}
