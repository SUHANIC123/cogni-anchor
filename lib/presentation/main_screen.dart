import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/screens/chatbot_page.dart';
import 'package:cogni_anchor/presentation/screens/face_recog/fr_intro_page.dart';
import 'package:cogni_anchor/presentation/screens/reminder_page.dart';
import 'package:cogni_anchor/data/models/user_model.dart'; // Imported from new model file
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final UserModel userModel;
  const MainScreen({super.key, required this.userModel});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final orange = colors.appColor;

  // 1. Define all possible pages
  final List<Widget> _allPages = [
    // Placeholder - will be replaced with ReminderPage(UserModel: widget.UserModel)
    const ReminderPage(userModel: UserModel.caretaker),
    Container(color: Colors.green), // Index 1: Location/Send
    const ChatbotPage(), // Index 2: Chatbot
    const FacialRecognitionPage(), // Index 3: Face Recognition
    Container(color: Colors.red), // Index 4: Settings
  ];

  // 2. Define the list of navigation bar items with their original index
  final List<Map<String, dynamic>> _allNavItems = [
    {'index': 0, 'iconOutlined': Icons.alarm_rounded, 'iconFilled': Icons.alarm, 'label': 'Reminders'},
    {'index': 1, 'iconOutlined': Icons.send_rounded, 'iconFilled': Icons.send, 'label': 'Location'},
    {'index': 2, 'iconOutlined': Icons.chat_bubble_outline_rounded, 'iconFilled': Icons.chat_bubble, 'label': 'Chatbot'},
    {'index': 3, 'iconOutlined': Icons.face_outlined, 'iconFilled': Icons.face, 'label': 'Face Recog'},
    {'index': 4, 'iconOutlined': Icons.settings_outlined, 'iconFilled': Icons.settings, 'label': 'Settings'},
  ];

  late List<Widget> _pages;
  late List<Map<String, dynamic>> _finalNavItems;

  @override
  void initState() {
    super.initState();
    _filterPagesAndNav();
  }

  void _filterPagesAndNav() {
    if (widget.userModel == UserModel.patient) {
      // Patient: Reminders (0) and Chatbot (2) only
      List<int> allowedIndices = [0, 2];

      _pages = allowedIndices.map((i) => _allPages[i]).toList();
      // Set the correct UserModel for ReminderPage
      _pages[0] = ReminderPage(userModel: widget.userModel);

      _finalNavItems = _allNavItems.where((item) => allowedIndices.contains(item['index'])).toList();
    } else {
      // Caretaker: All pages
      _pages = _allPages;
      // Set the correct UserModel for ReminderPage
      _pages[0] = ReminderPage(userModel: widget.userModel);

      _finalNavItems = _allNavItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: orange,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r), topRight: Radius.circular(20.r)),
        ),
        child: GNav(
          selectedIndex: _selectedIndex,
          onTabChange: (i) {
            setState(() => _selectedIndex = i);
          },

          haptic: true,
          gap: 6,
          iconSize: 26,
          tabBorderRadius: 12,

          color: Colors.white70,
          activeColor: Colors.white,

          tabBackgroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          mainAxisAlignment: MainAxisAlignment.center,

          // Generate the final list of GButtons based on the filtered list
          tabs: _finalNavItems.asMap().entries.map((entry) {
            int i = entry.key; // The index in the new filtered list
            IconData iconFilled = entry.value['iconFilled'];
            IconData iconOutlined = entry.value['iconOutlined'];

            return GButton(
              // Use the new index 'i' for comparison to show the filled icon
              icon: _selectedIndex == i ? iconFilled : iconOutlined,
            );
          }).toList(),
        ),
      ),
    );
  }
}
