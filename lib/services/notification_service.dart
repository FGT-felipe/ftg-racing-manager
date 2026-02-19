import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch notifications for a specific team.
  Stream<List<AppNotification>> getTeamNotifications(String teamId) {
    return _db
        .collection('teams')
        .doc(teamId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            // Ensure timestamp is present, even if pending write
            if (data['timestamp'] == null && doc.metadata.hasPendingWrites) {
              data['timestamp'] = Timestamp.now();
            }
            return AppNotification.fromMap(data);
          }).toList();
        });
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String teamId, String notificationId) async {
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Add a new notification.
  Future<void> addNotification({
    required String teamId,
    required String title,
    required String message,
    required String type,
    String? actionRoute,
  }) async {
    await _db.collection('teams').doc(teamId).collection('notifications').add({
      'title': title,
      'message': message,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'actionRoute': actionRoute,
    });
  }

  /// Delete a notification.
  Future<void> deleteNotification(String teamId, String notificationId) async {
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}
