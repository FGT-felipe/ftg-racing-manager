import 'package:cloud_firestore/cloud_firestore.dart';

class TeamService {
  static final TeamService _instance = TeamService._internal();
  factory TeamService() => _instance;
  TeamService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> claimTeam(DocumentReference teamRef, String userId) async {
    return _db.runTransaction((transaction) async {
      final teamDoc = await transaction.get(teamRef);

      if (!teamDoc.exists) {
        throw Exception("Team does not exist");
      }

      final data = teamDoc.data() as Map<String, dynamic>;

      if (data['managerId'] != null) {
        throw Exception("Team already taken");
      }

      transaction.update(teamRef, {'managerId': userId, 'isBot': false});
    });
  }
}
