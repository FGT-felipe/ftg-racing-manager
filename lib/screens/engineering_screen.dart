import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/core_models.dart';
import '../models/user_models.dart';
import '../services/car_service.dart';
import '../services/driver_assignment_service.dart';
import '../widgets/car_schematic_widget.dart';
import '../widgets/common/instruction_card.dart';
import '../services/driver_portrait_service.dart';

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
                    title: l10n.garageTitle.toUpperCase(),
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
                              l10n.upgradeLimitReached,
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
                          carLabel: l10n.carLabelA,
                          driver: driverA,
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
                          carLabel: l10n.carLabelB,
                          driver: driverB,
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
  final Driver? driver;
  final int carIndex;
  final Map<String, int> stats;
  final String teamId;
  final int currentBudget;
  final bool hasUpgradedThisWeek;
  final ManagerRole? managerRole;

  const _CarUpgradesColumn({
    required this.carLabel,
    required this.driver,
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
        Text(
          carLabel,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: CarSchematicWidget(
                stats: stats,
                carLabel: l10n.carPerformanceTitle(carLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: _DriverSmallCard(driver: driver)),
          ],
        ),

        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: [
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
            _UpgradeTile(
              title: l10n.chassisPart,
              partKey: 'chassis',
              carIndex: carIndex,
              level: stats['chassis'] ?? 1,
              currentBudget: currentBudget,
              teamId: teamId,
              isDisabled: hasUpgradedThisWeek,
              managerRole: managerRole,
            ),
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
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "L${widget.level}",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (widget.level / 20).clamp(0.0, 1.0),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            color: Theme.of(context).primaryColor,
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.costLabel(l10n.currencySymbol, costFormatted),
                style: TextStyle(
                  color: canAfford
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : (isMaxed ? Colors.green : Colors.redAccent),
                  fontSize: 10,
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

class _DriverSmallCard extends StatelessWidget {
  final Driver? driver;

  const _DriverSmallCard({this.driver});

  @override
  Widget build(BuildContext context) {
    if (driver == null) {
      return Container(
        height: 154, // Match CarSchematicWidget roughly
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          color: Colors.white.withValues(alpha: 0.02),
        ),
        child: const Center(
          child: Icon(
            Icons.person_off_rounded,
            color: Colors.white24,
            size: 32,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final portraitUrl =
        driver!.portraitUrl ??
        DriverPortraitService().getEffectivePortraitUrl(
          driverId: driver!.id,
          countryCode: driver!.countryCode,
          gender: driver!.gender,
          age: driver!.age,
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              image: DecorationImage(
                image: portraitUrl.startsWith('http')
                    ? NetworkImage(portraitUrl) as ImageProvider
                    : AssetImage(portraitUrl),
                fit: BoxFit.cover,
                onError: (e, s) => debugPrint('Error $e'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            driver!.name.split(' ').first,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            driver!.name.split(' ').length > 1
                ? driver!.name.split(' ').last
                : '',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getFlagEmoji(driver!.countryCode),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                "L${(driver!.stats[DriverStats.consistency] ?? 0) ~/ 5}",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🏁';
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
