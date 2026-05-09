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

    final dir = Directory('/storage/emulated/0/Download');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await _exportSnapshots(db, dir.path, timestamp);
    await _exportEvents(db, dir.path, timestamp);
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
        row['timestamp'],
      ]);
    }

    final csv = const ListToCsvConverter().convert(data);

    final file = File(join(dirPath, 'snapshots_$timestamp.csv'));

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

    final file = File(join(dirPath, 'events_$timestamp.csv'));

    await file.writeAsString('\uFEFF$csv');
  }
}