import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReminderChildCardWidget extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final Color color;

  const ReminderChildCardWidget({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.alarm,
              color: color,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      date,
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                    ),
                    SizedBox(width: 10.w),
                    Icon(Icons.access_time, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      time,
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey),
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
