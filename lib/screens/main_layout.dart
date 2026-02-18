import 'package:flutter/material.dart';
import 'home/dashboard_screen.dart';
import 'engineering_screen.dart';
import 'team/team_screen.dart';
import 'drivers/drivers_screen.dart';
import 'race/paddock_screen.dart';
import 'standings_screen.dart';
import 'office/finances_screen.dart';
import 'office/sponsorship_screen.dart';
import 'calendar/calendar_screen.dart';
import 'race/race_day_screen.dart';
import '../widgets/common/app_logo.dart';
import '../services/season_service.dart';
import '../services/time_service.dart';
import 'dart:async';

class MainLayout extends StatefulWidget {
  final String teamId;

  const MainLayout({super.key, required this.teamId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;
  bool _isRaceInProgress = false;
  Timer? _statusTimer;

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _checkRaceStatus();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkRaceStatus();
    });
    _views = [
      DashboardScreen(
        teamId: widget.teamId,
        onNavigate: (index) => _onItemTapped(index),
      ),
      EngineeringScreen(teamId: widget.teamId), // Car
      TeamScreen(teamId: widget.teamId),
      DriversScreen(teamId: widget.teamId),
      PaddockScreen(teamId: widget.teamId),
      RaceDayScreen(teamId: widget.teamId),
      const StandingsScreen(),
      FinancesScreen(teamId: widget.teamId),
      SponsorshipScreen(teamId: widget.teamId),
      CalendarScreen(teamId: widget.teamId),
    ];
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkRaceStatus() async {
    final season = await SeasonService().getActiveSeason();
    if (season == null) return;

    final currentRace = SeasonService().getCurrentRace(season);
    final status = TimeService().getRaceWeekStatus(
      TimeService().nowBogota,
      currentRace?.event.date,
    );

    if (mounted) {
      setState(() {
        _isRaceInProgress = status == RaceWeekStatus.race;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Global Header with Logo
    final globalAppBar = AppBar(
      title: AppLogo(size: 28, isDark: theme.brightness == Brightness.light),
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            // Future: Account settings
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Divider(
          height: 1,
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
    );

    // Navigation items configuration
    final navDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_rounded),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.directions_car_filled_outlined),
        selectedIcon: Icon(Icons.directions_car_filled),
        label: Text('Car'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.business_outlined),
        selectedIcon: Icon(Icons.business),
        label: Text('Team'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Drivers'),
      ),
      NavigationRailDestination(
        icon: Transform.rotate(
          angle: 0.5,
          child: const Icon(Icons.sports_score_outlined),
        ),
        selectedIcon: Transform.rotate(
          angle: 0.5,
          child: const Icon(Icons.sports_score),
        ),
        label: const Text('Padock'),
      ),
      NavigationRailDestination(
        icon: _BlinkingRaceIcon(
          inProgress: _isRaceInProgress,
          isSelected: false,
        ),
        selectedIcon: _BlinkingRaceIcon(
          inProgress: _isRaceInProgress,
          isSelected: true,
        ),
        label: const Text('Race Day'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.emoji_events_outlined),
        selectedIcon: Icon(Icons.emoji_events),
        label: Text('Standings'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.monetization_on_outlined),
        selectedIcon: Icon(Icons.monetization_on),
        label: Text('Finances'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.handshake_outlined),
        selectedIcon: Icon(Icons.handshake),
        label: Text('Sponsors'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: Text('Calendar'),
      ),
    ];

    final bottomNavItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.directions_car_filled),
        label: 'Car',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Team'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Drivers'),
      BottomNavigationBarItem(icon: Icon(Icons.sports_score), label: 'Padock'),
      BottomNavigationBarItem(
        icon: _BlinkingRaceIcon(
          inProgress: _isRaceInProgress,
          isSelected: false,
          isBottomNav: true,
        ),
        label: 'Race Day',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events),
        label: 'Standings',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.monetization_on),
        label: 'Finances',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.handshake), label: 'Sponsors'),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month),
        label: 'Calendar',
      ),
    ];

    return Scaffold(
      appBar: globalAppBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop Layout
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  extended: !_isCollapsed,
                  destinations: navDestinations,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  minExtendedWidth: 200,
                  leading: IconButton(
                    icon: Icon(_isCollapsed ? Icons.menu : Icons.menu_open),
                    onPressed: _toggleSidebar,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _views,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout
            return IndexedStack(index: _selectedIndex, children: _views);
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 900
          ? BottomNavigationBar(
              items: bottomNavItems,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 10,
            )
          : null,
    );
  }
}

class _BlinkingRaceIcon extends StatefulWidget {
  final bool inProgress;
  final bool isSelected;
  final bool isBottomNav;

  const _BlinkingRaceIcon({
    required this.inProgress,
    required this.isSelected,
    this.isBottomNav = false,
  });

  @override
  State<_BlinkingRaceIcon> createState() => _BlinkingRaceIconState();
}

class _BlinkingRaceIconState extends State<_BlinkingRaceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.inProgress) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BlinkingRaceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inProgress && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.inProgress && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.isSelected
        ? (widget.isBottomNav ? theme.primaryColor : theme.primaryColor)
        : (widget.isBottomNav
              ? Colors.grey
              : theme.iconTheme.color?.withValues(alpha: 0.5) ?? Colors.grey);

    if (!widget.inProgress) {
      return Icon(
        Icons.play_circle_outline,
        color: baseColor.withValues(alpha: 0.4),
      );
    }

    return FadeTransition(
      opacity: _animation,
      child: Icon(Icons.play_circle_filled, color: Colors.greenAccent),
    );
  }
}
