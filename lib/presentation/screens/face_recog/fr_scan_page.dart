import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/logic/face_recog/face_recog_bloc.dart';
// Removed unused import: import 'package:cogni_anchor/main.dart'; 
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_found_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_result_not_found_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class FRScanPage extends StatefulWidget {
  const FRScanPage({super.key});

  @override
  State<FRScanPage> createState() => _FRScanPageState();
}

class _FRScanPageState extends State<FRScanPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // FIX: Renamed local variable to 'camerasList' and ensure await is used.
    final List<CameraDescription> camerasList = await availableCameras();

    final frontCamera = camerasList.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front, 
      orElse: () => camerasList.first
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _captureAndScan();
      }
    } catch (e) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()));
    }
  }

  Future<void> _captureAndScan() async {
    try {
      final xFile = await _cameraController.takePicture();
      final file = File(xFile.path);
      // 2. Dispatch ScanFace event
      if (mounted) context.read<FaceRecogBloc>().add(ScanFace(file));
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocListener<FaceRecogBloc, FaceRecogState>(
      listener: (context, state) {
        if (state is ScanSuccess) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FRResultFoundPage(person: state.person)));
        } else if (state is ScanNoMatch || state is ScanError) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FRResultNotFoundPage()));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(child: CameraPreview(_cameraController)),

            // ... [Keep your existing UI overlay: "Trouble remembering...", "Scanning face..." text, etc.] ...
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Example UI
                  Container(
                    padding: EdgeInsets.all(10),
                    color: Colors.white,
                    child: BlocBuilder<FaceRecogBloc, FaceRecogState>(
                      builder: (context, state) {
                        if (state is FaceRecogLoading) return Text(state.message);
                        return Text("Align face...");
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}