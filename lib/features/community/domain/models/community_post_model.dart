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
    );
  }
}
