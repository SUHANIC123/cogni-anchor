import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/chatbot/chatbot_service.dart';
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';

import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  static const String _nameTag = 'ChatbotPage';

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  WebSocketChannel? _channel;
  bool _isWsConnected = false;

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();

  bool _isRecording = false;
  bool _recorderInitialized = false;
  bool _playerInitialized = false;
  bool _isPlaying = false;

  bool _isRecorderReady = false;
  String? _recordingPath;

  String? _pairId;

  String get patientId => AuthService.instance.currentUser?.id ?? "demo_patient";

  @override
  void initState() {
    super.initState();
    dev.log("Initializing Chatbot Page...", name: _nameTag);
    _initAudio();
    _fetchPairIdAndConnect();
    _messages.add(ChatMessage(
      text: "Hi! I'm your cognitive health companion. How can I help you today?",
      isBot: true,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initAudio() async {
    try {
      await _audioRecorder.openRecorder();
      _recorderInitialized = true;

      await _audioPlayer.openPlayer();
      _playerInitialized = true;

      await _audioPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));

      if (mounted) setState(() {});
      dev.log("Audio initialized successfully", name: _nameTag);
    } catch (e) {
      dev.log("Failed to initialize audio session: $e", name: _nameTag, error: e);
    }
  }

  @override
  void dispose() {
    dev.log("Disposing Chatbot Page", name: _nameTag);
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    if (_recorderInitialized) _audioRecorder.closeRecorder();
    if (_playerInitialized) _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> _fetchPairIdAndConnect() async {
    try {
      dev.log("Fetching Pair ID from Context...", name: _nameTag);

      _pairId = PairContext.pairId;

      if (_pairId != null) {
        dev.log("Found Pair ID: $_pairId", name: _nameTag);
      } else {
        dev.log("No Pair ID found in context (User might be unconnected)", name: _nameTag);
      }

      if (mounted) setState(() {});
      _connectWebSocket();
    } catch (e) {
      dev.log("Error fetching pair ID: $e", name: _nameTag, error: e);
    }
  }

  void _connectWebSocket() {
    if (_pairId == null) {
      dev.log("Cannot connect WS: Pair ID is null", name: _nameTag);
      return;
    }

    String baseUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');

    // FIX: Using /api/v1/agent/... to match backend router prefix for agent.py
    final wsUrl = '$baseUrl/api/v1/agent/ws/$patientId/$_pairId';

    dev.log("Attempting WS Connection to: $wsUrl", name: _nameTag);

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen((message) {
        dev.log("WS Message Received: $message", name: _nameTag);

        final data = jsonDecode(message);
        final response = data['response'];

        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(text: response, isBot: true, timestamp: DateTime.now()));
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }, onError: (e) {
        dev.log("WS Error: $e", name: _nameTag, error: e);
        if (mounted) setState(() => _isWsConnected = false);
      }, onDone: () {
        dev.log("WS Closed", name: _nameTag);
        if (mounted) setState(() => _isWsConnected = false);
      });

      if (mounted) setState(() => _isWsConnected = true);
      dev.log("WS Connected", name: _nameTag);
    } catch (e) {
      dev.log("WS Connect Exception: $e", name: _nameTag, error: e);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    dev.log("Sending message: $message", name: _nameTag);

    if (_isPlaying) await _stopPlayback();

    setState(() {
      _messages.add(ChatMessage(text: message, isBot: false, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    if (_channel != null && _isWsConnected) {
      dev.log("Sending via WebSocket", name: _nameTag);
      final payload = jsonEncode({"message": message});
      _channel!.sink.add(payload);
    } else {
      dev.log("WebSocket not connected, falling back to HTTP", name: _nameTag);
      try {
        final currentPairId = _pairId ?? "demo_pair_001";

        final response = await ChatbotService.sendTextMessage(
          patientId: patientId,
          pairId: currentPairId,
          message: message,
        );

        dev.log("HTTP Response: $response", name: _nameTag);

        setState(() {
          _messages.add(ChatMessage(text: response, isBot: true, timestamp: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      } catch (e) {
        _handleError(e);
      }
    }
  }

  void _handleError(Object e) {
    dev.log("Error processing message: $e", name: _nameTag, error: e);
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I couldn't process that. Please check your connection.",
          isBot: true,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _startRecording() async {
    if (!_recorderInitialized) return;
    if (_isPlaying) await _stopPlayback();

    dev.log("Starting recording...", name: _nameTag);

    setState(() {
      _isRecording = true;
      _isRecorderReady = false;
      _recordingPath = null;
    });

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        dev.log("Microphone permission denied", name: _nameTag);
        setState(() => _isRecording = false);
        return;
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDocDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      setState(() => _recordingPath = filePath);

      await _audioRecorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);
      _isRecorderReady = true;
      dev.log("Recording started at: $filePath", name: _nameTag);
    } catch (e) {
      dev.log("Recording error: $e", name: _nameTag, error: e);
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    dev.log("Stopping recording...", name: _nameTag);
    try {
      for (int i = 0; i < 10; i++) {
        if (_isRecorderReady) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!_isRecorderReady || _recordingPath == null) {
        dev.log("Recorder not ready or path null", name: _nameTag);
        await _audioRecorder.stopRecorder();
        setState(() => _isRecording = false);
        return;
      }

      await _audioRecorder.stopRecorder();
      setState(() => _isRecording = false);

      final file = File(_recordingPath!);
      if (await file.exists()) {
        final int size = await file.length();
        dev.log("Recording file exists, size: $size bytes", name: _nameTag);
        if (size > 500) {
          _sendVoiceMessage(_recordingPath!);
        } else {
          dev.log("Recording too small, discarded", name: _nameTag);
        }
      }
    } catch (e) {
      dev.log("Stop recording error: $e", name: _nameTag, error: e);
      setState(() => _isRecording = false);
    }
  }

  Future<void> _sendVoiceMessage(String audioPath) async {
    dev.log("Sending voice message from: $audioPath", name: _nameTag);
    setState(() {
      _messages.add(ChatMessage(text: " Voice message sent...", isBot: false, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final audioBytes = await File(audioPath).readAsBytes();
      if (audioBytes.isEmpty) throw Exception("Audio file is empty");

      final response = await ChatbotService.sendVoiceMessage(
        patientId: patientId,
        audioBytes: audioBytes,
        filename: 'voice_message.aac',
      );

      dev.log("Voice Response: $response", name: _nameTag);

      final audioUrl = response['audio_url'];

      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          text: " ${response['transcription']}",
          isBot: false,
          timestamp: DateTime.now(),
        );
        _messages.add(ChatMessage(
          text: response['response'] as String,
          isBot: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();

      if (audioUrl != null && _playerInitialized) {
        _playResponseAudio(audioUrl);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _playResponseAudio(String relativeUrl) async {
    try {
      dev.log("Playing audio response from: $relativeUrl", name: _nameTag);
      await _audioPlayer.stopPlayer();
      final fullUrl = "${ApiConfig.baseUrl}$relativeUrl";
      setState(() => _isPlaying = true);
      await _audioPlayer.startPlayer(
        fromURI: fullUrl,
        whenFinished: () {
          dev.log("Audio playback finished", name: _nameTag);
          if (mounted) setState(() => _isPlaying = false);
        },
      );
    } catch (e) {
      dev.log("Audio playback error: $e", name: _nameTag, error: e);
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _stopPlayback() async {
    dev.log("Stopping audio playback", name: _nameTag);
    await _audioPlayer.stopPlayer();
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        title: AppText("AI Companion", fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble();
                }
                return _buildModernBubble(_messages[index]);
              },
            ),
          ),
          if (_isPlaying)
            Container(
              color: AppColors.primaryLight,
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, size: 16.sp, color: AppColors.primary),
                  Gap(8.w),
                  Text("Speaking...", style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
                  Gap(16.w),
                  GestureDetector(
                    onTap: _stopPlayback,
                    child: Icon(Icons.stop_circle_outlined, size: 20.sp, color: Colors.red),
                  )
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildModernBubble(ChatMessage msg) {
    final isMe = !msg.isBot;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: isMe ? 50.w : 0, right: isMe ? 0 : 50.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
            bottomRight: Radius.circular(isMe ? 4.r : 20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.textPrimary,
            fontSize: 15.sp,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
        child: SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Ask me anything...",
                fillColor: AppColors.background,
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Gap(12.w),
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () {
              setState(() => _isRecording = false);
            },
            child: CircleAvatar(
              radius: 24.r,
              backgroundColor: _isRecording ? Colors.redAccent : AppColors.surface,
              child: Icon(Icons.mic, color: _isRecording ? Colors.white : AppColors.primary),
            ),
          ),
          Gap(8.w),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final bool isError;
  ChatMessage({required this.text, required this.isBot, required this.timestamp, this.isError = false});
}
