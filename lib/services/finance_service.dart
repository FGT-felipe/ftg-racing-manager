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
}
