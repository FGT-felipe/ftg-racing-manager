import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/core_models.dart';

/// Race document status in Firestore `races/{raceId}`.
enum RaceDocumentStatus {
  scheduled,
  qualifying,
  completed,
}

/// Service for active season and current race. Provides race document id
/// for qualifying grid and race results.
class SeasonService {
  static final SeasonService _instance = SeasonService._internal();
  factory SeasonService() => _instance;
  SeasonService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of the active season (first season in collection).
  /// For single-league setups; extend later with league/division filter if needed.
  Stream<Season?> getActiveSeasonStream() {
    return _db.collection('seasons').limit(1).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return Season.fromMap(data);
    });
  }

  /// One-shot fetch of active season.
  Future<Season?> getActiveSeason() async {
    final snapshot = await _db.collection('seasons').limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    data['id'] = doc.id;
    return Season.fromMap(data);
  }

  /// Index of the next uncompleted race in the calendar (-1 if all completed).
  int getCurrentRaceIndex(Season season) {
    return season.calendar.indexWhere((r) => !r.isCompleted);
  }

  /// Current (next) race event and its index. Returns null if no pending race.
  ({RaceEvent event, int index})? getCurrentRace(Season season) {
    final index = getCurrentRaceIndex(season);
    if (index == -1) return null;
    return (event: season.calendar[index], index: index);
  }

  /// Stable race document id for this season + race event.
  String raceDocumentId(String seasonId, RaceEvent event) {
    return '${seasonId}_${event.id}';
  }

  /// Gets or creates the race document for the current weekend.
  /// Returns the race document id. Creates with status 'scheduled' if missing.
  Future<String> getOrCreateRaceDocument(String seasonId, RaceEvent event) async {
    final raceId = raceDocumentId(seasonId, event);
    final ref = _db.collection('races').doc(raceId);
    final doc = await ref.get();
    if (doc.exists) return raceId;
    await ref.set({
      'seasonId': seasonId,
      'raceEventId': event.id,
      'trackName': event.trackName,
      'countryCode': event.countryCode,
      'circuitId': event.circuitId,
      'status': RaceDocumentStatus.scheduled.name,
      'grid': <String, dynamic>{},
      'results': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return raceId;
  }

  /// Fetches race document snapshot (for grid/status/results).
  Future<DocumentSnapshot> getRaceDocument(String raceId) async {
    return _db.collection('races').doc(raceId).get();
  }

  /// Updates race document with qualifying grid. Status becomes 'qualifying' or stays.
  Future<void> saveQualifyingGrid(
    String raceId,
    List<Map<String, dynamic>> gridResults,
  ) async {
    final ref = _db.collection('races').doc(raceId);
    final grid = <String, int>{};
    for (var i = 0; i < gridResults.length; i++) {
      grid[gridResults[i]['driverId'] as String] = i + 1;
    }
    await ref.update({
      'grid': grid,
      'qualifyingResults': gridResults,
      'status': RaceDocumentStatus.qualifying.name,
      'gridUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates race document with race results and sets status to completed.
  Future<void> saveRaceResults(
    String raceId,
    Map<String, int> finalPositions,
    Map<String, dynamic>? extraResults,
  ) async {
    final ref = _db.collection('races').doc(raceId);
    final update = <String, dynamic>{
      'results': finalPositions,
      'status': RaceDocumentStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    };
    if (extraResults != null) update.addAll(extraResults);
    await ref.update(update);
  }
}
