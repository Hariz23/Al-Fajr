import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Settings", "Tetapan")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.language, color: AppTheme.primaryGreen),
            title: Text(lang.getText("Language", "Bahasa")),
            subtitle: Text(lang.isEnglish ? "English" : "Bahasa Melayu"),
            activeThumbColor: AppTheme.primaryGreen,
            value: lang.isEnglish,
            onChanged: (bool value) => lang.toggleLanguage(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_none, color: AppTheme.primaryGreen),
            title: Text(lang.getText("Prayer Notifications", "Notifikasi Solat")),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrayerNotificationDetailScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              lang.getText("Logout", "Log Keluar"),
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showLogoutDialog(context, lang),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.getText("Logout", "Log Keluar")),
        content: Text(lang.getText("Are you sure?", "Adakah anda pasti?")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.getText("Cancel", "Batal"))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            }, 
            child: Text(lang.getText("Logout", "Log Keluar"), style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}

class PrayerNotificationDetailScreen extends StatelessWidget {
  const PrayerNotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final prayers = lang.prayerNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Notification Settings", "Tetapan Notifikasi")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: prayers.keys.map((prayerKey) {
          return SwitchListTile(
            activeThumbColor: AppTheme.primaryGreen,
            title: Text(_getPrayerDisplayName(prayerKey, lang)),
            value: prayers[prayerKey]!,
            onChanged: (bool value) {
              // Now matches the method name in LanguageProvider
              lang.togglePrayerNotification(prayerKey);
            },
          );
        }).toList(),
      ),
    );
  }

  String _getPrayerDisplayName(String key, LanguageProvider lang) {
    if (lang.isEnglish) return key;
    const names = {"Fajr": "Subuh", "Dhuhr": "Zohor", "Asr": "Asar", "Maghrib": "Maghrib", "Isha": "Isyak"};
    return names[key] ?? key;
  }
}