import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../services/driver_assignment_service.dart';
import '../../services/universe_service.dart';
import '../../services/season_service.dart';
import '../../services/transfer_market_service.dart';
import '../../widgets/common/onyx_table.dart';
import '../../widgets/common/driver_stars.dart';
import '../../widgets/common/onyx_skeleton.dart';
import 'widgets/driver_card.dart';
import 'widgets/transfer_options_modal.dart';
import 'widgets/renew_contract_modal.dart';
import '../../l10n/app_localizations.dart';

class DriversScreen extends StatefulWidget {
  final String teamId;

  const DriversScreen({super.key, required this.teamId});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  String? _teamName;
  String? _leagueName;
  int? _currentYear;

  @override
  void initState() {
    super.initState();
    _refreshDrivers();
  }

  void _refreshDrivers() async {
    // Fetch Team Name and League Name
    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();

      if (teamDoc.exists) {
        final teamData = teamDoc.data();
        if (mounted) {
          setState(() {
            _teamName = teamData?['name'];
          });
        }
      }

      final universe = await UniverseService().getUniverse();
      if (universe != null && mounted) {
        String? foundLeagueName;
        for (var league in universe.getAllLeagues()) {
          if (league.teams.any((t) => t.id == widget.teamId)) {
            foundLeagueName = league.name;
            break;
          }
        }
        setState(() {
          _leagueName = foundLeagueName;
        });
      }

      final activeSeason = await SeasonService().getActiveSeason();
      if (activeSeason != null && mounted) {
        setState(() {
          _currentYear = activeSeason.year;
        });
      }
    } catch (e) {
      debugPrint('Error fetching context names: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).driversManagementTitle),
      ),
      body: _buildCurrentDriversTab(),
    );
  }

  Widget _buildCurrentDriversTab() {
    return StreamBuilder<List<Driver>>(
      stream: DriverAssignmentService().streamDriversByTeam(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonTable();
        }

        if (snapshot.hasError) {
          debugPrint("Drivers stream error: ${snapshot.error}");
          return Center(
            child: Text(AppLocalizations.of(context).errorLoadingDrivers),
          );
        }

        final drivers = snapshot.data ?? [];

        if (drivers.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context).noDriversFound),
          );
        }

        return OnyxTable(
          flexValues: const [1, 3, 2, 3, 2, 2, 1, 1, 1],
          columns: const [
            "", // country_flag
            "Name",
            "Team Status",
            "Potential",
            "Morale",
            "Fitness",
            "Races",
            "Podiums",
            "Wins",
          ],
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];

            return Row(
              children: [
                // country_flag
                Expanded(
                  flex: 1,
                  child: Text(
                    _getFlagEmoji(driver.countryCode),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                // Name
                Expanded(
                  flex: 3,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showDriverDetail(context, driver),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (driver.portraitUrl != null &&
                              driver.portraitUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundImage: NetworkImage(
                                  driver.portraitUrl!,
                                ),
                                backgroundColor: Colors.white10,
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white10,
                                child: Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              driver.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white24,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Team Status
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTeamStatusBadge(driver),
                  ),
                ),
                // Potential
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DriverStars(
                      currentStars: driver.currentStars,
                      maxStars: driver.potential,
                    ),
                  ),
                ),
                // Morale
                Expanded(
                  flex: 2,
                  child: _buildStatValue(driver.getStat(DriverStats.morale)),
                ),
                // Fitness
                Expanded(
                  flex: 2,
                  child: _buildStatValue(driver.getStat(DriverStats.fitness)),
                ),
                // Races
                Expanded(
                  flex: 1,
                  child: Text(
                    driver.races.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Podiums
                Expanded(
                  flex: 1,
                  child: Text(
                    driver.podiums.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Wins
                Expanded(
                  flex: 1,
                  child: Text(
                    driver.wins.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatValue(int value) {
    Color color = Colors.green;
    if (value < 40) {
      color = Colors.red;
    } else if (value < 70) {
      color = Colors.orange;
    }
    return Text(
      "$value%",
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTeamStatusBadge(Driver driver) {
    String status = "Academy";
    Color color = Colors.grey;

    if (driver.carIndex == 0 || driver.carIndex == 1) {
      status = "Principal";
      color = const Color(0xFF00C853);
    } else if (driver.role == 'Reserve' || driver.role == 'Reserve Driver') {
      status = "Reserve";
      color = Colors.amber;
    } else if (driver.statusTitle.contains("Academy") ||
        driver.role == 'Young Driver' ||
        driver.role == 'Academy') {
      status = "Academy";
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSkeletonTable() {
    return OnyxTable(
      flexValues: const [1, 3, 2, 3, 2, 2, 1, 1, 1],
      columns: const [
        "",
        "Name",
        "Team Status",
        "Potential",
        "Morale",
        "Fitness",
        "Races",
        "Podiums",
        "Wins",
      ],
      itemCount: 5,
      itemBuilder: (context, index) {
        return Row(
          children: [
            const Expanded(flex: 1, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 8),
            const Expanded(flex: 3, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 8),
            const Expanded(flex: 2, child: OnyxSkeleton(height: 16)),
            const SizedBox(width: 8),
            const Expanded(flex: 3, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 8),
            const Expanded(flex: 2, child: OnyxSkeleton(height: 12)),
            const SizedBox(width: 8),
            const Expanded(flex: 2, child: OnyxSkeleton(height: 12)),
            const SizedBox(width: 8),
            const Expanded(flex: 1, child: OnyxSkeleton(height: 12)),
            const SizedBox(width: 8),
            const Expanded(flex: 1, child: OnyxSkeleton(height: 12)),
            const SizedBox(width: 8),
            const Expanded(flex: 1, child: OnyxSkeleton(height: 12)),
          ],
        );
      },
    );
  }

  String _getFlagEmoji(String countryCode) {
    // Basic flag conversion or hardcoded map
    final map = {
      'BR': '🇧🇷',
      'AR': '🇦🇷',
      'CO': '🇨🇴',
      'MX': '🇲🇽',
      'ES': '🇪🇸',
      'US': '🇺🇸',
      'GB': '🇬🇧',
      'FR': '🇫🇷',
      'DE': '🇩🇪',
      'IT': '🇮🇹',
      'JP': '🇯🇵',
    };
    return map[countryCode.toUpperCase()] ?? '🏁';
  }

  void _showDriverDetail(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DriverCard(
                    driver: driver,
                    teamName: _teamName,
                    leagueName: _leagueName,
                    currentYear: _currentYear,
                    onRenew: () {
                      Navigator.pop(ctx);
                      RenewContractModal.show(context, widget.teamId, driver);
                    },
                    onTransferMarket: () {
                      Navigator.pop(ctx);
                      TransferOptionsModal.show(context, widget.teamId, driver);
                    },
                    onCancelTransfer: () async {
                      try {
                        await TransferMarketService().cancelTransfer(
                          widget.teamId,
                          driver.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Transfer cancelled! Morale decreased.",
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
