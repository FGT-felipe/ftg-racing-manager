import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'team_selection_screen.dart';
import '../../l10n/app_localizations.dart';

class CreateManagerScreen extends StatefulWidget {
  const CreateManagerScreen({super.key});

  @override
  State<CreateManagerScreen> createState() => _CreateManagerScreenState();
}

class _CreateManagerScreenState extends State<CreateManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  String? _selectedCountry;
  String? _selectedGender;
  int _selectedRoleIndex = 0;
  bool _isLoading = false;

  // DATOS DE ROLES
  List<Map<String, dynamic>> get _roles => [
    {
      'id': 'ex_driver',
      'title': AppLocalizations.of(context).roleExDriverTitle,
      'desc': AppLocalizations.of(context).roleExDriverDesc,
      'icon': Icons.sports_motorsports,
      'pros': [
        '+5 driver feedback for setup',
        '+2% driver race pace',
        '+10 driver morale during race',
        'Unlocks Risky Driver Style',
      ],
      'cons': [
        'Drivers salary is 20% higher',
        '+5% higher risk of race crashes',
      ],
    },
    {
      'id': 'business',
      'title': AppLocalizations.of(context).roleBusinessTitle,
      'desc': AppLocalizations.of(context).roleBusinessDesc,
      'icon': Icons.pie_chart,
      'pros': [
        '+15% better financial sponsorship deals',
        '-10% facility upgrade costs',
      ],
      'cons': [
        '-2% driver race pace',
        '-10% driver morale if sponsor goals fail',
      ],
    },
    {
      'id': 'bureaucrat',
      'title': AppLocalizations.of(context).roleBureaucratTitle,
      'desc': AppLocalizations.of(context).roleBureaucratDesc,
      'icon': Icons.gavel,
      'pros': [
        '-10% facility purchase and upgrade costs',
        '+1 extra youth academy driver per level',
      ],
      'cons': ['Car part upgrade cooldown is 2 weeks (not 1)'],
    },
    {
      'id': 'engineer',
      'title': AppLocalizations.of(context).roleEngineerTitle,
      'desc': AppLocalizations.of(context).roleEngineerDesc,
      'icon': Icons.build,
      'pros': [
        'Can upgrade 2 car parts simultaneously',
        '-10% tyre wear',
        '+5% Qualifying success probability',
      ],
      'cons': ['-5% driver XP gain', 'Car part upgrades cost double'],
    },
  ];

  Future<void> _establishCareer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String birthDate =
          "${_yearCtrl.text}-${_monthCtrl.text.padLeft(2, '0')}-${_dayCtrl.text.padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection('managers')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'firstName': _nameCtrl.text.trim(),
            'lastName': _surnameCtrl.text.trim(),
            'nationality': _selectedCountry ?? 'Brazil',
            'gender': _selectedGender ?? 'Male',
            'birthDate': birthDate,
            'backgroundId': _roles[_selectedRoleIndex]['id'],
            'reputation': 50,
            'teamId': '',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              TeamSelectionScreen(nationality: _selectedCountry ?? 'Brazil'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF15151E);
    final accentHighlight = Theme.of(context).colorScheme.secondary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentHighlight))
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context).createManagerProfile,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: textColor.withValues(alpha: 0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        _buildSectionTitle(
                          AppLocalizations.of(context).personalInfoTitle,
                        ),
                        const SizedBox(height: 20),

                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    "First Name",
                                    _nameCtrl,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    "Last Name",
                                    _surnameCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _selectedCountry,
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    hint: Text(
                                      AppLocalizations.of(context).countryLabel,
                                      style: GoogleFonts.raleway(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    decoration: _inputDeco(null),
                                    dropdownColor: const Color(0xFF292A33),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        enabled: false,
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).countryLabel,
                                          style: GoogleFonts.raleway(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      ...[
                                        'Brazil',
                                        'Argentina',
                                        'Colombia',
                                        'Mexico',
                                        'Uruguay',
                                        'Chile',
                                      ].map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: GoogleFonts.raleway(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedCountry = v),
                                    validator: (v) => v == null
                                        ? AppLocalizations.of(
                                            context,
                                          ).selectCountryError
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _selectedGender,
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    hint: Text(
                                      AppLocalizations.of(context).genderLabel,
                                      style: GoogleFonts.raleway(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    decoration: _inputDeco(null),
                                    dropdownColor: const Color(0xFF292A33),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        enabled: false,
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).genderLabel,
                                          style: GoogleFonts.raleway(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      ...['Male', 'Female', 'Non-binary'].map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(
                                            g == 'Male'
                                                ? AppLocalizations.of(
                                                    context,
                                                  ).maleGender
                                                : g == 'Female'
                                                ? AppLocalizations.of(
                                                    context,
                                                  ).femaleGender
                                                : AppLocalizations.of(
                                                    context,
                                                  ).nonBinaryGender,
                                            style: GoogleFonts.raleway(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedGender = v),
                                    validator: (v) => v == null
                                        ? AppLocalizations.of(
                                            context,
                                          ).selectGenderError
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    AppLocalizations.of(context).dayLabel,
                                    _dayCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    AppLocalizations.of(context).monthLabel,
                                    _monthCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    AppLocalizations.of(context).yearLabel,
                                    _yearCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        _buildSectionTitle(
                          AppLocalizations.of(context).selectBackgroundTitle,
                        ),
                        const SizedBox(height: 20),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 800) {
                              return _buildDesktopRoles();
                            } else {
                              return _buildMobileRoles();
                            }
                          },
                        ),

                        const Divider(color: Colors.white10, height: 40),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context).createManagerDesc,
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Container(
                              height: 60,
                              width: 240,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF2A2A2A),
                                    Color(0xFF000000),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00C853,
                                  ).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _establishCareer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).establishCareerBtn,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: const Color(0xFF00C853),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.secondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.raleway(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: _inputDeco(label),
      validator: (v) => v == null || v.isEmpty
          ? AppLocalizations.of(context).requiredError
          : null,
    );
  }

  InputDecoration _inputDeco(String? label) {
    return InputDecoration(
      label: label != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF292A33),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label),
            )
          : null,
      labelStyle: GoogleFonts.raleway(
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: GoogleFonts.raleway(
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.bold,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      filled: true,
      fillColor: const Color(0xFF292A33),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildMobileRoles() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _roles.asMap().entries.map((entry) {
        int idx = entry.key;
        var role = entry.value;
        bool isSelected = _selectedRoleIndex == idx;
        return GestureDetector(
          onTap: () => setState(() => _selectedRoleIndex = idx),
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1)
                  : null,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  role['icon'],
                  color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  role['title'],
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopRoles() {
    var selectedRole = _roles[_selectedRoleIndex];
    return Container(
      height: 350,
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: ListView.builder(
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedRoleIndex == index;
                return ListTile(
                  leading: Icon(
                    _roles[index]['icon'],
                    color: isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey,
                  ),
                  title: Text(
                    _roles[index]['title'],
                    style: GoogleFonts.raleway(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () => setState(() => _selectedRoleIndex = index),
                  selected: isSelected,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.05),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          selectedRole['icon'],
                          size: 48,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (selectedRole['title'] as String).toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              selectedRole['desc'],
                              style: GoogleFonts.raleway(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).advantagesTitle,
                                style: GoogleFonts.poppins(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(selectedRole['pros'] as List<String>).map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add_circle,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          p,
                                          style: GoogleFonts.raleway(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).disadvantagesTitle,
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(selectedRole['cons'] as List<String>).map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.remove_circle,
                                        size: 16,
                                        color: Colors.redAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c,
                                          style: GoogleFonts.raleway(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
