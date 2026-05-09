import 'package:flutter/material.dart';

import '../services/db_service.dart';

class SyncDataPage extends StatefulWidget {
  const SyncDataPage({super.key});

  @override
  State<SyncDataPage> createState() =>
      _SyncDataPageState();
}

class _SyncDataPageState
    extends State<SyncDataPage> {
  List<String> timestamps = [];

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final db =
    await DbService.instance.database;

    final result = await db.rawQuery('''
      SELECT DISTINCT timestamp
      FROM snapshots
      ORDER BY timestamp DESC
    ''');

    timestamps = result
        .map(
          (e) =>
          e['timestamp'].toString(),
    )
        .toList();

    setState(() {});
  }

  Future<void> deleteSync(
      String timestamp,
      ) async {
    final db =
    await DbService.instance.database;

    await db.delete(
      'snapshots',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('同期データ一覧'),
      ),

      body: ListView.builder(
        itemCount: timestamps.length,

        itemBuilder: (context, index) {
          final timestamp =
          timestamps[index];

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.sync,
              ),

              title: Text(timestamp),

              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                ),

                onPressed: () async {
                  final ok =
                  await showDialog<bool>(
                    context: context,

                    builder: (_) {
                      return AlertDialog(
                        title: const Text(
                          '削除確認',
                        ),

                        content:
                        const Text(
                          'この同期データを削除しますか？',
                        ),

                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },

                            child:
                            const Text(
                              'キャンセル',
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },

                            child:
                            const Text(
                              '削除',
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (ok == true) {
                    await deleteSync(
                      timestamp,
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}