import 'dart:developer' as developer;
import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/data/notification/fcm_service.dart';
import 'package:cogni_anchor/presentation/screens/onboarding/onboarding_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/screens/auth/signup_page.dart';
import 'package:cogni_anchor/presentation/main_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    developer.log('Login attempt started for ${_emailController.text}', name: 'LoginPage');

    try {
      final userProfile = await AuthService.instance.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      developer.log('API login successful, initializing FCM', name: 'LoginPage');
      await FCMService.instance.initialize();

      if (!mounted) return;

      final role = userProfile.role == 'patient' 
          ? UserModel.patient 
          : UserModel.caretaker;

      final hasSeenOnboarding = await AuthService.instance.hasSeenOnboarding();
      developer.log('Login complete. Role: $role, HasSeenOnboarding: $hasSeenOnboarding', name: 'LoginPage');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => hasSeenOnboarding
              ? BlocProvider(
                  create: (_) => ReminderBloc(),
                  child: MainScreen(userModel: role),
                )
              : OnboardingScreen(userModel: role),
        ),
        (_) => false,
      );

    } catch (e) {
      developer.log('Login failed: $e', name: 'LoginPage', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText("Welcome to CogniAnchor", fontWeight: FontWeight.bold, fontSize: 24.sp),
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
            Gap(24.h),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                );
              },
              child: const Text("Create an account"),
            ),
          ],
        ),
      ),
    );
  }
}