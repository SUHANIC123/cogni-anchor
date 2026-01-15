import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';
import 'package:cogni_anchor/data/reminder/reminder_api_service.dart';
import 'package:cogni_anchor/data/reminder/reminder_model.dart';

import 'package:intl/intl.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  static const String _nameTag = 'ReminderBloc';

  final ReminderApiService _apiService = ReminderApiService();
  WebSocketChannel? _wsChannel;

  ReminderBloc() : super(ReminderInitial()) {
    on<LoadReminders>(_onLoadReminders);
    on<AddReminder>(_onAddReminder);
    on<DeleteReminder>(_onDeleteReminder);
    on<InitializeReminderWebSocket>(_onInitWebSocket);
  }

  String? _getPairId() {
    return PairContext.pairId;
  }

  @override
  Future<void> close() {
    _wsChannel?.sink.close();
    return super.close();
  }

  Future<void> _onInitWebSocket(
    InitializeReminderWebSocket event,
    Emitter<ReminderState> emit,
  ) async {
    final pairId = _getPairId();
    if (pairId == null) return;

    if (_wsChannel != null) {
      await _wsChannel!.sink.close();
    }

    try {
      String baseUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = '$baseUrl/api/v1/reminders/ws/$pairId';

      log("Connecting to Reminder WS: $wsUrl", name: _nameTag);
      _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

      _wsChannel!.stream.listen((message) {
        log("Reminder WS Event: $message", name: _nameTag);
        add(LoadReminders());
      }, onError: (e) {
        log("Reminder WS Error: $e", name: _nameTag);
      });
    } catch (e) {
      log("Reminder WS Connect Fail: $e", name: _nameTag);
    }
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<ReminderState> emit,
  ) async {
    if (_wsChannel == null) {
      add(InitializeReminderWebSocket());
    }

    emit(ReminderLoading());

    try {
      final pairId = _getPairId();
      if (pairId == null) {
        emit(const RemindersLoaded([], null));
        return;
      }

      final reminders = await _apiService.getReminders(pairId);

      final now = DateTime.now();
      final format = DateFormat("dd MMM yyyy hh:mm a");

      final List<Reminder> upcoming = [];

      for (final r in reminders) {
        try {
          final dt = format.parse("${r.date} ${r.time}");
          if (dt.isAfter(now)) {
            upcoming.add(r);
          }
        } catch (e) {
          log("Date parsing error: $e");
        }
      }

      upcoming.sort((a, b) {
        final aDate = format.parse("${a.date} ${a.time}");
        final bDate = format.parse("${b.date} ${b.time}");
        return aDate.compareTo(bDate);
      });

      final next = upcoming.isNotEmpty ? upcoming.first : null;

      emit(RemindersLoaded(reminders, next));
    } catch (e, st) {
      log("Load error: $e", name: _nameTag);
      log("Stacktrace: $st", name: _nameTag);
      emit(const ReminderError("Failed to load reminders"));
    }
  }

  Future<void> _onAddReminder(
    AddReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final pairId = _getPairId();
      if (pairId == null) {
        emit(const ReminderError("No patient connected"));
        return;
      }

      // 1. Validate Date
      final format = DateFormat("dd MMM yyyy hh:mm a");
      final scheduledDate = format.parse("${event.reminder.date} ${event.reminder.time}");

      if (!scheduledDate.isAfter(DateTime.now())) {
        emit(const ReminderError("Cannot set reminder in the past"));
        return;
      }

      // 2. Send to Backend
      await _apiService.createReminder(
        reminder: event.reminder,
        pairId: pairId,
      );

      add(LoadReminders());
    } catch (e, st) {
      log("Add error: $e", name: _nameTag);
      log("Stacktrace: $st", name: _nameTag);
      emit(const ReminderError("Failed to add reminder"));
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _apiService.deleteReminder(event.reminder.id);
      add(LoadReminders());
    } catch (e, st) {
      log("Delete error: $e", name: _nameTag);
      log("Stacktrace: $st", name: _nameTag);
      emit(const ReminderError("Failed to delete reminder"));
    }
  }
}
