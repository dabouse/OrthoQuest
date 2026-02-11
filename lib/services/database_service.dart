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
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        sticker_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'key': 'brushing_duration',
      'value': '120',
    }); // 2 minutes in seconds
    await db.insert('settings', {'key': 'day_end_hour', 'value': '5'}); // 5 AM

    // Create user_stats table
    await db.execute('''
      CREATE TABLE user_stats(
        id INTEGER PRIMARY KEY,
        xp INTEGER,
        level INTEGER
      )
    ''');
    // Insert initial user stats
    await db.insert('user_stats', {'id': 1, 'xp': 0, 'level': 1});

    // Create user_badges table
    await db.execute('''
      CREATE TABLE user_badges(
        badge_id TEXT PRIMARY KEY,
        unlocked_at TEXT
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add user_stats table if upgrading from version 1
      await db.execute('''
        CREATE TABLE user_stats(
          id INTEGER PRIMARY KEY,
          xp INTEGER,
          level INTEGER
        )
      ''');
      await db.insert('user_stats', {'id': 1, 'xp': 0, 'level': 1});
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE user_badges(
          badge_id TEXT PRIMARY KEY,
          unlocked_at TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      // Fix for "no such column: id" in user_stats if schema was malformed
      // We drop and recreate to be safe
      await db.execute('DROP TABLE IF EXISTS user_stats');
      await db.execute('''
        CREATE TABLE user_stats(
          id INTEGER PRIMARY KEY,
          xp INTEGER,
          level INTEGER
        )
      ''');
      await db.insert('user_stats', {'id': 1, 'xp': 0, 'level': 1});

      // Also ensure user_badges exists if skipped
      await db.execute(
        'CREATE TABLE IF NOT EXISTS user_badges(badge_id TEXT PRIMARY KEY, unlocked_at TEXT)',
      );
    }
  }

  // Session Methods
  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<Session>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'start_time DESC',
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
      'sessions',
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
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
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'];
    }
    return null;
  }

  // User Stats Methods
  Future<Map<String, dynamic>> getUserStats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_stats',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    // Default if not found (unexpected as we create it)
    return {'xp': 0, 'level': 1};
  }

  Future<void> updateUserStats(int xp, int level) async {
    final db = await database;
    await db.update(
      'user_stats',
      {'xp': xp, 'level': level},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Badge Methods
  Future<List<String>> getUnlockedBadges() async {
    final db = await database;
    // Check if table exists (in case of fresh install vs upgrade)
    // actually we handled it in onCreate/onUpgrade.
    // If table doesn't exist, query throws.

    final maps = await db.query('user_badges');
    return maps.map((e) => e['badge_id'] as String).toList();
  }

  Future<void> unlockBadge(String badgeId) async {
    final db = await database;
    await db.insert('user_badges', {
      'badge_id': badgeId,
      'unlocked_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Injecte des données fictives aléatoires pour la démonstration.
  Future<void> _seedDummyData() async {
    final random = Random();
    final db = await database;

    // Clear existing
    await db.delete('sessions');
    await db.delete('user_badges');

    final now = DateTime.now();
    // Générer des données pour les 14 derniers jours
    for (int i = 0; i < 14; i++) {
      final dayDate = now.subtract(Duration(days: i));

      // 80% de chance d'avoir une session de jour
      if (random.nextDouble() > 0.2) {
        final startHour = 7 + random.nextInt(4); // 7h à 10h
        final durationHours = 4 + random.nextInt(4); // 4h à 7h
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
            stickerId: random.nextInt(5) + 1,
          ),
        );
      }

      // 90% de chance d'avoir une session de nuit
      if (random.nextDouble() > 0.1) {
        final startHour = 20 + random.nextInt(3); // 20h à 22h
        final durationHours = 7 + random.nextInt(4); // 7h à 10h
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
            stickerId: random.nextInt(5) + 1,
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

    // Mettre à jour les stats de brossage
    final totalBrushings = 5 + random.nextInt(20);
    await updateSetting('total_brushings', totalBrushings.toString());

    // Ajouter de l'XP et un niveau aléatoire
    final randomXp = 1000 + random.nextInt(4000);
    final level = (randomXp / 1000).floor() + 1;
    await updateUserStats(randomXp, level);
  }

  // Wrapper for public access if needed (the existing code had seedDummyData public)
  Future<void> seedDummyData() => _seedDummyData();

  /// Efface toutes les sessions et badges, et réinitialise les stats utilisateur.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sessions');
    await db.delete('user_badges');
    await db.update('user_stats', {'xp': 0, 'level': 1}, where: 'id = 1');
    await updateSetting('total_brushings', '0');
  }
}
