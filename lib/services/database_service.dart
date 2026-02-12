import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';
import '../utils/date_utils.dart';
import '../models/badge.dart';

/// Service singleton gérant la base de données SQLite locale.
///
/// Contient les méthodes pour :
/// - Initialiser la BDD.
/// - CRUD sur les sessions (ajout, mise à jour, lecture).
/// - Gestion des paramètres (clé-valeur).
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Table & Column Constants
  static const String tableSessions = 'sessions';
  static const String colId = 'id';
  static const String colStartTime = 'start_time';
  static const String colEndTime = 'end_time';
  static const String colStickerId = 'sticker_id';

  static const String tableSettings = 'settings';
  static const String colKey = 'key';
  static const String colValue = 'value';

  static const String tableUserStats = 'user_stats';
  static const String colXp = 'xp';
  // Note: colLevel matches the database column name 'level'
  static const String colLevel = 'level';

  static const String tableUserBadges = 'user_badges';
  static const String colBadgeId = 'badge_id';
  static const String colUnlockedAt = 'unlocked_at';

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'orthoquest.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSessions(
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colStartTime TEXT NOT NULL,
        $colEndTime TEXT,
        $colStickerId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSettings(
        $colKey TEXT PRIMARY KEY,
        $colValue TEXT
      )
    ''');

    // Insert default settings
    await db.insert(tableSettings, {
      colKey: 'brushing_duration',
      colValue: '120',
    }); // 2 minutes in seconds
    await db.insert(tableSettings, {
      colKey: 'day_end_hour',
      colValue: '5',
    }); // 5 AM

    // Create user_stats table
    await db.execute('''
      CREATE TABLE $tableUserStats(
        $colId INTEGER PRIMARY KEY,
        $colXp INTEGER,
        $colLevel INTEGER
      )
    ''');
    // Insert initial user stats
    await db.insert(tableUserStats, {colId: 1, colXp: 0, colLevel: 1});

    // Create user_badges table
    await db.execute('''
      CREATE TABLE $tableUserBadges(
        $colBadgeId TEXT PRIMARY KEY,
        $colUnlockedAt TEXT
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add user_stats table if upgrading from version 1
      await db.execute('''
        CREATE TABLE $tableUserStats(
          $colId INTEGER PRIMARY KEY,
          $colXp INTEGER,
          $colLevel INTEGER
        )
      ''');
      await db.insert(tableUserStats, {colId: 1, colXp: 0, colLevel: 1});
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $tableUserBadges(
          $colBadgeId TEXT PRIMARY KEY,
          $colUnlockedAt TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      // Fix for "no such column: id" in user_stats if schema was malformed
      // We drop and recreate to be safe
      await db.execute('DROP TABLE IF EXISTS $tableUserStats');
      await db.execute('''
        CREATE TABLE $tableUserStats(
          $colId INTEGER PRIMARY KEY,
          $colXp INTEGER,
          $colLevel INTEGER
        )
      ''');
      await db.insert(tableUserStats, {colId: 1, colXp: 0, colLevel: 1});

      // Also ensure user_badges exists if skipped
      await db.execute(
        'CREATE TABLE IF NOT EXISTS $tableUserBadges($colBadgeId TEXT PRIMARY KEY, $colUnlockedAt TEXT)',
      );
    }
  }

  // Session Methods
  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert(tableSessions, session.toMap());
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      tableSessions,
      session.toMap(),
      where: '$colId = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<Session>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSessions,
      orderBy: '$colStartTime DESC',
    );
    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }

  // Get daily stats for the last 7 days
  // Returns map of Date -> Duration(minutes)
  Future<Map<DateTime, int>> getDailySummaries() async {
    final sessions = await getSessions();
    final summaries = <DateTime, int>{};

    // We need to group sessions by "reporting day" (starts at 5 AM)
    for (var session in sessions) {
      if (session.endTime == null) {
        continue;
      }

      final start = session.startTime;
      // Utilisation de l'utilitaire centralisé pour la règle des 5h du matin
      final reportingDate = OrthoDateUtils.getReportingDate(start);

      final duration = session.durationInMinutes;
      summaries[reportingDate] = (summaries[reportingDate] ?? 0) + duration;
    }

    return summaries;
  }

  Future<Session?> getLastOpenSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSessions,
      where: '$colEndTime IS NULL',
      orderBy: '$colStartTime DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    }
    return null;
  }

  // Settings Methods
  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert(tableSettings, {
      colKey: key,
      colValue: value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSettings,
      where: '$colKey = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first[colValue];
    }
    return null;
  }

  // User Stats Methods
  Future<Map<String, dynamic>> getUserStats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUserStats,
      where: '$colId = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    // Default if not found (unexpected as we create it)
    return {colXp: 0, colLevel: 1};
  }

  Future<void> updateUserStats(int xp, int level) async {
    final db = await database;
    await db.update(
      tableUserStats,
      {colXp: xp, colLevel: level},
      where: '$colId = ?',
      whereArgs: [1],
    );
  }

  // Badge Methods
  Future<List<String>> getUnlockedBadges() async {
    final db = await database;
    // Check if table exists (in case of fresh install vs upgrade)
    // actually we handled it in onCreate/onUpgrade.
    // If table doesn't exist, query throws.

    final maps = await db.query(tableUserBadges);
    return maps.map((e) => e[colBadgeId] as String).toList();
  }

  Future<void> unlockBadge(String badgeId) async {
    final db = await database;
    await db.insert(tableUserBadges, {
      colBadgeId: badgeId,
      colUnlockedAt: DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Injecte des données fictives aléatoires pour la démonstration.
  Future<void> _seedDummyData() async {
    final random = Random();
    final db = await database;

    // Clear existing
    await db.delete(tableSessions);
    await db.delete(tableUserBadges);

    // Récupérer l'objectif pour s'assurer de le dépasser
    final goalStr = await getSetting('daily_goal');
    final dailyGoal = int.tryParse(goalStr ?? '13') ?? 13;

    final now = DateTime.now();
    // Générer des données pour les 14 derniers jours
    for (int i = 0; i < 14; i++) {
      final dayDate = now.subtract(Duration(days: i));

      // On force la réussite pour les 10 derniers jours pour voir le badge rose
      bool forceSuccess = i < 10;

      // Session de jour
      if (forceSuccess || random.nextDouble() > 0.2) {
        final startHour = 7 + random.nextInt(2); // 7h-8h
        final durationHours = forceSuccess ? 6 : (4 + random.nextInt(4));
        final startDay = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          startHour,
          random.nextInt(60),
        );
        final endDay = startDay.add(Duration(hours: durationHours));

        await insertSession(
          Session(
            startTime: startDay,
            endTime: endDay,
            stickerId: random.nextInt(2), // Plutôt motivé (0 ou 1)
          ),
        );
      }

      // Session de nuit
      if (forceSuccess || random.nextDouble() > 0.1) {
        final startHour = 20 + random.nextInt(2); // 20h-21h
        // Si forceSuccess, on s'assure que jour + nuit > dailyGoal
        final durationHours = forceSuccess
            ? (dailyGoal - 5 + random.nextInt(3))
            : (7 + random.nextInt(4));
        final startNight = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          startHour,
          random.nextInt(60),
        );
        final endNight = startNight.add(Duration(hours: durationHours));

        await insertSession(
          Session(
            startTime: startNight,
            endTime: endNight,
            stickerId: random.nextInt(2),
          ),
        );
      }
    }

    // Débloquer 2 à 4 badges au hasard
    final badgeIds = appBadges.map((b) => b.id).toList();
    badgeIds.shuffle();
    final numBadges = 2 + random.nextInt(3);
    for (int i = 0; i < numBadges; i++) {
      await unlockBadge(badgeIds[i]);
    }

    // Toujours débloquer Steel Teeth si on force le streak
    await unlockBadge('steel_teeth');

    // Mettre à jour les stats de brossage
    final totalBrushings = 15 + random.nextInt(10);
    await updateSetting('total_brushings', totalBrushings.toString());

    // Ajouter de l'XP et un niveau aléatoire
    final randomXp = 3000 + random.nextInt(2000);
    final level = (randomXp / 1000).floor() + 1;
    await updateUserStats(randomXp, level);
  }

  // Wrapper for public access if needed (the existing code had seedDummyData public)
  Future<void> seedDummyData() => _seedDummyData();

  /// Efface toutes les sessions et badges, et réinitialise les stats utilisateur.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableSessions);
    await db.delete(tableUserBadges);
    await db.update(tableUserStats, {
      colXp: 0,
      colLevel: 1,
    }, where: '$colId = 1');
    await updateSetting('total_brushings', '0');
  }
}
