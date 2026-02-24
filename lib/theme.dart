import 'package:flutter/material.dart';

class AppTheme {
  // Replace these with the EXACT hex codes from your mockup
  static const Color primaryGreen = Color(0xFF006400); // Deep Islamic Green
  static const Color accentGold = Color(0xFFC5A059);   // Modern Gold
  static const Color bgSoftWhite = Color(0xFFF8F9FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGold,
      ),
      scaffoldBackgroundColor: bgSoftWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}