import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/season_service.dart';
import '../../services/time_service.dart';
import '../../services/auth_service.dart';
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
import '../../widgets/common/dynamic_loading_indicator.dart';
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
  final String teamId;
  final Function(String)? onNavigate;

  const DashboardScreen({super.key, required this.teamId, this.onNavigate});

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
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const Scaffold(body: DynamicLoadingIndicator());
        }
        final user = userSnapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('managers')
              .doc(user.uid)
              .snapshots(),
          builder: (context, managerSnapshot) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(widget.teamId)
                  .snapshots(),
              builder: (context, teamSnapshot) {
                return StreamBuilder<Season?>(
                  stream: SeasonService().getActiveSeasonStream(),
                  builder: (context, seasonSnapshot) {
                    return StreamBuilder<List<AppNotification>>(
                      stream: NotificationService().getTeamNotifications(
                        widget.teamId,
                      ),
                      builder: (context, notificationsSnapshot) {
                        if (managerSnapshot.hasError || teamSnapshot.hasError) {
                          return Scaffold(
                            body: Center(child: Text("Data Load Error")),
                          );
                        }

                        if (!managerSnapshot.hasData || !teamSnapshot.hasData) {
                          return const Scaffold(
                            body: DynamicLoadingIndicator(),
                          );
                        }

                        final data = DashboardData(
                          user: user,
                          manager: managerSnapshot.data!.exists
                              ? ManagerProfile.fromMap(
                                  managerSnapshot.data!.data()
                                      as Map<String, dynamic>,
                                )
                              : null,
                          team: teamSnapshot.data!.exists
                              ? Team.fromMap(
                                  teamSnapshot.data!.data()
                                      as Map<String, dynamic>,
                                )
                              : null,
                          season: seasonSnapshot.data,
                          notifications: notificationsSnapshot.data ?? [],
                        );

                        if (data.manager == null || data.team == null) {
                          return const Scaffold(
                            body: DynamicLoadingIndicator(),
                          );
                        }

                        final manager = data.manager!;
                        final team = data.team!;
                        final season = data.season;
                        final notifications = data.notifications;

                        // Business Logic (Pre-calculated once per stream emission)
                        final currentRace = season != null
                            ? SeasonService().getCurrentRace(season)
                            : null;
                        final circuitId =
                            currentRace?.event.circuitId ?? 'generic';
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
                            team.weekStatus['practiceLaps']
                                as Map<String, dynamic>? ??
                            {};
                        for (var v in practiceLapsMap.values) {
                          if (v is int) totalPracticeLaps += v;
                        }

                        final driverSetups =
                            team.weekStatus['driverSetups']
                                as Map<String, dynamic>? ??
                            {};
                        final circuitProfile = CircuitService()
                            .getCircuitProfile(circuitId);

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
                                  builder: (context) => GarageScreen(
                                    teamId: team.id,
                                    circuitId: circuitId,
                                  ),
                                ),
                              );
                            } else if (currentStatus ==
                                RaceWeekStatus.qualifying) {
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
                            } else if (currentStatus ==
                                RaceWeekStatus.raceStrategy) {
                              if (seasonId == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RaceStrategyScreen(
                                    seasonId: seasonId,
                                    teamId: team.id,
                                    circuitId: circuitId,
                                  ),
                                ),
                              );
                            } else if (currentStatus == RaceWeekStatus.race ||
                                currentStatus == RaceWeekStatus.postRace) {
                              if (seasonId == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RaceLiveScreen(seasonId: seasonId),
                                ),
                              );
                            }
                          }
                        }

                        return Scaffold(
                          body: SafeArea(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TeamHeader(
                                    managerName:
                                        "${manager.name} ${manager.surname}",
                                    teamName: team.name,
                                  ),
                                  const SizedBox(height: 24),
                                  RaceStatusHero(
                                    currentStatus: currentStatus,
                                    circuitName:
                                        currentRace?.event.trackName ??
                                        "Grand Prix",
                                    countryCode:
                                        (currentRace?.event.countryCode ?? "—")
                                            .toUpperCase(),
                                    flagEmoji:
                                        currentRace?.event.flagEmoji ?? "🏁",
                                    targetDate: targetDate,
                                    qualyDate: qualyDate,
                                    raceDate: raceDate,
                                    onActionPressed: onHeroAction,
                                    totalLaps:
                                        currentRace?.event.totalLaps ?? 50,
                                    weatherPractice:
                                        currentRace?.event.weatherPractice ??
                                        'Sunny',
                                    weatherQualifying:
                                        currentRace?.event.weatherQualifying ??
                                        'Cloudy',
                                    weatherRace:
                                        currentRace?.event.weatherRace ??
                                        'Sunny',
                                    characteristics:
                                        circuitProfile.characteristics,
                                    aeroWeight: circuitProfile.aeroWeight,
                                    chassisWeight: circuitProfile.chassisWeight,
                                    powertrainWeight:
                                        circuitProfile.powertrainWeight,
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    AppLocalizations.of(context).quickView,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
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
                                                  (d
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >)['qualifying'] !=
                                                      null &&
                                                  d['isSetupSent'] == true,
                                            ),
                                        strategySubmitted:
                                            driverSetups.length >= 2 &&
                                            driverSetups.values.every(
                                              (d) =>
                                                  (d
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >)['race'] !=
                                                      null &&
                                                  d['isSetupSent'] == true,
                                            ),
                                        completedLaps: totalPracticeLaps,
                                        totalLaps:
                                            kMaxPracticeLapsPerDriver * 2,
                                      );

                                      final officeNewsColumn = Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            ).officeNewsTitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  letterSpacing: 1.5,
                                                  color: Colors.grey,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (notifications.isEmpty)
                                            Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .cardTheme
                                                    .color
                                                    ?.withValues(alpha: 0.5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.05),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .notifications_none_rounded,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    ).noNewNotifications,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontStyle:
                                                          FontStyle.italic,
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
                                                      onTap: () =>
                                                          NotificationService()
                                                              .markAsRead(
                                                                widget.teamId,
                                                                n.id,
                                                              ),
                                                      onDismiss: () =>
                                                          NotificationService()
                                                              .deleteNotification(
                                                                widget.teamId,
                                                                n.id,
                                                              ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                        ],
                                      );

                                      if (isWide) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
