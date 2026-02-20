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

  /// Puebla todas las ligas del universo con equipos bot si están vacías
  Future<void> populateLeagues() async {
    debugPrint("TEAM ASSIGNMENT: Iniciando población de ligas...");

    final universe = await UniverseService().getUniverse();
    if (universe == null) {
      throw Exception('Universe not initialized.');
    }

    int totalTeamsCreated = 0;

    for (final league in universe.leagues) {
      if (league.teams.isNotEmpty) {
        debugPrint("TEAM ASSIGNMENT: Liga ${league.name} ya tiene equipos.");
        continue;
      }

      debugPrint("TEAM ASSIGNMENT: Poblando liga ${league.name}...");
      final teamsCreated = await _populateLeague(league);
      totalTeamsCreated += teamsCreated;
    }

    debugPrint(
      "TEAM ASSIGNMENT: Completado. $totalTeamsCreated equipos creados.",
    );
  }

  /// Puebla una liga específica (11 equipos)
  Future<int> _populateLeague(FtgLeague league) async {
    final factory = TeamFactory();
    final teams = <Team>[];

    for (int i = 0; i < 11; i++) {
      final team = factory.generateBotTeam();
      teams.add(team);
    }

    await _saveTeams(teams);

    final updatedLeague = league.copyWith(teams: teams);
    await UniverseService().updateLeague(updatedLeague);

    return teams.length;
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

  /// Obtiene todos los equipos de una liga
  Future<List<Team>> getTeamsByLeague(String leagueId) async {
    final universe = await UniverseService().getUniverse();
    if (universe == null) return [];

    final league = universe.getLeagueById(leagueId);
    if (league == null) return [];

    return league.teams;
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

    // También limpiar referencias en el universo
    final universe = await UniverseService().getUniverse();
    if (universe != null) {
      for (final league in universe.leagues) {
        final clearedLeague = league.copyWith(teams: []);
        await UniverseService().updateLeague(clearedLeague);
      }
    }
  }
}
