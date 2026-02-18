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
import '../../utils/app_constants.dart';

class DashboardScreen extends StatelessWidget {
  final String teamId;
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, required this.teamId, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    // Remove top-level SingleChildScrollView to allow Scaffold
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final uid = authSnapshot.data!.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('managers')
              .doc(uid)
              .snapshots(),
          builder: (context, managerSnapshot) {
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
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(teamId)
                  .snapshots(),
              builder: (context, teamSnapshot) {
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
                  stream: SeasonService().getActiveSeasonStream(),
                  builder: (context, seasonSnapshot) {
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

                    void onHeroAction() {
                      if (onNavigate != null) {
                        if (currentStatus == RaceWeekStatus.race) {
                          onNavigate!(5); // Index 5 is Race Day
                        } else {
                          onNavigate!(4); // Index 4 is Paddock/Padock
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
                            ),

                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isDesktop = constraints.maxWidth > 800;

                                final cardChecklist = PreparationChecklist(
                                  setupSubmitted:
                                      team.weekStatus['qualifyingSetup'] !=
                                          null &&
                                      totalPracticeLaps >= 1,
                                  strategySubmitted:
                                      team.weekStatus['raceStrategy'] != null,
                                  completedLaps: totalPracticeLaps,
                                  totalLaps: kMaxPracticeLapsPerDriver * 2,
                                );

                                final circuitProfile = CircuitService()
                                    .getCircuitProfile(circuitId);

                                final cardCircuit = CircuitInfoCard(
                                  circuitName: circuitName,
                                  flagEmoji: flagEmoji,
                                  totalLaps: currentRace?.event.totalLaps ?? 50,
                                  weatherPractice:
                                      currentRace?.event.weatherPractice ??
                                      'Sunny',
                                  weatherQualifying:
                                      currentRace?.event.weatherQualifying ??
                                      'Cloudy',
                                  weatherRace:
                                      currentRace?.event.weatherRace ?? 'Sunny',
                                  characteristics:
                                      circuitProfile.characteristics,
                                  aeroWeight: circuitProfile.aeroWeight,
                                  chassisWeight: circuitProfile.chassisWeight,
                                  powertrainWeight:
                                      circuitProfile.powertrainWeight,
                                );

                                if (isDesktop) {
                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(child: cardChecklist),
                                        const SizedBox(width: 16),
                                        Expanded(child: cardCircuit),
                                      ],
                                    ),
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      cardChecklist,
                                      const SizedBox(height: 16),
                                      cardCircuit,
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            FinanceCard(
                              budget: team.budget,
                              onTap: () {
                                if (onNavigate != null) {
                                  onNavigate!(7); // Index 7 is Finances
                                  return;
                                }
                                if (team.id.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Error: Team ID is invalid",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FinancesScreen(teamId: team.id),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            Text(
                              "PADDOCK RUMORS",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    letterSpacing: 1.5,
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: const [
                                  NewsItemCard(
                                    headline:
                                        "New technical regulations might favor engine power in 2027.",
                                    source: "Racing Daily",
                                  ),
                                  NewsItemCard(
                                    headline:
                                        "Rumors of a new street circuit in Buenos Aires growing stronger.",
                                    source: "Paddock Pass",
                                  ),
                                ],
                              ),
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
}
