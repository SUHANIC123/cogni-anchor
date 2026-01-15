import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class MicSharingService {
  static final MicSharingService instance = MicSharingService._();
  MicSharingService._();

  IOWebSocketChannel? _channel;
  final RecorderStream _recorder = RecorderStream();
  StreamSubscription<List<int>>? _audioSub;
  
  bool _isAudioInitialized = false;
  bool _isMicActive = false;

  void startListeningForCommands({
    required String pairId,
    required String baseUrl,
    required ServiceInstance service,
  }) {
    if (_channel != null && _channel!.closeCode == null) return;

    print("🎙️ Audio Service Standing By...");
    final wsUrl = '$baseUrl/ws/audio/$pairId/patient';

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen((message) async {
        if (message == "START_MIC") {
          await _startMicStreaming(service);
        } else if (message == "STOP_MIC") {
          await _stopMicStreaming(service);
        }
      }, onError: (e) {
        print("Audio WS Error: $e");
      });
    } catch (e) {
      print("Audio Connection Error: $e");
    }
  }

  Future<void> _startMicStreaming(ServiceInstance service) async {
    if (_isMicActive) return;
    print("🎙️ Caretaker requested Mic. Starting...");

    if (!_isAudioInitialized) {
      try {
        await _recorder.initialize();
        _isAudioInitialized = true;
      } catch (e) {
        print("❌ Audio Init Failed: $e");
        return;
      }
    }

    try {
      _isMicActive = true;
      
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "CogniAnchor",
          content: "Microphone Active (Caretaker Listening)",
        );
      }

      // Start Stream
      _audioSub = _recorder.audioStream.listen((data) {
        if (_channel != null && _isMicActive) {
          _channel!.sink.add(data);
        }
      });
      
      await _recorder.start();
    } catch (e) {
      print("Error starting recorder: $e");
      _isMicActive = false;
    }
  }

  Future<void> _stopMicStreaming(ServiceInstance service) async {
    if (!_isMicActive) return;
    print("🎙️ Stopping Mic Streaming...");
    
    _isMicActive = false;
    try {
      await _recorder.stop();
    } catch (_) {}
    await _audioSub?.cancel();

    // Reset Notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "CogniAnchor",
        content: "Service active",
      );
    }
  }

  /// Completely kills the service (e.g. when permission revoked)
  void dispose() {
    _isMicActive = false;
    _audioSub?.cancel();
    _recorder.stop(); // Safe to call even if stopped
    _channel?.sink.close();
    _channel = null;
    print("🛑 Audio Service Disposed");
  }
}