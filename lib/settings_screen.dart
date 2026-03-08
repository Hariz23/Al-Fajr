import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'admin_profile_provider.dart';
import 'theme.dart';

// --- MAIN SETTINGS SCREEN ---
class SettingsScreen extends StatelessWidget {
  final bool isAdmin; 
  const SettingsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final adminProfile = Provider.of<AdminProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Settings", "Tetapan")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // 1. Language Toggle
          SwitchListTile(
            secondary: const Icon(Icons.language, color: AppTheme.primaryGreen),
            title: Text(lang.getText("Language", "Bahasa")),
            subtitle: Text(lang.isEnglish ? "English" : "Bahasa Melayu"),
            activeColor: AppTheme.primaryGreen,
            value: lang.isEnglish,
            onChanged: (bool value) => lang.toggleLanguage(),
          ),
          const Divider(),

          // 2. Admin Identity Section (Visible ONLY to Admins)
          if (isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                lang.getText("Admin Profile", "Profil Admin"),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: AppTheme.primaryGreen),
              title: Text(lang.getText("Masjid & State", "Masjid & Negeri")),
              subtitle: Text(
                adminProfile.isProfileComplete 
                  ? "${adminProfile.masjidName} (${adminProfile.state})" 
                  : lang.getText("Required for posting", "Wajib diisi untuk memulakan pos")
              ),
              trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
              onTap: () => _showAdminIdentityDialog(context, adminProfile, lang),
            ),
            const Divider(),
          ],

          // 3. PRAYER NOTIFICATIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              lang.getText("Notifications", "Notifikasi"),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryGreen),
            title: Text(lang.getText("Prayer Time Alerts", "Amaran Waktu Solat")),
            subtitle: Text(lang.getText("Configure Azan sounds", "Tetapkan bunyi Azan")),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const PrayerNotificationDetailScreen())
              );
            },
          ),
          const Divider(),

          // 4. Logout
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

  void _showAdminIdentityDialog(BuildContext context, AdminProfileProvider profile, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AdminIdentityPicker(profile: profile, lang: lang),
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
              FirebaseAuth.instance.signOut();
            }, 
            child: Text(lang.getText("Logout", "Log Keluar"), style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}

// --- PRAYER NOTIFICATION DETAIL SCREEN CLASS ---
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
        children: [
          // --- DEBUG BUTTON SECTION ---
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Debug Tool", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => lang.showTestAzanNotification(),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text("TEST AZAN NOTIFICATION", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const Text(
                  "Triggers notification immediately to verify sound settings.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                )
              ],
            ),
          ),
          const Divider(),

          // --- PRAYER TOGGLES ---
          ...prayers.keys.map((prayerKey) {
            return SwitchListTile(
              activeColor: AppTheme.primaryGreen,
              title: Text(lang.isEnglish ? prayerKey : _translatePrayer(prayerKey)),
              value: prayers[prayerKey]!,
              onChanged: (bool value) => lang.togglePrayerNotification(prayerKey),
            );
          }),
        ],
      ),
    );
  }

  String _translatePrayer(String key) {
    Map<String, String> translations = {
      "Fajr": "Subuh", "Dhuhr": "Zohor", "Asr": "Asar", "Maghrib": "Maghrib", "Isha": "Isyak"
    };
    return translations[key] ?? key;
  }
}

// --- ADMIN IDENTITY PICKER WIDGET CLASS ---
class AdminIdentityPicker extends StatefulWidget {
  final AdminProfileProvider profile;
  final LanguageProvider lang;
  const AdminIdentityPicker({super.key, required this.profile, required this.lang});

  @override
  State<AdminIdentityPicker> createState() => _AdminIdentityPickerState();
}

class _AdminIdentityPickerState extends State<AdminIdentityPicker> {
  final List<String> _states = ["Selangor", "Putrajaya", "Kuala Lumpur"];
  final Map<String, List<String>> _masjids = {
    "Selangor": ["Masjid Bukit Jelutong", "Masjid Subang Jaya"],
    "Putrajaya": ["Masjid Putra"],
    "Kuala Lumpur": ["Masjid Wilayah"],
  };

  String? _tempState;
  String? _tempMasjid;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lang.getText("Identity Setup", "Tetapan Identiti")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "State"),
            items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() { _tempState = val; _tempMasjid = null; }),
          ),
          const SizedBox(height: 10),
          if (_tempState != null)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Masjid/Surau"),
              items: _masjids[_tempState]!.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _tempMasjid = val),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.lang.getText("Cancel", "Batal"))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          onPressed: () {
            if (_tempState != null && _tempMasjid != null) {
              widget.profile.updateProfile(_tempMasjid!, _tempState!);
              Navigator.pop(context);
            }
          },
          child: Text(widget.lang.getText("Save", "Simpan"), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}