import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';

class LocationSharingService {
  static final LocationSharingService instance = LocationSharingService._();
  LocationSharingService._();

  IOWebSocketChannel? _channel;
  StreamSubscription<Position>? _positionSub;

  void startStreaming({
    required String pairId,
    required String userId,
    required String baseUrl,
  }) {
    if (_positionSub != null) return; 

    print("📍 Starting Location Stream...");
    final wsUrl = '$baseUrl/ws/location/$pairId/patient';

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

      _positionSub = Geolocator.getPositionStream(
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
        
        try {
          _channel?.sink.add(data);
        } catch (e) {
          print("Error sending location: $e");
        }
      });
    } catch (e) {
      print("Location Setup Error: $e");
      stopStreaming();
    }
  }

  void stopStreaming() {
    if (_positionSub != null) {
      _positionSub?.cancel();
      _positionSub = null;
    }
    if (_channel != null) {
      _channel?.sink.close();
      _channel = null;
    }
  }
}