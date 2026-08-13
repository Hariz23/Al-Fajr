import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'notification_service.dart';
import 'prayer_times_repository.dart';
import 'theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late Future<bool> _permissionFuture;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  void _refreshPermission() {
    _permissionFuture = NotificationService().checkAlarmPermission();
  }

  Future<void> _togglePrayer(
    LanguageProvider lang,
    String prayer,
    bool enabled,
  ) async {
    if (enabled) {
      final permissionGranted = await NotificationService()
          .requestRequiredPermissions();
      if (!permissionGranted) {
        if (!mounted) return;
        setState(_refreshPermission);
        showAppMessage(
          context,
          lang.getText(
            'Notification permission is required to enable this alert.',
            'Kebenaran notifikasi diperlukan untuk mengaktifkan amaran ini.',
          ),
          isError: true,
        );
        return;
      }
    }
    await lang.togglePrayerNotification(prayer);
    try {
      if (!enabled) {
        await NotificationService().cancelPrayer(_prayerId(prayer));
      } else {
        final timings = await PrayerTimesRepository.fetchKualaLumpur();
        await NotificationService().scheduleAllPrayers(timings);
      }
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'The preference was saved, but the schedule could not be refreshed. It will retry next time the app opens.',
          'Pilihan disimpan, tetapi jadual tidak dapat dikemas kini. Ia akan dicuba semula apabila aplikasi dibuka.',
        ),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final settings = lang.prayerNotifications;

    return AppPage(
      title: lang.getText('Azan alerts', 'Amaran azan'),
      subtitle: lang.getText(
        'Kuala Lumpur prayer schedule',
        'Jadual waktu solat Kuala Lumpur',
      ),
      showBackButton: true,
      child: Column(
        children: [
          FutureBuilder<bool>(
            future: _permissionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppSurface(
                  child: Row(
                    children: [
                      CupertinoActivityIndicator(),
                      SizedBox(width: 14),
                      Text('Checking system permission…'),
                    ],
                  ),
                );
              }
              final granted = snapshot.data ?? false;
              return AppSurface(
                color: granted ? AppTheme.mint : AppTheme.warmCream,
                borderColor: granted ? AppTheme.mintStrong : AppTheme.paleGold,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: granted
                            ? AppTheme.primaryGreen
                            : AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        granted
                            ? CupertinoIcons.check_mark
                            : CupertinoIcons.exclamationmark,
                        color: AppTheme.textOnPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            granted
                                ? lang.getText('System ready', 'Sistem sedia')
                                : lang.getText(
                                    'Permission required',
                                    'Kebenaran diperlukan',
                                  ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            granted
                                ? lang.getText(
                                    'Prayer alerts can be scheduled.',
                                    'Amaran solat boleh dijadualkan.',
                                  )
                                : lang.getText(
                                    'Allow precise alarms for timely alerts.',
                                    'Benarkan penggera tepat untuk amaran tepat waktu.',
                                  ),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!granted)
                      TextButton(
                        onPressed: () async {
                          await NotificationService()
                              .requestRequiredPermissions();
                          if (!mounted) return;
                          setState(_refreshPermission);
                        },
                        child: Text(lang.getText('Allow', 'Benarkan')),
                      ),
                  ],
                ),
              );
            },
          ),
          AppSectionTitle(title: lang.getText('PRAYER ALERTS', 'AMARAN SOLAT')),
          AppSettingsGroup(
            children: [
              for (final prayer in settings.keys)
                AppSettingsRow(
                  icon: _prayerIcon(prayer),
                  title: _prayerName(prayer, lang),
                  subtitle: lang.getText(
                    'Play an alert at prayer time',
                    'Mainkan amaran pada waktu solat',
                  ),
                  trailing: CupertinoSwitch(
                    value: settings[prayer]!,
                    activeTrackColor: AppTheme.primaryGreen,
                    onChanged: (value) => _togglePrayer(lang, prayer, value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            lang.getText(
              'Alert delivery can be affected by Focus modes, silent settings and battery restrictions.',
              'Penghantaran amaran boleh dipengaruhi oleh mod Fokus, tetapan senyap dan sekatan bateri.',
            ),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (kDebugMode) ...[
            AppSectionTitle(title: lang.getText('DEVELOPER', 'PEMBANGUN')),
            AppSettingsGroup(
              children: [
                AppSettingsRow(
                  icon: CupertinoIcons.timer,
                  iconColor: AppTheme.warning,
                  title: 'Schedule manual test',
                  onTap: () => _scheduleTest(lang),
                ),
                AppSettingsRow(
                  icon: CupertinoIcons.list_bullet,
                  iconColor: AppTheme.info,
                  title: 'Print pending queue',
                  onTap: () async {
                    await NotificationService().checkPending();
                    if (!context.mounted) return;
                    showAppMessage(
                      context,
                      'Queue printed to the debug console.',
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scheduleTest(LanguageProvider lang) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Manual azan test',
    );
    if (picked == null) return;
    await NotificationService().scheduleDebug(id: 88, pickedTime: picked);
    if (!mounted) return;
    showAppMessage(
      context,
      lang.getText('Test alert scheduled.', 'Amaran ujian dijadualkan.'),
    );
  }

  int _prayerId(String prayer) => switch (prayer) {
    'Fajr' => 0,
    'Dhuhr' => 1,
    'Asr' => 2,
    'Maghrib' => 3,
    'Isha' => 4,
    _ => 99,
  };

  IconData _prayerIcon(String prayer) => switch (prayer) {
    'Fajr' => CupertinoIcons.cloud_moon_fill,
    'Dhuhr' => CupertinoIcons.sun_max_fill,
    'Asr' => CupertinoIcons.cloud_sun_fill,
    'Maghrib' => CupertinoIcons.sunset_fill,
    _ => CupertinoIcons.moon_stars_fill,
  };

  String _prayerName(String prayer, LanguageProvider lang) {
    if (lang.isEnglish) return prayer;
    return const {
          'Fajr': 'Subuh',
          'Dhuhr': 'Zohor',
          'Asr': 'Asar',
          'Maghrib': 'Maghrib',
          'Isha': 'Isyak',
        }[prayer] ??
        prayer;
  }
}
