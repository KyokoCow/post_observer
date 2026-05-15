import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class ExportService {

  Future<void> exportCsv() async {
    try {
      final db = await DbService.instance.database;

      final now = DateTime.now();

      final timestamp = now
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');

      /// =========================
      /// 保存先
      /// =========================

      final baseDir = Directory('/storage/emulated/0/Download');

      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }

      /// =========================
      /// temp dir
      /// =========================

      final exportDir = Directory(
        join(baseDir.path, 'post_observer_export_$timestamp'),
      );

      await exportDir.create(recursive: true);

      /// =========================
      /// export
      /// =========================

      await _exportArticles(db, exportDir.path);
      await _exportSnapshots(db, exportDir.path);
      await _exportEvents(db, exportDir.path);
      await _exportTags(db, exportDir.path);
      await _exportSyncSessions(db, exportDir.path);

      /// =========================
      /// zip
      /// =========================

      final zipPath = join(
        baseDir.path,
        'post_observer_$timestamp.zip',
      );

      final encoder = ZipFileEncoder();

      encoder.create(zipPath);

      encoder.addDirectory(
        exportDir,
        includeDirName: false,
      );

      encoder.close();

      /// =========================
      /// temp delete
      /// =========================

      await exportDir.delete(recursive: true);

    } catch (e) {
      print('Export failed: $e');
      rethrow;
    }
  }

  /// =========================
  /// articles
  /// =========================

  Future<void> _exportArticles(Database db, String dirPath) async {
    final rows = await db.query(
      'articles',
      orderBy: 'created_at ASC',
    );

    final data = <List<dynamic>>[
      ['article_id', 'title', 'created_at', 'updated_at', 'first_seen_at'],
      ...rows.map((row) => [
        row['article_id'],
        row['title'],
        row['created_at'],
        row['updated_at'],
        row['first_seen_at'],
      ]),
    ];

    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'articles.csv'));

    await file.writeAsString('\uFEFF$csv');
  }

  /// =========================
  /// snapshots
  /// =========================

  Future<void> _exportSnapshots(Database db, String dirPath) async {
    final rows = await db.query(
      'snapshots',
      orderBy: 'timestamp ASC',
    );

    final data = <List<dynamic>>[
      [
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
      ],
      ...rows.map((row) => [
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
      ]),
    ];

    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'snapshots.csv'));

    await file.writeAsString('\uFEFF$csv');
  }

  /// =========================
  /// events
  /// =========================

  Future<void> _exportEvents(Database db, String dirPath) async {
    final rows = await db.query(
      'events',
      orderBy: 'event_at ASC',
    );

    final data = <List<dynamic>>[
      [
        'id',
        'sync_id',
        'article_id',
        'type',
        'memo',
        'source',
        'event_at',
        'created_at',
      ],
      ...rows.map((row) => [
        row['id'],
        row['sync_id'],
        row['article_id'],
        row['type'],
        row['memo'],
        row['source'],
        row['event_at'],
        row['created_at'],
      ]),
    ];

    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'events.csv'));

    await file.writeAsString('\uFEFF$csv');
  }

  /// =========================
  /// tags
  /// =========================

  Future<void> _exportTags(Database db, String dirPath) async {
    final rows = await db.query('tags');

    final data = <List<dynamic>>[
      ['sync_id', 'article_id', 'tag'],
      ...rows.map((row) => [
        row['sync_id'],
        row['article_id'],
        row['tag'],
      ]),
    ];

    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'tags.csv'));

    await file.writeAsString('\uFEFF$csv');
  }

  /// =========================
  /// sync_sessions
  /// =========================

  Future<void> _exportSyncSessions(Database db, String dirPath) async {
    final rows = await db.query('sync_sessions');

    final data = <List<dynamic>>[
      [
        'sync_id',
        'timestamp',
        'total_articles',
        'total_views',
        'total_likes',
        'total_stocks',
        'followers',
        'followees',
        'items_count',
      ],
      ...rows.map((row) => [
        row['sync_id'],
        row['timestamp'],
        row['total_articles'],
        row['total_views'],
        row['total_likes'],
        row['total_stocks'],
        row['followers'],
        row['followees'],
        row['items_count'],
      ]),
    ];

    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'sync_sessions.csv'));

    await file.writeAsString('\uFEFF$csv');
  }
}