import 'dart:async';
import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/core/background_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';

class PatientPermissionsScreen extends StatefulWidget {
  const PatientPermissionsScreen({super.key});

  @override
  State<PatientPermissionsScreen> createState() => _PatientPermissionsScreenState();
}

class _PatientPermissionsScreenState extends State<PatientPermissionsScreen> {
  bool _isLocationSharingOn = false;
  bool _isMicSharingOn = false;

  bool _hasLocationPermission = false;
  bool _hasMicPermission = false;

  bool? _prevLocationState;
  bool? _prevMicState;

  Timer? _syncTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDevicePermissions();
    _fetchBackendStatus();

    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchBackendStatus(silent: true);
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkDevicePermissions() async {
    final loc = await Permission.location.status;
    final mic = await Permission.microphone.status;

    if (mounted) {
      setState(() {
        _hasLocationPermission = loc.isGranted;
        _hasMicPermission = mic.isGranted;
      });
    }
  }

  Future<void> _fetchBackendStatus({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId != null) {
        final data = await ApiService.getPatientStatus(userId);

        final remoteLoc = data['location_toggle_on'] ?? false;
        final remoteMic = data['mic_toggle_on'] ?? false;

        if (mounted) {
          setState(() {
            _isLocationSharingOn = remoteLoc;
            _isMicSharingOn = remoteMic;
            _isLoading = false;
          });
        }

        if (_prevLocationState != remoteLoc) {
          await BackgroundService.instance.setLocationEnabled(remoteLoc);
          if (remoteLoc) await BackgroundService.instance.start();
          _prevLocationState = remoteLoc;
        }

        if (_prevMicState != remoteMic) {
          await BackgroundService.instance.setMicEnabled(remoteMic);
          if (remoteMic) await BackgroundService.instance.start();
          _prevMicState = remoteMic;
        }
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
    } finally {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEnabled,
    required bool hasDevicePermission,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              Gap(16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    Gap(4.h),
                    AppText(
                      subtitle,
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                ignoring: true,
                child: Switch(
                  value: isEnabled,
                  activeThumbColor: color,
                  onChanged: (val) {},
                ),
              ),
            ],
          ),
          if (!hasDevicePermission && isEnabled) ...[
            Gap(12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20.sp),
                  Gap(8.w),
                  Expanded(
                    child: AppText(
                      "Permission missing. Please enable in Settings.",
                      fontSize: 12.sp,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const TextButton(
                    onPressed: openAppSettings,
                    child: Text("Settings"),
                  )
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        automaticallyImplyLeading: false,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        title: AppText(
          "Privacy & Permissions",
          fontSize: 18.sp,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary),
                        Gap(12.w),
                        Expanded(
                          child: AppText(
                            "These settings are managed by your caretaker.",
                            fontSize: 13.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(24.h),
                  _buildPermissionTile(
                    title: "Location Sharing",
                    subtitle: "Allows caretaker to see your location",
                    icon: Icons.location_on_rounded,
                    color: Colors.blue,
                    isEnabled: _isLocationSharingOn,
                    hasDevicePermission: _hasLocationPermission,
                  ),
                  _buildPermissionTile(
                    title: "Environment Stream",
                    subtitle: "Allows caretaker to hear surroundings",
                    icon: Icons.mic_rounded,
                    color: Colors.orange,
                    isEnabled: _isMicSharingOn,
                    hasDevicePermission: _hasMicPermission,
                  ),
                ],
              ),
            ),
    );
  }
}
