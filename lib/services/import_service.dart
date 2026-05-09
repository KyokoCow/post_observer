import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import 'db_service.dart';

class ImportService {
  Future<void> importSnapshots() async {
    final result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) {
      return;
    }

    final path =
        result.files.single.path;

    if (path == null) {
      return;
    }

    final db =
    await DbService.instance.database;

    await db.delete('snapshots');

    final file = File(path);

    final content =
    await file.readAsString();

    final rows =
    const CsvToListConverter()
        .convert(content);

    for (int i = 1;
    i < rows.length;
    i++) {
      final row = rows[i];

      await db.insert(
        'snapshots',
        {
          'article_id': row[0],
          'title': row[1],
          'views': row[2],
          'likes': row[3],
          'stocks': row[4],
          'timestamp': row[5],
        },
      );
    }
  }

  Future<void> importEvents() async {
    final result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) {
      return;
    }

    final path =
        result.files.single.path;

    if (path == null) {
      return;
    }

    final db =
    await DbService.instance.database;

    await db.delete('events');

    final file = File(path);

    final content =
    await file.readAsString();

    final rows =
    const CsvToListConverter()
        .convert(content);

    for (int i = 1;
    i < rows.length;
    i++) {
      final row = rows[i];

      await db.insert(
        'events',
        {
          'timestamp': row[0],
          'type': row[1],
          'memo': row[2],
        },
      );
    }
  }
}