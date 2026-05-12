class Article {
  final String articleId;

  final String title;

  final String? createdAt;
  final String? updatedAt;

  final String firstSeenAt;
  final String lastSeenAt;

  const Article({
    required this.articleId,
    required this.title,

    required this.createdAt,
    required this.updatedAt,

    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      articleId: map['article_id'] as String,

      title: map['title'] as String,

      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,

      firstSeenAt: map['first_seen_at'] as String,

      lastSeenAt: map['last_seen_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'article_id': articleId,

      'title': title,

      'created_at': createdAt,
      'updated_at': updatedAt,

      'first_seen_at': firstSeenAt,
      'last_seen_at': lastSeenAt,
    };
  }
}