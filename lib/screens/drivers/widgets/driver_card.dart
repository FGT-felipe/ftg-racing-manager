import 'package:flutter/material.dart';
import '../../../models/core_models.dart';
import '../../../services/driver_portrait_service.dart';

class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onRenew;
  final VoidCallback? onFire;
  final String? teamName;
  final String? divisionName;
  final int? currentYear;

  const DriverCard({
    super.key,
    required this.driver,
    this.onRenew,
    this.onFire,
    this.teamName,
    this.divisionName,
    this.currentYear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.secondary, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column A: Profile & Contract
          Expanded(flex: 2, child: _buildColumnA(context)),
          const VerticalDivider(
            width: 48,
            thickness: 1,
            indent: 10,
            endIndent: 10,
          ),
          // Combined Grid for B and C
          Expanded(
            flex: 7,
            child: Column(
              children: [
                // Row 1: Skills & Form
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildSkillsSection(context)),
                      const VerticalDivider(
                        width: 48,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      Expanded(flex: 4, child: _buildChampionshipForm(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Row 2: Career Details (Symmetrically aligned)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildCareerStatsSummary(context),
                      ),
                      const VerticalDivider(
                        width: 48,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      Expanded(flex: 4, child: _buildCareerHistory(context)),
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
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Age: ${driver.age}',
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
            Text(
              driver.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
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
          'CONTRACT DETAILS',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildContractRow('Status', driver.role),
        _buildContractRow(
          'Salary/Race',
          '\$${(driver.salary / 24000).toStringAsFixed(1)}k',
        ),
        _buildContractRow(
          'Termination',
          '\$${(driver.salary / 1000).toStringAsFixed(0)}k',
        ),
        _buildContractRow(
          'Remaining',
          '${driver.contractYearsRemaining} Season(s)',
        ),
        const SizedBox(height: 24),
        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onFire,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                child: const Text('Fire'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onRenew,
                child: const Text('Renew'),
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
    final allStats = driver.stats.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DRIVER STATS',
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
            return Wrap(
              spacing: 16,
              runSpacing: 20,
              children: allStats.map((entry) {
                return SizedBox(
                  width: itemWidth,
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
        children: [
          Text(
            'CAREER STATS',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCareerStatCircle(
                context,
                'WINS',
                '${driver.wins}',
                Icons.emoji_events_rounded,
              ),
              _buildCareerStatCircle(
                context,
                'PODIUMS',
                '${driver.podiums}',
                Icons.star_rounded,
              ),
              _buildCareerStatCircle(
                context,
                'RACES',
                '${driver.races}',
                Icons.flag_rounded,
              ),
            ],
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF15151E), // App Background
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.secondary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
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
              Text(
                'CHAMPIONSHIP FORM',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to standings (already in main layout usually)
                },
                child: const Text('Season Standings'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Pos: ', style: theme.textTheme.titleMedium),
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
            headers: ['Event', 'Qualy', 'Race', 'Pts'],
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
            'CAREER HISTORY',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTinyTable(
            context,
            headers: [
              'Season',
              'Team',
              'Championship',
              'Races',
              'Podiums',
              'Wins',
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
              driver,
              teamName ?? 'Individual',
              divisionName ?? '--',
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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          _formatSkillName(label),
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
                borderRadius: BorderRadius.circular(4),
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
                    borderRadius: BorderRadius.circular(4),
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
                    'No data available yet',
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

    return UnconstrainedBox(
      alignment: alignmentMap[alignment] ?? Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
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
    Driver driver,
    String currentTeam,
    String currentDiv,
  ) {
    final List<List<String>> rows = [];

    // Fila de la temporada actual (siempre 0 al inicio)
    rows.add([
      '${currentYear ?? 2026}',
      currentTeam,
      currentDiv,
      '0',
      '0',
      '0',
    ]);

    if (driver.races <= 0) return rows;

    // Generador estable basado en ID para que no cambie al refrescar la UI
    int remainingRaces = driver.races;
    int remainingPodiums = driver.podiums;
    int remainingWins = driver.wins;

    // Años a generar basados en la edad (máximo hasta 2020)
    int yearsPro = (driver.age - 20).clamp(1, 6);

    for (int i = 0; i < yearsPro; i++) {
      int year = 2025 - i;

      // Distribución de carreras (max 9 por año)
      int yearRaces = (remainingRaces / (yearsPro - i)).ceil();
      if (yearRaces > 9) yearRaces = 9;
      if (yearRaces > remainingRaces) yearRaces = remainingRaces;

      // Distribución de victorias y podios (más probable en años recientes por progresión)
      // Ajustamos un poco para que no sea todo lineal
      double weight = 1.0 - (i * 0.1); // Peso decreciente para años más viejos

      int yearWins = (remainingWins * (yearRaces / remainingRaces) * weight)
          .floor();
      if (yearWins > yearRaces) yearWins = yearRaces;

      int yearPodiums =
          (remainingPodiums * (yearRaces / remainingRaces) * weight).floor();
      if (yearPodiums > yearRaces) yearPodiums = yearRaces;
      if (yearPodiums < yearWins) yearPodiums = yearWins;

      rows.add([
        '$year',
        currentTeam,
        i == 0 ? currentDiv : 'División Inferior',
        '$yearRaces',
        '$yearPodiums',
        '$yearWins',
      ]);

      remainingRaces -= yearRaces;
      remainingPodiums -= yearPodiums;
      remainingWins -= yearWins;

      if (remainingRaces <= 0) break;
    }

    return rows;
  }

  String _formatSkillName(String key) {
    return key[0].toUpperCase() + key.substring(1);
  }

  String _getFlagEmoji(String countryCode) {
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
    return flags[countryCode.toUpperCase()] ?? '🏳️';
  }
}
