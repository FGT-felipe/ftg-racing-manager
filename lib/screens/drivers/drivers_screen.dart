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

class _DriversScreenState extends State<DriversScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Driver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current Drivers'),
            Tab(text: 'Youth Academy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCurrentDriversTab(), _buildYouthAcademyTab()],
      ),
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

  Widget _buildYouthAcademyTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Youth Academy Coming Soon',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Train and promote the next generation of champions.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
