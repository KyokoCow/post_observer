import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart';

import 'db_service.dart';

class ExportService {
  Future<void> exportCsv() async {
    final db = await DbService.instance.database;

    final now = DateTime.now();

    final timestamp =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final baseDir =
    Directory(
      '/storage/emulated/0/Download',
    );

    if (!await baseDir.exists()) {
      await baseDir.create(
        recursive: true,
      );
    }

    /// ★ export専用フォルダ
    final exportDir = Directory(
      join(
        baseDir.path,
        'qiita_observer_$timestamp',
      ),
    );

    await exportDir.create(
      recursive: true,
    );

    if (!await baseDir.exists()) {
      await baseDir.create(
        recursive: true,
      );
    }

    await _exportSnapshots(db, exportDir.path, timestamp);
    await _exportEvents(db, exportDir.path, timestamp);
    await _exportTags(
      db,
      exportDir.path,
      timestamp,
    );

    await _exportSyncSessions(
      db,
      exportDir.path,
      timestamp,
    );
  }

  Future<void> _exportSnapshots(
      dynamic db,
      String dirPath,
      String timestamp,
      ) async {
    final rows = await db.query(
      'snapshots',
      orderBy: 'timestamp ASC',
    );

    final data = <List<dynamic>>[];

    data.add([
      'sync_id',
      'article_id',
      'title',
      'views',
      'likes',
      'stocks',
      'comments',
      'created_at',
      'updated_at',
      'timestamp',
    ]);

    for (final row in rows) {
      data.add([
        row['sync_id'],
        row['article_id'],
        row['title'],
        row['views'],
        row['likes'],
        row['stocks'],
        row['comments'],
        row['created_at'],
        row['updated_at'],
        row['timestamp'],
      ]);
    }

    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'snapshots.csv'));

    await file.writeAsString('\uFEFF$csv');
  }

  Future<void> _exportEvents(
      dynamic db,
      String dirPath,
      String timestamp,
      ) async {
    final rows = await db.query(
      'events',
      orderBy: 'timestamp ASC',
    );

    final data = <List<dynamic>>[];

    data.add([
      'sync_id',
      'type',
      'memo',
      'timestamp',
    ]);

    for (final row in rows) {
      data.add([
        row['sync_id'],
        row['type'],
        row['memo'],
        row['timestamp'],
      ]);
    }



    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'events.csv'));

    await file.writeAsString('\uFEFF$csv');
  }

  Future<void> _exportTags(
      dynamic db,
      String dirPath,
      String timestamp,
      ) async {
    final rows = await db.query('tags');

    final data = <List<dynamic>>[];

    data.add([
      'sync_id',
      'article_id',
      'tag',
    ]);

    for (final row in rows) {
      data.add([
        row['sync_id'],
        row['article_id'],
        row['tag'],
      ]);
    }

    final csv =
    const ListToCsvConverter()
        .convert(data);

    final path = join(
      dirPath,
      'tags.csv',
    );

    await File(path).writeAsString(
      '\uFEFF$csv',
    );
  }

  Future<void> _exportSyncSessions(
      dynamic db,
      String dirPath,
      String timestamp,
      ) async {
    final rows =
    await db.query('sync_sessions');

    final data = <List<dynamic>>[];

    data.add([
      'sync_id',
      'timestamp',
      'total_articles',
      'total_views',
      'total_likes',
      'total_stocks',
      'followers',
    ]);

    for (final row in rows) {
      data.add([
        row['sync_id'],
        row['timestamp'],
        row['total_articles'],
        row['total_views'],
        row['total_likes'],
        row['total_stocks'],
        row['followers'],
      ]);
    }

    final csv =
    const ListToCsvConverter()
        .convert(data);

    final path = join(
      dirPath,
      'sync_sessions.csv',
    );

    await File(path).writeAsString(
      '\uFEFF$csv',
    );
  }
}