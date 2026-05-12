import 'package:flutter/material.dart';

import '../pages/detail_page.dart';
import '../services/analytics_service.dart';
import '../services/sync_service.dart';
import '../pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final syncService = SyncService();
  final analytics = AnalyticsService();

  List<Map<String, dynamic>> articles = [];
  Map<String, dynamic>? session;

  bool loading = false;

  // ★ PV差分キャッシュ（FutureBuilder廃止）
  Map<String, int> diffCache = {};

  Future<void> refresh() async {
    setState(() {
      loading = true;
    });

    try {
      await syncService.sync();

      articles = await analytics.latestArticles();
      session = await analytics.latestSession();

      // ★ 差分をまとめて取得（FutureBuilder廃止）
      diffCache.clear();

      for (final a in articles) {
        final id = a['article_id'] as String;

        try {
          diffCache[id] = await analytics.dailyIncrease(id);
        } catch (e) {
          diffCache[id] = 0;
        }
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同期完了')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qiita Observer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: refresh,
        child: const Icon(Icons.sync),
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        children: [

          /// =========================
          /// ユーザー情報
          /// =========================

          if (session != null)
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'あなたの情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '記事数: ${session!['total_articles']}',
                    ),

                    Text(
                      '総PV: ${session!['total_views']}',
                    ),

                    Text(
                      '総LGTM: ${session!['total_likes']}',
                    ),

                    Text(
                      '総Stock: ${session!['total_stocks']}',
                    ),

                    Text(
                      'Follower: ${session!['followers']}',
                    ),
                  ],
                ),
              ),
            ),

          /// =========================
          /// 記事一覧
          /// =========================

          ...articles.map((a) {
            final id = a['article_id'] as String;
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

                title: Text(
                  a['title'].toString(),
                ),

                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PV ${a['views']} (+$diff)',
                    ),

                    Text(
                      'LGTM ${a['likes']}',
                    ),

                    Text(
                      'Stock ${a['stocks']}',
                    ),
                  ],
                ),

                trailing:
                const Icon(Icons.chevron_right),
              ),
            );
          }),
        ],
      ),
    );
  }
}