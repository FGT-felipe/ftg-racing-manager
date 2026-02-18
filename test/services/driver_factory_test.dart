import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/core_models.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/services/driver_factory.dart';

void main() {
  group('Phase 5: Driver Factory Tests', () {
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

    test('elite drivers have better age range (22-35)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.age, greaterThanOrEqualTo(22));
        expect(driver.age, lessThanOrEqualTo(35));
      }
    });

    test('professional drivers have wider age range (20-38)', () {
      final factory = DriverFactory(argentina);

      final ages = <int>[];
      for (int i = 0; i < 50; i++) {
        final driver = factory.generateDriver(divisionTier: 2);
        ages.add(driver.age);
        expect(driver.age, greaterThanOrEqualTo(20));
        expect(driver.age, lessThanOrEqualTo(38));
      }

      // Debe tener variedad en el rango
      expect(ages.toSet().length, greaterThan(10));
    });

    test('elite drivers have higher potential (70-95)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.potential, greaterThanOrEqualTo(70));
        expect(driver.potential, lessThanOrEqualTo(95));
      }
    });

    test('professional drivers have lower potential (50-80)', () {
      final factory = DriverFactory(mexico);

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 2);
        expect(driver.potential, greaterThanOrEqualTo(50));
        expect(driver.potential, lessThanOrEqualTo(80));
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

    test('elite drivers have higher stats (60-85)', () {
      final factory = DriverFactory(mexico);

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 1);

        expect(driver.stats['consistency'], greaterThanOrEqualTo(60));
        expect(driver.stats['consistency'], lessThanOrEqualTo(85));

        expect(driver.stats['overtaking'], greaterThanOrEqualTo(60));
        expect(driver.stats['overtaking'], lessThanOrEqualTo(85));

        expect(driver.stats['defending'], greaterThanOrEqualTo(60));
        expect(driver.stats['defending'], lessThanOrEqualTo(85));

        expect(driver.stats['racecraft'], greaterThanOrEqualTo(60));
        expect(driver.stats['racecraft'], lessThanOrEqualTo(85));

        expect(driver.stats['speed'], greaterThanOrEqualTo(60));
        expect(driver.stats['speed'], lessThanOrEqualTo(85));
      }
    });

    test('professional drivers have lower stats (40-65)', () {
      final factory = DriverFactory(brasil);

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 2);

        expect(driver.stats['consistency'], greaterThanOrEqualTo(40));
        expect(driver.stats['consistency'], lessThanOrEqualTo(65));

        expect(driver.stats['overtaking'], greaterThanOrEqualTo(40));
        expect(driver.stats['overtaking'], lessThanOrEqualTo(65));
      }
    });

    test('generates drivers with complete stats structure', () {
      final factory = DriverFactory(argentina);
      final driver = factory.generateDriver(divisionTier: 1);

      expect(driver.stats.containsKey('consistency'), isTrue);
      expect(driver.stats.containsKey('overtaking'), isTrue);
      expect(driver.stats.containsKey('defending'), isTrue);
      expect(driver.stats.containsKey('racecraft'), isTrue);
      expect(driver.stats.containsKey('speed'), isTrue);
      expect(driver.stats.length, 5);
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

    test('driver serialization roundtrip works correctly', () {
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
        expect(driver.stats['consistency'], greaterThan(0));
        expect(driver.stats['overtaking'], greaterThan(0));
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
        expect(eliteDriver.potential, greaterThanOrEqualTo(70));

        // Test Professional
        final proDriver = factory.generateDriver(divisionTier: 2);
        expect(proDriver, isNotNull);
        expect(proDriver.potential, greaterThanOrEqualTo(50));
        expect(proDriver.potential, lessThanOrEqualTo(80));
      }
    });

    test('tier validation produces expected stat ranges', () {
      final factory = DriverFactory(brasil);

      // Generar muchos drivers y verificar distribución
      final eliteDrivers = List.generate(
        100,
        (_) => factory.generateDriver(divisionTier: 1),
      );

      final avgSpeed =
          eliteDrivers.map((d) => d.stats['speed']!).reduce((a, b) => a + b) /
          100;

      // Promedio debe estar cerca del punto medio del rango (60-85 → ~72.5)
      expect(avgSpeed, greaterThan(68));
      expect(avgSpeed, lessThan(77));
    });
  });
}
