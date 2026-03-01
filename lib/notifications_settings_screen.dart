import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'theme.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final settings = lang.prayerNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Notification Settings", "Tetapan Notifikasi")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: settings.keys.map((prayer) {
          return SwitchListTile(
            activeColor: AppTheme.primaryGreen,
            secondary: Icon(
              settings[prayer]! ? Icons.notifications_active : Icons.notifications_off,
              color: settings[prayer]! ? AppTheme.primaryGreen : Colors.grey,
            ),
            title: Text(_getPrayerName(prayer, lang)),
            subtitle: Text(
              settings[prayer]! 
                ? lang.getText("Enabled", "Aktif") 
                : lang.getText("Disabled", "Dimatikan")
            ),
            value: settings[prayer]!,
            onChanged: (bool value) {
              lang.togglePrayerNotification(prayer);
            },
          );
        }).toList(),
      ),
    );
  }

  // Helper to translate prayer names
  String _getPrayerName(String prayer, LanguageProvider lang) {
    if (lang.isEnglish) return prayer;
    Map<String, String> msNames = {
      "Fajr": "Subuh",
      "Dhuhr": "Zohor",
      "Asr": "Asar",
      "Maghrib": "Maghrib",
      "Isha": "Isyak",
    };
    return msNames[prayer] ?? prayer;
  }
}