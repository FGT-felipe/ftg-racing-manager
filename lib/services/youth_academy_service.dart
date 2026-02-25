import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/widgets.dart';
import '../models/core_models.dart';
import '../models/user_models.dart';
import '../models/domain/domain_models.dart';
import 'season_service.dart';

/// Servicio para gestionar la Academia de Jóvenes de un equipo.
///
/// Firestore structure:
/// ```
/// teams/{teamId}/
///   academy/
///     config (doc)         → { countryCode, countryName, countryFlag, academyLevel, maxSlots }
///     candidates/ (subcol) → YoungDriver docs (status: 'candidate')
///     selected/ (subcol)   → YoungDriver docs (status: 'selected')
/// ```
class YouthAcademyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── References ──────────────────────────────────────────────────────────
  DocumentReference _configRef(String teamId) =>
      _db.collection('teams').doc(teamId).collection('academy').doc('config');

  CollectionReference _candidatesRef(String teamId) => _db
      .collection('teams')
      .doc(teamId)
      .collection('academy')
      .doc('config')
      .collection('candidates');

  CollectionReference _selectedRef(String teamId) => _db
      .collection('teams')
      .doc(teamId)
      .collection('academy')
      .doc('config')
      .collection('selected');

  // ── Academy Config ──────────────────────────────────────────────────────

  /// Stream the academy configuration for a team.
  /// Returns null if the academy hasn't been purchased yet.
  Stream<Map<String, dynamic>?> streamAcademyConfig(String teamId) {
    return _configRef(teamId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return snap.data() as Map<String, dynamic>?;
    });
  }

  /// Get the academy config as a one-shot read.
  Future<Map<String, dynamic>?> getAcademyConfig(String teamId) async {
    final snap = await _configRef(teamId).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>?;
  }

  /// Purchase the Youth Academy (level 1) for $100,000.
  ///
  /// Creates the config doc, generates 2 initial candidates (1M + 1F),
  /// and records the transaction.
  Future<void> purchaseAcademy(
    String teamId,
    Country country, {
    ManagerRole? role,
  }) async {
    final teamRef = _db.collection('teams').doc(teamId);
    final activeSeason = await SeasonService().getActiveSeason();
    final currentSeasonId = activeSeason?.id ?? 'unknown';

    await _db.runTransaction((txn) async {
      final teamSnap = await txn.get(teamRef);
      if (!teamSnap.exists) throw Exception('Team not found');

      final team = Team.fromMap(teamSnap.data() as Map<String, dynamic>);
      const purchasePrice = 100000;

      if (team.budget < purchasePrice) {
        throw Exception('Insufficient budget to purchase Youth Academy');
      }

      int maxSlots = 2; // 2 × level 1
      if (role == ManagerRole.bureaucrat) {
        maxSlots += 1; // +1 extra slot per level for Bureaucrat
      }

      // Create config doc
      txn.set(_configRef(teamId), {
        'countryCode': country.code,
        'countryName': country.name,
        'countryFlag': country.flagEmoji,
        'academyLevel': 1,
        'maxSlots': maxSlots,
        'lastUpgradeSeasonId': currentSeasonId,
      });

      // Update team budget and facility
      final facility = Facility(
        type: FacilityType.youthAcademy,
        level: 1,
        lastUpgradeSeasonId: currentSeasonId,
      );
      txn.update(teamRef, {
        'budget': team.budget - purchasePrice,
        'facilities.${FacilityType.youthAcademy.name}': facility.toMap(),
      });

      // Record transaction
      final transRef = teamRef.collection('transactions').doc();
      txn.set(
        transRef,
        Transaction(
          id: transRef.id,
          description:
              'Youth Academy purchased (${country.flagEmoji} ${country.name})',
          amount: -purchasePrice,
          date: DateTime.now(),
          type: 'ACADEMY',
        ).toMap(),
      );
    });

    // Generate initial candidates after the transaction completes
    await _generateAndStoreCandidates(teamId, 1, country);
  }

  // ── Candidates ──────────────────────────────────────────────────────────

  /// Stream the current candidates for a team.
  Stream<List<YoungDriver>> streamCandidates(String teamId) {
    return _candidatesRef(teamId).snapshots().map((snap) {
      return snap.docs
          .map((doc) => YoungDriver.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Select (follow) a candidate — moves from candidates to selected.
  Future<void> selectCandidate(String teamId, String candidateId) async {
    final config = await getAcademyConfig(teamId);
    if (config == null) throw Exception('Academy not purchased');

    final maxSlots = config['maxSlots'] ?? 2;

    // Check capacity
    final selectedSnap = await _selectedRef(teamId).get();
    if (selectedSnap.docs.length >= maxSlots) {
      throw Exception('Academy is full. Upgrade to add more slots.');
    }

    // Get candidate
    final candidateDoc = await _candidatesRef(teamId).doc(candidateId).get();
    if (!candidateDoc.exists) throw Exception('Candidate not found');

    final candidate = YoungDriver.fromMap(
      candidateDoc.data() as Map<String, dynamic>,
    );

    // Move to selected
    final selectedDriver = candidate.copyWith(
      status: 'selected',
      selectedAt: DateTime.now(),
      expiresAt: null, // Selected drivers don't expire
    );

    final batch = _db.batch();
    batch.set(_selectedRef(teamId).doc(candidateId), selectedDriver.toMap());
    batch.delete(_candidatesRef(teamId).doc(candidateId));
    await batch.commit();

    // Record salary transaction
    final teamRef = _db.collection('teams').doc(teamId);
    final transRef = teamRef.collection('transactions').doc();
    await transRef.set(
      Transaction(
        id: transRef.id,
        description: 'Academy: ${candidate.name} contract signed',
        amount: -candidate.salary,
        date: DateTime.now(),
        type: 'ACADEMY',
      ).toMap(),
    );

    // Deduct budget
    await teamRef.update({'budget': FieldValue.increment(-candidate.salary)});

    // Check if we need a replacement candidate
    await _ensureTwoCandidates(teamId);
  }

  /// Dismiss a candidate and generate a replacement.
  Future<void> dismissCandidate(String teamId, String candidateId) async {
    final candidateDoc = await _candidatesRef(teamId).doc(candidateId).get();
    if (!candidateDoc.exists) return;

    await _candidatesRef(teamId).doc(candidateId).delete();
    await _ensureTwoCandidates(teamId);
  }

  // ── Selected Drivers ────────────────────────────────────────────────────

  /// Stream the selected (followed) drivers.
  Stream<List<YoungDriver>> streamSelectedDrivers(String teamId) {
    return _selectedRef(teamId).snapshots().map((snap) {
      return snap.docs
          .map((doc) => YoungDriver.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Release a selected driver (stop training). No refund.
  Future<void> releaseSelectedDriver(String teamId, String driverId) async {
    await _selectedRef(teamId).doc(driverId).delete();

    // Record transaction
    final teamRef = _db.collection('teams').doc(teamId);
    final transRef = teamRef.collection('transactions').doc();
    await transRef.set(
      Transaction(
        id: transRef.id,
        description: 'Academy: Driver released from program',
        amount: 0,
        date: DateTime.now(),
        type: 'ACADEMY',
      ).toMap(),
    );
  }

  // ── Academy Upgrade ─────────────────────────────────────────────────────

  /// Upgrade the academy level (+1). Max 5, 1 per season.
  Future<void> upgradeAcademy(String teamId, {ManagerRole? role}) async {
    final teamRef = _db.collection('teams').doc(teamId);
    final activeSeason = await SeasonService().getActiveSeason();
    final currentSeasonId = activeSeason?.id ?? 'unknown';

    return _db.runTransaction((txn) async {
      final teamSnap = await txn.get(teamRef);
      if (!teamSnap.exists) throw Exception('Team not found');

      final team = Team.fromMap(teamSnap.data() as Map<String, dynamic>);
      final configSnap = await txn.get(_configRef(teamId));
      if (!configSnap.exists) throw Exception('Academy not purchased');

      final config = configSnap.data() as Map<String, dynamic>;
      final currentLevel = (config['academyLevel'] as num?)?.toInt() ?? 1;
      final lastUpgradeSeasonId = config['lastUpgradeSeasonId'] as String?;

      if (lastUpgradeSeasonId == currentSeasonId) {
        throw Exception('Youth Academy can only be upgraded once per season.');
      }

      if (currentLevel >= 5) {
        throw Exception('Academy is already at maximum level (5)');
      }

      int upgradePrice = 1000000 * currentLevel;
      if (role == ManagerRole.businessAdmin || role == ManagerRole.bureaucrat) {
        upgradePrice = (upgradePrice * 0.9).round();
      }

      if (team.budget < upgradePrice) {
        throw Exception('Insufficient budget for upgrade');
      }

      final int newLevel = currentLevel + 1;
      int maxSlots = newLevel * 2;

      if (role == ManagerRole.bureaucrat) {
        maxSlots += newLevel; // +1 extra slot per level
      }

      // Update config
      txn.update(_configRef(teamId), {
        'academyLevel': newLevel,
        'maxSlots': maxSlots,
        'lastUpgradeSeasonId': currentSeasonId,
      });

      // Update team budget and facility
      txn.update(teamRef, {
        'budget': team.budget - upgradePrice,
        'facilities.${FacilityType.youthAcademy.name}.level': newLevel,
        'facilities.${FacilityType.youthAcademy.name}.lastUpgradeSeasonId':
            currentSeasonId,
      });

      // Record transaction
      final transRef = teamRef.collection('transactions').doc();
      txn.set(
        transRef,
        Transaction(
          id: transRef.id,
          description: 'Youth Academy upgraded to level $newLevel',
          amount: -upgradePrice,
          date: DateTime.now(),
          type: 'ACADEMY',
        ).toMap(),
      );
    });
  }

  // ── Promote to Main Team ────────────────────────────────────────────────

  /// Promote a young driver to the main team, replacing a specific driver slot.
  ///
  /// The young driver becomes a full Driver with:
  /// - 100% morale
  /// - 50% of normal salary
  /// - Lower morale decay rate
  Future<void> promoteToMainTeam(
    String teamId,
    String youngDriverId,
    String replaceDriverId,
  ) async {
    // Get the young driver
    final youngDoc = await _selectedRef(teamId).doc(youngDriverId).get();
    if (!youngDoc.exists) throw Exception('Young driver not found');

    final youngDriver = YoungDriver.fromMap(
      youngDoc.data() as Map<String, dynamic>,
    );

    // Get the existing driver to know their carIndex
    final teamRef = _db.collection('teams').doc(teamId);
    final existingDriverDoc = await teamRef
        .collection('drivers')
        .doc(replaceDriverId)
        .get();
    if (!existingDriverDoc.exists) {
      throw Exception('Driver to replace not found');
    }

    final existingDriver = Driver.fromMap(
      existingDriverDoc.data() as Map<String, dynamic>,
    );

    // Build stats from the mid-range of their stat ranges
    final stats = <String, int>{};
    final statPotentials = <String, int>{};
    for (final key in DriverStats.all) {
      final min = youngDriver.statRangeMin[key] ?? youngDriver.baseSkill;
      final max =
          youngDriver.statRangeMax[key] ??
          (youngDriver.baseSkill + youngDriver.growthPotential);
      stats[key] = min; // Start at lower bound when promoted
      statPotentials[key] = max;
    }

    // Create the new full Driver
    final newDriver = Driver(
      id: youngDriver.id,
      teamId: teamId,
      carIndex: existingDriver.carIndex,
      name: youngDriver.name,
      age: youngDriver.age,
      potential: youngDriver.potentialStars,
      points: 0,
      gender: youngDriver.gender,
      stats: stats,
      statPotentials: statPotentials,
      traits: [DriverTrait.youngProdigy],
      countryCode: youngDriver.nationality.code,
      role: existingDriver.role,
      salary: (existingDriver.salary * 0.5).round(), // 50% salary
      contractYearsRemaining: 2,
      portraitUrl: youngDriver.portraitUrl,
      statusTitle: 'Academy Graduate',
    );

    // Apply the change
    final batch = _db.batch();

    // Remove young driver from academy
    batch.delete(_selectedRef(teamId).doc(youngDriverId));

    // Replace the existing driver with the promoted one
    batch.set(
      teamRef.collection('drivers').doc(newDriver.id),
      newDriver.toMap(),
    );
    batch.delete(teamRef.collection('drivers').doc(replaceDriverId));

    await batch.commit();

    // Record transaction
    final transRef = teamRef.collection('transactions').doc();
    await transRef.set(
      Transaction(
        id: transRef.id,
        description: 'Academy: ${youngDriver.name} promoted to main team',
        amount: 0,
        date: DateTime.now(),
        type: 'ACADEMY',
      ).toMap(),
    );
  }

  // ── Weekly Refresh ──────────────────────────────────────────────────────

  /// Refresh candidates: expire unselected ones and generate new pair.
  /// Called during the weekly cycle.
  Future<void> refreshCandidates(String teamId) async {
    final config = await getAcademyConfig(teamId);
    if (config == null) return;

    final candidates = await _candidatesRef(teamId).get();
    final batch = _db.batch();

    // Delete expired candidates
    for (final doc in candidates.docs) {
      final driver = YoungDriver.fromMap(doc.data() as Map<String, dynamic>);
      if (driver.isExpired) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();

    // Ensure we always have 2 candidates
    await _ensureTwoCandidates(teamId);
  }

  // ── Private Helpers ────────────────────────────────────────────────────

  /// Ensure there are exactly 2 candidates (1M + 1F).
  Future<void> _ensureTwoCandidates(String teamId) async {
    final config = await getAcademyConfig(teamId);
    if (config == null) return;

    final level = config['academyLevel'] ?? 1;
    final countryCode = config['countryCode'] ?? 'CO';
    final countryName = config['countryName'] ?? 'Colombia';
    final countryFlag = config['countryFlag'] ?? '🇨🇴';

    final country = Country(
      code: countryCode,
      name: countryName,
      flagEmoji: countryFlag,
    );

    final candidatesSnap = await _candidatesRef(teamId).get();
    final existing = candidatesSnap.docs
        .map((d) => YoungDriver.fromMap(d.data() as Map<String, dynamic>))
        .toList();

    final hasMale = existing.any((d) => d.gender == 'M');
    final hasFemale = existing.any((d) => d.gender == 'F');

    final factory = YouthAcademyFactory();

    if (!hasMale) {
      final male = factory.generateReplacement(
        academyLevel: level,
        country: country,
        gender: 'M',
      );
      await _candidatesRef(teamId).doc(male.id).set(male.toMap());
    }

    if (!hasFemale) {
      final female = factory.generateReplacement(
        academyLevel: level,
        country: country,
        gender: 'F',
      );
      await _candidatesRef(teamId).doc(female.id).set(female.toMap());
    }
  }

  /// Generate and store initial candidates.
  Future<void> _generateAndStoreCandidates(
    String teamId,
    int level,
    Country country,
  ) async {
    final factory = YouthAcademyFactory();
    final pair = factory.generateCandidatePair(
      academyLevel: level,
      country: country,
    );

    for (final driver in pair) {
      await _candidatesRef(teamId).doc(driver.id).set(driver.toMap());
    }

    debugPrint(
      'ACADEMY: Generated ${pair.length} initial candidates for team $teamId',
    );
  }
}
