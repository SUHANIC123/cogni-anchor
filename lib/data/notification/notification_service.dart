import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminder_channel_v4';
  static const String _channelName = 'Reminders';
  static const String _channelDesc = 'High priority reminders';

  Future<void> init({bool requestPermission = true}) async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint(" Notification Clicked: ${details.payload}");
      },
    );

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    // Only request permissions if explicitly asked (Foreground only)
    if (requestPermission) {
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        try {
          await androidImplementation.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint("️ Exact alarms permission request failed: $e");
        }
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentBanner: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    if (scheduledTime.isBefore(now.add(const Duration(seconds: 5)))) {
      debugPrint(" Showing immediate notification for: $title");
      await _plugin.show(id, title, body, notificationDetails);
      return;
    }

    debugPrint(" Scheduling notification for: $scheduledTime");
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
