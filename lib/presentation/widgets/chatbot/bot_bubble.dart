import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class BotBubble extends StatelessWidget {
  final String text;
  const BotBubble(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(color: const Color(0xffefefef), borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        children: [
          Icon(Icons.fluorescent_rounded, color: AppColors.primary.withValues(alpha: 0.7)),
          Gap(10.w),
          Expanded(child: AppText(text, fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }
}