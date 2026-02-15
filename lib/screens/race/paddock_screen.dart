import 'package:flutter/material.dart';
import '../../models/core_models.dart';
import '../../services/time_service.dart';
import '../../services/season_service.dart';
import 'garage_screen.dart';
import 'qualifying_screen.dart';
import 'race_strategy_screen.dart';
import 'race_live_screen.dart';

class PaddockScreen extends StatefulWidget {
  final String teamId;

  const PaddockScreen({super.key, required this.teamId});

  @override
  State<PaddockScreen> createState() => _PaddockScreenState();
}

class _PaddockScreenState extends State<PaddockScreen> {
  @override
  Widget build(BuildContext context) {
    final timeService = TimeService();
    final status = timeService.currentStatus;

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

        final currentRace = SeasonService().getCurrentRace(season);
        final circuitId = currentRace?.event.circuitId;

        // Dispatch based on status
        switch (status) {
          case RaceWeekStatus.practice:
            return GarageScreen(
              teamId: widget.teamId,
              circuitId: circuitId,
              isEmbed: true,
            );
          case RaceWeekStatus.qualifying:
            return QualifyingScreen(
              seasonId: season.id,
              circuitId: circuitId,
              isEmbed: true,
            );
          case RaceWeekStatus.raceStrategy:
            return RaceStrategyScreen(
              seasonId: season.id,
              teamId: widget.teamId,
              circuitId: circuitId,
              isEmbed: true,
            );
          case RaceWeekStatus.race:
          case RaceWeekStatus.postRace:
            // Check if upcoming race is too far (meaning current finished)
            if (currentRace != null) {
              final now = timeService.nowBogota;
              final diff = currentRace.event.date.difference(now).inDays;
              if (diff > 4) {
                return const Center(
                  child: Text("Race weekend concluded. Check Standings."),
                );
              }
            }
            return RaceLiveScreen(seasonId: season.id, isEmbed: true);
        }
      },
    );
  }
}
