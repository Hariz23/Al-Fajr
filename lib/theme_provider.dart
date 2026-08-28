import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorScheme { green, blue, purple, maroon }

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  AppColorScheme _scheme = AppColorScheme.green;

  bool get isDark => _isDark;
  AppColorScheme get scheme => _scheme;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
    _scheme = AppColorScheme.values[prefs.getInt('colorScheme') ?? 0];
    notifyListeners();
  }

  Future<void> toggleDark() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  Future<void> setScheme(AppColorScheme scheme) async {
    _scheme = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorScheme', scheme.index);
    notifyListeners();
  }

  // Primary color per scheme — used by MaterialApp
  Color get primaryGreen => switch (_scheme) {
    AppColorScheme.green  => const Color(0xFF0B6B4D), // your original
    AppColorScheme.blue   => const Color(0xFF1565C0),
    AppColorScheme.purple => const Color(0xFF6A1B9A),
    AppColorScheme.maroon => const Color(0xFF880E4F),
  };

  Color get primaryGreenDark => switch (_scheme) {
    AppColorScheme.green  => const Color(0xFF064532), // your original
    AppColorScheme.blue   => const Color(0xFF0D47A1),
    AppColorScheme.purple => const Color(0xFF4A148C),
    AppColorScheme.maroon => const Color(0xFF560027),
  };

  Color get accentGold => switch (_scheme) {
    AppColorScheme.green  => const Color(0xFFD5A748), // your original
    AppColorScheme.blue   => const Color(0xFF80D8FF),
    AppColorScheme.purple => const Color(0xFFCE93D8),
    AppColorScheme.maroon => const Color(0xFFFFCC80),
  };
}