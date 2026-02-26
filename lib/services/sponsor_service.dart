import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'notification_service.dart';
import '../models/core_models.dart';
import '../models/user_models.dart';

enum NegotiationStatus { success, failed, locked }

class NegotiationResult {
  final NegotiationStatus status;
  final String message;
  final int remainingAttempts;

  NegotiationResult(this.status, this.message, {this.remainingAttempts = 0});
}

class SponsorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  List<SponsorOffer> getAvailableSponsors(
    SponsorSlot slot,
    ManagerRole role,
    Map<String, dynamic> negotiations,
  ) {
    // 1. Calculate Bonus Multiplier based on Role
    double multiplier = 1.0;
    bool isAdmin = false;

    if (role == ManagerRole.businessAdmin) {
      multiplier = 1.15; // 15% Bonus
      isAdmin = true;
    }

    // Helper to randomize personality
    SponsorPersonality getRandomPersonality() {
      return SponsorPersonality.values[_random.nextInt(
        SponsorPersonality.values.length,
      )];
    }

    // Helper to randomize duration (4 to 10 races)
    int getRandomDuration() {
      return 4 + _random.nextInt(7);
    }

    // Generate base offers and apply multipliers
    SponsorOffer createOffer({
      required String id,
      required String name,
      required SponsorTier tier,
      required int baseSign,
      required int baseWeekly,
      required int baseObj,
      required String objDesc,
    }) {
      return SponsorOffer(
        id: id,
        name: name,
        tier: tier,
        signingBonus: (baseSign * multiplier).round(),
        weeklyBasePayment: (baseWeekly * multiplier).round(),
        objectiveBonus: (baseObj * multiplier).round(),
        objectiveDescription: objDesc,
        personality: getRandomPersonality(),
        contractDuration: getRandomDuration(),
        isAdminBonusApplied: isAdmin,
      );
    }

    // List of offers to return
    List<SponsorOffer> offers = [];

    switch (slot) {
      case SponsorSlot.rearWing:
        offers = [
          createOffer(
            id: 'titans_oil',
            name: 'Titans Oil',
            tier: SponsorTier.title,
            baseSign: 1000000,
            baseWeekly: 150000,
            baseObj: 250000,
            objDesc: "objFinishTop3",
          ),
          createOffer(
            id: 'global_tech',
            name: 'Global Tech',
            tier: SponsorTier.title,
            baseSign: 800000,
            baseWeekly: 180000,
            baseObj: 200000,
            objDesc: "objBothInPoints",
          ),
          createOffer(
            id: 'zenith_sky',
            name: 'Zenith Sky',
            tier: SponsorTier.title,
            baseSign: 900000,
            baseWeekly: 140000,
            baseObj: 300000,
            objDesc: "objRaceWin",
          ),
        ];
        break;
      case SponsorSlot.frontWing:
      case SponsorSlot.sidepods:
        offers = [
          createOffer(
            id: 'fast_logistics',
            name: 'Fast Logistics',
            tier: SponsorTier.major,
            baseSign: 300000,
            baseWeekly: 50000,
            baseObj: 100000,
            objDesc: "objFinishTop10",
          ),
          createOffer(
            id: 'spark_energy',
            name: 'Spark Energy',
            tier: SponsorTier.major,
            baseSign: 350000,
            baseWeekly: 40000,
            baseObj: 120000,
            objDesc: "objFastestLap",
          ),
          createOffer(
            id: 'eco_pulse',
            name: 'Eco Pulse',
            tier: SponsorTier.major,
            baseSign: 250000,
            baseWeekly: 60000,
            baseObj: 80000,
            objDesc: "objFinishRace",
          ),
        ];
        break;
      default: // Nose / Halo
        offers = [
          createOffer(
            id: 'local_drinks',
            name: 'Local Drinks',
            tier: SponsorTier.partner,
            baseSign: 50000,
            baseWeekly: 15000,
            baseObj: 30000,
            objDesc: "objFinishRace",
          ),
          createOffer(
            id: 'micro_chips',
            name: 'Micro Chips',
            tier: SponsorTier.partner,
            baseSign: 70000,
            baseWeekly: 12000,
            baseObj: 40000,
            objDesc: "objImproveGrid",
          ),
          createOffer(
            id: 'nitro_gear',
            name: 'Nitro Gear',
            tier: SponsorTier.partner,
            baseSign: 60000,
            baseWeekly: 18000,
            baseObj: 35000,
            objDesc: "objOvertake3Cars",
          ),
        ];
    }

    // Apply persisted negotiation state
    for (var offer in offers) {
      if (negotiations.containsKey(offer.id)) {
        final state = negotiations[offer.id] as Map<String, dynamic>;
        offer.attemptsMade = state['attemptsMade'] ?? 0;
        if (state['lockedUntil'] != null) {
          offer.lockedUntil = DateTime.tryParse(state['lockedUntil']);
        }
      }
    }

    return offers;
  }

  Future<NegotiationResult> negotiate({
    required String teamId,
    required SponsorOffer offer,
    required String tactic,
    required SponsorSlot slot,
  }) async {
    // 1. Validation
    if (offer.attemptsMade >= 2) {
      return NegotiationResult(
        NegotiationStatus.locked,
        "Negotiation failed too many times.",
        remainingAttempts: 0,
      );
    }
    if (offer.lockedUntil != null &&
        offer.lockedUntil!.isAfter(DateTime.now())) {
      return NegotiationResult(
        NegotiationStatus.locked,
        "Sponsor is still reconsidering.",
        remainingAttempts: 0,
      );
    }

    // 2. Logic (Purely Tactic Based now)
    double chance = 30.0; // Base chance

    final personalityName = offer.personality.name.toUpperCase();
    final normalizedTactic = tactic.toUpperCase();

    // Map new tactics to old internal ones for comparison if needed
    String effectiveTactic = normalizedTactic;
    if (normalizedTactic == 'PERSUASIVE') effectiveTactic = 'AGGRESSIVE';
    if (normalizedTactic == 'NEGOTIATOR') effectiveTactic = 'PROFESSIONAL';
    if (normalizedTactic == 'COLLABORATIVE') effectiveTactic = 'FRIENDLY';

    // Check Matching
    if (effectiveTactic == personalityName) {
      chance += 50.0; // Perfect match -> 80%
    } else if (effectiveTactic == 'PROFESSIONAL' ||
        personalityName == 'PROFESSIONAL') {
      chance += 10.0; // Neutral match -> 40%
    } else {
      chance -= 20.0; // Opposite match -> 10%
    }

    // Roll
    final random = _random.nextInt(100);
    bool isWin = random < chance;

    if (isWin) {
      await _signContract(teamId, offer, slot);
      return NegotiationResult(NegotiationStatus.success, "Deal Signed!");
    } else {
      offer.attemptsMade++;
      int remaining = 2 - offer.attemptsMade;

      if (offer.attemptsMade >= 2) {
        offer.lockedUntil = DateTime.now().add(const Duration(days: 7));
      }

      // Persist negotiation state
      await _updateNegotiationState(teamId, offer);

      if (offer.attemptsMade >= 2) {
        return NegotiationResult(
          NegotiationStatus.locked,
          "Sponsor walked away.",
          remainingAttempts: 0,
        );
      }

      return NegotiationResult(
        NegotiationStatus.failed,
        "Negotiation failed.",
        remainingAttempts: remaining,
      );
    }
  }

  Future<void> _updateNegotiationState(
    String teamId,
    SponsorOffer offer,
  ) async {
    final teamRef = _db.collection('teams').doc(teamId);
    await _db.runTransaction((transaction) async {
      final teamDoc = await transaction.get(teamRef);
      if (!teamDoc.exists) return;

      Map<String, dynamic> weekStatus = Map<String, dynamic>.from(
        teamDoc.data()?['weekStatus'] ?? {},
      );
      Map<String, dynamic> negotiations = Map<String, dynamic>.from(
        weekStatus['sponsorNegotiations'] ?? {},
      );

      negotiations[offer.id] = {
        'attemptsMade': offer.attemptsMade,
        'lockedUntil': offer.lockedUntil?.toIso8601String(),
      };

      weekStatus['sponsorNegotiations'] = negotiations;
      transaction.update(teamRef, {'weekStatus': weekStatus});
    });
  }

  Future<void> _signContract(
    String teamId,
    SponsorOffer offer,
    SponsorSlot slot,
  ) async {
    final teamRef = _db.collection('teams').doc(teamId);

    final contract = ActiveContract(
      sponsorId: offer.id,
      sponsorName: offer.name,
      slot: slot,
      weeklyBasePayment: offer.weeklyBasePayment,
      racesRemaining: offer.contractDuration,
    );

    await _db.runTransaction((transaction) async {
      final teamDoc = await transaction.get(teamRef);
      if (!teamDoc.exists) return;

      final currentBudget = teamDoc.data()?['budget'] ?? 0;
      final newBudget = currentBudget + offer.signingBonus;

      Map<String, dynamic> sponsors = Map<String, dynamic>.from(
        teamDoc.data()?['sponsors'] ?? {},
      );
      sponsors[slot.name] = contract.toMap();

      // Clear negotiation state for this sponsor when signed
      Map<String, dynamic> weekStatus = Map<String, dynamic>.from(
        teamDoc.data()?['weekStatus'] ?? {},
      );
      Map<String, dynamic> negotiations = Map<String, dynamic>.from(
        weekStatus['sponsorNegotiations'] ?? {},
      );
      negotiations.remove(offer.id);
      weekStatus['sponsorNegotiations'] = negotiations;

      transaction.update(teamRef, {
        'budget': newBudget,
        'sponsors': sponsors,
        'weekStatus': weekStatus,
      });

      final txRef = teamRef.collection('transactions').doc();
      transaction.set(txRef, {
        'id': txRef.id,
        'description': "Signing Bonus: ${offer.name}",
        'amount': offer.signingBonus,
        'date': DateTime.now().toIso8601String(),
        'type': 'SPONSOR',
      });

      // Add "Office News" notification
      await NotificationService().addNotification(
        teamId: teamId,
        title: "New Sponsor",
        message:
            "Signed a new contract with ${offer.name} for the ${slot.name} slot.",
        type: 'SUCCESS',
        actionRoute: '/sponsors',
      );
    });
  }
}
