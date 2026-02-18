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
      // 3. Simular Vueltas para cada piloto
      final driversSnapshot = await _db
          .collection('drivers')
          .where('teamId', isEqualTo: team.id)
          .get();
      for (var i = 0; i < driversSnapshot.docs.length; i++) {
        final driverDoc = driversSnapshot.docs[i];
        final driver = Driver.fromMap({...driverDoc.data(), 'carIndex': i});

        CarSetup driverSetup;
        if (team.isBot) {
          driverSetup = _generateAISetup(circuit, team);
        } else {
          // Player Team: Recuperar setup per-driver o usar default
          final driverData = team.weekStatus['driverSetups'] != null
              ? team.weekStatus['driverSetups'][driver.id]
              : null;

          if (driverData != null && driverData['qualifying'] != null) {
            driverSetup = CarSetup.fromMap(
              Map<String, dynamic>.from(driverData['qualifying']),
            );
          } else {
            driverSetup = CarSetup();
          }
        }

        // Simular vuelta
        final result = simulatePracticeRun(
          circuit: circuit,
          team: team,
          driver: driver,
          setup: driverSetup,
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
        final dDoc = await _db.collection('drivers').doc(poleDriverId).get();
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
    // Penalties are reduced by the quality of the corresponding macro-part.
    // Level 20 reduces setup penalty impact by 50%.
    final stats =
        team.carStats[driver.carIndex.toString()] ??
        {'aero': 1, 'powertrain': 1, 'chassis': 1};

    double aeroBonus = 1.0 - ((stats['aero'] ?? 1).clamp(1, 20) / 40.0);
    double powerBonus = 1.0 - ((stats['powertrain'] ?? 1).clamp(1, 20) / 40.0);
    double chassisBonus = 1.0 - ((stats['chassis'] ?? 1).clamp(1, 20) / 40.0);

    double setupPenalty = 0.0;
    List<String> feedback = [];

    // Aero Front
    int gapFront = setup.frontWing - ideal.frontWing;
    setupPenalty += gapFront.abs() * 0.04 * aeroBonus;
    if (gapFront > 15) {
      feedback.add(
        "The front end is way too sharp, I'm fighting oversteer in every corner.",
      );
    } else if (gapFront < -15) {
      feedback.add("The car is lazy on entry, we have too much understeer.");
    }

    // Aero Rear
    int gapRear = setup.rearWing - ideal.rearWing;
    setupPenalty += gapRear.abs() * 0.04 * aeroBonus;
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
    setupPenalty += gapSusp.abs() * 0.025 * chassisBonus;
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
    setupPenalty += gapGear.abs() * 0.035 * powerBonus;
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
    setupPenalty += gapTyre.abs() * 0.02 * chassisBonus;
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
    double aeroVal = (stats['aero'] ?? 1).toDouble().clamp(1, 20);
    double powerVal = (stats['powertrain'] ?? 1).toDouble().clamp(1, 20);
    double chassisVal = (stats['chassis'] ?? 1).toDouble().clamp(1, 20);

    // Performance factor logic using circuit weights
    double weightedStat =
        (aeroVal * circuit.aeroWeight) +
        (powerVal * circuit.powertrainWeight) +
        (chassisVal * circuit.chassisWeight);

    // Weighted stat max is 20 if all stats are 20 and weights sum to 1.0.
    // Factor impact is 25% (0.25)
    double carPerformanceFactor = 1.0 - ((weightedStat / 20.0) * 0.25);

    // Determinar condiciones de lluvia (necesario antes del driver factor)
    final bool formIsWet =
        circuit.characteristics.containsKey('Weather') &&
        circuit.characteristics['Weather']!.contains('Rain');

    // --- DRIVER PERFORMANCE (New 11-stat model) ---
    // Braking: qué tan tarde frena (reduce tiempo en curvas)
    final braking = (driver.stats[DriverStats.braking] ?? 50) / 100.0;
    // Cornering: velocidad de paso por curva
    final cornering = (driver.stats[DriverStats.cornering] ?? 50) / 100.0;
    // Adaptability: ajuste al circuito y condiciones
    final adaptability = (driver.stats[DriverStats.adaptability] ?? 50) / 100.0;
    // Focus: reduce errores bajo presión
    final focus = (driver.stats[DriverStats.focus] ?? 50) / 100.0;
    // Morale: impacto en rendimiento general
    final morale = (driver.stats[DriverStats.morale] ?? 70) / 100.0;

    // Combinación ponderada de stats de conducción (impacto total: 8%)
    double driverFactor =
        1.0 -
        (braking * 0.02 +
            cornering * 0.025 +
            adaptability * 0.015 +
            focus * 0.01 +
            (morale - 0.5) * 0.01); // Morale: -0.5% a +0.5%

    // Rasgo: Maestro de la Lluvia en condiciones húmedas
    if (formIsWet && driver.hasTrait(DriverTrait.rainMaster)) {
      driverFactor -= 0.01; // Bonus adicional en lluvia
    }

    double actualLapTime =
        circuit.baseLapTime * carPerformanceFactor * driverFactor;

    // --- TYRE LOGIC ---
    // User Request:
    // Soft: +5 speed (approx -0.5s on lap time)
    // Medium: +3 speed (approx -0.3s)
    // Hard: +1 speed (approx -0.1s)
    // Wet: +3 speed in wet (approx -0.3s in wet), but huge penalty in dry.

    // For now assuming DRY conditions unless circuit says otherwise.
    double tyreDelta = 0.0;

    if (formIsWet) {
      // WET CONDITIONS
      switch (setup.tyreCompound) {
        case TyreCompound.wet:
          tyreDelta = -0.3; // Proper tyre for conditions
          feedback.add("The wet tyres are working well in this rain.");
          break;
        default:
          // Dry tyres in wet -> DISASTER
          tyreDelta = 8.0;
          feedback.add("I have zero grip! We need wet tyres immediately!");
          setupPenalty += 5.0; // Extra penalty to setup confidence
          break;
      }
    } else {
      // DRY CONDITIONS (Default)
      switch (setup.tyreCompound) {
        case TyreCompound.soft:
          tyreDelta = -0.5;
          feedback.add("Softs feel grippy and fast.");
          break;
        case TyreCompound.medium:
          tyreDelta = -0.3;
          feedback.add("Mediums are a good balance.");
          break;
        case TyreCompound.hard:
          tyreDelta = -0.1;
          feedback.add("Hards are a bit slow but durable.");
          break;
        case TyreCompound.wet:
          // Wet tyres in dry -> DISASTER penalty
          tyreDelta = 3.0;
          feedback.add(
            "Why are we on wets? The track is dry! I'm burning these up!",
          );
          setupPenalty += 2.0;
          break;
      }
    }

    actualLapTime += tyreDelta;

    // --- TYRE WEAR LOGIC ---
    double circuitWearFactor = circuit.tyreWearMultiplier;

    // Compound wear factors (Relative)
    double compoundWearMod = 1.0;
    switch (setup.tyreCompound) {
      case TyreCompound.soft:
        compoundWearMod = 1.5; // High wear
        break;
      case TyreCompound.medium:
        compoundWearMod = 1.0; // Normal wear
        break;
      case TyreCompound.hard:
        compoundWearMod = 0.7; // Low wear
        break;
      case TyreCompound.wet:
        compoundWearMod = formIsWet ? 0.8 : 4.0; // Destroyed in dry
        break;
    }

    // Smoothness reduce el desgaste de neumáticos
    // 100 smoothness = 30% menos desgaste; 0 smoothness = 20% más desgaste
    final smoothness = (driver.stats[DriverStats.smoothness] ?? 50) / 100.0;
    final smoothnessMod = 1.0 - ((smoothness - 0.5) * 0.5); // 0.75 to 1.25

    // Rasgo: Cuidador de Neumáticos reduce desgaste un 15%
    final tyreSaverMod = driver.hasTrait(DriverTrait.tyreSaver) ? 0.85 : 1.0;

    double wearIntensity =
        circuitWearFactor * compoundWearMod * smoothnessMod * tyreSaverMod;

    if (wearIntensity > 1.8) {
      if (!formIsWet) {
        feedback.add(
          "I'm struggling with high degradation. These tyres won't last long here.",
        );
      }
      actualLapTime += 0.2;
    } else if (wearIntensity < 0.8) {
      if (!formIsWet) {
        feedback.add(
          "Tyre wear is non-existent. We could probably push harder or use softer compounds.",
        );
      }
    }

    // Add Setup Penalty
    actualLapTime += setupPenalty;

    // Add Randomness (Driver consistency + focus)
    // Smoothness reduce el desgaste de neumáticos (ya aplicado arriba)
    // Consistency reduce la variabilidad de tiempos
    double consistency = (driver.stats[DriverStats.consistency] ?? 50) / 100.0;
    double focusVal = (driver.stats[DriverStats.focus] ?? 50) / 100.0;
    // Combinamos consistency y focus para reducir variabilidad
    double stabilityFactor = (consistency * 0.7 + focusVal * 0.3);
    double randomVariation =
        (random.nextDouble() - 0.5) * 1.2 * (1.0 - stabilityFactor);
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
    int totalLaps = circuit.laps;

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
        // Fuel consumption affects how much time is gained as fuel is burned
        lapTime -= (lap * 0.05 * circuit.fuelConsumptionMultiplier);

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
          // Add Wear based on circuit factor
          tyreWear[driverId] =
              wear + (3.0 * circuit.tyreWearMultiplier) + random.nextDouble();
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
    final circuit = CircuitService().getCircuitProfile(currentRace.circuitId);

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
        final newStats = Map<String, Map<String, int>>.from(team.carStats);
        for (var carKey in ['0', '1']) {
          final stats = Map<String, int>.from(newStats[carKey] ?? {});
          if (random.nextInt(100) < 30) {
            stats['aero'] = (stats['aero'] ?? 1) + 1;
            upgraded = true;
          }
          if (random.nextInt(100) < 30) {
            stats['powertrain'] = (stats['powertrain'] ?? 1) + 1;
            upgraded = true;
          }
          if (random.nextInt(100) < 30) {
            stats['chassis'] = (stats['chassis'] ?? 1) + 1;
            upgraded = true;
          }
          newStats[carKey] = stats;
        }
        if (upgraded) {
          batch.update(teamDoc.reference, {'carStats': newStats});
        }
      }

      final driversSnapshot = await _db
          .collection('drivers')
          .where('teamId', isEqualTo: team.id)
          .get();

      for (var driverDoc in driversSnapshot.docs) {
        final driver = Driver.fromMap(driverDoc.data());

        // 3. Reliability Check (DNF) - Smoothed formula
        final stats =
            team.carStats[driver.carIndex.toString()] ?? {'reliability': 50};
        final reliability = (stats['reliability'] ?? 50).toDouble();
        final double failureChance = (100.0 - reliability) * 0.25;
        final double roll = random.nextDouble() * 100;

        double score = 0;
        bool isDNF = roll < failureChance;

        if (isDNF) {
          dnfNames.add("${driver.name} (${team.name})");
          score = 0;
        } else {
          // 4. Calculate Performance using new 11-stat model
          final carS =
              team.carStats[driver.carIndex.toString()] ??
              {'aero': 1, 'powertrain': 1, 'chassis': 1};

          // Driving stats contribution
          final drivingScore =
              (driver.stats[DriverStats.braking] ?? 50) * 0.18 +
              (driver.stats[DriverStats.cornering] ?? 50) * 0.20 +
              (driver.stats[DriverStats.overtaking] ?? 50) * 0.15 +
              (driver.stats[DriverStats.consistency] ?? 50) * 0.12 +
              (driver.stats[DriverStats.smoothness] ?? 50) * 0.10 +
              (driver.stats[DriverStats.adaptability] ?? 50) * 0.08;

          // Mental stats contribution
          final mentalScore =
              (driver.stats[DriverStats.fitness] ?? 50) * 0.10 +
              (driver.stats[DriverStats.focus] ?? 50) * 0.07;

          // Morale bonus/penalty
          final moraleBonus =
              ((driver.stats[DriverStats.morale] ?? 70) - 50) * 0.1;

          // Car contribution
          final carScore =
              ((carS['aero'] ?? 1) * 3).toDouble() +
              ((carS['powertrain'] ?? 1) * 3).toDouble() +
              ((carS['chassis'] ?? 1) * 3).toDouble();

          score =
              drivingScore +
              mentalScore +
              moraleBonus +
              carScore +
              random.nextInt(26).toDouble();

          // Trait bonuses
          if (driver.hasTrait(DriverTrait.firstLapHero)) score += 2.0;
          if (driver.hasTrait(DriverTrait.aggressive)) score += 1.5;
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
        if (pointsEarned > 0) {
          driverUpdates['points'] = FieldValue.increment(pointsEarned);
        }
        if (i == 0 && !perf.isDNF) {
          driverUpdates['wins'] = FieldValue.increment(1);
        }
        if (i < 3 && !perf.isDNF) {
          driverUpdates['podiums'] = FieldValue.increment(1);
        }

        // Aplicar XP post-carrera y declive por edad
        final xpUpdates = _calculatePostRaceStatChanges(
          driver: perf.driver,
          finalPosition: i + 1,
          totalDrivers: performances.length,
          totalLaps: circuit.laps,
          overtakesCompleted: random.nextInt(5), // Estimación para bot
          facilitiesMultiplier: 1.0, // Sin instalaciones para bot
        );
        if (xpUpdates.isNotEmpty) {
          driverUpdates['stats'] = xpUpdates;
        }

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
        'seasonPoints': FieldValue.increment(pts),
        'seasonRaces': FieldValue.increment(1),
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
      if (teamWon) {
        teamUpdates['wins'] = FieldValue.increment(1);
        teamUpdates['seasonWins'] = FieldValue.increment(1);
      }
      if (teamPodiums > 0) {
        teamUpdates['podiums'] = FieldValue.increment(teamPodiums);
        teamUpdates['seasonPodiums'] = FieldValue.increment(teamPodiums);
      }

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
    if (raceIndex == -1) {
      throw Exception("No pending races to apply results to");
    }
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
        final newStats = Map<String, Map<String, int>>.from(team.carStats);
        for (var carKey in ['0', '1']) {
          final stats = Map<String, int>.from(newStats[carKey] ?? {});
          if (random.nextInt(100) < 30) {
            stats['aero'] = (stats['aero'] ?? 1) + 1;
            upgraded = true;
          }
          if (random.nextInt(100) < 30) {
            stats['powertrain'] = (stats['powertrain'] ?? 1) + 1;
            upgraded = true;
          }
          if (random.nextInt(100) < 30) {
            stats['chassis'] = (stats['chassis'] ?? 1) + 1;
            upgraded = true;
          }
          newStats[carKey] = stats;
        }
        if (upgraded) {
          batch.update(teamDoc.reference, {'carStats': newStats});
        }
      }

      final driversSnapshot = await _db
          .collection('drivers')
          .where('teamId', isEqualTo: team.id)
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
        Map<String, dynamic> driverUpdates = {
          'races': FieldValue.increment(1),
          'seasonRaces': FieldValue.increment(1),
        };
        if (points > 0) {
          driverUpdates['points'] = FieldValue.increment(points);
          driverUpdates['seasonPoints'] = FieldValue.increment(points);
        }
        if (isWin) {
          driverUpdates['wins'] = FieldValue.increment(1);
          driverUpdates['seasonWins'] = FieldValue.increment(1);
        }
        if (isPodium) {
          driverUpdates['podiums'] = FieldValue.increment(1);
          driverUpdates['seasonPodiums'] = FieldValue.increment(1);
        }

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
        updates['seasonPoints'] = FieldValue.increment(earnedPoints);
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
      if (teamWon) {
        updates['wins'] = FieldValue.increment(1);
        updates['seasonWins'] = FieldValue.increment(1);
      }
      if (teamPodiums > 0) {
        updates['podiums'] = FieldValue.increment(teamPodiums);
        updates['seasonPodiums'] = FieldValue.increment(teamPodiums);
      }

      // Reset week status
      updates['weekStatus'] = {
        'practiceCompleted': false,
        'strategySet': false,
        'sponsorReviewed': false,
        'hasUpgradedThisWeek': false,
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

  /// Calcula los cambios de stats post-carrera para un piloto.
  ///
  /// Implementa la fórmula:
  /// Nueva_Habilidad = Habilidad_Actual + (Puntos_Entrenamiento * Multiplicador_Instalaciones * Multiplicador_Edad)
  ///
  /// Retorna un mapa con los nuevos valores de stats (solo los que cambian).
  /// Si no hay cambios, retorna un mapa vacío.
  Map<String, int> _calculatePostRaceStatChanges({
    required Driver driver,
    required int finalPosition,
    required int totalDrivers,
    required int totalLaps,
    required int overtakesCompleted,
    required double
    facilitiesMultiplier, // 1.0 = sin instalaciones, 1.5 = instalaciones élite
  }) {
    final currentStats = Map<String, int>.from(driver.stats);
    final newStats = Map<String, int>.from(currentStats);
    bool hasChanges = false;

    // --- Multiplicador de Edad ---
    // < 22: aprenden rápido (1.5x)
    // 22-35: prime (1.0x)
    // > 35: declive para stats físicos
    final age = driver.age;
    double ageMultiplier;
    if (age < 22) {
      ageMultiplier = 1.5;
    } else if (age <= 35) {
      ageMultiplier = 1.0;
    } else {
      ageMultiplier = 0.5;
    }

    // Rasgo: Joven Prodigio aumenta velocidad de aprendizaje
    if (driver.hasTrait(DriverTrait.youngProdigy) && age < 23) {
      ageMultiplier *= 1.2;
    }

    // --- Puntos de Entrenamiento base ---
    // Posición final: ganador obtiene más XP (éxito)
    final positionRatio = 1.0 - ((finalPosition - 1) / totalDrivers.toDouble());
    final positionBonus = positionRatio * 2.0; // 0.0 a 2.0 puntos

    // Vueltas completadas: resistencia
    final lapsBonus = (totalLaps / 100.0).clamp(0.3, 1.0);

    // Total de puntos de entrenamiento base
    final baseXp = positionBonus + lapsBonus;

    // --- Aplicar XP a stats de conducción ---
    for (final statKey in DriverStats.drivingStats) {
      final current = currentStats[statKey] ?? 50;
      final maxPotential = driver.getStatPotential(statKey);

      // Si ya alcanzó el techo, no mejora
      if (current >= maxPotential) continue;

      // Bonus especial para overtaking si hizo maniobras
      double statXp = baseXp;
      if (statKey == DriverStats.overtaking) {
        statXp += overtakesCompleted * 0.3;
      }

      final gain = (statXp * facilitiesMultiplier * ageMultiplier).round();
      if (gain > 0) {
        newStats[statKey] = (current + gain).clamp(0, maxPotential);
        if (newStats[statKey] != current) hasChanges = true;
      }
    }

    // --- Declive físico por edad ---
    // A partir de los 32-34 años, fitness y braking empiezan a caer
    if (age >= 32) {
      final declineAge = age - 31; // 1 a N años de declive
      final declineRate = (declineAge * 0.5).clamp(0.5, 3.0);

      for (final statKey in DriverStats.physicalStats) {
        final current = newStats[statKey] ?? 50;
        // Rasgo Veterano mitiga el declive de consistency
        final decline = declineRate.round();
        if (decline > 0 && current > 30) {
          // No cae por debajo de 30
          newStats[statKey] = (current - decline).clamp(30, 100);
          if (newStats[statKey] != (currentStats[statKey] ?? 50)) {
            hasChanges = true;
          }
        }
      }
    }

    // --- Ganancia de experiencia para stats mentales ---
    // Feedback y Consistency mejoran con la experiencia (especialmente veteranos)
    final experienceXp = lapsBonus * 0.5 * (age > 32 ? 1.3 : 1.0);
    for (final statKey in DriverStats.experienceStats) {
      final current = newStats[statKey] ?? 50;
      final maxPotential = driver.getStatPotential(statKey);
      if (current >= maxPotential) continue;

      final gain = (experienceXp * facilitiesMultiplier).round();
      if (gain > 0) {
        newStats[statKey] = (current + gain).clamp(0, maxPotential);
        if (newStats[statKey] != (currentStats[statKey] ?? 50)) {
          hasChanges = true;
        }
      }
    }

    // Rasgo Veterano: bonus adicional a consistency después de los 35
    if (driver.hasTrait(DriverTrait.veteran) && age > 35) {
      final current = newStats[DriverStats.consistency] ?? 50;
      final maxPotential = driver.getStatPotential(DriverStats.consistency);
      if (current < maxPotential) {
        newStats[DriverStats.consistency] = (current + 1).clamp(
          0,
          maxPotential,
        );
        hasChanges = true;
      }
    }

    return hasChanges ? newStats : {};
  }

  /// Aplica XP post-carrera a un piloto del equipo del jugador.
  ///
  /// Llamar después de [applyRaceResults] para el equipo del jugador.
  /// [overtakesPerDriver] mapa de driverId -> número de adelantamientos.
  /// [facilitiesMultiplier] basado en las instalaciones del equipo (1.0 a 1.5).
  Future<void> applyPostRaceXp({
    required String seasonId,
    required Map<String, int> finalPositions,
    required Map<String, int> overtakesPerDriver,
    required int totalLaps,
    required double facilitiesMultiplier,
  }) async {
    final driversSnapshot = await _db.collection('drivers').get();
    final batch = _db.batch();
    bool hasBatchUpdates = false;

    for (final driverDoc in driversSnapshot.docs) {
      final driver = Driver.fromMap(driverDoc.data());
      final position = finalPositions[driver.id];
      if (position == null) continue;

      final xpUpdates = _calculatePostRaceStatChanges(
        driver: driver,
        finalPosition: position,
        totalDrivers: finalPositions.length,
        totalLaps: totalLaps,
        overtakesCompleted: overtakesPerDriver[driver.id] ?? 0,
        facilitiesMultiplier: facilitiesMultiplier,
      );

      if (xpUpdates.isNotEmpty) {
        batch.update(driverDoc.reference, {'stats': xpUpdates});
        hasBatchUpdates = true;
      }
    }

    if (hasBatchUpdates) {
      await batch.commit();
    }
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
