import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette
  static const Color neonApex = Color(0xFF10B981); // Emerald Green
  static const Color carbonFiber = Color(0xFF0F172A); // Slate 900
  static const Color metalCool = Color(0xFF94A3B8); // Slate 400
  static const Color background = Color(0xFFF4F6F8); // Soft Cool Grey
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFEF5350);
  static const Color success = Color(0xFF66BB6A);
  static const Color textBody = Color(0xFF334155); // Slate 700

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: neonApex,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: neonApex,
        onPrimary: carbonFiber,
        secondary: metalCool,
        surface: surface,
        onSurface: carbonFiber,
        error: error,
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.outfit(
          color: carbonFiber,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: carbonFiber,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: carbonFiber,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: carbonFiber, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textBody, fontSize: 14),
        labelLarge: GoogleFonts.inter(
          color: carbonFiber,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: carbonFiber.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: carbonFiber.withValues(alpha: 0.05)),
        ),
        margin: EdgeInsets.zero,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: carbonFiber),
        titleTextStyle: GoogleFonts.outfit(
          color: carbonFiber,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),

      // Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: neonApex),
        unselectedIconTheme: IconThemeData(
          color: metalCool.withValues(alpha: 0.7),
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: carbonFiber,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(color: metalCool),
        indicatorColor: neonApex.withValues(alpha: 0.2),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: neonApex,
        unselectedItemColor: metalCool,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonApex,
          foregroundColor: carbonFiber,
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
          foregroundColor: carbonFiber,
          side: const BorderSide(color: neonApex, width: 2),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
