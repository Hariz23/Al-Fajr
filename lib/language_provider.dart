import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  // Helper to return the correct string based on state
  String getText(String en, String ms) => _isEnglish ? en : ms;
}