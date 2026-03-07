import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Dark Theme Brand Colors ──
  static const Color _darkBackground = Color(0xFF15151E);
  static const Color _darkText = Color(0xFFFFFFFF);
  static const Color _darkAccent = Color(0xFFC1C4F4);
  static const Color _darkPrimary = Color(0xFF3A40B1);
  static const Color _darkCardColor = Color(0xFF292A33);
  static const Color _darkButtonHover = Color(0xFF424686);
  static const Color _errorColor = Color(0xFFEF5350);

  // ── Light Theme Brand Colors ──
  static const Color _lightBackground = Color(0xFFF2F3F8);
  static const Color _lightText = Color(0xFF1A1A2E);
  static const Color _lightAccent = Color(0xFF5A5FBF);
  static const Color _lightPrimary = Color(0xFF3A40B1);
  static const Color _lightCardColor = Color(0xFFFFFFFF);
  static const Color _lightButtonHover = Color(0xFF5258C9);

  // ═══════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      primaryColor: _darkPrimary,

      colorScheme: ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: _darkText,
        secondary: _darkAccent,
        onSecondary: Colors.black,
        surface: _darkBackground,
        onSurface: _darkText,
        error: _errorColor,
      ),

      textTheme: TextTheme(
        headlineMedium: GoogleFonts.poppins(
          color: _darkText,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: _darkText,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: GoogleFonts.poppins(
          color: _darkText,
          fontWeight: FontWeight.w900,
        ),
        bodyLarge: GoogleFonts.raleway(color: _darkText, fontSize: 16),
        bodyMedium: GoogleFonts.raleway(
          color: _darkText.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.raleway(
          color: _darkText,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: _darkCardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _darkText),
        titleTextStyle: GoogleFonts.poppins(
          color: _darkText,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.hovered)) return _darkButtonHover;
            return _darkPrimary;
          }),
          foregroundColor: WidgetStateProperty.all(_darkText),
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
              foregroundColor: _darkText,
              backgroundColor: _darkCardColor,
              side: BorderSide(
                color: _darkText.withValues(alpha: 0.1),
                width: 1,
              ),
              textStyle: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return _darkButtonHover;
                }
                return _darkCardColor;
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
        backgroundColor: _darkCardColor,
        selectedItemColor: _darkAccent,
        unselectedItemColor: _darkText.withValues(alpha: 0.5),
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
          borderSide: BorderSide(color: _darkAccent, width: 2),
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
        labelColor: _darkAccent,
        unselectedLabelColor: _darkText.withValues(alpha: 0.4),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      primaryColor: _lightPrimary,
      dividerColor: _lightText.withValues(alpha: 0.1),

      colorScheme: ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: Colors.white,
        secondary: _lightAccent,
        onSecondary: Colors.white,
        surface: _lightBackground,
        onSurface: _lightText,
        error: _errorColor,
      ),

      textTheme: TextTheme(
        headlineMedium: GoogleFonts.poppins(
          color: _lightText,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: _lightText,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: GoogleFonts.poppins(
          color: _lightText,
          fontWeight: FontWeight.w900,
        ),
        bodyLarge: GoogleFonts.raleway(color: _lightText, fontSize: 16),
        bodyMedium: GoogleFonts.raleway(
          color: _lightText.withValues(alpha: 0.75),
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.raleway(
          color: _lightText,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: _lightCardColor,
        elevation: 2, // Slightly more elevation for depth in light mode
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _lightText),
        titleTextStyle: GoogleFonts.poppins(
          color: _lightText,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),

      iconTheme: const IconThemeData(color: _lightText),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.hovered)) return _lightButtonHover;
            return _lightPrimary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
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
              foregroundColor: _lightText,
              backgroundColor: _lightCardColor,
              side: BorderSide(
                color: _lightText.withValues(alpha: 0.12),
                width: 1,
              ),
              textStyle: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return _lightPrimary.withValues(alpha: 0.08);
                }
                return _lightCardColor;
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
        backgroundColor: _lightCardColor,
        selectedItemColor: _lightPrimary,
        unselectedItemColor: _lightText.withValues(alpha: 0.45),
        elevation: 4,
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
          borderSide: BorderSide(color: _lightPrimary, width: 2),
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
        labelColor: _lightPrimary,
        unselectedLabelColor: _lightText.withValues(alpha: 0.4),
      ),
    );
  }
}
