import 'package:cogni_anchor/data/core/pair_context.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_scan_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_add_person_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_people_list_page.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class FacialRecognitionPage extends StatelessWidget {
  const FacialRecognitionPage({super.key});

  void _requirePair(BuildContext context, VoidCallback action) {
    if (PairContext.pairId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please connect to a patient first")),
      );
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        automaticallyImplyLeading: false,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        title: AppText(
          "Face Recognition",
          fontSize: 18.sp,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(10.h),
            _buildHeroCard(),
            Gap(24.h),
            _sectionHeader("Management"),
            Gap(12.h),
            _buildActionTile(
              context,
              title: "Add New Person",
              subtitle: "Register a family member or friend",
              icon: Icons.person_add_rounded,
              color: Colors.blueAccent,
              onTap: () => _requirePair(
                context,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FRAddPersonPage()),
                ),
              ),
            ),
            Gap(16.h),
            _buildActionTile(
              context,
              title: "Manage People",
              subtitle: "Edit details of registered faces",
              icon: Icons.manage_accounts_rounded,
              color: Colors.orangeAccent,
              onTap: () => _requirePair(
                context,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FRPeopleListPage(forEditing: true),
                  ),
                ),
              ),
            ),
            Gap(16.h),
            _buildActionTile(
              context,
              title: "Remove Person",
              subtitle: "Delete a person from database",
              icon: Icons.person_remove_rounded,
              color: Colors.redAccent,
              onTap: () => _requirePair(
                context,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FRPeopleListPage(forEditing: false),
                  ),
                ),
              ),
            ),
            Gap(100.h),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _requirePair(
          context,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FRScanPage()),
          ),
        ),
        label: const AppText("Start Scanning", color: Colors.white, fontWeight: FontWeight.w600),
        icon: const Icon(Icons.center_focus_strong, color: Colors.white),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: AppText(
        title,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.visibility_outlined, color: AppColors.primary, size: 28.sp),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  "Identify in real-time",
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                Gap(4.h),
                AppText(
                  "Point camera to recognize loved ones instantly.",
                  color: Colors.grey,
                  fontSize: 13.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            Gap(16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                    color: AppColors.textPrimary,
                  ),
                  Gap(4.h),
                  AppText(
                    subtitle,
                    color: Colors.grey.shade500,
                    fontSize: 12.sp,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
