import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';
import '../../services/circuit_service.dart';

class RaceStrategyScreen extends StatefulWidget {
  final String teamId;
  final String? circuitId;

  const RaceStrategyScreen({super.key, required this.teamId, this.circuitId});

  @override
  State<RaceStrategyScreen> createState() => _RaceStrategyScreenState();
}

class _RaceStrategyScreenState extends State<RaceStrategyScreen> {
  CarSetup _currentSetup = CarSetup();
  bool _isLoading = false;
  CircuitProfile? _circuit;
  List<Driver> _drivers = [];

  bool _isSubmitted = false;

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

        // Load Race Setup if exists, else Qualy Setup, else Current Setup
        if (team.weekStatus['raceSetup'] != null) {
          _currentSetup = CarSetup.fromMap(
            Map<String, dynamic>.from(team.weekStatus['raceSetup']),
          );
          _isSubmitted =
              true; // Assume if it exists it was submitted? Or check flag.
          // Check specific flag if available, plan says weekStatus.raceStrategy
          if (team.weekStatus['raceStrategy'] != null) {
            _isSubmitted = true;
          }
        } else if (team.weekStatus['qualifyingSetup'] != null) {
          _currentSetup = CarSetup.fromMap(
            Map<String, dynamic>.from(team.weekStatus['qualifyingSetup']),
          );
        } else if (team.weekStatus['currentSetup'] != null) {
          _currentSetup = CarSetup.fromMap(
            Map<String, dynamic>.from(team.weekStatus['currentSetup']),
          );
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
        // We might want to show driver info later
      }

      // 3. Fetch Circuit
      _circuit = CircuitService().getCircuitProfile(
        widget.circuitId ?? 'interlagos',
      );
    } catch (e) {
      debugPrint("Error loading strategy data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitStrategy() async {
    setState(() => _isLoading = true);

    try {
      // Save to weekStatus
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.raceSetup': _currentSetup.toMap(),
            'weekStatus.raceStrategy': true,
            'weekStatus.raceStrategySubmittedAt': FieldValue.serverTimestamp(),
          });

      setState(() => _isSubmitted = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Race Strategy submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving strategy: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSlider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              "$value",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: Colors.orangeAccent,
          onChanged: _isSubmitted ? null : (v) => onChanged(v.round()),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _circuit == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Race Strategy - ${_circuit?.name}"),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.privacy_tip,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSubmitted ? "STRATEGY LOCKED" : "DEFINE RACE SETUP",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSubmitted
                            ? "Your race setup has been submitted to Parc Fermé."
                            : "Adjust your setup one last time for the race. Consider tyre wear and fuel load.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_circuit != null) ...[
                Text(
                  "Circuit Characteristics",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _circuit!.characteristics.entries.map((e) {
                    return Chip(
                      label: Text("${e.key}: ${e.value}"),
                      backgroundColor: Colors.blueGrey[800],
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                "Final Car Setup",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              _buildSlider(
                "Front Wing (Aero)",
                _currentSetup.frontWing,
                (v) => setState(() => _currentSetup.frontWing = v),
              ),
              _buildSlider(
                "Rear Wing (Drag)",
                _currentSetup.rearWing,
                (v) => setState(() => _currentSetup.rearWing = v),
              ),
              _buildSlider(
                "Suspension (Stiffness)",
                _currentSetup.suspension,
                (v) => setState(() => _currentSetup.suspension = v),
              ),
              _buildSlider(
                "Gear Ratio (Accel/Top)",
                _currentSetup.gearRatio,
                (v) => setState(() => _currentSetup.gearRatio = v),
              ),
              _buildSlider(
                "Tyre Pressure (Grip)",
                _currentSetup.tyrePressure,
                (v) => setState(() => _currentSetup.tyrePressure = v),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _isSubmitted)
                      ? null
                      : _submitStrategy,
                  icon: _isSubmitted
                      ? const Icon(Icons.lock)
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitted
                        ? "STRATEGY SUBMITTED"
                        : "SUBMIT RACE STRATEGY",
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: _isSubmitted
                        ? Colors.grey
                        : Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
