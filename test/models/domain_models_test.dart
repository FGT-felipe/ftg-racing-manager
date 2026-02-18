import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';

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

    test('CountryLeague serialization roundtrip', () {
      final country = Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷');
      final division = LeagueDivision(
        id: 'div1',
        countryLeagueId: 'league-ar',
        name: 'Primera',
        tier: 1,
        maxCapacity: 10,
        teamIds: ['team1'],
      );

      final league = CountryLeague(
        id: 'league-ar',
        country: country,
        name: 'Liga Argentina',
        divisions: [division],
        currentSeasonId: 'season1',
      );

      final map = league.toMap();
      final restored = CountryLeague.fromMap(map);

      expect(restored.id, league.id);
      expect(restored.country.code, league.country.code);
      expect(restored.name, league.name);
      expect(restored.divisions.length, 1);
      expect(restored.currentSeasonId, league.currentSeasonId);
    });

    test('CountryLeague lookup methods', () {
      final country = Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽');
      final div1 = LeagueDivision(
        id: 'div1',
        countryLeagueId: 'league-mx',
        name: 'Elite',
        tier: 1,
        maxCapacity: 8,
        teamIds: ['t1', 't2'],
      );
      final div2 = LeagueDivision(
        id: 'div2',
        countryLeagueId: 'league-mx',
        name: 'Segunda',
        tier: 2,
        maxCapacity: 8,
        teamIds: ['t3'],
      );

      final league = CountryLeague(
        id: 'league-mx',
        country: country,
        name: 'Liga Mexicana',
        divisions: [div1, div2],
        currentSeasonId: 'season1',
      );

      expect(league.getDivisionByTier(1)?.name, 'Elite');
      expect(league.getDivisionByTier(2)?.name, 'Segunda');
      expect(league.getDivisionByTier(3), isNull);
      expect(league.getDivisionById('div1')?.tier, 1);
      expect(league.totalTeams(), 3);
    });

    test('GameUniverse serialization roundtrip', () {
      final country = Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴');
      final division = LeagueDivision(
        id: 'div1',
        countryLeagueId: 'league-co',
        name: 'Primera',
        tier: 1,
        maxCapacity: 10,
      );
      final league = CountryLeague(
        id: 'league-co',
        country: country,
        name: 'Liga Colombiana',
        divisions: [division],
        currentSeasonId: 'season1',
      );

      final universe = GameUniverse(
        activeLeagues: {'CO': league},
        createdAt: DateTime(2026, 1, 1),
        gameVersion: '1.0.0',
      );

      final map = universe.toMap();
      final restored = GameUniverse.fromMap(map);

      expect(restored.activeLeagues.length, 1);
      expect(restored.activeLeagues['CO']?.country.code, 'CO');
      expect(restored.gameVersion, '1.0.0');
    });

    test('GameUniverse operations', () {
      final countryBR = Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷');
      final countryAR = Country(
        code: 'AR',
        name: 'Argentina',
        flagEmoji: '🇦🇷',
      );

      final leagueBR = CountryLeague(
        id: 'league-br',
        country: countryBR,
        name: 'Liga Brasileña',
        divisions: [],
        currentSeasonId: 'season1',
      );

      final leagueAR = CountryLeague(
        id: 'league-ar',
        country: countryAR,
        name: 'Liga Argentina',
        divisions: [],
        currentSeasonId: 'season1',
      );

      final universe = GameUniverse(
        activeLeagues: {'BR': leagueBR},
        createdAt: DateTime.now(),
      );

      expect(universe.totalActiveLeagues(), 1);
      expect(universe.getLeagueByCountry('BR')?.country.code, 'BR');

      final expandedUniverse = universe.addLeague(leagueAR);
      expect(expandedUniverse.totalActiveLeagues(), 2);
      expect(expandedUniverse.getAllLeagues().length, 2);

      final shrunkUniverse = expandedUniverse.removeLeague('BR');
      expect(shrunkUniverse.totalActiveLeagues(), 1);
      expect(shrunkUniverse.getLeagueByCountry('BR'), isNull);
    });
  });
}
