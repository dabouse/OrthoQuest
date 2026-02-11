import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../utils/date_utils.dart';

class UserState {
  final int xp;
  final int level;
  final int streak;
  final List<String> unlockedBadges;

  UserState({
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.unlockedBadges = const [],
  });

  UserState copyWith({
    int? xp,
    int? level,
    int? streak,
    List<String>? unlockedBadges,
  }) {
    return UserState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    Future.microtask(() => _loadStats());
    return UserState();
  }

  Future<void> _loadStats() async {
    // Load generic stats (xp, level) from DB
    final stats = await DatabaseService().getUserStats();

    // Load goal
    final goalStr = await DatabaseService().getSetting('daily_goal');
    final goal = int.tryParse(goalStr ?? '13') ?? 13;

    // For streak, we calculate it dynamically from sessions
    final summaries = await DatabaseService().getDailySummaries();
    final streak = _calculateStreak(summaries, goal);

    final badges = await DatabaseService().getUnlockedBadges();

    state = state.copyWith(
      xp: stats['xp'] as int,
      level: stats['level'] as int,
      streak: streak,
      unlockedBadges: badges,
    );
  }

  int _calculateStreak(Map<DateTime, int> summaries, int dailyGoal) {
    int streak = 0;
    final now = DateTime.now();
    final targetMinutes = dailyGoal * 60;

    // Utilisation de l'utilitaire centralisé pour la règle des 5h du matin
    final reportingToday = OrthoDateUtils.getReportingDate(now);

    // Check Today
    if ((summaries[reportingToday] ?? 0) >= targetMinutes) {
      streak++;
    }

    // Check Past Days
    DateTime checkDate = reportingToday.subtract(const Duration(days: 1));
    while (true) {
      final normalizedCheck = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
      );
      if ((summaries[normalizedCheck] ?? 0) >= targetMinutes) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<void> addXp(int amount) async {
    int newXp = state.xp + amount;
    int newLevel = (newXp / 1000).floor() + 1; // Level up every 1000 XP

    state = state.copyWith(xp: newXp, level: newLevel);

    // Persist to DB
    await DatabaseService().updateUserStats(newXp, newLevel);
  }

  Future<void> unlockBadge(String badgeId) async {
    if (state.unlockedBadges.contains(badgeId)) return;

    final newBadges = List<String>.from(state.unlockedBadges)..add(badgeId);
    state = state.copyWith(unlockedBadges: newBadges);

    await DatabaseService().unlockBadge(badgeId);
  }

  Future<void> recordBrushing() async {
    // Award XP
    await addXp(50);

    // Increment Count
    final currentStr = await DatabaseService().getSetting('total_brushings');
    final current = int.tryParse(currentStr ?? '0') ?? 0;
    final newValue = current + 1;
    await DatabaseService().updateSetting(
      'total_brushings',
      newValue.toString(),
    );

    // Check Badge
    if (newValue >= 10) {
      unlockBadge('hygiene_pro');
    }
  }

  Future<void> checkSessionBadges() async {
    final sessions = await DatabaseService().getSessions();

    // First Steps
    if (sessions.isNotEmpty) {
      unlockBadge('first_steps');
    }

    // Night Owl
    final nightCount = sessions.where((s) => s.stickerId == 5).length;
    if (nightCount >= 5) {
      unlockBadge('night_owl');
    }

    // Steel Teeth  (Streak Updated separately in loadStats/Timer)
    if (state.streak >= 7) {
      unlockBadge('steel_teeth');
    }

    // Marathon (Any day > 16h)
    final summaries = await DatabaseService().getDailySummaries();
    if (summaries.values.any((min) => min >= 16 * 60)) {
      unlockBadge('marathon');
    }
  }

  Future<void> refresh() async {
    await _loadStats();
  }

  void incrementStreak() {
    // Logic included in loading stats logic for now
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
