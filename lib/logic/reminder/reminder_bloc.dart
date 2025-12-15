import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:cogni_anchor/data/http/reminder_http_services.dart';
import 'package:cogni_anchor/data/models/reminder_model.dart';
import 'package:cogni_anchor/data/notification_service.dart'; // NEW IMPORT
import 'package:intl/intl.dart'; 

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  static const String _nameTag = 'ReminderBloc';
  final ReminderHttpServices _httpServices = ReminderHttpServices();
  final NotificationService _notificationService = NotificationService(); // NEW SERVICE

  ReminderBloc() : super(ReminderInitial()) {
    log('Initialized.', name: _nameTag);
    on<LoadReminders>(_onLoadReminders);
    on<AddReminder>(_onAddReminder);
  }

  /// Helper to parse "dd MMM yyyy" and "hh:mm a" into DateTime
  DateTime? _parseDateTime(String dateStr, String timeStr) {
    try {
      DateFormat format = DateFormat("dd MMM yyyy hh:mm a");
      String combined = "${dateStr.trim()} ${timeStr.trim()}";
      return format.parse(combined);
    } catch (e) {
      log('Error parsing date: $e', name: _nameTag);
      return null;
    }
  }

  /// Helper to sort reminders
  List<Reminder> _sortReminders(List<Reminder> reminders) {
    reminders.sort((a, b) {
      DateTime? dtA = _parseDateTime(a.date, a.time);
      DateTime? dtB = _parseDateTime(b.date, b.time);
      if (dtA == null || dtB == null) return 0;
      return dtA.compareTo(dtB);
    });
    return reminders;
  }

  Future<void> _onLoadReminders(LoadReminders event, Emitter<ReminderState> emit) async {
    log('Received LoadReminders event.', name: _nameTag);
    emit(ReminderLoading());
    try {
      List<Reminder> reminders = await _httpServices.getReminders();
      
      // 1. Sort Reminders
      reminders = _sortReminders(reminders);

      // 2. Schedule Notifications for all valid future reminders
      await _notificationService.cancelAll(); // Clear old alarms
      
      for (var reminder in reminders) {
        if (reminder.id != null) {
          final dt = _parseDateTime(reminder.date, reminder.time);
          
          // Schedule only if time is in the future
          if (dt != null && dt.isAfter(DateTime.now())) {
            await _notificationService.scheduleNotification(
              id: reminder.id!,
              title: "Do Now: ${reminder.title}",
              body: "It is time for your task.",
              scheduledDate: dt,
            );
          }
        }
      }

      // 3. Separate Upcoming from List
      Reminder? upcoming = reminders.isNotEmpty ? reminders.first : null;
      final remainingReminders = reminders.where((r) => r != upcoming).toList();

      emit(RemindersLoaded(remainingReminders, upcoming));
    } catch (e) {
      log('Error during LoadReminders: $e', name: _nameTag);
      emit(const ReminderError("Failed to fetch reminders."));
    }
  }

  Future<void> _onAddReminder(AddReminder event, Emitter<ReminderState> emit) async {
    // Keep existing logic exactly as is, it triggers LoadReminders at the end
    final currentState = state;
    if (currentState is! ReminderLoading) emit(ReminderLoading());

    try {
      final response = await _httpServices.createReminder(event.reminder);

      if (response['success'] == true) {
        emit(ReminderAdded(event.reminder.title));
        add(LoadReminders()); // This will trigger the new scheduling logic above
      } else {
        final errorMessage = response['error'] ?? "Failed to save reminder.";
        emit(ReminderError(errorMessage));
        if (currentState is RemindersLoaded) {
          emit(RemindersLoaded(currentState.reminders, currentState.upcomingReminder));
        }
      }
    } catch (e) {
      emit(const ReminderError("Network error during reminder creation."));
      if (currentState is RemindersLoaded) {
        emit(RemindersLoaded(currentState.reminders, currentState.upcomingReminder));
      }
    }
  }
}