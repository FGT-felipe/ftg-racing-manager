import 'package:flutter/material.dart';
import '../../models/core_models.dart';
import '../../services/driver_assignment_service.dart';
import 'widgets/driver_card.dart';

class DriversScreen extends StatefulWidget {
  final String teamId;

  const DriversScreen({super.key, required this.teamId});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  late Future<List<Driver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _refreshDrivers();
  }

  void _refreshDrivers() {
    setState(() {
      _driversFuture = DriverAssignmentService().getDriversByTeam(
        widget.teamId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drivers Management')),
      body: _buildCurrentDriversTab(),
    );
  }

  Widget _buildCurrentDriversTab() {
    return FutureBuilder<List<Driver>>(
      future: _driversFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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
