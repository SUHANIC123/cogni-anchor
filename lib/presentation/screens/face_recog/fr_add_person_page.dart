import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/data/chatbot/embedding_service.dart';
import 'package:cogni_anchor/data/core/api_service.dart';
import 'package:cogni_anchor/data/face_recog/camera_store.dart';
import 'package:cogni_anchor/data/face_recog/face_crop_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class FRAddPersonPage extends StatefulWidget {
  final File? initialImageFile;
  const FRAddPersonPage({super.key, this.initialImageFile});
  @override
  State<FRAddPersonPage> createState() => _FRAddPersonPageState();
}

class _FRAddPersonPageState extends State<FRAddPersonPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isSaving = false;
  File? _capturedImage;
  CameraDescription? _currentCamera;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _capturedImage = widget.initialImageFile;
    if (_capturedImage == null) _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _currentCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
    _cameraController = CameraController(_currentCamera!, ResolutionPreset.medium, enableAudio: false);
    try {
      await _cameraController.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) { debugPrint("Camera error: $e"); }
  }

  Future<void> _flipCamera() async {
    _isFrontCamera = !_isFrontCamera;
    _currentCamera = cameras.firstWhere((c) => c.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back), orElse: () => cameras.first);
    await _cameraController.dispose();
    _cameraController = CameraController(_currentCamera!, ResolutionPreset.medium, enableAudio: false);
    try {
      await _cameraController.initialize();
      if (mounted) setState(() {});
    } catch (e) { debugPrint("Flip error: $e"); }
  }

  Future<void> _pickFromGallery() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _capturedImage = File(img.path));
  }

  Future<void> _captureImage() async {
    if (_capturedImage != null) { setState(() => _capturedImage = null); return; }
    if (!_isCameraInitialized) return;
    try {
      final xFile = await _cameraController.takePicture();
      setState(() => _capturedImage = File(xFile.path));
    } catch (e) { debugPrint("Capture error: $e"); }
  }

  Future<void> _enrollPerson() async {
    if (_capturedImage == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image and Name required")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final cropped = await FaceCropService.instance.detectAndCropFace(_capturedImage!);
      if (cropped == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No face detected")));
        return;
      }
      final bytes = await cropped.readAsBytes();
      final embedding = await EmbeddingService.instance.getEmbedding(bytes);
      final success = await ApiService.addPerson(
        imageBytes: bytes,
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        occupation: _occupationController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        notes: _notesController.text.trim(),
        embedding: embedding,
      );
      if (success && mounted) Navigator.pop(context);
    } catch (e) { debugPrint("Enroll error: $e"); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) _cameraController.dispose();
    _nameController.dispose(); _relationshipController.dispose(); _occupationController.dispose(); _ageController.dispose(); _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showCamera = _capturedImage == null && _isCameraInitialized;
    return Scaffold(
      appBar: AppBar(
        title: AppText("Add New Person", color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 18.sp),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              height: 400.h,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.primary, width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: _capturedImage != null
                    ? Image.file(_capturedImage!, fit: BoxFit.cover)
                    : showCamera ? CameraPreview(_cameraController) : const Center(child: Text("Initializing...")),
              ),
            ),
            Gap(12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _smallButton(Icons.cameraswitch, _flipCamera),
                _smallButton(Icons.photo_library, _pickFromGallery),
                _smallButton(_capturedImage != null ? Icons.refresh : Icons.camera, _captureImage),
              ],
            ),
            Gap(25.h),
            AppText("Person Details", fontSize: 16.sp, fontWeight: FontWeight.w600),
            Gap(15.h),
            _buildTF("Full Name", _nameController),
            Gap(15.h),
            _buildTF("Relationship", _relationshipController),
            Gap(15.h),
            _buildTF("Occupation", _occupationController),
            Gap(15.h),
            _buildTF("Age", _ageController),
            Gap(15.h),
            _buildTF("Notes", _notesController, maxLines: 3),
            Gap(40.h),
            _isSaving ? const CircularProgressIndicator() : FRMainButton(label: "Save and Enroll", onTap: _enrollPerson),
          ],
        ),
      ),
    );
  }

  Widget _buildTF(String hint, TextEditingController c, {int maxLines = 1}) {
    return TextField(
      controller: c, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))),
    );
  }

  Widget _smallButton(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: CircleAvatar(radius: 25, backgroundColor: AppColors.primary, child: Icon(icon, color: Colors.white)));
  }
}