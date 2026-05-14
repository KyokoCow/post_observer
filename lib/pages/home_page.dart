import 'package:flutter/material.dart';

import '../pages/detail_page.dart';
import '../pages/settings_page.dart';

import '../services/analytics_service.dart';
import '../services/auto_sync_service.dart';
import '../services/sync_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final syncService = SyncService();
  final analytics = AnalyticsService();

  List<Map<String, dynamic>> articles = [];

  bool loading = false;

  /// cache
  Map<String, int> diffCache = {};
  Map<String, List<String>> tagCache = {};

  /// =========================
  /// refresh
  /// =========================
  Future<void> refresh({bool showSnackBar = true}) async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      await syncService.sync();
      await reloadOnly();

      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同期完了')),
        );
      }
    } catch (e) {
      debugPrint('SYNC ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同期エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// =========================
  /// DB再読み込みのみ
  /// =========================
  Future<void> reloadOnly() async {
    articles = await analytics.latestArticles();

    /// ❌ sessions削除（完全廃止）
    /// session = await analytics.latestSession(); ←削除

    diffCache.clear();
    tagCache.clear();

    for (final a in articles) {
      final id = a['article_id'].toString();

      try {
        diffCache[id] = await analytics.dailyIncrease(id);
        tagCache[id] = await analytics.tags(id);
      } catch (e) {
        diffCache[id] = 0;
        tagCache[id] = [];
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// =========================
  /// init
  /// =========================
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await refresh(showSnackBar: false);

    await AutoSyncService.instance.start();
  }

  /// =========================
  /// dispose
  /// =========================
  @override
  void dispose() {
    AutoSyncService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qiita Observer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );

              await reloadOnly();
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: refresh,
        child: const Icon(Icons.sync),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          /// =========================
          /// articles
          /// =========================
          ...articles.map((a) {
            final id = a['article_id'].toString();
            final diff = diffCache[id] ?? 0;

            return Card(
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(
                        articleId: id,
                        title: a['title'].toString(),
                      ),
                    ),
                  );
                },

                title: Text(a['title'].toString()),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    Text('PV ${a['views']} (+$diff)'),
                    Text('LGTM ${a['likes']}'),
                    Text('Stock ${a['stocks']}'),
                    Text('Comments ${a['comments']}'),

                    const SizedBox(height: 8),

                    Text(
                      'Created: ${a['created_at']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    Text(
                      'Updated: ${a['updated_at']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (tagCache[id] ?? [])
                          .map((tag) => Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 10),
                        ),
                        visualDensity: VisualDensity.compact,
                      ))
                          .toList(),
                    ),
                  ],
                ),

                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }),
        ],
      ),
    );
  }
}