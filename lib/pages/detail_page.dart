import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
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
  State<DetailPage> createState() =>
      _DetailPageState();
}

class _DetailPageState
    extends State<DetailPage> {

  final analytics = AnalyticsService();

  List<Map<String, dynamic>> history = [];

  List<AppEvent> events = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    history = await analytics.history(
      widget.articleId,
    );

    events = await DbService.instance
        .getEventsByArticleId(
      widget.articleId,
    );

    setState(() {});
  }

  IconData _icon(String type) {

    switch (type) {

      case EventType.posted:
        return Icons.publish;

      case EventType.updated:
        return Icons.edit;

      case EventType.shared:
        return Icons.share;

      default:
        return Icons.circle;
    }
  }

  Color _color(String type) {

    switch (type) {

      case EventType.posted:
        return Colors.blue;

      case EventType.updated:
        return Colors.orange;

      case EventType.shared:
        return Colors.green;

      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {

    if (history.isEmpty) {

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text('データなし'),
        ),
      );
    }

    final spots = <FlSpot>[];

    double maxY = 10;

    for (int i = 0; i < history.length; i++) {

      final views =
      (history[i]['views'] as int)
          .toDouble();

      if (views > maxY) {
        maxY = views;
      }

      spots.add(
        FlSpot(
          i.toDouble(),
          views,
        ),
      );
    }

    maxY += 20;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            Expanded(
              child: LineChart(
                LineChartData(

                  minY: 0,
                  maxY: maxY,

                  gridData: FlGridData(
                    show: true,
                  ),

                  borderData: FlBorderData(
                    show: true,
                  ),

                  titlesData: FlTitlesData(

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,

                        getTitlesWidget:
                            (value, meta) {

                          return Text(
                            value
                                .toInt()
                                .toString(),
                            style:
                            const TextStyle(
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        reservedSize: 70,

                        interval: 1,

                        getTitlesWidget:
                            (value, meta) {

                          final index =
                          value.toInt();

                          if (index < 0 ||
                              index >=
                                  history
                                      .length) {
                            return const SizedBox();
                          }

                          final timestamp =
                          DateTime.parse(
                            history[index]
                            ['timestamp'],
                          );

                          final pointEvents =
                          events.where((e) {

                            final eventTime =
                                e.timestamp;

                            return eventTime
                                .isBefore(
                              timestamp
                                  .add(
                                const Duration(
                                  minutes:
                                  30,
                                ),
                              ),
                            ) &&
                                eventTime
                                    .isAfter(
                                  timestamp
                                      .subtract(
                                    const Duration(
                                      minutes:
                                      30,
                                    ),
                                  ),
                                );
                          }).toList();

                          return Column(
                            mainAxisSize:
                            MainAxisSize.min,

                            children: [

                              Text(
                                '${timestamp.month}/${timestamp.day}\n'
                                    '${timestamp.hour.toString().padLeft(2, '0')}:'
                                    '${timestamp.minute.toString().padLeft(2, '0')}',
                                textAlign:
                                TextAlign.center,

                                style:
                                const TextStyle(
                                  fontSize: 10,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              if (pointEvents
                                  .isNotEmpty)

                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

                                  children:
                                  pointEvents
                                      .map((e) {

                                    return Padding(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal:
                                        1,
                                      ),

                                      child: Icon(
                                        _icon(
                                          e.type,
                                        ),

                                        size: 14,

                                        color:
                                        _color(
                                          e.type,
                                        ),
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

                  lineBarsData: [

                    LineChartBarData(

                      spots: spots,

                      isCurved: true,

                      barWidth: 3,

                      dotData: FlDotData(
                        show: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(

                itemCount: events.length,

                itemBuilder:
                    (context, index) {

                  final e =
                  events[index];

                  return Card(
                    child: ListTile(

                      leading: Icon(
                        _icon(e.type),
                        color:
                        _color(e.type),
                      ),

                      title: Text(
                        e.type,
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Text(
                            e.timestamp
                                .toString(),
                          ),

                          if ((e.memo ?? '')
                              .isNotEmpty)

                            Text(
                              e.memo!,
                            ),

                          Text(
                            'source: ${e.source}',
                            style:
                            const TextStyle(
                              fontSize: 12,
                              color:
                              Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}