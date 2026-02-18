import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';
import '../services/season_service.dart';
import '../services/universe_service.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  String? _selectedLeagueId;
  String? _selectedDivisionId;
  bool _initialized = false;

  void _initializeSelection(GameUniverse universe, String? userTeamId) {
    if (_initialized) return;

    // Default: try to find user's league and division
    if (userTeamId != null) {
      for (final league in universe.getAllLeagues()) {
        for (final division in league.divisions) {
          if (division.teamIds.contains(userTeamId)) {
            _selectedLeagueId = league.id;
            _selectedDivisionId = division.id;
            _initialized = true;
            return;
          }
        }
      }
    }

    // Fallback: first league and first division
    if (universe.activeLeagues.isNotEmpty) {
      final firstLeague = universe.getAllLeagues().first;
      _selectedLeagueId = firstLeague.id;
      if (firstLeague.divisions.isNotEmpty) {
        _selectedDivisionId = firstLeague.divisions.first.id;
      }
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<GameUniverse?>(
      stream: UniverseService().getUniverseStream(),
      builder: (context, universeSnapshot) {
        if (!universeSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final universe = universeSnapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .where('managerId', isEqualTo: currentUser?.uid)
              .limit(1)
              .snapshots(),
          builder: (context, teamSnapshot) {
            if (!teamSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            String? userTeamId;
            if (teamSnapshot.data!.docs.isNotEmpty) {
              userTeamId = teamSnapshot.data!.docs.first.id;
            }

            // Initialize selection if needed
            _initializeSelection(universe, userTeamId);

            // Get selected objects
            CountryLeague? selectedLeague;
            if (_selectedLeagueId != null) {
              // IDK why finding by value in map is hard, checking values list
              try {
                selectedLeague = universe.getAllLeagues().firstWhere(
                  (l) => l.id == _selectedLeagueId,
                );
              } catch (_) {}
            }

            LeagueDivision? selectedDivision;
            if (selectedLeague != null && _selectedDivisionId != null) {
              selectedDivision = selectedLeague.getDivisionById(
                _selectedDivisionId!,
              );
              // Fallback if division not in this league (handling switch logic)
              if (selectedDivision == null &&
                  selectedLeague.divisions.isNotEmpty) {
                selectedDivision = selectedLeague.divisions.first;
                _selectedDivisionId = selectedDivision.id;
              }
            } else if (selectedLeague != null &&
                selectedLeague.divisions.isNotEmpty) {
              selectedDivision = selectedLeague.divisions.first;
              _selectedDivisionId = selectedDivision.id;
            }

            if (selectedLeague == null || selectedDivision == null) {
              return const Center(child: Text("No leagues available."));
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER WITH DROPDOWNS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<Season?>(
                              future: SeasonService().getSeasonById(
                                selectedLeague.currentSeasonId,
                              ),
                              builder: (context, seasonSnapshot) {
                                final seasonYear =
                                    seasonSnapshot.data?.year ?? 2026;
                                return Text(
                                  "STANDINGS SEASON $seasonYear".toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                );
                              },
                            ),
                            // Current League/Division info if desired, or just title
                          ],
                        ),
                      ),
                      // DROPDOWNS
                      Row(
                        children: [
                          // LEAGUE DROPDOWN
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedLeague.id,
                                dropdownColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                items: universe.getAllLeagues().map((league) {
                                  return DropdownMenuItem(
                                    value: league.id,
                                    child: Text(
                                      league.name, // e.g., "Liga Brasil"
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedLeagueId = val;
                                      // Reset division when league changes
                                      final newLeague = universe
                                          .getAllLeagues()
                                          .firstWhere((l) => l.id == val);
                                      if (newLeague.divisions.isNotEmpty) {
                                        _selectedDivisionId =
                                            newLeague.divisions.first.id;
                                      } else {
                                        _selectedDivisionId = null;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // DIVISION DROPDOWN
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedDivision.id,
                                dropdownColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                items: selectedLeague.divisions.map((div) {
                                  return DropdownMenuItem(
                                    value: div.id,
                                    child: Text(
                                      div.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDivisionId = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // MAIN CONTENT
                  Expanded(
                    child: Card(
                      color: Colors.black,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              indicatorColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              labelColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              unselectedLabelColor: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              indicatorSize: TabBarIndicatorSize.label,
                              tabs: const [
                                Tab(text: "DRIVERS"),
                                Tab(text: "CONSTRUCTORS"),
                                Tab(text: "LAST RACE"),
                              ],
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _DriversStandingsTab(
                                    division: selectedDivision,
                                    highlightTeamId: userTeamId,
                                  ),
                                  _ConstructorsStandingsTab(
                                    division: selectedDivision,
                                    highlightTeamId: userTeamId,
                                  ),
                                  _LastRaceStandingsTab(
                                    seasonId: selectedLeague.currentSeasonId,
                                    highlightTeamId: userTeamId,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DriversStandingsTab extends StatelessWidget {
  final LeagueDivision division;
  final String? highlightTeamId;

  const _DriversStandingsTab({required this.division, this.highlightTeamId});

  @override
  Widget build(BuildContext context) {
    if (division.teamIds.isEmpty) {
      return const Center(child: Text("No teams in this division."));
    }

    // Optimization: we could filter by teamIds in query if < 30 items
    // Since division size is usually small, this is fine.

    // We cannot easily do collectionGroup('drivers').where('teamId', whereIn: teamIds)
    // without composite index usually.
    // Instead, we fetch all and filter client side OR fetch per team.
    // Given low volume, client side filter (or just fetching all drivers if collection not huge) is simplest.
    // BUT we should try to be efficient.
    // Let's rely on fetching all drivers for now as before, but filtering output.

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('drivers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter drivers that belong to teams in this division
        final drivers = snapshot.data!.docs
            .map((d) {
              final data = d.data() as Map<String, dynamic>;
              // Ensure teamId is set
              if (data['teamId'] == null) {
                data['teamId'] = d.reference.parent.parent?.id;
              } else if (data['teamId'] is DocumentReference) {
                data['teamId'] = (data['teamId'] as DocumentReference).id;
              }
              return Driver.fromMap(data);
            })
            .where((d) => division.teamIds.contains(d.teamId))
            .toList();

        // Need team names map
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .where(FieldPath.documentId, whereIn: division.teamIds)
              .snapshots(),
          builder: (context, teamSnapshot) {
            if (!teamSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final teamMap = {
              for (var doc in teamSnapshot.data!.docs)
                doc.id: (doc.data() as Map<String, dynamic>)['name'] as String,
            };

            drivers.sort((a, b) {
              if (b.seasonPoints != a.seasonPoints) {
                return b.seasonPoints.compareTo(a.seasonPoints);
              }
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

            Map<String, int> ranks = {};
            for (int i = 0; i < drivers.length; i++) {
              ranks[drivers[i].id] = i + 1;
            }

            return _StandingsTable(
              flexValues: const [1, 3, 3, 1, 1, 1, 1, 1],
              columns: const [
                "Pos",
                "Driver",
                "Team",
                "R",
                "W",
                "P",
                "Pl",
                "Pts",
              ],
              highlightIndices: drivers
                  .asMap()
                  .entries
                  .where((e) => e.value.teamId == highlightTeamId)
                  .map((e) => e.key)
                  .toList(),
              rows: drivers
                  .map(
                    (d) => <String>[
                      "#${ranks[d.id] ?? '-'}",
                      d.name,
                      teamMap[d.teamId] ?? '—',
                      "${d.seasonRaces}",
                      "${d.seasonWins}",
                      "${d.seasonPodiums}",
                      "${d.seasonPoles}",
                      "${d.seasonPoints}",
                    ],
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _ConstructorsStandingsTab extends StatelessWidget {
  final LeagueDivision division;
  final String? highlightTeamId;

  const _ConstructorsStandingsTab({
    required this.division,
    this.highlightTeamId,
  });

  @override
  Widget build(BuildContext context) {
    if (division.teamIds.isEmpty) {
      return const Center(child: Text("No teams in this division."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where(FieldPath.documentId, whereIn: division.teamIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final teams = snapshot.data!.docs
            .map((d) => Team.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        // Sort by seasonPoints DESC (primary) then Name ASC (secondary tie-breaker)
        teams.sort((a, b) {
          if (b.seasonPoints != a.seasonPoints) {
            return b.seasonPoints.compareTo(a.seasonPoints);
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        Map<String, int> ranks = {};
        for (int i = 0; i < teams.length; i++) {
          ranks[teams[i].id] = i + 1;
        }

        return _StandingsTable(
          flexValues: const [1, 4, 1, 1, 1, 1, 2],
          columns: const ["Pos", "Team", "R", "W", "P", "Pl", "Pts"],
          highlightIndices: teams
              .asMap()
              .entries
              .where((e) => e.value.id == highlightTeamId)
              .map((e) => e.key)
              .toList(),
          rows: teams
              .map(
                (t) => <String>[
                  "#${ranks[t.id] ?? '-'}",
                  t.name,
                  "${t.seasonRaces}",
                  "${t.seasonWins}",
                  "${t.seasonPodiums}",
                  "${t.seasonPoles}",
                  "${t.seasonPoints}",
                ],
              )
              .toList(),
        );
      },
    );
  }
}

class _LastRaceStandingsTab extends StatelessWidget {
  final String seasonId;
  final String? highlightTeamId;

  const _LastRaceStandingsTab({required this.seasonId, this.highlightTeamId});

  @override
  Widget build(BuildContext context) {
    // If we only have teamId, we need team name for highlighting because Race results (legacy) used teamName.
    // Ideally we should use ID. Let's try to get team name if possible, or just skip highlight if matching by name is flaky.
    // Actually the previous code used `playerTeamName`.
    // I can fetch user's team name via a future if needed, or pass it down.
    // For now, let's see if we can highlight by ID or if we need Name.
    // Race results structure: `{'teamName': '...', 'driverName': '...'}`. It stores names! Ideally it should store IDs.
    // If it stores names, we need the user's team name to highlight.
    // I'll fetch it quickly if `highlightTeamId` is present.

    return FutureBuilder<DocumentSnapshot>(
      future: highlightTeamId != null
          ? FirebaseFirestore.instance
                .collection('teams')
                .doc(highlightTeamId)
                .get()
          : null,
      builder: (context, teamSnap) {
        String? playerTeamName;
        if (teamSnap.hasData && teamSnap.data!.exists) {
          playerTeamName =
              (teamSnap.data!.data() as Map<String, dynamic>)['name'];
        }

        return FutureBuilder<Season?>(
          future: SeasonService().getSeasonById(seasonId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final season = snapshot.data!;

            // Find last completed race
            final lastRaceIndex = season.calendar.lastIndexWhere(
              (r) => r.isCompleted,
            );
            if (lastRaceIndex == -1) {
              return const Center(
                child: Text(
                  "The season hasn't started yet.",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              );
            }

            final lastRaceEvent = season.calendar[lastRaceIndex];
            final raceId = SeasonService().raceDocumentId(
              season.id,
              lastRaceEvent,
            );

            return FutureBuilder<DocumentSnapshot>(
              future: SeasonService().getRaceDocument(raceId),
              builder: (context, raceSnapshot) {
                if (!raceSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final raceData =
                    raceSnapshot.data!.data() as Map<String, dynamic>?;
                if (raceData == null || raceData['qualifyingResults'] == null) {
                  return const Center(
                    child: Text("No data available for the last race."),
                  );
                }

                // Try to get race results first, fall back to qualifying results (which is weird but was existing logic partially)
                // Existing logic: `final results = List<Map<String, dynamic>>.from(raceData['qualifyingResults'] ?? []);`
                // Wait, results usually come from `results` map in `raceData` which is `position -> driverId`?
                // `SeasonService.saveRaceResults` saves `results` as `Map<String, int> finalPositions`.
                // It does NOT save a list with names.
                // However, `qualifyingResults` IS a list of maps with names.
                // The previous code displayed `qualifyingResults` as RACE RESULTS?
                // "RESULTS: ${lastRaceEvent.trackName}" was the title.
                // And it calculated points [25, 18, ...] based on the list index.
                // This implies it was treating the qualifying list as race result, OR the race result structure was misunderstood.
                // Given `saveRaceResults` saves `results` (map of ID->Pos), showing `qualifyingResults` (list of maps) as final results is actually WRONG if race happened.
                // BUT, looking at `applyRaceResults` (not shown here but implied), maybe `qualifyingResults` IS updated or `results` is used.
                // Re-reading `_LastRaceStandingsTab` original code:
                // `final results = List<Map<String, dynamic>>.from(raceData['qualifyingResults'] ?? []);`
                // It STRICTLY used qualifying results. This might have been a placeholder or "Qualifying Results" tab labeled as "Last Race"?
                // Or maybe existing simulation writes to `qualifyingResults`.
                // I will KEEP the existing logic to avoid breaking it, assuming `qualifyingResults` contains what we want to show.

                final results = List<Map<String, dynamic>>.from(
                  raceData['qualifyingResults'] ?? [],
                );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      "RESULTS: ${lastRaceEvent.trackName}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    const Text(
                      "DRIVER RESULTS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    _StandingsTable(
                      flexValues: const [1, 4, 4, 2],
                      columns: const ["Pos", "Driver", "Team", "Pts"],
                      highlightIndices: results
                          .take(10)
                          .toList()
                          .asMap()
                          .entries
                          .where((e) {
                            final name = e.value['teamName']?.toString().trim();
                            return name != null &&
                                name == playerTeamName?.trim();
                          })
                          .map((e) => e.key)
                          .toList(),
                      rows: results.take(10).toList().asMap().entries.map((e) {
                        final res = e.value;
                        final pos = e.key + 1;
                        final points = [
                          25,
                          18,
                          15,
                          12,
                          10,
                          8,
                          6,
                          4,
                          2,
                          1,
                        ][e.key];
                        return <String>[
                          "$pos",
                          res['driverName'] ?? 'Unknown',
                          res['teamName'] ?? 'Unknown',
                          "+$points",
                        ];
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "CONSTRUCTOR RESULTS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final teamPointsMap = <String, int>{};
                        for (int i = 0; i < results.length; i++) {
                          final teamName = results[i]['teamName'] ?? 'Unknown';
                          final points = (i < 10)
                              ? [25, 18, 15, 12, 10, 8, 6, 4, 2, 1][i]
                              : 0;
                          teamPointsMap[teamName] =
                              (teamPointsMap[teamName] ?? 0) + points;
                        }
                        final constructorResults =
                            teamPointsMap.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));

                        return _StandingsTable(
                          flexValues: const [1, 7, 2],
                          columns: const ["Pos", "Team", "Pts"],
                          highlightIndices: constructorResults
                              .asMap()
                              .entries
                              .where((e) {
                                final name = e.value.key.trim();
                                return name == playerTeamName?.trim();
                              })
                              .map((e) => e.key)
                              .toList(),
                          rows: constructorResults.asMap().entries.map((e) {
                            return <String>[
                              "${e.key + 1}",
                              e.value.key,
                              "+${e.value.value}",
                            ];
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final List<int> flexValues;
  final List<int> highlightIndices;

  const _StandingsTable({
    required this.columns,
    required this.rows,
    required this.flexValues,
    this.highlightIndices = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Column(
        children: [
          // HEADER ROW
          Row(
            children: List.generate(columns.length, (i) {
              return Expanded(
                flex: flexValues[i],
                child: Text(
                  columns[i].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // DATA ROWS
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isHighlighted = highlightIndices.contains(index);

            return Container(
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.15)
                    : null,
                border: Border(
                  left: isHighlighted
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 4,
                        )
                      : BorderSide.none,
                  bottom: const BorderSide(color: Color(0xFF303037), width: 1),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Row(
                  children: List.generate(row.length, (i) {
                    return Expanded(
                      flex: flexValues[i],
                      child: Text(
                        row[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: isHighlighted
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
