import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../services/driver_assignment_service.dart';
import '../../services/universe_service.dart';
import '../../services/season_service.dart';
import 'widgets/driver_card.dart';

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
      appBar: AppBar(title: const Text('Drivers Management')),
      body: _buildCurrentDriversTab(),
    );
  }

  Widget _buildCurrentDriversTab() {
    return StreamBuilder<List<Driver>>(
      stream: DriverAssignmentService().streamDriversByTeam(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("Drivers stream error: ${snapshot.error}");
          return const Center(
            child: Text('Error loading drivers. Please check your connection.'),
          );
        }

        final drivers = snapshot.data ?? [];

        if (drivers.isEmpty) {
          return const Center(child: Text('No drivers found for this team.'));
        }

        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return DriverCard(
              driver: driver,
              teamName: _teamName,
              leagueName: _leagueName,
              currentYear: _currentYear,
              onRenew: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Renewing contract for ${driver.name}... (Simulated)',
                    ),
                  ),
                );
              },
              onFire: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Firing ${driver.name}... (Simulated)'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
