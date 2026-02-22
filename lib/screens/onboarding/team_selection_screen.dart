import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/core_models.dart';
import '../../models/domain/domain_models.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import '../../services/universe_service.dart';
import '../../models/user_models.dart';
import '../../widgets/common/dynamic_loading_indicator.dart';
import '../../l10n/app_localizations.dart';

class TeamSelectionScreen extends StatefulWidget {
  final String nationality;

  const TeamSelectionScreen({super.key, required this.nationality});

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  bool _isLoading = true;
  FtgLeague? _worldLeague;
  FtgLeague? _secondLeague;
  List<Team> _worldTeams = [];
  List<Team> _secondTeams = [];
  Map<String, List<Driver>> _driversByTeam = {};
  Map<String, ManagerProfile> _managersByTeam = {};
  bool _isWorldFull = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeagueData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLeagueData() async {
    try {
      final universe = await UniverseService().getUniverse();

      if (universe == null) {
        throw Exception("Game universe not initialized");
      }

      final worldLeague = universe.getLeagueById('ftg_world');
      final secondLeague = universe.getLeagueById('ftg_2th');

      if (worldLeague == null || secondLeague == null) {
        throw Exception("Required leagues not found");
      }

      // Fetch LIVE team data from Firestore (universe doc has stale isBot)
      final db = FirebaseFirestore.instance;

      Future<List<Team>> fetchLiveTeams(FtgLeague league) async {
        final liveTeams = <Team>[];
        for (final t in league.teams) {
          final doc = await db.collection('teams').doc(t.id).get();
          if (doc.exists) {
            liveTeams.add(Team.fromMap(doc.data()!));
          } else {
            liveTeams.add(t); // Fallback to universe snapshot
          }
        }
        return liveTeams;
      }

      final worldTeams = await fetchLiveTeams(worldLeague);
      final secondTeams = await fetchLiveTeams(secondLeague);

      // Fetch LIVE drivers from Firestore
      final Map<String, List<Driver>> driversByTeam = {};
      final allTeamIds = [
        ...worldTeams.map((t) => t.id),
        ...secondTeams.map((t) => t.id),
      ];
      for (final tid in allTeamIds) {
        final dSnap = await db
            .collection('drivers')
            .where('teamId', isEqualTo: tid)
            .get();
        if (dSnap.docs.isNotEmpty) {
          driversByTeam[tid] = dSnap.docs
              .map((d) => Driver.fromMap(d.data()))
              .toList();
        }
      }

      // Identify taken teams and fetch manager profiles
      final Map<String, ManagerProfile> managersByTeam = {};
      final List<Team> allTeams = [...worldTeams, ...secondTeams];

      for (var team in allTeams) {
        if (!team.isBot && team.managerId != null) {
          final manager = await AuthService().getManagerProfile(
            team.managerId!,
          );
          if (manager != null) {
            managersByTeam[team.id] = manager;
          }
        }
      }

      // Check if world league is full
      final worldFull = worldTeams.every((t) => !t.isBot);

      if (mounted) {
        setState(() {
          _worldLeague = worldLeague;
          _secondLeague = secondLeague;
          _worldTeams = worldTeams;
          _secondTeams = secondTeams;
          _driversByTeam = driversByTeam;
          _managersByTeam = managersByTeam;
          _isWorldFull = worldFull;
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
    } finally {
      // Clean up if needed
    }
  }

  Future<void> _handleApplyJob(
    Team team,
    String leagueId,
    String leagueName,
  ) async {
    final nav = Navigator.of(context); // Capture Navigator before async gaps
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).signingWithTeam(team.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );

      final user = AuthService().currentUser;
      if (user == null) throw Exception("Auth failed");

      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(team.id);

      // Claim the team for this manager
      await TeamService().claimTeam(teamRef, user.uid);

      // Trigger Press News notification
      try {
        final manager = await AuthService().getManagerProfile(user.uid);
        if (manager != null) {
          /*
          final drivers = _driversByTeam[team.id] ?? [];
          final mainDriverName = drivers.isNotEmpty
              ? drivers[0].name
              : "the main driver";
          final secondaryDriverName = drivers.length > 1
              ? drivers[1].name
              : "the secondary driver";

          await LeagueNotificationService().addLeagueNotification(
            leagueId: leagueId,
            title: "NEW MANAGER ARRIVES",
            message:
                "pressNewsManagerJoin", // We use the message field for the translation key
            type: "MANAGER_JOIN",
            managerName: "${manager.name} ${manager.surname}",
            teamName: team.name,
            payload: {
              "managerName": manager.name,
              "managerSurname": manager.surname,
              "teamName": team.name,
              "leagueName": leagueName,
              "roleManager": manager.role.title,
              "mainDriver": mainDriverName,
              "secondaryDriver": secondaryDriverName,
            },
          );
          */
        }
      } catch (e) {
        debugPrint("Error sending press news notification: $e");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).applicationFailed(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Regardless of success or failure, we MUST pop the loading dialog.
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: DynamicLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text('Error: $_errorMessage')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).selectTeamTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context).selectTeamDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            if (_worldTeams.isNotEmpty) ...[
              _buildDivisionSection(
                _worldLeague?.name ??
                    AppLocalizations.of(context).worldChampionship,
                _worldTeams,
                leagueId: _worldLeague?.id ?? '',
              ),
              const SizedBox(height: 32),
            ],

            if (_secondTeams.isNotEmpty) ...[
              _buildDivisionSection(
                _secondLeague?.name ??
                    AppLocalizations.of(context).secondSeries,
                _secondTeams,
                leagueId: _secondLeague?.id ?? '',
                isLocked: !_isWorldFull,
              ),
            ],

            if (_worldTeams.isEmpty && _secondTeams.isEmpty)
              Center(
                child: Text(AppLocalizations.of(context).noTeamsAvailable),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionSection(
    String title,
    List<Team> teams, {
    required String leagueId,
    bool isLocked = false,
  }) {
    // Recommendation logic: mark as recommended if available bot count <= 8
    final isRecommended = teams.where((t) => t.isBot).length <= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : Colors.white,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 12),
              Icon(Icons.lock, color: Colors.grey, size: 18),
            ],
            if (isRecommended && !isLocked) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  AppLocalizations.of(context).recommendedTag,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (isLocked)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              AppLocalizations.of(context).unlockLeagueDesc,
              style: TextStyle(
                color: Colors.orange.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio:
                1.5, // Increased logic to reduce card height vertically further.
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final budgetInMillions = (team.budget / 1000000).toStringAsFixed(0);
            final drivers = _driversByTeam[team.id] ?? [];
            final manager = _managersByTeam[team.id];

            return _TeamSelectionCard(
              team: team,
              budgetFormatted: "\$${budgetInMillions}M",
              drivers: drivers,
              manager: manager,
              isLocked: isLocked,
              onApply: isLocked
                  ? null
                  : () => _handleApplyJob(team, leagueId, title),
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
  final List<Driver> drivers;
  final ManagerProfile? manager;
  final bool isLocked;
  final VoidCallback? onApply;

  const _TeamSelectionCard({
    required this.team,
    required this.budgetFormatted,
    required this.drivers,
    this.manager,
    this.isLocked = false,
    this.onApply,
  });

  String _getFlagEmoji(String? country) {
    if (country == null) return '🏳️';
    final upperCountry = country.toUpperCase();

    // Map of codes and names to flags
    const flags = {
      'BR': '🇧🇷',
      'BRAZIL': '🇧🇷',
      'AR': '🇦🇷',
      'ARGENTINA': '🇦🇷',
      'CO': '🇨🇴',
      'COLOMBIA': '🇨🇴',
      'MX': '🇲🇽',
      'MEXICO': '🇲🇽',
      'UY': '🇺🇾',
      'URUGUAY': '🇺🇾',
      'CL': '🇨🇱',
      'CHILE': '🇨🇱',
      'GB': '🇬🇧',
      'UNITED KINGDOM': '🇬🇧',
      'UK': '🇬🇧',
      'DE': '🇩🇪',
      'GERMANY': '🇩🇪',
      'IT': '🇮🇹',
      'ITALY': '🇮🇹',
      'ES': '🇪🇸',
      'SPAIN': '🇪🇸',
      'FR': '🇫🇷',
      'FRANCE': '🇫🇷',
    };
    return flags[upperCountry] ?? '🏳️';
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = !team.isBot;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Card(
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isOccupied
                    ? Colors.amber.withValues(alpha: 0.3)
                    : isLocked
                    ? Colors.white10
                    : Colors.white24,
                width: 1,
              ),
            ),
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('blueprints/blueprintcars.png'),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isOccupied
                      ? [const Color(0xFF1A1A16), const Color(0xFF121210)]
                      : [const Color(0xFF1A1A1A), const Color(0xFF121212)],
                ),
              ),
              child: Opacity(
                opacity: isOccupied ? 0.7 : 1.0,
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
                            color: isLocked ? Colors.grey : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // Driver Info
                        ...drivers.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final driver = entry.value;
                          final label = idx == 0
                              ? AppLocalizations.of(context).mainDriverLabel
                              : AppLocalizations.of(
                                  context,
                                ).secondaryDriverLabel;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Text(
                                  "$label: ",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _getFlagEmoji(driver.countryCode),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  driver.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Manager info for occupied teams
                        if (isOccupied && manager != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Divider(color: Colors.white10),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${manager?.name} ${manager?.surname}",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              budgetFormatted,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!isOccupied && !isLocked)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            AppLocalizations.of(context).selectTeamBtn,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // "SELECTED" ribbon for occupied teams
          if (isOccupied)
            Positioned(
              top: 12,
              right: -30,
              child: Transform.rotate(
                angle: 0.785398, // 45 degrees
                child: Container(
                  width: 120,
                  color: Colors.amber.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    AppLocalizations.of(context).selectedTag,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
