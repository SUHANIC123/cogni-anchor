part of 'reminder_bloc.dart';

abstract class ReminderEvent {
  const ReminderEvent();
}

class LoadReminders extends ReminderEvent {}

class InitializeReminderWebSocket extends ReminderEvent {}

class AddReminder extends ReminderEvent {
  final Reminder reminder;
  const AddReminder(this.reminder);
}

class DeleteReminder extends ReminderEvent {
  final Reminder reminder;

  const DeleteReminder(this.reminder);
}
