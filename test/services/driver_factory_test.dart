import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/core_models.dart';
import 'package:ftg_racing_manager/services/driver_factory.dart';

void main() {
  group('Phase 5: Driver Factory Tests (New hierarchical system)', () {
    setUp(() {});

    test('generates driver with correct initial properties', () {
      final factory = DriverFactory();
      final driver = factory.generateDriver(divisionTier: 1);

      expect(driver, isNotNull);
      expect(driver.teamId, isNull); // No asignado aún
      expect(driver.points, 0);
      expect(driver.wins, 0);
      expect(driver.podiums, 0);
      expect(driver.poles, 0);
    });

    test('generates driver with non-empty full name', () {
      final factory = DriverFactory();
      final driver = factory.generateDriver(divisionTier: 2);

      expect(driver.name, isNotEmpty);
      expect(driver.name.contains(' '), isTrue); // Nombre + Apellido
    });

    test('all drivers have older age range (29-40)', () {
      final factory = DriverFactory();

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.age, greaterThanOrEqualTo(29));
        expect(driver.age, lessThanOrEqualTo(40));
      }
    });

    test('elite drivers have higher potential stars (3-5)', () {
      final factory = DriverFactory();

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.potential, greaterThanOrEqualTo(3));
        expect(driver.potential, lessThanOrEqualTo(5));
      }
    });

    test('professional drivers have lower potential stars (1-4)', () {
      final factory = DriverFactory();

      for (int i = 0; i < 30; i++) {
        final driver = factory.generateDriver(divisionTier: 2);
        expect(driver.potential, greaterThanOrEqualTo(1));
        expect(driver.potential, lessThanOrEqualTo(4));
      }
    });

    test('generates drivers with complete 11-stat structure', () {
      final factory = DriverFactory();
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

    test('generates drivers with valid gender', () {
      final factory = DriverFactory();

      for (int i = 0; i < 20; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        expect(driver.gender, isIn(['M', 'F']));
      }
    });

    test('generates 1 male and 1 female when forced', () {
      final factory = DriverFactory();

      final male = factory.generateDriver(divisionTier: 1, forcedGender: 'M');
      expect(male.gender, 'M');

      final female = factory.generateDriver(divisionTier: 1, forcedGender: 'F');
      expect(female.gender, 'F');
    });

    test('nationality distribution: 40% Colombian approx', () {
      final factory = DriverFactory();
      int colombian = 0;
      const total = 200;

      for (int i = 0; i < total; i++) {
        final driver = factory.generateDriver(divisionTier: 1);
        if (driver.countryCode == 'CO') colombian++;
      }

      // 40% of 200 = 80. Allow some margin.
      expect(colombian, greaterThan(60));
      expect(colombian, lessThan(100));
    });

    test('driver serialization roundtrip works correctly', () {
      final factory = DriverFactory();
      final driver = factory.generateDriver(divisionTier: 1);

      final map = driver.toMap();
      final restored = Driver.fromMap(map);

      expect(restored.id, driver.id);
      expect(restored.name, driver.name);
      expect(restored.age, driver.age);
      expect(restored.potential, driver.potential);
      expect(restored.gender, driver.gender);
    });
  });
}
