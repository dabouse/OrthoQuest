import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import 'user_provider.dart';

// State class
class TimerState {
  final bool isRunning;
  final DateTime? startTime;
  final Duration currentSessionDuration;
  final Duration dailyTotalDuration;
  final List<Session> dailySessions;
  final Map<DateTime, int> recentHistory;
  final int dailyGoal; // Hours

  TimerState({
    this.isRunning = false,
    this.startTime,
    this.currentSessionDuration = Duration.zero,
    this.dailyTotalDuration = Duration.zero,
    this.dailySessions = const [],
    this.recentHistory = const {},
    this.dailyGoal = 13,
  });

  TimerState copyWith({
    bool? isRunning,
    DateTime? startTime,
    Duration? currentSessionDuration,
    Duration? dailyTotalDuration,
    List<Session>? dailySessions,
    Map<DateTime, int>? recentHistory,
    int? dailyGoal,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
      currentSessionDuration:
          currentSessionDuration ?? this.currentSessionDuration,
      dailyTotalDuration: dailyTotalDuration ?? this.dailyTotalDuration,
      dailySessions: dailySessions ?? this.dailySessions,
      recentHistory: recentHistory ?? this.recentHistory,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

// Provider
final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);

/// Gère l'état du timer et la logique métier des sessions.
class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;
  Timer? _saveTimer; // Timer pour sauvegardes périodiques
  Timer? _notificationTimer; // Timer pour mises à jour de notification

  @override
  TimerState build() {
    Future.microtask(() => _init());
    ref.onDispose(() {
      _ticker?.cancel();
      _saveTimer?.cancel();
      _notificationTimer?.cancel();
    });
    return TimerState();
  }

  Future<void> _init() async {
    await _checkOpenSession();
    await _loadDailyStats();
    await _loadHistory();
    await refreshSettings();
  }

  Future<void> refreshSettings() async {
    final goalStr = await DatabaseService().getSetting('daily_goal');
    final goal = int.tryParse(goalStr ?? '13') ?? 13;
    state = state.copyWith(dailyGoal: goal);
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseService().getDailySummaries();
    state = state.copyWith(recentHistory: history);
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
      _startPeriodicSave();
      _startNotificationUpdates();
    }
  }

  Future<void> _loadDailyStats() async {
    final now = DateTime.now();
    // Utilisation de l'utilitaire centralisé pour la règle des 5h du matin
    final dayStart = OrthoDateUtils.getDayStart(now);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final allSessions = await DatabaseService().getSessions();

    final dailySessions = allSessions.where((s) {
      return s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd);
    }).toList();

    Duration total = Duration.zero;
    for (var s in dailySessions) {
      total += s.duration;
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
    _startPeriodicSave();
    _startNotificationUpdates();
    // Refresh stats (optional, as new session has 0 duration initially)
    _loadDailyStats();
  }

  Future<void> updateSessionSticker(int sessionId, int stickerId) async {
    final sessionToUpdate = state.dailySessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => Session(id: -1, startTime: DateTime.now()),
    );

    if (sessionToUpdate.id == -1) return;

    final updatedSession = sessionToUpdate.copyWith(stickerId: stickerId);
    await DatabaseService().updateSession(updatedSession);
    await _loadDailyStats(); // Refresh UI
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

      // Award XP: 10 XP per hour (approx 1 XP per 6 minutes)
      // Minimum duration to award XP? maybe 1 minute?
      final duration = updatedSession.duration;
      if (duration.inMinutes > 0) {
        final xpEarned = (duration.inMinutes / 6)
            .floor(); // 10 XP / 60 min = 1/6
        if (xpEarned > 0) {
          ref.read(userProvider.notifier).addXp(xpEarned);
        }
      }
    }

    _ticker?.cancel();
    _saveTimer?.cancel();
    _notificationTimer?.cancel();
    await NotificationService().hideTimerNotification();

    state = state.copyWith(
      isRunning: false,
      startTime: null,
      currentSessionDuration: Duration.zero,
    );
    await _loadDailyStats();
    await _loadHistory(); // Refresh history

    // Check for badges
    ref.read(userProvider.notifier).checkSessionBadges();
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

  /// Démarre un timer périodique pour sauvegarder la session en cours
  /// toutes les 30 secondes. Cela garantit qu'en cas de fermeture brutale,
  /// au maximum 30 secondes de données sont perdues.
  void _startPeriodicSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _saveCurrentSession();
    });
  }

  /// Démarre un timer pour mettre à jour la notification toutes les secondes.
  void _startNotificationUpdates() {
    _notificationTimer?.cancel();
    // Afficher immédiatement la notification
    NotificationService().showTimerNotification(state.currentSessionDuration);

    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRunning && state.startTime != null) {
        final duration = DateTime.now().difference(state.startTime!);
        NotificationService().showTimerNotification(duration);
      }
    });
  }

  /// Sauvegarde la session en cours dans la base de données.
  /// Cette méthode est appelée périodiquement et lors de la mise
  /// en arrière-plan pour garantir qu'aucun temps ne soit perdu.
  Future<void> _saveCurrentSession() async {
    if (!state.isRunning || state.startTime == null) return;

    final openSession = await DatabaseService().getLastOpenSession();
    if (openSession != null) {
      // La session est toujours "ouverte" (pas d'endTime), on la garde telle quelle
      // mais on s'assure qu'elle est bien dans la BD.
      // En réalité, comme on ne modifie pas endTime, on n'a rien à faire.
      // Cette méthode sert surtout de point d'ancrage pour de futures améliorations.
    }
  }

  /// Appelé lorsque l'application passe en arrière-plan.
  /// Sauvegarde l'état actuel pour garantir qu'aucune donnée ne soit perdue.
  Future<void> onAppPaused() async {
    if (state.isRunning) {
      await _saveCurrentSession();
    }
  }

  /// Appelé lorsque l'application revient au premier plan.
  /// Vérifie s'il y a une session ouverte et la restaure si nécessaire.
  Future<void> onAppResumed() async {
    if (state.isRunning && state.startTime != null) {
      // Recalculer la durée actuelle au cas où l'app serait restée
      // en arrière-plan pendant un moment
      final duration = DateTime.now().difference(state.startTime!);
      state = state.copyWith(currentSessionDuration: duration);
      // Relancer les timers si nécessaire
      if (_ticker == null || !_ticker!.isActive) {
        _startTicker();
      }
      if (_saveTimer == null || !_saveTimer!.isActive) {
        _startPeriodicSave();
      }
      if (_notificationTimer == null || !_notificationTimer!.isActive) {
        _startNotificationUpdates();
      }
    }
  }
}
