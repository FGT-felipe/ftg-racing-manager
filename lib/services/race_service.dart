import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';
import '../models/simulation_models.dart';
import '../services/circuit_service.dart';
import '../services/season_service.dart';
import '../services/notification_service.dart';
import '../utils/economy_constants.dart';

class RaceService {
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera un setup aproximado para la IA basado en la calidad del equipo
  CarSetup _generateAISetup(CircuitProfile circuit, Team team) {
    final random = Random();
    final ideal = circuit.idealSetup;

    // Competencia de la IA basada en stats del coche (Aero + Powertrain + Chassis)
    final stats =
        team.carStats['0'] ?? {'aero': 50, 'powertrain': 50, 'chassis': 50};
    double avgStat =
        ((stats['aero'] ?? 50) +
            (stats['powertrain'] ?? 50) +
            (stats['chassis'] ?? 50)) /
        3.0;
    int maxDeviation = ((100 - avgStat) / 4).round().clamp(2, 25);

    int dev() => random.nextInt(maxDeviation * 2 + 1) - maxDeviation;

    return CarSetup(
      frontWing: (ideal.frontWing + dev()).clamp(0, 100),
      rearWing: (ideal.rearWing + dev()).clamp(0, 100),
      suspension: (ideal.suspension + dev()).clamp(0, 100),
      gearRatio: (ideal.gearRatio + dev()).clamp(0, 100),
    );
  }

  Future<QualifyingSessionResult> simulateQualifying({
    required String raceId,
    required String leagueId,
    required RaceEvent currentRace,
    required CircuitProfile circuit,
    required Map<String, Team> teamsMap,
    required Map<String, Driver> driversMap,
    required Map<String, CarSetup> setupsMap,
  }) async {
    List<Map<String, dynamic>> qualyResults = [];

    for (var team in teamsMap.values) {
      // 3. Simular Vueltas para cada piloto
      final teamDrivers = driversMap.values
          .where((d) => d.teamId == team.id)
          .toList();
      for (var driver in teamDrivers) {
        CarSetup driverSetup = CarSetup();
        bool isCrashed = false;
        double lapTime = 0.0;
        String tyreCompoundName = 'medium';
        bool setupSubmitted = false;

        if (team.isBot) {
          driverSetup = _generateAISetup(circuit, team);
          // Simular vuelta
          final result = simulatePracticeRun(
            circuit: circuit,
            team: team,
            driver: driver,
            setup: driverSetup,
            weatherOverride: currentRace.weatherQualifying,
          );
          lapTime = result.lapTime;
          isCrashed = result.isCrashed;
          tyreCompoundName = driverSetup.tyreCompound.name;
        } else {
          // Player Team: Recuperar setup per-driver o usar default
          final driverData = team.weekStatus['driverSetups'] != null
              ? team.weekStatus['driverSetups'][driver.id]
              : null;

          if (driverData != null && driverData['qualifying'] != null) {
            driverSetup = CarSetup.fromMap(
              Map<String, dynamic>.from(driverData['qualifying']),
            );
            setupSubmitted = driverData['qualifyingSubmitted'] == true;
          }

          // Use human manager's manual qualifying sprint if it exists
          if (driverData != null &&
              driverData['qualifyingBestTime'] != null &&
              (driverData['qualifyingBestTime'] as num) > 0) {
            lapTime = (driverData['qualifyingBestTime'] as num).toDouble();
            isCrashed = driverData['qualifyingDnf'] == true;
            tyreCompoundName =
                driverData['qualifyingBestCompound'] as String? ??
                driverSetup.tyreCompound.name;
          } else {
            // Re-simular vuelta si no hay tiempo manual
            final result = simulatePracticeRun(
              circuit: circuit,
              team: team,
              driver: driver,
              setup: driverSetup,
              weatherOverride: currentRace.weatherQualifying,
            );
            lapTime = result.lapTime;
            isCrashed = result.isCrashed;
            tyreCompoundName = driverSetup.tyreCompound.name;
          }
        }

        qualyResults.add({
          'driverId': driver.id,
          'driverName': driver.name,
          'teamName': team.name,
          'lapTime': lapTime,
          'tyreCompound': tyreCompoundName,
          'isCrashed': isCrashed,
          'setupSubmitted': setupSubmitted || team.isBot,
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

    // 7. Increment Pole Stat and update player's weekStatus with best compound
    if (qualyResults.isNotEmpty) {
      final poleDriverId = qualyResults.first['driverId'] as String;

      // Update individual driver and team stats for pole
      final poleDriverDoc = await _db
          .collection('drivers')
          .doc(poleDriverId)
          .get();
      if (poleDriverDoc.exists) {
        await poleDriverDoc.reference.update({
          'poles': FieldValue.increment(1),
        });
        final pTeamId = poleDriverDoc.data()!['teamId'] as String?;
        if (pTeamId != null) {
          await _db.collection('teams').doc(pTeamId).update({
            'poles': FieldValue.increment(1),
          });
        }
      }

      // 8. ECONOMY: Qualifying Prize Payouts (Top 3 positions)
      final Map<String, int> teamQualyPrizes = {};
      for (
        int i = 0;
        i < qualyResults.length && i < kQualyPrizesByPosition.length;
        i++
      ) {
        final dId = qualyResults[i]['driverId'] as String;
        final driver = driversMap[dId];
        if (driver != null && driver.teamId != null) {
          final prize = kQualyPrizesByPosition[i];
          teamQualyPrizes[driver.teamId!] =
              (teamQualyPrizes[driver.teamId!] ?? 0) + prize;
        }
      }

      // Apply qualifying prizes to team budgets and log transactions
      for (var entry in teamQualyPrizes.entries) {
        final tId = entry.key;
        final totalPrize = entry.value;
        await _db.collection('teams').doc(tId).update({
          'budget': FieldValue.increment(totalPrize),
        });

        final txRef = _db
            .collection('teams')
            .doc(tId)
            .collection('transactions')
            .doc();
        await txRef.set({
          'id': txRef.id,
          'description': 'Qualifying Prize Money',
          'amount': totalPrize,
          'date': DateTime.now().toIso8601String(),
          'type': 'QUALIFYING',
        });
      }

      // Update Player's weekStatus with qualifying best compounds
      for (var res in qualyResults) {
        final dId = res['driverId'] as String;
        final compound = res['tyreCompound'] as String;
        final driver = driversMap[dId];
        if (driver != null && driver.teamId != null) {
          final tId = driver.teamId!;
          final team = teamsMap[tId];

          if (team != null && team.isBot != true) {
            final tRef = _db.collection('teams').doc(tId);
            await tRef.update({
              'weekStatus.driverSetups.$dId.qualifyingBestCompound': compound,
            });

            final pos =
                qualyResults.indexWhere((r) => r['driverId'] == dId) + 1;
            final driverName = res['driverName'] as String;

            String qualyMsg =
                "$driverName qualified P$pos for the ${currentRace.trackName}!";
            if (pos <= kQualyPrizesByPosition.length) {
              final driverPrize = kQualyPrizesByPosition[pos - 1];
              qualyMsg +=
                  " Prize: \$${(driverPrize / 1000).toStringAsFixed(0)}k";
            }

            await NotificationService().addNotification(
              teamId: tId,
              title: "Qualifying Finished",
              message: qualyMsg,
              type: 'NEWS',
              actionRoute: '/race_week/garage',
            );
          }
        }
      }
    }

    return QualifyingSessionResult(grid: qualyResults);
  }

  Future<RaceSessionResult> simulateRaceSession({
    required String raceId,
    required String leagueId,
    required RaceEvent currentRace,
    required CircuitProfile circuit,
    required List<Map<String, dynamic>> grid, // [ {driverId, team, setup...} ]
    required Map<String, Team> teamsMap, // id -> Team
    required Map<String, Driver> driversMap, // id -> Driver
    required Map<String, CarSetup> setupsMap, // driverId -> Setup
    bool isDemo = false,
  }) async {
    // This is a placeholder for the full simulation logic.
    // In a real scenario, this would contain the loop over laps, etc.
    return RaceSessionResult(
      raceId: raceId,
      laps: [],
      finalPositions: {},
      totalTimes: {},
      dnfs: [],
    );
  }

  Future<void> chargeActionCost(
    String teamId,
    String description,
    int amount,
    String type,
  ) async {
    await _db.collection('teams').doc(teamId).update({
      'budget': FieldValue.increment(-amount),
    });

    final transactionId = _db
        .collection('teams')
        .doc(teamId)
        .collection('transactions')
        .doc()
        .id;

    await _db
        .collection('teams')
        .doc(teamId)
        .collection('transactions')
        .doc(transactionId)
        .set({
          'id': transactionId,
          'description': description,
          'amount': -amount,
          'date': DateTime.now().toIso8601String(),
          'type': type,
        });
  }

  Future<void> chargeCrashPenalty(String teamId, String driverId) async {
    // -$500k repairs, -$200k medical as per user request
    const int repairCost = 500000;
    const int medicalCost = 200000;
    const int totalPenalty = repairCost + medicalCost;

    await _db.collection('teams').doc(teamId).update({
      'budget': FieldValue.increment(-totalPenalty),
    });

    // Log the transaction
    final transactionId = _db
        .collection('teams')
        .doc(teamId)
        .collection('transactions')
        .doc()
        .id;
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('transactions')
        .doc(transactionId)
        .set({
          'id': transactionId,
          'description':
              'Crash Penalties ($repairCost Repair + $medicalCost Medical)',
          'amount': -totalPenalty,
          'date': DateTime.now().toIso8601String(),
          'type': 'REPAIR',
        });

    // Apply strong fitness penalty (-40 points)
    final driverDoc = await _db.collection('drivers').doc(driverId).get();
    if (driverDoc.exists) {
      final stats = Map<String, int>.from(driverDoc.data()?['stats'] ?? {});
      final currentFitness =
          stats[DriverStats.fitness] ?? stats['fitness'] ?? 100;
      stats['fitness'] = (currentFitness - 40).clamp(0, 100);
      await driverDoc.reference.update({'stats': stats});
    }
  }

  /// Simula una vuelta de práctica para un conductor específico con un setup dado
  PracticeRunResult simulatePracticeRun({
    required CircuitProfile circuit,
    required Team team,
    required Driver driver,
    required CarSetup setup,
    DriverStyle? styleOverride,
    String? weatherOverride,
  }) {
    final random = Random();
    final ideal = circuit.idealSetup;

    // 1. Calcular la desviación del setup (Penalty)
    final stats =
        team.carStats[driver.carIndex.toString()] ??
        {'aero': 1, 'powertrain': 1, 'chassis': 1};

    double aeroBonus = 1.0 - ((stats['aero'] ?? 1).clamp(1, 20) / 40.0);
    double powerBonus = 1.0 - ((stats['powertrain'] ?? 1).clamp(1, 20) / 40.0);
    double chassisBonus = 1.0 - ((stats['chassis'] ?? 1).clamp(1, 20) / 40.0);

    double setupPenalty = 0.0;
    List<String> feedback = [];
    List<String> tyreFeedback = [];

    // Aero Front
    int gapFront = (setup.frontWing - ideal.frontWing);
    double effectiveGapFront = (gapFront.abs() <= 3)
        ? 0
        : (gapFront.abs() - 3).toDouble();
    setupPenalty += effectiveGapFront * 0.03 * aeroBonus;
    if (gapFront > 15) {
      feedback.add(
        "The front end is way too sharp, I'm fighting oversteer in every corner.",
      );
    } else if (gapFront < -15) {
      feedback.add("The car is lazy on entry, we have too much understeer.");
    }

    // Aero Rear
    int gapRear = setup.rearWing - ideal.rearWing;
    double effectiveGapRear = (gapRear.abs() <= 3)
        ? 0
        : (gapRear.abs() - 3).toDouble();
    setupPenalty += effectiveGapRear * 0.03 * aeroBonus;
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
    double effectiveGapSusp = (gapSusp.abs() <= 3)
        ? 0
        : (gapSusp.abs() - 3).toDouble();
    setupPenalty += effectiveGapSusp * 0.02 * chassisBonus;
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
    double effectiveGapGear = (gapGear.abs() <= 3)
        ? 0
        : (gapGear.abs() - 3).toDouble();
    setupPenalty += effectiveGapGear * 0.025 * powerBonus;
    if (gapGear > 15) {
      feedback.add(
        "The gears are too short, I'm hitting the limiter way before the end of the straight.",
      );
    } else if (gapGear < -15) {
      feedback.add(
        "The gear ratios are too long, the acceleration out of slow corners is non-existent.",
      );
    }

    // 2. Calcular Base Lap Time ajustado por el coche y conductor
    double aeroVal = (stats['aero'] ?? 1).toDouble().clamp(1, 20);
    double powerVal = (stats['powertrain'] ?? 1).toDouble().clamp(1, 20);
    double chassisVal = (stats['chassis'] ?? 1).toDouble().clamp(1, 20);

    double weightedStat =
        (aeroVal * circuit.aeroWeight) +
        (powerVal * circuit.powertrainWeight) +
        (chassisVal * circuit.chassisWeight);

    double carPerformanceFactor = 1.0 - ((weightedStat / 20.0) * 0.25);

    final formIsWet =
        weatherOverride?.toLowerCase().contains('rain') == true ||
        weatherOverride?.toLowerCase().contains('wet') == true;

    final braking = (driver.stats[DriverStats.braking] ?? 50) / 100.0;
    final cornering = (driver.stats[DriverStats.cornering] ?? 50) / 100.0;
    final adaptability = (driver.stats[DriverStats.adaptability] ?? 50) / 100.0;
    final focusVal = (driver.stats[DriverStats.focus] ?? 50) / 100.0;
    final morale = (driver.stats[DriverStats.morale] ?? 70) / 100.0;
    final consistency = (driver.stats[DriverStats.consistency] ?? 50) / 100.0;

    double driverFactor =
        1.0 -
        (braking * 0.02 +
            cornering * 0.025 +
            adaptability * 0.015 +
            focusVal * 0.01 +
            (morale - 0.5) * 0.01);

    if (formIsWet && driver.hasTrait(DriverTrait.rainMaster)) {
      driverFactor -= 0.01;
    }

    // --- DRIVER STYLE LOGIC ---
    double styleBonus = 0.0;
    double accidentBaseRisk = 0.0003;

    final effectiveStyle = styleOverride ?? setup.qualifyingStyle;
    switch (effectiveStyle) {
      case DriverStyle.defensive:
        styleBonus = -0.01;
        accidentBaseRisk = 0.0001;
        break;
      case DriverStyle.mostRisky:
        styleBonus = 0.04;
        accidentBaseRisk = 0.002;
        break;
      case DriverStyle.offensive:
        styleBonus = 0.02;
        accidentBaseRisk = 0.001;
        break;
      case DriverStyle.normal:
        styleBonus = 0.0;
        accidentBaseRisk = 0.0003;
        break;
    }

    double driverRiskFactor =
        (1.0 - focusVal) * 0.5 +
        (1.0 - consistency) * 0.3 +
        (1.0 - morale) * 0.2;
    double totalAccidentProb = accidentBaseRisk + (driverRiskFactor * 0.001);

    bool hasCrashed = random.nextDouble() < totalAccidentProb;
    driverFactor -= styleBonus;

    double actualLapTime =
        circuit.baseLapTime * carPerformanceFactor * driverFactor;

    double tyreDelta = 0.0;
    if (formIsWet) {
      if (setup.tyreCompound == TyreCompound.wet) {
        tyreDelta = -0.3;
        tyreFeedback.add("The wet tyres are working well in this rain.");
      } else {
        tyreDelta = 8.0;
        tyreFeedback.add("I have zero grip! We need wet tyres immediately!");
        setupPenalty += 5.0;
      }
    } else {
      switch (setup.tyreCompound) {
        case TyreCompound.soft:
          tyreDelta = -0.5;
          break;
        case TyreCompound.medium:
          tyreDelta = -0.3;
          break;
        case TyreCompound.hard:
          tyreDelta = -0.1;
          break;
        case TyreCompound.wet:
          tyreDelta = 3.0;
          setupPenalty += 2.0;
          break;
      }
    }

    actualLapTime += tyreDelta + setupPenalty;
    double stabilityFactor = (consistency * 0.7 + focusVal * 0.3);
    double randomVariation =
        (random.nextDouble() - 0.5) * 1.2 * (1.0 - stabilityFactor);
    actualLapTime += randomVariation;

    double totalGap =
        (gapFront.abs() + gapRear.abs() + gapSusp.abs() + gapGear.abs())
            .toDouble();
    double confidence = (1.0 - (totalGap / 100.0)).clamp(0.0, 1.0);

    return PracticeRunResult(
      lapTime: hasCrashed ? 999.0 : actualLapTime,
      driverFeedback: feedback,
      tyreFeedback: tyreFeedback,
      setupConfidence: confidence,
      setupUsed: setup,
      isCrashed: hasCrashed,
    );
  }

  Future<void> simulateNextRace(String seasonId) async {
    // 1. Fetch data
    final seasonDoc = await _db.collection('seasons').doc(seasonId).get();
    if (!seasonDoc.exists) {
      throw Exception("Season not found");
    }
    final season = Season.fromMap(seasonDoc.data()!);

    final current = SeasonService().getCurrentRace(season);
    if (current == null) {
      throw Exception("No pending races");
    }
    final currentRace = current.event;
    final circuit = CircuitService().getCircuitProfile(currentRace.circuitId);

    // Fetch all related entities for simulation
    final teamsSubset = await _db
        .collection('teams')
        .where('leagueId', isEqualTo: season.leagueId)
        .get();
    final driversSubset = await _db
        .collection('drivers')
        .where('leagueId', isEqualTo: season.leagueId)
        .get();

    final Map<String, Team> leagueTeamsMap = {
      for (var doc in teamsSubset.docs) doc.id: Team.fromMap(doc.data()),
    };
    final Map<String, Driver> leagueDriversMap = {
      for (var doc in driversSubset.docs) doc.id: Driver.fromMap(doc.data()),
    };
    final Map<String, CarSetup> leagueSetupsMap =
        {}; // Populated normally from team data

    // 2. Qualifying
    final qualyResult = await simulateQualifying(
      raceId: currentRace.id,
      leagueId: season.leagueId,
      currentRace: currentRace,
      circuit: circuit,
      teamsMap: leagueTeamsMap,
      driversMap: leagueDriversMap,
      setupsMap: leagueSetupsMap,
    );

    // 3. Race
    final raceResult = await simulateRaceSession(
      raceId: currentRace.id,
      leagueId: season.leagueId,
      currentRace: currentRace,
      circuit: circuit,
      grid: qualyResult.grid,
      teamsMap: leagueTeamsMap,
      driversMap: leagueDriversMap,
      setupsMap: leagueSetupsMap,
    );

    // 4. Update Stats & Standings (Placeholder)
    await applyRaceResults(
      seasonId: seasonId,
      leagueId: season.leagueId,
      raceResult: raceResult,
      teamsMap: leagueTeamsMap,
      driversMap: leagueDriversMap,
    );
  }

  Future<Map<String, dynamic>> applyRaceResults({
    required String seasonId,
    required String leagueId,
    required RaceSessionResult raceResult,
    required Map<String, Team> teamsMap,
    required Map<String, Driver> driversMap,
  }) async {
    // Basic implementation for now to satisfy UI
    return {'playerEarnings': 0};
  }
}
