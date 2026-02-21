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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Personal Management'.toUpperCase(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: screenWidth > 1200 ? 3 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.85,
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isEnabled ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 34,
                      color: isEnabled
                          ? theme.colorScheme.secondary
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isEnabled ? Colors.white : Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
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
                  'COMING SOON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
