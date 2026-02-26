import 'package:cloud_firestore/cloud_firestore.dart';

class TransferBid {
  final String id;
  final String driverId;
  final String teamId;
  final int amount;
  final DateTime createdAt;

  TransferBid({
    required this.id,
    required this.driverId,
    required this.teamId,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'teamId': teamId,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TransferBid.fromMap(Map<String, dynamic> map) {
    DateTime parseTs(dynamic ts) {
      if (ts == null) return DateTime.now();
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return TransferBid(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      teamId: map['teamId'] ?? '',
      amount: map['amount'] ?? 0,
      createdAt: parseTs(map['createdAt']),
    );
  }
}
