import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:cogni_anchor/data/chatbot/embedding_service.dart';
import 'package:cogni_anchor/data/face_recog/camera_store.dart';
import 'package:cogni_anchor/data/notification/notification_service.dart';
import 'package:cogni_anchor/logic/bloc/auth/auth_bloc.dart';
import 'package:cogni_anchor/logic/bloc/auth/auth_state.dart';
import 'package:cogni_anchor/presentation/main_screen.dart';
import 'package:cogni_anchor/presentation/screens/auth/login_page.dart';
import 'package:cogni_anchor/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await NotificationService().init();
      developer.log('Local notifications initialized', name: 'AppInitializer');

      try {
        cameras = await availableCameras();
        developer.log('Cameras initialized', name: 'AppInitializer');
      } catch (e) {
        developer.log('Camera init error: $e', name: 'AppInitializer', error: e);
      }

      await EmbeddingService.instance.loadModel();
      developer.log('Embedding model loaded', name: 'AppInitializer');
    } catch (e, s) {
      developer.log('Service initialization failed: $e', name: 'AppInitializer', error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _servicesInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          if (!state.hasSeenOnboarding) {
            return OnboardingScreen(userModel: state.role);
          }
          return MainScreen(userModel: state.role);
        }

        if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginPage();
        }

        return const LoginPage();
      },
    );
  }
}
