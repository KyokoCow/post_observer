import 'package:flutter/material.dart';

import '../services/auto_sync_service.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

import 'event_page.dart';
import 'sync_data_page.dart';

class SettingsPage extends StatefulWidget {

  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {

  final exportService =
  ExportService();

  final importService =
  ImportService();

  bool autoSyncEnabled = false;

  int autoSyncMinutes = 60;

  bool loading = true;

  /// =========================
  /// 初期読み込み
  /// =========================

  @override
  void initState() {

    super.initState();

    loadSettings();
  }

  Future<void> loadSettings() async {

    final enabled =
    await DbService.instance.getSetting(
      'auto_sync_enabled',
    );

    final minutes =
    await DbService.instance.getSetting(
      'auto_sync_minutes',
    );

    autoSyncEnabled =
        enabled == 'true';

    autoSyncMinutes =
        int.tryParse(
          minutes ?? '60',
        ) ??
            60;

    setState(() {
      loading = false;
    });
  }

  /// =========================
  /// 保存
  /// =========================

  Future<void> saveSettings() async {

    await DbService.instance.setSetting(
      'auto_sync_enabled',
      autoSyncEnabled.toString(),
    );

    await DbService.instance.setSetting(
      'auto_sync_minutes',
      autoSyncMinutes.toString(),
    );

    await AutoSyncService
        .instance
        .restart();
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {

      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text('設定'),
      ),

      body: ListView(

        children: [

          /// =========================
          /// Auto Sync
          /// =========================

          const Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),

            child: Text(
              '自動同期',

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          SwitchListTile(

            secondary:
            const Icon(Icons.sync),

            title: const Text(
              '自動同期を有効化',
            ),

            subtitle: const Text(
              'アプリ起動中のみ動作',
            ),

            value: autoSyncEnabled,

            onChanged: (v) async {

              setState(() {
                autoSyncEnabled = v;
              });

              await saveSettings();
            },
          ),

          ListTile(

            leading:
            const Icon(Icons.timer),

            title: const Text(
              '同期間隔',
            ),

            subtitle: Text(
              '$autoSyncMinutes 分',
            ),

            trailing:
            DropdownButton<int>(

              value: autoSyncMinutes,

              items: const [

                DropdownMenuItem(
                  value: 5,
                  child: Text('5分'),
                ),

                DropdownMenuItem(
                  value: 15,
                  child: Text('15分'),
                ),

                DropdownMenuItem(
                  value: 30,
                  child: Text('30分'),
                ),

                DropdownMenuItem(
                  value: 60,
                  child: Text('1時間'),
                ),

                DropdownMenuItem(
                  value: 180,
                  child: Text('3時間'),
                ),
              ],

              onChanged:
              autoSyncEnabled
                  ? (v) async {

                if (v == null) {
                  return;
                }

                setState(() {
                  autoSyncMinutes = v;
                });

                await saveSettings();
              }
                  : null,
            ),
          ),

          const Divider(),

          /// =========================
          /// events
          /// =========================

          ListTile(

            leading:
            const Icon(Icons.event),

            title:
            const Text('投稿イベント'),

            trailing:
            const Icon(
              Icons.chevron_right,
            ),

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

          /// =========================
          /// sync data
          /// =========================

          ListTile(

            leading:
            const Icon(Icons.storage),

            title:
            const Text('同期データ一覧'),

            trailing:
            const Icon(
              Icons.chevron_right,
            ),

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

          const Divider(),

          /// =========================
          /// export
          /// =========================

          ListTile(

            leading:
            const Icon(Icons.upload),

            title:
            const Text('バックアップ作成'),

            onTap: () async {

              await exportService
                  .exportCsv();

              if (context.mounted) {

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(

                  const SnackBar(
                    content: Text(
                      'バックアップ作成完了',
                    ),
                  ),
                );
              }
            },
          ),

          /// =========================
          /// import
          /// =========================

          ListTile(

            leading:
            const Icon(Icons.download),

            title:
            const Text('バックアップ復元'),

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
                      '現在のデータを削除して復元しますか？',
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
                  .importAll();

              if (context.mounted) {

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(

                  const SnackBar(
                    content: Text(
                      'バックアップ復元完了',
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