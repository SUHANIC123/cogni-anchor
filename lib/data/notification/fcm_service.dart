import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/notification/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background Message: ${message.messageId}");
  
  if (message.data['type'] == 'new_reminder') {
    await NotificationService().init(requestPermission: false);
    await _scheduleFromData(message.data);
  }
}

Future<void> _scheduleFromData(Map<String, dynamic> data) async {
  try {
    final title = data['title'];
    final dateStr = data['date']; 
    final timeStr = data['time']; 
    final id = int.tryParse(data['id'] ?? '0') ?? 0;

    final format = DateFormat("dd MMM yyyy hh:mm a");
    final dateTime = format.parse("$dateStr $timeStr");

    await NotificationService().scheduleNotification(
      id: id,
      title: "Reminder: $title",
      body: "It's time for $title",
      scheduledTime: dateTime,
    );
    debugPrint("Scheduled reminder from FCM: $title at $dateTime");
  } catch (e) {
    debugPrint("Error scheduling from FCM: $e");
  }
}

class FCMService {
  static final FCMService instance = FCMService._();
  FCMService._();

  Future<void> initialize() async {
    // 1. Request Permission (Only in Foreground)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint("User declined or has not accepted permission");
      return;
    }

    // 2. Get Token & Send to Backend
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      try {
        await ApiService.updateFCMToken(token);
      } catch (e) {
        debugPrint("Failed to sync token: $e");
      }
    }

    // 3. Listen to Token Refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      ApiService.updateFCMToken(newToken);
    });

    // 4. Setup Handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground Message: ${message.data}");
      if (message.data['type'] == 'new_reminder') {
        _scheduleFromData(message.data);
      }
    });
  }
}