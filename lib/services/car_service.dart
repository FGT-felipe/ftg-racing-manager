import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../models/user_models.dart';

class CarService {
  static final CarService _instance = CarService._internal();
  factory CarService() => _instance;
  CarService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Gets the cost for upgrading a part from currentLevel to currentLevel + 1.
  /// Ex-Engineer pays double.
  int getUpgradeCost(int currentLevel, {ManagerRole? role}) {
    // Fibonacci sequence for multiplier: 1, 1, 2, 3, 5, 8, 13, 21...
    int n = currentLevel;
    if (n <= 2) {
      final base = 100000;
      return role == ManagerRole.exEngineer ? base * 2 : base;
    }

    int a = 1;
    int b = 1;
    for (int i = 2; i < n; i++) {
      int temp = a + b;
      a = b;
      b = temp;
    }

    final base = b * 100000;
    return role == ManagerRole.exEngineer ? base * 2 : base;
  }

  Future<void> upgradePart({
    required String teamId,
    required String partKey,
    required int carIndex,
    required int currentLevel,
    required int currentBudget,
    ManagerRole? role,
  }) async {
    if (currentLevel >= 20) {
      throw Exception("Part is already at maximum level (20)");
    }

    final cost = getUpgradeCost(currentLevel, role: role);

    if (currentBudget < cost) {
      throw Exception("Insufficient funds. Need \$${cost ~/ 1000}k");
    }

    final teamRef = _db.collection('teams').doc(teamId);

    return _db.runTransaction((transaction) async {
      final teamDoc = await transaction.get(teamRef);

      if (!teamDoc.exists) {
        throw Exception("Team does not exist");
      }

      final data = teamDoc.data() as Map<String, dynamic>;
      final budget = data['budget'] as int;

      // Check weekly upgrade limit
      final weekStatus = Map<String, dynamic>.from(data['weekStatus'] ?? {});
      final int upgradeCount = (weekStatus['upgradesThisWeek'] as int?) ?? 0;

      // Bureaucrat: 2-week cooldown — check if cooldownWeeksLeft > 0
      final int cooldownLeft =
          (weekStatus['upgradeCooldownWeeksLeft'] as int?) ?? 0;
      if (role == ManagerRole.bureaucrat && cooldownLeft > 0) {
        throw Exception(
          "Bureaucrat cooldown: $cooldownLeft week(s) remaining.",
        );
      }

      // Ex-Engineer can upgrade 2 parts per week, others only 1
      final int maxUpgrades = role == ManagerRole.exEngineer ? 2 : 1;
      if (upgradeCount >= maxUpgrades) {
        throw Exception("Upgrade limit reached ($maxUpgrades per week).");
      }

      // Initialize carStats structure if missing or old
      Map<String, dynamic> carStats = {};
      final rawCarStats = data['carStats'];
      if (rawCarStats is Map) {
        if (rawCarStats.containsKey('0') || rawCarStats.containsKey('1')) {
          carStats = Map<String, dynamic>.from(rawCarStats);
        } else {
          // Migrate old single stats to both cars
          final oldStats = Map<String, int>.from(rawCarStats);
          carStats = {'0': oldStats, '1': Map<String, int>.from(oldStats)};
        }
      } else {
        final def = {'aero': 1, 'engine': 1, 'reliability': 1};
        carStats = {'0': def, '1': Map<String, int>.from(def)};
      }

      final String carKey = carIndex.toString();
      final Map<String, int> targetCarStats = Map<String, int>.from(
        carStats[carKey] ?? {'aero': 1, 'engine': 1, 'reliability': 1},
      );

      if (budget < cost) {
        throw Exception("Insufficient funds");
      }

      final newLevel = (targetCarStats[partKey] ?? 1) + 1;
      targetCarStats[partKey] = newLevel;
      carStats[carKey] = targetCarStats;

      // Update week status
      weekStatus['upgradesThisWeek'] = upgradeCount + 1;
      weekStatus['hasUpgradedThisWeek'] = true; // backward compat

      // Bureaucrat: set 2-week cooldown after upgrading
      if (role == ManagerRole.bureaucrat) {
        weekStatus['upgradeCooldownWeeksLeft'] = 2;
      }

      transaction.update(teamRef, {
        'budget': budget - cost,
        'carStats': carStats,
        'weekStatus': weekStatus,
      });

      // Record transaction
      final txRef = teamRef.collection('transactions').doc();
      final carLabel = carIndex == 0 ? "Car A" : "Car B";
      transaction.set(txRef, {
        'id': txRef.id,
        'description': "Upgrade $partKey to LVL $newLevel ($carLabel)",
        'amount': -cost,
        'date': DateTime.now().toIso8601String(),
        'type': 'UPGRADE',
      });

      // Add "Office News" notification
      await NotificationService().addNotification(
        teamId: teamId,
        title: "Car Updated",
        message:
            "Upgraded $partKey to LVL $newLevel on ${carIndex == 0 ? 'Car A' : 'Car B'}.",
        type: 'SUCCESS',
        actionRoute: '/engineering',
      );
    });
  }
}
