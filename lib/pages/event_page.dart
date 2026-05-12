import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/db_service.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() =>
      _EventPageState();
}

class _EventPageState
    extends State<EventPage> {

  List<AppEvent> events = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    events =
    await DbService.instance.getAllEvents();

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

          return Card(
            child: ListTile(

              title: Text(e.type),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  /// article_id
                  if (e.articleId != null)
                    Text(
                      'article_id: ${e.articleId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                  /// sync_id
                  if (e.syncId != null)
                    Text(
                      'sync_id: ${e.syncId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                  /// timestamp
                  Text(
                    e.timestamp.toString(),
                  ),

                  /// memo
                  if ((e.memo ?? '')
                      .isNotEmpty)
                    Text(
                      e.memo!,
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
                          'このイベントを削除しますか？',
                        ),

                        actions: [

                          TextButton(
                            onPressed: () =>
                                Navigator.pop(
                                  context,
                                  false,
                                ),

                            child:
                            const Text(
                              'キャンセル',
                            ),
                          ),

                          TextButton(
                            onPressed: () =>
                                Navigator.pop(
                                  context,
                                  true,
                                ),

                            child:
                            const Text('削除'),
                          ),
                        ],
                      );
                    },
                  );

                  if (ok == true &&
                      e.id != null) {

                    await deleteEvent(e.id!);
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