import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/simulation_models.dart';
import '../../services/circuit_service.dart';

import '../../widgets/fuel_input.dart';
import '../../widgets/common/onyx_table.dart';
import 'qualifying_screen.dart';

class RaceStrategyScreen extends StatefulWidget {
  final String seasonId;
  final String teamId;
  final String? circuitId;
  final String? raceDocId;
  final bool isEmbed;

  const RaceStrategyScreen({
    super.key,
    required this.seasonId,
    required this.teamId,
    this.circuitId,
    this.raceDocId,
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

  // Final Qualifying Grid
  List<Map<String, dynamic>> _qualyGrid = [];

  bool _isSubmitted = false;
  final Map<String, TyreCompound> _qualifyingBestCompounds = {};

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

      // 2. Fetch Drivers from top-level collection
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('teamId', isEqualTo: widget.teamId)
          .get();

      _drivers = driversSnapshot.docs
          .map((d) => Driver.fromMap({...d.data(), 'id': d.id}))
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

          // Load from unified structure: weekStatus.driverSetups.{driverId}.race
          final driverSetups =
              team.weekStatus['driverSetups'] as Map<dynamic, dynamic>?;
          if (driverSetups != null && driverSetups.containsKey(driver.id)) {
            final driverData = Map<String, dynamic>.from(
              driverSetups[driver.id],
            );
            if (driverData['race'] != null) {
              loadedSetup = CarSetup.fromMap(
                Map<String, dynamic>.from(driverData['race']),
              );
            } else if (driverData['qualifying'] != null) {
              // Fallback to Qualy Setup if Race Setup doesn't exist yet
              loadedSetup = CarSetup.fromMap(
                Map<String, dynamic>.from(driverData['qualifying']),
              );
            }
          }

          // Legacy Fallbacks
          if (loadedSetup == null) {
            if (team.weekStatus['raceSetup'] != null) {
              loadedSetup = CarSetup.fromMap(
                Map<String, dynamic>.from(team.weekStatus['raceSetup']),
              );
            } else if (team.weekStatus['qualifyingSetup'] != null) {
              loadedSetup = CarSetup.fromMap(
                Map<String, dynamic>.from(team.weekStatus['qualifyingSetup']),
              );
            }
          }

          _driverSetups[driver.id] = loadedSetup ?? CarSetup();
        }
      }

      // 4. Load Qualifying Results by exact document ID
      if (widget.raceDocId != null) {
        final raceDoc = await FirebaseFirestore.instance
            .collection('races')
            .doc(widget.raceDocId)
            .get();

        if (raceDoc.exists) {
          final data = raceDoc.data()!;
          final rawResults = data['qualifyingResults'] ?? data['qualyGrid'];
          if (rawResults != null &&
              rawResults is List &&
              rawResults.isNotEmpty) {
            _qualyGrid = rawResults
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            for (var res in _qualyGrid) {
              final dId = res['driverId'] as String?;
              final compoundName = res['tyreCompound'] as String?;
              if (dId != null && compoundName != null) {
                final compound = TyreCompound.values.firstWhere(
                  (c) => c.name == compoundName,
                  orElse: () => TyreCompound.soft,
                );
                _qualifyingBestCompounds[dId] = compound;
                if (_driverSetups.containsKey(dId) && !_isSubmitted) {
                  _driverSetups[dId]!.tyreCompound = compound;
                }
              }
            }
          }
        }
      }
    } catch (e, stack) {
      debugPrint("Error loading strategy data: $e");
      debugPrint("Stack: $stack");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitStrategy() async {
    setState(() => _isLoading = true);

    try {
      // Prepare batch updates for unified structure
      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId);

      Map<String, dynamic> updates = {
        'weekStatus.raceStrategy': true,
        'weekStatus.raceStrategySubmittedAt': FieldValue.serverTimestamp(),
      };

      for (var entry in _driverSetups.entries) {
        updates['weekStatus.driverSetups.${entry.key}.race'] = entry.value
            .toMap();
        updates['weekStatus.driverSetups.${entry.key}.raceSubmitted'] = true;
      }

      await teamRef.update(updates);

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
                fontSize: 12,
              ),
            ),
            Text(
              "$value",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: Theme.of(context).colorScheme.secondary,
            onChanged: _isSubmitted ? null : (v) => onChanged(v.round()),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildStyleSelector(
    DriverStyle currentStyle,
    ValueChanged<DriverStyle> onStyleChanged,
  ) {
    final styles = [
      (
        DriverStyle.defensive,
        Icons.keyboard_arrow_down,
        const Color(0xFF42A5F5),
      ),
      (DriverStyle.normal, Icons.remove, const Color(0xFF00C853)),
      (DriverStyle.offensive, Icons.keyboard_arrow_up, const Color(0xFFFF9800)),
      (
        DriverStyle.mostRisky,
        Icons.keyboard_double_arrow_up,
        const Color(0xFFFF3D3D),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: styles.map((s) {
        final isSelected = currentStyle == s.$1;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isSubmitted ? null : () => onStyleChanged(s.$1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? s.$3.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? s.$3 : Colors.white10,
                  width: 1,
                ),
              ),
              child: Icon(
                s.$2,
                size: 14,
                color: isSelected ? s.$3 : Colors.white24,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTyreColor(TyreCompound tc) {
    switch (tc) {
      case TyreCompound.soft:
        return Colors.redAccent;
      case TyreCompound.medium:
        return Colors.yellowAccent;
      case TyreCompound.hard:
        return Colors.white70;
      case TyreCompound.wet:
        return Colors.blueAccent;
    }
  }

  Widget _buildQualifyingGrid() {
    if (_qualyGrid.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          "Qualifying data not available yet.",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final theme = Theme.of(context);
    final highlightIndices = <int>[];

    final rows = List.generate(_qualyGrid.length, (index) {
      final row = _qualyGrid[index];
      final isMyTeam = row['teamId'] == widget.teamId;
      final isCrashed = row['isCrashed'] == true;
      final compoundString = row['tyreCompound'] as String? ?? 'medium';
      final compound = TyreCompound.values.firstWhere(
        (c) => c.name == compoundString,
        orElse: () => TyreCompound.medium,
      );

      if (isMyTeam) highlightIndices.add(index);

      // Pos, Driver, Team, Gap, Tyre
      final pos = "P${row['position'] ?? (index + 1)}";

      final driverContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            row['driverName'] ?? 'Unknown',
            style: TextStyle(
              fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
              color: isCrashed ? Colors.redAccent : Colors.white,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            row['teamName'] ?? 'Unknown',
            style: const TextStyle(fontSize: 10, color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

      final gapString = isCrashed
          ? 'DNF'
          : (index == 0
                ? _formatTime(row['lapTime'] ?? 0)
                : "+${(row['gap'] ?? 0.0).toStringAsFixed(3)}s");

      final tyreContent = Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _getTyreColor(compound)),
        ),
        child: Text(
          compound.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: _getTyreColor(compound),
          ),
        ),
      );

      return [
        pos,
        driverContent,
        WidgetSpan(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              gapString,
              style: TextStyle(
                fontFamily: 'monospace',
                color: isCrashed ? Colors.redAccent : Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Align(alignment: Alignment.center, child: tyreContent),
        ),
      ];
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "QUALIFYING RESULTS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Onyx background
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: OnyxTable(
              columns: const ['Pos', 'Driver', 'Gap', 'Tyre'],
              flexValues: const [1, 3, 2, 1],
              rows: rows,
              highlightIndices: highlightIndices,
              shrinkWrap: true,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(double seconds) {
    if (seconds <= 0) return "0:00.000";
    int min = seconds ~/ 60;
    double sec = seconds % 60;
    return "$min:${sec.toStringAsFixed(3).padLeft(6, '0')}";
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.privacy_tip, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSubmitted ? "STRATEGY LOCKED" : "DEFINE RACE SETUP",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loadInitialData,
                    tooltip: "Reload Data",
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isSubmitted
                  ? "Your race strategy and driving styles are locked in for the upcoming event."
                  : "Configure your complete race strategy: define starting tyres, fuel loads, and driving aggression for the start and every scheduled pit stop.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircuitCharacteristics(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildDriverSelectorTabs(ThemeData theme) {
    return Container(
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
              if (selected) {
                setState(() => _selectedDriverId = driver.id);
              }
            },
            selectedColor: theme.colorScheme.secondary,
            backgroundColor: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarConfiguration(CarSetup currentSetup, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CAR CONFIGURATION",
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          "Front Wing",
          currentSetup.frontWing,
          (v) => setState(() => currentSetup.frontWing = v),
        ),
        _buildSlider(
          "Rear Wing",
          currentSetup.rearWing,
          (v) => setState(() => currentSetup.rearWing = v),
        ),
        _buildSlider(
          "Suspension",
          currentSetup.suspension,
          (v) => setState(() => currentSetup.suspension = v),
        ),
        _buildSlider(
          "Gear Ratio",
          currentSetup.gearRatio,
          (v) => setState(() => currentSetup.gearRatio = v),
        ),
      ],
    );
  }

  Widget _buildStrategyAndPitStops(CarSetup currentSetup, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STRATEGY & PIT STOPS",
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // RACE START
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 70,
                child: Text(
                  "START",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white54,
                  ),
                ),
              ),
              // Tyre choices for Start
              Row(
                children: TyreCompound.values.map((tc) {
                  final isSelected = currentSetup.tyreCompound == tc;
                  final tcColor = _getTyreColor(tc);
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tcColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? tcColor : Colors.white10,
                      ),
                    ),
                    child: Text(
                      tc.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? tcColor : Colors.white24,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 12),
              FuelInput(
                value: currentSetup.initialFuel,
                onChanged: (v) => setState(() => currentSetup.initialFuel = v),
                enabled: !_isSubmitted,
              ),
              const SizedBox(width: 12),
              _buildStyleSelector(
                currentSetup.raceStyle,
                (s) => setState(() => currentSetup.raceStyle = s),
              ),
              const SizedBox(width: 8),
              const Tooltip(
                message:
                    "REGULATION: Start tyres are fixed. Drivers must start on the same compound used for their best qualifying lap.",
                child: Icon(
                  Icons.lock_outline,
                  size: 10,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // PIT STOPS
        ...List.generate(currentSetup.pitStops.length, (idx) {
          final stopTyre = currentSetup.pitStops[idx];
          final stopFuel = currentSetup.pitStopFuel[idx];
          final stopStyle = currentSetup.pitStopStyles.length > idx
              ? currentSetup.pitStopStyles[idx]
              : DriverStyle.normal;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    "STOP ${idx + 1}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white38,
                    ),
                  ),
                ),
                // Tyre choices for the stop
                Row(
                  children: TyreCompound.values.map((tc) {
                    final isSelected = stopTyre == tc;
                    final tcColor = _getTyreColor(tc);
                    return GestureDetector(
                      onTap: _isSubmitted
                          ? null
                          : () => setState(() {
                              currentSetup.pitStops[idx] = tc;
                            }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tcColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? tcColor : Colors.white10,
                          ),
                        ),
                        child: Text(
                          tc.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? tcColor : Colors.white24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 12),
                FuelInput(
                  value: stopFuel,
                  onChanged: (v) =>
                      setState(() => currentSetup.pitStopFuel[idx] = v),
                  enabled: !_isSubmitted,
                ),
                const SizedBox(width: 12),
                _buildStyleSelector(
                  stopStyle,
                  (s) => setState(() {
                    if (currentSetup.pitStopStyles.length > idx) {
                      currentSetup.pitStopStyles[idx] = s;
                    } else {
                      while (currentSetup.pitStopStyles.length <= idx) {
                        currentSetup.pitStopStyles.add(DriverStyle.normal);
                      }
                      currentSetup.pitStopStyles[idx] = s;
                    }
                  }),
                ),
                const SizedBox(width: 8),
                const Tooltip(
                  message:
                      "Strategy for this stint. Define tyres, fuel refill amount and driving style for the next stint.",
                  child: Icon(
                    Icons.lock_outline,
                    size: 10,
                    color: Colors.orangeAccent,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _isSubmitted
                      ? null
                      : () => setState(() {
                          currentSetup.pitStops.removeAt(idx);
                          currentSetup.pitStopFuel.removeAt(idx);
                          currentSetup.pitStopStyles.removeAt(idx);
                        }),
                ),
              ],
            ),
          );
        }),

        if (!_isSubmitted && currentSetup.pitStops.length < 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                currentSetup.pitStops.add(TyreCompound.hard);
                currentSetup.pitStopFuel.add(50.0);
                currentSetup.pitStopStyles.add(DriverStyle.normal);
              }),
              icon: const Icon(Icons.add, size: 14),
              label: const Text("ADD PIT STOP", style: TextStyle(fontSize: 10)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 32),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
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
          _isSubmitted ? "STRATEGY SUBMITTED" : "SUBMIT TEAM STRATEGY (ALL)",
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: _isSubmitted ? Colors.grey : theme.primaryColor,
          foregroundColor: theme.colorScheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN
            Expanded(flex: 5, child: _buildQualifyingGrid()),
            const SizedBox(width: 32),
            // RIGHT COLUMN
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(theme),
                  const SizedBox(height: 24),

                  if (_circuit != null) ...[
                    _buildCircuitCharacteristics(theme),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    "CONFIGURE DRIVER:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_drivers.isNotEmpty) _buildDriverSelectorTabs(theme),

                  if (currentSetup != null) ...[
                    _buildCarConfiguration(currentSetup, theme),
                    const SizedBox(height: 32),
                    _buildStrategyAndPitStops(currentSetup, theme),
                  ],

                  const SizedBox(height: 32),
                  _buildSubmitButton(theme),
                  const SizedBox(height: 32),
                ],
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
