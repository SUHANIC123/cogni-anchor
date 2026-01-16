import 'dart:async';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/notification/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background Message: ${message.messageId}");

  if (message.data['type'] == 'new_reminder') {
    await NotificationService().init(requestPermission: false);
    await _scheduleFromData(message.data);
  } else if (message.data['type'] == 'status_update') {
    await _handleStatusUpdate(message.data);
  }
}

Future<void> _handleStatusUpdate(Map<String, dynamic> data) async {
  debugPrint("Received Status Update in Background: $data");

  try {
    final prefs = await SharedPreferences.getInstance();

    // 1. Update Local Preferences so the service knows what to do when it starts
    if (data.containsKey('location_enabled')) {
      await prefs.setBool('bg_location_enabled', data['location_enabled'] == 'true');
    }
    if (data.containsKey('mic_enabled')) {
      await prefs.setBool('bg_mic_enabled', data['mic_enabled'] == 'true');
    }

    // 2. Wake Up / Start the Background Service
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (isRunning) {
      debugPrint("Service already running, updating config...");
      service.invoke("update_config");
    } else {
      debugPrint("Service killed. Waking up...");
      await service.startService();
    }
  } catch (e) {
    debugPrint("Error handling background status update: $e");
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

  // Stream to notify UI of status updates
  final _statusUpdateController = StreamController<void>.broadcast();
  Stream<void> get onStatusUpdate => _statusUpdateController.stream;

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
      } else if (message.data['type'] == 'status_update') {
        _handleStatusUpdate(message.data);
        // Notify UI subscribers that status has changed
        _statusUpdateController.add(null);
      }
    });
  }
}
