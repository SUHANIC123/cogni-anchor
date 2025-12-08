import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_found_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_not_found_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/main.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';

class RecognitionResult {
  final bool matchFound;
  RecognitionResult({required this.matchFound});

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(matchFound: json['match_found'] as bool);
  }
}

class FRScanPage extends StatefulWidget {
  const FRScanPage({super.key});

  @override
  State<FRScanPage> createState() => _FRScanPageState();
}

class _FRScanPageState extends State<FRScanPage> {
  static const String _baseUrl = 'https://eaa9e7cf9c64.ngrok-free.app/api/v1/faces/recognize';

  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _scanFace();
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()));
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<List<int>> _getCaptureImageBytes() async {
    if (!_isCameraInitialized) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isCameraInitialized) throw Exception("Camera not initialized.");
    }

    try {
      final xFile = await _cameraController.takePicture();
      final file = File(xFile.path);
      return await file.readAsBytes();
    } catch (e) {
      debugPrint("Error taking picture: $e");
      rethrow;
    }
  }

  Future<void> _scanFace() async {
    setState(() => _isScanning = true);

    List<int> imageBytes;
    try {
      imageBytes = await _getCaptureImageBytes();
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()));
      }
      return;
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'scan_image.jpg'));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = RecognitionResult.fromJson(jsonResponse);

        if (mounted) {
          if (result.matchFound) {
            // NEW: Parse all five fields from API response
            final recognizedPerson = RecognizedPerson(
              name: jsonResponse['person_name'] ?? 'Unknown',
              relationship: jsonResponse['relationship'] ?? 'N/A',
              occupation: jsonResponse['occupation'] ?? 'N/A', // NEW
              age: jsonResponse['age'] ?? 'N/A',             // NEW
              notes: jsonResponse['notes'] ?? 'None provided', // NEW
            );
            
            // Navigate and pass data
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FRResultFoundPage(person: recognizedPerson)));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()));
          }
        }
      } else {
        debugPrint("API Error: ${response.statusCode}, Body: ${response.body}");
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()));
        }
      }
    } catch (e) {
      debugPrint("Network/Other Error: $e");
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()));
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(_cameraController)),
          ),

          Positioned(
            top: 60.h,
            left: 0,
            right: 0,
            child: Center(
              child: AppText("Trouble remembering a person?", color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280.w,
                  height: 350.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.appColor, width: 3),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                Gap(20.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                  child: Column(
                    children: [
                      Icon(Icons.camera, color: colors.appColor),
                      Gap(5.h),
                      _isScanning ? AppText("Scanning face...", fontSize: 12.sp, color: colors.appColor) : AppText("Ready to scan", fontSize: 12.sp, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40.h,
            left: 20.w,
            right: 20.w,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_circleBtn(Icons.flashlight_on_outlined), _circleBtn(Icons.image_outlined)]),
          ),

          Positioned(
            top: 50.h,
            left: 20.w,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white),
    );
  }
}