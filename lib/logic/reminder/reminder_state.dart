part of 'reminder_bloc.dart';

abstract class ReminderState {
  const ReminderState();
}

class ReminderInitial extends ReminderState {}

class ReminderLoading extends ReminderState {}

class RemindersLoaded extends ReminderState {
  final List<Reminder> reminders;
  final Reminder? upcomingReminder;

  const RemindersLoaded(this.reminders, this.upcomingReminder);
}

class ReminderError extends ReminderState {
  final String message;
  const ReminderError(this.message);
}

class ReminderAdded extends ReminderState {
  final String title;
  const ReminderAdded(this.title);
}