import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/core_models.dart';
import '../models/domain/domain_models.dart';
import 'team_factory.dart';
import 'universe_service.dart';

/// Servicio para asignar equipos a divisiones.
///
/// Genera equipos usando TeamFactory y los distribuye en las divisiones
/// del universo, actualizando tanto la colección de equipos como las
/// referencias en las divisiones.
class TeamAssignmentService {
  static final TeamAssignmentService _instance =
      TeamAssignmentService._internal();
  factory TeamAssignmentService() => _instance;
  TeamAssignmentService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Puebla todas las divisiones del universo con equipos bot
  ///
  /// Estrategia:
  /// - 10 equipos por división
  /// - Equipos generados específicamente para el país de la liga
  /// - Distribuidos automáticamente entre División Élite (tier 1)
  ///   y División Profesional (tier 2)
  ///
  /// Este método es idempotente: si las divisiones ya tienen equipos,
  /// no hará nada.
  Future<void> populateAllDivisions() async {
    debugPrint("TEAM ASSIGNMENT: Iniciando población de divisiones...");

    final universe = await UniverseService().getUniverse();
    if (universe == null) {
      throw Exception(
        'Universe not initialized. Call initializeIfNeeded() first.',
      );
    }

    int totalTeamsCreated = 0;

    for (final league in universe.getAllLeagues()) {
      // Verificar si la liga ya tiene equipos asignados
      final hasTeams = league.divisions.any((div) => div.teamIds.isNotEmpty);
      if (hasTeams) {
        debugPrint(
          "TEAM ASSIGNMENT: Liga ${league.name} ya tiene equipos, saltando...",
        );
        continue;
      }

      debugPrint("TEAM ASSIGNMENT: Poblando liga ${league.name}...");
      final teamsCreated = await _populateLeagueDivisions(league);
      totalTeamsCreated += teamsCreated;
    }

    debugPrint(
      "TEAM ASSIGNMENT: Completado. $totalTeamsCreated equipos creados.",
    );
  }

  /// Puebla las divisiones de una liga específica
  ///
  /// Retorna el número de equipos creados
  Future<int> _populateLeagueDivisions(CountryLeague league) async {
    final factory = TeamFactory(league.country);
    int teamsCreated = 0;

    // Actualizar todas las divisiones
    final updatedDivisions = <LeagueDivision>[];

    for (final division in league.divisions) {
      final teams = <Team>[];
      final teamIds = <String>[];

      // Generar equipos para esta división
      for (int i = 0; i < division.maxCapacity; i++) {
        final team = factory.generateBotTeam();
        teams.add(team);
        teamIds.add(team.id);
      }

      // Persistir equipos en Firestore
      await _saveTeams(teams);
      teamsCreated += teams.length;

      // Crear división actualizada con IDs de equipos
      final updatedDivision = division.copyWith(teamIds: teamIds);
      updatedDivisions.add(updatedDivision);

      debugPrint(
        "TEAM ASSIGNMENT: ${division.name}: ${teams.length} equipos creados",
      );
    }

    // Actualizar liga con divisiones pobladas
    final updatedLeague = league.copyWith(divisions: updatedDivisions);

    // Persistir en universo
    await UniverseService().updateLeague(updatedLeague);

    return teamsCreated;
  }

  /// Guarda múltiples equipos en Firestore usando batch
  Future<void> _saveTeams(List<Team> teams) async {
    final batch = _db.batch();

    for (final team in teams) {
      final ref = _db.collection('teams').doc(team.id);
      batch.set(ref, team.toMap());
    }

    await batch.commit();
  }

  /// Obtiene todos los equipos de una división
  Future<List<Team>> getTeamsByDivision(String divisionId) async {
    // Primero obtener la división del universo
    final universe = await UniverseService().getUniverse();
    if (universe == null) return [];

    // Buscar división en todas las ligas
    LeagueDivision? targetDivision;
    for (final league in universe.getAllLeagues()) {
      final division = league.getDivisionById(divisionId);
      if (division != null) {
        targetDivision = division;
        break;
      }
    }

    if (targetDivision == null) return [];

    // Obtener equipos por sus IDs
    final teams = <Team>[];
    for (final teamId in targetDivision.teamIds) {
      final doc = await _db.collection('teams').doc(teamId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          teams.add(Team.fromMap({...data, 'id': doc.id}));
        }
      }
    }

    return teams;
  }

  /// Elimina todos los equipos (útil para testing/debugging)
  Future<void> deleteAllTeams() async {
    debugPrint("TEAM ASSIGNMENT: Eliminando todos los equipos...");

    final snapshot = await _db.collection('teams').get();
    if (snapshot.docs.isEmpty) {
      debugPrint("TEAM ASSIGNMENT: No hay equipos que eliminar.");
      return;
    }

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    debugPrint("TEAM ASSIGNMENT: ${snapshot.docs.length} equipos eliminados.");

    // También limpiar referencias en divisiones
    final universe = await UniverseService().getUniverse();
    if (universe != null) {
      for (final league in universe.getAllLeagues()) {
        final clearedDivisions = league.divisions
            .map((div) => div.copyWith(teamIds: []))
            .toList();
        final clearedLeague = league.copyWith(divisions: clearedDivisions);
        await UniverseService().updateLeague(clearedLeague);
      }
    }
  }
}
