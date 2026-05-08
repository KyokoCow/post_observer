import 'package:sqflite/sqflite.dart';

import 'db_service.dart';
import 'qiita_service.dart';

class SyncService {
  final qiita = QiitaService();

  Future<void> sync() async {
    final db = await DbService.instance.database;

    final items = await qiita.fetchItems();

    final now = DateTime.now().toIso8601String();

    for (final item in items) {
      await db.insert(
        'snapshots',
        {
          'article_id': item['id'],
          'title': item['title'],
          'views': item['page_views_count'] ?? 0,
          'likes': item['likes_count'] ?? 0,
          'stocks': item['stocks_count'] ?? 0,
          'timestamp': now,
        },
      );
    }
  }
}