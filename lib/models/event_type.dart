enum EventType {
  post,
  update,
  share,
  other,
}

extension EventTypeExtension on EventType {

  String get value => switch (this) {
    EventType.post => 'post',
    EventType.update => 'update',
    EventType.share => 'share',
    EventType.other => 'other',
  };

  String get label => switch (this) {
    EventType.post => '投稿',
    EventType.update => '更新',
    EventType.share => '共有',
    EventType.other => 'その他',
  };

  static EventType fromString(String value) {
    switch (value) {
      case 'post':
        return EventType.post;

      case 'update':
        return EventType.update;

      case 'share':
        return EventType.share;

      case 'other':
        return EventType.other;

      default:
        return EventType.other;
    }
  }
}