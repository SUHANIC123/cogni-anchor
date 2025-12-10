part of 'reminder_bloc.dart';

abstract class ReminderEvent {
  const ReminderEvent();
}

class LoadReminders extends ReminderEvent {}

class AddReminder extends ReminderEvent {
  final Reminder reminder;
  const AddReminder(this.reminder);
}