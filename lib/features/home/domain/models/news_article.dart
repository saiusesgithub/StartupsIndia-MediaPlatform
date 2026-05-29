import '../../../../core/models/news_article_model.dart';

/// Data model for a news article.
/// Structured to make Firebase stream swap trivial tomorrow:
/// just replace the hardcoded list with a Firestore StreamBuilder.
class NewsArticle {
  final String id;
  final String authorId;
  final String category;
  final String headline;
  final String sourceName;
  final String sourceId;
  final String sourceUrl;
  final String sourceLogoAsset; // local asset path for now
  final String thumbnailAsset; // local asset path for now
  final String timeAgo;
  final String body;
  final int likesCount;
  final int commentsCount;
  final bool isSourceFollowing;
  final bool isBookmarked;
  final bool isLiked;

  const NewsArticle({
    required this.id,
    this.authorId = '',
    required this.category,
    required this.headline,
    required this.sourceName,
    this.sourceId = '',
    this.sourceUrl = '',
    required this.sourceLogoAsset,
    required this.thumbnailAsset,
    required this.timeAgo,
    this.body = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isSourceFollowing = false,
    this.isBookmarked = false,
    this.isLiked = false,
  });

  /// Factory for constructing from a Firestore document map.
  /// Use this when wiring Firebase tomorrow.
  factory NewsArticle.fromMap(String id, Map<String, dynamic> map) {
    return NewsArticle(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      headline: map['headline'] as String? ?? '',
      sourceName: map['sourceName'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      sourceUrl:
          map['sourceUrl'] as String? ??
          map['wpLink'] as String? ??
          map['link'] as String? ??
          '',
      sourceLogoAsset: map['sourceLogoAsset'] as String? ?? '',
      thumbnailAsset: map['thumbnailAsset'] as String? ?? '',
      timeAgo: map['timeAgo'] as String? ?? '',
      body: map['body'] as String? ?? '',
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      isSourceFollowing: map['isSourceFollowing'] as bool? ?? false,
      isBookmarked: map['isBookmarked'] as bool? ?? false,
      isLiked: map['isLiked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'category': category,
    'authorId': authorId,
    'headline': headline,
    'sourceName': sourceName,
    'sourceId': sourceId,
    'sourceUrl': sourceUrl,
    'sourceLogoAsset': sourceLogoAsset,
    'thumbnailAsset': thumbnailAsset,
    'timeAgo': timeAgo,
    'body': body,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'isSourceFollowing': isSourceFollowing,
    'isBookmarked': isBookmarked,
    'isLiked': isLiked,
  };
}

extension NewsArticleModelAdapter on NewsArticle {
  NewsArticleModel toNewsArticleModel() {
    return NewsArticleModel(
      id: id,
      authorId: authorId,
      category: category,
      headline: headline,
      sourceName: sourceName,
      sourceId: sourceId,
      sourceUrl: sourceUrl,
      sourceLogoAsset: sourceLogoAsset,
      thumbnailAsset: thumbnailAsset,
      timeAgo: timeAgo,
      body: body,
      likesCount: likesCount,
      commentsCount: commentsCount,
      isSourceFollowing: isSourceFollowing,
      isBookmarked: isBookmarked,
      isLiked: isLiked,
    );
  }
}
