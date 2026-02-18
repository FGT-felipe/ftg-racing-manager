enum TyreCompound { soft, medium, hard, wet }

class CarSetup {
  int frontWing;
  int rearWing;
  int suspension;
  int gearRatio;
  int tyrePressure;
  TyreCompound tyreCompound;

  CarSetup({
    this.frontWing = 50,
    this.rearWing = 50,
    this.suspension = 50,
    this.gearRatio = 50,
    this.tyrePressure = 50,
    this.tyreCompound = TyreCompound.medium,
  });

  Map<String, dynamic> toMap() {
    return {
      'frontWing': frontWing,
      'rearWing': rearWing,
      'suspension': suspension,
      'gearRatio': gearRatio,
      'tyrePressure': tyrePressure,
      'tyreCompound': tyreCompound.name,
    };
  }

  factory CarSetup.fromMap(Map<String, dynamic> map) {
    return CarSetup(
      frontWing: map['frontWing'] ?? 50,
      rearWing: map['rearWing'] ?? 50,
      suspension: map['suspension'] ?? 50,
      gearRatio: map['gearRatio'] ?? 50,
      tyrePressure: map['tyrePressure'] ?? 50,
      tyreCompound: TyreCompound.values.firstWhere(
        (e) => e.name == (map['tyreCompound'] ?? 'medium'),
        orElse: () => TyreCompound.medium,
      ),
    );
  }

  CarSetup copyWith({
    int? frontWing,
    int? rearWing,
    int? suspension,
    int? gearRatio,
    int? tyrePressure,
    TyreCompound? tyreCompound,
  }) {
    return CarSetup(
      frontWing: frontWing ?? this.frontWing,
      rearWing: rearWing ?? this.rearWing,
      suspension: suspension ?? this.suspension,
      gearRatio: gearRatio ?? this.gearRatio,
      tyrePressure: tyrePressure ?? this.tyrePressure,
      tyreCompound: tyreCompound ?? this.tyreCompound,
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
  final double setupConfidence; // 0.0 to 1.0
  final CarSetup setupUsed;

  PracticeRunResult({
    required this.lapTime,
    this.gapToBest = 0.0,
    required this.driverFeedback,
    required this.setupConfidence,
    required this.setupUsed,
  });
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
