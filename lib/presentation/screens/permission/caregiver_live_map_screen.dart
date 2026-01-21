import 'dart:convert';
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CaregiverLiveMapScreen extends StatefulWidget {
  const CaregiverLiveMapScreen({super.key});

  @override
  State<CaregiverLiveMapScreen> createState() => _CaregiverLiveMapScreenState();
}

class _CaregiverLiveMapScreenState extends State<CaregiverLiveMapScreen> {
  WebSocketChannel? _channel;
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  bool _isConnected = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _connectToLiveStream();
  }

  void _connectToLiveStream() {
    final pairId = PairContext.pairId;
    if (pairId == null) return;

    String baseUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');

    final url = '$baseUrl/api/v1/location/ws/location/$pairId/caretaker';

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;

        if (lat != null && lng != null) {
          final newLocation = LatLng(lat, lng);

          if (mounted) {
            setState(() {
              _currentLocation = newLocation;
              _isConnected = true;
            });

            if (_isMapReady) {
              _mapController.move(newLocation, 16);
            }
          }
        }
      }, onError: (error) {
        debugPrint("WS Error: $error");
        if (mounted) setState(() => _isConnected = false);
      }, onDone: () {
        debugPrint("WS Closed");
        if (mounted) setState(() => _isConnected = false);
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Live Patient Location"),
            const SizedBox(width: 10),
            if (_isConnected) const Icon(Icons.circle, color: Colors.green, size: 12) else const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFFFF653A),
      ),
      body: _currentLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Waiting for patient location signal..."),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
                onMapReady: () {
                  _isMapReady = true;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.cogni_anchor',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60,
                      height: 60,
                      point: _currentLocation!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Color(0xFFFF653A),
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
