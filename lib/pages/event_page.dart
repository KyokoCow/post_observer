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

  final memoController =
  TextEditingController();

  String type = 'post';

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

  Future<void> addEvent() async {
    final db =
    await DbService.instance.database;

    await db.insert(
      'events',
      {
        'timestamp':
        DateTime.now().toIso8601String(),
        'type': type,
        'memo':
        memoController.text.trim(),
      },
    );

    memoController.clear();

    await load();
  }

  Future<void> deleteEvent(
      int id,
      ) async {
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
        title:
        const Text('投稿イベント'),
      ),

      floatingActionButton:
      FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title:
                const Text('イベント追加'),

                content: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: type,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'post',
                          child: Text(
                            '投稿',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'share',
                          child: Text(
                            '共有',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'update',
                          child: Text(
                            '更新',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(
                            'その他',
                          ),
                        ),
                      ],

                      onChanged: (v) {
                        if (v == null) {
                          return;
                        }

                        setState(() {
                          type = v;
                        });
                      },
                    ),

                    TextField(
                      controller:
                      memoController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'メモ',
                      ),
                    ),
                  ],
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    child:
                    const Text(
                      'キャンセル',
                    ),
                  ),

                  TextButton(
                    onPressed: () async {
                      await addEvent();

                      if (context.mounted) {
                        Navigator.pop(
                          context,
                        );
                      }
                    },

                    child:
                    const Text(
                      '保存',
                    ),
                  ),
                ],
              );
            },
          );
        },

        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        itemCount: events.length,

        itemBuilder: (context, index) {
          final e = events[index];

          return Card(
            child: ListTile(
              title: Text(
                '${e['type']}'
                    ' : '
                    '${e['memo']}',
              ),

              subtitle: Text(
                e['timestamp']
                    .toString(),
              ),

              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                ),

                onPressed: () async {
                  await deleteEvent(
                    e['id'] as int,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}