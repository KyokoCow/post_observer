import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/article.dart';
import '../models/article_snapshot.dart';
import '../models/event.dart';

class DbService {

  static final DbService instance =
  DbService._();

  DbService._();

  Database? _database;

  Future<Database> get database async {

    if (_database != null) {
      return _database!;
    }

    _database = await _init();

    return _database!;
  }

  Future<Database> _init() async {

    final path = join(
      await getDatabasesPath(),
      'qiita_observer.db',
    );

    return openDatabase(

      path,

      version: 11,

      onCreate: (
          db,
          version,
          ) async {

        await _createAll(db);
      },

      /// 開発中なので全再生成
      onUpgrade: (
          db,
          oldVersion,
          newVersion,
          ) async {

        await db.execute(
          'DROP TABLE IF EXISTS snapshots',
        );

        await db.execute(
          'DROP TABLE IF EXISTS events',
        );

        await db.execute(
          'DROP TABLE IF EXISTS sync_sessions',
        );

        await db.execute(
          'DROP TABLE IF EXISTS articles',
        );

        await db.execute(
          'DROP TABLE IF EXISTS tags',
        );

        await db.execute(
          'DROP TABLE IF EXISTS settings',
        );

        await db.execute(
          'DROP TABLE IF EXISTS users',
        );

        await _createAll(db);
      },
    );
  }

  Future<void> _createAll(
      Database db,
      ) async {
    /// =========================
    /// users
    /// =========================

    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
    
        name TEXT NOT NULL,
    
        profile_image_url TEXT NOT NULL,
    
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    /// =========================
    /// snapshots
    /// =========================

    await db.execute('''
      CREATE TABLE snapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        sync_id INTEGER NOT NULL,

        article_id TEXT NOT NULL,

        title TEXT NOT NULL,

        views INTEGER NOT NULL,
        likes INTEGER NOT NULL,
        stocks INTEGER NOT NULL,

        comments INTEGER NOT NULL DEFAULT 0,

        created_at TEXT,
        updated_at TEXT,

        timestamp TEXT NOT NULL
      )
    ''');

    /// =========================
    /// events
    /// =========================

    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        sync_id INTEGER,

        article_id TEXT,

        type TEXT NOT NULL,

        memo TEXT,

        source TEXT NOT NULL,

        event_at TEXT NOT NULL,

        created_at TEXT NOT NULL
      )
    ''');

    /// =========================
    /// sync_sessions
    /// =========================

    await db.execute('''
      CREATE TABLE sync_sessions(
        sync_id INTEGER PRIMARY KEY,

        timestamp TEXT NOT NULL,

        total_articles INTEGER NOT NULL DEFAULT 0,
        total_views INTEGER NOT NULL DEFAULT 0,
        total_likes INTEGER NOT NULL DEFAULT 0,
        total_stocks INTEGER NOT NULL DEFAULT 0,

        followers INTEGER NOT NULL DEFAULT 0
      )
    ''');

    /// =========================
    /// articles
    /// =========================

    await db.execute('''
      CREATE TABLE articles(
        article_id TEXT PRIMARY KEY,

        title TEXT NOT NULL,

        created_at TEXT,
        updated_at TEXT,

        first_seen_at TEXT NOT NULL
      )
    ''');

    /// =========================
    /// tags
    /// =========================

    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        sync_id INTEGER NOT NULL,

        article_id TEXT NOT NULL,

        tag TEXT NOT NULL
      )
    ''');

    /// =========================
    /// settings
    /// =========================

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    /// default settings

    await db.insert(
      'settings',
      {
        'key':
        'auto_sync_enabled',

        'value':
        'false',
      },
    );

    await db.insert(
      'settings',
      {
        'key':
        'auto_sync_minutes',

        'value':
        '60',
      },
    );
  }

  /// =========================
  /// articles
  /// =========================

  Future<List<Article>>
  getArticles() async {

    final db = await database;

    final maps = await db.query(
      'articles',
      orderBy: 'updated_at DESC',
    );

    return maps
        .map((e) =>
        Article.fromMap(e))
        .toList();
  }

  /// =========================
  /// snapshots
  /// =========================

  Future<List<ArticleSnapshot>>
  getSnapshotsByArticleId(
      String articleId,
      ) async {

    final db = await database;

    final maps = await db.query(
      'snapshots',

      where: 'article_id = ?',

      whereArgs: [articleId],

      orderBy: 'timestamp ASC',
    );

    return maps
        .map((e) =>
        ArticleSnapshot.fromMap(e))
        .toList();
  }

  /// =========================
  /// events by article
  /// =========================

  Future<List<AppEvent>>
  getEventsByArticleId(
      String articleId,
      ) async {

    final db = await database;

    final maps = await db.query(
      'events',

      where: 'article_id = ?',

      whereArgs: [articleId],

      orderBy: 'event_at ASC',
    );

    return maps
        .map((e) =>
        AppEvent.fromMap(e))
        .toList();
  }

  /// =========================
  /// all events
  /// =========================

  Future<List<AppEvent>>
  getAllEvents() async {

    final db = await database;

    final maps = await db.query(
      'events',
      orderBy: 'event_at DESC',
    );

    return maps
        .map((e) =>
        AppEvent.fromMap(e))
        .toList();
  }

  /// =========================
  /// insert event
  /// =========================

  Future<void> insertEvent(
      AppEvent event,
      ) async {

    final db = await database;

    await db.insert(
      'events',
      event.toMap(),
    );
  }

  Future<void> saveUser(
      Map<String, dynamic> user,
      ) async {

    final db = await database;

    await db.insert(
      'users',
      user,

      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  /// =========================
  /// user
  /// =========================

  Future<Map<String, dynamic>?>
  getUser() async {

    final db = await database;

    final result = await db.query(
      'users',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }
  /// =========================
  /// settings
  /// =========================

  Future<String?> getSetting(
      String key,
      ) async {

    final db = await database;

    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['value'] as String;
  }

  Future<void> setSetting(
      String key,
      String value,
      ) async {

    final db = await database;

    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
      },

      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }
}