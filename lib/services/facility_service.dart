import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/core_models.dart';

class FacilityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> upgradeFacility(String teamId, FacilityType type) async {
    final teamRef = _db.collection('teams').doc(teamId);

    return _db.runTransaction((transaction) async {
      final teamDoc = await transaction.get(teamRef);
      if (!teamDoc.exists) throw Exception("Team not found");

      final team = Team.fromMap(teamDoc.data() as Map<String, dynamic>);

      // Get the facility or create default
      Facility facility = team.facilities[type.name] ?? Facility(type: type);

      // Special case for base facilities if they are at level 0
      if ((type == FacilityType.teamOffice || type == FacilityType.garage) &&
          facility.level == 0) {
        facility = facility.copyWith(level: 1);
      }

      int price = facility.upgradePrice;

      if (team.budget < price) {
        throw Exception("Insufficient budget");
      }

      if (facility.level >= 5) {
        throw Exception("Maximum level reached");
      }

      // Update facility
      final updatedFacility = facility.copyWith(level: facility.level + 1);

      // Update team budget and facilities
      transaction.update(teamRef, {
        'budget': team.budget - price,
        'facilities.${type.name}': updatedFacility.toMap(),
      });

      // Add transaction history
      final transRef = teamRef.collection('transactions').doc();
      final trans = Transaction(
        id: transRef.id,
        description:
            "Upgraded ${facility.name} to level ${updatedFacility.level}",
        amount: -price,
        date: DateTime.now(),
        type: 'UPGRADE',
      );
      transaction.set(transRef, trans.toMap());
    });
  }

  /// Ensures base facilities exist at level 1
  Future<void> ensureBaseFacilities(String teamId) async {
    final teamRef = _db.collection('teams').doc(teamId);
    final teamDoc = await teamRef.get();
    if (!teamDoc.exists) return;

    final team = Team.fromMap(teamDoc.data() as Map<String, dynamic>);
    bool needsUpdate = false;
    Map<String, dynamic> updates = {};

    if (team.facilities[FacilityType.teamOffice.name] == null) {
      updates['facilities.${FacilityType.teamOffice.name}'] = Facility(
        type: FacilityType.teamOffice,
        level: 1,
      ).toMap();
      needsUpdate = true;
    }
    if (team.facilities[FacilityType.garage.name] == null) {
      updates['facilities.${FacilityType.garage.name}'] = Facility(
        type: FacilityType.garage,
        level: 1,
      ).toMap();
      needsUpdate = true;
    }

    if (needsUpdate) {
      await teamRef.update(updates);
    }
  }
}
