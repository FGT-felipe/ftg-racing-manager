import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'dart:math';

import '../models/core_models.dart';
import '../models/transfer_bid.dart';
import '../models/domain/domain_models.dart';
import 'notification_service.dart';
import 'driver_name_service.dart';
import 'driver_portrait_service.dart';

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
        'priceAtListing': marketValue,
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

    // 1. Enforce 5-driver limit (Check before transaction)
    final teamDriversSnap = await _db
        .collection('drivers')
        .where('teamId', isEqualTo: biddingTeamId)
        .get();
    if (teamDriversSnap.docs.length >= 5) {
      throw Exception(
        "Team already has 5 drivers (limit reached). You cannot bid for more drivers.",
      );
    }

    await _db.runTransaction((txn) async {
      final teamSnap = await txn.get(teamRef);
      final driverSnap = await txn.get(driverRef);

      if (!teamSnap.exists || !driverSnap.exists) {
        throw Exception("Team or Driver not found.");
      }

      final team = Team.fromMap(teamSnap.data() as Map<String, dynamic>);
      final d = Driver.fromMap(driverSnap.data() as Map<String, dynamic>);

      if (!d.isTransferListed) {
        throw Exception("This driver is not available on the market.");
      }

      // Enforce 5-minute bidding lockout
      final listedAt = d.transferListedAt ?? DateTime.now();
      final expiresAt = listedAt.add(const Duration(hours: 24));
      final diff = expiresAt.difference(DateTime.now());

      if (diff.inMinutes < 5) {
        throw Exception(
          "Bidding is closed for this driver (less than 5 minutes remaining).",
        );
      }

      if (team.id == d.teamId) {
        throw Exception("You cannot bid on your own driver.");
      }

      // Use persisted priceAtListing if available
      final int referencePrice = d.priceAtListing > 0
          ? d.priceAtListing
          : d.marketValue;

      if (d.currentHighestBid == 0) {
        if (bidAmount < referencePrice) {
          throw Exception(
            "The initial bid must be at least \$${(referencePrice / 1000).toStringAsFixed(0)}k.",
          );
        }
      } else if (bidAmount <= d.currentHighestBid) {
        throw Exception(
          "Bid must be higher than the current highest bid (\$${(d.currentHighestBid / 1000).toStringAsFixed(0)}k).",
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

      final previousBidderId = d.highestBidderTeamId;

      if (previousBidderId != null && previousBidderId != biddingTeamId) {
        // Refund previous bidder
        final prevBidderRef = _db.collection('teams').doc(previousBidderId);
        final prevSnap = await txn.get(prevBidderRef);
        if (prevSnap.exists) {
          final prevTeam = Team.fromMap(
            prevSnap.data() as Map<String, dynamic>,
          );
          txn.update(prevBidderRef, {
            'budget': prevTeam.budget + d.currentHighestBid,
          });

          // Record refund transaction
          final refundTransRef = prevBidderRef.collection('transactions').doc();
          txn.set(
            refundTransRef,
            Transaction(
              id: refundTransRef.id,
              description: 'Transfer Bid Outbid: ${d.name}',
              amount: d.currentHighestBid,
              date: DateTime.now(),
              type: 'TRANSFER_REFUND',
            ).toMap(),
          );

          // Create Notification
          _notificationService.addNotification(
            teamId: previousBidderId,
            title: "Transfer Bid Surpassed",
            message:
                "Your bid of \$${d.currentHighestBid} for ${d.name} has been surpassed. Your funds have been refunded.",
            type: "WARNING",
            actionRoute: "/market",
          );
        }
      }

      // Deduct from new bidder
      txn.update(teamRef, {'budget': team.budget - bidAmount});

      // Record bid transaction
      final bidTransRef = teamRef.collection('transactions').doc();
      txn.set(
        bidTransRef,
        Transaction(
          id: bidTransRef.id,
          description: 'Transfer Bid Placed: ${d.name}',
          amount: -bidAmount,
          date: DateTime.now(),
          type: 'TRANSFER_BID',
        ).toMap(),
      );

      // Update driver
      txn.update(driverRef, {
        'currentHighestBid': bidAmount,
        'highestBidderTeamId': biddingTeamId,
        'highestBidderTeamName': team.name,
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

  // 4b. Cancel Bid
  // Clears the current highest bid if the bidder wants to withdraw.
  // Funs are NOT returned as per product rules.
  Future<void> cancelBid(String teamId, String driverId) async {
    final driverRef = _db.collection('drivers').doc(driverId);

    await _db.runTransaction((txn) async {
      final driverSnap = await txn.get(driverRef);

      if (!driverSnap.exists) {
        throw Exception("Driver not found.");
      }

      final driver = Driver.fromMap(driverSnap.data() as Map<String, dynamic>);

      if (driver.highestBidderTeamId != teamId) {
        throw Exception("You are not the highest bidder for this driver.");
      }

      // Enforce 5-minute bidding lockout (same as placeBid)
      final listedAt = driver.transferListedAt ?? DateTime.now();
      final expiresAt = listedAt.add(const Duration(hours: 24));
      final diff = expiresAt.difference(DateTime.now());

      if (diff.inMinutes < 5) {
        throw Exception(
          "Transfer is almost closed. You can no longer cancel your bid.",
        );
      }

      // Clear bidding info on driver
      txn.update(driverRef, {
        'currentHighestBid': 0,
        'highestBidderTeamId': FieldValue.delete(),
        'highestBidderTeamName': FieldValue.delete(),
      });

      // We could also delete the TransferBid record, but keeping it as a "failed/cancelled" log might be better.
      // For now, let's just clear the driver state.
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
      if (morale > 80) {
        moraleMod = 0.8;
      } else if (morale < 50) {
        moraleMod = 1.3;
      }

      if (driver.negotiationAttempts >= 3) {
        throw Exception(
          "This driver has already rejected 3 offers and is no longer interested in negotiating today.",
        );
      }

      final int finalExpectedSalary = (baseExpectedSalary * moraleMod).round();

      if (salary >= finalExpectedSalary) {
        accepted = true;

        // Boost morale for a good contract
        final newMorale = (morale + 15).clamp(0, 100);

        txn.update(driverRef, {
          'salary': salary,
          'contractYearsRemaining':
              driver.contractYearsRemaining + durationYears,
          'role': role,
          'stats.${DriverStats.morale}': newMorale,
          'negotiationAttempts': 0, // Reset on success
        });
      } else {
        accepted = false;
        final newAttempts = driver.negotiationAttempts + 1;

        // Penalize morale for rejection
        // If it's the 3rd strike, drop morale even more
        int moraleDrop = 10;
        if (newAttempts >= 3) {
          moraleDrop = 25;
        }
        final newMorale = (morale - moraleDrop).clamp(0, 100);

        txn.update(driverRef, {
          'stats.${DriverStats.morale}': newMorale,
          'negotiationAttempts': newAttempts,
        });
      }
    });

    return accepted;
  }

  // 6. Generate Admin Market Drivers
  Future<void> generateAdminMarketDrivers(int count) async {
    final batch = _db.batch();
    int opCount = 0;

    final Random rnd = Random();
    final nameService = DriverNameService();
    final portraitService = DriverPortraitService();

    final countryPool = [
      Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷'),
      Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷'),
      Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴'),
      Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽'),
      Country(code: 'CL', name: 'Chile', flagEmoji: '🇨🇱'),
      Country(code: 'UY', name: 'Uruguay', flagEmoji: '🇺🇾'),
      Country(code: 'ES', name: 'España', flagEmoji: '🇪🇸'),
      Country(code: 'IT', name: 'Italia', flagEmoji: '🇮🇹'),
      Country(code: 'GB', name: 'United Kingdom', flagEmoji: '🇬🇧'),
      Country(code: 'DE', name: 'Germany', flagEmoji: '🇩🇪'),
      Country(code: 'FR', name: 'France', flagEmoji: '🇫🇷'),
      Country(code: 'US', name: 'USA', flagEmoji: '🇺🇸'),
      Country(code: 'JP', name: 'Japan', flagEmoji: '🇯🇵'),
    ];

    for (int i = 0; i < count; i++) {
      final driverRef = _db.collection('drivers').doc();

      int potential = 1;
      int r = rnd.nextInt(100);
      if (r < 15) {
        potential = 5;
      } else if (r < 35) {
        potential = 4;
      } else if (r < 65) {
        potential = 3;
      } else if (r < 90) {
        potential = 2;
      }

      final age = 18 + rnd.nextInt(15);
      final gender = rnd.nextBool() ? 'M' : 'F';
      final country = countryPool[rnd.nextInt(countryPool.length)];

      final stats = <String, int>{};
      final statPotentials = <String, int>{};

      for (final key in DriverStats.all) {
        final pot = (potential * 20).clamp(10, 100);
        statPotentials[key] = pot;
        // Current skill depends on age and potential
        stats[key] = (pot - 15 - rnd.nextInt(20)).clamp(5, 100);
      }

      final name = nameService.generateName(
        gender: gender,
        countryCode: country.code,
      );

      // Staggered listing time:
      // First driver listed "now" (expires in 24h)
      // Second driver listed "in 24h" (expires in 48h)
      // etc...
      final staggeredListingTime = DateTime.now().add(Duration(hours: 24 * i));

      final d = Driver(
        id: driverRef.id,
        name: name,
        age: age,
        potential: potential,
        points: 0,
        gender: gender,
        stats: stats,
        statPotentials: statPotentials,
        isTransferListed: true,
        transferListedAt: staggeredListingTime,
        countryCode: country.code,
        portraitUrl: portraitService.getPortraitUrl(
          driverId: driverRef.id,
          gender: gender,
          countryCode: country.code,
          age: age,
        ),
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

  // 7. Clear Admin Market Drivers
  Future<void> clearAdminMarketDrivers() async {
    final snapshot = await _db
        .collection('drivers')
        .where('isTransferListed', isEqualTo: true)
        .where('teamId', isNull: true)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
