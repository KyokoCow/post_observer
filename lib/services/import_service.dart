import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';

import 'db_service.dart';

class ImportService {

  /// =========================
  /// sync_id変換テーブル
  /// =========================

  final Map<int, int> _syncIdMap = {};

  int _remapSyncId(int oldId) {

    return _syncIdMap.putIfAbsent(
      oldId,
          () =>
      DateTime.now().millisecondsSinceEpoch +
          _syncIdMap.length,
    );
  }

  /// =========================
  /// メインImport
  /// =========================

  Future<void> importAll() async {

    /// zip選択

    final result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) {
      return;
    }

    final zipPath =
        result.files.single.path;

    if (zipPath == null) {
      return;
    }

    /// =========================
    /// temp展開
    /// =========================

    final tempDir =
    await Directory.systemTemp
        .createTemp();

    extractFileToDisk(
      zipPath,
      tempDir.path,
    );

    /// =========================
    /// exportDir検出
    /// =========================

    final dirs = tempDir
        .listSync()
        .whereType<Directory>()
        .toList();

    if (dirs.isEmpty) {

      throw Exception(
        'zip内フォルダが見つかりません',
      );
    }

    final rootDir = dirs.first;

    final snapshotsFile = File(
      join(
        rootDir.path,
        'snapshots.csv',
      ),
    );

    final eventsFile = File(
      join(
        rootDir.path,
        'events.csv',
      ),
    );

    final tagsFile = File(
      join(
        rootDir.path,
        'tags.csv',
      ),
    );

    final sessionsFile = File(
      join(
        rootDir.path,
        'sync_sessions.csv',
      ),
    );

    /// snapshots は必須

    if (!await snapshotsFile.exists()) {

      throw Exception(
        'snapshots.csv が見つかりません',
      );
    }

    final hasEvents =
    await eventsFile.exists();

    final hasTags =
    await tagsFile.exists();

    final hasSessions =
    await sessionsFile.exists();

    final db =
    await DbService.instance.database;

    /// =========================
    /// 開発用フルクリア
    /// =========================

    await db.delete('snapshots');
    await db.delete('events');
    await db.delete('tags');
    await db.delete('sync_sessions');

    /// =========================
    /// import
    /// =========================

    await importSnapshots(
      db,
      snapshotsFile,
    );

    if (hasEvents) {

      await importEvents(
        db,
        eventsFile,
      );
    }

    if (hasTags) {

      await importTags(
        db,
        tagsFile,
      );
    }

    if (hasSessions) {

      await importSyncSessions(
        db,
        sessionsFile,
      );
    }

    /// =========================
    /// temp削除
    /// =========================

    await tempDir.delete(
      recursive: true,
    );
  }

  /// =========================
  /// snapshots
  /// =========================

  Future<void> importSnapshots(
      dynamic db,
      File file,
      ) async {

    final content =
    await file.readAsString();

    final rows =
    const CsvToListConverter()
        .convert(content);

    for (int i = 1; i < rows.length; i++) {

      final row = rows[i];

      final oldSyncId =
      int.parse(row[0].toString());

      final newSyncId =
      _remapSyncId(oldSyncId);

      await db.insert(
        'snapshots',
        {
          'sync_id': newSyncId,

          'article_id': row[1],

          'title': row[2],

          'views': row[3],

          'likes': row[4],

          'stocks': row[5],

          'comments':
          row.length > 6
              ? row[6] ?? 0
              : 0,

          'created_at':
          row.length > 7
              ? row[7]
              : null,

          'updated_at':
          row.length > 8
              ? row[8]
              : null,

          'timestamp':
          row.length > 9
              ? row[9]
              : row[6],
        },
      );
    }
  }

  /// =========================
  /// events
  /// =========================

  Future<void> importEvents(
      dynamic db,
      File file,
      ) async {

    final content =
    await file.readAsString();

    final rows =
    const CsvToListConverter()
        .convert(content);

    for (int i = 1; i < rows.length; i++) {

      final row = rows[i];

      final oldSyncId =
      int.parse(row[0].toString());

      final newSyncId =
      _remapSyncId(oldSyncId);

      await db.insert(
        'events',
        {
          'sync_id': newSyncId,

          'type': row[1],

          'memo': row[2],

          'timestamp': row[3],
        },
      );
    }
  }

  /// =========================
  /// tags
  /// =========================

  Future<void> importTags(
      dynamic db,
      File file,
      ) async {

    final content =
    await file.readAsString();

    final rows =
    const CsvToListConverter()
        .convert(content);

    for (int i = 1; i < rows.length; i++) {

      final row = rows[i];

      final oldSyncId =
      int.parse(row[0].toString());

      final newSyncId =
      _remapSyncId(oldSyncId);

      await db.insert(
        'tags',
        {
          'sync_id': newSyncId,

          'article_id': row[1],

          'tag': row[2],
        },
      );
    }
  }

  /// =========================
  /// sync_sessions
  /// =========================

  Future<void> importSyncSessions(
      dynamic db,
      File file,
      ) async {

    final content =
    await file.readAsString();

    final rows =
    const CsvToListConverter()
        .convert(content);

    for (int i = 1; i < rows.length; i++) {

      final row = rows[i];

      final oldSyncId =
      int.parse(row[0].toString());

      final newSyncId =
      _remapSyncId(oldSyncId);

      await db.insert(
        'sync_sessions',
        {
          'sync_id': newSyncId,

          'timestamp':
          row.length > 1
              ? row[1]
              : '',

          'total_articles':
          row.length > 2
              ? row[2] ?? 0
              : 0,

          'total_views':
          row.length > 3
              ? row[3] ?? 0
              : 0,

          'total_likes':
          row.length > 4
              ? row[4] ?? 0
              : 0,

          'total_stocks':
          row.length > 5
              ? row[5] ?? 0
              : 0,

          'followers':
          row.length > 6
              ? row[6] ?? 0
              : 0,
        },
      );
    }
  }
}