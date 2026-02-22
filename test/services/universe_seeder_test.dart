import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/services/universe_seeder.dart';

void main() {
  group('Phase 3: Universe Seeder Tests (Refactored)', () {
    test('creates initial universe with correct version and leagues', () {
      final universe = UniverseSeeder.createInitialUniverse();

      expect(universe, isNotNull);
      expect(universe.gameVersion, '1.1.0');
      expect(universe.leagues.length, 3);
    });

    test('creates the 3 main hierarchy leagues', () {
      final universe = UniverseSeeder.createInitialUniverse();

      final leagueIds = universe.leagues.map((l) => l.id).toList();
      expect(leagueIds, containsAll(['ftg_world', 'ftg_2th', 'ftg_karting']));

      final world = universe.getLeagueById('ftg_world');
      expect(world?.name, 'FTG World Championship');
      expect(world?.tier, 1);

      final second = universe.getLeagueById('ftg_2th');
      expect(second?.name, 'FTG 2th Series');
      expect(second?.tier, 2);

      final karting = universe.getLeagueById('ftg_karting');
      expect(karting?.name, 'FTG Karting Championship');
      expect(karting?.tier, 3);
    });

    test('each league has 11 teams and correct driver pairs', () {
      final universe = UniverseSeeder.createInitialUniverse();

      for (final league in universe.leagues) {
        expect(league.totalTeams(), 11);
        expect(league.teams.length, 11);

        // Cada liga debe tener 22 pilotos (2 por equipo)
        expect(league.drivers.length, 22);

        for (final team in league.teams) {
          final teamDrivers = league.drivers
              .where((d) => d.teamId == team.id)
              .toList();

          expect(
            teamDrivers.length,
            2,
            reason: 'Team ${team.id} should have 2 drivers',
          );

          final genders = teamDrivers.map((d) => d.gender).toList();
          expect(
            genders,
            containsAll(['M', 'F']),
            reason: 'Team ${team.id} must have 1 male and 1 female driver',
          );
        }
      }
    });

    test('each league has academy initialized with Colombia', () {
      final universe = UniverseSeeder.createInitialUniverse();

      for (final league in universe.leagues) {
        expect(league.academy, isNotNull);
        expect(league.academyCountry.code, 'CO');

        // El piloto generado por la academia debe ser de Colombia
        final youngDriver = league.academy.generatePromisingDriver(
          academyLevel: 1,
          country: league.academyCountry,
        );
        expect(youngDriver.nationality.code, 'CO');
      }
    });

    test('universe is serializable', () {
      final universe = UniverseSeeder.createInitialUniverse();

      final map = universe.toMap();
      final restored = GameUniverse.fromMap(map);

      expect(restored.leagues.length, universe.leagues.length);
      expect(restored.gameVersion, universe.gameVersion);

      for (int i = 0; i < universe.leagues.length; i++) {
        final original = universe.leagues[i];
        final restoredLeague = restored.leagues[i];

        expect(restoredLeague.id, original.id);
        expect(restoredLeague.name, original.name);
        expect(restoredLeague.teams.length, original.teams.length);
        expect(restoredLeague.drivers.length, original.drivers.length);
      }
    });

    test('multiple universe instances are independent', () {
      final universe1 = UniverseSeeder.createInitialUniverse();
      final universe2 = UniverseSeeder.createInitialUniverse();

      expect(identical(universe1, universe2), isFalse);
      expect(universe1.leagues.length, universe2.leagues.length);
    });
  });
}
