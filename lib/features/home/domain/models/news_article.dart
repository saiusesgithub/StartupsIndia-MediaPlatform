/// Data model for a news article.
/// Structured to make Firebase stream swap trivial tomorrow:
/// just replace the hardcoded list with a Firestore StreamBuilder.
class NewsArticle {
  final String id;
  final String category;
  final String headline;
  final String sourceName;
  final String sourceLogoAsset; // local asset path for now
  final String thumbnailAsset;  // local asset path for now
  final String timeAgo;

  const NewsArticle({
    required this.id,
    required this.category,
    required this.headline,
    required this.sourceName,
    required this.sourceLogoAsset,
    required this.thumbnailAsset,
    required this.timeAgo,
  });

  /// Factory for constructing from a Firestore document map.
  /// Use this when wiring Firebase tomorrow.
  factory NewsArticle.fromMap(String id, Map<String, dynamic> map) {
    return NewsArticle(
      id: id,
      category: map['category'] as String? ?? '',
      headline: map['headline'] as String? ?? '',
      sourceName: map['sourceName'] as String? ?? '',
      sourceLogoAsset: map['sourceLogoAsset'] as String? ?? '',
      thumbnailAsset: map['thumbnailAsset'] as String? ?? '',
      timeAgo: map['timeAgo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'headline': headline,
        'sourceName': sourceName,
        'sourceLogoAsset': sourceLogoAsset,
        'thumbnailAsset': thumbnailAsset,
        'timeAgo': timeAgo,
      };
}
