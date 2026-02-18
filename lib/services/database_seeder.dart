import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/core_models.dart';

import '../config/game_config.dart';
import 'universe_service.dart';
import 'team_assignment_service.dart';
import 'driver_assignment_service.dart';
import 'driver_portrait_service.dart';

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

  static Future<void> nukeAndReseed({DateTime? startDate}) async {
    try {
      debugPrint("NUKE: Iniciando borrado total...");

      // Borrar el universo primero para limpiar jerarquía
      await UniverseService().deleteUniverse();
      debugPrint("NUKE: Universo eliminado.");

      final driversSnapshot = await _db.collectionGroup('drivers').get();
      if (driversSnapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in driversSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint("NUKE: Pilotos eliminados.");
      }

      final collectionsToClear = [
        'teams',
        'leagues',
        'seasons',
        'divisions',
        'races',
      ]; // Added races
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
      await seedWorld(
        force: true,
        startDate: startDate ?? GameConfig.seasonStart,
      );
    } catch (e, stack) {
      debugPrint("ERROR FATAL EN NUKE: $e");
      debugPrint(stack.toString());
      rethrow;
    }
  }

  static Future<void> seedWorld({
    bool force = false,
    DateTime? startDate,
  }) async {
    try {
      debugPrint("SEEDING: Iniciando...");

      // PHASE 3: Inicializar universo jerárquico
      debugPrint("SEEDING: Inicializando GameUniverse...");
      await UniverseService().initializeIfNeeded();
      debugPrint("SEEDING: GameUniverse inicializado.");

      // PHASE 4: Poblar divisiones con equipos
      debugPrint("SEEDING: Poblando divisiones con equipos...");
      await TeamAssignmentService().populateAllDivisions();
      debugPrint("SEEDING: Equipos asignados a divisiones.");

      // PHASE 5: Asignar pilotos a equipos
      debugPrint("SEEDING: Asignando pilotos a equipos...");
      await DriverAssignmentService().populateAllTeams();
      debugPrint("SEEDING: Pilotos asignados.");

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
      final now = startDate ?? DateTime.now();

      final List<RaceEvent> calendar = [
        RaceEvent(
          id: 'r1',
          trackName: "Autódromo Hermanos Rodríguez",
          countryCode: "MX",
          flagEmoji: "🇲🇽",
          circuitId: 'mexico',
          date: now,
          isCompleted: false,
          totalLaps: 71,
          weatherPractice: "Sunny",
          weatherQualifying: "Sunny",
          weatherRace: "Sunny",
        ),
        RaceEvent(
          id: 'r2',
          trackName: "Circuito Urbano de Las Vegas",
          countryCode: "US",
          flagEmoji: "🇺🇸",
          circuitId: 'vegas',
          date: now.add(const Duration(days: 7)),
          isCompleted: false,
          totalLaps: 50,
          weatherPractice: "Sunny",
          weatherQualifying: "Cloudy",
          weatherRace: "Sunny",
        ),
        RaceEvent(
          id: 'r3',
          trackName: "Autódromo José Carlos Pace",
          countryCode: "BR",
          flagEmoji: "🇧🇷",
          circuitId: 'interlagos',
          date: now.add(const Duration(days: 14)),
          isCompleted: false,
          totalLaps: 71,
          weatherPractice: "Cloudy",
          weatherQualifying: "Rainy",
          weatherRace: "Rainy",
        ),
        RaceEvent(
          id: 'r4',
          trackName: "Autódromo Internacional de Miami",
          countryCode: "US",
          flagEmoji: "🇺🇸",
          circuitId: 'miami',
          date: now.add(const Duration(days: 21)),
          isCompleted: false,
          totalLaps: 57,
          weatherPractice: "Sunny",
          weatherQualifying: "Sunny",
          weatherRace: "Sunny",
        ),
        RaceEvent(
          id: 'r5',
          trackName: "Circuito Callejero de San Pablo",
          countryCode: "BR",
          flagEmoji: "🇧🇷",
          circuitId: 'san_pablo_street',
          date: now.add(const Duration(days: 28)),
          isCompleted: false,
          totalLaps: 40,
          weatherPractice: "Sunny",
          weatherQualifying: "Sunny",
          weatherRace: "Sunny",
        ),
        RaceEvent(
          id: 'r6',
          trackName: "Circuito de Indianápolis",
          countryCode: "US",
          flagEmoji: "🇺🇸",
          circuitId: 'indianapolis',
          date: now.add(const Duration(days: 35)),
          isCompleted: false,
          totalLaps: 73,
          weatherPractice: "Sunny",
          weatherQualifying: "Cloudy",
          weatherRace: "Sunny",
        ),
        RaceEvent(
          id: 'r7',
          trackName: "Circuito Gilles Villeneuve",
          countryCode: "CA",
          flagEmoji: "🇨🇦",
          circuitId: 'montreal',
          date: now.add(const Duration(days: 42)),
          isCompleted: false,
          totalLaps: 70,
          weatherPractice: "Sunny",
          weatherQualifying: "Sunny",
          weatherRace: "Cloudy",
        ),
        RaceEvent(
          id: 'r8',
          trackName: "Circuito de las Américas",
          countryCode: "US",
          flagEmoji: "🇺🇸",
          circuitId: 'texas',
          date: now.add(const Duration(days: 49)),
          isCompleted: false,
          totalLaps: 56,
          weatherPractice: "Sunny",
          weatherQualifying: "Sunny",
          weatherRace: "Sunny",
        ),
        RaceEvent(
          id: 'r9',
          trackName: "Autódromo Oscar y Juan Gálvez",
          countryCode: "AR",
          flagEmoji: "🇦🇷",
          circuitId: 'buenos_aires',
          date: now.add(const Duration(days: 56)),
          isCompleted: false,
          totalLaps: 72,
          weatherPractice: "Sunny",
          weatherQualifying: "Sunny",
          weatherRace: "Sunny",
        ),
      ];

      // 3. SEASON
      final seasonRef = _db.collection('seasons').doc();
      final season = Season(
        id: seasonRef.id,
        leagueId: leagueRef.id,
        number: 1,
        year: 2026,
        calendar: calendar,
        startDate: now, // Persist start date
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
          races: 0,
          wins: 0,
          podiums: 0,
          poles: 0,
          carStats: {
            '0': {'aero': 1, 'powertrain': 1, 'chassis': 1, 'reliability': 1},
            '1': {'aero': 1, 'powertrain': 1, 'chassis': 1, 'reliability': 1},
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
          final age = 29 + random.nextInt(12);
          final speed = 40 + random.nextInt(51);
          final cornering = 40 + random.nextInt(51);

          final gender = isFemale ? 'F' : 'M';
          final driverRef = teamRef.collection('drivers').doc();
          batch.set(
            driverRef,
            Driver(
              id: driverRef.id,
              teamId: teamRef.id,
              carIndex: i, // 0 for Car A, 1 for Car B
              name: "$firstName $lastName",
              age: age,
              potential: 70 + random.nextInt(30),
              points: 0,
              gender: gender,
              stats: {
                'speed': speed,
                'cornering': cornering,
                'consistency': 40 + random.nextInt(41),
              },
              countryCode: 'CO', // Manual seeding fallback
              role: i == 0 ? 'Main Driver' : 'Secondary Driver',
              salary: 500000,
              contractYearsRemaining: 1,
              weeklyGrowth: {'speed': 0.2, 'consistency': 0.1},
              portraitUrl: DriverPortraitService().getPortraitUrl(
                driverId: driverRef.id,
                countryCode: 'CO',
                gender: gender,
                age: age,
              ),
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
