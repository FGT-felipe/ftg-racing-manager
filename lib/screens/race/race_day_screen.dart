import 'package:flutter/material.dart';
import '../../services/time_service.dart';
import '../../services/season_service.dart';
import '../../models/core_models.dart';
import 'race_live_screen.dart';

class RaceDayScreen extends StatelessWidget {
  final String teamId;

  const RaceDayScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Season?>(
      future: SeasonService().getActiveSeason(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final season = snapshot.data;
        if (season == null) {
          return const Center(child: Text("No active season found."));
        }

        final timeService = TimeService();
        final currentRace = SeasonService().getCurrentRace(season);

        // Determine if it's actually race day and in progress
        final status = timeService.getRaceWeekStatus(
          timeService.nowBogota,
          currentRace?.event.date,
        );

        if (status == RaceWeekStatus.race) {
          return RaceLiveScreen(seasonId: season.id, isEmbed: true);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "RACE DAY LOCKED",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentRace != null
                      ? "Next race: ${currentRace.event.trackName}"
                      : "No upcoming races scheduled.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                if (status == RaceWeekStatus.postRace) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "The race has already finished.",
                    style: TextStyle(color: Colors.tealAccent),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
