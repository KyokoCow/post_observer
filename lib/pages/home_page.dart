import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../pages/detail_page.dart';
import '../pages/settings_page.dart';

import '../services/analytics_service.dart';
import '../services/auto_sync_service.dart';
import '../services/db_service.dart';
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
  List<Map<String, dynamic>>
  rankingArticles = [];

  bool loading = false;

  /// cache
  Map<String, int> diffCache = {};
  Map<String, List<String>> tagCache = {};
  Map<String, dynamic>? user;
  Map<String, dynamic>? session;
  List<FlSpot> pvSpots = [];

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

    final userData =
    await DbService.instance.getUser();

    debugPrint(userData.toString());

    user = userData;

    session =
    await analytics.latestSession();

    debugPrint(session.toString());
    debugPrint(
      (await analytics.dailyPvTrend())
          .toString(),
    );

    final trend =
    await analytics.dailyPvTrend();

    pvSpots = List.generate(
      trend.length,
          (i) {

        final item = trend[i];

        final views =
        (item['views'] ?? 0) as int;

        return FlSpot(
          i.toDouble(),
          views.toDouble(),
        );
      },
    );
    debugPrint(pvSpots.toString());

    articles =
    await analytics.latestArticles();

    rankingArticles =
    List<Map<String, dynamic>>
        .from(articles);

    rankingArticles.sort((a, b) {

      final av =
      (a['views'] ?? 0) as int;

      final bv =
      (b['views'] ?? 0) as int;

      return bv.compareTo(av);
    });

    diffCache.clear();
    tagCache.clear();

    for (final a in articles) {
      final id = a['article_id'].toString();

      try {
        diffCache[id] =
        await analytics.dailyIncrease(id);

        tagCache[id] =
        await analytics.tags(id);

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
          if (user != null)
            Card(
              margin: const EdgeInsets.all(12),

              child: Padding(
                padding: const EdgeInsets.all(12),

                child: Row(
                  children: [

                    CircleAvatar(
                      radius: 32,

                      backgroundImage: NetworkImage(
                        user!['profile_image_url']
                            .toString(),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(
                          user!['name'].toString(),

                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '@${user!['id']}',

                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (session != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),

              child: Row(
                children: [

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          children: [

                            const Text(
                              'PV',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              session!['total_views']
                                  .toString(),

                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          children: [

                            const Text(
                              'LGTM',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              session!['total_likes']
                                  .toString(),

                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          children: [

                            const Text(
                              'Stock',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              session!['total_stocks']
                                  .toString(),

                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (pvSpots.isNotEmpty)
            SizedBox(
              height: 200,

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),

                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),

                    child: LineChart(
                      LineChartData(

                        gridData:
                        const FlGridData(
                          show: false,
                        ),

                        borderData:
                        FlBorderData(
                          show: false,
                        ),

                        titlesData:
                        const FlTitlesData(
                          show: false,
                        ),

                        lineBarsData: [

                          LineChartBarData(
                            spots: pvSpots,

                            isCurved: true,

                            barWidth: 3,

                            dotData:
                            const FlDotData(
                              show: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Card(
            margin: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
            ),

            child: Column(
              children: List.generate(

                rankingArticles.take(5).length,

                    (i) {

                  final a =
                  rankingArticles[i];

                  return Column(
                    children: [

                      ListTile(

                        leading: CircleAvatar(
                          child: Text(
                            '${i + 1}',
                          ),
                        ),

                        title: Text(
                          a['title']
                              .toString(),
                        ),

                        subtitle: Text(
                          'PV ${a['views']}',
                        ),

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailPage(
                                    articleId:
                                    a['article_id']
                                        .toString(),

                                    title:
                                    a['title']
                                        .toString(),
                                  ),
                            ),
                          );
                        },
                      ),

                      if (i != 4)
                        const Divider(
                          height: 1,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

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