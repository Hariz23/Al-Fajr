import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProfileProvider with ChangeNotifier {
  String? _masjidName;
  String? _state;

  String? get masjidName => _masjidName;
  String? get state => _state;

  // Persistence: Loads data from disk when the app starts
  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _masjidName = prefs.getString('masjidName');
    _state = prefs.getString('state');
    notifyListeners();
  }

  // UPDATED: Added SharedPreferences logic while KEEPING your names
  void updateProfile(String masjidName, String state) async {
    this._masjidName = masjidName;
    this._state = state;
    notifyListeners();

    // ADAPTATION: Save to local storage so it persists after closing
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('masjidName', masjidName);
    await prefs.setString('state', state);
  }

  bool get isProfileComplete => _masjidName != null && _masjidName!.isNotEmpty && _state != null;
}