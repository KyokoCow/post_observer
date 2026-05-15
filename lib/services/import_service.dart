import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class ImportService {

  final Map<int, int> _syncIdMap = {};

  int _remapSyncId(int oldId) {
    return _syncIdMap.putIfAbsent(
      oldId,
          () => DateTime.now().millisecondsSinceEpoch + _syncIdMap.length,
    );
  }

  /// =========================
  /// main import
  /// =========================

  Future<void> importAll() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) return;

    final zipPath = result.files.single.path;
    if (zipPath == null) return;

    final tempDir = await Directory.systemTemp.createTemp();

    extractFileToDisk(zipPath, tempDir.path);

    final dirs = tempDir.listSync().whereType<Directory>().toList();
    if (dirs.isEmpty) {
      throw Exception('zip内フォルダが見つかりません');
    }

    final rootDir = dirs.first;

    final articlesFile = File(join(rootDir.path, 'articles.csv'));
    final snapshotsFile = File(join(rootDir.path, 'snapshots.csv'));
    final eventsFile = File(join(rootDir.path, 'events.csv'));
    final tagsFile = File(join(rootDir.path, 'tags.csv'));
    final sessionsFile = File(join(rootDir.path, 'sync_sessions.csv'));

    final db = await DbService.instance.database;

    /// =========================
    /// clear
    /// =========================

    await db.transaction((txn) async {
      await txn.delete('articles');
      await txn.delete('snapshots');
      await txn.delete('events');
      await txn.delete('tags');
      await txn.delete('sync_sessions');
    });

    /// =========================
    /// import
    /// =========================

    if (await articlesFile.exists()) {
      await importArticles(db, articlesFile);
    }

    if (await snapshotsFile.exists()) {
      await importSnapshots(db, snapshotsFile);
    } else {
      throw Exception('snapshots.csv が見つかりません');
    }

    if (await eventsFile.exists()) {
      await importEvents(db, eventsFile);
    }

    if (await tagsFile.exists()) {
      await importTags(db, tagsFile);
    }

    if (await sessionsFile.exists()) {
      await importSyncSessions(db, sessionsFile);
    }

    await tempDir.delete(recursive: true);
  }

  /// =========================
  /// articles
  /// =========================

  Future<void> importArticles(Database db, File file) async {
    final rows = const CsvToListConverter().convert(await file.readAsString());

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      await db.insert(
        'articles',
        {
          'article_id': row[0],
          'title': row[1],
          'created_at': row.length > 2 ? row[2] : '',
          'updated_at': row.length > 3 ? row[3] : '',
          'first_seen_at': row.length > 4 ? row[4] : '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// =========================
  /// snapshots
  /// =========================

  Future<void> importSnapshots(Database db, File file) async {
    final rows = const CsvToListConverter().convert(await file.readAsString());

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final oldSyncId = int.tryParse(row[0].toString()) ?? 0;
      final newSyncId = _remapSyncId(oldSyncId);

      await db.insert('snapshots', {
        'sync_id': newSyncId,
        'article_id': row[1],
        'title': row[2],
        'views': row[3],
        'likes': row[4],
        'stocks': row[5],
        'comments': row.length > 6 ? (row[6] ?? 0) : 0,
        'created_at': row.length > 7 ? row[7] : '',
        'updated_at': row.length > 8 ? row[8] : '',
        'timestamp': row.length > 9 ? row[9] : '',
      });
    }
  }

  /// =========================
  /// events
  /// =========================

  Future<void> importEvents(Database db, File file) async {
    final rows = const CsvToListConverter().convert(await file.readAsString());

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      int? newSyncId;

      if (row.length > 1 && row[1] != null && row[1].toString().isNotEmpty) {
        final oldSyncId = int.tryParse(row[1].toString());
        if (oldSyncId != null) {
          newSyncId = _remapSyncId(oldSyncId);
        }
      }

      await db.insert('events', {
        'sync_id': newSyncId,
        'article_id': row.length > 2 ? row[2] : '',
        'type': row.length > 3 ? row[3] : 'other',
        'memo': row.length > 4 ? row[4] : '',
        'source': row.length > 5 ? row[5] : 'manual',
        'event_at': row.length > 6 ? row[6] : '',
        'created_at':
        row.length > 7 ? row[7] : DateTime.now().toIso8601String(),
      });
    }
  }

  /// =========================
  /// tags
  /// =========================

  Future<void> importTags(Database db, File file) async {
    final rows = const CsvToListConverter().convert(await file.readAsString());

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final oldSyncId = int.tryParse(row[0].toString()) ?? 0;
      final newSyncId = _remapSyncId(oldSyncId);

      await db.insert('tags', {
        'sync_id': newSyncId,
        'article_id': row[1],
        'tag': row[2],
      });
    }
  }

  /// =========================
  /// sync_sessions
  /// =========================

  Future<void> importSyncSessions(Database db, File file) async {
    final rows = const CsvToListConverter().convert(await file.readAsString());

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final oldSyncId = int.tryParse(row[0].toString()) ?? 0;
      final newSyncId = _remapSyncId(oldSyncId);

      await db.insert('sync_sessions', {
        'sync_id': newSyncId,
        'timestamp': row.length > 1 ? row[1] : '',
        'total_articles': row.length > 2 ? (row[2] ?? 0) : 0,
        'total_views': row.length > 3 ? (row[3] ?? 0) : 0,
        'total_likes': row.length > 4 ? (row[4] ?? 0) : 0,
        'total_stocks': row.length > 5 ? (row[5] ?? 0) : 0,
        'followers': row.length > 6 ? (row[6] ?? 0) : 0,
        'followees': row.length > 7 ? (row[7] ?? 0) : 0,
        'items_count': row.length > 8 ? (row[8] ?? 0) : 0,
      });
    }
  }
}