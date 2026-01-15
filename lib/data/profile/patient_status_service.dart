import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientStatusService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> markLoggedIn() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    developer.log('Marking patient as logged in: ${user.id}', name: 'PatientStatusService');
    await _client.from('patient_status').upsert({
      'patient_user_id': user.id,
      'is_logged_in': true,
      'last_active_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateLastActive() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('patient_status').update({
      'last_active_at': DateTime.now().toIso8601String(),
    }).eq('patient_user_id', user.id);
  }

  static Future<void> markLoggedOut() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    developer.log('Marking patient as logged out: ${user.id}', name: 'PatientStatusService');
    await _client.from('patient_status').update({
      'is_logged_in': false,
      'last_active_at': DateTime.now().toIso8601String(),
    }).eq('patient_user_id', user.id);
  }
}
