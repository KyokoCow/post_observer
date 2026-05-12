class AppEvent {
  final int? id;

  final int? syncId;

  final String? articleId;

  final String type;

  final String? memo;

  final DateTime timestamp;

  AppEvent({
    this.id,
    this.syncId,
    this.articleId,
    required this.type,
    this.memo,
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

      'timestamp':
      timestamp.toIso8601String(),
    };
  }
}