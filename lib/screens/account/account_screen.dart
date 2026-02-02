import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/user_models.dart'; // ManagerProfile
import 'package:intl/intl.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AppUser? _appUser;
  ManagerProfile? _managerProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final appUser = await AuthService().getAppUser(user.uid);
    final managerProfile = await AuthService().getManagerProfile(user.uid);

    if (mounted) {
      setState(() {
        _appUser = appUser;
        _managerProfile = managerProfile;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            "Account Settings",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // User Section
          _buildSectionTitle("User Profile"),
          const SizedBox(height: 16),
          if (_appUser != null)
            _buildInfoCard([
              _buildInfoRow(
                "Name",
                "${_appUser!.firstName} ${_appUser!.lastName}",
              ),
              _buildInfoRow("Email", _appUser!.email),
              _buildInfoRow(
                "Registered",
                DateFormat.yMMMd().format(_appUser!.registrationDate),
              ),
            ])
          else
            const Text("User data not found."),

          const SizedBox(height: 32),

          // Manager Section
          _buildSectionTitle("Manager Profile"),
          const SizedBox(height: 16),
          if (_managerProfile != null)
            _buildInfoCard([
              _buildInfoRow(
                "Manager Name",
                "${_managerProfile!.name} ${_managerProfile!.surname}",
              ),
              _buildInfoRow("Role", _managerProfile!.role.title),
              _buildInfoRow(
                "Reputation",
                _managerProfile!.reputation.toString(),
              ),
              _buildInfoRow("Country", _managerProfile!.country),
            ])
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No Manager Profile created for this game yet.",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                AuthService().signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text("LOG OUT"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
