import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class League {
  final String id;
  final String name;

  League({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory League.fromMap(Map<String, dynamic> map) {
    return League(id: map['id'] ?? '', name: map['name'] ?? '');
  }
}

class RaceEvent {
  final String id;
  final String trackName;
  final String countryCode;
  final String flagEmoji;

  /// Circuit identifier for CircuitService (e.g. 'interlagos', 'monza').
  /// Used to get ideal setup and lap time. If null/empty, generic circuit is used.
  final String circuitId;
  final DateTime date;
  final bool isCompleted;
  final int totalLaps;
  final String weatherPractice;
  final String weatherQualifying;
  final String weatherRace;

  RaceEvent({
    required this.id,
    required this.trackName,
    required this.countryCode,
    this.flagEmoji = '🏁',
    this.circuitId = 'generic',
    required this.date,
    required this.isCompleted,
    this.totalLaps = 50,
    this.weatherPractice = 'Sunny',
    this.weatherQualifying = 'Cloudy',
    this.weatherRace = 'Sunny',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackName': trackName,
      'countryCode': countryCode,
      'flagEmoji': flagEmoji,
      'circuitId': circuitId,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'totalLaps': totalLaps,
      'weatherPractice': weatherPractice,
      'weatherQualifying': weatherQualifying,
      'weatherRace': weatherRace,
    };
  }

  factory RaceEvent.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return RaceEvent(
      id: map['id'] ?? '',
      trackName: map['trackName'] ?? '',
      countryCode: map['countryCode'] ?? '',
      flagEmoji: map['flagEmoji'] ?? '🏁',
      circuitId: map['circuitId'] ?? 'generic',
      date: date,
      isCompleted: map['isCompleted'] ?? false,
      totalLaps: map['totalLaps'] ?? 50,
      weatherPractice: map['weatherPractice'] ?? 'Sunny',
      weatherQualifying: map['weatherQualifying'] ?? 'Cloudy',
      weatherRace: map['weatherRace'] ?? 'Sunny',
    );
  }
}

class Season {
  final String id;
  final String leagueId;
  final int number; // e.g. 1, 2, 3
  final int year;
  final List<RaceEvent> calendar;
  final DateTime startDate;

  Season({
    required this.id,
    required this.leagueId,
    required this.number,
    required this.year,
    required this.calendar,
    required this.startDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'leagueId': leagueId,
      'number': number,
      'year': year,
      'calendar': calendar.map((e) => e.toMap()).toList(),
      'startDate': Timestamp.fromDate(startDate),
    };
  }

  factory Season.fromMap(Map<String, dynamic> map) {
    final rawStart = map['startDate'];
    DateTime start;
    if (rawStart is Timestamp) {
      start = rawStart.toDate();
    } else if (rawStart is String) {
      start = DateTime.tryParse(rawStart) ?? DateTime.now();
    } else {
      start = DateTime.now();
    }

    return Season(
      id: map['id'] ?? '',
      leagueId: map['leagueId'] ?? '',
      number: map['number'] ?? 1,
      year: map['year'] ?? 2024,
      startDate: start,
      calendar: (map['calendar'] as List? ?? [])
          .map((e) => RaceEvent.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class Division {
  final String id;
  final String leagueId;
  final String name;
  final int level;

  Division({
    required this.id,
    required this.leagueId,
    required this.name,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'leagueId': leagueId, 'name': name, 'level': level};
  }

  factory Division.fromMap(Map<String, dynamic> map) {
    return Division(
      id: map['id'] ?? '',
      leagueId: map['leagueId'] ?? '',
      name: map['name'] ?? '',
      level: map['level'] ?? 1,
    );
  }
}

class Transaction {
  final String id;
  final String description;
  final int amount;
  final DateTime date;
  final String type; // 'SPONSOR', 'SALARY', 'UPGRADE', 'REWARD', 'PRACTICE'

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: map['amount'] ?? 0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      type: map['type'] ?? 'OTHER',
    );
  }
}

class NewsItem {
  final String headline;
  final String body;
  final String? imageUrl;
  final DateTime date;
  final String source;

  NewsItem({
    required this.headline,
    required this.body,
    this.imageUrl,
    required this.date,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'headline': headline,
      'body': body,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'source': source,
    };
  }

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      headline: map['headline'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      source: map['source'] ?? 'General',
    );
  }
}

enum SponsorTier { title, major, partner }

enum SponsorSlot { rearWing, frontWing, sidepods, nose, halo }

enum SponsorPersonality { aggressive, professional, friendly }

class SponsorOffer {
  final String id;
  final String name;
  final SponsorTier tier;
  final int signingBonus;
  final int weeklyBasePayment;
  final int objectiveBonus;
  final String objectiveDescription;
  final int consecutiveFailuresAllowed;
  final SponsorPersonality personality;
  final int contractDuration; // Number of races
  final bool isAdminBonusApplied;
  int attemptsMade;
  DateTime? lockedUntil;

  SponsorOffer({
    required this.id,
    required this.name,
    required this.tier,
    required this.signingBonus,
    required this.weeklyBasePayment,
    required this.objectiveBonus,
    required this.objectiveDescription,
    required this.personality,
    required this.contractDuration,
    this.isAdminBonusApplied = false,
    this.consecutiveFailuresAllowed = 2,
    this.attemptsMade = 0,
    this.lockedUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tier': tier.name,
      'signingBonus': signingBonus,
      'weeklyBasePayment': weeklyBasePayment,
      'objectiveBonus': objectiveBonus,
      'objectiveDescription': objectiveDescription,
      'consecutiveFailuresAllowed': consecutiveFailuresAllowed,
      'personality': personality.name,
      'contractDuration': contractDuration,
      'isAdminBonusApplied': isAdminBonusApplied,
      'attemptsMade': attemptsMade,
      'lockedUntil': lockedUntil?.toIso8601String(),
    };
  }

  factory SponsorOffer.fromMap(Map<String, dynamic> map) {
    return SponsorOffer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      tier: SponsorTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => SponsorTier.partner,
      ),
      signingBonus: map['signingBonus'] ?? 0,
      weeklyBasePayment: map['weeklyBasePayment'] ?? 0,
      objectiveBonus: map['objectiveBonus'] ?? 0,
      objectiveDescription: map['objectiveDescription'] ?? '',
      consecutiveFailuresAllowed: map['consecutiveFailuresAllowed'] ?? 2,
      personality: SponsorPersonality.values.firstWhere(
        (e) => e.name == map['personality'],
        orElse: () => SponsorPersonality.professional,
      ),
      contractDuration: map['contractDuration'] ?? 5,
      isAdminBonusApplied: map['isAdminBonusApplied'] ?? false,
      attemptsMade: map['attemptsMade'] ?? 0,
      lockedUntil: map['lockedUntil'] != null
          ? DateTime.parse(map['lockedUntil'])
          : null,
    );
  }
}

class ActiveContract {
  final String sponsorId;
  final String sponsorName;
  final SponsorSlot slot;
  final int currentFailures;
  final int weeklyBasePayment;
  final int racesRemaining;

  ActiveContract({
    required this.sponsorId,
    required this.sponsorName,
    required this.slot,
    this.currentFailures = 0,
    required this.weeklyBasePayment,
    required this.racesRemaining,
  });

  Map<String, dynamic> toMap() {
    return {
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'slot': slot.name,
      'currentFailures': currentFailures,
      'weeklyBasePayment': weeklyBasePayment,
      'racesRemaining': racesRemaining,
    };
  }

  factory ActiveContract.fromMap(Map<String, dynamic> map) {
    return ActiveContract(
      sponsorId: map['sponsorId'] ?? '',
      sponsorName: map['sponsorName'] ?? '',
      slot: SponsorSlot.values.firstWhere((e) => e.name == map['slot']),
      currentFailures: map['currentFailures'] ?? 0,
      weeklyBasePayment: map['weeklyBasePayment'] ?? 0,
      racesRemaining: map['racesRemaining'] ?? 0,
    );
  }
}

class Team {
  final String id;
  final String name;
  final String? managerId;
  final bool isBot;
  final int budget;
  final int points;
  final int races;
  final int wins;
  final int podiums;
  final int poles;

  // Seasonal standings data
  final int seasonPoints;
  final int seasonRaces;
  final int seasonWins;
  final int seasonPodiums;
  final int seasonPoles;
  final int nameChangeCount;

  final Map<String, Map<String, int>> carStats;
  final Map<String, dynamic> weekStatus;
  final Map<String, ActiveContract> sponsors;
  final Map<String, Facility> facilities;

  Team({
    required this.id,
    required this.name,
    this.managerId,
    required this.isBot,
    required this.budget,
    required this.points,
    this.races = 0,
    this.wins = 0,
    this.podiums = 0,
    this.poles = 0,
    this.seasonPoints = 0,
    this.seasonRaces = 0,
    this.seasonWins = 0,
    this.seasonPodiums = 0,
    this.seasonPoles = 0,
    this.nameChangeCount = 0,
    required this.carStats,
    required this.weekStatus,
    this.sponsors = const {},
    this.facilities = const {},
  });

  /// Check if a driver has submitted their setup for the current session.
  bool hasSubmittedSetup(String driverId) {
    final driverData = weekStatus['driverSetups']?[driverId];
    return driverData?['isSetupSent'] == true;
  }

  /// Indicates if the team is currently locked for post-race processing.
  bool get isLockedForProcessing => weekStatus['isLockedForProcessing'] == true;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'managerId': managerId,
      'isBot': isBot,
      'budget': budget,
      'points': points,
      'races': races,
      'wins': wins,
      'podiums': podiums,
      'poles': poles,
      'seasonPoints': seasonPoints,
      'seasonRaces': seasonRaces,
      'seasonWins': seasonWins,
      'seasonPodiums': seasonPodiums,
      'seasonPoles': seasonPoles,
      'nameChangeCount': nameChangeCount,
      'carStats': carStats,
      'weekStatus': weekStatus,
      'sponsors': sponsors.map((k, v) => MapEntry(k, v.toMap())),
      'facilities': facilities.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    // Migration logic for carStats
    Map<String, Map<String, int>> carStatsMap = {};
    final rawCarStats = map['carStats'];

    if (rawCarStats is Map) {
      if (rawCarStats.containsKey('0') || rawCarStats.containsKey('1')) {
        // New structure
        carStatsMap = {
          '0': Map<String, int>.from(
            rawCarStats['0'] ??
                {'aero': 1, 'powertrain': 1, 'chassis': 1, 'reliability': 1},
          ),
          '1': Map<String, int>.from(
            rawCarStats['1'] ??
                {'aero': 1, 'powertrain': 1, 'chassis': 1, 'reliability': 1},
          ),
        };
      } else {
        // Old structure: migrate single car stats to both cars
        final stats = Map<String, int>.from(rawCarStats);
        // Rename engine to powertrain if it exists
        if (stats.containsKey('engine')) {
          stats['powertrain'] = stats.remove('engine')!;
        }
        stats.putIfAbsent('chassis', () => 1);
        carStatsMap = {'0': stats, '1': Map<String, int>.from(stats)};
      }
    } else {
      // Default
      final defaultStats = {
        'aero': 1,
        'powertrain': 1,
        'chassis': 1,
        'reliability': 1,
      };
      carStatsMap = {
        '0': defaultStats,
        '1': Map<String, int>.from(defaultStats),
      };
    }

    return Team(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      managerId: map['managerId'],
      isBot: map['isBot'] ?? false,
      budget: map['budget'] ?? 0,
      points: map['points'] ?? 0,
      races: map['races'] ?? 0,
      wins: map['wins'] ?? 0,
      podiums: map['podiums'] ?? 0,
      poles: map['poles'] ?? 0,
      seasonPoints: map['seasonPoints'] ?? 0,
      seasonRaces: map['seasonRaces'] ?? 0,
      seasonWins: map['seasonWins'] ?? 0,
      seasonPodiums: map['seasonPodiums'] ?? 0,
      seasonPoles: map['seasonPoles'] ?? 0,
      nameChangeCount: map['nameChangeCount'] ?? 0,
      carStats: carStatsMap,
      weekStatus: Map<String, dynamic>.from(map['weekStatus'] ?? {}),
      sponsors: (map['sponsors'] as Map<String, dynamic>? ?? {}).map(
        (k, v) =>
            MapEntry(k, ActiveContract.fromMap(Map<String, dynamic>.from(v))),
      ),
      facilities: (map['facilities'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, Facility.fromMap(Map<String, dynamic>.from(v))),
      ),
    );
  }

  Team copyWith({
    String? id,
    String? name,
    String? managerId,
    bool? isBot,
    int? budget,
    int? points,
    int? races,
    int? wins,
    int? podiums,
    int? poles,
    int? seasonPoints,
    int? seasonRaces,
    int? seasonWins,
    int? seasonPodiums,
    int? seasonPoles,
    int? nameChangeCount,
    Map<String, Map<String, int>>? carStats,
    Map<String, dynamic>? weekStatus,
    Map<String, ActiveContract>? sponsors,
    Map<String, Facility>? facilities,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      managerId: managerId ?? this.managerId,
      isBot: isBot ?? this.isBot,
      budget: budget ?? this.budget,
      points: points ?? this.points,
      races: races ?? this.races,
      wins: wins ?? this.wins,
      podiums: podiums ?? this.podiums,
      poles: poles ?? this.poles,
      seasonPoints: seasonPoints ?? this.seasonPoints,
      seasonRaces: seasonRaces ?? this.seasonRaces,
      seasonWins: seasonWins ?? this.seasonWins,
      seasonPodiums: seasonPodiums ?? this.seasonPodiums,
      seasonPoles: seasonPoles ?? this.seasonPoles,
      nameChangeCount: nameChangeCount ?? this.nameChangeCount,
      carStats: carStats ?? this.carStats,
      weekStatus: weekStatus ?? this.weekStatus,
      sponsors: sponsors ?? this.sponsors,
      facilities: facilities ?? this.facilities,
    );
  }
}

enum FacilityType {
  teamOffice,
  garage,
  youthAcademy,
  pressRoom,
  scoutingOffice,
  racingSimulator,
  gym,
  rdOffice,
}

class Facility {
  final FacilityType type;
  final int level;
  final bool isLocked;
  final String? lastUpgradeSeasonId;

  Facility({
    required this.type,
    this.level = 0,
    this.isLocked = false,
    this.lastUpgradeSeasonId,
  });

  String get name {
    switch (type) {
      case FacilityType.teamOffice:
        return "Team Office";
      case FacilityType.garage:
        return "Garage";
      case FacilityType.youthAcademy:
        return "Youth Academy";
      case FacilityType.pressRoom:
        return "Press Room";
      case FacilityType.scoutingOffice:
        return "Scouting Office";
      case FacilityType.racingSimulator:
        return "Racing Simulator";
      case FacilityType.gym:
        return "Gym";
      case FacilityType.rdOffice:
        return "R&D Office";
    }
  }

  bool get isSoon {
    return type == FacilityType.pressRoom ||
        type == FacilityType.scoutingOffice ||
        type == FacilityType.racingSimulator ||
        type == FacilityType.gym ||
        type == FacilityType.rdOffice;
  }

  int get upgradePrice {
    if (level >= 5) return 0;

    // Youth Academy overrides base price when upgrading (level > 0).
    // Level 0 (to buy) is 100000. Level 1->2 is 1M, 2->3 is 2M, etc.
    if (type == FacilityType.youthAcademy && level > 0) {
      return 1000000 * level;
    }

    // Base prices
    int basePrice = 100000;
    // level 0 (to buy): 100k
    // level 1: 200k
    // level 2: 300k
    return basePrice * (level + 1);
  }

  int get maintenanceCost {
    if (level == 0) return 0;
    // 10% of the next upgrade price or fixed based on current level
    return level * 15000;
  }

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case FacilityType.teamOffice:
        return l10n.facTeamOffice;
      case FacilityType.garage:
        return l10n.facGarage;
      case FacilityType.youthAcademy:
        return l10n.facYouthAcademy;
      case FacilityType.pressRoom:
        return l10n.facPressRoom;
      case FacilityType.scoutingOffice:
        return l10n.facScoutingOffice;
      case FacilityType.racingSimulator:
        return l10n.facRacingSimulator;
      case FacilityType.gym:
        return l10n.facGym;
      case FacilityType.rdOffice:
        return l10n.facRDOffice;
    }
  }

  String getLocalizedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case FacilityType.teamOffice:
        return l10n.descTeamOffice;
      case FacilityType.garage:
        return l10n.descGarage;
      case FacilityType.youthAcademy:
        return l10n.descYouthAcademy;
      case FacilityType.pressRoom:
        return l10n.descPressRoom;
      case FacilityType.scoutingOffice:
        return l10n.descScoutingOffice;
      case FacilityType.racingSimulator:
        return l10n.descRacingSimulator;
      case FacilityType.gym:
        return l10n.descGym;
      case FacilityType.rdOffice:
        return l10n.descRDOffice;
    }
  }

  String getLocalizedBonus(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (level == 0) return l10n.notPurchased;
    switch (type) {
      case FacilityType.teamOffice:
        return l10n.bonusBudget((level * 5).toString());
      case FacilityType.garage:
        return l10n.bonusRepair((level * 2).toString());
      case FacilityType.youthAcademy:
        return l10n.bonusScouting((level * 10).toString());
      default:
        return l10n.bonusTBD;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'level': level,
      'isLocked': isLocked,
      if (lastUpgradeSeasonId != null)
        'lastUpgradeSeasonId': lastUpgradeSeasonId,
    };
  }

  factory Facility.fromMap(Map<String, dynamic> map) {
    return Facility(
      type: FacilityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FacilityType.teamOffice,
      ),
      level: map['level'] ?? 0,
      isLocked: map['isLocked'] ?? false,
      lastUpgradeSeasonId: map['lastUpgradeSeasonId'],
    );
  }

  Facility copyWith({int? level, bool? isLocked, String? lastUpgradeSeasonId}) {
    return Facility(
      type: type,
      level: level ?? this.level,
      isLocked: isLocked ?? this.isLocked,
      lastUpgradeSeasonId: lastUpgradeSeasonId ?? this.lastUpgradeSeasonId,
    );
  }
}

/// Rasgos especiales que puede tener un piloto.
/// Cada rasgo otorga bonificaciones o penalizaciones en la simulación.
enum DriverTrait {
  /// Arranca muy bien la primera vuelta (+5 overtaking en vuelta 1)
  firstLapHero,

  /// Padre o familiar famoso en el mundo del motor (mejora marketability)
  famousFamily,

  /// Experto en lluvia (+10 adaptability en condiciones húmedas)
  rainMaster,

  /// Piloto agresivo (mejor overtaking, pero más riesgo de colisión)
  aggressive,

  /// Suavísimo con los neumáticos (reduce desgaste un 15%)
  tyreSaver,

  /// Piloto veterano experimentado (consistency +5 después de los 35)
  veteran,

  /// Joven promesa (aprende un 20% más rápido antes de los 23)
  youngProdigy,
}

/// Nombres legibles para los rasgos
extension DriverTraitExtension on DriverTrait {
  String get displayName {
    switch (this) {
      case DriverTrait.firstLapHero:
        return 'Héroe de la Primera Vuelta';
      case DriverTrait.famousFamily:
        return 'Familia Famosa';
      case DriverTrait.rainMaster:
        return 'Maestro de la Lluvia';
      case DriverTrait.aggressive:
        return 'Piloto Agresivo';
      case DriverTrait.tyreSaver:
        return 'Cuidador de Neumáticos';
      case DriverTrait.veteran:
        return 'Veterano Experimentado';
      case DriverTrait.youngProdigy:
        return 'Joven Prodigio';
    }
  }

  String get description {
    switch (this) {
      case DriverTrait.firstLapHero:
        return '+5 Adelantamiento en la primera vuelta';
      case DriverTrait.famousFamily:
        return '+10 Comercialidad';
      case DriverTrait.rainMaster:
        return '+10 Adaptabilidad en lluvia';
      case DriverTrait.aggressive:
        return '+5 Adelantamiento, mayor riesgo de colisión';
      case DriverTrait.tyreSaver:
        return '-15% desgaste de neumáticos';
      case DriverTrait.veteran:
        return '+5 Consistencia después de los 35';
      case DriverTrait.youngProdigy:
        return '+20% velocidad de aprendizaje antes de los 23';
    }
  }
}

/// Claves de estadísticas del piloto.
/// Usadas para acceder a [Driver.stats] y [Driver.statPotentials].
class DriverStats {
  // --- Habilidades de Conducción ---
  /// Qué tan tarde puede frenar antes de una curva. Reduce bloqueo de neumáticos.
  static const String braking = 'braking';

  /// Velocidad de paso por curva y precisión en la línea de carrera.
  static const String cornering = 'cornering';

  /// Reduce la tasa de desgaste de neumáticos. Crítico para estrategia.
  static const String smoothness = 'smoothness';

  /// Capacidad para ver huecos y concretar maniobras de rebase.
  static const String overtaking = 'overtaking';

  /// Reduce la variabilidad de tiempos de vuelta.
  static const String consistency = 'consistency';

  /// Rapidez para adaptarse a cambios de setup y condiciones climáticas.
  static const String adaptability = 'adaptability';

  // --- Estadísticas Mentales y de Equipo ---
  /// Controla la caída de rendimiento físico durante la carrera.
  static const String fitness = 'fitness';

  /// Velocidad y precisión para generar puntos de conocimiento en prácticas.
  static const String feedback = 'feedback';

  /// Probabilidad de cometer errores bajo presión o verse en colisiones.
  static const String focus = 'focus';

  /// Felicidad del piloto. Alta moral mejora rendimiento.
  static const String morale = 'morale';

  // --- Atributos Externos ---
  /// Atrae mejores patrocinadores. Crucial para las finanzas del equipo.
  static const String marketability = 'marketability';

  /// Lista de todas las claves de stats de conducción (afectan tiempos de vuelta)
  static const List<String> drivingStats = [
    braking,
    cornering,
    smoothness,
    overtaking,
    consistency,
    adaptability,
  ];

  /// Lista de todas las claves de stats mentales
  static const List<String> mentalStats = [fitness, feedback, focus, morale];

  /// Lista de todas las claves de stats
  static const List<String> all = [
    braking,
    cornering,
    smoothness,
    overtaking,
    consistency,
    adaptability,
    fitness,
    feedback,
    focus,
    morale,
    marketability,
  ];

  /// Stats que declinan con la edad (físicos)
  static const List<String> physicalStats = [fitness, braking];

  /// Stats que pueden mejorar con la experiencia (veteranos)
  static const List<String> experienceStats = [feedback, consistency, focus];
}

class Driver {
  final String id;
  final String? teamId;
  final int carIndex; // 0 for Car A, 1 for Car B
  final String name;
  final int age;

  /// Potencial global como estrellas de ojeo (1-5).
  /// Indica el techo general del piloto visible para el manager.
  /// El potencial real por stat está en [statPotentials].
  final int potential;

  final int points;
  final String gender;
  final int championships; // New field
  final int races;
  final int wins;
  final int podiums;
  final int poles;

  // Seasonal standings data
  final int seasonPoints;
  final int seasonRaces;
  final int seasonWins;
  final int seasonPodiums;
  final int seasonPoles;

  /// Estadísticas actuales del piloto (0-100 por stat).
  /// Claves definidas en [DriverStats].
  final Map<String, int> stats;

  /// Potencial máximo por estadística (0-100).
  /// Un piloto no puede superar este techo sin importar cuánto entrene.
  /// Si está vacío, se usa [potential] * 20 como techo global.
  final Map<String, int> statPotentials;

  /// Rasgos especiales del piloto.
  final List<DriverTrait> traits;

  final String countryCode;
  final String role; // 'Main', 'Second', 'Equal', 'Reserve'
  final int salary;
  final int contractYearsRemaining;
  final Map<String, double> weeklyGrowth;
  final String? portraitUrl;
  final String statusTitle;

  Driver({
    required this.id,
    this.teamId,
    this.carIndex = 0,
    required this.name,
    required this.age,
    required this.potential,
    required this.points,
    required this.gender,
    this.championships = 0,
    this.races = 0,
    this.wins = 0,
    this.podiums = 0,
    this.poles = 0,
    this.seasonPoints = 0,
    this.seasonRaces = 0,
    this.seasonWins = 0,
    this.seasonPodiums = 0,
    this.seasonPoles = 0,
    required this.stats,
    this.statPotentials = const {},
    this.traits = const [],
    this.countryCode = 'BR',
    this.role = 'Equal Status',
    this.salary = 500000,
    this.contractYearsRemaining = 1,
    this.weeklyGrowth = const {},
    this.portraitUrl,
    this.statusTitle = 'Unknown Status',
  });

  /// Retorna el potencial máximo de una estadística específica.
  /// Si no está definido en [statPotentials], usa [potential] * 20 como techo.
  int getStatPotential(String statKey) {
    return statPotentials[statKey] ?? (potential * 20).clamp(0, 100);
  }

  /// Retorna el valor actual de una estadística, con fallback a 50.
  int getStat(String statKey) => stats[statKey] ?? 50;

  /// Calcula el multiplicador de edad para el entrenamiento.
  /// < 22: aprende rápido (1.5x)
  /// 22-35: prime (1.0x)
  /// > 35: declive (-1.0x para stats físicos)
  double get ageTrainingMultiplier {
    if (age < 22) return 1.5;
    if (age <= 35) return 1.0;
    return 0.5; // Puede seguir mejorando experiencia, pero más lento
  }

  /// Retorna true si el piloto tiene un rasgo específico.
  bool hasTrait(DriverTrait trait) => traits.contains(trait);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'carIndex': carIndex,
      'name': name,
      'age': age,
      'potential': potential,
      'points': points,
      'gender': gender,
      'championships': championships,
      'races': races,
      'wins': wins,
      'podiums': podiums,
      'poles': poles,
      'seasonPoints': seasonPoints,
      'seasonRaces': seasonRaces,
      'seasonWins': seasonWins,
      'seasonPodiums': seasonPodiums,
      'seasonPoles': seasonPoles,
      'stats': stats,
      'statPotentials': statPotentials,
      'traits': traits.map((t) => t.name).toList(),
      'countryCode': countryCode,
      'role': role,
      'salary': salary,
      'contractYearsRemaining': contractYearsRemaining,
      'weeklyGrowth': weeklyGrowth,
      'portraitUrl': portraitUrl,
      'statusTitle': statusTitle,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    // Migración: si tiene stats viejos (speed, racecraft, defending), convertirlos
    // Safe parsing of stats from num to int
    final Map<String, int> rawStats = (map['stats'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toInt()),
    );
    final migratedStats = _migrateOldStats(rawStats);

    // Parsear traits
    final rawTraits = (map['traits'] as List? ?? []);
    final parsedTraits = rawTraits
        .map((t) => DriverTrait.values.where((e) => e.name == t).firstOrNull)
        .whereType<DriverTrait>()
        .toList();

    return Driver(
      id: map['id'] ?? '',
      teamId: map['teamId'],
      carIndex: map['carIndex'] ?? 0,
      name: map['name'] ?? 'Unknown Driver',
      age: map['age'] ?? 21,
      potential: map['potential'] ?? 3,
      points: map['points'] ?? 0,
      gender: map['gender'] ?? 'M',
      championships: map['championships'] ?? 0,
      races: map['races'] ?? 0,
      wins: map['wins'] ?? 0,
      podiums: map['podiums'] ?? 0,
      poles: map['poles'] ?? 0,
      seasonPoints: map['seasonPoints'] ?? 0,
      seasonRaces: map['seasonRaces'] ?? 0,
      seasonWins: map['seasonWins'] ?? 0,
      seasonPodiums: map['seasonPodiums'] ?? 0,
      seasonPoles: map['seasonPoles'] ?? 0,
      stats: migratedStats,
      statPotentials: Map<String, int>.from(map['statPotentials'] ?? {}),
      traits: parsedTraits,
      countryCode: map['countryCode'] ?? 'BR',
      role: map['role'] ?? 'Equal Status',
      salary: map['salary'] ?? 500000,
      contractYearsRemaining: map['contractYearsRemaining'] ?? 1,
      weeklyGrowth: Map<String, double>.from(
        (map['weeklyGrowth'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      portraitUrl: map['portraitUrl'],
      statusTitle: map['statusTitle'] ?? 'Unknown Status',
    );
  }

  /// Migra stats del formato antiguo al nuevo.
  static Map<String, int> _migrateOldStats(Map<String, int> old) {
    // Si ya tiene el nuevo formato, retornar tal cual
    if (old.containsKey(DriverStats.braking) ||
        old.containsKey(DriverStats.smoothness)) {
      // Asegurar que todos los stats existen con valores por defecto
      final result = <String, int>{};
      for (final key in DriverStats.all) {
        result[key] = old[key] ?? 50;
      }
      return result;
    }

    // Migración desde formato viejo (speed, cornering, consistency, overtaking, defending, racecraft)
    final speed = old['speed'] ?? 50;
    final cornering = old['cornering'] ?? 50;
    final consistency = old['consistency'] ?? 50;
    final overtaking = old['overtaking'] ?? 50;

    return {
      DriverStats.braking: ((speed + (old['defending'] ?? 50)) / 2).round(),
      DriverStats.cornering: cornering,
      DriverStats.smoothness: ((consistency + (old['racecraft'] ?? 50)) / 2)
          .round(),
      DriverStats.overtaking: overtaking,
      DriverStats.consistency: consistency,
      DriverStats.adaptability: 50,
      DriverStats.fitness: 50,
      DriverStats.feedback: ((speed + consistency) / 2).round(),
      DriverStats.focus: consistency,
      DriverStats.morale: 70,
      DriverStats.marketability: 40,
    };
  }

  Driver copyWith({
    String? id,
    String? teamId,
    int? carIndex,
    String? name,
    int? age,
    int? potential,
    int? points,
    String? gender,
    int? championships,
    int? races,
    int? wins,
    int? podiums,
    int? poles,
    Map<String, int>? stats,
    Map<String, int>? statPotentials,
    List<DriverTrait>? traits,
    String? countryCode,
    String? role,
    int? salary,
    int? contractYearsRemaining,
    Map<String, double>? weeklyGrowth,
    String? portraitUrl,
    String? statusTitle,
  }) {
    return Driver(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      carIndex: carIndex ?? this.carIndex,
      name: name ?? this.name,
      age: age ?? this.age,
      potential: potential ?? this.potential,
      points: points ?? this.points,
      gender: gender ?? this.gender,
      championships: championships ?? this.championships,
      races: races ?? this.races,
      wins: wins ?? this.wins,
      podiums: podiums ?? this.podiums,
      poles: poles ?? this.poles,
      stats: stats ?? this.stats,
      statPotentials: statPotentials ?? this.statPotentials,
      traits: traits ?? this.traits,
      countryCode: countryCode ?? this.countryCode,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      contractYearsRemaining:
          contractYearsRemaining ?? this.contractYearsRemaining,
      weeklyGrowth: weeklyGrowth ?? this.weeklyGrowth,
      portraitUrl: portraitUrl ?? this.portraitUrl,
      statusTitle: statusTitle ?? this.statusTitle,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'NEWS', 'ALERT', 'SUCCESS', 'TEAM', 'OFFICE'
  final String? eventType; // e.g. 'RACE_RESULT', 'QUALY_RESULT'
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.eventType,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'eventType': eventType,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionRoute': actionRoute,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    DateTime parseTs(dynamic ts) {
      if (ts == null) return DateTime.now();
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'NEWS',
      eventType: map['eventType'],
      timestamp: parseTs(map['timestamp']),
      isRead: map['isRead'] ?? false,
      actionRoute: map['actionRoute'],
    );
  }
}

class LeagueNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'MANAGER_JOIN', 'CRASH', 'WINNER'
  final DateTime timestamp;
  final String leagueId;
  final String? eventType; // 'Practice', 'Qualifying', 'Race'
  final String? pilotName;
  final String? managerName;
  final String? teamName;
  final Map<String, dynamic>? payload;
  final bool isArchived;

  LeagueNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.leagueId,
    this.eventType,
    this.pilotName,
    this.managerName,
    this.teamName,
    this.payload,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'leagueId': leagueId,
      'eventType': eventType,
      'pilotName': pilotName,
      'managerName': managerName,
      'teamName': teamName,
      'payload': payload,
      'isArchived': isArchived,
    };
  }

  factory LeagueNotification.fromMap(Map<String, dynamic> map) {
    DateTime parseTs(dynamic ts) {
      if (ts == null) return DateTime.now();
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return LeagueNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'NEWS',
      timestamp: parseTs(map['timestamp']),
      leagueId: map['leagueId'] ?? '',
      eventType: map['eventType'],
      pilotName: map['pilotName'],
      managerName: map['managerName'],
      teamName: map['teamName'],
      payload: map['payload'] as Map<String, dynamic>?,
      isArchived: map['isArchived'] ?? false,
    );
  }
}
