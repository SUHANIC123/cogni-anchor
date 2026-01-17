import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';
import 'package:cogni_anchor/data/location/location_sharing_service.dart';
import 'package:cogni_anchor/data/location/mic_sharing_service.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  static final BackgroundService instance = BackgroundService._();
  BackgroundService._();

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_channel',
      'Live Tracking',
      description: 'Sharing live location and audio',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_channel',
        initialNotificationTitle: 'CogniAnchor',
        initialNotificationContent: 'Service active',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [
          AndroidForegroundType.location,
          AndroidForegroundType.microphone,
        ],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  // --- UI Helpers to toggle preferences ---

  Future<void> setLocationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_location_enabled', enabled);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) service.invoke("update_config");
  }

  Future<void> setMicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_mic_enabled', enabled);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) service.invoke("update_config");
  }

  Future<void> start() async {
    final service = FlutterBackgroundService();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (PairContext.pairId != null) {
      await prefs.setString('bg_pair_id', PairContext.pairId!);
    }
    await prefs.setString('bg_api_url', ApiConfig.baseUrl);

    await service.startService();
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}

// -----------------------------------------------------------------------------
//  BACKGROUND ISOLATE
// -----------------------------------------------------------------------------

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 1. Initial Config Load
  final prefs = await SharedPreferences.getInstance();
  final pairId = prefs.getString('bg_pair_id');
  String baseUrl = prefs.getString('bg_api_url') ?? "https://cogni-anchor.olildu.dpdns.org";
  String wsBaseUrl = baseUrl.replaceFirst('http', 'ws');

  final userIdStr = prefs.getString('user_session');
  String userId = "unknown";
  if (userIdStr != null) {
    try {
      userId = jsonDecode(userIdStr)['id'];
    } catch (_) {}
  }

  if (pairId == null) {
    service.stopSelf();
    return;
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // 2. State Management Function
  void updateServices() async {
    // Reload prefs to get latest toggle state
    await prefs.reload();
    final isLocEnabled = prefs.getBool('bg_location_enabled') ?? false;
    final isMicEnabled = prefs.getBool('bg_mic_enabled') ?? false;

    // --- Manage Location ---
    if (isLocEnabled) {
      LocationSharingService.instance.startStreaming(pairId: pairId, userId: userId, baseUrl: wsBaseUrl);
    } else {
      LocationSharingService.instance.stopStreaming();
    }

    // Manage Mic
    if (isMicEnabled) {
      MicSharingService.instance.startListeningForCommands(pairId: pairId, baseUrl: wsBaseUrl, service: service);
    } else {
      MicSharingService.instance.dispose();
    }
  }

  // 3. Initial Run
  updateServices();

  service.on("update_config").listen((event) {
    updateServices();
  });
}
