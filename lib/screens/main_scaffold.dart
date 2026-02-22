import 'package:flutter/material.dart';
import 'home/dashboard_screen.dart';
import 'engineering_screen.dart';
import 'standings_screen.dart';
import 'job_market_screen.dart';
import '../l10n/app_localizations.dart';

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
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: AppLocalizations.of(context).navHQ,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.build_circle),
              label: AppLocalizations.of(context).navGarage,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events),
              label: AppLocalizations.of(context).navSeason,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.groups),
              label: AppLocalizations.of(context).navMarket,
            ),
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
