import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuickChip extends StatelessWidget {
  final String title;
  const QuickChip(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), border: Border.all(color: AppColors.primary, width: 1.4)),
      child: AppText(title, fontSize: 14.sp, color: AppColors.primary),
    );
  }
}