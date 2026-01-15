import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingPermissionPage extends StatefulWidget {
  final UserModel userModel;
  const OnboardingPermissionPage({super.key, required this.userModel});

  @override
  State<OnboardingPermissionPage> createState() => _OnboardingPermissionPageState();
}

class _OnboardingPermissionPageState extends State<OnboardingPermissionPage> with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _micGranted = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.status;
    final loc = await Permission.location.status;
    final mic = await Permission.microphone.status;
    final cam = await Permission.camera.status;

    if (mounted) {
      setState(() {
        _notificationGranted = notif.isGranted;
        _locationGranted = loc.isGranted;
        _micGranted = mic.isGranted;
        _cameraGranted = cam.isGranted;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = widget.userModel == UserModel.patient;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, size: 60.sp, color: AppColors.primary),
          ),
          Gap(24.h),
          AppText(
            "Permissions Required",
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          Gap(12.h),
          AppText(
            "To provide the best care and safety features, we need access to the following:",
            fontSize: 14.sp,
            color: Colors.grey.shade600,
            textAlign: TextAlign.center,
          ),
          Gap(30.h),

          _buildPermissionTile(
            "Notifications",
            "For reminders and emergency alerts",
            Icons.notifications_active_rounded,
            Colors.orangeAccent,
            _notificationGranted,
            Permission.notification,
          ),

          _buildPermissionTile(
            "Location",
            isPatient ? "For live safety tracking" : "To show your location on map",
            Icons.location_on_rounded,
            Colors.blueAccent,
            _locationGranted,
            Permission.location,
          ),

          if (isPatient)
            _buildPermissionTile(
              "Microphone",
              "For voice chat & environment sharing",
              Icons.mic_rounded,
              Colors.redAccent,
              _micGranted,
              Permission.microphone,
            ),

          _buildPermissionTile(
            "Camera",
            "For face recognition & scanning",
            Icons.camera_alt_rounded,
            Colors.purpleAccent,
            _cameraGranted,
            Permission.camera,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isGranted,
    Permission permission,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isGranted ? Colors.green.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isGranted ? Colors.green.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: isGranted ? Colors.green : color,
              size: 20.sp,
            ),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, fontSize: 15.sp, fontWeight: FontWeight.w600),
                AppText(subtitle, fontSize: 11.sp, color: Colors.grey),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: () => _requestPermission(permission),
              style: TextButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.1),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: AppText(
                "Allow",
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
