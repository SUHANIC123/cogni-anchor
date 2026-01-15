import 'dart:async';
import 'dart:io';
import 'package:cogni_anchor/data/chatbot/embedding_service.dart';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/face_recog/camera_store.dart';
import 'package:cogni_anchor/data/face_recog/face_crop_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_found_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_not_found_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:camera/camera.dart';

class FRScanPage extends StatefulWidget {
  const FRScanPage({super.key});

  @override
  State<FRScanPage> createState() => _FRScanPageState();
}

class _FRScanPageState extends State<FRScanPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  CameraLensDirection _currentLens = CameraLensDirection.front;
  bool _foundFace = false;
  Timer? _scanTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera(_currentLens);
  }

  Future<void> _initializeCamera(CameraLensDirection lens) async {
    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == lens,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startScanWindow();
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
      _goToNotFound();
    }
  }

  void _startScanWindow() {
    _foundFace = false;
    _scanFaceLoop();
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!_foundFace && mounted) {
        _goToNotFound();
      }
    });
  }

  Future<void> _scanFaceLoop() async {
    while (!_foundFace && mounted) {
      await _scanFaceOnce();
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  Future<void> _scanFaceOnce() async {
    try {
      final xFile = await _cameraController.takePicture();
      final imageFile = File(xFile.path);
      final croppedFace = await FaceCropService.instance.detectAndCropFace(imageFile);

      if (croppedFace == null) return;

      final faceBytes = await croppedFace.readAsBytes();
      final embedding = await EmbeddingService.instance.getEmbedding(faceBytes);
      final result = await ApiService.scanPerson(embedding: embedding);

      if (result['matched'] == true && mounted) {
        _foundFace = true;
        _scanTimeoutTimer?.cancel();
        final person = result['person'] as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => FRResultFoundPage(person: person)),
        );
      }
    } catch (e) {
      debugPrint("Scan attempt error: $e");
    }
  }

  void _goToNotFound() {
    _scanTimeoutTimer?.cancel();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()),
      );
    }
  }

  Future<void> _flipCamera() async {
    _scanTimeoutTimer?.cancel();
    await _cameraController.dispose();

    setState(() {
      _isCameraInitialized = false;
      _currentLens = _currentLens == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
    });

    await _initializeCamera(_currentLens);
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel();
    _cameraController.dispose();
    super.dispose();
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
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                Gap(20.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.camera, color: AppColors.primary),
                      Gap(5.h),
                      AppText("Scanning face...", fontSize: 12.sp, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40.h,
            right: 20.w,
            child: GestureDetector(
              onTap: _flipCamera,
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.cameraswitch, color: Colors.white),
              ),
            ),
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
}