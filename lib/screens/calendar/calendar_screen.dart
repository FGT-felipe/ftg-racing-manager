import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ftg_racing_manager/l10n/app_localizations.dart';
import '../../services/season_service.dart';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: season.calendar.length,
                itemBuilder: (context, index) {
                  final event = season.calendar[index];
                  final isCurrent =
                      !event.isCompleted &&
                      (index == 0 || season.calendar[index - 1].isCompleted);

                  return _buildCalendarItem(
                    context,
                    event,
                    index + 1,
                    isCurrent,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarItem(
    BuildContext context,
    RaceEvent event,
    int round,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateStr = DateFormat('MMM dd, yyyy').format(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.primaryColor.withValues(alpha: 0.1)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: theme.primaryColor, width: 2)
            : Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "R$round",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? theme.primaryColor : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(event.flagEmoji, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
        title: Text(
          event.trackName.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(dateStr, style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 12),
            const Icon(Icons.loop, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              "${event.totalLaps} ${l10n.lapsIntel}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        trailing: event.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.calendarStatusScheduled,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
