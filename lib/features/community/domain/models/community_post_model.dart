import 'package:cloud_firestore/cloud_firestore.dart';

enum CommunityPostType { announcement, event, system }

class CommunityPostModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String authorRole;
  final CommunityPostType type;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? linkUrl;
  final String? linkTitle;
  final String? linkDescription;
  final int commentCount;

  const CommunityPostModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorRole,
    required this.type,
    this.createdAt,
    this.imageUrl,
    this.linkUrl,
    this.linkTitle,
    this.linkDescription,
    this.commentCount = 0,
  });

  factory CommunityPostModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawType = data['type'] as String? ?? 'announcement';
    final type = switch (rawType) {
      'event' => CommunityPostType.event,
      'system' => CommunityPostType.system,
      _ => CommunityPostType.announcement,
    };
    return CommunityPostModel(
      id: doc.id,
      content: data['content'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Admin',
      authorAvatarUrl: data['authorAvatarUrl'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      type: type,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'] as String?,
      linkUrl: data['linkUrl'] as String?,
      linkTitle: data['linkTitle'] as String?,
      linkDescription: data['linkDescription'] as String?,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

enum CommunityCommentStatus { visible, reported, deleted }

class CommunityCommentModel {
  final String id;
  final String postId;
  final String communityId;
  final String content;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String authorRole;
  final DateTime? createdAt;
  final String? replyToCommentId;
  final String? replyToAuthorName;
  final List<String> mentionedUserIds;
  final int reportCount;
  final CommunityCommentStatus status;
  final bool isAdminReply;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.communityId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorRole,
    this.createdAt,
    this.replyToCommentId,
    this.replyToAuthorName,
    this.mentionedUserIds = const [],
    this.reportCount = 0,
    this.status = CommunityCommentStatus.visible,
    this.isAdminReply = false,
  });

  bool get isDeleted => status == CommunityCommentStatus.deleted;
  bool get hasAdminReply => isAdminReply || mentionedUserIds.contains(authorId);

  factory CommunityCommentModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawStatus = data['status'] as String? ?? 'visible';
    final status = switch (rawStatus) {
      'reported' => CommunityCommentStatus.reported,
      'deleted' => CommunityCommentStatus.deleted,
      _ => CommunityCommentStatus.visible,
    };
    return CommunityCommentModel(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      communityId: data['communityId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Member',
      authorAvatarUrl: data['authorAvatarUrl'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      replyToCommentId: data['replyToCommentId'] as String?,
      replyToAuthorName: data['replyToAuthorName'] as String?,
      mentionedUserIds:
          (data['mentionedUserIds'] as List<dynamic>? ?? []).cast<String>(),
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      status: status,
      isAdminReply: data['isAdminReply'] as bool? ?? false,
    );
  }
}
