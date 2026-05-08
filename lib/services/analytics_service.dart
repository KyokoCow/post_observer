import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class AnalyticsService {
  Future<List<Map<String, dynamic>>> latestArticles() async {
    final db = await DbService.instance.database;

    final result = await db.rawQuery('''
    SELECT *
    FROM snapshots s1
    WHERE timestamp = (
      SELECT MAX(timestamp)
      FROM snapshots s2
      WHERE s1.article_id = s2.article_id
    )
    ''');

    return result;
  }

  Future<int> dailyIncrease(String articleId) async {
    final db = await DbService.instance.database;

    final rows = await db.query(
      'snapshots',
      where: 'article_id = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp DESC',
      limit: 2,
    );

    if (rows.length < 2) return 0;

    final latest = rows[0]['views'] as int;
    final previous = rows[1]['views'] as int;

    return latest - previous;
  }
  Future<List<Map<String, dynamic>>> history(
      String articleId,
      ) async {
    final db = await DbService.instance.database;

    return db.query(
      'snapshots',
      where: 'article_id = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp ASC',
    );
  }
}