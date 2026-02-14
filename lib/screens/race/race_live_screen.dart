import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/race_service.dart';
import '../../services/season_service.dart';
import '../../services/circuit_service.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';

class RaceLiveScreen extends StatefulWidget {
  final String seasonId;
  const RaceLiveScreen({super.key, required this.seasonId});

  @override
  State<RaceLiveScreen> createState() => _RaceLiveScreenState();
}

class _RaceLiveScreenState extends State<RaceLiveScreen> {
  bool _isLoading = false;

  Future<void> _simulateRace() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get Season and Current Race
      final seasonDoc = await FirebaseFirestore.instance
          .collection('seasons')
          .doc(widget.seasonId)
          .get();
      if (!seasonDoc.exists) throw Exception("Season not found");
      final season = Season.fromMap(seasonDoc.data()!);

      final current = SeasonService().getCurrentRace(season);
      if (current == null) {
        throw Exception("No pending race in calendar");
      }
      final raceEvent = current.event;

      // 2. Get Race Document (for Grid)
      final raceId = SeasonService().raceDocumentId(widget.seasonId, raceEvent);
      final raceDoc = await FirebaseFirestore.instance
          .collection('races')
          .doc(raceId)
          .get();

      if (!raceDoc.exists) {
        throw Exception("Race document not found. Did you run Qualifying?");
      }

      final raceData = raceDoc.data()!;
      if (raceData['grid'] == null) {
        throw Exception("Grid not found. Run Qualifying first.");
      }

      final List<Map<String, dynamic>> grid = List<Map<String, dynamic>>.from(
        raceData['grid'],
      );

      // 3. Prepare data for simulation (Teams, Drivers, Setups)
      final teamsSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .get();
      Map<String, Team> teamsMap = {};
      Map<String, Driver> driversMap = {};
      Map<String, CarSetup> setupsMap = {};

      for (var teamDoc in teamsSnapshot.docs) {
        final team = Team.fromMap(teamDoc.data());
        teamsMap[team.id] = team;

        // Fetch drivers
        final driversSnapshot = await teamDoc.reference
            .collection('drivers')
            .get();
        for (var dDoc in driversSnapshot.docs) {
          final driver = Driver.fromMap(dDoc.data());
          driversMap[driver.id] = driver;

          // Determine setup (Player vs AI)
          if (team.isBot) {
            // For AI, we generate setup or use a default if not stored.
            // SimulateRaceSession handles logic if we pass it, OR we generate here.
            // The old logic generated it inside simulateNextRace, but simulateRaceSession expects it passed.
            // Let's create a Helper in RaceService to generate AI Setup or do it here.
            // Re-using logic: circuit.idealSetup
            final circuit = CircuitService().getCircuitProfile(
              raceEvent.circuitId,
            );
            // Simple deviation for now
            setupsMap[driver.id] = circuit.idealSetup;
            // Ideally we should reuse _generateAISetup from RaceService but it's private.
            // We can make it public or just use ideal setup for now (AI is perfect!)
            // OR: rely on WeekStatus if AI set it? (AI doesn't currently set it in weekStatus).
            // Let's assume ideal setup for AI to make them competitive.
          } else {
            // Player: Use Race Strategy setup or Qualifying setup
            if (team.weekStatus['raceSetup'] != null) {
              setupsMap[driver.id] = CarSetup.fromMap(
                Map<String, dynamic>.from(team.weekStatus['raceSetup']),
              );
            } else if (team.weekStatus['qualifyingSetup'] != null) {
              setupsMap[driver.id] = CarSetup.fromMap(
                Map<String, dynamic>.from(team.weekStatus['qualifyingSetup']),
              );
            } else {
              setupsMap[driver.id] = CarSetup(); // Default
            }
          }
        }
      }

      final circuit = CircuitService().getCircuitProfile(raceEvent.circuitId);

      // 4. Run Simulation (Lap by Lap)
      final result = await RaceService().simulateRaceSession(
        raceId: raceId,
        circuit: circuit,
        grid: grid,
        teamsMap: teamsMap,
        driversMap: driversMap,
        setupsMap: setupsMap,
      );

      // 5. Apply Results (Points, Economy, Calendar)
      final applyRes = await RaceService().applyRaceResults(
        widget.seasonId,
        result,
      );

      // 6. Show Result
      if (mounted) {
        setState(() => _isLoading = false);

        final winnerId = result.finalPositions.entries
            .firstWhere((e) => e.value == 1)
            .key;
        final winnerName = driversMap[winnerId]?.name ?? "Unknown";

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("RACE FINISHED"),
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
                  Navigator.pop(context); // Exit RaceLiveScreen
                },
                child: const Text("RETURN TO DASHBOARD"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Grand Prix - LIVE")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Main Race Event",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _simulateRace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
                child: const Text(
                  "WATCH RACE SIMULATION",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
