import 'dart:convert';
import 'dart:io';
import 'package:cogni_anchor/data/http/base_http_service.dart';
import 'package:cogni_anchor/presentation/widgets/face_recog/fr_components.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FaceRecogHttpServices {
  static final String _baseUrl = BaseHttpService.baseUrl;

  /// Enrolls a new person's face into the database.
  Future<Map<String, dynamic>> enrollPerson({
    required String name,
    required String relationship,
    required String occupation,
    required String age,
    required String notes,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/faces/enroll'));

      request.fields['name'] = name;
      request.fields['relationship'] = relationship;
      request.fields['occupation'] = occupation;
      request.fields['age'] = age;
      request.fields['notes'] = notes;

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorDetail = response.body.contains("detail") ? (jsonDecode(response.body)['detail'] ?? "Unknown enrollment error") : "Failed to enroll person.";
        return {'success': false, 'error': errorDetail};
      }
    } catch (e) {
      debugPrint("Network/Enrollment Error: $e");
      return {'success': false, 'error': 'Network error: Could not connect to server.'};
    }
  }

  /// Attempts to recognize a face from an image.
  Future<Map<String, dynamic>> recognizeFace(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/faces/recognize'));
      request.files.add(http.MultipartFile.fromBytes('file', await imageFile.readAsBytes(), filename: 'scan_image.jpg'));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final matchFound = jsonResponse['match_found'] as bool;

        if (matchFound) {
          final person = RecognizedPerson(
            name: jsonResponse['person_name'] ?? 'Unknown',
            relationship: jsonResponse['relationship'] ?? 'N/A',
            occupation: jsonResponse['occupation'] ?? 'N/A',
            age: jsonResponse['age'] ?? 'N/A',
            notes: jsonResponse['notes'] ?? 'None provided',
          );
          return {'matchFound': true, 'person': person};
        } else {
          return {'matchFound': false};
        }
      } else {
        debugPrint("API Error: ${response.statusCode}, Body: ${response.body}");
        return {'matchFound': false, 'error': 'Recognition API failed: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint("Network/Recognition Error: $e");
      return {'matchFound': false, 'error': 'Network error: Could not connect to server.'};
    }
  }
}