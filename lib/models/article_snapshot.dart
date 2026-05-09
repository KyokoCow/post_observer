class ArticleSnapshot {
  final int? id;
  final int? syncId; // ★追加
  final String articleId;
  final String title;
  final int views;
  final int likes;
  final int stocks;
  final DateTime timestamp;

  ArticleSnapshot({
    this.id,
    this.syncId, // ★追加
    required this.articleId,
    required this.title,
    required this.views,
    required this.likes,
    required this.stocks,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sync_id': syncId, // ★追加（ここが重要）
      'article_id': articleId,
      'title': title,
      'views': views,
      'likes': likes,
      'stocks': stocks,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}