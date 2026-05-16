import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';

class ImportService {
  final Map<int, int> _syncIdMap = {};

  /// =========================
  /// sync_id remap
  /// =========================

  int _remapSyncId(int oldId) {
    return _syncIdMap.putIfAbsent(
      oldId,
          () => DateTime.now().millisecondsSinceEpoch + _syncIdMap.length,
    );
  }

  /// =========================
  /// safe int parse
  /// =========================

  int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  /// =========================
  /// BOM remove
  /// =========================

  String cleanCsv(String text) {
    if (text.isEmpty) return text;

    if (text.codeUnitAt(0) == 0xFEFF) {
      return text.substring(1);
    }

    return text;
  }

  /// =========================
  /// CSV reader
  /// =========================

  Future<List<List<dynamic>>> readCsv(File file) async {
    final content = cleanCsv(
      await file.readAsString(),
    );

    final rows = const CsvToListConverter().convert(content);

    print('CSV READ: ${file.path}');
    print('ROWS: ${rows.length}');

    if (rows.isNotEmpty) {
      print('HEADER: ${rows.first}');
    }

    return rows;
  }

  /// =========================
  /// main import
  /// =========================

  Future<void> importAll() async {
    print('========================');
    print('IMPORT START');
    print('========================');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) {
      print('FILE PICK CANCELLED');
      return;
    }

    final zipPath = result.files.single.path;

    if (zipPath == null) {
      throw Exception('ZIP path is null');
    }

    print('ZIP PATH: $zipPath');

    final tempDir = await Directory.systemTemp.createTemp();

    extractFileToDisk(zipPath, tempDir.path);

    Directory rootDir;

    final dirs =
    tempDir.listSync().whereType<Directory>().toList();

    if (dirs.isNotEmpty) {
      /// ZIP内にフォルダがある場合
      rootDir = dirs.first;

      print('ZIP ROOT DIRECTORY FOUND');
      print(rootDir.path);
    } else {
      /// ZIP直下にCSVがある場合
      rootDir = tempDir;

      print('ZIP HAS NO ROOT DIRECTORY');
      print('USING TEMP DIR AS ROOT');
      print(rootDir.path);
    }

    print('ROOT DIR: ${rootDir.path}');

    print('FILES IN ZIP:');

    for (final entity in rootDir.listSync()) {
      print(entity.path);
    }

    final articlesFile =
    File(join(rootDir.path, 'articles.csv'));

    final snapshotsFile =
    File(join(rootDir.path, 'snapshots.csv'));

    final eventsFile =
    File(join(rootDir.path, 'events.csv'));

    final tagsFile =
    File(join(rootDir.path, 'tags.csv'));

    final sessionsFile =
    File(join(rootDir.path, 'sync_sessions.csv'));

    final db = await DbService.instance.database;

    await printCounts(db, 'BEFORE CLEAR');

    /// =========================
    /// CLEAR
    /// =========================

    try {
      print('CLEAR START');

      await db.transaction((txn) async {
        final tables = [
          'tags',
          'events',
          'snapshots',
          'sync_sessions',
          'articles',
        ];

        for (final table in tables) {
          print('DELETE: $table');

          final before = Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM $table',
            ),
          );

          print('$table BEFORE: $before');

          final deleted = await txn.delete(table);

          print('$table DELETED: $deleted');

          final after = Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM $table',
            ),
          );

          print('$table AFTER: $after');
        }
      });

      print('CLEAR SUCCESS');
    } catch (e, st) {
      print('CLEAR ERROR');
      print(e);
      print(st);

      rethrow;
    }

    await printCounts(db, 'AFTER CLEAR');

    /// =========================
    /// IMPORT
    /// =========================

    try {
      if (await articlesFile.exists()) {
        print('========================');
        print('IMPORT ARTICLES START');
        print('========================');

        await importArticles(db, articlesFile);

        print('IMPORT ARTICLES END');
        await printCounts(db, 'AFTER ARTICLES');
      }

      if (await sessionsFile.exists()) {
        print('========================');
        print('IMPORT SYNC_SESSIONS START');
        print('========================');

        await importSyncSessions(db, sessionsFile);

        print('IMPORT SYNC_SESSIONS END');
        await printCounts(db, 'AFTER SYNC_SESSIONS');
      }

      if (await snapshotsFile.exists()) {
        print('========================');
        print('IMPORT SNAPSHOTS START');
        print('========================');

        await importSnapshots(db, snapshotsFile);

        print('IMPORT SNAPSHOTS END');
        await printCounts(db, 'AFTER SNAPSHOTS');
      } else {
        throw Exception('snapshots.csv が見つかりません');
      }

      if (await eventsFile.exists()) {
        print('========================');
        print('IMPORT EVENTS START');
        print('========================');

        await importEvents(db, eventsFile);

        print('IMPORT EVENTS END');
        await printCounts(db, 'AFTER EVENTS');
      }

      if (await tagsFile.exists()) {
        print('========================');
        print('IMPORT TAGS START');
        print('========================');

        await importTags(db, tagsFile);

        print('IMPORT TAGS END');
        await printCounts(db, 'AFTER TAGS');
      }

      print('========================');
      print('IMPORT SUCCESS');
      print('========================');

      await printCounts(db, 'FINAL');
    } catch (e, st) {
      print('========================');
      print('IMPORT ERROR');
      print(e);
      print(st);
      print('========================');

      await printCounts(db, 'ERROR STATE');

      rethrow;
    }

    try {
      await tempDir.delete(recursive: true);
      print('TEMP DIR DELETED');
    } catch (e) {
      print('TEMP DELETE ERROR');
      print(e);
    }
  }

  /// =========================
  /// articles
  /// =========================

  Future<void> importArticles(Database db, File file) async {
    final rows = await readCsv(file);

    for (int i = 1; i < rows.length; i++) {

      final row = rows[i];
      print('articles row[$i]: $row');

      try {
        await db.insert(
          'articles',
          {
            'article_id': row[0].toString(),
            'title': row.length > 1 ? row[1].toString() : '',
            'created_at': row.length > 2 ? row[2].toString() : '',
            'updated_at': row.length > 3 ? row[3].toString() : '',
            'first_seen_at': row.length > 4 ? row[4].toString() : '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        print('articles error row[$i]');
        print(row);
        rethrow;
      }
    }
  }

  /// =========================
  /// sync_sessions
  /// =========================

  Future<void> importSyncSessions(Database db, File file) async {
    final rows = await readCsv(file);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      print('sync_sessions row[$i]: $row');

      try {
        print('sync_sessions row[$i]: $row');

        final oldSyncId =
            int.tryParse(row[0].toString()) ?? 0;

        final newSyncId =
        _remapSyncId(oldSyncId);

        await db.insert(
          'sync_sessions',
          {
            'sync_id': newSyncId,

            'timestamp':
            row.length > 1
                ? row[1].toString()
                : '',

            'total_articles':
            row.length > 2
                ? toInt(row[2])
                : 0,

            'total_views':
            row.length > 3
                ? toInt(row[3])
                : 0,

            'total_likes':
            row.length > 4
                ? toInt(row[4])
                : 0,

            'total_stocks':
            row.length > 5
                ? toInt(row[5])
                : 0,

            'followers':
            row.length > 6
                ? toInt(row[6])
                : 0,

            'followees':
            row.length > 7
                ? toInt(row[7])
                : 0,

            'items_count':
            row.length > 8
                ? toInt(row[8])
                : 0,
          },
        );
      } catch (e, st) {
        print('sync_sessions error row[$i]');
        print(row);
        print(e);
        print(st);

        rethrow;
      }
    }
  }

  /// =========================
  /// snapshots
  /// =========================

  Future<void> importSnapshots(Database db, File file) async {
    final rows = await readCsv(file);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      print('snapshots row[$i]: $row');

      try {
        final oldSyncId =
            int.tryParse(row[0].toString()) ?? 0;

        final newSyncId =
        _remapSyncId(oldSyncId);

        await db.insert(
          'snapshots',
          {
            'sync_id': newSyncId,
            'article_id': row[1].toString(),
            'title': row[2].toString(),

            'views':
            row.length > 3
                ? toInt(row[3])
                : 0,

            'likes':
            row.length > 4
                ? toInt(row[4])
                : 0,

            'stocks':
            row.length > 5
                ? toInt(row[5])
                : 0,

            'comments':
            row.length > 6
                ? toInt(row[6])
                : 0,

            'created_at':
            row.length > 7
                ? row[7].toString()
                : '',

            'updated_at':
            row.length > 8
                ? row[8].toString()
                : '',

            'timestamp':
            row.length > 9
                ? row[9].toString()
                : '',
          },
        );
      } catch (e, st) {
        print('snapshots error row[$i]');
        print(row);
        print(e);
        print(st);

        rethrow;
      }
    }
  }

  /// =========================
  /// events
  /// =========================

  Future<void> importEvents(Database db, File file) async {
    final rows = await readCsv(file);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      print('events row[$i]: $row');

      try {
        int? newSyncId;

        if (row.length > 1 &&
            row[1] != null &&
            row[1].toString().isNotEmpty) {
          final oldSyncId =
          int.tryParse(row[1].toString());

          if (oldSyncId != null) {
            newSyncId = _remapSyncId(oldSyncId);
          }
        }

        await db.insert(
          'events',
          {
            'sync_id': newSyncId,

            'article_id':
            row.length > 2
                ? row[2].toString()
                : '',

            'type':
            row.length > 3
                ? row[3].toString()
                : 'other',

            'memo':
            row.length > 4
                ? row[4].toString()
                : '',

            'source':
            row.length > 5
                ? row[5].toString()
                : 'manual',

            'event_at':
            row.length > 6
                ? row[6].toString()
                : '',

            'created_at':
            row.length > 7
                ? row[7].toString()
                : DateTime.now().toIso8601String(),
          },
        );
      } catch (e, st) {
        print('events error row[$i]');
        print(row);
        print(e);
        print(st);

        rethrow;
      }
    }
  }

  /// =========================
  /// tags
  /// =========================

  Future<void> importTags(Database db, File file) async {
    final rows = await readCsv(file);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      print('tags row[$i]: $row');

      try {
        final oldSyncId =
            int.tryParse(row[0].toString()) ?? 0;

        final newSyncId =
        _remapSyncId(oldSyncId);

        await db.insert(
          'tags',
          {
            'sync_id': newSyncId,
            'article_id': row[1].toString(),
            'tag': row[2].toString(),
          },
        );
      } catch (e, st) {
        print('tags error row[$i]');
        print(row);
        print(e);
        print(st);

        rethrow;
      }
    }
  }
  Future<void> printCounts(Database db, String label) async {
    print('========== $label ==========');

    final tables = [
      'articles',
      'snapshots',
      'events',
      'tags',
      'sync_sessions',
    ];

    for (final table in tables) {
      try {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $table',
        );

        print('$table: ${result.first['count']}');
      } catch (e) {
        print('$table ERROR');
        print(e);
      }
    }

    print('========================');
  }
}