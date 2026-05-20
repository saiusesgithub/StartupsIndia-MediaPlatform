import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../theme/style_guide.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/community_model.dart';
import '../../domain/models/community_post_model.dart';
import '../providers/community_providers.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState
    extends ConsumerState<CommunityDetailScreen> {
  bool _joiningLeaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) return;
    await ref
        .read(communityRepositoryProvider)
        .markCommunityRead(widget.communityId, authUser.uid);
  }

  Future<void> _toggleMembership(
      bool isMember, CommunityModel community) async {
    setState(() => _joiningLeaving = true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      if (isMember) {
        final authUser = ref.read(authStateChangesProvider).value;
        if (authUser == null) return;
        await repo.leaveCommunity(widget.communityId, authUser.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Left ${community.name}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final user = await ref
            .read(authRepositoryProvider)
            .getCurrentUserModel();
        if (user == null) return;
        await repo.joinCommunity(widget.communityId, user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${community.name}!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joiningLeaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final communitiesAsync = ref.watch(communitiesProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final postsAsync =
        ref.watch(communityPostsProvider(widget.communityId));

    final community = communitiesAsync.asData?.value
        .where((c) => c.id == widget.communityId)
        .firstOrNull;

    final memberships = membershipsAsync.asData?.value ?? {};
    final isMember = memberships.contains(widget.communityId);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, community, isMember),
            if (community != null) _buildCommunityInfo(isDark, community),
            Expanded(
              child: postsAsync.when(
                data: (posts) => posts.isEmpty
                    ? _buildEmptyFeed(isDark)
                    : _buildFeed(isDark, posts),
                loading: () => _buildEmptyFeed(isDark),
                error: (_, _) => _buildEmptyFeed(isDark),
              ),
            ),
            _buildReadOnlyBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark,
      CommunityModel? community, bool isMember) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          ),
          Expanded(
            child: Text(
              community?.name ?? '',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          if (community != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _joiningLeaving
                  ? SizedBox(
                      width: 48,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDefault,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _toggleMembership(isMember, community),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isMember
                              ? Colors.transparent
                              : AppColors.primaryDefault,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isMember
                                ? (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.grayscaleLine)
                                : AppColors.primaryDefault,
                          ),
                        ),
                        child: Text(
                          isMember ? 'Leave' : 'Join',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isMember
                                ? (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.grayscaleBodyText)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityInfo(bool isDark, CommunityModel community) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: community.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child:
                  Text(community.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatCount(community.memberCount)} members',
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(bool isDark, List<CommunityPostModel> posts) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      physics: const BouncingScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final post = posts[i];
        return _PostThread(
          isDark: isDark,
          communityId: widget.communityId,
          post: post,
        );
      },
    );
  }

  Widget _buildEmptyFeed(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
            const SizedBox(height: 16),
            Text(
              'No announcements yet',
              style: AppTypography.textSmall.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Admin announcements and community\nupdates will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleBodyText,
          ),
          const SizedBox(width: 6),
          Text(
            'Only admins can post announcements',
            style: AppTypography.textSmall.copyWith(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post bubble ───────────────────────────────────────────────────────────────

class _PostThread extends StatelessWidget {
  final bool isDark;
  final String communityId;
  final CommunityPostModel post;

  const _PostThread({
    required this.isDark,
    required this.communityId,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    if (post.type == CommunityPostType.system) {
      return _SystemMessage(isDark: isDark, post: post);
    }
    return _AnnouncementThread(
      isDark: isDark,
      communityId: communityId,
      post: post,
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final bool isDark;
  final CommunityPostModel post;

  const _SystemMessage({required this.isDark, required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 8),
          Text(
            post.content,
            style: AppTypography.textSmall.copyWith(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _AnnouncementThread extends ConsumerStatefulWidget {
  final bool isDark;
  final String communityId;
  final CommunityPostModel post;

  const _AnnouncementThread({
    required this.isDark,
    required this.communityId,
    required this.post,
  });

  @override
  ConsumerState<_AnnouncementThread> createState() =>
      _AnnouncementThreadState();
}

class _AnnouncementThreadState extends ConsumerState<_AnnouncementThread> {
  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        isDark: widget.isDark,
        communityId: widget.communityId,
        post: widget.post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = widget.isDark;
    final isEvent = post.type == CommunityPostType.event;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _Avatar(
            name: post.authorName,
            avatarUrl: post.authorAvatarUrl,
          ),
          const SizedBox(width: 10),

          // Bubble
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name + role + time
                Row(
                  children: [
                    Text(
                      post.authorName,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      ),
                    ),
                    if (post.authorRole.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isEvent
                              ? const Color(0xFF5C6BC0).withValues(alpha: 0.15)
                              : AppColors.primaryDefault.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.authorRole,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isEvent
                                ? const Color(0xFF5C6BC0)
                                : AppColors.primaryDefault,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTime(post.createdAt),
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Content bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.grayscaleLine,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEvent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 14,
                                color: const Color(0xFF5C6BC0),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'EVENT',
                                style: AppTypography.textSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: const Color(0xFF5C6BC0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        post.content,
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                        ),
                      ),
                      if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              post.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      if (post.linkUrl != null && post.linkUrl!.isNotEmpty)
                        _LinkPreview(isDark: isDark, post: post),
                      const SizedBox(height: 10),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openComments,
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.grayscaleBodyText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${post.commentCount} comments',
                              style: AppTypography.textSmall.copyWith(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.grayscaleBodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  final bool isDark;
  final CommunityPostModel post;

  const _LinkPreview({required this.isDark, required this.post});

  Future<void> _openLink(BuildContext context) async {
    final rawUrl = post.linkUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) return;
    final normalized =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
        ? rawUrl
        : 'https://$rawUrl';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openLink(context),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkInputBackground : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.link_rounded,
              color: AppColors.primaryDefault,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.linkTitle?.isNotEmpty == true
                        ? post.linkTitle!
                        : post.linkUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  if (post.linkDescription?.isNotEmpty == true)
                    Text(
                      post.linkDescription!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.open_in_new_rounded,
              color: AppColors.primaryDefault,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final String communityId;
  final CommunityPostModel post;

  const _CommentsSheet({
    required this.isDark,
    required this.communityId,
    required this.post,
  });

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _posting = false;
  CommunityCommentModel? _replyingTo;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUserModel();
      if (user == null) return;
      await ref.read(communityRepositoryProvider).addComment(
            communityId: widget.communityId,
            postId: widget.post.id,
            content: text,
            user: user,
            replyToCommentId: _replyingTo?.id,
            replyToAuthorId: _replyingTo?.authorId,
            replyToAuthorName: _replyingTo?.authorName,
          );
      _commentController.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _reportComment(CommunityCommentModel comment) async {
    final authUser = ref.read(authStateChangesProvider).value;
    if (authUser == null) return;
    await ref.read(communityRepositoryProvider).reportComment(
          communityId: widget.communityId,
          postId: widget.post.id,
          commentId: comment.id,
          userId: authUser.uid,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported for admin review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final commentsAsync = ref.watch(
      communityCommentsProvider(
        (communityId: widget.communityId, postId: widget.post.id),
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.grayscaleLine,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comments',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.grayscaleTitleActive,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: commentsAsync.when(
                    data: (comments) {
                      final visible =
                          comments.where((c) => !c.isDeleted).toList();
                      if (visible.isEmpty) {
                        return _CommentsEmptyState(isDark: isDark);
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final comment = visible[index];
                          return _CommentTile(
                            isDark: isDark,
                            comment: comment,
                            onReply: () => setState(() {
                              _replyingTo = comment;
                              _commentController.text =
                                  '@${comment.authorName} ';
                            }),
                            onReport: () => _reportComment(comment),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDefault,
                        strokeWidth: 2,
                      ),
                    ),
                    error: (_, _) => _CommentsEmptyState(
                      isDark: isDark,
                      title: 'Comments unavailable',
                      body: 'Please try again after a moment.',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: _CommentInput(
                    isDark: isDark,
                    controller: _commentController,
                    replyingTo: _replyingTo,
                    isPosting: _posting,
                    onCancelReply: () => setState(() => _replyingTo = null),
                    onSubmit: _submitComment,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentsEmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String body;

  const _CommentsEmptyState({
    required this.isDark,
    this.title = 'No comments yet',
    this.body = 'Ask the first doubt on this announcement.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 34,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.textSmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final bool isDark;
  final CommunityCommentModel comment;
  final VoidCallback onReply;
  final VoidCallback onReport;

  const _CommentTile({
    required this.isDark,
    required this.comment,
    required this.onReply,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBackground : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: comment.authorName, avatarUrl: comment.authorAvatarUrl),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                        ),
                      ),
                    ),
                    if (comment.isAdminReply)
                      _TinyBadge(label: 'Admin', color: AppColors.primaryDefault),
                    Text(
                      _formatTime(comment.createdAt),
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ),
                if (comment.replyToAuthorName?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Replying to @${comment.replyToAuthorName}',
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: AppColors.primaryDefault,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Reply',
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDefault,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReport,
                      child: Text(
                        comment.status == CommunityCommentStatus.reported
                            ? 'Reported'
                            : 'Report',
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.textSmall.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final CommunityCommentModel? replyingTo;
  final bool isPosting;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;

  const _CommentInput({
    required this.isDark,
    required this.controller,
    required this.replyingTo,
    required this.isPosting,
    required this.onCancelReply,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBackground : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Column(
        children: [
          if (replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to @${replyingTo!.authorName}',
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: AppColors.primaryDefault,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.primaryDefault,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask a doubt or add a comment',
                    hintStyle: AppTypography.textSmall.copyWith(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: isPosting ? null : onSubmit,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDefault,
                    shape: BoxShape.circle,
                  ),
                  child: isPosting
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 1.6,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const _Avatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryDefault.withValues(alpha: 0.15),
        image: avatarUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarUrl.isEmpty
          ? Center(
              child: Text(
                initial,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDefault,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatCount(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _formatTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
