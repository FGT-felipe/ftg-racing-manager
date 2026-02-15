import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';
import '../services/season_service.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
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

        final drivers = snapshot.data!.docs
            .map((d) => Driver.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        // Calculate ranks based on points before sorting alphabetically
        final sortedByPoints = List<Driver>.from(drivers)
          ..sort((a, b) => b.points.compareTo(a.points));
        Map<String, int> ranks = {};
        for (int i = 0; i < sortedByPoints.length; i++) {
          ranks[sortedByPoints[i].id] = i + 1;
        }

        // Sort alphabetically as requested
        drivers.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('teams').snapshots(),
          builder: (context, teamSnapshot) {
            if (!teamSnapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final teamMap = {
              for (var t in teamSnapshot.data!.docs)
                t.id: (t.data() as Map<String, dynamic>)['name'] as String,
            };

            return _StandingsTable(
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
              rows: drivers
                  .map(
                    (d) => <String>[
                      "#${ranks[d.id] ?? '-'}",
                      d.name,
                      teamMap[d.teamId] ?? 'Freelance',
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

        // Calculate ranks
        final sortedByPoints = List<Team>.from(teams)
          ..sort((a, b) => b.points.compareTo(a.points));
        Map<String, int> ranks = {};
        for (int i = 0; i < sortedByPoints.length; i++) {
          ranks[sortedByPoints[i].id] = i + 1;
        }

        // Sort alphabetically
        teams.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        return _StandingsTable(
          columns: const ["Pos", "Team", "R", "W", "P", "Pl", "Pts"],
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                const Text(
                  "DRIVER RESULTS",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                _StandingsTable(
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

                    return _StandingsTable(
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

  const _StandingsTable({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 48,
          columns: columns
              .map(
                (c) => DataColumn(
                  label: Text(
                    c,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              )
              .toList(),
          rows: rows
              .map(
                (r) => DataRow(
                  cells: r
                      .map(
                        (cell) => DataCell(
                          Text(cell, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
