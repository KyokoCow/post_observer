import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/db_service.dart';

class DetailPage extends StatefulWidget {
  final String articleId;
  final String title;

  const DetailPage({
    super.key,
    required this.articleId,
    required this.title,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final analytics = AnalyticsService();

  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    debugPrint("========== DETAIL LOAD START ==========");
    debugPrint("articleId = ${widget.articleId}");

    final db = await DbService.instance.database;

    // ★ DB構造チェック（安全診断）
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
    );
    debugPrint("TABLES = $tables");

    final columns = await db.rawQuery(
        "PRAGMA table_info(events)"
    );
    debugPrint("EVENTS COLUMNS = $columns");

    history = await analytics.history(widget.articleId);

    debugPrint("history length = ${history.length}");

    final syncIds = history
        .map((e) => e['sync_id'] as int?)
        .whereType<int>()
        .toSet()
        .toList();

    debugPrint("syncIds = $syncIds");

    if (syncIds.isEmpty) {
      events = [];
      setState(() {});
      return;
    }

    final placeholders =
    List.filled(syncIds.length, '?').join(',');

    /// ★★★ ここが完全修正ポイント（snapshot_id → sync_id）★★★
    final result = await db.rawQuery(
      '''
      SELECT *
      FROM events
      WHERE sync_id IN ($placeholders)
      ORDER BY timestamp ASC
      ''',
      syncIds,
    );

    events = result;

    debugPrint("events length = ${events.length}");
    debugPrint("========== DETAIL LOAD END ==========");

    setState(() {});
  }

  IconData _icon(String type) {
    switch (type) {
      case 'post':
        return Icons.publish;
      case 'share':
        return Icons.share;
      case 'update':
        return Icons.edit;
      default:
        return Icons.circle;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'post':
        return Colors.blue;
      case 'share':
        return Colors.green;
      case 'update':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];

    double maxY = 10;

    for (int i = 0; i < history.length; i++) {
      final y = (history[i]['views'] as int).toDouble();
      if (y > maxY) maxY = y;

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: y,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    maxY += 20;

    /// ★ sync_idベースでイベント→index変換
    final eventByIndex = <int, List<Map<String, dynamic>>>{};

    for (final e in events) {
      final syncId = e['sync_id'] as int?;
      if (syncId == null) continue;

      final index = history.indexWhere(
            (h) => h['sync_id'] == syncId,
      );

      if (index == -1) continue;

      eventByIndex.putIfAbsent(index, () => []);
      eventByIndex[index]!.add(e);
    }

    final chartWidth =
    history.isEmpty ? 300.0 : history.length * 70.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toInt().toString()),
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 70,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= history.length) {
                          return const SizedBox();
                        }

                        final timestamp = DateTime.parse(
                          history[index]['timestamp'],
                        );

                        final evts = eventByIndex[index] ?? [];

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${timestamp.month}/${timestamp.day}\n'
                                  '${timestamp.hour.toString().padLeft(2, '0')}:'
                                  '${timestamp.minute.toString().padLeft(2, '0')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),

                            const SizedBox(height: 4),

                            if (evts.isNotEmpty)
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: evts.map((e) {
                                  final type = e['type'] as String;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    child: Icon(
                                      _icon(type),
                                      size: 14,
                                      color: _color(type),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                barGroups: bars,
              ),
            ),
          ),
        ),
      ),
    );
  }
}