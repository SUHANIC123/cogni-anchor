import 'dart:convert';
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  static Future<String> sendTextMessage({
    required String patientId,
    required String pairId,
    required String message,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/agent/chat');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_id': patientId,
              'pair_id': pairId,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  static Future<Map<String, dynamic>> sendVoiceMessage({
    required String patientId,
    required List<int> audioBytes,
    required String filename,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/voice');
      var request = http.MultipartRequest('POST', url);

      request.fields['patient_id'] = patientId;
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'transcription': data['transcription'] as String,
          'response': data['response'] as String,
          'audio_url': data['audio_url'] as String?,
        };
      } else {
        throw Exception('Failed to process voice: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending voice message: $e');
    }
  }
}
