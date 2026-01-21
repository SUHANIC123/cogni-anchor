import 'dart:developer' as developer;
import 'package:cogni_anchor/data/core/background_service.dart';
import 'package:cogni_anchor/data/notification/notification_service.dart';
import 'package:cogni_anchor/logic/bloc/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/logic/bloc/auth/auth_bloc.dart';
import 'package:cogni_anchor/logic/bloc/auth/auth_event.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogni_anchor/presentation/screens/app_initializer.dart';
import 'package:sound_stream/sound_stream.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  developer.log('Firebase initialized', name: 'Main');
  
  await NotificationService().init();
  developer.log('Notification Service initialized', name: 'Main');
  
  await BackgroundService.instance.initialize();
  developer.log('Background Service initialized', name: 'Main');

  try {
    final recorder = RecorderStream();
    await recorder.initialize();
    developer.log('Recorder pre-initialized in main thread', name: 'Main');
  } catch (e) {
    developer.log('Recorder pre-init warning: $e', name: 'Main');
  }

  runApp(const CogniAnchor());
}

class CogniAnchor extends StatelessWidget {
  const CogniAnchor({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ReminderBloc(),
        ),
        BlocProvider(
          create: (_) => AuthBloc()..add(AuthCheckStatus()),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}