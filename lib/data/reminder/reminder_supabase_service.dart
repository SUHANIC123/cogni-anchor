import 'package:cogni_anchor/data/reminder/reminder_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderSupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Reminder>> getReminders(String pairId) async {
    final response = await _client
        .from('reminders')
        .select()
        .eq('pair_id', pairId)
        .order('date', ascending: true)
        .order('time', ascending: true);

    return (response as List).map((json) => Reminder.fromJson(json)).toList();
  }

  Future<void> createReminder({
    required Reminder reminder,
    required String pairId,
  }) async {
    await _client.from('reminders').insert({
      'title': reminder.title,
      'date': reminder.date,
      'time': reminder.time,
      'pair_id': pairId,
    });
  }

  Future<void> deleteReminder(String reminderId) async {
    final id = int.parse(reminderId);

    await _client.from('reminders').delete().eq('id', id);
  }
}
