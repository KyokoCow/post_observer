class EventType {

  static const posted = 'article_posted';

  static const updated = 'article_updated';

  static const shared = 'article_shared';

  static const other = 'article_other';
}

class EventSource {

  static const auto = 'auto';

  static const manual = 'manual';
}

class AppEvent {

  final int? id;

  final int? syncId;

  final String? articleId;

  final String type;

  final String? memo;

  final String source;

  final DateTime timestamp;

  AppEvent({
    this.id,

    this.syncId,

    this.articleId,

    required this.type,

    this.memo,

    required this.source,

    required this.timestamp,
  });

  factory AppEvent.fromMap(
      Map<String, dynamic> map,
      ) {

    return AppEvent(
      id: map['id'] as int?,

      syncId: map['sync_id'] as int?,

      articleId: map['article_id'] as String?,

      type: map['type'] as String,

      memo: map['memo'] as String?,

      source: map['source'] as String,

      timestamp: DateTime.parse(
        map['timestamp'] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {

    return {
      'id': id,

      'sync_id': syncId,

      'article_id': articleId,

      'type': type,

      'memo': memo,

      'source': source,

      'timestamp':
      timestamp.toIso8601String(),
    };
  }
}