import 'package:flutter/material.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/engineering_screen.dart';
import '../screens/standings_screen.dart';
import '../screens/job_market_screen.dart';
import '../screens/office/office_screen.dart';

class ResponsiveMainScaffold extends StatefulWidget {
  final String teamId;

  const ResponsiveMainScaffold({super.key, required this.teamId});

  @override
  State<ResponsiveMainScaffold> createState() => _ResponsiveMainScaffoldState();
}

class _ResponsiveMainScaffoldState extends State<ResponsiveMainScaffold> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(teamId: widget.teamId),
      OfficeScreen(teamId: widget.teamId), // Integrated Office
      EngineeringScreen(teamId: widget.teamId),
      const StandingsScreen(),
      const JobMarketScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop / Web Layout (> 800px)
        if (constraints.maxWidth >= 800) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.9,
                  minWidth: 80,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_rounded),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('HQ'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.business_center_outlined),
                      selectedIcon: Icon(Icons.business_center),
                      label: Text('Office'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.build_circle_outlined),
                      selectedIcon: Icon(Icons.build_circle),
                      label: Text('Garage'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.emoji_events_outlined),
                      selectedIcon: Icon(Icons.emoji_events),
                      label: Text('Season'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(Icons.groups),
                      label: Text('Market'),
                    ),
                  ],
                ),
                // Vertical Divider
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Content Area
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1600,
                      ), // Max width for ultrawide fix
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Layout (< 800px)
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: IndexedStack(index: _selectedIndex, children: _pages),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    label: 'HQ',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.business_center),
                    label: 'Office',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.build_circle),
                    label: 'Garage',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events),
                    label: 'Season',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.groups),
                    label: 'Market',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
          );
        }
      },
    );
  }
}
