import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';

void main() {
  group('Phase 2: Youth Academy Factory Tests', () {
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

      test('toString provides readable output', () {
        final driver = YoungDriver(
          id: 'test-id-3',
          name: 'Diego López',
          nationality: brasil,
          age: 16,
          baseSkill: 40,
          gender: 'M',
          potential: 75,
        );

        final str = driver.toString();
        expect(str, contains('Diego López'));
        expect(str, contains('BR'));
        expect(str, contains('16'));
        expect(str, contains('40'));
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
        expect(driver.nationality.name, 'Brasil');
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

      test('generates driver with potential in expected range (70-95)', () {
        final factory = YouthAcademyFactory(argentina);

        for (int i = 0; i < 20; i++) {
          final driver = factory.generatePromisingDriver();
          expect(driver.potential, greaterThanOrEqualTo(70));
          expect(driver.potential, lessThanOrEqualTo(95));
        }
      });

      test('generates drivers with valid gender (M or F)', () {
        final factory = YouthAcademyFactory(brasil);

        for (int i = 0; i < 20; i++) {
          final driver = factory.generatePromisingDriver();
          expect(driver.gender, isIn(['M', 'F']));
        }
      });

      test('generates drivers with unique IDs', () {
        final factory = YouthAcademyFactory(brasil);
        final ids = <String>{};

        for (int i = 0; i < 100; i++) {
          final driver = factory.generatePromisingDriver();
          expect(
            ids.contains(driver.id),
            isFalse,
            reason: 'Duplicate ID generated: ${driver.id}',
          );
          ids.add(driver.id);
        }
      });

      test('generates drivers with valid names', () {
        final factory = YouthAcademyFactory(argentina);

        for (int i = 0; i < 10; i++) {
          final driver = factory.generatePromisingDriver();
          expect(driver.name.isNotEmpty, isTrue);
          expect(
            driver.name.contains(' '),
            isTrue,
            reason: 'Name should have first and last name',
          );
        }
      });

      test(
        'different factories produce drivers of different nationalities',
        () {
          final factoryBR = YouthAcademyFactory(brasil);
          final factoryAR = YouthAcademyFactory(argentina);

          final driverBR = factoryBR.generatePromisingDriver();
          final driverAR = factoryAR.generatePromisingDriver();

          expect(driverBR.nationality.code, 'BR');
          expect(driverAR.nationality.code, 'AR');
          expect(
            driverBR.nationality.code,
            isNot(equals(driverAR.nationality.code)),
          );
        },
      );
    });

    group('CountryLeague Academy Integration', () {
      test('CountryLeague initializes academy automatically', () {
        final league = CountryLeague(
          id: 'league-br',
          country: brasil,
          name: 'Liga Brasileña',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        expect(league.academy, isNotNull);
        expect(league.academy.country.code, 'BR');
      });

      test('academy generates drivers of league\'s country', () {
        final leagueBR = CountryLeague(
          id: 'league-br',
          country: brasil,
          name: 'Liga Brasileña',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        final youngDriver = leagueBR.academy.generatePromisingDriver();
        expect(youngDriver.nationality.code, 'BR');
      });

      test('different leagues have independent academies', () {
        final leagueBR = CountryLeague(
          id: 'league-br',
          country: brasil,
          name: 'Liga Brasileña',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        final leagueAR = CountryLeague(
          id: 'league-ar',
          country: argentina,
          name: 'Liga Argentina',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        final driverBR = leagueBR.academy.generatePromisingDriver();
        final driverAR = leagueAR.academy.generatePromisingDriver();

        expect(driverBR.nationality.code, 'BR');
        expect(driverAR.nationality.code, 'AR');
      });

      test('league can generate multiple young drivers', () {
        final league = CountryLeague(
          id: 'league-br',
          country: brasil,
          name: 'Liga Brasileña',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        final drivers = List.generate(
          5,
          (_) => league.academy.generatePromisingDriver(),
        );

        expect(drivers.length, 5);
        for (final driver in drivers) {
          expect(driver.nationality.code, 'BR');
        }

        // All should have unique IDs
        final ids = drivers.map((d) => d.id).toSet();
        expect(ids.length, 5);
      });

      test('copyWith maintains academy functionality', () {
        final originalLeague = CountryLeague(
          id: 'league-br',
          country: brasil,
          name: 'Liga Brasileña',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        final copiedLeague = originalLeague.copyWith(
          name: 'Liga Brasileña Pro',
        );

        expect(copiedLeague.academy, isNotNull);
        expect(copiedLeague.academy.country.code, 'BR');

        final driver = copiedLeague.academy.generatePromisingDriver();
        expect(driver.nationality.code, 'BR');
      });
    });

    group('Integration with Phase 1 Models', () {
      test('GameUniverse with multiple leagues and academies', () {
        final leagueBR = CountryLeague(
          id: 'league-br',
          country: brasil,
          name: 'Liga Brasileña',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        final leagueAR = CountryLeague(
          id: 'league-ar',
          country: argentina,
          name: 'Liga Argentina',
          divisions: [],
          currentSeasonId: 'season-2026',
        );

        final universe = GameUniverse(
          activeLeagues: {'BR': leagueBR, 'AR': leagueAR},
          createdAt: DateTime.now(),
        );

        // Get leagues from universe and generate drivers
        final brLeague = universe.getLeagueByCountry('BR');
        final arLeague = universe.getLeagueByCountry('AR');

        final driverBR = brLeague!.academy.generatePromisingDriver();
        final driverAR = arLeague!.academy.generatePromisingDriver();

        expect(driverBR.nationality.code, 'BR');
        expect(driverAR.nationality.code, 'AR');
      });
    });
  });
}
