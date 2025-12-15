import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cogni_anchor/data/http/face_recog_http_services.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';

part 'face_recog_event.dart';
part 'face_recog_state.dart';

class FaceRecogBloc extends Bloc<FaceRecogEvent, FaceRecogState> {
  final FaceRecogHttpServices _httpServices = FaceRecogHttpServices();

  FaceRecogBloc() : super(FaceRecogInitial()) {
    on<EnrollPerson>(_onEnrollPerson);
    on<ScanFace>(_onScanFace);
  }

  Future<void> _onEnrollPerson(EnrollPerson event, Emitter<FaceRecogState> emit) async {
    emit(const FaceRecogLoading("Enrolling person..."));
    try {
      final result = await _httpServices.enrollPerson(
        name: event.name,
        relationship: event.relationship,
        occupation: event.occupation,
        age: event.age,
        notes: event.notes,
        imageFile: event.imageFile,
      );

      if (result['success'] == true) {
        emit(EnrollmentSuccess(event.name));
      } else {
        emit(EnrollmentError(result['error'] ?? "Enrollment failed."));
      }
    } catch (e) {
      emit(const EnrollmentError("Network error during enrollment."));
    }
  }

  Future<void> _onScanFace(ScanFace event, Emitter<FaceRecogState> emit) async {
    emit(const FaceRecogLoading("Scanning face..."));
    try {
      final result = await _httpServices.recognizeFace(event.imageFile);

      if (result['matchFound'] == true) {
        emit(ScanSuccess(result['person'] as RecognizedPerson));
      } else if (result['matchFound'] == false) {
        emit(ScanNoMatch());
      } else {
        emit(ScanError(result['error'] ?? "Scan failed."));
      }
    } catch (e) {
      emit(const ScanError("Network error during scanning."));
    }
  }
}