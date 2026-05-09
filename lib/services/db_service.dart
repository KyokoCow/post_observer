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
      version: 3,

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
  }
}