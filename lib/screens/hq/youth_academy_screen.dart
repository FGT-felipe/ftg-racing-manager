import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../models/domain/domain_models.dart';
import '../../services/youth_academy_service.dart';
import '../../services/finance_service.dart';
import '../../widgets/common/instruction_card.dart';

class YouthAcademyScreen extends StatefulWidget {
  final String teamId;

  const YouthAcademyScreen({super.key, required this.teamId});

  @override
  State<YouthAcademyScreen> createState() => _YouthAcademyScreenState();
}

class _YouthAcademyScreenState extends State<YouthAcademyScreen> {
  final YouthAcademyService _academyService = YouthAcademyService();
  final FinanceService _financeService = FinanceService();
  Country? _selectedCountry;
  bool _isPurchasing = false;

  /// Available countries for academy setup
  static final List<Country> _availableCountries = [
    Country(code: 'CO', name: 'Colombia', flagEmoji: '🇨🇴'),
    Country(code: 'BR', name: 'Brasil', flagEmoji: '🇧🇷'),
    Country(code: 'AR', name: 'Argentina', flagEmoji: '🇦🇷'),
    Country(code: 'MX', name: 'México', flagEmoji: '🇲🇽'),
    Country(code: 'CL', name: 'Chile', flagEmoji: '🇨🇱'),
    Country(code: 'UY', name: 'Uruguay', flagEmoji: '🇺🇾'),
    Country(code: 'ES', name: 'España', flagEmoji: '🇪🇸'),
    Country(code: 'IT', name: 'Italia', flagEmoji: '🇮🇹'),
    Country(code: 'GB', name: 'United Kingdom', flagEmoji: '🇬🇧'),
    Country(code: 'DE', name: 'Germany', flagEmoji: '🇩🇪'),
    Country(code: 'FR', name: 'France', flagEmoji: '🇫🇷'),
    Country(code: 'JP', name: 'Japan', flagEmoji: '🇯🇵'),
    Country(code: 'US', name: 'United States', flagEmoji: '🇺🇸'),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .snapshots(),
      builder: (context, teamSnap) {
        if (!teamSnap.hasData || !teamSnap.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final team = Team.fromMap(
          teamSnap.data!.data() as Map<String, dynamic>,
        );

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _academyService.streamAcademyConfig(widget.teamId),
          builder: (context, configSnap) {
            if (configSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final config = configSnap.data;

            if (config == null) {
              return _buildPurchaseView(team);
            }

            return _buildAcademyView(team, config);
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STATE A: Purchase Academy
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPurchaseView(Team team) {
    final theme = Theme.of(context);
    const green = Color(0xFF00C853);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      green.withValues(alpha: 0.2),
                      green.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: green.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'YOUTH ACADEMY',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Develop tomorrow\'s champions',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHAT YOU GET',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: green,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBullet('Scout 2 young prospects every week'),
                    _buildBullet('Follow and train promising talent'),
                    _buildBullet('Promote graduates to your main team'),
                    _buildBullet('Upgradeable to level 5 (more slots)'),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'COST',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          _financeService.formatCurrency(100000),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR BUDGET',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          _financeService.formatCurrency(team.budget),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: team.budget >= 100000
                                ? green
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Country selector
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT COUNTRY OF ORIGIN',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: green,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All academy graduates will have this nationality.',
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Country>(
                      initialValue: _selectedCountry,
                      dropdownColor: const Color(0xFF1A1A1A),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: green),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: Text(
                        'Choose a country...',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                      items: _availableCountries.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.flagEmoji}  ${c.name}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (c) => setState(() => _selectedCountry = c),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Purchase button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_selectedCountry != null &&
                          team.budget >= 100000 &&
                          !_isPurchasing)
                      ? () => _purchaseAcademy(team)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.05,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'BUILD YOUTH ACADEMY',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: Color(0xFF00C853))),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseAcademy(Team team) async {
    if (_selectedCountry == null) return;
    setState(() => _isPurchasing = true);

    try {
      await _academyService.purchaseAcademy(widget.teamId, _selectedCountry!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Youth Academy built! 🎓 Scouts deployed to ${_selectedCountry!.name}',
            ),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STATE B: Academy Active
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAcademyView(Team team, Map<String, dynamic> config) {
    final level = config['academyLevel'] ?? 1;
    final maxSlots = config['maxSlots'] ?? 2;
    final countryFlag = config['countryFlag'] ?? '🏁';
    final countryName = config['countryName'] ?? 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction banner
          InstructionCard(
            icon: Icons.school_rounded,
            title: 'YOUTH ACADEMY',
            description:
                'Every week, new young prospects arrive at your academy. '
                'Follow the ones you believe in and watch them grow. '
                'At the end of the season, promote graduates to your main team!',
          ),
          const SizedBox(height: 24),

          // Academy info bar
          _buildAcademyInfoBar(
            level: level,
            maxSlots: maxSlots,
            countryFlag: countryFlag,
            countryName: countryName,
            team: team,
          ),
          const SizedBox(height: 32),

          // Candidates section
          Text(
            'AVAILABLE PROSPECTS',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00C853),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose wisely — the sooner you follow a prospect, the more training they receive.',
            style: GoogleFonts.raleway(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          _buildCandidatesSection(level, maxSlots),
          const SizedBox(height: 32),

          // Selected drivers section
          Text(
            'YOUR ACADEMY ROSTER',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00C853),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Drivers you are actively training. Track their progress and promote them at season end.',
            style: GoogleFonts.raleway(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          _buildSelectedDriversSection(maxSlots),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAcademyInfoBar({
    required int level,
    required int maxSlots,
    required String countryFlag,
    required String countryName,
    required Team team,
  }) {
    const green = Color(0xFF00C853);
    final upgradePrice = 1000000 * level;
    final canUpgrade = level < 5 && team.budget >= upgradePrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Level stars
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEVEL',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < level ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < level ? green : Colors.white24,
                    size: 22,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Country
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COUNTRY',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$countryFlag $countryName',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Upgrade button
          if (level < 5)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'UPGRADE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: canUpgrade ? () => _upgradeAcademy() : null,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: Text(
                    _financeService.formatCurrency(upgradePrice),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.05,
                    ),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'MAX LEVEL',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: green,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _upgradeAcademy() async {
    try {
      await _academyService.upgradeAcademy(widget.teamId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Academy upgraded! 🚀 New capacity unlocked.'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Candidates Section ────────────────────────────────────────────────

  Widget _buildCandidatesSection(int level, int maxSlots) {
    return StreamBuilder<List<YoungDriver>>(
      stream: _academyService.streamCandidates(widget.teamId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final candidates = snap.data ?? [];

        if (candidates.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Text(
                'No prospects available. Check back next week!',
                style: GoogleFonts.raleway(fontSize: 14, color: Colors.white38),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: candidates.map((d) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: d == candidates.first ? 12 : 0,
                        left: d == candidates.last ? 12 : 0,
                      ),
                      child: _CandidateCard(
                        driver: d,
                        onSelect: () => _selectCandidate(d.id),
                        onDismiss: () => _dismissCandidate(d.id),
                        maxSlots: maxSlots,
                        teamId: widget.teamId,
                        academyService: _academyService,
                      ),
                    ),
                  );
                }).toList(),
              );
            } else {
              return Column(
                children: candidates.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CandidateCard(
                      driver: d,
                      onSelect: () => _selectCandidate(d.id),
                      onDismiss: () => _dismissCandidate(d.id),
                      maxSlots: maxSlots,
                      teamId: widget.teamId,
                      academyService: _academyService,
                    ),
                  );
                }).toList(),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _selectCandidate(String candidateId) async {
    try {
      await _academyService.selectCandidate(widget.teamId, candidateId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prospect signed! Training begins now. ✍️'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dismissCandidate(String candidateId) async {
    try {
      await _academyService.dismissCandidate(widget.teamId, candidateId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Selected Drivers Section ─────────────────────────────────────────

  Widget _buildSelectedDriversSection(int maxSlots) {
    return StreamBuilder<List<YoungDriver>>(
      stream: _academyService.streamSelectedDrivers(widget.teamId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final selected = snap.data ?? [];

        if (selected.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No drivers in training yet.',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Follow a prospect above to start training.',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Capacity indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${selected.length} / $maxSlots SLOTS',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            ...selected.map((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SelectedDriverCard(
                  driver: d,
                  onRelease: () => _releaseDriver(d.id, d.name),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _releaseDriver(String driverId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'RELEASE DRIVER',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to release $name from the academy? '
          'You will not recover any investment made.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'RELEASE',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _academyService.releaseSelectedDriver(widget.teamId, driverId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Driver released from academy.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Candidate Card Widget
// ══════════════════════════════════════════════════════════════════════════════

class _CandidateCard extends StatelessWidget {
  final YoungDriver driver;
  final VoidCallback onSelect;
  final VoidCallback onDismiss;
  final int maxSlots;
  final String teamId;
  final YouthAcademyService academyService;

  const _CandidateCard({
    required this.driver,
    required this.onSelect,
    required this.onDismiss,
    required this.maxSlots,
    required this.teamId,
    required this.academyService,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: portrait + name
          Row(
            children: [
              // Portrait
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: green.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: driver.portraitUrl != null
                      ? Image.asset(
                          driver.portraitUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            driver.gender == 'M'
                                ? Icons.person
                                : Icons.person_2,
                            color: Colors.white38,
                            size: 32,
                          ),
                        )
                      : Icon(
                          driver.gender == 'M' ? Icons.person : Icons.person_2,
                          color: Colors.white38,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          driver.nationality.flagEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        _infoTag(
                          driver.gender == 'M' ? '♂' : '♀',
                          driver.gender == 'M'
                              ? Colors.blue
                              : Colors.pinkAccent,
                        ),
                        const SizedBox(width: 6),
                        _infoTag('AGE ${driver.age}', Colors.white54),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Growth potential stars
          Row(
            children: [
              Text(
                'POTENTIAL',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                return Icon(
                  i < driver.potentialStars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: i < driver.potentialStars
                      ? Colors.amber
                      : Colors.white24,
                  size: 16,
                );
              }),
            ],
          ),
          const SizedBox(height: 12),

          // Stat range bars
          ...[
            'braking',
            'cornering',
            'smoothness',
            'overtaking',
          ].map((stat) => _buildStatRangeBar(stat)),
          const SizedBox(height: 16),

          // Salary info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONTRACT',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '\$${(driver.salary / 1000).toStringAsFixed(0)}k / year',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.withValues(alpha: 0.8),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'DISMISS',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text(
                    'FOLLOW',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatRangeBar(String statKey) {
    final min = driver.statRangeMin[statKey] ?? 0;
    final max = driver.statRangeMax[statKey] ?? 0;

    final label = statKey[0].toUpperCase() + statKey.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final leftPos = (min / 100) * width;
                final barWidth = ((max - min) / 100) * width;

                return Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: leftPos,
                        child: Container(
                          width: barWidth.clamp(4, width - leftPos),
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00C853).withValues(alpha: 0.5),
                                const Color(0xFF00C853),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$min-$max',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Selected Driver Card Widget
// ══════════════════════════════════════════════════════════════════════════════

class _SelectedDriverCard extends StatelessWidget {
  final YoungDriver driver;
  final VoidCallback onRelease;

  const _SelectedDriverCard({required this.driver, required this.onRelease});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: green.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [green.withValues(alpha: 0.05), const Color(0xFF121212)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Portrait
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: green.withValues(alpha: 0.4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: driver.portraitUrl != null
                      ? Image.asset(
                          driver.portraitUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            driver.gender == 'M'
                                ? Icons.person
                                : Icons.person_2,
                            color: green,
                            size: 28,
                          ),
                        )
                      : Icon(
                          driver.gender == 'M' ? Icons.person : Icons.person_2,
                          color: green,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'IN TRAINING',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: green,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${driver.nationality.flagEmoji} ${driver.gender == 'M' ? '♂' : '♀'} AGE ${driver.age}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < driver.potentialStars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < driver.potentialStars
                            ? Colors.amber
                            : Colors.white24,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Training progress bars
          ...DriverStats.drivingStats.map((stat) => _buildProgressBar(stat)),
          const SizedBox(height: 8),

          // Training started info + release
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (driver.selectedAt != null)
                Text(
                  'Training since ${_formatDate(driver.selectedAt!)}',
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                onPressed: onRelease,
                icon: Icon(
                  Icons.person_remove_rounded,
                  size: 14,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                label: Text(
                  'RELEASE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.red.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String statKey) {
    final min = driver.statRangeMin[statKey] ?? 0;
    final max = driver.statRangeMax[statKey] ?? 0;
    final progress = driver.trainingProgress[statKey] ?? 0.0;

    final label = statKey[0].toUpperCase() + statKey.substring(1);
    // Current estimated value based on progress
    final currentVal = min + ((max - min) * progress / 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (progress / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '$currentVal / $max',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}';
  }
}
