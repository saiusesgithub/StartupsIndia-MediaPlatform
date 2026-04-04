import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticleModel {
  final String id;
  final DateTime? createdAt;
  final String authorId;
  final String category;
  final String headline;
  final String sourceName;
  final String sourceId;
  final String sourceLogoAsset;
  final String thumbnailAsset;
  final String timeAgo;
  final String body;
  final int likesCount;
  final int commentsCount;
  final bool isSourceFollowing;
  final bool isBookmarked;
  final bool isLiked;
  final bool isTrending;

  const NewsArticleModel({
    required this.id,
    this.createdAt,
    this.authorId = '',
    required this.category,
    required this.headline,
    required this.sourceName,
    this.sourceId = '',
    required this.sourceLogoAsset,
    required this.thumbnailAsset,
    required this.timeAgo,
    this.body = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isSourceFollowing = false,
    this.isBookmarked = false,
    this.isLiked = false,
    this.isTrending = false,
  });

  NewsArticleModel copyWith({
    String? id,
    DateTime? createdAt,
    String? authorId,
    String? category,
    String? headline,
    String? sourceName,
    String? sourceId,
    String? sourceLogoAsset,
    String? thumbnailAsset,
    String? timeAgo,
    String? body,
    int? likesCount,
    int? commentsCount,
    bool? isSourceFollowing,
    bool? isBookmarked,
    bool? isLiked,
    bool? isTrending,
  }) {
    return NewsArticleModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      category: category ?? this.category,
      headline: headline ?? this.headline,
      sourceName: sourceName ?? this.sourceName,
      sourceId: sourceId ?? this.sourceId,
      sourceLogoAsset: sourceLogoAsset ?? this.sourceLogoAsset,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      timeAgo: timeAgo ?? this.timeAgo,
      body: body ?? this.body,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isSourceFollowing: isSourceFollowing ?? this.isSourceFollowing,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isLiked: isLiked ?? this.isLiked,
      isTrending: isTrending ?? this.isTrending,
    );
  }

  factory NewsArticleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAtValue = data['createdAt'];
    DateTime? createdAt;
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    }

    return NewsArticleModel(
      id: doc.id,
      createdAt: createdAt,
      authorId: data['authorId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      headline: data['headline'] as String? ?? '',
      sourceName: data['sourceName'] as String? ?? '',
      sourceId: data['sourceId'] as String? ?? '',
      sourceLogoAsset: data['sourceLogoAsset'] as String? ?? '',
      thumbnailAsset: data['thumbnailAsset'] as String? ?? '',
      timeAgo: data['timeAgo'] as String? ?? '',
      body: data['body'] as String? ?? '',
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      isSourceFollowing: data['isSourceFollowing'] as bool? ?? false,
      isBookmarked: data['isBookmarked'] as bool? ?? false,
      isLiked: data['isLiked'] as bool? ?? false,
      isTrending: data['isTrending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'authorId': authorId,
      'category': category,
      'headline': headline,
      'sourceName': sourceName,
      'sourceId': sourceId,
      'sourceLogoAsset': sourceLogoAsset,
      'thumbnailAsset': thumbnailAsset,
      'timeAgo': timeAgo,
      'body': body,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isSourceFollowing': isSourceFollowing,
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
      'isTrending': isTrending,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
