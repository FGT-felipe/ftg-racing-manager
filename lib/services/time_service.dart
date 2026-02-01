class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  String getCurrentPhase() {
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return "RACE_WEEKEND";
    }
    return "PREPARATION";
  }

  Duration getTimeUntilRace() {
    final now = DateTime.now();
    // Goal: Next Sunday at 14:00
    DateTime target = DateTime(now.year, now.month, now.day, 14, 0);

    // Adjust to next Sunday
    int daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    if (daysUntilSunday == 0 && now.hour >= 14) {
      daysUntilSunday = 7;
    }

    target = target.add(Duration(days: daysUntilSunday));
    return target.difference(now);
  }

  String formatDuration(Duration duration) {
    if (duration.isNegative) return "0d 0h";
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    return "${days}d ${hours}h";
  }
}
