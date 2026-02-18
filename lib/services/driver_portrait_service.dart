class DriverPortraitService {
  static final DriverPortraitService _instance =
      DriverPortraitService._internal();
  factory DriverPortraitService() => _instance;
  DriverPortraitService._internal();

  /// Returns the path to the hyper-realistic driver avatar.
  /// Uses specific assets provided by the user.
  String getPortraitUrl({
    required String driverId,
    required String countryCode,
    required String gender,
    required int age,
  }) {
    final isFemale = gender.toLowerCase().startsWith('f');

    if (isFemale) {
      return 'assets/drivers/Gemini_Generated_Image_yl6vheyl6vheyl6v.png';
    } else {
      return 'assets/drivers/Gemini_Generated_Image_vdio0kvdio0kvdio.png';
    }
  }

  /// Helper to get a portrait URL for a driver.
  String getEffectivePortraitUrl({
    required String driverId,
    required String countryCode,
    required String gender,
    required int age,
  }) {
    return getPortraitUrl(
      driverId: driverId,
      countryCode: countryCode,
      gender: gender,
      age: age,
    );
  }
}
