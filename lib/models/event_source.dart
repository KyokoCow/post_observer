enum EventSource {
  auto,
  manual,
}

extension EventSourceExtension on EventSource {

  String get value => switch (this) {
    EventSource.auto => 'auto',
    EventSource.manual => 'manual',
  };

  String get label => switch (this) {
    EventSource.auto => '自動',
    EventSource.manual => '手動',
  };

  static EventSource fromString(String value) {
    switch (value) {
      case 'auto':
        return EventSource.auto;

      case 'manual':
        return EventSource.manual;

      default:
        return EventSource.manual;
    }
  }
}