import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/time_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_models.dart';
import '../../models/core_models.dart';
import 'dashboard_widgets.dart';
import '../office/office_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String teamId;

  const DashboardScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final timeService = TimeService();
    final phase = timeService.getCurrentPhase();
    final isRaceWeekend = phase == "RACE_WEEKEND";
    final countdown = timeService.formatDuration(
      timeService.getTimeUntilRace(),
    );

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
                          const SizedBox(height: 20),

                          StatusCard(
                            status: isRaceWeekend
                                ? "Parc Fermé"
                                : "Factory Open",
                            timeUntilRace: countdown,
                            isRaceWeekend: isRaceWeekend,
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
                                ?.copyWith(letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height:
                                120, // Increased height for Card usage inside NewsItem
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

                          _buildManagementTasks(context, team),
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

  Widget _buildManagementTasks(BuildContext context, Team team) {
    final practiceDone = team.weekStatus['practiceCompleted'] ?? false;
    final strategyDone = team.weekStatus['strategySet'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MANAGEMENT TASKS",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildTaskItem(
          context,
          Icons.psychology,
          "Practice Session",
          practiceDone,
        ),
        _buildTaskItem(
          context,
          Icons.settings_suggest,
          "Strategy Setup",
          strategyDone,
        ),
        _buildTaskItem(context, Icons.handshake, "Sponsor Review", false),
      ],
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    IconData icon,
    String title,
    bool completed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: completed ? Colors.greenAccent : Colors.grey),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              color: completed
                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                  : Theme.of(context).colorScheme.onSurface,
              decoration: completed ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (completed)
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
          else
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
