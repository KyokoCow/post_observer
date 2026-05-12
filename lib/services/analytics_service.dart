import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class AnalyticsService {
  Future<List<Map<String, dynamic>>> latestArticles() async {
    final db = await DbService.instance.database;

    final latestSession = await db.query(
      'sync_sessions',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (latestSession.isEmpty) {
      return [];
    }

    final syncId =
    latestSession.first['sync_id'];

    return db.query(
      'snapshots',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      orderBy: 'views DESC',
    );
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

  Future<Map<String, dynamic>?> latestSession() async {
    final db = await DbService.instance.database;

    final result = await db.query(
      'sync_sessions',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }
  Future<List<String>> tags(
      String articleId,
      ) async {

    final db =
    await DbService.instance.database;

    final latest = await db.query(
      'snapshots',
      where: 'article_id = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (latest.isEmpty) {
      return [];
    }

    final syncId =
    latest.first['sync_id'];

    final result = await db.query(
      'tags',
      where:
      'article_id = ? AND sync_id = ?',
      whereArgs: [
        articleId,
        syncId,
      ],
    );

    return result
        .map((e) => e['tag'].toString())
        .toSet()
        .toList();
  }
}