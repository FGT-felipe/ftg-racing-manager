import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';
import '../models/simulation_models.dart';
import '../services/circuit_service.dart';

class RaceService {
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera un setup aproximado para la IA basado en la calidad del equipo
  CarSetup _generateAISetup(CircuitProfile circuit, Team team) {
    final random = Random();
    final ideal = circuit.idealSetup;

    // Competencia de la IA basada en stats del coche (Aero + Engine)
    // 100 stats = 0 desviación. 50 stats = +/- 10 desviación.
    double avgStat =
        ((team.carStats['aero'] ?? 50) + (team.carStats['engine'] ?? 50)) / 2.0;
    int maxDeviation = ((100 - avgStat) / 4).round().clamp(2, 25);

    int dev() => random.nextInt(maxDeviation * 2 + 1) - maxDeviation;

    return CarSetup(
      frontWing: (ideal.frontWing + dev()).clamp(0, 100),
      rearWing: (ideal.rearWing + dev()).clamp(0, 100),
      suspension: (ideal.suspension + dev()).clamp(0, 100),
      gearRatio: (ideal.gearRatio + dev()).clamp(0, 100),
      tyrePressure: (ideal.tyrePressure + dev()).clamp(0, 100),
    );
  }

  Future<List<Map<String, dynamic>>> simulateQualifying(String seasonId) async {
    // 1. Obtener Datos
    final seasonDoc = await _db.collection('seasons').doc(seasonId).get();
    if (!seasonDoc.exists) throw Exception("Season not found");
    final season = Season.fromMap(seasonDoc.data()!);

    final raceIndex = season.calendar.indexWhere((r) => !r.isCompleted);
    if (raceIndex == -1) throw Exception("No pending races");
    // final currentRace = season.calendar[raceIndex];

    // TODO: Usar el ID real del circuito cuando esté disponible en RaceEvent
    // Por ahora usamos el nombre o ID genérico derivado
    // final circuit = CircuitService().getCircuitProfile(currentRace.circuitId);
    final circuit = CircuitService().getCircuitProfile(
      'interlagos',
    ); // Mock default

    final teamsSnapshot = await _db.collection('teams').get();
    List<Map<String, dynamic>> qualyResults = [];

    for (var teamDoc in teamsSnapshot.docs) {
      final team = Team.fromMap(teamDoc.data());
      CarSetup teamSetup;

      // 2. Determinar Setup
      if (team.isBot) {
        teamSetup = _generateAISetup(circuit, team);
      } else {
        // Player Team: Recuperar setup guardado o usar default
        if (team.weekStatus['currentSetup'] != null) {
          teamSetup = CarSetup.fromMap(
            Map<String, dynamic>.from(team.weekStatus['currentSetup']),
          );
        } else {
          teamSetup = CarSetup(); // Default 50-50-50...
        }
      }

      // 3. Simular Vueltas para cada piloto
      final driversSnapshot = await teamDoc.reference
          .collection('drivers')
          .get();
      for (var driverDoc in driversSnapshot.docs) {
        final driver = Driver.fromMap(driverDoc.data());

        // Simular vuelta
        final result = simulatePracticeRun(
          circuit: circuit,
          team: team,
          driver: driver,
          setup: teamSetup,
        );

        qualyResults.add({
          'driverId': driver.id,
          'driverName': driver.name,
          'teamName': team.name,
          'lapTime': result.lapTime,
          'gap': 0.0, // Se calcula después de ordenar
        });
      }
    }

    // 4. Ordenar Grid (Menor tiempo primero)
    qualyResults.sort(
      (a, b) => (a['lapTime'] as double).compareTo(b['lapTime'] as double),
    );

    // 5. Calcular Gaps
    if (qualyResults.isNotEmpty) {
      double poleTime = qualyResults.first['lapTime'];
      for (var res in qualyResults) {
        res['gap'] = (res['lapTime'] as double) - poleTime;
      }
    }

    return qualyResults;
  }

  /// Simula una vuelta de práctica para un conductor específico con un setup dado
  PracticeRunResult simulatePracticeRun({
    required CircuitProfile circuit,
    required Team team,
    required Driver driver,
    required CarSetup setup,
  }) {
    final random = Random();
    final ideal = circuit.idealSetup;

    // 1. Calcular la desviación del setup (Penalty)
    double setupPenalty = 0.0;
    List<String> feedback = [];

    // Aero Front
    int gapFront = setup.frontWing - ideal.frontWing;
    setupPenalty += gapFront.abs() * 0.05; // 0.05s por punto de diferencia
    if (gapFront > 15)
      feedback.add("Steering feels too sensitive (Oversteer).");
    if (gapFront < -15)
      feedback.add("The car doesn't want to turn in (Understeer).");

    // Aero Rear
    int gapRear = setup.rearWing - ideal.rearWing;
    setupPenalty += gapRear.abs() * 0.05;
    if (gapRear > 15) feedback.add("Too much drag on the straights.");
    if (gapRear < -15) feedback.add("The rear is loose on exit.");

    // Suspension
    int gapSusp = setup.suspension - ideal.suspension;
    setupPenalty += gapSusp.abs() * 0.03;
    if (gapSusp > 15) feedback.add("Car is bouncing too much over kerbs.");
    if (gapSusp < -15) feedback.add("Car feels sluggish to precise inputs.");

    // Gear Ratio
    int gapGear = setup.gearRatio - ideal.gearRatio;
    setupPenalty += gapGear.abs() * 0.04;
    if (gapGear > 15) feedback.add("Hitting the rev limiter too early.");
    if (gapGear < -15) feedback.add("Acceleration out of corners is poor.");

    // Tyre Pressure
    int gapTyre = setup.tyrePressure - ideal.tyrePressure;
    setupPenalty += gapTyre.abs() * 0.02;
    if (gapTyre > 10) feedback.add("Tyres are overheating quickly.");
    if (gapTyre < -10) feedback.add("Struggling to get heat into the tyres.");

    // 2. Calcular Base Lap Time ajustado por el coche y conductor
    // Car Score: (Aero + Engine + Reliability) / 300 -> 0.5 to 1.0 factor?
    // Better car = Lower lap time.
    double carPerformanceFactor =
        1.0 -
        (((team.carStats['aero'] ?? 50) + (team.carStats['engine'] ?? 50)) /
            200.0 *
            0.05);
    // Max reduction 5%. This is conservative. Let's make it 2s range.

    // Driver Score
    double driverFactor =
        1.0 -
        (((driver.stats['speed'] ?? 50) + (driver.stats['cornering'] ?? 50)) /
            200.0 *
            0.03);

    double actualLapTime =
        circuit.baseLapTime * carPerformanceFactor * driverFactor;

    // Add Setup Penalty
    actualLapTime += setupPenalty;

    // Add Randomness (Driver consistency)
    double consistency =
        (driver.stats['consistency'] ?? 50) / 100.0; // 0.5 to 1.0
    double randomVariation =
        (random.nextDouble() - 0.5) *
        2 *
        (1.0 - consistency); // +/- based on consistency
    actualLapTime += randomVariation;

    // 3. Calcular Setup Confidence
    // 0 gap = 100%. Max gap approx 50 per component * 5 = 250.
    double totalGap =
        (gapFront.abs() +
                gapRear.abs() +
                gapSusp.abs() +
                gapGear.abs() +
                gapTyre.abs())
            .toDouble();
    double confidence = (1.0 - (totalGap / 200.0)).clamp(0.0, 1.0);

    if (feedback.isEmpty) {
      if (confidence > 0.95)
        feedback.add("The balance feels perfect!");
      else
        feedback.add("The car feels okay, maybe small tweaks needed.");
    }

    return PracticeRunResult(
      lapTime: actualLapTime,
      driverFeedback: feedback,
      setupConfidence: confidence,
    );
  }

  /// Simula una carrera completa vuelta a vuelta
  Future<RaceSessionResult> simulateRaceSession({
    required String raceId,
    required CircuitProfile circuit,
    required List<Map<String, dynamic>> grid, // [ {driverId, team, setup...} ]
    required Map<String, Team> teamsMap, // id -> Team
    required Map<String, Driver> driversMap, // id -> Driver
    required Map<String, CarSetup> setupsMap, // driverId -> Setup
  }) async {
    final random = Random();
    int totalLaps = 50;

    // Initial State
    List<String> currentOrder = grid
        .map((e) => e['driverId'] as String)
        .toList();
    Map<String, double> totalTimes = {for (var id in currentOrder) id: 0.0};
    Map<String, double> tyreWear = {for (var id in currentOrder) id: 0.0};
    List<String> dnfs = [];
    List<LapData> raceLog = [];

    // Base loop
    for (int lap = 1; lap <= totalLaps; lap++) {
      Map<String, double> currentLapTimes = {};
      List<RaceEventLog> lapEvents = [];

      // 1. Calculate Times
      for (var driverId in currentOrder) {
        if (dnfs.contains(driverId)) continue;

        final driver = driversMap[driverId]!;
        final team = teamsMap[driver.teamId!]!;
        final setup = setupsMap[driverId]!;

        // Base Performance
        PracticeRunResult baseRun = simulatePracticeRun(
          circuit: circuit,
          team: team,
          driver: driver,
          setup: setup,
        );

        double lapTime = baseRun.lapTime;

        // Tyre Wear Penalty
        double wear = tyreWear[driverId]!;
        lapTime += pow(wear / 100.0, 2) * 5.0; // Exponential penalty

        // Fuel Effect (Car gets lighter)
        lapTime -= (lap * 0.05);

        // Pit Stop Logic
        if (wear > 70) {
          lapTime += 25.0; // Pit Time
          tyreWear[driverId] = 0.0;
          lapEvents.add(
            RaceEventLog(
              lapNumber: lap,
              driverId: driverId,
              description: "Pit Stop",
              type: "PIT",
            ),
          );
        } else {
          // Add Wear
          tyreWear[driverId] = wear + 3.0 + random.nextDouble();
        }

        currentLapTimes[driverId] = lapTime;
        totalTimes[driverId] = (totalTimes[driverId] ?? 0) + lapTime;
      }

      // 2. Resolve Positions (Sort by Total Time)
      List<String> newOrder = List.from(currentOrder);
      newOrder.sort((a, b) {
        if (dnfs.contains(a)) return 1;
        if (dnfs.contains(b)) return -1;
        return totalTimes[a]!.compareTo(totalTimes[b]!);
      });

      // Detect Overtakes
      for (int i = 0; i < newOrder.length; i++) {
        String driver = newOrder[i];
        if (dnfs.contains(driver)) continue;

        int oldPos = currentOrder.indexOf(driver);
        if (oldPos != -1 && i < oldPos) {
          lapEvents.add(
            RaceEventLog(
              lapNumber: lap,
              driverId: driver,
              description: "Overtake", // Generic for now
              type: "OVERTAKE",
            ),
          );
        }
      }
      currentOrder = newOrder;

      // 3. Store Lap Data
      Map<String, int> positions = {};
      for (int i = 0; i < currentOrder.length; i++) {
        positions[currentOrder[i]] = i + 1;
      }

      raceLog.add(
        LapData(
          lapNumber: lap,
          driverLapTimes: currentLapTimes,
          positions: positions,
          events: lapEvents,
        ),
      );
    }

    // Final Result
    Map<String, int> finalPositions = {};
    for (int i = 0; i < currentOrder.length; i++) {
      finalPositions[currentOrder[i]] = i + 1;
    }

    return RaceSessionResult(
      raceId: raceId,
      laps: raceLog,
      finalPositions: finalPositions,
      totalTimes: totalTimes,
      dnfs: dnfs,
    );
  }

  Future<Map<String, dynamic>> simulateNextRace(String seasonId) async {
    final random = Random();

    // 1. Identify the Race
    final seasonDoc = await _db.collection('seasons').doc(seasonId).get();
    if (!seasonDoc.exists) throw Exception("Season not found");

    final season = Season.fromMap(seasonDoc.data()!);
    final raceIndex = season.calendar.indexWhere((r) => !r.isCompleted);

    if (raceIndex == -1) throw Exception("No more races in this season");

    final currentRace = season.calendar[raceIndex];

    // 2. Obtain Competitors & AI Progression
    final teamsSnapshot = await _db.collection('teams').get();
    List<_DriverPerformance> performances = [];
    List<String> dnfNames = [];

    final batch = _db.batch();

    for (var teamDoc in teamsSnapshot.docs) {
      final team = Team.fromMap(teamDoc.data());

      // Upgrade AI teams (40% chance for aero and engine)
      if (team.isBot) {
        bool upgraded = false;
        final newStats = Map<String, int>.from(team.carStats);

        if (random.nextInt(100) < 40) {
          newStats['aero'] = (newStats['aero'] ?? 50) + 1;
          upgraded = true;
        }
        if (random.nextInt(100) < 40) {
          newStats['engine'] = (newStats['engine'] ?? 50) + 1;
          upgraded = true;
        }

        if (upgraded) {
          batch.update(teamDoc.reference, {'carStats': newStats});
        }
      }

      final driversSnapshot = await teamDoc.reference
          .collection('drivers')
          .get();

      for (var driverDoc in driversSnapshot.docs) {
        final driver = Driver.fromMap(driverDoc.data());

        // 3. Reliability Check (DNF) - Smoothed formula
        final reliability = (team.carStats['reliability'] ?? 50).toDouble();
        final double failureChance = (100.0 - reliability) * 0.25;
        final double roll = random.nextDouble() * 100;

        double score = 0;
        bool isDNF = roll < failureChance;

        if (isDNF) {
          dnfNames.add("${driver.name} (${team.name})");
          score = 0;
        } else {
          // 4. Calculate Performance
          score =
              (driver.stats['speed'] ?? 0).toDouble() +
              (driver.stats['cornering'] ?? 0).toDouble() +
              ((team.carStats['aero'] ?? 0) * 2).toDouble() +
              ((team.carStats['engine'] ?? 0) * 2).toDouble() +
              random.nextInt(26).toDouble();
        }

        performances.add(
          _DriverPerformance(
            driver: driver,
            team: team,
            driverRef: driverDoc.reference,
            teamRef: teamDoc.reference,
            score: score,
            isDNF: isDNF,
          ),
        );
      }
    }

    // 5. Sort and Award Points
    performances.sort((a, b) => b.score.compareTo(a.score));

    final pointSystem = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
    Map<DocumentReference, int> teamPointUpdates = {};

    for (int i = 0; i < performances.length; i++) {
      final perf = performances[i];
      int pointsEarned = 0;

      if (!perf.isDNF && i < pointSystem.length) {
        pointsEarned = pointSystem[i];
      }

      if (pointsEarned > 0) {
        batch.update(perf.driverRef, {
          'points': FieldValue.increment(pointsEarned),
        });
        teamPointUpdates[perf.teamRef] =
            (teamPointUpdates[perf.teamRef] ?? 0) + pointsEarned;
      }
    }

    // 6. ECONOMY: Financial Rewards
    const int basePrize = 250000;
    const int pointValue = 150000;
    int playerEarnings = 0;

    // We need to apply prizes to ALL teams based on points earned this race
    for (var teamDoc in teamsSnapshot.docs) {
      final teamRef = teamDoc.reference;
      final team = Team.fromMap(teamDoc.data());
      final racePoints = teamPointUpdates[teamRef] ?? 0;
      final earnings = basePrize + (racePoints * pointValue);

      batch.update(teamRef, {'budget': FieldValue.increment(earnings)});

      // If this is the player's team (not a bot), store earnings to return to UI
      if (!team.isBot) {
        playerEarnings = earnings;
      }
    }

    // Update Team Documents with points
    teamPointUpdates.forEach((ref, pts) {
      batch.update(ref, {'points': FieldValue.increment(pts)});
    });

    // 7. Update Season Calendar
    final updatedCalendar = List<RaceEvent>.from(season.calendar);
    updatedCalendar[raceIndex] = RaceEvent(
      id: currentRace.id,
      trackName: currentRace.trackName,
      countryCode: currentRace.countryCode,
      date: currentRace.date,
      isCompleted: true,
    );

    batch.update(seasonDoc.reference, {
      'calendar': updatedCalendar.map((e) => e.toMap()).toList(),
    });

    // Commit changes
    await batch.commit();

    // 8. Return Results
    return {
      'podium': performances.take(3).map((p) => p.driver).toList(),
      'dnfDrivers': dnfNames,
      'playerEarnings': playerEarnings,
    };
  }
}

class _DriverPerformance {
  final Driver driver;
  final Team team;
  final DocumentReference driverRef;
  final DocumentReference teamRef;
  final double score;
  final bool isDNF;

  _DriverPerformance({
    required this.driver,
    required this.team,
    required this.driverRef,
    required this.teamRef,
    required this.score,
    required this.isDNF,
  });
}
