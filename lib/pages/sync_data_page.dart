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
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final db =
    await DbService.instance.database;

    rows = await db.query(
      'snapshots',
      orderBy: 'timestamp DESC',
    );

    setState(() {});
  }

  Future<void> deleteRow(int id) async {
    final db =
    await DbService.instance.database;

    await db.delete(
      'snapshots',
      where: 'id = ?',
      whereArgs: [id],
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
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];

          return Card(
            child: ListTile(
              title: Text(
                row['title']
                    ?.toString() ??
                    '',
              ),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    row['timestamp']
                        .toString(),
                  ),

                  Text(
                    'PV ${row['views']}  '
                        'LGTM ${row['likes']}  '
                        'Stock ${row['stocks']}',
                  ),
                ],
              ),

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
                          'このデータを削除しますか？',
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
                    await deleteRow(
                      row['id'] as int,
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