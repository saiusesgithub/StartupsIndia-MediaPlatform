import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/style_guide.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/community_model.dart';
import '../providers/community_providers.dart';

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
    final membershipsAsync = ref.watch(myMembershipsProvider);

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
                  final memberships =
                      membershipsAsync.asData?.value ?? {};
                  final joined = communities
                      .where((c) => memberships.contains(c.id))
                      .toList();
                  final discover = communities
                      .where((c) => !memberships.contains(c.id))
                      .toList();
                  return [
                    _QuickActionsSliver(
                      isDark: isDark,
                      joinedCount: joined.length,
                      discoverCount: discover.length,
                    ),
                    if (joined.isNotEmpty)
                      _MyGroupsSliver(
                        isDark: isDark,
                        communities: joined,
                        memberships: memberships,
                      ),
                    _DiscoverSliver(
                      isDark: isDark,
                      communities: discover,
                      memberships: memberships,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ];
                },
                loading: () => [
                  SliverFillRemaining(
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

// ── Quick actions row ─────────────────────────────────────────────────────────

class _QuickActionsSliver extends StatelessWidget {
  final bool isDark;
  final int joinedCount;
  final int discoverCount;

  const _QuickActionsSliver({
    required this.isDark,
    required this.joinedCount,
    required this.discoverCount,
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
              color: const Color(0xFF6C5CE7),
              label: 'My Groups',
              count: '$joinedCount Groups',
            ),
            const SizedBox(width: 10),
            _ActionChip(
              isDark: isDark,
              icon: Icons.explore_rounded,
              color: const Color(0xFF0984E3),
              label: 'Discover',
              count: 'Explore Groups',
            ),
            const SizedBox(width: 10),
            _ActionChip(
              isDark: isDark,
              icon: Icons.notifications_none_rounded,
              color: const Color(0xFFF4B740),
              label: 'Activity',
              count: 'Updates',
            ),
          ],
        ),
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

  const _ActionChip({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}

// ── My Groups section ─────────────────────────────────────────────────────────

class _MyGroupsSliver extends StatelessWidget {
  final bool isDark;
  final List<CommunityModel> communities;
  final Set<String> memberships;

  const _MyGroupsSliver({
    required this.isDark,
    required this.communities,
    required this.memberships,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(isDark: isDark, label: 'My Groups'),
          ...communities.map(
            (c) => _CommunityListTile(
              isDark: isDark,
              community: c,
              isMember: true,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Discover section ──────────────────────────────────────────────────────────

class _DiscoverSliver extends ConsumerWidget {
  final bool isDark;
  final List<CommunityModel> communities;
  final Set<String> memberships;

  const _DiscoverSliver({
    required this.isDark,
    required this.communities,
    required this.memberships,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (communities.isEmpty) return const SizedBox.shrink();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(isDark: isDark, label: 'Discover Groups'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: communities.length,
              itemBuilder: (context, i) => _DiscoverCard(
                isDark: isDark,
                community: communities[i],
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
      final user = await widget.ref
          .read(authRepositoryProvider)
          .getCurrentUserModel();
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
      onTap: () => Navigator.pushNamed(
        context,
        '/community-detail',
        arguments: c.id,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(c.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              c.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatCount(c.memberCount)} members',
              style: AppTypography.textSmall.copyWith(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _loading ? null : _join,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDefault,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 14,
                          child: Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                color: Colors.white,
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
                            color: Colors.white,
                          ),
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

// ── Community list tile (My Groups) ──────────────────────────────────────────

class _CommunityListTile extends StatelessWidget {
  final bool isDark;
  final CommunityModel community;
  final bool isMember;

  const _CommunityListTile({
    required this.isDark,
    required this.community,
    required this.isMember,
  });

  @override
  Widget build(BuildContext context) {
    final c = community;
    final lastPost = c.lastPost;
    final lastMsg = lastPost?['content'] as String? ?? 'No announcements yet';
    final lastAuthor = lastPost?['authorName'] as String? ?? '';
    final lastTime = _formatLastTime(lastPost?['createdAt']);

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/community-detail', arguments: c.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Row(
          children: [
            // Emoji icon
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

            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (lastAuthor.isNotEmpty) ...[
                        Text(
                          lastAuthor,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                        ),
                        Text(
                          ': ',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 12,
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
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCount(c.memberCount)} members',
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

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  final String label;

  const _SectionHeader({required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
    );
  }
}

// ── Guest sliver ──────────────────────────────────────────────────────────────

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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatCount(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _formatLastTime(dynamic raw) {
  if (raw == null) return '';
  final dt = raw is DateTime
      ? raw
      : raw is Timestamp
          ? raw.toDate()
          : null;
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}';
}
