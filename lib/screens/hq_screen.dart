import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/core_models.dart';
import '../services/facility_service.dart';
import '../services/finance_service.dart';
import '../widgets/common/instruction_card.dart';

class HQScreen extends StatefulWidget {
  final String teamId;
  final Function(String)? onNavigate;

  const HQScreen({super.key, required this.teamId, this.onNavigate});

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
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 0, // Minimal height as info is in the body
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

          // Build a full list of facilities based on the enum to ensure all are shown
          final allFacilities = FacilityType.values.map((type) {
            return team.facilities[type.name] ?? Facility(type: type);
          }).toList();

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
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Facilities Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 1200 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio:
                        1.85, // More compact to reduce empty space
                  ),
                  itemCount: allFacilities.length,
                  itemBuilder: (context, index) {
                    final facility = allFacilities[index];
                    return _FacilityCard(
                      facility: facility,
                      teamId: widget.teamId,
                      canUpgrade: true,
                      onNavigate: widget.onNavigate,
                    );
                  },
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
  final Function(String)? onNavigate;

  const _FacilityCard({
    required this.facility,
    required this.teamId,
    required this.canUpgrade,
    this.onNavigate,
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

  void _onCardTap() {
    if (onNavigate == null || facility.isSoon || facility.level == 0) return;

    switch (facility.type) {
      case FacilityType.teamOffice:
        onNavigate!('hq_office');
        break;
      case FacilityType.garage:
        onNavigate!('hq_garage');
        break;
      case FacilityType.youthAcademy:
        onNavigate!('hq_academy');
        break;
      default:
        // Other facilities don't have dedicated screens yet
        break;
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
        Container(
          width: double.infinity,
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
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isSoon ? null : _onCardTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isPurchased && !isSoon) ...[
                      Text(
                        "LEVEL ${facility.level}",
                        style: GoogleFonts.raleway(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.secondary,
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
                        fontSize: 15,
                        color: isEnabled ? Colors.white : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        facility.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? Colors.white70
                              : Colors.white.withValues(alpha: 0.3),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                                  color: theme.colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),
                          if (canUpgrade && !isMaxLevel)
                            TextButton(
                              onPressed: () => _handleUpgrade(context),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF141414),
                                foregroundColor: theme.colorScheme.secondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 11,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const StadiumBorder(
                                  side: BorderSide(
                                    color: Color(
                                      0x4D00C853,
                                    ), // 30% Success Green
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                isPurchased ? "UPGRADE" : "BUY",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 48),
                    ],
                  ],
                ),
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
                  'COMING SOON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7, // Smaller font for ribbon
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
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
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.raleway(
            fontSize: 11.5,
            color: isMuted
                ? Colors.white.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.75),
          ),
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    color ??
                    (isMuted
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
