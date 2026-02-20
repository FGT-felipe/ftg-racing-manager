import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/models/core_models.dart';

void main() {
  group('Domain Models Serialization Tests', () {
    test('Country serialization roundtrip', () {
      final country = Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷');

      final map = country.toMap();
      final restored = Country.fromMap(map);

      expect(restored.code, country.code);
      expect(restored.name, country.name);
      expect(restored.flagEmoji, country.flagEmoji);
    });

    test('LeagueDivision serialization roundtrip', () {
      final division = LeagueDivision(
        id: 'div1',
        countryLeagueId: 'league-br',
        name: 'Série Ouro',
        tier: 1,
        maxCapacity: 10,
        teamIds: ['team1', 'team2', 'team3'],
      );

      final map = division.toMap();
      final restored = LeagueDivision.fromMap(map);

      expect(restored.id, division.id);
      expect(restored.countryLeagueId, division.countryLeagueId);
      expect(restored.name, division.name);
      expect(restored.tier, division.tier);
      expect(restored.maxCapacity, division.maxCapacity);
      expect(restored.teamIds, division.teamIds);
    });

    test('LeagueDivision capacity checks', () {
      final division = LeagueDivision(
        id: 'div1',
        countryLeagueId: 'league-br',
        name: 'Test Division',
        tier: 1,
        maxCapacity: 5,
        teamIds: ['team1', 'team2', 'team3'],
      );

      expect(division.isFull(), false);
      expect(division.hasSpace(), true);
      expect(division.availableSlots(), 2);

      final fullDivision = division.copyWith(
        teamIds: ['t1', 't2', 't3', 't4', 't5'],
      );

      expect(fullDivision.isFull(), true);
      expect(fullDivision.hasSpace(), false);
      expect(fullDivision.availableSlots(), 0);
    });

    test('FtgLeague serialization roundtrip', () {
      final league = FtgLeague(
        id: 'league-ar',
        name: 'Liga Argentina',
        tier: 1,
        teams: [],
        drivers: [],
        currentSeasonId: 'season1',
      );

      final map = league.toMap();
      final restored = FtgLeague.fromMap(map);

      expect(restored.id, league.id);
      expect(restored.name, league.name);
      expect(restored.tier, league.tier);
      expect(restored.currentSeasonId, league.currentSeasonId);
    });

    test('FtgLeague basic operations', () {
      final league = FtgLeague(
        id: 'league-mx',
        name: 'Liga Mexicana',
        tier: 1,
        teams: [
          Team(
            id: 't1',
            name: 'T1',
            isBot: true,
            budget: 0,
            points: 0,
            carStats: {},
            weekStatus: {},
          ),
          Team(
            id: 't2',
            name: 'T2',
            isBot: true,
            budget: 0,
            points: 0,
            carStats: {},
            weekStatus: {},
          ),
        ],
        drivers: [],
        currentSeasonId: 'season1',
      );

      expect(league.teams.length, 2);
      expect(league.tier, 1);
    });

    test('GameUniverse serialization roundtrip', () {
      final league = FtgLeague(
        id: 'league-co',
        name: 'Liga Colombiana',
        tier: 1,
        teams: [],
        drivers: [],
        currentSeasonId: 'season1',
      );

      final universe = GameUniverse(
        leagues: [league],
        createdAt: DateTime(2026, 1, 1),
        gameVersion: '1.0.0',
      );

      final map = universe.toMap();
      final restored = GameUniverse.fromMap(map);

      expect(restored.leagues.length, 1);
      expect(restored.leagues.first.name, 'Liga Colombiana');
      expect(restored.gameVersion, '1.0.0');
    });

    test('GameUniverse operations', () {
      final leagueBR = FtgLeague(
        id: 'league-br',
        name: 'Liga Brasileña',
        tier: 1,
        teams: [],
        drivers: [],
        currentSeasonId: 'season1',
      );

      final leagueAR = FtgLeague(
        id: 'league-ar',
        name: 'Liga Argentina',
        tier: 2,
        teams: [],
        drivers: [],
        currentSeasonId: 'season1',
      );

      final universe = GameUniverse(
        leagues: [leagueBR],
        createdAt: DateTime.now(),
      );

      expect(universe.leagues.length, 1);
      expect(universe.getLeagueById('league-br')?.id, 'league-br');

      final expandedUniverse = universe.copyWith(
        leagues: [...universe.leagues, leagueAR],
      );
      expect(expandedUniverse.leagues.length, 2);

      final firstLeague = expandedUniverse.leagues.first;
      expect(firstLeague.id, 'league-br');
    });
  });
}
