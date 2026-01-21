import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsConditionsScreen extends StatefulWidget {
  final VoidCallback? onAccept;
  final bool showHeader;

  const TermsConditionsScreen({
    super.key,
    this.onAccept,
    this.showHeader = true,
  });

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool agreed = false;

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse("${ApiConfig.baseUrl}/privacy");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch $url")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        leading: widget.showHeader
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          "Terms & Privacy Policy",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Privacy Policy",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        const Text(
                          "We collect location, audio, and face data solely for patient safety. Read our full policy at:",
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        SizedBox(height: 4.h),
                        GestureDetector(
                          onTap: _launchPrivacyPolicy,
                          child: Text(
                            "${ApiConfig.baseUrl}/privacy",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  const Text(
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
                    "6. Acceptance of Terms\n\n"
                    "By using this application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.\n",
                    style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          _buildAgreementSection(),
        ],
      ),
    );
  }

  Widget _buildAgreementSection() => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
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
                  child: Text(
                    "Yes, I agree to all the Terms and Conditions",
                    style: TextStyle(fontSize: 13),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Accept and Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
