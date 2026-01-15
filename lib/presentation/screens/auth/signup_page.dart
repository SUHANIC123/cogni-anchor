import 'dart:developer' as developer;
import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedRole = 'patient'; 
  bool _loading = false;

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill all fields");
      return;
    }
    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _loading = true);
    developer.log('Signup attempt started for $email with role $_selectedRole', name: 'SignupPage');

    try {
      await AuthService.instance.signUp(
        email: email,
        password: password,
        role: _selectedRole,
      );

      developer.log('Signup successful for $email', name: 'SignupPage');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created! Please login.")),
        );
        Navigator.pop(context); // Go back to login
      }
    } catch (e) {
      developer.log('Signup failed: $e', name: 'SignupPage', error: e);
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText("Create Account", fontWeight: FontWeight.bold, fontSize: 24.sp),
                Gap(30.h),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                Gap(16.h),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                Gap(16.h),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Confirm Password"),
                ),
                Gap(16.h),
                AppText("I am a:", fontWeight: FontWeight.w600, fontSize: 14.sp),
                Gap(8.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard("Patient", "patient"),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: _buildRoleCard("Caretaker", "caretaker"),
                    ),
                  ],
                ),
                Gap(24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sign Up"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String value) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}