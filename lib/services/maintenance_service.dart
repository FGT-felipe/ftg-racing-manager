import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';

class MaintenanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fixes the race calendars for 'ftg_2th' and 'ftg_karting' leagues.
  /// This uses confirmed Season IDs from Firestore as the "Absolute Truth".
  Future<void> fixRaceCalendars() async {
    debugPrint("Starting Race Calendar Maintenance...");

    // 1. Confirmed IDs from the user (Absolute Truth)
    const String worldSeasonId = '3sh7fStGc55XxwmQHaJu';
    final Map<String, String> targetSeasons = {
      'ftg_2th': 'Py9vb4IrLJGZPDCCCUkG',
      'ftg_karting': 'qRM0nhyt95JGXqgxLtnT',
    };

    // 2. Fetch ftg_world calendar as the reference
    final worldSeasonDoc = await _db
        .collection('seasons')
        .doc(worldSeasonId)
        .get();

    if (!worldSeasonDoc.exists || worldSeasonDoc.data() == null) {
      debugPrint("ftg_world season $worldSeasonId not found. Aborting.");
      return;
    }

    final worldSeason = Season.fromMap(worldSeasonDoc.data()!);
    // Create a map of circuitId -> RaceEvent for easy lookup
    final Map<String, RaceEvent> referenceMap = {
      for (var race in worldSeason.calendar) race.circuitId: race,
    };

    debugPrint("Reference calendar loaded from ftg_world ($worldSeasonId)");

    // 3. Update target seasons
    for (var entry in targetSeasons.entries) {
      final leagueId = entry.key;
      final seasonId = entry.value;

      await _fixSeasonCalendar(seasonId, leagueId, referenceMap);
    }

    debugPrint("Race Calendar Maintenance completed.");
  }

  Future<void> _fixSeasonCalendar(
    String seasonId,
    String leagueId,
    Map<String, RaceEvent> referenceMap,
  ) async {
    debugPrint("Fixing calendar for season: $seasonId (League: $leagueId)");

    final seasonDoc = await _db.collection('seasons').doc(seasonId).get();
    if (!seasonDoc.exists || seasonDoc.data() == null) {
      debugPrint("Season $seasonId not found. Skipping.");
      return;
    }

    final season = Season.fromMap(seasonDoc.data()!);
    final List<RaceEvent> calendar = List.from(season.calendar);
    bool changed = false;

    for (int i = 0; i < calendar.length; i++) {
      final race = calendar[i];

      // Skip completed races to preserve player history
      if (race.isCompleted) continue;

      // Look up the circuit in the reference map
      final referenceRace = referenceMap[race.circuitId];
      if (referenceRace == null) {
        debugPrint(
          "No reference found for circuit ${race.circuitId}. Skipping.",
        );
        continue;
      }

      // Update if laps or weather differ from reference
      bool lapsMatch = race.totalLaps == referenceRace.totalLaps;
      bool weatherMatch =
          race.weatherQualifying == referenceRace.weatherQualifying &&
          race.weatherRace == referenceRace.weatherRace;

      if (!lapsMatch || !weatherMatch) {
        debugPrint(
          "Updating ${race.trackName}: "
          "Laps (${race.totalLaps} -> ${referenceRace.totalLaps}), "
          "Qualy (${race.weatherQualifying} -> ${referenceRace.weatherQualifying}), "
          "Race (${race.weatherRace} -> ${referenceRace.weatherRace})",
        );

        calendar[i] = race.copyWith(
          totalLaps: referenceRace.totalLaps,
          weatherQualifying: referenceRace.weatherQualifying,
          weatherRace: referenceRace.weatherRace,
        );
        changed = true;
      }
    }

    if (changed) {
      await _db.collection('seasons').doc(seasonId).update({
        'calendar': calendar.map((e) => e.toMap()).toList(),
      });
      debugPrint("Season $seasonId updated successfully.");
    } else {
      debugPrint("No changes needed for season $seasonId.");
    }
  }
}
