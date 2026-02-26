import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/core_models.dart';
import 'package:intl/intl.dart';

class FinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Transaction>> getTransactionHistory(String teamId) {
    return _db
        .collection('teams')
        .doc(teamId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Transaction.fromMap(doc.data());
          }).toList();
        });
  }

  String formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'en_US',
    );
    return formatter.format(amount);
  }

  String formatCompactCurrency(int amount) {
    if (amount.abs() >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount.abs() >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}k";
    }
    return amount.toString();
  }

  Future<void> applyGreatRebalanceTax() async {
    final teamsSnap = await _db.collection('teams').get();

    // Firestore batch limit is 500 operations
    List<WriteBatch> batches = [];
    WriteBatch currentBatch = _db.batch();
    int opCount = 0;

    for (var doc in teamsSnap.docs) {
      final teamData = doc.data();
      final teamRef = doc.reference;
      int currentBudget = teamData['budget'] ?? 0;
      int newBudget = currentBudget;

      // 1. Bailout / Tax
      if (currentBudget > 3000000) {
        int excess = currentBudget - 3000000;
        newBudget = 3000000 + (excess * 0.2).toInt();
      } else if (currentBudget < 1500000) {
        newBudget = 1500000;
      }

      // Add a transaction if changed
      if (newBudget != currentBudget) {
        final txRef = teamRef.collection('transactions').doc();
        currentBatch.set(txRef, {
          'id': txRef.id,
          'description': 'Great Economic Rebalance 2026',
          'amount': newBudget - currentBudget,
          'date': DateTime.now().toIso8601String(),
          'type': 'TAX',
        });
        opCount++;
      }

      // 2. Wipe active sponsors and negotiations
      Map<String, dynamic> weekStatus = Map<String, dynamic>.from(
        teamData['weekStatus'] ?? {},
      );
      weekStatus['sponsorNegotiations'] = {};

      currentBatch.update(teamRef, {
        'budget': newBudget,
        'sponsors': {}, // Wipe all active sponsors
        'weekStatus': weekStatus,
      });
      opCount++;

      // Notify team manager
      final notifRef = teamRef.collection('notifications').doc();
      currentBatch.set(notifRef, {
        'teamId': doc.id,
        'title': 'Economic Rebalance',
        'message':
            'The Racing Federation has applied an economic rebalance. Your budget is now \$${formatCompactCurrency(newBudget)}. Previous sponsors have been terminated.',
        'type': 'INFO',
        'actionRoute': '/hq',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      opCount++;

      if (opCount >= 400) {
        batches.add(currentBatch);
        currentBatch = _db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      batches.add(currentBatch);
    }

    for (var b in batches) {
      await b.commit();
    }
  }
}
