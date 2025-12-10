import 'package:cogni_anchor/presentation/main_screen.dart';
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cogni_anchor/data/models/user_model.dart'; // Imported from new model file

class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  State<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  void _selectRole(UserModel role) {
    // Navigate to MainScreen and pass the selected role
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen(userModel: role)));
  }

  Widget _buildRoleCard({required String title, required String subtitle, required IconData icon, required UserModel role, required Color cardColor}) {
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(color: cardColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50.sp, color: Colors.white),
            Gap(15.h),
            AppText(title, fontSize: 24.sp, fontWeight: FontWeight.w700, color: Colors.white),
            Gap(5.h),
            AppText(subtitle, fontSize: 14.sp, color: Colors.white70, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 25.w),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText("Who are you?", fontSize: 30.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                      Gap(10.h),
                      AppText("Select the option that best suits you to continue.", fontSize: 13.sp, textAlign: TextAlign.center, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRoleCard(
                      title: "Caretaker",
                      subtitle: "Manage reminders, settings, and full access to all features.",
                      icon: Icons.shield,
                      role: UserModel.caretaker,
                      cardColor: colors.appColor,
                    ),
                    _buildRoleCard(
                      title: "Patient",
                      subtitle: "Simplified interface with essential features like reminders and chatbot.",
                      icon: Icons.person_outline,
                      role: UserModel.patient,
                      cardColor: Colors.blueGrey.shade400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
