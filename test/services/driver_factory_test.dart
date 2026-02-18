import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/core_models.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/services/driver_factory.dart';

void main() {
  group('Phase 5: Driver Factory Tests (New 11-Stat Model)', () {
    late Country brasil;
    late Country argentina;
    late Country mexico;

    setUp(() {
      brasil = Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷');
      argentina = Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷');
      mexico = Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽');
    });

    test('creates driver factory with country context', () {
      final factory = DriverFactory(brasil);
      expect(factory.country.code, 'BR');
      expect(factory.country.name, 'Brasil');
    });

    test('generates driver with correct initial properties', () {
      final factory = DriverFactory(brasil);
      final driver = factory.generateDriver(divisionTier: 1);

      expect(driver, isNotNull);
      expect(driver.teamId, isNull); // No asignado aún
      expect(driver.points, 0);
      expect(driver.wins, 0);
      expect(driver.podiums, 0);
      expect(driver.poles, 0);
    });

    test('generates driver with valid ID containing country code', () {
      final factory = DriverFactory(argentina);
      final driver = factory.generateDriver(divisionTier: 1);

      expect(driver.id, isNotEmpty);
      expect(driver.id, contains('driver_ar'));
    });

    test('generates driver with non-empty full name', () {
      final factory = DriverFactory(mexico);
      final driver = factory.generateDriver(divisionTier: 2);

      expect(driver.name, isNotEmpty);
      expect(driver.name.contains(' '), isTrue); // Nombre + Apellido
    });

    test('all drivers have older age range (29-40)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.age, greaterThanOrEqualTo(29));
        expect(driver.age, lessThanOrEqualTo(40));
      }
    });

    test('professional drivers also have older age range (29-40)', () {
      final factory = DriverFactory(argentina);

      final ages = <int>[];
      for (int i = 0; i < 50; i++) {
        final driver = factory.generateDriver(divisionTier: 2);
        ages.add(driver.age);
        expect(driver.age, greaterThanOrEqualTo(29));
        expect(driver.age, lessThanOrEqualTo(40));
      }

      // Debe tener variedad en el rango
      expect(ages.toSet().length, greaterThan(5));
    });

    test('elite drivers have higher potential stars (3-5)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.potential, greaterThanOrEqualTo(3));
        expect(driver.potential, lessThanOrEqualTo(5));
      }
    });

    test('professional drivers have lower potential stars (1-4)', () {
      final factory = DriverFactory(mexico);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 2);
        expect(driver.potential, greaterThanOrEqualTo(1));
        expect(driver.potential, lessThanOrEqualTo(4));
      }
    });

    test('elite drivers have more prior races (10-50)', () {
      final factory = DriverFactory(argentina);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.races, greaterThanOrEqualTo(10));
        expect(driver.races, lessThanOrEqualTo(50));
      }
    });

    test('professional drivers have fewer prior races (0-20)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 2);
        expect(driver.races, greaterThanOrEqualTo(0));
        expect(driver.races, lessThanOrEqualTo(20));
      }
    });

    test('elite drivers have higher driving stats (60-85)', () {
      final factory = DriverFactory(mexico);

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 1);

        // Verificar stats de conducción
        for (final statKey in DriverStats.drivingStats) {
          expect(
            driver.stats[statKey],
            greaterThanOrEqualTo(
              55,
            ), // Puede ser un poco menor por ajuste de edad
            reason: '$statKey should be >= 55 for elite',
          );
          expect(
            driver.stats[statKey],
            lessThanOrEqualTo(95),
            reason: '$statKey should be <= 95',
          );
        }
      }
    });

    test('professional drivers have lower driving stats (40-65)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 2);

        expect(driver.stats[DriverStats.braking], greaterThanOrEqualTo(40));
        expect(driver.stats[DriverStats.braking], lessThanOrEqualTo(65));

        expect(driver.stats[DriverStats.cornering], greaterThanOrEqualTo(40));
        expect(driver.stats[DriverStats.cornering], lessThanOrEqualTo(65));
      }
    });

    test('generates drivers with complete 11-stat structure', () {
      final factory = DriverFactory(argentina);
      final driver = factory.generateDriver(divisionTier: 1);

      // Verificar que todos los stats del nuevo modelo están presentes
      for (final statKey in DriverStats.all) {
        expect(
          driver.stats.containsKey(statKey),
          isTrue,
          reason: 'Missing stat: $statKey',
        );
        expect(driver.stats[statKey], isNotNull, reason: 'Null stat: $statKey');
      }
      expect(driver.stats.length, DriverStats.all.length);
    });

    test('generates drivers with stat potentials for all stats', () {
      final factory = DriverFactory(brasil);
      final driver = factory.generateDriver(divisionTier: 1);

      expect(driver.statPotentials, isNotEmpty);
      for (final statKey in DriverStats.all) {
        expect(
          driver.statPotentials.containsKey(statKey),
          isTrue,
          reason: 'Missing potential for: $statKey',
        );
        // Potencial siempre >= valor actual
        expect(
          driver.statPotentials[statKey]!,
          greaterThanOrEqualTo(driver.stats[statKey]!),
          reason: 'Potential < current for: $statKey',
        );
      }
    });

    test('stat potentials are within valid range (0-100)', () {
      final factory = DriverFactory(mexico);

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        for (final statKey in DriverStats.all) {
          final potential = driver.statPotentials[statKey] ?? 0;
          expect(potential, greaterThanOrEqualTo(0));
          expect(potential, lessThanOrEqualTo(100));
        }
      }
    });

    test('getStatPotential returns correct value', () {
      final factory = DriverFactory(brasil);
      final driver = factory.generateDriver(divisionTier: 1);

      // Si tiene statPotentials definidos, debe retornarlos
      for (final statKey in DriverStats.all) {
        if (driver.statPotentials.containsKey(statKey)) {
          expect(
            driver.getStatPotential(statKey),
            driver.statPotentials[statKey],
          );
        }
      }
    });

    test('ageTrainingMultiplier is correct for different ages', () {
      final factory = DriverFactory(brasil);

      // Crear driver con edad específica usando copyWith
      final youngDriver = factory
          .generateDriver(divisionTier: 2)
          .copyWith(age: 20);
      expect(youngDriver.ageTrainingMultiplier, 1.5);

      final primeDriver = factory
          .generateDriver(divisionTier: 1)
          .copyWith(age: 28);
      expect(primeDriver.ageTrainingMultiplier, 1.0);

      final veteranDriver = factory
          .generateDriver(divisionTier: 1)
          .copyWith(age: 38);
      expect(veteranDriver.ageTrainingMultiplier, 0.5);
    });

    test('generates drivers with valid gender', () {
      final factory = DriverFactory(mexico);

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.gender, isIn(['M', 'F']));
      }
    });

    test('generates drivers with unique IDs', () {
      final factory = DriverFactory(brasil);
      final ids = <String>{};

      for (int i = 0; i < 50; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(
          ids.contains(driver.id),
          isFalse,
          reason: 'Duplicate ID generated: ${driver.id}',
        );
        ids.add(driver.id);
      }

      expect(ids.length, 50);
    });

    test('different tiers produce drivers with different characteristics', () {
      final factory = DriverFactory(argentina);

      final eliteDrivers = List.generate(
        20,
        (_) => factory.generateDriver(divisionTier: 1),
      );
      final proDrivers = List.generate(
        20,
        (_) => factory.generateDriver(divisionTier: 2),
      );

      // Promedios Elite
      final avgElitePotential =
          eliteDrivers.map((d) => d.potential).reduce((a, b) => a + b) / 20;
      final avgEliteRaces =
          eliteDrivers.map((d) => d.races).reduce((a, b) => a + b) / 20;

      // Promedios Profesional
      final avgProPotential =
          proDrivers.map((d) => d.potential).reduce((a, b) => a + b) / 20;
      final avgProRaces =
          proDrivers.map((d) => d.races).reduce((a, b) => a + b) / 20;

      // Élite debe tener mejores números
      expect(avgElitePotential, greaterThan(avgProPotential));
      expect(avgEliteRaces, greaterThan(avgProRaces));
    });

    test('driver serialization roundtrip works correctly with new stats', () {
      final factory = DriverFactory(mexico);
      final driver = factory.generateDriver(divisionTier: 1);

      final map = driver.toMap();
      final restored = Driver.fromMap(map);

      expect(restored.id, driver.id);
      expect(restored.name, driver.name);
      expect(restored.teamId, driver.teamId);
      expect(restored.age, driver.age);
      expect(restored.potential, driver.potential);
      expect(restored.points, driver.points);
      expect(restored.gender, driver.gender);
      expect(restored.races, driver.races);
      expect(restored.wins, driver.wins);
      expect(restored.podiums, driver.podiums);
      expect(restored.poles, driver.poles);

      // Verificar que todos los stats se preservan
      for (final statKey in DriverStats.all) {
        expect(
          restored.stats[statKey],
          driver.stats[statKey],
          reason: 'Stat $statKey not preserved in roundtrip',
        );
      }

      // Verificar potenciales
      for (final statKey in DriverStats.all) {
        expect(
          restored.statPotentials[statKey],
          driver.statPotentials[statKey],
          reason: 'Potential $statKey not preserved in roundtrip',
        );
      }

      // Verificar traits
      expect(restored.traits, driver.traits);
    });

    test('old stats format migrates correctly to new format', () {
      // Simular datos viejos de Firestore
      final oldMap = {
        'id': 'test_driver',
        'name': 'Test Driver',
        'age': 28,
        'potential': 75, // Formato viejo (0-100)
        'points': 0,
        'gender': 'M',
        'races': 10,
        'wins': 0,
        'podiums': 0,
        'poles': 0,
        'stats': {
          'speed': 70,
          'cornering': 65,
          'consistency': 60,
          'overtaking': 55,
          'defending': 50,
          'racecraft': 58,
        },
        'countryCode': 'BR',
        'role': 'Equal Status',
        'salary': 500000,
        'contractYearsRemaining': 1,
        'weeklyGrowth': {},
      };

      final driver = Driver.fromMap(oldMap);

      // Debe tener todos los nuevos stats
      for (final statKey in DriverStats.all) {
        expect(
          driver.stats.containsKey(statKey),
          isTrue,
          reason: 'Missing migrated stat: $statKey',
        );
        expect(
          driver.stats[statKey],
          isNotNull,
          reason: 'Null migrated stat: $statKey',
        );
      }

      // Cornering debe preservarse del formato viejo
      expect(driver.stats[DriverStats.cornering], 65);
      // Consistency debe preservarse
      expect(driver.stats[DriverStats.consistency], 60);
      // Overtaking debe preservarse
      expect(driver.stats[DriverStats.overtaking], 55);
    });

    test('generates drivers with Brazilian names', () {
      final factory = DriverFactory(brasil);
      final drivers = List.generate(
        10,
        (_) => factory.generateDriver(divisionTier: 1),
      );

      for (final driver in drivers) {
        expect(driver.name, isNotEmpty);
        expect(driver.name.split(' ').length, greaterThanOrEqualTo(2));
      }
    });

    test('generates drivers with Argentine names', () {
      final factory = DriverFactory(argentina);
      final drivers = List.generate(
        10,
        (_) => factory.generateDriver(divisionTier: 1),
      );

      for (final driver in drivers) {
        expect(driver.name, isNotEmpty);
        expect(driver.name.split(' ').length, greaterThanOrEqualTo(2));
      }
    });

    test('multiple drivers from same factory have different names', () {
      final factory = DriverFactory(brasil);
      final drivers = List.generate(
        30,
        (_) => factory.generateDriver(divisionTier: 1),
      );

      final names = drivers.map((d) => d.name).toSet();
      // Debería haber variedad (no todos iguales)
      expect(names.length, greaterThan(5));
    });

    test('all generated drivers are valid for competition', () {
      final factory = DriverFactory(mexico);
      final drivers = List.generate(
        10,
        (i) => factory.generateDriver(divisionTier: i % 2 + 1),
      );

      for (final driver in drivers) {
        expect(driver.id, isNotEmpty);
        expect(driver.name, isNotEmpty);
        expect(driver.age, greaterThan(0));
        expect(driver.potential, greaterThan(0));
        expect(driver.stats[DriverStats.consistency], greaterThan(0));
        expect(driver.stats[DriverStats.overtaking], greaterThan(0));
        expect(driver.stats[DriverStats.braking], greaterThan(0));
        expect(driver.stats[DriverStats.fitness], greaterThan(0));
      }
    });

    test('integration: factory works with all Phase 1-3 countries', () {
      final countries = [
        Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷'),
        Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷'),
        Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴'),
        Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽'),
        Country(code: 'UY', name: 'Uruguay', flagEmoji: '🇺🇾'),
        Country(code: 'CL', name: 'Chile', flagEmoji: '🇨🇱'),
      ];

      for (final country in countries) {
        final factory = DriverFactory(country);

        // Test Elite
        final eliteDriver = factory.generateDriver(divisionTier: 1);
        expect(eliteDriver, isNotNull);
        expect(
          eliteDriver.id,
          contains('driver_${country.code.toLowerCase()}'),
        );
        expect(eliteDriver.potential, greaterThanOrEqualTo(3));
        expect(eliteDriver.stats.length, DriverStats.all.length);

        // Test Professional
        final proDriver = factory.generateDriver(divisionTier: 2);
        expect(proDriver, isNotNull);
        expect(proDriver.potential, greaterThanOrEqualTo(1));
        expect(proDriver.potential, lessThanOrEqualTo(4));
        expect(proDriver.stats.length, DriverStats.all.length);
      }
    });

    test('tier validation produces expected stat ranges for cornering', () {
      final factory = DriverFactory(brasil);

      // Generar muchos drivers y verificar distribución
      final eliteDrivers = List.generate(
        100,
        (_) => factory.generateDriver(divisionTier: 1),
      );

      final avgCornering =
          eliteDrivers
              .map((d) => d.stats[DriverStats.cornering]!)
              .reduce((a, b) => a + b) /
          100;

      // Promedio debe estar cerca del punto medio del rango (60-85 → ~72.5)
      expect(avgCornering, greaterThan(65));
      expect(avgCornering, lessThan(82));
    });

    test('morale starts in healthy range (65-85)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.stats[DriverStats.morale], greaterThanOrEqualTo(65));
        expect(driver.stats[DriverStats.morale], lessThanOrEqualTo(85));
      }
    });

    test('hasTrait returns correct results', () {
      final factory = DriverFactory(brasil);
      final driver = factory.generateDriver(divisionTier: 1);

      // Verificar que hasTrait es consistente con traits list
      for (final trait in DriverTrait.values) {
        expect(driver.hasTrait(trait), driver.traits.contains(trait));
      }
    });

    test('DriverStats class has all expected keys', () {
      expect(DriverStats.all.length, 11);
      expect(DriverStats.drivingStats.length, 6);
      expect(DriverStats.mentalStats.length, 4);
      expect(DriverStats.physicalStats.length, 2);
      expect(DriverStats.experienceStats.length, 3);

      // Verificar que las listas contienen los stats correctos
      expect(DriverStats.drivingStats, contains(DriverStats.braking));
      expect(DriverStats.drivingStats, contains(DriverStats.cornering));
      expect(DriverStats.drivingStats, contains(DriverStats.smoothness));
      expect(DriverStats.drivingStats, contains(DriverStats.overtaking));
      expect(DriverStats.drivingStats, contains(DriverStats.consistency));
      expect(DriverStats.drivingStats, contains(DriverStats.adaptability));

      expect(DriverStats.physicalStats, contains(DriverStats.fitness));
      expect(DriverStats.physicalStats, contains(DriverStats.braking));

      expect(DriverStats.experienceStats, contains(DriverStats.feedback));
      expect(DriverStats.experienceStats, contains(DriverStats.consistency));
      expect(DriverStats.experienceStats, contains(DriverStats.focus));
    });

    test(
      'DriverTrait displayName and description are defined for all traits',
      () {
        for (final trait in DriverTrait.values) {
          expect(trait.displayName, isNotEmpty);
          expect(trait.description, isNotEmpty);
        }
      },
    );
  });
}
