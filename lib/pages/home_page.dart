import 'package:flutter/material.dart';

import '../pages/detail_page.dart';
import '../pages/settings_page.dart';

import '../services/analytics_service.dart';
import '../services/auto_sync_service.dart';
import '../services/sync_service.dart';

class HomePage extends StatefulWidget {

  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {

  final syncService =
  SyncService();

  final analytics =
  AnalyticsService();

  List<Map<String, dynamic>>
  articles = [];

  Map<String, dynamic>? session;

  bool loading = false;

  /// =========================
  /// cache
  /// =========================

  Map<String, int>
  diffCache = {};

  Map<String, List<String>>
  tagCache = {};

  /// =========================
  /// refresh
  /// =========================

  Future<void> refresh({
    bool showSnackBar = true,
  }) async {

    if (mounted) {

      setState(() {
        loading = true;
      });
    }

    try {

      await syncService.sync();

      await reloadOnly();

      if (showSnackBar &&
          mounted) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(
            content:
            Text('同期完了'),
          ),
        );
      }

    } catch (e) {

      debugPrint(
        'SYNC ERROR: $e',
      );

      if (mounted) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(
            content:
            Text('同期エラー: $e'),
          ),
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

    articles =
    await analytics.latestArticles();

    session =
    await analytics.latestSession();

    /// cache rebuild

    diffCache.clear();

    tagCache.clear();

    for (final a in articles) {

      final id =
      a['article_id'] as String;

      try {

        diffCache[id] =
        await analytics.dailyIncrease(id);

        tagCache[id] =
        await analytics.tags(id);

      } catch (e) {

        diffCache[id] = 0;
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

    /// 初回同期

    await refresh(
      showSnackBar: false,
    );

    /// 自動同期開始

    await AutoSyncService
        .instance
        .start();
  }

  /// =========================
  /// dispose
  /// =========================

  @override
  void dispose() {

    AutoSyncService
        .instance
        .stop();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {

    return Scaffold(

      appBar: AppBar(

        title:
        const Text(
          'Qiita Observer',
        ),

        actions: [

          IconButton(

            icon:
            const Icon(
              Icons.settings,
            ),

            onPressed: () async {

              await Navigator.push(

                context,

                MaterialPageRoute(
                  builder: (_) =>
                  const SettingsPage(),
                ),
              );

              /// 設定変更後再読込

              await reloadOnly();
            },
          ),
        ],
      ),

      floatingActionButton:
      FloatingActionButton(

        onPressed: () {

          refresh();
        },

        child:
        const Icon(
          Icons.sync,
        ),
      ),

      body: loading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : ListView(

        children: [

          /// =========================
          /// user info
          /// =========================

          if (session != null)

            Card(

              margin:
              const EdgeInsets.all(12),

              child: Padding(

                padding:
                const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'あなたの情報',

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      '記事数: '
                          '${session!['total_articles']}',
                    ),

                    Text(
                      '総PV: '
                          '${session!['total_views']}',
                    ),

                    Text(
                      '総LGTM: '
                          '${session!['total_likes']}',
                    ),

                    Text(
                      '総Stock: '
                          '${session!['total_stocks']}',
                    ),

                    Text(
                      'Follower: '
                          '${session!['followers']}',
                    ),
                  ],
                ),
              ),
            ),

          /// =========================
          /// articles
          /// =========================

          ...articles.map((a) {

            final id =
            a['article_id'] as String;

            final diff =
                diffCache[id] ?? 0;

            return Card(

              child: ListTile(

                onTap: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (_) =>
                          DetailPage(

                            articleId: id,

                            title:
                            a['title']
                                .toString(),
                          ),
                    ),
                  );
                },

                title: Text(
                  a['title']
                      .toString(),
                ),

                subtitle: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'PV ${a['views']} '
                          '(+$diff)',
                    ),

                    Text(
                      'LGTM ${a['likes']}',
                    ),

                    Text(
                      'Stock ${a['stocks']}',
                    ),

                    Text(
                      'Comments '
                          '${a['comments']}',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(

                      'Created: '
                          '${a['created_at']}',

                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey,
                      ),
                    ),

                    Text(

                      'Updated: '
                          '${a['updated_at']}',

                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Wrap(

                      spacing: 4,

                      runSpacing: 4,

                      children:
                      (tagCache[id] ?? [])
                          .map((tag) {

                        return Chip(

                          label: Text(

                            tag,

                            style:
                            const TextStyle(
                              fontSize: 10,
                            ),
                          ),

                          visualDensity:
                          VisualDensity.compact,
                        );

                      }).toList(),
                    ),
                  ],
                ),

                trailing:
                const Icon(
                  Icons.chevron_right,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}