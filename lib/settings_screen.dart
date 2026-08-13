import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_profile_provider.dart';
import 'app_ui.dart';
import 'language_provider.dart';
import 'notifications_settings_screen.dart';
import 'super_admin_screen.dart';
import 'theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final isSuperAdmin = role == 'super_admin';
    final email =
        user?.email ?? lang.getText('Signed-in account', 'Akaun aktif');
    final initial = email.isEmpty ? 'A' : email.characters.first.toUpperCase();

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
            AppSurface(
              color: AppTheme.primaryGreenDark,
              borderColor: AppTheme.primaryGreenDark,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentGold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppTheme.primaryGreenDark,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.textOnPrimary.withValues(
                              alpha: 0.12,
                            ),
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
                  Image.asset('assets/icon.png', width: 42, height: 42),
                ],
              ),
            ),
            AppSectionTitle(title: lang.getText('PREFERENCES', 'PILIHAN')),
            AppSettingsGroup(
              children: [
                AppSettingsRow(
                  icon: CupertinoIcons.globe,
                  title: lang.getText('Language', 'Bahasa'),
                  subtitle: lang.isEnglish ? 'English' : 'Bahasa Melayu',
                  trailing: CupertinoSwitch(
                    value: lang.isEnglish,
                    activeTrackColor: AppTheme.primaryGreen,
                    onChanged: (_) => lang.toggleLanguage(),
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
                    CupertinoPageRoute<void>(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            if (isSuperAdmin) ...[
              AppSectionTitle(
                title: lang.getText('ADMINISTRATION', 'PENTADBIRAN'),
              ),
              AppSettingsGroup(
                children: [
                  AppSettingsRow(
                    icon: CupertinoIcons.shield_lefthalf_fill,
                    iconColor: AppTheme.info,
                    title: lang.getText(
                      'Super Admin portal',
                      'Portal Super Admin',
                    ),
                    subtitle: lang.getText(
                      'Manage mosques and administrators',
                      'Urus masjid dan pentadbir',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute<void>(
                        builder: (_) => const SuperAdminScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

  String _roleLabel(String role, LanguageProvider lang) {
    return switch (role) {
      'super_admin' => lang.getText('SUPER ADMIN', 'SUPER ADMIN'),
      'admin' => lang.getText('MOSQUE ADMIN', 'ADMIN MASJID'),
      _ => lang.getText('COMMUNITY MEMBER', 'AHLI KOMUNITI'),
    };
  }

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
