import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';
import '../services/race_service.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("STANDINGS & CALENDAR"),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.5),
            tabs: const [
              Tab(text: "DRIVERS"),
              Tab(text: "TEAMS"),
              Tab(text: "CALENDAR"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_DriversTab(), _TeamsTab(), _CalendarTab()],
        ),
      ),
    );
  }
}

class _DriversTab extends StatelessWidget {
  const _DriversTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('drivers')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final driver = Driver.fromMap(
              docs[index].data() as Map<String, dynamic>,
            );
            return Card(
              color: Theme.of(context).cardTheme.color,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? Colors.yellow
                      : Colors.tealAccent.withOpacity(0.1),
                  child: Text(
                    "#${index + 1}",
                    style: TextStyle(
                      color: index == 0
                          ? Colors.black
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                title: Text(
                  driver.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  "${driver.points} pts",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final team = Team.fromMap(
              docs[index].data() as Map<String, dynamic>,
            );
            return Card(
              color: Theme.of(context).cardTheme.color,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? Colors.yellow
                      : Colors.tealAccent.withOpacity(0.1),
                  child: Text(
                    "#${index + 1}",
                    style: TextStyle(
                      color: index == 0
                          ? Colors.black
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                title: Text(
                  team.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  "${team.points} pts",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab();

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  bool _isSimulating = false;

  Future<void> _handleSimulate(
    BuildContext context,
    String seasonId,
    String trackName,
  ) async {
    final l10n = AppLocalizations.of(context);

    setState(() => _isSimulating = true);

    try {
      final results = await RaceService().simulateNextRace(seasonId);
      final List<Driver> podium = results['podium'] as List<Driver>;
      final List<String> dnfDrivers = results['dnfDrivers'] as List<String>;
      final int playerEarnings = results['playerEarnings'] as int;
      final earningsM = (playerEarnings / 1000000).toStringAsFixed(1);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(
              l10n.raceResults,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.podium.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  _PodiumItem(
                    pos: 1,
                    name: podium[0].name,
                    color: Colors.yellow,
                  ),
                  _PodiumItem(pos: 2, name: podium[1].name, color: Colors.grey),
                  _PodiumItem(
                    pos: 3,
                    name: podium[2].name,
                    color: Colors.brown,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.financialReport.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.earnings,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "+ ${l10n.currencySymbol}$earningsM${l10n.millionsSuffix}",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  if (dnfDrivers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "RETIRED (DNF)",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.redAccent, thickness: 0.5),
                    ...dnfDrivers.map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CLOSE",
                  style: TextStyle(color: Colors.tealAccent),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('seasons')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        if (snapshot.data!.docs.isEmpty)
          return const Center(child: Text("No Calendar found"));

        final seasonDoc = snapshot.data!.docs.first;
        final season = Season.fromMap(seasonDoc.data() as Map<String, dynamic>);
        final events = season.calendar;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final dateFormat = DateFormat('MMM dd, yyyy');
            final isNext =
                !event.isCompleted &&
                (index == 0 || events[index - 1].isCompleted);

            return Opacity(
              opacity: event.isCompleted ? 0.6 : 1.0,
              child: Card(
                color: isNext
                    ? Theme.of(context).primaryColor.withOpacity(0.05)
                    : Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isNext
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.trackName,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dateFormat.format(event.date),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (event.isCompleted)
                            const Icon(Icons.check_circle, color: Colors.teal)
                          else if (isNext)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "NEXT",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          else
                            const Text(
                              "UPCOMING",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      if (isNext) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSimulating
                                ? null
                                : () => _handleSimulate(
                                    context,
                                    season.id,
                                    event.trackName,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondary,
                            ),
                            child: _isSimulating
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondary,
                                    ),
                                  )
                                : Text(l10n.simulateBtn.toUpperCase()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int pos;
  final String name;
  final Color color;

  const _PodiumItem({
    required this.pos,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(
              pos.toString(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
