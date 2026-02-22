import 'dart:async';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';
import '../utils/app_defaults.dart';
import '../utils/date_utils.dart';
import '../models/badge.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

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

  static const String tableUnlockedAssets = 'unlocked_assets';
  static const String colAssetId = 'asset_id';
  static const String colAssetType = 'asset_type'; // 'theme', 'sticker', etc.

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static Completer<Database>? _dbCompleter;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;

    if (_dbCompleter != null) return _dbCompleter!.future;

    _dbCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _dbCompleter!.complete(_database);
      final db = _database!;
      _dbCompleter = null;
      return db;
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'orthoquest.db');

    return await openDatabase(
      path,
      version: 5,
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
      colValue: '${AppDefaults.brushingDurationSeconds}',
    });
    await db.insert(tableSettings, {
      colKey: 'day_end_hour',
      colValue: '${AppDefaults.dayEndHour}',
    });

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

    // Create unlocked_assets table
    await db.execute('''
      CREATE TABLE $tableUnlockedAssets(
        $colAssetId TEXT PRIMARY KEY,
        $colAssetType TEXT,
        $colUnlockedAt TEXT
      )
    ''');

    // Insert default theme
    await db.insert(tableUnlockedAssets, {
      colAssetId: 'default_neon',
      colAssetType: 'theme',
      colUnlockedAt: DateTime.now().toIso8601String(),
    });

    await db.insert(tableSettings, {
      colKey: 'active_theme',
      colValue: 'default_neon',
    });
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

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUnlockedAssets(
          $colAssetId TEXT PRIMARY KEY,
          $colAssetType TEXT,
          $colUnlockedAt TEXT
        )
      ''');
      // Débloquer le thème et l'avatar par défaut
      await db.insert(tableUnlockedAssets, {
        colAssetId: 'default_neon',
        colAssetType: 'theme',
        colUnlockedAt: DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.insert(tableUnlockedAssets, {
        colAssetId: '👤',
        colAssetType: 'avatar',
        colUnlockedAt: DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // S'assurer que les paramètres actifs existent
      final List<Map<String, dynamic>> themeMaps = await db.query(
        tableSettings,
        where: '$colKey = ?',
        whereArgs: ['active_theme'],
      );
      if (themeMaps.isEmpty) {
        await db.insert(tableSettings, {
          colKey: 'active_theme',
          colValue: 'default_neon',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final List<Map<String, dynamic>> avatarMaps = await db.query(
        tableSettings,
        where: '$colKey = ?',
        whereArgs: ['active_avatar'],
      );
      if (avatarMaps.isEmpty) {
        await db.insert(tableSettings, {
          colKey: 'active_avatar',
          colValue: '👤',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
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

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete(
      tableSessions,
      where: '$colId = ?',
      whereArgs: [id],
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

  // Returns map of Date -> Duration(minutes).
  // Les sessions traversant la frontière de journée sont découpées entre les jours.
  Future<Map<DateTime, int>> getDailySummaries() async {
    final sessions = await getSessions();
    final summaries = <DateTime, int>{};
    final dayEndHour = int.tryParse(await getSetting('day_end_hour') ?? '') ?? AppDefaults.dayEndHour;

    for (var session in sessions) {
      if (session.endTime == null) continue;

      final splits = OrthoDateUtils.splitSessionAcrossDays(
        session.startTime,
        session.endTime!,
        dayEndHour: dayEndHour,
      );
      for (final entry in splits.entries) {
        summaries[entry.key] = (summaries[entry.key] ?? 0) + entry.value;
      }
    }

    return summaries;
  }

  /// Retourne le total exact en millisecondes pour la journée de reporting donnée.
  /// Si [date] est null, utilise la date actuelle. Les sessions sont clippées
  /// à la fenêtre de la journée demandée.
  Future<int> getTodayTotalMs([DateTime? date]) async {
    final dayEndHour = int.tryParse(await getSetting('day_end_hour') ?? '') ?? AppDefaults.dayEndHour;
    final reportDate = OrthoDateUtils.getReportingDate(date ?? DateTime.now(), dayEndHour: dayEndHour);
    final sessions = await getSessions();
    int totalMs = 0;

    for (var session in sessions) {
      if (session.endTime == null) continue;

      totalMs += OrthoDateUtils.clipSessionToDay(
        session.startTime,
        session.endTime!,
        targetDate: reportDate,
        dayEndHour: dayEndHour,
      );
    }
    return totalMs;
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

  // Asset Methods
  Future<List<String>> getUnlockedAssets(String type) async {
    final db = await database;
    final maps = await db.query(
      tableUnlockedAssets,
      where: '$colAssetType = ?',
      whereArgs: [type],
    );
    return maps.map((e) => e[colAssetId] as String).toList();
  }

  Future<void> unlockAsset(String assetId, String type) async {
    final db = await database;
    await db.insert(tableUnlockedAssets, {
      colAssetId: assetId,
      colAssetType: type,
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
    try {
      await db.delete(tableUnlockedAssets);
    } catch (_) {
      // Table might not exist yet if migration failed
    }

    // Récupérer l'objectif pour s'assurer de le dépasser
    final goalStr = await getSetting('daily_goal');
    final dailyGoal = int.tryParse(goalStr ?? '') ?? AppDefaults.dailyGoalHours;

    final now = DateTime.now();
    // Générer des données pour les 21 derniers jours (plus de volume)
    for (int i = 0; i < 21; i++) {
      final dayDate = now.subtract(Duration(days: i));

      // On force la réussite pour les 10 derniers jours pour voir le streak
      bool forceSuccess = i < 10;

      // Session de jour
      if (forceSuccess || random.nextDouble() > 0.3) {
        final startHour = 7 + random.nextInt(3); // 7h-10h
        final durationHours = forceSuccess ? 5 : (3 + random.nextInt(5));
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
            stickerId: random.nextInt(4),
          ),
        );
      }

      // Session de nuit
      if (forceSuccess || random.nextDouble() > 0.1) {
        final startHour = 19 + random.nextInt(3); // 19h-22h
        final durationHours = forceSuccess
            ? (dailyGoal - 4 + random.nextInt(4))
            : (6 + random.nextInt(6));
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
            stickerId: random.nextInt(4),
          ),
        );
      }
    }

    // Débloquer des badges aléatoires
    final badgeIds = appBadges.map((b) => b.id).toList();
    badgeIds.shuffle();
    final numBadges = 1 + random.nextInt(4);
    for (int i = 0; i < numBadges; i++) {
      await unlockBadge(badgeIds[i]);
    }

    // Génération aléatoire du niveau et récompenses (1 à 25)
    final level = 1 + random.nextInt(25);
    final xp = (level - 1) * 1000 + random.nextInt(1000);
    await updateUserStats(xp, level);

    // Débloquer les actifs de base
    await unlockAsset('default_neon', 'theme');
    await unlockAsset('👤', 'avatar');

    // Débloquer selon le niveau généré
    final List<String> unlockedThemes = ['default_neon'];
    final List<String> unlockedAvatars = ['👤'];

    // Débloquer les thèmes selon le niveau généré (1 par niveau)
    for (int lvl = 2; lvl <= level; lvl++) {
      String? themeId;
      if (lvl == 2) themeId = 'deep_space';
      if (lvl == 3) themeId = 'aurora';
      if (lvl == 4) themeId = 'sunset';
      if (lvl == 5) themeId = 'midnight';
      if (lvl == 6) themeId = 'desert';
      if (lvl == 7) themeId = 'emerald';
      if (lvl == 8) themeId = 'cyber_pink';
      if (lvl == 9) themeId = 'ocean';
      if (lvl == 10) themeId = 'volcano';

      if (themeId != null) {
        await unlockAsset(themeId, 'theme');
        unlockedThemes.add(themeId);
      }
    }

    if (level >= 2) {
      await unlockAsset('🦖', 'avatar');
      unlockedAvatars.add('🦖');
    }
    if (level >= 7) {
      await unlockAsset('🛡️', 'avatar');
      unlockedAvatars.add('🛡️');
    }
    if (level >= 12) {
      await unlockAsset('🚀', 'avatar');
      unlockedAvatars.add('🚀');
    }
    if (level >= 20) {
      await unlockAsset('👑', 'avatar');
      unlockedAvatars.add('👑');
    }

    // Choisir un thème et avatar actif au hasard parmi ceux débloqués
    final activeTheme = unlockedThemes[random.nextInt(unlockedThemes.length)];
    final activeAvatar =
        unlockedAvatars[random.nextInt(unlockedAvatars.length)];
    await updateSetting('active_theme', activeTheme);
    await updateSetting('active_avatar', activeAvatar);

    // Mettre à jour les stats de brossage
    final totalBrushings = 10 + random.nextInt(30);
    await updateSetting('total_brushings', totalBrushings.toString());
  }

  // Wrapper for public access if needed (the existing code had seedDummyData public)
  Future<void> seedDummyData() => _seedDummyData();

  /// Efface toutes les sessions et badges, et réinitialise les stats utilisateur.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableSessions);
    await db.delete(tableUserBadges);
    await db.delete(tableUnlockedAssets);
    await db.update(tableUserStats, {
      colXp: 0,
      colLevel: 1,
    }, where: '$colId = 1');
    await updateSetting('total_brushings', '0');
    await updateSetting('active_theme', 'default_neon');
    await updateSetting('active_avatar', '👤');
    await updateSetting('last_seen_level', '1');
    await updateSetting('has_unseen_reward', 'false');

    // Redébloquer le thème par défaut
    await unlockAsset('default_neon', 'theme');
    await unlockAsset('👤', 'avatar');
  }

  // --- Export & Import Methods ---

  /// Exporte la base de données actuelle via le menu de partage du système.
  Future<void> exportDatabase() async {
    final db = await database;
    final path = db.path;
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Sauvegarde OrthoQuest - ${DateTime.now().toIso8601String()}',
    );
  }

  /// Ouvre un sélecteur de fichier pour importer une base de données.
  /// Efface la base actuelle puis copie le fichier sélectionné pour un état propre.
  /// Retourne true en cas de succès, false sinon.
  Future<bool> importDatabase() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return false;
      }

      final File selectedFile = File(result.files.single.path!);
      if (!await selectedFile.exists()) {
        print("Fichier sélectionné introuvable : ${selectedFile.path}");
        return false;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'orthoquest.db');
      final backupPath = '$path.backup';

      // 1. Fermer la connexion actuelle
      if (_database != null) {
        await _database!.close();
        _database = null;
        _dbCompleter = null;
      }

      // 2. Sauvegarde de secours avant suppression (au cas où la copie échoue)
      final existingDb = File(path);
      if (await existingDb.exists()) {
        await existingDb.copy(backupPath);
        await existingDb.delete();
      }

      // 3. Copier le fichier importé
      await selectedFile.copy(path);

      // 4. Supprimer la sauvegarde (succès)
      final backup = File(backupPath);
      if (await backup.exists()) {
        await backup.delete();
      }

      return true;
    } catch (e) {
      print("Erreur lors de l'import : $e");
      // Tenter de restaurer la sauvegarde en cas d'échec
      try {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'orthoquest.db');
        final backupPath = '$path.backup';
        final backup = File(backupPath);
        if (await backup.exists()) {
          await backup.copy(path);
          await backup.delete();
        }
      } catch (restoreError) {
        print("Restauration échouée : $restoreError");
      }
      return false;
    }
  }
}
