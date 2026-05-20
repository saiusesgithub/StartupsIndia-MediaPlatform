import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/style_guide.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/community_model.dart';
import '../../domain/models/community_post_model.dart';
import '../providers/community_providers.dart';

enum CommunityCollectionKind { myGroups, discover, activity }

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    if (_seeded) return;
    _seeded = true;
    await ref.read(communityRepositoryProvider).seedDefaultCommunities();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = FirebaseAuth.instance.currentUser == null;
    final communitiesAsync = ref.watch(communitiesProvider);
    final membershipsAsync = ref.watch(myMembershipDetailsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(isDark),
            if (isGuest)
              _GuestSliver(isDark: isDark)
            else
              ...communitiesAsync.when(
                data: (communities) {
                  final memberships = membershipsAsync.asData?.value ?? {};
                  final joined = communities
                      .where((c) => memberships.containsKey(c.id))
                      .toList();
                  final discover = communities
                      .where((c) => !memberships.containsKey(c.id))
                      .toList();
                  return [
                    _QuickActionsSliver(
                      isDark: isDark,
                      joinedCount: joined.length,
                      discoverCount: discover.length,
                      activityCount: 0,
                    ),
                    _MyGroupsSliver(
                      isDark: isDark,
                      communities: joined,
                      memberships: memberships,
                      showAll: false,
                      onViewAll: () => _openCollection(
                        CommunityCollectionKind.myGroups,
                      ),
                    ),
                    _DiscoverSliver(
                      isDark: isDark,
                      communities: discover,
                      showAll: false,
                      onViewAll: () => _openCollection(
                        CommunityCollectionKind.discover,
                      ),
                    ),
                    _ActivityPreviewSliver(
                      isDark: isDark,
                      onViewAll: () => _openCollection(
                        CommunityCollectionKind.activity,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ];
                },
                loading: () => [
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDefault,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
                error: (_, _) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Failed to load communities.',
                        textAlign: TextAlign.center,
                        style: AppTypography.textSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openCollection(CommunityCollectionKind kind) {
    Navigator.pushNamed(context, '/community-collection', arguments: kind);
  }

  SliverToBoxAdapter _buildHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: AppTypography.displaySmallBold.copyWith(
                fontSize: 24,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Connect, collaborate and grow with the startup ecosystem',
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSliver extends StatelessWidget {
  final bool isDark;
  final int joinedCount;
  final int discoverCount;
  final int activityCount;

  const _QuickActionsSliver({
    required this.isDark,
    required this.joinedCount,
    required this.discoverCount,
    required this.activityCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Row(
          children: [
            _ActionChip(
              isDark: isDark,
              icon: Icons.groups_rounded,
              color: const Color(0xFFE8341C),
              label: 'My Groups',
              count: '$joinedCount Groups',
              onTap: () => Navigator.pushNamed(
                context,
                '/community-collection',
                arguments: CommunityCollectionKind.myGroups,
              ),
            ),
            const SizedBox(width: 10),
            _ActionChip(
              isDark: isDark,
              icon: Icons.explore_rounded,
              color: const Color(0xFF9B51E0),
              label: 'Discover',
              count: discoverCount == 0 ? 'All joined' : 'Explore Groups',
              onTap: () => Navigator.pushNamed(
                context,
                '/community-collection',
                arguments: CommunityCollectionKind.discover,
              ),
            ),
            const SizedBox(width: 10),
            _ActionChip(
              isDark: isDark,
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF0984E3),
              label: 'My Activity',
              count: '$activityCount New',
              onTap: () => Navigator.pushNamed(
                context,
                '/community-collection',
                arguments: CommunityCollectionKind.activity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityCollectionScreen extends ConsumerWidget {
  final CommunityCollectionKind kind;

  const CommunityCollectionScreen({super.key, required this.kind});

  String get _title => switch (kind) {
        CommunityCollectionKind.myGroups => 'My Groups',
        CommunityCollectionKind.discover => 'Discover Groups',
        CommunityCollectionKind.activity => 'My Activity',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final communitiesAsync = ref.watch(communitiesProvider);
    final membershipsAsync = ref.watch(myMembershipDetailsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CollectionHeader(isDark: isDark, title: _title),
            ),
            if (kind == CommunityCollectionKind.activity)
              _ActivitySliver(isDark: isDark)
            else
              ...communitiesAsync.when(
                data: (communities) {
                  final memberships = membershipsAsync.asData?.value ?? {};
                  final joined = communities
                      .where((c) => memberships.containsKey(c.id))
                      .toList();
                  final discover = communities
                      .where((c) => !memberships.containsKey(c.id))
                      .toList();
                  if (kind == CommunityCollectionKind.myGroups) {
                    return [
                      _MyGroupsSliver(
                        isDark: isDark,
                        communities: joined,
                        memberships: memberships,
                        showAll: true,
                      ),
                    ];
                  }
                  return [
                    _DiscoverSliver(
                      isDark: isDark,
                      communities: discover,
                      showAll: true,
                    ),
                  ];
                },
                loading: () => [
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDefault,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
                error: (_, _) => [
                  SliverToBoxAdapter(
                    child: _EmptyState(
                      isDark: isDark,
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load communities',
                      body: 'Please try again in a moment.',
                    ),
                  ),
                ],
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  final bool isDark;
  final String title;

  const _CollectionHeader({required this.isDark, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.displaySmallBold.copyWith(
                fontSize: 22,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String label;
  final String count;
  final VoidCallback onTap;

  const _ActionChip({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
              Text(
                count,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyGroupsSliver extends StatelessWidget {
  final bool isDark;
  final List<CommunityModel> communities;
  final Map<String, CommunityMembershipModel> memberships;
  final bool showAll;
  final VoidCallback? onViewAll;

  const _MyGroupsSliver({
    required this.isDark,
    required this.communities,
    required this.memberships,
    required this.showAll,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final visible = showAll ? communities : communities.take(3).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            isDark: isDark,
            label: 'My Groups',
            showViewAll: !showAll && communities.length > visible.length,
            onViewAll: onViewAll,
          ),
          if (visible.isEmpty)
            _EmptyState(
              isDark: isDark,
              icon: Icons.groups_outlined,
              title: 'No groups joined yet',
              body: 'Discover a community and join the conversations.',
            )
          else
            ...visible.map(
              (c) => _CommunityListTile(
                isDark: isDark,
                community: c,
                membership: memberships[c.id],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DiscoverSliver extends ConsumerWidget {
  final bool isDark;
  final List<CommunityModel> communities;
  final bool showAll;
  final VoidCallback? onViewAll;

  const _DiscoverSliver({
    required this.isDark,
    required this.communities,
    required this.showAll,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = showAll ? communities : communities.take(4).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            isDark: isDark,
            label: 'Discover Groups',
            showViewAll: !showAll && communities.length > visible.length,
            onViewAll: onViewAll,
          ),
          if (visible.isEmpty)
            _EmptyState(
              isDark: isDark,
              icon: Icons.check_circle_outline_rounded,
              title: 'All communities joined',
              body: 'Your joined communities are listed in My Groups.',
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: visible.length,
                itemBuilder: (context, i) => _DiscoverCard(
                  isDark: isDark,
                  community: visible[i],
                  ref: ref,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DiscoverCard extends StatefulWidget {
  final bool isDark;
  final CommunityModel community;
  final WidgetRef ref;

  const _DiscoverCard({
    required this.isDark,
    required this.community,
    required this.ref,
  });

  @override
  State<_DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<_DiscoverCard> {
  bool _loading = false;

  Future<void> _join() async {
    setState(() => _loading = true);
    try {
      final user =
          await widget.ref.read(authRepositoryProvider).getCurrentUserModel();
      if (user == null) return;
      await widget.ref
          .read(communityRepositoryProvider)
          .joinCommunity(widget.community.id, user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.community;
    final isDark = widget.isDark;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/community-detail', arguments: c.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(c.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              c.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${_formatCount(c.memberCount)} Members',
              style: AppTypography.textSmall.copyWith(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _loading ? null : _join,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.primaryDefault),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 14,
                        child: Center(
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryDefault,
                              strokeWidth: 1.5,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        'Join',
                        textAlign: TextAlign.center,
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDefault,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityListTile extends StatelessWidget {
  final bool isDark;
  final CommunityModel community;
  final CommunityMembershipModel? membership;

  const _CommunityListTile({
    required this.isDark,
    required this.community,
    this.membership,
  });

  @override
  Widget build(BuildContext context) {
    final c = community;
    final lastPost = _announcementPreview(c.lastPost);
    final lastMsg = lastPost?['content'] as String? ?? c.description;
    final lastAuthor = lastPost?['authorName'] as String? ?? '';
    final lastTime = _formatLastTime(lastPost?['createdAt']);
    final hasUnread = _hasUnreadAnnouncement(c, membership);

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/community-detail', arguments: c.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(c.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.grayscaleTitleActive,
                          ),
                        ),
                      ),
                      if (hasUnread) const _UnreadDot(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (lastAuthor.isNotEmpty) ...[
                        Text(
                          '$lastAuthor: ',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatCount(c.memberCount)} Members',
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 11,
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
            const SizedBox(width: 8),
            Text(
              lastTime,
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
    );
  }
}

class _ActivityPreviewSliver extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onViewAll;

  const _ActivityPreviewSliver({
    required this.isDark,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(myCommunityActivityProvider).asData?.value ?? [];
    final visible = activity.take(3).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            isDark: isDark,
            label: 'My Activity',
            showViewAll: activity.length > visible.length,
            onViewAll: onViewAll,
          ),
          if (visible.isEmpty)
            _EmptyState(
              isDark: isDark,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No questions yet',
              body: 'Your comments and pending admin replies will show here.',
            )
          else
            ...visible.map((comment) => _ActivityTile(
                  isDark: isDark,
                  comment: comment,
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActivitySliver extends ConsumerWidget {
  final bool isDark;

  const _ActivitySliver({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(myCommunityActivityProvider);
    return SliverToBoxAdapter(
      child: activityAsync.when(
        data: (activity) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(isDark: isDark, label: 'My Activity'),
            if (activity.isEmpty)
              _EmptyState(
                isDark: isDark,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No questions yet',
                body: 'Ask a doubt on any announcement to track it here.',
              )
            else
              ...activity.map((comment) => _ActivityTile(
                    isDark: isDark,
                    comment: comment,
                  )),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryDefault,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, _) => _EmptyState(
          isDark: isDark,
          icon: Icons.error_outline_rounded,
          title: 'Activity unavailable',
          body: 'Your questions could not be loaded right now.',
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final bool isDark;
  final CommunityCommentModel comment;

  const _ActivityTile({required this.isDark, required this.comment});

  @override
  Widget build(BuildContext context) {
    final pending = !comment.hasAdminReply;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pending
                ? Icons.hourglass_top_rounded
                : Icons.mark_chat_read_outlined,
            color: pending ? const Color(0xFFF4B740) : AppColors.primaryDefault,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${pending ? 'Pending admin reply' : 'Admin replied'} · ${_formatTime(comment.createdAt)}',
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
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  final String label;
  final bool showViewAll;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.isDark,
    required this.label,
    this.showViewAll = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.textSmall.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDefault,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryDefault,
                    size: 18,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String body;

  const _EmptyState({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleBodyText,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.textSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 3),
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
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        color: AppColors.primaryDefault,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _GuestSliver extends StatelessWidget {
  final bool isDark;
  const _GuestSliver({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryDefault.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: AppColors.primaryDefault,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Join the Community',
              style: AppTypography.displaySmallBold.copyWith(
                fontSize: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account to join communities\nand connect with fellow founders.',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/signup'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDefault,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Create Free Account',
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmallBold.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Text(
                'Already have an account? Log In',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic>? _announcementPreview(Map<String, dynamic>? lastPost) {
  if (lastPost == null) return null;
  if (lastPost['type'] == 'system') return null;
  return lastPost;
}

bool _hasUnreadAnnouncement(
  CommunityModel community,
  CommunityMembershipModel? membership,
) {
  final last = community.lastAnnouncementAt ??
      _timestampToDate(_announcementPreview(community.lastPost)?['createdAt']);
  if (last == null) return false;
  final readAt = membership?.lastReadAnnouncementAt;
  if (readAt == null) return true;
  return last.isAfter(readAt);
}

String _formatCount(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _formatLastTime(dynamic raw) {
  final dt = _timestampToDate(raw);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}';
}

String _formatTime(DateTime? dt) {
  if (dt == null) return 'just now';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

DateTime? _timestampToDate(dynamic raw) {
  return raw is DateTime
      ? raw
      : raw is Timestamp
          ? raw.toDate()
          : null;
}
