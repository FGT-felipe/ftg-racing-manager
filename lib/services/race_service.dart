import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';
import '../models/simulation_models.dart';
import '../services/circuit_service.dart';
import '../services/season_service.dart';

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
    // 1. Obtener temporada y carrera actual
    final seasonDoc = await _db.collection('seasons').doc(seasonId).get();
    if (!seasonDoc.exists) throw Exception("Season not found");
    final season = Season.fromMap(seasonDoc.data()!);

    final current = SeasonService().getCurrentRace(season);
    if (current == null) throw Exception("No pending races");
    final currentRace = current.event;

    final circuit = CircuitService().getCircuitProfile(currentRace.circuitId);

    final raceId = await SeasonService().getOrCreateRaceDocument(
      seasonId,
      currentRace,
    );

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

    // 6. Guardar parrilla en races/{raceId}
    await SeasonService().saveQualifyingGrid(raceId, qualyResults);

    // 7. Increment Pole Stat for the winner
    if (qualyResults.isNotEmpty) {
      final poleDriverId = qualyResults.first['driverId'] as String;
      // We need the reference. This is a bit tricky since we don't have it here easily.
      // But we can find which team is it from qualyResults or just run a query.
      final teams = await _db.collection('teams').get();
      for (var tDoc in teams.docs) {
        final dDoc = await tDoc.reference
            .collection('drivers')
            .doc(poleDriverId)
            .get();
        if (dDoc.exists) {
          await dDoc.reference.update({'poles': FieldValue.increment(1)});
          await tDoc.reference.update({'poles': FieldValue.increment(1)});
          break;
        }
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
    setupPenalty += gapFront.abs() * 0.04; // Slightly reduced from 0.05
    if (gapFront > 15) {
      feedback.add(
        "The front end is way too sharp, I'm fighting oversteer in every corner.",
      );
    } else if (gapFront < -15) {
      feedback.add("The car is lazy on entry, we have too much understeer.");
    }

    // Aero Rear
    int gapRear = setup.rearWing - ideal.rearWing;
    setupPenalty += gapRear.abs() * 0.04;
    if (gapRear > 15) {
      feedback.add(
        "We're slow on the straights, feels like we have a parachute attached.",
      );
    } else if (gapRear < -15) {
      feedback.add(
        "The rear is very nervous. I can't put the power down without losing it.",
      );
    }

    // Suspension
    int gapSusp = setup.suspension - ideal.suspension;
    setupPenalty += gapSusp.abs() * 0.025;
    if (gapSusp > 15) {
      feedback.add(
        "The car is too stiff, it's bouncing like crazy over the kerbs.",
      );
    } else if (gapSusp < -15) {
      feedback.add(
        "The suspension feels like jelly, the car is rolling too much in the turns.",
      );
    }

    // Gear Ratio
    int gapGear = setup.gearRatio - ideal.gearRatio;
    setupPenalty += gapGear.abs() * 0.035;
    if (gapGear > 15) {
      feedback.add(
        "The gears are too short, I'm hitting the limiter way before the end of the straight.",
      );
    } else if (gapGear < -15) {
      feedback.add(
        "The gear ratios are too long, the acceleration out of slow corners is non-existent.",
      );
    }

    // Tyre Pressure
    int gapTyre = setup.tyrePressure - ideal.tyrePressure;
    setupPenalty += gapTyre.abs() * 0.02;
    if (gapTyre > 10) {
      feedback.add(
        "Tyre pressures are too high, they're overheating and losing grip after three corners.",
      );
    } else if (gapTyre < -10) {
      feedback.add(
        "I can't get any heat into the tyres, they feel stone cold.",
      );
    }

    // 2. Calcular Base Lap Time ajustado por el coche y conductor
    // Car Score: Quality levels 1-20.
    double aeroVal = (team.carStats['aero'] ?? 1).toDouble().clamp(1, 20);
    double engineVal = (team.carStats['engine'] ?? 1).toDouble().clamp(1, 20);

    // Performance factor impact increased to 20% (0.20) to make car quality much more significant.
    // Level 20 = 0.80 factor, Level 1 = 0.99 factor approx.
    double carPerformanceFactor = 1.0 - (((aeroVal + engineVal) / 40.0) * 0.20);

    // Driver Score
    double driverFactor =
        1.0 -
        (((driver.stats['speed'] ?? 50) + (driver.stats['cornering'] ?? 50)) /
            200.0 *
            0.05);

    double actualLapTime =
        circuit.baseLapTime * carPerformanceFactor * driverFactor;

    // Add Setup Penalty
    actualLapTime += setupPenalty;

    // Add Randomness (Driver consistency)
    double consistency = (driver.stats['consistency'] ?? 50) / 100.0;
    double randomVariation =
        (random.nextDouble() - 0.5) *
        1.2 * // Slightly reduced random swing
        (1.0 - consistency);
    actualLapTime += randomVariation;

    // 3. Calcular Setup Confidence
    double totalGap =
        (gapFront.abs() +
                gapRear.abs() +
                gapSusp.abs() +
                gapGear.abs() +
                gapTyre.abs())
            .toDouble();
    double confidence = (1.0 - (totalGap / 120.0)).clamp(0.0, 1.0);

    if (feedback.isEmpty) {
      if (confidence > 0.98) {
        feedback.add(
          "The balance is spot on! I wouldn't change a single thing.",
        );
      } else if (confidence > 0.92) {
        feedback.add(
          "The car feels excellent, only very minor tweaks could improve it.",
        );
      } else {
        // Find the part with the largest remaining gap
        Map<String, int> gaps = {
          "front wing": gapFront,
          "rear wing": gapRear,
          "suspension": gapSusp,
          "gearing": gapGear,
          "tyre pressures": gapTyre,
        };

        String worstPart = "";
        int maxAbsGap = 0;
        gaps.forEach((key, val) {
          if (val.abs() > maxAbsGap) {
            maxAbsGap = val.abs();
            worstPart = key;
          }
        });

        int gapValue = gaps[worstPart]!;
        if (gapValue > 5) {
          feedback.add(
            "I still feel $worstPart is a bit too high for this track.",
          );
        } else if (gapValue < -5) {
          feedback.add(
            "I think we could gain time by increasing the $worstPart.",
          );
        } else {
          feedback.add(
            "The setup is okay, but I feel there is still more potential in the car.",
          );
        }
      }
    }

    return PracticeRunResult(
      lapTime: actualLapTime,
      driverFeedback: feedback,
      setupConfidence: confidence,
      setupUsed: setup,
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

      if (pointsEarned > 0 || !perf.isDNF) {
        Map<String, dynamic> driverUpdates = {'races': FieldValue.increment(1)};
        if (pointsEarned > 0)
          driverUpdates['points'] = FieldValue.increment(pointsEarned);
        if (i == 0 && !perf.isDNF)
          driverUpdates['wins'] = FieldValue.increment(1);
        if (i < 3 && !perf.isDNF)
          driverUpdates['podiums'] = FieldValue.increment(1);

        batch.update(perf.driverRef, driverUpdates);

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

    // Update Team Documents with points and participation stats
    for (var teamRef in teamPointUpdates.keys) {
      int pts = teamPointUpdates[teamRef]!;
      Map<String, dynamic> teamUpdates = {
        'points': FieldValue.increment(pts),
        'races': FieldValue.increment(1),
      };

      // Check if team had a winner or podiums in this simulated race
      bool teamWon = false;
      int teamPodiums = 0;
      for (int i = 0; i < performances.length; i++) {
        if (performances[i].teamRef == teamRef) {
          if (i == 0 && !performances[i].isDNF) teamWon = true;
          if (i < 3 && !performances[i].isDNF) teamPodiums++;
        }
      }
      if (teamWon) teamUpdates['wins'] = FieldValue.increment(1);
      if (teamPodiums > 0)
        teamUpdates['podiums'] = FieldValue.increment(teamPodiums);

      batch.update(teamRef, teamUpdates);
    }

    // 7. Update Season Calendar
    final updatedCalendar = List<RaceEvent>.from(season.calendar);
    updatedCalendar[raceIndex] = RaceEvent(
      id: currentRace.id,
      trackName: currentRace.trackName,
      countryCode: currentRace.countryCode,
      date: currentRace.date,
      circuitId: currentRace.circuitId,
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

  /// Aplica los resultados de una sesión de carrera (RaceSessionResult) a la temporada:
  /// - Actualiza puntos de pilotos y equipos.
  /// - Actualiza presupuesto (premios).
  /// - Mejora IA (opcional).
  /// - Actualiza calendario (marca carrera como completada).
  Future<Map<String, dynamic>> applyRaceResults(
    String seasonId,
    RaceSessionResult result,
  ) async {
    final seasonDoc = await _db.collection('seasons').doc(seasonId).get();
    if (!seasonDoc.exists) throw Exception("Season not found");
    final season = Season.fromMap(seasonDoc.data()!);

    // Identify current race index based on UNCOMPLETED races
    final raceIndex = season.calendar.indexWhere((r) => !r.isCompleted);
    if (raceIndex == -1)
      throw Exception("No pending races to apply results to");
    final currentRace = season.calendar[raceIndex];

    final batch = _db.batch();
    final pointSystem = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
    final random = Random();

    // 1. Fetch all teams/drivers to update them
    final teamsSnapshot = await _db.collection('teams').get();
    Map<String, Team> teamsMap = {};
    // Map driverId -> DocumentReference needed for points update
    Map<String, DocumentReference> driverRefs = {};
    Map<String, String> driverTeamIds = {};
    int playerEarnings = 0;

    for (var teamDoc in teamsSnapshot.docs) {
      final team = Team.fromMap(teamDoc.data());
      teamsMap[team.id] = team;

      // AI Upgrades (Logic from simulateNextRace)
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
      for (var dDoc in driversSnapshot.docs) {
        driverRefs[dDoc.id] = dDoc.reference;
        driverTeamIds[dDoc.id] = team.id;
      }
    }

    // 2. Process Results
    Map<String, int> teamPointUpdates = {}; // teamId -> new points to add

    // Get sorted list of driverIds based on finalPositions (1st place = 1)
    List<String> sortedDriverIds = result.finalPositions.keys.toList();
    sortedDriverIds.sort(
      (a, b) => (result.finalPositions[a] ?? 999).compareTo(
        result.finalPositions[b] ?? 999,
      ),
    );

    // Filter out DNFs from points?
    // Usually DNFs are at the bottom anyway if sorted by position,
    // but position mapping should handle it (e.g. DNF = 20).
    // Let's assume finalPositions are valid 1..N.

    for (int i = 0; i < sortedDriverIds.length; i++) {
      final driverId = sortedDriverIds[i];
      if (result.dnfs.contains(driverId)) continue;

      // Points for top 10 (i=0 is 1st place)
      int points = (i < pointSystem.length) ? pointSystem[i] : 0;
      bool isWin = i == 0;
      bool isPodium = i < 3;

      // Update Driver Stats
      if (driverRefs.containsKey(driverId)) {
        Map<String, dynamic> driverUpdates = {'races': FieldValue.increment(1)};
        if (points > 0) driverUpdates['points'] = FieldValue.increment(points);
        if (isWin) driverUpdates['wins'] = FieldValue.increment(1);
        if (isPodium) driverUpdates['podiums'] = FieldValue.increment(1);

        batch.update(driverRefs[driverId]!, driverUpdates);
      }

      // Accumulate Team Stats
      final tId = driverTeamIds[driverId];
      if (tId != null) {
        teamPointUpdates[tId] = (teamPointUpdates[tId] ?? 0) + points;
        // We will apply races/wins/podiums to teams in the next loop to avoid duplicate increments
        // if both drivers get a podium (though only 1 win is possible per race,
        // but multiple drivers can contribute to 'races' and 'podiums').
      }
    }

    // 3. Update Team Stats and Budget
    const int basePrize = 250000;
    const int pointValue = 150000;

    for (var teamId in teamsMap.keys) {
      final earnedPoints = teamPointUpdates[teamId] ?? 0;
      final earnings = basePrize + (earnedPoints * pointValue);
      final team = teamsMap[teamId]!;

      final teamRef = _db.collection('teams').doc(teamId);

      Map<String, dynamic> updates = {
        'budget': FieldValue.increment(earnings),
        'races': FieldValue.increment(
          1,
        ), // Assume team participated if at least one driver did
      };

      if (earnedPoints > 0) {
        updates['points'] = FieldValue.increment(earnedPoints);
      }

      // Determine if team got a win or podium in this race
      bool teamWon = false;
      int teamPodiums = 0;
      for (int i = 0; i < sortedDriverIds.length; i++) {
        if (driverTeamIds[sortedDriverIds[i]] == teamId) {
          if (i == 0) teamWon = true;
          if (i < 3) teamPodiums++;
        }
      }
      if (teamWon) updates['wins'] = FieldValue.increment(1);
      if (teamPodiums > 0)
        updates['podiums'] = FieldValue.increment(teamPodiums);

      // Reset week status
      updates['weekStatus'] = {
        'practiceCompleted': false,
        'strategySet': false,
        'sponsorReviewed': false,
        // Preserve structure if needed, but clearing flags is key
      };

      batch.update(teamRef, updates);

      if (!team.isBot) {
        playerEarnings = earnings;
      }
    }

    // 4. Update Calendar
    final updatedCalendar = List<RaceEvent>.from(season.calendar);
    updatedCalendar[raceIndex] = RaceEvent(
      id: currentRace.id,
      trackName: currentRace.trackName,
      countryCode: currentRace.countryCode,
      date: currentRace.date,
      circuitId: currentRace.circuitId, // Preserve circuitId
      isCompleted: true,
    );

    batch.update(seasonDoc.reference, {
      'calendar': updatedCalendar.map((e) => e.toMap()).toList(),
    });

    // 5. Commit
    await batch.commit();

    return {
      'playerEarnings': playerEarnings,
      'pointsAwarded': teamPointUpdates,
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
