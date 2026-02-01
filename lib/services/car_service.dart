import 'package:cloud_firestore/cloud_firestore.dart';

class CarService {
  static final CarService _instance = CarService._internal();
  factory CarService() => _instance;
  CarService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> upgradePart({
    required String teamId,
    required String partKey,
    required int currentLevel,
    required int currentBudget,
  }) async {
    final cost = currentLevel * 100000;

    if (currentBudget < cost) {
      throw Exception("Insufficient funds");
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

      final newLevel = (carStats[partKey] ?? 0) + 1;
      carStats[partKey] = newLevel;

      transaction.update(teamRef, {
        'budget': budget - cost,
        'carStats': carStats,
      });
    });
  }
}
