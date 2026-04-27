import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'admin_profile_provider.dart';
import 'theme.dart';
import 'super_admin_screen.dart';

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
          // --- LANGUAGE SWITCHER ---
          SwitchListTile(
            secondary: const Icon(Icons.language, color: AppTheme.primaryGreen),
            title: Text(lang.getText("Language", "Bahasa")),
            subtitle: Text(lang.isEnglish ? "English" : "Bahasa Melayu"),
            activeThumbColor: AppTheme.primaryGreen, // Thumb is the moving circle
            activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5), // Track is the path
            value: lang.isEnglish,
            onChanged: (bool value) => lang.toggleLanguage(),
          ),
          const Divider(),

          // --- SUPER ADMIN PORTAL ---
          // Only show this if they are actually the Super Admin
          if (adminProfile.isSuperAdmin) ...[
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.blueAccent, size: 30),
              title: Text(
                lang.getText("Super Admin Portal", "Portal Super Admin"),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              subtitle: Text(lang.getText("Manage Masjids & Users", "Urus Masjid & Pengguna")),
              trailing: const Icon(Icons.chevron_right, color: Colors.blueAccent),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SuperAdminScreen()));
              },
            ),
            const Divider(),
          ],

          // --- LOGOUT ---
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
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(lang.getText("Cancel", "Batal"))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            }, 
            child: Text(
              lang.getText("Logout", "Log Keluar"), 
              style: const TextStyle(color: Colors.red)
            )
          ),
        ],
      ),
    );
  }
}