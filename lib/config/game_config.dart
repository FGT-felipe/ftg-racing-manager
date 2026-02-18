class GameConfig {
  /// Configuration for the Season Start Date.
  /// If provided, the database seeder will use this date to anchor the schedule.
  /// The first race will be scheduled relative to this date.
  /// Example: DateTime(2026, 2, 22) to start season on Feb 22, 2026.
  static final DateTime seasonStart = DateTime(2026, 2, 22);

  /// Set to true to wipe and reseed the database on app launch.
  /// IMPORTANT: Set back to false after running once!
  static const bool shouldReset = false;
}
