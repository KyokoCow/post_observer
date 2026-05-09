import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';

import 'db_service.dart';

class ExportService {
  Future<void> exportCsv() async {
    final db =
    await DbService.instance.database;

    final rows = await db.query(
      'snapshots',
      orderBy: 'timestamp ASC',
    );

    final data = <List<dynamic>>[];

    data.add([
      'article_id',
      'title',
      'views',
      'likes',
      'stocks',
      'timestamp',
    ]);

    for (final row in rows) {
      data.add([
        row['article_id'],
        row['title'],
        row['views'],
        row['likes'],
        row['stocks'],
        row['timestamp'],
      ]);
    }

    final csv =
    const ListToCsvConverter()
        .convert(data);

    final now = DateTime.now();

    final fileName =
        'qiita_export_'
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}.csv';

    // Android Downloads
    final dir =
    Directory('/storage/emulated/0/Download');

    if (!await dir.exists()) {
      await dir.create(
        recursive: true,
      );
    }

    final path = join(
      dir.path,
      fileName,
    );

    final file = File(path);

    await file.writeAsString(
      '\uFEFF$csv',
    );

    await Share.shareXFiles([
      XFile(path),
    ]);
  }
}