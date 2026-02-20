import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/core_models.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/services/team_factory.dart';

void main() {
  group('Phase 4: Team Factory Tests (Refactored)', () {
    late Country brasil;
    late Country argentina;
    late Country mexico;

    setUp(() {
      brasil = Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷');
      argentina = Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷');
      mexico = Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽');
    });

    test('generates bot team with correct properties', () {
      final factory = TeamFactory();
      final team = factory.generateBotTeam(forcedCountry: brasil);

      expect(team, isNotNull);
      expect(team.isBot, isTrue);
      expect(team.managerId, isNull);
      expect(team.points, 0);
    });

    test('generates team with valid ID containing country code', () {
      final factory = TeamFactory();
      final team = factory.generateBotTeam(forcedCountry: argentina);

      expect(team.id, isNotEmpty);
      expect(team.id.toLowerCase(), contains('team_ar'));
    });

    test('generates team with non-empty name', () {
      final factory = TeamFactory();
      final team = factory.generateBotTeam(forcedCountry: mexico);

      expect(team.name, isNotEmpty);
      expect(team.name.length, greaterThan(3));
    });

    test('generates fixed budget (5M)', () {
      final factory = TeamFactory();
      final team = factory.generateBotTeam(forcedCountry: brasil);
      expect(team.budget, 5000000);
    });

    test('generates car stats structure correctly', () {
      final factory = TeamFactory();
      final team = factory.generateBotTeam(forcedCountry: argentina);

      expect(team.carStats['0']!.containsKey('aero'), isTrue);
      expect(team.carStats['0']!.containsKey('powertrain'), isTrue);
      expect(team.carStats.length, 2); // 2 cars
    });

    test('generates teams with unique IDs', () {
      final factory = TeamFactory();
      final ids = <String>{};

      for (int i = 0; i < 50; i++) {
        final team = factory.generateBotTeam();
        expect(ids.contains(team.id), isFalse);
        ids.add(team.id);
      }

      expect(ids.length, 50);
    });

    test('team serialization roundtrip works correctly', () {
      final factory = TeamFactory();
      final team = factory.generateBotTeam(forcedCountry: brasil);

      final map = team.toMap();
      final restored = Team.fromMap(map);

      expect(restored.id, team.id);
      expect(restored.name, team.name);
    });
  });
}
