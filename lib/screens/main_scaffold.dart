import 'package:flutter/material.dart';
import 'home/dashboard_screen.dart';
import 'engineering_screen.dart';
import 'standings_screen.dart';
import 'job_market_screen.dart';

class MainScaffold extends StatefulWidget {
  final String teamId;

  const MainScaffold({super.key, required this.teamId});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(teamId: widget.teamId),
      EngineeringScreen(teamId: widget.teamId),
      const StandingsScreen(), // Office/Sponsors will go here or in a sub-page
      const JobMarketScreen(), // Paddock/Market
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'HQ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_circle),
              label: 'Garage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Paddock',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Market'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        ),
      ),
    );
  }
}
