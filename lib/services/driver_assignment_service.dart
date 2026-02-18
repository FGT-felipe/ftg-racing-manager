import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';
import 'driver_factory.dart';
import 'universe_service.dart';
import 'team_assignment_service.dart';

/// Servicio para asignar pilotos a equipos.
///
/// Genera pilotos usando DriverFactory y los distribuye en los equipos,
/// actualizando la colección de pilotos con el teamId correspondiente.
class DriverAssignmentService {
  static final DriverAssignmentService _instance =
      DriverAssignmentService._internal();
  factory DriverAssignmentService() => _instance;
  DriverAssignmentService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Puebla todos los equipos del universo con pilotos
  ///
  /// Estrategia:
  /// - 2 pilotos por equipo
  /// - Total: 240 pilotos (120 equipos × 2)
  /// - Stats basados en tier de división
  ///
  /// Este método es idempotente: si los equipos ya tienen pilotos,
  /// no hará nada.
  Future<void> populateAllTeams() async {
    debugPrint("DRIVER ASSIGNMENT: Iniciando asignación de pilotos...");

    final universe = await UniverseService().getUniverse();
    if (universe == null) {
      throw Exception(
        'Universe not initialized. Call initializeIfNeeded() first.',
      );
    }

    int totalDriversCreated = 0;

    for (final league in universe.getAllLeagues()) {
      debugPrint("DRIVER ASSIGNMENT: Poblando liga ${league.name}...");

      for (final division in league.divisions) {
        // Verificar si la división ya tiene pilotos
        final existingDrivers = await _countDriversInDivision(division.id);
        if (existingDrivers > 0) {
          debugPrint(
            "DRIVER ASSIGNMENT: División ${division.name} ya tiene $existingDrivers pilotos, saltando...",
          );
          continue;
        }

        final driversCreated = await _populateDivisionTeams(
          league.country,
          division,
        );
        totalDriversCreated += driversCreated;
      }
    }

    debugPrint(
      "DRIVER ASSIGNMENT: Completado. $totalDriversCreated pilotos creados.",
    );
  }

  /// Puebla los equipos de una división con pilotos
  ///
  /// Retorna el número de pilotos creados
  Future<int> _populateDivisionTeams(
    Country country,
    LeagueDivision division,
  ) async {
    final factory = DriverFactory(country);
    int driversCreated = 0;

    // Obtener equipos de esta división
    final teams = await TeamAssignmentService().getTeamsByDivision(division.id);

    final drivers = <Driver>[];

    for (final team in teams) {
      // Generar 2 pilotos por equipo
      for (int i = 0; i < 2; i++) {
        final driver = factory.generateDriver(divisionTier: division.tier);

        // Assign role based on index
        final role = i == 0 ? 'Main Driver' : 'Secondary Driver';

        // Mock weekly growth for visual demonstration
        final mockGrowth = {
          'speed': (0.1 + (i * 0.1)) * (driver.age > 35 ? -1 : 1),
          'consistency': 0.2,
          'racecraft': 0.1,
        };

        // Crear driver con teamId asignado
        final assignedDriver = driver.copyWith(
          teamId: team.id, // Vincular con equipo
          carIndex: i, // 0 for Car A, 1 for Car B
          role: role,
          weeklyGrowth: mockGrowth,
        );

        drivers.add(assignedDriver);
        driversCreated++;
      }
    }

    // Persistir drivers usando batch
    await _saveDrivers(drivers);

    debugPrint(
      "DRIVER ASSIGNMENT: ${division.name}: $driversCreated pilotos creados",
    );

    return driversCreated;
  }

  /// Guarda múltiples pilotos en Firestore usando batch
  Future<void> _saveDrivers(List<Driver> drivers) async {
    final batch = _db.batch();

    for (final driver in drivers) {
      final ref = _db.collection('drivers').doc(driver.id);
      batch.set(ref, driver.toMap());
    }

    await batch.commit();
  }

  /// Cuenta pilotos existentes en una división
  Future<int> _countDriversInDivision(String divisionId) async {
    // Obtener equipos de la división
    final teams = await TeamAssignmentService().getTeamsByDivision(divisionId);
    if (teams.isEmpty) return 0;

    final teamIds = teams.map((t) => t.id).toList();

    // Contar drivers de estos equipos
    int count = 0;
    for (final teamId in teamIds) {
      final snapshot = await _db
          .collection('drivers')
          .where('teamId', isEqualTo: teamId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) count++;
    }

    return count;
  }

  /// Obtiene pilotos de un equipo
  Future<List<Driver>> getDriversByTeam(String teamId) async {
    final snapshot = await _db
        .collection('drivers')
        .where('teamId', isEqualTo: teamId)
        .get();

    return snapshot.docs
        .map((doc) => Driver.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Obtiene todos los pilotos de una división
  Future<List<Driver>> getDriversByDivision(String divisionId) async {
    final teams = await TeamAssignmentService().getTeamsByDivision(divisionId);
    final allDrivers = <Driver>[];

    for (final team in teams) {
      final drivers = await getDriversByTeam(team.id);
      allDrivers.addAll(drivers);
    }

    return allDrivers;
  }

  /// Elimina todos los pilotos (útil para testing/debugging)
  Future<void> deleteAllDrivers() async {
    debugPrint("DRIVER ASSIGNMENT: Eliminando todos los pilotos...");

    final snapshot = await _db.collection('drivers').get();
    if (snapshot.docs.isEmpty) {
      debugPrint("DRIVER ASSIGNMENT: No hay pilotos que eliminar.");
      return;
    }

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    debugPrint(
      "DRIVER ASSIGNMENT: ${snapshot.docs.length} pilotos eliminados.",
    );
  }
}
