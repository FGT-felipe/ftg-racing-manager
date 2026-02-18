import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InstructionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? extraContent;

  const InstructionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.15),
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (extraContent != null) ...[
              const SizedBox(height: 8),
              extraContent!,
            ],
          ],
        ),
      ),
    );
  }
}
