import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class TextInputBox extends StatelessWidget {
  const TextInputBox({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(padding: EdgeInsets.symmetric(horizontal: 16.w), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]), child: const TextField(decoration: InputDecoration(border: InputBorder.none, hintText: "How can I help?")))),
        Gap(12.w),
        Container(width: 50.w, height: 50.w, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white)),
      ],
    );
  }
}