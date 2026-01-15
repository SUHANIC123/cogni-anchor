import 'dart:convert';
import 'package:cogni_anchor/data/reminder/reminder_model.dart';
import 'package:http/http.dart' as http;
import 'package:cogni_anchor/data/core/config/api_config.dart';


class ReminderApiService {
  // GET /api/v1/reminders/{pair_id}
  Future<List<Reminder>> getReminders(String pairId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/reminders/$pairId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> remindersJson = data['reminders'];

        return remindersJson.map((json) => Reminder.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reminders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reminders: $e');
    }
  }

  // POST /api/v1/reminders/
  Future<Reminder> createReminder({
    required Reminder reminder,
    required String pairId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/reminders/');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pair_id': pairId,
          'title': reminder.title,
          'date': reminder.date,
          'time': reminder.time,
        }),
      );

      if (response.statusCode == 201) {
        return Reminder.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create reminder: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating reminder: $e');
    }
  }

  // DELETE /api/v1/reminders/{reminder_id}
  Future<void> deleteReminder(String reminderId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/reminders/$reminderId');

    try {
      final response = await http.delete(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete reminder: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting reminder: $e');
    }
  }
}
