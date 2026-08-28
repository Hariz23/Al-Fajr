import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_profile_provider.dart';
import 'app_ui.dart';
import 'language_provider.dart';
import 'language_switch.dart';
import 'notifications_settings_screen.dart';
import 'super_admin_screen.dart';
import 'theme.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final lang        = context.watch<LanguageProvider>();
    final themeP      = context.watch<ThemeProvider>();
    final user        = FirebaseAuth.instance.currentUser;
    final isSuperAdmin = role == 'super_admin';
    final email       = user?.email ?? lang.getText('Signed-in account', 'Akaun aktif');
    final initial     = email.isEmpty ? 'A' : email.characters.first.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 20,
        title: Text(
          lang.getText('Settings', 'Tetapan'),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
          children: [

            // ── Profile card (tappable) ──────────────────────────────
            GestureDetector(
              onTap: () => _showProfileSheet(context, lang, email, initial, themeP),
              child: AppSurface(
                color: themeP.primaryGreenDark,
                borderColor: themeP.primaryGreenDark,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: themeP.accentGold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: themeP.primaryGreenDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textOnPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.textOnPrimary.withValues(alpha: 0.12),
                              borderRadius: AppTheme.borderRadiusLg,
                            ),
                            child: Text(
                              _roleLabel(role, lang),
                              style: const TextStyle(
                                color: AppTheme.textOnPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tap hint icon
                    const Icon(CupertinoIcons.chevron_right,
                        color: AppTheme.textOnPrimary, size: 18),
                  ],
                ),
              ),
            ),

            // ── Preferences ─────────────────────────────────────────
            AppSectionTitle(title: lang.getText('PREFERENCES', 'PILIHAN')),
            AppSettingsGroup(
              children: [
                AppSettingsRow(
                  icon: CupertinoIcons.globe,
                  title: lang.getText('Language', 'Bahasa'),
                  subtitle: lang.isEnglish ? 'English' : 'Bahasa Melayu',
                  trailing: LanguageSwitch(
                    isEnglish: lang.isEnglish,
                    onChanged: lang.setEnglish,
                  ),
                ),
                AppSettingsRow(
                  icon: CupertinoIcons.bell_fill,
                  title: lang.getText('Azan notifications', 'Notifikasi azan'),
                  subtitle: lang.getText(
                    'Choose alerts for each prayer',
                    'Pilih amaran bagi setiap solat',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),

        /*    ── Appearance ──────────────────────────────────────────
            AppSectionTitle(title: lang.getText('APPEARANCE', 'PENAMPILAN')),
            AppSettingsGroup(
              children: [
                Dark mode toggle
                AppSettingsRow(
                  icon: CupertinoIcons.moon_fill,
                  title: lang.getText('Dark mode', 'Mod gelap'),
                  subtitle: themeP.isDark
                      ? lang.getText('On', 'Hidup')
                      : lang.getText('Off', 'Mati'),
                  trailing: CupertinoSwitch(
                    value: themeP.isDark,
                    activeTrackColor: themeP.primaryGreen,
                    onChanged: (_) => themeP.toggleDark(),
                  ),
                ),
              Color scheme picker
                AppSettingsRow(
                  icon: CupertinoIcons.paintbrush_fill,
                  title: lang.getText('Colour theme', 'Tema warna'),
                  subtitle: _schemeLabel(themeP.scheme, lang),
                  onTap: () => _showColorPicker(context, lang, themeP),
                ),
              ],
            ), */

            // ── Super admin ─────────────────────────────────────────
            if (isSuperAdmin) ...[
              AppSectionTitle(title: lang.getText('ADMINISTRATION', 'PENTADBIRAN')),
              AppSettingsGroup(
                children: [
                  AppSettingsRow(
                    icon: CupertinoIcons.shield_lefthalf_fill,
                    iconColor: AppTheme.info,
                    title: lang.getText('Super Admin portal', 'Portal Super Admin'),
                    subtitle: lang.getText(
                      'Manage mosques and administrators',
                      'Urus masjid dan pentadbir',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SuperAdminScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Account ─────────────────────────────────────────────
            AppSectionTitle(title: lang.getText('ACCOUNT', 'AKAUN')),
            AppSettingsGroup(
              children: [
                AppSettingsRow(
                  icon: CupertinoIcons.square_arrow_right,
                  title: lang.getText('Sign out', 'Log keluar'),
                  destructive: true,
                  onTap: () => _signOut(context, lang),
                ),
              ],
            ),

            const SizedBox(height: 22),
            const Text(
              'Al Fajr • Made for mindful daily worship',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile bottom sheet ───────────────────────────────────────────
  void _showProfileSheet(
    BuildContext context,
    LanguageProvider lang,
    String email,
    String initial,
    ThemeProvider themeP,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Avatar
            Container(
              width: 80, height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: themeP.accentGold,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: TextStyle(
                  color: themeP.primaryGreenDark,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              email,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              lang.getText(
                'Your account is managed by Firebase Authentication.\nTo change your email or password, use the options below.',
                'Akaun anda diurus oleh Firebase Authentication.\nGunakan pilihan di bawah untuk tukar e-mel atau kata laluan.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // Change password
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(CupertinoIcons.lock_rotation),
                label: Text(lang.getText('Send password reset email', 'Hantar e-mel tetapan semula kata laluan')),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user?.email != null) {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(lang.getText('Reset email sent!', 'E-mel tetapan semula dihantar!'))),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            // Close
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.getText('Close', 'Tutup')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Color scheme picker ────────────────────────────────────────────
 /* void _showColorPicker(BuildContext context, LanguageProvider lang, ThemeProvider themeP) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              lang.getText('Choose a colour theme', 'Pilih tema warna'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ...AppColorScheme.values.map((scheme) {
              final isSelected = themeP.scheme == scheme;
              // Preview colors per scheme
              final Color previewPrimary = switch (scheme) {
                AppColorScheme.green  => const Color(0xFF2E7D32),
                AppColorScheme.blue   => const Color(0xFF1565C0),
                AppColorScheme.purple => const Color(0xFF6A1B9A),
                AppColorScheme.maroon => const Color(0xFF880E4F),
              };
              final Color previewAccent = switch (scheme) {
                AppColorScheme.green  => const Color(0xFFFFCA28),
                AppColorScheme.blue   => const Color(0xFF80D8FF),
                AppColorScheme.purple => const Color(0xFFCE93D8),
                AppColorScheme.maroon => const Color(0xFFFFCC80),
              };
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(backgroundColor: previewPrimary, radius: 14),
                    const SizedBox(width: 6),
                    CircleAvatar(backgroundColor: previewAccent, radius: 10),
                  ],
                ),
                title: Text(_schemeLabel(scheme, lang),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: isSelected
                    ? Icon(CupertinoIcons.checkmark_circle_fill, color: themeP.primaryGreen)
                    : null,
                onTap: () {
                  themeP.setScheme(scheme);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  } */

  // ── Helpers ────────────────────────────────────────────────────────
  String _roleLabel(String role, LanguageProvider lang) {
    return switch (role) {
      'super_admin' => lang.getText('SUPER ADMIN', 'SUPER ADMIN'),
      'admin'       => lang.getText('MOSQUE ADMIN', 'ADMIN MASJID'),
      _             => lang.getText('COMMUNITY MEMBER', 'AHLI KOMUNITI'),
    };
  }

 /* String _schemeLabel(AppColorScheme scheme, LanguageProvider lang) {
    return switch (scheme) {
      AppColorScheme.green  => lang.getText('Forest Green', 'Hijau Hutan'),
      AppColorScheme.blue   => lang.getText('Ocean Blue', 'Biru Laut'),
      AppColorScheme.purple => lang.getText('Royal Purple', 'Ungu Diraja'),
      AppColorScheme.maroon => lang.getText('Deep Maroon', 'Merah Gelap'),
    };
  } */

  Future<void> _signOut(BuildContext context, LanguageProvider lang) async {
    final confirmed = await showDestructiveConfirmation(
      context,
      title: lang.getText('Sign out?', 'Log keluar?'),
      message: lang.getText(
        'You can sign back in at any time.',
        'Anda boleh log masuk semula pada bila-bila masa.',
      ),
      confirmLabel: lang.getText('Sign out', 'Log keluar'),
      cancelLabel: lang.getText('Cancel', 'Batal'),
    );
    if (!confirmed || !context.mounted) return;
    context.read<AdminProfileProvider>().clearProfile();
    await FirebaseAuth.instance.signOut();
  }
}