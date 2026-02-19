import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';
import '../../services/driver_assignment_service.dart';
import '../../services/race_service.dart';
import '../../services/season_service.dart';
import '../../services/driver_development_service.dart';
import '../../services/circuit_service.dart';
import '../../services/time_service.dart';
import '../../services/driver_portrait_service.dart';
import '../../services/universe_service.dart';
import '../../services/team_assignment_service.dart';
import '../../utils/app_constants.dart';
import 'package:ftg_racing_manager/l10n/app_localizations.dart';

class GarageScreen extends StatefulWidget {
  final String teamId;

  /// Circuit id for setup/profile (e.g. 'interlagos').
  final String? circuitId;
  final bool isEmbed;

  const GarageScreen({
    super.key,
    required this.teamId,
    this.circuitId,
    this.isEmbed = false,
  });

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen>
    with TickerProviderStateMixin {
  // State
  bool _isLoading = false;
  CircuitProfile? _circuit;
  List<Driver> _drivers = [];
  String? _selectedDriverId;
  Map<String, int> _driverLaps = {};
  final Map<String, TyreCompound?> _driverLastTyreFeedbackCompound = {};

  // Per-driver setups: driverId -> CarSetup
  final Map<String, CarSetup> _driverPracticeSetups = {};
  final Map<String, CarSetup> _driverQualifyingSetups = {};
  final Map<String, CarSetup> _driverRaceSetups = {};

  final Map<String, bool> _qualifyingSetupsSubmitted = {};
  final Map<String, bool> _raceSetupsSubmitted = {};

  // Per-driver lap history: driverId -> [{lapTime, confidence, feedback}]
  final Map<String, List<Map<String, dynamic>>> _driverLapHistory = {};

  PracticeRunResult? _lastResult;
  double? _fastestGlobalLap;
  String? _fastestGlobalDriverId;
  final Map<String, double> _bestPersonalLaps = {};
  String? _pitBoardMessage;
  final List<Map<String, dynamic>> _feedbackHistory = [];
  int _lapsToRun = 5;
  RaceEvent? _currentEvent;

  // ─── QUALIFYING STATE ───
  static const int kMaxQualifyingAttempts = 6;
  // Per-driver qualifying attempts: driverId -> count
  final Map<String, int> _qualifyingAttempts = {};
  // Per-driver best qualifying time: driverId -> best lap time
  final Map<String, double> _qualifyingBestTimes = {};
  // Per-driver qualifying laps: driverId -> total laps
  final Map<String, int> _qualifyingLaps = {};
  // Per-driver best qualifying compound: driverId -> compound
  final Map<String, TyreCompound> _qualifyingBestCompounds = {};
  // Per-driver last qualifying lap time
  final Map<String, double> _qualifyingLastLaps = {};
  // Whether the driver has started qualifying (Parc Fermé triggers after first attempt)
  final Map<String, bool> _qualifyingParcFerme = {};
  // Full qualifying results table: [{driverId, driverName, teamName, teamId, bestTime, laps}]
  List<Map<String, dynamic>> _qualifyingResultsTable = [];
  // Division teams for the qualifying results
  List<Team> _divisionTeams = [];
  List<Driver> _divisionDrivers = [];

  // Setup tab: 0=Practice, 1=Qualifying, 2=Race
  late TabController _tabController;
  AnimationController? _blinkingController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _blinkingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _blinkingController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Drivers first so we can map setups
      _drivers = await DriverAssignmentService().getDriversByTeam(
        widget.teamId,
      );

      if (_drivers.isNotEmpty) {
        _selectedDriverId = _drivers.first.id;
        for (var driver in _drivers) {
          _driverLaps.putIfAbsent(driver.id, () => 0);
          _driverPracticeSetups.putIfAbsent(driver.id, () => CarSetup());
          _driverQualifyingSetups.putIfAbsent(driver.id, () => CarSetup());
          _driverRaceSetups.putIfAbsent(driver.id, () => CarSetup());
          _driverLapHistory.putIfAbsent(driver.id, () => []);
          _qualifyingSetupsSubmitted.putIfAbsent(driver.id, () => false);
          _raceSetupsSubmitted.putIfAbsent(driver.id, () => false);
        }
      }

      // 2. Fetch Team
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (teamDoc.exists) {
        final team = Team.fromMap(teamDoc.data()!);
        // Load practice laps
        if (team.weekStatus['practiceLaps'] != null) {
          _driverLaps = Map<String, int>.from(team.weekStatus['practiceLaps']);
        }

        // Load qualifying and race setups from weekStatus if they exist (backward compatibility or initial load)
        final driverSetupsData = team.weekStatus['driverSetups'] != null
            ? Map<String, dynamic>.from(team.weekStatus['driverSetups'])
            : null;

        if (driverSetupsData != null) {
          driverSetupsData.forEach((dId, data) {
            final driverData = Map<String, dynamic>.from(data);
            if (driverData['qualifying'] != null) {
              _driverQualifyingSetups[dId] = CarSetup.fromMap(
                Map<String, dynamic>.from(driverData['qualifying']),
              );
              _qualifyingSetupsSubmitted[dId] =
                  driverData['qualifyingSubmitted'] == true;

              // Load attempts, laps, best times, parc ferme
              if (driverData['qualifyingAttempts'] != null) {
                _qualifyingAttempts[dId] =
                    driverData['qualifyingAttempts'] as int;
              }
              if (driverData['qualifyingLaps'] != null) {
                _qualifyingLaps[dId] = driverData['qualifyingLaps'] as int;
              }
              if (driverData['qualifyingBestTime'] != null) {
                _qualifyingBestTimes[dId] =
                    (driverData['qualifyingBestTime'] as num).toDouble();
              }
              if (driverData['qualifyingParcFerme'] != null) {
                _qualifyingParcFerme[dId] =
                    driverData['qualifyingParcFerme'] == true;
              }
              if (driverData['qualifyingBestCompound'] != null) {
                _qualifyingBestCompounds[dId] = TyreCompound.values.firstWhere(
                  (c) => c.name == driverData['qualifyingBestCompound'],
                  orElse: () => TyreCompound.soft,
                );
              }
            }
            if (driverData['race'] != null) {
              _driverRaceSetups[dId] = CarSetup.fromMap(
                Map<String, dynamic>.from(driverData['race']),
              );
              _raceSetupsSubmitted[dId] = driverData['raceSubmitted'] == true;
            }
          });
        }
      }

      // 3. Fetch Season & Race Event for weather
      final season = await SeasonService().getActiveSeason();
      if (season != null) {
        final currentRace = SeasonService().getCurrentRace(season);
        _currentEvent = currentRace?.event;
      }

      // 4. Fetch Circuit
      _circuit = CircuitService().getCircuitProfile(
        widget.circuitId ?? 'interlagos',
      );

      // 5. Load practice results per driver
      await _loadPracticeResults();

      // 6. Load division teams/drivers for qualifying results
      await _loadDivisionData();
    } catch (e) {
      debugPrint("Error loading garage data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPracticeResults() async {
    try {
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('practice_results')
          .orderBy('timestamp', descending: true)
          .get();

      // Track last setup loaded per driver
      Set<String> setupLoaded = {};

      for (var doc in resultsSnapshot.docs) {
        final data = doc.data();
        final driverId = data['driverId'] as String;

        // Load setup from most recent run for each driver if not already loaded from team doc
        if (!setupLoaded.contains(driverId) && data['setupUsed'] != null) {
          final setup = CarSetup.fromMap(
            Map<String, dynamic>.from(data['setupUsed']),
          );
          _driverPracticeSetups[driverId] = setup;
          _driverLastTyreFeedbackCompound[driverId] = setup.tyreCompound;
          setupLoaded.add(driverId);
        }

        // Build lap history
        _driverLapHistory.putIfAbsent(driverId, () => []);
        final lapTime = (data['lapTime'] as num).toDouble();
        _driverLapHistory[driverId]!.add({
          'lapTime': lapTime,
          'confidence': data['setupConfidence'] ?? 0.0,
          'feedback': data['feedback'] ?? '',
          'setup': data['setupUsed'] != null
              ? CarSetup.fromMap(Map<String, dynamic>.from(data['setupUsed']))
              : null,
        });

        // Track PB and Global Fastest
        if (_bestPersonalLaps[driverId] == null ||
            lapTime < _bestPersonalLaps[driverId]!) {
          _bestPersonalLaps[driverId] = lapTime;
        }
        if (_fastestGlobalLap == null || lapTime < _fastestGlobalLap!) {
          _fastestGlobalLap = lapTime;
          _fastestGlobalDriverId = driverId;
        }

        // Add to feedback history
        final feedbackMsg = data['feedback'] as String?;
        // Also check if we have a list
        final feedbacks = data['feedbackList'] != null
            ? List<String>.from(data['feedbackList'])
            : (feedbackMsg != null && feedbackMsg.isNotEmpty
                  ? [feedbackMsg]
                  : []);

        if (feedbacks.isNotEmpty) {
          final driverName =
              _drivers
                  .where((d) => d.id == driverId)
                  .map((d) => d.name)
                  .firstOrNull ??
              'Driver';

          final confidence =
              (data['setupConfidence'] as num?)?.toDouble() ?? 0.0;

          final sessionId =
              data['sessionId'] as String? ??
              data['timestamp']?.toDate().toIso8601String() ??
              DateTime.now().millisecondsSinceEpoch.toString();

          for (final msg in feedbacks) {
            _feedbackHistory.add({
              'sessionId': sessionId,
              'driverId': driverId,
              'driverName': driverName,
              'message': msg,
              'color': _getConfidenceColor(confidence),
              'timestamp': data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
              'confidence': confidence,
              'bestLapInSeries': (data['bestLapInSeries'] as num?)?.toDouble(),
            });
          }
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading practice results: $e");
    }
  }

  void _onDriverChanged(String? newDriverId) {
    if (newDriverId == null || newDriverId == _selectedDriverId) return;
    setState(() {
      _selectedDriverId = newDriverId;
      _lastResult = null; // Clear last result when switching
    });
  }

  CarSetup get _currentDriverPracticeSetup {
    return _driverPracticeSetups[_selectedDriverId] ?? CarSetup();
  }

  CarSetup get _currentDriverQualifyingSetup {
    return _driverQualifyingSetups[_selectedDriverId] ?? CarSetup();
  }

  CarSetup get _currentDriverRaceSetup {
    return _driverRaceSetups[_selectedDriverId] ?? CarSetup();
  }

  void _updateCurrentDriverSetup(CarSetup setup, {int tabIndex = 0}) {
    if (_selectedDriverId != null) {
      if (tabIndex == 0) _driverPracticeSetups[_selectedDriverId!] = setup;
      if (tabIndex == 1) _driverQualifyingSetups[_selectedDriverId!] = setup;
      if (tabIndex == 2) _driverRaceSetups[_selectedDriverId!] = setup;
    }
  }

  Future<void> _runPracticeSeries() async {
    if (_circuit == null || _selectedDriverId == null) return;

    final currentLaps = _driverLaps[_selectedDriverId] ?? 0;
    if (currentLaps + _lapsToRun > kMaxPracticeLapsPerDriver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Driver reached max practice laps ($kMaxPracticeLapsPerDriver). Reducing series to ${kMaxPracticeLapsPerDriver - currentLaps} laps.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      if (kMaxPracticeLapsPerDriver - currentLaps <= 0) return;
    }

    // Cost Check ($3k per run)
    const int kPracticeRunCost = 3000;
    // We need to fetch team budget first, but it's okay to check in transaction or just deduct.
    // Assuming team has budget or allow negative for now, but better check.
    // For simplicity, we just deduct.

    final int actualLaps =
        (currentLaps + _lapsToRun > kMaxPracticeLapsPerDriver)
        ? kMaxPracticeLapsPerDriver - currentLaps
        : _lapsToRun;

    setState(() => _isLoading = true);
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;

    try {
      final l10n = AppLocalizations.of(context);
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (!teamDoc.exists) throw Exception("Team not found");
      final team = Team.fromMap(teamDoc.data()!);
      final driver = _drivers.firstWhere((d) => d.id == _selectedDriverId);
      final setup = _currentDriverPracticeSetup;

      // --- Pit Board Animation START ---
      setState(() => _pitBoardMessage = l10n.pitBoardLeftPits(driver.name));
      await Future.delayed(const Duration(milliseconds: 1200));
      setState(
        () => _pitBoardMessage = l10n.pitBoardStartingPractice(driver.name),
      );
      await Future.delayed(const Duration(milliseconds: 1000));

      PracticeRunResult? lastLapResult;
      double bestLapInSeries = 9999.0; // Track best lap for this series

      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      for (int i = 0; i < actualLaps; i++) {
        setState(
          () => _pitBoardMessage = l10n.pitBoardOnLap(
            driver.name,
            i + 1,
            actualLaps,
          ),
        );

        final result = RaceService().simulatePracticeRun(
          circuit: _circuit!,
          team: team,
          driver: driver,
          setup: setup,
        );

        // Simulate lap time delay
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;

        lastLapResult = result;

        // Check for records in real-time to alert on Pit Board
        bool isNewTeamRecord =
            (_fastestGlobalLap == null || result.lapTime < _fastestGlobalLap!);
        bool isNewPB =
            (_bestPersonalLaps[_selectedDriverId] == null ||
            result.lapTime < _bestPersonalLaps[_selectedDriverId]!);

        if (isNewTeamRecord) {
          _fastestGlobalLap = result.lapTime;
          _fastestGlobalDriverId = _selectedDriverId;
          setState(
            () => _pitBoardMessage = l10n.pitBoardNewTeamRecord(
              driver.name,
              _formatLapTime(result.lapTime),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1500));
        } else if (isNewPB) {
          _bestPersonalLaps[_selectedDriverId!] = result.lapTime;
          setState(
            () => _pitBoardMessage = l10n.pitBoardNewPB(
              driver.name,
              _formatLapTime(result.lapTime),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1500));
        }

        // Add to lap history
        _driverLapHistory.putIfAbsent(_selectedDriverId!, () => []);
        _driverLapHistory[_selectedDriverId!]!.insert(0, {
          'lapTime': result.lapTime,
          'confidence': result.setupConfidence,
          'feedback': result.driverFeedback.isNotEmpty
              ? result.driverFeedback.first
              : '',
          'setup': setup.copyWith(),
          'seriesIndex': i + 1,
          'totalInSeries': actualLaps,
        });

        final List<String> feedbackToStore = List.from(result.driverFeedback);
        final currentTyre = setup.tyreCompound;
        if (i == actualLaps - 1 &&
            _driverLastTyreFeedbackCompound[_selectedDriverId] != currentTyre) {
          feedbackToStore.addAll(result.tyreFeedback);
        }

        // Update best lap in series
        if (result.lapTime < bestLapInSeries) {
          bestLapInSeries = result.lapTime;
        }

        // Save practice result per driver
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('practice_results')
            .add({
              'driverId': _selectedDriverId,
              'lapTime': result.lapTime,
              'setupUsed': setup.toMap(),
              'feedbackList': feedbackToStore, // Combined list
              'timestamp': FieldValue.serverTimestamp(),
              'setupConfidence': result.setupConfidence,
              'isEndSeries': i == actualLaps - 1,
              'sessionId': sessionId, // Add session ID
              'bestLapInSeries': bestLapInSeries, // Add best lap for the series
            });
      }

      if (lastLapResult != null) {
        // Determine feedback to show in UI
        final List<String> feedbackToShow = List.from(
          lastLapResult.driverFeedback,
        );
        final currentTyre = setup.tyreCompound;
        if (_driverLastTyreFeedbackCompound[_selectedDriverId] != currentTyre) {
          feedbackToShow.addAll(lastLapResult.tyreFeedback);
          _driverLastTyreFeedbackCompound[_selectedDriverId!] = currentTyre;
        }
        if (feedbackToShow.isEmpty) {
          feedbackToShow.add(
            "Series completed. Setup confidence: ${(lastLapResult.setupConfidence * 100).toStringAsFixed(0)}%",
          );
        }

        final commsSkill = driver.stats['consistency'] ?? 50;
        for (var msg in feedbackToShow) {
          Color msgColor = defaultTextColor;
          final lowerMsg = msg.toLowerCase();

          if (lowerMsg.contains('perfect') ||
              lowerMsg.contains('spot on') ||
              lowerMsg.contains('excellent')) {
            msgColor = const Color(0xFF00C853); // Changed to Green as requested
          } else if (lowerMsg.contains('tyre') ||
              lowerMsg.contains('grip') ||
              lowerMsg.contains('soft') ||
              lowerMsg.contains('medium') ||
              lowerMsg.contains('hard') ||
              lowerMsg.contains('wet') ||
              lowerMsg.contains('degradation')) {
            msgColor = Colors.blueAccent; // Distinct color for tyre feedback
          } else if (commsSkill > 50) {
            if (lowerMsg.contains('increase') ||
                lowerMsg.contains('reduce') ||
                lowerMsg.contains('too') ||
                lowerMsg.contains('more') ||
                lowerMsg.contains('less')) {
              msgColor = Colors.red;
            } else if (lowerMsg.contains('good') ||
                lowerMsg.contains('fine') ||
                lowerMsg.contains('ok')) {
              msgColor = Colors.green;
            }
          }

          _feedbackHistory.insert(0, {
            'sessionId': sessionId,
            'driverName': driver.name,
            'driverId': driver.id,
            'message': msg,
            'color': msgColor,
            'timestamp': DateTime.now(),
            'bestLapInSeries': bestLapInSeries,
          });
        }

        // Update Laps
        _driverLaps[_selectedDriverId!] = currentLaps + actualLaps;

        // Calculate average lap time for development
        double totalLapTime = 0;
        final history = _driverLapHistory[_selectedDriverId!]!;
        for (int i = 0; i < actualLaps; i++) {
          totalLapTime += history[i]['lapTime'] as double;
        }
        double avgTime = totalLapTime / actualLaps;

        // ─── Apply Driver Development & Fitness ───
        final devSummary = await DriverDevelopmentService()
            .applyPracticeDevelopment(
              driver: driver,
              setupConfidence: lastLapResult.setupConfidence,
              averageLapTime: avgTime,
              lapsCompleted: actualLaps,
              sendNotification: false, // Don't send second notification
            );

        // Save to team weekStatus
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .update({
              'weekStatus.practiceLaps': _driverLaps,
              'weekStatus.driverSetups.$_selectedDriverId.practice': setup
                  .toMap(),
              'weekStatus.driverSetups.$_selectedDriverId.practiceConfidence':
                  lastLapResult.setupConfidence,
              'budget': FieldValue.increment(-kPracticeRunCost),
            });

        // Record financial movement for practice
        final transRef = FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('transactions')
            .doc();
        final trans = Transaction(
          id: transRef.id,
          description:
              "Practice (${_currentEvent?.trackName ?? 'Unknown'}): ${driver.name}",
          amount: -kPracticeRunCost,
          date: DateTime.now(),
          type: 'PRACTICE',
        );
        await transRef.set(trans.toMap());
        // RE-FETCH DRIVERS to show REAL-TIME stat changes in the UI
        final updatedDrivers = await DriverAssignmentService().getDriversByTeam(
          widget.teamId,
        );

        // Add COMPACT Notification for Practice Run
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('notifications')
            .add({
              'title': 'Practice Run: ${driver.name}',
              'message':
                  '$actualLaps laps completed (Avg: ${_formatLapTime(avgTime)}). '
                  'Session cost: \$${kPracticeRunCost / 1000}K. '
                  '\n$devSummary',
              'type': 'TEAM',
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
            });

        if (mounted) {
          setState(() {
            _drivers = updatedDrivers; // Real-time update
            _lastResult = lastLapResult;
          });
        }

        // --- Pit Board Animation END ---
        setState(
          () => _pitBoardMessage = l10n.pitBoardReturningPits(driver.name),
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        setState(() => _pitBoardMessage = l10n.pitBoardInGarage(driver.name));
        await Future.delayed(const Duration(milliseconds: 1000));
        setState(() => _pitBoardMessage = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveQualifyingSetupDraft() async {
    if (_selectedDriverId == null) return;
    setState(() => _isLoading = true);
    try {
      // Copy practice setup to qualifying setup for the selected driver
      final practiceSetup = _currentDriverPracticeSetup;
      final qualSetup = practiceSetup.copyWith();
      _driverQualifyingSetups[_selectedDriverId!] = qualSetup;

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.driverSetups.$_selectedDriverId.qualifying': qualSetup
                .toMap(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Qualifying setup saved (Draft)"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRaceSetupDraft() async {
    if (_selectedDriverId == null) return;
    setState(() => _isLoading = true);
    try {
      // Copy practice setup to race setup for the selected driver
      final practiceSetup = _currentDriverPracticeSetup;
      final raceSetup = practiceSetup.copyWith();
      _driverRaceSetups[_selectedDriverId!] = raceSetup;

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.driverSetups.$_selectedDriverId.race': raceSetup
                .toMap(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Race setup saved (Draft)"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Load all teams and drivers from the player's division
  Future<void> _loadDivisionData() async {
    try {
      final universe = await UniverseService().getUniverse();
      if (universe == null) return;

      // Find the division containing this team
      for (final league in universe.getAllLeagues()) {
        for (final division in league.divisions) {
          if (division.teamIds.contains(widget.teamId)) {
            _divisionTeams = await TeamAssignmentService().getTeamsByDivision(
              division.id,
            );
            _divisionDrivers = await DriverAssignmentService()
                .getDriversByDivision(division.id);
            _buildInitialQualifyingTable();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading division data: $e");
    }
  }

  /// Build the initial qualifying results table with all drivers showing their recorded times
  void _buildInitialQualifyingTable() {
    _qualifyingResultsTable = _divisionDrivers.map((driver) {
      final team = _divisionTeams.firstWhere(
        (t) => t.id == driver.teamId,
        orElse: () => Team(
          id: '',
          name: 'Unknown',
          isBot: true,
          budget: 0,
          points: 0,
          carStats: {},
          weekStatus: {},
        ),
      );

      double bestTime = 0.0;
      int laps = 0;

      TyreCompound? bestCompound;

      if (team.id == widget.teamId) {
        // Use player's loaded state
        bestTime = _qualifyingBestTimes[driver.id] ?? 0.0;
        laps = _qualifyingLaps[driver.id] ?? 0;
        bestCompound = _qualifyingBestCompounds[driver.id];
      } else {
        // Use bot data from their weekStatus
        final driverSetup = team.weekStatus['driverSetups']?[driver.id];
        if (driverSetup != null) {
          bestTime =
              (driverSetup['qualifyingBestTime'] as num?)?.toDouble() ?? 0.0;
          laps = (driverSetup['qualifyingLaps'] as num?)?.toInt() ?? 0;
          if (driverSetup['qualifyingBestCompound'] != null) {
            bestCompound = TyreCompound.values.firstWhere(
              (c) => c.name == driverSetup['qualifyingBestCompound'],
              orElse: () => TyreCompound.soft,
            );
          }
        }
      }

      return {
        'driverId': driver.id,
        'driverName': driver.name,
        'teamName': team.name,
        'teamId': team.id,
        'bestTime': bestTime,
        'laps': laps,
        'bestCompound': bestCompound,
        'isPlayerTeam': team.id == widget.teamId,
      };
    }).toList();

    _sortQualifyingResults();
  }

  /// Run a qualifying attempt for the selected driver
  Future<void> _runQualifyingAttempt() async {
    if (_selectedDriverId == null || _circuit == null) return;

    final driverId = _selectedDriverId!;
    final currentAttempts = _qualifyingAttempts[driverId] ?? 0;

    if (currentAttempts >= kMaxQualifyingAttempts) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Maximum qualifying attempts (6) reached for this driver.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _pitBoardMessage = "OUT LAP...";
    });

    try {
      final driver = _drivers.firstWhere((d) => d.id == driverId);
      final setup = _currentDriverQualifyingSetup;
      final team = _divisionTeams.firstWhere(
        (t) => t.id == widget.teamId,
        orElse: () => Team(
          id: widget.teamId,
          name: 'Unknown',
          isBot: false,
          budget: 0,
          points: 0,
          carStats: {},
          weekStatus: {},
        ),
      );

      final startLaps = _qualifyingLaps[driverId] ?? 0;

      // --- SIMULATION SEQUENCE ---
      // 1. Out lap
      setState(() => _qualifyingLaps[driverId] = startLaps + 1);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      // 2. Flying Lap
      setState(() => _pitBoardMessage = "PUSHING...");
      final result = RaceService().simulatePracticeRun(
        circuit: _circuit!,
        team: team,
        driver: driver,
        setup: setup,
      );
      setState(() => _qualifyingLaps[driverId] = startLaps + 2);
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      // 3. In Lap
      setState(() {
        _pitBoardMessage = "IN LAP...";
        _qualifyingLaps[driverId] = startLaps + 3;
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      final newAttempts = currentAttempts + 1;
      _qualifyingAttempts[driverId] = newAttempts;
      final totalLaps = _qualifyingLaps[driverId]!;

      // Activate Parc Fermé after first attempt
      _qualifyingParcFerme[driverId] = true;

      // Track best time
      final previousBest = _qualifyingBestTimes[driverId] ?? 0.0;
      if (previousBest == 0.0 || result.lapTime < previousBest) {
        _qualifyingBestTimes[driverId] = result.lapTime;
        _qualifyingBestCompounds[driverId] = setup.tyreCompound;
      }
      final bestTime = _qualifyingBestTimes[driverId]!;
      // Use current compound as fallback if previous best compound wasn't recorded
      final bestCompound =
          _qualifyingBestCompounds[driverId] ?? setup.tyreCompound;
      // Ensure we have it stored for next time
      _qualifyingBestCompounds[driverId] = bestCompound;
      _qualifyingLastLaps[driverId] = result.lapTime;

      // Update qualifying results table for this driver
      final tableIdx = _qualifyingResultsTable.indexWhere(
        (r) => r['driverId'] == driverId,
      );
      if (tableIdx >= 0) {
        _qualifyingResultsTable[tableIdx]['bestTime'] = bestTime;
        _qualifyingResultsTable[tableIdx]['laps'] = totalLaps;
        _qualifyingResultsTable[tableIdx]['bestCompound'] = bestCompound;
      }

      // Sort the table: drivers with times first (by time ASC), then no-time drivers
      _sortQualifyingResults();

      // Save qualifying data to Firestore
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.driverSetups.$driverId.qualifying': setup.toMap(),
            'weekStatus.driverSetups.$driverId.qualifyingAttempts': newAttempts,
            'weekStatus.driverSetups.$driverId.qualifyingLaps': totalLaps,
            'weekStatus.driverSetups.$driverId.qualifyingBestTime': bestTime,
            'weekStatus.driverSetups.$driverId.qualifyingBestCompound':
                bestCompound.name,
            'weekStatus.driverSetups.$driverId.qualifyingParcFerme': true,
          });

      // --- PERSIST DRIVER STATS (Fitness, etc.) ---
      await DriverDevelopmentService().applyQualifyingPersistence(
        driver: driver,
      );

      // RE-FETCH DRIVERS to show REAL-TIME stat changes (fitness drop) in the UI
      final updatedDrivers = await DriverAssignmentService().getDriversByTeam(
        widget.teamId,
      );

      if (mounted) {
        setState(() {
          _drivers = updatedDrivers;
          _pitBoardMessage = null;
        });
      }

      if (mounted) {
        final isImproved = result.lapTime <= bestTime;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isImproved
                  ? "✓ ${_formatLapTime(result.lapTime)} — New best! (Attempt $newAttempts/$kMaxQualifyingAttempts)"
                  : "⏱ ${_formatLapTime(result.lapTime)} — No improvement (Attempt $newAttempts/$kMaxQualifyingAttempts)",
            ),
            backgroundColor: isImproved ? Colors.green : Colors.blueGrey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sortQualifyingResults() {
    _qualifyingResultsTable.sort((a, b) {
      final timeA = a['bestTime'] as double;
      final timeB = b['bestTime'] as double;
      // Drivers with no time (0.0) go to the bottom
      if (timeA == 0.0 && timeB == 0.0) return 0;
      if (timeA == 0.0) return 1;
      if (timeB == 0.0) return -1;
      return timeA.compareTo(timeB);
    });
  }

  Future<void> _saveRaceSetup() async {
    if (_selectedDriverId == null) return;
    setState(() => _isLoading = true);
    try {
      final setup = _currentDriverRaceSetup;

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.driverSetups.$_selectedDriverId.race': setup.toMap(),
            'weekStatus.driverSetups.$_selectedDriverId.raceSubmitted': true,
            'weekStatus.driverSetups.$_selectedDriverId.raceSubmittedAt':
                FieldValue.serverTimestamp(),
          });

      setState(() => _raceSetupsSubmitted[_selectedDriverId!] = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Race setup submitted!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _circuit == null) {
      final loadingIndicator = Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
      if (widget.isEmbed) return loadingIndicator;
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: loadingIndicator,
      );
    }

    final timeService = TimeService();
    final isPaddockOpen = timeService.currentStatus == RaceWeekStatus.practice;

    final content = Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "PRACTICE"),
            Tab(text: "QUALIFYING"),
            Tab(text: "RACE"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPracticeTab(theme, isPaddockOpen),
              _buildQualifyingTab(theme, isPaddockOpen),
              _buildRaceTab(theme, isPaddockOpen),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbed) {
      return content;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _circuit?.name ?? 'Paddock',
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (!isPaddockOpen)
            Container(
              margin: const EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "PARC FERMÉ",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: content,
    );
  }

  // ─── PRACTICE TAB ───

  Widget _buildPracticeTab(ThemeData theme, bool isPaddockOpen) {
    return Row(
      children: [
        // LEFT: Setup + Controls
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Driver selector
              _buildDriverSelector(theme),
              const SizedBox(height: 12),

              // Circuit intel (compact)
              if (_circuit != null && _circuit!.characteristics.isNotEmpty)
                _buildCircuitIntel(theme),
              const SizedBox(height: 12),

              // Setup sliders (compact)
              _buildSetupCard(
                theme,
                "PRACTICE SETUP",
                _currentDriverPracticeSetup,
                isPaddockOpen,
                (field, val) {
                  setState(() {
                    final s = _currentDriverPracticeSetup;
                    switch (field) {
                      case 'frontWing':
                        s.frontWing = val;
                      case 'rearWing':
                        s.rearWing = val;
                      case 'suspension':
                        s.suspension = val;
                      case 'gearRatio':
                        s.gearRatio = val;
                    }
                    _updateCurrentDriverSetup(s, tabIndex: 0);
                  });
                },
                (compound) {
                  setState(() {
                    final s = _currentDriverPracticeSetup;
                    s.tyreCompound = compound;
                    _updateCurrentDriverSetup(s, tabIndex: 0);
                  });
                },
                null,
                onStyleChanged: (style) {
                  setState(() {
                    final s = _currentDriverPracticeSetup;
                    s.qualifyingStyle = style;
                    _updateCurrentDriverSetup(s, tabIndex: 0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // RUN PRACTICE SERIES button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _lapsToRun,
                          items: [1, 2, 3, 5, 8, 10, 15].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                "$value Laps",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: isPaddockOpen
                              ? (val) {
                                  if (val != null)
                                    setState(() => _lapsToRun = val);
                                }
                              : null,
                          dropdownColor: theme.cardTheme.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (isPaddockOpen && !_isLoading)
                          ? _runPracticeSeries
                          : null,
                      icon: isPaddockOpen
                          ? const Icon(Icons.speed, size: 18)
                          : const Icon(Icons.lock, size: 18),
                      label: Text(isPaddockOpen ? "START SERIES" : "LOCKED"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: isPaddockOpen
                            ? theme.primaryColor
                            : Colors.grey[400],
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // SAVE QUALIFYING SETUP button SECOND
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (isPaddockOpen && !_isLoading)
                      ? _saveQualifyingSetupDraft
                      : null,
                  icon: const Icon(Icons.save_as_outlined, size: 18),
                  label: const Text("COPY TO QUALIFYING SETUP"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // SAVE RACE SETUP button THIRD
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (isPaddockOpen && !_isLoading)
                      ? _saveRaceSetupDraft
                      : null,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text("COPY TO RACE SETUP"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ),

        // RIGHT: Telemetry + Feedback
        Expanded(
          flex: 5,
          child: Column(
            children: [
              // Last Lap Card
              _buildLastLapCard(theme),
              const SizedBox(height: 4),
              // Lap History Table
              _buildLapHistoryCard(theme),
              const SizedBox(height: 4),
              // Pit Board
              _buildPitBoard(theme),
              const SizedBox(height: 4),
              // Driver Feedback
              Expanded(child: _buildFeedbackCard(theme)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── QUALIFYING TAB ───

  Widget _buildQualifyingTab(ThemeData theme, bool isPaddockOpen) {
    final driverId = _selectedDriverId;
    final isParcFerme = _qualifyingParcFerme[driverId] == true;
    final attempts = _qualifyingAttempts[driverId] ?? 0;
    final hasAttemptsLeft = attempts < kMaxQualifyingAttempts;

    return Row(
      children: [
        // LEFT: Setup + Controls
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Driver selector
              _buildDriverSelector(theme),
              const SizedBox(height: 12),

              if (driverId == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("Select a driver to configure setup"),
                  ),
                )
              else ...[
                // Info / Parc Fermé card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isParcFerme
                        ? Colors.orange.withOpacity(0.08)
                        : const Color(0xFFFFB800).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isParcFerme
                          ? Colors.orange.withOpacity(0.4)
                          : const Color(0xFFFFB800).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isParcFerme ? Icons.lock_outline : Icons.info_outline,
                        color: isParcFerme
                            ? Colors.orange
                            : const Color(0xFFFFB800),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isParcFerme
                              ? "PARC FERMÉ: Only front wing and tyres can be changed. "
                                    "Attempts: $attempts/$kMaxQualifyingAttempts"
                              : "Configure your qualifying setup and run attempts to set the best lap time. "
                                    "You have $kMaxQualifyingAttempts attempts per driver.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Best time display
                if ((_qualifyingBestTimes[driverId] ?? 0.0) > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.15),
                          Colors.green.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "BEST: ${_formatLapTime(_qualifyingBestTimes[driverId]!)}",
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "$attempts/$kMaxQualifyingAttempts ATTEMPTS",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Setup card with Parc Fermé restrictions
                _buildQualifyingSetupCard(theme, isParcFerme),
                const SizedBox(height: 12),

                // RUN QUALIFYING ATTEMPT button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (isPaddockOpen && !_isLoading && hasAttemptsLeft)
                        ? _runQualifyingAttempt
                        : null,
                    icon: Icon(
                      hasAttemptsLeft ? Icons.speed : Icons.check_circle,
                      size: 18,
                    ),
                    label: Text(
                      hasAttemptsLeft
                          ? "RUN QUALIFYING ATTEMPT (${attempts + 1}/$kMaxQualifyingAttempts)"
                          : "ALL ATTEMPTS USED",
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: hasAttemptsLeft
                          ? const Color(0xFFFFB800)
                          : Colors.grey[700],
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // RIGHT: Qualifying Results Table
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildQualifyingPitBoard(theme),
              Expanded(child: _buildQualifyingResultsPanel(theme)),
            ],
          ),
        ),
      ],
    );
  }

  /// Interactive Pit Board for live qualifying feeling
  Widget _buildQualifyingPitBoard(ThemeData theme) {
    if (_selectedDriverId == null) return const SizedBox.shrink();

    final driverId = _selectedDriverId!;
    final bestTime = _qualifyingBestTimes[driverId] ?? 0.0;
    final lastTime = _qualifyingLastLaps[driverId] ?? 0.0;
    final laps = _qualifyingLaps[driverId] ?? 0;
    final compound = _currentDriverQualifyingSetup.tyreCompound;

    final status = TimeService().currentStatus;
    final isSessionOpen =
        status == RaceWeekStatus.practice ||
        status == RaceWeekStatus.qualifying;

    // Find position and gap
    int pos = 0;
    double gap = 0.0;
    final idx = _qualifyingResultsTable.indexWhere(
      (r) => r['driverId'] == driverId,
    );
    if (idx >= 0) {
      final row = _qualifyingResultsTable[idx];
      if ((row['bestTime'] as double) > 0) {
        pos = idx + 1;
        final p1Time = _qualifyingResultsTable.first['bestTime'] as double;
        if (p1Time > 0) gap = (row['bestTime'] as double) - p1Time;
      }
    }

    final displayStatus =
        _pitBoardMessage ?? (bestTime > 0 ? "IN BOX" : "READY");

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E1E1E), const Color(0xFF0A0A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titulo de sesión
          Center(
            child: isSessionOpen && _blinkingController != null
                ? AnimatedBuilder(
                    animation: _blinkingController!,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _blinkingController!.value,
                        child: child,
                      );
                    },
                    child: Text(
                      "QUALIFYING SESSION OPEN",
                      style: TextStyle(
                        color: const Color(0xFF00E676),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                  )
                : Text(
                    isSessionOpen
                        ? "QUALIFYING SESSION OPEN"
                        : "QUALIFYING SESSION CLOSED",
                    style: TextStyle(
                      color: isSessionOpen
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF5252),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Pit Board Top Row (Status & Laps)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isLoading
                        ? const Color(0xFFFF5252)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  displayStatus.toUpperCase(),
                  style: TextStyle(
                    color: _isLoading
                        ? const Color(0xFFFF5252)
                        : Colors.white70,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    "LAPS ",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    laps.toString().padLeft(3, '0'),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pit Board Main Info
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Position
                Expanded(
                  child: _buildPitBoardField(
                    "POS",
                    pos > 0 ? pos.toString().padLeft(2, '0') : "--",
                  ),
                ),
                const SizedBox(width: 8),
                // Gap
                Expanded(
                  child: _buildPitBoardField(
                    "GAP",
                    pos > 1
                        ? "+${gap.toStringAsFixed(3)}"
                        : (pos == 1 ? "P1" : "---"),
                  ),
                ),
                const SizedBox(width: 8),
                // Compound
                _buildPitBoardCompound(compound),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Times Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Last Lap
                Expanded(
                  child: _buildPitBoardField(
                    "LAST LAP",
                    lastTime > 0 ? _formatLapTime(lastTime) : "--:---.---",
                  ),
                ),
                const SizedBox(width: 8),
                // Best Time
                Expanded(
                  child: _buildPitBoardField(
                    "BEST LAP",
                    bestTime > 0 ? _formatLapTime(bestTime) : "--:---.---",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitBoardField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitBoardCompound(TyreCompound compound) {
    Color color;
    switch (compound) {
      case TyreCompound.soft:
        color = Colors.red;
        break;
      case TyreCompound.medium:
        color = Colors.yellow;
        break;
      case TyreCompound.hard:
        color = Colors.white;
        break;
      case TyreCompound.wet:
        color = Colors.blue;
        break;
    }

    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              compound.name[0].toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Setup card for qualifying with Parc Fermé restrictions
  Widget _buildQualifyingSetupCard(ThemeData theme, bool isParcFerme) {
    final setup = _currentDriverQualifyingSetup;
    return _buildSetupCard(
      theme,
      "QUALIFYING SETUP",
      setup,
      true, // Always editable in qualifying (restrictions handled per-field)
      (field, val) {
        // Parc Fermé: only front wing can be changed after first attempt
        if (isParcFerme && field != 'frontWing') return;
        setState(() {
          switch (field) {
            case 'frontWing':
              setup.frontWing = val;
            case 'rearWing':
              setup.rearWing = val;
            case 'suspension':
              setup.suspension = val;
            case 'gearRatio':
              setup.gearRatio = val;
          }
          _updateCurrentDriverSetup(setup, tabIndex: 1);
        });
      },
      (compound) {
        setState(() {
          setup.tyreCompound = compound;
          _updateCurrentDriverSetup(setup, tabIndex: 1);
        });
      },
      null, // No pit stops for qualifying
      parcFermeFields: isParcFerme
          ? {'rearWing', 'suspension', 'gearRatio'}
          : null,
      onStyleChanged: (style) {
        setState(() {
          setup.qualifyingStyle = style;
          _updateCurrentDriverSetup(setup, tabIndex: 1);
        });
      },
    );
  }

  /// Qualifying Results panel (right column)
  Widget _buildQualifyingResultsPanel(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFB800),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  "QUALIFYING RESULTS",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.5,
                    color: Color(0xFFFFB800),
                  ),
                ),
                const Spacer(),
                Text(
                  _currentEvent?.trackName ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withOpacity(0.03),
            child: const Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Text("POS", style: _qualyHeaderStyle),
                ),
                Expanded(
                  flex: 4,
                  child: Text("DRIVER", style: _qualyHeaderStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text("CONSTRUCTOR", style: _qualyHeaderStyle),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    "TYRE",
                    style: _qualyHeaderStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "TIME",
                    style: _qualyHeaderStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    "LAPS",
                    style: _qualyHeaderStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          // Table rows
          Expanded(
            child: _qualifyingResultsTable.isEmpty
                ? Center(
                    child: Text(
                      "Loading participants...",
                      style: TextStyle(color: Colors.white.withOpacity(0.3)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _qualifyingResultsTable.length,
                    itemBuilder: (context, index) {
                      final row = _qualifyingResultsTable[index];
                      return _buildQualifyingResultRow(theme, row, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _qualyHeaderStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.0,
    color: Colors.white38,
  );

  Widget _buildQualifyingResultRow(
    ThemeData theme,
    Map<String, dynamic> row,
    int index,
  ) {
    final bestTime = row['bestTime'] as double;
    final laps = row['laps'] as int;
    final isPlayerTeam = row['isPlayerTeam'] == true;
    final hasTime = bestTime > 0;
    final pos = index + 1;

    // Calculate gap to P1
    String gapText = '';
    if (hasTime && index > 0) {
      final p1Time = _qualifyingResultsTable.first['bestTime'] as double;
      if (p1Time > 0) {
        final gap = bestTime - p1Time;
        gapText = '+${gap.toStringAsFixed(3)}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPlayerTeam
            ? theme.colorScheme.secondary.withOpacity(0.08)
            : null,
        border: Border(
          left: isPlayerTeam
              ? BorderSide(color: theme.colorScheme.secondary, width: 3)
              : BorderSide.none,
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              hasTime ? '$pos' : '—',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: pos <= 3 && hasTime
                    ? const Color(0xFFFFB800)
                    : Colors.white.withOpacity(hasTime ? 0.7 : 0.2),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              row['driverName'] ?? '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPlayerTeam ? FontWeight.bold : FontWeight.normal,
                color: isPlayerTeam
                    ? theme.colorScheme.secondary
                    : Colors.white.withOpacity(hasTime ? 0.9 : 0.3),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row['teamName'] ?? '',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(hasTime ? 0.5 : 0.2),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: _buildSmallTyreIcon(row['bestCompound'] as TyreCompound?),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasTime ? _formatLapTime(bestTime) : '00:00.000',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: hasTime
                        ? (index == 0
                              ? const Color(0xFFFFB800)
                              : Colors.white.withOpacity(0.8))
                        : Colors.white.withOpacity(0.15),
                  ),
                  textAlign: TextAlign.right,
                ),
                if (gapText.isNotEmpty)
                  Text(
                    gapText,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.35),
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$laps',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(hasTime ? 0.5 : 0.15),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── RACE TAB ───

  Widget _buildRaceTab(ThemeData theme, bool isPaddockOpen) {
    final isSubmitted = _raceSetupsSubmitted[_selectedDriverId] == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Driver selector
        _buildDriverSelector(theme),
        const SizedBox(height: 16),

        if (_selectedDriverId == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("Select a driver to configure setup"),
            ),
          )
        else ...[
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF5252).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Color(0xFFFF5252)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Configure your race strategy setup. This setup will be used during the race itself. "
                    "Rule: Hard compound tyres MUST be used at least once during the race. "
                    "Consider tyre wear and fuel consumption for the full race distance.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isSubmitted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text(
                    "Race setup submitted ✓",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          _buildSetupCard(
            theme,
            "RACE SETUP",
            _currentDriverRaceSetup,
            isPaddockOpen && !isSubmitted,
            (field, val) {
              setState(() {
                final s = _currentDriverRaceSetup;
                switch (field) {
                  case 'frontWing':
                    s.frontWing = val;
                  case 'rearWing':
                    s.rearWing = val;
                  case 'suspension':
                    s.suspension = val;
                  case 'gearRatio':
                    s.gearRatio = val;
                }
                _updateCurrentDriverSetup(s, tabIndex: 2);
              });
            },
            (compound) {
              setState(() {
                final s = _currentDriverRaceSetup;
                s.tyreCompound = compound;
                _updateCurrentDriverSetup(s, tabIndex: 2);
              });
            },
            (stops) {
              setState(() {
                final s = _currentDriverRaceSetup;
                s.pitStops = stops;
                _updateCurrentDriverSetup(s, tabIndex: 2);
              });
            },
          ),
          const SizedBox(height: 16),

          if (!isSubmitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isPaddockOpen && !_isLoading)
                    ? _saveRaceSetup
                    : null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text("SUBMIT RACE SETUP"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // ─── REUSABLE WIDGETS ───

  Widget _buildDriverSelector(ThemeData theme) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, bottom: 8),
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          final isSelected = driver.id == _selectedDriverId;
          final laps = _driverLaps[driver.id] ?? 0;
          final maxed = laps >= kMaxPracticeLapsPerDriver;

          final portraitUrl =
              driver.portraitUrl ??
              DriverPortraitService().getEffectivePortraitUrl(
                driverId: driver.id,
                countryCode: driver.countryCode,
                gender: driver.gender,
                age: driver.age,
              );

          return GestureDetector(
            onTap: () => _onDriverChanged(driver.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 2 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [const Color(0xFF2A2A2A), const Color(0xFF121212)]
                      : [const Color(0xFF1E1E1E), const Color(0xFF0A0A0A)],
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    // 35% Portrait Area
                    Expanded(
                      flex: 35,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: portraitUrl.startsWith('http')
                                ? NetworkImage(portraitUrl) as ImageProvider
                                : AssetImage(portraitUrl),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 65% Info Area
                    Expanded(
                      flex: 65,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(
                              builder: (context) {
                                final parts = driver.name.split(' ');
                                final displayName = parts.length > 1
                                    ? "${parts[0][0]}. ${parts.last}"
                                    : driver.name;
                                return Text(
                                  displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildFitnessBar(theme, driver),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.speed,
                                  size: 10,
                                  color: maxed ? Colors.orange : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$laps / $kMaxPracticeLapsPerDriver LAPS",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: maxed
                                        ? Colors.orange
                                        : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircuitIntel(ThemeData theme) {
    String currentSessionWeather = "Sunny"; // Fallback
    if (_currentEvent != null) {
      if (_tabController.index == 0)
        currentSessionWeather = _currentEvent!.weatherPractice;
      if (_tabController.index == 1)
        currentSessionWeather = _currentEvent!.weatherQualifying;
      if (_tabController.index == 2)
        currentSessionWeather = _currentEvent!.weatherRace;
    }

    return Card(
      color: theme.cardTheme.color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blueAccent),
                const SizedBox(width: 6),
                Text(
                  "CIRCUIT INTEL",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  _circuit!.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Weather Chip
                _buildCircuitChip(
                  "Current Weather",
                  currentSessionWeather,
                  isWeather: true,
                ),

                // Performance Focus Chips
                ..._getPerformanceFocusChips(),

                // Other characteristics
                ..._circuit!.characteristics.entries.map((e) {
                  return _buildCircuitChip(e.key, e.value);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getPerformanceFocusChips() {
    List<Widget> chips = [];
    final aero = _circuit!.aeroWeight;
    final power = _circuit!.powertrainWeight;
    final chassis = _circuit!.chassisWeight;

    if (aero >= 0.4) chips.add(_buildCircuitChip("Focus", "Aerodynamics"));
    if (power >= 0.4) chips.add(_buildCircuitChip("Focus", "Powertrain"));
    if (chassis >= 0.4) chips.add(_buildCircuitChip("Focus", "Chassis"));

    return chips;
  }

  Widget _buildCircuitChip(String key, String value, {bool isWeather = false}) {
    Color bg, text;
    IconData? icon;

    if (isWeather) {
      if (value.toLowerCase().contains('rain') ||
          value.toLowerCase().contains('storm')) {
        bg = Colors.blue.withOpacity(0.1);
        text = Colors.blue;
        icon = Icons.umbrella;
      } else if (value.toLowerCase().contains('cloud')) {
        bg = Colors.grey.withOpacity(0.1);
        text = Colors.grey;
        icon = Icons.cloud;
      } else {
        bg = Colors.orange.withOpacity(0.1);
        text = Colors.orange;
        icon = Icons.wb_sunny;
      }
    } else if (value == 'High' ||
        value == 'Important' ||
        value == 'Crucial' ||
        value == 'Critical' ||
        value == 'Very High' ||
        value == 'Maximum' ||
        key == 'Focus') {
      bg = const Color(0xFFFF5252).withOpacity(0.1);
      text = const Color(0xFFFF5252);
    } else if (value == 'Low' || value == 'Low Priority') {
      bg = const Color(0xFF00C853).withOpacity(0.1);
      text = const Color(0xFF00C853);
    } else {
      bg = const Color(0xFFFFB800).withOpacity(0.1);
      text = const Color(0xFFFFB800);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            isWeather ? value : "$key: $value",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupCard(
    ThemeData theme,
    String title,
    CarSetup setup,
    bool editable,
    void Function(String field, int value) onChanged,
    ValueChanged<TyreCompound>? onCompoundChanged,
    void Function(List<TyreCompound> stops)? onPitStopsChanged, {
    Set<String>? parcFermeFields,
    ValueChanged<DriverStyle>? onStyleChanged,
  }) {
    Widget buildSlider(String label, int value, String fieldId) {
      final isLocked = parcFermeFields?.contains(fieldId) ?? false;
      return Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: AbsorbPointer(
          absorbing: isLocked,
          child: Row(
            children: [
              Expanded(
                child: _buildCompactSlider(
                  theme,
                  label,
                  value,
                  (v) => onChanged(fieldId, v),
                ),
              ),
              if (isLocked)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.lock, size: 12, color: Colors.orange),
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: theme.cardTheme.color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AbsorbPointer(
          absorbing: !editable,
          child: Opacity(
            opacity: editable ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                buildSlider("Front Wing", setup.frontWing, 'frontWing'),
                buildSlider("Rear Wing", setup.rearWing, 'rearWing'),
                buildSlider("Suspension", setup.suspension, 'suspension'),
                buildSlider("Gear Ratio", setup.gearRatio, 'gearRatio'),
                const SizedBox(height: 12),
                if (onStyleChanged != null) ...[
                  const Text(
                    "Driver Style",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: DriverStyle.values.map((style) {
                      final isSelected = setup.qualifyingStyle == style;
                      Color styleColor;
                      String styleLabel;
                      IconData icon;

                      switch (style) {
                        case DriverStyle.normal:
                          styleColor = Colors.green;
                          styleLabel = "NORMAL";
                          icon = Icons.directions_car;
                          break;
                        case DriverStyle.aggressive:
                          styleColor = Colors.orange;
                          styleLabel = "AGGRESSIVE";
                          icon = Icons.flash_on;
                          break;
                        case DriverStyle.mostRisky:
                          styleColor = Colors.red;
                          styleLabel = "RISKY";
                          icon = Icons.warning;
                          break;
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onStyleChanged(style),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? styleColor.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.03),
                              border: Border.all(
                                color: isSelected
                                    ? styleColor
                                    : Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  icon,
                                  size: 14,
                                  color: isSelected
                                      ? styleColor
                                      : Colors.white38,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  styleLabel,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? styleColor
                                        : Colors.white24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  "Tyre Compound",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: TyreCompound.values.map((compound) {
                    final isSelected = setup.tyreCompound == compound;
                    Color compoundColor;
                    switch (compound) {
                      case TyreCompound.soft:
                        compoundColor = Colors.red;
                      case TyreCompound.medium:
                        compoundColor = Colors.yellow;
                      case TyreCompound.hard:
                        compoundColor = Colors.white;
                      case TyreCompound.wet:
                        compoundColor = Colors.blue;
                    }

                    return InkWell(
                      onTap: () => onCompoundChanged?.call(compound),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? compoundColor.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? compoundColor
                                : Colors.grey.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          compound.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? compoundColor : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (onPitStopsChanged != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Race Strategy: Pit Stops",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      ...List.generate(setup.pitStops.length, (index) {
                        final currentStop = setup.pitStops[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Row(
                                  children: [
                                    Text(
                                      "STOP ${index + 1}:",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (editable)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 16,
                                          color: Colors.redAccent,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          final newStops =
                                              List<TyreCompound>.from(
                                                setup.pitStops,
                                              );
                                          newStops.removeAt(index);
                                          onPitStopsChanged(newStops);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: TyreCompound.values.map((compound) {
                                    final isSelected = currentStop == compound;
                                    Color compoundColor;
                                    switch (compound) {
                                      case TyreCompound.soft:
                                        compoundColor = Colors.red;
                                      case TyreCompound.medium:
                                        compoundColor = Colors.yellow;
                                      case TyreCompound.hard:
                                        compoundColor = Colors.white;
                                      case TyreCompound.wet:
                                        compoundColor = Colors.blue;
                                    }

                                    return InkWell(
                                      onTap: editable
                                          ? () {
                                              final newStops =
                                                  List<TyreCompound>.from(
                                                    setup.pitStops,
                                                  );
                                              newStops[index] = compound;
                                              onPitStopsChanged(newStops);
                                            }
                                          : null,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? compoundColor.withOpacity(0.2)
                                              : Colors.white.withOpacity(0.05),
                                          border: Border.all(
                                            color: isSelected
                                                ? compoundColor
                                                : Colors.transparent,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          compound.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? compoundColor
                                                : Colors.white24,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (editable && setup.pitStops.length < 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final newStops = List<TyreCompound>.from(
                                setup.pitStops,
                              );
                              newStops.add(TyreCompound.hard);
                              onPitStopsChanged(newStops);
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              "ADD PIT STOP",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 36),
                              side: BorderSide(
                                color: theme.primaryColor.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSlider(
    ThemeData theme,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: theme.colorScheme.secondary,
                inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(
                  0.1,
                ),
                thumbColor: theme.colorScheme.secondary,
                overlayColor: theme.colorScheme.secondary.withOpacity(0.1),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          Container(
            width: 32,
            alignment: Alignment.centerRight,
            child: Text(
              "$value",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastLapCard(ThemeData theme) {
    final personalBest = _bestPersonalLaps[_selectedDriverId];
    final globalBest = _fastestGlobalLap;
    final lastTime = _lastResult?.lapTime;

    // Help determine if last lap is PB or Global Best
    final isPB =
        lastTime != null && personalBest != null && lastTime <= personalBest;
    final isGlobal =
        lastTime != null && globalBest != null && lastTime <= globalBest;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E1E1E), const Color(0xFF0A0A0A)],
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Last Lap
            _buildStatColumn(
              theme,
              "LAST LAP",
              lastTime != null ? _formatLapTime(lastTime) : "-:---.---",
              isGlobal
                  ? const Color(0xFFE040FB)
                  : (isPB
                        ? const Color(0xFF00C853)
                        : theme.colorScheme.onSurface),
              CrossAxisAlignment.start,
            ),
            _buildDivider(theme),
            // 2. Best Personal (PB)
            _buildStatColumn(
              theme,
              "BEST PB",
              personalBest != null ? _formatLapTime(personalBest) : "-:---.---",
              const Color(0xFF00C853),
              CrossAxisAlignment.start,
            ),
            _buildDivider(theme),
            // 3. Fastest Lap (Overall)
            _buildStatColumn(
              theme,
              "FASTEST",
              globalBest != null ? _formatLapTime(globalBest) : "-:---.---",
              const Color(0xFFE040FB),
              CrossAxisAlignment.start,
              subValue: _fastestGlobalDriverId != null
                  ? _formatDriverInitialName(
                      _drivers
                          .firstWhere((d) => d.id == _fastestGlobalDriverId)
                          .name,
                    )
                  : null,
            ),
            _buildDivider(theme),
            // 4. Confidence
            _buildStatColumn(
              theme,
              "CONFIDENCE",
              _lastResult != null
                  ? "${(_lastResult!.setupConfidence * 100).toStringAsFixed(0)}%"
                  : "--%",
              _getConfidenceColor(_lastResult?.setupConfidence ?? 0),
              CrossAxisAlignment.end,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    ThemeData theme,
    String label,
    String value,
    Color color,
    CrossAxisAlignment alignment, {
    String? subValue,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 1.5,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: label == "CONFIDENCE" || label == "LAST LAP" ? 22 : 16,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        if (subValue != null)
          Text(
            subValue.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return VerticalDivider(
      width: 20,
      thickness: 1,
      indent: 5,
      endIndent: 5,
      color: theme.colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Widget _buildLapHistoryCard(ThemeData theme) {
    final laps = _driverLapHistory[_selectedDriverId] ?? [];
    final selectedDriver = _drivers
        .where((d) => d.id == _selectedDriverId)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: theme.primaryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  "LAP TIMES — ${selectedDriver?.name.split(' ').last.toUpperCase() ?? ''}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (laps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "No laps recorded yet",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  )
                else ...[
                  // Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    color: Colors.white.withValues(alpha: 0.03),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            "#",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "LAP TIME",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            "CONF",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // SCROLLABLE LIST OF LAPS with fixed height
                  SizedBox(
                    height: 180, // Fixed height for lap history
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: laps.length,
                      itemBuilder: (context, index) {
                        // Show newest on top (laps list already has newest at index 0 from _runPracticeSeries)
                        final lap = laps[index];
                        final lapTime = (lap['lapTime'] as num).toDouble();
                        final conf =
                            ((lap['confidence'] as num?)?.toDouble() ?? 0);
                        final bestTime = laps
                            .map((l) => (l['lapTime'] as num).toDouble())
                            .reduce((a, b) => a < b ? a : b);
                        final isBest = lapTime == bestTime;

                        // The chronological number of the lap
                        final lapNumber = laps.length - index;

                        return InkWell(
                          onTap: () => _showLapSetupDialog(lap),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isBest
                                  ? theme.primaryColor.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    "$lapNumber",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color: isBest
                                          ? theme.primaryColor
                                          : Colors.white38,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _formatLapTime(lapTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      color: isBest
                                          ? theme.primaryColor
                                          : Colors.white,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    "${(conf * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getConfidenceColor(conf),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitBoard(ThemeData theme) {
    if (_selectedDriverId == null) return const SizedBox.shrink();

    final totalLaps = _driverLaps[_selectedDriverId] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.developer_board, color: theme.primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                "PIT BOARD",
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Text(
                "LAPS: $totalLaps",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey(_pitBoardMessage),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Text(
                  _pitBoardMessage ?? "READY",
                  style: TextStyle(
                    color: _pitBoardMessage != null
                        ? theme.primaryColor
                        : Colors.white24,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Colors.white.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  "DRIVER FEEDBACK",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (_feedbackHistory.isNotEmpty)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: _groupFeedbackBySession().map((session) {
                  final driverName = session['driverName'] as String;
                  final messages =
                      session['messages'] as List<Map<String, dynamic>>;
                  final bestLap = session['bestLapInSeries'] as double?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: _driverColor(driverName),
                              child: Text(
                                driverName.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              driverName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Spacer(),
                            if (bestLap != null)
                              Text(
                                "BEST: ${_formatLapTime(bestLap)}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: theme.primaryColor.withOpacity(0.7),
                                  fontFamily: 'monospace',
                                ),
                              ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.white10,
                          ),
                        ),
                        ...messages.map((m) {
                          final color = m['color'] as Color;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_right,
                                  size: 14,
                                  color: color.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    m['message'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  "No feedback gathered yet",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.1),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLapSetupDialog(Map<String, dynamic> lap) {
    final setup = lap['setup'] as CarSetup?;
    if (setup == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "LAP SETUP — ${_formatLapTime(lap['lapTime'])}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSetupDetailRow("Front Wing", setup.frontWing),
              _buildSetupDetailRow("Rear Wing", setup.rearWing),
              _buildSetupDetailRow("Suspension", setup.suspension),
              _buildSetupDetailRow("Gear Ratio", setup.gearRatio),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Confidence"),
                  Text(
                    "${((lap['confidence'] ?? 0) * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(lap['confidence'] ?? 0),
                    ),
                  ),
                ],
              ),
              if (lap['feedback'] != null && lap['feedback'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  "\"${lap['feedback']}\"",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCurrentDriverSetup(setup.copyWith());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Setup restored to current session"),
                  ),
                );
              },
              child: const Text("RESTORE THIS SETUP"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSetupDetailRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            "$value",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───

  String _formatLapTime(double seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toStringAsFixed(3).padLeft(6, '0')}';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.98) return const Color(0xFF00C853); // Changed to Green
    if (confidence > 0.9) return const Color(0xFF64DD17);
    if (confidence > 0.7) return const Color(0xFFFFB800);
    return const Color(0xFFFF5252);
  }

  List<Map<String, dynamic>> _groupFeedbackBySession() {
    final List<Map<String, dynamic>> grouped = [];
    String? lastSessionId;

    for (var item in _feedbackHistory) {
      final sessionId = item['sessionId'] as String?;
      if (sessionId != null && sessionId == lastSessionId) {
        (grouped.last['messages'] as List).add(item);
      } else {
        lastSessionId = sessionId;
        grouped.add({
          'sessionId': sessionId,
          'driverId': item['driverId'],
          'driverName': item['driverName'],
          'bestLapInSeries': item['bestLapInSeries'],
          'messages': [item],
        });
      }
    }
    return grouped;
  }

  String _formatDriverInitialName(String fullName) {
    if (fullName.isEmpty) return "";
    final parts = fullName.split(' ');
    if (parts.length < 2) return fullName;
    return "${parts[0][0]}. ${parts.sublist(1).join(' ')}";
  }

  Color _driverColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final hue = (name.codeUnits.reduce((a, b) => a + b) * 13) % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.45).toColor();
  }

  Widget _buildFitnessBar(ThemeData theme, Driver driver) {
    final fitness = driver.stats[DriverStats.fitness] ?? 100;
    final progress = (fitness / 100.0).clamp(0.01, 1.0);

    Color barColor = const Color(0xFF00C853); // High
    if (fitness < 40) {
      barColor = const Color(0xFFFF5252); // Low
    } else if (fitness < 75) {
      barColor = const Color(0xFFFFB800); // Med
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 110,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 110 * progress,
              height: 4,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: barColor.withOpacity(0.3), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 8, color: barColor),
            const SizedBox(width: 2),
            Text(
              "FITNESS: $fitness%",
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: barColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallTyreIcon(TyreCompound? compound) {
    if (compound == null) return const SizedBox.shrink();
    Color color;
    switch (compound) {
      case TyreCompound.soft:
        color = Colors.red;
        break;
      case TyreCompound.medium:
        color = Colors.yellow;
        break;
      case TyreCompound.hard:
        color = Colors.white;
        break;
      case TyreCompound.wet:
        color = Colors.blue;
        break;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          compound.name[0].toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
