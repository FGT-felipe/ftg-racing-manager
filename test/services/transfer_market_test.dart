import 'package:flutter_test/flutter_test.dart';
import 'package:ftg_racing_manager/models/core_models.dart';
import 'package:ftg_racing_manager/services/driver_portrait_service.dart';

/// Helper to create a minimal Driver map for testing
Map<String, dynamic> _makeDriverMap({
  String id = 'driver_001',
  String name = 'Test Driver',
  int age = 25,
  int potential = 3,
  String gender = 'M',
  String countryCode = 'BR',
  String? portraitUrl,
  bool isTransferListed = false,
  String? transferListedAt,
  int currentHighestBid = 0,
  String? highestBidderTeamId,
  String? highestBidderTeamName,
}) {
  return {
    'id': id,
    'name': name,
    'age': age,
    'potential': potential,
    'points': 0,
    'gender': gender,
    'countryCode': countryCode,
    'stats': {
      'braking': 60,
      'cornering': 55,
      'smoothness': 50,
      'overtaking': 65,
      'consistency': 58,
      'adaptability': 52,
      'fitness': 70,
      'feedback': 45,
      'focus': 60,
      'morale': 75,
      'marketability': 40,
    },
    if (portraitUrl != null) 'portraitUrl': portraitUrl,
    'isTransferListed': isTransferListed,
    if (transferListedAt != null) 'transferListedAt': transferListedAt,
    'currentHighestBid': currentHighestBid,
    if (highestBidderTeamId != null) 'highestBidderTeamId': highestBidderTeamId,
    if (highestBidderTeamName != null)
      'highestBidderTeamName': highestBidderTeamName,
  };
}

void main() {
  group('Transfer Market - Portrait URL Consistency', () {
    test('Driver.fromMap preserves portraitUrl when set', () {
      const expectedUrl = 'drivers/male/male_driver_c.png';
      final map = _makeDriverMap(portraitUrl: expectedUrl);

      final driver = Driver.fromMap(map);

      expect(driver.portraitUrl, expectedUrl);
    });

    test('Driver.fromMap returns null portraitUrl when not in map', () {
      final map = _makeDriverMap();

      final driver = Driver.fromMap(map);

      expect(driver.portraitUrl, isNull);
    });

    test('Driver portraitUrl survives toMap/fromMap roundtrip', () {
      const expectedUrl = 'drivers/female/female_driver_b.png';
      final original = Driver.fromMap(_makeDriverMap(portraitUrl: expectedUrl));

      final serialized = original.toMap();
      final restored = Driver.fromMap(serialized);

      expect(restored.portraitUrl, original.portraitUrl);
      expect(restored.portraitUrl, expectedUrl);
    });

    test(
      'DriverPortraitService returns deterministic result for same driverId',
      () {
        final service = DriverPortraitService();

        final url1 = service.getPortraitUrl(
          driverId: 'abc123',
          gender: 'M',
          countryCode: 'BR',
          age: 22,
        );
        final url2 = service.getPortraitUrl(
          driverId: 'abc123',
          gender: 'M',
          countryCode: 'BR',
          age: 22,
        );

        expect(url1, url2);
      },
    );

    test(
      'Portrait set by DriverPortraitService matches getEffectivePortraitUrl with same driverId',
      () {
        final service = DriverPortraitService();
        const driverId = 'driver_xyz_456';
        const gender = 'F';

        final setUrl = service.getPortraitUrl(
          driverId: driverId,
          gender: gender,
        );
        final effectiveUrl = service.getEffectivePortraitUrl(
          driverId: driverId,
          gender: gender,
        );

        expect(
          setUrl,
          effectiveUrl,
          reason:
              'Table and detail card should show the same avatar when using the same driverId',
        );
      },
    );
  });

  group('Transfer Market - Transfer Fields Serialization', () {
    test('Driver.fromMap preserves all transfer market fields', () {
      final listedAt = DateTime(2026, 3, 4, 12, 0, 0);
      final map = _makeDriverMap(
        isTransferListed: true,
        transferListedAt: listedAt.toIso8601String(),
        currentHighestBid: 500000,
        highestBidderTeamId: 'team_abc',
        highestBidderTeamName: 'Racing Bulls',
      );

      final driver = Driver.fromMap(map);

      expect(driver.isTransferListed, true);
      expect(driver.transferListedAt, listedAt);
      expect(driver.currentHighestBid, 500000);
      expect(driver.highestBidderTeamId, 'team_abc');
      expect(driver.highestBidderTeamName, 'Racing Bulls');
    });

    test('Transfer market fields survive toMap/fromMap roundtrip', () {
      final listedAt = DateTime(2026, 3, 4, 12, 0, 0);
      final original = Driver.fromMap(
        _makeDriverMap(
          isTransferListed: true,
          transferListedAt: listedAt.toIso8601String(),
          currentHighestBid: 750000,
          highestBidderTeamId: 'team_xyz',
          highestBidderTeamName: 'Speed Demons',
          portraitUrl: 'drivers/male/male_driver_a.png',
        ),
      );

      final serialized = original.toMap();
      final restored = Driver.fromMap(serialized);

      expect(restored.isTransferListed, original.isTransferListed);
      expect(restored.transferListedAt, original.transferListedAt);
      expect(restored.currentHighestBid, original.currentHighestBid);
      expect(restored.highestBidderTeamId, original.highestBidderTeamId);
      expect(restored.highestBidderTeamName, original.highestBidderTeamName);
      expect(restored.portraitUrl, original.portraitUrl);
    });
  });

  group('Transfer Market - Countdown Expiry Logic', () {
    test('expired transfer has negative time difference', () {
      final listedAt = DateTime.now().subtract(const Duration(hours: 25));
      final expiresAt = listedAt.add(const Duration(hours: 24));
      final diff = expiresAt.difference(DateTime.now());

      expect(
        diff.isNegative,
        true,
        reason: 'A transfer listed 25h ago should have expired',
      );
    });

    test('active transfer has positive time difference', () {
      final listedAt = DateTime.now().subtract(const Duration(hours: 12));
      final expiresAt = listedAt.add(const Duration(hours: 24));
      final diff = expiresAt.difference(DateTime.now());

      expect(
        diff.isNegative,
        false,
        reason: 'A transfer listed 12h ago should still be active',
      );
    });

    test('transfer in last 5 minutes has positive but small diff', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 3));
      final diff = expiresAt.difference(DateTime.now());

      expect(diff.isNegative, false);
      expect(
        diff.inMinutes,
        lessThan(5),
        reason: 'Should be in the lockout zone',
      );
    });
  });
}
