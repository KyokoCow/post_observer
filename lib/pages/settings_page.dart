import 'package:flutter/material.dart';
import 'sync_data_page.dart';
import '../services/export_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});


  @override
  Widget build(BuildContext context) {
    final exportService = ExportService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
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
            trailing:
            const Icon(Icons.chevron_right),
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
            const Text('CSVインポート'),
            trailing:
            const Icon(Icons.chevron_right),
            onTap: () {
              // TODO
            },
          ),
        ],
      ),
    );
  }
}