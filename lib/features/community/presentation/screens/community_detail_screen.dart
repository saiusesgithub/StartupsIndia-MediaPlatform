import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDefault,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Failed to load announcements.',
                    style: AppTypography.textSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                ),
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
        return _PostBubble(isDark: isDark, post: post);
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

class _PostBubble extends StatelessWidget {
  final bool isDark;
  final CommunityPostModel post;

  const _PostBubble({required this.isDark, required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.type == CommunityPostType.system) {
      return _SystemMessage(isDark: isDark, post: post);
    }
    return _AnnouncementBubble(isDark: isDark, post: post);
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

class _AnnouncementBubble extends StatelessWidget {
  final bool isDark;
  final CommunityPostModel post;

  const _AnnouncementBubble({required this.isDark, required this.post});

  @override
  Widget build(BuildContext context) {
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
                    color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
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
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
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
