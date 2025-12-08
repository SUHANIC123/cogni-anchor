import 'package:camera/camera.dart';
import 'package:cogni_anchor/presentation/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const CogniAnchor());
}

class CogniAnchor extends StatelessWidget {
  const CogniAnchor({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(390, 844),
      child: const MaterialApp(debugShowCheckedModeBanner: false, home: MainScreen()),
    );
  }
}
