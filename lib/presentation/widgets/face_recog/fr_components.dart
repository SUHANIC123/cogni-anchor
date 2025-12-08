import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/face_recog/fr_add_person_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class RecognizedPerson {
  final String name;
  final String relationship;
  final String occupation; // NEW FIELD
  final String age;        // NEW FIELD
  final String notes;      // NEW FIELD

  const RecognizedPerson({
    required this.name,
    required this.relationship,
    required this.occupation, // UPDATED
    required this.age,        // UPDATED
    required this.notes,      // UPDATED
  });
}

class FRMainButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FRMainButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.appColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
          elevation: 0,
        ),
        child: AppText(label, color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class FRHowItWorksCard extends StatelessWidget {
  const FRHowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.appColor, size: 20.sp),
              Gap(8.w),
              AppText("How it works", fontSize: 16.sp, fontWeight: FontWeight.w600),
            ],
          ),
          Gap(15.h),
          _stepItem(Icons.camera_alt_outlined, "Position Camera", "Hold your phone steady and point the camera at the person's face"),
          _stepItem(Icons.face_unlock_outlined, "Wait for Recognition", "The app will automatically scan and identify the person"),
          _stepItem(Icons.person_outline, "View Information", "See their name, relationship, and other helpful details", isLast: true),
        ],
      ),
    );
  }

  Widget _stepItem(IconData icon, String title, String sub, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: const Color(0xFFFFF0E6), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(icon, color: colors.appColor, size: 20.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, fontSize: 14.sp, fontWeight: FontWeight.w600),
                Gap(4.h),
                AppText(sub, fontSize: 11.sp, color: Colors.black54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FRPersonCard extends StatelessWidget {
  final RecognizedPerson person;

  const FRPersonCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(person.name, fontSize: 20.sp, fontWeight: FontWeight.w700),
          Gap(8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14.sp, color: Colors.green),
                Gap(4.w),
                AppText("Verified Match", fontSize: 12.sp, color: Colors.green, fontWeight: FontWeight.w600),
              ],
            ),
          ),
          Gap(20.h),
          _infoRow(Icons.favorite_border, "Relationship", person.relationship),
          _infoRow(Icons.work_outline, "Occupation", person.occupation), // NEW DISPLAY
          _infoRow(Icons.calendar_today_outlined, "Age", person.age),      // NEW DISPLAY
          _infoRow(Icons.edit_note, "Notes", person.notes),            // NEW DISPLAY
          Gap(20.h),
          FRMainButton(label: "OK", onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.appColor, size: 22.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(label, fontSize: 12.sp, color: Colors.grey),
                AppText(value, fontSize: 15.sp, fontWeight: FontWeight.w500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FRNotFoundCard extends StatelessWidget {
  const FRNotFoundCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText("No Information Found!", fontSize: 18.sp, fontWeight: FontWeight.w700),
          Gap(8.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, size: 14.sp, color: Colors.red),
              Gap(4.w),
              AppText("This person is not in your database", fontSize: 12.sp, color: Colors.red),
            ],
          ),
          Gap(30.h),
          FRMainButton(
            label: "Add to Database",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FRAddPersonPage()));
            },
          ),
          Gap(12.h),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.r), color: const Color(0xFFFFF0E6)),
              child: AppText("Back to Home", fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}