import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/core_models.dart';
import '../../models/user_models.dart';
import '../../services/auth_service.dart';
import '../../services/driver_assignment_service.dart';
import '../../services/universe_service.dart';
import '../../widgets/car_selector.dart';

class TeamScreen extends StatefulWidget {
  final String teamId;

  const TeamScreen({super.key, required this.teamId});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  String _currentName = '';
  int _nameChangeCount = 0;
  ManagerProfile? _managerProfile;
  int _liveryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
    _loadManagerProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    final doc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _currentName = data['name'] ?? '';
        _nameController.text = _currentName;
        _nameChangeCount = data['nameChangeCount'] ?? 0;
        _liveryIndex = data['liveryIndex'] ?? 0;
      });
    }
  }

  Future<void> _loadManagerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await AuthService().getManagerProfile(user.uid);
    if (mounted && profile != null) {
      setState(() => _managerProfile = profile);
    }
  }

  Future<void> _saveNewName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _currentName) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId);
      final teamDoc = await teamRef.get();
      final data = teamDoc.data()!;
      final budget = data['budget'] ?? 0;
      final currentCount = data['nameChangeCount'] ?? 0;
      final bool isFirstChange = currentCount == 0;
      const nameChangeCost = 500000;

      if (!isFirstChange && budget < nameChangeCost) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Insufficient budget! Name change costs \$500,000.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final int costApplied = isFirstChange ? 0 : nameChangeCost;

      // Robust save: upsert via merge
      await teamRef.set({
        'name': newName,
        'budget': budget - costApplied,
        'nameChangeCount': currentCount + 1,
      }, SetOptions(merge: true));

      // Sync with global universe safely
      try {
        await UniverseService().updateTeamInUniverse(
          widget.teamId,
          newName: newName,
          newBudget: budget - costApplied,
          nameChangeCount: currentCount + 1,
        );
      } catch (e) {
        debugPrint('Failed to sync team name with Universe: $e');
        // Continue applying state to UI even if Universe update fails,
        // since the main teams collection is the source of truth
      }

      if (mounted) {
        setState(() {
          _currentName = newName;
          _isEditing = false;
          _isSaving = false;
          _nameChangeCount = currentCount + 1;
        });

        final message = isFirstChange
            ? 'Team renamed to "$newName". First change is free!'
            : 'Team renamed to "$newName". \$500,000 deducted.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Row 1: Team Name + Career Stats (30/70)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildNameChangeCard(context)),
              const SizedBox(width: 20),
              Expanded(flex: 7, child: _buildTeamCareerStats(context)),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2: Manager Card (Livery card hidden until redesign)
          _buildManagerCard(context),
        ],
      ),
    );
  }

  Widget _buildNameChangeCard(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'TEAM IDENTITY',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // Team Name Display / Edit
          Text(
            'Team Name',
            style: GoogleFonts.raleway(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          if (_isEditing) ...[
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF292A33),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _nameController.text = _currentName;
                      setState(() => _isEditing = false);
                    },
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF000000)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFF00C853).withValues(alpha: 0.3),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNewName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00C853),
                              ),
                            )
                          : Text(
                              'CONFIRM',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF00C853),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currentName.isEmpty ? '...' : _currentName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: Icon(Icons.edit_outlined, size: 18, color: accentColor),
                  tooltip: 'Change team name',
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),

          // Cost & Regulation info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.amber.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REGULATIONS',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.withValues(alpha: 0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRegulationRow(
                  Icons.card_giftcard_outlined,
                  'First change: ${_nameChangeCount > 0 ? 'USED' : 'FREE'}',
                  color: _nameChangeCount > 0 ? Colors.white24 : Colors.green,
                ),
                const SizedBox(height: 8),
                _buildRegulationRow(
                  Icons.monetization_on_outlined,
                  'Next changes: \$500,000 each',
                  color: _nameChangeCount > 0 ? Colors.amber : Colors.white38,
                ),
              ],
            ),
          ),

          // Status badge
          if (_nameChangeCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RENAMED $_nameChangeCount TIME${_nameChangeCount == 1 ? '' : 'S'}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegulationRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.white38),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.raleway(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: (color ?? Colors.white).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCareerStats(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    return StreamBuilder<List<Driver>>(
      stream: DriverAssignmentService().streamDriversByTeam(widget.teamId),
      builder: (context, snapshot) {
        // Calculate combined stats from both drivers
        int totalTitles = 0;
        int totalWins = 0;
        int totalPodiums = 0;
        int totalRaces = 0;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          for (final driver in snapshot.data!) {
            totalTitles += driver.championships;
            totalWins += driver.wins;
            totalPodiums += driver.podiums;
            totalRaces += driver.races;
          }
        }

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TEAM CAREER STATS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'COMBINED DRIVERS',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCareerStatCircle(
                      context,
                      'TITLES',
                      '$totalTitles',
                      Icons.emoji_events_rounded,
                    ),
                    _buildCareerStatCircle(
                      context,
                      'WINS',
                      '$totalWins',
                      Icons.military_tech_rounded,
                    ),
                    _buildCareerStatCircle(
                      context,
                      'PODIUMS',
                      '$totalPodiums',
                      Icons.star_rounded,
                    ),
                    _buildCareerStatCircle(
                      context,
                      'RACES',
                      '$totalRaces',
                      Icons.flag_rounded,
                    ),
                  ],
                ),

              const SizedBox(height: 28),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 16),

              // Per-driver breakdown
              if (snapshot.hasData && snapshot.data!.isNotEmpty)
                _buildDriverBreakdownTable(context, snapshot.data!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCareerStatCircle(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF15151E),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white38,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverBreakdownTable(
    BuildContext context,
    List<Driver> drivers,
  ) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DRIVER BREAKDOWN',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),

        // Header row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'DRIVER',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ...['TITLES', 'WINS', 'PODIUMS', 'RACES'].map(
                (h) => Expanded(
                  flex: 2,
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white38,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Driver rows
        ...drivers.asMap().entries.map((entry) {
          final driver = entry.value;
          final isLast = entry.key == drivers.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: entry.key == 0
                              ? accentColor
                              : accentColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          driver.name,
                          style: GoogleFonts.raleway(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatCell('${driver.championships}'),
                _buildStatCell('${driver.wins}'),
                _buildStatCell('${driver.podiums}'),
                _buildStatCell('${driver.races}'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCell(String value) {
    return Expanded(
      flex: 2,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildLiveryCard(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TEAM LIVERY',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'SELECT YOUR COLORS',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accentColor.withValues(alpha: 0.8),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Car Selector Widget — fills remaining space
          Expanded(
            child: Center(
              child: CarSelector(
                assetPath: 'liverys/livery_map2.png',
                columns: 6,
                rows: 3,
                initialIndex: _liveryIndex,
                onChanged: (index) {
                  setState(() => _liveryIndex = index);
                  _saveLivery(index);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 8),

          // Info
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 14,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              Text(
                'Your livery will be shown in race replays and standings.',
                style: GoogleFonts.raleway(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveLivery(int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({'liveryIndex': index});
    } catch (e) {
      debugPrint('Error saving livery: $e');
    }
  }

  Widget _buildManagerCard(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    if (_managerProfile == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final manager = _managerProfile!;
    final role = manager.role;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'MANAGER PROFILE',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // Avatar
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF292A33),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.person_rounded,
                size: 40,
                color: accentColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Flag + Name
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getFlagEmoji(manager.country),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${manager.name} ${manager.surname}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),

          // Background Role Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Icon(_getRoleIcon(role), size: 28, color: accentColor),
                const SizedBox(height: 8),
                Text(
                  role.title.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Advantages
          Text(
            'ADVANTAGES',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...role.pros.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.add_circle, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Disadvantages
          Text(
            'DISADVANTAGES',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...role.cons.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.remove_circle,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c,
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(ManagerRole role) {
    switch (role) {
      case ManagerRole.exDriver:
        return Icons.sports_motorsports;
      case ManagerRole.businessAdmin:
        return Icons.pie_chart;
      case ManagerRole.bureaucrat:
        return Icons.gavel;
      case ManagerRole.exEngineer:
        return Icons.build;
    }
  }

  String _getFlagEmoji(String? country) {
    if (country == null) return '🏳️';
    final upperCountry = country.toUpperCase();
    const flags = {
      'BR': '🇧🇷',
      'BRAZIL': '🇧🇷',
      'AR': '🇦🇷',
      'ARGENTINA': '🇦🇷',
      'CO': '🇨🇴',
      'COLOMBIA': '🇨🇴',
      'MX': '🇲🇽',
      'MEXICO': '🇲🇽',
      'UY': '🇺🇾',
      'URUGUAY': '🇺🇾',
      'CL': '🇨🇱',
      'CHILE': '🇨🇱',
      'GB': '🇬🇧',
      'UNITED KINGDOM': '🇬🇧',
      'UK': '🇬🇧',
      'DE': '🇩🇪',
      'GERMANY': '🇩🇪',
      'IT': '🇮🇹',
      'ITALY': '🇮🇹',
      'ES': '🇪🇸',
      'SPAIN': '🇪🇸',
      'FR': '🇫🇷',
      'FRANCE': '🇫🇷',
      'US': '🇺🇸',
      'USA': '🇺🇸',
      'UNITED STATES': '🇺🇸',
    };
    return flags[upperCountry] ?? '🏳️';
  }
}
