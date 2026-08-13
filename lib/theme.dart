import 'package:flutter/material.dart';

/// Single source of truth for the app's visual language.
///
/// Screens should not hardcode colors, radii or component styling. They read
/// from the active theme (`Theme.of(context)`) or from the tokens below, so a
/// restyle is a change to this file rather than a sweep across every screen.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Color tokens
  // ---------------------------------------------------------------------------

  static const Color primaryGreen = Color(0xFF006400); // Deep Islamic Green
  static const Color primaryGreenDark = Color(0xFF004B00);
  static const Color accentGold = Color(0xFFC5A059); // Modern Gold

  static const Color bgSoftWhite = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFE4E6E8);
  static const Color danger = Color(0xFFC62828);

  // ---------------------------------------------------------------------------
  // Shape and spacing tokens
  // ---------------------------------------------------------------------------

  static const double radiusSm = 10;
  static const double radiusMd = 15;
  static const double radiusLg = 20;

  static const double spaceSm = 8;
  static const double spaceMd = 15;
  static const double spaceLg = 25;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  /// Height used by the full-width primary actions on the auth screens.
  static const double buttonHeight = 56;

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      onPrimary: textOnPrimary,
      secondary: accentGold,
      surface: surface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgSoftWhite,
      dividerColor: divider,

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.4),
          disabledForegroundColor: textOnPrimary,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMd),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        prefixIconColor: textSecondary,
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(borderRadius: borderRadiusMd),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: const BorderSide(color: danger),
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMd,
          side: const BorderSide(color: divider),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: primaryGreen,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 13),
      ),

      dividerTheme: const DividerThemeData(color: divider, thickness: 0.5),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSm),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),
    );
  }
}
