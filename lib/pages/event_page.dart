import 'package:flutter/material.dart';

import '../services/db_service.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() =>
      _EventPageState();
}

class _EventPageState
    extends State<EventPage> {
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final db =
    await DbService.instance.database;

    events = await db.query(
      'events',
      orderBy: 'timestamp DESC',
    );

    setState(() {});
  }

  Future<void> deleteEvent(int id) async {
    final db =
    await DbService.instance.database;

    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントログ'),
      ),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];

          final syncId = e['sync_id'];

          return Card(
            child: ListTile(
              title: Text(
                e['type'].toString(),
              ),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'sync_id: $syncId',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  Text(
                    e['timestamp'].toString(),
                  ),

                  if ((e['memo'] ?? '')
                      .toString()
                      .isNotEmpty)
                    Text(
                      e['memo'].toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),

              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final ok =
                  await showDialog<bool>(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title:
                        const Text('削除確認'),
                        content: const Text(
                            'このイベントを削除しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(
                                    context, false),
                            child:
                            const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(
                                    context, true),
                            child:
                            const Text('削除'),
                          ),
                        ],
                      );
                    },
                  );

                  if (ok == true) {
                    await deleteEvent(
                      e['id'] as int,
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