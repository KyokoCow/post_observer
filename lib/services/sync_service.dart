import 'package:sqflite/sqflite.dart';

import 'db_service.dart';
import 'qiita_service.dart';

class SyncService {
  final qiita = QiitaService();

  Future<void> sync() async {
    final db = await DbService.instance.database;

    final items = await qiita.fetchItems();

    final now = DateTime.now().toIso8601String();

    // ★ 同期単位ID（これが核）
    final syncId = DateTime.now().millisecondsSinceEpoch;

    for (final item in items) {
      await db.insert(
        'snapshots',
        {
          'sync_id': syncId, // ★必須（抜けてた原因）
          'article_id': item['id'],
          'title': item['title'],
          'views': item['page_views_count'] ?? 0,
          'likes': item['likes_count'] ?? 0,
          'stocks': item['stocks_count'] ?? 0,
          'timestamp': now,
        },
      );
    }

    // （任意）イベントも同一syncに紐づける場合の例
    // await db.insert('events', {
    //   'sync_id': syncId,
    //   'type': 'sync',
    //   'memo': 'auto sync',
    //   'timestamp': now,
    // });
  }
}