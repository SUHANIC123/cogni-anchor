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
      setState(() => _statusText = "Error: No Pair ID");
      return;
    }

    try {
      await _player.initialize();

      String baseUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final url = '$baseUrl/ws/audio/$pairId/caretaker';

      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      _sendCommandWithRetry("START_MIC");

      _channel!.stream.listen((data) {
        if (data is List<int>) {
          if (!_isConnected) {
            setState(() {
              _isConnected = true;
              _statusText = "Listening to Patient...";
            });
          }
          _player.writeChunk(Uint8List.fromList(data));
        }
      }, onError: (e) {
        setState(() => _statusText = "Connection Error");
        debugPrint("Audio Error: $e");
      });

      await _player.start();
    } catch (e) {
      setState(() => _statusText = "Failed to connect");
      debugPrint("Connection failed: $e");
    }
  }

  Future<void> _sendCommandWithRetry(String cmd) async {
    for (int i = 0; i < 3; i++) {
      if (_channel != null) {
        _channel!.sink.add(cmd);
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
                  scale: _isConnected ? _pulse.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isConnected ? const Color(0xFFFF653A).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? const Color(0xFFFF653A) : Colors.grey,
                    ),
                    child: const Icon(
                      Icons.mic,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
