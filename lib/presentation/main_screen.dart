import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/data/core/background_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/screens/chatbot/chatbot_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_intro_page.dart';
import 'package:cogni_anchor/presentation/screens/permission/patient_permissions_screen.dart';
import 'package:cogni_anchor/presentation/screens/permissions_screen.dart';
import 'package:cogni_anchor/presentation/screens/reminder/reminder_page.dart';
import 'package:cogni_anchor/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends StatefulWidget {
  final UserModel userModel;
  const MainScreen({super.key, required this.userModel});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<Map<String, dynamic>> _finalNavItems;

  final List<Map<String, dynamic>> _allNavItems = [
    {'index': 0, 'iconOutlined': Icons.alarm_rounded, 'iconFilled': Icons.alarm, 'label': 'Alarm'},
    {'index': 1, 'iconOutlined': Icons.share_location_rounded, 'iconFilled': Icons.share_location, 'label': 'Share'},
    {'index': 2, 'iconOutlined': Icons.chat_bubble_outline_rounded, 'iconFilled': Icons.chat_bubble, 'label': 'Chat'},
    {'index': 3, 'iconOutlined': Icons.face_outlined, 'iconFilled': Icons.face, 'label': 'Face'},
    {'index': 4, 'iconOutlined': Icons.settings_outlined, 'iconFilled': Icons.settings, 'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _initPages(); // Initialize pages based on role

    if (widget.userModel == UserModel.patient) {
      _checkAndStartService();
    }
  }

  void _initPages() {
    final permissionsPage = widget.userModel == UserModel.patient ? const PatientPermissionsScreen() : const PermissionsScreen();

    final allPages = [ReminderPage(userModel: widget.userModel), permissionsPage, const ChatbotPage(), const FacialRecognitionPage(), SettingsScreen(userModel: widget.userModel)];

    if (widget.userModel == UserModel.patient) {
      _pages = allPages;
      _finalNavItems = _allNavItems;
    } else {
      _pages = allPages;
      _finalNavItems = _allNavItems;
    }
  }

  Future<void> _checkAndStartService() async {
    final locStatus = await Permission.locationAlways.status;
    final micStatus = await Permission.microphone.status;

    if (locStatus.isGranted || micStatus.isGranted) {
      await BackgroundService.instance.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: GNav(
              rippleColor: AppColors.primaryLight,
              hoverColor: AppColors.primaryLight,
              gap: 8,
              activeColor: AppColors.primary,
              iconSize: 24.sp,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: AppColors.primaryLight,
              color: AppColors.textSecondary,
              tabs: _finalNavItems.asMap().entries.map((entry) {
                int i = entry.key;
                IconData iconFilled = entry.value['iconFilled'];
                IconData iconOutlined = entry.value['iconOutlined'];
                String label = entry.value['label'];

                return GButton(
                  icon: _selectedIndex == i ? iconFilled : iconOutlined,
                  text: label,
                );
              }).toList(),
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
