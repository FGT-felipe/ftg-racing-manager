import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // FTG Brand Colors
  static const Color neonGreen = Color(0xFF00FF88); // Verde Neón FTG
  static const Color darkText = Color(0xFF1A1A1A); // Casi negro para texto
  static const Color lightBackground = Color(0xFFF5F5F5); // Blanco grisáceo
  static const Color cardWhite = Colors.white;
  static const Color error = Color(0xFFEF5350);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: neonGreen,

      colorScheme: ColorScheme.light(
        primary: neonGreen,
        onPrimary: Colors.black,
        secondary: neonGreen.withValues(alpha: 0.7),
        surface: cardWhite,
        onSurface: darkText,
        error: error,
        background: lightBackground,
        onBackground: darkText,
      ),

      textTheme: TextTheme(
        headlineMedium: GoogleFonts.outfit(
          color: darkText,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: darkText,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: darkText,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: darkText, fontSize: 16),
        bodyMedium: GoogleFonts.inter(
          color: darkText.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.inter(
          color: darkText,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: neonGreen.withValues(alpha: 0.2), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: cardWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.outfit(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: neonGreen, width: 2),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: neonGreen,
        unselectedItemColor: darkText.withValues(alpha: 0.5),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
    );
  }
}
