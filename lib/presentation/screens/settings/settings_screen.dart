import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/screens/profile/dementia_profile_screen.dart';
import 'package:cogni_anchor/presentation/screens/profile/edit_profile_screen.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cogni_anchor/presentation/screens/auth/login_page.dart';
import 'change_password_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel userModel;
  const SettingsScreen({super.key, required this.userModel});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? pairId;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    pairId = PairContext.pairId;
  }

  Future<void> _logout() async {
    AuthService.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        title: AppText("Settings", fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildProfileHeader(),
            Gap(24.h),
            _tile(Icons.edit_outlined, "Edit Profile", () => _go(const EditProfileScreen())),
            _tile(Icons.person_outline, "Dementia Patient Profile", () => _go(const DementiaProfileScreen())),
            if (widget.userModel == UserModel.patient && pairId != null) _patientPairIdBox(),
            if (widget.userModel == UserModel.caretaker) _caretakerSection(),
            _tile(Icons.lock_outline, "Change Password", () => _go(const ChangePasswordScreen())),
            _tile(Icons.description_outlined, "Terms and Conditions", () => _go(const TermsConditionsScreen())),
            Gap(20.h),
            _logoutTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = AuthService.instance.currentUser;
    return Column(
      children: [
        CircleAvatar(
          radius: 45.r,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, size: 45.sp, color: AppColors.primary),
        ),
        Gap(12.h),
        AppText(widget.userModel == UserModel.patient ? "Patient" : "Caretaker", fontSize: 18.sp, fontWeight: FontWeight.bold),
        AppText(user?.email ?? "", fontSize: 14.sp, color: Colors.grey),
      ],
    );
  }

  Widget _caretakerSection() {
    return pairId == null ? _tile(Icons.group_outlined, "Connect to Patient", _showPairIdDialog) : _caretakerPairIdBox();
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: AppText(title, fontSize: 15.sp, fontWeight: FontWeight.w500),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutTile() {
    return Container(
      decoration: _boxDecoration(),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const AppText("Log out", color: Colors.red, fontWeight: FontWeight.w600),
        onTap: () => _logout(),
      ),
    );
  }

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      );

  void _go(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _showPairIdDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: AppText("Connect to Patient", fontWeight: FontWeight.bold, fontSize: 18.sp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText("Enter the pair code shown on the patient's device.", fontSize: 13.sp, color: Colors.grey),
            Gap(16.h),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Enter Pair Code",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;

              final caretakerId = AuthService.instance.currentUser?.id;
              if (caretakerId == null) return;

              try {
                await AuthService.instance.connectPatient(code, caretakerId);
                if (mounted) {
                  setState(() => pairId = code);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connected successfully!")));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  Widget _patientPairIdBox() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText("Your Pair Code", fontSize: 12.sp, color: Colors.grey),
                AppText(pairId!, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pairId!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied")));
            },
          )
        ],
      ),
    );
  }

  Widget _caretakerPairIdBox() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          const Icon(Icons.link, color: AppColors.success),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText("Linked to Patient", fontSize: 12.sp, color: Colors.grey),
                AppText("Pair ID: $pairId", fontSize: 14.sp, fontWeight: FontWeight.bold),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success),
        ],
      ),
    );
  }
}
