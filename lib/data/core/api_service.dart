import 'dart:convert';
import 'dart:typed_data';
import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get _pairId => PairContext.require;

  // ===== USER PROFILE ENDPOINTS =====
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    // Matches @router.get("/users/{user_id}") in backend users_pairs.py
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/users/users/$userId");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to fetch profile: ${response.body}");
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/users/users/$userId");
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update profile: ${response.body}");
    }
  }

  static Future<void> changePassword(String userId, String currentPass, String newPass) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/users/users/$userId/password");
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "current_password": currentPass,
        "new_password": newPass,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'] ?? "Failed to change password";
      throw Exception(error);
    }
  }

  // ===== PAIR ENDPOINTS =====

  // FIX: Added missing getPairInfo method
  static Future<Map<String, dynamic>> getPairInfo(String pairId) async {
    // Matches @router.get("/pairs/{pair_id}") in backend users_pairs.py
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/pairs/$pairId");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to fetch pair info: ${response.body}");
  }

  // ===== FACE RECOGNITION ENDPOINTS =====
  // Matches prefix="/api/v1/face" in face_recognition.py
  static Future<List<dynamic>> getPeople() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/face/getPeople?pair_id=$_pairId");
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["people"] ?? [];
    } else {
      throw Exception("Failed to fetch people: ${res.body}");
    }
  }

  static Future<bool> addPerson({
    required Uint8List imageBytes,
    required String name,
    required String relationship,
    required String occupation,
    required int age,
    String? notes,
    required List<double> embedding,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/face/addPerson");
    final request = http.MultipartRequest('POST', uri);

    request.fields['pair_id'] = _pairId;
    request.fields['name'] = name;
    request.fields['relationship'] = relationship;
    request.fields['occupation'] = occupation;
    request.fields['age'] = age.toString();
    request.fields['notes'] = notes ?? '';
    request.fields['embedding'] = jsonEncode(embedding);

    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: 'face.jpg'),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  static Future<bool> updatePerson({
    required String personId,
    Uint8List? imageBytes,
    String? name,
    String? relationship,
    String? occupation,
    int? age,
    String? notes,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/face/updatePerson");
    final request = http.MultipartRequest('PUT', uri);

    request.fields['person_id'] = personId;
    if (name != null) request.fields['name'] = name;
    if (relationship != null) request.fields['relationship'] = relationship;
    if (occupation != null) request.fields['occupation'] = occupation;
    if (age != null) request.fields['age'] = age.toString();
    if (notes != null) request.fields['notes'] = notes;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: 'update_face.jpg'),
      );
    }

    final streamed = await request.send();
    return streamed.statusCode == 200;
  }

  static Future<Map<String, dynamic>> scanPerson({required List<double> embedding}) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/face/scan");
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pair_id': _pairId,
        'embedding': embedding,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception("Scan failed: ${res.body}");
    }
  }

  static Future<bool> deletePerson(String personId) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/face/deletePerson?person_id=$personId");
    final res = await http.delete(uri);
    return res.statusCode == 200;
  }

  // ===== PATIENT STATUS ENDPOINTS =====
  // Matches prefix="/api/v1/patient" in patient_features.py
  static Future<void> updatePatientStatus({
    bool? locationToggle,
    bool? micToggle,
    bool? locationPermission,
    bool? micPermission,
    bool? isLoggedIn,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/patient/status?user_id=$userId");

    final body = <String, dynamic>{};
    if (locationToggle != null) body['location_toggle_on'] = locationToggle;
    if (micToggle != null) body['mic_toggle_on'] = micToggle;
    if (locationPermission != null) body['location_permission'] = locationPermission;
    if (micPermission != null) body['mic_permission'] = micPermission;
    if (isLoggedIn != null) body['is_logged_in'] = isLoggedIn;

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update status");
    }
  }

  static Future<Map<String, dynamic>> getPatientStatus(String userId) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/patient/status/$userId");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to fetch status");
  }

  static Future<void> updateFCMToken(String token) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/v1/users/users/fcm-token?user_id=$userId");
    try {
      await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (e) {
      print("Error updating token: $e");
    }
  }
}
