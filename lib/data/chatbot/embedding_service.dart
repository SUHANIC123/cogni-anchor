import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  static final EmbeddingService instance = EmbeddingService._internal();
  Interpreter? _interpreter;

  EmbeddingService._internal();

  Future<void> loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
      print(" MobileFaceNet model loaded!");
    } catch (e) {
      print(" Failed to load model: $e");
    }
  }

  Future<List<double>> getEmbedding(Uint8List imageBytes) async {
    if (_interpreter == null) {
      throw Exception("Interpreter not loaded. Call loadModel() first.");
    }

    final image = img.decodeImage(imageBytes)!;
    final resized = img.copyResize(image, width: 112, height: 112);

    final input = List.generate(
      112,
      (y) => List.generate(112, (x) {
        final pixel = resized.getPixel(x, y);
        return [
          (pixel.r - 127.5) / 128.0,
          (pixel.g - 127.5) / 128.0,
          (pixel.b - 127.5) / 128.0,
        ];
      }),
    );

    final output = List.filled(192, 0.0).reshape([1, 192]);

    _interpreter!.run([input], output);

    return List<double>.from(output[0]);
  }
}
