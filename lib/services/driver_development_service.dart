import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';
import 'notification_service.dart';

class DriverDevelopmentService {
  static final DriverDevelopmentService _instance =
      DriverDevelopmentService._internal();
  factory DriverDevelopmentService() => _instance;
  DriverDevelopmentService._internal();

  final Random _random = Random();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Applies development and fitness changes after a practice series.
  /// Returns a summary message of the changes.
  Future<String> applyPracticeDevelopment({
    required Driver driver,
    required double setupConfidence,
    required double averageLapTime,
    required int lapsCompleted,
    bool sendNotification = true,
  }) async {
    // 1. Calculate XP Gain (0.1% to 2%)
    // Factors: Age, Potential
    double baseGain = 0.001 + (_random.nextDouble() * 0.019); // 0.1% to 2.0%

    // Multiplier based on age (learning faster if young)
    double ageMult = 1.0;
    if (driver.age < 22)
      ageMult = 1.5;
    else if (driver.age < 26)
      ageMult = 1.25;
    else if (driver.age > 35)
      ageMult = 0.5;

    // Multiplier based on potential (1-5 stars)
    double potMult = 0.5 + (driver.potential * 0.2); // 0.7x to 1.5x

    double totalGainProgress = baseGain * ageMult * potMult;

    // Pick 1-3 random stats to improve (excluding marketability and morale)
    final eligibleStats = DriverStats.all
        .where(
          (s) =>
              s != DriverStats.marketability &&
              s != DriverStats.morale &&
              driver.getStat(s) < driver.getStatPotential(s),
        )
        .toList();

    if (eligibleStats.isEmpty)
      return "No more room to grow."; // No more room to grow

    final numStatsToImprove = _random.nextInt(3) + 1; // 1 to 3
    eligibleStats.shuffle(_random);
    final selectedStats = eligibleStats.take(numStatsToImprove).toList();

    Map<String, int> updatedStats = Map.from(driver.stats);
    Map<String, double> updatedGrowth = Map.from(driver.weeklyGrowth);
    List<String> leveledUpStats = [];

    for (var statKey in selectedStats) {
      double currentGrowth = updatedGrowth[statKey] ?? 0.0;
      double newGrowth = currentGrowth + totalGainProgress;

      if (newGrowth >= 1.0) {
        int statIncrease = newGrowth.floor();
        updatedStats[statKey] = (updatedStats[statKey]! + statIncrease).clamp(
          0,
          driver.getStatPotential(statKey),
        );
        newGrowth -= statIncrease;
        leveledUpStats.add(statKey);
      }
      updatedGrowth[statKey] = newGrowth;
    }

    // 2. Calculate Fitness Loss (0.5% to 1.2% points)
    // If setup was good, less fitness loss.
    // Range: 0.5 (perfect setup) to 1.2 (very bad setup)
    double baseLoss = 1.2 - (setupConfidence * 0.7);
    // Add small random jitter (+/- 0.05)
    double jitter = (_random.nextDouble() * 0.1) - 0.05;
    double fitnessChange = -(baseLoss + jitter).clamp(0.5, 1.2);

    double currentFitnessGrowth = updatedGrowth[DriverStats.fitness] ?? 0.0;
    double newFitnessGrowth = currentFitnessGrowth + fitnessChange;

    if (newFitnessGrowth < 0.0) {
      int statDecrease = (-newFitnessGrowth).floor() + 1;
      updatedStats[DriverStats.fitness] =
          (updatedStats[DriverStats.fitness]! - statDecrease).clamp(0, 100);
      newFitnessGrowth += statDecrease;
    }
    updatedGrowth[DriverStats.fitness] = newFitnessGrowth;

    // Bonus feedback if run was good
    bool feedbackBonus = setupConfidence > 0.85;
    if (feedbackBonus) {
      double feedbackGain =
          0.005 + (_random.nextDouble() * 0.01); // Extra 0.5% to 1.5%
      double currentFeedbackGrowth = updatedGrowth[DriverStats.feedback] ?? 0.0;
      double newFeedbackGrowth = currentFeedbackFeedback(
        currentFeedbackGrowth,
        feedbackGain,
        updatedStats,
        driver,
      );
      updatedGrowth[DriverStats.feedback] = newFeedbackGrowth;
    }

    // 3. Update Firestore
    await _db.collection('drivers').doc(driver.id).update({
      'stats': updatedStats,
      'weeklyGrowth': updatedGrowth,
    });

    // 4. Summary Message
    String improvements = selectedStats
        .map(
          (s) =>
              "${s.toUpperCase()} (+${(totalGainProgress * 100).toStringAsFixed(2)}%)",
        )
        .join(", ");
    String msg = "Gained experience in: $improvements.";

    if (leveledUpStats.isNotEmpty) {
      msg +=
          " 🚀 LEVEL UP: ${leveledUpStats.map((s) => s.toUpperCase()).join(", ")}!";
    }

    msg += " 🔋 Fitness: ${(fitnessChange).toStringAsFixed(2)} pts.";

    if (sendNotification) {
      await NotificationService().addNotification(
        teamId: driver.teamId!,
        title: "Series Finished: ${driver.name}",
        message: "The driver completed the series and $msg",
        type: feedbackBonus ? 'SUCCESS' : 'NEWS',
      );
    }

    return msg;
  }

  /// Persists driver stats and growth to Firestore after a qualifying session.
  /// Used primarily to save fitness changes affected by Driver Style.
  Future<void> applyQualifyingPersistence({required Driver driver}) async {
    await _db.collection('drivers').doc(driver.id).update({
      'stats': driver.stats,
      'weeklyGrowth': driver.weeklyGrowth,
    });
  }

  double currentFeedbackFeedback(
    double current,
    double gain,
    Map<String, int> stats,
    Driver driver,
  ) {
    double n = current + gain;
    if (n >= 1.0) {
      stats[DriverStats.feedback] = (stats[DriverStats.feedback]! + 1).clamp(
        0,
        driver.getStatPotential(DriverStats.feedback),
      );
      n -= 1.0;
    }
    return n;
  }
}
