import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/user_models.dart';
import '../../services/sponsor_service.dart';
import '../../services/auth_service.dart';
import '../../services/finance_service.dart';
import '../../utils/responsive_layout.dart';

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
      future: FirebaseFirestore.instance
          .collection('managers')
          .doc(AuthService().currentUser?.uid)
          .get(),
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
        final managerRoleStr = managerData?['role'] ?? 'noExperience';
        final managerRole = ManagerRole.values.firstWhere(
          (e) => e.name == managerRoleStr,
          orElse: () => ManagerRole.noExperience,
        );

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
              // Left Side: Car Visualization (40%)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildCarVisualization(team, role, isDesktop: true),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Side: Details / Offers (60%)
              Expanded(flex: 6, child: _buildDesktopRightPanel(team)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRightPanel(Team team) {
    if (_selectedSlotDesktop == null) {
      return Center(
        child: Text(
          "Select a car part to manage sponsorships",
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
            "ACTIVE CONTRACT: ${_selectedSlotDesktop!.name.toUpperCase()}",
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
              borderRadius: BorderRadius.circular(8),
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
                      label: "Weekly Pay",
                      value: _financeService.formatCurrency(
                        activeContract.weeklyBasePayment,
                      ),
                    ),
                    _DetailItem(
                      label: "Races Left",
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
            "AVAILABLE OFFERS: ${_selectedSlotDesktop!.name.toUpperCase()}",
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _desktopOffers?.length ?? 0,
              itemBuilder: (context, index) {
                return _SponsorOfferCard(
                  offer: _desktopOffers![index],
                  teamId: widget.teamId,
                  slot: _selectedSlotDesktop!,
                  role: ManagerRole
                      .noExperience, // Role logic handled in generation
                  sponsorService: _sponsorService,
                  financeService: _financeService,
                  onNegotiationComplete: () => setState(() {}),
                );
              },
            ),
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
          "Rear Wing",
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
                "Sidepod (L)",
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
                "Sidepod (R)",
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
          "Halo",
          SponsorSlot.halo,
          team.sponsors[SponsorSlot.halo.name],
          role,
          Colors.grey,
          isDesktop,
        ),
        const SizedBox(height: 12),
        _buildSlotItem(
          "Front Wing",
          SponsorSlot.frontWing,
          team.sponsors[SponsorSlot.frontWing.name],
          role,
          Theme.of(context).colorScheme.secondary,
          isDesktop,
        ),
        const SizedBox(height: 12),
        _buildSlotItem(
          "Nose",
          SponsorSlot.nose,
          team.sponsors[SponsorSlot.nose.name],
          role,
          Theme.of(context).colorScheme.secondary,
          isDesktop,
        ),
      ],
    );
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

    return GestureDetector(
      onTap: () {
        if (isDesktop) {
          _selectSlotDesktop(slot, role);
        } else if (!hasContract) {
          _showSponsorCarouselMobile(context, slot, role);
        }
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: (hasContract || isSelected)
              ? color.withValues(alpha: 0.05)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
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
                    : (isDesktop ? "MANAGE" : "+ SELECT SPONSOR"),
                style: TextStyle(
                  color: hasContract
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNegotiationLegend() {
    return const _CommonInstructionCard(
      icon: Icons.handshake_rounded,
      title: "NEGOTIATION RULES",
      description:
          "Choose a strategy that matches the sponsor's personality. Remember you have 3 attempts total; if you fail, the sponsor will leave for 7 days.",
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
              theme.colorScheme.primary.withValues(alpha: 0.15),
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
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

  const _SponsorOfferCard({
    required this.offer,
    required this.teamId,
    required this.slot,
    required this.role,
    required this.sponsorService,
    required this.financeService,
    required this.onNegotiationComplete,
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
      margin: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 5,
      ), // Adjusted for general use
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.offer.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.offer.isAdminBonusApplied)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
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
            "Signing Bonus",
            widget.financeService.formatCurrency(widget.offer.signingBonus),
            Colors.green,
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            "Weekly Payment",
            widget.financeService.formatCurrency(
              widget.offer.weeklyBasePayment,
            ),
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          _infoRow(
            Icons.timer_outlined,
            "Duration",
            "${widget.offer.contractDuration} Races",
            Colors.blue,
          ),
          _infoRow(
            Icons.emoji_events_outlined,
            "Objective",
            widget.offer.objectiveDescription,
            Colors.orangeAccent,
          ),
          const Spacer(),
          if (isLocked)
            const Center(
              child: Text(
                "SUSPENDED",
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
                "CHOOSE TACTIC (${3 - widget.offer.attemptsMade} left)",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.38),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _tacticBtn("AGGRESSIVE", Colors.red)),
                const SizedBox(width: 8),
                Expanded(
                  child: _tacticBtn(
                    "PROFESSIONAL",
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tacticBtn(
                    "FRIENDLY",
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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

  Widget _tacticBtn(String label, Color color) {
    return OutlinedButton(
      onPressed: () => _negotiate(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
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
      height: 520,
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
                  "AVAILABLE SPONSORS",
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
