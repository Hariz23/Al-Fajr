import 'package:flutter/material.dart';

class AdminProfileProvider extends ChangeNotifier {
  String? _masjidName;
  String? _state;

  String? get masjidName => _masjidName;
  String? get state => _state;

  // Checks if the boss's requirement for State/Masjid is met
  bool get isProfileComplete => _masjidName != null && _state != null;

  void updateProfile(String name, String state) {
    _masjidName = name;
    _state = state;
    notifyListeners(); // Updates the UI everywhere
  }
}