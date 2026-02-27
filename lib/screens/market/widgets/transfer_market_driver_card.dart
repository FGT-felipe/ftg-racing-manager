import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../models/core_models.dart';
import '../../../utils/currency_formatter.dart';
import '../../../services/driver_portrait_service.dart';
import '../../../l10n/app_localizations.dart';

class TransferMarketDriverCard extends StatefulWidget {
  final Driver driver;
  final String currentTeamId;
  final VoidCallback? onBid;
  final VoidCallback? onCancelBid;
  final VoidCallback? onCancelTransfer;
  final bool isCancellingBid;
  final int? currentYear;

  final VoidCallback? onClose;

  const TransferMarketDriverCard({
    super.key,
    required this.driver,
    required this.currentTeamId,
    this.onBid,
    this.onCancelBid,
    this.onCancelTransfer,
    this.isCancellingBid = false,
    this.currentYear,
    this.onClose,
  });

  @override
  State<TransferMarketDriverCard> createState() =>
      _TransferMarketDriverCardState();
}

class _TransferMarketDriverCardState extends State<TransferMarketDriverCard> {
  bool _isHoveringBid = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Stats for the radar chart and bars
    final statsKeys = [
      DriverStats.braking,
      DriverStats.cornering,
      DriverStats.smoothness,
      DriverStats.overtaking,
      DriverStats.consistency,
      DriverStats.adaptability,
      DriverStats.fitness,
      DriverStats.feedback,
      DriverStats.focus,
    ];

    final statsValues = statsKeys.map((k) => widget.driver.getStat(k)).toList();

    return Container(
      width: double.infinity,
      height: 650, // Fixed height to satisfy internal Spacers
      constraints: const BoxConstraints(maxWidth: 1200),
      // margin removed for better alignment in dialogs
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background subtle pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),

          if (widget.onClose != null)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white.withValues(alpha: 0.05),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: widget.onClose,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(
                  height: 580,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Column 1: Identity & Contract
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildIdentityBlock(context, l10n),
                            const SizedBox(height: 24),
                            _buildContractSection(context, l10n),
                            const Spacer(),
                            _buildActionButtons(context, l10n),
                          ],
                        ),
                      ),

                      const VerticalDivider(
                        width: 48,
                        thickness: 1,
                        color: Colors.white10,
                      ),

                      // Column 2: Stats & Visualization
                      Expanded(
                        flex: 4,
                        child: _buildStatsSection(
                          context,
                          l10n,
                          statsKeys,
                          statsValues,
                        ),
                      ),

                      const VerticalDivider(
                        width: 48,
                        thickness: 1,
                        color: Colors.white10,
                      ),

                      // Column 3: History & Form
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildTableSection(
                              l10n.championshipFormTitle,
                              _buildFormTable(context, l10n),
                            ),
                            const SizedBox(height: 24),
                            _buildTableSection(
                              l10n.careerHistoryTitle,
                              _buildHistoryTable(context, l10n),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityBlock(BuildContext context, AppLocalizations l10n) {
    final portraitUrl = DriverPortraitService().getEffectivePortraitUrl(
      driverId: widget.driver.id,
      countryCode: widget.driver.countryCode,
      gender: widget.driver.gender,
      age: widget.driver.age,
    );

    // Level Badge Logic
    String levelText;
    Color levelColor;
    if (widget.driver.currentStars >= 5) {
      levelText = "ELITE";
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
              width: 100,
              height: 100,
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
                      fontSize: 26,
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
        // Custom Driver Stars
        _buildPotentialStars(),
      ],
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

  Widget _buildContractSection(BuildContext context, AppLocalizations l10n) {
    const labelStyle = TextStyle(color: Color(0xFFA0AEC0), fontSize: 13);
    const valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    return Container(
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
            "CONTRACT DETAILS",
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildContractRow(
            "Status",
            _getLocalizedRole(context, widget.driver.role),
            labelStyle,
            valueStyle,
          ),
          _buildContractRow(
            "Salary",
            CurrencyFormatter.format(widget.driver.salary),
            labelStyle,
            valueStyle.copyWith(color: Colors.white),
          ),
          _buildContractRow(
            "Termination",
            CurrencyFormatter.format(widget.driver.salary * 5),
            labelStyle,
            valueStyle,
          ),
          _buildContractRow(
            "Remaining",
            "${widget.driver.contractYearsRemaining} Season",
            labelStyle,
            valueStyle,
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildContractRow(
            "Morale",
            "${(widget.driver.getStat(DriverStats.morale) / 5).round()}/20",
            labelStyle,
            valueStyle,
          ),
          _buildContractRow(
            "Marketability",
            "${(widget.driver.getStat(DriverStats.marketability) / 5).round()}/20",
            labelStyle,
            valueStyle,
          ),
          const SizedBox(height: 12),
          Text(
            "MARKET VALUE",
            style: labelStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            CurrencyFormatter.format(widget.driver.marketValue),
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractRow(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
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

  Widget _buildStatsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<String> keys,
    List<int> values,
  ) {
    return Column(
      children: [
        // Badge moved here
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFFFFC107).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            "TRANSFER MARKET",
            style: GoogleFonts.montserrat(
              color: const Color(0xFFFFC107),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 5,
          child: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: RadarChartPainter(
                  values.map((v) => v / 100.0).toList(),
                  keys.map((k) => _formatSkillName(context, k)).toList(),
                  const Color(0xFF00E676),
                  values.any((v) => v >= 75), // Glow if any stat >= 15 (75/100)
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          flex: 6,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4.5,
              crossAxisSpacing: 24,
              mainAxisSpacing: 12,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              return _buildStatIndicator(context, keys[index], values[index]);
            },
          ),
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
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              displayValue.toString(),
              style: GoogleFonts.robotoMono(
                color: color,
                fontSize: 14,
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

  Widget _buildTableSection(String title, Widget table) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: table),
        ],
      ),
    );
  }

  Widget _buildFormTable(BuildContext context, AppLocalizations l10n) {
    return _buildCleanTable(
      headers: ["EVENT", "Q", "R", "P"],
      flexValues: [4, 1, 1, 1],
      rows: [], // No form data yet in the model snapshot usually
      emptyMessage: "No Data Available Yet",
    );
  }

  Widget _buildHistoryTable(BuildContext context, AppLocalizations l10n) {
    final rows = _generateHistory(context, widget.driver);
    return _buildCleanTable(
      headers: [
        l10n.yearHeader.toUpperCase(),
        l10n.teamHeader.toUpperCase(),
        l10n.seriesHeader.toUpperCase(),
        l10n.rHeader.toUpperCase(),
        l10n.pHeader.toUpperCase(),
        l10n.wHeader.toUpperCase(),
      ],
      flexValues: [1, 2, 2, 1, 1, 1],
      rows: rows,
      emptyMessage: l10n.noDataAvailableYet,
    );
  }

  Widget _buildCleanTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<int>? flexValues,
    String? emptyMessage,
  }) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(headers.length, (i) {
              return Expanded(
                flex: flexValues != null ? flexValues[i] : 1,
                child: Text(
                  headers[i],
                  style: GoogleFonts.montserrat(
                    color: Colors.white30,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage ?? "No Data",
                    style: const TextStyle(
                      color: Colors.white24,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: rows.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final bool isEven = index % 2 == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: List.generate(row.length, (i) {
                          return Expanded(
                            flex: flexValues != null ? flexValues[i] : 1,
                            child: Text(
                              row[i],
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              textAlign: i == 0
                                  ? TextAlign.left
                                  : TextAlign.center,
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    // If the driver belongs to the current team
    if (widget.driver.teamId == widget.currentTeamId) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: widget.onCancelTransfer,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFF5252)),
            foregroundColor: const Color(0xFFFF5252),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: Text(
            "CANCEL TRANSFER",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    if (widget.driver.highestBidderTeamId == widget.currentTeamId) {
      // Current highest bidder: Retirar Puja behavior preserved
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF00E676),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "YOU HAVE THE HIGHEST BID",
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: widget.isCancellingBid ? null : widget.onCancelBid,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF5252)),
                foregroundColor: const Color(0xFFFF5252),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: widget.isCancellingBid
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF5252),
                      ),
                    )
                  : Text(
                      "WITHDRAW BID",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    // Normal Market UI
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringBid = true),
      onExit: (_) => setState(() => _isHoveringBid = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: _isHoveringBid
              ? [
                  const BoxShadow(
                    color: Color(0xFFFFC107),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: FilledButton(
          onPressed: widget.onBid,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107), // Traffic Yellow
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel, size: 18),
              const SizedBox(width: 10),
              Text(
                "PLACE BID",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<List<String>> _generateHistory(BuildContext context, Driver driver) {
    final l10n = AppLocalizations.of(context);
    List<List<String>> rows = [];

    // If no races have been run, return empty to show "No data yet"
    if (driver.races == 0) return rows;

    int startYear = widget.currentYear ?? 2026;

    // 1. Current Season Stats
    if (driver.seasonRaces > 0) {
      rows.add([
        "$startYear",
        driver.teamId == null ? l10n.historyIndividual : "F1 Team",
        "F1 SERIES",
        "${driver.seasonRaces}",
        "${driver.seasonPodiums}",
        "${driver.seasonWins}",
      ]);
    }

    // 2. Aggregate Remaining History as "Prior Career"
    int remRaces = driver.races - driver.seasonRaces;
    if (remRaces > 0) {
      int remWins = driver.wins - driver.seasonWins;
      int remPodiums = driver.podiums - driver.seasonPodiums;

      rows.add([
        "PREV",
        l10n.historyIndividual,
        l10n.historyLowerDivision,
        "$remRaces",
        "$remPodiums",
        "$remWins",
      ]);
    }

    return rows;
  }

  String _formatSkillName(BuildContext context, String key) {
    switch (key) {
      case 'braking':
        return 'Braking';
      case 'cornering':
        return 'Cornering';
      case 'smoothness':
        return 'Smoothness';
      case 'overtaking':
        return 'Overtaking';
      case 'consistency':
        return 'Consistency';
      case 'adaptability':
        return 'Adaptability';
      case 'fitness':
        return 'Fitness';
      case 'feedback':
        return 'Feedback';
      case 'focus':
        return 'Focus';
      default:
        return key.toUpperCase();
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
    switch (role) {
      case 'Main':
        return 'Main Driver';
      case 'Second':
        return 'Secondary';
      case 'Equal':
      case 'Equal Status':
        return 'Equal Status';
      case 'Reserve':
        return 'Reserve';
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
      ..color = color.withValues(alpha: 0.5)
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

    // Draw labels icons or markers if needed
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
      ..color = Colors.white
      ..strokeWidth = 1;

    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
