import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/core_models.dart';
import '../models/user_models.dart';
import '../services/car_service.dart';
import '../services/driver_assignment_service.dart';
import '../widgets/car_schematic_widget.dart';
import '../widgets/common/instruction_card.dart';

class EngineeringScreen extends StatefulWidget {
  final String teamId;

  const EngineeringScreen({super.key, required this.teamId});

  @override
  State<EngineeringScreen> createState() => _EngineeringScreenState();
}

class _EngineeringScreenState extends State<EngineeringScreen> {
  ManagerRole? _managerRole;

  @override
  void initState() {
    super.initState();
    _loadManagerRole();
  }

  Future<void> _loadManagerRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('managers')
        .doc(uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        final profile = ManagerProfile.fromMap(doc.data()!);
        _managerRole = profile.role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .snapshots(),
      builder: (context, teamSnapshot) {
        if (teamSnapshot.hasError) {
          return Center(child: Text("Error: ${teamSnapshot.error}"));
        }
        if (teamSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = teamSnapshot.data!.data() as Map<String, dynamic>;
        final team = Team.fromMap(data);
        final budgetM = (team.budget / 1000000).toStringAsFixed(1);

        // Ex-Engineer can upgrade 2/week, else 1
        final int upgradeCount =
            (team.weekStatus['upgradesThisWeek'] as int?) ?? 0;
        final int maxUpgrades = _managerRole == ManagerRole.exEngineer ? 2 : 1;
        final bool hasUpgraded = upgradeCount >= maxUpgrades;

        // Bureaucrat cooldown
        final int cooldownLeft =
            (team.weekStatus['upgradeCooldownWeeksLeft'] as int?) ?? 0;
        final bool isCooldown =
            _managerRole == ManagerRole.bureaucrat && cooldownLeft > 0;

        return FutureBuilder<List<Driver>>(
          future: DriverAssignmentService().getDriversByTeam(widget.teamId),
          builder: (context, driverSnapshot) {
            final drivers = driverSnapshot.data ?? [];
            final driverA = drivers.where((d) => d.carIndex == 0).firstOrNull;
            final driverB = drivers.where((d) => d.carIndex == 1).firstOrNull;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // R&D Lab Info Header (Shared Instruction Card)
                  InstructionCard(
                    icon: Icons.biotech_rounded,
                    title: "GARAGE",
                    description: l10n.engineeringDescription,
                    extraContent: Column(
                      children: [
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.budgetLabel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              "${l10n.currencySymbol}$budgetM${l10n.millionsSuffix}",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (hasUpgraded)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.orangeAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Weekly upgrade limit reached. Wait for the next race to upgrade again.",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CarUpgradesColumn(
                          carLabel: "CAR A",
                          driverName: driverA?.name ?? l10n.noDriverAssigned,
                          carIndex: 0,
                          stats:
                              team.carStats['0'] ??
                              {
                                'aero': 1,
                                'powertrain': 1,
                                'chassis': 1,
                                'reliability': 1,
                              },
                          teamId: team.id,
                          currentBudget: team.budget,
                          hasUpgradedThisWeek: hasUpgraded || isCooldown,
                          managerRole: _managerRole,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _CarUpgradesColumn(
                          carLabel: "CAR B",
                          driverName: driverB?.name ?? l10n.noDriverAssigned,
                          carIndex: 1,
                          stats:
                              team.carStats['1'] ??
                              {
                                'aero': 1,
                                'powertrain': 1,
                                'chassis': 1,
                                'reliability': 1,
                              },
                          teamId: team.id,
                          currentBudget: team.budget,
                          hasUpgradedThisWeek: hasUpgraded || isCooldown,
                          managerRole: _managerRole,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CarUpgradesColumn extends StatelessWidget {
  final String carLabel;
  final String driverName;
  final int carIndex;
  final Map<String, int> stats;
  final String teamId;
  final int currentBudget;
  final bool hasUpgradedThisWeek;
  final ManagerRole? managerRole;

  const _CarUpgradesColumn({
    required this.carLabel,
    required this.driverName,
    required this.carIndex,
    required this.stats,
    required this.teamId,
    required this.currentBudget,
    required this.hasUpgradedThisWeek,
    this.managerRole,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              carLabel,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                driverName,
                style: GoogleFonts.raleway(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: CarSchematicWidget(
            stats: stats,
            carLabel: "$carLabel PERFORMANCE",
          ),
        ),
        const SizedBox(height: 20),
        _UpgradeTile(
          title: l10n.aero,
          partKey: 'aero',
          carIndex: carIndex,
          level: stats['aero'] ?? 1,
          currentBudget: currentBudget,
          teamId: teamId,
          isDisabled: hasUpgradedThisWeek,
          managerRole: managerRole,
        ),
        const SizedBox(height: 16),
        _UpgradeTile(
          title: l10n.engine,
          partKey: 'powertrain',
          carIndex: carIndex,
          level: stats['powertrain'] ?? 1,
          currentBudget: currentBudget,
          teamId: teamId,
          isDisabled: hasUpgradedThisWeek,
          managerRole: managerRole,
        ),
        const SizedBox(height: 16),
        _UpgradeTile(
          title: "Chassis",
          partKey: 'chassis',
          carIndex: carIndex,
          level: stats['chassis'] ?? 1,
          currentBudget: currentBudget,
          teamId: teamId,
          isDisabled: hasUpgradedThisWeek,
          managerRole: managerRole,
        ),
        const SizedBox(height: 16),
        _UpgradeTile(
          title: l10n.reliability,
          partKey: 'reliability',
          carIndex: carIndex,
          level: stats['reliability'] ?? 1,
          currentBudget: currentBudget,
          teamId: teamId,
          isDisabled: hasUpgradedThisWeek,
          managerRole: managerRole,
        ),
      ],
    );
  }
}

class _UpgradeTile extends StatefulWidget {
  final String title;
  final String partKey;
  final int carIndex;
  final int level;
  final int currentBudget;
  final String teamId;
  final bool isDisabled;
  final ManagerRole? managerRole;

  const _UpgradeTile({
    required this.title,
    required this.partKey,
    required this.carIndex,
    required this.level,
    required this.currentBudget,
    required this.teamId,
    this.isDisabled = false,
    this.managerRole,
  });

  @override
  State<_UpgradeTile> createState() => _UpgradeTileState();
}

class _UpgradeTileState extends State<_UpgradeTile> {
  bool _isUpgrading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cost = CarService().getUpgradeCost(
      widget.level,
      role: widget.managerRole,
    );
    final canAfford = widget.currentBudget >= cost;
    final isMaxed = widget.level >= 20;

    // Check if playable
    final canUpgrade = canAfford && !widget.isDisabled && !isMaxed;

    // Formatting cost nicely (e.g. $100k, $1.1M)
    String costFormatted;
    if (cost >= 1000000) {
      costFormatted =
          "${(cost / 1000000).toStringAsFixed(1)}${l10n.millionsSuffix}";
    } else {
      costFormatted = "${(cost / 1000).toStringAsFixed(0)}k";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "L${widget.level}",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (widget.level / 20).clamp(0.0, 1.0),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            color: Theme.of(context).primaryColor,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.costLabel(l10n.currencySymbol, costFormatted),
                style: TextStyle(
                  color: canAfford
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : (isMaxed ? Colors.green : Colors.redAccent),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (canUpgrade && !_isUpgrading)
                      ? () async {
                          setState(() => _isUpgrading = true);
                          try {
                            await CarService().upgradePart(
                              teamId: widget.teamId,
                              carIndex: widget.carIndex,
                              partKey: widget.partKey,
                              currentLevel: widget.level,
                              currentBudget: widget.currentBudget,
                              role: widget.managerRole,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isUpgrading = false);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: _isUpgrading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          l10n.upgradeBtn.toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
