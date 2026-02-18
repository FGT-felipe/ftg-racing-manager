import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_selection_screen.dart';
import '../../widgets/common/app_logo.dart';

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
  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'ex_driver',
      'title': 'Ex-Driver',
      'desc': 'Using your racing intuition to lead.',
      'icon': Icons.sports_motorsports,
      'pros': [
        'Technical bonus in racing sessions',
        'Better driver feedback accuracy',
        'Respect from pit crew',
      ],
      'cons': [
        'Slow management skill progression',
        'Higher salary expectation',
        'Aggressive strategy bias',
      ],
    },
    {
      'id': 'business',
      'title': 'Business Admin',
      'desc': 'Optimization and profit above all.',
      'icon': Icons.pie_chart,
      'pros': [
        'Better financial deals & sponsors',
        'Lower facility upgrade costs',
        'Marketing bonus',
      ],
      'cons': [
        'High driver fatigue rate',
        'Poor relationship with engineers',
        'Risk aversion',
      ],
    },
    {
      'id': 'bureaucrat',
      'title': 'Bureaucrat',
      'desc': 'Master of rules and politics.',
      'icon': Icons.gavel,
      'pros': [
        'Cheaper personnel contracts',
        'Avoids FIA penalties',
        'Stable board confidence',
      ],
      'cons': [
        'Poor team harmony & rivalries',
        'Slower car development',
        'Boring press conferences',
      ],
    },
    {
      'id': 'engineer',
      'title': 'Ex-Engineer',
      'desc': 'Technical excellence is the only way.',
      'icon': Icons.build,
      'pros': [
        'Faster car setup & R&D',
        'Reliability bonuses',
        'Unlock tech upgrades faster',
      ],
      'cons': [
        'Drivers gain less XP',
        'Ignoring commercial opportunities',
        'Micro-management penalty',
      ],
    },
    {
      'id': 'none',
      'title': 'No Experience',
      'desc': 'A fresh perspective on the sport.',
      'icon': Icons.person_outline,
      'pros': [
        'Maximum growth potential',
        'No pre-existing rivalries',
        'Balanced leadership style',
      ],
      'cons': [
        'No starting bonuses',
        'Lower initial reputation',
        'Learning curve for telemetry',
      ],
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
                            const AppLogo(size: 40, withText: false),
                            const SizedBox(width: 16),
                            Text(
                              "CREATE MANAGER PROFILE",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textColor.withValues(alpha: 0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        _buildSectionTitle("PERSONAL INFO"),
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
                                    hint: const Text(
                                      "Country",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    decoration: _inputDeco(null),
                                    dropdownColor: Colors.white,
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        enabled: false,
                                        child: Text(
                                          "Country",
                                          style: TextStyle(
                                            color: Colors.grey,
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
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedCountry = v),
                                    validator: (v) =>
                                        v == null ? "Select Country" : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _selectedGender,
                                    hint: const Text(
                                      "Gender",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    decoration: _inputDeco(null),
                                    dropdownColor: Colors.white,
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        enabled: false,
                                        child: Text(
                                          "Gender",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      ...['Male', 'Female', 'Non-binary'].map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(
                                            g,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedGender = v),
                                    validator: (v) =>
                                        v == null ? "Select Gender" : null,
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
                                    "Day",
                                    _dayCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    "Month",
                                    _monthCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    "Year",
                                    _yearCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        _buildSectionTitle("SELECT BACKGROUND"),
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

                        const SizedBox(height: 40),

                        SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _establishCareer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentHighlight,
                              foregroundColor: Colors.black,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "ESTABLISH CAREER",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
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
      style: TextStyle(
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
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: _inputDeco(label),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }

  InputDecoration _inputDeco(String? label) {
    return InputDecoration(
      label: label != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label),
            )
          : null,
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.bold,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
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
              color: isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
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
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.black,
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
                              selectedRole['title'].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              selectedRole['desc'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
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
                                "ADVANTAGES",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
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
                              const Text(
                                "DISADVANTAGES",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
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
