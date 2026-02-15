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
      final carStats = Map<String, int>.from(data['carStats'] ?? {});

      if (budget < cost) {
        throw Exception("Insufficient funds");
      }

      final newLevel = (carStats[partKey] ?? 1) + 1;
      carStats[partKey] = newLevel;

      transaction.update(teamRef, {
        'budget': budget - cost,
        'carStats': carStats,
      });

      // Record transaction
      final txRef = teamRef.collection('transactions').doc();
      transaction.set(txRef, {
        'id': txRef.id,
        'description': "Upgrade $partKey to LVL $newLevel",
        'amount': -cost,
        'date': DateTime.now().toIso8601String(),
        'type': 'UPGRADE',
      });
    });
  }
}
