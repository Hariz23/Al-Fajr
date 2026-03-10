import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final Map<String, bool> _prayerNotifications = {
    "Fajr": true,
    "Dhuhr": true,
    "Asr": true,
    "Maghrib": true,
    "Isha": true,
  };

  Map<String, bool> get prayerNotifications => _prayerNotifications;

  LanguageProvider() {
    _loadFromDisk();
    _initNotifications(); 
  }

  // --- 1. INITIALIZATION ---
  Future<void> _initNotifications() async {
    // Initialize Timezones for Malaysia/Local
    tz.initializeTimeZones();
    try {
      final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier)); 
    } catch (e) {
      debugPrint("Timezone error: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
        
    // v21 requirement: use named 'settings' parameter
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request permissions for Android 13+ & Exact Alarms
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // --- 2. STORAGE & LANGUAGE ---
  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? true;
    _prayerNotifications.forEach((key, value) {
      _prayerNotifications[key] = prefs.getBool('notify_$key') ?? true;
    });
    notifyListeners();
  }

  void toggleLanguage() async {
    _isEnglish = !_isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', _isEnglish);
    notifyListeners();
  }

  void togglePrayerNotification(String prayerKey) async {
    if (_prayerNotifications.containsKey(prayerKey)) {
      _prayerNotifications[prayerKey] = !_prayerNotifications[prayerKey]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_$prayerKey', _prayerNotifications[prayerKey]!);
      notifyListeners();
    }
  }

  // --- 3. THE SCHEDULER (Fixed for v21) ---
  Future<void> scheduleAllPrayers(Map<String, String> prayerTimes) async {
    await _notificationsPlugin.cancelAll();

    for (var entry in prayerTimes.entries) {
      String prayerName = entry.key;
      if (_prayerNotifications[prayerName] == false) continue;

      try {
        final now = DateTime.now();
        final parts = entry.value.split(':');
        var scheduledDate = DateTime(
          now.year, now.month, now.day, 
          int.parse(parts[0]), int.parse(parts[1])
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        bool isSubuh = (prayerName == "Fajr");
        String channelId = isSubuh ? "subuh_channel" : "standard_azan";
        String soundFile = isSubuh ? "subuh" : "azan";

        // v21: All parameters are now NAMED and uiLocalNotificationDateInterpretation is removed
        await _notificationsPlugin.zonedSchedule(
          id: prayerName.hashCode,
          title: getText("Time for $prayerName", "Waktu Solat $prayerName"),
          body: getText("Hayya 'ala-s-Salah", "Marilah menunaikan solat"),
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              isSubuh ? "Subuh Notifications" : "Standard Azan",
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound(soundFile),
              playSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint("Error scheduling $prayerName: $e");
      }
    }
  }

  // --- 4. INSTANT TRIGGER (For Testing) ---
  void triggerInstantAzan(String prayerName) async {
    bool isSubuh = (prayerName == "Fajr");
    String soundFile = isSubuh ? "subuh" : "azan";

    await _notificationsPlugin.show(
      id: prayerName.hashCode, 
      title: getText("Test: $prayerName", "Ujian: $prayerName"),
      body: getText("Playing $soundFile.mp3", "Memainkan $soundFile.mp3"),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          "test_channel",
          "Test Notification",
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundFile),
          playSound: true,
        ),
      ),
    );
  }

  String getText(String en, String ms) => _isEnglish ? en : ms;
}