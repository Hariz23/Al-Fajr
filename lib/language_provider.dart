import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  Map<String, bool> _prayerNotifications = {
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

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? true;
    _prayerNotifications.forEach((key, value) {
      _prayerNotifications[key] = prefs.getBool('notify_$key') ?? true;
    });
    notifyListeners();
  }

  void toggleLanguage() async {
    _isEnglish = !_isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', _isEnglish);
    notifyListeners();
  }

  // FIXED: Renamed to match the UI call
  void togglePrayerNotification(String prayerKey) async {
    if (_prayerNotifications.containsKey(prayerKey)) {
      _prayerNotifications[prayerKey] = !_prayerNotifications[prayerKey]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_$prayerKey', _prayerNotifications[prayerKey]!);
      notifyListeners();
    }
  }

  String getText(String en, String ms) => _isEnglish ? en : ms;
}