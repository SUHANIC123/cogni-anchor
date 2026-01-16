import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r))),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: AppText("Change Password", color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Current Password"),
            TextField(controller: _currentPasswordController, obscureText: true, decoration: const InputDecoration(hintText: "Enter current password")),
            Gap(20.h),
            _buildLabel("New Password"),
            TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(hintText: "Enter new password")),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {}, // Logic from original file
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Update Password"),
              ),
            ),
            Gap(20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
        child: AppText(text, fontWeight: FontWeight.w600, fontSize: 14.sp),
      );
}
