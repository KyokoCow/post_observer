import 'package:flutter/material.dart';

import '../services/db_service.dart';

class SyncDataPage extends StatefulWidget {
  const SyncDataPage({super.key});

  @override
  State<SyncDataPage> createState() => _SyncDataPageState();
}

class _SyncDataPageState extends State<SyncDataPage> {
  List<Map<String, dynamic>> snapshots = [];

  Map<int, List<Map<String, dynamic>>> eventMap = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db = await DbService.instance.database;

    // ★ sync_idごとに最新1件だけ取得（正しい書き方）
    final result = await db.rawQuery('''
      SELECT *
      FROM snapshots
      WHERE id IN (
        SELECT MAX(id)
        FROM snapshots
        GROUP BY sync_id
      )
      ORDER BY timestamp DESC
    ''');

    snapshots = result;

    final eventResult = await db.query('events');

    eventMap.clear();

    for (final e in eventResult) {
      final syncId = e['sync_id'] as int?;
      if (syncId == null) continue;

      eventMap.putIfAbsent(syncId, () => []);
      eventMap[syncId]!.add(e);
    }

    setState(() {});
  }

  Future<void> deleteSync(int syncId) async {
    final db = await DbService.instance.database;

    await db.delete(
      'snapshots',
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );

    await db.delete(
      'events',
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );

    await load();
  }

  Future<void> addEvent(int syncId, String type) async {
    final db = await DbService.instance.database;

    await db.insert(
      'events',
      {
        'sync_id': syncId,
        'type': type,
        'memo': '',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Widget _tag(String type) {
    late Color color;
    late String label;

    switch (type) {
      case 'post':
        color = Colors.blue;
        label = '投稿';
        break;
      case 'share':
        color = Colors.green;
        label = '共有';
        break;
      case 'update':
        color = Colors.orange;
        label = '更新';
        break;
      case 'other':
        color = Colors.purple;
        label = 'その他';
        break;
      default:
        color = Colors.grey;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddEventDialog(int syncId) {
    String type = 'post';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('イベント追加'),
              content: DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'post', child: Text('投稿')),
                  DropdownMenuItem(value: 'share', child: Text('共有')),
                  DropdownMenuItem(value: 'update', child: Text('更新')),
                  DropdownMenuItem(value: 'other', child: Text('その他')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => type = v);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    await addEvent(syncId, type);

                    if (context.mounted) {
                      Navigator.pop(context);
                      await load();
                    }
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同期データ一覧'),
      ),
      body: ListView.builder(
        itemCount: snapshots.length,
        itemBuilder: (context, index) {
          final s = snapshots[index];
          final syncId = s['sync_id'] as int;

          final events = eventMap[syncId] ?? [];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.sync),

              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['timestamp'].toString()),
                  const SizedBox(height: 4),

                  if (events.isEmpty)
                    const Text(
                      'イベントなし',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  else
                    Wrap(
                      children: events
                          .map((e) => _tag(e['type'].toString()))
                          .toList(),
                    ),
                ],
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddEventDialog(syncId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            title: const Text('削除確認'),
                            content: const Text('この同期データを削除しますか？'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('削除'),
                              ),
                            ],
                          );
                        },
                      );

                      if (ok == true) {
                        await deleteSync(syncId);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}