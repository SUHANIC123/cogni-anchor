import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReminderMainCardWidget extends StatelessWidget {
  final String title;
  final String time;
  final Color color;

  const ReminderMainCardWidget({super.key, required this.title, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130.h,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 55.w,
            height: 55.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(Icons.upcoming, color: Colors.white, size: 30.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Upcoming Reminder",
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 6.h),
                Text(
                  title,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16.sp, color: Colors.white70),
                    SizedBox(width: 4.w),
                    Text(
                      time,
                      style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
