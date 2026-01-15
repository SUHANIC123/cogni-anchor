import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFF653A),
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
                    child: Icon(Icons.arrow_back, color: Color(0xFFFF653A)),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Terms and Conditions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1. General Usage\n\n"
                    "This application is designed to assist individuals living with dementia and their caregivers by providing tools for reminders, face recognition, and information management. Users must ensure that all information provided is accurate, complete, and kept up to date. The application should be used responsibly and only for its intended purpose.\n\n"
                    "2. User Responsibilities\n\n"
                    "Users are responsible for maintaining the confidentiality of their login credentials. Any activity performed through the user’s account will be considered the responsibility of the account holder. Caregivers must ensure that patient data entered into the system is done with consent and in the best interest of the patient.\n\n"
                    "3. Data Privacy and Security\n\n"
                    "We take data privacy seriously. All personal information is securely stored and encrypted. Data is shared only between paired users (patient and caregiver) and is not disclosed to third parties without consent, except where required by law. Despite our security measures, we cannot guarantee absolute protection against unauthorized access.\n\n"
                    "4. Medical Disclaimer\n\n"
                    "This application is not a medical device and does not provide medical advice, diagnosis, or treatment. The information and features offered are intended for assistance only and must not replace professional medical consultation or emergency services.\n\n"
                    "5. Limitations of Liability\n\n"
                    "The developers and service providers shall not be held liable for any direct, indirect, incidental, or consequential damages arising from the use or inability to use the application. This includes but is not limited to data loss, missed reminders, or incorrect identification.\n\n"
                    "6. Prohibited Activities\n\n"
                    "Users must not attempt to reverse engineer, modify, distribute, or misuse the application. Any unauthorized access, abuse of features, or violation of applicable laws may result in suspension or termination of the account.\n\n"
                    "7. Service Availability\n\n"
                    "We reserve the right to modify, suspend, or discontinue any part of the service at any time for maintenance, updates, or security reasons without prior notice.\n\n"
                    "8. Termination\n\n"
                    "Access to the application may be terminated if a user violates these terms or engages in unlawful or harmful activities. Upon termination, access to stored data may be restricted or removed.\n\n"
                    "9. Acceptance of Terms\n\n"
                    "By using this application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.\n",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Checkbox(
                  value: agreed,
                  onChanged: (value) {
                    setState(() {
                      agreed = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    "Yes, I agree to all the Terms and Conditions",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: agreed ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Accept and Continue",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
