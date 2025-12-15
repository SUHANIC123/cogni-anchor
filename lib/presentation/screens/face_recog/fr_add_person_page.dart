import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cogni_anchor/logic/face_recog/face_recog_bloc.dart';
// Removed unused import: import 'package:cogni_anchor/main.dart';
import 'package:cogni_anchor/presentation/constants/colors.dart' as colors;
import 'package:cogni_anchor/presentation/widgets/common/app_text.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

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
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _capturedImage = widget.initialImageFile;
    if (_capturedImage == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // FIX: Renamed local variable to 'camerasList' and ensure await is used.
    final List<CameraDescription> camerasList = await availableCameras();

    // Find the front camera or fallback to the first camera
    final frontCamera = camerasList.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => camerasList.first
    );

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
    // If an image exists, treat the tap as a Recapture (clear the current image)
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

  void _enrollPerson() {
    if (_nameController.text.isEmpty || _relationshipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Relationship are required.")));
      return;
    }
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A face image must be captured.")));
      return;
    }

    // Dispatch EnrollPerson event (BLoC connection preserved)
    context.read<FaceRecogBloc>().add(
      EnrollPerson(
        name: _nameController.text,
        relationship: _relationshipController.text,
        occupation: _occupationController.text,
        age: _ageController.text,
        notes: _notesController.text,
        imageFile: _capturedImage!,
      ),
    );
  }

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    _nameController.dispose();
    _relationshipController.dispose();
    _occupationController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FaceRecogBloc, FaceRecogState>(
      listener: (context, state) {
        if (state is EnrollmentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${state.name} enrolled!")));
          Navigator.pop(context);
        } else if (state is EnrollmentError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        bool isLoading = state is FaceRecogLoading;

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
                _buildTextField("Occupation", _occupationController),
                Gap(15.h),
                _buildTextField("Age", _ageController),
                Gap(15.h),
                _buildTextField("Notes", _notesController, maxLines: 3),

                Gap(40.h),

                // Button tied to BLoC loading state
                isLoading ? const Center(child: CircularProgressIndicator()) : FRMainButton(label: "Save and Enroll", onTap: _enrollPerson),
              ],
            ),
          ),
        );
      },
    );
  }
}