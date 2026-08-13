import 'package:flutter/cupertino.dart';
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

  static const Color primaryGreen = Color(0xFF0B6B4D);
  static const Color primaryGreenDark = Color(0xFF064532);
  static const Color accentGold = Color(0xFFD5A748);
  static const Color mint = Color(0xFFE7F3ED);
  static const Color mintStrong = Color(0xFFCDE8DB);
  static const Color warmCream = Color(0xFFFAF5E9);
  static const Color paleGold = Color(0xFFF5EBD2);

  static const Color bgSoftWhite = Color(0xFFF4F6F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F3F1);

  static const Color textPrimary = Color(0xFF18201D);
  static const Color textSecondary = Color(0xFF68716D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFE2E8E5);
  static const Color danger = Color(0xFFC62828);
  static const Color success = Color(0xFF16835F);
  static const Color warning = Color(0xFFB76E00);
  static const Color info = Color(0xFF2F6CA8);

  // ---------------------------------------------------------------------------
  // Shape and spacing tokens
  // ---------------------------------------------------------------------------

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 26;

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
      splashFactory: NoSplash.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
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
          minimumSize: const Size(44, 52),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.35),
          elevation: 0,
          minimumSize: const Size(44, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
          minimumSize: const Size(44, 48),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        prefixIconColor: textSecondary,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMd,
          borderSide: const BorderSide(color: danger, width: 1.5),
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

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textOnPrimary
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primaryGreen : divider,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: mint,
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusLg),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusLg),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusLg),
      ),

      dividerTheme: const DividerThemeData(color: divider, thickness: 0.5),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSm),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
