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
  final String featuredImageUrl;
  final String timeAgo;
  final String body;
  final int likesCount;
  final int commentsCount;
  final bool isSourceFollowing;
  final bool isBookmarked;
  final bool isLiked;
  final bool isTrending;
  final List<String> likedBy;
  final List<String> bookmarkedBy;
  final String description;
  final int viewCount;
  final List<String> imageGallery;
  final String youtubeVideoId;
  final List<String> tags;

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
    this.featuredImageUrl = '',
    required this.timeAgo,
    this.body = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isSourceFollowing = false,
    this.isBookmarked = false,
    this.isLiked = false,
    this.isTrending = false,
    this.likedBy = const [],
    this.bookmarkedBy = const [],
    this.description = '',
    this.viewCount = 0,
    this.imageGallery = const [],
    this.youtubeVideoId = '',
    this.tags = const [],
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
    String? featuredImageUrl,
    String? timeAgo,
    String? body,
    int? likesCount,
    int? commentsCount,
    bool? isSourceFollowing,
    bool? isBookmarked,
    bool? isLiked,
    bool? isTrending,
    List<String>? likedBy,
    List<String>? bookmarkedBy,
    String? description,
    int? viewCount,
    List<String>? imageGallery,
    String? youtubeVideoId,
    List<String>? tags,
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
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      timeAgo: timeAgo ?? this.timeAgo,
      body: body ?? this.body,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isSourceFollowing: isSourceFollowing ?? this.isSourceFollowing,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isLiked: isLiked ?? this.isLiked,
      isTrending: isTrending ?? this.isTrending,
      likedBy: likedBy ?? this.likedBy,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
      description: description ?? this.description,
      viewCount: viewCount ?? this.viewCount,
      imageGallery: imageGallery ?? this.imageGallery,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      tags: tags ?? this.tags,
    );
  }

  factory NewsArticleModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    DateTime? createdAt;
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    }

    return NewsArticleModel(
      id: id,
      createdAt: createdAt,
      authorId: map['authorId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      headline: map['headline'] as String? ?? '',
      sourceName: map['sourceName'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      sourceLogoAsset: map['sourceLogoAsset'] as String? ?? '',
      thumbnailAsset: map['thumbnailAsset'] as String? ?? '',
      featuredImageUrl:
          map['featuredImageUrl'] as String? ??
          map['featuredImage'] as String? ??
          '',
      timeAgo: map['timeAgo'] as String? ?? '',
      body: map['body'] as String? ?? '',
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      isSourceFollowing: map['isSourceFollowing'] as bool? ?? false,
      isBookmarked: map['isBookmarked'] as bool? ?? false,
      isLiked: map['isLiked'] as bool? ?? false,
      isTrending: map['isTrending'] as bool? ?? false,
      likedBy: List<String>.from(map['likedBy'] as List? ?? []),
      bookmarkedBy: List<String>.from(map['bookmarkedBy'] as List? ?? []),
      description: map['description'] as String? ?? '',
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
      imageGallery: List<String>.from(map['imageGallery'] as List? ?? []),
      youtubeVideoId: map['youtubeVideoId'] as String? ?? '',
      tags: List<String>.from(map['tags'] as List? ?? []),
    );
  }

  factory NewsArticleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return NewsArticleModel.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'authorId': authorId,
      'category': category,
      'headline': headline,
      'sourceName': sourceName,
      'sourceId': sourceId,
      'sourceLogoAsset': sourceLogoAsset,
      'thumbnailAsset': thumbnailAsset,
      'featuredImageUrl': featuredImageUrl,
      'timeAgo': timeAgo,
      'body': body,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isSourceFollowing': isSourceFollowing,
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
      'isTrending': isTrending,
      'likedBy': likedBy,
      'bookmarkedBy': bookmarkedBy,
      'description': description,
      'viewCount': viewCount,
      'imageGallery': imageGallery,
      'youtubeVideoId': youtubeVideoId,
      'tags': tags,
    };
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      ...toMap(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
