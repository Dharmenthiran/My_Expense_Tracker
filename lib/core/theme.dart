import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Light Theme Colors
  static const Color _lightPrimary = Color(0xFF6366F1); // Indigo
  static const Color _lightSecondary = Color(0xFFEC4899); // Pink
  static const Color _lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color _lightSurface = Color(0xFFFFFFFF);

  // Premium Dark Theme Colors
  static const Color _darkPrimary = Color(0xFF818CF8); // Indigo 400
  static const Color _darkSecondary = Color(0xFFF472B6); // Pink 400
  static const Color _darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color _darkSurface = Color(0xFF1E293B); // Slate 800

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _lightPrimary,
      primary: _lightPrimary,
      secondary: _lightSecondary,
      surface: _lightSurface,
      background: _lightBackground,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.outfitTextTheme(),
    scaffoldBackgroundColor: _lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkPrimary,
      primary: _darkPrimary,
      secondary: _darkSecondary,
      surface: _darkSurface,
      background: _darkBackground,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  
  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [_lightPrimary, _lightSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x66FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0xCC1E293B), Color(0x661E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
