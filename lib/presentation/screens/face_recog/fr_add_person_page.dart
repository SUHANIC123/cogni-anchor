import 'dart:convert';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/main.dart';
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart'; // For FRMainButton
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class FRAddPersonPage extends StatefulWidget {
  final File? initialImageFile;

  const FRAddPersonPage({super.key, this.initialImageFile});

  @override
  State<FRAddPersonPage> createState() => _FRAddPersonPageState();
}

class _FRAddPersonPageState extends State<FRAddPersonPage> {
  static const String _baseUrl = 'https://eaa9e7cf9c64.ngrok-free.app/api/v1/faces/enroll';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController(); // NEW CONTROLLER
  final TextEditingController _ageController = TextEditingController();        // NEW CONTROLLER
  final TextEditingController _notesController = TextEditingController();      // NEW CONTROLLER

  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  File? _capturedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _capturedImage = widget.initialImageFile;
    if (_capturedImage == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _captureImage() async {
    if (_capturedImage != null) {
      setState(() => _capturedImage = null);
      return;
    }

    if (!_isCameraInitialized) return;

    try {
      final xFile = await _cameraController.takePicture();
      setState(() {
        _capturedImage = File(xFile.path);
      });
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  Future<void> _enrollPerson() async {
    if (_nameController.text.isEmpty || _relationshipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Relationship are required.")));
      return;
    }

    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A face image must be captured.")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      request.fields['name'] = _nameController.text;
      request.fields['relationship'] = _relationshipController.text;
      request.fields['occupation'] = _occupationController.text; // NEW FIELD
      request.fields['age'] = _ageController.text;             // NEW FIELD
      request.fields['notes'] = _notesController.text;         // NEW FIELD

      request.files.add(await http.MultipartFile.fromPath('file', _capturedImage!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_nameController.text} enrolled successfully!")));
        Navigator.pop(context);
      } else {
        final errorDetail = response.body.contains("detail") ? (jsonDecode(response.body)['detail'] ?? "Unknown error") : "Failed to enroll person.";
        log("$errorDetail", name: "Error fr_add_person_page.dart");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enrollment failed: $errorDetail")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error: Could not connect to server.")));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    _nameController.dispose();
    _relationshipController.dispose();
    _occupationController.dispose(); // DISPOSE NEW CONTROLLER
    _ageController.dispose();        // DISPOSE NEW CONTROLLER
    _notesController.dispose();      // DISPOSE NEW CONTROLLER
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText("Add New Person", color: colors.appColor, fontWeight: FontWeight.w600, fontSize: 18.sp),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.appColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCaptureSection(),

            Gap(25.h),

            AppText("Person Details", fontSize: 16.sp, fontWeight: FontWeight.w600),
            Gap(15.h),
            _buildTextField("Full Name", _nameController),
            Gap(15.h),
            _buildTextField("Relationship (e.g., Father, Neighbor)", _relationshipController),
            Gap(15.h),
            _buildTextField("Occupation", _occupationController), // NEW FIELD
            Gap(15.h),
            _buildTextField("Age", _ageController),              // NEW FIELD
            Gap(15.h),
            _buildTextField("Notes", _notesController, maxLines: 3), // NEW FIELD

            Gap(40.h),

            _isSaving ? const Center(child: CircularProgressIndicator()) : FRMainButton(label: "Save and Enroll", onTap: _enrollPerson),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colors.appColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildImageCaptureSection() {
    final showCameraView = _capturedImage == null && _isCameraInitialized;
    double aspectRatio = _isCameraInitialized ? _cameraController.value.aspectRatio : 1.0;

    return Column(
      children: [
        Container(
          height: 400.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: colors.appColor, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: _capturedImage != null
                ? Image.file(_capturedImage!, fit: BoxFit.cover)
                : showCameraView
                ? SizedBox(
                    child: AspectRatio(aspectRatio: aspectRatio, child: CameraPreview(_cameraController)),
                  )
                : Center(child: AppText("Initializing Camera...", color: Colors.grey.shade600)),
          ),
        ),
        Gap(15.h),
        SizedBox(
          width: 150.w,
          child: ElevatedButton(
            onPressed: (_capturedImage != null || _isCameraInitialized) ? _captureImage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _capturedImage != null ? Colors.redAccent : colors.appColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
              elevation: 0,
            ),
            child: AppText(_capturedImage != null ? "Recapture" : "Capture Face", color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}