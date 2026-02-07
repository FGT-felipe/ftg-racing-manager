import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/time_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_models.dart';
import '../../models/core_models.dart';
import 'dashboard_widgets.dart';
import '../office/office_screen.dart';
import '../race/garage_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String teamId;

  const DashboardScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: StreamBuilder<User?>(
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

                    // Time Service Integration
                    final timeService = TimeService();
                    final currentStatus = timeService.currentStatus;
                    final targetDate = timeService.nowBogota.add(
                      timeService.getTimeUntilNextEvent(),
                    );

                    final practiceLapsMap =
                        team.weekStatus['practiceLaps']
                            as Map<String, dynamic>? ??
                        {};
                    int totalPracticeLaps = 0;
                    for (var v in practiceLapsMap.values) {
                      if (v is int) totalPracticeLaps += v;
                    }

                    return Padding(
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
                            circuitName: "Interlagos Grand Prix",
                            countryCode: "br",
                            targetDate: targetDate,
                            onActionPressed: () {
                              if (currentStatus == RaceWeekStatus.practice) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GarageScreen(teamId: team.id),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Action for ${timeService.statusDisplayName} not implemented yet",
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          PreparationChecklist(
                            setupSubmitted:
                                team.weekStatus['qualifyingSetup'] != null &&
                                totalPracticeLaps >= 1,
                            strategySubmitted:
                                team.weekStatus['raceStrategy'] != null,
                            completedLaps: totalPracticeLaps,
                            totalLaps: 20,
                          ),

                          const SizedBox(height: 24),

                          FinanceCard(
                            budget: team.budget,
                            onTap: () {
                              if (team.id.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Error: Team ID is invalid"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OfficeScreen(teamId: team.id),
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
                    );
                  },
                );
              },
            );
          },
        ),
      ),
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
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Action for Contact Admin
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("CONTACT ADMIN"),
          ),
        ],
      ),
    );
  }
}
