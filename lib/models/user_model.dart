class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime registrationDate;

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      registrationDate: map['registrationDate'] != null
          ? DateTime.parse(map['registrationDate'])
          : DateTime.now(),
    );
  }
}
