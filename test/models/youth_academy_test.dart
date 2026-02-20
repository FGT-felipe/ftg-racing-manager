import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';

void main() {
  group('Phase 2: Youth Academy Factory Tests (Hierarchical System)', () {
    late Country brasil;
    late Country argentina;

    setUp(() {
      brasil = Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷');
      argentina = Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷');
    });

    group('YoungDriver Model', () {
      test('creates young driver with all properties', () {
        final driver = YoungDriver(
          id: 'test-id-1',
          name: 'Carlos Silva',
          nationality: brasil,
          age: 17,
          baseSkill: 45,
          gender: 'M',
          potential: 85,
        );

        expect(driver.id, 'test-id-1');
        expect(driver.name, 'Carlos Silva');
        expect(driver.nationality.code, 'BR');
        expect(driver.age, 17);
        expect(driver.baseSkill, 45);
        expect(driver.gender, 'M');
        expect(driver.potential, 85);
      });

      test('serialization roundtrip works correctly', () {
        final driver = YoungDriver(
          id: 'test-id-2',
          name: 'Maria Santos',
          nationality: argentina,
          age: 18,
          baseSkill: 50,
          gender: 'F',
          potential: 90,
        );

        final map = driver.toMap();
        final restored = YoungDriver.fromMap(map);

        expect(restored.id, driver.id);
        expect(restored.name, driver.name);
        expect(restored.nationality.code, driver.nationality.code);
        expect(restored.age, driver.age);
        expect(restored.baseSkill, driver.baseSkill);
        expect(restored.gender, driver.gender);
        expect(restored.potential, driver.potential);
      });
    });

    group('YouthAcademyFactory', () {
      test('creates factory with country context', () {
        final factory = YouthAcademyFactory(brasil);
        expect(factory.country.code, 'BR');
        expect(factory.country.name, 'Brasil');
      });

      test('generates young driver with correct nationality', () {
        final factory = YouthAcademyFactory(brasil);
        final driver = factory.generatePromisingDriver();

        expect(driver.nationality.code, 'BR');
      });

      test('generates driver with age in expected range (16-19)', () {
        final factory = YouthAcademyFactory(argentina);

        for (int i = 0; i < 20; i++) {
          final driver = factory.generatePromisingDriver();
          expect(driver.age, greaterThanOrEqualTo(16));
          expect(driver.age, lessThanOrEqualTo(19));
        }
      });

      test('generates driver with baseSkill in expected range (35-55)', () {
        final factory = YouthAcademyFactory(brasil);

        for (int i = 0; i < 20; i++) {
          final driver = factory.generatePromisingDriver();
          expect(driver.baseSkill, greaterThanOrEqualTo(35));
          expect(driver.baseSkill, lessThanOrEqualTo(55));
        }
      });

      test('generates drivers with unique IDs', () {
        final factory = YouthAcademyFactory(brasil);
        final ids = <String>{};

        for (int i = 0; i < 50; i++) {
          final driver = factory.generatePromisingDriver();
          expect(ids.contains(driver.id), isFalse);
          ids.add(driver.id);
        }
      });
    });

    group('FtgLeague Academy Integration', () {
      test('FtgLeague initializes academy with CO as default', () {
        final league = FtgLeague(
          id: 'league-br',
          name: 'Liga Brasileña',
          tier: 1,
          teams: [],
          drivers: [],
          currentSeasonId: 'season-2026',
        );

        expect(league.academy, isNotNull);
        expect(league.academy.country.code, 'CO'); // Default in seeder/factory
      });

      test('academy generates drivers of its country', () {
        final leagueBR = FtgLeague(
          id: 'league-br',
          name: 'Liga Brasileña',
          tier: 1,
          teams: [],
          drivers: [],
          currentSeasonId: 'season-2026',
        );

        final youngDriver = leagueBR.academy.generatePromisingDriver();
        expect(youngDriver.nationality.code, 'CO');
      });
    });

    group('Integration with Universe', () {
      test('GameUniverse with multiple leagues and academies', () {
        final leagueBR = FtgLeague(
          id: 'league-br',
          name: 'World Championship',
          tier: 1,
          teams: [],
          drivers: [],
          currentSeasonId: 'season-2026',
        );

        final leagueAR = FtgLeague(
          id: 'league-ar',
          name: '2th Series',
          tier: 2,
          teams: [],
          drivers: [],
          currentSeasonId: 'season-2026',
        );

        final universe = GameUniverse(
          leagues: [leagueBR, leagueAR],
          createdAt: DateTime.now(),
        );

        expect(universe.leagues.length, 2);

        final brLeague = universe.getLeagueById('league-br');
        expect(brLeague?.academy.country.code, 'CO');
      });
    });
  });
}
