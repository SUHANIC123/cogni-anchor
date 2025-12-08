import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FRResultFoundPage extends StatelessWidget {
  final RecognizedPerson person;

  const FRResultFoundPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade300,
          ),

          Positioned(
            top: 60.h,
            left: 20.w,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.9), Colors.orange.withOpacity(0.6)]),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text("Person Recognized!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  Text("We found them in your database", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: FRPersonCard(person: person),
          ),
        ],
      ),
    );
  }
}