import 'package:cloud_firestore/cloud_firestore.dart';
import 'country_model.dart';

/// Modelo de dominio que representa un piloto joven generado por la academia.
///
/// A diferencia del Driver de core_models, este modelo está específicamente
/// diseñado para pilotos prometedores sin experiencia y vinculados a un país.
class YoungDriver {
  /// ID único del piloto
  final String id;

  /// Nombre completo del piloto
  final String name;

  /// Nacionalidad del piloto (obligatoria, vinculada al país de la academia)
  final Country nationality;

  /// Edad del piloto (típicamente 16-19 años para jóvenes promesas)
  final int age;

  /// Habilidad base inicial (sin experiencia en carreras)
  /// Rango según nivel de academia: nivel 1 → 7, nivel 5 → 15
  final int baseSkill;

  /// Género del piloto ('M' o 'F')
  final String gender;

  /// Potencial de crecimiento en puntos (5-12 según nivel de academia)
  final int growthPotential;

  /// Imagen de perfil del piloto
  final String? portraitUrl;

  /// Estado del piloto: 'candidate', 'selected', 'released'
  final String status;

  /// Fecha de selección por el manager
  final DateTime? selectedAt;

  /// Fecha de expiración para candidatos no seleccionados
  final DateTime? expiresAt;

  /// Salario fijo: $100,000
  final int salary;

  /// Duración del contrato: 1 año
  final int contractYears;

  /// Estadísticas mínimas posibles (rango UI) por stat key
  final Map<String, int> statRangeMin;

  /// Estadísticas máximas posibles (rango UI) por stat key
  final Map<String, int> statRangeMax;

  /// Progreso de entrenamiento semanal (% por stat key, 0.0-100.0)
  final Map<String, double> trainingProgress;

  /// Historial de reportes semanales
  final List<Map<String, dynamic>> weeklyReports;

  YoungDriver({
    required this.id,
    required this.name,
    required this.nationality,
    required this.age,
    required this.baseSkill,
    required this.gender,
    required this.growthPotential,
    this.portraitUrl,
    this.status = 'candidate',
    this.selectedAt,
    this.expiresAt,
    this.salary = 100000,
    this.contractYears = 1,
    this.statRangeMin = const {},
    this.statRangeMax = const {},
    this.trainingProgress = const {},
    this.weeklyReports = const [],
  });

  /// Potencial global como estrellas (1-5) para UI
  int get potentialStars => (growthPotential / 2.4).ceil().clamp(1, 5);

  /// Si el candidato ya ha expirado
  bool get isExpired =>
      status == 'candidate' &&
      expiresAt != null &&
      DateTime.now().isAfter(expiresAt!);

  /// Si el piloto está siendo seguido
  bool get isSelected => status == 'selected';

  /// Serializa el piloto joven a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nationality': nationality.toMap(),
      'age': age,
      'baseSkill': baseSkill,
      'gender': gender,
      'growthPotential': growthPotential,
      'portraitUrl': portraitUrl,
      'status': status,
      'selectedAt': selectedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'salary': salary,
      'contractYears': contractYears,
      'statRangeMin': statRangeMin,
      'statRangeMax': statRangeMax,
      'trainingProgress': trainingProgress,
      'weeklyReports': weeklyReports,
    };
  }

  /// Crea una instancia de YoungDriver desde un mapa de Firestore
  factory YoungDriver.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return YoungDriver(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown Driver',
      nationality: Country.fromMap(
        Map<String, dynamic>.from(map['nationality'] ?? {}),
      ),
      age: map['age'] ?? 18,
      baseSkill: map['baseSkill'] ?? 7,
      gender: map['gender'] ?? 'M',
      growthPotential: map['growthPotential'] ?? 5,
      portraitUrl: map['portraitUrl'],
      status: map['status'] ?? 'candidate',
      selectedAt: parseDate(map['selectedAt']),
      expiresAt: parseDate(map['expiresAt']),
      salary: map['salary'] ?? 100000,
      contractYears: map['contractYears'] ?? 1,
      statRangeMin: Map<String, int>.from(map['statRangeMin'] ?? {}),
      statRangeMax: Map<String, int>.from(map['statRangeMax'] ?? {}),
      trainingProgress: Map<String, double>.from(
        (map['trainingProgress'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      weeklyReports: List<Map<String, dynamic>>.from(
        (map['weeklyReports'] ?? []).map((r) => Map<String, dynamic>.from(r)),
      ),
    );
  }

  YoungDriver copyWith({
    String? id,
    String? name,
    Country? nationality,
    int? age,
    int? baseSkill,
    String? gender,
    int? growthPotential,
    String? portraitUrl,
    String? status,
    DateTime? selectedAt,
    DateTime? expiresAt,
    int? salary,
    int? contractYears,
    Map<String, int>? statRangeMin,
    Map<String, int>? statRangeMax,
    Map<String, double>? trainingProgress,
    List<Map<String, dynamic>>? weeklyReports,
  }) {
    return YoungDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      age: age ?? this.age,
      baseSkill: baseSkill ?? this.baseSkill,
      gender: gender ?? this.gender,
      growthPotential: growthPotential ?? this.growthPotential,
      portraitUrl: portraitUrl ?? this.portraitUrl,
      status: status ?? this.status,
      selectedAt: selectedAt ?? this.selectedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      salary: salary ?? this.salary,
      contractYears: contractYears ?? this.contractYears,
      statRangeMin: statRangeMin ?? this.statRangeMin,
      statRangeMax: statRangeMax ?? this.statRangeMax,
      trainingProgress: trainingProgress ?? this.trainingProgress,
      weeklyReports: weeklyReports ?? this.weeklyReports,
    );
  }

  @override
  String toString() =>
      'YoungDriver($name, ${nationality.code}, age $age, skill $baseSkill, status $status)';
}
