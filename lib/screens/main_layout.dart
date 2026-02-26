import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
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
import 'market/transfer_market_screen.dart';
import 'hq_screen.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/new_badge.dart';
import '../widgets/common/breadcrumbs.dart';
import '../services/season_service.dart';
import '../services/time_service.dart';
import '../services/notification_service.dart';
import '../models/core_models.dart';
import '../models/user_model.dart';
import '../widgets/notification_card.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';

class NavNode {
  final String Function(BuildContext) titleBuilder;
  final Widget? screen;
  final List<NavNode>? children;
  final String id;
  final bool showNewBadge;

  NavNode({
    required this.titleBuilder,
    this.screen,
    this.children,
    required this.id,
    this.showNewBadge = false,
  });
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
  final List<AppNotification> _activeOverlayNotifications = [];
  OverlayEntry? _notificationsOverlayEntry;
  Timer? _statusTimer;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  Set<String> _knownNotificationIds = {};
  bool _firstLoad = true;
  AppUser? _appUser;
  final LayerLink _accountLayerLink = LayerLink();
  OverlayEntry? _accountOverlayEntry;
  bool _isAccountCardOpen = false;

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
        titleBuilder: (context) => AppLocalizations.of(context).navDashboard,
        screen: DashboardScreen(
          teamId: widget.teamId,
          onNavigate: (id) {
            final node = _findNodeById(id, _navTree);
            if (node != null) _onNodeSelected(node);
          },
        ),
      ),
      NavNode(
        id: 'hq',
        titleBuilder: (context) => AppLocalizations.of(context).navHQ,
        screen: HQScreen(
          teamId: widget.teamId,
          onNavigate: (id) {
            final node = _findNodeById(id, _navTree);
            if (node != null) _onNodeSelected(node);
          },
        ),
        children: [
          NavNode(
            id: 'hq_office',
            titleBuilder: (context) =>
                AppLocalizations.of(context).navTeamOffice,
            screen: TeamScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'hq_garage',
            titleBuilder: (context) => AppLocalizations.of(context).navGarage,
            screen: EngineeringScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'hq_academy',
            titleBuilder: (context) =>
                AppLocalizations.of(context).navYouthAcademy,
            screen: YouthAcademyScreen(teamId: widget.teamId),
          ),
        ],
      ),
      NavNode(
        id: 'racing',
        titleBuilder: (context) => AppLocalizations.of(context).navRacing,
        children: [
          NavNode(
            id: 'racing_setup',
            titleBuilder: (context) =>
                AppLocalizations.of(context).navWeekendSetup,
            screen: PaddockScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'racing_day',
            titleBuilder: (context) => AppLocalizations.of(context).navRaceDay,
            screen: RaceDayScreen(teamId: widget.teamId),
          ),
        ],
      ),
      NavNode(
        id: 'market',
        titleBuilder: (context) => "Transfer Market",
        screen: TransferMarketScreen(teamId: widget.teamId),
        showNewBadge: true,
      ),
      NavNode(
        id: 'management',
        titleBuilder: (context) => AppLocalizations.of(context).navManagement,
        children: [
          NavNode(
            id: 'mgmt_personal',
            titleBuilder: (context) => AppLocalizations.of(context).navPersonal,
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
                titleBuilder: (context) =>
                    AppLocalizations.of(context).navDrivers,
                screen: DriversScreen(teamId: widget.teamId),
              ),
            ],
          ),
          NavNode(
            id: 'mgmt_finances',
            titleBuilder: (context) => AppLocalizations.of(context).navFinances,
            screen: FinancesScreen(teamId: widget.teamId),
          ),
          NavNode(
            id: 'mgmt_sponsors',
            titleBuilder: (context) => AppLocalizations.of(context).navSponsors,
            screen: SponsorshipScreen(teamId: widget.teamId),
          ),
        ],
      ),
      NavNode(
        id: 'season',
        titleBuilder: (context) => AppLocalizations.of(context).navSeason,
        children: [
          NavNode(
            id: 'season_standings',
            titleBuilder: (context) =>
                AppLocalizations.of(context).navStandings,
            screen: const StandingsScreen(),
          ),
          NavNode(
            id: 'season_calendar',
            titleBuilder: (context) => AppLocalizations.of(context).navCalendar,
            screen: CalendarScreen(teamId: widget.teamId),
          ),
        ],
      ),
    ];

    _flatLeaves = _getFlatLeaves(_navTree);
    _setupNotificationListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertNotificationsOverlay();
    });
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final appUser = await AuthService().getAppUser(user.uid);
      if (mounted) {
        setState(() {
          _appUser = appUser;
        });
      }
    }
  }

  void _toggleAccountCard() {
    if (_isAccountCardOpen) {
      _closeAccountCard();
    } else {
      _openAccountCard();
    }
  }

  void _openAccountCard() {
    _accountOverlayEntry = _createAccountOverlayEntry();
    Overlay.of(context).insert(_accountOverlayEntry!);
    setState(() {
      _isAccountCardOpen = true;
    });
  }

  void _closeAccountCard() {
    _accountOverlayEntry?.remove();
    _accountOverlayEntry = null;
    setState(() {
      _isAccountCardOpen = false;
    });
  }

  OverlayEntry _createAccountOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeAccountCard,
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _accountLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(
                -250,
                48,
              ), // Adjust to show below and to the left
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1A1A1A), // Onyx background
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).accountInfo,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        AppLocalizations.of(context).emailLabel,
                        _appUser?.email ??
                            FirebaseAuth.instance.currentUser?.email ??
                            AppLocalizations.of(context).notAvailable,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        AppLocalizations.of(context).registeredLabel,
                        _appUser != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(_appUser!.registrationDate)
                            : AppLocalizations.of(context).notAvailable,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        AppLocalizations.of(context).lastSession,
                        FirebaseAuth
                                    .instance
                                    .currentUser
                                    ?.metadata
                                    .lastSignInTime !=
                                null
                            ? DateFormat('MMM dd, yyyy HH:mm').format(
                                FirebaseAuth
                                    .instance
                                    .currentUser!
                                    .metadata
                                    .lastSignInTime!,
                              )
                            : AppLocalizations.of(context).notAvailable,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.raleway(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    _closeAccountCard();
    await AuthService().signOut();
  }

  void _insertNotificationsOverlay() {
    _notificationsOverlayEntry = OverlayEntry(
      builder: (context) => _buildNotificationsOverlay(context),
    );
    Overlay.of(context).insert(_notificationsOverlayEntry!);
  }

  Widget _buildNotificationsOverlay(BuildContext context) {
    if (_activeOverlayNotifications.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      right: 24,
      width: 400, // Slightly wider for better readability
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _activeOverlayNotifications.reversed.map((notification) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: NotificationCard(
                notification: notification,
                onDismiss: () => _removeNotificationFromOverlay(notification),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _removeNotificationFromOverlay(AppNotification notification) {
    _activeOverlayNotifications.removeWhere((n) => n.id == notification.id);
    _notificationsOverlayEntry?.markNeedsBuild();
  }

  void _setupNotificationListener() {
    _notificationSubscription = NotificationService()
        .getTeamNotifications(widget.teamId)
        .listen((notifications) {
          if (_firstLoad) {
            _knownNotificationIds = notifications.map((n) => n.id).toSet();
            _firstLoad = false;
            return;
          }

          for (final n in notifications) {
            if (!_knownNotificationIds.contains(n.id)) {
              _knownNotificationIds.add(n.id);
              // Only show if it's recent (e.g., < 1 minute old)
              if (n.timestamp.isAfter(
                DateTime.now().subtract(const Duration(minutes: 1)),
              )) {
                _showNotificationOverlay(n);
                break; // Show only one at a time to avoid overlap
              }
            }
          }
        });
  }

  void _showNotificationOverlay(AppNotification notification) {
    // Add to list
    _activeOverlayNotifications.add(notification);
    _notificationsOverlayEntry?.markNeedsBuild();

    // Auto remove after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      _removeNotificationFromOverlay(notification);
    });
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
    _notificationSubscription?.cancel();
    _notificationsOverlayEntry?.remove();
    _notificationsOverlayEntry = null;
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

  Widget _buildEconomyStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Text(
            label.toUpperCase(),
            style: GoogleFonts.raleway(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
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
        title: Row(
          children: [
            AppLogo(size: 28, isDark: theme.brightness == Brightness.light),
            const SizedBox(width: 24),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(widget.teamId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const SizedBox.shrink();
                }
                final team = Team.fromMap(
                  snapshot.data!.data() as Map<String, dynamic>,
                );
                final NumberFormat formatter = NumberFormat.simpleCurrency(
                  decimalDigits: 0,
                );
                final transferBudget =
                    (team.budget * team.transferBudgetPercentage / 100).round();

                return Row(
                  children: [
                    _buildEconomyStat(
                      label: AppLocalizations.of(context).totalBalance,
                      value: formatter.format(team.budget),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 20),
                    _buildEconomyStat(
                      label: AppLocalizations.of(context).transferBudgetLabel,
                      value: formatter.format(transferBudget),
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (FirebaseAuth.instance.currentUser?.email ==
              'felipe@firetower.games')
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              icon: const Icon(
                Icons.admin_panel_settings,
                color: Colors.tealAccent,
              ),
              label: Text(
                AppLocalizations.of(context).adminBtn,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
            ),
          CompositedTransformTarget(
            link: _accountLayerLink,
            child: TextButton.icon(
              onPressed: _toggleAccountCard,
              icon: Icon(
                Icons.account_circle_outlined,
                color: _isAccountCardOpen
                    ? theme.colorScheme.secondary
                    : Colors.white,
              ),
              label: Text(
                AppLocalizations.of(context).accountBtn,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isAccountCardOpen
                      ? theme.colorScheme.secondary
                      : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white70)
                .copyWith(
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.hovered)
                        ? theme.colorScheme.error
                        : Colors.white70,
                  ),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.hovered)
                        ? theme.colorScheme.error.withValues(alpha: 0.1)
                        : null,
                  ),
                ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    AppLocalizations.of(context).logOutConfirmTitle,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                  ),
                  content: Text(AppLocalizations.of(context).logOutConfirmDesc),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).cancelBtn),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: Text(
                        AppLocalizations.of(context).logOutBtn,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout), // Color handled by foregroundColor
            label: Text(
              AppLocalizations.of(context).logOutBtn,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                                          label: node.titleBuilder(context),
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
                  icon: node.showNewBadge
                      ? NewBadgeWidget(
                          createdAt: DateTime.now(),
                          forceShow: true,
                          child: const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                  label: node.titleBuilder(context).toUpperCase(),
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
              children: navTree
                  .map((node) => _buildNode(context, node, 0))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(BuildContext context, NavNode node, int depth) {
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

    // Level 1 items (depth 0) are the only ones shown in the sidebar now
    if (depth == 0) {
      return _buildTile(
        context: context,
        node: node,
        depth: depth,
        isSelected: isSelected,
        contentColor: contentColor,
        fontWeight: fontWeight,
        fontSize: fontSize,
        paddingLeft: paddingLeft,
      );
    }

    // Hide everything else (depth > 0)
    return const SizedBox.shrink();
  }

  Widget _buildTile({
    required BuildContext context,
    required NavNode node,
    required int depth,
    required bool isSelected,
    required Color contentColor,
    required FontWeight fontWeight,
    required double fontSize,
    required double paddingLeft,
  }) {
    Widget titleWidget = Text(
      node.titleBuilder(context).toUpperCase(),
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
    );

    if (node.showNewBadge) {
      titleWidget = NewBadgeWidget(
        createdAt: DateTime.now(),
        forceShow: true,
        child: titleWidget,
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.only(left: paddingLeft, right: 16.0),
      title: isCollapsed ? null : titleWidget,
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
          final isRaceDay = child.id == 'racing_day';

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
                  color: isRaceDay && !isSelected
                      ? const Color(0xFFFF5252).withValues(alpha: 0.06)
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? (isRaceDay
                                ? const Color(0xFFFF5252)
                                : theme.primaryColor)
                          : (isRaceDay
                                ? const Color(0xFFFF5252).withValues(alpha: 0.4)
                                : Colors.transparent),
                      width: isRaceDay ? 2 : 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRaceDay)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.flag,
                          size: 14,
                          color: isSelected
                              ? const Color(0xFFFF5252)
                              : const Color(0xFFFF5252).withValues(alpha: 0.7),
                        ),
                      ),
                    Text(
                      child.titleBuilder(context),
                      style: GoogleFonts.raleway(
                        color: isRaceDay
                            ? (isSelected
                                  ? const Color(0xFFFF5252)
                                  : const Color(
                                      0xFFFF5252,
                                    ).withValues(alpha: 0.8))
                            : (isSelected ? Colors.white : Colors.white54),
                        fontWeight: isSelected || isRaceDay
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
