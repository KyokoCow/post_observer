class ArticleSnapshot {
  final int? id;
  final String articleId;
  final String title;
  final int views;
  final int likes;
  final int stocks;
  final DateTime timestamp;

  ArticleSnapshot({
    this.id,
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
      'article_id': articleId,
      'title': title,
      'views': views,
      'likes': likes,
      'stocks': stocks,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}