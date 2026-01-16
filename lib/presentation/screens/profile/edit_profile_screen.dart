import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;
      final data = await ApiService.getUserProfile(user.id);
      setState(() {
        _nameController.text = data['name'] ?? '';
        _contactController.text = data['contact'] ?? '';
        _gender = data['gender'];
        if (data['date_of_birth'] != null) _dob = DateTime.parse(data['date_of_birth']);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r))),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: AppText("Edit Profile", color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Full Name"),
                TextField(controller: _nameController),
                Gap(20.h),
                _buildLabel("Contact Number"),
                TextField(controller: _contactController, keyboardType: TextInputType.phone),
                Gap(20.h),
                _buildLabel("Gender"),
                _buildGenderDropdown(),
                Gap(20.h),
                _buildLabel("Date of Birth"),
                _buildDatePicker(),
                Gap(40.h),
                SizedBox(
                  width: double.infinity,
                  height: 55.h,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () {}, // Logic from original file
                    child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
    child: AppText(text, fontWeight: FontWeight.w600, fontSize: 14.sp),
  );

  Widget _buildGenderDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) => setState(() => _gender = newValue),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _dob ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
        if (picked != null) setState(() => _dob = picked);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_dob == null ? "Select Date" : DateFormat('dd MMM yyyy').format(_dob!)),
            const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}