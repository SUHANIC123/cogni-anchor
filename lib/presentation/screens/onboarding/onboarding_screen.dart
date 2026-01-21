import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/screens/onboarding/caretaker_setup_page.dart';
import 'package:cogni_anchor/presentation/screens/onboarding/onboarding_permission_page.dart';
import 'package:cogni_anchor/presentation/screens/onboarding/patient_setup_page.dart';
import 'package:cogni_anchor/presentation/screens/settings/terms_conditions_screen.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class OnboardingScreen extends StatefulWidget {
  final UserModel userModel;
  const OnboardingScreen({super.key, required this.userModel});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late List<OnboardingContent> _contents;
  bool _allPermissionsGranted = false;

  bool get _isPatient => widget.userModel == UserModel.patient;

  // Added missing content lists to resolve undefined identifier errors
  final List<OnboardingContent> _patientContent = [
    OnboardingContent(
      title: "Your AI Companion",
      description: "I'm here to help you remember things and chat whenever you need help.",
      icon: Icons.smart_toy_rounded,
      color: Colors.blueAccent,
    ),
    OnboardingContent(
      title: "Never Miss a Moment",
      description: "I'll remind you about medications, appointments, and daily tasks on time.",
      icon: Icons.alarm_on_rounded,
      color: Colors.orangeAccent,
    ),
    OnboardingContent(
      title: "Recognize Loved Ones",
      description: "Having trouble remembering a face? Just scan with your camera, and I'll help you.",
      icon: Icons.face_retouching_natural_rounded,
      color: Colors.purpleAccent,
    ),
    OnboardingContent(
      title: "Stay Safe & Connected",
      description: "Your caretaker can see where you are to ensure you are always safe.",
      icon: Icons.health_and_safety_rounded,
      color: AppColors.success,
    ),
  ];

  final List<OnboardingContent> _caretakerContent = [
    OnboardingContent(
      title: "Remote Monitoring",
      description: "Monitor the patient's live location and audio environment in real-time.",
      icon: Icons.location_on_rounded,
      color: Colors.blueAccent,
    ),
    OnboardingContent(
      title: "Manage Reminders",
      description: "Set and manage medication reminders that sync instantly to the patient's device.",
      icon: Icons.edit_calendar_rounded,
      color: Colors.orangeAccent,
    ),
    OnboardingContent(
      title: "Face Database",
      description: "Update the trusted people database to help your loved one recognize family.",
      icon: Icons.people_alt_rounded,
      color: Colors.purpleAccent,
    ),
    OnboardingContent(
      title: "Peace of Mind",
      description: "Receive instant alerts and stay connected to ensure their well-being.",
      icon: Icons.favorite_rounded,
      color: Colors.redAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contents = _isPatient ? _patientContent : _caretakerContent;
  }

  void _onNextPressed() {
    final int permissionPageIndex = _contents.length;
    final int termsPageIndex = _contents.length + 1;

    if (_currentIndex == permissionPageIndex) {
      if (!_allPermissionsGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please grant all permissions to continue")),
        );
        return;
      }
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentIndex == termsPageIndex) {
      // Logic handled by the "Accept" button inside TermsConditionsScreen
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Total pages = Content Slides + Permission Page + Terms Page
    final int totalViewPages = _contents.length + 2;
    final bool isTermsPage = _currentIndex == totalViewPages - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalViewPages,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  if (index < _contents.length) {
                    return _buildPage(_contents[index]);
                  } else if (index == _contents.length) {
                    return OnboardingPermissionPage(
                      userModel: widget.userModel,
                      onPermissionsChanged: (granted) => setState(() => _allPermissionsGranted = granted),
                    );
                  } else {
                    return TermsConditionsScreen(
                      showHeader: false,
                      onAccept: () {
                        if (_isPatient) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientSetupPage()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CaretakerSetupPage()));
                        }
                      },
                    );
                  }
                },
              ),
            ),
            if (!isTermsPage) _buildBottomControls(totalViewPages),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(int totalPages) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              totalPages,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: 6.w),
                height: 8.h,
                width: _currentIndex == index ? 24.w : 8.w,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text("Next", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingContent content) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(color: content.color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(content.icon, size: 100.sp, color: content.color),
          ),
          Gap(40.h),
          AppText(content.title, fontSize: 24.sp, fontWeight: FontWeight.bold, textAlign: TextAlign.center),
          Gap(16.h),
          AppText(content.description, fontSize: 15.sp, color: Colors.grey.shade600, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// Added missing class definition to resolve undefined class error
class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
