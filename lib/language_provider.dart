import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  // 1. Setup the plugin instance
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

  // 2. Initialize using strict named parameters (v21.0.0+ style)
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
        
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap logic here
      },
    );

    // Request permissions for Android 13+ (Required for Azan to work)
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
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

  // 3. THE MAIN TRIGGER (Fixed for separate sounds/channels)
  void triggerPrayerAzan(String prayerName) async {
    // Check if notifications are enabled for this specific prayer
    if (_prayerNotifications[prayerName] == false) return;

    bool isSubuh = (prayerName == "Fajr");
    
    // We use TWO different Channel IDs because Android locks 1 sound per channel
    String channelId = isSubuh ? "subuh_channel_v1" : "standard_azan_channel_v1";
    String channelName = isSubuh ? "Subuh Notifications" : "Standard Azan Notifications";
    String soundFile = isSubuh ? "subuh" : "azan";

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId, 
      channelName,
      channelDescription: 'Azan alerts for $prayerName',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundFile), 
      playSound: true,
      enableVibration: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: prayerName.hashCode, 
      title: getText("Time for $prayerName", "Waktu Solat $prayerName"),
      body: getText("Hayya 'ala-s-Salah", "Marilah menunaikan solat"),
      notificationDetails: platformChannelSpecifics,
    );
  }

  String getText(String en, String ms) => _isEnglish ? en : ms;
}