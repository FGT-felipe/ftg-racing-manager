import 'package:flutter/material.dart';
import '../../../models/core_models.dart';
import '../../../services/driver_portrait_service.dart';
import '../../../services/driver_status_service.dart';
import '../../../l10n/app_localizations.dart';

class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onRenew;
  final VoidCallback? onTransferMarket;
  final VoidCallback? onCancelTransfer;
  final String? teamName;
  final String? leagueName;
  final int? currentYear;

  const DriverCard({
    super.key,
    required this.driver,
    this.onRenew,
    this.onTransferMarket,
    this.onCancelTransfer,
    this.teamName,
    this.leagueName,
    this.currentYear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left Accent Border
          Positioned(
            left: 0,
            top: 20,
            bottom: 20,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isDesktop
                ? _buildDesktopLayout(context)
                : _buildMobileLayout(context),
          ),
          if (driver.isTransferListed)
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

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column A: Profile & Contract
        Expanded(flex: 2, child: _buildColumnA(context)),
        const SizedBox(width: 48),
        // Combined Grid for B and C
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // Row 1: Skills & Form
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildSkillsSection(context)),
                  const SizedBox(width: 48),
                  Expanded(flex: 4, child: _buildChampionshipForm(context)),
                ],
              ),
              const SizedBox(height: 24),
              // Row 2: Career Details (Symmetrically aligned)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: _buildCareerStatsSummary(context)),
                    const SizedBox(width: 48),
                    Expanded(flex: 4, child: _buildCareerHistory(context)),
                  ],
                ),
              ),
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
        _buildColumnB(context),
        const Divider(height: 32),
        _buildColumnC(context),
      ],
    );
  }

  Widget _buildColumnA(BuildContext context) {
    final theme = Theme.of(context);
    final portraitUrl =
        driver.portraitUrl ??
        DriverPortraitService().getEffectivePortraitUrl(
          driverId: driver.id,
          countryCode: driver.countryCode,
          gender: driver.gender,
          age: driver.age,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 3,
              ),
              image: DecorationImage(
                image: portraitUrl.startsWith('http')
                    ? NetworkImage(portraitUrl) as ImageProvider
                    : AssetImage(portraitUrl),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Error loading avatar: $exception');
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            AppLocalizations.of(context).ageLabel(driver.age),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Name & Flag
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getFlagEmoji(driver.countryCode),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                driver.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Potential Stars
        Center(child: _buildPotentialStars(driver.potential)),
        const SizedBox(height: 24),
        // Contract Details
        Text(
          AppLocalizations.of(context).contractDetailsTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildContractRow(
          AppLocalizations.of(context).contractStatusLabel,
          _getLocalizedRole(context, driver.role),
        ),
        _buildContractRow(
          AppLocalizations.of(context).salaryPerRaceLabel,
          '\$${(driver.salary / 24000).toStringAsFixed(1)}k',
        ),
        _buildContractRow(
          AppLocalizations.of(context).terminationLabel,
          '\$${(driver.salary / 1000).toStringAsFixed(0)}k',
        ),
        _buildContractRow(
          AppLocalizations.of(context).remainingLabel,
          AppLocalizations.of(
            context,
          ).seasonsRemaining(driver.contractYearsRemaining.toString()),
        ),
        const SizedBox(height: 16),
        Divider(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          height: 1,
        ),
        const SizedBox(height: 16),
        _buildContractRow(
          AppLocalizations.of(context).moraleLabel,
          '${(driver.stats[DriverStats.morale] ?? 0) ~/ 5}/20',
        ),
        _buildContractRow(
          AppLocalizations.of(context).marketabilityLabel,
          '${(driver.stats[DriverStats.marketability] ?? 0) ~/ 5}/20',
        ),
        _buildContractRow(
          "Market Value", // TODO localized
          '\$${(driver.marketValue / 1000).toStringAsFixed(0)}k',
        ),
        const SizedBox(height: 16),
        Divider(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          height: 1,
        ),
        const SizedBox(height: 24),
        Row(
          children: driver.isTransferListed
              ? [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancelTransfer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("CANCEL TRANSFER"),
                      ),
                    ),
                  ),
                ]
              : [
                  Expanded(
                    child: FilledButton(
                      onPressed: onTransferMarket,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("Transfer Market"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FilledButton(
                      onPressed: onRenew,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppLocalizations.of(context).renewContractBtn,
                        ),
                      ),
                    ),
                  ),
                ],
        ),
      ],
    );
  }

  Widget _buildColumnB(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkillsSection(context),
        const SizedBox(height: 32),
        _buildCareerStatsSummary(context),
      ],
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final theme = Theme.of(context);
    final allStats = driver.stats.entries
        .where(
          (e) =>
              e.key != DriverStats.morale && e.key != DriverStats.marketability,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).driverStatsSectionTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = (constraints.maxWidth - 32) / 3;
            // Ensure proper calculation even if width implies small layout
            final effectiveWidth = itemWidth < 50 ? 50.0 : itemWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 20,
              children: allStats.map((entry) {
                return SizedBox(
                  width: effectiveWidth,
                  child: _buildStatBar(context, entry.key, entry.value),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCareerStatsSummary(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).careerStatsTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).titlesStat,
                '${driver.championships}',
                Icons.emoji_events_rounded,
              ),
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).winsStat,
                '${driver.wins}',
                Icons.military_tech_rounded,
              ),
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).podiumsStat,
                '${driver.podiums}',
                Icons.star_rounded,
              ),
              _buildCareerStatCircle(
                context,
                AppLocalizations.of(context).racesStat,
                '${driver.races}',
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
                driver.statusTitle,
              ),
              triggerMode: TooltipTriggerMode.tap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DriverStatusService.getLocalizedTitle(
                        context,
                        driver.statusTitle,
                      ).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.help_outline_rounded,
                      size: 12,
                      color: theme.colorScheme.secondary.withValues(alpha: 0.7),
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

  Widget _buildColumnC(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChampionshipForm(context),
        const SizedBox(height: 24),
        _buildCareerHistory(context),
      ],
    );
  }

  Widget _buildChampionshipForm(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  AppLocalizations.of(context).championshipFormTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to standings (already in main layout usually)
                },
                child: Text(AppLocalizations.of(context).standingsBtn),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                AppLocalizations.of(context).posLabel,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '#--', // Fetching real position would require async in the card or passing it
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTinyTable(
            context,
            headers: [
              AppLocalizations.of(context).eventHeader,
              AppLocalizations.of(context).qHeader,
              AppLocalizations.of(context).rHeader,
              AppLocalizations.of(context).pHeader,
            ],
            flexValues: [3, 1, 1, 1],
            alignments: [
              TextAlign.left,
              TextAlign.center,
              TextAlign.center,
              TextAlign.center,
            ],
            rows: [], // Will be populated when history service is implemented
          ),
        ],
      ),
    );
  }

  Widget _buildCareerHistory(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).careerHistoryTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTinyTable(
            context,
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
              driver,
              teamName ?? AppLocalizations.of(context).historyIndividual,
              leagueName ?? '--',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPotentialStars(int potential) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < potential ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildContractRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(BuildContext context, String label, int value) {
    final theme = Theme.of(context);
    final displayValue = (value / 5).round();
    final progress = (value / 100.0).clamp(
      0.005,
      1.0,
    ); // Minimum width for color visibility

    final Color statColor = _getStatColor(displayValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatSkillName(context, label),
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: statColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: statColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              '$displayValue',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatColor(int value) {
    if (value == 0) return const Color(0xFFEF5350); // Red
    if (value >= 18) return const Color(0xFF2E7D32); // Dark Green
    if (value >= 14) return const Color(0xFF66BB6A); // Light Green
    if (value >= 10) return const Color(0xFF26C6DA); // Cyan
    if (value >= 6) return const Color(0xFFFFD54F); // Yellow
    return const Color(0xFFFF7043); // Orange
  }

  Widget _buildTinyTable(
    BuildContext context, {
    required List<String> headers,
    required List<List<String>> rows,
    double maxHeight = 120,
    List<int>? flexValues,
    List<int>? badgeColumns,
    List<TextAlign>? alignments,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: List.generate(headers.length, (i) {
            final alignment = alignments != null
                ? alignments[i]
                : TextAlign.left;
            return Expanded(
              flex: flexValues != null ? flexValues[i] : 1,
              child: Text(
                headers[i],
                textAlign: alignment,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            );
          }),
        ),
        const Divider(height: 12),
        SizedBox(
          height: maxHeight,
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).noDataAvailableYet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: rows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: List.generate(row.length, (i) {
                            final isBadge = badgeColumns?.contains(i) ?? false;
                            final alignment = alignments != null
                                ? alignments[i]
                                : TextAlign.left;
                            return Expanded(
                              flex: flexValues != null ? flexValues[i] : 1,
                              child: isBadge
                                  ? _buildBadge(context, row[i], alignment)
                                  : Text(
                                      row[i],
                                      textAlign: alignment,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            );
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String text, TextAlign alignment) {
    final theme = Theme.of(context);

    final alignmentMap = {
      TextAlign.left: Alignment.centerLeft,
      TextAlign.center: Alignment.center,
      TextAlign.right: Alignment.centerRight,
    };

    return Align(
      alignment: alignmentMap[alignment] ?? Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    int currentYearValue = currentYear ?? startYear;

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
