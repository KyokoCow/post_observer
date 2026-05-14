import 'event_source.dart';
import 'event_type.dart';

class AppEvent {

  final int? id;

  final int? syncId;

  final String? articleId;

  final EventType type;

  final String? memo;

  final EventSource source;

  final DateTime eventAt;

  final DateTime createdAt;

  AppEvent({
    this.id,
    this.syncId,
    this.articleId,
    required this.type,
    this.memo,
    required this.source,
    required this.eventAt,
    required this.createdAt,
  });

  factory AppEvent.fromMap(
      Map<String, dynamic> map,
      ) {

    return AppEvent(
      id: map['id'] as int?,

      syncId: map['sync_id'] as int?,

      articleId: map['article_id'] as String?,

      type: EventTypeExtension.fromString(
        map['type'] as String,
      ),

      memo: map['memo'] as String?,

      source: EventSourceExtension.fromString(
        map['source'] as String,
      ),

      eventAt: DateTime.parse(
        map['event_at'] as String,
      ),

      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {

    return {
      'id': id,

      'sync_id': syncId,

      'article_id': articleId,

      'type': type.value,

      'memo': memo,

      'source': source.value,

      'event_at':
      eventAt.toIso8601String(),

      'created_at':
      createdAt.toIso8601String(),
    };
  }
}