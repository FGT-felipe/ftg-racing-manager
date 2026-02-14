import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';
import '../../services/race_service.dart';
import '../../services/circuit_service.dart';
import '../../services/time_service.dart';
import 'widgets/internal_timing_card.dart';
import '../../utils/app_constants.dart';

class GarageScreen extends StatefulWidget {
  final String teamId;

  /// Circuit id for setup/profile (e.g. 'interlagos'). Uses current race circuit when opened from dashboard.
  final String? circuitId;

  const GarageScreen({super.key, required this.teamId, this.circuitId});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  CarSetup _currentSetup = CarSetup();
  PracticeRunResult? _lastResult;
  bool _isLoading = false;
  CircuitProfile? _circuit;
  List<Driver> _drivers = [];
  String? _selectedDriverId;
  Map<String, int> _driverLaps = {};
  List<Map<String, dynamic>> _feedbackHistory =
      []; // {driverName, message, color, time}

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Team Setup
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (teamDoc.exists) {
        final team = Team.fromMap(teamDoc.data()!);
        if (team.weekStatus['currentSetup'] != null) {
          _currentSetup = CarSetup.fromMap(
            Map<String, dynamic>.from(team.weekStatus['currentSetup']),
          );
        }
        if (team.weekStatus['practiceLaps'] != null) {
          _driverLaps = Map<String, int>.from(team.weekStatus['practiceLaps']);
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
        // Initialize lap counts if not present
        for (var driver in _drivers) {
          _driverLaps.putIfAbsent(driver.id, () => 0);
        }
      }

      // 3. Fetch Circuit (from current race when circuitId passed, else default)
      _circuit = CircuitService().getCircuitProfile(
        widget.circuitId ?? 'interlagos',
      );

      // 4. Load last practice results for each driver
      await _loadLastPracticeResults();
    } catch (e) {
      debugPrint("Error loading garage data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLastPracticeResults() async {
    try {
      for (var driver in _drivers) {
        final lastResultSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .collection('practice_results')
            .where('driverId', isEqualTo: driver.id)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastResultSnapshot.docs.isNotEmpty) {
          final data = lastResultSnapshot.docs.first.data();

          // Store last result for this driver
          if (driver.id == _selectedDriverId) {
            // Update current setup if this is the selected driver
            _currentSetup = CarSetup.fromMap(
              data['setupUsed'] as Map<String, dynamic>,
            );
          }

          // Store feedback
          if (data['feedback'] != null &&
              (data['feedback'] as String).isNotEmpty) {
            _feedbackHistory.add({
              'driverName': driver.name,
              'message': data['feedback'],
              'color': Colors.greenAccent,
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
            });
          }
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading practice results: $e");
    }
  }

  Future<void> _onDriverChanged(String? newDriverId) async {
    if (newDriverId == null || newDriverId == _selectedDriverId) return;

    setState(() {
      _selectedDriverId = newDriverId;
      _isLoading = true;
    });

    try {
      // Load last practice result for this driver
      final lastResultSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('practice_results')
          .where('driverId', isEqualTo: newDriverId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastResultSnapshot.docs.isNotEmpty) {
        final data = lastResultSnapshot.docs.first.data();
        setState(() {
          _currentSetup = CarSetup.fromMap(
            data['setupUsed'] as Map<String, dynamic>,
          );
        });
      } else {
        // Reset to default setup if no previous results
        setState(() {
          _currentSetup = CarSetup(
            frontWing: 50,
            rearWing: 50,
            suspension: 50,
            tyrePressure: 50,
          );
        });
      }
    } catch (e) {
      debugPrint("Error loading driver setup: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runPracticeLap() async {
    if (_circuit == null || _selectedDriverId == null) return;

    final currentLaps = _driverLaps[_selectedDriverId] ?? 0;
    if (currentLaps >= kMaxPracticeLapsPerDriver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Driver finished practice session (Max $kMaxPracticeLapsPerDriver laps)",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (!teamDoc.exists) throw Exception("Team not found");
      final team = Team.fromMap(teamDoc.data()!);
      final driver = _drivers.firstWhere((d) => d.id == _selectedDriverId);

      final result = RaceService().simulatePracticeRun(
        circuit: _circuit!,
        team: team,
        driver: driver,
        setup: _currentSetup,
      );

      // Analyze Feedback
      // Use 'consistency' or 'experience' as proxy for communication if not present
      final commsSkill = driver.stats['consistency'] ?? 50;

      for (var msg in result.driverFeedback) {
        Color msgColor = Colors.white;
        final lowerMsg = msg.toLowerCase();

        if (lowerMsg.contains('perfect') ||
            lowerMsg.contains('spot on') ||
            lowerMsg.contains('excellent') ||
            lowerMsg.contains('lujo')) {
          msgColor = Colors.purpleAccent; // Setup perfecto
        } else if (commsSkill > 50) {
          // High skill driver gives hints
          if (lowerMsg.contains('increase') ||
              lowerMsg.contains('reduce') ||
              lowerMsg.contains('too') ||
              lowerMsg.contains('more') ||
              lowerMsg.contains('less')) {
            msgColor = Colors.redAccent; // Needs change
          } else if (lowerMsg.contains('good') ||
              lowerMsg.contains('fine') ||
              lowerMsg.contains('ok')) {
            msgColor = Colors.greenAccent; // Good
          }
        }

        _feedbackHistory.insert(0, {
          'driverName': driver.name,
          'message': msg,
          'color': msgColor, // Store Color object
          'timestamp': DateTime.now(),
        });
      }

      // Update Laps
      _driverLaps[_selectedDriverId!] = currentLaps + 1;

      // Save to practice_results subcollection
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('practice_results')
          .add({
            'driverId': _selectedDriverId,
            'lapTime': result.lapTime,
            'setupUsed': _currentSetup.toMap(),
            'feedback': result.driverFeedback.isNotEmpty
                ? result.driverFeedback.first
                : '',
            'timestamp': FieldValue.serverTimestamp(),
            'setupConfidence': result.setupConfidence,
          });

      // Save Setup and Laps to team weekStatus
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.currentSetup': _currentSetup.toMap(),
            'weekStatus.setupConfidence': result.setupConfidence,
            'weekStatus.practiceLaps': _driverLaps,
          });

      setState(() {
        _lastResult = result;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndSendSetup() async {
    setState(() => _isLoading = true);

    try {
      final totalLaps = _driverLaps.values.fold<int>(
        0,
        (sum, laps) => sum + laps,
      );

      if (totalLaps < 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "You must complete at least 1 practice lap before submitting setup",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Save to current_event subcollection
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('current_event')
          .doc('qualifying_setup')
          .set({
            'setup': _currentSetup.toMap(),
            'submittedAt': FieldValue.serverTimestamp(),
            'practiceLapsCompleted': totalLaps,
          });

      // Also update weekStatus for backward compatibility
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.qualifyingSetup': _currentSetup.toMap(),
            'weekStatus.setupSubmittedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Qualifying setup submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving setup: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _circuit == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Use TimeService for Paddock Logic
    final timeService = TimeService();
    final isPaddockOpen = timeService.currentStatus == RaceWeekStatus.practice;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Garage - ${_circuit?.name ?? 'Circuit'}"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (!isPaddockOpen)
            Container(
              margin: const EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Setup Controls
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver Selection
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _drivers.length,
                          itemBuilder: (context, index) {
                            final driver = _drivers[index];
                            final isSelected = driver.id == _selectedDriverId;
                            final laps = _driverLaps[driver.id] ?? 0;

                            return GestureDetector(
                              onTap: () => _onDriverChanged(driver.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF333333)
                                      : const Color(0xFF252525),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.orangeAccent
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildDriverAvatar(driver.name),
                                    const SizedBox(height: 8),
                                    Text(
                                      driver.name.split(' ').last,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "$laps/$kMaxPracticeLapsPerDriver laps",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: laps >= kMaxPracticeLapsPerDriver
                                            ? Colors.redAccent
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Circuit Characteristics
                      if (_circuit != null &&
                          _circuit!.characteristics.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "CIRCUIT INTEL",
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._circuit!.characteristics.entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e.key,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      _buildCircuitBadge(e.value),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Text(
                        "Car Setup",
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),

                      AbsorbPointer(
                        absorbing: !isPaddockOpen,
                        child: Opacity(
                          opacity: isPaddockOpen ? 1.0 : 0.6,
                          child: Column(
                            children: [
                              _buildSlider(
                                "Front Wing (Aero)",
                                _currentSetup.frontWing,
                                (v) =>
                                    setState(() => _currentSetup.frontWing = v),
                              ),
                              _buildSlider(
                                "Rear Wing (Drag)",
                                _currentSetup.rearWing,
                                (v) =>
                                    setState(() => _currentSetup.rearWing = v),
                              ),
                              _buildSlider(
                                "Suspension (Stiffness)",
                                _currentSetup.suspension,
                                (v) => setState(
                                  () => _currentSetup.suspension = v,
                                ),
                              ),
                              _buildSlider(
                                "Gear Ratio (Accel/Top)",
                                _currentSetup.gearRatio,
                                (v) =>
                                    setState(() => _currentSetup.gearRatio = v),
                              ),
                              _buildSlider(
                                "Tyre Pressure (Grip)",
                                _currentSetup.tyrePressure,
                                (v) => setState(
                                  () => _currentSetup.tyrePressure = v,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (isPaddockOpen && !_isLoading)
                              ? _saveAndSendSetup
                              : null,
                          icon: const Icon(Icons.send),
                          label: const Text("SAVE & SEND SETUP"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: isPaddockOpen
                                ? Colors.tealAccent
                                : Colors.grey[800],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (isPaddockOpen && !_isLoading)
                              ? _runPracticeLap
                              : null,
                          icon: isPaddockOpen
                              ? const Icon(Icons.speed)
                              : const Icon(Icons.lock),
                          label: Text(
                            isPaddockOpen
                                ? "RUN PRACTICE LAP"
                                : "SESSION LOCKED",
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: isPaddockOpen
                                ? const Color(0xFF00FF88)
                                : Colors.grey[400],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right Panel: Telemetry & Feedback
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Lap Time Card
                Card(
                  margin: const EdgeInsets.fromLTRB(0, 16, 16, 8),
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LAST LAP TIME",
                              style: TextStyle(
                                color: Colors.grey[500],
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lastResult != null
                                  ? "${_lastResult!.lapTime.toStringAsFixed(3)}s"
                                  : "--.---",
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
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
                                color: Colors.grey[500],
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lastResult != null
                                  ? "${(_lastResult!.setupConfidence * 100).toStringAsFixed(0)}%"
                                  : "--%",
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
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
                ),

                // Driver Feedback Card
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(0, 8, 16, 16),
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "DRIVER FEEDBACK",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey[800]),
                          const SizedBox(height: 16),

                          if (_feedbackHistory.isNotEmpty)
                            Expanded(
                              child: ListView.builder(
                                itemCount: _feedbackHistory.length,
                                itemBuilder: (context, index) {
                                  final item = _feedbackHistory[index];
                                  final color = item['color'] as Color;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDriverAvatar(
                                          item['driverName'],
                                          false,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    item['driverName'],
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "• ${(item['timestamp'] as DateTime).toLocal().toString().substring(11, 16)}",
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item['message'],
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.4,
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
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "No feedback yet.\nRun a practice lap to get data from your drivers.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitBadge(String value) {
    Color bg;
    Color text;

    if (value == 'High' || value == 'Important') {
      bg = const Color(0xFFFF5252).withValues(alpha: 0.2); // Red
      text = const Color(0xFFFF5252);
    } else if (value == 'Low') {
      bg = const Color(0xFF00E676).withValues(alpha: 0.2); // Green
      text = const Color(0xFF00E676);
    } else {
      // Normal / Default
      bg = const Color(0xFFFFEA00).withValues(alpha: 0.2); // Yellow
      text = const Color(0xFFFFEA00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: text.withValues(alpha: 0.5)),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.9) return const Color(0xFF00E676);
    if (confidence > 0.7) return const Color(0xFFFFEA00);
    return const Color(0xFFFF5252);
  }

  Widget _buildSlider(String label, int value, Function(int) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Theme(
            data: ThemeData.dark().copyWith(
              sliderTheme: SliderThemeData(
                activeTrackColor: Colors.tealAccent,
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.tealAccent,
                overlayColor: Colors.tealAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: value.toString(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverAvatar(String name, [bool large = true]) {
    final scale = large ? 1.0 : 0.7;
    // Consistent color seeded by name
    final hue = (name.codeUnits.reduce((a, b) => a + b) * 13) % 360;
    final teamColor = HSLColor.fromAHSL(
      1.0,
      hue.toDouble(),
      0.8,
      0.5,
    ).toColor();

    return SizedBox(
      width: 40 * scale,
      height: 40 * scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Head
          Container(
            width: 24 * scale,
            height: 28 * scale,
            margin: EdgeInsets.only(bottom: 4 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCCBC),
              borderRadius: BorderRadius.circular(6 * scale),
            ),
          ),
          // Eyes
          Positioned(
            bottom: 18 * scale,
            left: 14 * scale,
            child: Container(
              width: 4 * scale,
              height: 4 * scale,
              color: Colors.black87,
            ),
          ),
          Positioned(
            bottom: 18 * scale,
            right: 14 * scale,
            child: Container(
              width: 4 * scale,
              height: 4 * scale,
              color: Colors.black87,
            ),
          ),
          // Cap Visor
          Positioned(
            top: 6 * scale,
            child: Container(
              width: 30 * scale,
              height: 4 * scale,
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: BorderRadius.circular(2 * scale),
              ),
            ),
          ),
          // Cap Dome
          Positioned(
            top: 0,
            child: Container(
              width: 26 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
