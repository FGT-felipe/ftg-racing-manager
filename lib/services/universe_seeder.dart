import '../models/domain/domain_models.dart';
import '../models/core_models.dart';

/// Seeder para crear un GameUniverse con la jerarquía FTG.
class UniverseSeeder {
  /// Crea el universo inicial con las 3 ligas principales
  static GameUniverse createInitialUniverse() {
    final worldChampionship = _createLeague(
      id: 'ftg_world',
      name: 'FTG World Championship',
      tier: 1,
    );

    final secondSeries = _createLeague(
      id: 'ftg_2th',
      name: 'FTG 2th Series',
      tier: 2,
    );

    final kartingChampionship = _createLeague(
      id: 'ftg_karting',
      name: 'FTG Karting Championship',
      tier: 3,
    );

    return GameUniverse(
      leagues: [worldChampionship, secondSeries, kartingChampionship],
      createdAt: DateTime.now(),
      gameVersion: '1.1.0',
    );
  }

  /// Crea una liga vacía con su configuración básica
  static FtgLeague _createLeague({
    required String id,
    required String name,
    required int tier,
  }) {
    final teams = <Team>[];
    final drivers = <Driver>[];

    final defaultCountry = Country(
      code: 'CO',
      name: 'Colombia',
      flagEmoji: '🇨🇴',
    );

    return FtgLeague(
      id: id,
      name: name,
      tier: tier,
      academyDefaultCountry: defaultCountry,
      teams: teams,
      drivers: drivers,
      currentSeasonId: 'season_2026_$id',
    );
  }
}
