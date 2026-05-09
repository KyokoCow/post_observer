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
    history = await analytics.history(
      widget.articleId,
    );

    final db =
    await DbService.instance.database;

    events = await db.query('events');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];

    double maxY = 10;

    for (int i = 0; i < history.length; i++) {
      final row = history[i];

      final y =
      (row['views'] as int).toDouble();

      if (y > maxY) maxY = y;

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: y,
              width: 18,
              borderRadius:
              BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    maxY += 20;

    // ★ イベントをグラフ上に重ねる（縦線）
    final verticalLines = <VerticalLine>[];

    for (final e in events) {
      final ts = e['timestamp'].toString();

      final index = history.indexWhere(
            (h) => h['timestamp'] == ts,
      );

      if (index == -1) continue;

      Color color;

      switch (e['type']) {
        case 'post':
          color = Colors.blue;
          break;
        case 'share':
          color = Colors.green;
          break;
        case 'update':
          color = Colors.orange;
          break;
        default:
          color = Colors.purple;
      }

      verticalLines.add(
        VerticalLine(
          x: index.toDouble(),
          color: color.withOpacity(0.8),
          strokeWidth: 2,
          dashArray: [5, 5],
        ),
      );
    }

    final chartWidth = history.isEmpty
        ? 300.0
        : (history.length * 70.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
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

                extraLinesData: ExtraLinesData(
                  verticalLines: verticalLines,
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 ||
                            index >= history.length) {
                          return const SizedBox();
                        }

                        final timestamp =
                        DateTime.parse(
                          history[index]['timestamp'],
                        );

                        return Text(
                          '${timestamp.month}/${timestamp.day}\n'
                              '${timestamp.hour.toString().padLeft(2, '0')}:'
                              '${timestamp.minute.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                          ),
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