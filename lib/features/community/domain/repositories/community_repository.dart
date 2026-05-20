import '../models/community_model.dart';
import '../models/community_post_model.dart';
import '../../../../core/models/user_model.dart';

abstract class CommunityRepository {
  Future<void> seedDefaultCommunities();
  Stream<List<CommunityModel>> watchCommunities();
  Stream<Set<String>> watchMyMemberships(String userId);
  Stream<Map<String, CommunityMembershipModel>> watchMyMembershipDetails(
    String userId,
  );
  Stream<List<CommunityPostModel>> watchPosts(String communityId);
  Stream<List<CommunityCommentModel>> watchComments(
    String communityId,
    String postId,
  );
  Stream<List<CommunityCommentModel>> watchMyCommentActivity({
    required String userId,
    required String displayName,
  });
  Future<void> joinCommunity(String communityId, UserModel user);
  Future<void> leaveCommunity(String communityId, String userId);
  Future<void> markCommunityRead(String communityId, String userId);
  Future<void> addComment({
    required String communityId,
    required String postId,
    required String content,
    required UserModel user,
    String? replyToCommentId,
    String? replyToAuthorId,
    String? replyToAuthorName,
  });
  Future<void> reportComment({
    required String communityId,
    required String postId,
    required String commentId,
    required String userId,
  });
}
