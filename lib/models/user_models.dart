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
        return "(+) +2% race pace, +10 morale during race";
      case ManagerRole.businessAdmin:
        return "(+) +15% sponsor deals, -10% facility costs";
      case ManagerRole.bureaucrat:
        return "(+) -10% facility costs, +1 academy slot/level";
      case ManagerRole.exEngineer:
        return "(+) 2 simultaneous upgrades, -10% tyre wear";
      case ManagerRole.noExperience:
        return "(+) No bonuses";
    }
  }

  String get debuffText {
    switch (this) {
      case ManagerRole.exDriver:
        return "(-) +20% driver salary, +5% crash risk";
      case ManagerRole.businessAdmin:
        return "(-) -2% race pace, morale loss on sponsor fail";
      case ManagerRole.bureaucrat:
        return "(-) 2-week part upgrade cooldown";
      case ManagerRole.exEngineer:
        return "(-) -5% driver XP, double upgrade cost";
      case ManagerRole.noExperience:
        return "(-) No penalties";
    }
  }

  List<String> get pros {
    switch (this) {
      case ManagerRole.exDriver:
        return [
          "+5 driver feedback for setup",
          "+2% driver race pace",
          "+10 driver morale during race",
          "Unlocks Risky Driver Style",
        ];
      case ManagerRole.businessAdmin:
        return [
          "+15% better financial sponsorship deals",
          "-10% facility upgrade costs",
        ];
      case ManagerRole.bureaucrat:
        return [
          "-10% facility purchase and upgrade costs",
          "+1 extra youth academy driver per level",
        ];
      case ManagerRole.exEngineer:
        return [
          "Can upgrade 2 car parts simultaneously",
          "-10% tyre wear",
          "+5% Qualifying success probability",
        ];
      case ManagerRole.noExperience:
        return ["No bonuses or penalties"];
    }
  }

  List<String> get cons {
    switch (this) {
      case ManagerRole.exDriver:
        return [
          "Drivers salary is 20% higher",
          "+5% higher risk of race crashes",
        ];
      case ManagerRole.businessAdmin:
        return [
          "-2% driver race pace",
          "-10% driver morale if sponsor goals fail",
        ];
      case ManagerRole.bureaucrat:
        return ["Car part upgrade cooldown is 2 weeks (not 1)"];
      case ManagerRole.exEngineer:
        return ["-5% driver XP gain", "Car part upgrades cost double"];
      case ManagerRole.noExperience:
        return ["No bonuses or penalties"];
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
      name: map['firstName'] ?? '',
      surname: map['lastName'] ?? '',
      country: map['nationality'] ?? 'Unknown',
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
