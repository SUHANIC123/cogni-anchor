import 'dart:typed_data';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/core/config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FREditPersonFullPage extends StatefulWidget {
  final Map<String, dynamic> person;
  const FREditPersonFullPage({super.key, required this.person});
  @override
  State<FREditPersonFullPage> createState() => _FREditPersonFullPageState();
}

class _FREditPersonFullPageState extends State<FREditPersonFullPage> {
  late TextEditingController nameController;
  late TextEditingController relController;
  late TextEditingController occController;
  late TextEditingController ageController;
  late TextEditingController notesController;
  Uint8List? pickedBytes;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    nameController = TextEditingController(text: p['name']);
    relController = TextEditingController(text: p['relationship']);
    occController = TextEditingController(text: p['occupation']);
    ageController = TextEditingController(text: p['age']?.toString() ?? '');
    notesController = TextEditingController(text: p['notes'] ?? '');
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (picked != null) {
      pickedBytes = await picked.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      // final ok = await ApiService.updatePerson(
      //   personId: widget.person['id'].toString(),
      //   imageBytes: pickedBytes,
      //   name: nameController.text.trim(),
      //   relationship: relController.text.trim(),
      //   occupation: occController.text.trim(),
      //   age: int.tryParse(ageController.text.trim()) ?? 0,
      //   notes: notesController.text.trim(),
      // );
      // if (ok && mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved changes")));
      //   Navigator.pop(context, true);
      // } else if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Save failed")));
      // }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Save error")));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Person?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => saving = true);
    try {
      final ok = await ApiService.deletePerson(widget.person['id'].toString());
      if (ok && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete error")));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    relController.dispose();
    occController.dispose();
    ageController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? rawUrl = widget.person['image_url'];
    final String fullUrl = (rawUrl != null && rawUrl.startsWith('/')) ? "${ApiConfig.baseUrl}$rawUrl" : (rawUrl ?? '');

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(22))),
        title: const Text("Edit Person", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.w),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: pickedBytes != null
                    ? Image.memory(pickedBytes!, width: 180.w, height: 180.w, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: fullUrl,
                        width: 180.w,
                        height: 180.w,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.person, size: 50, color: Colors.grey))),
              ),
            ),
            SizedBox(height: 14.h),
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo_library), label: const Text("Change photo")),
            SizedBox(height: 14.h),
            _buildField("Full name", nameController),
            SizedBox(height: 12.h),
            _buildField("Relationship", relController),
            SizedBox(height: 12.h),
            _buildField("Occupation", occController),
            SizedBox(height: 12.h),
            _buildField("Age", ageController, keyboardType: TextInputType.number),
            SizedBox(height: 12.h),
            _buildField("Notes", notesController, maxLines: 3),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size(double.infinity, 48.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: saving ? const CircularProgressIndicator(color: Colors.white) : Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: saving ? null : _delete,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text("Delete Person", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController c, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)), contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h)),
    );
  }
}
