import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';

void main() {
  group('Phase 2: Youth Academy Factory Tests (Updated API)', () {
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
          baseSkill: 9,
          gender: 'M',
          growthPotential: 8,
        );

        expect(driver.id, 'test-id-1');
        expect(driver.name, 'Carlos Silva');
        expect(driver.nationality.code, 'BR');
        expect(driver.age, 17);
        expect(driver.baseSkill, 9);
        expect(driver.gender, 'M');
        expect(driver.growthPotential, 8);
        expect(driver.status, 'candidate');
        expect(driver.salary, 100000);
        expect(driver.contractYears, 1);
      });

      test('serialization roundtrip works correctly', () {
        final driver = YoungDriver(
          id: 'test-id-2',
          name: 'Maria Santos',
          nationality: argentina,
          age: 18,
          baseSkill: 11,
          gender: 'F',
          growthPotential: 10,
          status: 'selected',
          selectedAt: DateTime(2026, 1, 15),
          statRangeMin: {'braking': 8, 'cornering': 9},
          statRangeMax: {'braking': 18, 'cornering': 21},
        );

        final map = driver.toMap();
        final restored = YoungDriver.fromMap(map);

        expect(restored.id, driver.id);
        expect(restored.name, driver.name);
        expect(restored.nationality.code, driver.nationality.code);
        expect(restored.age, driver.age);
        expect(restored.baseSkill, driver.baseSkill);
        expect(restored.gender, driver.gender);
        expect(restored.growthPotential, driver.growthPotential);
        expect(restored.status, 'selected');
        expect(restored.statRangeMin['braking'], 8);
        expect(restored.statRangeMax['cornering'], 21);
      });

      test('potentialStars calculated correctly', () {
        // growthPotential 5 → ceil(5/2.4) = 3 stars
        expect(
          YoungDriver(
            id: 'a',
            name: 'A',
            nationality: brasil,
            age: 16,
            baseSkill: 7,
            gender: 'M',
            growthPotential: 5,
          ).potentialStars,
          3,
        );
        // growthPotential 12 → ceil(12/2.4) = 5 stars
        expect(
          YoungDriver(
            id: 'b',
            name: 'B',
            nationality: brasil,
            age: 16,
            baseSkill: 15,
            gender: 'F',
            growthPotential: 12,
          ).potentialStars,
          5,
        );
      });

      test('isExpired works correctly', () {
        final expired = YoungDriver(
          id: 'e1',
          name: 'Expired',
          nationality: brasil,
          age: 17,
          baseSkill: 7,
          gender: 'M',
          growthPotential: 5,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expired.isExpired, isTrue);

        final notExpired = YoungDriver(
          id: 'e2',
          name: 'Fresh',
          nationality: brasil,
          age: 17,
          baseSkill: 7,
          gender: 'M',
          growthPotential: 5,
          expiresAt: DateTime.now().add(const Duration(days: 3)),
        );
        expect(notExpired.isExpired, isFalse);
      });
    });

    group('YouthAcademyFactory', () {
      test('creates factory without country context', () {
        final factory = YouthAcademyFactory();
        expect(factory, isNotNull);
      });

      test('generates driver with correct nationality from parameter', () {
        final factory = YouthAcademyFactory();
        final driver = factory.generatePromisingDriver(
          academyLevel: 1,
          country: brasil,
        );
        expect(driver.nationality.code, 'BR');
      });

      test('generates driver with age in expected range (16-19)', () {
        final factory = YouthAcademyFactory();
        for (int i = 0; i < 20; i++) {
          final driver = factory.generatePromisingDriver(
            academyLevel: 1,
            country: argentina,
          );
          expect(driver.age, greaterThanOrEqualTo(16));
          expect(driver.age, lessThanOrEqualTo(19));
        }
      });

      test('generates driver with baseSkill scaled by academy level', () {
        final factory = YouthAcademyFactory();

        // Level 1: baseSkill = 7
        final level1 = factory.generatePromisingDriver(
          academyLevel: 1,
          country: brasil,
        );
        expect(level1.baseSkill, 7);

        // Level 5: baseSkill = 15
        final level5 = factory.generatePromisingDriver(
          academyLevel: 5,
          country: brasil,
        );
        expect(level5.baseSkill, 15);
      });

      test('generates candidate pair with 1M + 1F', () {
        final factory = YouthAcademyFactory();
        final pair = factory.generateCandidatePair(
          academyLevel: 3,
          country: brasil,
        );

        expect(pair.length, 2);
        expect(pair[0].gender, 'M');
        expect(pair[1].gender, 'F');
      });

      test('generates drivers with unique IDs', () {
        final factory = YouthAcademyFactory();
        final ids = <String>{};

        for (int i = 0; i < 50; i++) {
          final driver = factory.generatePromisingDriver(
            academyLevel: 1,
            country: brasil,
          );
          expect(ids.contains(driver.id), isFalse);
          ids.add(driver.id);
        }
      });

      test('all generated drivers have status candidate', () {
        final factory = YouthAcademyFactory();
        final driver = factory.generatePromisingDriver(
          academyLevel: 2,
          country: argentina,
        );
        expect(driver.status, 'candidate');
        expect(driver.salary, 100000);
        expect(driver.contractYears, 1);
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
        expect(league.academyCountry.code, 'CO');
      });

      test('academy generates drivers of specified country', () {
        final leagueBR = FtgLeague(
          id: 'league-br',
          name: 'Liga Brasileña',
          tier: 1,
          teams: [],
          drivers: [],
          currentSeasonId: 'season-2026',
        );

        final youngDriver = leagueBR.academy.generatePromisingDriver(
          academyLevel: 1,
          country: leagueBR.academyCountry,
        );
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
        expect(brLeague?.academyCountry.code, 'CO');
      });
    });
  });
}
