import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 4,

      onCreate: (db, version) async {
        await _createAll(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // ★開発用フルリセット（現状維持でOKだが将来注意）
          await db.execute('DROP TABLE IF EXISTS snapshots');
          await db.execute('DROP TABLE IF EXISTS events');

          await _createAll(db);
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
        sync_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        memo TEXT,
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
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id INTEGER NOT NULL,
        article_id TEXT NOT NULL,
        tag TEXT NOT NULL
      )
    ''');
  }
}