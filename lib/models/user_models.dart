enum ManagerRole {
  exDriver,
  businessAdmin,
  bureaucrat,
  exEngineer,
  noExperience,
}

extension ManagerRoleExtension on ManagerRole {
  String get title {
    switch (this) {
      case ManagerRole.exDriver:
        return "Ex-Driver";
      case ManagerRole.businessAdmin:
        return "Business Admin";
      case ManagerRole.bureaucrat:
        return "Bureaucrat";
      case ManagerRole.exEngineer:
        return "Ex-Engineer";
      case ManagerRole.noExperience:
        return "No Experience";
    }
  }

  String get description {
    switch (this) {
      case ManagerRole.exDriver:
        return "Using your racing intuition to lead.";
      case ManagerRole.businessAdmin:
        return "Optimization and profit above all.";
      case ManagerRole.bureaucrat:
        return "Master of rules and politics.";
      case ManagerRole.exEngineer:
        return "Technical excellence is the only way.";
      case ManagerRole.noExperience:
        return "A fresh perspective on the sport.";
    }
  }

  String get buffText {
    switch (this) {
      case ManagerRole.exDriver:
        return "(+) Technical bonus in sessions";
      case ManagerRole.businessAdmin:
        return "(+) Better financial deals & sponsors";
      case ManagerRole.bureaucrat:
        return "(+) Cheaper personnel contracts";
      case ManagerRole.exEngineer:
        return "(+) Faster car setup & R&D";
      case ManagerRole.noExperience:
        return "(+) Balanced approach";
    }
  }

  String get debuffText {
    switch (this) {
      case ManagerRole.exDriver:
        return "(-) Slower improvement in management stats";
      case ManagerRole.businessAdmin:
        return "(-) High driver fatigue rate";
      case ManagerRole.bureaucrat:
        return "(-) Poor team harmony & rivalries";
      case ManagerRole.exEngineer:
        return "(-) Drivers gain less XP";
      case ManagerRole.noExperience:
        return "(-) No specialized bonuses";
    }
  }

  List<String> get pros {
    switch (this) {
      case ManagerRole.exDriver:
        return [
          "Technical bonus in racing sessions",
          "Better driver feedback accuracy",
          "Respect from pit crew",
        ];
      case ManagerRole.businessAdmin:
        return [
          "Higher sponsor payouts (+15%)",
          "Reduced interest on loans",
          "Cheaper facility upgrades",
        ];
      case ManagerRole.bureaucrat:
        return [
          "Lower personnel salary demands",
          "Easier rule changes approval",
          "Political influence in paddock",
        ];
      case ManagerRole.exEngineer:
        return [
          "Faster car development (R&D)",
          "Improved car reliability",
          "Precise wind tunnel data",
        ];
      case ManagerRole.noExperience:
        return [
          "Maximum growth potential",
          "No pre-existing rivalries",
          "Balanced leadership style",
        ];
    }
  }

  List<String> get cons {
    switch (this) {
      case ManagerRole.exDriver:
        return [
          "Slow management skill progression",
          "Higher salary expectation",
          "Aggressive strategy bias",
        ];
      case ManagerRole.businessAdmin:
        return [
          "Strict focus on profits vs performance",
          "High driver pressure/fatigue",
          "Personnel feel undervalued",
        ];
      case ManagerRole.bureaucrat:
        return [
          "Slow decision making",
          "Poor team harmony",
          "Bureaucratic overhead",
        ];
      case ManagerRole.exEngineer:
        return [
          "Difficulty managing driver egos",
          "Drivers gain experience slower",
          "Perfectionism delays parts",
        ];
      case ManagerRole.noExperience:
        return [
          "No starting bonuses",
          "Lower initial reputation",
          "Learning curve for telemetry",
        ];
    }
  }
}

class ManagerProfile {
  final String uid;
  final String name;
  final String surname;
  final String country;
  final DateTime birthDate;
  final ManagerRole role;
  final int reputation;
  final List<String> trophyCase;

  ManagerProfile({
    required this.uid,
    required this.name,
    required this.surname,
    required this.country,
    required this.birthDate,
    required this.role,
    this.reputation = 0,
    this.trophyCase = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'surname': surname,
      'country': country,
      'birthDate': birthDate.toIso8601String(),
      'role': role.name,
      'reputation': reputation,
      'trophyCase': trophyCase,
    };
  }

  factory ManagerProfile.fromMap(Map<String, dynamic> map) {
    return ManagerProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      country: map['country'] ?? 'Unknown',
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : DateTime(2000),
      role: ManagerRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => ManagerRole.noExperience,
      ),
      reputation: map['reputation'] ?? 0,
      trophyCase: List<String>.from(map['trophyCase'] ?? []),
    );
  }
}
