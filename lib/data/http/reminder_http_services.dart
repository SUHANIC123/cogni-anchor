import 'dart:convert';
import 'package:cogni_anchor/data/http/base_http_service.dart';
import 'package:cogni_anchor/data/models/reminder_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ReminderHttpServices {
  static final String _baseUrl = BaseHttpService.baseUrl;

  /// Creates a new reminder.
  Future<Map<String, dynamic>> createReminder(Reminder reminder) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reminders/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': reminder.title,
          'date': reminder.date, // e.g., '17 Nov 2025'
          'time': reminder.time, // e.g., '06:30 AM'
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorDetail = jsonDecode(response.body)['detail'] ?? "Unknown error during reminder creation.";
        return {'success': false, 'error': errorDetail};
      }
    } catch (e) {
      debugPrint("Network/Create Reminder Error: $e");
      return {'success': false, 'error': 'Network error: Could not connect to server.'};
    }
  }

  /// Fetches all future reminders.
  Future<List<Reminder>> getReminders() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/reminders/get'));

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Reminder.fromJson(json)).toList();
      } else {
        debugPrint("API Error: ${response.statusCode}, Body: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Network/Get Reminders Error: $e");
      return [];
    }
  }
}