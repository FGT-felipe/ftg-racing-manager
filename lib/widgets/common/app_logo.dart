import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size; // Base size for the icon
  final bool
  isDark; // To toggle text color (Dark text for Light bg, White for Dark bg)
  final bool withText;

  const AppLogo({
    super.key,
    this.size = 40,
    this.isDark = true, // Default to dark text (for light backgrounds)
    this.withText = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF10B981); // Emerald
    final Color textColor = isDark ? const Color(0xFF1E1E24) : Colors.white;

    return Row(
      // Row for horizontal layout (Icon + Text)
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.sports_motorsports, size: size, color: primaryColor),
        if (withText) ...[
          SizedBox(width: size * 0.3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "FTG RACING",
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 1.2,
                  height: 1.0,
                ),
              ),
              Text(
                "MANAGER 2026",
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
