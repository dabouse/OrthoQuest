import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';

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

    return await openDatabase(path, version: 1, onCreate: _onCreate);
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
      // If session started before 5 AM, it belongs to the previous day
      final reportingDate = start.hour < 5
          ? DateTime(start.year, start.month, start.day - 1)
          : DateTime(start.year, start.month, start.day);

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
}
