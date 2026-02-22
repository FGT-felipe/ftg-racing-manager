import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';

class LeagueNotificationService {
  static final LeagueNotificationService _instance =
      LeagueNotificationService._internal();
  factory LeagueNotificationService() => _instance;
  LeagueNotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch notifications for a specific league.
  Stream<List<LeagueNotification>> getLeagueNotifications(String leagueId) {
    if (leagueId.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('leagues')
        .doc(leagueId)
        .collection('press_news')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                // Ensure timestamp is present, even if pending write
                if (data['timestamp'] == null &&
                    doc.metadata.hasPendingWrites) {
                  data['timestamp'] = Timestamp.now();
                }
                return LeagueNotification.fromMap(data);
              })
              .where((notif) => !notif.isArchived)
              .toList();
        });
  }

  /// Add a new league notification (Press News).
  Future<void> addLeagueNotification({
    required String leagueId,
    required String title,
    required String message,
    required String type,
    String? eventType,
    String? pilotName,
    String? managerName,
    String? teamName,
    Map<String, dynamic>? payload,
  }) async {
    // Press News logic disabled as per user request
    /*
    await _db.collection('leagues').doc(leagueId).collection('press_news').add({
      'title': title,
      'message': message,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'leagueId': leagueId,
      'eventType': eventType,
      'pilotName': pilotName,
      'managerName': managerName,
      'teamName': teamName,
      'payload': payload,
      'isArchived': false,
    });
    */
  }

  /// Archive old notifications (Older than 2 weeks).
  /// This can be called periodically or manually.
  Future<void> archiveOldNotifications(String leagueId) async {
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
    final snapshot = await _db
        .collection('leagues')
        .doc(leagueId)
        .collection('press_news')
        .where('isArchived', isEqualTo: false)
        .where('timestamp', isLessThan: Timestamp.fromDate(twoWeeksAgo))
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isArchived': true});
    }
    await batch.commit();
  }
}
