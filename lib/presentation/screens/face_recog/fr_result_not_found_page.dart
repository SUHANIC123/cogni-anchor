import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FRResultNotFoundPage extends StatelessWidget {
  const FRResultNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey.shade300),
          Positioned(
            top: 60.h,
            left: 20.w,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.redAccent.withValues(alpha: 0.9), Colors.redAccent.withValues(alpha: 0.6)]),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text(
                    "Person not Recognized!",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  ),
                  Text(
                    "We can't find them in your database",
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ),
          const Align(alignment: Alignment.center, child: FRNotFoundCard()),
        ],
      ),
    );
  }
}
