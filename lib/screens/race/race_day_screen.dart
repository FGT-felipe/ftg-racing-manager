import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/season_service.dart';
import '../../services/universe_service.dart';
import '../../services/time_service.dart';
import '../../services/circuit_service.dart';
import '../../services/race_service.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';

/// Race Day "Live" Viewer
///
/// Reads pre-computed lap data from Firestore (races/{raceId}/laps) written
/// by the Cloud Function `scheduledRace`.  The viewer determines which lap is
/// "current" based on elapsed wall-clock time since the race start (Sunday
/// 14:00 COT).  Data is refreshed periodically so the user sees incremental
/// position updates without any client-side simulation.
class RaceDayScreen extends StatefulWidget {
  final String teamId;

  const RaceDayScreen({super.key, required this.teamId});

  @override
  State<RaceDayScreen> createState() => _RaceDayScreenState();
}

class _RaceDayScreenState extends State<RaceDayScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ───
  bool _isLoading = true;
  String? _error;

  // Race metadata
  String _circuitName = '';
  String _flagEmoji = '🏁';
  int _totalLaps = 50;
  String? _raceId;
  bool _isFinished = false;
  double _liveDurationSeconds = 0;
  int _updateIntervalSeconds = 120;

  // Lap data keyed by lap number
  final Map<int, Map<String, dynamic>> _lapDataMap = {};
  List<int> _sortedLapKeys = [];

  // Current display state
  int _currentLapNumber = 0;
  Map<String, dynamic> _currentPositions = {}; // driverId -> position
  Map<String, dynamic> _previousPositions =
      {}; // driverId -> position (last lap)
  Map<String, dynamic> _currentLapTimes = {};
  Map<String, dynamic> _currentTyres = {}; // driverId -> TyreCompound
  Map<String, double> _bestLapTimes = {}; // driverId -> best lap time
  List<Map<String, dynamic>> _allEvents =
      []; // Cumulative events up to current lap

  String? _overallFastestDriverId;
  double _overallFastestTime = double.infinity;
  double _leaderTotalTime = 0.0;

  // Drivers / Teams cache
  final Map<String, String> _driverNames = {};
  final Map<String, String> _driverTeamIds = {};
  final Map<String, String> _teamNames = {};

  // Timers
  Timer? _refreshTimer;
  Timer? _tickTimer;
  DateTime? _raceStartTime;

  // Animation
  late AnimationController _pulseController;
  final ScrollController _leaderboardScroll = ScrollController();
  final ScrollController _eventsScroll = ScrollController();
  final ScrollController _commentaryScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadRaceData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tickTimer?.cancel();
    _pulseController.dispose();
    _leaderboardScroll.dispose();
    _eventsScroll.dispose();
    _commentaryScroll.dispose();
    super.dispose();
  }

  // ─── Data Loading ───

  Future<void> _loadRaceData() async {
    try {
      // 1. Get active season & current race
      final season = await SeasonService().getActiveSeason();
      if (season == null) throw Exception('No active season');

      final currentRace = SeasonService().getCurrentRace(season);
      if (currentRace == null) throw Exception('No current race');

      final raceEvent = currentRace.event;
      _circuitName = raceEvent.trackName;
      _flagEmoji = raceEvent.flagEmoji;
      _totalLaps = raceEvent.totalLaps;

      final circuitProfile = CircuitService().getCircuitProfile(
        raceEvent.circuitId,
      );
      _totalLaps = circuitProfile.laps;

      _raceId = SeasonService().raceDocumentId(season.id, raceEvent);

      // 2. Get race document
      final raceDoc = await FirebaseFirestore.instance
          .collection('races')
          .doc(_raceId)
          .get();

      if (!raceDoc.exists) throw Exception('Race document not found');

      final raceData = raceDoc.data()!;
      _isFinished = raceData['isFinished'] == true;
      _liveDurationSeconds =
          (raceData['liveDurationSeconds'] as num?)?.toDouble() ?? 0;
      _updateIntervalSeconds =
          (raceData['updateIntervalSeconds'] as num?)?.toInt() ?? 120;

      // Calculate race start time (Sunday 14:00 Bogotá of current week)
      _raceStartTime = _calculateRaceStartTime(raceEvent.date);

      // 3. Pre-load driver/team names from qualyGrid
      final grid = raceData['qualyGrid'] as List<dynamic>? ?? [];
      for (var entry in grid) {
        final e = Map<String, dynamic>.from(entry);
        final driverId = e['driverId'] as String;
        _driverNames[driverId] = e['driverName'] as String? ?? 'Driver';
        _driverTeamIds[driverId] = e['teamId'] as String? ?? '';
        _teamNames[e['teamId'] as String? ?? ''] =
            e['teamName'] as String? ?? 'Team';
      }

      // If driver names are missing from grid, fetch from drivers collection
      if (_driverNames.isEmpty && raceData['finalPositions'] != null) {
        final positions = Map<String, dynamic>.from(raceData['finalPositions']);
        for (var driverId in positions.keys) {
          if (!_driverNames.containsKey(driverId)) {
            try {
              final dDoc = await FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(driverId)
                  .get();
              if (dDoc.exists) {
                _driverNames[driverId] = dDoc.data()?['name'] ?? 'Driver';
                _driverTeamIds[driverId] = dDoc.data()?['teamId'] ?? '';
              }
            } catch (_) {}
          }
        }
      }

      // 4. Load laps subcollection
      await _fetchLapsData();

      // 5. Calculate current lap based on time
      _updateCurrentLap();

      // 6. Start periodic refresh
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(
        Duration(seconds: _updateIntervalSeconds),
        (_) => _fetchLapsAndUpdate(),
      );

      // 7. Start tick timer for lap progress animation
      _tickTimer?.cancel();
      _tickTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) {
          _updateCurrentLap();
          setState(() {});
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  DateTime _calculateRaceStartTime(DateTime? raceDate) {
    if (raceDate != null) {
      // Race date from calendar, use 14:00 on that day
      return DateTime(raceDate.year, raceDate.month, raceDate.day, 14, 0, 0);
    }
    // Fallback: this Sunday at 14:00
    final now = TimeService().nowBogota;
    final daysUntilSunday = (7 - now.weekday) % 7;
    final sunday = now.add(Duration(days: daysUntilSunday));
    return DateTime(sunday.year, sunday.month, sunday.day, 14, 0, 0);
  }

  Future<void> _fetchLapsData() async {
    if (_raceId == null) return;

    final lapsSnap = await FirebaseFirestore.instance
        .collection('races')
        .doc(_raceId)
        .collection('laps')
        .orderBy(FieldPath.documentId)
        .get();

    _lapDataMap.clear();
    for (var doc in lapsSnap.docs) {
      final lapNum = int.tryParse(doc.id) ?? 0;
      _lapDataMap[lapNum] = doc.data();
    }
    _sortedLapKeys = _lapDataMap.keys.toList()..sort();
  }

  Future<void> _fetchLapsAndUpdate() async {
    if (_isDemoMode) return;
    await _fetchLapsData();
    _updateCurrentLap();
    if (mounted) setState(() {});
  }

  void _updateCurrentLap() {
    if (_sortedLapKeys.isEmpty) {
      _currentLapNumber = 0;
      return;
    }

    if (_isFinished) {
      // Show final lap
      _currentLapNumber = _sortedLapKeys.last;
    } else if (_raceStartTime != null && _liveDurationSeconds > 0) {
      // Calculate elapsed time
      final now = TimeService().nowBogota;
      final elapsed = now.difference(_raceStartTime!).inSeconds;

      if (elapsed <= 0) {
        _currentLapNumber = 0;
      } else {
        // Map elapsed time to lap number
        final fraction = (elapsed / _liveDurationSeconds).clamp(0.0, 1.0);
        final estimatedLap = (fraction * _totalLaps).round().clamp(
          1,
          _totalLaps,
        );

        // Find the closest key lap we have data for
        _currentLapNumber = _sortedLapKeys.first;
        for (var key in _sortedLapKeys) {
          if (key <= estimatedLap) {
            _currentLapNumber = key;
          } else {
            break;
          }
        }
      }
    } else {
      // No timing info — show latest available
      _currentLapNumber = _sortedLapKeys.last;
    }

    // Build display data from current lap
    _buildDisplayData();
  }

  void _buildDisplayData() {
    final lapData = _lapDataMap[_currentLapNumber];
    if (lapData == null) {
      _currentPositions = {};
      _currentLapTimes = {};
      _allEvents = [];
      return;
    }

    _currentPositions = Map<String, dynamic>.from(lapData['positions'] ?? {});
    _currentLapTimes = Map<String, dynamic>.from(lapData['lapTimes'] ?? {});
    _currentTyres = Map<String, dynamic>.from(lapData['tyres'] ?? {});

    // Gather all events from lap 1 to current lap
    final List<Map<String, dynamic>> localEvents = [];
    double localOverallFastestTime = double.infinity;
    String? localOverallFastestDriverId;
    double localLeaderTotalTime = 0.0;

    Map<String, dynamic> localPreviousPositions = {};
    Map<String, double> localBestLapTimes = {};

    for (var key in _sortedLapKeys) {
      if (key > _currentLapNumber) break;
      final ld = _lapDataMap[key];
      if (ld == null) continue;

      final positions = ld['positions'] as Map<String, dynamic>? ?? {};
      final lapTimes = ld['lapTimes'] as Map<String, dynamic>? ?? {};

      // Track previous positions for the change indicator
      if (key == _currentLapNumber - 1) {
        localPreviousPositions = Map.from(positions);
      } else if (_currentLapNumber == 1 && key == 0) {
        // If current lap is 1 and we have grid data (lap 0)
        localPreviousPositions = Map.from(positions);
      }

      // Track personal best lap times
      for (var entry in lapTimes.entries) {
        final driverId = entry.key;
        final t = (entry.value as num?)?.toDouble() ?? 999.0;
        if (t < 900) {
          final currentBest = localBestLapTimes[driverId] ?? double.infinity;
          if (t < currentBest) {
            localBestLapTimes[driverId] = t;
          }
        }
      }

      // Accumulate leader's total time for this lap
      int bestPos = 999;
      String? lapLeader;
      for (var pe in positions.entries) {
        final p = (pe.value as num).toInt();
        if (p < bestPos) {
          bestPos = p;
          lapLeader = pe.key;
        }
      }
      if (lapLeader != null) {
        final lt = (lapTimes[lapLeader] as num?)?.toDouble() ?? 0;
        if (lt < 900) localLeaderTotalTime += lt;
      }

      // Add original events with position tag
      if (ld['events'] != null) {
        for (var evt in (ld['events'] as List<dynamic>)) {
          final evtMap = Map<String, dynamic>.from(evt);
          // Tag with the driver's position in this lap
          final driverId = (evtMap['driverId'] as String?) ?? '';
          final driverPos = (positions[driverId] as num?)?.toInt() ?? 99;
          evtMap['position'] = driverPos;
          localEvents.add(evtMap);
        }
      }

      // Inject FASTEST_LAP event when a new overall fastest is set
      String? lapFastestId;
      double lapFastestTime = double.infinity;
      for (var entry in lapTimes.entries) {
        final t = (entry.value as num?)?.toDouble() ?? 999.0;
        if (t < 900 && t < lapFastestTime) {
          lapFastestTime = t;
          lapFastestId = entry.key;
        }
      }
      if (lapFastestId != null && lapFastestTime < localOverallFastestTime) {
        localOverallFastestTime = lapFastestTime;
        localOverallFastestDriverId = lapFastestId;
        localEvents.add({
          'type': 'FASTEST_LAP',
          'lap': key,
          'driverId': localOverallFastestDriverId,
          'desc':
              '${_formatLapTime(localOverallFastestTime)} — New fastest lap of the race!',
          'position': (positions[lapFastestId] as num?)?.toInt() ?? 99,
        });
      }
    }

    // Commit to state variables at once
    _allEvents = localEvents;
    _overallFastestTime = localOverallFastestTime;
    _overallFastestDriverId = localOverallFastestDriverId;
    _leaderTotalTime = localLeaderTotalTime;
    _previousPositions = localPreviousPositions;
    _bestLapTimes = localBestLapTimes;

    // Inject a FINISH event when race reaches the last lap
    if (_currentLapNumber >= _totalLaps && _currentLapNumber > 0) {
      final sorted = _currentPositions.entries.toList()
        ..sort(
          (a, b) =>
              (a.value as num).toInt().compareTo((b.value as num).toInt()),
        );

      final p1 = sorted.isNotEmpty ? _driverName(sorted[0].key) : '???';
      final p2 = sorted.length > 1 ? _driverName(sorted[1].key) : '???';
      final p3 = sorted.length > 2 ? _driverName(sorted[2].key) : '???';

      _allEvents.add({
        'type': 'FINISH',
        'lap': _currentLapNumber,
        'driverId': sorted.isNotEmpty ? sorted[0].key : '',
        'desc': 'P1: $p1 — P2: $p2 — P3: $p3',
        'position': 1,
      });
    }
  }

  // ─── QA DEMO MODE ───

  void _promptDemoMode() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("QA DEMO MODE"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter Admin Password"),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == "ftgadmin2026") {
                Navigator.pop(context);
                _enableDemoMode();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid Password")),
                );
              }
            },
            child: const Text("ACCESS"),
          ),
        ],
      ),
    );
  }

  void _enableDemoMode() {
    setState(() {
      _isLoading = false;
      _error = null;
      _isDemoMode = true;
      _isFinished = false;
    });
    _runDemoSimulation();
  }

  bool _isDemoMode = false;
  RaceSessionResult? _demoResult;

  Future<void> _runDemoSimulation() async {
    setState(() => _isLoading = true);
    try {
      final season = await SeasonService().getActiveSeason();
      if (season == null) throw Exception("No Active Season");
      final currentRace = SeasonService().getCurrentRace(season);
      if (currentRace == null) throw Exception("No Current Race");

      // 1. Get Circuit
      final circuit = CircuitService().getCircuitProfile(
        currentRace.event.circuitId,
      );
      _circuitName = currentRace.event.trackName;
      _flagEmoji = currentRace.event.flagEmoji;
      _totalLaps = circuit.laps;

      // 2. Fetch Teams & Drivers with League Filtering
      final teamsSnap = await FirebaseFirestore.instance
          .collection('teams')
          .get();
      final driversSnap = await FirebaseFirestore.instance
          .collection('drivers')
          .get();

      // Filter teams: Only show teams from the SAME LEAGUE as the current teamId.
      final universe = await UniverseService().getUniverse();
      Set<String> validTeamIds = {};

      if (universe != null) {
        Set<String> targetLeagueTeamIds = {};
        Set<String> allUniverseTeamIds = {};

        for (final league in universe.getAllLeagues()) {
          final leagueTeams = league.teams.map((t) => t.id).toSet();
          allUniverseTeamIds.addAll(leagueTeams);

          if (leagueTeams.contains(widget.teamId)) {
            targetLeagueTeamIds = leagueTeams;
          }
        }

        if (targetLeagueTeamIds.isNotEmpty) {
          // User is in a known Universe league -> show that league
          validTeamIds = targetLeagueTeamIds;
        } else {
          // User is NOT in a Universe league -> show "Manual/Custom" league (teams not in universe)
          validTeamIds = teamsSnap.docs
              .map((d) => d.id)
              .toSet()
              .difference(allUniverseTeamIds);
        }
      } else {
        // Fallback: show all if universe not ready
        validTeamIds = teamsSnap.docs.map((d) => d.id).toSet();
      }

      final Map<String, Team> teamsMap = {};
      final Map<String, Driver> driversMap = {};
      final List<Map<String, dynamic>> grid = [];
      final Map<String, CarSetup> setupsMap = {};

      for (var doc in teamsSnap.docs) {
        if (!validTeamIds.contains(doc.id)) continue;
        final t = Team.fromMap(doc.data());
        teamsMap[t.id] = t;
      }

      int gridPos = 1;
      for (var doc in driversSnap.docs) {
        final d = Driver.fromMap(doc.data());
        if (d.teamId != null && teamsMap.containsKey(d.teamId)) {
          driversMap[d.id] = d;
          grid.add({
            'driverId': d.id,
            'teamId': d.teamId,
            'position': gridPos++,
            'lapTime': 80.0 + gridPos * 0.1, // Fake qualy
          });

          // Randomize setup for Demo to test different strategies
          final setup = CarSetup();
          final rng = Random();
          final strategyRand = rng.nextInt(3);
          if (strategyRand == 0) {
            setup.tyreCompound = TyreCompound.soft;
            setup.pitStops = [TyreCompound.hard];
            setup.raceStyle = DriverStyle.offensive;
            setup.initialFuel = 40.0;
          } else if (strategyRand == 1) {
            setup.tyreCompound = TyreCompound.medium;
            setup.pitStops = [TyreCompound.hard];
            setup.raceStyle = DriverStyle.normal;
            setup.initialFuel = 50.0;
          } else {
            setup.tyreCompound = TyreCompound.hard;
            setup.pitStops = [TyreCompound.medium];
            setup.raceStyle = DriverStyle.defensive;
            setup.initialFuel = 60.0;
          }
          setupsMap[d.id] = setup;

          _driverNames[d.id] = d.name;
          _driverTeamIds[d.id] = d.teamId!;
          _teamNames[d.teamId!] = teamsMap[d.teamId]?.name ?? "Team";
        }
      }

      // 3. Simulate
      final result = await RaceService().simulateRaceSession(
        raceId: "demo_race",
        leagueId: season.leagueId,
        circuit: circuit,
        grid: grid,
        teamsMap: teamsMap,
        driversMap: driversMap,
        setupsMap: setupsMap,
        isDemo: true,
      );

      _demoResult = result;
      _convertDemoResultToLapData();

      // 4. Start Demo Replay (4 minutes duration)
      // Total Laps / 4 minutes = Laps per second?
      // 4 minutes = 240 seconds.
      // If 50 laps, that's 1 lap every 4.8 seconds.
      final lapIntervalMs = (240 * 1000) ~/ _totalLaps;

      setState(() {
        _isLoading = false;
        _currentLapNumber = 0;
      });

      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(Duration(milliseconds: lapIntervalMs), (
        timer,
      ) {
        if (_currentLapNumber < _totalLaps) {
          setState(() {
            _currentLapNumber++;
            _buildDisplayData();
          });
        } else {
          timer.cancel();
          setState(() => _isFinished = true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Demo Error: $e";
        });
      }
    }
  }

  void _convertDemoResultToLapData() {
    if (_demoResult == null) return;
    _lapDataMap.clear();

    for (var lap in _demoResult!.laps) {
      // Convert LapData to Map
      _lapDataMap[lap.lapNumber] = {
        'positions': lap.positions,
        'lapTimes': lap.driverLapTimes,
        'tyres': lap.driverTyres,
        'events': lap.events
            .map(
              (e) => {
                'type': e.type,
                'lap': e.lapNumber,
                'driverId': e.driverId,
                'desc': e.description,
              },
            )
            .toList(),
      };
    }
    _sortedLapKeys = _lapDataMap.keys.toList()..sort();
  }

  // ─── Helpers ───

  String _formatLapTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds - (mins * 60);
    return "$mins:${secs.toStringAsFixed(3).padLeft(6, '0')}";
  }

  String _formatRaceTime(double totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final mins = ((totalSeconds % 3600) / 60).floor();
    final secs = (totalSeconds % 60).floor();
    return '${hours.toString().padLeft(2, '0')}H:${mins.toString().padLeft(2, '0')}M:${secs.toString().padLeft(2, '0')}S';
  }

  String _driverName(String driverId) {
    return _driverNames[driverId] ?? 'Driver';
  }

  String _driverTeamName(String driverId) {
    final teamId = _driverTeamIds[driverId] ?? '';
    return _teamNames[teamId] ?? 'Team';
  }

  bool _isPlayerTeam(String driverId) {
    return _driverTeamIds[driverId] == widget.teamId;
  }

  Color _eventColor(String type) {
    switch (type.toUpperCase()) {
      case 'OVERTAKE':
        return const Color(0xFF00C853);
      case 'PIT':
        return const Color(0xFFFFB800);
      case 'DNF':
        return const Color(0xFFFF5252);
      case 'INFO':
        return Colors.blueAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _eventIcon(String type) {
    switch (type.toUpperCase()) {
      case 'OVERTAKE':
        return Icons.swap_vert;
      case 'PIT':
        return Icons.local_gas_station;
      case 'DNF':
        return Icons.warning_amber_rounded;
      case 'INFO':
        return Icons.info_outline;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getTyreColor(TyreCompound? compound) {
    switch (compound) {
      case TyreCompound.soft:
        return Colors.redAccent;
      case TyreCompound.medium:
        return Colors.yellowAccent;
      case TyreCompound.hard:
        return Colors.white70;
      case TyreCompound.wet:
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  String _getTyreShorthand(TyreCompound? compound) {
    switch (compound) {
      case TyreCompound.soft:
        return 'S';
      case TyreCompound.medium:
        return 'M';
      case TyreCompound.hard:
        return 'H';
      case TyreCompound.wet:
        return 'W';
      default:
        return '?';
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeService = TimeService();

    // Check race status
    return FutureBuilder<Season?>(
      future: SeasonService().getActiveSeason(),
      builder: (context, snapshot) {
        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: theme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'LOADING RACE DATA...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        if (_error != null) {
          return _buildLockedState(context);
        }

        final season = snapshot.data;
        final currentRace = season != null
            ? SeasonService().getCurrentRace(season)
            : null;
        final status = timeService.getRaceWeekStatus(
          timeService.nowBogota,
          currentRace?.event.date,
        );

        // If no lap data and not race time, show locked state
        if (_sortedLapKeys.isEmpty &&
            status != RaceWeekStatus.race &&
            status != RaceWeekStatus.postRace) {
          return _buildLockedState(context);
        }

        // If we have lap data OR it's race/postRace time, show race viewer
        return _buildRaceViewer(context);
      },
    );
  }

  Widget _buildLockedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'RACE DAY',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _circuitName.isNotEmpty
                ? '$_flagEmoji $_circuitName'
                : 'Waiting for race data...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              _isFinished
                  ? 'RACE COMPLETED — VIEW RESULTS'
                  : 'RACE STARTS SUNDAY 2:00 PM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: _promptDemoMode,
            icon: Icon(
              Icons.bug_report,
              size: 14,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            label: Text(
              "QA DEMO",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceViewer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── RACE HEADER ───
          _buildRaceHeader(context),
          const SizedBox(height: 12),

          // ─── MAIN CONTENT: Leaderboard + Pit Board side by side ───
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Leaderboard
                Expanded(flex: 6, child: _buildLeaderboard(context)),
                const SizedBox(width: 12),
                // Right: Pit Board + Commentary
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(flex: 5, child: _buildEventFeed(context)),
                      const SizedBox(height: 12),
                      Expanded(flex: 5, child: _buildCommentaryFeed(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── RACE HEADER ───

  Widget _buildRaceHeader(BuildContext context) {
    final progress = _totalLaps > 0
        ? (_currentLapNumber / _totalLaps).clamp(0.0, 1.0)
        : 0.0;

    final bool isLive = !_isFinished && _currentLapNumber > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Live indicator
              if (isLive)
                FadeTransition(
                  opacity: _pulseController,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          color: Color(0xFFFF5252),
                          size: 10,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isFinished
                        ? const Color(0xFF00C853).withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isFinished
                          ? const Color(0xFF00C853).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    _isFinished ? 'FINISHED' : 'PRE-RACE',
                    style: TextStyle(
                      color: _isFinished
                          ? const Color(0xFF00C853)
                          : Colors.white54,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

              const SizedBox(width: 16),

              // Circuit name
              Expanded(
                child: Text(
                  '$_flagEmoji  ${_circuitName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Lap counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'LAP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_currentLapNumber',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' / $_totalLaps',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                _isFinished ? const Color(0xFF00C853) : const Color(0xFFFF5252),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Fastest Lap & Total Race Time row
          Builder(
            builder: (context) {
              final hasFastest =
                  _overallFastestDriverId != null &&
                  _overallFastestTime < double.infinity;

              return Row(
                children: [
                  // Fastest Lap
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: const Color(0xFFE040FB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FASTEST LAP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasFastest)
                          Flexible(
                            child: Text(
                              '${_driverName(_overallFastestDriverId!)}  ${_formatLapTime(_overallFastestTime)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE040FB),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          Text(
                            '—',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Total Race Time
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RACE TIME',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _leaderTotalTime > 0
                            ? _formatRaceTime(_leaderTotalTime)
                            : '—',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── LEADERBOARD ───

  Widget _buildLeaderboard(BuildContext context) {
    if (_currentPositions.isEmpty) {
      return _buildEmptyCard(
        context,
        'POSITIONS',
        Icons.format_list_numbered,
        'Waiting for race to start...',
      );
    }

    // Sort by position
    final sorted = _currentPositions.entries.toList()
      ..sort(
        (a, b) => (a.value as num).toInt().compareTo((b.value as num).toInt()),
      );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.format_list_numbered,
                  color: Color(0xFFFF5252),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'RACE POSITIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFFFF5252),
                  ),
                ),
                const Spacer(),
                Text(
                  '${sorted.length} DRIVERS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withValues(alpha: 0.03),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    '', // Prev Pos Icon Space
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    'POS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DRIVER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    'LATEST',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    'BEST',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'INTERVAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

          // Rows
          Expanded(
            child: Builder(
              builder: (context) {
                // Get leader's lap time for gap calculation
                final leaderId = sorted.isNotEmpty ? sorted.first.key : null;
                final leaderLapTime = leaderId != null
                    ? (_currentLapTimes[leaderId] as num?)?.toDouble()
                    : null;

                return ListView.builder(
                  controller: _leaderboardScroll,
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final entry = sorted[index];
                    final driverId = entry.key;
                    final pos = (entry.value as num).toInt();
                    final lapTime = (_currentLapTimes[driverId] as num?)
                        ?.toDouble();
                    final isPlayer = _isPlayerTeam(driverId);
                    final isDnf = lapTime == null || lapTime > 900;
                    final isFastestLap = driverId == _overallFastestDriverId;
                    final isPitting = _allEvents.any(
                      (e) =>
                          e['driverId'] == driverId &&
                          e['lap'] == _currentLapNumber &&
                          e['type']?.toString().toUpperCase() == 'PIT',
                    );

                    // Compute Position Change
                    IconData? changeIcon;
                    Color? changeColor;
                    if (_previousPositions.containsKey(driverId)) {
                      final prevPos = (_previousPositions[driverId] as num)
                          .toInt();
                      if (pos < prevPos) {
                        changeIcon = Icons.arrow_drop_up;
                        changeColor = const Color(0xFF00C853); // Green
                      } else if (pos > prevPos) {
                        changeIcon = Icons.arrow_drop_down;
                        changeColor = const Color(0xFFFF5252); // Red
                      } else {
                        changeIcon = Icons.remove;
                        changeColor = Colors.white.withValues(
                          alpha: 0.3,
                        ); // Neutral
                      }
                    }

                    // Compute interval text
                    String intervalText;
                    if (isDnf) {
                      intervalText = 'RETIRED';
                    } else if (index == 0) {
                      intervalText = 'LEADER';
                    } else if (leaderLapTime != null && leaderLapTime < 900) {
                      final gap = lapTime - leaderLapTime;
                      intervalText = '+${gap.toStringAsFixed(3)}s';
                    } else {
                      intervalText = _formatLapTime(lapTime);
                    }

                    // Compute times
                    final latestLapText = isDnf ? '—' : _formatLapTime(lapTime);
                    final bestLapNum = _bestLapTimes[driverId];
                    final bestLapText = (bestLapNum != null && bestLapNum < 900)
                        ? _formatLapTime(bestLapNum)
                        : '—';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isPlayer
                            ? Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.08)
                            : null,
                        border: Border(
                          left: isPlayer
                              ? BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  width: 3,
                                )
                              : BorderSide.none,
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Change Icon
                          SizedBox(
                            width: 16,
                            child: changeIcon != null
                                ? Icon(changeIcon, size: 16, color: changeColor)
                                : const SizedBox.shrink(),
                          ),

                          // Position
                          SizedBox(
                            width: 24,
                            child: Text(
                              isDnf ? 'DNF' : '$pos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDnf
                                    ? const Color(0xFFFF5252)
                                    : (pos <= 3
                                          ? const Color(0xFFFFB800)
                                          : Colors.white.withValues(
                                              alpha: 0.7,
                                            )),
                              ),
                            ),
                          ),

                          // Driver name
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Tyre Compound Indicator
                                    if (!isDnf &&
                                        _currentTyres.containsKey(driverId))
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _getTyreColor(
                                              _currentTyres[driverId]
                                                  as TyreCompound?,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          _getTyreShorthand(
                                            _currentTyres[driverId]
                                                as TyreCompound?,
                                          ),
                                          style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: _getTyreColor(
                                              _currentTyres[driverId]
                                                  as TyreCompound?,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        _driverName(driverId),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isPlayer
                                              ? FontWeight.w900
                                              : FontWeight.w500,
                                          color: isFastestLap && !isDnf
                                              ? const Color(0xFFE040FB)
                                              : (isPlayer
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.secondary
                                                    : (isDnf
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                          : Colors.white
                                                                .withValues(
                                                                  alpha: 0.9,
                                                                ))),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isPitting && !isDnf) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.local_gas_station,
                                        size: 10,
                                        color: Color(0xFFFFB800),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'IN BOXES!',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFFFB800),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                // Show team abbreviation below driver name to save space
                                Text(
                                  _driverTeamName(driverId),
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white.withValues(
                                      alpha: isDnf ? 0.2 : 0.4,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Latest Lap
                          SizedBox(
                            width: 55,
                            child: Text(
                              latestLapText,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Colors.white.withValues(
                                  alpha: isDnf ? 0.3 : 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Best Lap
                          SizedBox(
                            width: 55,
                            child: Text(
                              bestLapText,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: isFastestLap
                                    ? const Color(0xFFE040FB)
                                    : Colors.white.withValues(alpha: 0.9),
                                fontWeight: isFastestLap
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Interval (gap to leader)
                          Expanded(
                            flex: 1,
                            child: Text(
                              intervalText,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDnf
                                    ? const Color(0xFFFF5252)
                                    : (isFastestLap
                                          ? const Color(0xFFE040FB)
                                          : Colors.white.withValues(
                                              alpha: 0.7,
                                            )),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── EVENT FEED / PIT BOARD ───

  Widget _buildEventFeed(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.developer_board,
                  color: Color(0xFFFFB800),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'PIT BOARD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFFFFB800),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_allEvents.where((e) => _isPlayerTeam(e['driverId'] ?? '')).length} EVENTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // Events list (filtered to player's drivers only)
          Expanded(
            child: () {
              final playerEvents = _allEvents
                  .where((e) => _isPlayerTeam(e['driverId'] ?? ''))
                  .toList();
              if (playerEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.radio_button_unchecked,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentLapNumber == 0
                            ? 'LIGHTS OUT SOON...'
                            : 'NO EVENTS YET',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: _eventsScroll,
                reverse: true,
                itemCount: playerEvents.length,
                itemBuilder: (context, index) {
                  final evt = playerEvents[playerEvents.length - 1 - index];
                  return _buildEventItem(context, evt);
                },
              );
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Map<String, dynamic> evt) {
    final type = (evt['type'] as String?) ?? 'INFO';
    final lap = (evt['lap'] as num?)?.toInt() ?? 0;
    final driverId = (evt['driverId'] as String?) ?? '';
    final desc = (evt['desc'] as String?) ?? '';
    final color = _eventColor(type);
    final icon = _eventIcon(type);
    final isPlayer = _isPlayerTeam(driverId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPlayer
            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lap badge
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'L$lap',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),

          // Event icon
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),

          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName(driverId).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isPlayer
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── COMMENTARY FEED (TV/Radio style) ───

  String _generateCommentary(Map<String, dynamic> evt) {
    final type = (evt['type'] as String?) ?? 'INFO';
    final driverId = (evt['driverId'] as String?) ?? '';
    final desc = (evt['desc'] as String?) ?? '';
    final name = _driverName(driverId);
    final team = _driverTeamName(driverId);
    final lap = (evt['lap'] as num?)?.toInt() ?? 0;
    final rng = Random(name.hashCode ^ lap);

    switch (type.toUpperCase()) {
      case 'OVERTAKE':
        final phrases = [
          "And $name makes a brilliant move! $desc What a display of racecraft from the $team driver!",
          "Wheel to wheel action! $name goes for it — $desc Incredible bravery!",
          "The crowd is on their feet! $name with an audacious overtake — $desc",
          "What a move by $name of $team! $desc That's racing at its finest!",
        ];
        return phrases[rng.nextInt(phrases.length)];
      case 'PIT':
        final pos = (evt['position'] as num?)?.toInt() ?? 99;
        if (pos <= 3 && pos > 0) {
          final top3Phrases = [
            "BOX BOX! The leader $name is in! $desc This is a critical moment for $team!",
            "Strategy unfolding! $name from P$pos dives into the pits. $desc $team needs a perfect stop here!",
            "Tension in the pit lane as $name brings it in! $desc Can $team keep them in the top 3?",
            "Massive call! $name is pitting from P$pos. $desc Let's see how the $team crew handles the pressure!",
          ];
          return top3Phrases[rng.nextInt(top3Phrases.length)];
        }
        final phrases = [
          "Box box box! $name dives into the pit lane. $desc The $team crew is ready!",
          "$name heads for the pits — $desc Let's see how fast the $team crew can turn this around!",
          "Strategic call from $team! $name comes in for a stop. $desc",
        ];
        return phrases[rng.nextInt(phrases.length)];
      case 'DNF':
        final phrases = [
          "Oh no! Disaster strikes for $name! $desc The $team garage won't want to see this replay.",
          "Heartbreak for $team — $name is OUT of the race. $desc What a cruel sport.",
          "And that's the end of the day for $name. $desc Absolutely gutted.",
        ];
        return phrases[rng.nextInt(phrases.length)];
      case 'FINISH':
        final phrases = [
          "🏁 CHECKERED FLAG! The race is over! What a grand prix! The podium: $desc",
          "🏁 And that's the checkered flag! An incredible race comes to an end! Podium finishers: $desc",
          "🏁 The flag is waved! What a spectacle! Your podium today: $desc",
        ];
        return phrases[rng.nextInt(phrases.length)];
      case 'FASTEST_LAP':
        final phrases = [
          "⚡ FASTEST LAP! $name of $team sets the benchmark — $desc",
          "⚡ Purple sector! $name goes fastest with $desc What pace!",
          "⚡ NEW FASTEST LAP for $name! $desc The $team car is flying!",
        ];
        return phrases[rng.nextInt(phrases.length)];
      default:
        final phrases = [
          "News from the pit wall — $name: $desc",
          "Interesting development for $name of $team. $desc",
          "The stewards take note — $name: $desc",
        ];
        return phrases[rng.nextInt(phrases.length)];
    }
  }

  Widget _buildCommentaryFeed(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080810),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // Header — broadcast style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.12),
                  const Color(0xFF080810),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'ON AIR',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00BCD4),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.podcasts, color: Color(0xFF00BCD4), size: 14),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'LIVE COMMENTARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF00BCD4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.tv,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 14,
                ),
              ],
            ),
          ),

          // Scan-line overlay + commentary list
          Expanded(
            child: Stack(
              children: [
                // Commentary content
                Builder(
                  builder: (context) {
                    // Filter to important events only
                    final importantEvents = _allEvents.where((evt) {
                      final type = ((evt['type'] as String?) ?? '')
                          .toUpperCase();
                      final driverId = (evt['driverId'] as String?) ?? '';
                      final position = (evt['position'] as num?)?.toInt() ?? 99;

                      // Always show crashes, DNFs, FINISH, and FASTEST_LAP
                      if (type == 'DNF' ||
                          type == 'FINISH' ||
                          type == 'FASTEST_LAP') {
                        return true;
                      }

                      // Always show player team events
                      if (_isPlayerTeam(driverId)) return true;

                      // Show overtakes involving top-3 positions
                      if (type == 'OVERTAKE' && position <= 3) return true;

                      // Show PIT stops in top 5
                      if (type == 'PIT' && position <= 5) return true;

                      return false;
                    }).toList();

                    if (importantEvents.isEmpty) {
                      return Center(
                        child: Text(
                          _currentLapNumber == 0
                              ? 'Waiting for lights out...'
                              : 'The commentators are standing by...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _commentaryScroll,
                      reverse: false,
                      itemCount: importantEvents.length,
                      itemBuilder: (context, index) {
                        // index 0 = newest
                        final chronologicalIndex =
                            importantEvents.length - 1 - index;
                        final evt = importantEvents[chronologicalIndex];
                        final commentary = _generateCommentary(evt);
                        final lap = (evt['lap'] as num?)?.toInt() ?? 0;
                        final type = (evt['type'] as String?) ?? 'INFO';
                        final isPlayer = _isPlayerTeam(evt['driverId'] ?? '');
                        final isNewest = index == 0;

                        return _CommentaryItem(
                          key: ValueKey(
                            'commentary_${lap}_${evt['driverId']}_${type}_$chronologicalIndex',
                          ),
                          commentary: commentary,
                          lap: lap,
                          type: type,
                          isPlayer: isPlayer,
                          isNewest: isNewest,
                        );
                      },
                    );
                  },
                ),

                // Subtle scan-line overlay effect
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _ScanLinePainter()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context,
    String title,
    IconData icon,
    String message,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single commentary item. The newest item gets a typewriter text animation
/// and a highlighted background. Older items render statically.
class _CommentaryItem extends StatefulWidget {
  final String commentary;
  final int lap;
  final String type;
  final bool isPlayer;
  final bool isNewest;

  const _CommentaryItem({
    super.key,
    required this.commentary,
    required this.lap,
    required this.type,
    required this.isPlayer,
    this.isNewest = false,
  });

  @override
  State<_CommentaryItem> createState() => _CommentaryItemState();
}

class _CommentaryItemState extends State<_CommentaryItem> {
  int _visibleChars = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isNewest) {
      _visibleChars = 0;
      _startTypewriter();
    } else {
      _visibleChars = widget.commentary.length;
    }
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 18), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_visibleChars >= widget.commentary.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleChars += 2; // 2 chars at a time for speed
        if (_visibleChars > widget.commentary.length) {
          _visibleChars = widget.commentary.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type.toUpperCase();
    final displayText = widget.commentary.substring(0, _visibleChars);
    final isTyping =
        widget.isNewest && _visibleChars < widget.commentary.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isPlayer
                ? const Color(0xFFFFD54F).withValues(alpha: 0.1)
                : const Color(0xFF00BCD4).withValues(alpha: 0.06),
          ),
        ),
        color: widget.isNewest
            ? (widget.isPlayer
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.1)
                  : const Color(0xFF00BCD4).withValues(alpha: 0.08))
            : (widget.isPlayer
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.04)
                  : Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lap indicator
          Column(
            children: [
              Text(
                'L${widget.lap}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: widget.isPlayer
                      ? const Color(0xFFFFD54F).withValues(alpha: 0.6)
                      : const Color(0xFF00BCD4).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                type == 'DNF'
                    ? Icons.warning_amber_rounded
                    : type == 'PIT'
                    ? Icons.local_gas_station
                    : type == 'OVERTAKE'
                    ? Icons.swap_vert
                    : type == 'FINISH'
                    ? Icons.flag
                    : type == 'FASTEST_LAP'
                    ? Icons.timer
                    : Icons.mic,
                size: 12,
                color: type == 'FASTEST_LAP'
                    ? const Color(0xFFE040FB).withValues(alpha: 0.6)
                    : (widget.isPlayer
                          ? const Color(0xFFFFD54F).withValues(alpha: 0.4)
                          : const Color(0xFF00BCD4).withValues(alpha: 0.3)),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Commentary text with typewriter effect for newest
          Expanded(
            child: RichText(
              text: TextSpan(
                text: displayText,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: widget.isPlayer
                      ? const Color(
                          0xFFFFD54F,
                        ).withValues(alpha: widget.isNewest ? 1.0 : 0.7)
                      : (widget.isNewest
                            ? Colors.white.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.5)),
                  height: 1.4,
                ),
                children: [
                  if (isTyping)
                    TextSpan(
                      text: '▌',
                      style: TextStyle(
                        color: widget.isPlayer
                            ? const Color(0xFFFFD54F).withValues(alpha: 0.7)
                            : const Color(0xFF00BCD4).withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws subtle horizontal scan lines to simulate a vintage TV/CRT effect
/// on the commentary feed.
class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
