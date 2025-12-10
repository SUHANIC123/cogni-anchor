import 'package:camera/camera.dart';
import 'package:cogni_anchor/bloc/face_recog/face_recog_bloc.dart'; // NEW
import 'package:cogni_anchor/bloc/reminder/reminder_bloc.dart';     // NEW
import 'package:cogni_anchor/presentation/screens/user_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // NEW

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CogniAnchor());
}

class CogniAnchor extends StatelessWidget {
  const CogniAnchor({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the app with MultiBlocProvider
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
        designSize: Size(390, 844),
        child: const MaterialApp(
          debugShowCheckedModeBanner: false, 
          home: UserSelectionPage()
        ),
      ),
    );
  }
}