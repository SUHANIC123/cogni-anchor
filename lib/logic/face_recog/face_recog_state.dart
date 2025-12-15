part of 'face_recog_bloc.dart';

abstract class FaceRecogState {
  const FaceRecogState();
}

class FaceRecogInitial extends FaceRecogState {}

class FaceRecogLoading extends FaceRecogState {
  final String message;
  const FaceRecogLoading(this.message);
}

class EnrollmentSuccess extends FaceRecogState {
  final String name;
  const EnrollmentSuccess(this.name);
}

class EnrollmentError extends FaceRecogState {
  final String message;
  const EnrollmentError(this.message);
}

class ScanSuccess extends FaceRecogState {
  final RecognizedPerson person;
  const ScanSuccess(this.person);
}

class ScanNoMatch extends FaceRecogState {}

class ScanError extends FaceRecogState {
  final String message;
  const ScanError(this.message);
}