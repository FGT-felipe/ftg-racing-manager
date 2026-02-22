import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/race_service.dart';
import '../../services/season_service.dart';
import '../../services/circuit_service.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';

class RaceLiveScreen extends StatefulWidget {
  final String seasonId;
  final bool isEmbed;
  const RaceLiveScreen({
    super.key,
    required this.seasonId,
    this.isEmbed = false,
  });

  @override
  State<RaceLiveScreen> createState() => _RaceLiveScreenState();
}

class _RaceLiveScreenState extends State<RaceLiveScreen> {
  bool _initializing = true;
  bool _simulating = false;
  RaceSessionResult? _fullResult;
  int _currentLapIndex = 0; // 0-based index for UI loop
  Timer? _raceTimer;

  // Cache for display
  final Map<String, Driver> _driversMap = {};
  final Map<String, Team> _teamsMap = {};

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _raceTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSimulation() async {
    try {
      // 1. Fetch Data
      final seasonDoc = await FirebaseFirestore.instance
          .collection('seasons')
          .doc(widget.seasonId)
          .get();
      if (!seasonDoc.exists) throw Exception("Season not found");
      final season = Season.fromMap(seasonDoc.data()!);

      final current = SeasonService().getCurrentRace(season);
      if (current == null) throw Exception("No pending race");
      final raceEvent = current.event;
      final raceId = SeasonService().raceDocumentId(widget.seasonId, raceEvent);

      final raceDoc = await FirebaseFirestore.instance
          .collection('races')
          .doc(raceId)
          .get();
      if (!raceDoc.exists) {
        throw Exception("Race not found. Run Qualifying first.");
      }
      final raceData = raceDoc.data()!;
      if (raceData['grid'] == null) throw Exception("Grid not found.");

      final List<Map<String, dynamic>> grid = List<Map<String, dynamic>>.from(
        raceData['grid'],
      );

      // 2. Prepare Participants and Setups
      final teamsSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .get();
      Map<String, CarSetup> setupsMap = {};

      for (var teamDoc in teamsSnapshot.docs) {
        final team = Team.fromMap(teamDoc.data());
        _teamsMap[team.id] = team;

        final driversSnapshot = await FirebaseFirestore.instance
            .collection('drivers')
            .where('teamId', isEqualTo: team.id)
            .get();

        for (var i = 0; i < driversSnapshot.docs.length; i++) {
          final driverDoc = driversSnapshot.docs[i];
          final driver = Driver.fromMap({...driverDoc.data(), 'carIndex': i});
          _driversMap[driver.id] = driver;

          // Setup Logic
          if (team.isBot) {
            final circuit = CircuitService().getCircuitProfile(
              raceEvent.circuitId,
            );
            setupsMap[driver.id] = circuit.idealSetup;
          } else {
            CarSetup? setup;
            final driverSetups = team.weekStatus['driverSetups'] != null
                ? Map<String, dynamic>.from(team.weekStatus['driverSetups'])
                : null;
            final driverData =
                driverSetups != null && driverSetups.containsKey(driver.id)
                ? Map<String, dynamic>.from(driverSetups[driver.id])
                : null;

            if (driverData != null) {
              if (driverData['race'] != null) {
                setup = CarSetup.fromMap(
                  Map<String, dynamic>.from(driverData['race']),
                );
              } else if (driverData['qualifying'] != null) {
                setup = CarSetup.fromMap(
                  Map<String, dynamic>.from(driverData['qualifying']),
                );
              }
            }

            // Fallback to old paths for backward compatibility or defaults
            if (setup == null && team.weekStatus['raceSetup'] != null) {
              setup = CarSetup.fromMap(
                Map<String, dynamic>.from(team.weekStatus['raceSetup']),
              );
            }
            if (setup == null && team.weekStatus['qualifyingSetup'] != null) {
              setup = CarSetup.fromMap(
                Map<String, dynamic>.from(team.weekStatus['qualifyingSetup']),
              );
            }

            setupsMap[driver.id] = setup ?? CarSetup();
          }
        }
      }

      final circuit = CircuitService().getCircuitProfile(raceEvent.circuitId);

      // 3. Run Simulation (Calculate all laps)
      _fullResult = await RaceService().simulateRaceSession(
        raceId: raceId,
        leagueId: season.leagueId,
        circuit: circuit,
        grid: grid,
        teamsMap: _teamsMap,
        driversMap: _driversMap,
        setupsMap: setupsMap,
      );

      setState(() {
        _initializing = false;
        _simulating = true;
      });

      // 4. Start Replay Timer
      _startReplay();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        Navigator.pop(context);
      }
    }
  }

  void _startReplay() {
    // Show one lap every 800ms
    _raceTimer = Timer.periodic(const Duration(milliseconds: 800), (
      timer,
    ) async {
      if (_fullResult == null) return;

      if (_currentLapIndex < _fullResult!.laps.length - 1) {
        setState(() {
          _currentLapIndex++;
        });
      } else {
        timer.cancel();
        await _finishRace();
      }
    });
  }

  void _skipSimulation() {
    _raceTimer?.cancel();
    setState(() {
      _currentLapIndex = _fullResult!.laps.length - 1;
    });
    _finishRace();
  }

  Future<void> _finishRace() async {
    if (_fullResult == null) return;

    setState(() => _simulating = false); // Show saving indicator?

    // Apply Results
    final applyRes = await RaceService().applyRaceResults(
      widget.seasonId,
      _fullResult!,
    );

    if (!mounted) return;

    // Show Dialog
    final winnerId = _fullResult!.finalPositions.entries
        .firstWhere((e) => e.value == 1)
        .key;
    final winnerName = _driversMap[winnerId]?.name ?? "Unknown";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text(
          "RACE FINISHED",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Winner: $winnerName"),
            const SizedBox(height: 10),
            Text("Your team earnings: \$${applyRes['playerEarnings']}"),
            const SizedBox(height: 20),
            const Text("Results applied to season."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (!widget.isEmbed) {
                Navigator.pop(
                  context,
                ); // Exit RaceLiveScreen only if not embedded
              }
            },
            child: Text(widget.isEmbed ? "CONTINUE" : "RETURN TO DASHBOARD"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      final loadingIndicator = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Preparing Race Simulation..."),
          ],
        ),
      );
      if (widget.isEmbed) return loadingIndicator;
      return Scaffold(body: loadingIndicator);
    }

    if (_fullResult == null) {
      const errorContent = Center(child: Text("Simulation Error"));
      if (widget.isEmbed) return errorContent;
      return const Scaffold(body: errorContent);
    }

    final currentLapData = _fullResult!.laps[_currentLapIndex];
    final totalLaps = _fullResult!.laps.length;

    // Sort drivers by position in this lap
    final sortedDrivers = currentLapData.positions.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Determine overall fastest lap holder up to this point
    String? overallFastestDriverId;
    double overallFastestTime = double.infinity;
    for (int i = 0; i <= _currentLapIndex; i++) {
      final lapData = _fullResult!.laps[i];
      for (final entry in lapData.driverLapTimes.entries) {
        if (entry.value < 900 && entry.value < overallFastestTime) {
          overallFastestTime = entry.value;
          overallFastestDriverId = entry.key;
        }
      }
    }

    // Determine recent events (from this lap)
    final events = currentLapData.events;

    final content = Column(
      children: [
        // Race Monitor Header (Events)
        Container(
          height: 80,
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.all(12),
          child: events.isEmpty
              ? Center(
                  child: Text(
                    "Green Flag",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : ListView(
                  children: events
                      .map(
                        (e) => Text(
                          "[Lap ${e.lapNumber}] ${e.type}: ${_driversMap[e.driverId]?.name}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),

        // Fastest Lap & Race Time info bar
        Builder(
          builder: (context) {
            // Compute overall fastest lap across all laps so far
            String? overallFastestDriverId;
            double overallFastestTime = double.infinity;
            double leaderTotalTime = 0;

            for (int i = 0; i <= _currentLapIndex; i++) {
              final lap = _fullResult!.laps[i];
              for (var entry in lap.driverLapTimes.entries) {
                if (entry.value < 900 && entry.value < overallFastestTime) {
                  overallFastestTime = entry.value;
                  overallFastestDriverId = entry.key;
                }
              }
              // Accumulate leader's time
              String? lapLeader;
              int bestPos = 999;
              for (var pe in lap.positions.entries) {
                if (pe.value < bestPos) {
                  bestPos = pe.value;
                  lapLeader = pe.key;
                }
              }
              if (lapLeader != null) {
                final lt = lap.driverLapTimes[lapLeader] ?? 0;
                if (lt < 900) leaderTotalTime += lt;
              }
            }

            final hasFastest =
                overallFastestDriverId != null &&
                overallFastestTime < double.infinity;
            final fastestName = hasFastest
                ? (_driversMap[overallFastestDriverId]?.name ?? 'Unknown')
                : '—';

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Row(
                children: [
                  // Fastest Lap
                  Icon(Icons.timer, size: 14, color: const Color(0xFFE040FB)),
                  const SizedBox(width: 4),
                  Text(
                    hasFastest
                        ? '$fastestName  ${_formatLapTime(overallFastestTime)}'
                        : 'FASTEST LAP: —',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE040FB),
                    ),
                  ),
                  const Spacer(),
                  // Race Time
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    leaderTotalTime > 0
                        ? 'RACE: ${_formatRaceTime(leaderTotalTime)}'
                        : 'RACE: —',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Leaderboard
        Expanded(
          child: Builder(
            builder: (context) {
              // Get leader's lap time for gap calculation
              final leaderId = sortedDrivers.isNotEmpty
                  ? sortedDrivers.first.key
                  : null;
              final leaderLapTime = leaderId != null
                  ? currentLapData.driverLapTimes[leaderId]
                  : null;

              return ListView.builder(
                itemCount: sortedDrivers.length,
                itemBuilder: (context, index) {
                  final entry = sortedDrivers[index];
                  final driverId = entry.key;
                  final pos = entry.value;
                  final driver = _driversMap[driverId];
                  final team = _teamsMap[driver?.teamId];
                  final lapTime =
                      currentLapData.driverLapTimes[driverId] ?? 0.0;
                  final isDnf = lapTime > 900;
                  final isFastestLap = driverId == overallFastestDriverId;

                  // Compute interval text
                  String intervalText;
                  if (isDnf) {
                    intervalText = 'RETIRED';
                  } else if (index == 0) {
                    intervalText = 'LEADER';
                  } else if (leaderLapTime != null && leaderLapTime < 900) {
                    final gap = lapTime - leaderLapTime;
                    intervalText = '+${gap.toStringAsFixed(3)}s';
                  } else {
                    intervalText = '${lapTime.toStringAsFixed(3)}s';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            alignment: Alignment.center,
                            child: Text(
                              "$pos",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (isFastestLap && !isDnf)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.timer,
                                size: 16,
                                color: const Color(0xFFE040FB),
                              ),
                            ),
                        ],
                      ),
                      title: Text(driver?.name ?? "Unknown"),
                      subtitle: Text(team?.name ?? "Unknown Team"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            intervalText,
                            style: TextStyle(
                              color: isDnf
                                  ? Colors.red
                                  : (isFastestLap
                                        ? const Color(0xFFE040FB)
                                        : Theme.of(context).primaryColor),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.isEmbed) return content;

    return Scaffold(
      appBar: AppBar(
        title: Text("Lap ${currentLapData.lapNumber} / $totalLaps"),
        centerTitle: true,
        actions: [
          if (_simulating)
            TextButton(
              onPressed: _skipSimulation,
              child: Text(
                "SKIP",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
      body: content,
    );
  }

  String _formatLapTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds - (mins * 60);
    return "$mins:${secs.toStringAsFixed(3).padLeft(6, '0')}";
  }

  String _formatRaceTime(double totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final mins = ((totalSeconds % 3600) / 60).floor();
    final secs = (totalSeconds % 60).floor();
    return '${hours.toString().padLeft(2, '0')}H:${mins.toString().padLeft(2, '0')}M:${secs.toString().padLeft(2, '0')}S';
  }
}
