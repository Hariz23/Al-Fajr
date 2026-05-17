import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'notification_service.dart';
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
        children: [
          // STATUS CHECKER
          FutureBuilder<bool>(
            future: NotificationService().checkAlarmPermission(),
            builder: (context, snapshot) {
              final granted = snapshot.data ?? false;
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: granted ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: granted ? Colors.green : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(granted ? Icons.check_circle : Icons.error, color: granted ? Colors.green : Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      granted ? "System Ready" : "System Blocked - Grant Below",
                      style: TextStyle(fontWeight: FontWeight.bold, color: granted ? Colors.green[800] : Colors.red[800]),
                    ),
                  ],
                ),
              );
            },
          ),

          ...settings.keys.map((prayer) {
            final isEnabled = settings[prayer]!;
            return SwitchListTile(
              activeColor: AppTheme.primaryGreen,
              title: Text(_getPrayerName(prayer, lang)),
              value: isEnabled,
              onChanged: (bool value) async {
                lang.togglePrayerNotification(prayer);
                if (!value) {
                  await NotificationService().cancelPrayer(_getPrayerId(prayer));
                }
              },
            );
          }),

          const Divider(thickness: 2, height: 40),

          // DEBUG TOOLS
          ListTile(
            leading: const Icon(Icons.timer, color: Colors.orange),
            title: const Text("Set Manual Test Azan"),
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                await NotificationService().scheduleDebug(id: 88, pickedTime: picked);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Colors.blue),
            title: const Text("Check Pending Queue"),
            onTap: () => NotificationService().checkPending(),
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.red),
            title: const Text("Grant Alarm Permission"),
            onTap: () => NotificationService().openAlarmSettings(),
          ),
        ],
      ),
    );
  }

  int _getPrayerId(String prayer) {
    switch (prayer) {
      case "Fajr": return 0;
      case "Dhuhr": return 1;
      case "Asr": return 2;
      case "Maghrib": return 3;
      case "Isha": return 4;
      default: return 99;
    }
  }

  String _getPrayerName(String prayer, LanguageProvider lang) {
    if (lang.isEnglish) return prayer;
    Map<String, String> msNames = {
      "Fajr": "Subuh", "Dhuhr": "Zohor", "Asr": "Asar", "Maghrib": "Maghrib", "Isha": "Isyak",
    };
    return msNames[prayer] ?? prayer;
  }
}