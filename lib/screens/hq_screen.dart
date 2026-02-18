import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/core_models.dart';
import '../services/facility_service.dart';
import '../services/finance_service.dart';
import '../widgets/common/instruction_card.dart';
import 'standings_screen.dart';

class HQScreen extends StatefulWidget {
  final String teamId;

  const HQScreen({super.key, required this.teamId});

  @override
  State<HQScreen> createState() => _HQScreenState();
}

class _HQScreenState extends State<HQScreen> {
  @override
  void initState() {
    super.initState();
    FacilityService().ensureBaseFacilities(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.hqTitle.toUpperCase(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.orangeAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StandingsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final team = Team.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
          );
          final budgetM = (team.budget / 1000000).toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Instruction Card with Budget
                InstructionCard(
                  icon: Icons.business_center_rounded,
                  title: "HEADQUARTERS",
                  description:
                      "Buy and upgrade facilities to unlock powerful benefits and strategic advantages for your team. Be mindful of your investments, as advanced facilities will incur weekly maintenance costs as your empire grows.",
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
                            "${l10n.currencySymbol} $budgetM M",
                            style: GoogleFonts.poppins(
                              color: theme.colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  "FACILITIES",
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: screenWidth > 900
                      ? 4
                      : (screenWidth > 600 ? 3 : 2),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.0,
                  children: [
                    _FacilityCard(
                      facility:
                          team.facilities[FacilityType.teamOffice.name] ??
                          Facility(type: FacilityType.teamOffice, level: 1),
                      teamId: widget.teamId,
                      canUpgrade: false,
                    ),
                    _FacilityCard(
                      facility:
                          team.facilities[FacilityType.garage.name] ??
                          Facility(type: FacilityType.garage, level: 1),
                      teamId: widget.teamId,
                      canUpgrade: false,
                    ),
                    _FacilityCard(
                      facility:
                          team.facilities[FacilityType.youthAcademy.name] ??
                          Facility(type: FacilityType.youthAcademy, level: 0),
                      teamId: widget.teamId,
                      canUpgrade: true,
                    ),
                    _FacilityCard(
                      facility: Facility(type: FacilityType.pressRoom),
                      teamId: widget.teamId,
                      canUpgrade: false,
                    ),
                    _FacilityCard(
                      facility: Facility(type: FacilityType.scoutingOffice),
                      teamId: widget.teamId,
                      canUpgrade: false,
                    ),
                    _FacilityCard(
                      facility: Facility(type: FacilityType.racingSimulator),
                      teamId: widget.teamId,
                      canUpgrade: false,
                    ),
                    _FacilityCard(
                      facility: Facility(type: FacilityType.gym),
                      teamId: widget.teamId,
                      canUpgrade: false,
                    ),
                    _FacilityCard(
                      facility: Facility(type: FacilityType.rdOffice),
                      teamId: widget.teamId,
                      canUpgrade: false,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  final String teamId;
  final bool canUpgrade;

  const _FacilityCard({
    required this.facility,
    required this.teamId,
    required this.canUpgrade,
  });

  IconData _getIcon() {
    switch (facility.type) {
      case FacilityType.teamOffice:
        return Icons.corporate_fare_rounded;
      case FacilityType.garage:
        return Icons.directions_car_filled_rounded;
      case FacilityType.youthAcademy:
        return Icons.school_rounded;
      case FacilityType.pressRoom:
        return Icons.mic_external_on_rounded;
      case FacilityType.scoutingOffice:
        return Icons.search_rounded;
      case FacilityType.racingSimulator:
        return Icons.videogame_asset_rounded;
      case FacilityType.gym:
        return Icons.fitness_center_rounded;
      case FacilityType.rdOffice:
        return Icons.biotech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSoon = facility.isSoon;
    final isMaxLevel = facility.level >= 5;
    final isPurchased = facility.level > 0;
    final isEnabled = !isSoon;

    final nextLevelPrice = FinanceService().formatCompactCurrency(
      facility.level == 0 ? 100000 : facility.upgradePrice,
    );
    final maintenancePrice = FinanceService().formatCompactCurrency(
      facility.maintenanceCost,
    );

    return Stack(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: isEnabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isEnabled
              ? theme.cardTheme.color
              : theme.cardTheme.color?.withValues(alpha: 0.5),
          child: InkWell(
            onTap: isSoon ? null : () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isPurchased && !isSoon) ...[
                    Text(
                      "LEVEL ${facility.level}",
                      style: GoogleFonts.raleway(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      thickness: 0.5,
                      height: 12,
                    ),
                  ],
                  Icon(
                    _getIcon(),
                    size: isPurchased ? 34 : 40,
                    color: isEnabled
                        ? theme.colorScheme.secondary
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    facility.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isEnabled ? Colors.white : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (isEnabled) ...[
                    // Separator
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      thickness: 0.5,
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMaxLevel && canUpgrade)
                                _DetailRow(
                                  label: "Next level:",
                                  value: nextLevelPrice,
                                ),
                              _DetailRow(
                                label: "Maint cost:",
                                value: maintenancePrice,
                                isMuted: true,
                              ),
                              _DetailRow(
                                label: "Bonus:",
                                value: facility.bonusDescription,
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canUpgrade && !isMaxLevel)
                          ElevatedButton(
                            onPressed: () => _handleUpgrade(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              isPurchased ? "UPGRADE" : "BUY",
                              style: GoogleFonts.raleway(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (isSoon)
          Positioned(
            top: 10,
            right: -25,
            child: Transform.rotate(
              angle: 0.785, // 45 degrees
              child: Container(
                width: 100,
                color: Colors.redAccent.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text(
                  'SOON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleUpgrade(BuildContext context) async {
    try {
      await FacilityService().upgradeFacility(teamId, facility.type);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${facility.name} improved!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMuted;
  final Color? color;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isMuted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.raleway(
            fontSize: 8.5,
            color: isMuted
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
          ),
          children: [
            TextSpan(text: "$label "),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    color ??
                    (isMuted
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
