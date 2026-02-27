import 'dart:math';

class DriverPortraitService {
  static final DriverPortraitService _instance =
      DriverPortraitService._internal();
  factory DriverPortraitService() => _instance;
  DriverPortraitService._internal();

  /// List of male driver image names (a-l)
  static const List<String> _maleImages = [
    'male_driver_a.png',
    'male_driver_b.png',
    'male_driver_c.png',
    'male_driver_d.png',
    'male_driver_e.png',
    'male_driver_f.png',
    'male_driver_g.png',
    'male_driver_h.png',
    'male_driver_i.png',
    'male_driver_j.png',
    'male_driver_k.png',
    'male_driver_l.png',
  ];

  /// List of female driver image names (a-l)
  static const List<String> _femaleImages = [
    'female_driver_a.png',
    'female_driver_b.png',
    'female_driver_c.png',
    'female_driver_d.png',
    'female_driver_e.png',
    'female_driver_f.png',
    'female_driver_g.png',
    'female_driver_h.png',
    'female_driver_i.png',
    'female_driver_j.png',
    'female_driver_k.png',
    'female_driver_l.png',
  ];

  /// Returns the path to a random hyper-realistic driver avatar.
  String getPortraitUrl({
    required String driverId,
    required String gender,
    String? countryCode,
    int? age,
  }) {
    final isFemale = gender.toLowerCase().startsWith('f');
    final seed = driverId.hashCode;
    final random = Random(seed);

    if (isFemale) {
      final imageName = _femaleImages[random.nextInt(_femaleImages.length)];
      return 'drivers/female/$imageName';
    } else {
      final imageName = _maleImages[random.nextInt(_maleImages.length)];
      return 'drivers/male/$imageName';
    }
  }

  /// Helper to get a portrait URL for a driver.
  String getEffectivePortraitUrl({
    required String driverId,
    required String gender,
    String? countryCode,
    int? age,
  }) {
    return getPortraitUrl(
      driverId: driverId,
      gender: gender,
      countryCode: countryCode,
      age: age,
    );
  }
}
