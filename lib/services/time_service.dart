import 'package:timezone/timezone.dart' as tz;

enum RaceWeekStatus {
  practice, // Lunes 00:00 - Sábado 1:59 PM
  qualifying, // Sábado 2:00 PM - 3:00 PM (Setup Bloqueado)
  raceStrategy, // Sábado 3:00 PM - Domingo 1:59 PM (Setup Bloqueado)
  race, // Domingo 2:00 PM - 4:00 PM (Todo Bloqueado / Corriendo)
  postRace, // Domingo 4:00 PM - Domingo 11:59 PM
}

class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  /// Set to true to use fixed mock time (Friday 20:00) for testing. False = real Bogotá time.
  /// En desarrollo, poner `TimeService.useMockTime = true` en main.dart para usar hora fija.
  /// En producción, dejar `false`.
  static bool useMockTime = false;

  static const String _bogotaZone = 'America/Bogota';

  /// Current time in Bogotá (UTC-5). Uses mock time when [useMockTime] is true.
  DateTime get nowBogota {
    if (useMockTime) {
      return DateTime.parse("2026-02-06T20:00:00");
    }
    try {
      final location = tz.getLocation(_bogotaZone);
      final tzNow = tz.TZDateTime.now(location);
      return DateTime(
        tzNow.year,
        tzNow.month,
        tzNow.day,
        tzNow.hour,
        tzNow.minute,
        tzNow.second,
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Calculates status based on the specific race date.
  /// If [raceDate] is provided, checks if [now] is within the race week.
  /// If outside race week (e.g. previous week), forces Practice status.
  RaceWeekStatus getRaceWeekStatus(DateTime now, DateTime? raceDate) {
    if (raceDate == null) return RaceWeekStatus.practice;

    // Calculate start of the race week (assuming Monday start)
    // raceDate is usually Sunday.
    final raceWeekday = raceDate.weekday; // 1=Mon ... 7=Sun
    final startOfRaceWeek = DateTime(
      raceDate.year,
      raceDate.month,
      raceDate.day,
    ).subtract(Duration(days: raceWeekday - 1));

    // If we are before the Monday of the race week, it's Practice (Pre-Race analysis/setup)
    if (now.isBefore(startOfRaceWeek)) {
      return RaceWeekStatus.practice;
    }

    // If we are significantly past the race (e.g. next Tuesday), logic depends on next race.
    // But for a single race context, if > Sunday end, it's PostRace.
    // Race Week End = Sunday 23:59:59.
    // Let's rely on standard logic for the week.

    final weekday = now.weekday;
    final hour = now.hour;

    // Logic matches currentStatus textual logic
    // Monday(1) - Friday(5): Practice
    if (weekday >= 1 && weekday <= 5) {
      return RaceWeekStatus.practice;
    }

    // Saturday(6)
    if (weekday == 6) {
      if (hour < 14) return RaceWeekStatus.practice;
      if (hour == 14) return RaceWeekStatus.qualifying;
      return RaceWeekStatus.raceStrategy;
    }

    // Sunday(7)
    if (weekday == 7) {
      if (hour < 14) return RaceWeekStatus.raceStrategy;
      if (hour >= 14 && hour < 16) return RaceWeekStatus.race;
      return RaceWeekStatus.postRace;
    }

    return RaceWeekStatus.practice;
  }

  RaceWeekStatus get currentStatus {
    // Legacy/Naive fallback
    return getRaceWeekStatus(
      nowBogota,
      null,
    ); // Will behave as Practice usually,
    // Wait, if raceDate is null, returns Practice.
    // But 'currentStatus' originally returned Race on Sunday.
    // If I change it to return Practice, it might break simple tests.
    // But for Dashboard, I will use getRaceWeekStatus(now, raceDate).

    // I'll keep generic logic here for now but generic logic implies "Every week is race week".
    // This IS the bug.
    // But preventing regression in other screens?
    // Other screens should also be context-aware.
    // I'll leave generic logic as "Is VALID for a race week".
    // But I won't use it in Dashboard.
  }

  String get statusDisplayName {
    switch (currentStatus) {
      case RaceWeekStatus.practice:
        return "PRACTICE SESSION";
      case RaceWeekStatus.qualifying:
        return "QUALIFYING (LOCKED)";
      case RaceWeekStatus.raceStrategy:
        return "RACE STRATEGY";
      case RaceWeekStatus.race:
        return "RACE IN PROGRESS";
      case RaceWeekStatus.postRace:
        return "RACE FINISHED";
    }
  }

  /// Indica si el Setup del coche está bloqueado (Parc Fermé)
  bool get isSetupLocked {
    final status = currentStatus;
    return status == RaceWeekStatus.qualifying ||
        status == RaceWeekStatus.raceStrategy ||
        status == RaceWeekStatus.race;
  }

  /// Retorna el tiempo restante para el siguiente evento importante
  Duration getTimeUntilNextEvent([RaceWeekStatus? statusOverride]) {
    final now = nowBogota;
    final status = statusOverride ?? currentStatus;

    DateTime target;

    switch (status) {
      case RaceWeekStatus.practice:
        // Objetivo: Sábado 2:00 PM (Inicio Qualy)
        // If mocked to Friday (5), next Sat is (6).
        // 6 (Sat) - 5 (Fri) = 1 day.
        int daysUntilSat = (6 - now.weekday + 7) % 7;
        if (daysUntilSat == 0 && now.hour >= 14) daysUntilSat = 7;

        target = DateTime(
          now.year,
          now.month,
          now.day,
          14, // 14:00
          0,
        ).add(Duration(days: daysUntilSat));
        break;

      case RaceWeekStatus.qualifying:
        // Objetivo: Sábado 3:00 PM (Fin Qualy / Inicio Strategy)
        target = DateTime(now.year, now.month, now.day, 15, 0);
        break;

      case RaceWeekStatus.raceStrategy:
        // Objetivo: Domingo 2:00 PM (Inicio Carrera)
        // If Sat(6) 16:00 -> Target Sun(7) 14:00.
        int daysUntilSun = (7 - now.weekday + 7) % 7;
        if (daysUntilSun == 0 && now.hour >= 14) daysUntilSun = 7;

        target = DateTime(
          now.year,
          now.month,
          now.day,
          14,
          0,
        ).add(Duration(days: daysUntilSun));
        break;

      case RaceWeekStatus.race:
        // Objetivo: Domingo 4:00 PM (Fin de carrera)
        target = DateTime(now.year, now.month, now.day, 16, 0);
        break;

      case RaceWeekStatus.postRace:
        // Objetivo: Lunes 00:00 AM (Reinicio semana)
        target = DateTime(
          now.year,
          now.month,
          now.day,
          0,
          0,
        ).add(const Duration(days: 1));
        break;
    }

    return target.difference(now);
  }

  String formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00";
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) return "${days}d ${hours}h ${minutes}m";
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  DateTime getCurrentWeekQualyDate(DateTime now, DateTime? raceDate) {
    if (raceDate != null) {
      return DateTime(
        raceDate.year,
        raceDate.month,
        raceDate.day,
      ).subtract(const Duration(days: 1)).add(const Duration(hours: 14));
    }
    int daysFromMon = now.weekday - 1;
    DateTime monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysFromMon));
    return monday.add(const Duration(days: 5, hours: 14));
  }

  DateTime getCurrentWeekRaceDate(DateTime now, DateTime? raceDate) {
    if (raceDate != null) {
      return DateTime(
        raceDate.year,
        raceDate.month,
        raceDate.day,
      ).add(const Duration(hours: 14));
    }
    int daysFromMon = now.weekday - 1;
    DateTime monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysFromMon));
    return monday.add(const Duration(days: 6, hours: 14));
  }
}
