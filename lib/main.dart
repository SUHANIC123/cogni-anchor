import 'package:camera/camera.dart';
import 'package:cogni_anchor/data/notification_service.dart'; // NEW IMPORT
import 'package:cogni_anchor/logic/face_recog/face_recog_bloc.dart';
import 'package:cogni_anchor/logic/reminder/reminder_bloc.dart';
import 'package:cogni_anchor/presentation/screens/user_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notification Service
  await NotificationService().init();

  runApp(const CogniAnchor());
}

class CogniAnchor extends StatelessWidget {
  const CogniAnchor({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReminderBloc>(
          create: (context) => ReminderBloc(),
        ),
        BlocProvider<FaceRecogBloc>(
          create: (context) => FaceRecogBloc(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        child: const MaterialApp(
          debugShowCheckedModeBanner: false, 
          home: UserSelectionPage()
        ),
      ),
    );
  }
}