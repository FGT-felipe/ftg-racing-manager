import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // FTG Brand Colors - Updated Palette
  static const Color appBackground = Color(0xFF15151E);
  static const Color textNormal = Color(0xFFFFFFFF);
  static const Color accentHighlight = Color(
    0xFFC1C4F4,
  ); // Icons, badges, highlights
  static const Color primaryButton = Color(0xFF3A40B1);
  static const Color secondaryButton = Color(0xFF292A33);
  static const Color buttonHover = Color(0xFF424686);
  static const Color error = Color(0xFFEF5350);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Changed to dark as background is dark
      scaffoldBackgroundColor: appBackground,
      primaryColor: primaryButton,

      colorScheme: ColorScheme.dark(
        primary: primaryButton,
        onPrimary: textNormal,
        secondary: accentHighlight,
        onSecondary: Colors.black, // Dark text on light accent color
        surface: appBackground,
        onSurface: textNormal,
        error: error,
      ),

      textTheme: TextTheme(
        headlineMedium: GoogleFonts.poppins(
          color: textNormal,
          fontWeight: FontWeight.w900, // Black weight
        ),
        headlineSmall: GoogleFonts.poppins(
          color: textNormal,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: GoogleFonts.poppins(
          color: textNormal,
          fontWeight: FontWeight.w900,
        ),
        bodyLarge: GoogleFonts.raleway(color: textNormal, fontSize: 16),
        bodyMedium: GoogleFonts.raleway(
          color: textNormal.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.raleway(
          color: textNormal,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: secondaryButton, // Using secondary dark color for cards
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: appBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textNormal),
        titleTextStyle: GoogleFonts.poppins(
          color: textNormal,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.hovered)) return buttonHover;
            return primaryButton;
          }),
          foregroundColor: WidgetStateProperty.all(textNormal),
          elevation: WidgetStateProperty.all(0),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.raleway(fontWeight: FontWeight.bold),
          ),
          shape: WidgetStateProperty.all(const StadiumBorder()),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: textNormal,
              backgroundColor: secondaryButton,
              side: BorderSide(
                color: textNormal.withValues(alpha: 0.1),
                width: 1,
              ),
              textStyle: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) return buttonHover;
                return secondaryButton;
              }),
            ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.raleway(fontWeight: FontWeight.bold),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: secondaryButton,
        selectedItemColor: accentHighlight,
        unselectedItemColor: textNormal.withValues(alpha: 0.5),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.raleway(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.raleway(fontSize: 12),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: accentHighlight, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
        labelColor: accentHighlight,
        unselectedLabelColor: textNormal.withOpacity(0.4),
      ),
    );
  }
}
