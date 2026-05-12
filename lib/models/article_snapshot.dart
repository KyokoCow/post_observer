class ArticleSnapshot {
  final int? id;

  final int? syncId;

  final String articleId;

  final String title;

  final int views;
  final int likes;
  final int stocks;
  final int comments;

  final String? createdAt;
  final String? updatedAt;

  final DateTime timestamp;

  ArticleSnapshot({
    this.id,
    this.syncId,

    required this.articleId,
    required this.title,

    required this.views,
    required this.likes,
    required this.stocks,
    required this.comments,

    required this.createdAt,
    required this.updatedAt,

    required this.timestamp,
  });

  factory ArticleSnapshot.fromMap(
      Map<String, dynamic> map,
      ) {
    return ArticleSnapshot(
      id: map['id'] as int?,

      syncId: map['sync_id'] as int?,

      articleId: map['article_id'] as String,

      title: map['title'] as String,

      views: map['views'] as int,
      likes: map['likes'] as int,
      stocks: map['stocks'] as int,

      comments:
      (map['comments'] ?? 0) as int,

      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,

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

      'title': title,

      'views': views,
      'likes': likes,
      'stocks': stocks,

      'comments': comments,

      'created_at': createdAt,
      'updated_at': updatedAt,

      'timestamp':
      timestamp.toIso8601String(),
    };
  }
}