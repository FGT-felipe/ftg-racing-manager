import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';
import '../services/season_service.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Season?>(
      future: SeasonService().getActiveSeason(),
      builder: (context, snapshot) {
        final seasonNumber = snapshot.data?.number ?? 1;

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
                          labelColor: Theme.of(context).colorScheme.secondary,
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
                        const Expanded(
                          child: TabBarView(
                            children: [
                              _DriversStandingsTab(),
                              _ConstructorsStandingsTab(),
                              _LastRaceStandingsTab(),
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
  }
}

class _DriversStandingsTab extends StatelessWidget {
  const _DriversStandingsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('drivers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final drivers = snapshot.data!.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          // Ensure teamId is captured from the document path if missing in data
          if (data['teamId'] == null) {
            data['teamId'] = d.reference.parent.parent?.id;
          }
          return Driver.fromMap(data);
        }).toList();

        // Sort by points DESC (primary) then Name ASC (secondary tie-breaker)
        drivers.sort((a, b) {
          if (b.points != a.points) return b.points.compareTo(a.points);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        Map<String, int> ranks = {};
        for (int i = 0; i < drivers.length; i++) {
          ranks[drivers[i].id] = i + 1;
        }

        final user = FirebaseFirestore
            .instance
            .app
            .options
            .projectId; // Just a placeholder, we use FirebaseAuth below
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('managers')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, managerSnapshot) {
            final playerTeamId =
                (managerSnapshot.data?.data()
                    as Map<String, dynamic>?)?['teamId'];

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
  const _ConstructorsStandingsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teams').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

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

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('managers')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, managerSnapshot) {
            final playerTeamId =
                (managerSnapshot.data?.data()
                    as Map<String, dynamic>?)?['teamId'];

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
      },
    );
  }
}

class _LastRaceStandingsTab extends StatelessWidget {
  const _LastRaceStandingsTab();

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

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('managers')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                      builder: (context, managerSnapshot) {
                        final playerTeamId =
                            (managerSnapshot.data?.data()
                                as Map<String, dynamic>?)?['teamId'];

                        // Last race results are tricky as they might not have IDs in the results map
                        // but they have teamName and driverName.
                        // We'll need a way to identify the player team name.
                        // For now we use the ID comparison for Team Standings only if available.

                        return _StandingsTable(
                          flexValues: const [1, 7, 2],
                          columns: const ["Pos", "Team", "Pts"],
                          rows: constructorResults.asMap().entries.map((e) {
                            return <String>[
                              "${e.key + 1}",
                              e.value.key,
                              "+${e.value.value}",
                            ];
                          }).toList(),
                        );
                      },
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
                      ).colorScheme.secondary.withValues(alpha: 0.1)
                    : null,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF303037), width: 1),
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
