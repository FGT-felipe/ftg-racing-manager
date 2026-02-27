import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/core_models.dart';
import '../../../services/driver_portrait_service.dart';
import '../../../services/driver_status_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';

class DriverCard extends StatefulWidget {
  final Driver driver;
  final VoidCallback? onRenew;
  final VoidCallback? onTransferMarket;
  final VoidCallback? onCancelTransfer;
  final VoidCallback? onBid;
  final VoidCallback? onCancelBid;
  final bool isCancellingBid;
  final String? teamName;
  final String? currentTeamId;
  final String? leagueName;
  final int? currentYear;

  const DriverCard({
    super.key,
    required this.driver,
    this.onRenew,
    this.onTransferMarket,
    this.onCancelTransfer,
    this.onBid,
    this.onCancelBid,
    this.isCancellingBid = false,
    this.teamName,
    this.currentTeamId,
    this.leagueName,
    this.currentYear,
  });

  @override
  State<DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<DriverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  bool _isHoveringTransfer = false;
  bool _isHoveringRenew = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final isBack = angle > math.pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildBackView(context, isDesktop),
                )
              : _buildFrontView(context, isDesktop),
        );
      },
    );
  }

  Widget _buildFrontView(BuildContext context, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121216), // Deep Charcoal
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          // Left Accent Border
          Positioned(
            left: 0,
            top: 24,
            bottom: 24,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF00E676,
                ), // Use a more vibrant green or secondary
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isDesktop
                ? SizedBox(
                    height: 640, // Increased height to prevent overflows
                    child: _buildDesktopLayout(context),
                  )
                : _buildMobileLayout(context),
          ),
          // Front Flip Badge - Positioned TOP CENTER
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(child: _buildFlipBadge()),
          ),
          if (widget.driver.isTransferListed)
            Positioned(
              top: 12,
              left: -30,
              child: Transform.rotate(
                angle: -0.785398, // -45 degrees
                child: Container(
                  width: 150,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    "TRANSFER MARKET",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackView(BuildContext context, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121216), // Deep Charcoal
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isDesktop
                ? SizedBox(
                    height: 640,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_buildCareerStatsSummary(context)],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_buildCareerStatsSummary(context)],
                    ),
                  ),
          ),
          // Back Flip Badge - Positioned TOP CENTER
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(child: _buildFlipBadge()),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipBadge() {
    return GestureDetector(
      onTap: _toggleFlip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(
            0xFFFF00FF,
          ).withValues(alpha: 0.1), // Neon Pink with low alpha
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFFF00FF).withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF00FF).withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          "FLIP",
          style: GoogleFonts.montserrat(
            color: const Color(0xFFFF00FF),
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column 1: Identity & Contract
        Expanded(
          flex: 3,
          child: SingleChildScrollView(child: _buildColumnA(context)),
        ),
        const SizedBox(width: 24),
        // Column 2: Interaction, Radar & Skills
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 32), // Space for FLIP badge
              _buildSkillsSection(context),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Column 3: Form & History
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(child: _buildChampionshipForm(context, fillSpace: true)),
              const SizedBox(height: 20),
              Expanded(child: _buildCareerHistory(context, fillSpace: true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnA(context),
        const Divider(height: 32),
        _buildSkillsSection(context),
        const Divider(height: 32),
        _buildChampionshipForm(context),
        const Divider(height: 32),
        _buildCareerHistory(context),
      ],
    );
  }

  Widget _buildColumnA(BuildContext context) {
    final theme = Theme.of(context);
    final portraitUrl =
        widget.driver.portraitUrl ??
        DriverPortraitService().getEffectivePortraitUrl(
          driverId: widget.driver.id,
          countryCode: widget.driver.countryCode,
          gender: widget.driver.gender,
          age: widget.driver.age,
        );

    // Level Badge Logic from Transfer Market
    String levelText;
    Color levelColor;
    if (widget.driver.currentStars >= 5) {
      levelText = "ÉLITE";
      levelColor = const Color(0xFF00E676);
    } else if (widget.driver.currentStars >= 4) {
      levelText = "PRO";
      levelColor = const Color(0xFFFFEE58);
    } else {
      levelText = "AMATEUR";
      levelColor = const Color(0xFFA0AEC0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Portrait with Glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: levelColor.withValues(alpha: 0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: levelColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                image: DecorationImage(
                  image: portraitUrl.startsWith('http')
                      ? NetworkImage(portraitUrl) as ImageProvider
                      : AssetImage(portraitUrl),
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
                        _getFlagEmoji(widget.driver.countryCode),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: levelColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          levelText,
                          style: GoogleFonts.montserrat(
                            color: levelColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.driver.name.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Age ${widget.driver.age}",
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFFFC107),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Potential Stars
        _buildPotentialStars(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).contractDetailsTitle.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFA0AEC0),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildContractRow(
                AppLocalizations.of(context).contractStatusLabel,
                _getLocalizedRole(context, widget.driver.role),
              ),
              _buildContractRow(
                AppLocalizations.of(context).salaryPerRaceLabel,
                CurrencyFormatter.format(widget.driver.salary),
                valueColor: Colors.white,
              ),
              _buildContractRow(
                AppLocalizations.of(context).terminationLabel,
                CurrencyFormatter.format(widget.driver.salary * 5),
              ),
              _buildContractRow(
                AppLocalizations.of(context).remainingLabel,
                AppLocalizations.of(context).seasonsRemaining(
                  widget.driver.contractYearsRemaining.toString(),
                ),
              ),
              const Divider(height: 24, color: Colors.white10),
              Text(
                AppLocalizations.of(context).marketValueLabel.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFA0AEC0),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(widget.driver.marketValue),
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Divider(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          height: 1,
        ),
        const SizedBox(height: 16),
        _buildContractRow(
          AppLocalizations.of(context).moraleLabel,
          '${(widget.driver.stats[DriverStats.morale] ?? 0) ~/ 5}/20',
        ),
        _buildContractRow(
          AppLocalizations.of(context).marketabilityLabel,
          '${(widget.driver.stats[DriverStats.marketability] ?? 0) ~/ 5}/20',
        ),
        _buildContractRow(
          AppLocalizations.of(context).marketValueLabel,
          CurrencyFormatter.format(widget.driver.marketValue),
        ),
        if (widget.driver.isTransferListed &&
            widget.driver.currentHighestBid > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Highest Bid:",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.driver.currentHighestBid),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.driver.highestBidderTeamName != null)
                  Text(
                    "(${widget.driver.highestBidderTeamName})",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (widget.currentTeamId != null &&
                    widget.driver.highestBidderTeamId == widget.currentTeamId)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "YOU HAVE THE HIGHEST BID",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        InkWell(
                          onTap: widget.isCancellingBid
                              ? null
                              : widget.onCancelBid,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5),
                              ),
                            ),
                            child: widget.isCancellingBid
                                ? const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                : const Text(
                                    "CANCEL BID",
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Divider(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          height: 1,
        ),
        const SizedBox(height: 24),
        Row(
          children: widget.driver.isTransferListed
              ? [
                  if (widget.currentTeamId == widget.driver.teamId)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancelTransfer,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                          side: const BorderSide(color: Color(0xFFFF5252)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text("CANCEL TRANSFER"),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.onBid,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gavel, size: 16),
                              SizedBox(width: 8),
                              Text("PLACE BID"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ]
              : [
                  Expanded(
                    child: MouseRegion(
                      onEnter: (_) =>
                          setState(() => _isHoveringTransfer = true),
                      onExit: (_) =>
                          setState(() => _isHoveringTransfer = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _isHoveringTransfer
                              ? [
                                  const BoxShadow(
                                    color: Color(0xFF00C853),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [],
                        ),
                        child: FilledButton(
                          onPressed: widget.onTransferMarket,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart, size: 14),
                                SizedBox(width: 6),
                                Text("Transfer Market"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringRenew = true),
                      onExit: (_) => setState(() => _isHoveringRenew = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _isHoveringRenew
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [],
                        ),
                        child: FilledButton(
                          onPressed: widget.onRenew,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).renewContractBtn.toUpperCase(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
        ),
      ],
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final theme = Theme.of(context);
    final allStats = widget.driver.stats.entries
        .where(
          (e) =>
              e.key != DriverStats.morale && e.key != DriverStats.marketability,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).driverStatsSectionTitle.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.secondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: RadarChartPainter(
                allStats.map((e) => e.value / 100.0).toList(),
                allStats.map((e) => _formatSkillName(context, e.key)).toList(),
                const Color(0xFF00E676),
                allStats.any((e) => e.value >= 75),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 5.0, // Tighter ratio
            crossAxisSpacing: 12, // Reduced from 24
            mainAxisSpacing: 12,
          ),
          itemCount: allStats.length,
          itemBuilder: (context, index) {
            final entry = allStats[index];
            return _buildStatIndicator(context, entry.key, entry.value);
          },
        ),
      ],
    );
  }

  Widget _buildStatIndicator(BuildContext context, String key, int value) {
    final displayValue = (value / 5).round();
    Color color = const Color(0xFFFF5252); // Low
    if (displayValue >= 15) {
      color = const Color(0xFF00E676); // High
    } else if (displayValue >= 10) {
      color = const Color(0xFFFFEE58); // Medium
    }

    final bool hasGlow = displayValue >= 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatSkillName(context, key).toUpperCase(),
              style: GoogleFonts.montserrat(
                color: const Color(0xFFA0AEC0),
                fontSize: 8, // Reduced from 9
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              displayValue.toString(),
              style: GoogleFonts.robotoMono(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (value / 100.0).clamp(0.01, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: hasGlow
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCareerStatsSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).careerStatsTitle.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA0AEC0),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).titlesStat,
                '${widget.driver.championships}',
                Icons.emoji_events_rounded,
              ),
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).winsStat,
                '${widget.driver.wins}',
                Icons.military_tech_rounded,
              ),
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).podiumsStat,
                '${widget.driver.podiums}',
                Icons.star_rounded,
              ),
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).racesStat,
                '${widget.driver.races}',
                Icons.flag_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status Title Badge
          Center(
            child: Tooltip(
              message: DriverStatusService.getLocalizedDescription(
                context,
                widget.driver.statusTitle,
              ),
              triggerMode: TooltipTriggerMode.tap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E676).withValues(alpha: 0.15),
                      const Color(0xFF00E676).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF00E676),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DriverStatusService.getLocalizedTitle(
                        context,
                        widget.driver.statusTitle,
                      ).toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerStatCircle(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF15151E), // App Background
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.secondary, size: 16),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionshipForm(
    BuildContext context, {
    bool fillSpace = false,
  }) {
    return _buildTinyTable(
      context,
      title: AppLocalizations.of(context).championshipFormTitle.toUpperCase(),
      headers: ['EVENT', 'Q', 'R', 'P'],
      flexValues: [3, 1, 1, 1],
      alignments: [
        TextAlign.left,
        TextAlign.center,
        TextAlign.center,
        TextAlign.center,
      ],
      rows: [], // Will be populated when history service is implemented
      maxRows: 5,
      fillSpace: fillSpace,
    );
  }

  Widget _buildCareerHistory(BuildContext context, {bool fillSpace = false}) {
    return _buildTinyTable(
      context,
      title: AppLocalizations.of(context).careerHistoryTitle.toUpperCase(),
      headers: [
        AppLocalizations.of(context).yearHeader,
        AppLocalizations.of(context).teamHeader,
        AppLocalizations.of(context).seriesHeader,
        AppLocalizations.of(context).rHeader,
        AppLocalizations.of(context).pHeader,
        AppLocalizations.of(context).wHeader,
      ],
      flexValues: [1, 2, 2, 1, 1, 1],
      alignments: [
        TextAlign.center,
        TextAlign.center,
        TextAlign.center,
        TextAlign.center,
        TextAlign.center,
        TextAlign.center,
      ],
      badgeColumns: [1, 2],
      rows: _generateStableHistory(
        context,
        widget.driver,
        widget.teamName ?? AppLocalizations.of(context).historyIndividual,
        widget.leagueName ?? '--',
      ),
      maxRows: 5,
      fillSpace: fillSpace,
    );
  }

  Widget _buildPotentialStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        bool isCurrent = starIndex <= widget.driver.currentStars;
        bool isPotential = starIndex <= widget.driver.potential;

        Color starColor = Colors.white10;
        List<BoxShadow> shadows = [];

        if (isCurrent) {
          starColor = const Color(0xFF00B0FF); // Neon Electric Blue
          shadows = [
            const BoxShadow(
              color: Color(0xFF00B0FF),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ];
        } else if (isPotential) {
          starColor = const Color(0xFFFFD700); // Golden Yellow
          shadows = [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 4,
            ),
          ];
        }

        return Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: shadows,
            ),
            child: Icon(
              index < widget.driver.potential
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: starColor,
              size: 24,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContractRow(String label, String value, {Color? valueColor}) {
    const labelStyle = TextStyle(color: Color(0xFFA0AEC0), fontSize: 13);
    final valueStyle = TextStyle(
      color: valueColor ?? Colors.white,
      fontSize: 13,
      fontFamily: GoogleFonts.robotoMono().fontFamily,
      fontWeight: FontWeight.bold,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Widget _buildTinyTable(
    BuildContext context, {
    String? title,
    required List<String> headers,
    List<int>? flexValues,
    List<TextAlign>? alignments,
    List<int>? badgeColumns,
    required List<List<String>> rows,
    int? maxRows,
    bool fillSpace = false,
  }) {
    final theme = Theme.of(context);
    final effectiveFlexValues = flexValues ?? List.filled(headers.length, 1);
    final effectiveAlignments =
        alignments ?? List.filled(headers.length, TextAlign.center);

    Widget dataContent;
    if (rows.isEmpty) {
      dataContent = Center(
        child: Text(
          AppLocalizations.of(context).noDataAvailableYet,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else {
      dataContent = ListView.builder(
        shrinkWrap: !fillSpace,
        physics: fillSpace ? null : const NeverScrollableScrollPhysics(),
        itemCount: maxRows != null
            ? math.min(rows.length, maxRows)
            : rows.length,
        itemBuilder: (context, rowIndex) {
          final row = rows[rowIndex];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: rowIndex % 2 != 0
                  ? Colors.white.withValues(alpha: 0.05)
                  : null,
            ),
            child: Row(
              children: List.generate(row.length, (index) {
                final isBadge = badgeColumns?.contains(index) ?? false;
                return Expanded(
                  flex: effectiveFlexValues[index],
                  child: isBadge
                      ? Center(
                          child: _buildTeamBadgeOverlay(context, row[index]),
                        )
                      : Text(
                          row[index],
                          textAlign: effectiveAlignments[index],
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: index == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                );
              }),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA0AEC0),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: List.generate(headers.length, (index) {
              return Expanded(
                flex: effectiveFlexValues[index],
                child: Text(
                  headers[index].toUpperCase(),
                  textAlign: effectiveAlignments[index],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              );
            }),
          ),
        ),
        if (fillSpace) Expanded(child: dataContent) else dataContent,
      ],
    );
  }

  Widget _buildTeamBadgeOverlay(BuildContext context, String teamName) {
    if (teamName.isEmpty || teamName == '--') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        teamName,
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFA0AEC0),
        ),
      ),
    );
  }

  List<List<String>> _generateStableHistory(
    BuildContext context,
    Driver driver,
    String currentTeam,
    String currentLeague,
  ) {
    final l10n = AppLocalizations.of(context);
    List<List<String>> rows = [];
    int startYear = 2024;
    int currentYearValue = widget.currentYear ?? startYear;

    int totalRaces = driver.races;
    int totalPodiums = driver.podiums;
    int totalWins = driver.wins;
    int totalTitles = driver.championships;

    int remainingRaces = totalRaces;

    for (int i = 0; i < 5; i++) {
      int year = currentYearValue - i;
      int yearRaces = (totalRaces / 5).floor();
      if (i == 0) yearRaces += totalRaces % 5;

      int yearWins = (totalWins / 5).floor();
      if (i == 0) yearWins += totalWins % 5;

      int yearPodiums = (totalPodiums / 5).floor();
      if (i == 0) yearPodiums += totalPodiums % 5;

      bool isChampion = i < totalTitles;

      if (remainingRaces <= 0 && i > 0) break;

      String divDisplay = i == 0 ? currentLeague : l10n.historyLowerDivision;
      if (isChampion) {
        divDisplay = l10n.historyChampionBadge;
      }

      rows.add([
        '$year',
        currentTeam,
        divDisplay,
        '$yearRaces',
        '$yearPodiums',
        '$yearWins',
      ]);

      remainingRaces -= yearRaces;

      if (remainingRaces <= 0 && i >= 1) break;
    }

    return rows;
  }

  String _formatSkillName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'braking':
        return l10n.statBraking;
      case 'cornering':
        return l10n.statCornering;
      case 'smoothness':
        return l10n.statSmoothness;
      case 'overtaking':
        return l10n.statOvertaking;
      case 'consistency':
        return l10n.statConsistency;
      case 'adaptability':
        return l10n.statAdaptability;
      case 'fitness':
        return l10n.statFitness;
      case 'feedback':
        return l10n.statFeedback;
      case 'focus':
        return l10n.statFocus;
      case 'morale':
        return l10n.statMorale;
      case 'marketability':
        return l10n.statMarketability;
      default:
        if (key.isEmpty) return key;
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  String _getFlagEmoji(String? countryCode) {
    if (countryCode == null) return '🏳️';
    const flags = {
      'BR': '🇧🇷',
      'AR': '🇦🇷',
      'CO': '🇨🇴',
      'MX': '🇲🇽',
      'UY': '🇺🇾',
      'CL': '🇨🇱',
      'GB': '🇬🇧',
      'DE': '🇩🇪',
      'IT': '🇮🇹',
      'ES': '🇪🇸',
      'FR': '🇫🇷',
    };
    return flags[countryCode] ?? '🏳️';
  }

  String _getLocalizedRole(BuildContext context, String role) {
    final l10n = AppLocalizations.of(context);
    switch (role) {
      case 'Main':
        return l10n.roleMain;
      case 'Second':
      case 'Secondary':
        return l10n.roleSecond;
      case 'Equal':
      case 'Equal Status':
        return l10n.roleEqual;
      case 'Reserve':
        return l10n.roleReserve;
      default:
        return role;
    }
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final bool showGlow;

  RadarChartPainter(this.values, this.labels, this.color, this.showGlow);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    final angleStep = (2 * math.pi) / values.length;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid rings
    for (int i = 1; i <= 5; i++) {
      final r = radius * (i / 5);
      final path = Path();
      for (int j = 0; j < values.length; j++) {
        final angle = j * angleStep - math.pi / 2;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines
    for (int j = 0; j < values.length; j++) {
      final angle = j * angleStep - math.pi / 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        gridPaint,
      );
    }

    // Draw data path
    final dataPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (showGlow) {
      borderPaint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
    }

    final dataPath = Path();
    for (int j = 0; j < values.length; j++) {
      final angle = j * angleStep - math.pi / 2;
      final val = values[j].clamp(0.05, 1.0);
      final x = center.dx + radius * val * math.cos(angle);
      final y = center.dy + radius * val * math.sin(angle);
      if (j == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, borderPaint);

    // Draw labels markers
    for (int j = 0; j < values.length; j++) {
      final angle = j * angleStep - math.pi / 2;
      final val = values[j].clamp(0.05, 1.0);
      final x = center.dx + radius * val * math.cos(angle);
      final y = center.dy + radius * val * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const double step = 30.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
