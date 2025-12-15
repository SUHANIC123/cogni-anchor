import 'dart:io';
import 'package:flutter/foundation.dart'; // Needed for kReleaseMode, which is a common way to handle prod builds

class BaseHttpService {
  // --- CONFIGURATION ---
  
  // 1. Toggle this flag for testing/deployment.
  // Set to true to use the _ngrokUrl below.
  // Note: For a real app, you would use Flutter's built-in kReleaseMode for this:
  // static const bool isProd = kReleaseMode;
  // For simplicity in development, we define a manual toggle here:
  static const bool isProd = true; 
  
  // 2. Local Port and API Path
  static const String _localPort = '8001';
  static const String _apiPath = '/api/v1';

  // 3. Production URL (Replace this with your actual ngrok URL when deploying)
  static const String _ngrokUrl = 'https://79bfcb8a41fe.ngrok-free.app';
  
  // --- BASE URL RESOLVER ---
  
  static String get baseUrl {
    // 1. PRODUCTION CHECK
    if (isProd) {
      return '$_ngrokUrl$_apiPath';
    }

    // 2. DEVELOPMENT MODE (Localhost/Emulator)
    
    // iOS Simulator (on Mac Host) / Mac Desktop App
    // 127.0.0.1 works reliably for iOS/macOS to access the host.
    if (Platform.isIOS || Platform.isMacOS) {
      return 'http://127.0.0.1:$_localPort$_apiPath';
    } 
    // Android Emulator (on Mac Host)
    // 10.0.2.2 is the required alias for the Android emulator to connect to the host loopback adapter.
    else if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_localPort$_apiPath';
    } 
    // Fallback (e.g., Web/Desktop)
    else {
      return 'http://localhost:$_localPort$_apiPath';
    }
  }
}