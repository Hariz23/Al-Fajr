import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    // Reverted to your exact working timezone call
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    // Reverted to your exact setup using the named 'settings' parameter
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );
    _initialized = true;
  }

  // --- PREFERENCES LAYER ---
  /// Checks if the user has turned the prayer on/off. Defaults to true.
  Future<bool> _isPrayerEnabled(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notify_$prayerName') ?? true;
  }

  // --- THE FIXED ROOT CAUSE: SCHEDULE ALL REAL PRAYERS ---
  Future<void> scheduleAllPrayers(Map<String, String> prayerTimes) async {
    final now = DateTime.now();

    final Map<String, int> prayerIds = {
      "Fajr": 0,
      "Dhuhr": 1,
      "Asr": 2,
      "Maghrib": 3,
      "Isha": 4,
    };

    // Buffer: Loop through Today (0) and Tomorrow (1)
    for (int dayOffset = 0; dayOffset < 2; dayOffset++) {
      for (var entry in prayerTimes.entries) {
        final String name = entry.key;
        final String timeString = entry.value;

        if (!prayerIds.containsKey(name)) continue;

        // Skip scheduling if the user toggled this prayer off
        if (!await _isPrayerEnabled(name)) continue;

        try {
          final List<String> parts = timeString.split(':');
          final int hour = int.parse(parts[0]);
          final int minute = int.parse(parts[1]);

          // Calculate date for today or tomorrow based on dayOffset
          final targetDate = now.add(Duration(days: dayOffset));
          var scheduledTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            hour,
            minute,
          );

          if (scheduledTime.isAfter(now)) {
            // Unique IDs: Today (0-4), Tomorrow (10-14)
            final int uniqueId = prayerIds[name]! + (dayOffset * 10);

            await schedulePrayer(
              id: uniqueId,
              title: name,
              time: scheduledTime,
            );
            debugPrint(
              "Successfully scheduled: $name at ${scheduledTime.toString()} (ID: $uniqueId)",
            );
          }
        } catch (e) {
          debugPrint("Error scheduling $name: $e");
        }
      }
    }
  }

  // --- WORKER LAYER ---
  Future<void> schedulePrayer({
    required int id,
    required String title,
    required DateTime time,
  }) async {
    if (time.isBefore(DateTime.now())) return;

    final isSubuh =
        title.toLowerCase() == "fajr" ||
        title.toLowerCase() == "subuh" ||
        title.toLowerCase() == "debug test";
    final String soundName = isSubuh ? "subuh" : "azan";

    final String channelId = "prayer_ch_$soundName";
    final String channelName = isSubuh ? "Subuh Azan" : "Daily Azan";

    // Reverted perfectly back to your original named parameters logic
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: "Waktunya solat ${title.toLowerCase()}.",
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound(soundName),
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // --- UTILITY & DEBUG METHODS ---
  Future<void> scheduleDebug({
    required int id,
    required TimeOfDay pickedTime,
  }) async {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await schedulePrayer(id: id, title: "DEBUG TEST", time: scheduled);
  }

  Future<void> cancelPrayer(int id) async {
    await _notificationsPlugin.cancel(id: id);
    await _notificationsPlugin.cancel(id: id + 10);
  }

  Future<bool> checkAlarmPermission() async {
    final notificationsAllowed = await checkNotificationPermission();
    if (!notificationsAllowed) return false;
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    try {
      final bool? granted = await android.canScheduleExactNotifications();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkNotificationPermission() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return true;
  }

  Future<bool> requestRequiredPermissions() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final notificationsAllowed =
          await android.requestNotificationsPermission() ?? false;
      if (!notificationsAllowed) return false;
      try {
        return await android.requestExactAlarmsPermission() ?? false;
      } catch (_) {
        return false;
      }
    }
    final ios = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> checkPending() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint("--- PENDING AZANS (${pending.length}) ---");
    for (var p in pending) {
      debugPrint("ID: ${p.id} | Name: ${p.title}");
    }
  }

  Future<void> openAlarmSettings() async {
    await requestRequiredPermissions();
  }
}
