import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/services/universe_seeder.dart';

void main() {
  group('Phase 3: Universe Seeder Tests', () {
    test('creates initial universe with correct structure', () {
      final universe = UniverseSeeder.createInitialUniverse();

      expect(universe, isNotNull);
      expect(universe.gameVersion, '1.0.0');
      expect(universe.createdAt, isNotNull);
    });

    test('creates 6 country leagues', () {
      final universe = UniverseSeeder.createInitialUniverse();

      expect(universe.totalActiveLeagues(), 6);
      expect(universe.activeLeagues.length, 6);
    });

    test('includes all expected countries', () {
      final universe = UniverseSeeder.createInitialUniverse();

      final expectedCountries = ['BR', 'AR', 'CO', 'MX', 'UY', 'CL'];

      for (final code in expectedCountries) {
        final league = universe.getLeagueByCountry(code);
        expect(league, isNotNull, reason: 'Missing league for country $code');
        expect(league!.country.code, code);
      }
    });

    test('each country has correct league structure', () {
      final universe = UniverseSeeder.createInitialUniverse();

      for (final league in universe.getAllLeagues()) {
        // League debe tener ID basado en el código del país
        expect(league.id, contains(league.country.code.toLowerCase()));

        // Nombre debe contener el nombre del país
        expect(league.name, contains(league.country.name));

        // Debe tener 2 divisiones
        expect(league.divisions.length, 2);

        // Debe tener academy inicializada
        expect(league.academy, isNotNull);
        expect(league.academy.country.code, league.country.code);
      }
    });

    test('each league has 2 divisions with correct tiers', () {
      final universe = UniverseSeeder.createInitialUniverse();

      for (final league in universe.getAllLeagues()) {
        final divisions = league.divisions;

        expect(divisions.length, 2);

        // División Élite (tier 1)
        final eliteDivision = divisions.firstWhere((d) => d.tier == 1);
        expect(eliteDivision.name, 'División Élite');
        expect(eliteDivision.maxCapacity, 10);
        expect(eliteDivision.teamIds, isEmpty);

        // División Profesional (tier 2)
        final proDivision = divisions.firstWhere((d) => d.tier == 2);
        expect(proDivision.name, 'División Profesional');
        expect(proDivision.maxCapacity, 10);
        expect(proDivision.teamIds, isEmpty);
      }
    });

    test('divisions have correct IDs and references', () {
      final universe = UniverseSeeder.createInitialUniverse();

      for (final league in universe.getAllLeagues()) {
        for (final division in league.divisions) {
          // ID debe contener el código del país
          expect(division.id, contains(league.country.code.toLowerCase()));

          // countryLeagueId debe coincidir con el ID de la liga
          expect(division.countryLeagueId, league.id);
        }
      }
    });

    test('each league can generate young drivers', () {
      final universe = UniverseSeeder.createInitialUniverse();

      for (final league in universe.getAllLeagues()) {
        final youngDriver = league.academy.generatePromisingDriver();

        expect(youngDriver, isNotNull);
        expect(youngDriver.nationality.code, league.country.code);
        expect(youngDriver.age, greaterThanOrEqualTo(16));
        expect(youngDriver.age, lessThanOrEqualTo(19));
      }
    });

    test('universe is serializable', () {
      final universe = UniverseSeeder.createInitialUniverse();

      final map = universe.toMap();
      final restored = GameUniverse.fromMap(map);

      expect(restored.totalActiveLeagues(), universe.totalActiveLeagues());
      expect(restored.gameVersion, universe.gameVersion);

      // Verificar que todas las ligas se serializaron correctamente
      for (final code in ['BR', 'AR', 'CO', 'MX', 'UY', 'CL']) {
        final originalLeague = universe.getLeagueByCountry(code);
        final restoredLeague = restored.getLeagueByCountry(code);

        expect(restoredLeague, isNotNull);
        expect(restoredLeague!.id, originalLeague!.id);
        expect(restoredLeague.country.code, originalLeague.country.code);
        expect(
          restoredLeague.divisions.length,
          originalLeague.divisions.length,
        );
      }
    });

    test('brasil league has correct configuration', () {
      final universe = UniverseSeeder.createInitialUniverse();
      final leagueBR = universe.getLeagueByCountry('BR');

      expect(leagueBR, isNotNull);
      expect(leagueBR!.id, 'league_br');
      expect(leagueBR.country.code, 'BR');
      expect(leagueBR.country.name, 'Brasil');
      expect(leagueBR.country.flagEmoji, '🇧🇷');
      expect(leagueBR.name, 'Liga Brasil');
      expect(leagueBR.currentSeasonId, 'season_2026_br');
    });

    test('argentina league has correct configuration', () {
      final universe = UniverseSeeder.createInitialUniverse();
      final leagueAR = universe.getLeagueByCountry('AR');

      expect(leagueAR, isNotNull);
      expect(leagueAR!.id, 'league_ar');
      expect(leagueAR.country.code, 'AR');
      expect(leagueAR.country.name, 'Argentina');
      expect(leagueAR.country.flagEmoji, '🇦🇷');
      expect(leagueAR.name, 'Liga Argentina');
    });

    test('multiple universe instances are independent', () {
      final universe1 = UniverseSeeder.createInitialUniverse();
      final universe2 = UniverseSeeder.createInitialUniverse();

      // Deben ser instancias diferentes
      expect(identical(universe1, universe2), isFalse);

      // Pero con la misma estructura
      expect(universe1.totalActiveLeagues(), universe2.totalActiveLeagues());
    });

    test('total teams is zero initially', () {
      final universe = UniverseSeeder.createInitialUniverse();

      // No hay equipos asignados todavía
      expect(universe.totalTeams(), 0);

      for (final league in universe.getAllLeagues()) {
        expect(league.totalTeams(), 0);
      }
    });

    test('all divisions have available slots', () {
      final universe = UniverseSeeder.createInitialUniverse();

      for (final league in universe.getAllLeagues()) {
        for (final division in league.divisions) {
          expect(division.hasSpace(), isTrue);
          expect(division.isFull(), isFalse);
          expect(division.availableSlots(), 10);
        }
      }
    });

    test('can access divisions by tier', () {
      final universe = UniverseSeeder.createInitialUniverse();
      final league = universe.getLeagueByCountry('CO');

      final eliteDivision = league!.getDivisionByTier(1);
      final proDivision = league.getDivisionByTier(2);
      final nonexistent = league.getDivisionByTier(3);

      expect(eliteDivision, isNotNull);
      expect(eliteDivision!.tier, 1);

      expect(proDivision, isNotNull);
      expect(proDivision!.tier, 2);

      expect(nonexistent, isNull);
    });

    test('integration: universe with all phases combined', () {
      // Fase 1: GameUniverse
      final universe = UniverseSeeder.createInitialUniverse();

      // Verificar estructura completa
      expect(universe.totalActiveLeagues(), 6);

      // Fase 2: Youth Academy
      final leagueMX = universe.getLeagueByCountry('MX');
      final youngDriver = leagueMX!.academy.generatePromisingDriver();

      expect(youngDriver.nationality.code, 'MX');

      // Fase 3: Verificar que todo funciona junto
      final allLeagues = universe.getAllLeagues();
      for (final league in allLeagues) {
        // Cada liga puede generar pilotos
        final driver = league.academy.generatePromisingDriver();
        expect(driver.nationality.code, league.country.code);

        // Cada liga tiene divisiones válidas
        expect(league.divisions.length, 2);
        expect(league.getDivisionByTier(1), isNotNull);
        expect(league.getDivisionByTier(2), isNotNull);
      }
    });
  });
}
