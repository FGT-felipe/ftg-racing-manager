import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/domain/domain_models.dart';
import 'package:ftg_racing_manager/models/core_models.dart';

/// Helper that replicates the logic of UniverseService.updateTeamInUniverse
/// without requiring Firestore, so we can test the pure domain logic.
GameUniverse applyTeamNameUpdate(
  GameUniverse universe,
  String teamId, {
  String? newName,
  int? newBudget,
  int? nameChangeCount,
}) {
  bool found = false;
  final updatedLeagues = universe.leagues.map((league) {
    final teamIndex = league.teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      found = true;
      final updatedTeams = List<Team>.from(league.teams);
      updatedTeams[teamIndex] = updatedTeams[teamIndex].copyWith(
        name: newName,
        budget: newBudget,
        nameChangeCount: nameChangeCount,
      );
      return league.copyWith(teams: updatedTeams);
    }
    return league;
  }).toList();

  if (!found) {
    throw StateError('Team $teamId not found in any league.');
  }

  return universe.copyWith(leagues: updatedLeagues);
}

/// Helper: creates a minimal Team for testing.
Team _makeTeam(String id, String name, {int seasonPoints = 0}) {
  return Team(
    id: id,
    name: name,
    isBot: true,
    budget: 5000000,
    points: 0,
    seasonPoints: seasonPoints,
    carStats: {},
    weekStatus: {},
  );
}

/// Helper: creates a minimal Driver for testing.
Driver _makeDriver(
  String id,
  String name,
  String teamId, {
  int seasonPoints = 0,
}) {
  return Driver(
    id: id,
    name: name,
    teamId: teamId,
    age: 25,
    potential: 3,
    points: 0,
    gender: 'M',
    stats: {'braking': 60, 'cornering': 60},
    seasonPoints: seasonPoints,
  );
}

/// Helper: builds a team name map the same way _DriversStandingsTab does.
Map<String, String> buildTeamMap(List<Team> teams) {
  return {for (var t in teams) t.id: t.name};
}

/// Helper: builds a merged team map with live overrides,
/// matching the fix in _DriversStandingsTabState.
Map<String, String> buildTeamMapWithLiveOverrides(
  List<Team> universeTeams,
  Map<String, String> liveTeamNames,
) {
  return {for (var t in universeTeams) t.id: liveTeamNames[t.id] ?? t.name};
}

void main() {
  // ─────────────────────────────────────────────────
  // 1. TEAM.COPYWITH NAME UPDATE
  // ─────────────────────────────────────────────────
  group('Team.copyWith — Name Update', () {
    test('updates name while retaining all other fields', () {
      final team = _makeTeam('t1', 'Old Name');

      final updated = team.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(updated.id, 't1');
      expect(updated.isBot, true);
      expect(updated.budget, 5000000);
    });

    test('updates name and nameChangeCount together', () {
      final team = _makeTeam('t1', 'Original');

      final updated = team.copyWith(name: 'Renamed', nameChangeCount: 1);

      expect(updated.name, 'Renamed');
      expect(updated.nameChangeCount, 1);
    });

    test('updates name and budget together (rename cost)', () {
      final team = _makeTeam('t1', 'OldTeam');

      final updated = team.copyWith(
        name: 'NewTeam',
        budget: 5000000 - 500000,
        nameChangeCount: 2,
      );

      expect(updated.name, 'NewTeam');
      expect(updated.budget, 4500000);
      expect(updated.nameChangeCount, 2);
    });

    test('serializes and deserializes with updated name', () {
      final team = _makeTeam('t1', 'Original').copyWith(name: 'Updated');

      final map = team.toMap();
      final restored = Team.fromMap(map);

      expect(restored.name, 'Updated');
      expect(restored.id, 't1');
    });
  });

  // ─────────────────────────────────────────────────
  // 2. UNIVERSE TEAM UPDATE LOGIC (applyTeamNameUpdate)
  // ─────────────────────────────────────────────────
  group('applyTeamNameUpdate — Universe sync logic', () {
    late GameUniverse universe;

    setUp(() {
      final league1 = FtgLeague(
        id: 'ftg_world',
        name: 'FTG World Championship',
        tier: 1,
        teams: [
          _makeTeam('team_a', 'Team Alpha'),
          _makeTeam('team_b', 'Team Bravo'),
        ],
        drivers: [
          _makeDriver('d1', 'Driver One', 'team_a'),
          _makeDriver('d2', 'Driver Two', 'team_b'),
        ],
        currentSeasonId: 'season_2026',
      );

      final league2 = FtgLeague(
        id: 'ftg_2th',
        name: 'FTG 2th Series',
        tier: 2,
        teams: [
          _makeTeam('team_c', 'Team Charlie'),
          _makeTeam('team_d', 'Team Delta'),
        ],
        drivers: [
          _makeDriver('d3', 'Driver Three', 'team_c'),
          _makeDriver('d4', 'Driver Four', 'team_d'),
        ],
        currentSeasonId: 'season_2026',
      );

      universe = GameUniverse(
        leagues: [league1, league2],
        createdAt: DateTime(2026, 1, 1),
      );
    });

    test('updates team name in the correct league', () {
      final updated = applyTeamNameUpdate(
        universe,
        'team_a',
        newName: 'Team Omega',
      );

      final worldTeams = updated.getLeagueById('ftg_world')!.teams;
      final teamA = worldTeams.firstWhere((t) => t.id == 'team_a');

      expect(teamA.name, 'Team Omega');
    });

    test('does NOT change other teams when updating one team', () {
      final updated = applyTeamNameUpdate(
        universe,
        'team_a',
        newName: 'Team Omega',
      );

      final worldTeams = updated.getLeagueById('ftg_world')!.teams;
      final teamB = worldTeams.firstWhere((t) => t.id == 'team_b');
      expect(teamB.name, 'Team Bravo'); // unchanged

      // Other league also unchanged
      final secondTeams = updated.getLeagueById('ftg_2th')!.teams;
      final teamC = secondTeams.firstWhere((t) => t.id == 'team_c');
      expect(teamC.name, 'Team Charlie');
    });

    test('updates team in second league correctly', () {
      final updated = applyTeamNameUpdate(
        universe,
        'team_c',
        newName: 'Team X-Ray',
      );

      final secondTeams = updated.getLeagueById('ftg_2th')!.teams;
      final teamC = secondTeams.firstWhere((t) => t.id == 'team_c');
      expect(teamC.name, 'Team X-Ray');

      // World league unchanged
      final worldTeams = updated.getLeagueById('ftg_world')!.teams;
      expect(worldTeams[0].name, 'Team Alpha');
      expect(worldTeams[1].name, 'Team Bravo');
    });

    test('updates budget alongside name', () {
      final updated = applyTeamNameUpdate(
        universe,
        'team_a',
        newName: 'Team Budget',
        newBudget: 4500000,
        nameChangeCount: 1,
      );

      final team = updated
          .getLeagueById('ftg_world')!
          .teams
          .firstWhere((t) => t.id == 'team_a');

      expect(team.name, 'Team Budget');
      expect(team.budget, 4500000);
      expect(team.nameChangeCount, 1);
    });

    test('throws StateError when team not found in any league', () {
      expect(
        () => applyTeamNameUpdate(
          universe,
          'team_nonexistent',
          newName: 'Ghost Team',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError with descriptive message', () {
      try {
        applyTeamNameUpdate(universe, 'team_xyz', newName: 'Ghost');
        fail('Should have thrown');
      } on StateError catch (e) {
        expect(e.message, contains('team_xyz'));
        expect(e.message, contains('not found'));
      }
    });

    test('updated universe survives serialization roundtrip', () {
      final updated = applyTeamNameUpdate(
        universe,
        'team_b',
        newName: 'Team Foxtrot',
      );

      final map = updated.toMap();
      final restored = GameUniverse.fromMap(map);

      final restoredTeam = restored
          .getLeagueById('ftg_world')!
          .teams
          .firstWhere((t) => t.id == 'team_b');

      expect(restoredTeam.name, 'Team Foxtrot');
    });

    test('drivers list is unchanged after team name update', () {
      final updated = applyTeamNameUpdate(
        universe,
        'team_a',
        newName: 'New Name',
      );

      final drivers = updated.getLeagueById('ftg_world')!.drivers;
      expect(drivers.length, 2);
      expect(drivers[0].teamId, 'team_a');
      expect(drivers[0].name, 'Driver One');
    });
  });

  // ─────────────────────────────────────────────────
  // 3. STANDINGS TEAM MAP BUILDING (Drivers tab logic)
  // ─────────────────────────────────────────────────
  group('Standings — Team map building for driver standings', () {
    test('buildTeamMap creates id->name mapping from league teams', () {
      final teams = [
        _makeTeam('t1', 'Alpha Racing'),
        _makeTeam('t2', 'Bravo Motors'),
      ];

      final teamMap = buildTeamMap(teams);

      expect(teamMap['t1'], 'Alpha Racing');
      expect(teamMap['t2'], 'Bravo Motors');
    });

    test('buildTeamMap reflects name change after universe update', () {
      // Simulate: universe updated team name
      final teamsBefore = [
        _makeTeam('t1', 'Old Name'),
        _makeTeam('t2', 'Bravo Motors'),
      ];
      final teamsAfter = [
        _makeTeam('t1', 'New Name'),
        _makeTeam('t2', 'Bravo Motors'),
      ];

      final mapBefore = buildTeamMap(teamsBefore);
      final mapAfter = buildTeamMap(teamsAfter);

      expect(mapBefore['t1'], 'Old Name');
      expect(mapAfter['t1'], 'New Name');
      expect(mapAfter['t2'], 'Bravo Motors'); // unchanged
    });

    test('driver displays correct team name via teamMap lookup', () {
      final driver = _makeDriver('d1', 'Max Speed', 'team_racing');
      final teams = [
        _makeTeam('team_racing', 'Speed Demons'),
        _makeTeam('team_other', 'Other Team'),
      ];

      final teamMap = buildTeamMap(teams);
      final displayedTeamName = teamMap[driver.teamId] ?? '—';

      expect(displayedTeamName, 'Speed Demons');
    });

    test('fallback dash shown when driver teamId not in teamMap', () {
      final driver = _makeDriver('d1', 'Lost Driver', 'deleted_team');
      final teams = [_makeTeam('team_a', 'Alpha')];

      final teamMap = buildTeamMap(teams);
      final displayedTeamName = teamMap[driver.teamId] ?? '—';

      expect(displayedTeamName, '—');
    });
  });

  // ─────────────────────────────────────────────────
  // 4. LIVE NAME OVERRIDE (the fix for stale universe data)
  // ─────────────────────────────────────────────────
  group('Standings — Live team name override', () {
    test('live name overrides stale universe name', () {
      final universeTeams = [
        _makeTeam('t1', 'Stale Old Name'),
        _makeTeam('t2', 'Team Two'),
      ];
      final liveNames = {'t1': 'Fresh New Name'};

      final teamMap = buildTeamMapWithLiveOverrides(universeTeams, liveNames);

      expect(teamMap['t1'], 'Fresh New Name'); // live override
      expect(teamMap['t2'], 'Team Two'); // universe fallback
    });

    test('falls back to universe name when live data is missing', () {
      final universeTeams = [
        _makeTeam('t1', 'Alpha'),
        _makeTeam('t2', 'Bravo'),
      ];
      final liveNames = <String, String>{}; // empty — fetch failed or pending

      final teamMap = buildTeamMapWithLiveOverrides(universeTeams, liveNames);

      expect(teamMap['t1'], 'Alpha'); // fallback
      expect(teamMap['t2'], 'Bravo'); // fallback
    });

    test('all live names override all universe names', () {
      final universeTeams = [
        _makeTeam('t1', 'Old A'),
        _makeTeam('t2', 'Old B'),
        _makeTeam('t3', 'Old C'),
      ];
      final liveNames = {'t1': 'New A', 't2': 'New B', 't3': 'New C'};

      final teamMap = buildTeamMapWithLiveOverrides(universeTeams, liveNames);

      expect(teamMap['t1'], 'New A');
      expect(teamMap['t2'], 'New B');
      expect(teamMap['t3'], 'New C');
    });

    test('partial live data overrides only available teams', () {
      final universeTeams = [
        _makeTeam('t1', 'Old A'),
        _makeTeam('t2', 'Old B'),
        _makeTeam('t3', 'Old C'),
      ];
      final liveNames = {'t2': 'New B'}; // only t2 fetched

      final teamMap = buildTeamMapWithLiveOverrides(universeTeams, liveNames);

      expect(teamMap['t1'], 'Old A'); // universe fallback
      expect(teamMap['t2'], 'New B'); // live override
      expect(teamMap['t3'], 'Old C'); // universe fallback
    });
  });

  // ─────────────────────────────────────────────────
  // 5. CONSTRUCTORS TAB — Live team data merge
  // ─────────────────────────────────────────────────
  group('Standings — Constructors tab live team merge', () {
    test('live team replaces universe team completely', () {
      final universeTeams = [
        _makeTeam('t1', 'Old Name'),
        _makeTeam('t2', 'Team Bravo'),
      ];
      final liveTeamsMap = {'t1': _makeTeam('t1', 'New Name')};

      // Replicates the merge logic from _ConstructorsStandingsTabState.build
      final mergedTeams = universeTeams.map((ut) {
        return liveTeamsMap[ut.id] ?? ut;
      }).toList();

      expect(mergedTeams[0].name, 'New Name');
      expect(mergedTeams[1].name, 'Team Bravo'); // unchanged
    });

    test('live team with updated season stats replaces stale data', () {
      final universeTeams = [_makeTeam('t1', 'Team A', seasonPoints: 0)];
      final liveTeamsMap = {
        't1': Team(
          id: 't1',
          name: 'Team A Renamed',
          isBot: false,
          budget: 6000000,
          points: 100,
          seasonPoints: 75,
          seasonWins: 3,
          seasonPodiums: 5,
          seasonRaces: 10,
          carStats: {},
          weekStatus: {},
        ),
      };

      final mergedTeams = universeTeams.map((ut) {
        return liveTeamsMap[ut.id] ?? ut;
      }).toList();

      expect(mergedTeams[0].name, 'Team A Renamed');
      expect(mergedTeams[0].seasonPoints, 75);
      expect(mergedTeams[0].seasonWins, 3);
      expect(mergedTeams[0].seasonPodiums, 5);
    });

    test('sorting works correctly with mixed live/universe teams', () {
      final universeTeams = [
        _makeTeam('t1', 'Alpha', seasonPoints: 10),
        _makeTeam('t2', 'Bravo', seasonPoints: 30),
        _makeTeam('t3', 'Charlie', seasonPoints: 20),
      ];
      // Only t1 has live data with more points
      final liveTeamsMap = {'t1': _makeTeam('t1', 'Alpha', seasonPoints: 50)};

      final mergedTeams = universeTeams.map((ut) {
        return liveTeamsMap[ut.id] ?? ut;
      }).toList();

      // Sort by seasonPoints descending (like the standings does)
      mergedTeams.sort((a, b) {
        if (b.seasonPoints != a.seasonPoints) {
          return b.seasonPoints.compareTo(a.seasonPoints);
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      expect(mergedTeams[0].id, 't1'); // 50 pts (live)
      expect(mergedTeams[1].id, 't2'); // 30 pts (universe)
      expect(mergedTeams[2].id, 't3'); // 20 pts (universe)
    });
  });

  // ─────────────────────────────────────────────────
  // 6. END-TO-END: rename → universe update → standings map
  // ─────────────────────────────────────────────────
  group('End-to-end: team rename propagation', () {
    test('renamed team shows in driver standings team map', () {
      // Initial universe
      final universe = GameUniverse(
        leagues: [
          FtgLeague(
            id: 'world',
            name: 'World',
            tier: 1,
            teams: [
              _makeTeam('my_team', 'Generic Racing'),
              _makeTeam('rival', 'Rival Motors'),
            ],
            drivers: [
              _makeDriver('d1', 'Me', 'my_team'),
              _makeDriver('d2', 'Them', 'rival'),
            ],
            currentSeasonId: 's1',
          ),
        ],
        createdAt: DateTime(2026),
      );

      // Step 1: Update universe (simulating updateTeamInUniverse)
      final updatedUniverse = applyTeamNameUpdate(
        universe,
        'my_team',
        newName: 'Dragon Racing',
        nameChangeCount: 1,
      );

      // Step 2: Build team map for standings (simulating _DriversStandingsTab)
      final league = updatedUniverse.getLeagueById('world')!;
      final teamMap = buildTeamMap(league.teams);

      // Step 3: Verify the driver's team name resolves correctly
      final driver = league.drivers.firstWhere((d) => d.id == 'd1');
      final displayedName = teamMap[driver.teamId];

      expect(displayedName, 'Dragon Racing');
    });

    test('renamed team shows in constructor standings', () {
      final universe = GameUniverse(
        leagues: [
          FtgLeague(
            id: 'world',
            name: 'World',
            tier: 1,
            teams: [_makeTeam('my_team', 'Generic Racing')],
            drivers: [],
            currentSeasonId: 's1',
          ),
        ],
        createdAt: DateTime(2026),
      );

      final updated = applyTeamNameUpdate(
        universe,
        'my_team',
        newName: 'Phoenix Racing',
      );

      final team = updated.getLeagueById('world')!.teams.first;
      expect(team.name, 'Phoenix Racing');
    });

    test('live override works even when universe update fails', () {
      // Scenario: universe still has old name (sync failed),
      // but live data from teams collection has the new name
      final staleUniverseTeams = [_makeTeam('my_team', 'Old Name')];
      final liveNames = {'my_team': 'New Name'};

      final teamMap = buildTeamMapWithLiveOverrides(
        staleUniverseTeams,
        liveNames,
      );

      expect(teamMap['my_team'], 'New Name');
    });
  });
}
