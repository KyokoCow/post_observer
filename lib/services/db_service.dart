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
    final path = join(await getDatabasesPath(), 'qiita_observer.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE snapshots(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          article_id TEXT,
          title TEXT,
          views INTEGER,
          likes INTEGER,
          stocks INTEGER,
          timestamp TEXT
        )
        ''');
      },
    );
  }
}