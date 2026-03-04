import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/core_models.dart';
import '../../services/driver_assignment_service.dart';
import '../../services/driver_name_service.dart';
import '../../utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/instruction_card.dart';

class FitnessTrainerScreen extends StatefulWidget {
  final String teamId;

  const FitnessTrainerScreen({super.key, required this.teamId});

  @override
  State<FitnessTrainerScreen> createState() => _FitnessTrainerScreenState();
}

class _FitnessTrainerScreenState extends State<FitnessTrainerScreen> {
  bool _isLoading = true;
  String? _trainerName;
  String? _trainerCountry;
  int _trainerLevel = 1;

  String? _selectedPilotId;
  String? _currentlyAssignedPilotId;

  bool _hasUpgradedThisWeek = false;
  bool _hasTrainedThisWeek = false;

  List<Driver> _teamDrivers = [];

  final List<int> _salaryByLevel = [0, 0, 50000, 120000, 250000, 500000];
  final List<int> _bonusByLevel = [0, 3, 6, 9, 12, 15];
  final List<int> _upgradeCosts = [0, 0, 100000, 250000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final drivers = await DriverAssignmentService().getDriversByTeam(
        widget.teamId,
      );
      final activeDrivers = drivers
          .where((d) => !d.statusTitle.contains('Academy'))
          .toList();

      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId);
      final teamDoc = await teamRef.get();

      String trainerName;
      String trainerCountry;
      int trainerLvl = 1;
      bool upgradedWeek = false;
      bool trainedWeek = false;
      String? assignedId;

      bool nameWasGenerated = false;

      if (teamDoc.exists && teamDoc.data()!.containsKey('weekStatus')) {
        final weekStatus =
            teamDoc.data()!['weekStatus'] as Map<String, dynamic>;

        if (weekStatus['fitnessTrainerName'] != null) {
          trainerName = weekStatus['fitnessTrainerName'];
          trainerCountry = weekStatus['fitnessTrainerCountry'] ?? 'GB';
        } else {
          trainerName = DriverNameService().generateName(
            gender: 'M',
            countryCode: 'GB',
          );
          trainerCountry = 'GB';
          nameWasGenerated = true;
        }

        trainerLvl = weekStatus['fitnessTrainerLevel'] ?? 1;
        assignedId = weekStatus['fitnessTrainerAssignedTo'];
        upgradedWeek = weekStatus['fitnessTrainerUpgradedThisWeek'] ?? false;
        trainedWeek = weekStatus['fitnessTrainerTrainedThisWeek'] ?? false;
      } else {
        trainerName = DriverNameService().generateName(
          gender: 'M',
          countryCode: 'GB',
        );
        trainerCountry = 'GB';
        nameWasGenerated = true;
      }

      if (nameWasGenerated) {
        teamRef.set({
          'weekStatus': {
            'fitnessTrainerName': trainerName,
            'fitnessTrainerCountry': trainerCountry,
          },
        }, SetOptions(merge: true));
      }

      if (assignedId != null) {
        bool stillInTeam = activeDrivers.any((d) => d.id == assignedId);
        if (!stillInTeam) assignedId = null;
      }

      if (mounted) {
        setState(() {
          _teamDrivers = activeDrivers;
          _trainerName = trainerName;
          _trainerCountry = trainerCountry;
          _trainerLevel = trainerLvl;
          _currentlyAssignedPilotId = assignedId;
          _selectedPilotId = assignedId;
          _hasUpgradedThisWeek = upgradedWeek;
          _hasTrainedThisWeek = trainedWeek;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading Fitness Trainer: \$e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTrainerAssignment() async {
    if (_trainerName == null || _selectedPilotId == null) return;
    try {
      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId);
      await teamRef.set({
        'weekStatus': {
          'fitnessTrainerName': _trainerName,
          'fitnessTrainerCountry': _trainerCountry,
          'fitnessTrainerLevel': _trainerLevel,
          'fitnessTrainerAssignedTo': _selectedPilotId,
        },
      }, SetOptions(merge: true));

      setState(() {
        _currentlyAssignedPilotId = _selectedPilotId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Changes saved successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error al guardar entrenador: \$e");
    }
  }

  Future<void> _changeLevel(bool targetIsUpgrade) async {
    if (_hasUpgradedThisWeek) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action limited to once per week.")),
      );
      return;
    }
    int newLevel = targetIsUpgrade ? _trainerLevel + 1 : _trainerLevel - 1;
    if (newLevel < 1 || newLevel > 5) return;

    int cost = 0;
    if (targetIsUpgrade) cost = _upgradeCosts[newLevel];

    try {
      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId);

      if (targetIsUpgrade) {
        final teamDoc = await teamRef.get();
        int budget = teamDoc.data()?['budget'] ?? 0;
        if (budget < cost) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Insufficient budget to upgrade.")),
            );
          }
          return;
        }
      }

      await teamRef.set({
        if (targetIsUpgrade) 'budget': FieldValue.increment(-cost),
        'weekStatus': {
          'fitnessTrainerLevel': newLevel,
          'fitnessTrainerUpgradedThisWeek': true,
        },
      }, SetOptions(merge: true));

      setState(() {
        _trainerLevel = newLevel;
        _hasUpgradedThisWeek = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Trainer level ${targetIsUpgrade ? 'upgraded' : 'downgraded'} to $newLevel!",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error level up/down: $e");
    }
  }

  Future<void> _trainPilot() async {
    if (_currentlyAssignedPilotId == null) return;
    if (_hasTrainedThisWeek) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Training already performed this week.")),
      );
      return;
    }

    try {
      final int bonus = _bonusByLevel[_trainerLevel];

      final driverRef = FirebaseFirestore.instance
          .collection('characters')
          .doc(_currentlyAssignedPilotId);
      final driverDoc = await driverRef.get();

      if (driverDoc.exists) {
        Map<String, dynamic> stats = driverDoc.data()!['stats'] ?? {};
        int currentFit = stats['fitness'] ?? 50;
        int newFit = (currentFit + bonus).clamp(0, 100);
        stats['fitness'] = newFit;

        await driverRef.update({'stats': stats});
      }

      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId);
      await teamRef.set({
        'weekStatus': {'fitnessTrainerTrainedThisWeek': true},
      }, SetOptions(merge: true));

      setState(() {
        _hasTrainedThisWeek = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pilot recovered $bonus% of fitness!")),
        );
      }
    } catch (e) {
      debugPrint("Error on trainPilot(): $e");
    }
  }

  String _getFlagEmoji(String countryCode) {
    final map = {
      'BR': '🇧🇷',
      'AR': '🇦🇷',
      'CO': '🇨🇴',
      'MX': '🇲🇽',
      'ES': '🇪🇸',
      'US': '🇺🇸',
      'GB': '🇬🇧',
      'FR': '🇫🇷',
      'DE': '🇩🇪',
      'IT': '🇮🇹',
      'JP': '🇯🇵',
    };
    return map[countryCode.toUpperCase()] ?? '🏁';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  InstructionCard(
                    icon: Icons.fitness_center_rounded,
                    title: "Fitness Trainer",
                    description:
                        "The Fitness Trainer helps your pilots recover from fatigue.\n\n"
                        "• **Weekly Bonus**: Higher level trainers provide a larger automatic fitness recovery each week.\n"
                        "• **Train Pilot**: Use manual training once per week to give an extra boost to your assigned pilot.\n"
                        "• **Assignment**: Ensure the trainer is assigned to a pilot to apply the recovery bonus.\n"
                        "• **Training Limit**: You can only train **1 pilot per week**. Once trained, the assignment is locked until next week.\n"
                        "• **Upgrade/Downgrade**: You may only upgrade or downgrade the trainer **once per week**.",
                  ),
                  const SizedBox(height: 24),
                  _buildTrainerCard(context, l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildTrainerCard(BuildContext context, AppLocalizations l10n) {
    String levelText;
    Color levelColor;
    if (_trainerLevel >= 5) {
      levelText = "ELITE";
      levelColor = const Color(0xFF00E676);
    } else if (_trainerLevel >= 3) {
      levelText = "PRO";
      levelColor = const Color(0xFFFFEE58);
    } else {
      levelText = "AMATEUR";
      levelColor = const Color(0xFFA0AEC0);
    }

    final avatarUrl = 'staff/fitness_trainer.png';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Head Profile Section
            Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: levelColor.withOpacity(0.5),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: levelColor.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage(avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getFlagEmoji(_trainerCountry ?? 'GB'),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: levelColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: levelColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              "${levelText} - LVL $_trainerLevel",
                              style: GoogleFonts.montserrat(
                                color: levelColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _trainerName?.toUpperCase() ?? 'TRAINER',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Recovery Bonus: +${_bonusByLevel[_trainerLevel]}%",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // Contract / Salary Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "WEEKLY CONTRACT COST",
                  style: GoogleFonts.montserrat(
                    color: Colors.white38,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  _salaryByLevel[_trainerLevel] == 0
                      ? "FREE"
                      : CurrencyFormatter.format(_salaryByLevel[_trainerLevel]),
                  style: GoogleFonts.robotoMono(
                    color: _salaryByLevel[_trainerLevel] == 0
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Assignment
            Text(
              "ASSIGNED TO PILOT",
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPilotId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E1E2A),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        onChanged: _hasTrainedThisWeek
                            ? null
                            : (String? newValue) {
                                setState(() {
                                  _selectedPilotId = newValue;
                                });
                              },
                        items: _teamDrivers.map<DropdownMenuItem<String>>((
                          Driver driver,
                        ) {
                          return DropdownMenuItem<String>(
                            value: driver.id,
                            child: Text(driver.name),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (_selectedPilotId != null &&
                    _selectedPilotId != _currentlyAssignedPilotId) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveTrainerAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // Interaction Buttons
            Row(
              children: [
                if (_trainerLevel > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: _hasUpgradedThisWeek
                          ? null
                          : () => _changeLevel(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      child: const Icon(Icons.arrow_downward, size: 18),
                    ),
                  ),

                if (_trainerLevel < 5)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _hasUpgradedThisWeek
                          ? null
                          : () => _changeLevel(true),
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: Text(
                        "UPGRADE (${CurrencyFormatter.format(_upgradeCosts[_trainerLevel + 1])})",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _currentlyAssignedPilotId == null || _hasTrainedThisWeek
                        ? null
                        : _trainPilot,
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text("TRAIN PILOT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107), // Amber
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
}
