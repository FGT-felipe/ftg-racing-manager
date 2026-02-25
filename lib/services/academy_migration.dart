import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_models.dart';
import 'season_service.dart';

Future<void> syncAcademyLevels() async {
  debugPrint('--- [MIGRATION START] FIX YOUTH ACADEMY SEASONS ---');
  final teamsSnap = await FirebaseFirestore.instance.collection('teams').get();

  final activeSeason = await SeasonService().getActiveSeason();
  final currentSeasonId = activeSeason?.id ?? 'unknown';

  int processed = 0;

  for (final teamDoc in teamsSnap.docs) {
    final teamData = teamDoc.data();
    final facilities = teamData['facilities'] as Map<String, dynamic>? ?? {};
    final youthAcademy = facilities['youthAcademy'] as Map<String, dynamic>?;
    final managerId = teamData['managerId'] as String?;

    if (youthAcademy != null) {
      final int hqLevel = youthAcademy['level'] ?? 0;

      // We enforce max level 1 for now, as no one could have upgraded across multiple seasons.
      if (hqLevel > 1) {
        final configSnap = await teamDoc.reference
            .collection('academy')
            .doc('config')
            .get();

        if (configSnap.exists) {
          ManagerRole? role;
          if (managerId != null) {
            final managerSnap = await FirebaseFirestore.instance
                .collection('managers')
                .doc(managerId)
                .get();
            if (managerSnap.exists) {
              final data = managerSnap.data()!;
              data['uid'] = managerSnap.id; // Just to avoid missing uid field
              role = ManagerProfile.fromMap(data).role;
            }
          }

          debugPrint(
            'Rolling back team ${teamDoc.id} from level $hqLevel to 1',
          );

          int totalRefund = 0;

          // Calculate exact refund based on the bugged price they actually paid (100k * (l+1))
          for (int l = 1; l < hqLevel; l++) {
            // The bug previously used the FacilityService generic logic: price = 100000 * (level + 1)
            int paidPrice = 100000 * (l + 1);
            if (role == ManagerRole.businessAdmin ||
                role == ManagerRole.bureaucrat) {
              paidPrice = (paidPrice * 0.9).round();
            }
            totalRefund += paidPrice;
          }

          int newMaxSlots = 2; // base for level 1
          if (role == ManagerRole.bureaucrat) {
            newMaxSlots += 1; // +1 slot per level for bureaucrat
          }

          // Sync academy config level to match HQ level = 1
          await configSnap.reference.update({
            'academyLevel': 1,
            'maxSlots': newMaxSlots,
            'lastUpgradeSeasonId': currentSeasonId,
          });

          // Adjust the budget and add a transaction to reflect the paid difference
          if (totalRefund > 0) {
            await teamDoc.reference.update({
              'budget': FieldValue.increment(totalRefund),
              'facilities.youthAcademy.level': 1,
              'facilities.youthAcademy.lastUpgradeSeasonId': currentSeasonId,
            });

            final transRef = teamDoc.reference.collection('transactions').doc();
            await transRef.set({
              'id': transRef.id,
              'description': 'Academy Season Upgrade Refund',
              'amount': totalRefund,
              'date': DateTime.now().toIso8601String(),
              'type': 'REWARD',
            });
            debugPrint('-> Refunded $totalRefund to team budget.');
          }
          processed++;
        }
      } else if (hqLevel == 1) {
        // Ensure lastUpgradeSeasonId is set for those who are legitimately at level 1
        await teamDoc.reference
            .collection('academy')
            .doc('config')
            .update({'lastUpgradeSeasonId': currentSeasonId})
            .catchError((_) => null);
        await teamDoc.reference
            .update({
              'facilities.youthAcademy.lastUpgradeSeasonId': currentSeasonId,
            })
            .catchError((_) => null);
      }
    }
  }
  debugPrint('--- [MIGRATION END] Processed $processed teams ---');
}
