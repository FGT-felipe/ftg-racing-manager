import 'package:cloud_firestore/cloud_firestore.dart';

class CarService {
  static final CarService _instance = CarService._internal();
  factory CarService() => _instance;
  CarService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Gets the cost for upgrading a part from currentLevel to currentLevel + 1
  int getUpgradeCost(int currentLevel) {
    // Fibonacci sequence for multiplier: 1, 1, 2, 3, 5, 8, 13, 21...
    // Level 1 -> 2: multiplier F(1) = 1
    // Level 2 -> 3: multiplier F(2) = 1
    // Level 3 -> 4: multiplier F(3) = 2
    // ...
    // Using simple fib computation
    int n = currentLevel;
    if (n <= 2) return 100000; // $100k for initial levels

    int a = 1;
    int b = 1;
    for (int i = 2; i < n; i++) {
      int temp = a + b;
      a = b;
      b = temp;
    }

    return b * 100000; // Base cost $100k * fib multiplier
  }

  Future<void> upgradePart({
    required String teamId,
    required String partKey,
    required int carIndex,
    required int currentLevel,
    required int currentBudget,
  }) async {
    if (currentLevel >= 20) {
      throw Exception("Part is already at maximum level (20)");
    }

    final cost = getUpgradeCost(currentLevel);

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
      if (weekStatus['hasUpgradedThisWeek'] == true) {
        throw Exception("Only 1 upgrade allowed per race week.");
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
      weekStatus['hasUpgradedThisWeek'] = true;

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
    });
  }
}
