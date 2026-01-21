// lib/presentation/screens/onboarding/patient_setup_page.dart

import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/main_screen.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Ensure qr_flutter is in pubspec.yaml

class PatientSetupPage extends StatefulWidget {
  const PatientSetupPage({super.key});

  @override
  State<PatientSetupPage> createState() => _PatientSetupPageState();
}

class _PatientSetupPageState extends State<PatientSetupPage> {
  String? _pairId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPairId();
  }

  Future<void> _loadPairId() async {
    final user = AuthService.instance.currentUser;
    setState(() {
      _pairId = user?.pairId;
      _isLoading = false;
    });
  }

  Future<void> _finishSetup() async {
    await AuthService.instance.completeOnboarding();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ReminderBloc(),
          child: const MainScreen(userModel: UserModel.patient),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phonelink_ring_rounded, size: 60.sp, color: AppColors.primary),
              ),
              Gap(20.h),
              AppText(
                "Connect Caretaker",
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              Gap(12.h),
              AppText(
                "Show this QR code or share the manual code with your caretaker to connect your accounts.",
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                textAlign: TextAlign.center,
              ),
              Gap(40.h),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_pairId == null)
                const AppText("Error: No Pair ID found. Please login again.", color: Colors.red)
              else ...[
                // QR Code Display
                Center(
                  child: QrImageView(
                    data: _pairId!,
                    version: QrVersions.auto,
                    size: 200.w,
                    gapless: false,
                    foregroundColor: AppColors.primary,
                  ),
                ),
                Gap(24.h),
                _buildCodeBox(),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  onPressed: _finishSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 4,
                  ),
                  child: AppText("Enter App", fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              Gap(20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            _pairId!,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Gap(16.h),
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _pairId!));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied")));
          },
          icon: const Icon(Icons.copy, color: AppColors.primary),
          label: const AppText("Copy Code", color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}