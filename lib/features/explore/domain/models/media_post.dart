enum MediaType { image, video }

enum MediaSource { post, article }

class MediaPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatarUrl;
  final bool isVerified;
  final String thumbnailUrl;
  final String? mediaUrl; // video stream URL; null for images
  final MediaType mediaType;
  final MediaSource sourceType;
  final String headline;
  final String excerpt;
  final String category;
  final int readTimeMinutes;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
  final int colorIndex;

  const MediaPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatarUrl,
    required this.isVerified,
    required this.thumbnailUrl,
    this.mediaUrl,
    required this.mediaType,
    this.sourceType = MediaSource.article,
    required this.headline,
    required this.excerpt,
    required this.category,
    required this.readTimeMinutes,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    required this.shareCount,
    required this.isLiked,
    required this.isSaved,
    required this.colorIndex,
  });

  MediaPost copyWith({
    bool? isLiked,
    bool? isSaved,
    int? likeCount,
    int? saveCount,
  }) {
    return MediaPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatarUrl: authorAvatarUrl,
      isVerified: isVerified,
      thumbnailUrl: thumbnailUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      sourceType: sourceType,
      headline: headline,
      excerpt: excerpt,
      category: category,
      readTimeMinutes: readTimeMinutes,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      saveCount: saveCount ?? this.saveCount,
      shareCount: shareCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      colorIndex: colorIndex,
    );
  }
}
