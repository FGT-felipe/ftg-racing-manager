import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'hq/youth_academy_screen.dart';
import 'management/personal_screen.dart';
import 'hq_screen.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/breadcrumbs.dart';
import '../services/season_service.dart';
import '../services/time_service.dart';
import 'dart:async';

class NavNode {
  final String title;
  final Widget? screen;
  final List<NavNode>? children;
  final String id;

  NavNode({required this.title, this.screen, this.children, required this.id});
}

class MainLayout extends StatefulWidget {
  final String teamId;

  const MainLayout({super.key, required this.teamId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _selectedId = 'dashboard';
  String _activeParentId = 'dashboard';
  bool _isCollapsed = false;
  bool _isRaceInProgress = false;
  Timer? _statusTimer;

  late final List<NavNode> _navTree;
  late final List<NavNode> _flatLeaves;

  @override
  void initState() {
    super.initState();
    _checkRaceStatus();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkRaceStatus();
    });

    _navTree = [
      NavNode(
        id: 'dashboard',
        title: 'Dashboard',
        screen: DashboardScreen(
          teamId: widget.teamId,
          onNavigate: (index) {
            // Mapping index for compatibility if needed, but we use IDs now
          },
        ),
      ),
      NavNode(
        id: 'hq',
        title: 'HQ',
        screen: HQScreen(teamId: widget.teamId),
        children: [
          NavNode(
            id: 'hq_office',
            title: 'Team office',
            screen: TeamScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'hq_garage',
            title: 'Garage',
            screen: EngineeringScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'hq_academy',
            title: 'Youth Academy',
            screen: YouthAcademyScreen(teamId: widget.teamId),
          ),
        ],
      ),
      NavNode(
        id: 'racing',
        title: 'Racing',
        children: [
          NavNode(
            id: 'racing_setup',
            title: 'Weekend Setup',
            screen: PaddockScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'racing_day',
            title: 'Race day',
            screen: RaceDayScreen(teamId: widget.teamId),
          ),
        ],
      ),
      NavNode(
        id: 'management',
        title: 'Management',
        children: [
          NavNode(
            id: 'mgmt_personal',
            title: 'Personal',
            screen: PersonalScreen(
              teamId: widget.teamId,
              onDriversTap: () {
                final driversNode = _findNodeById('mgmt_drivers', _navTree);
                if (driversNode != null) _onNodeSelected(driversNode);
              },
            ),
            children: [
              NavNode(
                id: 'mgmt_drivers',
                title: 'Drivers',
                screen: DriversScreen(teamId: widget.teamId),
              ),
            ],
          ),
          NavNode(
            id: 'mgmt_finances',
            title: 'Finances',
            screen: FinancesScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'mgmt_sponsors',
            title: 'Sponsors',
            screen: SponsorshipScreen(teamId: widget.teamId),
          ),
        ],
      ),
      NavNode(
        id: 'season',
        title: 'Season',
        children: [
          NavNode(
            id: 'season_standings',
            title: 'Standings',
            screen: const StandingsScreen(),
          ),
          NavNode(
            id: 'season_calendar',
            title: 'Calendar',
            screen: CalendarScreen(teamId: widget.teamId),
          ),
        ],
      ),
    ];

    _flatLeaves = _getFlatLeaves(_navTree);
  }

  List<NavNode> _getFlatLeaves(List<NavNode> nodes) {
    List<NavNode> leaves = [];
    for (var node in nodes) {
      if (node.screen != null) {
        leaves.add(node);
      }
      if (node.children != null) {
        leaves.addAll(_getFlatLeaves(node.children!));
      }
    }
    return leaves;
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

  void _onNodeSelected(NavNode node) {
    setState(() {
      if (node.screen != null) {
        _selectedId = node.id;
        // Find parent to keep it active
        _activeParentId = _findParentId(node.id, _navTree) ?? node.id;
      } else if (node.children != null && node.children!.isNotEmpty) {
        // If it doesn't have a screen but has children, select the first child
        _onNodeSelected(node.children!.first);
      }
    });
  }

  NavNode? _findNodeById(String id, List<NavNode> nodes) {
    for (var node in nodes) {
      if (node.id == id) return node;
      if (node.children != null) {
        var found = _findNodeById(id, node.children!);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _findParentId(String childId, List<NavNode> nodes) {
    for (var node in nodes) {
      if (node.children != null) {
        for (var child in node.children!) {
          if (child.id == childId) return node.id;
          if (child.children != null) {
            String? grandParent = _findParentId(childId, [child]);
            if (grandParent != null) return node.id;
          }
        }
      }
    }
    return null;
  }

  List<NavNode> _getPathToNode(
    String id,
    List<NavNode> nodes, [
    List<NavNode>? currentPath,
  ]) {
    for (var node in nodes) {
      final newPath = <NavNode>[...(currentPath ?? []), node];
      if (node.id == id) return newPath;
      if (node.children != null) {
        final found = _getPathToNode(id, node.children!, newPath);
        if (found.isNotEmpty) return found;
      }
    }
    return [];
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width <= 900;

    return Scaffold(
      appBar: AppBar(
        title: AppLogo(size: 28, isDark: theme.brightness == Brightness.light),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
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
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              if (!isMobile)
                _Sidebar(
                  navTree: _navTree,
                  selectedId: _selectedId,
                  isCollapsed: _isCollapsed,
                  onNodeSelected: _onNodeSelected,
                  isRaceInProgress: _isRaceInProgress,
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      _SubNavbar(
                        navTree: _navTree,
                        activeParentId: _activeParentId,
                        selectedId: _selectedId,
                        onNodeSelected: _onNodeSelected,
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 16,
                                ),
                                child: Breadcrumbs(
                                  items: _getPathToNode(_selectedId, _navTree)
                                      .map(
                                        (node) => BreadcrumbItem(
                                          label: node.title,
                                          onTap: () => _onNodeSelected(node),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              Expanded(
                                child: IndexedStack(
                                  index: _flatLeaves.indexWhere(
                                    (n) => n.id == _selectedId,
                                  ),
                                  children: _flatLeaves
                                      .map((n) => n.screen!)
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Floating Sidebar Toggle
          if (!isMobile)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: _isCollapsed ? -12 : 250 - 12,
              top: 48,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: theme.colorScheme.secondary,
                  type: MaterialType.circle,
                  child: InkWell(
                    onTap: _toggleSidebar,
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _isCollapsed ? 0.5 : 0,
                        child: const Icon(
                          Icons.keyboard_double_arrow_left_rounded,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              items: _navTree.map((node) {
                return BottomNavigationBarItem(
                  icon: const SizedBox.shrink(), // No icons
                  label: node.title.toUpperCase(),
                );
              }).toList(),
              currentIndex: _navTree.indexWhere((n) => n.id == _activeParentId),
              onTap: (index) {
                var node = _navTree[index];
                _onNodeSelected(node);
              },
            )
          : null,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<NavNode> navTree;
  final String selectedId;
  final bool isCollapsed;
  final Function(NavNode) onNodeSelected;
  final bool isRaceInProgress;

  const _Sidebar({
    required this.navTree,
    required this.selectedId,
    required this.isCollapsed,
    required this.onNodeSelected,
    required this.isRaceInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 0 : 250,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: navTree.map((node) => _buildNode(node, 0)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(NavNode node, int depth) {
    final bool isSelected = selectedId == node.id;
    final bool hasChildren = node.children != null && node.children!.isNotEmpty;
    final theme = ThemeData.dark(); // Or inherit if needed, but sidebar is dark

    // Check if any child is selected for highlighting parent
    bool isAnyChildSelected = false;
    if (hasChildren) {
      isAnyChildSelected = _isDescendantSelected(node, selectedId);
    }

    final double paddingLeft = 16.0 + (depth * 16.0);
    final Color contentColor = (isSelected || isAnyChildSelected)
        ? (depth == 0 ? theme.colorScheme.secondary : Colors.white)
        : Colors.white54;
    final FontWeight fontWeight = (isSelected || isAnyChildSelected)
        ? FontWeight
              .w900 // Use Poppins Black style logic for main items
        : FontWeight.normal;
    final double fontSize = depth > 0 ? 12 : 14;

    if (!isCollapsed && hasChildren) {
      if (depth == 0) {
        // Level 1 items always show their children and have no chevron
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTile(
              node: node,
              depth: depth,
              isSelected: isSelected,
              contentColor: contentColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
              paddingLeft: paddingLeft,
            ),
            ...node.children!.map((child) => _buildNode(child, depth + 1)),
          ],
        );
      } else {
        // Level 2+ items use ExpansionTile for their submenus
        return Theme(
          data: theme.copyWith(
            dividerColor: Colors.transparent,
            hoverColor: Colors.white.withValues(alpha: 0.05),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.only(left: paddingLeft, right: 16.0),
            initiallyExpanded: isAnyChildSelected,
            title: Text(
              node.title.toUpperCase(),
              style: GoogleFonts.raleway(
                color: contentColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
            trailing: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: contentColor,
              size: 20,
            ),
            onExpansionChanged: (expanded) {
              if (node.screen != null) onNodeSelected(node);
            },
            children: node.children!
                .map((child) => _buildNode(child, depth + 1))
                .toList(),
          ),
        );
      }
    }

    return _buildTile(
      node: node,
      depth: depth,
      isSelected: isSelected,
      contentColor: contentColor,
      fontWeight: fontWeight,
      fontSize: fontSize,
      paddingLeft: paddingLeft,
    );
  }

  Widget _buildTile({
    required NavNode node,
    required int depth,
    required bool isSelected,
    required Color contentColor,
    required FontWeight fontWeight,
    required double fontSize,
    required double paddingLeft,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: paddingLeft, right: 16.0),
      title: isCollapsed
          ? null
          : Text(
              node.title.toUpperCase(),
              style: depth == 0
                  ? GoogleFonts.poppins(
                      color: contentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: fontSize,
                      letterSpacing: 1.2,
                    )
                  : GoogleFonts.raleway(
                      color: contentColor,
                      fontWeight: fontWeight,
                      fontSize: fontSize,
                    ),
            ),
      selected: isSelected,
      onTap: () => onNodeSelected(node),
    );
  }

  bool _isDescendantSelected(NavNode node, String selectedId) {
    if (node.children == null) return false;
    for (var child in node.children!) {
      if (child.id == selectedId) return true;
      if (_isDescendantSelected(child, selectedId)) return true;
    }
    return false;
  }
}

class _SubNavbar extends StatelessWidget {
  final List<NavNode> navTree;
  final String activeParentId;
  final String selectedId;
  final Function(NavNode) onNodeSelected;

  const _SubNavbar({
    required this.navTree,
    required this.activeParentId,
    required this.selectedId,
    required this.onNodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final parentNode = navTree.firstWhere(
      (n) => n.id == activeParentId,
      orElse: () => navTree.first,
    );
    if (parentNode.children == null || parentNode.children!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: parentNode.children!.length,
        itemBuilder: (context, index) {
          final child = parentNode.children![index];
          final isSelected =
              child.id == selectedId || _isChildSelected(child, selectedId);

          return IntrinsicWidth(
            child: InkWell(
              onTap: () {
                if (child.screen != null) {
                  onNodeSelected(child);
                } else if (child.children != null) {
                  onNodeSelected(child.children!.first);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? theme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  child.title,
                  style: GoogleFonts.raleway(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isChildSelected(NavNode node, String selectedId) {
    if (node.id == selectedId) return true;
    if (node.children == null) return false;
    for (var child in node.children!) {
      if (_isChildSelected(child, selectedId)) return true;
    }
    return false;
  }
}
