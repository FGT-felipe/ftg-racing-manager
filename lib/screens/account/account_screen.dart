import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/user_models.dart'; // ManagerProfile
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

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
            AppLocalizations.of(context).accountSettingsTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // User Section
          _buildSectionTitle(AppLocalizations.of(context).userProfileTitle),
          const SizedBox(height: 16),
          if (_appUser != null)
            _buildInfoCard([
              _buildInfoRow(
                AppLocalizations.of(context).nameLabel,
                "${_appUser!.firstName} ${_appUser!.lastName}",
              ),
              _buildInfoRow(
                AppLocalizations.of(context).emailLabel,
                _appUser!.email,
              ),
              _buildInfoRow(
                AppLocalizations.of(context).registeredLabel,
                DateFormat.yMMMd().format(_appUser!.registrationDate),
              ),
            ])
          else
            Text(AppLocalizations.of(context).userDataNotFound),

          const SizedBox(height: 32),

          // Manager Section
          _buildSectionTitle(AppLocalizations.of(context).managerProfileTitle),
          const SizedBox(height: 16),
          if (_managerProfile != null)
            _buildInfoCard([
              _buildInfoRow(
                AppLocalizations.of(context).managerNameLabel,
                "${_managerProfile!.name} ${_managerProfile!.surname}",
              ),
              _buildInfoRow(
                AppLocalizations.of(context).roleLabel,
                _managerProfile!.role.title,
              ),
              _buildInfoRow(
                "Reputation", // reputationLabel was missed in ARB, using raw string
                _managerProfile!.reputation.toString(),
              ),
              _buildInfoRow(
                AppLocalizations.of(context).countryLabel,
                _managerProfile!.country,
              ),
            ])
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).noManagerProfile,
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
              label: Text(AppLocalizations.of(context).logOutBtn),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
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
