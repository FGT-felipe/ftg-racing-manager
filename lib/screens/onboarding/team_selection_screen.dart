import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/core_models.dart';
import '../../models/domain/domain_models.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../services/universe_service.dart';
import '../../services/league_notification_service.dart';
import '../main_layout.dart';

class TeamSelectionScreen extends StatefulWidget {
  final String nationality;

  const TeamSelectionScreen({super.key, required this.nationality});

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  bool _isLoading = true;
  CountryLeague? _league;
  List<Team> _tier1Teams = [];
  List<Team> _tier2Teams = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeagueData();
  }

  Future<void> _loadLeagueData() async {
    try {
      final countryCode = _mapNationalityToCode(widget.nationality);
      final universe = await UniverseService().getUniverse();

      if (universe == null) {
        throw Exception("Game universe not initialized");
      }

      final league = universe.getLeagueByCountry(countryCode);
      if (league == null) {
        throw Exception("No league found for ${widget.nationality}");
      }

      // Fetch teams for each division
      final tier1Div = league.getDivisionByTier(1);
      final tier2Div = league.getDivisionByTier(2);

      final t1Teams = await _fetchAvailableTeams(tier1Div?.teamIds ?? []);
      final t2Teams = await _fetchAvailableTeams(tier2Div?.teamIds ?? []);

      if (mounted) {
        setState(() {
          _league = league;
          _tier1Teams = t1Teams;
          _tier2Teams = t2Teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _mapNationalityToCode(String nationality) {
    switch (nationality) {
      case 'Brazil':
        return 'BR';
      case 'Argentina':
        return 'AR';
      case 'Colombia':
        return 'CO';
      case 'Mexico':
        return 'MX';
      case 'Uruguay':
        return 'UY';
      case 'Chile':
        return 'CL';
      default:
        return 'BR';
    }
  }

  Future<List<Team>> _fetchAvailableTeams(List<String> teamIds) async {
    if (teamIds.isEmpty) return [];

    // Firestore 'in' query supports up to 10 items usually, but here we have exactly 10 ids per division.
    // However, to be safe and efficient, we can fetch all by IDs.
    // Or filter locally if list is small.
    // Query: teams where id IN [list] AND isBot == true

    if (teamIds.length > 10) {
      // Chunking if needed, but for now we expect 10
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('teams')
        .where(FieldPath.documentId, whereIn: teamIds)
        .where('isBot', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => Team.fromMap(doc.data())).toList();
  }

  Future<void> _handleApplyJob(Team team) async {
    // ... existing logic ...
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );

      final user = AuthService().currentUser;
      if (user == null) throw Exception("Auth failed");

      // Need reference to the specific team doc.
      // Since we used collectionGroup, we might lose the path if directly creating Team.
      // But we can reconstruct path: teams/{teamId} is usually root?
      // ACTUALLY, teams are in a root collection 'teams' as per Phase 4 TeamAssignmentService.

      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(team.id);

      // Claim the team for this manager
      await TeamService().claimTeam(teamRef, user.uid);

      // Trigger Press News notification
      try {
        final manager = await AuthService().getManagerProfile(user.uid);
        if (manager != null && _league != null) {
          await LeagueNotificationService().addLeagueNotification(
            leagueId: _league!.id,
            title: "NEW MANAGER ARRIVES",
            message:
                "${manager.name} ${manager.surname} has signed with ${team.name} to lead them in the ${_league!.name}!",
            type: "MANAGER_JOIN",
            managerName: "${manager.name} ${manager.surname}",
            teamName: team.name,
          );
        }
      } catch (e) {
        debugPrint("Error sending press news notification: $e");
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainLayout(teamId: team.id)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Application failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text('Error: $_errorMessage')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("SELECT TEAM - ${_league?.country.name.toUpperCase()}"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Choose a team to manage in the ${_league?.name}. Teams with fewer managers are recommended.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            if (_tier1Teams.isNotEmpty) ...[
              _buildDivisionSection(
                "Elite Division",
                _tier1Teams,
                isTier1: true,
              ),
              const SizedBox(height: 32),
            ],

            if (_tier2Teams.isNotEmpty) ...[
              _buildDivisionSection(
                "Professional Division",
                _tier2Teams,
                isTier1: false,
              ),
            ],

            if (_tier1Teams.isEmpty && _tier2Teams.isEmpty)
              const Center(child: Text("No teams available.")),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionSection(
    String title,
    List<Team> teams, {
    required bool isTier1,
  }) {
    // Recommendation logic:
    // If Tier 1 has fewer available bot teams (meaning more humans), it's more active?
    // User requested: "suggest always playing in leagues with more human players".
    // More humans = Fewer bot teams available.
    // So if available count is small, it's highly populated.
    // Let's mark as recommended if available count <= 5 (meaning >= 5 humans).

    final isRecommended = teams.length <= 8; // Arbitrary threshold

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (isRecommended) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  "RECOMMENDED",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final budgetInMillions = (team.budget / 1000000).toStringAsFixed(0);

            return _TeamSelectionCard(
              team: team,
              budgetFormatted: "\$${budgetInMillions}M",
              onApply: () => _handleApplyJob(team),
            );
          },
        ),
      ],
    );
  }
}

class _TeamSelectionCard extends StatelessWidget {
  final Team team;
  final String budgetFormatted;
  final VoidCallback onApply;

  const _TeamSelectionCard({
    required this.team,
    required this.budgetFormatted,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate stats average for display
    final stats =
        team.carStats['0'] ?? {'aero': 1, 'engine': 1, 'reliability': 1};
    final avgStats =
        ((stats['aero'] ?? 1) +
            (stats['engine'] ?? 1) +
            (stats['reliability'] ?? 1)) /
        3.0;
    final avgStatsStr = avgStats.toStringAsFixed(1);

    return Card(
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      budgetFormatted,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.speed, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Rating: $avgStatsStr",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  "SELECT TEAM",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
