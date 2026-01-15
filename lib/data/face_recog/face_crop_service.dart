import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class FaceCropService {
  static final FaceCropService instance = FaceCropService._internal();
  FaceCropService._internal();

  Future<File?> detectAndCropFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableLandmarks: false,
      ),
    );

    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      print(" No face detected.");
      return null;
    }

    final face = faces.first;
    final box = face.boundingBox;

    final bytes = await imageFile.readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) return null;

    int left = box.left.toInt();
    int top = box.top.toInt();
    int width = box.width.toInt();
    int height = box.height.toInt();

    img.Image cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    final dir = await getTemporaryDirectory();
    final outFile = File("${dir.path}/cropped_face.png")
      ..writeAsBytesSync(img.encodePng(cropped));

    print(" Face cropped: ${outFile.path}");
    return outFile;
  }
}
