import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/season_service.dart';
import '../../services/time_service.dart';
import '../../models/user_models.dart';
import '../../models/core_models.dart';
import 'dashboard_widgets.dart';

import '../race/garage_screen.dart';
import '../race/qualifying_screen.dart';
import '../race/race_live_screen.dart';
import '../race/race_strategy_screen.dart';
import '../../services/circuit_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_card.dart';
import '../../utils/app_constants.dart';
import '../../l10n/app_localizations.dart';

class DashboardData {
  final User? user;
  final ManagerProfile? manager;
  final Team? team;
  final Season? season;
  final List<AppNotification> notifications;

  DashboardData({
    this.user,
    this.manager,
    this.team,
    this.season,
    this.notifications = const [],
  });
}

class DashboardScreen extends StatefulWidget {
  final Team team;
  final ManagerProfile manager;
  final Season? season;
  final Function(String)? onNavigate;

  const DashboardScreen({
    super.key,
    required this.team,
    required this.manager,
    this.season,
    this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // No longer needed: manual stream management

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  // Removed manual stream consolidation logic to prevent memory leaks and redundant listeners

  @override
  Widget build(BuildContext context) {
    final manager = widget.manager;
    final team = widget.team;
    final season = widget.season;

    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService().getTeamNotifications(team.id),
      builder: (context, notificationsSnapshot) {
        final notifications = notificationsSnapshot.data ?? [];

        // Business Logic (Pre-calculated once per stream emission)
        final currentRace = season != null
            ? SeasonService().getCurrentRace(season)
            : null;
        final circuitId = currentRace?.event.circuitId ?? 'generic';
        final seasonId = season?.id;

        final timeService = TimeService();
        final currentStatus = timeService.getRaceWeekStatus(
          timeService.nowBogota,
          currentRace?.event.date,
        );
        final targetDate = timeService.nowBogota.add(
          timeService.getTimeUntilNextEvent(currentStatus),
        );
        final qualyDate = timeService.getCurrentWeekQualyDate(
          timeService.nowBogota,
          currentRace?.event.date,
        );
        final raceDate = timeService.getCurrentWeekRaceDate(
          timeService.nowBogota,
          currentRace?.event.date,
        );

        int totalPracticeLaps = 0;
        final practiceLapsMap =
            team.weekStatus['practiceLaps'] as Map<String, dynamic>? ?? {};
        for (var v in practiceLapsMap.values) {
          if (v is int) totalPracticeLaps += v;
        }

        final driverSetups =
            team.weekStatus['driverSetups'] as Map<String, dynamic>? ?? {};
        final circuitProfile = CircuitService().getCircuitProfile(circuitId);

        void onHeroAction() {
          if (widget.onNavigate != null) {
            if (currentStatus == RaceWeekStatus.race) {
              widget.onNavigate!('racing_day');
            } else {
              widget.onNavigate!('racing_setup');
            }
          } else {
            if (currentStatus == RaceWeekStatus.practice) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GarageScreen(teamId: team.id, circuitId: circuitId),
                ),
              );
            } else if (currentStatus == RaceWeekStatus.qualifying) {
              if (seasonId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QualifyingScreen(
                    seasonId: seasonId,
                    circuitId: circuitId,
                  ),
                ),
              );
            } else if (currentStatus == RaceWeekStatus.raceStrategy) {
              if (seasonId == null) return;
              final raceDocId = currentRace != null
                  ? SeasonService().raceDocumentId(seasonId, currentRace.event)
                  : null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RaceStrategyScreen(
                    seasonId: seasonId,
                    teamId: team.id,
                    circuitId: circuitId,
                    raceDocId: raceDocId,
                  ),
                ),
              );
            } else if (currentStatus == RaceWeekStatus.race ||
                currentStatus == RaceWeekStatus.postRace) {
              if (seasonId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RaceLiveScreen(seasonId: seasonId),
                ),
              );
            }
          }
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TeamHeader(
                    managerName: "${manager.name} ${manager.surname}",
                    teamName: team.name,
                  ),
                  const SizedBox(height: 24),
                  RaceStatusHero(
                    currentStatus: currentStatus,
                    circuitName: currentRace?.event.trackName ?? "Grand Prix",
                    countryCode: (currentRace?.event.countryCode ?? "—")
                        .toUpperCase(),
                    flagEmoji: currentRace?.event.flagEmoji ?? "🏁",
                    targetDate: targetDate,
                    qualyDate: qualyDate,
                    raceDate: raceDate,
                    onActionPressed: onHeroAction,
                    totalLaps: currentRace?.event.totalLaps ?? 50,
                    weatherPractice:
                        currentRace?.event.weatherPractice ?? 'Sunny',
                    weatherQualifying:
                        currentRace?.event.weatherQualifying ?? 'Cloudy',
                    weatherRace: currentRace?.event.weatherRace ?? 'Sunny',
                    characteristics: circuitProfile.characteristics,
                    aeroWeight: circuitProfile.aeroWeight,
                    chassisWeight: circuitProfile.chassisWeight,
                    powertrainWeight: circuitProfile.powertrainWeight,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context).quickView,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;

                      final checklistCard = PreparationChecklist(
                        setupSubmitted:
                            driverSetups.length >= 2 &&
                            driverSetups.values.every(
                              (d) =>
                                  (d as Map<String, dynamic>)['qualifying'] !=
                                      null &&
                                  d['isSetupSent'] == true,
                            ),
                        strategySubmitted:
                            driverSetups.length >= 2 &&
                            driverSetups.values.every(
                              (d) =>
                                  (d as Map<String, dynamic>)['race'] != null &&
                                  d['isSetupSent'] == true,
                            ),
                        completedLaps: totalPracticeLaps,
                        totalLaps: kMaxPracticeLapsPerDriver * 2,
                      );

                      final officeNewsColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).officeNewsTitle,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  letterSpacing: 1.5,
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (notifications.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF292A33),
                                    Color(0xFF1A1B23),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).noNewNotifications,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: notifications
                                  .take(3)
                                  .map(
                                    (n) => NotificationCard(
                                      notification: n,
                                      onTap: () => NotificationService()
                                          .markAsRead(team.id, n.id),
                                      onDismiss: () => NotificationService()
                                          .deleteNotification(team.id, n.id),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: checklistCard),
                            const SizedBox(width: 16),
                            Expanded(child: officeNewsColumn),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            checklistCard,
                            const SizedBox(height: 32),
                            officeNewsColumn,
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
