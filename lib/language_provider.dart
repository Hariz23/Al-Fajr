import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  // 1. Setup the plugin instance
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final Map<String, bool> _prayerNotifications = {
    "Fajr": true, "Dhuhr": true, "Asr": true, "Maghrib": true, "Isha": true,
  };

  Map<String, bool> get prayerNotifications => _prayerNotifications;

  LanguageProvider() {
    _loadFromDisk();
    _initNotifications(); 
  }

  // 2. Initialize using the NEW strict named parameters
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
        
    await _notificationsPlugin.initialize(
      settings: initializationSettings, // Required named parameter
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Optional: handle notification tap
      },
    );

    // Request permissions for Android 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

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

  // 3. THE DEBUG METHOD (Fully updated for v21 naming)
  void showTestAzanNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'azan_channel_v5', // Use a new ID to force a settings refresh
      'Adhan Notifications',
      channelDescription: 'Prayer time alerts with Azan sound',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('azan'), 
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    // ALL arguments MUST have names in v21+
    await _notificationsPlugin.show(
      id: 99, 
      title: getText("Test Azan", "Ujian Azan"),
      body: getText("Checking sound: azan.mp3", "Menguji bunyi: azan.mp3"),
      notificationDetails: platformChannelSpecifics,
    );
  }

  String getText(String en, String ms) => _isEnglish ? en : ms;
}