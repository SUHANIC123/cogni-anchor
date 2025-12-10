part of 'face_recog_bloc.dart';

abstract class FaceRecogEvent {
  const FaceRecogEvent();
}

class EnrollPerson extends FaceRecogEvent {
  final String name;
  final String relationship;
  final String occupation;
  final String age;
  final String notes;
  final File imageFile;

  const EnrollPerson({
    required this.name,
    required this.relationship,
    required this.occupation,
    required this.age,
    required this.notes,
    required this.imageFile,
  });
}

class ScanFace extends FaceRecogEvent {
  final File imageFile;
  const ScanFace(this.imageFile);
}