import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/user_models.dart';
import '../../services/sponsor_service.dart';
import '../../services/auth_service.dart';
import '../../services/finance_service.dart';
import '../../utils/responsive_layout.dart';
import '../../l10n/app_localizations.dart';

class SponsorshipScreen extends StatefulWidget {
  final String teamId;

  const SponsorshipScreen({super.key, required this.teamId});

  @override
  State<SponsorshipScreen> createState() => _SponsorshipScreenState();
}

class _SponsorshipScreenState extends State<SponsorshipScreen> {
  final SponsorService _sponsorService = SponsorService();
  final FinanceService _financeService = FinanceService();

  // Desktop State
  SponsorSlot? _selectedSlotDesktop;
  List<SponsorOffer>? _desktopOffers;

  late Future<DocumentSnapshot> _managerFuture;

  @override
  void initState() {
    super.initState();
    _managerFuture = FirebaseFirestore.instance
        .collection('managers')
        .doc(AuthService().currentUser?.uid)
        .get();
  }

  void _showSponsorCarouselMobile(
    BuildContext context,
    SponsorSlot slot,
    ManagerRole role,
  ) {
    final offers = _sponsorService.getAvailableSponsors(
      slot,
      role,
    ); // Passed role

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return _SponsorCarouselModal(
          teamId: widget.teamId,
          slot: slot,
          offers: offers,
          role: role,
          sponsorService: _sponsorService,
          financeService: _financeService,
          onComplete: () => setState(() {}),
        );
      },
    );
  }

  void _selectSlotDesktop(SponsorSlot slot, ManagerRole role) {
    setState(() {
      _selectedSlotDesktop = slot;
      _desktopOffers = _sponsorService.getAvailableSponsors(slot, role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _managerFuture,
      builder: (context, managerSnapshot) {
        if (!managerSnapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        final managerData =
            managerSnapshot.data!.data() as Map<String, dynamic>?;
        final profile = ManagerProfile.fromMap(managerData ?? {});
        final managerRole = profile.role;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .snapshots(),
          builder: (context, teamSnapshot) {
            if (!teamSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              );
            }

            final teamData = teamSnapshot.data!.data() as Map<String, dynamic>?;
            final team = Team.fromMap(teamData ?? {});

            return ResponsiveLayout(
              mobileBody: _buildMobileLayout(team, managerRole),
              desktopBody: _buildDesktopLayout(team, managerRole),
            );
          },
        );
      },
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(Team team, ManagerRole role) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNegotiationLegend(),
          const SizedBox(height: 32),
          _buildCarVisualization(team, role, isDesktop: false),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Team team, ManagerRole role) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNegotiationLegend(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Car Visualization (30%)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildCarVisualization(team, role, isDesktop: true),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Side: Details / Offers (70%)
              Expanded(flex: 7, child: _buildDesktopRightPanel(team, role)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRightPanel(Team team, ManagerRole role) {
    if (_selectedSlotDesktop == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).selectCarPartToManage,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
      );
    }

    final slotName = _selectedSlotDesktop!.name;
    final activeContract = team.sponsors[slotName];

    if (activeContract != null) {
      // Show Active Contract Details
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            ).activeContractTitle(_selectedSlotDesktop!.name.toUpperCase()),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.verified,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  activeContract.sponsorName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailItem(
                      label: AppLocalizations.of(context).weeklyPayLabel,
                      value: _financeService.formatCurrency(
                        activeContract.weeklyBasePayment,
                      ),
                    ),
                    _DetailItem(
                      label: AppLocalizations.of(context).racesLeftLabel,
                      value: "${activeContract.racesRemaining}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Show Offers Grid
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            ).availableOffersTitle(_selectedSlotDesktop!.name.toUpperCase()),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // Desktop: 1 sponsor per row (100% width)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _desktopOffers?.length ?? 0,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _SponsorOfferCard(
                offer: _desktopOffers![index],
                teamId: widget.teamId,
                slot: _selectedSlotDesktop!,
                role: role, // Use the actual role passed to the layout
                sponsorService: _sponsorService,
                financeService: _financeService,
                onNegotiationComplete: () => setState(() {}),
                isDesktop: true,
              );
            },
          ),
        ],
      );
    }
  }

  // --- SHARED WIDGETS ---

  Widget _buildCarVisualization(
    Team team,
    ManagerRole role, {
    required bool isDesktop,
  }) {
    return Column(
      children: [
        _buildSlotItem(
          AppLocalizations.of(context).rearWingPart,
          SponsorSlot.rearWing,
          team.sponsors[SponsorSlot.rearWing.name],
          role,
          Colors.orangeAccent,
          isDesktop,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSlotItem(
                AppLocalizations.of(context).sidepodLPart,
                SponsorSlot.sidepods,
                team.sponsors[SponsorSlot.sidepods.name],
                role,
                Colors.blueAccent,
                isDesktop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSlotItem(
                AppLocalizations.of(context).sidepodRPart,
                SponsorSlot.sidepods,
                team.sponsors[SponsorSlot.sidepods.name],
                role,
                Colors.blueAccent,
                isDesktop,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSlotItem(
          AppLocalizations.of(context).haloPart,
          SponsorSlot.halo,
          team.sponsors[SponsorSlot.halo.name],
          role,
          Colors.grey,
          isDesktop,
        ),
        const SizedBox(height: 12),
        _buildSlotItem(
          AppLocalizations.of(context).frontWingPart,
          SponsorSlot.frontWing,
          team.sponsors[SponsorSlot.frontWing.name],
          role,
          Theme.of(context).colorScheme.secondary,
          isDesktop,
        ),
        const SizedBox(height: 12),
        _buildSlotItem(
          AppLocalizations.of(context).nosePart,
          SponsorSlot.nose,
          team.sponsors[SponsorSlot.nose.name],
          role,
          Theme.of(context).colorScheme.secondary,
          isDesktop,
        ),
      ],
    );
  }

  String _getSlotAsset(SponsorSlot slot) {
    switch (slot) {
      case SponsorSlot.rearWing:
        return 'blueprints/rearwing.png';
      case SponsorSlot.frontWing:
        return 'blueprints/frontwing.png';
      case SponsorSlot.sidepods:
        return 'blueprints/sidepot.png';
      case SponsorSlot.nose:
        return 'blueprints/nose.png';
      case SponsorSlot.halo:
        return 'blueprints/halo.png';
    }
  }

  Widget _buildSlotItem(
    String label,
    SponsorSlot slot,
    ActiveContract? contract,
    ManagerRole role,
    Color color,
    bool isDesktop,
  ) {
    final hasContract = contract != null;
    final isSelected = _selectedSlotDesktop == slot;
    final assetPath = _getSlotAsset(slot);

    return GestureDetector(
      onTap: () {
        if (isDesktop) {
          _selectSlotDesktop(slot, role);
        } else if (!hasContract) {
          _showSponsorCarouselMobile(context, slot, role);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: (hasContract || isSelected)
              ? color.withValues(alpha: 0.08)
              : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Blueprint Image
            Positioned(
              left: -15,
              top: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  assetPath,
                  width: 120,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: hasContract
                          ? color
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasContract
                        ? contract.sponsorName
                        : (isDesktop
                              ? AppLocalizations.of(context).manageBtn
                              : AppLocalizations.of(context).selectSponsorBtn),
                    style: TextStyle(
                      color: hasContract
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          14, // Slightly smaller to accommodate images better
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNegotiationLegend() {
    return _CommonInstructionCard(
      icon: Icons.handshake_rounded,
      title: AppLocalizations.of(context).negotiationRulesTitle,
      description: AppLocalizations.of(context).negotiationRulesDesc,
    );
  }
}

class _CommonInstructionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _CommonInstructionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              const Color(0xFF0A0A0A),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SHARED OFFER CARD Component ---
class _SponsorOfferCard extends StatefulWidget {
  final SponsorOffer offer;
  final String teamId;
  final SponsorSlot slot;
  final ManagerRole
  role; // Used only for passing to negotiate logic if needed, but buff is pre-calculated
  final SponsorService sponsorService;
  final FinanceService financeService;
  final VoidCallback onNegotiationComplete;
  final bool isDesktop;

  const _SponsorOfferCard({
    required this.offer,
    required this.teamId,
    required this.slot,
    required this.role,
    required this.sponsorService,
    required this.financeService,
    required this.onNegotiationComplete,
    this.isDesktop = false,
  });

  @override
  State<_SponsorOfferCard> createState() => _SponsorOfferCardState();
}

class _SponsorOfferCardState extends State<_SponsorOfferCard> {
  bool _isNegotiating = false;

  void _negotiate(String tactic) async {
    setState(() => _isNegotiating = true);

    final result = await widget.sponsorService.negotiate(
      teamId: widget.teamId,
      offer: widget.offer,
      tactic: tactic,
      slot: widget.slot,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.status == NegotiationStatus.success
              ? Colors.green
              : Colors.red,
        ),
      );

      setState(() => _isNegotiating = false);

      if (result.status == NegotiationStatus.success) {
        widget.onNegotiationComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked =
        widget.offer.lockedUntil != null &&
        widget.offer.lockedUntil!.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
      child: widget.isDesktop
          ? _buildHorizontalContent(isLocked)
          : _buildVerticalContent(isLocked),
    );
  }

  Widget _buildVerticalContent(bool isLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.offer.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.offer.isAdminBonusApplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "+15%",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _infoRow(
          Icons.monetization_on_outlined,
          AppLocalizations.of(context).signingBonusLabel,
          widget.financeService.formatCurrency(widget.offer.signingBonus),
          Colors.green,
        ),
        _infoRow(
          Icons.calendar_today_outlined,
          AppLocalizations.of(context).weeklyPaymentLabel,
          widget.financeService.formatCurrency(widget.offer.weeklyBasePayment),
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        _infoRow(
          Icons.timer_outlined,
          AppLocalizations.of(context).durationLabel,
          AppLocalizations.of(
            context,
          ).durationRaces(widget.offer.contractDuration.toString()),
          Colors.blue,
        ),
        _infoRow(
          Icons.emoji_events_outlined,
          AppLocalizations.of(context).objectiveLabel,
          _localizeObjective(context, widget.offer.objectiveDescription),
          Colors.orangeAccent,
        ),
        const SizedBox(height: 16),
        if (isLocked)
          Center(
            child: Text(
              AppLocalizations.of(context).suspendedStatus,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else if (_isNegotiating)
          Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.secondary,
            ),
          )
        else ...[
          Center(
            child: Text(
              AppLocalizations.of(
                context,
              ).chooseTacticLabel((2 - widget.offer.attemptsMade).toString()),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tacticBtn(
                  AppLocalizations.of(context).persuasiveTactic,
                  const Color(0xFFFF5733),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tacticBtn(
                  AppLocalizations.of(context).negotiatorTactic,
                  const Color(0xFFF1C40F),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tacticBtn(
                  AppLocalizations.of(context).collaborativeTactic,
                  const Color(0xFFE9967A),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHorizontalContent(bool isLocked) {
    return Row(
      children: [
        // Left Info Section
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.offer.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (widget.offer.isAdminBonusApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "+15%",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _infoChip(
                    Icons.monetization_on_outlined,
                    widget.financeService.formatCurrency(
                      widget.offer.signingBonus,
                    ),
                    Colors.green,
                  ),
                  _infoChip(
                    Icons.calendar_today_outlined,
                    widget.financeService.formatCurrency(
                      widget.offer.weeklyBasePayment,
                    ),
                    Colors.white.withValues(alpha: 0.7),
                  ),
                  _infoChip(
                    Icons.timer_outlined,
                    AppLocalizations.of(
                      context,
                    ).durationRaces(widget.offer.contractDuration.toString()),
                    Colors.blue,
                  ),
                  _infoChip(
                    Icons.emoji_events_outlined,
                    _localizeObjective(
                      context,
                      widget.offer.objectiveDescription,
                    ),
                    Colors.orangeAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Action Section
        Expanded(
          flex: 3,
          child: _isNegotiating
              ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                )
              : isLocked
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).suspendedStatus,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).chooseTacticLabel(
                        (2 - widget.offer.attemptsMade).toString(),
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _tacticBtn(
                            AppLocalizations.of(context).persuasiveTactic,
                            const Color(0xFFFF5733),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tacticBtn(
                            AppLocalizations.of(context).negotiatorTactic,
                            const Color(0xFFF1C40F),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tacticBtn(
                            AppLocalizations.of(context).collaborativeTactic,
                            const Color(0xFFE9967A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _localizeObjective(BuildContext context, String objKey) {
    final l10n = AppLocalizations.of(context);
    switch (objKey) {
      case 'objFinishTop3':
        return l10n.objFinishTop3;
      case 'objBothInPoints':
        return l10n.objBothInPoints;
      case 'objRaceWin':
        return l10n.objRaceWin;
      case 'objFinishTop10':
        return l10n.objFinishTop10;
      case 'objFastestLap':
        return l10n.objFastestLap;
      case 'objFinishRace':
        return l10n.objFinishRace;
      case 'objImproveGrid':
        return l10n.objImproveGrid;
      case 'objOvertake3Cars':
        return l10n.objOvertake3Cars;
      default:
        return objKey;
    }
  }

  Widget _infoChip(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).dividerColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.38),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Componente 'sponsorsButtons' - Estilo Mute con revelación de color en Hover
  Widget _tacticBtn(String label, Color color) {
    return ElevatedButton(
      onPressed: () => _negotiate(label),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return color;
          }
          return Colors.white.withValues(alpha: 0.05);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFFEF9E7); // Crema claro
          }
          return Colors.white.withValues(alpha: 0.4);
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.1);
          }
          return null;
        }),
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 14),
        ),
        shape: WidgetStateProperty.all(const StadiumBorder()),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontFamily: 'Poppins',
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Wrapper for Mobile Carousel to adapt to reused _SponsorOfferCard
class _SponsorCarouselModal extends StatefulWidget {
  final String teamId;
  final SponsorSlot slot;
  final List<SponsorOffer> offers;
  final ManagerRole role;
  final SponsorService sponsorService;
  final FinanceService financeService;
  final VoidCallback onComplete;

  const _SponsorCarouselModal({
    required this.teamId,
    required this.slot,
    required this.offers,
    required this.role,
    required this.sponsorService,
    required this.financeService,
    required this.onComplete,
  });

  @override
  State<_SponsorCarouselModal> createState() => _SponsorCarouselModalState();
}

class _SponsorCarouselModalState extends State<_SponsorCarouselModal> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).availableSponsorsTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${_currentIndex + 1}/${widget.offers.length}",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemCount: widget.offers.length,
              itemBuilder: (context, index) {
                // Adapt to the shared card widget
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: _SponsorOfferCard(
                    offer: widget.offers[index],
                    teamId: widget.teamId,
                    slot: widget.slot,
                    role: widget.role,
                    sponsorService: widget.sponsorService,
                    financeService: widget.financeService,
                    onNegotiationComplete: () {
                      widget.onComplete();
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
