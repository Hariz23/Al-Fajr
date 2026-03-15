import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'admin_profile_provider.dart';
import 'theme.dart';
import 'super_admin_screen.dart'; // <-- New import!

class SettingsScreen extends StatelessWidget {
  final bool isAdmin; 
  const SettingsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final adminProfile = context.watch<AdminProfileProvider>();

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
            activeColor: AppTheme.primaryGreen,
            value: lang.isEnglish,
            onChanged: (bool value) => lang.toggleLanguage(),
          ),
          const Divider(),

          // --- SUPER ADMIN GOD MODE PANEL ---
          if (adminProfile.isSuperAdmin) ...[
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.blueAccent, size: 30),
              title: const Text("Super Admin Portal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              subtitle: const Text("Manage Masjids & Users"),
              trailing: const Icon(Icons.chevron_right, color: Colors.blueAccent),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SuperAdminScreen()));
              },
            ),
            const Divider(),
          ],

          // --- REGULAR ADMIN (LOCKED) ---
          if (isAdmin && !adminProfile.isSuperAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                lang.getText("Admin Profile", "Profil Admin"),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.grey), // Changed to a lock icon
              title: Text(lang.getText("Assigned Masjid", "Masjid Ditetapkan")),
              subtitle: Text(
                adminProfile.isProfileComplete 
                  ? "${adminProfile.masjidName} (${adminProfile.state})" 
                  : lang.getText("Contact Super Admin to assign", "Sila hubungi Super Admin")
              ),
              // NO onTap HERE! They are locked.
            ),
            const Divider(),
          ],

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
              FirebaseAuth.instance.signOut();
            }, 
            child: Text(lang.getText("Logout", "Log Keluar"), style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}