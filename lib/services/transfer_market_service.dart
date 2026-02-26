import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'dart:math';

import '../models/core_models.dart';
import '../models/transfer_bid.dart';
import 'notification_service.dart';

class TransferMarketService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // 1. List Driver on Market
  // Deducts 10% of market value from team's budget immediately.
  Future<void> listDriverOnMarket(String teamId, String driverId) async {
    final teamRef = _db.collection('teams').doc(teamId);
    final driverRef = _db.collection('drivers').doc(driverId);

    await _db.runTransaction((txn) async {
      final teamSnap = await txn.get(teamRef);
      final driverSnap = await txn.get(driverRef);

      if (!teamSnap.exists || !driverSnap.exists) {
        throw Exception("Team or Driver not found.");
      }

      final team = Team.fromMap(teamSnap.data() as Map<String, dynamic>);
      final driver = Driver.fromMap(driverSnap.data() as Map<String, dynamic>);

      if (driver.isTransferListed) {
        throw Exception("Driver is already on the transfer market.");
      }

      final int marketValue = driver.marketValue;
      final int listingFee = (marketValue * 0.10).round();

      if (team.budget < listingFee) {
        throw Exception(
          "Insufficient budget to pay the 10% listing fee of \$${listingFee.toString()}.",
        );
      }

      // Deduct fee
      txn.update(teamRef, {'budget': team.budget - listingFee});

      // Update driver
      txn.update(driverRef, {
        'isTransferListed': true,
        'transferListedAt': FieldValue.serverTimestamp(),
        'currentHighestBid': 0,
        'highestBidderTeamId': FieldValue.delete(),
      });

      // Record transaction
      final transRef = teamRef.collection('transactions').doc();
      txn.set(
        transRef,
        Transaction(
          id: transRef.id,
          description: 'Transfer Market Listing Fee: ${driver.name}',
          amount: -listingFee,
          date: DateTime.now(),
          type: 'TRANSFER',
        ).toMap(),
      );
    });
  }

  // 2. Release Driver
  // Deducts 10% of market value and removes driver from team (delete).
  Future<void> releaseDriver(String teamId, String driverId) async {
    final teamRef = _db.collection('teams').doc(teamId);
    final driverRef = _db.collection('drivers').doc(driverId);

    await _db.runTransaction((txn) async {
      final teamSnap = await txn.get(teamRef);
      final driverSnap = await txn.get(driverRef);

      if (!teamSnap.exists || !driverSnap.exists) {
        throw Exception("Team or Driver not found.");
      }

      final team = Team.fromMap(teamSnap.data() as Map<String, dynamic>);
      final driver = Driver.fromMap(driverSnap.data() as Map<String, dynamic>);

      final int marketValue = driver.marketValue;
      final int releaseFee = (marketValue * 0.10).round();

      if (team.budget < releaseFee) {
        throw Exception(
          "Insufficient budget to pay the 10% release fee of \$${releaseFee.toString()}.",
        );
      }

      // Deduct fee
      txn.update(teamRef, {'budget': team.budget - releaseFee});

      // Remove driver (we delete to keep database clean, or we could set teamId to null)
      txn.delete(driverRef);

      // Record transaction
      final transRef = teamRef.collection('transactions').doc();
      txn.set(
        transRef,
        Transaction(
          id: transRef.id,
          description: 'Driver Released: ${driver.name}',
          amount: -releaseFee,
          date: DateTime.now(),
          type: 'TRANSFER',
        ).toMap(),
      );
    });
  }

  // 3. Cancel Transfer
  // Reverts list status, applies moral penalty.
  Future<void> cancelTransfer(String teamId, String driverId) async {
    final driverRef = _db.collection('drivers').doc(driverId);

    await _db.runTransaction((txn) async {
      final driverSnap = await txn.get(driverRef);

      if (!driverSnap.exists) {
        throw Exception("Driver not found.");
      }

      final driver = Driver.fromMap(driverSnap.data() as Map<String, dynamic>);

      if (!driver.isTransferListed) {
        throw Exception("Driver is not on the transfer market.");
      }

      // Apply morale penalty
      final newMorale = (driver.getStat(DriverStats.morale) - 20).clamp(0, 100);

      txn.update(driverRef, {
        'isTransferListed': false,
        'transferListedAt': FieldValue.delete(),
        'currentHighestBid': FieldValue.delete(),
        'highestBidderTeamId': FieldValue.delete(),
        'stats.${DriverStats.morale}': newMorale,
      });
    });
  }

  // 4. Place Bid
  Future<void> placeBid(
    String biddingTeamId,
    String driverId,
    int bidAmount,
  ) async {
    final teamRef = _db.collection('teams').doc(biddingTeamId);
    final driverRef = _db.collection('drivers').doc(driverId);
    final bidRef = _db.collection('transferBids').doc();

    await _db.runTransaction((txn) async {
      final teamSnap = await txn.get(teamRef);
      final driverSnap = await txn.get(driverRef);

      if (!teamSnap.exists || !driverSnap.exists) {
        throw Exception("Team or Driver not found.");
      }

      final team = Team.fromMap(teamSnap.data() as Map<String, dynamic>);
      final driver = Driver.fromMap(driverSnap.data() as Map<String, dynamic>);

      if (!driver.isTransferListed) {
        throw Exception("This driver is not available on the market.");
      }

      if (team.id == driver.teamId) {
        throw Exception("You cannot bid on your own driver.");
      }

      // Check minimum outbid (e.g., must be higher than current highest)
      if (bidAmount <= driver.currentHighestBid) {
        throw Exception(
          "Bid must be higher than the current highest bid (\$${driver.currentHighestBid.toString()}).",
        );
      }

      // Validate transfer budget
      final double transferBudgetRatio = team.transferBudgetPercentage / 100.0;
      final int maxAllowedBid = (team.budget * transferBudgetRatio).round();

      if (bidAmount > maxAllowedBid) {
        throw Exception(
          "Bid exceeds your allowed transfer budget (\$${maxAllowedBid.toString()}). Adjust your transfer budget percentage in Finances.",
        );
      }

      final previousBidderId = driver.highestBidderTeamId;

      // Ensure funds are somewhat locked or we just deduct them?
      // If we deduct them now, we must refund the previous highest bidder.
      // Doing full escrow in Firestore is robust. Let's do it:

      if (previousBidderId != null && previousBidderId != biddingTeamId) {
        // Refund previous bidder
        final prevBidderRef = _db.collection('teams').doc(previousBidderId);
        final prevSnap = await txn.get(prevBidderRef);
        if (prevSnap.exists) {
          final prevTeam = Team.fromMap(
            prevSnap.data() as Map<String, dynamic>,
          );
          txn.update(prevBidderRef, {
            'budget': prevTeam.budget + driver.currentHighestBid,
          });

          // Record refund transaction
          final refundTransRef = prevBidderRef.collection('transactions').doc();
          txn.set(
            refundTransRef,
            Transaction(
              id: refundTransRef.id,
              description: 'Transfer Bid Outbid: ${driver.name}',
              amount: driver.currentHighestBid,
              date: DateTime.now(),
              type: 'TRANSFER_REFUND',
            ).toMap(),
          );

          // Create Notification for Outbid
          _notificationService.addNotification(
            teamId: previousBidderId,
            title: "Transfer Bid Surpassed",
            message:
                "Your bid of \$${driver.currentHighestBid} for ${driver.name} has been surpassed by another team. Your funds have been refunded.",
            type: "WARNING",
            actionRoute: "/market",
          );
        }
      }

      // Deduct from new bidder
      txn.update(teamRef, {'budget': team.budget - bidAmount});

      // Record deduction transaction
      final bidTransRef = teamRef.collection('transactions').doc();
      txn.set(
        bidTransRef,
        Transaction(
          id: bidTransRef.id,
          description: 'Transfer Bid Placed: ${driver.name}',
          amount: -bidAmount,
          date: DateTime.now(),
          type: 'TRANSFER_BID',
        ).toMap(),
      );

      // Update driver with new highest bid
      txn.update(driverRef, {
        'currentHighestBid': bidAmount,
        'highestBidderTeamId': biddingTeamId,
      });

      // Save bid record
      final bid = TransferBid(
        id: bidRef.id,
        driverId: driverId,
        teamId: biddingTeamId,
        amount: bidAmount,
        createdAt: DateTime.now(),
      );
      txn.set(bidRef, bid.toMap());
    });
  }

  // 5. Renew Contract
  Future<bool> renewContract({
    required String teamId,
    required String driverId,
    required int durationYears,
    required int salary,
    required String role,
  }) async {
    final driverRef = _db.collection('drivers').doc(driverId);
    bool accepted = false;

    await _db.runTransaction((txn) async {
      final driverSnap = await txn.get(driverRef);
      if (!driverSnap.exists) throw Exception("Driver not found");

      final driver = Driver.fromMap(driverSnap.data() as Map<String, dynamic>);

      // Basic logic to determine if driver accepts:
      // Minimum salary expected is roughly correlated to marketValue, stats, and morale.
      final int baseExpectedSalary = (driver.marketValue * 0.05).round().clamp(
        100000,
        10000000,
      ); // 5% of MV as yearly expected roughly?

      // Apply morale modifier: high morale accepts lower pay (up to 20% discount), low morale demands higher (up to 30% premium)
      final morale = driver.getStat(DriverStats.morale);
      double moraleMod = 1.0;
      if (morale > 80)
        moraleMod = 0.8;
      else if (morale < 50)
        moraleMod = 1.3;

      final int finalExpectedSalary = (baseExpectedSalary * moraleMod).round();

      if (salary >= finalExpectedSalary) {
        accepted = true;

        // Boost morale for a good contract
        final newMorale = (morale + 10).clamp(0, 100);

        txn.update(driverRef, {
          'salary': salary,
          'contractYearsRemaining':
              driver.contractYearsRemaining + durationYears,
          'role': role,
          'stats.${DriverStats.morale}': newMorale,
        });
      } else {
        accepted = false;
        // Penalize morale for lowball offer
        final newMorale = (morale - 10).clamp(0, 100);
        txn.update(driverRef, {'stats.${DriverStats.morale}': newMorale});
      }
    });

    return accepted;
  }

  // 6. Generate Admin Market Drivers
  Future<void> generateAdminMarketDrivers(int count) async {
    final batch = _db.batch();
    int opCount = 0;

    // Simplistic driver generation for the market
    final Random rnd = Random();

    for (int i = 0; i < count; i++) {
      final driverRef = _db.collection('drivers').doc();

      int potential = 1;
      int r = rnd.nextInt(100);
      if (r < 10)
        potential = 5;
      else if (r < 30)
        potential = 4;
      else if (r < 60)
        potential = 3;
      else if (r < 85)
        potential = 2;

      final age = 18 + rnd.nextInt(15);

      final stats = <String, int>{};
      final statPotentials = <String, int>{};

      for (final key in DriverStats.all) {
        final pot = (potential * 20).clamp(0, 100);
        statPotentials[key] = pot;
        stats[key] = max(10, pot - rnd.nextInt(30));
      }

      final d = Driver(
        id: driverRef.id,
        name: "Market Driver ${rnd.nextInt(9999)}",
        age: age,
        potential: potential,
        points: 0,
        gender: rnd.nextBool() ? 'M' : 'F',
        stats: stats,
        statPotentials: statPotentials,
        isTransferListed: true,
        transferListedAt: DateTime.now(),
      );

      batch.set(driverRef, d.toMap());
      opCount++;

      if (opCount == 400) {
        await batch.commit();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }
}
