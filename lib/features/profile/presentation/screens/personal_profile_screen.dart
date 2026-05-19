import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/news_article_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/presentation/widgets/news_tile.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../theme/style_guide.dart';
import '../../../community/presentation/providers/community_providers.dart';

enum _Tab { communities, saved, liked }

final profileSavedArticlesProvider =
    StreamProvider.autoDispose<List<NewsArticleModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(<NewsArticleModel>[]);
  return ref.watch(firestoreRepositoryProvider).getBookmarkedArticles(user.uid);
});

final profileLikedArticlesProvider =
    StreamProvider.autoDispose<List<NewsArticleModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(<NewsArticleModel>[]);
  return ref.watch(firestoreRepositoryProvider).getLikedArticles(user.uid);
});

class PersonalProfileScreen extends ConsumerStatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  ConsumerState<PersonalProfileScreen> createState() =>
      _PersonalProfileScreenState();
}

class _PersonalProfileScreenState
    extends ConsumerState<PersonalProfileScreen> {
  late Future<UserModel?> _userFuture;
  _Tab _activeTab = _Tab.communities;

  @override
  void initState() {
    super.initState();
    _userFuture = ref.read(authRepositoryProvider).getCurrentUserModel();
  }

  String _handle(UserModel? user) {
    final email = (user?.email.isNotEmpty == true)
        ? user!.email
        : FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) return 'you';
    return email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7);

    if (FirebaseAuth.instance.currentUser == null) {
      return GuestProfileScreen(isDark: isDark);
    }

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryDefault)),
          );
        }

        final user = snapshot.data ??
            const UserModel(
              uid: '',
              displayName: 'Your Name',
              bio: '',
              avatarUrl: '',
              websiteUrl: '',
              followersCount: 0,
              followingCount: 0,
              newsCount: 0,
            );

        return Scaffold(
          backgroundColor: bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _HeaderBar(isDark: isDark)),
              SliverToBoxAdapter(
                  child: _ProfileCard(
                user: user,
                handle: _handle(user),
                isDark: isDark,
                onEditProfile: _openEditProfile,
              )),
              SliverToBoxAdapter(child: _ProBanner(isDark: isDark)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabsDelegate(
                  activeTab: _activeTab,
                  isDark: isDark,
                  onTabSelected: (t) => setState(() => _activeTab = t),
                ),
              ),
              ..._tabContent(_activeTab, isDark),
              SliverToBoxAdapter(child: _Achievements(isDark: isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _tabContent(_Tab tab, bool isDark) {
    switch (tab) {
      case _Tab.communities:
        return [_ProfileCommunitiesSliver(isDark: isDark)];
      case _Tab.saved:
        return [
          _ArticleListSliver(
            articlesAsync: ref.watch(profileSavedArticlesProvider),
            isDark: isDark,
            emptyIcon: Icons.bookmark_border_rounded,
            emptyTitle: 'No saved posts',
            emptySubtitle: 'Tap the bookmark icon on any post to save it here.',
          ),
        ];
      case _Tab.liked:
        return [
          _ArticleListSliver(
            articlesAsync: ref.watch(profileLikedArticlesProvider),
            isDark: isDark,
            emptyIcon: Icons.favorite_border_rounded,
            emptyTitle: 'No liked posts',
            emptySubtitle: 'Posts you like will appear here.',
          ),
        ];
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.pushNamed(context, '/edit-profile');
    if (!mounted) return;
    setState(() {
      _userFuture = ref.read(authRepositoryProvider).getCurrentUserModel();
    });
  }
}

// ── Communities tab ───────────────────────────────────────────────────────────

class _ProfileCommunitiesSliver extends ConsumerWidget {
  final bool isDark;
  const _ProfileCommunitiesSliver({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(communitiesProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);

    final all = communitiesAsync.asData?.value ?? [];
    final memberships = membershipsAsync.asData?.value ?? {};
    final joined = all.where((c) => memberships.contains(c.id)).toList();

    if (communitiesAsync.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryDefault),
          ),
        ),
      );
    }

    if (joined.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyState(
          isDark: isDark,
          icon: Icons.people_outline_rounded,
          title: 'No communities yet',
          subtitle: 'Join a community to see it here.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final c = joined[i];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/community-detail',
                arguments: c.id,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.grayscaleWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.grayscaleLine,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          c.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          Text(
                            '${_fmtCount(c.memberCount)} members',
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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleButtonText,
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: joined.length,
        ),
      ),
    );
  }

  String _fmtCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _ArticleListSliver extends StatelessWidget {
  final AsyncValue<List<NewsArticleModel>> articlesAsync;
  final bool isDark;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _ArticleListSliver({
    required this.articlesAsync,
    required this.isDark,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return articlesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryDefault),
          ),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: _EmptyState(
          isDark: isDark,
          icon: Icons.error_outline_rounded,
          title: 'Could not load articles',
          subtitle: 'Pull back later or check your connection.',
        ),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              isDark: isDark,
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                return Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.grayscaleLine,
                );
              }

              final article = _toNewsArticle(articles[index ~/ 2]);
              return NewsTile(article: article);
            },
            childCount: articles.length * 2 - 1,
          ),
        );
      },
    );
  }

  NewsArticle _toNewsArticle(NewsArticleModel model) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return NewsArticle(
      id: model.id,
      authorId: model.authorId,
      category: model.category,
      headline: model.headline,
      sourceName: model.sourceName,
      sourceId: model.sourceId,
      sourceLogoAsset: model.sourceLogoAsset,
      thumbnailAsset: model.thumbnailAsset,
      timeAgo: formatArticleTimestamp(model.createdAt, fallback: model.timeAgo),
      body: model.body,
      likesCount: model.likesCount,
      commentsCount: model.commentsCount,
      isSourceFollowing: model.isSourceFollowing,
      isBookmarked:
          model.isBookmarked || model.bookmarkedBy.contains(currentUserId),
      isLiked: model.isLiked || model.likedBy.contains(currentUserId),
    );
  }
}

// ── Header bar ────────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final bool isDark;

  const _HeaderBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
        child: Row(
          children: [
            Text(
              'Profile',
              style: AppTypography.displaySmallBold.copyWith(
                fontSize: 22,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: Icon(
                Icons.settings_outlined,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleButtonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel user;
  final String handle;
  final bool isDark;
  final VoidCallback onEditProfile;

  const _ProfileCard({
    required this.user,
    required this.handle,
    required this.isDark,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
        ),
        child: Column(
          children: [
            // ── Cover + avatar stack ──────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDefault
                              .withValues(alpha: isDark ? 0.40 : 0.22),
                          const Color(0xFF1A0A2E)
                              .withValues(alpha: isDark ? 0.70 : 0.30),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 20,
                  child: _Avatar(url: user.avatarUrl, isDark: isDark),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onEditProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.grayscaleLine,
                        ),
                      ),
                      child: Text(
                        'Edit profile',
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Name / handle / role / bio / stats / website ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName.isEmpty
                                  ? 'Your Name'
                                  : user.displayName,
                              style: AppTypography.displaySmallBold.copyWith(
                                fontSize: 20,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.grayscaleTitleActive,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@$handle',
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
                      if (user.role.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDefault
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _fmtRole(user.role),
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDefault,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      user.bio,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (user.interests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests
                          .map(
                            (interest) => _InterestChip(
                              label: _fmtRole(interest),
                              isDark: isDark,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // 4 stats
                  Row(
                    children: [
                      _Stat(
                          value: _fmt(user.newsCount),
                          label: 'Posts',
                          isDark: isDark),
                      _StatDiv(isDark: isDark),
                      _Stat(
                          value: _fmt(user.followersCount),
                          label: 'Followers',
                          isDark: isDark),
                      _StatDiv(isDark: isDark),
                      _Stat(
                          value: _fmt(user.followingCount),
                          label: 'Following',
                          isDark: isDark),
                      _StatDiv(isDark: isDark),
                      _Stat(
                          value: '0',
                          label: 'Communities',
                          isDark: isDark),
                    ],
                  ),

                  if (user.websiteUrl.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.link_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user.websiteUrl
                                .replaceFirst(RegExp(r'https?://'), ''),
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 12,
                              color: AppColors.primaryDefault,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtRole(String role) => role
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Pro upgrade banner ────────────────────────────────────────────────────────

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _InterestChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryDefault.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryDefault.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.textSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDefault,
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final bool isDark;

  const _ProBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryDefault
                  .withValues(alpha: isDark ? 0.18 : 0.08),
              const Color(0xFFFF6B35)
                  .withValues(alpha: isDark ? 0.10 : 0.04),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryDefault.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryDefault.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.primaryDefault, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Startup India Pro',
                    style: AppTypography.displaySmallBold.copyWith(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  Text(
                    'Analytics, priority features & more',
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
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Upgrade Now →',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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

// ── Pinned 5-icon tab bar ─────────────────────────────────────────────────────

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final _Tab activeTab;
  final bool isDark;
  final ValueChanged<_Tab> onTabSelected;

  _TabsDelegate({
    required this.activeTab,
    required this.isDark,
    required this.onTabSelected,
  });

  static const _items = [
    (tab: _Tab.communities, icon: Icons.people_outline_rounded, label: 'Communities'),
    (tab: _Tab.saved, icon: Icons.bookmark_border_rounded, label: 'Saved'),
    (tab: _Tab.liked, icon: Icons.favorite_border_rounded, label: 'Liked'),
  ];

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg =
        isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7);
    return Container(
      color: bg,
      child: Row(
        children: _items
            .map((item) => Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(item.tab),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: activeTab == item.tab
                                ? AppColors.primaryDefault
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: activeTab == item.tab
                                ? AppColors.primaryDefault
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.grayscaleButtonText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 9,
                              fontWeight: activeTab == item.tab
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: activeTab == item.tab
                                  ? AppColors.primaryDefault
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.grayscaleButtonText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      old.activeTab != activeTab || old.isDark != isDark;
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, color: AppColors.primaryDefault, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 15,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              height: 1.5,
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

// ── Achievements ──────────────────────────────────────────────────────────────

class _Achievements extends StatelessWidget {
  final bool isDark;

  const _Achievements({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Achievements',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AchievementCard(
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFFFC107),
                  label: 'Top Contributor',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AchievementCard(
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF4CAF50),
                  label: 'Early Adopter',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AchievementCard(
                  icon: Icons.auto_stories_rounded,
                  color: const Color(0xFF2196F3),
                  label: 'Active Learner',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isDark;

  const _AchievementCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String url;
  final bool isDark;

  const _Avatar({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          width: 3,
        ),
        color: isDark
            ? AppColors.darkBackground
            : AppColors.grayscaleSecondaryButton,
      ),
      child: ClipOval(
        child: url.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => _fallback(),
                errorWidget: (context, url, error) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.primaryDefault.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded,
            color: AppColors.primaryDefault, size: 38),
      );
}

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _Stat(
      {required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
              fontSize: 10,
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

class _StatDiv extends StatelessWidget {
  final bool isDark;

  const _StatDiv({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
    );
  }
}
