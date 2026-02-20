import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/season_service.dart';
import '../../services/time_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_models.dart';
import '../../models/core_models.dart';
import 'dashboard_widgets.dart';
import '../office/finances_screen.dart';
import '../race/garage_screen.dart';
import '../race/qualifying_screen.dart';
import '../race/race_live_screen.dart';
import '../race/race_strategy_screen.dart';
import '../../services/circuit_service.dart';
import '../../services/notification_service.dart';
import '../../services/league_notification_service.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/press_news_card.dart';
import '../../utils/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  final String teamId;
  final Function(String)? onNavigate;

  const DashboardScreen({super.key, required this.teamId, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<DocumentSnapshot> _teamStream;
  late Stream<Season?> _seasonStream;

  // Manager stream depends on UID, so we memorize it locally
  Stream<DocumentSnapshot>? _managerStream;
  String? _currentManagerUid;

  @override
  void initState() {
    super.initState();
    _teamStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .snapshots();
    _seasonStream = SeasonService().getActiveSeasonStream().asBroadcastStream();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      _teamStream = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remove top-level SingleChildScrollView to allow Scaffold
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return Center(child: Text("Auth Error: ${authSnapshot.error}"));
        }
        if (!authSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final uid = authSnapshot.data!.uid;

        // Memoize manager stream
        if (_managerStream == null || _currentManagerUid != uid) {
          _currentManagerUid = uid;
          _managerStream = FirebaseFirestore.instance
              .collection('managers')
              .doc(uid)
              .snapshots();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _managerStream,
          builder: (context, managerSnapshot) {
            if (managerSnapshot.hasError) {
              return Center(
                child: Text("Manager Error: ${managerSnapshot.error}"),
              );
            }
            if (!managerSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final managerData =
                managerSnapshot.data!.data() as Map<String, dynamic>?;
            if (managerData == null) {
              return const Center(child: Text("Manager profile not found"));
            }
            final manager = ManagerProfile.fromMap(managerData);

            return StreamBuilder<DocumentSnapshot>(
              stream: _teamStream,
              builder: (context, teamSnapshot) {
                if (teamSnapshot.hasError) {
                  return Center(
                    child: Text("Team Error: ${teamSnapshot.error}"),
                  );
                }
                if (!teamSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teamData =
                    teamSnapshot.data!.data() as Map<String, dynamic>?;
                if (teamData == null) {
                  return _buildErrorState(context, "Team data not found");
                }
                final team = Team.fromMap(teamData);

                return StreamBuilder<Season?>(
                  stream: _seasonStream,
                  builder: (context, seasonSnapshot) {
                    if (seasonSnapshot.hasError) {
                      return Center(
                        child: Text("Season Error: ${seasonSnapshot.error}"),
                      );
                    }
                    final season = seasonSnapshot.data;
                    final currentRace = season != null
                        ? SeasonService().getCurrentRace(season)
                        : null;
                    final circuitName =
                        currentRace?.event.trackName ?? "Grand Prix";
                    final flagEmoji = currentRace?.event.flagEmoji ?? "🏁";
                    final countryCode = (currentRace?.event.countryCode ?? "—")
                        .toUpperCase();
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

                    // Calculate completed practice laps
                    final practiceLapsMap =
                        team.weekStatus['practiceLaps']
                            as Map<String, dynamic>? ??
                        {};
                    int totalPracticeLaps = 0;
                    for (var v in practiceLapsMap.values) {
                      if (v is int) totalPracticeLaps += v;
                    }

                    // Check driver setups status for real-time checklist
                    final driverSetups =
                        team.weekStatus['driverSetups']
                            as Map<String, dynamic>? ??
                        {};

                    void onHeroAction() {
                      if (widget.onNavigate != null) {
                        if (currentStatus == RaceWeekStatus.race) {
                          widget.onNavigate!('racing_day');
                        } else {
                          widget.onNavigate!('racing_setup');
                        }
                      } else {
                        // Fallback in case onNavigate is not provided
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

                    final circuitProfile = CircuitService().getCircuitProfile(
                      circuitId,
                    );

                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
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
                              circuitName: circuitName,
                              countryCode: countryCode,
                              flagEmoji: flagEmoji,
                              targetDate: targetDate,
                              onActionPressed: onHeroAction,
                              totalLaps: currentRace?.event.totalLaps ?? 50,
                              weatherPractice:
                                  currentRace?.event.weatherPractice ?? 'Sunny',
                              weatherQualifying:
                                  currentRace?.event.weatherQualifying ??
                                  'Cloudy',
                              weatherRace:
                                  currentRace?.event.weatherRace ?? 'Sunny',
                              characteristics: circuitProfile.characteristics,
                              aeroWeight: circuitProfile.aeroWeight,
                              chassisWeight: circuitProfile.chassisWeight,
                              powertrainWeight: circuitProfile.powertrainWeight,
                            ),

                            const SizedBox(height: 32),
                            Text(
                              "QUICK VIEW",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    letterSpacing: 1.5,
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 600;

                                final budgetCard = FinanceCard(
                                  budget: team.budget,
                                  onTap: () {
                                    if (widget.onNavigate != null) {
                                      widget.onNavigate!('mgmt_finances');
                                      return;
                                    }
                                    if (team.id.isEmpty) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FinancesScreen(teamId: team.id),
                                      ),
                                    );
                                  },
                                );

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
                                  totalLaps: kMaxPracticeLapsPerDriver * 2,
                                );

                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: budgetCard),
                                      const SizedBox(width: 16),
                                      Expanded(child: checklistCard),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      budgetCard,
                                      const SizedBox(height: 16),
                                      checklistCard,
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 32),
                            const SizedBox(height: 32),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isDesktop = constraints.maxWidth > 800;

                                final Widget pressNewsColumn = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PRESS NEWS",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            letterSpacing: 1.5,
                                            color: Colors.grey,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (season != null)
                                      StreamBuilder<List<LeagueNotification>>(
                                        stream: LeagueNotificationService()
                                            .getLeagueNotifications(
                                              season.leagueId,
                                            ),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            debugPrint(
                                              "Press News error: ${snapshot.error}",
                                            );
                                            return const Text(
                                              "Error loading news",
                                            );
                                          }
                                          final news = snapshot.data ?? [];
                                          if (news.isEmpty) {
                                            return _buildEmptyNews(context);
                                          }

                                          return LayoutBuilder(
                                            builder: (context, constraints) {
                                              final bool isWide =
                                                  constraints.maxWidth > 600;

                                              // If desktop, show up to 3 rows (6 cards).
                                              // If more than 6, it should scroll.
                                              // We limit the height to 3 rows * 130 approx = 400
                                              return SizedBox(
                                                height: isWide
                                                    ? (news.length > 2
                                                          ? 400
                                                          : 130)
                                                    : null,
                                                child: Scrollbar(
                                                  thumbVisibility: true,
                                                  child: GridView.builder(
                                                    shrinkWrap: !isWide,
                                                    physics: isWide
                                                        ? const AlwaysScrollableScrollPhysics()
                                                        : const NeverScrollableScrollPhysics(),
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: isWide
                                                              ? 2
                                                              : 1,
                                                          crossAxisSpacing: 16,
                                                          mainAxisSpacing: 12,
                                                          mainAxisExtent: 120,
                                                        ),
                                                    itemCount: news.length,
                                                    itemBuilder:
                                                        (context, index) =>
                                                            PressNewsCard(
                                                              notification:
                                                                  news[index],
                                                            ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      )
                                    else
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  ],
                                );

                                final Widget officeNewsColumn = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "OFFICE NEWS",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            letterSpacing: 1.5,
                                            color: Colors.grey,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    StreamBuilder<List<AppNotification>>(
                                      stream: NotificationService()
                                          .getTeamNotifications(widget.teamId),
                                      builder: (context, notifSnapshot) {
                                        if (notifSnapshot.hasError) {
                                          debugPrint(
                                            "Notification stream error: ${notifSnapshot.error}",
                                          );
                                          return Text(
                                            "Notifications unavailable",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          );
                                        }

                                        final notifications =
                                            notifSnapshot.data ?? [];
                                        if (notifications.isEmpty) {
                                          return Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .cardTheme
                                                  .color
                                                  ?.withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.05,
                                                ),
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
                                                  "No new notifications",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Column(
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
                                        );
                                      },
                                    ),
                                  ],
                                );

                                if (isDesktop) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: pressNewsColumn),
                                      const SizedBox(width: 24),
                                      Expanded(child: officeNewsColumn),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      pressNewsColumn,
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

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNews(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Row(
        children: [
          Icon(Icons.newspaper, color: Colors.grey),
          const SizedBox(width: 16),
          Text(
            "No news from the paddock yet.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
