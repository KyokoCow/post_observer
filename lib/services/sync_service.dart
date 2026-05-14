import 'package:flutter/cupertino.dart';

import '../models/event.dart';

import '../models/event_source.dart';
import '../models/event_type.dart';
import 'db_service.dart';
import 'qiita_service.dart';

class SyncService {

  final qiita = QiitaService();

  Future<void> sync() async {

    final db = await DbService.instance.database;

    final items = await qiita.fetchItems();

    final user = await qiita.fetchUser();

    final now = DateTime.now().toIso8601String();

    final syncId =
        DateTime.now().millisecondsSinceEpoch;

    /// =========================
    /// 集計
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
    /// article / event 更新
    /// =========================

    for (final item in items) {

      final articleId = item['id'];

      if (articleId == null) continue;

      final apiCreatedAt =
      item['created_at'];

      final apiUpdatedAt =
      item['updated_at'];

      final existing = await db.query(
        'articles',
        where: 'article_id = ?',
        whereArgs: [articleId],
        limit: 1,
      );

      /// =========================
      /// 新規記事
      /// =========================

      if (existing.isEmpty) {

        await db.insert(
          'articles',
          {
            'article_id': articleId,

            'title': item['title'],

            'created_at': apiCreatedAt,

            'updated_at': apiUpdatedAt,

            'first_seen_at': now,
          },
        );

        /// posted event

        await db.insert(
          'events',
          {
            'sync_id': syncId,

            'article_id': articleId,

            'type': EventType.post.value,

            'memo': null,

            'source': EventSource.auto.value,

            'event_at': apiCreatedAt,

            'created_at': now,
          },
        );

      } else {

        final current =
            existing.first;

        final currentUpdatedAt =
        current['updated_at'];

        /// =========================
        /// 更新検出
        /// =========================

        if (
        currentUpdatedAt !=
            apiUpdatedAt
        ) {

          await db.update(
            'articles',
            {
              'title': item['title'],

              'created_at': apiCreatedAt,

              'updated_at': apiUpdatedAt,
            },
            where: 'article_id = ?',
            whereArgs: [articleId],
          );

          /// updated event

          await db.insert(
            'events',
            {
              'sync_id': syncId,

              'article_id': articleId,

              'type': EventType.update.value,

              'memo': null,

              'source': EventSource.auto.value,

              'event_at': apiUpdatedAt,

              'created_at': now,
            },
          );
        }
      }

      /// =========================
      /// snapshots 保存
      /// =========================

      await db.insert(
        'snapshots',
        {
          'sync_id': syncId,

          'article_id': articleId,

          'title': item['title'],

          'views':
          (item['page_views_count'] ?? 0)
          as int,

          'likes':
          (item['likes_count'] ?? 0)
          as int,

          'stocks':
          (item['stocks_count'] ?? 0)
          as int,

          'comments':
          (item['comments_count'] ?? 0)
          as int,

          'created_at': apiCreatedAt,

          'updated_at': apiUpdatedAt,

          'timestamp': now,
        },
      );

      /// =========================
      /// tags 保存
      /// =========================

      final tags = item['tags'];

      if (tags is List) {

        for (final tag in tags) {

          final tagName =
          tag['name'];

          if (tagName == null) continue;

          await db.insert(
            'tags',
            {
              'sync_id': syncId,

              'article_id': articleId,

              'tag': tagName,
            },
          );
        }
      }
    }

    debugPrint(
      'sync completed',
    );
  }
}