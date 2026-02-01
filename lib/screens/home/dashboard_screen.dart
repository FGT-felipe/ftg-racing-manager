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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: AuthService().user,
          builder: (context, authSnapshot) {
            if (!authSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent),
              );
            }
            final uid = authSnapshot.data!.uid;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('managers')
                  .doc(uid)
                  .snapshots(),
              builder: (context, managerSnapshot) {
                if (!managerSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  );
                }

                final managerData =
                    managerSnapshot.data!.data() as Map<String, dynamic>?;
                if (managerData == null) {
                  return const Center(
                    child: Text(
                      "Manager profile not found",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                final manager = ManagerProfile.fromMap(managerData);

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('teams')
                      .doc(teamId)
                      .snapshots(),
                  builder: (context, teamSnapshot) {
                    if (!teamSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.tealAccent,
                        ),
                      );
                    }

                    final teamData =
                        teamSnapshot.data!.data() as Map<String, dynamic>?;
                    if (teamData == null) {
                      return _buildErrorState(context, "Team data not found");
                    }
                    final team = Team.fromMap(teamData);

                    return ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      children: [
                        TeamHeader(
                          managerName: "${manager.name} ${manager.surname}",
                          teamName: team.name,
                        ),
                        const SizedBox(height: 10),

                        StatusCard(
                          status: isRaceWeekend ? "Parc Fermé" : "Factory Open",
                          timeUntilRace: countdown,
                          isRaceWeekend: isRaceWeekend,
                        ),
                        const SizedBox(height: 24),

                        FinanceCard(
                          budget: team.budget,
                          onTap: () {
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

                        const Text(
                          "PADDOCK RUMORS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
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

                        _buildManagementTasks(team),
                      ],
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
          Text(message, style: const TextStyle(color: Colors.white70)),
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

  Widget _buildManagementTasks(Team team) {
    final practiceDone = team.weekStatus['practiceCompleted'] ?? false;
    final strategyDone = team.weekStatus['strategySet'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MANAGEMENT TASKS",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildTaskItem(Icons.psychology, "Practice Session", practiceDone),
        _buildTaskItem(Icons.settings_suggest, "Strategy Setup", strategyDone),
        _buildTaskItem(Icons.handshake, "Sponsor Review", false),
      ],
    );
  }

  Widget _buildTaskItem(IconData icon, String title, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: completed ? Colors.greenAccent : Colors.grey),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              color: completed ? Colors.white60 : Colors.white,
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
