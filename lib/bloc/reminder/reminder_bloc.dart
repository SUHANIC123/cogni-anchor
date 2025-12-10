import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:cogni_anchor/data/http/reminder_http_services.dart';
import 'package:cogni_anchor/data/models/reminder_model.dart';
import 'package:intl/intl.dart'; // Import intl for DateFormat

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  static const String _nameTag = 'ReminderBloc';
  final ReminderHttpServices _httpServices = ReminderHttpServices();

  ReminderBloc() : super(ReminderInitial()) {
    log('Initialized.', name: _nameTag);
    on<LoadReminders>(_onLoadReminders);
    on<AddReminder>(_onAddReminder);
  }

  /// Helper to sort reminders by Date and Time ascending (Closest first)
  List<Reminder> _sortReminders(List<Reminder> reminders) {
    reminders.sort((a, b) {
      try {
        // Construct DateTime from the stored strings "dd MMM yyyy" and "hh:mm a"
        // Example: "17 Nov 2025 06:30 AM"
        DateFormat format = DateFormat("dd MMM yyyy hh:mm a");
        
        // Normalize strings to ensure spacing
        String dtStringA = "${a.date.trim()} ${a.time.trim()}";
        String dtStringB = "${b.date.trim()} ${b.time.trim()}";
        
        DateTime dtA = format.parse(dtStringA);
        DateTime dtB = format.parse(dtStringB);
        
        return dtA.compareTo(dtB);
      } catch (e) {
        log('Error parsing date for sorting: $e', name: _nameTag);
        return 0; // Keep original order if parsing fails
      }
    });
    return reminders;
  }

  Future<void> _onLoadReminders(LoadReminders event, Emitter<ReminderState> emit) async {
    log('Received LoadReminders event. Fetching reminders...', name: _nameTag);
    emit(ReminderLoading());
    try {
      List<Reminder> reminders = await _httpServices.getReminders();
      
      // SORT: Ensure the closest reminder is at index 0
      reminders = _sortReminders(reminders);

      // Determine upcoming reminder (closest one)
      Reminder? upcoming = reminders.isNotEmpty ? reminders.first : null;

      // Filter out the upcoming reminder from the main list so it doesn't appear twice
      final remainingReminders = reminders.where((r) => r != upcoming).toList();

      log('Successfully fetched and sorted ${reminders.length} reminders. Upcoming: ${upcoming?.title ?? 'None'}', name: _nameTag);
      emit(RemindersLoaded(remainingReminders, upcoming));
    } catch (e) {
      log('Error during LoadReminders: $e', name: _nameTag);
      emit(const ReminderError("Failed to fetch reminders."));
    }
  }

  Future<void> _onAddReminder(AddReminder event, Emitter<ReminderState> emit) async {
    final currentState = state;
    log('Received AddReminder event: ${event.reminder.title}', name: _nameTag);

    if (currentState is! ReminderLoading) {
      emit(ReminderLoading());
    }

    try {
      final response = await _httpServices.createReminder(event.reminder);

      if (response['success'] == true) {
        log('Reminder successfully created. Refreshing list.', name: _nameTag);
        emit(ReminderAdded(event.reminder.title));
        add(LoadReminders()); 
      } else {
        final errorMessage = response['error'] ?? "Failed to save reminder.";
        log('API failed to save reminder: $errorMessage', name: _nameTag);
        emit(ReminderError(errorMessage));

        if (currentState is RemindersLoaded) {
          emit(RemindersLoaded(currentState.reminders, currentState.upcomingReminder));
        }
      }
    } catch (e) {
      log('Network error during AddReminder: $e', name: _nameTag);
      emit(const ReminderError("Network error during reminder creation."));
      if (currentState is RemindersLoaded) {
        emit(RemindersLoaded(currentState.reminders, currentState.upcomingReminder));
      }
    }
  }
}