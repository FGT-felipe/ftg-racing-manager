import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String type; // 'SPONSOR', 'SALARY', 'UPGRADE', 'REWARD'

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
    this.consecutiveFailuresAllowed = 3,
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
      consecutiveFailuresAllowed: map['consecutiveFailuresAllowed'] ?? 3,
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
  final Map<String, int> carStats;
  final Map<String, dynamic> weekStatus;
  final Map<String, ActiveContract> sponsors;

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
    required this.carStats,
    required this.weekStatus,
    this.sponsors = const {},
  });

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
      'carStats': carStats,
      'weekStatus': weekStatus,
      'sponsors': sponsors.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
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
      carStats: Map<String, int>.from(
        map['carStats'] ?? {'aero': 50, 'engine': 50, 'reliability': 50},
      ),
      weekStatus: Map<String, dynamic>.from(map['weekStatus'] ?? {}),
      sponsors: (map['sponsors'] as Map<String, dynamic>? ?? {}).map(
        (k, v) =>
            MapEntry(k, ActiveContract.fromMap(Map<String, dynamic>.from(v))),
      ),
    );
  }
}

class Driver {
  final String id;
  final String? teamId;
  final String name;
  final int age;
  final int potential;
  final int points;
  final String gender;
  final int races;
  final int wins;
  final int podiums;
  final int poles;
  final Map<String, int> stats;

  Driver({
    required this.id,
    this.teamId,
    required this.name,
    required this.age,
    required this.potential,
    required this.points,
    required this.gender,
    this.races = 0,
    this.wins = 0,
    this.podiums = 0,
    this.poles = 0,
    required this.stats,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'name': name,
      'age': age,
      'potential': potential,
      'points': points,
      'gender': gender,
      'races': races,
      'wins': wins,
      'podiums': podiums,
      'poles': poles,
      'stats': stats,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      teamId: map['teamId'],
      name: map['name'] ?? 'Unknown Driver',
      age: map['age'] ?? 21,
      potential: map['potential'] ?? 50,
      points: map['points'] ?? 0,
      gender: map['gender'] ?? 'M',
      races: map['races'] ?? 0,
      wins: map['wins'] ?? 0,
      podiums: map['podiums'] ?? 0,
      poles: map['poles'] ?? 0,
      stats: Map<String, int>.from(
        map['stats'] ?? {'speed': 50, 'cornering': 50, 'consistency': 50},
      ),
    );
  }
}
