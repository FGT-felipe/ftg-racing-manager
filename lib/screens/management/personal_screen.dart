import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalScreen extends StatelessWidget {
  final String teamId;
  final VoidCallback onDriversTap;

  const PersonalScreen({
    super.key,
    required this.teamId,
    required this.onDriversTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Personal Management'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _PersonalCard(
            title: 'Drivers',
            icon: Icons.people_alt_rounded,
            onTap: onDriversTap,
            isEnabled: true,
          ),
          _PersonalCard(
            title: 'Fitness Trainer',
            icon: Icons.fitness_center_rounded,
            onTap: () {},
            isEnabled: false,
          ),
          _PersonalCard(
            title: 'Chief Engineer',
            icon: Icons.engineering_rounded,
            onTap: () {},
            isEnabled: false,
          ),
          _PersonalCard(
            title: 'HR Manager',
            icon: Icons.badge_rounded,
            onTap: () {},
            isEnabled: false,
          ),
          _PersonalCard(
            title: 'Marketing Manager',
            icon: Icons.campaign_rounded,
            onTap: () {},
            isEnabled: false,
          ),
        ],
      ),
    );
  }
}

class _PersonalCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _PersonalCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          color: isEnabled
              ? theme.cardTheme.color
              : theme.cardTheme.color?.withValues(alpha: 0.5),
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: isEnabled
                        ? theme.colorScheme.secondary
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isEnabled ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isEnabled)
          Positioned(
            top: 10,
            right: -25,
            child: Transform.rotate(
              angle: 0.785, // 45 degrees
              child: Container(
                width: 100,
                color: Colors.redAccent.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text(
                  'SOON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
