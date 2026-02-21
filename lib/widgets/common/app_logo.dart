import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (withText) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "FTG",
                style: GoogleFonts.montserrat(
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              Text(
                "RACING MANAGER",
                style: GoogleFonts.montserrat(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
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
