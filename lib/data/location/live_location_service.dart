import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:developer' as dev;
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_stream/sound_stream.dart';

class LiveLocationService {
  static const String _logTag = 'LiveLocationService';
  static final LiveLocationService instance = LiveLocationService._();
  LiveLocationService._();

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
    dev.log("Service initialized", name: _logTag);
  }

  Future<void> start() async {
    final service = FlutterBackgroundService();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        dev.log("Location permission denied by user", name: _logTag);
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (PairContext.pairId != null) {
      await prefs.setString('bg_pair_id', PairContext.pairId!);
    }
    await prefs.setString('bg_api_url', ApiConfig.baseUrl);

    await service.startService();
    dev.log("Background service start requested", name: _logTag);
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    dev.log("Background service stop requested", name: _logTag);
  }
}

// -----------------------------------------------------------------------------
//  BACKGROUND ISOLATE
// -----------------------------------------------------------------------------

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  const String bgTag = 'BackgroundIsolate';
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    dev.log("Stop service signal received", name: bgTag);
    service.stopSelf();
  });

  final prefs = await SharedPreferences.getInstance();
  final pairId = prefs.getString('bg_pair_id');
  String baseUrl = prefs.getString('bg_api_url') ?? "https://cogni-anchor.olildu.dpdns.org";

  String wsBaseUrl = baseUrl.replaceFirst('http', 'ws');

  final userIdStr = prefs.getString('user_session');
  String? userId;
  if (userIdStr != null) {
    try {
      userId = jsonDecode(userIdStr)['id'];
    } catch (e) {
      dev.log("Error decoding user session", name: bgTag, error: e);
    }
  }

  if (pairId == null) {
    dev.log("Missing pairId, stopping service", name: bgTag);
    service.stopSelf();
    return;
  }

  // --- 1. LOCATION SETUP ---
  final locUrl = '$wsBaseUrl/ws/location/$pairId/patient';
  IOWebSocketChannel? locChannel;

  try {
    locChannel = IOWebSocketChannel.connect(Uri.parse(locUrl));
    dev.log("Location WebSocket connected", name: bgTag);

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final data = jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'user_id': userId,
      });
      if (locChannel != null) {
        try {
          locChannel.sink.add(data);
        } catch (e) {
          dev.log("Location socket send error", name: bgTag, error: e);
        }
      }
    });
  } catch (e) {
    dev.log("Location setup error", name: bgTag, error: e);
  }

  // --- 2. AUDIO SETUP ---
  final audioUrl = '$wsBaseUrl/ws/audio/$pairId/patient';
  IOWebSocketChannel? audioChannel;
  final RecorderStream recorder = RecorderStream();
  StreamSubscription<List<int>>? audioSub;
  bool isMicActive = false;
  bool isAudioInitialized = false;

  try {
    audioChannel = IOWebSocketChannel.connect(Uri.parse(audioUrl));
    dev.log("Audio WebSocket connected", name: bgTag);

    audioChannel.stream.listen((message) async {
      if (message == "START_MIC") {
        dev.log("Caretaker requested Mic. Initializing audio stream", name: bgTag);

        if (!isAudioInitialized) {
          try {
            await recorder.initialize();
            isAudioInitialized = true;
          } catch (e) {
            dev.log("Audio recorder initialization failed", name: bgTag, error: e);
            return;
          }
        }

        if (isAudioInitialized && !isMicActive) {
          isMicActive = true;

          try {
            audioSub = recorder.audioStream.listen((data) {
              if (audioChannel != null && isMicActive) {
                audioChannel.sink.add(data);
              }
            });

            await recorder.start();

            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: "CogniAnchor",
                content: "Microphone Active (Caretaker Listening)",
              );
            }
          } catch (e) {
            dev.log("Error starting audio recorder", name: bgTag, error: e);
            isMicActive = false;
          }
        }
      } else if (message == "STOP_MIC") {
        dev.log("Stopping Mic Streaming", name: bgTag);
        isMicActive = false;
        try {
          await recorder.stop();
        } catch (e) {
          dev.log("Error stopping recorder", name: bgTag, error: e);
        }
        await audioSub?.cancel();

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "CogniAnchor",
            content: "Service active",
          );
        }
      }
    });
  } catch (e) {
    dev.log("Audio WebSocket connection error", name: bgTag, error: e);
  }
}
