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
          return const Center(child: CircularProgressIndicator());
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
              return const Center(child: CircularProgressIndicator());
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

class _DriversStandingsTab extends StatelessWidget {
  final FtgLeague league;
  final String? highlightTeamId;

  const _DriversStandingsTab({required this.league, this.highlightTeamId});

  @override
  Widget build(BuildContext context) {
    if (league.teams.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noTeamsAvailable));
    }

    final drivers = List<Driver>.from(league.drivers);
    final teamMap = {for (var t in league.teams) t.id: t.name};

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

    return _StandingsTable(
      flexValues: const [1, 4, 4, 1, 1, 1, 1, 2],
      columns: [
        l10n.standingsPos,
        l10n.standingsDriver,
        l10n.standingsTeam,
        l10n.rHeader,
        l10n.wHeader,
        l10n.pHeader,
        "Pl", // Pole
        l10n.standingsPoints,
      ],
      highlightIndices: drivers
          .asMap()
          .entries
          .where((e) => e.value.teamId == highlightTeamId)
          .map((e) => e.key)
          .toList(),
      rows: drivers
          .map(
            (d) => <String>[
              "#${ranks[d.id] ?? '-'}",
              d.name,
              teamMap[d.teamId] ?? '—',
              "${d.seasonRaces}",
              "${d.seasonWins}",
              "${d.seasonPodiums}",
              "${d.seasonPoles}",
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

  @override
  void initState() {
    super.initState();
    _fetchManagers();
  }

  Future<void> _fetchManagers() async {
    final futures = <Future<void>>[];
    for (var team in widget.league.teams) {
      futures.add(
        FirebaseFirestore.instance.collection('teams').doc(team.id).get().then((
          teamDoc,
        ) {
          if (teamDoc.exists) {
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

    final teams = List<Team>.from(widget.league.teams);

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

    return _StandingsTable(
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
                    _StandingsTable(
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

                        return _StandingsTable(
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

class _StandingsTable extends StatelessWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final List<int> flexValues;
  final List<int> highlightIndices;

  const _StandingsTable({
    required this.columns,
    required this.rows,
    required this.flexValues,
    this.highlightIndices = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FIXED HEADER
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: List.generate(columns.length, (i) {
              return Expanded(
                flex: flexValues[i],
                child: Text(
                  columns[i].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
        ),
        // SCROLLABLE DATA ROWS
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 0),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final isHighlighted = highlightIndices.contains(index);

                return Container(
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? const Color(0xFF00C853).withValues(alpha: 0.1)
                        : (index % 2 == 0
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.01)),
                    border: Border(
                      left: isHighlighted
                          ? const BorderSide(color: Color(0xFF00C853), width: 4)
                          : BorderSide.none,
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: List.generate(row.length, (i) {
                        final isPoints = i == row.length - 1;
                        final isPos = i == 0;

                        final textStyle = (isPoints || isPos)
                            ? GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: isHighlighted
                                    ? const Color(0xFF00C853)
                                    : (isPos
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : Colors.white.withValues(
                                              alpha: 0.9,
                                            )),
                                fontWeight: isHighlighted || isPoints
                                    ? FontWeight.w900
                                    : FontWeight.w500,
                              )
                            : GoogleFonts.inter(
                                fontSize: 12,
                                color: isHighlighted
                                    ? const Color(0xFF00C853)
                                    : Colors.white.withValues(alpha: 0.9),
                                fontWeight: isHighlighted
                                    ? FontWeight.w900
                                    : FontWeight.w500,
                              );

                        final content = row[i];

                        return Expanded(
                          flex: flexValues[i],
                          child: content is InlineSpan
                              ? Text.rich(
                                  content,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text(
                                  content.toString(),
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
