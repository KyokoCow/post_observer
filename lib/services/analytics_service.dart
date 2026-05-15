import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class AnalyticsService {

  /// =========================
  /// 最新記事一覧
  /// =========================
  Future<List<Map<String, dynamic>>> latestArticles() async {
    final db = await DbService.instance.database;

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
  /// KPIデータ取得
  /// =========================

  Future<Map<String, dynamic>?>
  latestSession() async {

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

  /// =========================
  /// 最新スナップショット（sessions置換）
  /// =========================
  Future<Map<String, dynamic>?> latestSnapshot() async {
    final db = await DbService.instance.database;

    final result = await db.query(
      'snapshots',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  /// =========================
  /// 日次増加
  /// =========================
  Future<int> dailyIncrease(String articleId) async {
    final db = await DbService.instance.database;

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

    final latest = (result[0]['views'] as num?)?.toInt() ?? 0;
    final previous = (result[1]['views'] as num?)?.toInt() ?? 0;

    return latest - previous;
  }

  /// =========================
  /// tags
  /// =========================
  Future<List<String>> tags(String articleId) async {
    final db = await DbService.instance.database;

    try {
      final result = await db.query(
        'tags',
        where: 'article_id = ?',
        whereArgs: [articleId],
      );

      final tags = result
          .map((e) =>
          (e['tag_name'] ?? e['name'] ?? e['tag'] ?? '')
              .toString()
              .trim())
          .where((t) => t.isNotEmpty)
          .toList();

      return tags;

    } catch (e) {
      debugPrint('tags error: $e');
      return [];
    }
  }

  /// =========================
  /// history
  /// =========================
  Future<List<Map<String, dynamic>>> history(String articleId) async {
    final db = await DbService.instance.database;

    debugPrint('history() articleId = $articleId');

    final result = await db.query(
      'snapshots',
      where: 'article_id = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp ASC',
    );

    debugPrint('filtered history count = ${result.length}');

    return result;
  }
  Future<List<Map<String, dynamic>>>
  dailyPvTrend() async {

    final db =
    await DbService.instance.database;

    final snapshots = await db.query(
      'snapshots',
      orderBy: 'timestamp ASC',
    );

    final latestMap =
    <String, Map<String, dynamic>>{};

    for (final s in snapshots) {

      final ts =
      s['timestamp']?.toString();

      if (ts == null) {
        continue;
      }

      final dt = DateTime.parse(ts);

      final dateKey =
          '${dt.year}'
          '-${dt.month.toString().padLeft(2, '0')}'
          '-${dt.day.toString().padLeft(2, '0')}';

      final articleId =
      s['article_id'].toString();

      final key =
          '$dateKey-$articleId';

      latestMap[key] = s;
    }

    /// =========================
    /// 日別合計
    /// =========================

    final dailyMap = <String, int>{};

    for (final entry in latestMap.entries) {

      final snapshot = entry.value;

      final ts =
      snapshot['timestamp'].toString();

      final dt = DateTime.parse(ts);

      final dateKey =
          '${dt.year}'
          '-${dt.month.toString().padLeft(2, '0')}'
          '-${dt.day.toString().padLeft(2, '0')}';

      final views =
      (snapshot['views'] ?? 0) as int;

      dailyMap[dateKey] =
          (dailyMap[dateKey] ?? 0)
              + views;
    }

    return dailyMap.entries.map((e) {
      return {
        'date': e.key,
        'views': e.value,
      };
    }).toList();
  }
}