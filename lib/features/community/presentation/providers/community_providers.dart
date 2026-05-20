import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/models/community_model.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepositoryImpl(),
);

final communitiesProvider = StreamProvider<List<CommunityModel>>((ref) {
  return ref.watch(communityRepositoryProvider).watchCommunities();
});

final myMembershipsProvider = StreamProvider<Set<String>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value({});
  return ref.watch(communityRepositoryProvider).watchMyMemberships(uid);
});

final myMembershipDetailsProvider =
    StreamProvider<Map<String, CommunityMembershipModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value({});
  return ref.watch(communityRepositoryProvider).watchMyMembershipDetails(uid);
});

final communityPostsProvider =
    StreamProvider.family<List<CommunityPostModel>, String>((ref, communityId) {
  return ref.watch(communityRepositoryProvider).watchPosts(communityId);
});

final communityCommentsProvider = StreamProvider.family<
    List<CommunityCommentModel>, ({String communityId, String postId})>(
  (ref, args) {
    return ref
        .watch(communityRepositoryProvider)
        .watchComments(args.communityId, args.postId);
  },
);

final myCommunityActivityProvider =
    StreamProvider<List<CommunityCommentModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(communityRepositoryProvider).watchMyCommentActivity(uid);
});
