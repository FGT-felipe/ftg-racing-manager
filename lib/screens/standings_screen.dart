import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/core_models.dart';
import '../services/season_service.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Season?>(
      future: SeasonService().getActiveSeason(),
      builder: (context, seasonSnapshot) {
        final seasonNumber = seasonSnapshot.data?.number ?? 1;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .where('managerId', isEqualTo: currentUser?.uid)
              .limit(1)
              .snapshots(),
          builder: (context, teamSnapshot) {
            final playerTeamDoc =
                teamSnapshot.hasData && teamSnapshot.data!.docs.isNotEmpty
                ? teamSnapshot.data!.docs.first
                : null;
            final playerTeamId = playerTeamDoc?.id;
            final playerTeamName =
                (playerTeamDoc?.data() as Map<String, dynamic>?)?['name']
                    as String?;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SEASON $seasonNumber STANDINGS",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                                    playerTeamId: playerTeamId,
                                  ),
                                  _ConstructorsStandingsTab(
                                    playerTeamId: playerTeamId,
                                  ),
                                  _LastRaceStandingsTab(
                                    playerTeamName: playerTeamName,
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
  final String? playerTeamId;
  const _DriversStandingsTab({this.playerTeamId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teams').snapshots(),
      builder: (context, teamsSnapshot) {
        if (!teamsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final teamMap = {
          for (var doc in teamsSnapshot.data!.docs)
            doc.id: (doc.data() as Map<String, dynamic>)['name'] as String,
        };

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('drivers')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final drivers = snapshot.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              // Ensure teamId is consistent (String) and set from parent if missing
              if (data['teamId'] == null) {
                data['teamId'] = d.reference.parent.parent?.id;
              } else if (data['teamId'] is DocumentReference) {
                data['teamId'] = (data['teamId'] as DocumentReference).id;
              }
              return Driver.fromMap(data);
            }).toList();

            drivers.sort((a, b) {
              if (b.points != a.points) return b.points.compareTo(a.points);
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
                  .where((e) => e.value.teamId == playerTeamId)
                  .map((e) => e.key)
                  .toList(),
              rows: drivers
                  .map(
                    (d) => <String>[
                      "#${ranks[d.id] ?? '-'}",
                      d.name,
                      teamMap[d.teamId] ?? '—',
                      "${d.races}",
                      "${d.wins}",
                      "${d.podiums}",
                      "${d.poles}",
                      "${d.points}",
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
  final String? playerTeamId;
  const _ConstructorsStandingsTab({this.playerTeamId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teams').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final teams = snapshot.data!.docs
            .map((d) => Team.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        // Sort by points DESC (primary) then Name ASC (secondary tie-breaker)
        teams.sort((a, b) {
          if (b.points != a.points) return b.points.compareTo(a.points);
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
              .where((e) => e.value.id == playerTeamId)
              .map((e) => e.key)
              .toList(),
          rows: teams
              .map(
                (t) => <String>[
                  "#${ranks[t.id] ?? '-'}",
                  t.name,
                  "${t.races}",
                  "${t.wins}",
                  "${t.podiums}",
                  "${t.poles}",
                  "${t.points}",
                ],
              )
              .toList(),
        );
      },
    );
  }
}

class _LastRaceStandingsTab extends StatelessWidget {
  final String? playerTeamName;
  const _LastRaceStandingsTab({this.playerTeamName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Season?>(
      future: SeasonService().getActiveSeason(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
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
        final raceId = SeasonService().raceDocumentId(season.id, lastRaceEvent);

        return FutureBuilder<DocumentSnapshot>(
          future: SeasonService().getRaceDocument(raceId),
          builder: (context, raceSnapshot) {
            if (!raceSnapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final raceData = raceSnapshot.data!.data() as Map<String, dynamic>?;
            if (raceData == null || raceData['qualifyingResults'] == null) {
              return const Center(
                child: Text("No data available for the last race."),
              );
            }

            final results = List<Map<String, dynamic>>.from(
              raceData['qualifyingResults'] ?? [],
            );
            // Assuming we also have raceResults in the document if it was simulated.
            // If simulateNextRace was used, it doesn't store per-race results in a 'races' collection yet,
            // it only updates global points.
            // WAIT, the existing code for simulateNextRace doesn't seem to save results to a race doc.
            // But applyRaceResults DOES save status=completed.

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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                        return name != null && name == playerTeamName?.trim();
                      })
                      .map((e) => e.key)
                      .toList(),
                  rows: results.take(10).toList().asMap().entries.map((e) {
                    final res = e.value;
                    final pos = e.key + 1;
                    final points = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1][e.key];
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    final constructorResults = teamPointsMap.entries.toList()
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
