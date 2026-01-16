import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsConditionsScreen extends StatefulWidget {
  final VoidCallback? onAccept; // Callback for Onboarding flow
  final bool showHeader; // Toggle header for different use cases

  const TermsConditionsScreen({super.key, this.onAccept, this.showHeader = true});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          if (widget.showHeader) _buildHeader(),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1. General Usage\n\n"
                    "This application is designed to assist individuals living with dementia and their caregivers. Users must ensure that all information provided is accurate and up to date.\n\n"
                    "2. User Responsibilities\n\n"
                    "Users are responsible for maintaining the confidentiality of their login credentials. Caregivers must ensure that patient data entered into the system is done with consent.\n\n"
                    "3. Data Privacy and Security\n\n"
                    "Personal information is securely stored and encrypted. Data is shared only between paired users (patient and caregiver).\n\n"
                    "4. Medical Disclaimer\n\n"
                    "This application is not a medical device and does not provide medical advice or diagnosis. It is intended for assistance only.\n\n"
                    "5. Limitations of Liability\n\n"
                    "Developers shall not be held liable for any damages arising from the use of the application, including data loss or missed reminders.\n\n"
                    "9. Acceptance of Terms\n\n"
                    "By using this application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.\n",
                    style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          _buildAgreementSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              "Terms and Conditions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      );

  Widget _buildAgreementSection() => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: agreed,
                  activeColor: AppColors.primary,
                  onChanged: (value) => setState(() => agreed = value ?? false),
                ),
                const Expanded(
                  child: Text("Yes, I agree to all the Terms and Conditions", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: agreed ? widget.onAccept ?? () => Navigator.pop(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: agreed ? AppColors.primary : Colors.grey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Accept and Continue",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
}