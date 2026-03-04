import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ftg_racing_manager/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/core_models.dart';
import '../models/user_models.dart';
import '../models/domain/domain_models.dart';
import '../services/season_service.dart';
import '../services/universe_service.dart';
import '../widgets/common/onyx_table.dart';
import '../widgets/common/driver_stars.dart';
import '../widgets/common/onyx_skeleton.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  String? _selectedLeagueId;
  bool _initialized = false;

  void _initializeSelection(GameUniverse universe, String? userTeamId) {
    if (_initialized) return;

    // Default: try to find user's league (only if it's not tier 3)
    if (userTeamId != null) {
      for (final league in universe.leagues.where((l) => l.tier != 3)) {
        if (league.teams.any((t) => t.id == userTeamId)) {
          _selectedLeagueId = league.id;
          _initialized = true;
          return;
        }
      }
    }

    // Fallback: first non-tier 3 league
    final visibleLeagues = universe.leagues.where((l) => l.tier != 3).toList();
    if (visibleLeagues.isNotEmpty) {
      _selectedLeagueId = visibleLeagues.first.id;
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<GameUniverse?>(
      stream: UniverseService().getUniverseStream(),
      builder: (context, universeSnapshot) {
        if (!universeSnapshot.hasData) {
          return const StandingsSkeleton();
        }

        final universe = universeSnapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .where('managerId', isEqualTo: currentUser?.uid)
              .limit(1)
              .snapshots(),
          builder: (context, teamSnapshot) {
            if (!teamSnapshot.hasData) {
              return const StandingsSkeleton();
            }

            String? userTeamId;
            if (teamSnapshot.data!.docs.isNotEmpty) {
              userTeamId = teamSnapshot.data!.docs.first.id;
            }

            // Initialize selection if needed
            _initializeSelection(universe, userTeamId);

            // Get selected objects from filtered list
            final displayedLeagues = universe.leagues
                .where((l) => l.tier != 3)
                .toList();

            FtgLeague? selectedLeague;
            if (_selectedLeagueId != null) {
              try {
                selectedLeague = displayedLeagues.firstWhere(
                  (l) => l.id == _selectedLeagueId,
                );
              } catch (_) {}
            }

            if (selectedLeague == null && displayedLeagues.isNotEmpty) {
              selectedLeague = displayedLeagues.first;
              _selectedLeagueId = selectedLeague.id;
            }

            if (selectedLeague == null) {
              return Center(
                child: Text(AppLocalizations.of(context).noTeamsAvailable),
              );
            }

            final l10n = AppLocalizations.of(context);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER WITH DROPDOWNS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<Season?>(
                              future: SeasonService().getSeasonById(
                                selectedLeague.currentSeasonId,
                              ),
                              builder: (context, seasonSnapshot) {
                                final seasonYear =
                                    seasonSnapshot.data?.year ?? 2026;
                                return Text(
                                  "${l10n.standingsTitle} $seasonYear"
                                      .toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // LEAGUE DROPDOWN
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedLeague.id,
                            dropdownColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            items: displayedLeagues.map((league) {
                              return DropdownMenuItem(
                                value: league.id,
                                child: Text(
                                  league.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedLeagueId = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // MAIN CONTENT
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              indicatorColor: const Color(0xFF00C853),
                              labelColor: const Color(0xFF00C853),
                              unselectedLabelColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              indicatorSize: TabBarIndicatorSize.label,
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              tabs: [
                                Tab(text: l10n.navDrivers.toUpperCase()),
                                Tab(
                                  text: l10n.standingsConstructorTitle
                                      .toUpperCase(),
                                ),
                                Tab(text: l10n.raceResults.toUpperCase()),
                              ],
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _DriversStandingsTab(
                                    league: selectedLeague,
                                    highlightTeamId: userTeamId,
                                  ),
                                  _ConstructorsStandingsTab(
                                    league: selectedLeague,
                                    highlightTeamId: userTeamId,
                                  ),
                                  _LastRaceStandingsTab(
                                    seasonId: selectedLeague.currentSeasonId,
                                    highlightTeamId: userTeamId,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DriversStandingsTab extends StatefulWidget {
  final FtgLeague league;
  final String? highlightTeamId;

  const _DriversStandingsTab({required this.league, this.highlightTeamId});

  @override
  State<_DriversStandingsTab> createState() => _DriversStandingsTabState();
}

class _DriversStandingsTabState extends State<_DriversStandingsTab> {
  /// Live team names fetched from the authoritative `teams` collection.
  /// Falls back to universe snapshot names if fetch fails.
  Map<String, String> _liveTeamNames = {};

  @override
  void initState() {
    super.initState();
    _fetchLiveTeamNames();
  }

  @override
  void didUpdateWidget(covariant _DriversStandingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch if the league changed (e.g. league dropdown switch)
    if (oldWidget.league.id != widget.league.id) {
      _fetchLiveTeamNames();
    }
  }

  Future<void> _fetchLiveTeamNames() async {
    final teamIds = widget.league.teams.map((t) => t.id).toList();
    if (teamIds.isEmpty) return;

    final Map<String, String> names = {};
    // Firestore 'whereIn' limit is 30; batch if needed
    for (int i = 0; i < teamIds.length; i += 30) {
      final chunk = teamIds.sublist(
        i,
        i + 30 > teamIds.length ? teamIds.length : i + 30,
      );
      final snap = await FirebaseFirestore.instance
          .collection('teams')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        names[doc.id] = doc.data()['name'] as String? ?? '';
      }
    }

    if (mounted) {
      setState(() => _liveTeamNames = names);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.league.teams.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noTeamsAvailable));
    }

    final drivers = List<Driver>.from(widget.league.drivers);
    // Build team map with live names preferred, falling back to universe snapshot
    final teamMap = {
      for (var t in widget.league.teams) t.id: _liveTeamNames[t.id] ?? t.name,
    };

    drivers.sort((a, b) {
      if (b.seasonPoints != a.seasonPoints) {
        return b.seasonPoints.compareTo(a.seasonPoints);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    Map<String, int> ranks = {};
    for (int i = 0; i < drivers.length; i++) {
      ranks[drivers[i].id] = i + 1;
    }

    final l10n = AppLocalizations.of(context);

    return OnyxTable(
      flexValues: const [1, 4, 3, 4, 1, 1, 1, 2],
      columns: [
        l10n.standingsPos,
        l10n.standingsDriver,
        "POT",
        l10n.standingsTeam,
        l10n.rHeader,
        l10n.wHeader,
        l10n.pHeader,
        l10n.standingsPoints,
      ],
      highlightIndices: drivers
          .asMap()
          .entries
          .where((e) => e.value.teamId == widget.highlightTeamId)
          .map((e) => e.key)
          .toList(),
      rows: drivers
          .map(
            (d) => <dynamic>[
              "#${ranks[d.id] ?? '-'}",
              d.name,
              DriverStars(currentStars: d.currentStars, maxStars: d.potential),
              teamMap[d.teamId] ?? '—',
              "${d.seasonRaces}",
              "${d.seasonWins}",
              "${d.seasonPodiums}",
              "${d.seasonPoints}",
            ],
          )
          .toList(),
    );
  }
}

class _ConstructorsStandingsTab extends StatefulWidget {
  final FtgLeague league;
  final String? highlightTeamId;

  const _ConstructorsStandingsTab({required this.league, this.highlightTeamId});

  @override
  State<_ConstructorsStandingsTab> createState() =>
      _ConstructorsStandingsTabState();
}

class _ConstructorsStandingsTabState extends State<_ConstructorsStandingsTab> {
  final Map<String, ManagerProfile> _managersMap = {};

  /// Live team data fetched from the authoritative `teams` collection.
  /// Falls back to universe snapshot data if fetch fails.
  final Map<String, Team> _liveTeamsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchLiveData();
  }

  @override
  void didUpdateWidget(covariant _ConstructorsStandingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.league.id != widget.league.id) {
      _liveTeamsMap.clear();
      _managersMap.clear();
      _fetchLiveData();
    }
  }

  Future<void> _fetchLiveData() async {
    final futures = <Future<void>>[];
    for (var team in widget.league.teams) {
      futures.add(
        FirebaseFirestore.instance.collection('teams').doc(team.id).get().then((
          teamDoc,
        ) {
          if (teamDoc.exists) {
            // Capture live team data (name, season stats, etc.)
            if (mounted) {
              setState(() {
                _liveTeamsMap[team.id] = Team.fromMap(teamDoc.data()!);
              });
            }

            final managerId = teamDoc.data()?['managerId'] as String?;
            if (managerId != null && managerId.isNotEmpty) {
              return FirebaseFirestore.instance
                  .collection('managers')
                  .doc(managerId)
                  .get()
                  .then((managerDoc) {
                    if (managerDoc.exists && mounted) {
                      setState(() {
                        _managersMap[team.id] = ManagerProfile.fromMap(
                          managerDoc.data()!,
                        );
                      });
                    }
                  });
            }
          }
        }),
      );
    }
    await Future.wait(futures);
  }

  String _getFlagEmoji(String country) {
    final upperCountry = country.toUpperCase();
    const flags = {
      'BRAZIL': '🇧🇷',
      'ARGENTINA': '🇦🇷',
      'COLOMBIA': '🇨🇴',
      'MEXICO': '🇲🇽',
      'URUGUAY': '🇺🇾',
      'CHILE': '🇨🇱',
      'USA': '🇺🇸',
      'UNITED STATES': '🇺🇸',
      'ITALY': '🇮🇹',
      'SPAIN': '🇪🇸',
      'FRANCE': '🇫🇷',
      'GERMANY': '🇩🇪',
      'UNITED KINGDOM': '🇬🇧',
      'UK': '🇬🇧',
      'JAPAN': '🇯🇵',
      'NETHERLANDS': '🇳🇱',
      'CANADA': '🇨🇦',
      'AUSTRALIA': '🇦🇺',
    };
    return flags[upperCountry] ?? '🏁';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.league.teams.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noTeamsAvailable));
    }

    // Use live team data where available, falling back to universe snapshot
    final teams = widget.league.teams.map((universeTeam) {
      return _liveTeamsMap[universeTeam.id] ?? universeTeam;
    }).toList();

    teams.sort((a, b) {
      if (b.seasonPoints != a.seasonPoints) {
        return b.seasonPoints.compareTo(a.seasonPoints);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    Map<String, int> ranks = {};
    for (int i = 0; i < teams.length; i++) {
      ranks[teams[i].id] = i + 1;
    }

    final l10n = AppLocalizations.of(context);

    return OnyxTable(
      flexValues: const [1, 7, 1, 1, 1, 1, 2],
      columns: [
        l10n.standingsPos,
        l10n.standingsTeam,
        l10n.rHeader,
        l10n.wHeader,
        l10n.pHeader,
        "Pl",
        l10n.standingsPoints,
      ],
      highlightIndices: teams
          .asMap()
          .entries
          .where((e) => e.value.id == widget.highlightTeamId)
          .map((e) => e.key)
          .toList(),
      rows: teams.map((t) {
        final manager = _managersMap[t.id];
        final bool hasManager = manager != null;

        return <dynamic>[
          "#${ranks[t.id] ?? '-'}",
          TextSpan(
            children: [
              TextSpan(
                text: t.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (hasManager)
                TextSpan(
                  text:
                      '  (${_getFlagEmoji(manager.country)} ${manager.name} ${manager.surname})',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          "${t.seasonRaces}",
          "${t.seasonWins}",
          "${t.seasonPodiums}",
          "${t.seasonPoles}",
          "${t.seasonPoints}",
        ];
      }).toList(),
    );
  }
}

class _LastRaceStandingsTab extends StatelessWidget {
  final String seasonId;
  final String? highlightTeamId;

  const _LastRaceStandingsTab({required this.seasonId, this.highlightTeamId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: highlightTeamId != null
          ? FirebaseFirestore.instance
                .collection('teams')
                .doc(highlightTeamId)
                .get()
          : null,
      builder: (context, teamSnap) {
        String? playerTeamName;
        if (teamSnap.hasData && teamSnap.data!.exists) {
          playerTeamName =
              (teamSnap.data!.data() as Map<String, dynamic>)['name'];
        }

        return FutureBuilder<Season?>(
          future: SeasonService().getSeasonById(seasonId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final season = snapshot.data!;

            final lastRaceIndex = season.calendar.lastIndexWhere(
              (r) => r.isCompleted,
            );
            if (lastRaceIndex == -1) {
              return Center(
                child: Text(
                  AppLocalizations.of(context).noDataAvailableYet,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            final lastRaceEvent = season.calendar[lastRaceIndex];
            final raceId = SeasonService().raceDocumentId(
              season.id,
              lastRaceEvent,
            );

            return FutureBuilder<DocumentSnapshot>(
              future: SeasonService().getRaceDocument(raceId),
              builder: (context, raceSnapshot) {
                if (!raceSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final raceData =
                    raceSnapshot.data!.data() as Map<String, dynamic>?;
                if (raceData == null || raceData['qualifyingResults'] == null) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context).noDataAvailableYet,
                    ),
                  );
                }

                final results = List<Map<String, dynamic>>.from(
                  raceData['qualifyingResults'] ?? [],
                );

                final l10n = AppLocalizations.of(context);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      "${l10n.raceResults}: ${lastRaceEvent.trackName}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.raceDayRacePositions.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    OnyxTable(
                      flexValues: const [1, 4, 4, 2],
                      columns: [
                        l10n.standingsPos,
                        l10n.standingsDriver,
                        l10n.standingsTeam,
                        l10n.standingsPoints,
                      ],
                      highlightIndices: results
                          .take(10)
                          .toList()
                          .asMap()
                          .entries
                          .where((e) {
                            final name = e.value['teamName']?.toString().trim();
                            return name != null &&
                                name == playerTeamName?.trim();
                          })
                          .map((e) => e.key)
                          .toList(),
                      shrinkWrap: true,
                      rows: results.take(10).toList().asMap().entries.map((e) {
                        final pos = e.key + 1;
                        final points = [
                          25,
                          18,
                          15,
                          12,
                          10,
                          8,
                          6,
                          4,
                          2,
                          1,
                        ][e.key];
                        return <String>[
                          "$pos",
                          e.value['driverName'] ?? 'Unknown',
                          e.value['teamName'] ?? 'Unknown',
                          "+$points",
                        ];
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.standingsConstructorTitle.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final teamPointsMap = <String, int>{};
                        for (int i = 0; i < results.length; i++) {
                          final teamName = results[i]['teamName'] ?? 'Unknown';
                          final points = (i < 10)
                              ? [25, 18, 15, 12, 10, 8, 6, 4, 2, 1][i]
                              : 0;
                          teamPointsMap[teamName] =
                              (teamPointsMap[teamName] ?? 0) + points;
                        }
                        final constructorResults =
                            teamPointsMap.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));

                        return OnyxTable(
                          flexValues: const [1, 7, 2],
                          columns: [
                            l10n.standingsPos,
                            l10n.standingsTeam,
                            l10n.standingsPoints,
                          ],
                          highlightIndices: constructorResults
                              .asMap()
                              .entries
                              .where((e) {
                                final name = e.value.key.trim();
                                return name == playerTeamName?.trim();
                              })
                              .map((e) => e.key)
                              .toList(),
                          shrinkWrap: true,
                          rows: constructorResults.asMap().entries.map((e) {
                            return <String>[
                              "${e.key + 1}",
                              e.value.key,
                              "+${e.value.value}",
                            ];
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class StandingsSkeleton extends StatelessWidget {
  const StandingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const OnyxSkeleton(width: 150, height: 30, borderRadius: 4),
              const OnyxSkeleton(width: 120, height: 40, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 16),
          // Main Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        3,
                        (i) => const OnyxSkeleton(width: 80, height: 20),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 1,
                          child: OnyxSkeleton(height: 12),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 4,
                          child: OnyxSkeleton(height: 12),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 3,
                          child: OnyxSkeleton(height: 12),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 2,
                          child: OnyxSkeleton(height: 12),
                        ),
                      ],
                    ),
                  ),
                  // List Rows
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(0),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 10,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 1,
                                child: OnyxSkeleton(height: 14),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: OnyxSkeleton(
                                  height: 14,
                                  width: index % 2 == 0 ? 120 : 80,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: OnyxSkeleton(
                                  height: 14,
                                  width: index % 3 == 0 ? 100 : 60,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                flex: 2,
                                child: OnyxSkeleton(height: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
