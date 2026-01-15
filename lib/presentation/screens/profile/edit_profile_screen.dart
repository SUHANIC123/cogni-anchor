import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:flutter/material.dart';
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

      _nameController.text = data['name'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _gender = data['gender'];
      _dob = data['date_of_birth'] != null
          ? DateTime.parse(data['date_of_birth'])
          : null;

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      _showMsg("Failed to load profile");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showMsg("Name cannot be empty");
      return;
    }

    setState(() => _saving = true);

    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await ApiService.updateUserProfile(user.id, {
          'name': _nameController.text.trim(),
          'contact': _contactController.text.trim(),
          'gender': _gender,
          'date_of_birth': _dob?.toIso8601String(),
        });
        
        if (mounted) {
          _showMsg("Profile updated successfully");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showMsg("Update failed: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field("Name", _nameController),
                      _field("Contact", _contactController,
                          keyboard: TextInputType.phone),
                      _genderDropdown(),
                      _dobPicker(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const CircularProgressIndicator()
                              : const Text(
                                  "Save",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFF653A),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text(
              "Edit Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _field(String label, TextEditingController controller,
          {TextInputType keyboard = TextInputType.text}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 52,
            decoration: _box(),
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );

  Widget _genderDropdown() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gender"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _box(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _gender,
                hint: const Text("Select"),
                isExpanded: true,
                items: ['Male', 'Female', 'Other']
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );

  Widget _dobPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Date of Birth"),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: _box(),
              alignment: Alignment.centerLeft,
              child: Text(
                _dob == null
                    ? "Select date"
                    : DateFormat('dd MMM yyyy').format(_dob!),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      );
}