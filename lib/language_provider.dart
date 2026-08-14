import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  final Map<String, bool> _prayerNotifications = {
    "Fajr": true,
    "Dhuhr": true,
    "Asr": true,
    "Maghrib": true,
    "Isha": true,
  };

  Map<String, bool> get prayerNotifications => _prayerNotifications;

  LanguageProvider() {
    _loadFromDisk();
  }

  // --- 2. STORAGE & LANGUAGE ---
  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? true;
    _prayerNotifications.forEach((key, value) {
      _prayerNotifications[key] = prefs.getBool('notify_$key') ?? true;
    });
    notifyListeners();
  }

  Future<void> toggleLanguage() => setEnglish(!_isEnglish);

  /// Selects a language outright. The segmented control picks a side rather
  /// than flipping, so tapping the active one must be a no-op.
  Future<void> setEnglish(bool value) async {
    if (_isEnglish == value) return;
    _isEnglish = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', _isEnglish);
    notifyListeners();
  }

  Future<void> togglePrayerNotification(String prayerKey) async {
    if (_prayerNotifications.containsKey(prayerKey)) {
      _prayerNotifications[prayerKey] = !_prayerNotifications[prayerKey]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'notify_$prayerKey',
        _prayerNotifications[prayerKey]!,
      );
      notifyListeners();
    }
  }

  String getText(String en, String ms) => _isEnglish ? en : ms;
}
