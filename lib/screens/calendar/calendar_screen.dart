import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ftg_racing_manager/l10n/app_localizations.dart';
import '../../services/season_service.dart';
import '../../services/circuit_service.dart';
import '../../models/core_models.dart';

class CalendarScreen extends StatelessWidget {
  final String teamId;

  const CalendarScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Season?>(
      stream: SeasonService().getActiveSeasonStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final season = snapshot.data;
        final l10n = AppLocalizations.of(context);

        if (season == null || season.calendar.isEmpty) {
          return Center(child: Text(l10n.calendarNoEvents));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200
                ? 4
                : constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 650
                ? 2
                : 1;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SEASON ${season.year}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.calendarTitle,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = season.calendar[index];
                      final isCurrent =
                          !event.isCompleted &&
                          (index == 0 ||
                              season.calendar[index - 1].isCompleted);

                      return _buildCalendarGridItem(
                        context,
                        event,
                        index + 1,
                        isCurrent,
                      );
                    }, childCount: season.calendar.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarGridItem(
    BuildContext context,
    RaceEvent event,
    int round,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final circuit = CircuitService().getCircuitProfile(event.circuitId);
    final dateStr = DateFormat('MMM dd, yyyy').format(event.date);

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.primaryColor.withValues(alpha: 0.15)
            : theme.cardTheme.color?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? theme.primaryColor
              : theme.dividerColor.withValues(alpha: 0.1),
          width: isCurrent ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background text for ROUND
          Positioned(
            right: -10,
            top: -10,
            child: Text(
              "R$round",
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: theme.dividerColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.flagEmoji, style: const TextStyle(fontSize: 24)),
                    if (event.isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      )
                    else if (isCurrent)
                      _buildBadge(
                        l10n.calendarStatusScheduled,
                        theme.primaryColor,
                        Colors.black,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.trackName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(color: theme.hintColor, fontSize: 11),
                ),
                const Divider(height: 20),
                // Circuit Intel
                _buildIntelRow(
                  Icons.loop,
                  "${event.totalLaps} ${l10n.lapsIntel}",
                ),
                const SizedBox(height: 4),
                _buildIntelRow(
                  Icons.speed,
                  "SPEED: ${circuit.characteristics['Top Speed'] ?? 'N/A'}",
                ),
                const SizedBox(height: 4),
                _buildIntelRow(
                  Icons.settings_input_component,
                  "TYRE WEAR: ${circuit.characteristics['Tyre Wear'] ?? 'N/A'}",
                ),
                const SizedBox(height: 8),
                // Difficulty bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "TECH. DIFFICULTY",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          "${(circuit.difficulty * 10).toInt()}/10",
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: circuit.difficulty,
                        backgroundColor: theme.dividerColor.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          circuit.difficulty > 0.7
                              ? Colors.red
                              : circuit.difficulty > 0.4
                              ? Colors.orange
                              : Colors.green,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
