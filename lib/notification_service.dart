import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier)); 
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings, 
      iOS: DarwinInitializationSettings()
    );
    
    await _notificationsPlugin.initialize(
      settings: initSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      try { 
        await android.requestExactAlarmsPermission(); 
      } catch (_) {}
    }
  }

  // --- THE FIXED ROOT CAUSE: SCHEDULE ALL REAL PRAYERS ---
  /// Call this method whenever the app loads fresh data, updates its location,
  /// or when the user toggles a notification switch.
  /// 
  /// Example data format for [prayerTimes]: 
  /// { 'Fajr': '05:45', 'Dhuhr': '13:12', 'Asr': '16:30', 'Maghrib': '19:22', 'Isha': '20:35' }
  Future<void> scheduleAllPrayers(Map<String, String> prayerTimes) async {
    final now = DateTime.now();

    // Map names to matching distinct IDs for the system queue
    final Map<String, int> prayerIds = {
      "Fajr": 0,
      "Dhuhr": 1,
      "Asr": 2,
      "Maghrib": 3,
      "Isha": 4,
    };

    for (var entry in prayerTimes.entries) {
      final String name = entry.key; // e.g. "Maghrib"
      final String timeString = entry.value; // e.g. "19:22"
      
      if (!prayerIds.containsKey(name)) continue;
      final int id = prayerIds[name]!;

      try {
        // Split "19:22" into hours [19] and minutes [22]
        final List<String> parts = timeString.split(':');
        final int hour = int.parse(parts[0]);
        final int minute = int.parse(parts[1]);

        // Construct the full target DateTime object for today
        var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

        // If Maghrib has already passed for today, schedule it for tomorrow's time slot
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        // Pass it to our worker method
        await schedulePrayer(id: id, title: name, time: scheduledTime);
        debugPrint("Successfully scheduled real-time alarm: $name at $timeString (ID: $id)");

      } catch (e) {
        debugPrint("Error parsing or scheduling time for $name ($timeString): $e");
      }
    }
  }

  // --- WORKER LAYER ---
  Future<void> schedulePrayer({required int id, required String title, required DateTime time}) async {
    if (time.isBefore(DateTime.now())) return;

    final isSubuh = title.toLowerCase() == "fajr" || title.toLowerCase() == "subuh" || title.toLowerCase() == "debug test";
    final String soundName = isSubuh ? "subuh" : "azan";
    
    final String channelId = "prayer_ch_$soundName";
    final String channelName = isSubuh ? "Subuh Azan" : "Daily Azan";

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
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // --- UTILITY & DEBUG METHODS ---

  Future<void> scheduleDebug({required int id, required TimeOfDay pickedTime}) async {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    await schedulePrayer(id: id, title: "DEBUG TEST", time: scheduled);
  }

  Future<void> cancelPrayer(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<bool> checkAlarmPermission() async {
    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      final bool? granted = await android.requestExactAlarmsPermission();
      return granted ?? false;
    } catch (_) { 
      return false; 
    }
  }

  Future<void> checkPending() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint("--- PENDING AZANS (${pending.length}) ---");
    for (var p in pending) { 
      debugPrint("ID: ${p.id} | Name: ${p.title}"); 
    }
  }

  Future<void> openAlarmSettings() async {
    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestExactAlarmsPermission();
    }
  }
}