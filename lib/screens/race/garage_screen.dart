import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';
import '../../services/race_service.dart';
import '../../services/circuit_service.dart';
import '../../services/time_service.dart';
import '../../utils/app_constants.dart';

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
    with SingleTickerProviderStateMixin {
  // State
  bool _isLoading = false;
  CircuitProfile? _circuit;
  List<Driver> _drivers = [];
  String? _selectedDriverId;
  Map<String, int> _driverLaps = {};

  // Per-driver setups: driverId -> CarSetup
  final Map<String, CarSetup> _driverSetups = {};

  // Per-driver lap history: driverId -> [{lapTime, confidence, feedback}]
  final Map<String, List<Map<String, dynamic>>> _driverLapHistory = {};

  PracticeRunResult? _lastResult;
  final List<Map<String, dynamic>> _feedbackHistory = [];

  // Setup tab: 0=Practice, 1=Qualifying, 2=Race
  late TabController _tabController;

  // Qualifying & Race setups (team-level)
  CarSetup _qualifyingSetup = CarSetup();
  CarSetup _raceSetup = CarSetup();
  bool _qualifyingSetupSubmitted = false;
  bool _raceSetupSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Team
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
        // Load qualifying setup if already submitted
        if (team.weekStatus['qualifyingSetup'] != null) {
          _qualifyingSetup = CarSetup.fromMap(
            Map<String, dynamic>.from(team.weekStatus['qualifyingSetup']),
          );
          _qualifyingSetupSubmitted =
              team.weekStatus['setupSubmittedAt'] != null;
        }
        // Load race setup if already submitted
        if (team.weekStatus['raceSetup'] != null) {
          _raceSetup = CarSetup.fromMap(
            Map<String, dynamic>.from(team.weekStatus['raceSetup']),
          );
          _raceSetupSubmitted = team.weekStatus['raceSetupSubmittedAt'] != null;
        }
      }

      // 2. Fetch Drivers
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('drivers')
          .get();

      _drivers = driversSnapshot.docs
          .map((d) => Driver.fromMap(d.data()))
          .toList();

      if (_drivers.isNotEmpty) {
        _selectedDriverId = _drivers.first.id;
        for (var driver in _drivers) {
          _driverLaps.putIfAbsent(driver.id, () => 0);
          _driverSetups.putIfAbsent(driver.id, () => CarSetup());
          _driverLapHistory.putIfAbsent(driver.id, () => []);
        }
      }

      // 3. Fetch Circuit
      _circuit = CircuitService().getCircuitProfile(
        widget.circuitId ?? 'interlagos',
      );

      // 4. Load practice results per driver
      await _loadPracticeResults();
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

        // Load setup from most recent run for each driver
        if (!setupLoaded.contains(driverId) && data['setupUsed'] != null) {
          _driverSetups[driverId] = CarSetup.fromMap(
            Map<String, dynamic>.from(data['setupUsed']),
          );
          setupLoaded.add(driverId);
        }

        // Build lap history
        _driverLapHistory.putIfAbsent(driverId, () => []);
        _driverLapHistory[driverId]!.add({
          'lapTime': (data['lapTime'] as num).toDouble(),
          'confidence': data['setupConfidence'] ?? 0.0,
          'feedback': data['feedback'] ?? '',
          'setup': data['setupUsed'] != null
              ? CarSetup.fromMap(Map<String, dynamic>.from(data['setupUsed']))
              : null,
        });

        // Add to feedback history
        if (data['feedback'] != null &&
            (data['feedback'] as String).isNotEmpty) {
          final driverName =
              _drivers
                  .where((d) => d.id == driverId)
                  .map((d) => d.name)
                  .firstOrNull ??
              'Driver';
          _feedbackHistory.add({
            'driverName': driverName,
            'message': data['feedback'],
            'color': Colors.grey,
            'timestamp': data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
          });
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

  CarSetup get _currentDriverSetup {
    return _driverSetups[_selectedDriverId] ?? CarSetup();
  }

  void _updateCurrentDriverSetup(CarSetup setup) {
    if (_selectedDriverId != null) {
      _driverSetups[_selectedDriverId!] = setup;
    }
  }

  Future<void> _runPracticeLap() async {
    if (_circuit == null || _selectedDriverId == null) return;

    final currentLaps = _driverLaps[_selectedDriverId] ?? 0;
    if (currentLaps >= kMaxPracticeLapsPerDriver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Driver reached max practice laps ($kMaxPracticeLapsPerDriver)",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;

    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (!teamDoc.exists) throw Exception("Team not found");
      final team = Team.fromMap(teamDoc.data()!);
      final driver = _drivers.firstWhere((d) => d.id == _selectedDriverId);
      final setup = _currentDriverSetup;

      final result = RaceService().simulatePracticeRun(
        circuit: _circuit!,
        team: team,
        driver: driver,
        setup: setup,
      );

      // Color-code feedback
      final commsSkill = driver.stats['consistency'] ?? 50;
      for (var msg in result.driverFeedback) {
        Color msgColor = defaultTextColor;
        final lowerMsg = msg.toLowerCase();

        if (lowerMsg.contains('perfect') ||
            lowerMsg.contains('spot on') ||
            lowerMsg.contains('excellent')) {
          msgColor = Colors.green;
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
          'driverName': driver.name,
          'message': msg,
          'color': msgColor,
          'timestamp': DateTime.now(),
        });
      }

      // Update Laps
      _driverLaps[_selectedDriverId!] = currentLaps + 1;

      // Add to lap history
      _driverLapHistory.putIfAbsent(_selectedDriverId!, () => []);
      _driverLapHistory[_selectedDriverId!]!.insert(0, {
        'lapTime': result.lapTime,
        'confidence': result.setupConfidence,
        'feedback': result.driverFeedback.isNotEmpty
            ? result.driverFeedback.first
            : '',
        'setup': setup.copyWith(), // Copy the setup used
      });

      // Save practice result
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('practice_results')
          .add({
            'driverId': _selectedDriverId,
            'lapTime': result.lapTime,
            'setupUsed': setup.toMap(),
            'feedback': result.driverFeedback.isNotEmpty
                ? result.driverFeedback.first
                : '',
            'timestamp': FieldValue.serverTimestamp(),
            'setupConfidence': result.setupConfidence,
          });

      // Save to team weekStatus
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.currentSetup': setup.toMap(),
            'weekStatus.setupConfidence': result.setupConfidence,
            'weekStatus.practiceLaps': _driverLaps,
          });

      setState(() {
        _lastResult = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveQualifyingSetup() async {
    setState(() => _isLoading = true);
    try {
      final totalLaps = _driverLaps.values.fold<int>(0, (s, l) => s + l);
      if (totalLaps < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Complete at least 1 practice lap first"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('current_event')
          .doc('qualifying_setup')
          .set({
            'setup': _qualifyingSetup.toMap(),
            'submittedAt': FieldValue.serverTimestamp(),
            'practiceLapsCompleted': totalLaps,
          });

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.qualifyingSetup': _qualifyingSetup.toMap(),
            'weekStatus.setupSubmittedAt': FieldValue.serverTimestamp(),
          });

      setState(() => _qualifyingSetupSubmitted = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Qualifying setup submitted!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRaceSetup() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('current_event')
          .doc('race_setup')
          .set({
            'setup': _raceSetup.toMap(),
            'submittedAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.raceSetup': _raceSetup.toMap(),
            'weekStatus.raceSetupSubmittedAt': FieldValue.serverTimestamp(),
          });

      setState(() => _raceSetupSubmitted = true);
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
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.5,
          ),
          indicatorColor: theme.primaryColor,
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
                  borderRadius: BorderRadius.circular(4),
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
                _currentDriverSetup,
                isPaddockOpen,
                (field, val) {
                  setState(() {
                    final s = _currentDriverSetup;
                    switch (field) {
                      case 'frontWing':
                        s.frontWing = val;
                      case 'rearWing':
                        s.rearWing = val;
                      case 'suspension':
                        s.suspension = val;
                      case 'gearRatio':
                        s.gearRatio = val;
                      case 'tyrePressure':
                        s.tyrePressure = val;
                    }
                    _updateCurrentDriverSetup(s);
                  });
                },
              ),
              const SizedBox(height: 12),

              // RUN PRACTICE LAP button FIRST
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isPaddockOpen && !_isLoading)
                      ? _runPracticeLap
                      : null,
                  icon: isPaddockOpen
                      ? const Icon(Icons.speed, size: 18)
                      : const Icon(Icons.lock, size: 18),
                  label: Text(
                    isPaddockOpen ? "RUN PRACTICE LAP" : "SESSION LOCKED",
                  ),
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

              const SizedBox(height: 8),

              // SAVE QUALIFYING SETUP button SECOND
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (isPaddockOpen && !_isLoading)
                      ? _saveQualifyingSetup
                      : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text("SAVE AS QUALIFYING SETUP"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.primaryColor),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFB800).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFFB800)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Configure the car setup that will be used during the Qualifying session. "
                  "This determines your grid position for the race.",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_qualifyingSetupSubmitted)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  "Qualifying setup submitted ✓",
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
          "QUALIFYING SETUP",
          _qualifyingSetup,
          isPaddockOpen && !_qualifyingSetupSubmitted,
          (field, val) {
            setState(() {
              switch (field) {
                case 'frontWing':
                  _qualifyingSetup.frontWing = val;
                case 'rearWing':
                  _qualifyingSetup.rearWing = val;
                case 'suspension':
                  _qualifyingSetup.suspension = val;
                case 'gearRatio':
                  _qualifyingSetup.gearRatio = val;
                case 'tyrePressure':
                  _qualifyingSetup.tyrePressure = val;
              }
            });
          },
        ),
        const SizedBox(height: 16),

        if (!_qualifyingSetupSubmitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isPaddockOpen && !_isLoading)
                  ? _saveQualifyingSetup
                  : null,
              icon: const Icon(Icons.send, size: 18),
              label: const Text("SUBMIT QUALIFYING SETUP"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFFFB800),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── RACE TAB ───

  Widget _buildRaceTab(ThemeData theme, bool isPaddockOpen) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF5252).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFFFF5252)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Configure your race strategy setup. This setup will be used during the race itself. "
                  "Consider tyre wear and fuel consumption for the full race distance.",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_raceSetupSubmitted)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
          _raceSetup,
          isPaddockOpen && !_raceSetupSubmitted,
          (field, val) {
            setState(() {
              switch (field) {
                case 'frontWing':
                  _raceSetup.frontWing = val;
                case 'rearWing':
                  _raceSetup.rearWing = val;
                case 'suspension':
                  _raceSetup.suspension = val;
                case 'gearRatio':
                  _raceSetup.gearRatio = val;
                case 'tyrePressure':
                  _raceSetup.tyrePressure = val;
              }
            });
          },
        ),
        const SizedBox(height: 16),

        if (!_raceSetupSubmitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isPaddockOpen && !_isLoading) ? _saveRaceSetup : null,
              icon: const Icon(Icons.flag, size: 18),
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
    );
  }

  // ─── REUSABLE WIDGETS ───

  Widget _buildDriverSelector(ThemeData theme) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          final isSelected = driver.id == _selectedDriverId;
          final laps = _driverLaps[driver.id] ?? 0;
          final maxed = laps >= kMaxPracticeLapsPerDriver;

          return GestureDetector(
            onTap: () => _onDriverChanged(driver.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: isSelected ? theme.primaryColor : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _driverColor(driver.name),
                    child: Text(
                      driver.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name.split(' ').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "$laps/$kMaxPracticeLapsPerDriver laps",
                        style: TextStyle(
                          fontSize: 11,
                          color: maxed
                              ? Colors.redAccent
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                          fontWeight: maxed
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircuitIntel(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blueAccent),
                const SizedBox(width: 6),
                Text(
                  "CIRCUIT INTEL",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _circuit!.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _circuit!.characteristics.entries.map((e) {
                return _buildCircuitChip(e.key, e.value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircuitChip(String key, String value) {
    Color bg, text;
    if (value == 'High' ||
        value == 'Important' ||
        value == 'Crucial' ||
        value == 'Critical' ||
        value == 'Very High' ||
        value == 'Maximum') {
      bg = const Color(0xFFFF5252).withValues(alpha: 0.1);
      text = const Color(0xFFFF5252);
    } else if (value == 'Low' || value == 'Low Priority') {
      bg = const Color(0xFF00C853).withValues(alpha: 0.1);
      text = const Color(0xFF00C853);
    } else {
      bg = const Color(0xFFFFB800).withValues(alpha: 0.1);
      text = const Color(0xFFFFB800);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$key: $value",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildSetupCard(
    ThemeData theme,
    String title,
    CarSetup setup,
    bool editable,
    void Function(String field, int value) onChanged,
  ) {
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
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
                _buildCompactSlider(
                  theme,
                  "Front Wing",
                  setup.frontWing,
                  (v) => onChanged('frontWing', v),
                ),
                _buildCompactSlider(
                  theme,
                  "Rear Wing",
                  setup.rearWing,
                  (v) => onChanged('rearWing', v),
                ),
                _buildCompactSlider(
                  theme,
                  "Suspension",
                  setup.suspension,
                  (v) => onChanged('suspension', v),
                ),
                _buildCompactSlider(
                  theme,
                  "Gear Ratio",
                  setup.gearRatio,
                  (v) => onChanged('gearRatio', v),
                ),
                _buildCompactSlider(
                  theme,
                  "Tyre Pressure",
                  setup.tyrePressure,
                  (v) => onChanged('tyrePressure', v),
                ),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: theme.primaryColor,
                inactiveTrackColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.1,
                ),
                thumbColor: theme.primaryColor,
                overlayColor: theme.primaryColor.withValues(alpha: 0.1),
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
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastLapCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 0),
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LAST LAP TIME",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lastResult != null
                      ? _formatLapTime(_lastResult!.lapTime)
                      : "-:---.---",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "CONFIDENCE",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lastResult != null
                      ? "${(_lastResult!.setupConfidence * 100).toStringAsFixed(0)}%"
                      : "--%",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: _getConfidenceColor(
                      _lastResult?.setupConfidence ?? 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLapHistoryCard(ThemeData theme) {
    final laps = _driverLapHistory[_selectedDriverId] ?? [];
    final selectedDriver = _drivers
        .where((d) => d.id == _selectedDriverId)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.fromLTRB(0, 4, 12, 0),
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: theme.primaryColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  "LAP TIMES — ${selectedDriver?.name.split(' ').last.toUpperCase() ?? ''}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (laps.isEmpty)
              Text(
                "No laps recorded yet",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              )
            else
            // Header
            ...[
              Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      "#",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "LAP TIME",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
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
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Show individual laps (reversed so newest is on top, but numbered chronologically)
              ...laps.reversed.toList().asMap().entries.map((entry) {
                final i = entry.key;
                final lap = entry.value;
                final lapTime = (lap['lapTime'] as num).toDouble();
                final conf = ((lap['confidence'] as num?)?.toDouble() ?? 0);
                final bestTime = laps
                    .map((l) => (l['lapTime'] as num).toDouble())
                    .reduce((a, b) => a < b ? a : b);
                final isBest = lapTime == bestTime;

                return InkWell(
                  onTap: () => _showLapSetupDialog(lap),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isBest
                          ? theme.primaryColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            "${i + 1}",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: isBest
                                  ? theme.primaryColor
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatLapTime(lapTime),
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              fontWeight: isBest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isBest
                                  ? theme.primaryColor
                                  : theme.colorScheme.onSurface,
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
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: _getConfidenceColor(conf),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 4, 12, 12),
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  "DRIVER FEEDBACK",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_feedbackHistory.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _feedbackHistory.length,
                  itemBuilder: (context, index) {
                    final item = _feedbackHistory[index];
                    final color = item['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: _driverColor(
                              item['driverName'] ?? '',
                            ),
                            child: Text(
                              (item['driverName'] ?? 'D').toString().substring(
                                0,
                                1,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['driverName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                Text(
                                  item['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    "Run a practice lap to get feedback.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              _buildSetupDetailRow("Tyre Pressure", setup.tyrePressure),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    if (confidence > 0.9) return const Color(0xFF00C853);
    if (confidence > 0.7) return const Color(0xFFFFB800);
    return const Color(0xFFFF5252);
  }

  Color _driverColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final hue = (name.codeUnits.reduce((a, b) => a + b) * 13) % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.45).toColor();
  }
}
