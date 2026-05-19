import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/community_model.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/repositories/community_repository.dart';
import '../../../../core/models/user_model.dart';

const _kDefaultCommunities = [
  {
    'id': 'student-founders',
    'data': {
      'name': 'Student Founders',
      'description':
          'For college students and young entrepreneurs taking their first steps into the startup world.',
      'emoji': '🎓',
      'colorHex': '#6C5CE7',
      'memberCount': 0,
      'isDefault': true,
    },
  },
  {
    'id': 'entrepreneurs',
    'data': {
      'name': 'Entrepreneurs',
      'description':
          'For active founders and business owners building their next big thing.',
      'emoji': '🚀',
      'colorHex': '#E8341C',
      'memberCount': 0,
      'isDefault': true,
    },
  },
  {
    'id': 'investors-mentors',
    'data': {
      'name': 'Investors & Mentors',
      'description':
          'For angels, VCs, and seasoned advisors shaping the next generation of Indian startups.',
      'emoji': '💼',
      'colorHex': '#0984E3',
      'memberCount': 0,
      'isDefault': true,
    },
  },
  {
    'id': 'tech-builders',
    'data': {
      'name': 'Tech Builders',
      'description':
          'For developers and technical co-founders building products that scale.',
      'emoji': '⚡',
      'colorHex': '#00BA88',
      'memberCount': 0,
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
  Future<void> joinCommunity(String communityId, UserModel user) async {
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : user.fullName;

    final batch = _firestore.batch();

    // Track member in community subcollection (data collection for marketing)
    batch.set(
      _communities
          .doc(communityId)
          .collection('members')
          .doc(user.uid),
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

    // Increment community member count
    batch.update(_communities.doc(communityId), {
      'memberCount': FieldValue.increment(1),
    });

    // Track membership on user's side for fast "my communities" query
    batch.set(
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('communities')
          .doc(communityId),
      {'joinedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    await batch.commit();

    // Post system message and update lastPost denormalized field
    final systemContent = '$displayName joined the community';
    await _communities.doc(communityId).collection('announcements').add({
      'type': 'system',
      'content': systemContent,
      'authorId': user.uid,
      'authorName': displayName,
      'authorAvatarUrl': user.avatarUrl,
      'authorRole': user.role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _communities.doc(communityId).update({
      'lastPost': {
        'content': systemContent,
        'authorName': displayName,
        'authorAvatarUrl': user.avatarUrl,
        'type': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      },
    });
  }

  @override
  Future<void> leaveCommunity(String communityId, String userId) async {
    final batch = _firestore.batch();

    batch.delete(
        _communities.doc(communityId).collection('members').doc(userId));

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
}
