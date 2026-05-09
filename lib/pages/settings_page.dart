import 'package:flutter/material.dart';
import 'sync_data_page.dart';
import '../services/export_service.dart';
import 'event_page.dart';
import '../services/import_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});


  @override
  Widget build(BuildContext context) {
    final exportService = ExportService();
    final importService = ImportService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('投稿イベント'),
            trailing:
            const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const EventPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('同期データ一覧'),
            trailing:
            const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const SyncDataPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.upload),
            title:
            const Text('CSVエクスポート'),


            onTap: () async {
              await exportService.exportCsv();

              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'CSVエクスポート完了',
                    ),
                  ),
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.download),
            title:
            const Text('同期データ復元'),

            onTap: () async {
              final ok =
              await showDialog<bool>(
                context: context,

                builder: (_) {
                  return AlertDialog(
                    title: const Text(
                      '復元確認',
                    ),

                    content: const Text(
                      '現在のスナップショットを\n'
                          '削除して復元しますか？',
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },

                        child: const Text(
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

                        child: const Text(
                          '実行',
                        ),
                      ),
                    ],
                  );
                },
              );

              if (ok != true) {
                return;
              }

              await importService
                  .importSnapshots();

              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'スナップショット復元完了',
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title:
            const Text('イベント復元'),

            onTap: () async {
              final ok =
              await showDialog<bool>(
                context: context,

                builder: (_) {
                  return AlertDialog(
                    title: const Text(
                      '復元確認',
                    ),

                    content: const Text(
                      '現在のイベントを\n'
                          '削除して復元しますか？',
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },

                        child: const Text(
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

                        child: const Text(
                          '実行',
                        ),
                      ),
                    ],
                  );
                },
              );

              if (ok != true) {
                return;
              }

              await importService
                  .importEvents();

              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'イベント復元完了',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}