import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/user_model.dart';
import '../../domain/models/community_model.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/repositories/community_repository.dart';

const _kDefaultCommunities = [
  {
    'id': 'founders-network-india',
    'data': {
      'name': 'Founders Network India',
      'description':
          'A community for founders to connect, share challenges and grow together.',
      'emoji': '🚀',
      'colorHex': '#E8341C',
      'memberCount': 12100,
      'isDefault': true,
    },
  },
  {
    'id': 'ai-founders-club',
    'data': {
      'name': 'AI Founders Club',
      'description':
          'Building the future with AI. Learn, share and collaborate.',
      'emoji': '💡',
      'colorHex': '#00BA88',
      'memberCount': 856,
      'isDefault': true,
    },
  },
  {
    'id': 'investors-mentors',
    'data': {
      'name': 'Investors & Mentors',
      'description':
          'For angels, VCs, and seasoned advisors shaping the next generation of Indian startups.',
      'emoji': '💰',
      'colorHex': '#9B51E0',
      'memberCount': 732,
      'isDefault': true,
    },
  },
  {
    'id': 'mentorship-hub',
    'data': {
      'name': 'Mentorship Hub',
      'description': 'Learn from experienced founders and industry experts.',
      'emoji': '🎓',
      'colorHex': '#F2994A',
      'memberCount': 1100,
      'isDefault': true,
    },
  },
];

class CommunityRepositoryImpl implements CommunityRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _communities =>
      _firestore.collection('communities');

  @override
  Future<void> seedDefaultCommunities() async {
    final snap = await _communities.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final entry in _kDefaultCommunities) {
      final ref = _communities.doc(entry['id'] as String);
      final data = Map<String, dynamic>.from(entry['data'] as Map);
      data['createdAt'] = FieldValue.serverTimestamp();
      batch.set(ref, data, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Stream<List<CommunityModel>> watchCommunities() {
    return _communities
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(CommunityModel.fromFirestore).toList());
  }

  @override
  Stream<Set<String>> watchMyMemberships(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('communities')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  @override
  Stream<Map<String, CommunityMembershipModel>> watchMyMembershipDetails(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('communities')
        .snapshots()
        .map((snap) => {
              for (final doc in snap.docs)
                doc.id: CommunityMembershipModel.fromFirestore(doc),
            });
  }

  @override
  Stream<List<CommunityPostModel>> watchPosts(String communityId) {
    return _communities
        .doc(communityId)
        .collection('announcements')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map(CommunityPostModel.fromFirestore).toList());
  }

  @override
  Stream<List<CommunityCommentModel>> watchComments(
    String communityId,
    String postId,
  ) {
    return _communities
        .doc(communityId)
        .collection('announcements')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map(CommunityCommentModel.fromFirestore).toList());
  }

  @override
  Stream<List<CommunityCommentModel>> watchMyCommentActivity(String userId) {
    return _firestore
        .collectionGroup('comments')
        .where('authorId', isEqualTo: userId)
        .limit(30)
        .snapshots()
        .map((snap) {
      final comments =
          snap.docs.map(CommunityCommentModel.fromFirestore).toList();
      comments.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return comments;
    });
  }

  @override
  Future<void> joinCommunity(String communityId, UserModel user) async {
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : user.fullName;

    final batch = _firestore.batch();

    batch.set(
      _communities.doc(communityId).collection('members').doc(user.uid),
      {
        'userId': user.uid,
        'displayName': displayName,
        'avatarUrl': user.avatarUrl,
        'email': user.email,
        'role': user.role,
        'interests': user.interests,
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );

    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(1),
    });

    batch.set(
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('communities')
          .doc(communityId),
      {
        'joinedAt': FieldValue.serverTimestamp(),
        'lastReadAnnouncementAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    await _communities.doc(communityId).collection('announcements').add({
      'type': 'system',
      'content': '$displayName joined the community',
      'authorId': user.uid,
      'authorName': displayName,
      'authorAvatarUrl': user.avatarUrl,
      'authorRole': user.role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> leaveCommunity(String communityId, String userId) async {
    final batch = _firestore.batch();

    batch.delete(
      _communities.doc(communityId).collection('members').doc(userId),
    );

    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(-1),
    });

    batch.delete(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('communities')
          .doc(communityId),
    );

    await batch.commit();
  }

  @override
  Future<void> markCommunityRead(String communityId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('communities')
        .doc(communityId)
        .set(
      {'lastReadAnnouncementAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> addComment({
    required String communityId,
    required String postId,
    required String content,
    required UserModel user,
    String? replyToCommentId,
    String? replyToAuthorName,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : user.fullName;
    final postRef =
        _communities.doc(communityId).collection('announcements').doc(postId);
    final commentRef = postRef.collection('comments').doc();
    final batch = _firestore.batch();

    batch.set(commentRef, {
      'postId': postId,
      'communityId': communityId,
      'content': trimmed,
      'authorId': user.uid,
      'authorName': displayName,
      'authorAvatarUrl': user.avatarUrl,
      'authorRole': user.role,
      'replyToCommentId': replyToCommentId,
      'replyToAuthorName': replyToAuthorName,
      'mentionedUserIds': <String>[],
      'reportCount': 0,
      'status': 'visible',
      'isAdminReply': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  @override
  Future<void> reportComment({
    required String communityId,
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    final ref = _communities
        .doc(communityId)
        .collection('announcements')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    await ref.set({
      'reportCount': FieldValue.increment(1),
      'reportedBy': FieldValue.arrayUnion([userId]),
      'status': 'reported',
    }, SetOptions(merge: true));
  }
}
