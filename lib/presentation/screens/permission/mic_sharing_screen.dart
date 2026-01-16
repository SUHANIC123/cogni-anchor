import 'dart:async';
import 'dart:typed_data';
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sound_stream/sound_stream.dart';

class MicSharingScreen extends StatefulWidget {
  const MicSharingScreen({super.key});

  @override
  State<MicSharingScreen> createState() => _MicSharingScreenState();
}

class _MicSharingScreenState extends State<MicSharingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  WebSocketChannel? _channel;
  final PlayerStream _player = PlayerStream();
  
  bool _isConnected = false;
  bool _isReceivingAudio = false;
  String _statusText = "Connecting...";

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initAudioStream();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _initAudioStream() async {
    final pairId = PairContext.pairId;
    if (pairId == null) {
      if (mounted) setState(() => _statusText = "Error: No Pair ID");
      return;
    }

    try {
      await _player.initialize();

      String baseUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final url = '$baseUrl/api/v1/audio/ws/audio/$pairId/caretaker';

      debugPrint("Connecting to Audio WS: $url");
      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      if (mounted) {
        setState(() {
          _isConnected = true;
          _statusText = "Requesting Audio...";
        });
      }

      _sendCommandWithRetry("START_MIC");

      _channel!.stream.listen((data) {
        // FIX: Handle both Audio (List<int>) and Errors (String)
        if (data is List<int>) {
          if (!_isReceivingAudio) {
            if (mounted) {
              setState(() {
                _isReceivingAudio = true;
                _statusText = "Listening to Patient...";
              });
            }
          }
          _player.writeChunk(Uint8List.fromList(data));
        } else if (data is String) {
          debugPrint("Received Text: $data");
          if (data.contains("ERROR")) {
             if (mounted) {
               setState(() {
                 _statusText = "Patient Device Error: Mic Failed";
                 _isReceivingAudio = false;
                 _isConnected = false;
               });
             }
          }
        }
      }, onError: (e) {
        if (mounted) setState(() => _statusText = "Connection Error");
        debugPrint("Audio Error: $e");
      }, onDone: () {
        if (mounted) setState(() => _statusText = "Connection Closed");
      });

      await _player.start();
    } catch (e) {
      if (mounted) setState(() => _statusText = "Failed to connect");
      debugPrint("Connection failed: $e");
    }
  }

  Future<void> _sendCommandWithRetry(String cmd) async {
    for (int i = 0; i < 3; i++) {
      if (_channel != null) {
        try {
          _channel!.sink.add(cmd);
        } catch (_) {}
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _channel?.sink.add("STOP_MIC");
    _channel?.sink.close();
    _player.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = (_isConnected && _isReceivingAudio) 
        ? const Color(0xFFFF653A) 
        : (_statusText.contains("Error") || _statusText.contains("Failed")) 
            ? Colors.red 
            : Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFFF653A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Live Audio Monitor",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) {
                return Transform.scale(
                  scale: (_isConnected && _isReceivingAudio) ? _pulse.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                    child: Icon(
                      (_statusText.contains("Error")) ? Icons.error_outline : Icons.mic,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            if (_isConnected && !_isReceivingAudio && !_statusText.contains("Error"))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Waiting for patient device...",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Stop Listening",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}