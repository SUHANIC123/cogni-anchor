import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cogni_anchor/presentation/screens/permission/caregiver_live_map_screen.dart';
import 'package:cogni_anchor/presentation/screens/permission/mic_sharing_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool locationEnabled = false;
  bool microphoneEnabled = false;

  bool _loadingLocation = false;
  bool _loadingMic = false;
  bool _isLoadingStatus = true;
  
  String? _patientUserId;

  @override
  void initState() {
    super.initState();
    _loadLinkedPatientStatus();
  }

  Future<void> _loadLinkedPatientStatus() async {
    try {
      final pairId = PairContext.pairId;
      if (pairId == null) {
        if (mounted) setState(() => _isLoadingStatus = false);
        return;
      }

      final pairInfo = await ApiService.getPairInfo(pairId);
      final patientId = pairInfo['patient_user_id'];

      final status = await ApiService.getPatientStatus(patientId);

      if (mounted) {
        setState(() {
          _patientUserId = patientId; 
          locationEnabled = status['location_toggle_on'] ?? false;
          microphoneEnabled = status['mic_toggle_on'] ?? false;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      debugPrint("Status load error: $e");
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _toggleLocation(bool value) async {
    if (_loadingLocation || _patientUserId == null) return;
    setState(() => _loadingLocation = true);

    try {
      await ApiService.updatePatientStatus(
        locationToggle: value, 
        targetUserId: _patientUserId
      );
      setState(() => locationEnabled = value);
    } catch (e) {
      _showMsg("Action failed: ${e.toString()}");
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _toggleMic(bool value) async {
    if (_loadingMic || _patientUserId == null) return;
    setState(() => _loadingMic = true);

    try {
      await ApiService.updatePatientStatus(
        micToggle: value,
        targetUserId: _patientUserId
      );
      setState(() => microphoneEnabled = value);
    } catch (e) {
      _showMsg("Action failed: ${e.toString()}");
    } finally {
      setState(() => _loadingMic = false);
    }
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
          "Remote Monitor",
          fontSize: 18.sp,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.health_and_safety,
                      color: AppColors.primary,
                      size: 40.sp,
                    ),
                  ),
                  Gap(12.h),
                  AppText(
                    "Monitor and control patient status",
                    color: Colors.grey.shade700,
                    fontSize: 14.sp,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Gap(10.h),

            if (_isLoadingStatus)
              const Center(child: CircularProgressIndicator())
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: AppText("Live Services", fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Gap(12.h),

              _permissionTile(
                title: "Patient Location Sharing",
                subtitle: locationEnabled ? "Patient is tracking" : "Tracking disabled",
                icon: Icons.location_on_rounded,
                value: locationEnabled,
                isLoading: _loadingLocation,
                color: Colors.orangeAccent,
                onChanged: _toggleLocation,
                readOnly: false,
              ),

              if (locationEnabled)
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      icon: const Icon(Icons.map),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverLiveMapScreen()));
                      },
                      label: const Text("Open Live Map", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

              Gap(20.h),

              _permissionTile(
                title: "Patient Audio Sharing",
                subtitle: microphoneEnabled ? "Patient is streaming" : "Audio streaming off",
                icon: Icons.mic_rounded,
                value: microphoneEnabled,
                isLoading: _loadingMic,
                color: Colors.blueAccent,
                onChanged: _toggleMic,
                readOnly: false,
              ),

              if (microphoneEnabled)
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                        side: const BorderSide(color: Colors.blueAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      icon: const Icon(Icons.headset),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MicSharingScreen()));
                      },
                      label: const Text("Listen Live", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

              Gap(40.h),

              Center(
                child: AppText(
                  "Enabling these will activate features on the patient's device.",
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _permissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool isLoading,
    required Color color,
    required Function(bool) onChanged,
    required bool readOnly,
  }) {
    return Container(
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
      child: Row(
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
                AppText(title, fontSize: 16.sp, fontWeight: FontWeight.w600),
                Gap(4.h),
                AppText(subtitle, fontSize: 12.sp, color: Colors.grey),
              ],
            ),
          ),
          if (readOnly)
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.grey,
            )
          else
            isLoading
                ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
        ],
      ),
    );
  }

  void _showMsg(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}