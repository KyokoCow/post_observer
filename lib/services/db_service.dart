import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/article.dart';
import '../models/article_snapshot.dart';
import '../models/event.dart';

class DbService {
  static final DbService instance = DbService._();

  DbService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
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
      version: 8,

      onCreate: (db, version) async {
        await _createAll(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {

        if (oldVersion < 3) {

          await db.execute(
            'DROP TABLE IF EXISTS snapshots',
          );

          await db.execute(
            'DROP TABLE IF EXISTS events',
          );

          await _createAll(db);
        }

        if (oldVersion < 5) {

          await db.execute('''
            CREATE TABLE articles(
              article_id TEXT PRIMARY KEY,

              title TEXT NOT NULL,

              created_at TEXT,
              updated_at TEXT,

              first_seen_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 6) {

          await db.execute('''
            ALTER TABLE events
            ADD COLUMN article_id TEXT
          ''');
        }

        if (oldVersion < 8) {

          await db.execute('''
            ALTER TABLE events
            ADD COLUMN source TEXT
          ''');
        }
      },
    );
  }

  Future<void> _createAll(Database db) async {

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

    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        sync_id INTEGER,

        article_id TEXT,

        type TEXT NOT NULL,

        memo TEXT,

        source TEXT NOT NULL,

        timestamp TEXT NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE articles(
        article_id TEXT PRIMARY KEY,

        title TEXT NOT NULL,

        created_at TEXT,
        updated_at TEXT,

        first_seen_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        sync_id INTEGER NOT NULL,

        article_id TEXT NOT NULL,

        tag TEXT NOT NULL
      )
    ''');
  }

  Future<List<Article>> getArticles() async {

    final db = await database;

    final maps = await db.query(
      'articles',
      orderBy: 'updated_at DESC',
    );

    return maps
        .map((e) => Article.fromMap(e))
        .toList();
  }

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
        .map((e) => ArticleSnapshot.fromMap(e))
        .toList();
  }

  Future<List<AppEvent>>
  getEventsByArticleId(
      String articleId,
      ) async {

    final db = await database;

    final maps = await db.query(
      'events',
      where: 'article_id = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp ASC',
    );

    return maps
        .map((e) => AppEvent.fromMap(e))
        .toList();
  }

  Future<List<AppEvent>> getAllEvents() async {

    final db = await database;

    final maps = await db.query(
      'events',
      orderBy: 'timestamp DESC',
    );

    return maps
        .map((e) => AppEvent.fromMap(e))
        .toList();
  }

  Future<void> insertEvent(
      AppEvent event,
      ) async {

    final db = await database;

    await db.insert(
      'events',
      event.toMap(),
    );
  }
}