import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';
import '../../services/circuit_service.dart';
import 'qualifying_screen.dart';

class RaceStrategyScreen extends StatefulWidget {
  final String seasonId;
  final String teamId;
  final String? circuitId;
  final bool isEmbed;

  const RaceStrategyScreen({
    super.key,
    required this.seasonId,
    required this.teamId,
    this.circuitId,
    this.isEmbed = false,
  });

  @override
  State<RaceStrategyScreen> createState() => _RaceStrategyScreenState();
}

class _RaceStrategyScreenState extends State<RaceStrategyScreen> {
  bool _isLoading = false;
  CircuitProfile? _circuit;
  List<Driver> _drivers = [];

  // Setups per driver
  final Map<String, CarSetup> _driverSetups = {};
  String? _selectedDriverId;

  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Circuit
      final circuitId = widget.circuitId ?? 'interlagos';
      _circuit = CircuitService().getCircuitProfile(circuitId);

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
      }

      // 3. Fetch Team Setup (Check for existing strategy)
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();

      if (teamDoc.exists) {
        final team = Team.fromMap(teamDoc.data()!);

        // Check submission status
        if (team.weekStatus['raceStrategy'] == true) {
          _isSubmitted = true;
        }

        // Initialize setups for each driver
        for (var driver in _drivers) {
          CarSetup? loadedSetup;

          // A. Try loading specific Driver Race Setup
          final driverRaceSetups =
              team.weekStatus['driverRaceSetups'] as Map<dynamic, dynamic>?;
          if (driverRaceSetups != null &&
              driverRaceSetups.containsKey(driver.id)) {
            loadedSetup = CarSetup.fromMap(
              Map<String, dynamic>.from(driverRaceSetups[driver.id]),
            );
          }

          // B. Fallback: Try loading deprecated single 'raceSetup'
          if (loadedSetup == null && team.weekStatus['raceSetup'] != null) {
            loadedSetup = CarSetup.fromMap(
              Map<String, dynamic>.from(team.weekStatus['raceSetup']),
            );
          }

          // C. Fallback: Qualifying Setup
          if (loadedSetup == null) {
            // Check driverQualifyingSetups
            final driverQualySetups =
                team.weekStatus['driverQualysSetups'] as Map<dynamic, dynamic>?;
            if (driverQualySetups != null &&
                driverQualySetups.containsKey(driver.id)) {
              loadedSetup = CarSetup.fromMap(
                Map<String, dynamic>.from(driverQualySetups[driver.id]),
              );
            } else if (team.weekStatus['qualifyingSetup'] != null) {
              loadedSetup = CarSetup.fromMap(
                Map<String, dynamic>.from(team.weekStatus['qualifyingSetup']),
              );
            }
          }

          // D. Default
          _driverSetups[driver.id] = loadedSetup ?? CarSetup();
        }
      }
    } catch (e) {
      debugPrint("Error loading strategy data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitStrategy() async {
    setState(() => _isLoading = true);

    try {
      // Prepare map of setups
      Map<String, Map<String, dynamic>> setupsToSave = {};
      for (var entry in _driverSetups.entries) {
        setupsToSave[entry.key] = entry.value.toMap();
      }

      // Save to weekStatus
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
            'weekStatus.driverRaceSetups': setupsToSave,
            'weekStatus.raceStrategy': true,
            'weekStatus.raceStrategySubmittedAt': FieldValue.serverTimestamp(),
            // Legacy support (points to first driver or mean?) - let's just keep legacy null or ignore it to force using new field
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
            Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              "$value",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
          activeColor: Theme.of(context).primaryColor,
          onChanged: _isSubmitted ? null : (v) => onChanged(v.round()),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _circuit == null) {
      final loadingIndicator = const Center(child: CircularProgressIndicator());
      if (widget.isEmbed) return loadingIndicator;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: loadingIndicator,
      );
    }

    final currentSetup = _selectedDriverId != null
        ? _driverSetups[_selectedDriverId]
        : null;
    final theme = Theme.of(context);

    final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: theme.colorScheme.surface,
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSubmitted
                          ? "Your race setup has been submitted to Parc Fermé."
                          : "Adjust your setup one last time for the race. Consider tyre wear and fuel load.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_circuit != null) ...[
              Text(
                "Circuit Characteristics",
                style: theme.textTheme.titleMedium?.copyWith(
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
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.blueGrey[800]
                        : Colors.teal.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              "CONFIGURE DRIVER:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Driver Selector Tabs
            if (_drivers.isNotEmpty)
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 24),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _drivers.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final driver = _drivers[index];
                    final isSelected = driver.id == _selectedDriverId;

                    return ChoiceChip(
                      label: Text(driver.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected)
                          setState(() => _selectedDriverId = driver.id);
                      },
                      selectedColor: theme.primaryColor,
                      backgroundColor: theme.cardColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),

            if (currentSetup != null) ...[
              Text(
                "Final Setup",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _buildSlider(
                "Front Wing (Aero)",
                currentSetup.frontWing,
                (v) => setState(() => currentSetup.frontWing = v),
              ),
              _buildSlider(
                "Rear Wing (Drag)",
                currentSetup.rearWing,
                (v) => setState(() => currentSetup.rearWing = v),
              ),
              _buildSlider(
                "Suspension (Stiffness)",
                currentSetup.suspension,
                (v) => setState(() => currentSetup.suspension = v),
              ),
              _buildSlider(
                "Gear Ratio (Accel/Top)",
                currentSetup.gearRatio,
                (v) => setState(() => currentSetup.gearRatio = v),
              ),
              _buildSlider(
                "Tyre Pressure (Grip)",
                currentSetup.tyrePressure,
                (v) => setState(() => currentSetup.tyrePressure = v),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _isSubmitted)
                    ? null
                    : () {
                        // Confirmation Dialog?
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Submit Strategy?"),
                            content: const Text(
                              "This will lock the setup for BOTH drivers. Make sure you have configured both.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("CANCEL"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _submitStrategy();
                                },
                                child: const Text("SUBMIT ALL"),
                              ),
                            ],
                          ),
                        );
                      },
                icon: _isSubmitted
                    ? const Icon(Icons.lock)
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isSubmitted
                      ? "STRATEGY SUBMITTED"
                      : "SUBMIT TEAM STRATEGY (ALL)",
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: _isSubmitted
                      ? Colors.grey
                      : theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isEmbed) return content;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Race Strategy - ${_circuit?.name ?? 'Unknown Circuit'}"),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            tooltip: "Qualifying Results",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QualifyingScreen(
                    seasonId: widget.seasonId, // Need to pass seasonId
                    circuitId: widget.circuitId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }
}
