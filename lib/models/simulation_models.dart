enum TyreCompound { soft, medium, hard, wet }

enum DriverStyle { defensive, normal, offensive, mostRisky }

class CarSetup {
  int frontWing;
  int rearWing;
  int suspension;
  int gearRatio;
  TyreCompound tyreCompound;
  List<TyreCompound> pitStops;
  double initialFuel;
  List<double> pitStopFuel;
  DriverStyle qualifyingStyle;
  DriverStyle raceStyle;
  List<DriverStyle> pitStopStyles;

  CarSetup({
    this.frontWing = 50,
    this.rearWing = 50,
    this.suspension = 50,
    this.gearRatio = 50,
    this.tyreCompound = TyreCompound.medium,
    this.pitStops = const [TyreCompound.hard], // Default 1 stop
    this.initialFuel = 50.0,
    this.pitStopFuel = const [50.0],
    this.qualifyingStyle = DriverStyle.normal,
    this.raceStyle = DriverStyle.normal,
    this.pitStopStyles = const [DriverStyle.normal],
  });

  Map<String, dynamic> toMap() {
    return {
      'frontWing': frontWing,
      'rearWing': rearWing,
      'suspension': suspension,
      'gearRatio': gearRatio,
      'tyreCompound': tyreCompound.name,
      'pitStops': pitStops.map((e) => e.name).toList(),
      'initialFuel': initialFuel,
      'pitStopFuel': pitStopFuel,
      'qualifyingStyle': qualifyingStyle.name,
      'raceStyle': raceStyle.name,
      'pitStopStyles': pitStopStyles.map((e) => e.name).toList(),
    };
  }

  factory CarSetup.fromMap(Map<String, dynamic> map) {
    final pitStopsList = (map['pitStops'] as List? ?? [TyreCompound.hard.name])
        .map(
          (e) => TyreCompound.values.firstWhere(
            (tc) => tc.name == e,
            orElse: () => TyreCompound.medium,
          ),
        )
        .toList();

    return CarSetup(
      frontWing: map['frontWing'] ?? 50,
      rearWing: map['rearWing'] ?? 50,
      suspension: map['suspension'] ?? 50,
      gearRatio: map['gearRatio'] ?? 50,
      tyreCompound: TyreCompound.values.firstWhere(
        (e) => e.name == (map['tyreCompound'] ?? 'medium'),
        orElse: () => TyreCompound.medium,
      ),
      pitStops: pitStopsList,
      initialFuel: (map['initialFuel'] ?? 50.0).toDouble(),
      pitStopFuel:
          (map['pitStopFuel'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          List.filled(pitStopsList.length, 50.0),
      qualifyingStyle: DriverStyle.values.firstWhere(
        (e) => e.name == (map['qualifyingStyle'] ?? 'normal'),
        orElse: () => DriverStyle.normal,
      ),
      raceStyle: DriverStyle.values.firstWhere(
        (e) => e.name == (map['raceStyle'] ?? 'normal'),
        orElse: () => DriverStyle.normal,
      ),
      pitStopStyles:
          (map['pitStopStyles'] as List?)
              ?.map(
                (e) => DriverStyle.values.firstWhere(
                  (ds) => ds.name == e,
                  orElse: () => DriverStyle.normal,
                ),
              )
              .toList() ??
          List.filled(pitStopsList.length, DriverStyle.normal),
    );
  }

  CarSetup copyWith({
    int? frontWing,
    int? rearWing,
    int? suspension,
    int? gearRatio,
    TyreCompound? tyreCompound,
    List<TyreCompound>? pitStops,
    double? initialFuel,
    List<double>? pitStopFuel,
    DriverStyle? qualifyingStyle,
    DriverStyle? raceStyle,
    List<DriverStyle>? pitStopStyles,
  }) {
    return CarSetup(
      frontWing: frontWing ?? this.frontWing,
      rearWing: rearWing ?? this.rearWing,
      suspension: suspension ?? this.suspension,
      gearRatio: gearRatio ?? this.gearRatio,
      tyreCompound: tyreCompound ?? this.tyreCompound,
      pitStops: pitStops ?? this.pitStops,
      initialFuel: initialFuel ?? this.initialFuel,
      pitStopFuel: pitStopFuel ?? this.pitStopFuel,
      qualifyingStyle: qualifyingStyle ?? this.qualifyingStyle,
      raceStyle: raceStyle ?? this.raceStyle,
      pitStopStyles: pitStopStyles ?? this.pitStopStyles,
    );
  }
}

class CircuitProfile {
  final String id;
  final String name;
  final String flagEmoji;
  final CarSetup idealSetup;
  final double baseLapTime; // in seconds
  final int laps;
  final double tyreWearMultiplier;
  final double fuelConsumptionMultiplier;

  // Weights for car performance (should sum to 1.0 ideally)
  final double aeroWeight;
  final double chassisWeight;
  final double powertrainWeight;

  final double difficulty; // 0.0 to 1.0 (affects driver error chance)
  final double overtakingDifficulty; // 0.0 to 1.0
  final Map<String, String> characteristics;

  CircuitProfile({
    required this.id,
    required this.name,
    required this.flagEmoji,
    required this.idealSetup,
    required this.baseLapTime,
    required this.laps,
    this.tyreWearMultiplier = 1.0,
    this.fuelConsumptionMultiplier = 1.0,
    this.aeroWeight = 0.33,
    this.chassisWeight = 0.33,
    this.powertrainWeight = 0.34,
    this.difficulty = 0.5,
    this.overtakingDifficulty = 0.5,
    this.characteristics = const {},
  });
}

class PracticeRunResult {
  final double lapTime;
  final double gapToBest; // 0.0 if best
  final List<String> driverFeedback;
  final List<String> tyreFeedback;
  final double setupConfidence; // 0.0 to 1.0
  final CarSetup setupUsed;
  final bool isCrashed;

  PracticeRunResult({
    required this.lapTime,
    this.gapToBest = 0.0,
    required this.driverFeedback,
    this.tyreFeedback = const [],
    required this.setupConfidence,
    required this.setupUsed,
    this.isCrashed = false,
  });

  PracticeRunResult copyWith({
    double? lapTime,
    double? gapToBest,
    List<String>? driverFeedback,
    List<String>? tyreFeedback,
    double? setupConfidence,
    CarSetup? setupUsed,
    bool? isCrashed,
  }) {
    return PracticeRunResult(
      lapTime: lapTime ?? this.lapTime,
      gapToBest: gapToBest ?? this.gapToBest,
      driverFeedback: driverFeedback ?? this.driverFeedback,
      tyreFeedback: tyreFeedback ?? this.tyreFeedback,
      setupConfidence: setupConfidence ?? this.setupConfidence,
      setupUsed: setupUsed ?? this.setupUsed,
      isCrashed: isCrashed ?? this.isCrashed,
    );
  }
}

class RaceEventLog {
  final int lapNumber;
  final String driverId;
  final String description; // "Overtook X", "Pit Stop", "Crashed"
  final String type; // OVERTAKE, PIT, CRASH, INFO

  RaceEventLog({
    required this.lapNumber,
    required this.driverId,
    required this.description,
    required this.type,
  });
}

class LapData {
  final int lapNumber;
  final Map<String, double> driverLapTimes; // driverId -> time
  final Map<String, int> positions; // driverId -> position
  final List<RaceEventLog> events;

  LapData({
    required this.lapNumber,
    required this.driverLapTimes,
    required this.positions,
    required this.events,
  });
}

class RaceSessionResult {
  final String raceId;
  final List<LapData> laps;
  final Map<String, int> finalPositions; // driverId -> position
  final Map<String, double> totalTimes; // driverId -> total seconds
  final List<String> dnfs;

  RaceSessionResult({
    required this.raceId,
    required this.laps,
    required this.finalPositions,
    required this.totalTimes,
    required this.dnfs,
  });
}
