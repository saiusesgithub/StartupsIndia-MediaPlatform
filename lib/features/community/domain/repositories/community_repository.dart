import '../models/community_model.dart';
import '../models/community_post_model.dart';
import '../../../../core/models/user_model.dart';

abstract class CommunityRepository {
  Future<void> seedDefaultCommunities();
  Stream<List<CommunityModel>> watchCommunities();
  Stream<Set<String>> watchMyMemberships(String userId);
  Stream<List<CommunityPostModel>> watchPosts(String communityId);
  Future<void> joinCommunity(String communityId, UserModel user);
  Future<void> leaveCommunity(String communityId, String userId);
}
