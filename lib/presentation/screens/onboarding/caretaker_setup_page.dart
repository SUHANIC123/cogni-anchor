import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/main_screen.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CaretakerSetupPage extends StatefulWidget {
  const CaretakerSetupPage({super.key});

  @override
  State<CaretakerSetupPage> createState() => _CaretakerSetupPageState();
}

class _CaretakerSetupPageState extends State<CaretakerSetupPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isConnecting = false;
  bool _hasScanned = false;
  String? _existingPairId;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  void _checkExistingConnection() {
    final user = AuthService.instance.currentUser;
    if (user?.pairId != null) {
      setState(() {
        _existingPairId = user!.pairId;
      });
    }
  }

  Future<void> _proceedToApp() async {
    await AuthService.instance.completeOnboarding();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ReminderBloc(),
          child: const MainScreen(userModel: UserModel.caretaker),
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _handleConnection(String pairCode) async {
    if (_isConnecting || _hasScanned) return;

    setState(() {
      _isConnecting = true;
      _hasScanned = true;
    });

    try {
      final caretakerId = AuthService.instance.currentUser?.id;
      if (caretakerId == null) throw Exception("Session error: Please login again.");

      await AuthService.instance.connectPatient(pairCode, caretakerId);

      // Navigate to app after successful connection
      await _proceedToApp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() {
          _isConnecting = false;
          _hasScanned = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. If already connected, show "Continue" screen
    if (_existingPairId != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Connection Status"),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 80.sp, color: AppColors.success),
              Gap(24.h),
              AppText("You are connected!", fontSize: 22.sp, fontWeight: FontWeight.bold),
              Gap(12.h),
              AppText(
                "You are already linked to a patient account.",
                textAlign: TextAlign.center,
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
              Gap(8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppText("Pair ID: $_existingPairId", fontWeight: FontWeight.bold),
              ),
              Gap(40.h),
              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  onPressed: _proceedToApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: const Text("Continue to App", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Otherwise show Scanner Screen
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Link to Patient"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            AppText("Scan Patient's QR Code", fontSize: 20.sp, fontWeight: FontWeight.bold),
            Gap(12.h),
            AppText(
              "Point your camera at the QR code displayed on the patient's device.",
              textAlign: TextAlign.center,
              color: Colors.grey.shade600,
            ),
            Gap(24.h),
            Container(
              height: 300.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      _handleConnection(barcodes.first.rawValue!);
                    }
                  },
                ),
              ),
            ),
            Gap(30.h),
            const AppText("OR ENTER MANUALLY", color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
            Gap(16.h),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: "Enter Pairing Code",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            Gap(20.h),
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : () => _handleConnection(_codeController.text.trim()),
                child: _isConnecting ? const CircularProgressIndicator(color: Colors.white) : const Text("Connect Manually"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
