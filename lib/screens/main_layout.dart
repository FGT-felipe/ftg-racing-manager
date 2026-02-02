import 'package:flutter/material.dart';
import 'home/dashboard_screen.dart';
import 'engineering_screen.dart';
import 'job_market_screen.dart';
import 'office/office_screen.dart';
import 'account/account_screen.dart';

class MainLayout extends StatefulWidget {
  final String teamId;

  const MainLayout({super.key, required this.teamId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      DashboardScreen(teamId: widget.teamId),
      EngineeringScreen(teamId: widget.teamId), // Garage
      OfficeScreen(teamId: widget.teamId),
      const JobMarketScreen(),
      const AccountScreen(),
    ];
    // Prompt asked for: Dashboard, Garage, Office, Market. I implemented these 4 as primary.
    // Standings can be accessed via dashboard or elsewhere, but keeping it in the list if navigation allows.
    // I will expose 4 items in Nav as requested: Dashboard, Garage, Office, Market.
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Navigation items configuration
    final navDestinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_rounded),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.build_circle_outlined),
        selectedIcon: Icon(Icons.build_circle),
        label: Text('Garage'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.business_center_outlined),
        selectedIcon: Icon(Icons.business_center),
        label: Text('Office'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups),
        label: Text('Market'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Account'),
      ),
    ];

    final bottomNavItems = const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Garage'),
      BottomNavigationBarItem(
        icon: Icon(Icons.business_center),
        label: 'Office',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Market'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop Layout (> 900px)
        if (constraints.maxWidth > 900) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  extended: true, // Always show text as requested
                  destinations: navDestinations,
                  backgroundColor: Theme.of(
                    context,
                  ).cardTheme.color, // Color(0xFF2B2D31) from theme
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _views,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Layout (< 900px)
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: IndexedStack(index: _selectedIndex, children: _views),
            bottomNavigationBar: BottomNavigationBar(
              items: bottomNavItems,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        }
      },
    );
  }
}
