import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ToggleButton({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
        decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(18.r), boxShadow: selected ? [const BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))] : []),
        child: AppText(label, fontSize: 16.sp, color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
      ),
    );
  }
}