import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/core_models.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/services/team_factory.dart';

void main() {
  group('Phase 4: Team Factory Tests', () {
    late Country brasil;
    late Country argentina;
    late Country mexico;

    setUp(() {
      brasil = Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷');
      argentina = Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷');
      mexico = Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽');
    });

    test('creates team factory with country context', () {
      final factory = TeamFactory(brasil);
      expect(factory.country.code, 'BR');
      expect(factory.country.name, 'Brasil');
    });

    test('generates bot team with correct properties', () {
      final factory = TeamFactory(brasil);
      final team = factory.generateBotTeam();

      expect(team, isNotNull);
      expect(team.isBot, isTrue);
      expect(team.managerId, isNull);
      expect(team.points, 0);
      expect(team.races, 0);
      expect(team.wins, 0);
      expect(team.podiums, 0);
      expect(team.poles, 0);
    });

    test('generates team with valid ID containing country code', () {
      final factory = TeamFactory(argentina);
      final team = factory.generateBotTeam();

      expect(team.id, isNotEmpty);
      expect(team.id, contains('team_ar'));
    });

    test('generates team with non-empty name', () {
      final factory = TeamFactory(mexico);
      final team = factory.generateBotTeam();

      expect(team.name, isNotEmpty);
      expect(team.name.length, greaterThan(5));
    });

    test('generates budget in expected range (5M - 15M)', () {
      final factory = TeamFactory(brasil);

      for (int i = 0; i < 20; i++) {
        final team = factory.generateBotTeam();
        expect(team.budget, greaterThanOrEqualTo(5000000));
        expect(team.budget, lessThanOrEqualTo(15000000));
      }
    });

    test('generates car stats in expected range (1-20)', () {
      final factory = TeamFactory(argentina);

      for (int i = 0; i < 20; i++) {
        final team = factory.generateBotTeam();

        expect(team.carStats['0']!['aero'], greaterThanOrEqualTo(1));
        expect(team.carStats['0']!['aero'], lessThanOrEqualTo(20));

        expect(team.carStats['0']!['engine'], greaterThanOrEqualTo(1));
        expect(team.carStats['0']!['engine'], lessThanOrEqualTo(20));

        expect(team.carStats['0']!['reliability'], greaterThanOrEqualTo(1));
        expect(team.carStats['0']!['reliability'], lessThanOrEqualTo(20));
      }
    });

    test('generates teams with valid car stats structure', () {
      final factory = TeamFactory(brasil);
      final team = factory.generateBotTeam();

      expect(team.carStats['0']!.containsKey('aero'), isTrue);
      expect(team.carStats['0']!.containsKey('engine'), isTrue);
      expect(team.carStats['0']!.containsKey('reliability'), isTrue);
      expect(team.carStats.length, 2); // 2 cars
    });

    test('generates teams with valid week status', () {
      final factory = TeamFactory(mexico);
      final team = factory.generateBotTeam();

      expect(team.weekStatus, isNotNull);
      expect(team.weekStatus, isA<Map<String, dynamic>>());
      expect(team.weekStatus.containsKey('practiceCompleted'), isTrue);
      expect(team.weekStatus.containsKey('strategySet'), isTrue);
      expect(team.weekStatus.containsKey('sponsorReviewed'), isTrue);
    });

    test('generates teams with empty sponsors initially', () {
      final factory = TeamFactory(brasil);
      final team = factory.generateBotTeam();

      expect(team.sponsors, isEmpty);
    });

    test('generates teams with unique IDs', () {
      final factory = TeamFactory(argentina);
      final ids = <String>{};

      for (int i = 0; i < 50; i++) {
        final team = factory.generateBotTeam();
        expect(
          ids.contains(team.id),
          isFalse,
          reason: 'Duplicate ID generated: ${team.id}',
        );
        ids.add(team.id);
      }

      expect(ids.length, 50);
    });

    test('different factories produce teams for different countries', () {
      final factoryBR = TeamFactory(brasil);
      final factoryAR = TeamFactory(argentina);

      final teamBR = factoryBR.generateBotTeam();
      final teamAR = factoryAR.generateBotTeam();

      expect(teamBR.id, contains('team_br'));
      expect(teamAR.id, contains('team_ar'));
      expect(teamBR.id, isNot(contains('team_ar')));
      expect(teamAR.id, isNot(contains('team_br')));
    });

    test('team serialization roundtrip works correctly', () {
      final factory = TeamFactory(brasil);
      final team = factory.generateBotTeam();

      final map = team.toMap();
      final restored = Team.fromMap(map);

      expect(restored.id, team.id);
      expect(restored.name, team.name);
      expect(restored.managerId, team.managerId);
      expect(restored.isBot, team.isBot);
      expect(restored.budget, team.budget);
      expect(restored.points, team.points);
      expect(restored.races, team.races);
      expect(restored.wins, team.wins);
      expect(restored.podiums, team.podiums);
      expect(restored.poles, team.poles);
      expect(restored.carStats['0']!['aero'], team.carStats['0']!['aero']);
      expect(restored.carStats['0']!['engine'], team.carStats['0']!['engine']);
      expect(
        restored.carStats['0']!['reliability'],
        team.carStats['0']!['reliability'],
      );
    });

    test('generates teams with thematic names for Brasil', () {
      final factory = TeamFactory(brasil);
      final teams = List.generate(10, (_) => factory.generateBotTeam());

      for (final team in teams) {
        expect(team.name, isNotEmpty);
        // Nombres deben tener al menos 2 palabras (prefix + suffix)
        expect(team.name.contains(' '), isTrue);
      }
    });

    test('generates teams with thematic names for Argentina', () {
      final factory = TeamFactory(argentina);
      final teams = List.generate(10, (_) => factory.generateBotTeam());

      for (final team in teams) {
        expect(team.name, isNotEmpty);
        expect(team.name.contains(' '), isTrue);
      }
    });

    test('generates teams with thematic names for México', () {
      final factory = TeamFactory(mexico);
      final teams = List.generate(10, (_) => factory.generateBotTeam());

      for (final team in teams) {
        expect(team.name, isNotEmpty);
        expect(team.name.contains(' '), isTrue);
      }
    });

    test('multiple teams from same factory have different names', () {
      final factory = TeamFactory(brasil);
      final teams = List.generate(20, (_) => factory.generateBotTeam());

      final names = teams.map((t) => t.name).toSet();
      // Debería haber al menos alguna variedad en los nombres
      expect(names.length, greaterThan(1));
    });

    test('team factory maintains statistical consistency', () {
      final factory = TeamFactory(argentina);
      final teams = List.generate(100, (_) => factory.generateBotTeam());

      // Calcular promedios
      final avgBudget =
          teams.map((t) => t.budget).reduce((a, b) => a + b) / 100;
      final avgAero =
          teams.map((t) => t.carStats['0']!['aero']!).reduce((a, b) => a + b) /
          100;

      // Budget debe estar cerca del punto medio (10M)
      expect(avgBudget, greaterThan(8000000));
      expect(avgBudget, lessThan(12000000));

      // Aero debe estar cerca del punto medio (10.5)
      expect(avgAero, greaterThan(8.0));
      expect(avgAero, lessThan(13.0));
    });

    test('all generated teams are valid for competition', () {
      final factory = TeamFactory(mexico);
      final teams = List.generate(10, (_) => factory.generateBotTeam());

      for (final team in teams) {
        // Validar que todos los campos requeridos existen
        expect(team.id, isNotEmpty);
        expect(team.name, isNotEmpty);
        expect(team.isBot, isTrue);
        expect(team.budget, greaterThan(0));
        expect(team.carStats['0']!['aero'], greaterThan(0));
        expect(team.carStats['0']!['engine'], greaterThan(0));
        expect(team.carStats['0']!['reliability'], greaterThan(0));
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
        final factory = TeamFactory(country);
        final team = factory.generateBotTeam();

        expect(team, isNotNull);
        expect(team.id, contains('team_${country.code.toLowerCase()}'));
        expect(team.isBot, isTrue);
        expect(team.budget, greaterThanOrEqualTo(5000000));
        expect(team.budget, lessThanOrEqualTo(15000000));
      }
    });
  });
}
