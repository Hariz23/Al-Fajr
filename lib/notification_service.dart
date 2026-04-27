import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // FIX 1: Access the .name property of TimezoneInfo
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier)); 
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    
    // FIX 2: Use the 'settings:' named parameter
    await _notificationsPlugin.initialize(
      settings: initSettings, 
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> schedulePrayer(int id, String title, DateTime time) async {
    if (time.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: "Waktunya solat ${title.toLowerCase()}.",
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel', 
          'Prayer Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // FIX 3: Removed UILocalNotificationDateInterpretation (no longer required)
    );
  }

  // FIX 4: Use 'id:' named parameter for cancel
  Future<void> cancelPrayer(int id) async {
    await _notificationsPlugin.cancel(id: id); 
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}