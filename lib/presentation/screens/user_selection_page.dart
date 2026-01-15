import 'dart:developer' as developer;
import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/data/profile/patient_status_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cogni_anchor/presentation/screens/app_initializer.dart';

class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});
  @override
  State<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  bool _isSelecting = false;

  Future<void> _selectRole(UserModel role) async {
    if (_isSelecting) return;
    setState(() => _isSelecting = true);
    developer.log('Selecting role: ${role.name}', name: 'UserSelectionPage');

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("No user found during role selection");
      
      await Supabase.instance.client.from('users').update({'role': role.name}).eq('id', user.id);
      
      if (role == UserModel.patient) {
        await PatientStatusService.markLoggedIn();
      }
      
      developer.log('Role updated to ${role.name}, navigating to AppInitializer', name: 'UserSelectionPage');
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AppInitializer()), (_) => false);
    } catch (e) {
      developer.log('Error selecting role: $e', name: 'UserSelectionPage', error: e);
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  Widget _buildRoleCard({required String title, required String subtitle, required IconData icon, required UserModel role, required Color cardColor}) {
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: Container(
        width: double.infinity, margin: EdgeInsets.symmetric(vertical: 10.h), padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: cardColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(children: [Icon(icon, size: 50.sp, color: Colors.white), Gap(15.h), AppText(title, fontWeight: FontWeight.w700, color: Colors.white), Gap(5.h), AppText(subtitle, color: Colors.white70, textAlign: TextAlign.center)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 25.w),
          child: Column(
            children: [
              const Expanded(flex: 1, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [AppText("Who are you?", fontWeight: FontWeight.bold), SizedBox(height: 10), AppText("Select the option that best suits you to continue.", textAlign: TextAlign.center, color: Colors.grey)]))),
              Expanded(flex: 3, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [_buildRoleCard(title: "Caretaker", subtitle: "Manage reminders, settings, and full access to all features.", icon: Icons.shield, role: UserModel.caretaker, cardColor: AppColors.primary), _buildRoleCard(title: "Patient", subtitle: "Simplified interface with essential features like reminders and chatbot.", icon: Icons.person_outline, role: UserModel.patient, cardColor: Colors.blueGrey.shade400)])),
            ],
          ),
        ),
      ),
    );
  }
}