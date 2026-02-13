import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../utils/date_utils.dart';
import '../models/session.dart';
import '../utils/app_theme.dart';

class UserState {
  final int xp;
  final int level;
  final int streak;
  final List<String> unlockedBadges;
  final String activeTheme;
  final List<String> unlockedThemes;
  final int lastSeenLevel;
  final bool hasUnseenReward;
  final String? lastUnlockedReward;
  final double sectionOpacity;
  final double sectionBlur;

  UserState({
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.unlockedBadges = const [],
    this.activeTheme = 'default_neon',
    this.unlockedThemes = const ['default_neon'],
    this.lastSeenLevel = 0,
    this.hasUnseenReward = false,
    this.lastUnlockedReward,
    this.sectionOpacity = 0.1,
    this.sectionBlur = 10.0,
  });

  UserState copyWith({
    int? xp,
    int? level,
    int? streak,
    List<String>? unlockedBadges,
    String? activeTheme,
    List<String>? unlockedThemes,
    int? lastSeenLevel,
    bool? hasUnseenReward,
    String? lastUnlockedReward,
    double? sectionOpacity,
    double? sectionBlur,
  }) {
    return UserState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      activeTheme: activeTheme ?? this.activeTheme,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      lastSeenLevel: lastSeenLevel ?? this.lastSeenLevel,
      hasUnseenReward: hasUnseenReward ?? this.hasUnseenReward,
      lastUnlockedReward: lastUnlockedReward ?? this.lastUnlockedReward,
      sectionOpacity: sectionOpacity ?? this.sectionOpacity,
      sectionBlur: sectionBlur ?? this.sectionBlur,
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

    // Load themes & avatars
    final activeTheme = await DatabaseService().getSetting('active_theme');
    final unlockedThemes = await DatabaseService().getUnlockedAssets('theme');
    final lastSeenStr = await DatabaseService().getSetting('last_seen_level');
    final hasUnseenStr = await DatabaseService().getSetting(
      'has_unseen_reward',
    );
    final hasUnseen = hasUnseenStr == 'true';
    final lastSeen = int.tryParse(lastSeenStr ?? '0') ?? 0;

    final opacityStr = await DatabaseService().getSetting('section_opacity');
    final sectionOpacity = double.tryParse(opacityStr ?? '0.1') ?? 0.1;

    final blurStr = await DatabaseService().getSetting('section_blur');
    final sectionBlur = double.tryParse(blurStr ?? '10.0') ?? 10.0;

    final currentLevel = stats['level'] as int;
    final filteredThemes = unlockedThemes.where((themeId) {
      final requiredLevel = AppTheme.themeUnlockLevels[themeId] ?? 1;
      return currentLevel >= requiredLevel;
    }).toList();

    if (!filteredThemes.contains('default_neon')) {
      filteredThemes.add('default_neon');
    }

    state = state.copyWith(
      xp: stats['xp'] as int,
      level: currentLevel,
      streak: streak,
      unlockedBadges: badges,
      activeTheme: activeTheme ?? 'default_neon',
      unlockedThemes: filteredThemes,
      lastSeenLevel: lastSeen == 0 ? currentLevel : lastSeen,
      hasUnseenReward: hasUnseen,
      sectionOpacity: sectionOpacity,
      sectionBlur: sectionBlur,
    );

    // Ensure all rewards for current level are unlocked (useful for updates)
    _checkLevelRewards(state.level);
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
    int oldLevel = state.level;
    int newXp = state.xp + amount;
    int newLevel = (newXp / 1000).floor() + 1;

    // Check for level rewards
    String? reward;
    if (newLevel > oldLevel) {
      reward = _checkLevelRewards(newLevel);
    }

    state = state.copyWith(
      xp: newXp,
      level: newLevel,
      lastUnlockedReward: reward,
    );

    // Persist to DB
    await DatabaseService().updateUserStats(newXp, newLevel);
  }

  String? _checkLevelRewards(int level) {
    // Vérifier s'il y a un thème à débloquer pour ce niveau précis
    String? themeIdToUnlock;
    AppTheme.themeUnlockLevels.forEach((id, reqLevel) {
      if (reqLevel == level && id != 'default_neon') {
        themeIdToUnlock = id;
      }
    });

    if (themeIdToUnlock != null) {
      if (!state.unlockedThemes.contains(themeIdToUnlock!)) {
        unlockTheme(themeIdToUnlock!);
        setHasUnseenReward(true);
        return AppTheme.themeNames[themeIdToUnlock] ?? themeIdToUnlock;
      }
    }
    return null;
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

  /// Traite la fin d'une session : calcule l'XP et vérifie les badges.
  Future<void> processSessionCompletion(Session session) async {
    // 1. Calcul de l'XP
    // 10 XP par heure -> ~1 XP toutes les 6 minutes
    final duration = session.duration;
    if (duration.inMinutes > 0) {
      final xpEarned = (duration.inMinutes / 6).floor();
      if (xpEarned > 0) {
        await addXp(xpEarned);
      }
    }

    // 2. Vérification des badges
    await checkSessionBadges();
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

  Future<void> setTheme(String themeId) async {
    if (!state.unlockedThemes.contains(themeId)) return;

    state = state.copyWith(activeTheme: themeId);
    await DatabaseService().updateSetting('active_theme', themeId);
  }

  Future<void> unlockTheme(String themeId) async {
    if (state.unlockedThemes.contains(themeId)) return;

    final newThemes = List<String>.from(state.unlockedThemes)..add(themeId);
    state = state.copyWith(unlockedThemes: newThemes);

    await DatabaseService().unlockAsset(themeId, 'theme');
  }

  Future<void> markLevelAsSeen(int level) async {
    state = state.copyWith(lastSeenLevel: level);
    await DatabaseService().updateSetting('last_seen_level', level.toString());
  }

  Future<void> setHasUnseenReward(bool value) async {
    state = state.copyWith(hasUnseenReward: value);
    await DatabaseService().updateSetting(
      'has_unseen_reward',
      value.toString(),
    );
  }

  Future<void> setSectionOpacity(double value) async {
    state = state.copyWith(sectionOpacity: value);
    await DatabaseService().updateSetting('section_opacity', value.toString());
  }

  Future<void> setSectionBlur(double value) async {
    state = state.copyWith(sectionBlur: value);
    await DatabaseService().updateSetting('section_blur', value.toString());
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
