/// Represents a single card in the vertical swipe media feed.
///
/// VIDEO READINESS — when the client adds video support:
/// 1. Set [mediaType] to [MediaType.video] and populate [mediaUrl].
/// 2. In _MediaCardState (media_feed_screen.dart) uncomment the
///    VideoPlayerController block in initState/dispose.
/// 3. In _MediaLayer.build(), the switch already has the video branch
///    — just remove the placeholder and plug in VideoPlayer(controller).
/// Nothing in the overlay layers (author, actions, text) changes.
enum MediaType { image, video }

class MediaPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatarUrl;
  final bool isVerified;

  /// Always present — thumbnail image for both images and videos.
  final String thumbnailUrl;

  /// Video stream URL. Null for image posts.
  /// Populate this when [mediaType] == [MediaType.video].
  final String? mediaUrl;

  final MediaType mediaType;
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

  /// Used for gradient fallback when [thumbnailUrl] is empty.
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
