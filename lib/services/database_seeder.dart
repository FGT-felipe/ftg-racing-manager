import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart'; // Add widgets for Locale
import '../l10n/app_localizations.dart'; // Import AppLocalizations
import '../models/core_models.dart';

import '../config/game_config.dart';
import 'universe_service.dart';
import 'team_assignment_service.dart';
import 'driver_assignment_service.dart';
import 'driver_status_service.dart';
import 'circuit_service.dart';
import 'dart:math';

class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CircuitService _circuitService = CircuitService();

  /// Contador para IDs únicos

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

      final pressNewsSnapshot = await _db.collectionGroup('press_news').get();
      if (pressNewsSnapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in pressNewsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint("NUKE: Noticias de prensa eliminadas.");
      }

      final collectionsToClear = [
        'teams',
        'leagues',
        'seasons',
        'divisions',
        'races',
        'driver_titles',
        'managers',
      ]; // Added managers to allow full onboarding reset
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

      // PHASE 4: Poblar ligas con equipos
      debugPrint("SEEDING: Poblando ligas con equipos...");
      await TeamAssignmentService().populateLeagues();
      debugPrint("SEEDING: Equipos asignados.");

      // PHASE 5: Asignar pilotos a equipos
      debugPrint("SEEDING: Asignando pilotos a equipos...");
      await DriverAssignmentService().populateLeagues();
      debugPrint("SEEDING: Pilotos asignados.");

      if (!force) {
        final leaguesSnapshot = await _db.collection('leagues').limit(1).get();
        if (leaguesSnapshot.docs.isNotEmpty) return;
      }

      final batch = _db.batch();

      final universe = await UniverseService().getUniverse();
      if (universe == null) throw Exception("Universe not seeded");

      // 1. Create root "leagues" documents for each league in the universe
      // to support existing features like LeagueNotificationService
      for (final league in universe.leagues) {
        batch.set(_db.collection('leagues').doc(league.id), {
          'id': league.id,
          'name': league.name,
          'tier': league.tier,
        });

        // 2. CALENDAR: 9 races, 1 per week — uses all circuits from CircuitService
        final now = startDate ?? DateTime.now();
        final l10n = lookupAppLocalizations(const Locale('en'));

        final calendarData = [
          {
            'circuitId': 'mexico',
            'name': l10n.circuitMexico,
            'country': 'MX',
            'flag': '🇲🇽',
          },
          {
            'circuitId': 'interlagos',
            'name': l10n.circuitInterlagos,
            'country': 'BR',
            'flag': '🇧🇷',
          },
          {
            'circuitId': 'miami',
            'name': l10n.circuitMiami,
            'country': 'US',
            'flag': '🇺🇸',
          },
          {
            'circuitId': 'san_pablo_street',
            'name': l10n.circuitSanPabloStreet,
            'country': 'BR',
            'flag': '🇧🇷',
          },
          {
            'circuitId': 'indianapolis',
            'name': l10n.circuitIndianapolis,
            'country': 'US',
            'flag': '🇺🇸',
          },
          {
            'circuitId': 'montreal',
            'name': l10n.circuitMontreal,
            'country': 'CA',
            'flag': '🇨🇦',
          },
          {
            'circuitId': 'vegas',
            'name': l10n.circuitVegas,
            'country': 'US',
            'flag': '🇺🇸',
          },
          {
            'circuitId': 'texas',
            'name': l10n.circuitTexas,
            'country': 'US',
            'flag': '🇺🇸',
          },
          {
            'circuitId': 'buenos_aires',
            'name': l10n.circuitBuenosAires,
            'country': 'AR',
            'flag': '🇦🇷',
          },
        ];

        final List<RaceEvent> calendar = List.generate(calendarData.length, (
          i,
        ) {
          final data = calendarData[i];
          final circuitId = data['circuitId']!;
          final circuit = _circuitService.getCircuitProfile(circuitId);
          final random = Random();
          final conditions = [
            'Sunny',
            'Cloudy',
            'Overcast',
            'Rain',
            'Light Rain',
          ];

          return RaceEvent(
            id: 'r${i + 1}',
            trackName: data['name']!,
            countryCode: data['country']!,
            flagEmoji: data['flag']!,
            circuitId: circuitId,
            date: now.add(Duration(days: 7 * (i + 1))),
            totalLaps: circuit.laps, // Use dynamic laps
            weatherQualifying: conditions[random.nextInt(3)],
            weatherRace: conditions[random.nextInt(conditions.length)],
            isCompleted: false,
          );
        });

        // 3. SEASON for each league
        final seasonRef = _db.collection('seasons').doc();
        final season = Season(
          id: seasonRef.id,
          leagueId: league.id,
          number: 1,
          year: 2026,
          calendar: calendar,
          startDate: now,
        );
        batch.set(seasonRef, season.toMap());
      }

      // 1.5 SEED TITLES (Global)
      final titles = DriverStatusService.getAllTitles();
      for (final entry in titles.entries) {
        final titleRef = _db.collection('driver_titles').doc(entry.key);
        batch.set(titleRef, {
          'title': entry.key,
          'description': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint("SEEDING: ÉXITO.");
    } catch (e, stack) {
      debugPrint("SEED ERROR: $e\n$stack");
      rethrow;
    }
  }
}
