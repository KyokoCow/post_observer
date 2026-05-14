import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class AnalyticsService {

  /// =========================
  /// 最新記事一覧
  /// =========================

  Future<List<Map<String, dynamic>>>
  latestArticles() async {

    final db =
    await DbService.instance.database;

    final result = await db.rawQuery('''
      SELECT s.*
      FROM snapshots s
      INNER JOIN (
        SELECT
          article_id,
          MAX(timestamp) as max_time
        FROM snapshots
        GROUP BY article_id
      ) latest
      ON s.article_id = latest.article_id
      AND s.timestamp = latest.max_time
      ORDER BY s.views DESC
    ''');

    return result;
  }

  /// =========================
  /// 最新セッション
  /// =========================

  Future<Map<String, dynamic>?>
  latestSession() async {

    final db =
    await DbService.instance.database;

    final result = await db.query(
      'sessions',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  /// =========================
  /// 日次増加
  /// =========================

  Future<int> dailyIncrease(
      String articleId,
      ) async {

    final db =
    await DbService.instance.database;

    final result = await db.query(
      'snapshots',
      where: 'article_id = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp DESC',
      limit: 2,
    );

    if (result.length < 2) {
      return 0;
    }

    final latest =
    result[0]['views'] as int;

    final previous =
    result[1]['views'] as int;

    return latest - previous;
  }

  /// =========================
  /// tags
  /// =========================

  Future<List<String>> tags(
      String articleId,
      ) async {

    final db =
    await DbService.instance.database;

    try {

      final result = await db.query(
        'tags',
        where: 'article_id = ?',
        whereArgs: [articleId],
      );

      return result
          .map(
            (e) =>
            e['tag_name'].toString(),
      )
          .toList();

    } catch (e) {

      debugPrint(
        'tags error: $e',
      );

      return [];
    }
  }

  /// =========================
  /// history
  /// =========================

  Future<List<Map<String, dynamic>>>
  history(
      String articleId,
      ) async {

    final db =
    await DbService.instance.database;

    debugPrint(
      'history() articleId = $articleId',
    );

    final all = await db.query(
      'snapshots',
      orderBy: 'timestamp ASC',
    );

    debugPrint(
      'ALL snapshots count = ${all.length}',
    );

    for (final row in all) {

      debugPrint(
        'snapshot article_id = ${row['article_id']}',
      );
    }

    final result = await db.query(
      'snapshots',
      where: 'article_id = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp ASC',
    );

    debugPrint(
      'filtered history count = ${result.length}',
    );

    return result;
  }
}