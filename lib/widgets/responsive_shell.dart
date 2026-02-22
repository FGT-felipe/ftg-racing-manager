import 'package:flutter/material.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/engineering_screen.dart';
import '../screens/standings_screen.dart';
import '../screens/job_market_screen.dart';
import '../screens/office/finances_screen.dart';
import '../l10n/app_localizations.dart';

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
      FinancesScreen(teamId: widget.teamId), // Integrated Office
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
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.dashboard_rounded),
                      selectedIcon: const Icon(Icons.dashboard),
                      label: Text(AppLocalizations.of(context).navHQ),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.business_center_outlined),
                      selectedIcon: const Icon(Icons.business_center),
                      label: Text(AppLocalizations.of(context).navOffice),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.build_circle_outlined),
                      selectedIcon: const Icon(Icons.build_circle),
                      label: Text(AppLocalizations.of(context).navGarage),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.emoji_events_outlined),
                      selectedIcon: const Icon(Icons.emoji_events),
                      label: Text(AppLocalizations.of(context).navSeason),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.groups_outlined),
                      selectedIcon: const Icon(Icons.groups),
                      label: Text(AppLocalizations.of(context).navMarket),
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
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_rounded),
                    label: AppLocalizations.of(context).navHQ,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.business_center),
                    label: AppLocalizations.of(context).navOffice,
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
              ),
            ),
          );
        }
      },
    );
  }
}
