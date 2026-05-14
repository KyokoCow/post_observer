import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/event_source.dart';
import '../models/event_type.dart';

import '../services/db_service.dart';
import '../models/article.dart';

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

  Future<void> showAddDialog() async {

    final articles =
    await DbService.instance
        .getArticles();

    EventType selectedType =
        EventType.other;

    DateTime selectedDateTime =
    DateTime.now();

    String? selectedArticleId;

    final memoController =
    TextEditingController();

    final result =
    await showDialog<bool>(
      context: context,

      builder: (_) {

        return StatefulBuilder(

          builder: (
              context,
              setDialogState,
              ) {

            return AlertDialog(

              title:
              const Text('イベント追加'),

              content: SingleChildScrollView(

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    /// type

                    DropdownButtonFormField<
                        EventType>(

                      value: selectedType,

                      decoration:
                      const InputDecoration(
                        labelText:
                        'イベント種類',
                      ),

                      items:
                      EventType.values
                          .map((type) {

                        return DropdownMenuItem(
                          value: type,

                          child: Text(
                            type.label,
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {

                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedType =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    /// related article

                    DropdownButtonFormField<
                        String?>(

                      value:
                      selectedArticleId,

                      decoration:
                      const InputDecoration(
                        labelText:
                        '関連記事（任意）',
                      ),

                      items: [

                        const DropdownMenuItem(
                          value: null,

                          child: Text(
                            'なし',
                          ),
                        ),

                        ...articles.map(
                              (article) {

                            return DropdownMenuItem(

                              value:
                              article.articleId,

                              child: SizedBox(
                                width: 250,

                                child: Text(
                                  article.title,

                                  overflow:
                                  TextOverflow
                                      .ellipsis,

                                  maxLines: 1,
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      onChanged: (value) {

                        setDialogState(() {

                          selectedArticleId =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    /// datetime

                    ListTile(

                      contentPadding:
                      EdgeInsets.zero,

                      title: const Text(
                        'イベント時刻',
                      ),

                      subtitle: Text(
                        selectedDateTime
                            .toString(),
                      ),

                      trailing: const Icon(
                        Icons.calendar_month,
                      ),

                      onTap: () async {

                        final date =
                        await showDatePicker(
                          context: context,

                          initialDate:
                          selectedDateTime,

                          firstDate:
                          DateTime(2020),

                          lastDate:
                          DateTime(2100),
                        );

                        if (date == null) {
                          return;
                        }

                        final time =
                        await showTimePicker(
                          context: context,

                          initialTime:
                          TimeOfDay.fromDateTime(
                            selectedDateTime,
                          ),
                        );

                        if (time == null) {
                          return;
                        }

                        setDialogState(() {

                          selectedDateTime =
                              DateTime(
                                date.year,
                                date.month,
                                date.day,

                                time.hour,
                                time.minute,
                              );
                        });
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    /// memo

                    TextField(
                      controller:
                      memoController,

                      decoration:
                      const InputDecoration(
                        labelText:
                        'メモ（任意）',

                        border:
                        OutlineInputBorder(),
                      ),

                      maxLines: 3,
                    ),
                  ],
                ),
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

                FilledButton(
                  onPressed: () {

                    Navigator.pop(
                      context,
                      true,
                    );
                  },

                  child:
                  const Text(
                    '追加',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    await DbService.instance.insertEvent(

      AppEvent(

        syncId: null,

        articleId:
        selectedArticleId,

        type: selectedType,

        memo:
        memoController
            .text
            .trim()
            .isEmpty
            ? null
            : memoController
            .text
            .trim(),

        source:
        EventSource.manual,

        eventAt:
        selectedDateTime,

        createdAt:
        DateTime.now(),
      ),
    );

    await load();
  }

  IconData _icon(EventType type) {

    switch (type) {

      case EventType.post:
        return Icons.publish;

      case EventType.update:
        return Icons.edit;

      case EventType.share:
        return Icons.share;

      case EventType.other:
        return Icons.circle;
    }
  }

  Color _color(EventType type) {

    switch (type) {

      case EventType.post:
        return Colors.blue;

      case EventType.update:
        return Colors.orange;

      case EventType.share:
        return Colors.green;

      case EventType.other:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'イベント一覧',
        ),
      ),

      floatingActionButton:
      FloatingActionButton(

        onPressed: showAddDialog,

        child: const Icon(
          Icons.add,
        ),
      ),

      body: ListView.builder(
        itemCount: events.length,

        itemBuilder: (context, index) {

          final e = events[index];

          return Card(
            child: ListTile(

              leading: Icon(
                _icon(e.type),
                color: _color(e.type),
              ),

              title: Text(
                e.type.label,
              ),

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

                  /// event_at
                  Text(
                    e.eventAt.toString(),
                  ),

                  /// source
                  Text(
                    'source: ${e.source.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
                icon: const Icon(
                  Icons.delete,
                ),

                onPressed: () async {

                  final ok =
                  await showDialog<bool>(
                    context: context,

                    builder: (_) {

                      return AlertDialog(
                        title:
                        const Text(
                          '削除確認',
                        ),

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
                            const Text(
                              '削除',
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (ok == true &&
                      e.id != null) {

                    await deleteEvent(
                      e.id!,
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