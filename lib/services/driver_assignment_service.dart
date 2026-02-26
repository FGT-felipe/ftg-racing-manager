import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';
import 'driver_factory.dart';
import 'universe_service.dart';

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
  Future<void> populateLeagues() async {
    debugPrint("DRIVER ASSIGNMENT: Iniciando asignación de pilotos...");

    final universe = await UniverseService().getUniverse();
    if (universe == null) {
      throw Exception('Universe not initialized.');
    }

    int totalDriversCreated = 0;

    for (final league in universe.leagues) {
      if (league.tier == 3) {
        debugPrint(
          "DRIVER ASSIGNMENT: Skipping league ${league.name} (Tier 3) - Reserved for Youth Academy.",
        );
        continue;
      }

      debugPrint("DRIVER ASSIGNMENT: Poblando liga ${league.name}...");

      // Verificar si la liga ya tiene pilotos
      if (league.drivers.isNotEmpty) {
        debugPrint("DRIVER ASSIGNMENT: Liga ${league.name} ya tiene pilotos.");
        continue;
      }

      final driversCreated = await _populateLeagueDrivers(league);
      totalDriversCreated += driversCreated;
    }

    debugPrint(
      "DRIVER ASSIGNMENT: Completado. $totalDriversCreated pilotos creados.",
    );
  }

  /// Puebla los equipos de una liga con pilotos
  Future<int> _populateLeagueDrivers(FtgLeague league) async {
    final drivers = await generateAndSaveDriversForTeams(
      league.teams,
      league.tier,
    );

    // Actualizar liga con pilotos poblados
    final updatedLeague = league.copyWith(drivers: drivers);
    await UniverseService().updateLeague(updatedLeague);

    debugPrint(
      "DRIVER ASSIGNMENT: ${league.name}: ${drivers.length} pilotos creados",
    );

    return drivers.length;
  }

  /// Generates drivers for given teams independently of UniverseService
  Future<List<Driver>> generateAndSaveDriversForTeams(
    List<Team> teams,
    int tier,
  ) async {
    final factory = DriverFactory();
    final random = Random();

    final drivers = <Driver>[];

    for (final team in teams) {
      final isMaleMain = random.nextBool();

      // Generar 1 Male y 1 Female driver per team as per new requirements
      for (int i = 0; i < 2; i++) {
        final gender = (i == 0)
            ? (isMaleMain ? 'M' : 'F')
            : (isMaleMain ? 'F' : 'M');
        final driver = factory.generateDriver(
          divisionTier: tier,
          forcedGender: gender,
        );

        // Assign role based on index
        final role = i == 0 ? 'Main' : 'Second';

        // Mock weekly growth
        final mockGrowth = {
          'speed': (0.1 + (i * 0.1)) * (driver.age > 35 ? -1 : 1),
          'consistency': 0.2,
          'racecraft': 0.1,
        };

        final assignedDriver = driver.copyWith(
          teamId: team.id,
          carIndex: i,
          role: role,
          weeklyGrowth: mockGrowth,
        );

        drivers.add(assignedDriver);
      }
    }

    await _saveDrivers(drivers);
    return drivers;
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

  // Method _countDriversInDivision removed as we use league.drivers now.

  /// Obtiene pilotos de un equipo (Stream para tiempo real)
  Stream<List<Driver>> streamDriversByTeam(String teamId) {
    return _db
        .collection('drivers')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Driver.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        });
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

  /// Obtiene todos los pilotos de una liga
  Future<List<Driver>> getDriversByLeague(String leagueId) async {
    final universe = await UniverseService().getUniverse();
    if (universe == null) return [];

    final league = universe.getLeagueById(leagueId);
    if (league == null) return [];

    return league.drivers;
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
