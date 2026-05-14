import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/event_source.dart';
import '../models/event_type.dart';

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

    try {

      final rawHistory =
      await analytics.history(
        widget.articleId,
      );

      debugPrint(
        'history count: ${rawHistory.length}',
      );

      final mutableHistory =
      List<Map<String, dynamic>>.from(
        rawHistory,
      );

      if (mutableHistory.isNotEmpty) {

        final first =
            mutableHistory.first;

        final createdAt =
        first['created_at'];

        if (createdAt != null) {

          mutableHistory.insert(0, {

            'views': 0,
            'likes': 0,
            'stocks': 0,
            'comments': 0,

            'timestamp': createdAt,

            'created_at': createdAt,
            'updated_at': createdAt,
          });
        }
      }

      final db =
      await DbService.instance.database;

      final eventMaps =
      await db.query(

        'events',

        where: 'article_id = ?',

        whereArgs: [
          widget.articleId,
        ],

        orderBy: 'event_at ASC',
      );

      events =
          eventMaps
              .map(
                (e) => AppEvent.fromMap(e),
          )
              .toList();

      setState(() {

        history =
            mutableHistory;
      });

    } catch (e, st) {

      debugPrint(
        'DETAIL LOAD ERROR: $e',
      );

      debugPrint(
        '$st',
      );
    }
  }

  IconData _icon(EventType type) {

    switch (type) {

      case EventType.post:
        return Icons.publish;

      case EventType.update:
        return Icons.edit;

      case EventType.share:
        return Icons.share;

      case EventType.other:
        return Icons.circle;
    }
  }

  Color _color(EventType type) {

    switch (type) {

      case EventType.post:
        return Colors.blue;

      case EventType.update:
        return Colors.orange;

      case EventType.share:
        return Colors.green;

      case EventType.other:
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
      (history[i]['views'] as num)
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

                          final rawTimestamp =
                          history[index]['timestamp'];

                          if (rawTimestamp == null) {
                            return const SizedBox();
                          }

                          final timestamp =
                          DateTime.parse(
                            rawTimestamp.toString(),
                          );

                          final pointEvents =
                          events.where((e) {

                            final eventTime =
                                e.eventAt;

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

                      isCurved: false,

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
                        e.type.label,
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Text(
                            e.eventAt
                                .toString(),
                          ),

                          if ((e.memo ?? '')
                              .isNotEmpty)

                            Text(
                              e.memo!,
                            ),

                          Text(
                            'source: ${e.source.label}',
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