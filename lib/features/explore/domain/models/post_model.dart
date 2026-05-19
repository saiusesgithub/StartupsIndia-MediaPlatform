import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatarUrl;
  final String headline;
  final String excerpt;
  final String category;
  final String mediaType; // "video" or "image"
  final String videoUrl;
  final String thumbnailUrl;
  final List<String> likedBy;
  final int likesCount;
  final List<String> bookmarkedBy;
  final int commentsCount;
  final int shareCount;
  final bool isTrending;
  final DateTime? createdAt;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatarUrl,
    required this.headline,
    required this.excerpt,
    required this.category,
    required this.mediaType,
    this.videoUrl = '',
    required this.thumbnailUrl,
    this.likedBy = const [],
    this.likesCount = 0,
    this.bookmarkedBy = const [],
    this.commentsCount = 0,
    this.shareCount = 0,
    this.isTrending = false,
    this.createdAt,
  });

  factory PostModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      authorAvatarUrl: data['authorAvatarUrl'] as String? ?? '',
      headline: data['headline'] as String? ?? '',
      excerpt: data['excerpt'] as String? ?? '',
      category: data['category'] as String? ?? '',
      mediaType: data['mediaType'] as String? ?? 'image',
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      bookmarkedBy: List<String>.from(data['bookmarkedBy'] as List? ?? []),
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      isTrending: data['isTrending'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class CommentModel {
  final String id;
  final String userId;
  final String authorName;
  final String avatarUrl;
  final String content;
  final DateTime? createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.avatarUrl,
    required this.content,
    this.createdAt,
  });

  factory CommentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'User',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
