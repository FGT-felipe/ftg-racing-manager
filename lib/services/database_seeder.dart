import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/core_models.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> _maleNames = [
    "Juan",
    "Carlos",
    "Felipe",
    "Matías",
    "Diego",
    "Santiago",
    "Gabriel",
    "Lucas",
    "Mateo",
    "Sebastián",
    "Alejandro",
    "Valentín",
  ];
  static const List<String> _femaleNames = [
    "Sofía",
    "Valentina",
    "Camila",
    "Isabella",
    "Mariana",
    "Gabriela",
    "Daniela",
    "Martina",
    "Lucía",
    "Paula",
    "Elena",
    "Ximena",
  ];
  static const List<String> _lastNames = [
    "Rodríguez",
    "González",
    "Silva",
    "García",
    "López",
    "Martínez",
    "Pérez",
    "Gómez",
    "Sánchez",
    "Díaz",
    "Hernández",
    "Torres",
    "Ramírez",
    "Montoya",
    "Rossi",
    "Piquet",
    "Massa",
    "Fittipaldi",
    "Canapino",
  ];
  static const List<String> _teamNames = [
    "Escudería Los Andes",
    "Bogotá Racing",
    "Furia Porteña",
    "Carioca Speed",
    "Azteca Motorsport",
    "Pampa Speed",
    "Antioquia Grand Prix",
    "Quito Motorsport",
    "Caracas Racing Team",
    "Montevideo Performance",
  ];

  static Future<void> nukeAndReseed() async {
    try {
      debugPrint("NUKE: Iniciando borrado total...");

      final driversSnapshot = await _db.collectionGroup('drivers').get();
      if (driversSnapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in driversSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint("NUKE: Pilotos eliminados.");
      }

      final collectionsToClear = ['teams', 'leagues', 'seasons', 'divisions'];
      for (var collection in collectionsToClear) {
        final snapshot = await _db.collection(collection).get();
        if (snapshot.docs.isNotEmpty) {
          final batch = _db.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint("NUKE: Colección '$collection' eliminada.");
        }
      }

      debugPrint("NUKE: Borrado completado.");
      await seedWorld(force: true);
    } catch (e, stack) {
      debugPrint("ERROR FATAL EN NUKE: $e");
      debugPrint(stack.toString());
      rethrow;
    }
  }

  static Future<void> seedWorld({bool force = false}) async {
    try {
      debugPrint("SEEDING: Iniciando...");

      if (!force) {
        final leaguesSnapshot = await _db.collection('leagues').limit(1).get();
        if (leaguesSnapshot.docs.isNotEmpty) return;
      }

      final random = Random();
      final batch = _db.batch();

      // 1. LIGA
      final leagueRef = _db.collection('leagues').doc();
      final league = League(id: leagueRef.id, name: "Copa Suramericana");
      batch.set(leagueRef, league.toMap());

      // 2. CALENDARIO
      final now = DateTime.now();
      final List<RaceEvent> calendar = [
        RaceEvent(
          id: 'r1',
          trackName: "GP Interlagos",
          countryCode: "BR",
          date: now.add(const Duration(days: 2)),
          isCompleted: false,
        ),
        RaceEvent(
          id: 'r2',
          trackName: "GP Hermanos Rodríguez",
          countryCode: "MX",
          date: now.add(const Duration(days: 11)),
          isCompleted: false,
        ),
        RaceEvent(
          id: 'r3',
          trackName: "GP Termas de Río Hondo",
          countryCode: "AR",
          date: now.add(const Duration(days: 18)),
          isCompleted: false,
        ),
        RaceEvent(
          id: 'r4',
          trackName: "GP Tocancipá",
          countryCode: "CO",
          date: now.add(const Duration(days: 25)),
          isCompleted: false,
        ),
        RaceEvent(
          id: 'r5',
          trackName: "GP El Pinar",
          countryCode: "UY",
          date: now.add(const Duration(days: 32)),
          isCompleted: false,
        ),
        RaceEvent(
          id: 'r6',
          trackName: "GP Yahuarcocha",
          countryCode: "EC",
          date: now.add(const Duration(days: 39)),
          isCompleted: false,
        ),
      ];

      // 3. SEASON
      final seasonRef = _db.collection('seasons').doc();
      final season = Season(
        id: seasonRef.id,
        leagueId: leagueRef.id,
        year: 2026,
        calendar: calendar,
      );
      batch.set(seasonRef, season.toMap());

      final divisionRef = _db.collection('divisions').doc();
      final division = Division(
        id: divisionRef.id,
        leagueId: leagueRef.id,
        name: "Primera División",
        level: 1,
      );
      batch.set(divisionRef, division.toMap());

      // 4. EQUIPOS Y PILOTOS
      for (var teamName in _teamNames) {
        final teamRef = _db.collection('teams').doc();
        final team = Team(
          id: teamRef.id,
          name: teamName,
          isBot: true,
          budget: 10000000 + random.nextInt(5000000),
          points: 0,
          carStats: {
            'aero': 50 + random.nextInt(10),
            'engine': 50 + random.nextInt(10),
            'reliability': 50 + random.nextInt(10),
          },
          weekStatus: {
            'practiceCompleted': false,
            'strategySet': false,
            'sponsorReviewed': false,
          },
        );
        batch.set(teamRef, team.toMap());

        for (int i = 0; i < 2; i++) {
          final isFemale = random.nextBool();
          final firstName = isFemale
              ? _femaleNames[random.nextInt(_femaleNames.length)]
              : _maleNames[random.nextInt(_maleNames.length)];
          final lastName = _lastNames[random.nextInt(_lastNames.length)];
          final age = 18 + random.nextInt(18);
          final speed = 40 + random.nextInt(51);
          final cornering = 40 + random.nextInt(51);

          final driverRef = teamRef.collection('drivers').doc();
          batch.set(
            driverRef,
            Driver(
              id: driverRef.id,
              name: "$firstName $lastName",
              age: age,
              potential: 70 + random.nextInt(30),
              points: 0,
              gender: isFemale ? 'F' : 'M',
              stats: {'speed': speed, 'cornering': cornering},
            ).toMap(),
          );
        }
      }

      await batch.commit();
      debugPrint("SEEDING: ÉXITO.");
    } catch (e, stack) {
      debugPrint("SEED ERROR: $e\n$stack");
      rethrow;
    }
  }
}
