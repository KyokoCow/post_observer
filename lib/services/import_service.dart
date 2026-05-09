import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import 'db_service.dart';

class ImportService {
  /// ★共通：sync_id再マッピングテーブル
  final Map<int, int> _syncIdMap = {};

  int _remapSyncId(int oldId) {
    return _syncIdMap.putIfAbsent(
      oldId,
          () => DateTime.now().millisecondsSinceEpoch + oldId.hashCode,
    );
  }

  Future<void> importSnapshots() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    final db = await DbService.instance.database;

    await db.delete('snapshots');

    final file = File(path);
    final content = await file.readAsString();

    final rows = const CsvToListConverter().convert(content);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final oldSyncId = int.parse(row[0].toString());
      final newSyncId = _remapSyncId(oldSyncId);

      await db.insert(
        'snapshots',
        {
          'sync_id': newSyncId,
          'article_id': row[1],
          'title': row[2],
          'views': row[3],
          'likes': row[4],
          'stocks': row[5],
          'timestamp': row[6],
        },
      );
    }
  }

  Future<void> importEvents() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    final db = await DbService.instance.database;

    await db.delete('events');

    final file = File(path);
    final content = await file.readAsString();

    final rows = const CsvToListConverter().convert(content);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final oldSyncId = int.parse(row[0].toString());
      final newSyncId = _remapSyncId(oldSyncId);

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
}