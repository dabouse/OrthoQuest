import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/database_service.dart';

// State class
class TimerState {
  final bool isRunning;
  final DateTime? startTime;
  final Duration currentSessionDuration;
  final Duration dailyTotalDuration;
  final List<Session> dailySessions;

  TimerState({
    this.isRunning = false,
    this.startTime,
    this.currentSessionDuration = Duration.zero,
    this.dailyTotalDuration = Duration.zero,
    this.dailySessions = const [],
  });

  TimerState copyWith({
    bool? isRunning,
    DateTime? startTime,
    Duration? currentSessionDuration,
    Duration? dailyTotalDuration,
    List<Session>? dailySessions,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
      currentSessionDuration:
          currentSessionDuration ?? this.currentSessionDuration,
      dailyTotalDuration: dailyTotalDuration ?? this.dailyTotalDuration,
      dailySessions: dailySessions ?? this.dailySessions,
    );
  }
}

// Provider
final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() {
    // Initialize async (fire and forget or handle properly)
    // For build(), we return initial state.
    // We can trigger load in a side effect or separate init method.
    // Using Future.microtask to start loading.
    Future.microtask(() => _init());

    // Setup disposal
    ref.onDispose(() {
      _ticker?.cancel();
    });

    return TimerState();
  }

  Future<void> _init() async {
    await _checkOpenSession();
    await _loadDailyStats();
  }

  // Check if there's an open session in DB
  Future<void> _checkOpenSession() async {
    final session = await DatabaseService().getLastOpenSession();
    if (session != null) {
      state = state.copyWith(
        isRunning: true,
        startTime: session.startTime,
        currentSessionDuration: DateTime.now().difference(session.startTime),
      );
      _startTicker();
    }
  }

  Future<void> _loadDailyStats() async {
    final now = DateTime.now();
    // 5 AM rule
    final dayStart = now.hour < 5
        ? DateTime(now.year, now.month, now.day - 1, 5)
        : DateTime(now.year, now.month, now.day, 5);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final allSessions = await DatabaseService().getSessions();

    final dailySessions = allSessions.where((s) {
      return s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd);
    }).toList();

    Duration total = Duration.zero;
    for (var s in dailySessions) {
      int durationInMin = s.durationInMinutes;
      total += Duration(minutes: durationInMin);
    }

    state = state.copyWith(
      dailySessions: dailySessions,
      dailyTotalDuration: total,
    );
  }

  void startSession() async {
    if (state.isRunning) return;

    final now = DateTime.now();
    final newSession = Session(startTime: now);
    await DatabaseService().insertSession(newSession);

    state = state.copyWith(
      isRunning: true,
      startTime: now,
      currentSessionDuration: Duration.zero,
    );
    _startTicker();
    // Refresh stats (optional, as new session has 0 duration initially)
    _loadDailyStats();
  }

  Future<void> stopSession({int? stickerId}) async {
    if (!state.isRunning) return;

    final now = DateTime.now();
    final openSession = await DatabaseService().getLastOpenSession();
    if (openSession != null) {
      final updatedSession = openSession.copyWith(
        endTime: now,
        stickerId: stickerId,
      );
      await DatabaseService().updateSession(updatedSession);
    }

    _ticker?.cancel();
    state = state.copyWith(
      isRunning: false,
      startTime: null,
      currentSessionDuration: Duration.zero,
    );
    await _loadDailyStats();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.startTime != null) {
        final duration = DateTime.now().difference(state.startTime!);
        // debugPrint('Ticker: $duration');
        // Update state logic
        state = state.copyWith(currentSessionDuration: duration);
      }
    });
  }
}
