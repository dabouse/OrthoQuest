import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/app_defaults.dart';
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
  final int dayEndHour; // Heure de fin de journée (0-23, ex: 5 = 5h du matin)

  TimerState({
    this.isRunning = false,
    this.startTime,
    this.currentSessionDuration = Duration.zero,
    this.dailyTotalDuration = Duration.zero,
    this.dailySessions = const [],
    this.recentHistory = const {},
    this.dailyGoal = AppDefaults.dailyGoalHours,
    this.dayEndHour = AppDefaults.dayEndHour,
  });

  TimerState copyWith({
    bool? isRunning,
    DateTime? startTime,
    Duration? currentSessionDuration,
    Duration? dailyTotalDuration,
    List<Session>? dailySessions,
    Map<DateTime, int>? recentHistory,
    int? dailyGoal,
    int? dayEndHour,
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
      dayEndHour: dayEndHour ?? this.dayEndHour,
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
    await refreshSettings(); // Charge dailyGoal et dayEndHour avant les stats
    await _checkOpenSession();
    await _loadDailyStats();
    await _loadHistory();
  }

  Future<void> refreshSettings() async {
    final goalStr = await DatabaseService().getSetting('daily_goal');
    final dayEndStr = await DatabaseService().getSetting('day_end_hour');
    final goal = int.tryParse(goalStr ?? '') ?? AppDefaults.dailyGoalHours;
    final dayEndHour = int.tryParse(dayEndStr ?? '') ?? AppDefaults.dayEndHour;
    state = state.copyWith(dailyGoal: goal, dayEndHour: dayEndHour);
    // Recharger les stats car day_end_hour affecte le découpage des journées
    await _loadDailyStats();
    await _loadHistory();
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
    final dayEndHour = state.dayEndHour;
    final dayStart = OrthoDateUtils.getDayStart(now, dayEndHour: dayEndHour);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final reportDate = OrthoDateUtils.getReportingDate(now, dayEndHour: dayEndHour);

    final allSessions = await DatabaseService().getSessions();

    // Stickers : sessions démarrées aujourd'hui
    final dailySessions = allSessions.where((s) {
      return s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd);
    }).toList();

    // Durée totale : sessions qui chevauchent aujourd'hui, clippées à la fenêtre
    Duration total = Duration.zero;
    for (var s in allSessions) {
      if (s.endTime == null) continue;
      final ms = OrthoDateUtils.clipSessionToDay(
        s.startTime,
        s.endTime!,
        targetDate: reportDate,
        dayEndHour: dayEndHour,
      );
      if (ms > 0) {
        total += Duration(milliseconds: ms);
      }
    }

    state = state.copyWith(
      dailySessions: dailySessions,
      dailyTotalDuration: total,
    );
  }

  void startSession() async {
    if (state.isRunning) return;

    final now = DateTime.now();
    debugPrint('Starting session at $now'); // DEBUG for 500 error
    final newSession = Session(startTime: now);
    try {
      await DatabaseService().insertSession(newSession);
    } catch (e) {
      debugPrint('Error inserting session: $e');
      return;
    }

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

      // Delegate XP calculation and badge checking to UserProvider
      await ref
          .read(userProvider.notifier)
          .processSessionCompletion(updatedSession);
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
  }

  /// Ajoute une session manuelle avec validation.
  ///
  /// Permet d'ajouter rétroactivement une session non enregistrée.
  /// Retourne null si succès, ou un message d'erreur si échec de validation.
  Future<String?> addManualSession({
    required DateTime startTime,
    required Duration duration,
    int? stickerId,
  }) async {
    // Validation 1: Pas de session dans le futur
    if (startTime.isAfter(DateTime.now())) {
      return "La session ne peut pas être dans le futur";
    }

    // Validation 2: Durée valide
    if (duration.inMinutes <= 0) {
      return "La durée doit être supérieure à 0";
    }
    if (duration.inHours > 24) {
      return "La durée ne peut pas dépasser 24 heures";
    }

    // Calculer l'heure de fin
    final endTime = startTime.add(duration);

    // Validation 3: Vérifier qu'il n'y a pas de chevauchement
    final allSessions = await DatabaseService().getSessions();
    for (var session in allSessions) {
      final sessionStart = session.startTime;
      final sessionEnd = session.endTime ?? DateTime.now();

      // Vérifier si les intervalles se chevauchent
      final overlaps =
          (startTime.isBefore(sessionEnd) && endTime.isAfter(sessionStart));
      if (overlaps) {
        return "Cette session chevauche une session existante";
      }
    }

    // Créer et insérer la session
    final newSession = Session(
      startTime: startTime,
      endTime: endTime,
      stickerId: stickerId,
    );

    try {
      await DatabaseService().insertSession(newSession);

      // Traiter la session pour XP et badges
      await ref
          .read(userProvider.notifier)
          .processSessionCompletion(newSession);

      // Rafraîchir les statistiques
      await _loadDailyStats();
      await _loadHistory();

      // Rafraîchir le streak dans UserProvider
      await ref.read(userProvider.notifier).refresh();

      return null; // Succès
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la session manuelle: $e');
      return "Erreur lors de l'enregistrement de la session";
    }
  }

  /// Supprime une session existante et recalcule l'XP.
  Future<String?> deleteSession(int sessionId) async {
    try {
      await DatabaseService().deleteSession(sessionId);
      await ref.read(userProvider.notifier).recalculateXp();
      await _loadDailyStats();
      await _loadHistory();
      await ref.read(userProvider.notifier).refresh();
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la session: $e');
      return "Erreur lors de la suppression de la session";
    }
  }

  /// Modifie une session existante avec validation.
  /// Retourne null si succès, ou un message d'erreur.
  Future<String?> editSession({
    required int sessionId,
    required DateTime startTime,
    required Duration duration,
    int? stickerId,
  }) async {
    if (startTime.isAfter(DateTime.now())) {
      return "La session ne peut pas être dans le futur";
    }
    if (duration.inMinutes <= 0) {
      return "La durée doit être supérieure à 0";
    }
    if (duration.inHours > 24) {
      return "La durée ne peut pas dépasser 24 heures";
    }

    final endTime = startTime.add(duration);

    final allSessions = await DatabaseService().getSessions();
    for (var session in allSessions) {
      if (session.id == sessionId) continue;
      final sessionStart = session.startTime;
      final sessionEnd = session.endTime ?? DateTime.now();
      final overlaps =
          startTime.isBefore(sessionEnd) && endTime.isAfter(sessionStart);
      if (overlaps) {
        return "Cette session chevauche une session existante";
      }
    }

    final updatedSession = Session(
      id: sessionId,
      startTime: startTime,
      endTime: endTime,
      stickerId: stickerId,
    );

    try {
      await DatabaseService().updateSession(updatedSession);
      await ref.read(userProvider.notifier).recalculateXp();
      await _loadDailyStats();
      await _loadHistory();
      await ref.read(userProvider.notifier).refresh();
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la modification de la session: $e');
      return "Erreur lors de la modification de la session";
    }
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
  Future<void> onAppPaused() async {
    if (state.isRunning) {
      await _saveCurrentSession();
    }
  }

  /// Appelé lorsque l'application revient au premier plan.
  /// Vérifie s'il y a une session ouverte et la restaure si nécessaire.
  Future<void> onAppResumed() async {
    // Recharger systématiquement depuis la DB pour capter les changements du widget
    await _checkOpenSession();
    await _loadDailyStats();
    await _loadHistory();
  }
}
