import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';
import 'qiita_service.dart';

class SyncService {
  final qiita = QiitaService();

  Future<void> sync() async {
    final db = await DbService.instance.database;

    final items = await qiita.fetchItems();
    final user = await qiita.fetchUser();

    final now = DateTime.now().toIso8601String();

    // ★ 同期単位ID
    final syncId =
        DateTime.now().millisecondsSinceEpoch;

    /// =========================
    /// 集計値計算
    /// =========================

    int totalViews = 0;
    int totalLikes = 0;
    int totalStocks = 0;

    for (final item in items) {
      totalViews +=
      (item['page_views_count'] ?? 0) as int;

      totalLikes +=
      (item['likes_count'] ?? 0) as int;

      totalStocks +=
      (item['stocks_count'] ?? 0) as int;
    }

    final followers =
    (user['followers_count'] ?? 0) as int;

    debugPrint(
        "first item title = ${items.first['title']}"
    );

    debugPrint(
        "comments = ${items.first['comments_count']}"
    );

    debugPrint(
        "created_at = ${items.first['created_at']}"
    );

    debugPrint(
        "updated_at = ${items.first['updated_at']}"
    );

    debugPrint(
        "tags = ${items.first['tags']}"
    );

    debugPrint(
        "followers = $followers"
    );

    /// =========================
    /// sync_sessions 保存
    /// =========================

    await db.insert(
      'sync_sessions',
      {
        'sync_id': syncId,
        'timestamp': now,

        'total_articles': items.length,
        'total_views': totalViews,
        'total_likes': totalLikes,
        'total_stocks': totalStocks,
        'followers': followers,
      },
    );

    /// =========================
    /// snapshots 保存
    /// =========================

    for (final item in items) {
      await db.insert(
        'snapshots',
        {
          'sync_id': syncId,

          'article_id': item['id'],
          'title': item['title'],

          'views':
          (item['page_views_count'] ?? 0) as int,

          'likes':
          (item['likes_count'] ?? 0) as int,

          'stocks':
          (item['stocks_count'] ?? 0) as int,

          'comments':
          (item['comments_count'] ?? 0) as int,

          'created_at': item['created_at'],

          'updated_at': item['updated_at'],

          'timestamp': now,
        },
      );

      /// =========================
      /// tags 保存
      /// =========================

      final tags = item['tags'];

      if (tags is List) {
        for (final tag in tags) {
          final tagName = tag['name'];

          if (tagName == null) continue;

          await db.insert(
            'tags',
            {
              'sync_id': syncId,
              'article_id': item['id'],
              'tag': tagName,
            },
          );
        }
      }
    }

    /// =========================
    /// 自動同期イベント（任意）
    /// =========================

    // await db.insert(
    //   'events',
    //   {
    //     'sync_id': syncId,
    //     'type': 'sync',
    //     'memo': 'auto sync',
    //     'timestamp': now,
    //   },
    // );
  }
}