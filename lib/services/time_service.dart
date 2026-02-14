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
  static bool useMockTime = true;

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

  RaceWeekStatus get currentStatus {
    final now = nowBogota;
    final weekday = now.weekday; // 1 = Mon ... 5=Fri, 6=Sat, 7=Sun
    final hour = now.hour;

    // Lunes (1) a Viernes (5) -> Todo es práctica
    if (weekday >= 1 && weekday <= 5) {
      return RaceWeekStatus.practice;
    }

    // Sábado (6)
    if (weekday == 6) {
      if (hour < 14) return RaceWeekStatus.practice; // Hasta las 1:59:59 PM
      if (hour == 14) return RaceWeekStatus.qualifying; // 2:00 PM - 2:59:59 PM
      return RaceWeekStatus.raceStrategy; // 3:00 PM en adelante
    }

    // Domingo (7)
    if (weekday == 7) {
      if (hour < 14) return RaceWeekStatus.raceStrategy; // Hasta las 1:59:59 PM
      if (hour >= 14 && hour < 16)
        return RaceWeekStatus.race; // 2:00 PM - 3:59:59 PM
      return RaceWeekStatus.postRace; // 4:00 PM en adelante
    }

    return RaceWeekStatus.practice; // Fallback
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
  Duration getTimeUntilNextEvent() {
    final now = nowBogota;
    final status = currentStatus;

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
}
